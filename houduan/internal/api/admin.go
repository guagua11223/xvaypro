package api

import (
	"net/http"
	"strconv"
	"strings"
	"time"

	"xvay/houduan/internal/render"
	"xvay/houduan/internal/store"
	"xvay/houduan/internal/subscription"
	"xvay/houduan/internal/validate"
)

func (s *Server) overview(w http.ResponseWriter, r *http.Request) error {
	if err := s.requireAdmin(r); err != nil {
		return err
	}
	users, err := s.db.CountUsers()
	if err != nil {
		return err
	}
	nodes, err := s.db.CountNodes()
	if err != nil {
		return err
	}
	upload, download, err := s.db.TrafficSummary()
	if err != nil {
		return err
	}
	writeOK(w, http.StatusOK, map[string]any{
		"users": users, "nodes": nodes, "upload": upload, "download": download,
	})
	return nil
}

func (s *Server) adminUsers(w http.ResponseWriter, r *http.Request) error {
	if err := s.requireAdmin(r); err != nil {
		return err
	}
	limit, err := queryLimit(r)
	if err != nil {
		return err
	}
	users, err := s.db.ListUsers(limit)
	if err != nil {
		return err
	}
	out := make([]AdminUser, len(users))
	for i, user := range users {
		out[i] = adminUser(user, s.cfg)
	}
	writeOK(w, http.StatusOK, map[string]any{"users": out})
	return nil
}

func (s *Server) adminCreateUser(w http.ResponseWriter, r *http.Request) error {
	if err := s.requireAdmin(r); err != nil {
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
	password, err := validate.ParsePassword(body["password"])
	if err != nil {
		return err
	}
	zero := int64(0)
	total, err := validate.ParseBytes(body["total"], &zero)
	if err != nil {
		return err
	}
	expireAt, err := validate.ParseTime(body["expireAt"])
	if err != nil {
		return err
	}
	status := "active"
	if _, ok := body["status"]; ok && body["status"] != nil {
		status, err = validate.ParseStatus(body["status"])
		if err != nil {
			return err
		}
	}
	deviceLimit := int64(3)
	if _, ok := body["deviceLimit"]; ok && body["deviceLimit"] != nil {
		deviceLimit, err = validate.NonNegative(body["deviceLimit"], "设备数")
		if err != nil {
			return err
		}
	}
	user, err := s.db.CreateUser(store.UserInput{
		Email: email, Password: password, Total: total, ExpireAt: expireAt, Status: status, DeviceLimit: deviceLimit,
	})
	if err != nil {
		return err
	}
	writeOK(w, http.StatusCreated, adminUser(user, s.cfg))
	return nil
}

func (s *Server) adminGetUser(w http.ResponseWriter, r *http.Request) error {
	if err := s.requireAdmin(r); err != nil {
		return err
	}
	id, err := idParam(r)
	if err != nil {
		return err
	}
	user, ok, err := s.db.FindUserByID(id)
	if err != nil {
		return err
	}
	if !ok {
		return notFound("用户不存在")
	}
	writeOK(w, http.StatusOK, adminUser(user, s.cfg))
	return nil
}

func (s *Server) adminPatchUser(w http.ResponseWriter, r *http.Request) error {
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
	var patch store.UserPatch
	if value, ok := body["email"]; ok && value != nil {
		email, err := validate.ParseEmail(value)
		if err != nil {
			return err
		}
		patch.Email = &email
	}
	if value, ok := body["password"]; ok && value != nil {
		password, err := validate.ParsePassword(value)
		if err != nil {
			return err
		}
		patch.Password = &password
	}
	if value, ok := body["total"]; ok && value != nil {
		total, err := validate.ParseBytes(value, nil)
		if err != nil {
			return err
		}
		patch.Total = &total
	}
	if value, ok := body["expireAt"]; ok && value != nil {
		expireAt, err := validate.ParseTime(value)
		if err != nil {
			return err
		}
		patch.ExpireAt = &expireAt
	}
	if value, ok := body["status"]; ok && value != nil {
		status, err := validate.ParseStatus(value)
		if err != nil {
			return err
		}
		patch.Status = &status
	}
	if value, ok := body["deviceLimit"]; ok && value != nil {
		limit, err := validate.NonNegative(value, "设备数")
		if err != nil {
			return err
		}
		patch.DeviceLimit = &limit
	}
	if value, ok := body["upload"]; ok && value != nil {
		upload, err := validate.ParseBytes(value, nil)
		if err != nil {
			return err
		}
		patch.Upload = &upload
	}
	if value, ok := body["download"]; ok && value != nil {
		download, err := validate.ParseBytes(value, nil)
		if err != nil {
			return err
		}
		patch.Download = &download
	}
	user, err := s.db.UpdateUser(id, patch)
	if err != nil {
		return err
	}
	writeOK(w, http.StatusOK, adminUser(user, s.cfg))
	return nil
}

func (s *Server) adminDeleteUser(w http.ResponseWriter, r *http.Request) error {
	if err := s.requireAdmin(r); err != nil {
		return err
	}
	id, err := idParam(r)
	if err != nil {
		return err
	}
	if err := s.db.DeleteUser(id); err != nil {
		return err
	}
	writeOK(w, http.StatusOK, map[string]any{"id": id})
	return nil
}

func (s *Server) adminResetTraffic(w http.ResponseWriter, r *http.Request) error {
	if err := s.requireAdmin(r); err != nil {
		return err
	}
	id, err := idParam(r)
	if err != nil {
		return err
	}
	user, err := s.db.ResetTraffic(id)
	if err != nil {
		return err
	}
	writeOK(w, http.StatusOK, adminUser(user, s.cfg))
	return nil
}

func (s *Server) adminResetToken(w http.ResponseWriter, r *http.Request) error {
	if err := s.requireAdmin(r); err != nil {
		return err
	}
	id, err := idParam(r)
	if err != nil {
		return err
	}
	user, err := s.db.ResetSubToken(id)
	if err != nil {
		return err
	}
	writeOK(w, http.StatusOK, adminUser(user, s.cfg))
	return nil
}

func (s *Server) adminNodes(w http.ResponseWriter, r *http.Request) error {
	if err := s.requireAdmin(r); err != nil {
		return err
	}
	nodes, err := s.db.ListNodes()
	if err != nil {
		return err
	}
	now := time.Now().UnixMilli()
	out := make([]AdminNode, len(nodes))
	for i, node := range nodes {
		out[i] = adminNode(node, now, s.cfg.NodeOfflineMs)
	}
	writeOK(w, http.StatusOK, map[string]any{"nodes": out})
	return nil
}

func (s *Server) adminCreateNode(w http.ResponseWriter, r *http.Request) error {
	if err := s.requireAdmin(r); err != nil {
		return err
	}
	body, err := readJSON(r)
	if err != nil {
		return err
	}
	input, err := validate.NodeCreateInput(body)
	if err != nil {
		return err
	}
	node, err := s.db.CreateNode(input)
	if err != nil {
		return err
	}
	writeOK(w, http.StatusCreated, adminNode(node, time.Now().UnixMilli(), s.cfg.NodeOfflineMs))
	return nil
}

func (s *Server) adminGetNode(w http.ResponseWriter, r *http.Request) error {
	if err := s.requireAdmin(r); err != nil {
		return err
	}
	node, err := s.loadNode(r)
	if err != nil {
		return err
	}
	writeOK(w, http.StatusOK, adminNode(node, time.Now().UnixMilli(), s.cfg.NodeOfflineMs))
	return nil
}

func (s *Server) adminPatchNode(w http.ResponseWriter, r *http.Request) error {
	if err := s.requireAdmin(r); err != nil {
		return err
	}
	id, err := idParam(r)
	if err != nil {
		return err
	}
	current, ok, err := s.db.FindNode(id)
	if err != nil {
		return err
	}
	if !ok {
		return notFound("节点不存在")
	}
	body, err := readJSON(r)
	if err != nil {
		return err
	}
	patch, err := validate.NodePatchInput(body)
	if err != nil {
		return err
	}
	xrayPort, apiPort, hy2Port := current.XrayPort, current.XrayAPIPort, current.Hy2Port
	if patch.XrayPort != nil {
		xrayPort = *patch.XrayPort
	}
	if patch.XrayAPIPort != nil {
		apiPort = *patch.XrayAPIPort
	}
	if patch.Hy2Port != nil {
		hy2Port = *patch.Hy2Port
	}
	if err := validate.AssertDistinctPorts(xrayPort, apiPort, hy2Port); err != nil {
		return err
	}
	node, err := s.db.UpdateNode(id, patch)
	if err != nil {
		return err
	}
	writeOK(w, http.StatusOK, adminNode(node, time.Now().UnixMilli(), s.cfg.NodeOfflineMs))
	return nil
}

func (s *Server) adminDeleteNode(w http.ResponseWriter, r *http.Request) error {
	if err := s.requireAdmin(r); err != nil {
		return err
	}
	id, err := idParam(r)
	if err != nil {
		return err
	}
	if err := s.db.DeleteNode(id); err != nil {
		return err
	}
	writeOK(w, http.StatusOK, map[string]any{"id": id})
	return nil
}

func (s *Server) adminNodeConfig(w http.ResponseWriter, r *http.Request) error {
	if err := s.requireAdmin(r); err != nil {
		return err
	}
	node, err := s.loadNode(r)
	if err != nil {
		return err
	}
	bundle, err := subscription.NodeBundle(s.db, s.cfg, node)
	if err != nil {
		return err
	}
	writeOK(w, http.StatusOK, bundle)
	return nil
}

func (s *Server) adminRenderNode(w http.ResponseWriter, r *http.Request) error {
	if err := s.requireAdmin(r); err != nil {
		return err
	}
	node, err := s.loadNode(r)
	if err != nil {
		return err
	}
	bundle, err := subscription.NodeBundle(s.db, s.cfg, node)
	if err != nil {
		return err
	}
	files, err := render.WriteBundle(s.cfg, bundle)
	if err != nil {
		return err
	}
	writeOK(w, http.StatusOK, map[string]any{"files": files, "bundle": bundle})
	return nil
}

func (s *Server) adminSettings(w http.ResponseWriter, r *http.Request) error {
	if err := s.requireAdmin(r); err != nil {
		return err
	}
	settings, err := s.db.GetSettings()
	if err != nil {
		return err
	}
	writeOK(w, http.StatusOK, settingsView(settings))
	return nil
}

func (s *Server) adminPutSettings(w http.ResponseWriter, r *http.Request) error {
	if err := s.requireAdmin(r); err != nil {
		return err
	}
	body, err := readJSON(r)
	if err != nil {
		return err
	}
	patch := map[string]string{}
	if value, ok := body["profileName"]; ok && value != nil {
		text := asTrimmed(value)
		if text == "" {
			text = "飞连"
		}
		patch["profile_name"] = text
	}
	if value, ok := body["supportUrl"]; ok && value != nil {
		patch["support_url"] = asTrimmed(value)
	}
	if value, ok := body["profileWebPageUrl"]; ok && value != nil {
		patch["profile_web_page_url"] = asTrimmed(value)
	}
	if value, ok := body["autoUpdateInterval"]; ok && value != nil {
		n, err := validate.NonNegative(value, "更新间隔")
		if err != nil {
			return err
		}
		patch["auto_update_interval"] = strconv.FormatInt(n, 10)
	}
	if value, ok := body["trialBytes"]; ok && value != nil {
		n, err := validate.ParseBytes(value, nil)
		if err != nil {
			return err
		}
		patch["trial_bytes"] = strconv.FormatInt(n, 10)
	}
	if value, ok := body["trialDays"]; ok && value != nil {
		n, err := validate.NonNegative(value, "试用天数")
		if err != nil {
			return err
		}
		patch["trial_days"] = strconv.FormatInt(n, 10)
	}
	settings, err := s.db.SetSettings(patch)
	if err != nil {
		return err
	}
	writeOK(w, http.StatusOK, settingsView(settings))
	return nil
}

func (s *Server) adminAnnouncements(w http.ResponseWriter, r *http.Request) error {
	if err := s.requireAdmin(r); err != nil {
		return err
	}
	rows, err := s.db.ListAnnouncements(false)
	if err != nil {
		return err
	}
	writeOK(w, http.StatusOK, map[string]any{"announcements": rows})
	return nil
}

func (s *Server) adminCreateAnnouncement(w http.ResponseWriter, r *http.Request) error {
	if err := s.requireAdmin(r); err != nil {
		return err
	}
	body, err := readJSON(r)
	if err != nil {
		return err
	}
	title, err := validate.RequiredText(body["title"], "标题")
	if err != nil {
		return err
	}
	text, err := validate.RequiredText(body["body"], "内容")
	if err != nil {
		return err
	}
	enabled := true
	if _, ok := body["enabled"]; ok && body["enabled"] != nil {
		enabled, _ = body["enabled"].(bool)
	}
	row, err := s.db.CreateAnnouncement(title, text, enabled)
	if err != nil {
		return err
	}
	writeOK(w, http.StatusCreated, row)
	return nil
}

func (s *Server) adminPatchAnnouncement(w http.ResponseWriter, r *http.Request) error {
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
	var title, text *string
	var enabled *bool
	if value, ok := body["title"]; ok && value != nil {
		parsed, err := validate.RequiredText(value, "标题")
		if err != nil {
			return err
		}
		title = &parsed
	}
	if value, ok := body["body"]; ok && value != nil {
		parsed, err := validate.RequiredText(value, "内容")
		if err != nil {
			return err
		}
		text = &parsed
	}
	if value, ok := body["enabled"]; ok && value != nil {
		flag, _ := value.(bool)
		enabled = &flag
	}
	row, err := s.db.UpdateAnnouncement(id, title, text, enabled)
	if err != nil {
		return err
	}
	writeOK(w, http.StatusOK, row)
	return nil
}

func (s *Server) adminDeleteAnnouncement(w http.ResponseWriter, r *http.Request) error {
	if err := s.requireAdmin(r); err != nil {
		return err
	}
	id, err := idParam(r)
	if err != nil {
		return err
	}
	if err := s.db.DeleteAnnouncement(id); err != nil {
		return err
	}
	writeOK(w, http.StatusOK, map[string]any{"id": id})
	return nil
}

func (s *Server) loadNode(r *http.Request) (store.Node, error) {
	id, err := idParam(r)
	if err != nil {
		return store.Node{}, err
	}
	node, ok, err := s.db.FindNode(id)
	if err != nil {
		return store.Node{}, err
	}
	if !ok {
		return store.Node{}, notFound("节点不存在")
	}
	return node, nil
}

func asTrimmed(value any) string {
	text, _ := value.(string)
	return strings.TrimSpace(text)
}
