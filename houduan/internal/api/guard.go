package api

import (
	"net/http"
	"strings"
	"time"

	"xvay/houduan/internal/auth"
	"xvay/houduan/internal/errs"
	"xvay/houduan/internal/store"
)

func (s *Server) requireUser(r *http.Request) (store.User, error) {
	token := auth.BearerToken(r.Header.Get("Authorization"))
	if token == "" {
		return store.User{}, errs.New(http.StatusUnauthorized, "UNAUTHORIZED", "请先登录")
	}
	user, ok, err := s.db.FindUserBySession(token, time.Now().UnixMilli())
	if err != nil {
		return store.User{}, err
	}
	if !ok {
		return store.User{}, errs.New(http.StatusUnauthorized, "UNAUTHORIZED", "登录已失效")
	}
	return user, nil
}

func (s *Server) requireAdmin(r *http.Request) error {
	role, err := s.adminRole(r)
	if err != nil {
		return err
	}
	if roleAllowed(role, r.Method, r.URL.Path) {
		return nil
	}
	return errs.New(http.StatusForbidden, "FORBIDDEN", "当前角色无权访问该功能")
}

func (s *Server) adminRole(r *http.Request) (string, error) {
	token := auth.BearerToken(r.Header.Get("Authorization"))
	if token == "" {
		return "", errs.New(http.StatusUnauthorized, "UNAUTHORIZED", "管理凭证无效")
	}
	if s.cfg.AdminToken != "" && auth.SafeEqual(token, s.cfg.AdminToken) {
		return "super", nil
	}
	id, ok, err := s.db.AdminSessionAdminID(token, time.Now().UnixMilli())
	if err != nil {
		return "", err
	}
	if !ok {
		return "", errs.New(http.StatusUnauthorized, "UNAUTHORIZED", "管理凭证无效")
	}
	admins, err := s.db.ListCatalog("admins")
	if err != nil {
		return "", err
	}
	for _, item := range admins {
		if store.AsInt64(item["id"]) != id {
			continue
		}
		role := store.AsString(item["role"])
		if role == "" {
			role = "operator"
		}
		return role, nil
	}
	return "operator", nil
}

func roleAllowed(role, method, path string) bool {
	switch role {
	case "super", "operator":
		return true
	case "finance":
		return strings.HasPrefix(path, "/api/admin/withdrawals") ||
			strings.Contains(path, "/refunds") ||
			path == "/api/admin/orders" ||
			(method == http.MethodGet && path == "/api/admin/users")
	case "support":
		return strings.HasPrefix(path, "/api/admin/tickets") ||
			path == "/api/admin/support" ||
			(method == http.MethodGet && strings.HasPrefix(path, "/api/admin/announcements"))
	default:
		return false
	}
}

func (s *Server) requireNode(r *http.Request, id int64) (store.Node, error) {
	node, ok, err := s.db.FindNode(id)
	if err != nil {
		return store.Node{}, err
	}
	if !ok {
		return store.Node{}, errs.New(http.StatusNotFound, "NOT_FOUND", "节点不存在")
	}
	if !auth.SafeEqual(r.Header.Get("X-Node-Secret"), node.Secret) {
		return store.Node{}, errs.New(http.StatusUnauthorized, "UNAUTHORIZED", "节点凭证无效")
	}
	return node, nil
}
