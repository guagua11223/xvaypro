package api

import (
	"encoding/csv"
	"net/http"
	"strconv"
	"strings"
	"time"

	"xvay/houduan/internal/auth"
	"xvay/houduan/internal/store"
)

func (s *Server) allowRole(r *http.Request, extra ...string) error {
	if err := s.requireAdmin(r); err != nil {
		return err
	}
	role, _ := s.staffRole(r)
	if role == "super" || role == "operator" {
		return nil
	}
	for _, item := range extra {
		if role == item {
			return nil
		}
	}
	return forbidden("没有权限")
}

func (s *Server) staffRole(r *http.Request) (string, int64) {
	token := bearer(r)
	if s.cfg.AdminToken != "" && auth.SafeEqual(token, s.cfg.AdminToken) {
		return "super", 0
	}
	id, ok, err := s.db.AdminIDBySession(token, time.Now().UnixMilli())
	if err != nil || !ok {
		return "operator", 0
	}
	admin, found, err := s.db.GetCatalog("admins", id)
	if err != nil || !found {
		return "operator", id
	}
	role := store.AsString(admin["role"])
	if role == "" {
		role = "operator"
	}
	return role, id
}

func (s *Server) adminStats(w http.ResponseWriter, r *http.Request) error {
	if err := s.allowRole(r, "finance", "support"); err != nil {
		return err
	}
	_, _ = s.db.SettleDue(time.Now())
	stats, err := s.db.MemberStats(time.Now())
	if err != nil {
		return err
	}
	writeOK(w, http.StatusOK, stats)
	return nil
}

func (s *Server) adminMembers(w http.ResponseWriter, r *http.Request) error {
	if err := s.allowRole(r, "finance", "support"); err != nil {
		return err
	}
	list, err := s.db.ListMembers(r.URL.Query().Get("q"), 300)
	if err != nil {
		return err
	}
	out := make([]map[string]any, 0, len(list))
	for _, item := range list {
		out = append(out, s.memberJSON(item, false))
	}
	writeOK(w, http.StatusOK, map[string]any{"members": out})
	return nil
}

func (s *Server) adminSetDistributor(w http.ResponseWriter, r *http.Request) error {
	if err := s.allowRole(r); err != nil {
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
	rate := store.AsFloat(body["rate"])
	if rate == 0 {
		rate, err = s.db.ConfigFloat("distributor_default_rate", 55)
		if err != nil {
			return err
		}
	}
	if strings.HasSuffix(r.URL.Path, "/cancel") {
		if err := s.db.CancelDistributor(id); err != nil {
			return err
		}
		_, roleID := s.staffRole(r)
		_ = s.db.AddLog("admin", roleID, "cancel_distributor", strconv.FormatInt(id, 10), clientIP(r))
		writeOK(w, http.StatusOK, map[string]any{"id": id, "isDistributor": 0})
		return nil
	}
	if err := s.db.SetDistributor(id, rate, time.Now().UnixMilli()); err != nil {
		return err
	}
	_, roleID := s.staffRole(r)
	_ = s.db.AddLog("admin", roleID, "set_distributor", strconv.FormatInt(id, 10), clientIP(r))
	writeOK(w, http.StatusOK, map[string]any{"id": id, "isDistributor": 1, "rate": rate})
	return nil
}

func (s *Server) adminSetAgent(w http.ResponseWriter, r *http.Request) error {
	if err := s.allowRole(r); err != nil {
		return err
	}
	id, err := idParam(r)
	if err != nil {
		return err
	}
	if err := s.db.AuthorizeAgent(0, id, true); err != nil {
		return err
	}
	writeOK(w, http.StatusOK, map[string]any{"id": id, "isAgent": 1})
	return nil
}

func (s *Server) adminBan(w http.ResponseWriter, r *http.Request) error {
	if err := s.allowRole(r); err != nil {
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
	reason := store.AsString(body["reason"])
	if reason == "" {
		reason = "平台封禁"
	}
	if err := s.db.BanMember(id, reason, time.Now().UnixMilli()); err != nil {
		return err
	}
	_, actor := s.staffRole(r)
	_ = s.db.AddLog("admin", actor, "ban", reason, clientIP(r))
	writeOK(w, http.StatusOK, map[string]any{"id": id, "status": 1})
	return nil
}

func (s *Server) adminUnban(w http.ResponseWriter, r *http.Request) error {
	if err := s.allowRole(r); err != nil {
		return err
	}
	id, err := idParam(r)
	if err != nil {
		return err
	}
	if err := s.db.UnbanMember(id, time.Now().UnixMilli()); err != nil {
		return err
	}
	writeOK(w, http.StatusOK, map[string]any{"id": id, "status": 0})
	return nil
}

func (s *Server) adminUnbindEmail(w http.ResponseWriter, r *http.Request) error {
	if err := s.allowRole(r); err != nil {
		return err
	}
	id, err := idParam(r)
	if err != nil {
		return err
	}
	if err := s.db.UnbindEmail(id); err != nil {
		return err
	}
	_, actor := s.staffRole(r)
	_ = s.db.AddLog("admin", actor, "unbind_email", strconv.FormatInt(id, 10), clientIP(r))
	writeOK(w, http.StatusOK, map[string]any{"id": id, "emailStatus": 0})
	return nil
}

func (s *Server) adminSetParent(w http.ResponseWriter, r *http.Request) error {
	if err := s.allowRole(r); err != nil {
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
	if err := s.db.SetParent(id, store.AsInt64(body["parentId"])); err != nil {
		return err
	}
	writeOK(w, http.StatusOK, map[string]any{"id": id})
	return nil
}

func (s *Server) adminMemberRecords(w http.ResponseWriter, r *http.Request) error {
	if err := s.allowRole(r, "finance", "support"); err != nil {
		return err
	}
	id, err := idParam(r)
	if err != nil {
		return err
	}
	orders, err := s.db.ListCommerceOrders(id, 0, 0, 50)
	if err != nil {
		return err
	}
	comms, err := s.db.ListCommissionRows(id, 50)
	if err != nil {
		return err
	}
	withdraws, err := s.db.ListWithdrawals(id, 50)
	if err != nil {
		return err
	}
	writeOK(w, http.StatusOK, map[string]any{
		"orders": orderListJSON(orders), "commissions": commissionJSON(comms), "withdrawals": withdraws,
	})
	return nil
}

func (s *Server) adminDistributors(w http.ResponseWriter, r *http.Request) error {
	if err := s.allowRole(r, "finance"); err != nil {
		return err
	}
	list, err := s.db.ListMembers("", 500)
	if err != nil {
		return err
	}
	out := []map[string]any{}
	for _, item := range list {
		if item.IsDistributor != 1 {
			continue
		}
		rate, status, err := s.db.DistributorRate(item.ID)
		if err != nil {
			return err
		}
		direct, indirect, err := s.db.CountDownline(item.ID)
		if err != nil {
			return err
		}
		wallet, err := s.db.Wallet(item.ID)
		if err != nil {
			return err
		}
		out = append(out, map[string]any{
			"id": item.ID, "username": item.Username, "members": direct + indirect, "direct": direct, "indirect": indirect,
			"rate": rate, "status": status, "totalCommission": wallet.TotalIncome, "balance": wallet.Balance,
		})
	}
	writeOK(w, http.StatusOK, map[string]any{"distributors": out})
	return nil
}

func (s *Server) adminDistributorRate(w http.ResponseWriter, r *http.Request) error {
	if err := s.allowRole(r); err != nil {
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
	if err := s.db.SetDistributorRate(id, store.AsFloat(body["rate"])); err != nil {
		return err
	}
	writeOK(w, http.StatusOK, map[string]any{"id": id, "rate": store.AsFloat(body["rate"])})
	return nil
}

func (s *Server) adminCommerceOrders(w http.ResponseWriter, r *http.Request) error {
	if err := s.allowRole(r, "finance", "support"); err != nil {
		return err
	}
	from := store.AsInt64(r.URL.Query().Get("from"))
	to := store.AsInt64(r.URL.Query().Get("to"))
	if r.URL.Query().Get("export") == "1" {
		return s.exportOrders(w, from, to)
	}
	return s.writeOrders(w, 0, from, to)
}

func (s *Server) exportOrders(w http.ResponseWriter, from, to int64) error {
	list, err := s.db.ListCommerceOrders(0, from, to, 2000)
	if err != nil {
		return err
	}
	w.Header().Set("Content-Type", "text/csv; charset=utf-8")
	w.Header().Set("Content-Disposition", "attachment; filename=orders.csv")
	_, _ = w.Write([]byte{0xEF, 0xBB, 0xBF})
	cw := csv.NewWriter(w)
	_ = cw.Write([]string{"订单号", "用户ID", "金额", "手续费", "分佣基数", "支付状态", "分佣状态", "退款状态", "下单时间"})
	for _, order := range list {
		_ = cw.Write([]string{
			order.OrderNo, strconv.FormatInt(order.UserID, 10),
			strconv.FormatFloat(order.Amount, 'f', 2, 64),
			strconv.FormatFloat(order.GatewayFee, 'f', 2, 64),
			strconv.FormatFloat(order.CommissionBase, 'f', 2, 64),
			strconv.Itoa(order.PayStatus), strconv.Itoa(order.CommissionStatus), strconv.Itoa(order.RefundStatus),
			time.UnixMilli(order.CreatedAt).Format(time.RFC3339),
		})
	}
	cw.Flush()
	return cw.Error()
}

func (s *Server) adminWithdrawals(w http.ResponseWriter, r *http.Request) error {
	if err := s.allowRole(r, "finance"); err != nil {
		return err
	}
	list, err := s.db.ListWithdrawals(0, 200)
	if err != nil {
		return err
	}
	fee, _ := s.db.ConfigFloat("withdraw_fee_rate", 0)
	minAmount, _ := s.db.ConfigFloat("withdraw_min", 0)
	day, _ := s.db.ConfigFloat("settle_day", 1)
	writeOK(w, http.StatusOK, map[string]any{
		"feeRate": fee, "minAmount": minAmount, "settleDay": day, "withdrawals": list,
	})
	return nil
}

func (s *Server) adminAuditWithdrawal(w http.ResponseWriter, r *http.Request) error {
	if err := s.allowRole(r, "finance"); err != nil {
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
	action := store.AsString(body["action"])
	if err := s.db.AuditWithdrawal(id, action, time.Now().UnixMilli()); err != nil {
		return err
	}
	_, actor := s.staffRole(r)
	_ = s.db.AddLog("admin", actor, "withdraw_"+action, strconv.FormatInt(id, 10), clientIP(r))
	writeOK(w, http.StatusOK, map[string]any{"id": id, "action": action})
	return nil
}

func (s *Server) adminSaveWithdrawRules(w http.ResponseWriter, r *http.Request) error {
	if err := s.allowRole(r, "finance"); err != nil {
		return err
	}
	body, err := readJSON(r)
	if err != nil {
		return err
	}
	if err := s.db.PutConfigs(map[string]string{
		"withdraw_fee_rate": strconv.FormatFloat(store.AsFloat(body["feeRate"]), 'f', -1, 64),
		"withdraw_min":      strconv.FormatFloat(store.AsFloat(body["minAmount"]), 'f', -1, 64),
		"settle_day":        strconv.FormatFloat(store.AsFloat(body["settleDay"]), 'f', 0, 64),
	}); err != nil {
		return err
	}
	writeOK(w, http.StatusOK, map[string]any{"saved": true})
	return nil
}

func (s *Server) adminRefunds(w http.ResponseWriter, r *http.Request) error {
	if err := s.allowRole(r, "finance"); err != nil {
		return err
	}
	list, err := s.db.ListRefunds(200)
	if err != nil {
		return err
	}
	writeOK(w, http.StatusOK, map[string]any{"refunds": list})
	return nil
}

func (s *Server) adminHandleRefund(w http.ResponseWriter, r *http.Request) error {
	if err := s.allowRole(r, "finance"); err != nil {
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
	_, actor := s.staffRole(r)
	approve := store.AsString(body["action"]) == "approve"
	if err := s.db.HandleRefund(id, approve, actor, time.Now().UnixMilli()); err != nil {
		return err
	}
	_ = s.db.AddLog("admin", actor, "refund", store.AsString(body["action"]), clientIP(r))
	writeOK(w, http.StatusOK, map[string]any{"id": id})
	return nil
}

func (s *Server) adminCommissionSettings(w http.ResponseWriter, r *http.Request) error {
	if err := s.allowRole(r); err != nil {
		return err
	}
	if r.Method == http.MethodGet {
		settings, err := s.db.CommissionSettings()
		if err != nil {
			return err
		}
		writeOK(w, http.StatusOK, settings)
		return nil
	}
	body, err := readJSON(r)
	if err != nil {
		return err
	}
	three := true
	if v, ok := body["threeLevel"].(bool); ok {
		three = v
	}
	if err := s.db.SaveCommissionSettings(
		store.AsFloat(body["poolRate"]), store.AsFloat(body["level1Rate"]), store.AsFloat(body["level2Rate"]),
		store.AsFloat(body["level3Rate"]), store.AsFloat(body["commissionCap"]), store.AsFloat(body["rateCap"]),
		store.AsFloat(body["distributorRate"]), store.AsFloat(body["settleDay"]), three,
	); err != nil {
		return err
	}
	settings, err := s.db.CommissionSettings()
	if err != nil {
		return err
	}
	writeOK(w, http.StatusOK, settings)
	return nil
}

func (s *Server) adminNotices(w http.ResponseWriter, r *http.Request) error {
	if err := s.allowRole(r, "support"); err != nil {
		return err
	}
	if r.Method == http.MethodGet {
		list, err := s.db.ListNotices(false, time.Now().UnixMilli())
		if err != nil {
			return err
		}
		writeOK(w, http.StatusOK, map[string]any{"announcements": list})
		return nil
	}
	body, err := readJSON(r)
	if err != nil {
		return err
	}
	enabled := 1
	if store.AsString(body["status"]) == "0" {
		enabled = 0
	}
	id, err := s.db.SaveNotice(store.AsInt64(body["id"]), store.AsString(body["title"]), store.AsString(body["body"]),
		store.AsString(body["noticeType"]), enabled, store.AsInt64(body["startsAt"]), store.AsInt64(body["endsAt"]), time.Now().UnixMilli())
	if err != nil {
		return err
	}
	writeOK(w, http.StatusOK, map[string]any{"id": id})
	return nil
}

func (s *Server) adminAds(w http.ResponseWriter, r *http.Request) error {
	if err := s.allowRole(r, "support"); err != nil {
		return err
	}
	if r.Method == http.MethodGet {
		list, err := s.db.ListAds(false, 0)
		if err != nil {
			return err
		}
		writeOK(w, http.StatusOK, map[string]any{"ads": list})
		return nil
	}
	body, err := readJSON(r)
	if err != nil {
		return err
	}
	status := 1
	if body["status"] != nil {
		status = int(store.AsInt64(body["status"]))
	}
	id, err := s.db.SaveAd(store.AsInt64(body["id"]), store.AsString(body["slot"]), store.AsString(body["title"]),
		store.AsString(body["imageUrl"]), store.AsString(body["linkUrl"]), store.AsInt64(body["sortOrder"]),
		store.AsInt64(body["startsAt"]), store.AsInt64(body["endsAt"]), status)
	if err != nil {
		return err
	}
	writeOK(w, http.StatusOK, map[string]any{"id": id})
	return nil
}

func (s *Server) adminDeleteAd(w http.ResponseWriter, r *http.Request) error {
	if err := s.allowRole(r, "support"); err != nil {
		return err
	}
	id, err := idParam(r)
	if err != nil {
		return err
	}
	if err := s.db.DeleteAd(id); err != nil {
		return err
	}
	writeOK(w, http.StatusOK, map[string]any{"id": id})
	return nil
}

func (s *Server) adminServices(w http.ResponseWriter, r *http.Request) error {
	if err := s.allowRole(r, "support"); err != nil {
		return err
	}
	if r.Method == http.MethodGet {
		list, err := s.db.ListServices(false)
		if err != nil {
			return err
		}
		writeOK(w, http.StatusOK, map[string]any{"services": list})
		return nil
	}
	body, err := readJSON(r)
	if err != nil {
		return err
	}
	enabled := 1
	if store.AsInt64(body["enabled"]) == 0 && body["enabled"] != nil {
		enabled = 0
	}
	id, err := s.db.SaveService(store.AsInt64(body["id"]), store.AsString(body["channel"]), store.AsString(body["account"]),
		store.AsString(body["qrUrl"]), enabled, int(store.AsInt64(body["sortOrder"])))
	if err != nil {
		return err
	}
	writeOK(w, http.StatusOK, map[string]any{"id": id})
	return nil
}

func (s *Server) adminTickets(w http.ResponseWriter, r *http.Request) error {
	if err := s.allowRole(r, "support"); err != nil {
		return err
	}
	list, err := s.db.ListTickets(0)
	if err != nil {
		return err
	}
	writeOK(w, http.StatusOK, map[string]any{"tickets": list})
	return nil
}

func (s *Server) adminReplyTicket(w http.ResponseWriter, r *http.Request) error {
	if err := s.allowRole(r, "support"); err != nil {
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
	closeIt, _ := body["close"].(bool)
	if err := s.db.ReplyTicket(id, store.AsString(body["reply"]), closeIt, time.Now().UnixMilli()); err != nil {
		return err
	}
	writeOK(w, http.StatusOK, map[string]any{"id": id})
	return nil
}

func (s *Server) adminFourthPay(w http.ResponseWriter, r *http.Request) error {
	if err := s.allowRole(r); err != nil {
		return err
	}
	keys := []string{"fourth_mch_id", "fourth_gateway", "fourth_key", "fourth_notify_secret"}
	if r.Method == http.MethodGet {
		cfg, err := s.db.ConfigMap(keys)
		if err != nil {
			return err
		}
		writeOK(w, http.StatusOK, maskSecrets(cfg))
		return nil
	}
	body, err := readJSON(r)
	if err != nil {
		return err
	}
	values := map[string]string{}
	for _, key := range keys {
		raw := store.AsString(body[key])
		if raw == "" || raw == "******" {
			continue
		}
		values[key] = raw
	}
	if err := s.db.PutConfigs(values); err != nil {
		return err
	}
	cfg, err := s.db.ConfigMap(keys)
	if err != nil {
		return err
	}
	writeOK(w, http.StatusOK, maskSecrets(cfg))
	return nil
}

func (s *Server) adminEmailConfig(w http.ResponseWriter, r *http.Request) error {
	if err := s.allowRole(r); err != nil {
		return err
	}
	keys := []string{"email_host", "email_port", "email_user", "email_password", "email_from"}
	if r.Method == http.MethodGet {
		cfg, err := s.db.ConfigMap(keys)
		if err != nil {
			return err
		}
		writeOK(w, http.StatusOK, maskSecrets(cfg))
		return nil
	}
	body, err := readJSON(r)
	if err != nil {
		return err
	}
	values := map[string]string{}
	for _, key := range keys {
		raw := store.AsString(body[key])
		if raw == "" || raw == "******" {
			continue
		}
		values[key] = raw
	}
	if err := s.db.PutConfigs(values); err != nil {
		return err
	}
	cfg, err := s.db.ConfigMap(keys)
	if err != nil {
		return err
	}
	writeOK(w, http.StatusOK, maskSecrets(cfg))
	return nil
}

func (s *Server) adminSystemLogs(w http.ResponseWriter, r *http.Request) error {
	if err := s.allowRole(r); err != nil {
		return err
	}
	kind := r.URL.Query().Get("kind")
	list, err := s.db.ListLogs(kind, 100)
	if err != nil {
		return err
	}
	writeOK(w, http.StatusOK, map[string]any{"logs": list})
	return nil
}

func (s *Server) adminStaff(w http.ResponseWriter, r *http.Request) error {
	if err := s.allowRole(r); err != nil {
		return err
	}
	list, err := s.db.ListCatalog("admins")
	if err != nil {
		return err
	}
	out := make([]map[string]any, 0, len(list))
	for _, item := range list {
		out = append(out, store.PublicAdmin(item))
	}
	writeOK(w, http.StatusOK, map[string]any{"staff": out})
	return nil
}

func (s *Server) adminStaffRole(w http.ResponseWriter, r *http.Request) error {
	if err := s.allowRole(r); err != nil {
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
	role := store.AsString(body["role"])
	switch role {
	case "super", "operator", "finance", "support":
	default:
		return badRequest("角色只能是超级管理员、运营、财务或客服")
	}
	updated, err := s.db.UpdateCatalog("admins", id, map[string]any{"role": role})
	if err != nil {
		return err
	}
	writeOK(w, http.StatusOK, store.PublicAdmin(updated))
	return nil
}

func maskSecrets(cfg map[string]string) map[string]any {
	out := map[string]any{}
	for key, value := range cfg {
		if strings.Contains(key, "password") || strings.Contains(key, "secret") || strings.HasSuffix(key, "_key") {
			if value == "" {
				out[key] = ""
			} else {
				out[key] = "******"
			}
			out[key+"Configured"] = value != ""
			continue
		}
		out[key] = value
	}
	return out
}

func orderListJSON(list []store.CommerceOrder) []map[string]any {
	out := make([]map[string]any, 0, len(list))
	for _, order := range list {
		out = append(out, orderJSON(order, "", ""))
	}
	return out
}
