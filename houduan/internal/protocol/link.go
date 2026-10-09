package protocol

import (
	"net/url"
	"strings"
)

// BuildVlessLink returns a VLESS Reality share link for Xray-compatible clients.
func BuildVlessLink(node Node, user User) string {
	shortIDs := ParseShortIDs(node.RealityShortIDs)
	shortID := ""
	if len(shortIDs) > 0 {
		shortID = shortIDs[0]
	}
	fingerprint := node.RealityFingerprint
	if fingerprint == "" {
		fingerprint = "chrome"
	}
	spiderX := node.RealitySpiderX
	if spiderX == "" {
		spiderX = "/"
	}
	params := [][2]string{
		{"encryption", "none"},
		{"security", "reality"},
		{"sni", node.RealitySNI},
		{"fp", fingerprint},
		{"pbk", node.RealityPublicKey},
		{"sid", shortID},
		{"spx", spiderX},
		{"type", "tcp"},
	}
	if node.RealityFlow != "" {
		params = append(params, [2]string{"flow", node.RealityFlow})
	}
	host := trimTrailingPort(HostPort(node.Host, node.XrayPort))
	name := encodeURIComponent(node.Name + " · Reality")
	return "vless://" + user.UUID + "@" + host + ":" + itoa(int64(node.XrayPort)) + "?" + encodeParams(params) + "#" + name
}

// BuildHysteriaLink returns a hysteria2:// share link.
func BuildHysteriaLink(node Node, user User) string {
	userInfo := url.UserPassword(UserEmail(user.ID), user.Hy2Password).String()
	host := trimTrailingPort(HostPort(node.Host, node.Hy2Port))
	params := [][2]string{{"sni", node.Hy2SNI}}
	if node.Hy2Insecure {
		params = append(params, [2]string{"insecure", "1"})
	}
	if node.Hy2ObfsPassword != "" {
		params = append(params, [2]string{"obfs", "salamander"}, [2]string{"obfs-password", node.Hy2ObfsPassword})
	}
	name := encodeURIComponent(node.Name + " · Hysteria2")
	return "hysteria2://" + userInfo + "@" + host + ":" + itoa(int64(node.Hy2Port)) + "?" + encodeParams(params) + "#" + name
}

func encodeParams(params [][2]string) string {
	parts := make([]string, len(params))
	for i, pair := range params {
		parts[i] = url.QueryEscape(pair[0]) + "=" + url.QueryEscape(pair[1])
	}
	return strings.Join(parts, "&")
}

func trimTrailingPort(hostport string) string {
	for i := len(hostport) - 1; i >= 0; i-- {
		c := hostport[i]
		if c >= '0' && c <= '9' {
			continue
		}
		if c == ':' {
			return hostport[:i]
		}
		break
	}
	return hostport
}

func encodeURIComponent(s string) string {
	return strings.ReplaceAll(url.QueryEscape(s), "+", "%20")
}
