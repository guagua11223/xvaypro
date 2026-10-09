package protocol

import "encoding/json"

// Node is the subset of node fields needed to build Xray and Hysteria configs.
type Node struct {
	ID                 int64
	Name               string
	Host               string
	XrayPort           int
	XrayAPIPort        int
	RealityPrivateKey  string
	RealityPublicKey   string
	RealityShortIDs    string
	RealitySNI         string
	RealityDest        string
	RealitySpiderX     string
	RealityFingerprint string
	RealityFlow        string
	Hy2Port            int
	Hy2SNI             string
	Hy2Insecure        bool
	Hy2ObfsPassword    string
	Hy2UpMbps          int
	Hy2DownMbps        int
	Hy2Masquerade      string
	Hy2StatsSecret     string
}

// User is the subset of account fields placed into a node config.
type User struct {
	ID          int64
	UUID        string
	Hy2Password string
}

func UserEmail(id int64) string {
	return "u" + itoa(id)
}

func itoa(n int64) string {
	if n == 0 {
		return "0"
	}
	neg := n < 0
	if neg {
		n = -n
	}
	var buf [20]byte
	i := len(buf)
	for n > 0 {
		i--
		buf[i] = byte('0' + n%10)
		n /= 10
	}
	if neg {
		i--
		buf[i] = '-'
	}
	return string(buf[i:])
}

func ParseShortIDs(value string) []string {
	if value == "" {
		return []string{}
	}
	var parsed []string
	if err := json.Unmarshal([]byte(value), &parsed); err != nil || parsed == nil {
		return []string{}
	}
	return parsed
}

func HostPort(host string, port int) string {
	if containsByte(host, ':') && (len(host) == 0 || host[0] != '[') {
		return "[" + host + "]:" + itoa(int64(port))
	}
	return host + ":" + itoa(int64(port))
}

func containsByte(s string, c byte) bool {
	for i := 0; i < len(s); i++ {
		if s[i] == c {
			return true
		}
	}
	return false
}

func Hy2StatsListen(nodeID int64) string {
	return "127.0.0.1:" + itoa(39000+(nodeID%20000))
}
