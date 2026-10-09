package store

import (
	"database/sql"
	"encoding/json"
	"time"

	"xvay/houduan/internal/auth"
	"xvay/houduan/internal/errs"
	"xvay/houduan/internal/protocol"
)

const nodeCols = `id, name, region, country_code, host, sort_order, enabled, remark, secret,
	xray_enabled, xray_port, xray_api_port,
	reality_private_key, reality_public_key, reality_short_ids,
	reality_sni, reality_dest, reality_spider_x, reality_fingerprint, reality_flow,
	hy2_enabled, hy2_port, hy2_sni, hy2_insecure, hy2_obfs_password,
	hy2_up_mbps, hy2_down_mbps, hy2_cert_path, hy2_key_path, hy2_masquerade,
	hy2_stats_secret, last_seen_at, created_at`

func scanNode(row interface{ Scan(...any) error }) (Node, error) {
	var node Node
	var enabled, xrayEnabled, hy2Enabled, hy2Insecure int
	err := row.Scan(
		&node.ID, &node.Name, &node.Region, &node.CountryCode, &node.Host, &node.SortOrder, &enabled, &node.Remark, &node.Secret,
		&xrayEnabled, &node.XrayPort, &node.XrayAPIPort,
		&node.RealityPrivateKey, &node.RealityPublicKey, &node.RealityShortIDs,
		&node.RealitySNI, &node.RealityDest, &node.RealitySpiderX, &node.RealityFingerprint, &node.RealityFlow,
		&hy2Enabled, &node.Hy2Port, &node.Hy2SNI, &hy2Insecure, &node.Hy2ObfsPassword,
		&node.Hy2UpMbps, &node.Hy2DownMbps, &node.Hy2CertPath, &node.Hy2KeyPath, &node.Hy2Masquerade,
		&node.Hy2StatsSecret, &node.LastSeenAt, &node.CreatedAt,
	)
	node.Enabled = enabled != 0
	node.XrayEnabled = xrayEnabled != 0
	node.Hy2Enabled = hy2Enabled != 0
	node.Hy2Insecure = hy2Insecure != 0
	return node, err
}

func (s *Store) CreateNode(input NodeInput) (Node, error) {
	keys := protocol.RealityKeys{PrivateKey: input.RealityPrivateKey, PublicKey: input.RealityPublicKey}
	if keys.PrivateKey == "" {
		generated, err := protocol.GenerateRealityKeys()
		if err != nil {
			return Node{}, err
		}
		keys = generated
	}
	shortIDs, err := json.Marshal(input.RealityShortIDs)
	if err != nil {
		return Node{}, err
	}
	secret, err := auth.NewToken(24)
	if err != nil {
		return Node{}, err
	}
	statsSecret, err := auth.NewToken(18)
	if err != nil {
		return Node{}, err
	}
	row := s.db.QueryRow(
		`INSERT INTO nodes (
			name, region, country_code, host, sort_order, enabled, remark, secret,
			xray_enabled, xray_port, xray_api_port,
			reality_private_key, reality_public_key, reality_short_ids,
			reality_sni, reality_dest, reality_spider_x, reality_fingerprint, reality_flow,
			hy2_enabled, hy2_port, hy2_sni, hy2_insecure, hy2_obfs_password,
			hy2_up_mbps, hy2_down_mbps, hy2_cert_path, hy2_key_path, hy2_masquerade,
			hy2_stats_secret, last_seen_at, created_at
		) VALUES (
			?, ?, ?, ?, ?, ?, ?, ?,
			?, ?, ?,
			?, ?, ?,
			?, ?, ?, ?, ?,
			?, ?, ?, ?, ?,
			?, ?, ?, ?, ?,
			?, 0, ?
		) RETURNING `+nodeCols,
		input.Name, input.Region, input.CountryCode, input.Host, input.SortOrder, bit(input.Enabled), input.Remark, secret,
		bit(input.XrayEnabled), input.XrayPort, input.XrayAPIPort,
		keys.PrivateKey, keys.PublicKey, string(shortIDs),
		input.RealitySNI, input.RealityDest, input.RealitySpiderX, input.RealityFingerprint, input.RealityFlow,
		bit(input.Hy2Enabled), input.Hy2Port, input.Hy2SNI, bit(input.Hy2Insecure), input.Hy2ObfsPassword,
		input.Hy2UpMbps, input.Hy2DownMbps, input.Hy2CertPath, input.Hy2KeyPath, input.Hy2Masquerade,
		statsSecret, time.Now().UnixMilli(),
	)
	return scanNode(row)
}

func (s *Store) ListNodes() ([]Node, error) {
	rows, err := s.db.Query(`SELECT ` + nodeCols + ` FROM nodes ORDER BY sort_order ASC, id ASC`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var nodes []Node
	for rows.Next() {
		node, err := scanNode(rows)
		if err != nil {
			return nil, err
		}
		nodes = append(nodes, node)
	}
	if nodes == nil {
		nodes = []Node{}
	}
	return nodes, rows.Err()
}

func (s *Store) FindNode(id int64) (Node, bool, error) {
	node, err := scanNode(s.db.QueryRow(`SELECT `+nodeCols+` FROM nodes WHERE id = ?`, id))
	if err == sql.ErrNoRows {
		return Node{}, false, nil
	}
	return node, err == nil, err
}

func (s *Store) UpdateNode(id int64, patch NodePatch) (Node, error) {
	current, ok, err := s.FindNode(id)
	if err != nil {
		return Node{}, err
	}
	if !ok {
		return Node{}, errs.New(404, "NOT_FOUND", "节点不存在")
	}
	applyNodePatch(&current, patch)
	if patch.RotateRealityKeys {
		keys, err := protocol.GenerateRealityKeys()
		if err != nil {
			return Node{}, err
		}
		current.RealityPrivateKey = keys.PrivateKey
		current.RealityPublicKey = keys.PublicKey
	} else if patch.RealityPrivateKey != nil && *patch.RealityPrivateKey != "" {
		current.RealityPrivateKey = *patch.RealityPrivateKey
		if patch.RealityPublicKey != nil {
			current.RealityPublicKey = *patch.RealityPublicKey
		}
	}
	if patch.RotateSecret {
		secret, err := auth.NewToken(24)
		if err != nil {
			return Node{}, err
		}
		current.Secret = secret
	}
	if patch.RotateHy2StatsSecret {
		secret, err := auth.NewToken(18)
		if err != nil {
			return Node{}, err
		}
		current.Hy2StatsSecret = secret
	}
	if patch.RealityShortIDs != nil {
		raw, err := json.Marshal(patch.RealityShortIDs)
		if err != nil {
			return Node{}, err
		}
		current.RealityShortIDs = string(raw)
	}
	return scanNode(s.db.QueryRow(
		`UPDATE nodes SET
			name = ?, region = ?, country_code = ?, host = ?, sort_order = ?, enabled = ?,
			remark = ?, secret = ?, xray_enabled = ?, xray_port = ?, xray_api_port = ?,
			reality_private_key = ?, reality_public_key = ?, reality_short_ids = ?,
			reality_sni = ?, reality_dest = ?, reality_spider_x = ?, reality_fingerprint = ?,
			reality_flow = ?, hy2_enabled = ?, hy2_port = ?, hy2_sni = ?, hy2_insecure = ?,
			hy2_obfs_password = ?, hy2_up_mbps = ?, hy2_down_mbps = ?, hy2_cert_path = ?,
			hy2_key_path = ?, hy2_masquerade = ?, hy2_stats_secret = ?
		 WHERE id = ?
		 RETURNING `+nodeCols,
		current.Name, current.Region, current.CountryCode, current.Host, current.SortOrder, bit(current.Enabled),
		current.Remark, current.Secret, bit(current.XrayEnabled), current.XrayPort, current.XrayAPIPort,
		current.RealityPrivateKey, current.RealityPublicKey, current.RealityShortIDs,
		current.RealitySNI, current.RealityDest, current.RealitySpiderX, current.RealityFingerprint,
		current.RealityFlow, bit(current.Hy2Enabled), current.Hy2Port, current.Hy2SNI, bit(current.Hy2Insecure),
		current.Hy2ObfsPassword, current.Hy2UpMbps, current.Hy2DownMbps, current.Hy2CertPath,
		current.Hy2KeyPath, current.Hy2Masquerade, current.Hy2StatsSecret, id,
	))
}

func applyNodePatch(node *Node, patch NodePatch) {
	if patch.Name != nil {
		node.Name = *patch.Name
	}
	if patch.Region != nil {
		node.Region = *patch.Region
	}
	if patch.CountryCode != nil {
		node.CountryCode = *patch.CountryCode
	}
	if patch.Host != nil {
		node.Host = *patch.Host
	}
	if patch.SortOrder != nil {
		node.SortOrder = *patch.SortOrder
	}
	if patch.Enabled != nil {
		node.Enabled = *patch.Enabled
	}
	if patch.Remark != nil {
		node.Remark = *patch.Remark
	}
	if patch.XrayEnabled != nil {
		node.XrayEnabled = *patch.XrayEnabled
	}
	if patch.XrayPort != nil {
		node.XrayPort = *patch.XrayPort
	}
	if patch.XrayAPIPort != nil {
		node.XrayAPIPort = *patch.XrayAPIPort
	}
	if patch.RealitySNI != nil {
		node.RealitySNI = *patch.RealitySNI
	}
	if patch.RealityDest != nil {
		node.RealityDest = *patch.RealityDest
	}
	if patch.RealitySpiderX != nil {
		node.RealitySpiderX = *patch.RealitySpiderX
	}
	if patch.RealityFingerprint != nil {
		node.RealityFingerprint = *patch.RealityFingerprint
	}
	if patch.RealityFlow != nil {
		node.RealityFlow = *patch.RealityFlow
	}
	if patch.Hy2Enabled != nil {
		node.Hy2Enabled = *patch.Hy2Enabled
	}
	if patch.Hy2Port != nil {
		node.Hy2Port = *patch.Hy2Port
	}
	if patch.Hy2SNI != nil {
		node.Hy2SNI = *patch.Hy2SNI
	}
	if patch.Hy2Insecure != nil {
		node.Hy2Insecure = *patch.Hy2Insecure
	}
	if patch.Hy2ObfsPassword != nil {
		node.Hy2ObfsPassword = *patch.Hy2ObfsPassword
	}
	if patch.Hy2UpMbps != nil {
		node.Hy2UpMbps = *patch.Hy2UpMbps
	}
	if patch.Hy2DownMbps != nil {
		node.Hy2DownMbps = *patch.Hy2DownMbps
	}
	if patch.Hy2CertPath != nil {
		node.Hy2CertPath = *patch.Hy2CertPath
	}
	if patch.Hy2KeyPath != nil {
		node.Hy2KeyPath = *patch.Hy2KeyPath
	}
	if patch.Hy2Masquerade != nil {
		node.Hy2Masquerade = *patch.Hy2Masquerade
	}
}

func (s *Store) DeleteNode(id int64) error {
	res, err := s.db.Exec(`DELETE FROM nodes WHERE id = ?`, id)
	if err != nil {
		return err
	}
	n, err := res.RowsAffected()
	if err != nil {
		return err
	}
	if n == 0 {
		return errs.New(404, "NOT_FOUND", "节点不存在")
	}
	return nil
}

func (s *Store) TouchNode(id int64, online bool) (Node, error) {
	seen := int64(0)
	if online {
		seen = time.Now().UnixMilli()
	}
	node, err := scanNode(s.db.QueryRow(
		`UPDATE nodes SET last_seen_at = ? WHERE id = ? RETURNING `+nodeCols, seen, id,
	))
	if err == sql.ErrNoRows {
		return Node{}, errs.New(404, "NOT_FOUND", "节点不存在")
	}
	return node, err
}

func (s *Store) CountNodes() (int64, error) {
	var n int64
	err := s.db.QueryRow(`SELECT COUNT(*) FROM nodes`).Scan(&n)
	return n, err
}
