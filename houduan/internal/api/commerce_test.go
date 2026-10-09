package api_test

import (
	"net/http"
	"strconv"
	"strings"
	"testing"
	"time"

	"xvay/houduan/internal/api"
	"xvay/houduan/internal/auth"
	"xvay/houduan/internal/config"
	"xvay/houduan/internal/store"
)

func TestCommerce(t *testing.T) {
	cfg := config.Config{
		DataDir: t.TempDir(), DatabasePath: ":memory:",
		PublicBaseURL: "http://127.0.0.1:8787", AdminToken: "admin-token",
		TrialBytes: 0, TrialDays: 0, SessionTTLMs: 3_600_000, PayDebug: true,
	}
	db, err := store.Open(cfg)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { db.Close() })
	handler := api.New(cfg, db)
	closed := config.Config{
		DataDir: cfg.DataDir, DatabasePath: ":memory:", PublicBaseURL: cfg.PublicBaseURL,
		AdminToken: cfg.AdminToken, SessionTTLMs: cfg.SessionTTLMs,
	}
	closed.DatabasePath = cfg.DatabasePath
	noPay := api.New(closed, db)

	a := signup(t, handler, "user_a", "")
	b := signup(t, handler, "user_b", a.user["inviteCode"].(string))
	c := signup(t, handler, "user_c", b.user["inviteCode"].(string))
	d := signup(t, handler, "user_d", c.user["inviteCode"].(string))
	badInvite := call(t, handler, http.MethodPost, "/api/app/register", "", map[string]any{
		"username": "user_x", "password": "password1", "inviteCode": "nope",
	})
	if badInvite.Status != http.StatusBadRequest || !strings.Contains(errorMessage(badInvite), "邀请码不正确") {
		t.Fatalf("bad invite %d %s", badInvite.Status, badInvite.Raw)
	}

	plans := call(t, handler, http.MethodGet, "/api/app/plans", d.token, nil)
	items, _ := plans.Data["items"].([]any)
	if plans.Status != http.StatusOK || len(items) != 4 {
		t.Fatalf("plans %d %s", plans.Status, plans.Raw)
	}
	wantPrice := map[string]float64{"week": 1500, "month": 3000, "quarter": 7800, "year": 25800}
	for _, item := range items {
		row := item.(map[string]any)
		if row["price"].(float64) != wantPrice[row["code"].(string)] || row["trafficGb"] == nil || row["durationDays"] == nil {
			t.Fatalf("plan row %v", row)
		}
	}

	blocked := call(t, noPay, http.MethodPost, "/api/app/orders/checkout", d.token, map[string]any{"planCode": "week"})
	if blocked.Status != http.StatusServiceUnavailable {
		t.Fatalf("gateway off %d %s", blocked.Status, blocked.Raw)
	}

	order := call(t, handler, http.MethodPost, "/api/app/orders/checkout", d.token, map[string]any{"planCode": "week"})
	if order.Status != http.StatusCreated || order.Data["channel"] != "debug" {
		t.Fatalf("checkout %d %s", order.Status, order.Raw)
	}
	orderBody := order.Data["order"].(map[string]any)
	paid := call(t, handler, http.MethodPost, "/api/pay/debug", "", map[string]any{"orderNo": orderBody["orderNo"]})
	if paid.Status != http.StatusOK || paid.Data["order"].(map[string]any)["status"] != "paid" {
		t.Fatalf("debug pay %d %s", paid.Status, paid.Raw)
	}
	again := call(t, handler, http.MethodPost, "/api/pay/debug", "", map[string]any{"orderNo": orderBody["orderNo"]})
	if again.Status != http.StatusOK || again.Data["alreadyPaid"] != true {
		t.Fatalf("idempotent pay %d %s", again.Status, again.Raw)
	}

	me := call(t, handler, http.MethodGet, "/api/app/me", d.token, nil)
	service := me.Data["service"].(map[string]any)
	if me.Status != http.StatusOK || int64(service["remainingBytes"].(float64)) != 20*1024*1024*1024 || int64(service["remainingMs"].(float64)) <= 0 {
		t.Fatalf("service %d %s", me.Status, me.Raw)
	}

	checkRebate(t, handler, c.token, idOf(d.user), 450, 0, "pending")
	checkRebate(t, handler, b.token, idOf(d.user), 225, 0, "pending")
	checkRebate(t, handler, a.token, idOf(d.user), 75, 0, "pending")

	preview := call(t, handler, http.MethodGet, "/api/admin/commissions/preview?amount=10000", "admin-token", nil)
	levels, _ := preview.Data["levels"].([]any)
	if preview.Status != http.StatusOK || int64(preview.Data["totalCommission"].(float64)) != 5000 || len(levels) != 3 {
		t.Fatalf("preview %d %s", preview.Status, preview.Raw)
	}
	if int64(levels[0].(map[string]any)["amount"].(float64)) != 3000 || levels[0].(map[string]any)["user"] != "C" ||
		int64(levels[1].(map[string]any)["amount"].(float64)) != 1500 || int64(levels[2].(map[string]any)["amount"].(float64)) != 500 {
		t.Fatalf("preview levels %s", preview.Raw)
	}

	settled := call(t, handler, http.MethodPost, "/api/admin/commissions/settle?force=1", "admin-token", map[string]any{})
	if settled.Status != http.StatusOK || int64(settled.Data["settled"].(float64)) != 3 {
		t.Fatalf("settle %d %s", settled.Status, settled.Raw)
	}
	checkRebate(t, handler, a.token, idOf(d.user), 75, 0, "settled")
	wallet := call(t, handler, http.MethodGet, "/api/app/wallet", a.token, nil)
	if int64(wallet.Data["balance"].(float64)) != 75 || int64(wallet.Data["totalEarned"].(float64)) != 75 {
		t.Fatalf("wallet after settle %s", wallet.Raw)
	}

	settings := call(t, handler, http.MethodPut, "/api/admin/settings", "admin-token", map[string]any{
		"withdrawMinCents": 10, "withdrawFeePercent": 10,
	})
	if settings.Status != http.StatusOK || int64(settings.Data["withdrawFeePercent"].(float64)) != 10 {
		t.Fatalf("settings %d %s", settings.Status, settings.Raw)
	}
	withdraw := call(t, handler, http.MethodPost, "/api/app/withdrawals", a.token, map[string]any{
		"amount": 50, "account": "alipay-a",
	})
	if withdraw.Status != http.StatusCreated || int64(withdraw.Data["fee"].(float64)) != 5 || int64(withdraw.Data["netAmount"].(float64)) != 45 {
		t.Fatalf("withdraw %d %s", withdraw.Status, withdraw.Raw)
	}
	wallet = call(t, handler, http.MethodGet, "/api/app/wallet", a.token, nil)
	if int64(wallet.Data["balance"].(float64)) != 25 || int64(wallet.Data["frozen"].(float64)) != 50 {
		t.Fatalf("wallet after withdraw %s", wallet.Raw)
	}

	refund := call(t, handler, http.MethodPost, "/api/admin/orders/"+idText(orderBody["id"])+"/refunds", "admin-token", map[string]any{
		"amount": 1500, "status": "success", "reason": "退款",
	})
	if refund.Status != http.StatusCreated && refund.Status != http.StatusOK {
		t.Fatalf("refund %d %s", refund.Status, refund.Raw)
	}
	wallet = call(t, handler, http.MethodGet, "/api/app/wallet", a.token, nil)
	deductions, _ := wallet.Data["deductions"].([]any)
	if int64(wallet.Data["balance"].(float64)) != -50 || int64(wallet.Data["negativeBalance"].(float64)) != 50 ||
		int64(wallet.Data["frozen"].(float64)) != 50 || int64(wallet.Data["totalEarned"].(float64)) != 75 || len(deductions) == 0 {
		t.Fatalf("clawback wallet %s", wallet.Raw)
	}
	checkRebate(t, handler, a.token, idOf(d.user), 75, 0, "reversed")

	promo := call(t, handler, http.MethodGet, "/api/app/promotion", a.token, nil)
	team, _ := promo.Data["team"].([]any)
	if promo.Status != http.StatusOK || promo.Data["invite"].(map[string]any)["inviteCode"] != a.user["inviteCode"] || len(team) != 3 {
		t.Fatalf("promotion %d %s", promo.Status, promo.Raw)
	}
	if team[0].(map[string]any)["level"].(float64) != 1 || team[2].(map[string]any)["level"].(float64) != 3 {
		t.Fatalf("team levels %s", promo.Raw)
	}
	qr := callRaw(t, handler, http.MethodGet, "/api/app/invite/qr.png", a.token)
	if qr.Code != http.StatusOK || !strings.HasPrefix(qr.Body, "\x89PNG") {
		t.Fatalf("qr %d %q", qr.Code, qr.Body[:min(20, len(qr.Body))])
	}

	expireAt := time.Now().Add(48 * time.Hour).UnixMilli()
	patched := call(t, handler, http.MethodPatch, "/api/admin/users/"+idText(d.user["id"]), "admin-token", map[string]any{
		"expireAt": expireAt,
	})
	if patched.Status != http.StatusOK {
		t.Fatalf("expire patch %d %s", patched.Status, patched.Raw)
	}
	me = call(t, handler, http.MethodGet, "/api/app/me", d.token, nil)
	service = me.Data["service"].(map[string]any)
	if service["expiringSoon"] != true || !strings.Contains(service["remindMessage"].(string), "2 天") {
		t.Fatalf("remind %s", me.Raw)
	}
	before := int64(service["expireAt"].(float64))
	renew := call(t, handler, http.MethodPost, "/api/app/orders/renew", d.token, map[string]any{"planCode": "week"})
	renewOrder := renew.Data["order"].(map[string]any)
	if renew.Status != http.StatusCreated || renewOrder["renew"] != true {
		t.Fatalf("renew %d %s", renew.Status, renew.Raw)
	}
	paid = call(t, handler, http.MethodPost, "/api/pay/debug", "", map[string]any{"orderNo": renewOrder["orderNo"]})
	if paid.Status != http.StatusOK {
		t.Fatalf("renew pay %d %s", paid.Status, paid.Raw)
	}
	me = call(t, handler, http.MethodGet, "/api/app/me", d.token, nil)
	after := int64(me.Data["service"].(map[string]any)["expireAt"].(float64))
	if after-before < 6*24*3600*1000 {
		t.Fatalf("renew expire %d -> %d", before, after)
	}

	p := signup(t, handler, "dealer_p", "")
	set := call(t, handler, http.MethodPost, "/api/admin/users/"+idText(p.user["id"])+"/distributor", "admin-token", map[string]any{
		"enabled": true, "rate": 40,
	})
	if set.Status != http.StatusOK || set.Data["userType"] != "dealer" || int64(set.Data["canAuthorizeAgent"].(float64)) != 1 || int64(set.Data["walletEnabled"].(float64)) != 1 {
		t.Fatalf("set distributor %d %s", set.Status, set.Raw)
	}
	p = login(t, handler, "dealer_p")
	q := signup(t, handler, "agent_q", p.user["inviteCode"].(string))
	qWallet := call(t, handler, http.MethodGet, "/api/app/wallet", q.token, nil)
	if qWallet.Data["enabled"] != false || !strings.Contains(qWallet.Data["reason"].(string), "钱包未开通") {
		t.Fatalf("q wallet %s", qWallet.Raw)
	}
	qOrder := payPlan(t, handler, q.token, "week")
	checkRebate(t, handler, p.token, idOf(q.user), 600, 1, "pending")

	authAgent := call(t, handler, http.MethodPost, "/api/distributor/members/"+idText(q.user["id"])+"/agent", p.token, map[string]any{"enabled": true})
	if authAgent.Status != http.StatusOK || int64(authAgent.Data["isAgent"].(float64)) != 1 || int64(authAgent.Data["walletEnabled"].(float64)) != 1 {
		t.Fatalf("authorize %d %s", authAgent.Status, authAgent.Raw)
	}
	q = login(t, handler, "agent_q")
	denied := call(t, handler, http.MethodPost, "/api/distributor/members/"+idText(p.user["id"])+"/agent", q.token, map[string]any{"enabled": true})
	if denied.Status != http.StatusForbidden {
		t.Fatalf("agent authorize %d %s", denied.Status, denied.Raw)
	}
	tooHigh := call(t, handler, http.MethodPost, "/api/distributor/members/"+idText(q.user["id"])+"/rate", p.token, map[string]any{"rate": 50})
	if tooHigh.Status != http.StatusBadRequest || !strings.Contains(errorMessage(tooHigh), "会员返佣比例不能超过经销商分佣比例") {
		t.Fatalf("rate high %d %s", tooHigh.Status, tooHigh.Raw)
	}
	rated := call(t, handler, http.MethodPost, "/api/distributor/members/"+idText(q.user["id"])+"/rate", p.token, map[string]any{"rate": 20})
	if rated.Status != http.StatusOK || int64(rated.Data["memberRate"].(float64)) != 20 {
		t.Fatalf("rate %d %s", rated.Status, rated.Raw)
	}
	r := signup(t, handler, "buyer_r", q.user["inviteCode"].(string))
	payPlan(t, handler, r.token, "week")
	checkRebate(t, handler, q.token, idOf(r.user), 300, 1, "pending")
	if findRebate(call(t, handler, http.MethodGet, "/api/app/rebates", p.token, nil), idOf(r.user)) != nil {
		t.Fatal("distributor should not take a second share from R")
	}

	m := signup(t, handler, "member_m", p.user["inviteCode"].(string))
	if call(t, handler, http.MethodGet, "/api/app/rebates", m.token, nil).Status != http.StatusForbidden {
		t.Fatal("member rebate should be closed")
	}
	s := signup(t, handler, "buyer_s", m.user["inviteCode"].(string))
	payPlan(t, handler, s.token, "week")
	checkRebate(t, handler, p.token, idOf(s.user), 225, 0, "pending")

	ban := call(t, handler, http.MethodPost, "/api/distributor/members/"+idText(m.user["id"])+"/ban-request", p.token, map[string]any{"reason": "异常"})
	if ban.Status != http.StatusCreated {
		t.Fatalf("ban request %d %s", ban.Status, ban.Raw)
	}
	still := call(t, handler, http.MethodGet, "/api/app/me", m.token, nil)
	if still.Data["status"] != "active" {
		t.Fatalf("ban must not disable immediately %s", still.Raw)
	}
	review := call(t, handler, http.MethodPost, "/api/admin/requests/"+idText(ban.Data["id"])+"/review", "admin-token", map[string]any{"approve": true})
	if review.Status != http.StatusOK {
		t.Fatalf("review request %d %s", review.Status, review.Raw)
	}
	if call(t, handler, http.MethodPost, "/api/app/login", "", map[string]any{"username": "member_m", "password": "password1"}).Status != http.StatusForbidden {
		t.Fatal("banned member should not login")
	}

	ticket := call(t, handler, http.MethodPost, "/api/app/tickets", d.token, map[string]any{"subject": "续费咨询", "body": "想确认到期时间"})
	if ticket.Status != http.StatusCreated {
		t.Fatalf("ticket %d %s", ticket.Status, ticket.Raw)
	}
	finance := adminOf(t, db, handler, "finance", "finance")
	support := adminOf(t, db, handler, "support", "support")
	if call(t, handler, http.MethodGet, "/api/admin/nodes", finance, nil).Status != http.StatusForbidden {
		t.Fatal("finance should not list nodes")
	}
	if call(t, handler, http.MethodGet, "/api/admin/withdrawals", finance, nil).Status != http.StatusOK {
		t.Fatal("finance should list withdrawals")
	}
	if call(t, handler, http.MethodGet, "/api/admin/nodes", support, nil).Status != http.StatusForbidden {
		t.Fatal("support should not list nodes")
	}
	listed := call(t, handler, http.MethodGet, "/api/admin/tickets", support, nil)
	listedItems, _ := listed.Data["items"].([]any)
	if listed.Status != http.StatusOK || len(listedItems) == 0 {
		t.Fatalf("tickets %d %s", listed.Status, listed.Raw)
	}
	updated := call(t, handler, http.MethodPatch, "/api/admin/tickets/"+idText(ticket.Data["id"]), support, map[string]any{"status": "replied"})
	if updated.Status != http.StatusOK || updated.Data["status"] != "replied" {
		t.Fatalf("ticket status %d %s", updated.Status, updated.Raw)
	}
	_ = qOrder
}

type session struct {
	token string
	user  map[string]any
}

func signup(t *testing.T, handler http.Handler, username, invite string) session {
	t.Helper()
	body := map[string]any{"username": username, "password": "password1"}
	if invite != "" {
		body["inviteCode"] = invite
	}
	res := call(t, handler, http.MethodPost, "/api/app/register", "", body)
	if res.Status != http.StatusCreated {
		t.Fatalf("register %s %d %s", username, res.Status, res.Raw)
	}
	return session{token: res.Data["token"].(string), user: res.Data["user"].(map[string]any)}
}

func login(t *testing.T, handler http.Handler, username string) session {
	t.Helper()
	res := call(t, handler, http.MethodPost, "/api/app/login", "", map[string]any{
		"username": username, "password": "password1",
	})
	if res.Status != http.StatusOK {
		t.Fatalf("login %s %d %s", username, res.Status, res.Raw)
	}
	return session{token: res.Data["token"].(string), user: res.Data["user"].(map[string]any)}
}

func payPlan(t *testing.T, handler http.Handler, token, code string) map[string]any {
	t.Helper()
	order := call(t, handler, http.MethodPost, "/api/app/orders/checkout", token, map[string]any{"planCode": code})
	if order.Status != http.StatusCreated {
		t.Fatalf("checkout %d %s", order.Status, order.Raw)
	}
	body := order.Data["order"].(map[string]any)
	paid := call(t, handler, http.MethodPost, "/api/pay/debug", "", map[string]any{"orderNo": body["orderNo"]})
	if paid.Status != http.StatusOK {
		t.Fatalf("pay %d %s", paid.Status, paid.Raw)
	}
	return body
}

func checkRebate(t *testing.T, handler http.Handler, token string, buyer int64, amount int64, mode int64, status string) {
	t.Helper()
	res := call(t, handler, http.MethodGet, "/api/app/rebates", token, nil)
	if res.Status != http.StatusOK {
		t.Fatalf("rebates %d %s", res.Status, res.Raw)
	}
	row := findRebate(res, buyer)
	if row == nil || int64(row["amount"].(float64)) != amount || int64(row["mode"].(float64)) != mode || row["status"] != status {
		t.Fatalf("rebate buyer %d want %d/%d/%s in %s", buyer, amount, mode, status, res.Raw)
	}
}

func findRebate(res result, buyer int64) map[string]any {
	items, _ := res.Data["items"].([]any)
	for _, item := range items {
		row := item.(map[string]any)
		if int64(row["buyerId"].(float64)) == buyer {
			return row
		}
	}
	return nil
}

func adminOf(t *testing.T, db *store.Store, handler http.Handler, username, role string) string {
	t.Helper()
	hash, err := auth.HashPassword(username + "pass")
	if err != nil {
		t.Fatal(err)
	}
	if _, err := db.InsertCatalog("admins", map[string]any{
		"username": username, "passwordHash": hash, "nickname": username,
		"role": role, "phone": "", "createdAt": time.Now().UTC().Format(time.RFC3339),
	}); err != nil {
		t.Fatal(err)
	}
	res := call(t, handler, http.MethodPost, "/api/admin/login", "", map[string]any{
		"username": username, "password": username + "pass",
	})
	if res.Status != http.StatusOK {
		t.Fatalf("admin login %s %d %s", username, res.Status, res.Raw)
	}
	return res.Data["token"].(string)
}

func errorMessage(res result) string {
	errBody, _ := res.Body["error"].(map[string]any)
	text, _ := errBody["message"].(string)
	return text
}

func idOf(user map[string]any) int64 {
	return int64(user["id"].(float64))
}

func idText(value any) string {
	return strconv.FormatInt(int64(value.(float64)), 10)
}
