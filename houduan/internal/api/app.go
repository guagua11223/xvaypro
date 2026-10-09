package api

import (
	"net/http"
	"strconv"
	"time"

	"xvay/houduan/internal/auth"
	"xvay/houduan/internal/errs"
	"xvay/houduan/internal/store"
	"xvay/houduan/internal/subscription"
	"xvay/houduan/internal/validate"
)

func (s *Server) register(w http.ResponseWriter, r *http.Request) error {
	body, err := readJSON(r)
	if err != nil {
		return err
	}
	settings, err := s.db.GetSettings()
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
	total, err := validate.ParseBytes(settings["trial_bytes"], &zero)
	if err != nil {
		return err
	}
	user, err := s.db.CreateUser(store.UserInput{
		Email: email, Password: password, Total: total,
		ExpireAt: validate.TrialExpireAt(settings, time.Now()), DeviceLimit: 3,
	})
	if err != nil {
		return err
	}
	token, err := s.db.CreateSession(user, s.cfg.SessionTTLMs)
	if err != nil {
		return err
	}
	s.syncNodes()
	writeOK(w, http.StatusCreated, map[string]any{"token": token, "user": appUser(user, s.cfg)})
	return nil
}

func (s *Server) login(w http.ResponseWriter, r *http.Request) error {
	body, err := readJSON(r)
	if err != nil {
		return err
	}
	email, err := validate.ParseEmail(body["email"])
	if err != nil {
		return err
	}
	password, _ := body["password"].(string)
	user, ok, err := s.db.FindUserByEmail(email)
	if err != nil {
		return err
	}
	if !ok || !checkPassword(password, user.PasswordHash) {
		return unauthorized("邮箱或密码不正确")
	}
	token, err := s.db.CreateSession(user, s.cfg.SessionTTLMs)
	if err != nil {
		return err
	}
	writeOK(w, http.StatusOK, map[string]any{"token": token, "user": appUser(user, s.cfg)})
	return nil
}

func (s *Server) logout(w http.ResponseWriter, r *http.Request) error {
	if _, err := s.requireUser(r); err != nil {
		return err
	}
	token := bearer(r)
	if err := s.db.DeleteSession(token); err != nil {
		return err
	}
	writeOK(w, http.StatusOK, map[string]any{"loggedOut": true})
	return nil
}

func (s *Server) me(w http.ResponseWriter, r *http.Request) error {
	user, err := s.requireUser(r)
	if err != nil {
		return err
	}
	writeOK(w, http.StatusOK, appUser(user, s.cfg))
	return nil
}

func (s *Server) appNodes(w http.ResponseWriter, r *http.Request) error {
	if _, err := s.requireUser(r); err != nil {
		return err
	}
	nodes, err := s.db.ListNodes()
	if err != nil {
		return err
	}
	now := time.Now().UnixMilli()
	out := []PublicNode{}
	for _, node := range nodes {
		if node.Enabled && (node.XrayEnabled || node.Hy2Enabled) {
			out = append(out, publicNode(node, now, s.cfg.NodeOfflineMs))
		}
	}
	writeOK(w, http.StatusOK, map[string]any{"nodes": out})
	return nil
}

func (s *Server) appAnnouncements(w http.ResponseWriter, r *http.Request) error {
	if _, err := s.requireUser(r); err != nil {
		return err
	}
	rows, err := s.db.ListAnnouncements(true)
	if err != nil {
		return err
	}
	out := make([]PublicAnnouncement, len(rows))
	for i, row := range rows {
		out[i] = publicAnnouncement(row)
	}
	writeOK(w, http.StatusOK, map[string]any{"announcements": out})
	return nil
}

func (s *Server) profile(w http.ResponseWriter, r *http.Request) error {
	user, err := s.requireUser(r)
	if err != nil {
		return err
	}
	document, err := subscription.Build(s.db, s.cfg, user)
	if err != nil {
		return err
	}
	writeOK(w, http.StatusOK, document)
	return nil
}

func (s *Server) appTraffic(w http.ResponseWriter, r *http.Request) error {
	user, err := s.requireUser(r)
	if err != nil {
		return err
	}
	if !s.cfg.AcceptAppTraffic {
		return forbidden("流量以节点上报为准")
	}
	body, err := readJSON(r)
	if err != nil {
		return err
	}
	zero := int64(0)
	upload, err := validate.ParseBytes(body["upload"], &zero)
	if err != nil {
		return err
	}
	download, err := validate.ParseBytes(body["download"], &zero)
	if err != nil {
		return err
	}
	result, err := s.db.ApplyTraffic(0, []store.TrafficEntry{{
		UUID: user.UUID, Upload: upload, Download: download,
	}}, "delta")
	if err != nil {
		return err
	}
	if len(result.Updated) == 0 {
		writeOK(w, http.StatusOK, nil)
		return nil
	}
	writeOK(w, http.StatusOK, result.Updated[0])
	return nil
}

func (s *Server) subscription(w http.ResponseWriter, r *http.Request) error {
	user, ok, err := s.db.FindUserBySubToken(param(r, "token"))
	if err != nil {
		return err
	}
	if !ok {
		return notFound("订阅不存在")
	}
	format := r.URL.Query().Get("format")
	if format == "" {
		format = "anyportal"
	}
	switch format {
	case "v2ray":
		text, err := subscription.BuildV2ray(s.db, user)
		if err != nil {
			return err
		}
		writeText(w, http.StatusOK, text, map[string]string{
			"subscription-userinfo": subscription.UserInfoHeader(user),
		})
		return nil
	case "anyportal":
		document, err := subscription.Build(s.db, s.cfg, user)
		if err != nil {
			return err
		}
		interval, _ := document["autoUpdateInterval"].(int)
		w.Header().Set("profile-update-interval", strconv.Itoa(interval))
		w.Header().Set("subscription-userinfo", subscription.UserInfoHeader(user))
		writeJSON(w, http.StatusOK, document)
		return nil
	default:
		return badRequest("format 只能是 anyportal 或 v2ray")
	}
}

func bearer(r *http.Request) string {
	return auth.BearerToken(r.Header.Get("Authorization"))
}

func checkPassword(password, hash string) bool {
	return auth.VerifyPassword(password, hash)
}

func badRequest(message string) error {
	return errs.New(http.StatusBadRequest, "VALIDATION", message)
}

func unauthorized(message string) error {
	return errs.New(http.StatusUnauthorized, "UNAUTHORIZED", message)
}

func forbidden(message string) error {
	return errs.New(http.StatusForbidden, "FORBIDDEN", message)
}

func notFound(message string) error {
	return errs.New(http.StatusNotFound, "NOT_FOUND", message)
}
