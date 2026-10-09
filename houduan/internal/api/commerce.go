package api

import (
	"net"
	"net/http"
	"strconv"
	"strings"
	"time"

	"xvay/houduan/internal/auth"
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
	_, _ = s.db.SettleDue(time.Now())
	writeOK(w, http.StatusOK, s.memberJSON(member, true))
	return nil
}

func (s *Server) listPackages(w http.ResponseWriter, r *http.Request) error {
	if _, err := s.requireUser(r); err != nil {
		return err
	}
	list, err := s.db.ListPackages(true)
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
	_, _ = s.db.SettleDue(time.Now())
	wallet, err := s.db.Wallet(user.ID)
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
	id, err := s.db.RequestWithdraw(user.ID, store.AsFloat(body["amount"]), time.Now().UnixMilli())
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
	writeOK(w, http.StatusOK, map[string]any{
		"inviteCode": member.InviteCode,
		"inviteUrl":  link,
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
		"userId":   maskID(member.ID),
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
	order, ok, err := s.db.FindOrder(store.AsInt64(body["orderId"]))
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
	order, err := s.db.MarkOrderPaid(store.AsString(body["orderNo"]), store.AsFloat(body["gatewayFee"]), time.Now().UnixMilli())
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
		id, err := s.db.CreateTicket(user.ID, title, text, time.Now().UnixMilli())
		if err != nil {
			return err
		}
		writeOK(w, http.StatusCreated, map[string]any{"id": id})
		return nil
	}
	list, err := s.db.ListTickets(user.ID)
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
	pkgs, _ := s.db.ListPackages(false)
	pkgName := map[int64]string{}
	for _, p := range pkgs {
		pkgName[p.ID] = p.Name
	}
	out := make([]map[string]any, 0, len(list))
	for _, order := range list {
		name, ok := names[order.UserID]
		if !ok {
			name, _ = s.usernameOf(order.UserID)
			names[order.UserID] = name
		}
		out = append(out, orderJSON(order, name, pkgName[order.PackageID]))
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

func maskID(id int64) string {
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
