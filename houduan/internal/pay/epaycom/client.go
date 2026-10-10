package epaycom

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strconv"
	"strings"
	"time"
)

const (
	defaultAPIBase = "https://api.epay.com/capi/openapi"
	version        = "V2.0.0"
	statusPaid     = "7"
)

type Config struct {
	Account          string
	APIKey           string
	APIBase          string
	MerchantName     string
	Currency         string
	PaymentCurrency  string
	PaymentCountry   string
	Language         string
}

type Order struct {
	No        string
	Amount    float64
	NotifyURL string
	SuccessURL string
	FailURL   string
	Remark    string
}

type CreateResult struct {
	PayURL      string
	EpayOrderNo string
	Fee         string
	Raw         map[string]any
}

func (c Config) ready() error {
	if strings.TrimSpace(c.Account) == "" {
		return fmt.Errorf("未配置 EPAY 账号")
	}
	if strings.TrimSpace(c.APIKey) == "" {
		return fmt.Errorf("未配置 EPAY API Key")
	}
	return nil
}

func (c Config) baseURL() string {
	base := strings.TrimSpace(c.APIBase)
	if base == "" {
		base = defaultAPIBase
	}
	return strings.TrimRight(base, "/")
}

func (c Config) currency() string {
	if v := strings.TrimSpace(c.Currency); v != "" {
		return strings.ToUpper(v)
	}
	return "CNY"
}

func (c Config) language() string {
	if v := strings.TrimSpace(c.Language); v != "" {
		return strings.ToUpper(v)
	}
	return "CN"
}

func (c Config) merchantName() string {
	if v := strings.TrimSpace(c.MerchantName); v != "" {
		return v
	}
	return "飞连"
}

// AmountString formats yuan with 2 decimal places.
func AmountString(amount float64) string {
	return strconv.FormatFloat(amount, 'f', 2, 64)
}

// CreateCheckout creates an EPAY.com cashier order and returns epayUrl.
func CreateCheckout(cfg Config, order Order) (CreateResult, error) {
	if err := cfg.ready(); err != nil {
		return CreateResult{}, err
	}
	if strings.TrimSpace(order.No) == "" {
		return CreateResult{}, fmt.Errorf("缺少商家订单号")
	}
	if order.Amount <= 0 {
		return CreateResult{}, fmt.Errorf("订单金额无效")
	}
	param := map[string]any{
		"epayAccount":     strings.TrimSpace(cfg.Account),
		"merchantName":    cfg.merchantName(),
		"merchantOrderNo": order.No,
		"amount":          AmountString(order.Amount),
		"currency":        cfg.currency(),
		"notifyUrl":       order.NotifyURL,
		"successUrl":      order.SuccessURL,
		"failUrl":         order.FailURL,
		"remark":          order.Remark,
		"language":        cfg.language(),
		"version":         version,
	}
	if v := strings.TrimSpace(cfg.PaymentCurrency); v != "" {
		param["paymentCurrency"] = strings.ToUpper(v)
	}
	if v := strings.TrimSpace(cfg.PaymentCountry); v != "" {
		param["paymentCountry"] = strings.ToUpper(v)
	}
	body := map[string]any{
		"param": param,
		"sign":  Sign(param, cfg.APIKey),
	}
	payload, err := json.Marshal(body)
	if err != nil {
		return CreateResult{}, err
	}
	endpoint := cfg.baseURL() + "/gateway/sendTransaction"
	client := &http.Client{Timeout: 20 * time.Second}
	req, err := http.NewRequest(http.MethodPost, endpoint, bytes.NewReader(payload))
	if err != nil {
		return CreateResult{}, err
	}
	req.Header.Set("Content-Type", "application/json")
	resp, err := client.Do(req)
	if err != nil {
		return CreateResult{}, err
	}
	defer resp.Body.Close()
	raw, err := io.ReadAll(io.LimitReader(resp.Body, 1<<20))
	if err != nil {
		return CreateResult{}, err
	}
	var reply struct {
		Code    any            `json:"code"`
		Message string         `json:"message"`
		Data    map[string]any `json:"data"`
	}
	if err := json.Unmarshal(raw, &reply); err != nil {
		return CreateResult{}, fmt.Errorf("EPAY 响应异常: %s", strings.TrimSpace(string(raw)))
	}
	if asInt(reply.Code) != 1 {
		msg := strings.TrimSpace(reply.Message)
		if msg == "" {
			msg = "EPAY 下单失败"
		}
		return CreateResult{}, fmt.Errorf("%s", msg)
	}
	payURL, _ := reply.Data["epayUrl"].(string)
	if payURL == "" {
		return CreateResult{}, fmt.Errorf("EPAY 未返回支付链接")
	}
	epayNo, _ := reply.Data["epayOrderNo"].(string)
	fee, _ := reply.Data["fee"].(string)
	return CreateResult{PayURL: payURL, EpayOrderNo: epayNo, Fee: fee, Raw: reply.Data}, nil
}

// VerifyNotify validates EPAY async notify form and returns order numbers when paid.
func VerifyNotify(cfg Config, values url.Values) (merchantOrderNo, epayOrderNo string, fee float64, err error) {
	if err := cfg.ready(); err != nil {
		return "", "", 0, err
	}
	got := values.Get("sign")
	if got == "" || !strings.EqualFold(got, SignForm(values, cfg.APIKey)) {
		return "", "", 0, fmt.Errorf("签名不正确")
	}
	if values.Get("status") != statusPaid {
		return "", "", 0, fmt.Errorf("支付未完成")
	}
	merchantOrderNo = strings.TrimSpace(values.Get("merchantOrderNo"))
	if merchantOrderNo == "" {
		return "", "", 0, fmt.Errorf("缺少商家订单号")
	}
	epayOrderNo = strings.TrimSpace(values.Get("epayOrderNo"))
	if feeRaw := strings.TrimSpace(values.Get("fee")); feeRaw != "" {
		fee, _ = strconv.ParseFloat(feeRaw, 64)
	}
	return merchantOrderNo, epayOrderNo, fee, nil
}

func asInt(v any) int {
	switch t := v.(type) {
	case float64:
		return int(t)
	case json.Number:
		n, _ := t.Int64()
		return int(n)
	case string:
		n, _ := strconv.Atoi(t)
		return n
	case int:
		return t
	default:
		return 0
	}
}
