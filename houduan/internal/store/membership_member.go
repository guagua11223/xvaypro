package store

import (
	"database/sql"
	"fmt"
	"strings"

	"xvay/houduan/internal/errs"
)

type Member struct {
	ID                int64
	Email             string
	Username          string
	Avatar            string
	Phone             string
	BindEmail         string
	EmailStatus       int
	EmailVerifiedAt   int64
	EmailBindAt       int64
	IsDistributor     int
	IsAgent           int
	CommissionMode    int
	WalletEnabled     int
	CanAuthorizeAgent int
	ParentID          int64
	DistributorID     int64
	Path              string
	MemberStatus      int
	BannedAt          int64
	BanReason         string
	InviteCode        string
	Status            string
	CreatedAt         int64
	Upload            int64
	Download          int64
	Total             int64
	ExpireAt          int64
}

const memberCols = `id, email, username, avatar, phone, bind_email, email_status, email_verified_at, email_bind_at,
	is_distributor, is_agent, commission_mode, wallet_enabled, can_authorize_agent,
	parent_id, distributor_id, relation_path, member_status, banned_at, ban_reason, invite_code,
	status, created_at, upload, download, total, expire_at`

func scanMember(row interface{ Scan(...any) error }) (Member, error) {
	var m Member
	err := row.Scan(
		&m.ID, &m.Email, &m.Username, &m.Avatar, &m.Phone, &m.BindEmail, &m.EmailStatus, &m.EmailVerifiedAt, &m.EmailBindAt,
		&m.IsDistributor, &m.IsAgent, &m.CommissionMode, &m.WalletEnabled, &m.CanAuthorizeAgent,
		&m.ParentID, &m.DistributorID, &m.Path, &m.MemberStatus, &m.BannedAt, &m.BanReason, &m.InviteCode,
		&m.Status, &m.CreatedAt, &m.Upload, &m.Download, &m.Total, &m.ExpireAt,
	)
	return m, err
}

func (s *Store) LoadMember(id int64) (Member, bool, error) {
	m, err := scanMember(s.db.QueryRow(`SELECT `+memberCols+` FROM users WHERE id = ?`, id))
	if err == sql.ErrNoRows {
		return Member{}, false, nil
	}
	if err != nil {
		return Member{}, false, err
	}
	return m, true, nil
}

func (s *Store) FindLogin(account string) (Member, bool, error) {
	m, err := scanMember(s.db.QueryRow(`SELECT `+memberCols+` FROM users WHERE username = ?`, account))
	if err == sql.ErrNoRows {
		m, err = scanMember(s.db.QueryRow(`SELECT `+memberCols+` FROM users WHERE email = ?`, account))
	}
	if err == sql.ErrNoRows {
		return Member{}, false, nil
	}
	if err != nil {
		return Member{}, false, err
	}
	return m, true, nil
}

func (s *Store) FindByInvite(code string) (Member, bool, error) {
	code = strings.TrimSpace(code)
	if code == "" {
		return Member{}, false, nil
	}
	m, err := scanMember(s.db.QueryRow(
		`SELECT `+memberCols+` FROM users WHERE invite_code = ? OR lower(invite_code) = lower(?) LIMIT 1`,
		code, code,
	))
	if err == sql.ErrNoRows {
		return Member{}, false, nil
	}
	if err != nil {
		return Member{}, false, err
	}
	return m, true, nil
}

// ListInvitees returns accounts that registered under this member's invite code.
func (s *Store) ListInvitees(parentID int64, limit int) ([]Member, error) {
	if limit <= 0 || limit > 200 {
		limit = 50
	}
	rows, err := s.db.Query(
		`SELECT `+memberCols+` FROM users WHERE parent_id = ? OR referrer_id = ? ORDER BY id DESC LIMIT ?`,
		parentID, parentID, limit,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	list := []Member{}
	for rows.Next() {
		m, err := scanMember(rows)
		if err != nil {
			return nil, err
		}
		list = append(list, m)
	}
	return list, rows.Err()
}

func (s *Store) UsernameTaken(username string, except int64) (bool, error) {
	var n int
	err := s.db.QueryRow(`SELECT COUNT(*) FROM users WHERE username = ? AND id <> ?`, username, except).Scan(&n)
	return n > 0, err
}

// InitMember attaches referral, wallet and invite code after the VPN user row exists.
func (s *Store) InitMember(id int64, username, invite string) error {
	username = strings.TrimSpace(username)
	invite = strings.TrimSpace(invite)
	var parent Member
	if invite != "" {
		found, ok, err := s.FindByInvite(invite)
		if err != nil {
			return err
		}
		if !ok || found.MemberStatus == 1 {
			return errs.New(400, "VALIDATION", "邀请码不正确")
		}
		parent = found
	}
	return s.linkMember(id, username, parent.ID)
}

func (s *Store) linkMember(id int64, username string, parentID int64) error {
	return s.tx(func(tx *sql.Tx) error {
		return linkMemberTx(tx, id, username, parentID)
	})
}

func linkMemberTx(tx *sql.Tx, id int64, username string, parentID int64) error {
	if parentID == id {
		return errs.New(400, "VALIDATION", "不能把自己设为上级")
	}
	var parent Member
	if parentID > 0 {
		found, err := scanMember(tx.QueryRow(`SELECT `+memberCols+` FROM users WHERE id = ?`, parentID))
		if err == sql.ErrNoRows {
			return errs.New(400, "VALIDATION", "上级不存在")
		}
		if err != nil {
			return err
		}
		parent = found
		if strings.Contains(parent.Path, fmt.Sprintf("/%d/", id)) {
			return errs.New(400, "VALIDATION", "不能把下级设为上级")
		}
	}
	distributorID := int64(0)
	wallet := 1
	mode := 0
	if parent.ID > 0 {
		if parent.IsDistributor == 1 {
			distributorID = parent.ID
			wallet = 0
			mode = 1
		} else if parent.DistributorID > 0 {
			distributorID = parent.DistributorID
			wallet = 0
			mode = 1
		}
	}
	var self Member
	self, err := scanMember(tx.QueryRow(`SELECT `+memberCols+` FROM users WHERE id = ?`, id))
	if err != nil {
		return err
	}
	if self.IsDistributor == 1 || self.IsAgent == 1 {
		wallet = 1
	}
	code := self.InviteCode
	if code == "" {
		code, err = uniqueInviteTx(tx)
		if err != nil {
			return err
		}
	}
	if username == "" {
		username = self.Username
	}
	path := fmt.Sprintf("/%d/", id)
	if parent.ID > 0 && parent.Path != "" {
		path = parent.Path + fmt.Sprintf("%d/", id)
	} else if parent.ID > 0 {
		path = fmt.Sprintf("/%d/%d/", parent.ID, id)
	}
	level1, level2, level3 := parent.ID, parent.ParentID, int64(0)
	if parent.ParentID > 0 {
		_ = tx.QueryRow(`SELECT parent_id FROM users WHERE id = ?`, parent.ParentID).Scan(&level3)
	}
	if _, err = tx.Exec(`UPDATE users SET username = ?, parent_id = ?, referrer_id = ?, distributor_id = ?, relation_path = ?,
		wallet_enabled = ?, commission_mode = ?, invite_code = ? WHERE id = ?`,
		username, parentID, parentID, distributorID, path, wallet, mode, code, id); err != nil {
		return err
	}
	_, err = tx.Exec(`INSERT INTO user_relations (user_id, parent_id, level1_id, level2_id, level3_id, path)
		VALUES (?, ?, ?, ?, ?, ?)
		ON CONFLICT(user_id) DO UPDATE SET
			parent_id = excluded.parent_id, level1_id = excluded.level1_id,
			level2_id = excluded.level2_id, level3_id = excluded.level3_id, path = excluded.path`,
		id, parentID, level1, level2, level3, path)
	if err != nil {
		return err
	}
	if wallet == 1 {
		_, err = tx.Exec(`INSERT INTO wallets (user_id, balance, frozen, total_income, total_withdraw, negative_balance, version)
			VALUES (?, 0, 0, 0, 0, 0, 0) ON CONFLICT(user_id) DO NOTHING`, id)
	}
	return err
}

func uniqueInviteTx(tx *sql.Tx) (string, error) {
	for range 8 {
		code, err := randomAlphabet(8)
		if err != nil {
			return "", err
		}
		var n int
		if err := tx.QueryRow(`SELECT COUNT(*) FROM users WHERE invite_code = ?`, code).Scan(&n); err != nil {
			return "", err
		}
		if n == 0 {
			return code, nil
		}
	}
	return "", errs.New(500, "INTERNAL", "邀请码生成失败")
}

func (s *Store) ListMembers(keyword string, limit int) ([]Member, error) {
	if limit <= 0 || limit > 500 {
		limit = 200
	}
	query := `SELECT ` + memberCols + ` FROM users`
	var args []any
	if keyword != "" {
		query += ` WHERE username LIKE ? OR bind_email LIKE ? OR phone LIKE ? OR email LIKE ?`
		like := "%" + keyword + "%"
		args = append(args, like, like, like, like)
	}
	query += ` ORDER BY id DESC LIMIT ?`
	args = append(args, limit)
	rows, err := s.db.Query(query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var list []Member
	for rows.Next() {
		m, err := scanMember(rows)
		if err != nil {
			return nil, err
		}
		list = append(list, m)
	}
	if list == nil {
		list = []Member{}
	}
	return list, rows.Err()
}

func (s *Store) MembersOfDistributor(distributorID int64) ([]Member, error) {
	rows, err := s.db.Query(`SELECT `+memberCols+` FROM users WHERE distributor_id = ? ORDER BY id DESC`, distributorID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var list []Member
	for rows.Next() {
		m, err := scanMember(rows)
		if err != nil {
			return nil, err
		}
		list = append(list, m)
	}
	if list == nil {
		list = []Member{}
	}
	return list, rows.Err()
}

func (s *Store) OpenDistributor(id int64, rate float64, now int64) error {
	if rate < 0 {
		return errs.New(400, "VALIDATION", "分佣比例不能为负")
	}
	capRate, err := s.ConfigFloat("rate_cap", 100)
	if err != nil {
		return err
	}
	if rate > capRate {
		return errs.New(400, "VALIDATION", "分佣比例超过上限")
	}
	return s.tx(func(tx *sql.Tx) error {
		m, err := scanMember(tx.QueryRow(`SELECT `+memberCols+` FROM users WHERE id = ?`, id))
		if err == sql.ErrNoRows {
			return errs.New(404, "NOT_FOUND", "会员不存在")
		}
		if err != nil {
			return err
		}
		parentDist := int64(0)
		if m.IsDistributor == 0 {
			parentDist = m.DistributorID
		}
		if _, err := tx.Exec(`UPDATE users SET is_distributor = 1, wallet_enabled = 1, can_authorize_agent = 1,
			commission_mode = 1, is_agent = 0 WHERE id = ?`, id); err != nil {
			return err
		}
		_, err = tx.Exec(`INSERT INTO distributors (user_id, parent_distributor_id, commission_rate, can_authorize_agent, total_members, total_commission, status, created_at)
			VALUES (?, ?, ?, 1, 0, 0, 0, ?)
			ON CONFLICT(user_id) DO UPDATE SET commission_rate = excluded.commission_rate, status = 0, can_authorize_agent = 1`,
			id, parentDist, rate, now)
		if err != nil {
			return err
		}
		_, err = tx.Exec(`INSERT INTO wallets (user_id, balance, frozen, total_income, total_withdraw, negative_balance, version)
			VALUES (?, 0, 0, 0, 0, 0, 0) ON CONFLICT(user_id) DO NOTHING`, id)
		return err
	})
}

func (s *Store) CancelDistributor(id int64) error {
	return s.tx(func(tx *sql.Tx) error {
		res, err := tx.Exec(`UPDATE users SET is_distributor = 0, can_authorize_agent = 0, commission_mode = 0 WHERE id = ? AND is_distributor = 1`, id)
		if err != nil {
			return err
		}
		n, _ := res.RowsAffected()
		if n == 0 {
			return errs.New(404, "NOT_FOUND", "经销商不存在")
		}
		if _, err := tx.Exec(`UPDATE distributors SET status = 1, can_authorize_agent = 0 WHERE user_id = ?`, id); err != nil {
			return err
		}
		if _, err := tx.Exec(`UPDATE users SET distributor_id = 0, wallet_enabled = 1, commission_mode = 0
			WHERE distributor_id = ? AND is_agent = 0 AND is_distributor = 0`, id); err != nil {
			return err
		}
		_, err = tx.Exec(`UPDATE users SET distributor_id = 0 WHERE distributor_id = ?`, id)
		return err
	})
}

func (s *Store) SetDistributorRate(id int64, rate float64) error {
	capRate, err := s.ConfigFloat("rate_cap", 100)
	if err != nil {
		return err
	}
	if rate < 0 || rate > capRate {
		return errs.New(400, "VALIDATION", "分佣比例超过上限")
	}
	var highest float64
	if err := s.db.QueryRow(`SELECT COALESCE(MAX(rate), 0) FROM commission_rates WHERE distributor_id = ?`, id).Scan(&highest); err != nil {
		return err
	}
	if highest > rate {
		return errs.New(400, "VALIDATION", "已有会员比例高于该比例，请先调低会员比例")
	}
	res, err := s.db.Exec(`UPDATE distributors SET commission_rate = ? WHERE user_id = ? AND status = 0`, rate, id)
	if err != nil {
		return err
	}
	n, _ := res.RowsAffected()
	if n == 0 {
		return errs.New(404, "NOT_FOUND", "经销商不存在")
	}
	return nil
}

func (s *Store) SetCustomRate(distributorID, memberID int64, rate float64, actor int64, now int64) error {
	if rate < 0 {
		return errs.New(400, "VALIDATION", "返佣比例不能为负")
	}
	own, status, err := s.DistributorRate(distributorID)
	if err != nil {
		return err
	}
	if status != 0 {
		return errs.New(404, "NOT_FOUND", "经销商不存在")
	}
	if rate > own {
		return errs.New(400, "VALIDATION", "会员返佣比例不能超过经销商分佣比例")
	}
	m, ok, err := s.LoadMember(memberID)
	if err != nil {
		return err
	}
	if !ok || m.DistributorID != distributorID {
		return errs.New(403, "FORBIDDEN", "只能给自己旗下会员设置比例")
	}
	_, err = s.db.Exec(`INSERT INTO commission_rates (distributor_id, member_id, rate, rate_type, max_rate, created_by, created_at)
		VALUES (?, ?, ?, 'custom', ?, ?, ?)
		ON CONFLICT(distributor_id, member_id) DO UPDATE SET rate = excluded.rate, max_rate = excluded.max_rate, created_by = excluded.created_by`,
		distributorID, memberID, rate, own, actor, now)
	if err != nil {
		return err
	}
	_, err = s.db.Exec(`UPDATE users SET member_rate = ? WHERE id = ?`, int(rate), memberID)
	return err
}

func (s *Store) AuthorizeAgent(actorID, memberID int64, actorIsAdmin bool) error {
	return s.tx(func(tx *sql.Tx) error {
		member, err := scanMember(tx.QueryRow(`SELECT `+memberCols+` FROM users WHERE id = ?`, memberID))
		if err == sql.ErrNoRows {
			return errs.New(404, "NOT_FOUND", "会员不存在")
		}
		if err != nil {
			return err
		}
		if !actorIsAdmin {
			actor, err := scanMember(tx.QueryRow(`SELECT `+memberCols+` FROM users WHERE id = ?`, actorID))
			if err != nil {
				return err
			}
			if actor.CanAuthorizeAgent != 1 || actor.IsDistributor != 1 {
				return errs.New(403, "FORBIDDEN", "代理不能再发展代理")
			}
			if member.DistributorID != actorID {
				return errs.New(403, "FORBIDDEN", "只能授权自己旗下的会员")
			}
		}
		if member.IsDistributor == 1 {
			return errs.New(400, "VALIDATION", "经销商不需要再授权为代理")
		}
		_, err = tx.Exec(`UPDATE users SET is_agent = 1, wallet_enabled = 1, can_authorize_agent = 0 WHERE id = ?`, memberID)
		if err != nil {
			return err
		}
		_, err = tx.Exec(`INSERT INTO wallets (user_id, balance, frozen, total_income, total_withdraw, negative_balance, version)
			VALUES (?, 0, 0, 0, 0, 0, 0) ON CONFLICT(user_id) DO NOTHING`, memberID)
		return err
	})
}

func (s *Store) SetWallet(id int64, enabled int) error {
	_, err := s.db.Exec(`UPDATE users SET wallet_enabled = ? WHERE id = ?`, enabled, id)
	if err != nil {
		return err
	}
	if enabled == 1 {
		_, err = s.db.Exec(`INSERT INTO wallets (user_id, balance, frozen, total_income, total_withdraw, negative_balance, version)
			VALUES (?, 0, 0, 0, 0, 0, 0) ON CONFLICT(user_id) DO NOTHING`, id)
	}
	return err
}

func (s *Store) BanMember(id int64, reason string, now int64) error {
	return s.tx(func(tx *sql.Tx) error {
		res, err := tx.Exec(`UPDATE users SET status = 'disabled', member_status = 1, banned_at = ?, ban_reason = ? WHERE id = ?`, now, reason, id)
		if err != nil {
			return err
		}
		n, _ := res.RowsAffected()
		if n == 0 {
			return errs.New(404, "NOT_FOUND", "会员不存在")
		}
		_, err = tx.Exec(`UPDATE orders SET service_status = 2 WHERE user_id = ? AND pay_status = 1 AND service_status = 1`, id)
		return err
	})
}

func (s *Store) UnbanMember(id, now int64) error {
	return s.tx(func(tx *sql.Tx) error {
		res, err := tx.Exec(`UPDATE users SET status = 'active', member_status = 0, banned_at = 0, ban_reason = '' WHERE id = ?`, id)
		if err != nil {
			return err
		}
		n, _ := res.RowsAffected()
		if n == 0 {
			return errs.New(404, "NOT_FOUND", "会员不存在")
		}
		_, err = tx.Exec(`UPDATE orders SET service_status = CASE WHEN node_end_at > ? THEN 1 ELSE 3 END
			WHERE user_id = ? AND service_status = 2`, now, id)
		return err
	})
}

func (s *Store) UnbindEmail(id int64) error {
	res, err := s.db.Exec(`UPDATE users SET bind_email = '', email_status = 0, email_verified_at = 0, email_bind_at = 0 WHERE id = ?`, id)
	if err != nil {
		return err
	}
	n, _ := res.RowsAffected()
	if n == 0 {
		return errs.New(404, "NOT_FOUND", "会员不存在")
	}
	return nil
}

func (s *Store) SetParent(id, parentID int64) error {
	var username string
	if err := s.db.QueryRow(`SELECT username FROM users WHERE id = ?`, id).Scan(&username); err != nil {
		if err == sql.ErrNoRows {
			return errs.New(404, "NOT_FOUND", "会员不存在")
		}
		return err
	}
	if err := s.linkMember(id, username, parentID); err != nil {
		return err
	}
	rows, err := s.db.Query(`SELECT id FROM users WHERE parent_id = ?`, id)
	if err != nil {
		return err
	}
	defer rows.Close()
	var children []int64
	for rows.Next() {
		var child int64
		if err := rows.Scan(&child); err != nil {
			return err
		}
		children = append(children, child)
	}
	if err := rows.Err(); err != nil {
		return err
	}
	for _, child := range children {
		if err := s.SetParent(child, id); err != nil {
			return err
		}
	}
	return nil
}
