package epaycom

import (
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"net/url"
	"sort"
	"strings"
)

// Sign builds the EPAY.com request/notify signature (SHA-256 upper hex).
// Empty strings and nil values are dropped; nested maps become {k=v&...}.
func Sign(params map[string]any, apiKey string) string {
	cleaned := prune(params)
	q := queryString(cleaned)
	sum := sha256.Sum256([]byte(q + "&key=" + apiKey))
	return strings.ToUpper(hex.EncodeToString(sum[:]))
}

// SignForm signs flat form notify fields (all string values).
func SignForm(values url.Values, apiKey string) string {
	params := map[string]any{}
	for key, list := range values {
		if key == "sign" || len(list) == 0 {
			continue
		}
		params[key] = list[0]
	}
	return Sign(params, apiKey)
}

func prune(v any) any {
	switch t := v.(type) {
	case map[string]any:
		out := map[string]any{}
		for key, value := range t {
			cleaned := prune(value)
			if cleaned == nil {
				continue
			}
			if s, ok := cleaned.(string); ok && s == "" {
				continue
			}
			out[key] = cleaned
		}
		if len(out) == 0 {
			return nil
		}
		return out
	case []any:
		out := make([]any, 0, len(t))
		for _, item := range t {
			cleaned := prune(item)
			if cleaned == nil {
				continue
			}
			out = append(out, cleaned)
		}
		if len(out) == 0 {
			return nil
		}
		return out
	case string:
		if t == "" {
			return nil
		}
		return t
	case nil:
		return nil
	default:
		return t
	}
}

func queryString(v any) string {
	m, ok := v.(map[string]any)
	if !ok || len(m) == 0 {
		return ""
	}
	keys := make([]string, 0, len(m))
	for key := range m {
		keys = append(keys, key)
	}
	sort.Strings(keys)
	parts := make([]string, 0, len(keys))
	for _, key := range keys {
		value := m[key]
		switch nested := value.(type) {
		case map[string]any:
			parts = append(parts, key+"={"+queryString(nested)+"}")
		default:
			parts = append(parts, key+"="+fmt.Sprint(value))
		}
	}
	return strings.Join(parts, "&")
}
