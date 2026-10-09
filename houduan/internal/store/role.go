package store

import (
	"crypto/rand"
	"encoding/hex"

	"xvay/houduan/internal/errs"
)

func (s *Store) finishNewUser(user User) (User, error) {
	code, err := s.uniqueInviteCode()
	if err != nil {
		return User{}, err
	}
	emailStatus := 0
	if user.Email != "" {
		emailStatus = 2
	}
	if _, err := s.db.Exec(
		`UPDATE users SET invite_code = ?, email_status = ?, wallet_enabled = 1, member_rate = -1 WHERE id = ?`,
		code, emailStatus, user.ID,
	); err != nil {
		return User{}, err
	}
	found, _, err := s.FindUserByID(user.ID)
	return found, err
}

func (s *Store) uniqueInviteCode() (string, error) {
	for i := 0; i < 8; i++ {
		buf := make([]byte, 4)
		if _, err := rand.Read(buf); err != nil {
			return "", err
		}
		code := hex.EncodeToString(buf)
		var n int
		if err := s.db.QueryRow(`SELECT COUNT(*) FROM users WHERE invite_code = ?`, code).Scan(&n); err != nil {
			return "", err
		}
		if n == 0 {
			return code, nil
		}
	}
	return "", errs.New(500, "INTERNAL", "邀请码生成失败")
}

func (s *Store) FindUserByInvite(code string) (User, bool, error) {
	if code == "" {
		return User{}, false, nil
	}
	user, err := scanUser(s.db.QueryRow(`SELECT `+userCols+` FROM users WHERE invite_code = ?`, code))
	return optionalUser(user, err)
}

func (s *Store) BindReferrer(userID, referrerID int64) (User, error) {
	if userID == referrerID {
		return User{}, errs.New(400, "VALIDATION", "不能绑定自己为推荐人")
	}
	user, ok, err := s.FindUserByID(userID)
	if err != nil {
		return User{}, err
	}
	if !ok {
		return User{}, errs.New(404, "NOT_FOUND", "用户不存在")
	}
	referrer, ok, err := s.FindUserByID(referrerID)
	if err != nil {
		return User{}, err
	}
	if !ok {
		return User{}, errs.New(400, "VALIDATION", "邀请码不正确")
	}
	seen := map[int64]bool{userID: true}
	for id := referrer.ID; id > 0; {
		if seen[id] {
			return User{}, errs.New(400, "VALIDATION", "推荐关系不能成环")
		}
		seen[id] = true
		next, ok, err := s.FindUserByID(id)
		if err != nil {
			return User{}, err
		}
		if !ok {
			break
		}
		id = next.ReferrerID
	}
	user.ReferrerID = referrer.ID
	if referrer.IsDistributor == 1 {
		user.DistributorID = referrer.ID
	} else {
		user.DistributorID = referrer.DistributorID
	}
	return s.saveAccess(user)
}

func (s *Store) ApplyUserType(id int64, userType string) (User, error) {
	user, ok, err := s.FindUserByID(id)
	if err != nil {
		return User{}, err
	}
	if !ok {
		return User{}, errs.New(404, "NOT_FOUND", "用户不存在")
	}
	switch userType {
	case "dealer":
		user.IsDistributor = 1
		user.IsAgent = 0
		user.DistributorID = 0
		if user.DistributorRate <= 0 {
			user.DistributorRate = 50
		}
	case "agent":
		user.IsDistributor = 0
		user.IsAgent = 1
	default:
		user.IsDistributor = 0
		user.IsAgent = 0
		user.UserType = "member"
	}
	return s.saveAccess(user)
}

func (s *Store) SetDistributor(id int64, enabled bool, rate int) (User, error) {
	user, ok, err := s.FindUserByID(id)
	if err != nil {
		return User{}, err
	}
	if !ok {
		return User{}, errs.New(404, "NOT_FOUND", "用户不存在")
	}
	if enabled {
		if rate <= 0 {
			rate = 50
		}
		if rate > 100 {
			return User{}, errs.New(400, "VALIDATION", "经销商分佣比例不能超过 100")
		}
		user.IsDistributor = 1
		user.IsAgent = 0
		user.DistributorID = 0
		user.DistributorRate = rate
	} else {
		user.IsDistributor = 0
		user.DistributorRate = 0
	}
	return s.saveAccess(user)
}

func (s *Store) SetAgent(id int64, enabled bool) (User, error) {
	user, ok, err := s.FindUserByID(id)
	if err != nil {
		return User{}, err
	}
	if !ok {
		return User{}, errs.New(404, "NOT_FOUND", "用户不存在")
	}
	if user.IsDistributor == 1 {
		return User{}, errs.New(400, "VALIDATION", "经销商不能被设为代理")
	}
	if enabled {
		user.IsAgent = 1
	} else {
		user.IsAgent = 0
	}
	return s.saveAccess(user)
}

func (s *Store) SetMemberRate(memberID int64, rate int) (User, error) {
	user, ok, err := s.FindUserByID(memberID)
	if err != nil {
		return User{}, err
	}
	if !ok {
		return User{}, errs.New(404, "NOT_FOUND", "用户不存在")
	}
	if rate < -1 || rate > 100 {
		return User{}, errs.New(400, "VALIDATION", "返佣比例不正确")
	}
	if rate >= 0 {
		if user.DistributorID == 0 {
			return User{}, errs.New(400, "VALIDATION", "该会员没有归属经销商")
		}
		dist, ok, err := s.FindUserByID(user.DistributorID)
		if err != nil {
			return User{}, err
		}
		if !ok || rate > dist.DistributorRate {
			return User{}, errs.New(400, "VALIDATION", "会员返佣比例不能超过经销商分佣比例")
		}
	}
	user.MemberRate = rate
	return s.saveAccess(user)
}

func (s *Store) saveAccess(user User) (User, error) {
	user.CanAuthorizeAgent = 0
	if user.IsDistributor == 1 {
		user.CanAuthorizeAgent = 1
	}
	user.WalletEnabled = 0
	if user.IsDistributor == 1 || user.IsAgent == 1 || user.DistributorID == 0 {
		user.WalletEnabled = 1
	}
	user.CommissionMode = 0
	if user.IsDistributor == 1 || (user.DistributorID > 0 && user.MemberRate >= 0) {
		user.CommissionMode = 1
	}
	switch {
	case user.IsDistributor == 1:
		user.UserType = "dealer"
	case user.IsAgent == 1:
		user.UserType = "agent"
	default:
		user.UserType = "member"
	}
	if _, err := s.db.Exec(
		`UPDATE users SET
			referrer_id = ?, distributor_id = ?, is_distributor = ?, is_agent = ?,
			commission_mode = ?, wallet_enabled = ?, can_authorize_agent = ?,
			user_type = ?, distributor_rate = ?, member_rate = ?
		 WHERE id = ?`,
		user.ReferrerID, user.DistributorID, user.IsDistributor, user.IsAgent,
		user.CommissionMode, user.WalletEnabled, user.CanAuthorizeAgent,
		user.UserType, user.DistributorRate, user.MemberRate, user.ID,
	); err != nil {
		return User{}, err
	}
	found, _, err := s.FindUserByID(user.ID)
	return found, err
}

func (s *Store) ListDownline(distributorID int64) ([]User, error) {
	rows, err := s.db.Query(`SELECT `+userCols+` FROM users WHERE distributor_id = ? ORDER BY id ASC`, distributorID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	return collectUsers(rows)
}

func (s *Store) ListTeam(userID int64, limit int) ([]User, []int, error) {
	if limit <= 0 || limit > 500 {
		limit = 200
	}
	type item struct {
		id    int64
		level int
	}
	queue := []item{{userID, 0}}
	var users []User
	var levels []int
	seen := map[int64]bool{userID: true}
	for len(queue) > 0 && len(users) < limit {
		cur := queue[0]
		queue = queue[1:]
		rows, err := s.db.Query(`SELECT `+userCols+` FROM users WHERE referrer_id = ? ORDER BY id ASC`, cur.id)
		if err != nil {
			return nil, nil, err
		}
		children, err := collectUsers(rows)
		rows.Close()
		if err != nil {
			return nil, nil, err
		}
		for _, child := range children {
			if seen[child.ID] {
				continue
			}
			seen[child.ID] = true
			users = append(users, child)
			levels = append(levels, cur.level+1)
			if cur.level < 20 {
				queue = append(queue, item{child.ID, cur.level + 1})
			}
			if len(users) >= limit {
				break
			}
		}
	}
	if users == nil {
		users = []User{}
		levels = []int{}
	}
	return users, levels, nil
}

func collectUsers(rows interface {
	Next() bool
	Scan(...any) error
	Err() error
}) ([]User, error) {
	list := []User{}
	for rows.Next() {
		user, err := scanUser(rows)
		if err != nil {
			return nil, err
		}
		list = append(list, user)
	}
	return list, rows.Err()
}
