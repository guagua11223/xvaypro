package protocol

type Hy2Paths struct {
	Cert string
	Key  string
}

func salamander(password string) map[string]any {
	return map[string]any{
		"type": "salamander",
		"salamander": map[string]any{
			"password": password,
		},
	}
}

// BuildHysteriaClient is the Hysteria 2 client config for one user on this node.
func BuildHysteriaClient(node Node, user User) map[string]any {
	config := map[string]any{
		"server": HostPort(node.Host, node.Hy2Port),
		"auth":   UserEmail(user.ID) + ":" + user.Hy2Password,
		"tls": map[string]any{
			"sni":      node.Hy2SNI,
			"insecure": node.Hy2Insecure,
		},
	}
	if node.Hy2ObfsPassword != "" {
		config["obfs"] = salamander(node.Hy2ObfsPassword)
	}
	if node.Hy2UpMbps > 0 || node.Hy2DownMbps > 0 {
		bandwidth := map[string]any{}
		if node.Hy2UpMbps > 0 {
			bandwidth["up"] = itoa(int64(node.Hy2UpMbps)) + " mbps"
		}
		if node.Hy2DownMbps > 0 {
			bandwidth["down"] = itoa(int64(node.Hy2DownMbps)) + " mbps"
		}
		config["bandwidth"] = bandwidth
	}
	return config
}

// BuildHysteriaServer is the Hysteria 2 server config with userpass auth and traffic stats.
func BuildHysteriaServer(node Node, users []User, paths Hy2Paths) map[string]any {
	userpass := map[string]any{}
	for _, user := range users {
		userpass[UserEmail(user.ID)] = user.Hy2Password
	}
	masquerade := node.Hy2Masquerade
	if masquerade == "" {
		masquerade = "https://" + node.Hy2SNI + "/"
	}
	config := map[string]any{
		"listen": ":" + itoa(int64(node.Hy2Port)),
		"tls": map[string]any{
			"cert": paths.Cert,
			"key":  paths.Key,
		},
		"auth": map[string]any{
			"type":     "userpass",
			"userpass": userpass,
		},
		"masquerade": map[string]any{
			"type": "proxy",
			"proxy": map[string]any{
				"url":         masquerade,
				"rewriteHost": true,
			},
		},
		"trafficStats": map[string]any{
			"listen": Hy2StatsListen(node.ID),
			"secret": node.Hy2StatsSecret,
		},
	}
	if node.Hy2ObfsPassword != "" {
		config["obfs"] = salamander(node.Hy2ObfsPassword)
	}
	return config
}
