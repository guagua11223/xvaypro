package validate

import (
	"encoding/json"
	"math"
	"regexp"
	"strconv"
	"strings"
	"time"

	"xvay/houduan/internal/errs"
	"xvay/houduan/internal/protocol"
	"xvay/houduan/internal/store"
)

var (
	emailPattern = regexp.MustCompile(`^[^\s@]+@[^\s@]+\.[^\s@]+$`)
	flows        = map[string]bool{"": true, "xtls-rprx-vision": true, "xtls-rprx-vision-udp443": true}
	statuses     = map[string]bool{"active": true, "disabled": true, "expired": true}
)

func ParseEmail(value any) (string, error) {
	email := strings.ToLower(strings.TrimSpace(asString(value)))
	if !emailPattern.MatchString(email) || len(email) > 254 {
		return "", errs.New(400, "VALIDATION", "邮箱格式不正确")
	}
	return email, nil
}

func ParsePassword(value any) (string, error) {
	password, ok := value.(string)
	if !ok {
		password = ""
	}
	if len(password) < 8 || len(password) > 128 {
		return "", errs.New(400, "VALIDATION", "密码长度需要在 8 到 128 之间")
	}
	return password, nil
}

func ParseTime(value any) (int64, error) {
	if value == nil || value == "" {
		return 0, nil
	}
	if n, ok, err := number(value); ok {
		if err != nil || n < 0 {
			return 0, errs.New(400, "VALIDATION", "时间不正确")
		}
		if n == 0 {
			return 0, nil
		}
		if n < 1e12 {
			return n * 1000, nil
		}
		return n, nil
	}
	text := asString(value)
	if text == "" {
		return 0, errs.New(400, "VALIDATION", "时间不正确")
	}
	for _, layout := range []string{time.RFC3339, "2006-01-02", "2006-01-02 15:04:05", "2006-01-02T15:04:05"} {
		if parsed, err := time.Parse(layout, text); err == nil {
			return parsed.UnixMilli(), nil
		}
	}
	return 0, errs.New(400, "VALIDATION", "时间不正确")
}

func ParseBytes(value any, fallback *int64) (int64, error) {
	if value == nil {
		if fallback != nil {
			return *fallback, nil
		}
		return 0, errs.New(400, "VALIDATION", "流量数值不正确")
	}
	n, ok, err := number(value)
	if !ok || err != nil || n < 0 {
		return 0, errs.New(400, "VALIDATION", "流量数值不正确")
	}
	return n, nil
}

func ParseStatus(value any) (string, error) {
	status := asString(value)
	if !statuses[status] {
		return "", errs.New(400, "VALIDATION", "状态只能是 active、disabled 或 expired")
	}
	return status, nil
}

func TrialExpireAt(settings map[string]string, now time.Time) int64 {
	days, err := strconv.ParseInt(settings["trial_days"], 10, 64)
	if err != nil || days <= 0 {
		return 0
	}
	return now.UnixMilli() + days*24*3600*1000
}

func NodeCreateInput(body map[string]any) (store.NodeInput, error) {
	input, err := readNode(body, false)
	if err != nil {
		return store.NodeInput{}, err
	}
	if strings.TrimSpace(input.Name) == "" {
		return store.NodeInput{}, errs.New(400, "VALIDATION", "节点名称不能为空")
	}
	if strings.TrimSpace(input.Host) == "" {
		return store.NodeInput{}, errs.New(400, "VALIDATION", "节点地址不能为空")
	}
	sni := input.RealitySNI
	if sni == "" {
		sni = "www.microsoft.com"
	}
	created := store.NodeInput{
		Name: input.Name, Region: input.Region, CountryCode: input.CountryCode, Host: input.Host,
		SortOrder: derefInt64(input.SortOrder, 0), Enabled: derefBool(input.Enabled, true), Remark: input.Remark,
		XrayEnabled: derefBool(input.XrayEnabled, true), XrayPort: derefInt(input.XrayPort, 443), XrayAPIPort: derefInt(input.XrayAPIPort, 10085),
		RealitySNI: sni, RealityDest: orString(input.RealityDest, sni+":443"),
		RealitySpiderX: orStringPtr(input.RealitySpiderX, "/"), RealityFingerprint: orString(input.RealityFingerprint, "chrome"),
		RealityFlow: orStringPtr(input.RealityFlow, "xtls-rprx-vision"),
		Hy2Enabled:  derefBool(input.Hy2Enabled, true), Hy2Port: derefInt(input.Hy2Port, 8443),
		Hy2SNI: orString(input.Hy2SNI, sni), Hy2Insecure: derefBool(input.Hy2Insecure, false),
		Hy2ObfsPassword: input.Hy2ObfsPassword, Hy2UpMbps: derefInt(input.Hy2UpMbps, 100), Hy2DownMbps: derefInt(input.Hy2DownMbps, 100),
		Hy2CertPath: input.Hy2CertPath, Hy2KeyPath: input.Hy2KeyPath, Hy2Masquerade: input.Hy2Masquerade,
	}
	if input.RealityShortIDs != nil {
		created.RealityShortIDs = input.RealityShortIDs
	} else {
		shortID, err := protocol.GenerateShortID()
		if err != nil {
			return store.NodeInput{}, err
		}
		created.RealityShortIDs = []string{shortID}
	}
	if input.RealityPrivateKey != nil {
		created.RealityPrivateKey = *input.RealityPrivateKey
	}
	if input.RealityPublicKey != nil {
		created.RealityPublicKey = *input.RealityPublicKey
	}
	if err := assertPorts(created.XrayPort, created.XrayAPIPort, created.Hy2Port); err != nil {
		return store.NodeInput{}, err
	}
	if err := assertRealityKeys(&created.RealityPrivateKey, &created.RealityPublicKey); err != nil {
		return store.NodeInput{}, err
	}
	return created, nil
}

func NodePatchInput(body map[string]any) (store.NodePatch, error) {
	read, err := readNode(body, true)
	if err != nil {
		return store.NodePatch{}, err
	}
	patch := store.NodePatch{
		Name: read.NamePtr, Region: read.RegionPtr, CountryCode: read.CountryPtr, Host: read.HostPtr,
		SortOrder: read.SortOrder, Enabled: read.Enabled, Remark: read.RemarkPtr,
		XrayEnabled: read.XrayEnabled, XrayPort: read.XrayPort, XrayAPIPort: read.XrayAPIPort,
		RealitySNI: read.RealitySNIPtr, RealityDest: read.RealityDestPtr, RealitySpiderX: read.RealitySpiderX,
		RealityFingerprint: read.RealityFingerprintPtr, RealityFlow: read.RealityFlow, RealityShortIDs: read.RealityShortIDs,
		Hy2Enabled: read.Hy2Enabled, Hy2Port: read.Hy2Port, Hy2SNI: read.Hy2SNIPtr, Hy2Insecure: read.Hy2Insecure,
		Hy2ObfsPassword: read.Hy2ObfsPtr, Hy2UpMbps: read.Hy2UpMbps, Hy2DownMbps: read.Hy2DownMbps,
		Hy2CertPath: read.Hy2CertPtr, Hy2KeyPath: read.Hy2KeyPtr, Hy2Masquerade: read.Hy2MasqPtr,
	}
	if _, ok := field(body, "rotateRealityKeys"); ok {
		patch.RotateRealityKeys = asBool(body["rotateRealityKeys"])
	}
	if _, ok := field(body, "rotateSecret"); ok {
		patch.RotateSecret = asBool(body["rotateSecret"])
	}
	if _, ok := field(body, "rotateHy2StatsSecret"); ok {
		patch.RotateHy2StatsSecret = asBool(body["rotateHy2StatsSecret"])
	}
	if read.RealityPrivateKey != nil {
		private := *read.RealityPrivateKey
		public := ""
		if read.RealityPublicKey != nil {
			public = *read.RealityPublicKey
		}
		if err := assertRealityKeys(&private, &public); err != nil {
			return store.NodePatch{}, err
		}
		patch.RealityPrivateKey = &private
		patch.RealityPublicKey = &public
	}
	return patch, nil
}

type nodeRead struct {
	Name                  string
	NamePtr               *string
	Region                string
	RegionPtr             *string
	CountryCode           string
	CountryPtr            *string
	Host                  string
	HostPtr               *string
	SortOrder             *int64
	Enabled               *bool
	Remark                string
	RemarkPtr             *string
	XrayEnabled           *bool
	XrayPort              *int
	XrayAPIPort           *int
	RealitySNI            string
	RealitySNIPtr         *string
	RealityDest           string
	RealityDestPtr        *string
	RealitySpiderX        *string
	RealityFingerprint    string
	RealityFingerprintPtr *string
	RealityFlow           *string
	RealityShortIDs       []string
	RealityPrivateKey     *string
	RealityPublicKey      *string
	Hy2Enabled            *bool
	Hy2Port               *int
	Hy2SNI                string
	Hy2SNIPtr             *string
	Hy2Insecure           *bool
	Hy2ObfsPassword       string
	Hy2ObfsPtr            *string
	Hy2UpMbps             *int
	Hy2DownMbps           *int
	Hy2CertPath           string
	Hy2CertPtr            *string
	Hy2KeyPath            string
	Hy2KeyPtr             *string
	Hy2Masquerade         string
	Hy2MasqPtr            *string
}

func readNode(body map[string]any, partial bool) (nodeRead, error) {
	var out nodeRead
	if value, ok := field(body, "name"); ok || !partial {
		if ok {
			text, err := requiredText(value, "节点名称")
			if err != nil {
				return out, err
			}
			out.Name = text
			out.NamePtr = &text
		}
	}
	if value, ok := field(body, "region"); ok {
		text := strings.TrimSpace(asString(value))
		out.Region = text
		out.RegionPtr = &text
	}
	if value, ok := field(body, "countryCode"); ok {
		text := strings.ToUpper(strings.TrimSpace(asString(value)))
		out.CountryCode = text
		out.CountryPtr = &text
	}
	if value, ok := field(body, "host"); ok || !partial {
		if ok {
			text, err := hostText(value)
			if err != nil {
				return out, err
			}
			out.Host = text
			out.HostPtr = &text
		}
	}
	if value, ok := field(body, "sortOrder"); ok {
		n, err := nonNegative(value, "排序")
		if err != nil {
			return out, err
		}
		out.SortOrder = &n
	}
	if _, ok := field(body, "enabled"); ok {
		v := asBool(body["enabled"])
		out.Enabled = &v
	}
	if value, ok := field(body, "remark"); ok {
		text := asString(value)
		out.Remark = text
		out.RemarkPtr = &text
	}
	if _, ok := field(body, "xrayEnabled"); ok {
		v := asBool(body["xrayEnabled"])
		out.XrayEnabled = &v
	}
	if value, ok := field(body, "xrayPort"); ok {
		n, err := port(value, "Xray 端口")
		if err != nil {
			return out, err
		}
		out.XrayPort = &n
	}
	if value, ok := field(body, "xrayApiPort"); ok {
		n, err := port(value, "Xray API 端口")
		if err != nil {
			return out, err
		}
		out.XrayAPIPort = &n
	}
	if value, ok := field(body, "realitySni"); ok {
		text, err := requiredText(value, "Reality SNI")
		if err != nil {
			return out, err
		}
		out.RealitySNI = text
		out.RealitySNIPtr = &text
	}
	if value, ok := field(body, "realityDest"); ok {
		text, err := requiredText(value, "Reality dest")
		if err != nil {
			return out, err
		}
		out.RealityDest = text
		out.RealityDestPtr = &text
	}
	if value, ok := field(body, "realitySpiderX"); ok {
		text := asString(value)
		out.RealitySpiderX = &text
	}
	if value, ok := field(body, "realityFingerprint"); ok {
		text, err := requiredText(value, "指纹")
		if err != nil {
			return out, err
		}
		out.RealityFingerprint = text
		out.RealityFingerprintPtr = &text
	}
	if value, ok := field(body, "realityFlow"); ok {
		text := asString(value)
		if !flows[text] {
			return out, errs.New(400, "VALIDATION", "不支持的 Reality flow")
		}
		out.RealityFlow = &text
	}
	if value, ok := field(body, "realityShortIds"); ok {
		ids, err := shortIDs(value)
		if err != nil {
			return out, err
		}
		out.RealityShortIDs = ids
	}
	if value, ok := field(body, "realityPrivateKey"); ok {
		text := asString(value)
		out.RealityPrivateKey = &text
	}
	if value, ok := field(body, "realityPublicKey"); ok {
		text := asString(value)
		out.RealityPublicKey = &text
	}
	if _, ok := field(body, "hy2Enabled"); ok {
		v := asBool(body["hy2Enabled"])
		out.Hy2Enabled = &v
	}
	if value, ok := field(body, "hy2Port"); ok {
		n, err := port(value, "Hysteria2 端口")
		if err != nil {
			return out, err
		}
		out.Hy2Port = &n
	}
	if value, ok := field(body, "hy2Sni"); ok {
		text, err := requiredText(value, "Hysteria2 SNI")
		if err != nil {
			return out, err
		}
		out.Hy2SNI = text
		out.Hy2SNIPtr = &text
	}
	if _, ok := field(body, "hy2Insecure"); ok {
		v := asBool(body["hy2Insecure"])
		out.Hy2Insecure = &v
	}
	if value, ok := field(body, "hy2ObfsPassword"); ok {
		text := asString(value)
		out.Hy2ObfsPassword = text
		out.Hy2ObfsPtr = &text
	}
	if value, ok := field(body, "hy2UpMbps"); ok {
		n, err := nonNegative(value, "上行带宽")
		if err != nil {
			return out, err
		}
		parsed := int(n)
		out.Hy2UpMbps = &parsed
	}
	if value, ok := field(body, "hy2DownMbps"); ok {
		n, err := nonNegative(value, "下行带宽")
		if err != nil {
			return out, err
		}
		parsed := int(n)
		out.Hy2DownMbps = &parsed
	}
	if value, ok := field(body, "hy2CertPath"); ok {
		text := asString(value)
		out.Hy2CertPath = text
		out.Hy2CertPtr = &text
	}
	if value, ok := field(body, "hy2KeyPath"); ok {
		text := asString(value)
		out.Hy2KeyPath = text
		out.Hy2KeyPtr = &text
	}
	if value, ok := field(body, "hy2Masquerade"); ok {
		text := asString(value)
		out.Hy2Masquerade = text
		out.Hy2MasqPtr = &text
	}
	return out, nil
}

func assertPorts(ports ...int) error {
	seen := map[int]bool{}
	for _, port := range ports {
		if port == 0 {
			continue
		}
		if seen[port] {
			return errs.New(400, "VALIDATION", "Xray、API、Hysteria2 端口不能相同")
		}
		seen[port] = true
	}
	return nil
}

func AssertDistinctPorts(ports ...int) error {
	seen := map[int]bool{}
	for _, port := range ports {
		if seen[port] {
			return errs.New(400, "VALIDATION", "Xray、API、Hysteria2 端口不能相同")
		}
		seen[port] = true
	}
	return nil
}

func assertRealityKeys(privateKey, publicKey *string) error {
	if privateKey == nil || *privateKey == "" {
		return nil
	}
	derived, err := protocol.PublicKeyFromPrivate(*privateKey)
	if err != nil {
		return errs.New(400, "VALIDATION", "Reality 私钥不正确")
	}
	if publicKey != nil && *publicKey != "" && *publicKey != derived {
		return errs.New(400, "VALIDATION", "Reality 公钥与私钥不匹配")
	}
	*publicKey = derived
	return nil
}

func shortIDs(value any) ([]string, error) {
	list, ok := value.([]any)
	if !ok || len(list) == 0 || len(list) > 8 {
		return nil, errs.New(400, "VALIDATION", "shortId 需要 1 到 8 个")
	}
	out := make([]string, len(list))
	for i, item := range list {
		id := strings.ToLower(asString(item))
		if !regexp.MustCompile(`^[0-9a-f]{0,16}$`).MatchString(id) || len(id)%2 != 0 {
			return nil, errs.New(400, "VALIDATION", "shortId 必须是偶数位十六进制，最长 16")
		}
		out[i] = id
	}
	return out, nil
}

func NonNegative(value any, label string) (int64, error) {
	return nonNegative(value, label)
}

func nonNegative(value any, label string) (int64, error) {
	n, ok, err := number(value)
	if !ok || err != nil || n < 0 {
		return 0, errs.New(400, "VALIDATION", label+"不正确")
	}
	return n, nil
}

func port(value any, label string) (int, error) {
	n, ok, err := number(value)
	if !ok || err != nil || n < 1 || n > 65535 {
		return 0, errs.New(400, "VALIDATION", label+"不正确")
	}
	return int(n), nil
}

func requiredText(value any, label string) (string, error) {
	text := strings.TrimSpace(asString(value))
	if text == "" {
		return "", errs.New(400, "VALIDATION", label+"不能为空")
	}
	return text, nil
}

func RequiredText(value any, label string) (string, error) {
	return requiredText(value, label)
}

func hostText(value any) (string, error) {
	host, err := requiredText(value, "节点地址")
	if err != nil {
		return "", err
	}
	if strings.ContainsAny(host, " \t\r\n") {
		return "", errs.New(400, "VALIDATION", "节点地址不正确")
	}
	return host, nil
}

func field(body map[string]any, key string) (any, bool) {
	value, ok := body[key]
	if !ok || value == nil {
		return nil, false
	}
	return value, true
}

func asString(value any) string {
	switch v := value.(type) {
	case string:
		return v
	case json.Number:
		return v.String()
	default:
		return ""
	}
}

func asBool(value any) bool {
	v, _ := value.(bool)
	return v
}

func number(value any) (int64, bool, error) {
	switch v := value.(type) {
	case json.Number:
		n, err := v.Int64()
		return n, true, err
	case int:
		return int64(v), true, nil
	case int64:
		return v, true, nil
	case string:
		n, err := strconv.ParseInt(strings.TrimSpace(v), 10, 64)
		return n, true, err
	case float64:
		if math.IsNaN(v) || math.IsInf(v, 0) || v != math.Trunc(v) {
			return 0, true, strconv.ErrSyntax
		}
		return int64(v), true, nil
	default:
		return 0, false, nil
	}
}

func derefBool(v *bool, fallback bool) bool {
	if v == nil {
		return fallback
	}
	return *v
}

func derefInt(v *int, fallback int) int {
	if v == nil {
		return fallback
	}
	return *v
}

func derefInt64(v *int64, fallback int64) int64 {
	if v == nil {
		return fallback
	}
	return *v
}

func orString(v, fallback string) string {
	if v == "" {
		return fallback
	}
	return v
}

func orStringPtr(v *string, fallback string) string {
	if v == nil {
		return fallback
	}
	return *v
}
