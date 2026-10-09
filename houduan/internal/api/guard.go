package api

import (
	"net/http"
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
	token := auth.BearerToken(r.Header.Get("Authorization"))
	if s.cfg.AdminToken == "" || !auth.SafeEqual(token, s.cfg.AdminToken) {
		return errs.New(http.StatusUnauthorized, "UNAUTHORIZED", "管理凭证无效")
	}
	return nil
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
