package protocol

// BuildXrayClient is the outbound a client uses to dial this node with VLESS + Reality.
func BuildXrayClient(node Node, user User) map[string]any {
	shortIDs := ParseShortIDs(node.RealityShortIDs)
	shortID := ""
	if len(shortIDs) > 0 {
		shortID = shortIDs[0]
	}
	userConfig := map[string]any{
		"id":         user.UUID,
		"encryption": "none",
	}
	if node.RealityFlow != "" {
		userConfig["flow"] = node.RealityFlow
	}
	fingerprint := node.RealityFingerprint
	if fingerprint == "" {
		fingerprint = "chrome"
	}
	spiderX := node.RealitySpiderX
	if spiderX == "" {
		spiderX = "/"
	}
	return map[string]any{
		"outbounds": []any{
			map[string]any{
				"tag":      "proxy",
				"protocol": "vless",
				"settings": map[string]any{
					"vnext": []any{
						map[string]any{
							"address": node.Host,
							"port":    node.XrayPort,
							"users":   []any{userConfig},
						},
					},
				},
				"streamSettings": map[string]any{
					"network":  "tcp",
					"security": "reality",
					"realitySettings": map[string]any{
						"serverName":  node.RealitySNI,
						"fingerprint": fingerprint,
						"publicKey":   node.RealityPublicKey,
						"shortId":     shortID,
						"spiderX":     spiderX,
					},
				},
			},
		},
	}
}

// BuildXrayServer is an xray-core config: VLESS inbound with Reality, plus a local Stats API.
func BuildXrayServer(node Node, users []User) map[string]any {
	shortIDs := ParseShortIDs(node.RealityShortIDs)
	if len(shortIDs) == 0 {
		shortIDs = []string{""}
	}
	clients := make([]any, 0, len(users))
	for _, user := range users {
		client := map[string]any{
			"id":    user.UUID,
			"email": UserEmail(user.ID),
			"level": 0,
		}
		if node.RealityFlow != "" {
			client["flow"] = node.RealityFlow
		}
		clients = append(clients, client)
	}
	return map[string]any{
		"log":   map[string]any{"loglevel": "warning"},
		"stats": map[string]any{},
		"api": map[string]any{
			"tag":      "api",
			"services": []any{"StatsService"},
		},
		"policy": map[string]any{
			"levels": map[string]any{
				"0": map[string]any{
					"statsUserUplink":   true,
					"statsUserDownlink": true,
				},
			},
			"system": map[string]any{
				"statsInboundUplink":    true,
				"statsInboundDownlink":  true,
				"statsOutboundUplink":   true,
				"statsOutboundDownlink": true,
			},
		},
		"inbounds": []any{
			map[string]any{
				"tag":      "api",
				"listen":   "127.0.0.1",
				"port":     node.XrayAPIPort,
				"protocol": "dokodemo-door",
				"settings": map[string]any{"address": "127.0.0.1"},
			},
			map[string]any{
				"tag":      "vless-reality",
				"listen":   "0.0.0.0",
				"port":     node.XrayPort,
				"protocol": "vless",
				"settings": map[string]any{
					"clients":    clients,
					"decryption": "none",
				},
				"streamSettings": map[string]any{
					"network":  "tcp",
					"security": "reality",
					"realitySettings": map[string]any{
						"show":        false,
						"dest":        node.RealityDest,
						"xver":        0,
						"serverNames": []any{node.RealitySNI},
						"privateKey":  node.RealityPrivateKey,
						"shortIds":    shortIDs,
					},
				},
				"sniffing": map[string]any{
					"enabled":      true,
					"destOverride": []any{"http", "tls", "quic"},
				},
			},
		},
		"outbounds": []any{
			map[string]any{"tag": "direct", "protocol": "freedom"},
			map[string]any{"tag": "block", "protocol": "blackhole"},
		},
		"routing": map[string]any{
			"domainStrategy": "AsIs",
			"rules": []any{
				map[string]any{
					"type":        "field",
					"inboundTag":  []any{"api"},
					"outboundTag": "api",
				},
			},
		},
	}
}
