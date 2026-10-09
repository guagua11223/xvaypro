package api

import (
	"strconv"
	"time"

	"xvay/houduan/internal/access"
	"xvay/houduan/internal/config"
	"xvay/houduan/internal/protocol"
	"xvay/houduan/internal/store"
	"xvay/houduan/internal/subscription"
)

type AccessView struct {
	OK      bool   `json:"ok"`
	Code    string `json:"code"`
	Message string `json:"message"`
}

type AppUser struct {
	ID                   int64        `json:"id"`
	IDText               string       `json:"idText"`
	Username             string       `json:"username"`
	Nickname             string       `json:"nickname"`
	Avatar               string       `json:"avatar"`
	UserType             string       `json:"userType"`
	UserTypeLabel        string       `json:"userTypeLabel"`
	Email                string       `json:"email"`
	EmailBound           bool         `json:"emailBound"`
	BindEmailReminder    bool         `json:"bindEmailReminder"`
	BindEmailMessage     string       `json:"bindEmailMessage,omitempty"`
	IsDistributor        int          `json:"isDistributor"`
	IsAgent              int          `json:"isAgent"`
	CommissionMode       int          `json:"commissionMode"`
	WalletEnabled        int          `json:"walletEnabled"`
	CanAuthorizeAgent    int          `json:"canAuthorizeAgent"`
	EmailStatus          int          `json:"emailStatus"`
	InviteCode           string       `json:"inviteCode,omitempty"`
	Service              *ServiceView `json:"service,omitempty"`
	UUID                 string       `json:"uuid"`
	Status               string       `json:"status"`
	Upload               int64        `json:"upload"`
	Download             int64        `json:"download"`
	Total                int64        `json:"total"`
	ExpireAt             int64        `json:"expireAt"`
	DeviceLimit          int64        `json:"deviceLimit"`
	SubscriptionURL      string       `json:"subscriptionUrl"`
	SubscriptionProtocol string       `json:"subscriptionProtocol"`
	Access               AccessView   `json:"access"`
}

type AdminUser struct {
	AppUser
	Hy2Password string `json:"hy2Password"`
	SubToken    string `json:"subToken"`
	CreatedAt   int64  `json:"createdAt"`
	DisplayName string `json:"displayName,omitempty"`
	Phone       string `json:"phone,omitempty"`
	PlanID      int64  `json:"planId,omitempty"`
	AgentID     int64  `json:"agentId,omitempty"`
	Device      string `json:"device,omitempty"`
	Platform    string `json:"platform,omitempty"`
	Region      string `json:"region,omitempty"`
	LastLoginAt int64  `json:"lastLoginAt,omitempty"`
}

type PublicNode struct {
	ID          int64    `json:"id"`
	Name        string   `json:"name"`
	Region      string   `json:"region"`
	CountryCode string   `json:"countryCode"`
	Host        string   `json:"host"`
	Protocols   []string `json:"protocols"`
	Online      bool     `json:"online"`
}

type XrayView struct {
	Enabled     bool     `json:"enabled"`
	Port        int      `json:"port"`
	APIPort     int      `json:"apiPort"`
	PrivateKey  string   `json:"privateKey"`
	PublicKey   string   `json:"publicKey"`
	ShortIDs    []string `json:"shortIds"`
	SNI         string   `json:"sni"`
	Dest        string   `json:"dest"`
	SpiderX     string   `json:"spiderX"`
	Fingerprint string   `json:"fingerprint"`
	Flow        string   `json:"flow"`
}

type Hy2View struct {
	Enabled      bool   `json:"enabled"`
	Port         int    `json:"port"`
	SNI          string `json:"sni"`
	Insecure     bool   `json:"insecure"`
	ObfsPassword string `json:"obfsPassword"`
	UpMbps       int    `json:"upMbps"`
	DownMbps     int    `json:"downMbps"`
	CertPath     string `json:"certPath"`
	KeyPath      string `json:"keyPath"`
	Masquerade   string `json:"masquerade"`
	StatsSecret  string `json:"statsSecret"`
}

type AdminNode struct {
	PublicNode
	Enabled    bool     `json:"enabled"`
	SortOrder  int64    `json:"sortOrder"`
	Remark     string   `json:"remark"`
	Secret     string   `json:"secret"`
	LastSeenAt int64    `json:"lastSeenAt"`
	Xray       XrayView `json:"xray"`
	Hysteria2  Hy2View  `json:"hysteria2"`
	GroupID    int64    `json:"groupId,omitempty"`
	CoreType   string   `json:"coreType,omitempty"`
	Key        string   `json:"key,omitempty"`
	LineType   string   `json:"lineType,omitempty"`
	Latency    int      `json:"latency,omitempty"`
	LineStatus string   `json:"lineStatus,omitempty"`
	URL        string   `json:"url,omitempty"`
}

type ServiceView struct {
	TotalBytes     int64  `json:"totalBytes"`
	UsedBytes      int64  `json:"usedBytes"`
	RemainingBytes int64  `json:"remainingBytes"`
	ExpireAt       int64  `json:"expireAt"`
	RemainingMs    int64  `json:"remainingMs"`
	ExpiringSoon   bool   `json:"expiringSoon"`
	Expired        bool   `json:"expired"`
	RemindMessage  string `json:"remindMessage,omitempty"`
}

type PublicAnnouncement struct {
	ID         int64  `json:"id"`
	Title      string `json:"title"`
	Body       string `json:"body"`
	CreatedAt  int64  `json:"createdAt"`
	Historical bool   `json:"historical"`
}

type SettingsView struct {
	ProfileName           string `json:"profileName"`
	SupportURL            string `json:"supportUrl"`
	ProfileWebPageURL     string `json:"profileWebPageUrl"`
	AutoUpdateInterval    int64  `json:"autoUpdateInterval"`
	TrialBytes            int64  `json:"trialBytes"`
	TrialDays             int64  `json:"trialDays"`
	SupportWechat         string `json:"supportWechat"`
	SupportQQ             string `json:"supportQq"`
	SupportTelegram       string `json:"supportTelegram"`
	SupportOnline         string `json:"supportOnline"`
	SupportQrcode         string `json:"supportQrcode"`
	CommissionPoolPercent int64  `json:"commissionPoolPercent"`
	CommissionSettleDay   int64  `json:"commissionSettleDay"`
	WithdrawFeePercent    int64  `json:"withdrawFeePercent"`
	WithdrawMinCents      int64  `json:"withdrawMinCents"`
	ExpireRemindDays      int64  `json:"expireRemindDays"`
}

func appUser(user store.User, cfg config.Config) AppUser {
	state := access.StateOf(user.Status, user.ExpireAt, user.Upload, user.Download, user.Total, time.Now())
	bound := user.Email != ""
	message := ""
	if !bound {
		message = "当前账号未绑定邮箱，账号丢失后将无法找回。请前往账号安全完成绑定。"
	}
	return AppUser{
		ID: user.ID, IDText: strconv.FormatInt(user.ID, 10),
		Username: user.Username, Nickname: user.Nickname, Avatar: user.Avatar,
		UserType: user.UserType, UserTypeLabel: userTypeLabel(user.UserType),
		Email: user.Email, EmailBound: bound, BindEmailReminder: !bound, BindEmailMessage: message,
		IsDistributor: user.IsDistributor, IsAgent: user.IsAgent, CommissionMode: user.CommissionMode,
		WalletEnabled: user.WalletEnabled, CanAuthorizeAgent: user.CanAuthorizeAgent,
		EmailStatus: user.EmailStatus, InviteCode: user.InviteCode,
		UUID: user.UUID, Status: user.Status,
		Upload: user.Upload, Download: user.Download, Total: user.Total,
		ExpireAt: user.ExpireAt, DeviceLimit: user.DeviceLimit,
		SubscriptionURL: subscription.URL(cfg, user), SubscriptionProtocol: "anyportal-rest",
		Access: AccessView{OK: state.OK, Code: state.Code, Message: state.Message},
	}
}

func userTypeLabel(userType string) string {
	switch userType {
	case "agent":
		return "代理"
	case "dealer":
		return "经销商"
	default:
		return "普通会员"
	}
}

func adminUser(user store.User, cfg config.Config) AdminUser {
	return AdminUser{
		AppUser:     appUser(user, cfg),
		Hy2Password: user.Hy2Password,
		SubToken:    user.SubToken,
		CreatedAt:   user.CreatedAt,
	}
}

func publicNode(node store.Node, now, offlineMs int64) PublicNode {
	protocols := []string{}
	if node.XrayEnabled {
		protocols = append(protocols, "reality")
	}
	if node.Hy2Enabled {
		protocols = append(protocols, "hysteria2")
	}
	return PublicNode{
		ID: node.ID, Name: node.Name, Region: node.Region, CountryCode: node.CountryCode, Host: node.Host,
		Protocols: protocols,
		Online:    node.LastSeenAt > 0 && now-node.LastSeenAt <= offlineMs,
	}
}

func adminNode(node store.Node, now, offlineMs int64) AdminNode {
	return AdminNode{
		PublicNode: publicNode(node, now, offlineMs),
		Enabled:    node.Enabled,
		SortOrder:  node.SortOrder,
		Remark:     node.Remark,
		Secret:     node.Secret,
		LastSeenAt: node.LastSeenAt,
		Xray: XrayView{
			Enabled: node.XrayEnabled, Port: node.XrayPort, APIPort: node.XrayAPIPort,
			PrivateKey: node.RealityPrivateKey, PublicKey: node.RealityPublicKey,
			ShortIDs: protocol.ParseShortIDs(node.RealityShortIDs),
			SNI:      node.RealitySNI, Dest: node.RealityDest, SpiderX: node.RealitySpiderX,
			Fingerprint: node.RealityFingerprint, Flow: node.RealityFlow,
		},
		Hysteria2: Hy2View{
			Enabled: node.Hy2Enabled, Port: node.Hy2Port, SNI: node.Hy2SNI, Insecure: node.Hy2Insecure,
			ObfsPassword: node.Hy2ObfsPassword, UpMbps: node.Hy2UpMbps, DownMbps: node.Hy2DownMbps,
			CertPath: node.Hy2CertPath, KeyPath: node.Hy2KeyPath, Masquerade: node.Hy2Masquerade,
			StatsSecret: node.Hy2StatsSecret,
		},
	}
}

func publicAnnouncement(row store.Announcement) PublicAnnouncement {
	return PublicAnnouncement{
		ID: row.ID, Title: row.Title, Body: row.Body, CreatedAt: row.CreatedAt,
		Historical: row.Enabled == 0,
	}
}

func settingsView(settings map[string]string) SettingsView {
	interval, _ := parseSetting(settings["auto_update_interval"])
	trialBytes, _ := parseSetting(settings["trial_bytes"])
	trialDays, _ := parseSetting(settings["trial_days"])
	return SettingsView{
		ProfileName: settings["profile_name"], SupportURL: settings["support_url"],
		ProfileWebPageURL:  settings["profile_web_page_url"],
		AutoUpdateInterval: interval, TrialBytes: trialBytes, TrialDays: trialDays,
		SupportWechat: settings["support_wechat"], SupportQQ: settings["support_qq"],
		SupportTelegram: settings["support_telegram"], SupportOnline: settings["support_online"],
		SupportQrcode:         settings["support_qrcode"],
		CommissionPoolPercent: settingOr(settings["commission_pool_percent"], 50),
		CommissionSettleDay:   settingOr(settings["commission_settle_day"], 1),
		WithdrawFeePercent:    settingOr(settings["withdraw_fee_percent"], 0),
		WithdrawMinCents:      settingOr(settings["withdraw_min_cents"], 10000),
		ExpireRemindDays:      settingOr(settings["expire_remind_days"], 3),
	}
}

func settingOr(raw string, fallback int64) int64 {
	if raw == "" {
		return fallback
	}
	n, err := strconv.ParseInt(raw, 10, 64)
	if err != nil {
		return fallback
	}
	return n
}

func parseSetting(value string) (int64, error) {
	if value == "" {
		return 0, nil
	}
	n := int64(0)
	for _, c := range value {
		if c < '0' || c > '9' {
			return 0, strconvErr
		}
		n = n*10 + int64(c-'0')
	}
	return n, nil
}

var strconvErr = errString("bad number")

type errString string

func (e errString) Error() string { return string(e) }
