package api

import (
	"net"
	"net/http"
	"net/url"
	"strings"
	"time"

	"xvay/houduan/internal/auth"
	"xvay/houduan/internal/errs"
	"xvay/houduan/internal/store"
)

var mutableKinds = map[string]bool{
	"groups": true, "cores": true, "assets": true, "plans": true,
	"agents": true, "commissionRules": true, "commissions": true,
}

func (s *Server) adminLogin(w http.ResponseWriter, r *http.Request) error {
	body, err := readJSON(r)
	if err != nil {
		return err
	}
	username := strings.TrimSpace(store.AsString(body["username"]))
	password := store.AsString(body["password"])
	if username == "" || password == "" {
		return errs.New(http.StatusBadRequest, "VALIDATION", "请输入账号和密码")
	}
	admins, err := s.db.ListCatalog("admins")
	if err != nil {
		return err
	}
	var found map[string]any
	for _, item := range admins {
		if store.AsString(item["username"]) == username {
			found = item
			break
		}
	}
	if found == nil || !auth.VerifyPassword(password, store.AsString(found["passwordHash"])) {
		return errs.New(http.StatusUnauthorized, "UNAUTHORIZED", "账号或密码不正确")
	}
	token, err := s.db.CreateAdminSession(store.AsInt64(found["id"]), time.Duration(s.cfg.SessionTTLMs)*time.Millisecond)
	if err != nil {
		return err
	}
	writeOK(w, http.StatusOK, map[string]any{
		"token": token,
		"user":  store.PublicAdmin(found),
	})
	return nil
}

func (s *Server) adminRegister(w http.ResponseWriter, r *http.Request) error {
	body, err := readJSON(r)
	if err != nil {
		return err
	}
	username := strings.TrimSpace(store.AsString(body["username"]))
	password := store.AsString(body["password"])
	nickname := strings.TrimSpace(store.AsString(body["nickname"]))
	phone := strings.TrimSpace(store.AsString(body["phone"]))
	if len(username) < 3 || len(username) > 20 {
		return errs.New(http.StatusBadRequest, "VALIDATION", "用户名长度为 3-20 位")
	}
	if len(password) < 6 || len(password) > 128 {
		return errs.New(http.StatusBadRequest, "VALIDATION", "密码至少 6 位")
	}
	if nickname == "" {
		nickname = username
	}
	admins, err := s.db.ListCatalog("admins")
	if err != nil {
		return err
	}
	for _, item := range admins {
		if store.AsString(item["username"]) == username {
			return errs.New(http.StatusConflict, "CONFLICT", "用户名已存在")
		}
	}
	hash, err := auth.HashPassword(password)
	if err != nil {
		return err
	}
	created, err := s.db.InsertCatalog("admins", map[string]any{
		"username": username, "passwordHash": hash, "nickname": nickname,
		"role": "operator", "phone": phone, "createdAt": time.Now().UTC().Format(time.RFC3339),
	})
	if err != nil {
		return err
	}
	token, err := s.db.CreateAdminSession(store.AsInt64(created["id"]), time.Duration(s.cfg.SessionTTLMs)*time.Millisecond)
	if err != nil {
		return err
	}
	writeOK(w, http.StatusCreated, map[string]any{
		"token": token,
		"user":  store.PublicAdmin(created),
	})
	return nil
}

func (s *Server) adminCatalog(w http.ResponseWriter, r *http.Request) error {
	if err := s.requireAdmin(r); err != nil {
		return err
	}
	payload := map[string]any{}
	for _, kind := range []string{"groups", "cores", "assets", "plans", "agents", "commissionRules", "commissions"} {
		rows, err := s.db.ListCatalog(kind)
		if err != nil {
			return err
		}
		if kind == "agents" {
			public := make([]map[string]any, 0, len(rows))
			for _, row := range rows {
				public = append(public, store.PublicAgent(row))
			}
			payload[kind] = public
			continue
		}
		payload[kind] = rows
	}
	admins, err := s.db.ListCatalog("admins")
	if err != nil {
		return err
	}
	publicAdmins := make([]map[string]any, 0, len(admins))
	for _, item := range admins {
		publicAdmins = append(publicAdmins, store.PublicAdmin(item))
	}
	payload["admins"] = publicAdmins
	settings, ok, err := s.db.GetSingleton("appSettings")
	if err != nil {
		return err
	}
	if !ok {
		settings = map[string]any{}
	}
	payload["appSettings"] = settings
	users, err := s.presentUsers()
	if err != nil {
		return err
	}
	nodes, err := s.presentNodes()
	if err != nil {
		return err
	}
	payload["users"] = users
	payload["nodes"] = nodes
	writeOK(w, http.StatusOK, payload)
	return nil
}

func (s *Server) adminCreateCatalog(w http.ResponseWriter, r *http.Request) error {
	if err := s.requireAdmin(r); err != nil {
		return err
	}
	kind := param(r, "kind")
	if !mutableKinds[kind] {
		return errs.New(http.StatusNotFound, "NOT_FOUND", "接口不存在")
	}
	body, err := readJSON(r)
	if err != nil {
		return err
	}
	delete(body, "id")
	created, err := s.db.InsertCatalog(kind, body)
	if err != nil {
		return err
	}
	writeOK(w, http.StatusCreated, created)
	return nil
}

func (s *Server) adminPatchCatalog(w http.ResponseWriter, r *http.Request) error {
	if err := s.requireAdmin(r); err != nil {
		return err
	}
	kind := param(r, "kind")
	if !mutableKinds[kind] {
		return errs.New(http.StatusNotFound, "NOT_FOUND", "接口不存在")
	}
	id, err := idParam(r)
	if err != nil {
		return err
	}
	body, err := readJSON(r)
	if err != nil {
		return err
	}
	updated, err := s.db.UpdateCatalog(kind, id, body)
	if err != nil {
		return err
	}
	writeOK(w, http.StatusOK, updated)
	return nil
}

func (s *Server) adminDeleteCatalog(w http.ResponseWriter, r *http.Request) error {
	if err := s.requireAdmin(r); err != nil {
		return err
	}
	kind := param(r, "kind")
	if !mutableKinds[kind] {
		return errs.New(http.StatusNotFound, "NOT_FOUND", "接口不存在")
	}
	id, err := idParam(r)
	if err != nil {
		return err
	}
	if err := s.db.DeleteCatalog(kind, id); err != nil {
		return err
	}
	writeOK(w, http.StatusOK, map[string]any{"id": id})
	return nil
}

func (s *Server) adminPutAppSettings(w http.ResponseWriter, r *http.Request) error {
	if err := s.requireAdmin(r); err != nil {
		return err
	}
	body, err := readJSON(r)
	if err != nil {
		return err
	}
	saved, err := s.db.PutSingleton("appSettings", body)
	if err != nil {
		return err
	}
	patch := map[string]string{}
	if name := strings.TrimSpace(store.AsString(body["appName"])); name != "" {
		patch["profile_name"] = name
	}
	if support, ok := body["supportUrl"]; ok {
		patch["support_url"] = strings.TrimSpace(store.AsString(support))
	}
	if len(patch) > 0 {
		if _, err := s.db.SetSettings(patch); err != nil {
			return err
		}
	}
	title := "讯连宝"
	text := strings.TrimSpace(store.AsString(body["announcement"]))
	if text != "" {
		rows, err := s.db.ListAnnouncements(false)
		if err != nil {
			return err
		}
		if len(rows) == 0 {
			if _, err := s.db.CreateAnnouncement(title, text, true); err != nil {
				return err
			}
		} else {
			bodyText := text
			if _, err := s.db.UpdateAnnouncement(rows[0].ID, &title, &bodyText, nil); err != nil {
				return err
			}
		}
	}
	writeOK(w, http.StatusOK, saved)
	return nil
}

func (s *Server) adminSettleCommission(w http.ResponseWriter, r *http.Request) error {
	if err := s.requireAdmin(r); err != nil {
		return err
	}
	if param(r, "kind") != "commissions" {
		return errs.New(http.StatusNotFound, "NOT_FOUND", "接口不存在")
	}
	id, err := idParam(r)
	if err != nil {
		return err
	}
	row, ok, err := s.db.GetCatalog("commissions", id)
	if err != nil {
		return err
	}
	if !ok {
		return errs.New(http.StatusNotFound, "NOT_FOUND", "记录不存在")
	}
	if store.AsString(row["status"]) != "pending" {
		return errs.New(http.StatusBadRequest, "VALIDATION", "只有待结算记录可以结算")
	}
	updated, err := s.db.UpdateCatalog("commissions", id, map[string]any{
		"status":    "settled",
		"settledAt": time.Now().UTC().Format(time.RFC3339),
	})
	if err != nil {
		return err
	}
	agentID := store.AsInt64(row["agentId"])
	agent, ok, err := s.db.GetCatalog("agents", agentID)
	if err != nil {
		return err
	}
	if ok {
		amount := store.AsFloat(row["commission"])
		if _, err := s.db.UpdateCatalog("agents", agentID, map[string]any{
			"balance":         store.AsFloat(agent["balance"]) + amount,
			"totalCommission": store.AsFloat(agent["totalCommission"]) + amount,
		}); err != nil {
			return err
		}
	}
	writeOK(w, http.StatusOK, updated)
	return nil
}

func (s *Server) adminRejectCommission(w http.ResponseWriter, r *http.Request) error {
	if err := s.requireAdmin(r); err != nil {
		return err
	}
	if param(r, "kind") != "commissions" {
		return errs.New(http.StatusNotFound, "NOT_FOUND", "接口不存在")
	}
	id, err := idParam(r)
	if err != nil {
		return err
	}
	body, err := readJSON(r)
	if err != nil {
		return err
	}
	row, ok, err := s.db.GetCatalog("commissions", id)
	if err != nil {
		return err
	}
	if !ok {
		return errs.New(http.StatusNotFound, "NOT_FOUND", "记录不存在")
	}
	if store.AsString(row["status"]) != "pending" {
		return errs.New(http.StatusBadRequest, "VALIDATION", "只有待结算记录可以驳回")
	}
	remark := strings.TrimSpace(store.AsString(body["remark"]))
	if remark == "" {
		remark = store.AsString(row["remark"])
	}
	updated, err := s.db.UpdateCatalog("commissions", id, map[string]any{
		"status":    "rejected",
		"settledAt": time.Now().UTC().Format(time.RFC3339),
		"remark":    remark,
	})
	if err != nil {
		return err
	}
	writeOK(w, http.StatusOK, updated)
	return nil
}

func (s *Server) adminResetDemo(w http.ResponseWriter, r *http.Request) error {
	if err := s.requireAdmin(r); err != nil {
		return err
	}
	if err := s.db.ResetDemo(); err != nil {
		return err
	}
	if err := s.db.SeedDemo(); err != nil {
		return err
	}
	s.syncNodes()
	if err := s.db.KeepDemoOnline(); err != nil {
		return err
	}
	writeOK(w, http.StatusOK, map[string]any{"reset": true})
	return nil
}

func (s *Server) appBootstrap(w http.ResponseWriter, r *http.Request) error {
	if _, err := s.requireUser(r); err != nil {
		return err
	}
	plans, err := s.db.ListCatalog("plans")
	if err != nil {
		return err
	}
	openPlans := make([]map[string]any, 0, len(plans))
	for _, plan := range plans {
		if store.AsString(plan["status"]) == "on" {
			openPlans = append(openPlans, plan)
		}
	}
	notices, err := s.db.ListAnnouncements(true)
	if err != nil {
		return err
	}
	settings, _, err := s.db.GetSingleton("appSettings")
	if err != nil {
		return err
	}
	if settings == nil {
		settings = map[string]any{}
	}
	nodes, err := s.presentNodes()
	if err != nil {
		return err
	}
	publicNodes := make([]map[string]any, 0, len(nodes))
	for _, node := range nodes {
		if !node.Enabled {
			continue
		}
		publicNodes = append(publicNodes, map[string]any{
			"id": node.ID, "name": node.Name, "region": node.Region, "host": node.Host,
			"online": node.Online, "status": node.LineStatus, "latency": node.Latency,
			"coreType": node.CoreType, "groupId": node.GroupID,
		})
	}
	announcements := make([]PublicAnnouncement, 0, len(notices))
	for _, row := range notices {
		announcements = append(announcements, PublicAnnouncement{
			ID: row.ID, Title: row.Title, Body: row.Body, CreatedAt: row.CreatedAt,
		})
	}
	writeOK(w, http.StatusOK, map[string]any{
		"plans": plans, "openPlans": openPlans,
		"announcements": announcements, "settings": settings, "nodes": publicNodes,
	})
	return nil
}

func (s *Server) presentUsers() ([]AdminUser, error) {
	users, err := s.db.ListUsers(500)
	if err != nil {
		return nil, err
	}
	profiles, err := s.db.ListProfiles()
	if err != nil {
		return nil, err
	}
	out := make([]AdminUser, len(users))
	for i, user := range users {
		out[i] = attachProfile(adminUser(user, s.cfg), profiles[user.ID])
	}
	return out, nil
}

func (s *Server) presentNodes() ([]AdminNode, error) {
	nodes, err := s.db.ListNodes()
	if err != nil {
		return nil, err
	}
	meta, err := s.db.ListNodeMeta()
	if err != nil {
		return nil, err
	}
	now := time.Now().UnixMilli()
	out := make([]AdminNode, len(nodes))
	for i, node := range nodes {
		out[i] = attachNodeMeta(adminNode(node, now, s.cfg.NodeOfflineMs), meta[node.ID])
	}
	return out, nil
}

func (s *Server) saveUserProfile(id int64, body map[string]any) error {
	if !hasProfileFields(body) {
		return nil
	}
	current, _, err := s.db.FindProfile(id)
	if err != nil {
		return err
	}
	current.UserID = id
	if value, ok := body["displayName"]; ok {
		current.DisplayName = strings.TrimSpace(store.AsString(value))
	}
	if value, ok := body["phone"]; ok {
		current.Phone = strings.TrimSpace(store.AsString(value))
	}
	if _, ok := body["planId"]; ok {
		current.PlanID = store.AsInt64(body["planId"])
	}
	if _, ok := body["agentId"]; ok {
		current.AgentID = store.AsInt64(body["agentId"])
	}
	if value, ok := body["device"]; ok {
		current.Device = strings.TrimSpace(store.AsString(value))
	}
	if value, ok := body["platform"]; ok {
		current.Platform = strings.TrimSpace(store.AsString(value))
	}
	if value, ok := body["region"]; ok {
		current.Region = strings.TrimSpace(store.AsString(value))
	}
	return s.db.SaveProfile(current)
}

func (s *Server) saveNodeMeta(id int64, body map[string]any) error {
	if !hasNodeMeta(body) {
		return nil
	}
	current, _, err := s.db.FindNodeMeta(id)
	if err != nil {
		return err
	}
	current.NodeID = id
	if _, ok := body["groupId"]; ok {
		current.GroupID = store.AsInt64(body["groupId"])
	}
	if value, ok := body["coreType"]; ok {
		current.CoreType = store.AsString(value)
	}
	if value, ok := body["key"]; ok {
		current.Key = strings.TrimSpace(store.AsString(value))
	}
	if value, ok := body["lineType"]; ok {
		current.LineType = store.AsString(value)
	} else if value, ok := body["type"]; ok {
		lineType := store.AsString(value)
		if lineType == "local" || lineType == "remote" {
			current.LineType = lineType
		}
	}
	if _, ok := body["latency"]; ok {
		current.Latency = int(store.AsInt64(body["latency"]))
	}
	if value, ok := body["lineStatus"]; ok {
		current.LineStatus = store.AsString(value)
	} else if value, ok := body["status"]; ok {
		status := store.AsString(value)
		if status == "online" || status == "offline" || status == "maintain" {
			current.LineStatus = status
		}
	}
	if value, ok := body["url"]; ok {
		current.URL = strings.TrimSpace(store.AsString(value))
	}
	return s.db.SaveNodeMeta(current)
}

func normalizeNodeBody(body map[string]any) {
	if raw := strings.TrimSpace(store.AsString(body["url"])); raw != "" {
		body["host"] = hostOf(raw)
		return
	}
	if raw := strings.TrimSpace(store.AsString(body["host"])); strings.Contains(raw, "://") {
		body["url"] = raw
		body["host"] = hostOf(raw)
	}
}

func hostOf(raw string) string {
	parsed, err := url.Parse(raw)
	if err != nil || parsed.Hostname() == "" {
		if host, _, err := net.SplitHostPort(raw); err == nil {
			return host
		}
		return raw
	}
	return parsed.Hostname()
}

func hasProfileFields(body map[string]any) bool {
	for _, key := range []string{"displayName", "phone", "planId", "agentId", "device", "platform", "region"} {
		if _, ok := body[key]; ok {
			return true
		}
	}
	return false
}

func hasNodeMeta(body map[string]any) bool {
	for _, key := range []string{"groupId", "coreType", "key", "lineType", "type", "latency", "lineStatus", "status", "url"} {
		if _, ok := body[key]; ok {
			return true
		}
	}
	return false
}

func (s *Server) oneUser(user store.User) (AdminUser, error) {
	profile, _, err := s.db.FindProfile(user.ID)
	if err != nil {
		return AdminUser{}, err
	}
	return attachProfile(adminUser(user, s.cfg), profile), nil
}

func (s *Server) oneNode(node store.Node) (AdminNode, error) {
	meta, _, err := s.db.FindNodeMeta(node.ID)
	if err != nil {
		return AdminNode{}, err
	}
	return attachNodeMeta(adminNode(node, time.Now().UnixMilli(), s.cfg.NodeOfflineMs), meta), nil
}

func attachProfile(view AdminUser, profile store.Profile) AdminUser {
	view.DisplayName = profile.DisplayName
	view.Phone = profile.Phone
	view.PlanID = profile.PlanID
	view.AgentID = profile.AgentID
	view.Device = profile.Device
	view.Platform = profile.Platform
	view.Region = profile.Region
	view.LastLoginAt = profile.LastLoginAt
	return view
}

func attachNodeMeta(view AdminNode, meta store.NodeMeta) AdminNode {
	view.GroupID = meta.GroupID
	view.CoreType = meta.CoreType
	view.Key = meta.Key
	view.LineType = meta.LineType
	view.Latency = meta.Latency
	view.LineStatus = meta.LineStatus
	view.URL = meta.URL
	return view
}
