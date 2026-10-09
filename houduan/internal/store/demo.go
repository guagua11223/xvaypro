package store

import (
	"net/url"
	"time"

	"xvay/houduan/internal/auth"
	"xvay/houduan/internal/protocol"
)

const demoUserPassword = "Xv@y2026"

// SeedDemo fills an empty database with the same records the admin console used to keep locally.
// It is idempotent: a finished seed is marked and later startups leave existing rows alone.
func (s *Store) SeedDemo() error {
	settings, err := s.GetSettings()
	if err != nil {
		return err
	}
	if settings["demo_seeded"] == "1" {
		return nil
	}
	if err := s.seedDemoCatalog(); err != nil {
		return err
	}
	users, err := s.seedDemoUsers()
	if err != nil {
		return err
	}
	if err := s.seedDemoNodes(); err != nil {
		return err
	}
	if err := s.seedDemoCommissions(users); err != nil {
		return err
	}
	if err := s.seedDemoNotice(); err != nil {
		return err
	}
	if _, err := s.SetSettings(map[string]string{
		"profile_name":     "AnyPortal",
		"support_url":      "https://xvay.example/support",
		"support_wechat":   "feilian-support",
		"support_qq":       "800123456",
		"support_telegram": "https://t.me/feilian",
		"support_online":   "https://xvay.example/support",
		"support_qrcode":   "https://xvay.example/support/qr.png",
	}); err != nil {
		return err
	}
	if err := s.KeepDemoOnline(); err != nil {
		return err
	}
	_, err = s.db.Exec(
		`INSERT INTO settings (key, value) VALUES ('demo_seeded', '1')
		 ON CONFLICT(key) DO UPDATE SET value = excluded.value`,
	)
	return err
}

func (s *Store) seedDemoCatalog() error {
	hash, err := auth.HashPassword("admin123")
	if err != nil {
		return err
	}
	if err := s.ensureCatalog("admins", []map[string]any{
		{
			"id": int64(1), "username": "admin", "passwordHash": hash, "nickname": "超级管理员",
			"role": "super", "phone": "13800000000", "createdAt": agoISO(120),
		},
	}); err != nil {
		return err
	}
	if err := s.ensureCatalog("groups", []map[string]any{
		{"id": int64(1), "name": "默认", "type": "local", "protocol": "", "coreType": "xray", "autoUpdateInterval": 0, "url": "", "status": "enabled", "updatedAt": agoISO(2)},
		{"id": int64(2), "name": "亚洲高速", "type": "remote", "protocol": "anyportalRest", "coreType": "sing-box", "autoUpdateInterval": 60, "url": "https://api.xvay.example/groups/asia", "status": "enabled", "updatedAt": agoISO(1)},
		{"id": int64(3), "name": "全球通用", "type": "remote", "protocol": "generic", "coreType": "clash", "autoUpdateInterval": 360, "url": "https://sub.xvay.example/global.yaml", "status": "enabled", "updatedAt": agoISO(3)},
	}); err != nil {
		return err
	}
	if err := s.ensureCatalog("cores", []map[string]any{
		{"id": int64(1), "name": "v2ray", "version": "5.16.1", "enabled": true, "isExec": true, "workingDir": "", "updatedAt": agoISO(10)},
		{"id": int64(2), "name": "xray", "version": "1.8.24", "enabled": true, "isExec": true, "workingDir": "", "updatedAt": agoISO(4)},
		{"id": int64(3), "name": "sing-box", "version": "1.11.0", "enabled": true, "isExec": true, "workingDir": "", "updatedAt": agoISO(6)},
		{"id": int64(4), "name": "clash", "version": "1.18.0", "enabled": true, "isExec": true, "workingDir": "", "updatedAt": agoISO(20)},
		{"id": int64(5), "name": "hysteria2", "version": "2.6.0", "enabled": false, "isExec": true, "workingDir": "", "updatedAt": agoISO(15)},
		{"id": int64(6), "name": "naive", "version": "1.0.0", "enabled": false, "isExec": true, "workingDir": "", "updatedAt": agoISO(30)},
	}); err != nil {
		return err
	}
	if err := s.ensureCatalog("assets", []map[string]any{
		{"id": int64(1), "name": "geoip.dat", "type": "remote", "path": "assets/geoip.dat", "url": "github://v2fly/geoip/geoip.dat", "autoUpdateInterval": 1440, "updatedAt": agoISO(2)},
		{"id": int64(2), "name": "geosite.dat", "type": "remote", "path": "assets/geosite.dat", "url": "github://v2fly/domain-list-community/dlc.dat", "autoUpdateInterval": 1440, "updatedAt": agoISO(2)},
		{"id": int64(3), "name": "geoip.srs", "type": "remote", "path": "assets/geoip.srs", "url": "github://SagerNet/sing-geoip/geoip.srs", "autoUpdateInterval": 1440, "updatedAt": agoISO(5)},
		{"id": int64(4), "name": "geosite.srs", "type": "remote", "path": "assets/geosite.srs", "url": "github://SagerNet/sing-geosite/geosite.srs", "autoUpdateInterval": 1440, "updatedAt": agoISO(5)},
	}); err != nil {
		return err
	}
	if err := s.ensureCatalog("plans", []map[string]any{
		{"id": int64(1), "name": "月卡", "price": 30, "durationDays": 30, "trafficGB": 100, "deviceLimit": 2, "status": "on", "updatedAt": agoISO(8)},
		{"id": int64(2), "name": "季卡", "price": 78, "durationDays": 90, "trafficGB": 300, "deviceLimit": 3, "status": "on", "updatedAt": agoISO(8)},
		{"id": int64(3), "name": "年卡", "price": 258, "durationDays": 365, "trafficGB": 1500, "deviceLimit": 5, "status": "on", "updatedAt": agoISO(8)},
	}); err != nil {
		return err
	}
	if err := s.ensureCatalog("agents", []map[string]any{
		{"id": int64(1), "name": "华南总代", "username": "agent-hn", "phone": "13900001001", "level": "gold", "inviteCode": "飞连-HN", "parentId": nil, "balance": 154.8, "totalCommission": 154.8, "status": "active", "remark": "覆盖广东直营与下级站点", "createdAt": agoISO(200)},
		{"id": int64(2), "name": "华东渠道", "username": "agent-hd", "phone": "13900001002", "level": "gold", "inviteCode": "飞连-HD", "parentId": nil, "balance": 9, "totalCommission": 9, "status": "active", "remark": "上海、江苏渠道", "createdAt": agoISO(180)},
		{"id": int64(3), "name": "深圳站", "username": "agent-sz", "phone": "13900001003", "level": "silver", "inviteCode": "飞连-SZ", "parentId": int64(1), "balance": 0, "totalCommission": 0, "status": "active", "remark": "华南总代下级", "createdAt": agoISO(90)},
		{"id": int64(4), "name": "杭州站", "username": "agent-hz", "phone": "13900001004", "level": "bronze", "inviteCode": "飞连-HZ", "parentId": int64(2), "balance": 0, "totalCommission": 0, "status": "frozen", "remark": "结算资料待补充", "createdAt": agoISO(40)},
	}); err != nil {
		return err
	}
	if err := s.ensureCatalog("commissionRules", []map[string]any{
		{"id": int64(1), "level": "gold", "rate": 30, "minOrder": 30, "settleCycle": "weekly", "enabled": true},
		{"id": int64(2), "level": "silver", "rate": 20, "minOrder": 30, "settleCycle": "weekly", "enabled": true},
		{"id": int64(3), "level": "bronze", "rate": 12, "minOrder": 30, "settleCycle": "monthly", "enabled": true},
	}); err != nil {
		return err
	}
	_, ok, err := s.GetSingleton("appSettings")
	if err != nil {
		return err
	}
	if ok {
		return nil
	}
	_, err = s.PutSingleton("appSettings", defaultAppSettings())
	return err
}

func defaultAppSettings() map[string]any {
	return map[string]any{
		"appName": "AnyPortal", "version": "0.6.31",
		"localeFollowSystem": true, "locale": "zh",
		"autoUpdate": true, "connectAtStartup": false, "connectAtLaunch": false,
		"brightnessFollowSystem": true, "brightnessDark": false,
		"serverAddress": "127.0.0.1", "apiBase": "http://127.0.0.1:8787",
		"socksPort": 15491, "httpPort": 15492,
		"defaultMode": "fullSpeed", "systemProxy": false, "tun": false,
		"pingUrl": "http://www.gstatic.com/generate_204", "pingMaxConcurrency": 8,
		"announcement": "欢迎使用 飞连。线路、套餐与公告由总后台统一配置后下发到 App。",
		"supportUrl":   "https://xvay.example/support",
		"aboutText":    "AnyPortal 客户端，支持 V2Ray、Xray、sing-box、Clash、Hysteria2 与 Naive。",
		"profileName":  "AnyPortal",
	}
}

type demoUser struct {
	Name       string
	Email      string
	Phone      string
	Status     string
	PlanID     int64
	AgentID    int64
	UsedGB     float64
	TotalGB    float64
	Device     string
	Platform   string
	Region     string
	Registered float64
	LastLogin  float64
	ExpireDays float64
	Devices    int64
}

func (s *Store) seedDemoUsers() (map[string]int64, error) {
	rows := []demoUser{
		{"林晓", "linxiao@example.com", "13811110001", "active", 1, 3, 36.4, 100, "Pixel 8", "Android", "深圳", 20, 0.2, 10, 2},
		{"周宁", "zhouning@example.com", "13811110002", "active", 3, 1, 420, 1500, "iPhone 15", "iOS", "广州", 80, 0.5, 280, 5},
		{"陈可", "chenke@example.com", "13811110003", "active", 2, 4, 88, 300, "Windows PC", "Windows", "杭州", 40, 1, 50, 3},
		{"赵磊", "zhaolei@example.com", "13811110004", "expired", 1, 2, 97, 100, "MacBook", "macOS", "上海", 60, 12, -3, 2},
		{"孙琪", "sunqi@example.com", "13811110005", "disabled", 3, 1, 12, 1500, "iPad", "iOS", "广州", 15, 9, 340, 5},
		{"吴迪", "wudi@example.com", "13811110006", "active", 2, 3, 140, 300, "Mac mini", "macOS", "东莞", 25, 0.1, 65, 3},
		{"郑爽", "zhengshuang@example.com", "13811110007", "active", 1, 0, 18, 100, "Xiaomi 14", "Android", "北京", 6, 0.4, 24, 2},
		{"何俊", "hejun@example.com", "13811110008", "active", 3, 2, 260, 1500, "iPhone 16", "iOS", "南京", 100, 2, 200, 5},
	}
	ids := map[string]int64{}
	for _, row := range rows {
		existing, ok, err := s.FindUserByEmail(row.Email)
		if err != nil {
			return nil, err
		}
		if ok {
			ids[row.Email] = existing.ID
			continue
		}
		user, err := s.CreateUser(UserInput{
			Email: row.Email, Nickname: row.Name, Password: demoUserPassword,
			Total: gbBytes(row.TotalGB), ExpireAt: futureMs(row.ExpireDays),
			Status: row.Status, DeviceLimit: row.Devices,
		})
		if err != nil {
			return nil, err
		}
		download := gbBytes(row.UsedGB)
		if _, err := s.UpdateUser(user.ID, UserPatch{Download: &download}); err != nil {
			return nil, err
		}
		if err := s.SetCreatedAt(user.ID, agoMs(row.Registered)); err != nil {
			return nil, err
		}
		if err := s.SaveProfile(Profile{
			UserID: user.ID, DisplayName: row.Name, Phone: row.Phone,
			PlanID: row.PlanID, AgentID: row.AgentID, Device: row.Device,
			Platform: row.Platform, Region: row.Region, LastLoginAt: agoMs(row.LastLogin), Demo: true,
		}); err != nil {
			return nil, err
		}
		ids[row.Email] = user.ID
	}
	return ids, nil
}

type demoNode struct {
	Name     string
	Key      string
	Region   string
	Country  string
	URL      string
	Core     string
	LineType string
	Status   string
	GroupID  int64
	Latency  int
}

func (s *Store) seedDemoNodes() error {
	var count int
	if err := s.db.QueryRow(`SELECT COUNT(*) FROM nodes WHERE remark = 'demo'`).Scan(&count); err != nil {
		return err
	}
	if count > 0 {
		return nil
	}
	rows := []demoNode{
		{"香港 01", "hk-01", "香港", "HK", "vless://hk-01.xvay.example:443", "xray", "remote", "online", 2, 38},
		{"东京 01", "jp-tyo-01", "日本东京", "JP", "vless://tyo-01.xvay.example:443", "sing-box", "remote", "online", 2, 62},
		{"新加坡 01", "sg-01", "新加坡", "SG", "vless://sg-01.xvay.example:443", "xray", "remote", "online", 2, 71},
		{"洛杉矶 01", "us-lax-01", "美国洛杉矶", "US", "https://sub.xvay.example/nodes/lax", "clash", "remote", "maintain", 3, 168},
		{"首尔 01", "kr-sel-01", "韩国首尔", "KR", "hysteria2://sel-01.xvay.example:443", "hysteria2", "remote", "online", 2, 54},
		{"本地调试", "local-dev", "本地", "CN", "", "v2ray", "local", "offline", 1, 0},
	}
	for i, row := range rows {
		shortID, err := protocol.GenerateShortID()
		if err != nil {
			return err
		}
		host := hostOf(row.URL)
		if host == "" {
			host = "127.0.0.1"
		}
		node, err := s.CreateNode(NodeInput{
			Name: row.Name, Region: row.Region, CountryCode: row.Country, Host: host,
			SortOrder: int64(i), Enabled: row.Status != "offline", Remark: "demo",
			XrayEnabled: row.Core != "hysteria2", XrayPort: 24000 + i, XrayAPIPort: 25000 + i,
			RealityShortIDs: []string{shortID},
			RealitySNI:      "www.microsoft.com", RealityDest: "www.microsoft.com:443",
			RealitySpiderX: "/", RealityFingerprint: "chrome", RealityFlow: "xtls-rprx-vision",
			Hy2Enabled: row.LineType == "remote", Hy2Port: 26000 + i, Hy2SNI: "www.microsoft.com", Hy2Insecure: true,
			Hy2UpMbps: 100, Hy2DownMbps: 100,
		})
		if err != nil {
			return err
		}
		if err := s.SaveNodeMeta(NodeMeta{
			NodeID: node.ID, GroupID: row.GroupID, CoreType: row.Core, Key: row.Key,
			LineType: row.LineType, Latency: row.Latency, LineStatus: row.Status, URL: row.URL,
		}); err != nil {
			return err
		}
	}
	return nil
}

type demoCommission struct {
	Email      string
	AgentID    int64
	OrderNo    string
	Amount     float64
	Rate       float64
	Commission float64
	Status     string
	Created    float64
	Settled    float64
	Remark     string
}

func (s *Store) seedDemoCommissions(users map[string]int64) error {
	existing, err := s.ListCatalog("commissions")
	if err != nil {
		return err
	}
	if len(existing) > 0 {
		return nil
	}
	rows := []demoCommission{
		{"linxiao@example.com", 3, "XV20261001001", 30, 20, 6, "pending", 2, 0, "月卡续费"},
		{"zhouning@example.com", 1, "XV20260912008", 258, 30, 77.4, "settled", 27, 20, "年卡"},
		{"chenke@example.com", 4, "XV20261003012", 78, 12, 9.36, "pending", 1, 0, "季卡"},
		{"zhaolei@example.com", 2, "XV20260820003", 30, 30, 9, "settled", 50, 43, "月卡"},
		{"sunqi@example.com", 1, "XV20260928019", 258, 30, 77.4, "settled", 11, 7, "年卡"},
		{"wudi@example.com", 3, "XV20261006021", 78, 20, 15.6, "pending", 0.6, 0, "季卡"},
		{"hejun@example.com", 2, "XV20261007030", 258, 30, 77.4, "pending", 0.3, 0, "年卡续费"},
	}
	for i, row := range rows {
		settled := ""
		if row.Settled > 0 {
			settled = agoISO(row.Settled)
		}
		if _, err := s.InsertCatalog("commissions", map[string]any{
			"id": int64(i + 1), "agentId": row.AgentID, "userId": users[row.Email],
			"orderNo": row.OrderNo, "orderAmount": row.Amount, "rate": row.Rate,
			"commission": row.Commission, "status": row.Status,
			"createdAt": agoISO(row.Created), "settledAt": settled, "remark": row.Remark,
		}); err != nil {
			return err
		}
	}
	return nil
}

func (s *Store) seedDemoNotice() error {
	var count int
	if err := s.db.QueryRow(`SELECT COUNT(*) FROM announcements`).Scan(&count); err != nil {
		return err
	}
	if count > 0 {
		return nil
	}
	_, err := s.CreateAnnouncement("飞连", "欢迎使用 飞连。线路、套餐与公告由总后台统一配置后下发到 App。", true)
	return err
}

func (s *Store) ensureCatalog(kind string, rows []map[string]any) error {
	existing, err := s.ListCatalog(kind)
	if err != nil {
		return err
	}
	if len(existing) > 0 {
		return nil
	}
	for _, row := range rows {
		if _, err := s.InsertCatalog(kind, row); err != nil {
			return err
		}
	}
	return nil
}

func agoISO(days float64) string {
	return time.Now().Add(-time.Duration(days * float64(24*time.Hour))).UTC().Format(time.RFC3339)
}

func agoMs(days float64) int64 {
	return time.Now().Add(-time.Duration(days * float64(24*time.Hour))).UnixMilli()
}

func futureMs(days float64) int64 {
	return time.Now().Add(time.Duration(days * float64(24*time.Hour))).UnixMilli()
}

func gbBytes(gb float64) int64 {
	return int64(gb * 1024 * 1024 * 1024)
}

func hostOf(raw string) string {
	if raw == "" {
		return ""
	}
	parsed, err := url.Parse(raw)
	if err != nil || parsed.Hostname() == "" {
		return raw
	}
	return parsed.Hostname()
}
