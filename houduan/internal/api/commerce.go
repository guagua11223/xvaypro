package api

import (
	"fmt"
	"net/http"
	"net/url"
	"strings"
	"time"

	"github.com/skip2/go-qrcode"

	"xvay/houduan/internal/errs"
	"xvay/houduan/internal/pay"
	"xvay/houduan/internal/store"
)

func (s *Server) presentUser(user store.User) AppUser {
	view := appUser(user, s.cfg)
	view.Service = serviceState(user, time.Now(), s.remindDays())
	return view
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

func (s *Server) distributorMembers(w http.ResponseWriter, r *http.Request) error {
	user, err := s.requireDistributor(r)
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

func (s *Server) distributorSetAgent(w http.ResponseWriter, r *http.Request) error {
	self, err := s.requireDistributor(r)
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

func (s *Server) distributorSetRate(w http.ResponseWriter, r *http.Request) error {
	self, err := s.requireDistributor(r)
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

func (s *Server) distributorCommissions(w http.ResponseWriter, r *http.Request) error {
	user, err := s.requireDistributor(r)
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

func (s *Server) distributorBanRequest(w http.ResponseWriter, r *http.Request) error {
	self, err := s.requireDistributor(r)
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

func (s *Server) adminSetDistributor(w http.ResponseWriter, r *http.Request) error {
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

func (s *Server) adminWithdrawals(w http.ResponseWriter, r *http.Request) error {
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

func (s *Server) adminTickets(w http.ResponseWriter, r *http.Request) error {
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

func (s *Server) requireDistributor(r *http.Request) (store.User, error) {
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
