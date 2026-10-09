package api

import (
	"crypto/rand"
	"net/http"
	"sort"
	"strings"
	"time"

	"xvay/houduan/internal/auth"
	"xvay/houduan/internal/errs"
	"xvay/houduan/internal/store"
)

func (s *Server) agentRegister(w http.ResponseWriter, r *http.Request) error {
	body, err := readJSON(r)
	if err != nil {
		return err
	}
	username := strings.TrimSpace(store.AsString(body["username"]))
	password := store.AsString(body["password"])
	name := strings.TrimSpace(store.AsString(body["name"]))
	phone := strings.TrimSpace(store.AsString(body["phone"]))
	inviteCode := strings.TrimSpace(store.AsString(body["inviteCode"]))
	if len(username) < 3 || len(username) > 20 {
		return errs.New(http.StatusBadRequest, "VALIDATION", "用户名长度为 3-20 位")
	}
	if len(password) < 6 || len(password) > 128 {
		return errs.New(http.StatusBadRequest, "VALIDATION", "密码至少 6 位")
	}
	if name == "" || len(name) > 20 {
		return errs.New(http.StatusBadRequest, "VALIDATION", "请填写代理名称")
	}
	if phone != "" && !phoneOK(phone) {
		return errs.New(http.StatusBadRequest, "VALIDATION", "请输入 11 位手机号")
	}
	agents, err := s.db.ListCatalog("agents")
	if err != nil {
		return err
	}
	for _, item := range agents {
		if store.AsString(item["username"]) == username {
			return errs.New(http.StatusConflict, "CONFLICT", "用户名已存在")
		}
	}
	var parentID any
	if inviteCode != "" {
		parent, ok := findAgentByInvite(agents, inviteCode)
		if !ok {
			return errs.New(http.StatusBadRequest, "VALIDATION", "邀请码不存在")
		}
		if store.AsString(parent["status"]) == "frozen" {
			return errs.New(http.StatusBadRequest, "VALIDATION", "上级代理已冻结，不能加入")
		}
		parentID = store.AsInt64(parent["id"])
	}
	hash, err := auth.HashPassword(password)
	if err != nil {
		return err
	}
	code, err := uniqueInviteCode(agents)
	if err != nil {
		return err
	}
	created, err := s.db.InsertCatalog("agents", map[string]any{
		"username":        username,
		"passwordHash":    hash,
		"name":            name,
		"phone":           phone,
		"level":           "bronze",
		"inviteCode":      code,
		"parentId":        parentID,
		"balance":         0,
		"totalCommission": 0,
		"status":          "active",
		"remark":          "",
		"createdAt":       time.Now().UTC().Format(time.RFC3339),
	})
	if err != nil {
		return err
	}
	token, err := s.db.CreateAgentSession(store.AsInt64(created["id"]), time.Duration(s.cfg.SessionTTLMs)*time.Millisecond)
	if err != nil {
		return err
	}
	writeOK(w, http.StatusCreated, map[string]any{
		"token": token,
		"user":  store.PublicAgent(created),
	})
	return nil
}

func (s *Server) agentLogin(w http.ResponseWriter, r *http.Request) error {
	body, err := readJSON(r)
	if err != nil {
		return err
	}
	username := strings.TrimSpace(store.AsString(body["username"]))
	password := store.AsString(body["password"])
	if username == "" || password == "" {
		return errs.New(http.StatusBadRequest, "VALIDATION", "请输入账号和密码")
	}
	agents, err := s.db.ListCatalog("agents")
	if err != nil {
		return err
	}
	var found map[string]any
	for _, item := range agents {
		if store.AsString(item["username"]) == username {
			found = item
			break
		}
	}
	if found == nil || !auth.VerifyPassword(password, store.AsString(found["passwordHash"])) {
		return errs.New(http.StatusUnauthorized, "UNAUTHORIZED", "账号或密码不正确")
	}
	if store.AsString(found["status"]) == "frozen" {
		return errs.New(http.StatusForbidden, "FORBIDDEN", "代理已冻结，不能登录")
	}
	token, err := s.db.CreateAgentSession(store.AsInt64(found["id"]), time.Duration(s.cfg.SessionTTLMs)*time.Millisecond)
	if err != nil {
		return err
	}
	writeOK(w, http.StatusOK, map[string]any{
		"token": token,
		"user":  store.PublicAgent(found),
	})
	return nil
}

func (s *Server) agentLogout(w http.ResponseWriter, r *http.Request) error {
	token := auth.BearerToken(r.Header.Get("Authorization"))
	if err := s.db.DeleteAgentSession(token); err != nil {
		return err
	}
	writeOK(w, http.StatusOK, map[string]any{"ok": true})
	return nil
}

func (s *Server) agentMe(w http.ResponseWriter, r *http.Request) error {
	agent, err := s.requireAgent(r)
	if err != nil {
		return err
	}
	writeOK(w, http.StatusOK, store.PublicAgent(agent))
	return nil
}

func (s *Server) agentTeam(w http.ResponseWriter, r *http.Request) error {
	agent, err := s.requireAgent(r)
	if err != nil {
		return err
	}
	agents, err := s.db.ListCatalog("agents")
	if err != nil {
		return err
	}
	selfID := store.AsInt64(agent["id"])
	direct := childrenOf(agents, selfID)
	out := make([]map[string]any, 0, len(direct))
	for _, child := range direct {
		item := store.PublicAgent(child)
		grand := childrenOf(agents, store.AsInt64(child["id"]))
		nested := make([]map[string]any, 0, len(grand))
		for _, row := range grand {
			nested = append(nested, store.PublicAgent(row))
		}
		item["agents"] = nested
		out = append(out, item)
	}
	writeOK(w, http.StatusOK, map[string]any{
		"agent":  store.PublicAgent(agent),
		"direct": out,
	})
	return nil
}

func (s *Server) agentCommissions(w http.ResponseWriter, r *http.Request) error {
	agent, err := s.requireAgent(r)
	if err != nil {
		return err
	}
	rows, err := s.db.ListCatalog("commissions")
	if err != nil {
		return err
	}
	selfID := store.AsInt64(agent["id"])
	profiles, err := s.db.ListProfiles()
	if err != nil {
		return err
	}
	orders := []map[string]any{}
	var pending, settled, rejected float64
	for _, row := range rows {
		if store.AsInt64(row["agentId"]) != selfID {
			continue
		}
		amount := store.AsFloat(row["commission"])
		switch store.AsString(row["status"]) {
		case "settled":
			settled += amount
		case "rejected":
			rejected += amount
		default:
			pending += amount
		}
		userName := ""
		if profile, ok := profiles[store.AsInt64(row["userId"])]; ok {
			userName = profile.DisplayName
		}
		if userName == "" {
			if user, ok, err := s.db.FindUserByID(store.AsInt64(row["userId"])); err != nil {
				return err
			} else if ok {
				userName = user.Email
			}
		}
		orders = append(orders, map[string]any{
			"id":          row["id"],
			"orderNo":     row["orderNo"],
			"orderAmount": row["orderAmount"],
			"rate":        row["rate"],
			"commission":  row["commission"],
			"status":      row["status"],
			"createdAt":   row["createdAt"],
			"settledAt":   row["settledAt"],
			"remark":      row["remark"],
			"userName":    userName,
		})
	}
	sort.Slice(orders, func(i, j int) bool {
		return store.AsString(orders[i]["createdAt"]) > store.AsString(orders[j]["createdAt"])
	})
	writeOK(w, http.StatusOK, map[string]any{
		"balance":         agent["balance"],
		"totalCommission": agent["totalCommission"],
		"pending":         pending,
		"settled":         settled,
		"rejected":        rejected,
		"orders":          orders,
	})
	return nil
}

func (s *Server) requireAgent(r *http.Request) (map[string]any, error) {
	token := auth.BearerToken(r.Header.Get("Authorization"))
	if token == "" {
		return nil, errs.New(http.StatusUnauthorized, "UNAUTHORIZED", "请先登录")
	}
	id, ok, err := s.db.AgentIDBySession(token, time.Now().UnixMilli())
	if err != nil {
		return nil, err
	}
	if !ok {
		return nil, errs.New(http.StatusUnauthorized, "UNAUTHORIZED", "登录已失效")
	}
	agent, ok, err := s.db.GetCatalog("agents", id)
	if err != nil {
		return nil, err
	}
	if !ok {
		return nil, errs.New(http.StatusUnauthorized, "UNAUTHORIZED", "登录已失效")
	}
	if store.AsString(agent["status"]) == "frozen" {
		return nil, errs.New(http.StatusForbidden, "FORBIDDEN", "代理已冻结")
	}
	return agent, nil
}

func childrenOf(agents []map[string]any, parentID int64) []map[string]any {
	out := []map[string]any{}
	for _, item := range agents {
		if store.AsInt64(item["parentId"]) == parentID {
			out = append(out, item)
		}
	}
	return out
}

func findAgentByInvite(agents []map[string]any, code string) (map[string]any, bool) {
	for _, item := range agents {
		if strings.EqualFold(store.AsString(item["inviteCode"]), code) {
			return item, true
		}
	}
	return nil, false
}

func uniqueInviteCode(agents []map[string]any) (string, error) {
	const alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
	for range 8 {
		buf := make([]byte, 6)
		if _, err := rand.Read(buf); err != nil {
			return "", err
		}
		raw := make([]byte, 6)
		for i, b := range buf {
			raw[i] = alphabet[int(b)%len(alphabet)]
		}
		code := "FL" + string(raw)
		if _, ok := findAgentByInvite(agents, code); !ok {
			return code, nil
		}
	}
	return "", errs.New(http.StatusInternalServerError, "INTERNAL", "邀请码生成失败")
}

func phoneOK(phone string) bool {
	if len(phone) != 11 || phone[0] != '1' {
		return false
	}
	for _, c := range phone {
		if c < '0' || c > '9' {
			return false
		}
	}
	return true
}
