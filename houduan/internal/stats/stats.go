package stats

// ParseXrayStats reads xray StatsService names:
// user>>>email>>>traffic>>>uplink|downlink.
func ParseXrayStats(payload any) []map[string]any {
	list := statList(payload)
	users := map[string]map[string]any{}
	order := []string{}
	for _, item := range list {
		obj, ok := item.(map[string]any)
		if !ok {
			continue
		}
		name, _ := obj["name"].(string)
		parts := splitKeep(name, ">>>")
		if len(parts) < 4 || parts[0] != "user" || parts[2] != "traffic" {
			continue
		}
		email := parts[1]
		row, exists := users[email]
		if !exists {
			row = map[string]any{"email": email, "upload": int64(0), "download": int64(0)}
			users[email] = row
			order = append(order, email)
		}
		value := asInt(obj["value"])
		switch parts[3] {
		case "uplink":
			row["upload"] = value
		case "downlink":
			row["download"] = value
		}
	}
	out := make([]map[string]any, 0, len(order))
	for _, email := range order {
		out = append(out, users[email])
	}
	return out
}

// ParseHysteriaTraffic reads Hysteria traffic stats.
// tx is client upload and rx is client download, unless txIs is "download".
func ParseHysteriaTraffic(payload any, txIs string) []map[string]any {
	obj, ok := payload.(map[string]any)
	if !ok {
		return nil
	}
	if txIs == "" {
		txIs = "upload"
	}
	users := make([]map[string]any, 0, len(obj))
	for email, raw := range obj {
		stat, ok := raw.(map[string]any)
		if !ok {
			continue
		}
		tx := asInt(stat["tx"])
		rx := asInt(stat["rx"])
		row := map[string]any{"email": email}
		if txIs == "download" {
			row["upload"] = rx
			row["download"] = tx
		} else {
			row["upload"] = tx
			row["download"] = rx
		}
		users = append(users, row)
	}
	return users
}

func statList(payload any) []any {
	switch value := payload.(type) {
	case []any:
		return value
	case map[string]any:
		if list, ok := value["stat"].([]any); ok {
			return list
		}
		if list, ok := value["stats"].([]any); ok {
			return list
		}
	}
	return nil
}

func splitKeep(s, sep string) []string {
	if s == "" {
		return []string{""}
	}
	var out []string
	for {
		i := indexOf(s, sep)
		if i < 0 {
			out = append(out, s)
			return out
		}
		out = append(out, s[:i])
		s = s[i+len(sep):]
	}
}

func indexOf(s, sep string) int {
	for i := 0; i+len(sep) <= len(s); i++ {
		if s[i:i+len(sep)] == sep {
			return i
		}
	}
	return -1
}

func asInt(value any) int64 {
	switch n := value.(type) {
	case int64:
		return n
	case int:
		return int64(n)
	case float64:
		return int64(n)
	case jsonNumber:
		v, _ := n.Int64()
		return v
	default:
		return 0
	}
}

// jsonNumber is implemented by encoding/json.Number.
type jsonNumber interface {
	Int64() (int64, error)
}
