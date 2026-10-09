package api

import (
	"net/http"
	"time"

	"xvay/houduan/internal/store"
)

func (s *Server) distributorLogin(w http.ResponseWriter, r *http.Request) error {
	body, err := readJSON(r)
	if err != nil {
		return err
	}
	account := store.AsString(body["username"])
	password := store.AsString(body["password"])
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
		_ = s.db.AddLoginLog("distributor", account, false, clientIP(r), deviceOf(r))
		return unauthorized("账号或密码不正确")
	}
	if member.IsDistributor != 1 {
		return forbidden("只有经销商可以登录这个后台")
	}
	rate, status, err := s.db.DistributorRate(member.ID)
	if err != nil {
		return err
	}
	if status != 0 || member.MemberStatus == 1 {
		return forbidden("经销商已停用")
	}
	token, err := s.db.CreateSession(user, s.cfg.SessionTTLMs)
	if err != nil {
		return err
	}
	_ = s.db.AddLoginLog("distributor", account, true, clientIP(r), deviceOf(r))
	view := s.memberJSON(member, false)
	view["rate"] = rate
	writeOK(w, http.StatusOK, map[string]any{"token": token, "user": view})
	return nil
}

func (s *Server) requireDistributor(r *http.Request) (store.Member, error) {
	user, err := s.requireUser(r)
	if err != nil {
		return store.Member{}, err
	}
	member, ok, err := s.db.LoadMember(user.ID)
	if err != nil {
		return store.Member{}, err
	}
	if !ok || member.IsDistributor != 1 || member.MemberStatus == 1 {
		return store.Member{}, forbidden("经销商登录已失效")
	}
	_, status, err := s.db.DistributorRate(member.ID)
	if err != nil {
		return store.Member{}, err
	}
	if status != 0 {
		return store.Member{}, forbidden("经销商已停用")
	}
	return member, nil
}

func (s *Server) distributorDashboard(w http.ResponseWriter, r *http.Request) error {
	member, err := s.requireDistributor(r)
	if err != nil {
		return err
	}
	_, _ = s.db.SettleDue(time.Now())
	members, err := s.db.MembersOfDistributor(member.ID)
	if err != nil {
		return err
	}
	start := time.Now()
	day := time.Date(start.Year(), start.Month(), start.Day(), 0, 0, 0, 0, start.Location()).UnixMilli()
	todayMembers := 0
	for _, item := range members {
		if item.CreatedAt >= day {
			todayMembers++
		}
	}
	ids := make([]int64, 0, len(members))
	for _, item := range members {
		ids = append(ids, item.ID)
	}
	orders, err := s.db.ListOrdersForUsers(ids, 500)
	if err != nil {
		return err
	}
	var todayAmount float64
	for _, order := range orders {
		if order.PayStatus == 1 && order.PayTime >= day {
			todayAmount += order.Amount
		}
	}
	comms, err := s.db.ListCommissionRows(member.ID, 200)
	if err != nil {
		return err
	}
	var todayCommission float64
	for _, row := range comms {
		if row.Status != 2 && row.CreatedAt >= day {
			todayCommission += row.Amount
		}
	}
	wallet, err := s.db.Wallet(member.ID)
	if err != nil {
		return err
	}
	rate, _, _ := s.db.DistributorRate(member.ID)
	writeOK(w, http.StatusOK, map[string]any{
		"members": len(members), "todayMembers": todayMembers, "todayOrderAmount": storeRound(todayAmount),
		"todayCommission": storeRound(todayCommission), "totalCommission": wallet.TotalIncome,
		"balance": wallet.Balance, "frozen": wallet.Frozen, "rate": rate, "inviteCode": member.InviteCode,
	})
	return nil
}

func (s *Server) distributorMembers(w http.ResponseWriter, r *http.Request) error {
	member, err := s.requireDistributor(r)
	if err != nil {
		return err
	}
	list, err := s.db.MembersOfDistributor(member.ID)
	if err != nil {
		return err
	}
	out := make([]map[string]any, 0, len(list))
	for _, item := range list {
		out = append(out, s.memberJSON(item, false))
	}
	writeOK(w, http.StatusOK, map[string]any{"members": out, "rate": memberRateOf(s, member.ID)})
	return nil
}

func (s *Server) distributorSetRate(w http.ResponseWriter, r *http.Request) error {
	member, err := s.requireDistributor(r)
	if err != nil {
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
	if err := s.db.SetMemberRate(member.ID, id, store.AsFloat(body["rate"]), member.ID, time.Now().UnixMilli()); err != nil {
		return err
	}
	writeOK(w, http.StatusOK, map[string]any{"id": id, "rate": store.AsFloat(body["rate"])})
	return nil
}

func (s *Server) distributorSetAgent(w http.ResponseWriter, r *http.Request) error {
	member, err := s.requireDistributor(r)
	if err != nil {
		return err
	}
	id, err := idParam(r)
	if err != nil {
		return err
	}
	if err := s.db.AuthorizeAgent(member.ID, id, false); err != nil {
		return err
	}
	writeOK(w, http.StatusOK, map[string]any{"id": id, "isAgent": 1})
	return nil
}

func (s *Server) distributorOrders(w http.ResponseWriter, r *http.Request) error {
	member, err := s.requireDistributor(r)
	if err != nil {
		return err
	}
	list, err := s.db.MembersOfDistributor(member.ID)
	if err != nil {
		return err
	}
	ids := make([]int64, 0, len(list))
	for _, item := range list {
		ids = append(ids, item.ID)
	}
	orders, err := s.db.ListOrdersForUsers(ids, 300)
	if err != nil {
		return err
	}
	writeOK(w, http.StatusOK, map[string]any{"orders": orderListJSON(orders)})
	return nil
}

func (s *Server) distributorCommissions(w http.ResponseWriter, r *http.Request) error {
	member, err := s.requireDistributor(r)
	if err != nil {
		return err
	}
	rows, err := s.db.ListCommissionRows(member.ID, 200)
	if err != nil {
		return err
	}
	writeOK(w, http.StatusOK, map[string]any{"commissions": commissionJSON(rows)})
	return nil
}

func (s *Server) distributorWithdrawals(w http.ResponseWriter, r *http.Request) error {
	member, err := s.requireDistributor(r)
	if err != nil {
		return err
	}
	if r.Method == http.MethodPost {
		body, err := readJSON(r)
		if err != nil {
			return err
		}
		id, err := s.db.RequestWithdraw(member.ID, store.AsFloat(body["amount"]), time.Now().UnixMilli())
		if err != nil {
			return err
		}
		writeOK(w, http.StatusCreated, map[string]any{"id": id})
		return nil
	}
	list, err := s.db.ListWithdrawals(member.ID, 100)
	if err != nil {
		return err
	}
	wallet, err := s.db.Wallet(member.ID)
	if err != nil {
		return err
	}
	writeOK(w, http.StatusOK, map[string]any{"balance": wallet.Balance, "frozen": wallet.Frozen, "withdrawals": list})
	return nil
}

func (s *Server) distributorInvite(w http.ResponseWriter, r *http.Request) error {
	if _, err := s.requireDistributor(r); err != nil {
		return err
	}
	return s.userInvite(w, r)
}

func (s *Server) distributorNotices(w http.ResponseWriter, r *http.Request) error {
	if _, err := s.requireDistributor(r); err != nil {
		return err
	}
	list, err := s.db.ListNotices(true, time.Now().UnixMilli())
	if err != nil {
		return err
	}
	writeOK(w, http.StatusOK, map[string]any{"announcements": list})
	return nil
}

func (s *Server) distributorSupport(w http.ResponseWriter, r *http.Request) error {
	if _, err := s.requireDistributor(r); err != nil {
		return err
	}
	list, err := s.db.ListServices(true)
	if err != nil {
		return err
	}
	writeOK(w, http.StatusOK, map[string]any{"services": list})
	return nil
}

func (s *Server) distributorBanRequest(w http.ResponseWriter, r *http.Request) error {
	member, err := s.requireDistributor(r)
	if err != nil {
		return err
	}
	id, err := idParam(r)
	if err != nil {
		return err
	}
	target, ok, err := s.db.LoadMember(id)
	if err != nil {
		return err
	}
	if !ok || target.DistributorID != member.ID {
		return forbidden("只能申请处理自己旗下的会员")
	}
	body, err := readJSON(r)
	if err != nil {
		return err
	}
	reason := store.AsString(body["reason"])
	if reason == "" {
		reason = "申请平台处理"
	}
	ticket, err := s.db.CreateTicket(member.ID, "申请处理会员 "+target.Username, reason, time.Now().UnixMilli())
	if err != nil {
		return err
	}
	writeOK(w, http.StatusCreated, map[string]any{"ticketId": ticket})
	return nil
}

func memberRateOf(s *Server, id int64) float64 {
	rate, _, _ := s.db.DistributorRate(id)
	return rate
}
