package api

import (
	"net/http"
	"strconv"
	"strings"
	"time"
	"unicode/utf8"

	"xvay/houduan/internal/auth"
	"xvay/houduan/internal/errs"
	"xvay/houduan/internal/protocol"
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
	username := strings.TrimSpace(store.AsString(body["username"]))
	invite := strings.TrimSpace(store.AsString(body["inviteCode"]))
	var email string
	if username != "" {
		if err := validUsername(username); err != nil {
			return err
		}
		taken, err := s.db.UsernameTaken(username, 0)
		if err != nil {
			return err
		}
		if taken {
			return errs.New(http.StatusConflict, "CONFLICT", "用户名已存在")
		}
		if strings.TrimSpace(store.AsString(body["email"])) != "" {
			email, err = validate.ParseEmail(body["email"])
			if err != nil {
				return err
			}
		} else {
			email = username + "@member.xvay"
		}
	} else {
		email, err = validate.ParseEmail(body["email"])
		if err != nil {
			return err
		}
		username = email
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
	if err := s.db.InitMember(user.ID, username, invite); err != nil {
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
	account := strings.TrimSpace(store.AsString(body["username"]))
	if account == "" {
		account = strings.TrimSpace(store.AsString(body["email"]))
	}
	password, _ := body["password"].(string)
	member, ok, err := s.db.FindLogin(account)
	if err != nil {
		return err
	}
	user, found := store.User{}, false
	if ok {
		user, found, err = s.db.FindUserByID(member.ID)
		if err != nil {
			return err
		}
	}
	if !found || !checkPassword(password, user.PasswordHash) {
		_ = s.db.AddLoginLog("user", account, false, clientIP(r), deviceOf(r))
		return unauthorized("账号或密码不正确")
	}
	if member.MemberStatus == 1 || user.Status == "disabled" {
		return forbidden("账号已封禁")
	}
	_ = s.db.AddLoginLog("user", account, true, clientIP(r), deviceOf(r))
	token, err := s.db.CreateSession(user, s.cfg.SessionTTLMs)
	if err != nil {
		return err
	}
	writeOK(w, http.StatusOK, map[string]any{"token": token, "user": appUser(user, s.cfg)})
	return nil
}

func (s *Server) appKeys(w http.ResponseWriter, r *http.Request) error {
	if _, err := s.requireUser(r); err != nil {
		return err
	}
	writeOK(w, http.StatusOK, protocol.VLESSKeys())
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
	writeOK(w, http.StatusOK, s.presentUser(user))
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

func validUsername(username string) error {
	n := utf8.RuneCountInString(username)
	if n < 3 || n > 20 || strings.ContainsAny(username, " \t@") {
		return badRequest("用户名需要 3-20 位，且不能包含空格或 @")
	}
	return nil
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
