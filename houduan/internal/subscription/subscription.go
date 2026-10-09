package subscription

import (
	"encoding/base64"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"xvay/houduan/internal/access"
	"xvay/houduan/internal/config"
	"xvay/houduan/internal/errs"
	"xvay/houduan/internal/protocol"
	"xvay/houduan/internal/store"
)

func URL(cfg config.Config, user store.User) string {
	return cfg.PublicBaseURL + "/api/sub/" + user.SubToken
}

func Build(db *store.Store, cfg config.Config, user store.User) (map[string]any, error) {
	if err := assertAccess(user); err != nil {
		return nil, err
	}
	settings, err := db.GetSettings()
	if err != nil {
		return nil, err
	}
	nodes, err := enabledNodes(db)
	if err != nil {
		return nil, err
	}
	profiles := []any{}
	for _, node := range nodes {
		view := protocolNode(node)
		account := protocolUser(user)
		if node.XrayEnabled {
			profiles = append(profiles, map[string]any{
				"name":       node.Name + " · Reality",
				"key":        "n" + strconv.FormatInt(node.ID, 10) + "-reality",
				"coreType":   "xray",
				"format":     "json",
				"coreConfig": protocol.BuildXrayClient(view, account),
			})
		}
		if node.Hy2Enabled {
			profiles = append(profiles, map[string]any{
				"name":       node.Name + " · Hysteria2",
				"key":        "n" + strconv.FormatInt(node.ID, 10) + "-hysteria2",
				"coreType":   "hysteria2",
				"format":     "json",
				"coreConfig": protocol.BuildHysteriaClient(view, account),
			})
		}
	}
	name := settings["profile_name"]
	if name == "" {
		name = "飞连"
	}
	interval, _ := strconv.Atoi(settings["auto_update_interval"])
	if interval == 0 {
		interval = 86400
	}
	document := map[string]any{
		"version":              1.2,
		"name":                 name,
		"autoUpdateInterval":   interval,
		"profiles":             profiles,
		"subscriptionUserInfo": UserInfo(user),
	}
	if settings["support_url"] != "" {
		document["supportUrl"] = settings["support_url"]
	}
	if settings["profile_web_page_url"] != "" {
		document["profileWebPageUrl"] = settings["profile_web_page_url"]
	}
	return document, nil
}

func BuildV2ray(db *store.Store, user store.User) (string, error) {
	if err := assertAccess(user); err != nil {
		return "", err
	}
	settings, err := db.GetSettings()
	if err != nil {
		return "", err
	}
	nodes, err := enabledNodes(db)
	if err != nil {
		return "", err
	}
	name := settings["profile_name"]
	if name == "" {
		name = "飞连"
	}
	interval, _ := strconv.Atoi(settings["auto_update_interval"])
	if interval == 0 {
		interval = 86400
	}
	lines := []string{
		"#profile-title: base64:" + base64.StdEncoding.EncodeToString([]byte(name)),
		"#profile-update-interval: " + strconv.Itoa(interval),
		"#subscription-userinfo: " + UserInfoHeader(user),
	}
	if settings["support_url"] != "" {
		lines = append(lines, "#support-url: "+settings["support_url"])
	}
	if settings["profile_web_page_url"] != "" {
		lines = append(lines, "#profile-web-page-url: "+settings["profile_web_page_url"])
	}
	for _, node := range nodes {
		view := protocolNode(node)
		account := protocolUser(user)
		if node.XrayEnabled {
			lines = append(lines, protocol.BuildVlessLink(view, account))
		}
		if node.Hy2Enabled {
			lines = append(lines, protocol.BuildHysteriaLink(view, account))
		}
	}
	return strings.Join(lines, "\n") + "\n", nil
}

type Bundle struct {
	Xray      any  `json:"xray"`
	Hysteria2 any  `json:"hysteria2"`
	Meta      Meta `json:"meta"`
}

type Meta struct {
	NodeID              int64  `json:"nodeId"`
	Name                string `json:"name"`
	Host                string `json:"host"`
	XrayAPI             string `json:"xrayApi"`
	HysteriaStats       string `json:"hysteriaStats"`
	HysteriaStatsSecret string `json:"hysteriaStatsSecret"`
	Cert                string `json:"cert"`
	Key                 string `json:"key"`
	CertCommand         string `json:"certCommand"`
	XrayCommand         string `json:"xrayCommand"`
	HysteriaCommand     string `json:"hysteriaCommand"`
}

func NodeBundle(db *store.Store, cfg config.Config, node store.Node) (Bundle, error) {
	users, err := db.ListEligibleUsers(time.Now().UnixMilli())
	if err != nil {
		return Bundle{}, err
	}
	accounts := make([]protocol.User, len(users))
	for i, user := range users {
		accounts[i] = protocolUser(user)
	}
	paths := HysteriaPaths(cfg, node)
	view := protocolNode(node)
	bundle := Bundle{
		Meta: Meta{
			NodeID:              node.ID,
			Name:                node.Name,
			Host:                node.Host,
			XrayAPI:             "127.0.0.1:" + strconv.Itoa(node.XrayAPIPort),
			HysteriaStats:       "http://" + protocol.Hy2StatsListen(node.ID),
			HysteriaStatsSecret: node.Hy2StatsSecret,
			Cert:                paths.Cert,
			Key:                 paths.Key,
			CertCommand:         opensslCommand(paths, node.Hy2SNI),
			XrayCommand:         "xray run -c xray.json",
			HysteriaCommand:     "hysteria server -c hysteria2.json",
		},
	}
	if node.XrayEnabled {
		bundle.Xray = protocol.BuildXrayServer(view, accounts)
	}
	if node.Hy2Enabled {
		bundle.Hysteria2 = protocol.BuildHysteriaServer(view, accounts, paths)
	}
	return bundle, nil
}

func HysteriaPaths(cfg config.Config, node store.Node) protocol.Hy2Paths {
	base := filepath.Join(cfg.DataDir, "nodes", strconv.FormatInt(node.ID, 10))
	cert := node.Hy2CertPath
	if cert == "" {
		cert = filepath.Join(base, "hy2.crt")
	}
	key := node.Hy2KeyPath
	if key == "" {
		key = filepath.Join(base, "hy2.key")
	}
	return protocol.Hy2Paths{Cert: cert, Key: key}
}

func UserInfo(user store.User) map[string]any {
	expire := int64(0)
	if user.ExpireAt != 0 {
		expire = user.ExpireAt / 1000
	}
	return map[string]any{
		"upload":   user.Upload,
		"download": user.Download,
		"total":    user.Total,
		"expire":   expire,
	}
}

func UserInfoHeader(user store.User) string {
	info := UserInfo(user)
	return "upload=" + strconv.FormatInt(info["upload"].(int64), 10) +
		"; download=" + strconv.FormatInt(info["download"].(int64), 10) +
		"; total=" + strconv.FormatInt(info["total"].(int64), 10) +
		"; expire=" + strconv.FormatInt(info["expire"].(int64), 10)
}

func assertAccess(user store.User) error {
	state := access.StateOf(user.Status, user.ExpireAt, user.Upload, user.Download, user.Total, time.Now())
	if !state.OK {
		return errs.New(state.Status, state.Code, state.Message)
	}
	return nil
}

func enabledNodes(db *store.Store) ([]store.Node, error) {
	nodes, err := db.ListNodes()
	if err != nil {
		return nil, err
	}
	out := make([]store.Node, 0, len(nodes))
	for _, node := range nodes {
		if node.Enabled && (node.XrayEnabled || node.Hy2Enabled) {
			out = append(out, node)
		}
	}
	return out, nil
}

func protocolNode(node store.Node) protocol.Node {
	return protocol.Node{
		ID: node.ID, Name: node.Name, Host: node.Host,
		XrayPort: node.XrayPort, XrayAPIPort: node.XrayAPIPort,
		RealityPrivateKey: node.RealityPrivateKey, RealityPublicKey: node.RealityPublicKey,
		RealityShortIDs: node.RealityShortIDs, RealitySNI: node.RealitySNI, RealityDest: node.RealityDest,
		RealitySpiderX: node.RealitySpiderX, RealityFingerprint: node.RealityFingerprint, RealityFlow: node.RealityFlow,
		Hy2Port: node.Hy2Port, Hy2SNI: node.Hy2SNI, Hy2Insecure: node.Hy2Insecure, Hy2ObfsPassword: node.Hy2ObfsPassword,
		Hy2UpMbps: node.Hy2UpMbps, Hy2DownMbps: node.Hy2DownMbps, Hy2Masquerade: node.Hy2Masquerade, Hy2StatsSecret: node.Hy2StatsSecret,
	}
}

func protocolUser(user store.User) protocol.User {
	return protocol.User{ID: user.ID, UUID: user.UUID, Hy2Password: user.Hy2Password}
}

func opensslCommand(paths protocol.Hy2Paths, sni string) string {
	return "openssl req -x509 -nodes -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -keyout " +
		shellQuote(paths.Key) + " -out " + shellQuote(paths.Cert) + " -subj /CN=" + sni + " -days 3650"
}

func shellQuote(value string) string {
	return "'" + strings.ReplaceAll(value, "'", `'\''`) + "'"
}
