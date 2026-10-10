package store

import (
	"database/sql"
	"strconv"
	"strings"
	"time"

	"xvay/houduan/internal/errs"
)

func parseFloat(raw string, fallback float64) float64 {
	n, err := strconv.ParseFloat(strings.TrimSpace(raw), 64)
	if err != nil {
		return fallback
	}
	return n
}

func (s *Store) ConfigString(key string) (string, error) {
	var value string
	err := s.db.QueryRow(`SELECT value FROM system_configs WHERE key = ?`, key).Scan(&value)
	if err == sql.ErrNoRows {
		return "", nil
	}
	return value, err
}

func (s *Store) ConfigFloat(key string, fallback float64) (float64, error) {
	raw, err := s.ConfigString(key)
	if err != nil || raw == "" {
		return fallback, err
	}
	return parseFloat(raw, fallback), nil
}

func (s *Store) ConfigMap(keys []string) (map[string]string, error) {
	out := map[string]string{}
	if len(keys) == 0 {
		rows, err := s.db.Query(`SELECT key, value FROM system_configs ORDER BY key`)
		if err != nil {
			return nil, err
		}
		defer rows.Close()
		for rows.Next() {
			var k, v string
			if err := rows.Scan(&k, &v); err != nil {
				return nil, err
			}
			out[k] = v
		}
		return out, rows.Err()
	}
	for _, key := range keys {
		value, err := s.ConfigString(key)
		if err != nil {
			return nil, err
		}
		out[key] = value
	}
	return out, nil
}

func (s *Store) PutConfigs(values map[string]string) error {
	return s.tx(func(tx *sql.Tx) error {
		for key, value := range values {
			if _, err := tx.Exec(`INSERT INTO system_configs (key, value) VALUES (?, ?)
				ON CONFLICT(key) DO UPDATE SET value = excluded.value`, key, value); err != nil {
				return err
			}
		}
		return nil
	})
}

func (s *Store) CommissionSettings() (map[string]any, error) {
	cfg, err := s.ConfigMap([]string{
		"modes_exclusive", "pool_rate", "level1_rate", "level2_rate", "level3_rate",
		"three_level_enabled", "commission_cap", "rate_cap", "distributor_default_rate", "settle_day",
	})
	if err != nil {
		return nil, err
	}
	plan := CommissionPlan{
		Pool: parseFloat(cfg["pool_rate"], 50), Level1: parseFloat(cfg["level1_rate"], 60),
		Level2: parseFloat(cfg["level2_rate"], 30), Level3: parseFloat(cfg["level3_rate"], 10),
		ThreeLevel: cfg["three_level_enabled"] != "0", Cap: parseFloat(cfg["commission_cap"], 0),
	}
	lines := SplitMemberCommission(100, []CommissionParty{{ID: 3}, {ID: 2}, {ID: 1}}, plan)
	example := map[string]any{"base": 100, "fee": 0, "pool": roundMoney(100 * plan.Pool / 100)}
	names := []string{"level1", "level2", "level3"}
	for i, line := range lines {
		if i < len(names) {
			example[names[i]] = line.Amount
		}
	}
	return map[string]any{
		"modesExclusive":  true,
		"poolRate":        plan.Pool,
		"level1Rate":      plan.Level1,
		"level2Rate":      plan.Level2,
		"level3Rate":      plan.Level3,
		"threeLevel":      plan.ThreeLevel,
		"commissionCap":   plan.Cap,
		"rateCap":         parseFloat(cfg["rate_cap"], 100),
		"distributorRate": parseFloat(cfg["distributor_default_rate"], 55),
		"settleDay":       parseFloat(cfg["settle_day"], 1),
		"example":         example,
	}, nil
}

func (s *Store) SaveCommissionSettings(pool, l1, l2, l3, cap, rateCap, distDefault, settleDay float64, three bool) error {
	l1, l2, l3 = 60, 30, 10
	if pool < 0 || pool > 100 {
		return errs.New(400, "VALIDATION", "分佣池比例须在 0 到 100 之间")
	}
	if settleDay < 1 || settleDay > 28 {
		return errs.New(400, "VALIDATION", "结算日请设在 1 到 28 日")
	}
	enabled := "1"
	if !three {
		enabled = "0"
	}
	return s.PutConfigs(map[string]string{
		"modes_exclusive":          "1",
		"pool_rate":                strconv.FormatFloat(pool, 'f', -1, 64),
		"level1_rate":              strconv.FormatFloat(l1, 'f', -1, 64),
		"level2_rate":              strconv.FormatFloat(l2, 'f', -1, 64),
		"level3_rate":              strconv.FormatFloat(l3, 'f', -1, 64),
		"three_level_enabled":      enabled,
		"commission_cap":           strconv.FormatFloat(cap, 'f', -1, 64),
		"rate_cap":                 strconv.FormatFloat(rateCap, 'f', -1, 64),
		"distributor_default_rate": strconv.FormatFloat(distDefault, 'f', -1, 64),
		"settle_day":               strconv.FormatFloat(settleDay, 'f', 0, 64),
	})
}

func (s *Store) SendEmailCode(email, scene, ip, device string, now int64) (string, error) {
	sceneOK := scene == "bind_email" || scene == "find_account" || scene == "reset_password"
	if !sceneOK {
		return "", errs.New(400, "VALIDATION", "验证码场景不正确")
	}
	var last int64
	err := s.db.QueryRow(`SELECT COALESCE(MAX(created_at), 0) FROM email_verification_codes WHERE email = ?`, email).Scan(&last)
	if err != nil {
		return "", err
	}
	if last > 0 && now-last < 60_000 {
		return "", errs.New(400, "VALIDATION", "60 秒内不能重复发送")
	}
	var hourCount int
	if err := s.db.QueryRow(`SELECT COUNT(*) FROM email_verification_codes WHERE email = ? AND created_at > ?`, email, now-3600_000).Scan(&hourCount); err != nil {
		return "", err
	}
	if hourCount >= 10 {
		return "", errs.New(400, "VALIDATION", "每小时最多发送 10 次")
	}
	code, err := randomDigits(6)
	if err != nil {
		return "", err
	}
	_, err = s.db.Exec(`INSERT INTO email_verification_codes (email, code, scene, expires_at, used_at, ip, device, created_at)
		VALUES (?, ?, ?, ?, 0, ?, ?, ?)`, email, code, scene, now+5*60_000, ip, device, now)
	return code, err
}

func (s *Store) UseEmailCode(email, scene, code string, now int64) error {
	var id, expires, used int64
	err := s.db.QueryRow(`SELECT id, expires_at, used_at FROM email_verification_codes
		WHERE email = ? AND scene = ? AND code = ? ORDER BY id DESC LIMIT 1`, email, scene, code).Scan(&id, &expires, &used)
	if err == sql.ErrNoRows {
		return errs.New(400, "VALIDATION", "验证码不正确")
	}
	if err != nil {
		return err
	}
	if used > 0 || expires < now {
		return errs.New(400, "VALIDATION", "验证码已失效")
	}
	_, err = s.db.Exec(`UPDATE email_verification_codes SET used_at = ? WHERE id = ?`, now, id)
	return err
}

func (s *Store) LatestEmailCode(email, scene string) (string, error) {
	var code string
	err := s.db.QueryRow(`SELECT code FROM email_verification_codes WHERE email = ? AND scene = ? ORDER BY id DESC LIMIT 1`, email, scene).Scan(&code)
	if err == sql.ErrNoRows {
		return "", nil
	}
	return code, err
}

func (s *Store) BindEmail(userID int64, email string, now int64) error {
	var owner int64
	err := s.db.QueryRow(`SELECT id FROM users WHERE bind_email = ? AND id <> ?`, email, userID).Scan(&owner)
	if err == nil {
		return errs.New(400, "VALIDATION", "该邮箱已绑定其他账号")
	}
	if err != sql.ErrNoRows {
		return err
	}
	res, err := s.db.Exec(`UPDATE users SET bind_email = ?, email_status = 2, email_verified_at = ?, email_bind_at = ? WHERE id = ?`,
		email, now, now, userID)
	if err != nil {
		return err
	}
	n, _ := res.RowsAffected()
	if n == 0 {
		return errs.New(404, "NOT_FOUND", "会员不存在")
	}
	return nil
}

func (s *Store) FindByBindEmail(email string) (Member, bool, error) {
	m, err := scanMember(s.db.QueryRow(`SELECT `+memberCols+` FROM users WHERE bind_email = ? AND email_status = 2`, email))
	if err == sql.ErrNoRows {
		return Member{}, false, nil
	}
	if err != nil {
		return Member{}, false, err
	}
	return m, true, nil
}

func (s *Store) AddLog(actorType string, actorID int64, action, detail, ip string) error {
	_, err := s.db.Exec(`INSERT INTO operation_logs (actor_type, actor_id, action, detail, ip, created_at) VALUES (?, ?, ?, ?, ?, ?)`,
		actorType, actorID, action, detail, ip, time.Now().UnixMilli())
	return err
}

func (s *Store) AddLoginLog(actorType, account string, success bool, ip, device string) error {
	_, err := s.db.Exec(`INSERT INTO login_logs (actor_type, account, success, ip, device, created_at) VALUES (?, ?, ?, ?, ?, ?)`,
		actorType, account, bit(success), ip, device, time.Now().UnixMilli())
	return err
}

func (s *Store) ListLogs(kind string, limit int) ([]map[string]any, error) {
	if limit <= 0 || limit > 200 {
		limit = 50
	}
	query := `SELECT id, actor_type, actor_id, action, detail, ip, created_at FROM operation_logs ORDER BY id DESC LIMIT ?`
	if kind == "login" {
		query = `SELECT id, actor_type, 0, account, '', ip, created_at FROM login_logs ORDER BY id DESC LIMIT ?`
	}
	rows, err := s.db.Query(query, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var list []map[string]any
	for rows.Next() {
		var id, actorID, created int64
		var actor, action, detail, ip string
		if err := rows.Scan(&id, &actor, &actorID, &action, &detail, &ip, &created); err != nil {
			return nil, err
		}
		list = append(list, map[string]any{
			"id": id, "actorType": actor, "actorId": actorID, "action": action, "detail": detail, "ip": ip, "createdAt": created,
		})
	}
	if list == nil {
		list = []map[string]any{}
	}
	return list, rows.Err()
}

const withdrawStatusSQL = `(CASE
		WHEN status IN ('2', 'paid') THEN 2
		WHEN status IN ('1', 'approved', 'success') THEN 1
		WHEN status IN ('3', 'rejected') THEN 3
		WHEN status IN ('4', 'cancelled', 'canceled') THEN 4
		WHEN status IN ('0', 'pending', '') THEN 0
		ELSE CAST(status AS INTEGER)
	END)`

func (s *Store) MemberStats(now time.Time) (map[string]any, error) {
	start := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, now.Location()).UnixMilli()
	out := map[string]any{}
	queries := []struct {
		key, sql string
		args     []any
	}{
		{"members", `SELECT COUNT(*) FROM users`, nil},
		{"todayMembers", `SELECT COUNT(*) FROM users WHERE created_at >= ?`, []any{start}},
		{"todayOrderAmount", `SELECT COALESCE(SUM(amount), 0) FROM orders WHERE pay_status = 1 AND pay_time >= ?`, []any{start}},
		{"orderAmount", `SELECT COALESCE(SUM(amount), 0) FROM orders WHERE pay_status = 1`, nil},
		{"orderCount", `SELECT COUNT(*) FROM orders`, nil},
		{"todayOrderCount", `SELECT COUNT(*) FROM orders WHERE pay_status = 1 AND pay_time >= ?`, []any{start}},
		{"todayWithdraw", `SELECT COALESCE(SUM(amount), 0) FROM withdrawals WHERE ` + withdrawStatusSQL + ` = 2 AND pay_time >= ?`, []any{start}},
		{"pendingWithdraw", `SELECT COUNT(*) FROM withdrawals WHERE ` + withdrawStatusSQL + ` = 0`, nil},
		{"todayCommission", `SELECT COALESCE(SUM(amount), 0) FROM commissions WHERE status <> 2 AND created_at >= ?`, []any{start}},
		{"commissionTotal", `SELECT COALESCE(SUM(amount), 0) FROM commissions WHERE status <> 2`, nil},
		{"pendingCommission", `SELECT COALESCE(SUM(amount), 0) FROM commissions WHERE status = 0`, nil},
		{"settledCommission", `SELECT COALESCE(SUM(amount), 0) FROM commissions WHERE status = 1`, nil},
		{"walletBalance", `SELECT COALESCE(SUM(balance), 0) FROM wallets`, nil},
		{"walletFrozen", `SELECT COALESCE(SUM(frozen), 0) FROM wallets`, nil},
		{"negativeBalance", `SELECT COALESCE(SUM(negative_balance), 0) FROM wallets`, nil},
		{"todayDistributors", `SELECT COUNT(*) FROM distributors WHERE status = 0 AND created_at >= ?`, []any{start}},
	}
	for _, q := range queries {
		var n float64
		if err := s.db.QueryRow(q.sql, q.args...).Scan(&n); err != nil {
			return nil, err
		}
		out[q.key] = n
	}
	return out, nil
}

func (s *Store) MemberRate(distributorID, memberID int64) (float64, bool, error) {
	var rate float64
	err := s.db.QueryRow(`SELECT rate FROM commission_rates WHERE distributor_id = ? AND member_id = ?`, distributorID, memberID).Scan(&rate)
	if err == sql.ErrNoRows {
		return 0, false, nil
	}
	return rate, err == nil, err
}

func (s *Store) DistributorRate(userID int64) (float64, int, error) {
	var rate float64
	var status int
	err := s.db.QueryRow(`SELECT commission_rate, status FROM distributors WHERE user_id = ?`, userID).Scan(&rate, &status)
	if err == sql.ErrNoRows {
		var flag, userRate int
		err = s.db.QueryRow(`SELECT is_distributor, distributor_rate FROM users WHERE id = ?`, userID).Scan(&flag, &userRate)
		if err != nil {
			return 0, 1, err
		}
		if flag == 1 {
			return float64(userRate), 0, nil
		}
		return 0, 1, nil
	}
	return rate, status, err
}

func (s *Store) CountDownline(distributorID int64) (direct, indirect int, err error) {
	if err = s.db.QueryRow(`SELECT COUNT(*) FROM users WHERE parent_id = ?`, distributorID).Scan(&direct); err != nil {
		return
	}
	err = s.db.QueryRow(`SELECT COUNT(*) FROM users WHERE distributor_id = ? AND parent_id <> ?`, distributorID, distributorID).Scan(&indirect)
	return
}
