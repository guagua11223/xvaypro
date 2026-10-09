package store

import "database/sql"

type Profile struct {
	UserID      int64
	DisplayName string
	Phone       string
	PlanID      int64
	AgentID     int64
	Device      string
	Platform    string
	Region      string
	LastLoginAt int64
	Demo        bool
}

type NodeMeta struct {
	NodeID     int64
	GroupID    int64
	CoreType   string
	Key        string
	LineType   string
	Latency    int
	LineStatus string
	URL        string
}

func (s *Store) SaveProfile(profile Profile) error {
	_, err := s.db.Exec(
		`INSERT INTO user_profiles (
			user_id, display_name, phone, plan_id, agent_id, device, platform, region, last_login_at, demo
		) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
		ON CONFLICT(user_id) DO UPDATE SET
			display_name = excluded.display_name,
			phone = excluded.phone,
			plan_id = excluded.plan_id,
			agent_id = excluded.agent_id,
			device = excluded.device,
			platform = excluded.platform,
			region = excluded.region,
			last_login_at = excluded.last_login_at,
			demo = excluded.demo`,
		profile.UserID, profile.DisplayName, profile.Phone, profile.PlanID, profile.AgentID,
		profile.Device, profile.Platform, profile.Region, profile.LastLoginAt, bit(profile.Demo),
	)
	return err
}

func (s *Store) FindProfile(userID int64) (Profile, bool, error) {
	var profile Profile
	var demo int
	err := s.db.QueryRow(
		`SELECT user_id, display_name, phone, plan_id, agent_id, device, platform, region, last_login_at, demo
		 FROM user_profiles WHERE user_id = ?`, userID,
	).Scan(
		&profile.UserID, &profile.DisplayName, &profile.Phone, &profile.PlanID, &profile.AgentID,
		&profile.Device, &profile.Platform, &profile.Region, &profile.LastLoginAt, &demo,
	)
	if err == sql.ErrNoRows {
		return Profile{}, false, nil
	}
	if err != nil {
		return Profile{}, false, err
	}
	profile.Demo = demo == 1
	return profile, true, nil
}

func (s *Store) ListProfiles() (map[int64]Profile, error) {
	rows, err := s.db.Query(
		`SELECT user_id, display_name, phone, plan_id, agent_id, device, platform, region, last_login_at, demo FROM user_profiles`,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := map[int64]Profile{}
	for rows.Next() {
		var profile Profile
		var demo int
		if err := rows.Scan(
			&profile.UserID, &profile.DisplayName, &profile.Phone, &profile.PlanID, &profile.AgentID,
			&profile.Device, &profile.Platform, &profile.Region, &profile.LastLoginAt, &demo,
		); err != nil {
			return nil, err
		}
		profile.Demo = demo == 1
		out[profile.UserID] = profile
	}
	return out, rows.Err()
}

func (s *Store) SaveNodeMeta(meta NodeMeta) error {
	_, err := s.db.Exec(
		`INSERT INTO node_meta (node_id, group_id, core_type, line_key, line_type, latency, line_status, url)
		 VALUES (?, ?, ?, ?, ?, ?, ?, ?)
		 ON CONFLICT(node_id) DO UPDATE SET
			group_id = excluded.group_id,
			core_type = excluded.core_type,
			line_key = excluded.line_key,
			line_type = excluded.line_type,
			latency = excluded.latency,
			line_status = excluded.line_status,
			url = excluded.url`,
		meta.NodeID, meta.GroupID, meta.CoreType, meta.Key, meta.LineType, meta.Latency, meta.LineStatus, meta.URL,
	)
	return err
}

func (s *Store) FindNodeMeta(nodeID int64) (NodeMeta, bool, error) {
	var meta NodeMeta
	err := s.db.QueryRow(
		`SELECT node_id, group_id, core_type, line_key, line_type, latency, line_status, url FROM node_meta WHERE node_id = ?`,
		nodeID,
	).Scan(&meta.NodeID, &meta.GroupID, &meta.CoreType, &meta.Key, &meta.LineType, &meta.Latency, &meta.LineStatus, &meta.URL)
	if err == sql.ErrNoRows {
		return NodeMeta{}, false, nil
	}
	if err != nil {
		return NodeMeta{}, false, err
	}
	return meta, true, nil
}

func (s *Store) ListNodeMeta() (map[int64]NodeMeta, error) {
	rows, err := s.db.Query(
		`SELECT node_id, group_id, core_type, line_key, line_type, latency, line_status, url FROM node_meta`,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := map[int64]NodeMeta{}
	for rows.Next() {
		var meta NodeMeta
		if err := rows.Scan(&meta.NodeID, &meta.GroupID, &meta.CoreType, &meta.Key, &meta.LineType, &meta.Latency, &meta.LineStatus, &meta.URL); err != nil {
			return nil, err
		}
		out[meta.NodeID] = meta
	}
	return out, rows.Err()
}

func (s *Store) SetCreatedAt(userID, createdAt int64) error {
	_, err := s.db.Exec(`UPDATE users SET created_at = ? WHERE id = ?`, createdAt, userID)
	return err
}

func (s *Store) KeepDemoOnline() error {
	future := nowMillis() + 365*24*3600*1000
	_, err := s.db.Exec(
		`UPDATE nodes SET last_seen_at = ?
		 WHERE remark = 'demo' AND id IN (SELECT node_id FROM node_meta WHERE line_status = 'online')`,
		future,
	)
	if err != nil {
		return err
	}
	_, err = s.db.Exec(
		`UPDATE nodes SET last_seen_at = 0
		 WHERE remark = 'demo' AND id IN (SELECT node_id FROM node_meta WHERE line_status != 'online')`,
	)
	return err
}

func (s *Store) ResetDemo() error {
	if _, err := s.db.Exec(`DELETE FROM users WHERE id IN (SELECT user_id FROM user_profiles WHERE demo = 1)`); err != nil {
		return err
	}
	if _, err := s.db.Exec(`DELETE FROM nodes WHERE remark = 'demo'`); err != nil {
		return err
	}
	if _, err := s.db.Exec(`DELETE FROM catalog`); err != nil {
		return err
	}
	if err := s.ClearAdminSessions(); err != nil {
		return err
	}
	if _, err := s.db.Exec(`DELETE FROM announcements`); err != nil {
		return err
	}
	_, err := s.db.Exec(`DELETE FROM settings WHERE key = 'demo_seeded'`)
	return err
}
