package epaycom

import (
	"net/url"
	"testing"
)

func TestSignStableAndDropsEmpty(t *testing.T) {
	params := map[string]any{
		"epayAccount":     "shop@epay.com",
		"merchantName":    "飞连",
		"merchantOrderNo": "XV20261010000001",
		"amount":          "30.00",
		"currency":        "CNY",
		"notifyUrl":       "https://example.com/api/pay/notify/epay",
		"successUrl":      "https://example.com/pay/ok",
		"failUrl":         "",
		"remark":          "",
		"language":        "CN",
		"version":         "V2.0.0",
		"extendFields": map[string]any{
			"sku": "month",
			"note": "",
		},
	}
	a := Sign(params, "test-api-key")
	b := Sign(params, "test-api-key")
	if a == "" || a != b {
		t.Fatalf("sign unstable: %q %q", a, b)
	}
	if len(a) != 64 {
		t.Fatalf("sha256 hex length: %d", len(a))
	}
	// Nested empty should not change sign vs without empty nested key.
	params2 := map[string]any{
		"epayAccount":     "shop@epay.com",
		"merchantName":    "飞连",
		"merchantOrderNo": "XV20261010000001",
		"amount":          "30.00",
		"currency":        "CNY",
		"notifyUrl":       "https://example.com/api/pay/notify/epay",
		"successUrl":      "https://example.com/pay/ok",
		"language":        "CN",
		"version":         "V2.0.0",
		"extendFields": map[string]any{
			"sku": "month",
		},
	}
	if Sign(params2, "test-api-key") != a {
		t.Fatal("empty fields should be ignored in sign")
	}
}

func TestSignForm(t *testing.T) {
	values := url.Values{}
	values.Set("merchantOrderNo", "XV1")
	values.Set("status", "7")
	values.Set("amount", "30.00")
	values.Set("sign", "IGNORE")
	got := SignForm(values, "k")
	expect := Sign(map[string]any{
		"merchantOrderNo": "XV1",
		"status":          "7",
		"amount":          "30.00",
	}, "k")
	if got != expect {
		t.Fatalf("form sign mismatch")
	}
}
