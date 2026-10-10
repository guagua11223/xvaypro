package api

import (
	"fmt"
	"net"
	"net/http"
	"net/url"
	"strconv"
	"strings"
	"time"

	"github.com/skip2/go-qrcode"

	"xvay/houduan/internal/auth"
	"xvay/houduan/internal/errs"
	"xvay/houduan/internal/pay"
	"xvay/houduan/internal/store"
	"xvay/houduan/internal/validate"
)

func (s *Server) userProfile(w http.ResponseWriter, r *http.Request) error {
	user, err := s.requireUser(r)
	if err != nil {
		return err
	}
	member, ok, err := s.db.LoadMember(user.ID)
	if err != nil {
		return err
	}
	if !ok {
		return notFound("会员不存在")
	}
	_, _ = s.db.SettleMemberDue(time.Now())
	writeOK(w, http.StatusOK, s.memberJSON(member, true))
	return nil
}

func (s *Server) listPackages(w http.ResponseWriter, r *http.Request) error {
	if _, err := s.requireUser(r); err != nil {
		return err
	}
	list, err := s.db.SellablePackages()
	if err != nil {
		return err
	}
	out := make([]map[string]any, 0, len(list))
	for _, item := range list {
		out = append(out, packageJSON(item))
	}
	writeOK(w, http.StatusOK, map[string]any{"packages": out})
	return nil
}

func (s *Server) createOrder(w http.ResponseWriter, r *http.Request) error {
	user, err := s.requireUser(r)
	if err != nil {
		return err
	}
	body, err := readJSON(r)
	if err != nil {
		return err
	}
	member, _, err := s.db.LoadMember(user.ID)
	if err != nil {
		return err
	}
	if member.MemberStatus == 1 {
		return forbidden("账号已封禁")
	}
	order, err := s.db.CreateCommerceOrder(user.ID, store.AsInt64(body["packageId"]), time.Now().UnixMilli())
	if err != nil {
		return err
	}
	writeOK(w, http.StatusCreated, map[string]any{"order": orderJSON(order, member.Username, ""), "pay": s.payPayload(order)})
	return nil
}

func (s *Server) listMyOrders(w http.ResponseWriter, r *http.Request) error {
	user, err := s.requireUser(r)
	if err != nil {
		return err
	}
	return s.writeOrders(w, user.ID, 0, 0)
}

func (s *Server) cancelMyOrder(w http.ResponseWriter, r *http.Request) error {
	user, err := s.requireUser(r)
	if err != nil {
		return err
	}
	body, err := readJSON(r)
	if err != nil {
		return err
	}
	if err := s.db.CancelCommerceOrder(user.ID, store.AsInt64(body["orderId"])); err != nil {
		return err
	}
	writeOK(w, http.StatusOK, map[string]any{"cancelled": true})
	return nil
}

func (s *Server) userWallet(w http.ResponseWriter, r *http.Request) error {
	user, err := s.requireUser(r)
	if err != nil {
		return err
	}
	member, _, err := s.db.LoadMember(user.ID)
	if err != nil {
		return err
	}
	if member.WalletEnabled != 1 {
		return forbidden("钱包未开通")
	}
	_, _ = s.db.SettleMemberDue(time.Now())
	wallet, err := s.db.MemberWallet(user.ID)
	if err != nil {
		return err
	}
	rows, err := s.db.ListCommissionRows(user.ID, 50)
	if err != nil {
		return err
	}
	writeOK(w, http.StatusOK, map[string]any{
		"balance": wallet.Balance, "frozen": wallet.Frozen, "totalIncome": wallet.TotalIncome,
		"totalWithdraw": wallet.TotalWithdraw, "negativeBalance": wallet.NegativeBalance,
		"commissions": commissionJSON(rows),
	})
	return nil
}

func (s *Server) userWithdraw(w http.ResponseWriter, r *http.Request) error {
	user, err := s.requireUser(r)
	if err != nil {
		return err
	}
	body, err := readJSON(r)
	if err != nil {
		return err
	}
	id, err := s.db.RequestMemberWithdraw(user.ID, store.AsFloat(body["amount"]), time.Now().UnixMilli())
	if err != nil {
		return err
	}
	writeOK(w, http.StatusCreated, map[string]any{"id": id})
	return nil
}

func (s *Server) userInvite(w http.ResponseWriter, r *http.Request) error {
	user, err := s.requireUser(r)
	if err != nil {
		return err
	}
	member, _, err := s.db.LoadMember(user.ID)
	if err != nil {
		return err
	}
	link := strings.TrimRight(s.cfg.PublicBaseURL, "/") + "/?invite=" + member.InviteCode
	settings, err := s.db.CommissionSettings()
	if err != nil {
		return err
	}
	invitees, err := s.db.ListInvitees(user.ID, 50)
	if err != nil {
		return err
	}
	items := make([]map[string]any, 0, len(invitees))
	for _, item := range invitees {
		items = append(items, map[string]any{
			"id": item.ID, "username": item.Username, "createdAt": item.CreatedAt,
			"userType": memberType(item),
		})
	}
	parentName, _ := s.usernameOf(member.ParentID)
	writeOK(w, http.StatusOK, map[string]any{
		"inviteCode": member.InviteCode,
		"inviteUrl":  link,
		"parentId":   member.ParentID,
		"parentName": parentName,
		"invitees":   items,
		"inviteeCount": len(items),
		"mode":       "三级推荐：直接推荐人为一级，其上两级为二级、三级。有经销商归属时只按经销商规则返佣，不叠加。",
		"rules":      settings,
	})
	return nil
}

func (s *Server) publicNotices(w http.ResponseWriter, r *http.Request) error {
	if _, err := s.requireUser(r); err != nil {
		return err
	}
	list, err := s.db.ListNotices(true, time.Now().UnixMilli())
	if err != nil {
		return err
	}
	writeOK(w, http.StatusOK, map[string]any{"announcements": list})
	return nil
}

func (s *Server) publicAds(w http.ResponseWriter, r *http.Request) error {
	if _, err := s.requireUser(r); err != nil {
		return err
	}
	list, err := s.db.ListAds(true, time.Now().UnixMilli())
	if err != nil {
		return err
	}
	writeOK(w, http.StatusOK, map[string]any{"ads": list})
	return nil
}

func (s *Server) publicSupport(w http.ResponseWriter, r *http.Request) error {
	if _, err := s.requireUser(r); err != nil {
		return err
	}
	list, err := s.db.ListServices(true)
	if err != nil {
		return err
	}
	writeOK(w, http.StatusOK, map[string]any{"services": list})
	return nil
}

func (s *Server) userSecurity(w http.ResponseWriter, r *http.Request) error {
	user, err := s.requireUser(r)
	if err != nil {
		return err
	}
	member, _, err := s.db.LoadMember(user.ID)
	if err != nil {
		return err
	}
	writeOK(w, http.StatusOK, map[string]any{
		"email": member.BindEmail, "emailStatus": member.EmailStatus,
		"emailBindAt": member.EmailBindAt, "needBind": member.EmailStatus != 2,
	})
	return nil
}

func (s *Server) sendEmailCode(w http.ResponseWriter, r *http.Request) error {
	body, err := readJSON(r)
	if err != nil {
		return err
	}
	email, err := validate.ParseEmail(body["email"])
	if err != nil {
		return err
	}
	scene := store.AsString(body["scene"])
	if scene == "bind_email" {
		if _, err := s.requireUser(r); err != nil {
			return err
		}
	}
	code, err := s.db.SendEmailCode(email, scene, clientIP(r), deviceOf(r), time.Now().UnixMilli())
	if err != nil {
		return err
	}
	_ = code
	_ = s.db.AddLog("user", 0, "email_code", scene+" "+email, clientIP(r))
	writeOK(w, http.StatusOK, map[string]any{"sent": true, "expireMinutes": 5})
	return nil
}

func (s *Server) bindEmail(w http.ResponseWriter, r *http.Request) error {
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
	if err := s.db.UseEmailCode(email, "bind_email", store.AsString(body["code"]), time.Now().UnixMilli()); err != nil {
		return err
	}
	if err := s.db.BindEmail(user.ID, email, time.Now().UnixMilli()); err != nil {
		return err
	}
	writeOK(w, http.StatusOK, map[string]any{"emailStatus": 2})
	return nil
}

func (s *Server) findAccount(w http.ResponseWriter, r *http.Request) error {
	body, err := readJSON(r)
	if err != nil {
		return err
	}
	email, err := validate.ParseEmail(body["email"])
	if err != nil {
		return err
	}
	if err := s.db.UseEmailCode(email, "find_account", store.AsString(body["code"]), time.Now().UnixMilli()); err != nil {
		return err
	}
	member, ok, err := s.db.FindByBindEmail(email)
	if err != nil {
		return err
	}
	if !ok {
		return notFound("没有找到绑定该邮箱的账号")
	}
	writeOK(w, http.StatusOK, map[string]any{
		"userId":   maskMemberID(member.ID),
		"username": maskName(member.Username),
	})
	return nil
}

func (s *Server) resetPasswordByEmail(w http.ResponseWriter, r *http.Request) error {
	body, err := readJSON(r)
	if err != nil {
		return err
	}
	email, err := validate.ParseEmail(body["email"])
	if err != nil {
		return err
	}
	password, err := validate.ParsePassword(body["password"])
	if err != nil {
		return err
	}
	if err := s.db.UseEmailCode(email, "reset_password", store.AsString(body["code"]), time.Now().UnixMilli()); err != nil {
		return err
	}
	member, ok, err := s.db.FindByBindEmail(email)
	if err != nil || !ok {
		return notFound("没有找到绑定该邮箱的账号")
	}
	if _, err := s.db.UpdateUser(member.ID, store.UserPatch{Password: &password}); err != nil {
		return err
	}
	_ = s.db.AddLog("user", member.ID, "reset_password", email, clientIP(r))
	writeOK(w, http.StatusOK, map[string]any{"reset": true})
	return nil
}

func (s *Server) payCreate(w http.ResponseWriter, r *http.Request) error {
	user, err := s.requireUser(r)
	if err != nil {
		return err
	}
	body, err := readJSON(r)
	if err != nil {
		return err
	}
	order, ok, err := s.db.FindCommerceOrder(store.AsInt64(body["orderId"]))
	if err != nil || !ok || order.UserID != user.ID {
		return notFound("订单不存在")
	}
	if order.PayStatus != 0 {
		return badRequest("订单不在待支付状态")
	}
	writeOK(w, http.StatusOK, s.payPayload(order))
	return nil
}

func (s *Server) payNotifyFourth(w http.ResponseWriter, r *http.Request) error {
	secret, err := s.db.ConfigString("fourth_notify_secret")
	if err != nil {
		return err
	}
	if secret == "" || !auth.SafeEqual(r.Header.Get("X-Fourth-Secret"), secret) {
		return unauthorized("支付通知校验失败")
	}
	body, err := readJSON(r)
	if err != nil {
		return err
	}
	order, err := s.db.MarkCommercePaid(store.AsString(body["orderNo"]), store.AsFloat(body["gatewayFee"]), time.Now().UnixMilli())
	if err != nil {
		return err
	}
	writeOK(w, http.StatusOK, map[string]any{"orderNo": order.OrderNo, "payStatus": order.PayStatus})
	return nil
}

func (s *Server) payRefund(w http.ResponseWriter, r *http.Request) error {
	user, err := s.requireUser(r)
	if err != nil {
		return err
	}
	body, err := readJSON(r)
	if err != nil {
		return err
	}
	id, err := s.db.ApplyRefund(store.AsInt64(body["orderId"]), user.ID, store.AsString(body["reason"]))
	if err != nil {
		return err
	}
	writeOK(w, http.StatusCreated, map[string]any{"id": id})
	return nil
}

func (s *Server) userTickets(w http.ResponseWriter, r *http.Request) error {
	user, err := s.requireUser(r)
	if err != nil {
		return err
	}
	if r.Method == http.MethodPost {
		body, err := readJSON(r)
		if err != nil {
			return err
		}
		title := strings.TrimSpace(store.AsString(body["title"]))
		text := strings.TrimSpace(store.AsString(body["body"]))
		if title == "" || text == "" {
			return badRequest("请填写工单标题和内容")
		}
		id, err := s.db.CreateMemberTicket(user.ID, title, text, time.Now().UnixMilli())
		if err != nil {
			return err
		}
		writeOK(w, http.StatusCreated, map[string]any{"id": id})
		return nil
	}
	list, err := s.db.ListMemberTickets(user.ID)
	if err != nil {
		return err
	}
	writeOK(w, http.StatusOK, map[string]any{"tickets": list})
	return nil
}

func (s *Server) payPayload(order store.CommerceOrder) map[string]any {
	gateway, _ := s.db.ConfigString("fourth_gateway")
	mch, _ := s.db.ConfigString("fourth_mch_id")
	return map[string]any{
		"orderNo": order.OrderNo, "amount": order.Amount, "channel": "fourth",
		"mchId": mch, "gateway": gateway,
	}
}

func (s *Server) memberJSON(m store.Member, withQuota bool) map[string]any {
	parentName, _ := s.usernameOf(m.ParentID)
	distName, _ := s.usernameOf(m.DistributorID)
	rate, hasRate, _ := s.db.MemberRate(m.DistributorID, m.ID)
	distRate, distStatus, _ := s.db.DistributorRate(m.ID)
	item := map[string]any{
		"id": m.ID, "username": m.Username, "avatar": m.Avatar, "phone": m.Phone,
		"email": m.BindEmail, "emailStatus": m.EmailStatus, "userType": memberType(m),
		"isDistributor": m.IsDistributor, "isAgent": m.IsAgent, "commissionMode": m.CommissionMode,
		"walletEnabled": m.WalletEnabled, "canAuthorizeAgent": m.CanAuthorizeAgent,
		"parentId": m.ParentID, "parentName": parentName, "distributorId": m.DistributorID, "distributorName": distName,
		"status": m.MemberStatus, "accountStatus": m.Status, "banReason": m.BanReason,
		"inviteCode": m.InviteCode, "createdAt": m.CreatedAt, "hasCustomRate": hasRate, "customRate": rate,
		"distributorRate": distRate, "distributorStatus": distStatus,
	}
	if withQuota {
		remain := m.Total - m.Upload - m.Download
		now := time.Now().UnixMilli()
		if remain < 0 || (m.ExpireAt > 0 && m.ExpireAt <= now) {
			remain = 0
		}
		left := int64(0)
		if m.ExpireAt > now {
			left = (m.ExpireAt - now) / 1000
		}
		item["trafficRemainGb"] = float64(remain) / (1024 * 1024 * 1024)
		item["expireAt"] = m.ExpireAt
		item["remainSeconds"] = left
	}
	return item
}

func (s *Server) usernameOf(id int64) (string, error) {
	if id == 0 {
		return "", nil
	}
	m, ok, err := s.db.LoadMember(id)
	if err != nil || !ok {
		return "", err
	}
	return m.Username, nil
}

func memberType(m store.Member) string {
	if m.IsDistributor == 1 {
		return "经销商"
	}
	if m.IsAgent == 1 {
		return "代理"
	}
	return "普通用户"
}

func packageJSON(p store.Package) map[string]any {
	return map[string]any{
		"id": p.ID, "name": p.Name, "durationType": p.DurationType, "durationDays": p.DurationDays,
		"trafficGb": p.TrafficGB, "price": p.Price, "status": p.Status,
	}
}

func orderJSON(o store.CommerceOrder, username, packageName string) map[string]any {
	return map[string]any{
		"id": o.ID, "orderNo": o.OrderNo, "userId": o.UserID, "username": username,
		"packageId": o.PackageID, "packageName": packageName, "amount": o.Amount,
		"gatewayFee": o.GatewayFee, "commissionBase": o.CommissionBase, "payChannel": o.PayChannel,
		"payStatus": o.PayStatus, "payTime": o.PayTime, "refundStatus": o.RefundStatus,
		"commissionStatus": o.CommissionStatus, "nodeStartAt": o.NodeStartAt, "nodeEndAt": o.NodeEndAt,
		"trafficGb": o.TrafficGB, "trafficUsedGb": o.TrafficUsedGB, "serviceStatus": o.ServiceStatus,
		"createdAt": o.CreatedAt,
	}
}

func commissionJSON(rows []store.CommissionRow) []map[string]any {
	out := make([]map[string]any, 0, len(rows))
	for _, row := range rows {
		out = append(out, map[string]any{
			"id": row.ID, "orderId": row.OrderID, "userId": row.UserID, "fromUserId": row.FromUserID,
			"level": row.Level, "mode": row.Mode, "rate": row.Rate, "baseAmount": row.BaseAmount,
			"amount": row.Amount, "status": row.Status, "settleMonth": row.SettleMonth, "createdAt": row.CreatedAt,
		})
	}
	return out
}

func (s *Server) writeOrders(w http.ResponseWriter, userID, from, to int64) error {
	list, err := s.db.ListCommerceOrders(userID, from, to, 500)
	if err != nil {
		return err
	}
	names := map[int64]string{}
	out := make([]map[string]any, 0, len(list))
	for _, order := range list {
		name, ok := names[order.UserID]
		if !ok {
			name, _ = s.usernameOf(order.UserID)
			names[order.UserID] = name
		}
		pkgName := ""
		if pkg, err := s.db.PackageForFulfillment(order.PackageID, order.Amount); err == nil {
			pkgName = pkg.Name
		}
		out = append(out, orderJSON(order, name, pkgName))
	}
	var amount float64
	for _, order := range list {
		if order.PayStatus == 1 {
			amount += order.Amount
		}
	}
	writeOK(w, http.StatusOK, map[string]any{"total": len(list), "paidAmount": storeRound(amount), "orders": out})
	return nil
}

func storeRound(v float64) float64 {
	return float64(int(v*100+0.5)) / 100
}

func maskMemberID(id int64) string {
	raw := strconv.FormatInt(id, 10)
	if len(raw) <= 2 {
		return "ID **"
	}
	return "ID **" + raw[len(raw)-2:]
}

func maskName(name string) string {
	runes := []rune(name)
	if len(runes) <= 2 {
		return string(runes[:1]) + "*"
	}
	return string(runes[:1]) + "***" + string(runes[len(runes)-1:])
}

func clientIP(r *http.Request) string {
	if fwd := r.Header.Get("X-Forwarded-For"); fwd != "" {
		return strings.TrimSpace(strings.Split(fwd, ",")[0])
	}
	host, _, err := net.SplitHostPort(r.RemoteAddr)
	if err != nil {
		return r.RemoteAddr
	}
	return host
}

func deviceOf(r *http.Request) string {
	device := r.Header.Get("X-Device")
	if device == "" {
		device = r.UserAgent()
	}
	if len(device) > 200 {
		device = device[:200]
	}
	return device
}

func (s *Server) presentUser(user store.User) AppUser {
	view := appUser(user, s.cfg)
	view.Service = serviceState(user, time.Now(), s.remindDays())
	view.EmailBound = strings.TrimSpace(user.Email) != ""
	if !view.EmailBound {
		view.BindEmailReminder = true
		view.BindEmailMessage = "请绑定邮箱，避免账号丢失"
	}
	return view
}

func userTypeLabel(kind string) string {
	switch kind {
	case "distributor":
		return "经销商"
	case "agent":
		return "代理"
	default:
		return "普通用户"
	}
}

func (s *Server) remindDays() int64 {
	return s.db.SettingInt("expire_remind_days", 3)
}

func serviceState(user store.User, now time.Time, remindDays int64) *ServiceView {
	if remindDays <= 0 {
		remindDays = 3
	}
	used := user.Upload + user.Download
	remainBytes := int64(0)
	if user.Total > used {
		remainBytes = user.Total - used
	}
	nowMs := now.UnixMilli()
	view := &ServiceView{
		TotalBytes: user.Total, UsedBytes: used, RemainingBytes: remainBytes,
		ExpireAt: user.ExpireAt,
	}
	if user.ExpireAt <= 0 {
		return view
	}
	remain := user.ExpireAt - nowMs
	if remain < 0 {
		remain = 0
	}
	view.RemainingMs = remain
	day := int64(24 * time.Hour / time.Millisecond)
	if user.ExpireAt <= nowMs {
		view.Expired = true
		view.RemindMessage = "套餐已到期，请续费后继续使用"
		return view
	}
	if remain <= remindDays*day {
		view.ExpiringSoon = true
		if remain < day {
			view.RemindMessage = "套餐将在 1 天内到期，请及时续费"
		} else {
			days := (remain + day - 1) / day
			view.RemindMessage = fmt.Sprintf("套餐将在 %d 天后到期，请及时续费", days)
		}
	}
	return view
}

func (s *Server) appPlans(w http.ResponseWriter, r *http.Request) error {
	if _, err := s.requireUser(r); err != nil {
		return err
	}
	plans, err := s.db.ListPlans(true)
	if err != nil {
		return err
	}
	items := make([]map[string]any, 0, len(plans))
	for _, plan := range plans {
		items = append(items, planView(plan))
	}
	writeOK(w, http.StatusOK, map[string]any{"items": items})
	return nil
}

func (s *Server) appCheckout(w http.ResponseWriter, r *http.Request) error {
	return s.checkout(w, r, false)
}

func (s *Server) appRenew(w http.ResponseWriter, r *http.Request) error {
	return s.checkout(w, r, true)
}

func (s *Server) checkout(w http.ResponseWriter, r *http.Request, renew bool) error {
	user, err := s.requireUser(r)
	if err != nil {
		return err
	}
	body, err := readJSON(r)
	if err != nil {
		return err
	}
	if !renew {
		if flag, ok := body["renew"].(bool); ok {
			renew = flag
		}
	}
	code := strings.TrimSpace(store.AsString(body["planCode"]))
	plan, ok, err := s.db.FindPlan(code)
	if err != nil {
		return err
	}
	if !ok || !plan.Enabled {
		return badRequest("套餐不存在")
	}
	channel := "epay"
	payURL := ""
	switch {
	case s.cfg.PayGatewayURL != "":
		channel = "epay"
	case s.cfg.PayDebug:
		channel = "debug"
		payURL = strings.TrimRight(s.cfg.PublicBaseURL, "/") + "/api/pay/debug"
	default:
		return errs.New(http.StatusServiceUnavailable, "UNAVAILABLE", "支付网关未配置")
	}
	now := time.Now().UnixMilli()
	title := plan.Name
	if renew {
		title = "续费 " + plan.Name
	}
	order, err := s.db.CreateOrder(store.OrderInput{
		UserID: user.ID, Title: title, Amount: plan.Price, Status: "pending",
		PayChannel: channel, Now: now, PlanCode: plan.Code,
		TrafficBytes: plan.TrafficGB * 1024 * 1024 * 1024,
		DurationMs:   plan.DurationDays * 24 * 3600 * 1000,
		Renew:        renew,
	})
	if err != nil {
		return err
	}
	if channel == "epay" {
		base := strings.TrimRight(s.cfg.PublicBaseURL, "/")
		link, err := pay.Create(s.cfg, pay.Order{
			No: order.OrderNo, Name: title, Amount: order.Amount,
			NotifyURL: base + "/api/pay/notify",
			ReturnURL: base + "/api/app/orders",
		})
		if err != nil {
			return errs.New(http.StatusBadGateway, "UPSTREAM", "支付下单失败")
		}
		payURL = link
	}
	writeOK(w, http.StatusCreated, map[string]any{
		"order": orderView(order, nil), "payUrl": payURL, "channel": channel,
	})
	return nil
}

func (s *Server) payNotify(w http.ResponseWriter, r *http.Request) error {
	if err := r.ParseForm(); err != nil {
		writeText(w, http.StatusBadRequest, "fail", nil)
		return nil
	}
	orderNo, tradeNo, err := pay.VerifyNotify(s.cfg, r.Form)
	if err != nil {
		writeText(w, http.StatusBadRequest, "fail", nil)
		return nil
	}
	order, ok, err := s.db.FindOrderByNo(orderNo)
	if err != nil || !ok {
		writeText(w, http.StatusBadRequest, "fail", nil)
		return nil
	}
	if money := r.Form.Get("money"); money != "" && money != pay.Yuan(order.Amount) {
		writeText(w, http.StatusBadRequest, "fail", nil)
		return nil
	}
	if _, _, err := s.db.MarkOrderPaid(orderNo, tradeNo, time.Now().UnixMilli()); err != nil {
		writeText(w, http.StatusBadRequest, "fail", nil)
		return nil
	}
	s.syncNodes()
	writeText(w, http.StatusOK, "success", nil)
	return nil
}

func (s *Server) payDebug(w http.ResponseWriter, r *http.Request) error {
	if !s.cfg.PayDebug {
		return notFound("接口不存在")
	}
	body, err := readJSON(r)
	if err != nil {
		return err
	}
	orderNo := strings.TrimSpace(store.AsString(body["orderNo"]))
	if orderNo == "" {
		orderNo = strings.TrimSpace(r.URL.Query().Get("orderNo"))
	}
	if orderNo == "" {
		return badRequest("缺少订单号")
	}
	order, already, err := s.db.MarkOrderPaid(orderNo, "debug", time.Now().UnixMilli())
	if err != nil {
		return err
	}
	s.syncNodes()
	writeOK(w, http.StatusOK, map[string]any{
		"order": orderView(order, nil), "alreadyPaid": already,
	})
	return nil
}

func (s *Server) appService(w http.ResponseWriter, r *http.Request) error {
	user, err := s.requireUser(r)
	if err != nil {
		return err
	}
	writeOK(w, http.StatusOK, serviceState(user, time.Now(), s.remindDays()))
	return nil
}

func (s *Server) appWallet(w http.ResponseWriter, r *http.Request) error {
	user, err := s.requireUser(r)
	if err != nil {
		return err
	}
	view, err := s.walletView(user)
	if err != nil {
		return err
	}
	writeOK(w, http.StatusOK, view)
	return nil
}

func (s *Server) appRebates(w http.ResponseWriter, r *http.Request) error {
	user, err := s.requireUser(r)
	if err != nil {
		return err
	}
	if user.WalletEnabled != 1 {
		return forbidden("钱包未开通")
	}
	rows, err := s.db.ListCommissions(user.ID, 0)
	if err != nil {
		return err
	}
	writeOK(w, http.StatusOK, map[string]any{"items": commissionViews(rows)})
	return nil
}

func (s *Server) appWithdraw(w http.ResponseWriter, r *http.Request) error {
	user, err := s.requireUser(r)
	if err != nil {
		return err
	}
	if user.WalletEnabled != 1 {
		return forbidden("钱包未开通")
	}
	body, err := readJSON(r)
	if err != nil {
		return err
	}
	amount, err := validateAmount(body["amount"])
	if err != nil {
		return err
	}
	account := clipText(strings.TrimSpace(store.AsString(body["account"])), 120)
	if account == "" {
		return badRequest("请填写提现账户")
	}
	minAmount := s.db.SettingInt("withdraw_min_cents", 10000)
	if amount < minAmount {
		return badRequest("未达到最低提现金额")
	}
	feePercent := int(s.db.SettingInt("withdraw_fee_percent", 0))
	item, err := s.db.RequestWithdraw(user.ID, amount, account, feePercent, time.Now().UnixMilli())
	if err != nil {
		return err
	}
	writeOK(w, http.StatusCreated, withdrawalView(item))
	return nil
}

func (s *Server) appPromotion(w http.ResponseWriter, r *http.Request) error {
	user, err := s.requireUser(r)
	if err != nil {
		return err
	}
	team, err := s.teamItems(user.ID)
	if err != nil {
		return err
	}
	pool := s.db.SettingInt("commission_pool_percent", 50)
	writeOK(w, http.StatusOK, map[string]any{
		"invite": s.inviteView(user),
		"rules": map[string]any{
			"system":      "分佣池默认 50%，平台后台可调整。订单金额乘以分佣池比例得到总分佣，再按一级 60%、二级 30%、三级 10% 分配。层级占比固定为 100%，不可修改。",
			"distributor": "直接推荐人是经销商时，只按该经销商自己的比例发放，不触发三级分佣。直接推荐人是会员或代理，且归属经销商已设置其返佣比例时，只发给直接推荐人。会员返佣比例不能超过经销商本人的分佣比例。未归属经销商或未设置会员比例时，走系统三级分佣。两种模式互斥，不叠加。",
		},
		"example": commissionPreview(10000, pool),
		"team":    team,
	})
	return nil
}

func (s *Server) appTeam(w http.ResponseWriter, r *http.Request) error {
	user, err := s.requireUser(r)
	if err != nil {
		return err
	}
	items, err := s.teamItems(user.ID)
	if err != nil {
		return err
	}
	writeOK(w, http.StatusOK, map[string]any{"items": items})
	return nil
}

func (s *Server) appInvite(w http.ResponseWriter, r *http.Request) error {
	user, err := s.requireUser(r)
	if err != nil {
		return err
	}
	writeOK(w, http.StatusOK, s.inviteView(user))
	return nil
}

func (s *Server) appInviteQR(w http.ResponseWriter, r *http.Request) error {
	user, err := s.requireUser(r)
	if err != nil {
		return err
	}
	png, err := qrcode.Encode(s.inviteLink(user), qrcode.Medium, 256)
	if err != nil {
		return err
	}
	w.Header().Set("Content-Type", "image/png")
	w.WriteHeader(http.StatusOK)
	_, _ = w.Write(png)
	return nil
}

func (s *Server) legacyDistributorMembers(w http.ResponseWriter, r *http.Request) error {
	user, err := s.legacyRequireDistributor(r)
	if err != nil {
		return err
	}
	rows, err := s.db.ListDownline(user.ID)
	if err != nil {
		return err
	}
	items := make([]map[string]any, 0, len(rows))
	for _, row := range rows {
		items = append(items, memberView(row))
	}
	writeOK(w, http.StatusOK, map[string]any{"items": items})
	return nil
}

func (s *Server) legacyDistributorSetAgent(w http.ResponseWriter, r *http.Request) error {
	self, err := s.legacyRequireDistributor(r)
	if err != nil {
		return err
	}
	member, err := s.ownMember(r, self.ID)
	if err != nil {
		return err
	}
	body, err := readJSON(r)
	if err != nil {
		return err
	}
	enabled, ok := body["enabled"].(bool)
	if !ok {
		return badRequest("请指定是否授权代理")
	}
	updated, err := s.db.SetAgent(member.ID, enabled)
	if err != nil {
		return err
	}
	writeOK(w, http.StatusOK, memberView(updated))
	return nil
}

func (s *Server) legacyDistributorSetRate(w http.ResponseWriter, r *http.Request) error {
	self, err := s.legacyRequireDistributor(r)
	if err != nil {
		return err
	}
	member, err := s.ownMember(r, self.ID)
	if err != nil {
		return err
	}
	body, err := readJSON(r)
	if err != nil {
		return err
	}
	if _, ok := body["rate"]; !ok {
		return badRequest("请填写返佣比例")
	}
	updated, err := s.db.SetMemberRate(member.ID, int(store.AsInt64(body["rate"])))
	if err != nil {
		return err
	}
	writeOK(w, http.StatusOK, memberView(updated))
	return nil
}

func (s *Server) legacyDistributorCommissions(w http.ResponseWriter, r *http.Request) error {
	user, err := s.legacyRequireDistributor(r)
	if err != nil {
		return err
	}
	rows, err := s.db.ListCommissions(0, user.ID)
	if err != nil {
		return err
	}
	writeOK(w, http.StatusOK, map[string]any{"items": commissionViews(rows)})
	return nil
}

func (s *Server) legacyDistributorBanRequest(w http.ResponseWriter, r *http.Request) error {
	self, err := s.legacyRequireDistributor(r)
	if err != nil {
		return err
	}
	member, err := s.ownMember(r, self.ID)
	if err != nil {
		return err
	}
	body, err := readJSON(r)
	if err != nil {
		return err
	}
	reason := clipText(strings.TrimSpace(store.AsString(body["reason"])), 200)
	if reason == "" {
		return badRequest("请填写申请原因")
	}
	item, err := s.db.CreatePlatformRequest(self.ID, member.ID, "ban", reason, time.Now().UnixMilli())
	if err != nil {
		return err
	}
	writeOK(w, http.StatusCreated, requestView(item))
	return nil
}

func (s *Server) legacyAdminSetDistributor(w http.ResponseWriter, r *http.Request) error {
	if err := s.requireAdmin(r); err != nil {
		return err
	}
	id, err := idParam(r)
	if err != nil {
		return err
	}
	body, err := readJSON(r)
	if err != nil {
		return err
	}
	enabled, ok := body["enabled"].(bool)
	if !ok {
		return badRequest("请指定是否设为经销商")
	}
	user, err := s.db.SetDistributor(id, enabled, int(store.AsInt64(body["rate"])))
	if err != nil {
		return err
	}
	s.syncNodes()
	view, err := s.oneUser(user)
	if err != nil {
		return err
	}
	writeOK(w, http.StatusOK, view)
	return nil
}

func (s *Server) adminPatchPlan(w http.ResponseWriter, r *http.Request) error {
	if err := s.requireAdmin(r); err != nil {
		return err
	}
	code := param(r, "code")
	plan, ok, err := s.db.FindPlan(code)
	if err != nil {
		return err
	}
	if !ok {
		return notFound("套餐不存在")
	}
	body, err := readJSON(r)
	if err != nil {
		return err
	}
	if value, ok := body["name"]; ok && value != nil {
		plan.Name = clipText(strings.TrimSpace(store.AsString(value)), 40)
	}
	if value, ok := body["price"]; ok && value != nil {
		plan.Price, err = validateAmount(value)
		if err != nil {
			return err
		}
	}
	if value, ok := body["trafficGb"]; ok && value != nil {
		plan.TrafficGB, err = validateAmount(value)
		if err != nil {
			return err
		}
	}
	if value, ok := body["durationDays"]; ok && value != nil {
		plan.DurationDays, err = validateAmount(value)
		if err != nil {
			return err
		}
	}
	if value, ok := body["enabled"].(bool); ok {
		plan.Enabled = value
	}
	updated, err := s.db.UpdatePlan(plan)
	if err != nil {
		return err
	}
	writeOK(w, http.StatusOK, planView(updated))
	return nil
}

func (s *Server) adminCommissionPreview(w http.ResponseWriter, r *http.Request) error {
	if err := s.requireAdmin(r); err != nil {
		return err
	}
	amount := int64(10000)
	if raw := r.URL.Query().Get("amount"); raw != "" {
		parsed, err := validateAmount(raw)
		if err != nil {
			return err
		}
		amount = parsed
	}
	pool := s.db.SettingInt("commission_pool_percent", 50)
	writeOK(w, http.StatusOK, commissionPreview(amount, pool))
	return nil
}

func (s *Server) adminSettleCommissions(w http.ResponseWriter, r *http.Request) error {
	if err := s.requireAdmin(r); err != nil {
		return err
	}
	var count int
	var err error
	if r.URL.Query().Get("force") == "1" {
		count, err = s.db.SettlePending(time.Now().UnixMilli())
	} else {
		count, err = s.db.SettleDue(time.Now())
	}
	if err != nil {
		return err
	}
	writeOK(w, http.StatusOK, map[string]any{"settled": count})
	return nil
}

func (s *Server) legacyAdminWithdrawals(w http.ResponseWriter, r *http.Request) error {
	if err := s.requireAdmin(r); err != nil {
		return err
	}
	rows, err := s.db.ListWithdrawals(0)
	if err != nil {
		return err
	}
	items := make([]map[string]any, 0, len(rows))
	for _, row := range rows {
		items = append(items, withdrawalView(row))
	}
	writeOK(w, http.StatusOK, map[string]any{"items": items})
	return nil
}

func (s *Server) adminReviewWithdraw(w http.ResponseWriter, r *http.Request) error {
	if err := s.requireAdmin(r); err != nil {
		return err
	}
	id, err := idParam(r)
	if err != nil {
		return err
	}
	body, err := readJSON(r)
	if err != nil {
		return err
	}
	approve, ok := body["approve"].(bool)
	if !ok {
		return badRequest("请指定审核结果")
	}
	item, err := s.db.ReviewWithdraw(id, approve, time.Now().UnixMilli())
	if err != nil {
		return err
	}
	writeOK(w, http.StatusOK, withdrawalView(item))
	return nil
}

func (s *Server) adminRequests(w http.ResponseWriter, r *http.Request) error {
	if err := s.requireAdmin(r); err != nil {
		return err
	}
	rows, err := s.db.ListPlatformRequests()
	if err != nil {
		return err
	}
	items := make([]map[string]any, 0, len(rows))
	for _, row := range rows {
		items = append(items, requestView(row))
	}
	writeOK(w, http.StatusOK, map[string]any{"items": items})
	return nil
}

func (s *Server) adminReviewRequest(w http.ResponseWriter, r *http.Request) error {
	if err := s.requireAdmin(r); err != nil {
		return err
	}
	id, err := idParam(r)
	if err != nil {
		return err
	}
	body, err := readJSON(r)
	if err != nil {
		return err
	}
	approve, ok := body["approve"].(bool)
	if !ok {
		return badRequest("请指定审核结果")
	}
	item, err := s.db.ReviewPlatformRequest(id, approve)
	if err != nil {
		return err
	}
	if approve && item.Action == "ban" {
		status := "disabled"
		if _, err := s.db.UpdateUser(item.TargetID, store.UserPatch{Status: &status}); err != nil {
			return err
		}
		s.syncNodes()
	}
	writeOK(w, http.StatusOK, requestView(item))
	return nil
}

func (s *Server) legacyAdminTickets(w http.ResponseWriter, r *http.Request) error {
	if err := s.requireAdmin(r); err != nil {
		return err
	}
	rows, err := s.db.ListAllTickets()
	if err != nil {
		return err
	}
	writeOK(w, http.StatusOK, map[string]any{"items": ticketViews(rows)})
	return nil
}

func (s *Server) adminPatchTicket(w http.ResponseWriter, r *http.Request) error {
	if err := s.requireAdmin(r); err != nil {
		return err
	}
	id, err := idParam(r)
	if err != nil {
		return err
	}
	body, err := readJSON(r)
	if err != nil {
		return err
	}
	status := strings.TrimSpace(store.AsString(body["status"]))
	switch status {
	case "open", "replied", "closed":
	default:
		return badRequest("工单状态不正确")
	}
	ticket, err := s.db.UpdateTicketStatus(id, status)
	if err != nil {
		return err
	}
	writeOK(w, http.StatusOK, ticketView(ticket))
	return nil
}

func (s *Server) adminSupport(w http.ResponseWriter, r *http.Request) error {
	if err := s.requireAdmin(r); err != nil {
		return err
	}
	settings, err := s.db.GetSettings()
	if err != nil {
		return err
	}
	writeOK(w, http.StatusOK, supportFields(settings))
	return nil
}

func (s *Server) adminPutSupport(w http.ResponseWriter, r *http.Request) error {
	if err := s.requireAdmin(r); err != nil {
		return err
	}
	body, err := readJSON(r)
	if err != nil {
		return err
	}
	mapping := map[string]string{
		"supportWechat": "support_wechat", "supportQq": "support_qq",
		"supportTelegram": "support_telegram", "supportOnline": "support_online",
		"supportQrcode": "support_qrcode",
	}
	patch := map[string]string{}
	for key, setting := range mapping {
		if value, ok := body[key]; ok && value != nil {
			patch[setting] = clipText(strings.TrimSpace(store.AsString(value)), 200)
		}
	}
	if _, err := s.db.SetSettings(patch); err != nil {
		return err
	}
	settings, err := s.db.GetSettings()
	if err != nil {
		return err
	}
	writeOK(w, http.StatusOK, supportFields(settings))
	return nil
}

func (s *Server) legacyRequireDistributor(r *http.Request) (store.User, error) {
	user, err := s.requireUser(r)
	if err != nil {
		return store.User{}, err
	}
	if user.IsDistributor != 1 {
		return store.User{}, forbidden("当前账号没有经销商后台权限")
	}
	return user, nil
}

func (s *Server) ownMember(r *http.Request, distributorID int64) (store.User, error) {
	id, err := idParam(r)
	if err != nil {
		return store.User{}, err
	}
	member, ok, err := s.db.FindUserByID(id)
	if err != nil {
		return store.User{}, err
	}
	if !ok || member.DistributorID != distributorID {
		return store.User{}, forbidden("只能管理自己旗下会员")
	}
	return member, nil
}

func (s *Server) walletView(user store.User) (map[string]any, error) {
	if user.WalletEnabled != 1 {
		return map[string]any{
			"enabled": false, "reason": "有上级经销商且未授权代理，钱包未开通",
			"totalEarned": int64(0), "balance": int64(0), "frozen": int64(0), "negativeBalance": int64(0),
			"totalEarnedYuan": "0.00", "balanceYuan": "0.00", "frozenYuan": "0.00", "negativeBalanceYuan": "0.00",
			"deductions": []map[string]any{},
		}, nil
	}
	wallet, err := s.db.WalletOf(user.ID)
	if err != nil {
		return nil, err
	}
	entries, err := s.db.ListWalletEntries(user.ID, "")
	if err != nil {
		return nil, err
	}
	negative := int64(0)
	if wallet.Balance < 0 {
		negative = -wallet.Balance
	}
	deductions := make([]map[string]any, 0)
	for _, entry := range entries {
		if entry.Kind != "refund_clawback" {
			continue
		}
		deductions = append(deductions, map[string]any{
			"id": entry.ID, "amount": entry.Amount, "amountYuan": yuan(entry.Amount),
			"balanceAfter": entry.BalanceAfter, "detail": entry.Detail, "createdAt": entry.CreatedAt,
		})
	}
	return map[string]any{
		"enabled":     true,
		"totalEarned": wallet.Earned, "totalEarnedYuan": yuan(wallet.Earned),
		"balance": wallet.Balance, "balanceYuan": yuan(wallet.Balance),
		"frozen": wallet.Frozen, "frozenYuan": yuan(wallet.Frozen),
		"negativeBalance": negative, "negativeBalanceYuan": yuan(negative),
		"deductions": deductions,
	}, nil
}

func (s *Server) teamItems(userID int64) ([]map[string]any, error) {
	users, levels, err := s.db.ListTeam(userID, 200)
	if err != nil {
		return nil, err
	}
	items := make([]map[string]any, 0, len(users))
	for i, user := range users {
		items = append(items, map[string]any{
			"id": user.ID, "username": user.Username, "nickname": user.Nickname,
			"userType": user.UserType, "userTypeLabel": userTypeLabel(user.UserType),
			"level": levels[i], "walletEnabled": user.WalletEnabled, "isAgent": user.IsAgent,
		})
	}
	return items, nil
}

func (s *Server) inviteView(user store.User) map[string]any {
	return map[string]any{
		"inviteCode": user.InviteCode,
		"inviteLink": s.inviteLink(user),
		"qrUrl":      "/api/app/invite/qr.png",
	}
}

func (s *Server) inviteLink(user store.User) string {
	return strings.TrimRight(s.cfg.PublicBaseURL, "/") + "/invite/" + url.PathEscape(user.InviteCode)
}

func memberView(user store.User) map[string]any {
	return map[string]any{
		"id": user.ID, "username": user.Username, "nickname": user.Nickname,
		"userType": user.UserType, "userTypeLabel": userTypeLabel(user.UserType),
		"isAgent": user.IsAgent, "isDistributor": user.IsDistributor,
		"walletEnabled": user.WalletEnabled, "memberRate": user.MemberRate,
		"status": user.Status,
	}
}

func planView(plan store.Plan) map[string]any {
	return map[string]any{
		"code": plan.Code, "name": plan.Name, "price": plan.Price, "priceYuan": yuan(plan.Price),
		"trafficGb": plan.TrafficGB, "durationDays": plan.DurationDays,
	}
}

func commissionViews(rows []store.Commission) []map[string]any {
	items := make([]map[string]any, 0, len(rows))
	for _, row := range rows {
		items = append(items, commissionView(row))
	}
	return items
}

func commissionView(row store.Commission) map[string]any {
	mode := "系统固定三级返点"
	if row.Mode == 1 {
		mode = "经销商自定义返佣"
	}
	status := "待结算"
	switch row.Status {
	case "settled":
		status = "已结算"
	case "reversed":
		status = "已退回"
	}
	return map[string]any{
		"id": row.ID, "orderId": row.OrderID, "orderNo": row.OrderNo,
		"buyerId": row.BuyerID, "buyerName": row.BuyerName, "beneficiaryId": row.BeneficiaryID,
		"level": row.Level, "mode": row.Mode, "modeLabel": mode, "rate": row.Rate,
		"baseAmount": row.BaseAmount, "amount": row.Amount, "amountYuan": yuan(row.Amount),
		"reversedAmount": row.ReversedAmount, "status": row.Status, "statusLabel": status,
		"createdAt": row.CreatedAt, "settledAt": row.SettledAt,
	}
}

func withdrawalView(item store.Withdrawal) map[string]any {
	label := "待审核"
	switch item.Status {
	case "approved":
		label = "已通过"
	case "rejected":
		label = "已拒绝"
	}
	return map[string]any{
		"id": item.ID, "userId": item.UserID,
		"amount": item.Amount, "amountYuan": yuan(item.Amount),
		"fee": item.Fee, "feeYuan": yuan(item.Fee),
		"netAmount": item.NetAmount, "netAmountYuan": yuan(item.NetAmount),
		"account": item.Account, "status": item.Status, "statusLabel": label,
		"createdAt": item.CreatedAt, "reviewedAt": item.ReviewedAt,
	}
}

func requestView(item store.PlatformRequest) map[string]any {
	return map[string]any{
		"id": item.ID, "requesterId": item.RequesterID, "targetId": item.TargetID,
		"action": item.Action, "reason": item.Reason, "status": item.Status, "createdAt": item.CreatedAt,
	}
}

func supportFields(settings map[string]string) map[string]any {
	return map[string]any{
		"supportWechat": settings["support_wechat"], "supportQq": settings["support_qq"],
		"supportTelegram": settings["support_telegram"], "supportOnline": settings["support_online"],
		"supportQrcode": settings["support_qrcode"],
	}
}

func commissionPreview(base, pool int64) map[string]any {
	total, l1, l2, l3 := store.SplitCommission(base, pool)
	return map[string]any{
		"chain":      "A 推荐 B，B 推荐 C，C 推荐 D，D 购买套餐",
		"baseAmount": base, "poolPercent": pool, "totalCommission": total,
		"levelPercents": map[string]int{"level1": store.Level1Percent, "level2": store.Level2Percent, "level3": store.Level3Percent},
		"levels": []map[string]any{
			{"user": "C", "level": 1, "title": "一级直接推荐人", "percent": store.Level1Percent, "amount": l1},
			{"user": "B", "level": 2, "title": "二级上级", "percent": store.Level2Percent, "amount": l2},
			{"user": "A", "level": 3, "title": "三级上级", "percent": store.Level3Percent, "amount": l3},
		},
		"note": "层级占比固定为 60%、30%、10%，不可修改。分佣池比例可在后台调整。",
	}
}

func validateAmount(value any) (int64, error) {
	amount, err := parseSetting(fmt.Sprint(value))
	if err != nil || amount <= 0 {
		return 0, badRequest("金额不正确")
	}
	return amount, nil
}
