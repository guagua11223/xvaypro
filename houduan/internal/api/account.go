package api

import (
	"fmt"
	"net"
	"net/http"
	"strconv"
	"strings"
	"time"
	"unicode/utf8"

	"xvay/houduan/internal/errs"
	"xvay/houduan/internal/mail"
	"xvay/houduan/internal/store"
	"xvay/houduan/internal/validate"
)

func (s *Server) updateProfile(w http.ResponseWriter, r *http.Request) error {
	user, err := s.requireUser(r)
	if err != nil {
		return err
	}
	body, err := readJSON(r)
	if err != nil {
		return err
	}
	patch := store.UserPatch{}
	changed := false
	if _, ok := body["nickname"]; ok {
		nickname, err := validate.ParseNickname(body["nickname"], "")
		if err != nil {
			return err
		}
		if nickname == "" {
			return badRequest("昵称不能为空")
		}
		patch.Nickname = &nickname
		changed = true
	}
	if _, ok := body["avatar"]; ok {
		avatar, err := validate.ParseAvatar(body["avatar"])
		if err != nil {
			return err
		}
		patch.Avatar = &avatar
		changed = true
	}
	if !changed {
		return badRequest("没有可更新的内容")
	}
	updated, err := s.db.UpdateUser(user.ID, patch)
	if err != nil {
		return err
	}
	if patch.Nickname != nil {
		if err := s.syncDisplayName(updated); err != nil {
			return err
		}
	}
	ip, device := requestMeta(r)
	if err := s.db.AddSecurityLog(updated.ID, "profile_update", ip, device, "修改个人信息", time.Now().UnixMilli()); err != nil {
		return err
	}
	writeOK(w, http.StatusOK, s.presentUser(updated))
	return nil
}

func (s *Server) appCenter(w http.ResponseWriter, r *http.Request) error {
	user, err := s.requireUser(r)
	if err != nil {
		return err
	}
	orders, err := s.orderList(user.ID)
	if err != nil {
		return err
	}
	announcements, err := s.announcementList(false)
	if err != nil {
		return err
	}
	support, err := s.supportView()
	if err != nil {
		return err
	}
	view := s.presentUser(user)
	writeOK(w, http.StatusOK, map[string]any{
		"user": view, "bindEmailReminder": view.BindEmailReminder, "bindEmailMessage": view.BindEmailMessage,
		"orders": orders, "announcements": announcements, "support": support,
	})
	return nil
}

func (s *Server) accountSecurity(w http.ResponseWriter, r *http.Request) error {
	user, err := s.requireUser(r)
	if err != nil {
		return err
	}
	logs, err := s.db.ListSecurityLogs(user.ID, 20)
	if err != nil {
		return err
	}
	view := s.presentUser(user)
	items := make([]map[string]any, 0, len(logs))
	for _, row := range logs {
		items = append(items, map[string]any{
			"id": row.ID, "action": row.Action, "actionLabel": actionLabel(row.Action),
			"ip": row.IP, "device": row.Device, "detail": row.Detail, "createdAt": row.CreatedAt,
		})
	}
	writeOK(w, http.StatusOK, map[string]any{
		"emailBound": view.EmailBound, "emailMasked": maskEmail(user.Email),
		"bindEmailReminder": view.BindEmailReminder, "bindEmailMessage": view.BindEmailMessage,
		"rules": map[string]any{
			"ttlSeconds": store.CodeTTLMs / 1000, "resendSeconds": store.CodeResendMs / 1000,
			"hourlyLimit": store.CodeHourlyLimit,
		},
		"logs": items,
	})
	return nil
}

func (s *Server) sendBindCode(w http.ResponseWriter, r *http.Request) error {
	user, err := s.requireUser(r)
	if err != nil {
		return err
	}
	body, err := readJSON(r)
	if err != nil {
		return err
	}
	email, err := validate.ParseEmail(body["email"])
	if err != nil {
		return err
	}
	if user.Email == email {
		return errs.New(http.StatusConflict, "CONFLICT", "该邮箱已绑定当前账号")
	}
	other, ok, err := s.db.FindUserByEmail(email)
	if err != nil {
		return err
	}
	if ok && other.ID != user.ID {
		return errs.New(http.StatusConflict, "CONFLICT", "该邮箱已绑定其他账号")
	}
	return s.deliverCode(w, r, store.PurposeBind, email, user.ID, true)
}

func (s *Server) accountBindEmail(w http.ResponseWriter, r *http.Request) error {
	user, err := s.requireUser(r)
	if err != nil {
		return err
	}
	body, err := readJSON(r)
	if err != nil {
		return err
	}
	email, err := validate.ParseEmail(body["email"])
	if err != nil {
		return err
	}
	code, err := validate.ParseCode(body["code"])
	if err != nil {
		return err
	}
	ip, device := requestMeta(r)
	now := time.Now().UnixMilli()
	if err := s.db.ConsumeEmailCode(email, store.PurposeBind, code, user.ID, ip, device, now); err != nil {
		return err
	}
	updated, err := s.db.BindUserEmail(user.ID, email)
	if err != nil {
		return err
	}
	if err := s.db.AddSecurityLog(updated.ID, "email_bind", ip, device, "完成邮箱绑定", now); err != nil {
		return err
	}
	writeOK(w, http.StatusOK, s.presentUser(updated))
	return nil
}

func (s *Server) recoverAccount(w http.ResponseWriter, r *http.Request) error {
	body, err := readJSON(r)
	if err != nil {
		return err
	}
	email, err := validate.ParseEmail(body["email"])
	if err != nil {
		return err
	}
	user, ok, err := s.db.FindUserByEmail(email)
	if err != nil {
		return err
	}
	userID := int64(0)
	if ok {
		userID = user.ID
	}
	return s.deliverCode(w, r, store.PurposeRecover, email, userID, ok)
}

func (s *Server) verifyRecover(w http.ResponseWriter, r *http.Request) error {
	body, err := readJSON(r)
	if err != nil {
		return err
	}
	email, err := validate.ParseEmail(body["email"])
	if err != nil {
		return err
	}
	code, err := validate.ParseCode(body["code"])
	if err != nil {
		return err
	}
	ip, device := requestMeta(r)
	now := time.Now().UnixMilli()
	if err := s.db.ConsumeEmailCode(email, store.PurposeRecover, code, 0, ip, device, now); err != nil {
		return err
	}
	user, ok, err := s.db.FindUserByEmail(email)
	if err != nil {
		return err
	}
	if !ok {
		return badRequest("验证码不正确或已过期")
	}
	if err := s.db.AddSecurityLog(user.ID, "account_recover", ip, device, "通过邮箱找回账号", now); err != nil {
		return err
	}
	writeOK(w, http.StatusOK, map[string]any{
		"accountId": maskID(user.ID),
		"username":  maskText(user.Username),
	})
	return nil
}

func (s *Server) sendResetCode(w http.ResponseWriter, r *http.Request) error {
	body, err := readJSON(r)
	if err != nil {
		return err
	}
	email, err := validate.ParseEmail(body["email"])
	if err != nil {
		return err
	}
	user, ok, err := s.db.FindUserByEmail(email)
	if err != nil {
		return err
	}
	userID := int64(0)
	if ok {
		userID = user.ID
	}
	return s.deliverCode(w, r, store.PurposeReset, email, userID, ok)
}

func (s *Server) resetPassword(w http.ResponseWriter, r *http.Request) error {
	body, err := readJSON(r)
	if err != nil {
		return err
	}
	email, err := validate.ParseEmail(body["email"])
	if err != nil {
		return err
	}
	code, err := validate.ParseCode(body["code"])
	if err != nil {
		return err
	}
	password, err := validate.ParsePassword(body["password"])
	if err != nil {
		return err
	}
	ip, device := requestMeta(r)
	now := time.Now().UnixMilli()
	if err := s.db.ConsumeEmailCode(email, store.PurposeReset, code, 0, ip, device, now); err != nil {
		return err
	}
	user, ok, err := s.db.FindUserByEmail(email)
	if err != nil {
		return err
	}
	if !ok {
		return badRequest("验证码不正确或已过期")
	}
	if _, err := s.db.UpdateUser(user.ID, store.UserPatch{Password: &password}); err != nil {
		return err
	}
	if err := s.db.DeleteUserSessions(user.ID); err != nil {
		return err
	}
	if err := s.db.AddSecurityLog(user.ID, "password_reset", ip, device, "通过邮箱重置密码", now); err != nil {
		return err
	}
	writeOK(w, http.StatusOK, map[string]any{"reset": true})
	return nil
}

func (s *Server) appOrders(w http.ResponseWriter, r *http.Request) error {
	user, err := s.requireUser(r)
	if err != nil {
		return err
	}
	orders, err := s.orderList(user.ID)
	if err != nil {
		return err
	}
	writeOK(w, http.StatusOK, map[string]any{"orders": orders})
	return nil
}

func (s *Server) appSupport(w http.ResponseWriter, r *http.Request) error {
	if _, err := s.requireUser(r); err != nil {
		return err
	}
	support, err := s.supportView()
	if err != nil {
		return err
	}
	writeOK(w, http.StatusOK, support)
	return nil
}

func (s *Server) appTickets(w http.ResponseWriter, r *http.Request) error {
	user, err := s.requireUser(r)
	if err != nil {
		return err
	}
	rows, err := s.db.ListTickets(user.ID)
	if err != nil {
		return err
	}
	writeOK(w, http.StatusOK, map[string]any{"tickets": ticketViews(rows)})
	return nil
}

func (s *Server) createTicket(w http.ResponseWriter, r *http.Request) error {
	user, err := s.requireUser(r)
	if err != nil {
		return err
	}
	body, err := readJSON(r)
	if err != nil {
		return err
	}
	subject, err := validate.RequiredText(body["subject"], "工单标题")
	if err != nil {
		return err
	}
	if utf8.RuneCountInString(subject) > 80 {
		return badRequest("工单标题最长 80 个字符")
	}
	text, err := validate.RequiredText(body["body"], "工单内容")
	if err != nil {
		return err
	}
	if utf8.RuneCountInString(text) > 2000 {
		return badRequest("工单内容最长 2000 个字符")
	}
	contact := strings.TrimSpace(store.AsString(body["contact"]))
	if utf8.RuneCountInString(contact) > 80 {
		return badRequest("联系方式最长 80 个字符")
	}
	ticket, err := s.db.CreateTicket(user.ID, subject, text, contact, time.Now().UnixMilli())
	if err != nil {
		return err
	}
	ip, device := requestMeta(r)
	if err := s.db.AddSecurityLog(user.ID, "ticket", ip, device, "提交客服工单", time.Now().UnixMilli()); err != nil {
		return err
	}
	writeOK(w, http.StatusCreated, ticketView(ticket))
	return nil
}

func (s *Server) adminCreateOrder(w http.ResponseWriter, r *http.Request) error {
	if err := s.requireAdmin(r); err != nil {
		return err
	}
	body, err := readJSON(r)
	if err != nil {
		return err
	}
	userID := store.AsInt64(body["userId"])
	if userID <= 0 {
		return badRequest("请指定用户")
	}
	if _, ok, err := s.db.FindUserByID(userID); err != nil || !ok {
		if err != nil {
			return err
		}
		return notFound("用户不存在")
	}
	title, err := validate.RequiredText(body["title"], "订单标题")
	if err != nil {
		return err
	}
	amount, err := validate.NonNegative(body["amount"], "订单金额")
	if err != nil {
		return err
	}
	status, err := validate.ParseOrderStatus(body["status"], "pending")
	if err != nil {
		return err
	}
	var paidAt int64
	if _, ok := body["paidAt"]; ok {
		paidAt, err = validate.ParseTime(body["paidAt"])
		if err != nil {
			return err
		}
	}
	order, err := s.db.CreateOrder(store.OrderInput{
		UserID: userID, Title: title, Amount: amount, Status: status,
		PayChannel: clipText(store.AsString(body["payChannel"]), 32),
		PayTradeNo: clipText(store.AsString(body["payTradeNo"]), 64),
		PaidAt:     paidAt, Now: time.Now().UnixMilli(),
	})
	if err != nil {
		return err
	}
	writeOK(w, http.StatusCreated, orderView(order, nil))
	return nil
}

func (s *Server) adminCreateRefund(w http.ResponseWriter, r *http.Request) error {
	if err := s.requireAdmin(r); err != nil {
		return err
	}
	orderID, err := idParam(r)
	if err != nil {
		return err
	}
	body, err := readJSON(r)
	if err != nil {
		return err
	}
	amount, err := validate.NonNegative(body["amount"], "退款金额")
	if err != nil {
		return err
	}
	if amount <= 0 {
		return badRequest("退款金额不正确")
	}
	status, err := validate.ParseRefundStatus(body["status"], "success")
	if err != nil {
		return err
	}
	reason := clipText(store.AsString(body["reason"]), 200)
	_, order, err := s.db.AddRefund(orderID, amount, status, reason, time.Now().UnixMilli())
	if err != nil {
		return err
	}
	refunds, err := s.db.ListRefunds(order.UserID)
	if err != nil {
		return err
	}
	matched := make([]store.Refund, 0)
	for _, refund := range refunds {
		if refund.OrderID == order.ID {
			matched = append(matched, refund)
		}
	}
	writeOK(w, http.StatusCreated, orderView(order, matched))
	return nil
}

func (s *Server) deliverCode(w http.ResponseWriter, r *http.Request, purpose, email string, userID int64, deliver bool) error {
	if !s.mailReady() {
		return errs.New(http.StatusServiceUnavailable, "MAIL", "邮件服务未配置，暂时无法发送验证码")
	}
	ip, device := requestMeta(r)
	now := time.Now().UnixMilli()
	code, err := s.db.IssueEmailCode(store.CodeIssue{
		Email: email, Purpose: purpose, UserID: userID, IP: ip, Device: device, Now: now, Deliver: deliver,
	})
	if err != nil {
		return err
	}
	if deliver {
		if err := mail.Send(s.cfg, email, codeSubject(purpose), codeBody(purpose, code)); err != nil {
			_ = s.db.DropLatestCode(email, purpose)
			return errs.New(http.StatusBadGateway, "MAIL", "验证码发送失败，请稍后重试")
		}
	}
	payload := map[string]any{
		"sent": true, "expiresIn": store.CodeTTLMs / 1000, "resendIn": store.CodeResendMs / 1000,
	}
	if deliver && s.cfg.MailDebug && code != "" {
		payload["debugCode"] = code
	}
	writeOK(w, http.StatusOK, payload)
	return nil
}

func (s *Server) mailReady() bool {
	return s.cfg.SMTPHost != "" || s.cfg.MailDebug
}

func (s *Server) announcementList(history bool) ([]PublicAnnouncement, error) {
	rows, err := s.db.ListAnnouncements(!history)
	if err != nil {
		return nil, err
	}
	out := make([]PublicAnnouncement, len(rows))
	for i, row := range rows {
		out[i] = publicAnnouncement(row)
	}
	return out, nil
}

func (s *Server) orderList(userID int64) ([]map[string]any, error) {
	orders, err := s.db.ListOrders(userID, 100)
	if err != nil {
		return nil, err
	}
	refunds, err := s.db.ListRefunds(userID)
	if err != nil {
		return nil, err
	}
	grouped := map[int64][]store.Refund{}
	for _, refund := range refunds {
		grouped[refund.OrderID] = append(grouped[refund.OrderID], refund)
	}
	out := make([]map[string]any, 0, len(orders))
	for _, order := range orders {
		out = append(out, orderView(order, grouped[order.ID]))
	}
	return out, nil
}

func (s *Server) supportView() (map[string]any, error) {
	settings, err := s.db.GetSettings()
	if err != nil {
		return nil, err
	}
	appSettings, _, err := s.db.GetSingleton("appSettings")
	if err != nil {
		return nil, err
	}
	if appSettings == nil {
		appSettings = map[string]any{}
	}
	pick := func(settingKey, appKey string) string {
		if value := strings.TrimSpace(settings[settingKey]); value != "" {
			return value
		}
		return strings.TrimSpace(store.AsString(appSettings[appKey]))
	}
	online := pick("support_online", "supportOnline")
	if online == "" {
		online = pick("support_url", "supportUrl")
	}
	return map[string]any{
		"wechat":   pick("support_wechat", "supportWechat"),
		"qq":       pick("support_qq", "supportQq"),
		"telegram": pick("support_telegram", "supportTelegram"),
		"online":   online,
		"qrcode":   pick("support_qrcode", "supportQrcode"),
	}, nil
}

func (s *Server) syncDisplayName(user store.User) error {
	current, _, err := s.db.FindProfile(user.ID)
	if err != nil {
		return err
	}
	current.UserID = user.ID
	current.DisplayName = user.Nickname
	return s.db.SaveProfile(current)
}

func orderView(order store.Order, refunds []store.Refund) map[string]any {
	if refunds == nil {
		refunds = []store.Refund{}
	}
	items := make([]map[string]any, 0, len(refunds))
	for _, refund := range refunds {
		items = append(items, map[string]any{
			"id": refund.ID, "amount": refund.Amount, "amountYuan": yuan(refund.Amount),
			"status": refund.Status, "statusLabel": refundStatusLabel(refund.Status),
			"reason": refund.Reason, "createdAt": refund.CreatedAt,
		})
	}
	return map[string]any{
		"id": order.ID, "orderNo": order.OrderNo, "title": order.Title,
		"amount": order.Amount, "amountYuan": yuan(order.Amount), "currency": order.Currency,
		"status": order.Status, "statusLabel": orderStatusLabel(order.Status),
		"payment": map[string]any{
			"channel": order.PayChannel, "tradeNo": order.PayTradeNo, "paidAt": order.PaidAt,
		},
		"planCode": order.PlanCode, "renew": order.Renew == 1,
		"refunds": items, "createdAt": order.CreatedAt,
	}
}

func ticketViews(rows []store.Ticket) []map[string]any {
	out := make([]map[string]any, 0, len(rows))
	for _, row := range rows {
		out = append(out, ticketView(row))
	}
	return out
}

func ticketView(ticket store.Ticket) map[string]any {
	label := "待处理"
	if ticket.Status == "closed" {
		label = "已关闭"
	}
	return map[string]any{
		"id": ticket.ID, "subject": ticket.Subject, "body": ticket.Body, "contact": ticket.Contact,
		"status": ticket.Status, "statusLabel": label, "createdAt": ticket.CreatedAt,
	}
}

func orderStatusLabel(status string) string {
	switch status {
	case "pending":
		return "待支付"
	case "paid":
		return "已支付"
	case "closed":
		return "已关闭"
	case "refunded":
		return "已退款"
	case "partial_refund":
		return "部分退款"
	default:
		return status
	}
}

func refundStatusLabel(status string) string {
	switch status {
	case "pending":
		return "退款处理中"
	case "success":
		return "退款成功"
	case "failed":
		return "退款失败"
	default:
		return status
	}
}

func yuan(cents int64) string {
	sign := ""
	if cents < 0 {
		sign = "-"
		cents = -cents
	}
	return fmt.Sprintf("%s%d.%02d", sign, cents/100, cents%100)
}

func accountName(body map[string]any) string {
	for _, key := range []string{"username", "account", "email"} {
		if text := strings.ToLower(strings.TrimSpace(store.AsString(body[key]))); text != "" {
			return text
		}
	}
	return ""
}

func requestMeta(r *http.Request) (string, string) {
	ip := ""
	if forwarded := r.Header.Get("X-Forwarded-For"); forwarded != "" {
		ip = strings.TrimSpace(strings.Split(forwarded, ",")[0])
	}
	if ip == "" {
		host, _, err := net.SplitHostPort(r.RemoteAddr)
		if err != nil {
			ip = r.RemoteAddr
		} else {
			ip = host
		}
	}
	device := strings.TrimSpace(r.Header.Get("X-Device"))
	if device == "" {
		device = r.UserAgent()
	}
	return clipText(ip, 64), clipText(device, 200)
}

func clipText(text string, n int) string {
	text = strings.TrimSpace(text)
	if len(text) <= n {
		return text
	}
	for n > 0 && !utf8.RuneStart(text[n]) {
		n--
	}
	return text[:n]
}

func maskID(id int64) string {
	return maskText(strconv.FormatInt(id, 10))
}

func maskText(raw string) string {
	rs := []rune(raw)
	n := len(rs)
	if n == 0 {
		return ""
	}
	if n == 1 {
		return "*"
	}
	if n == 2 {
		return string(rs[:1]) + "*"
	}
	stars := n - 2
	if stars > 6 {
		stars = 6
	}
	return string(rs[:1]) + strings.Repeat("*", stars) + string(rs[n-1:])
}

func maskEmail(email string) string {
	if email == "" {
		return ""
	}
	name, host, ok := strings.Cut(email, "@")
	if !ok {
		return maskText(email)
	}
	return maskText(name) + "@" + host
}

func actionLabel(action string) string {
	switch action {
	case "register":
		return "注册"
	case "login":
		return "登录"
	case "logout":
		return "退出登录"
	case "email_code":
		return "发送验证码"
	case "email_code_fail":
		return "验证码校验失败"
	case "email_bind":
		return "绑定邮箱"
	case "account_recover":
		return "找回账号"
	case "password_reset":
		return "重置密码"
	case "profile_update":
		return "修改资料"
	case "ticket":
		return "提交工单"
	default:
		return action
	}
}

func codeSubject(purpose string) string {
	switch purpose {
	case store.PurposeBind:
		return "绑定邮箱验证码"
	case store.PurposeRecover:
		return "找回账号验证码"
	case store.PurposeReset:
		return "重置密码验证码"
	default:
		return "验证码"
	}
}

func codeBody(purpose, code string) string {
	return codeSubject(purpose) + "：" + code + "\n验证码 5 分钟内有效，请勿泄露。"
}
