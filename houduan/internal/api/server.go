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
		{http.MethodGet, "/api/app/plans", s.appPlans},
		{http.MethodPost, "/api/app/orders/checkout", s.appCheckout},
		{http.MethodPost, "/api/app/orders/renew", s.appRenew},
		{http.MethodGet, "/api/app/wallet", s.appWallet},
		{http.MethodGet, "/api/app/rebates", s.appRebates},
		{http.MethodPost, "/api/app/withdrawals", s.appWithdraw},
		{http.MethodGet, "/api/app/promotion", s.appPromotion},
		{http.MethodGet, "/api/app/invite/qr.png", s.appInviteQR},
		{http.MethodPost, "/api/app/tickets", s.createTicket},
		{http.MethodPost, "/api/pay/debug", s.payDebug},
		{http.MethodGet, "/api/admin/commissions/preview", s.adminCommissionPreview},
		{http.MethodPost, "/api/admin/commissions/settle", s.adminSettleCommissions},
		{http.MethodGet, "/api/admin/requests", s.adminRequests},
		{http.MethodPost, "/api/admin/requests/:id/review", s.adminReviewRequest},
		{http.MethodPatch, "/api/admin/tickets/:id", s.adminPatchTicket},
		{http.MethodPost, "/api/admin/users/:id/distributor", s.legacyAdminSetDistributor},
		{http.MethodPost, "/api/admin/orders/:id/refunds", s.adminCreateRefund},
		{http.MethodGet, "/api/app/nodes", s.appNodes},
		{http.MethodGet, "/api/app/announcements", s.appAnnouncements},
		{http.MethodGet, "/api/app/bootstrap", s.appBootstrap},
		{http.MethodGet, "/api/app/keys", s.appKeys},
		{http.MethodGet, "/api/app/profile", s.profile},
		{http.MethodPost, "/api/app/connect", s.appConnect},
		{http.MethodPost, "/api/app/disconnect", s.appDisconnect},
		{http.MethodPost, "/api/app/traffic", s.appTraffic},
		{http.MethodGet, "/api/sub/:token", s.subscription},

		{http.MethodPost, "/api/node/:id/heartbeat", s.nodeHeartbeat},
		{http.MethodPost, "/api/node/:id/traffic", s.nodeTraffic},
		{http.MethodGet, "/api/node/:id/xray", s.nodeXray},
		{http.MethodGet, "/api/node/:id/hysteria2", s.nodeHysteria},
		{http.MethodGet, "/api/node/:id/bundle", s.nodeBundleRoute},

		{http.MethodGet, "/api/user/profile", s.userProfile},
		{http.MethodGet, "/api/user/security", s.userSecurity},
		{http.MethodPost, "/api/user/invite/bind", s.userBindInvite},
		{http.MethodPost, "/api/user/password/change", s.userChangePassword},
		{http.MethodPost, "/api/user/email/bind", s.bindEmail},
		{http.MethodGet, "/api/user/tickets", s.userTickets},
		{http.MethodPost, "/api/user/tickets", s.userTickets},
		{http.MethodGet, "/api/packages", s.listPackages},
		{http.MethodPost, "/api/orders", s.createOrder},
		{http.MethodGet, "/api/orders", s.listMyOrders},
		{http.MethodPost, "/api/orders/cancel", s.cancelMyOrder},
		{http.MethodGet, "/api/wallet", s.userWallet},
		{http.MethodPost, "/api/wallet/withdraw", s.userWithdraw},
		{http.MethodGet, "/api/invite", s.userInvite},
		{http.MethodGet, "/api/announcements", s.publicNotices},
		{http.MethodGet, "/api/ads", s.publicAds},
		{http.MethodGet, "/api/customer-service", s.publicSupport},
		{http.MethodPost, "/api/auth/email/send-code", s.sendEmailCode},
		{http.MethodPost, "/api/auth/find-account", s.findAccount},
		{http.MethodPost, "/api/auth/reset-password-by-email", s.resetPasswordByEmail},
		{http.MethodPost, "/api/pay/create", s.payCreate},
		{http.MethodPost, "/api/pay/notify/fourth", s.payNotifyFourth},
		{http.MethodPost, "/api/pay/notify/epay", s.payNotifyEpay},
		{http.MethodPost, "/api/pay/refund", s.payRefund},

		{http.MethodPost, "/api/distributor/login", s.distributorLogin},
		{http.MethodGet, "/api/distributor/dashboard", s.distributorDashboard},
		{http.MethodGet, "/api/distributor/members", s.distributorMembers},
		{http.MethodPost, "/api/distributor/members/:id/rate", s.distributorSetRate},
		{http.MethodPost, "/api/distributor/members/:id/agent", s.distributorSetAgent},
		{http.MethodPost, "/api/distributor/members/:id/ban-request", s.distributorBanRequest},
		{http.MethodGet, "/api/distributor/orders", s.distributorOrders},
		{http.MethodGet, "/api/distributor/commissions", s.distributorCommissions},
		{http.MethodGet, "/api/distributor/withdrawals", s.distributorWithdrawals},
		{http.MethodPost, "/api/distributor/withdrawals", s.distributorWithdrawals},
		{http.MethodGet, "/api/distributor/invite", s.distributorInvite},
		{http.MethodGet, "/api/distributor/announcements", s.distributorNotices},
		{http.MethodGet, "/api/distributor/customer-service", s.distributorSupport},

		{http.MethodPost, "/api/agent/register", s.agentRegister},
		{http.MethodPost, "/api/agent/login", s.agentLogin},
		{http.MethodPost, "/api/agent/logout", s.agentLogout},
		{http.MethodGet, "/api/agent/me", s.agentMe},
		{http.MethodGet, "/api/agent/team", s.agentTeam},
		{http.MethodGet, "/api/agent/commissions", s.agentCommissions},

		{http.MethodPost, "/api/admin/login", s.adminLogin},
		{http.MethodPost, "/api/admin/register", s.adminRegister},
		{http.MethodPost, "/api/admin/demo/reset", s.adminResetDemo},
		{http.MethodGet, "/api/admin/catalog", s.adminCatalog},
		{http.MethodPut, "/api/admin/catalog/appSettings", s.adminPutAppSettings},
		{http.MethodPost, "/api/admin/catalog/:kind/:id/settle", s.adminSettleCommission},
		{http.MethodPost, "/api/admin/catalog/:kind/:id/reject", s.adminRejectCommission},
		{http.MethodPost, "/api/admin/catalog/:kind", s.adminCreateCatalog},
		{http.MethodPatch, "/api/admin/catalog/:kind/:id", s.adminPatchCatalog},
		{http.MethodDelete, "/api/admin/catalog/:kind/:id", s.adminDeleteCatalog},
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
		{http.MethodGet, "/api/admin/stats", s.adminStats},
		{http.MethodGet, "/api/admin/members", s.adminMembers},
		{http.MethodPost, "/api/admin/members/:id/distributor/cancel", s.adminSetDistributor},
		{http.MethodPost, "/api/admin/members/:id/distributor", s.adminSetDistributor},
		{http.MethodPost, "/api/admin/members/:id/agent", s.adminSetAgent},
		{http.MethodPost, "/api/admin/members/:id/ban", s.adminBan},
		{http.MethodPost, "/api/admin/members/:id/unban", s.adminUnban},
		{http.MethodPost, "/api/admin/members/:id/email/unbind", s.adminUnbindEmail},
		{http.MethodPost, "/api/admin/members/:id/parent", s.adminSetParent},
		{http.MethodPost, "/api/admin/members/:id/rate", s.adminSetMemberRate},
		{http.MethodGet, "/api/admin/members/:id/records", s.adminMemberRecords},
		{http.MethodPost, "/api/admin/system/backup", s.adminBackup},
		{http.MethodGet, "/api/admin/distributors", s.adminDistributors},
		{http.MethodPost, "/api/admin/distributors/:id/rate", s.adminDistributorRate},
		{http.MethodGet, "/api/admin/commerce/orders", s.adminCommerceOrders},
		{http.MethodPost, "/api/admin/commerce/orders/:id/refund", s.adminCommerceRefund},
		{http.MethodGet, "/api/admin/withdrawals", s.adminWithdrawals},
		{http.MethodPost, "/api/admin/withdrawals/rules", s.adminSaveWithdrawRules},
		{http.MethodPost, "/api/admin/withdrawals/:id/audit", s.adminAuditWithdrawal},
		{http.MethodGet, "/api/admin/refunds", s.adminRefunds},
		{http.MethodPost, "/api/admin/refunds/:id/handle", s.adminHandleRefund},
		{http.MethodGet, "/api/admin/commission-settings", s.adminCommissionSettings},
		{http.MethodPost, "/api/admin/commission-settings", s.adminCommissionSettings},
		{http.MethodGet, "/api/admin/notices", s.adminNotices},
		{http.MethodPost, "/api/admin/notices", s.adminNotices},
		{http.MethodGet, "/api/admin/ads", s.adminAds},
		{http.MethodPost, "/api/admin/ads", s.adminAds},
		{http.MethodDelete, "/api/admin/ads/:id", s.adminDeleteAd},
		{http.MethodGet, "/api/admin/customer-services", s.adminServices},
		{http.MethodPost, "/api/admin/customer-services", s.adminServices},
		{http.MethodGet, "/api/admin/tickets", s.adminTickets},
		{http.MethodPost, "/api/admin/tickets/:id/reply", s.adminReplyTicket},
		{http.MethodGet, "/api/admin/payment/fourth", s.adminFourthPay},
		{http.MethodPost, "/api/admin/payment/fourth", s.adminFourthPay},
		{http.MethodGet, "/api/admin/payment/epay", s.adminEpay},
		{http.MethodPost, "/api/admin/payment/epay", s.adminEpay},
		{http.MethodGet, "/api/admin/system/email-config", s.adminEmailConfig},
		{http.MethodPost, "/api/admin/system/email-config", s.adminEmailConfig},
		{http.MethodGet, "/api/admin/system/logs", s.adminSystemLogs},
		{http.MethodGet, "/api/admin/staff", s.adminStaff},
		{http.MethodPost, "/api/admin/staff", s.adminCreateStaff},
		{http.MethodPost, "/api/admin/staff/:id/role", s.adminStaffRole},
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
