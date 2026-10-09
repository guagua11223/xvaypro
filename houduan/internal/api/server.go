package api

import (
	"log"
	"net/http"

	"xvay/houduan/internal/config"
	"xvay/houduan/internal/nodeproc"
	"xvay/houduan/internal/store"
)

type Server struct {
	cfg    config.Config
	db     *store.Store
	routes []route
}

func New(cfg config.Config, db *store.Store) *Server {
	s := &Server{cfg: cfg, db: db}
	s.routes = []route{
		{http.MethodGet, "/health", s.health},

		{http.MethodPost, "/api/app/register", s.register},
		{http.MethodPost, "/api/app/login", s.login},
		{http.MethodPost, "/api/app/logout", s.logout},
		{http.MethodGet, "/api/app/me", s.me},
		{http.MethodGet, "/api/app/nodes", s.appNodes},
		{http.MethodGet, "/api/app/announcements", s.appAnnouncements},
		{http.MethodGet, "/api/app/profile", s.profile},
		{http.MethodPost, "/api/app/traffic", s.appTraffic},
		{http.MethodGet, "/api/sub/:token", s.subscription},

		{http.MethodPost, "/api/node/:id/heartbeat", s.nodeHeartbeat},
		{http.MethodPost, "/api/node/:id/traffic", s.nodeTraffic},
		{http.MethodGet, "/api/node/:id/xray", s.nodeXray},
		{http.MethodGet, "/api/node/:id/hysteria2", s.nodeHysteria},
		{http.MethodGet, "/api/node/:id/bundle", s.nodeBundleRoute},

		{http.MethodGet, "/api/admin/overview", s.overview},
		{http.MethodGet, "/api/admin/users", s.adminUsers},
		{http.MethodPost, "/api/admin/users", s.adminCreateUser},
		{http.MethodGet, "/api/admin/users/:id", s.adminGetUser},
		{http.MethodPatch, "/api/admin/users/:id", s.adminPatchUser},
		{http.MethodDelete, "/api/admin/users/:id", s.adminDeleteUser},
		{http.MethodPost, "/api/admin/users/:id/reset-traffic", s.adminResetTraffic},
		{http.MethodPost, "/api/admin/users/:id/reset-token", s.adminResetToken},
		{http.MethodGet, "/api/admin/nodes", s.adminNodes},
		{http.MethodPost, "/api/admin/nodes", s.adminCreateNode},
		{http.MethodGet, "/api/admin/nodes/:id", s.adminGetNode},
		{http.MethodPatch, "/api/admin/nodes/:id", s.adminPatchNode},
		{http.MethodDelete, "/api/admin/nodes/:id", s.adminDeleteNode},
		{http.MethodGet, "/api/admin/nodes/:id/config", s.adminNodeConfig},
		{http.MethodPost, "/api/admin/nodes/:id/render", s.adminRenderNode},
		{http.MethodGet, "/api/admin/settings", s.adminSettings},
		{http.MethodPut, "/api/admin/settings", s.adminPutSettings},
		{http.MethodGet, "/api/admin/announcements", s.adminAnnouncements},
		{http.MethodPost, "/api/admin/announcements", s.adminCreateAnnouncement},
		{http.MethodPatch, "/api/admin/announcements/:id", s.adminPatchAnnouncement},
		{http.MethodDelete, "/api/admin/announcements/:id", s.adminDeleteAnnouncement},
	}
	return s
}

func (s *Server) syncNodes() {
	if err := nodeproc.Sync(s.db, s.cfg); err != nil {
		log.Printf("sync nodes: %v", err)
	}
}

func (s *Server) health(w http.ResponseWriter, _ *http.Request) error {
	writeOK(w, http.StatusOK, map[string]any{"status": "up"})
	return nil
}
