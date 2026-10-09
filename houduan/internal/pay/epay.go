package pay

import (
	"crypto/md5"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"sort"
	"strings"
	"time"

	"xvay/houduan/internal/config"
)

type Order struct {
	No        string
	Name      string
	Amount    int64
	NotifyURL string
	ReturnURL string
}

func Sign(params map[string]string, key string) string {
	names := make([]string, 0, len(params))
	for name, value := range params {
		if name == "sign" || name == "sign_type" || value == "" {
			continue
		}
		names = append(names, name)
	}
	sort.Strings(names)
	var b strings.Builder
	for i, name := range names {
		if i > 0 {
			b.WriteByte('&')
		}
		b.WriteString(name)
		b.WriteByte('=')
		b.WriteString(params[name])
	}
	b.WriteString(key)
	sum := md5.Sum([]byte(b.String()))
	return hex.EncodeToString(sum[:])
}

func Yuan(cents int64) string {
	sign := ""
	if cents < 0 {
		sign = "-"
		cents = -cents
	}
	return fmt.Sprintf("%s%d.%02d", sign, cents/100, cents%100)
}

func Create(cfg config.Config, order Order) (string, error) {
	if cfg.PayGatewayURL == "" {
		return "", fmt.Errorf("pay gateway is empty")
	}
	endpoint := strings.TrimRight(cfg.PayGatewayURL, "/")
	if !strings.Contains(endpoint, "mapi.php") {
		endpoint += "/mapi.php"
	}
	params := map[string]string{
		"pid":          cfg.PayMerchantID,
		"type":         "alipay",
		"out_trade_no": order.No,
		"notify_url":   order.NotifyURL,
		"return_url":   order.ReturnURL,
		"name":         order.Name,
		"money":        Yuan(order.Amount),
		"sign_type":    "MD5",
	}
	params["sign"] = Sign(params, cfg.PayKey)
	form := url.Values{}
	for key, value := range params {
		form.Set(key, value)
	}
	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.PostForm(endpoint, form)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()
	body, err := io.ReadAll(io.LimitReader(resp.Body, 1<<20))
	if err != nil {
		return "", err
	}
	var payload map[string]any
	if err := json.Unmarshal(body, &payload); err != nil {
		return "", fmt.Errorf("pay gateway: %s", strings.TrimSpace(string(body)))
	}
	if code, _ := payload["code"].(float64); code != 1 {
		msg, _ := payload["msg"].(string)
		if msg == "" {
			msg = "支付下单失败"
		}
		return "", fmt.Errorf("%s", msg)
	}
	for _, key := range []string{"payurl", "qrcode", "urlscheme"} {
		if text, _ := payload[key].(string); text != "" {
			return text, nil
		}
	}
	return "", fmt.Errorf("支付网关未返回支付链接")
}

func VerifyNotify(cfg config.Config, values url.Values) (string, string, error) {
	params := map[string]string{}
	for key, list := range values {
		if len(list) > 0 {
			params[key] = list[0]
		}
	}
	if !strings.EqualFold(params["sign"], Sign(params, cfg.PayKey)) {
		return "", "", fmt.Errorf("签名不正确")
	}
	if params["trade_status"] != "TRADE_SUCCESS" {
		return "", "", fmt.Errorf("支付未完成")
	}
	if params["out_trade_no"] == "" {
		return "", "", fmt.Errorf("缺少订单号")
	}
	return params["out_trade_no"], params["trade_no"], nil
}
