package store

import (
	"database/sql"
	"strconv"
	"time"

	"xvay/houduan/internal/errs"
)

const (
	Level1Percent = 60
	Level2Percent = 30
	Level3Percent = 10
)

type Plan struct {
	Code         string
	Name         string
	Price        int64
	TrafficGB    int64
	DurationDays int64
	SortOrder    int64
	Enabled      bool
}

type Wallet struct {
	UserID    int64
	Earned    int64
	Balance   int64
	Frozen    int64
	UpdatedAt int64
}

type WalletEntry struct {
	ID           int64
	UserID       int64
	Kind         string
	Amount       int64
	BalanceAfter int64
	RefID        int64
	Detail       string
	CreatedAt    int64
}

type Commission struct {
	ID             int64
	OrderID        int64
	OrderNo        string
	BuyerID        int64
	BuyerName      string
	BeneficiaryID  int64
	Level          int
	Mode           int
	Rate           int
	BaseAmount     int64
	Amount         int64
	ReversedAmount int64
	Status         string
	CreatedAt      int64
	SettledAt      int64
}

type Withdrawal struct {
	ID         int64
	UserID     int64
	Amount     int64
	Fee        int64
	NetAmount  int64
	Account    string
	Status     string
	CreatedAt  int64
	ReviewedAt int64
}

type PlatformRequest struct {
	ID          int64
	RequesterID int64
	TargetID    int64
	Action      string
	Reason      string
	Status      string
	CreatedAt   int64
}

func SplitCommission(base, poolPercent int64) (total, l1, l2, l3 int64) {
	if poolPercent < 0 {
		poolPercent = 0
	}
	if poolPercent > 100 {
		poolPercent = 100
	}
	total = base * poolPercent / 100
	l1 = total * Level1Percent / 100
	l2 = total * Level2Percent / 100
	l3 = total * Level3Percent / 100
	l1 += total - l1 - l2 - l3
	return total, l1, l2, l3
}

func (s *Store) seedPlans() error {
	plans := []Plan{
		{Code: "week", Name: "1 周", Price: 1500, TrafficGB: 20, DurationDays: 7, SortOrder: 1, Enabled: true},
		{Code: "month", Name: "1 月", Price: 3000, TrafficGB: 100, DurationDays: 30, SortOrder: 2, Enabled: true},
		{Code: "quarter", Name: "1 季度", Price: 7800, TrafficGB: 300, DurationDays: 90, SortOrder: 3, Enabled: true},
		{Code: "year", Name: "1 年", Price: 25800, TrafficGB: 1500, DurationDays: 365, SortOrder: 4, Enabled: true},
	}
	for _, plan := range plans {
		if _, err := s.db.Exec(
			`INSERT OR IGNORE INTO service_plans (code, name, price, traffic_gb, duration_days, sort_order, enabled)
			 VALUES (?, ?, ?, ?, ?, ?, ?)`,
			plan.Code, plan.Name, plan.Price, plan.TrafficGB, plan.DurationDays, plan.SortOrder, bit(plan.Enabled),
		); err != nil {
			return err
		}
	}
	return nil
}

func (s *Store) ListPlans(enabledOnly bool) ([]Plan, error) {
	query := `SELECT code, name, price, traffic_gb, duration_days, sort_order, enabled FROM service_plans ORDER BY sort_order, code`
	if enabledOnly {
		query = `SELECT code, name, price, traffic_gb, duration_days, sort_order, enabled FROM service_plans WHERE enabled = 1 ORDER BY sort_order, code`
	}
	rows, err := s.db.Query(query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	list := []Plan{}
	for rows.Next() {
		plan, err := scanPlan(rows)
		if err != nil {
			return nil, err
		}
		list = append(list, plan)
	}
	return list, rows.Err()
}

func (s *Store) FindPlan(code string) (Plan, bool, error) {
	plan, err := scanPlan(s.db.QueryRow(
		`SELECT code, name, price, traffic_gb, duration_days, sort_order, enabled FROM service_plans WHERE code = ?`, code,
	))
	if err == sql.ErrNoRows {
		return Plan{}, false, nil
	}
	if err != nil {
		return Plan{}, false, err
	}
	return plan, true, nil
}

func (s *Store) UpdatePlan(plan Plan) (Plan, error) {
	res, err := s.db.Exec(
		`UPDATE service_plans SET name = ?, price = ?, traffic_gb = ?, duration_days = ?, enabled = ? WHERE code = ?`,
		plan.Name, plan.Price, plan.TrafficGB, plan.DurationDays, bit(plan.Enabled), plan.Code,
	)
	if err != nil {
		return Plan{}, err
	}
	n, err := res.RowsAffected()
	if err != nil {
		return Plan{}, err
	}
	if n == 0 {
		return Plan{}, errs.New(404, "NOT_FOUND", "套餐不存在")
	}
	found, _, err := s.FindPlan(plan.Code)
	return found, err
}

func (s *Store) SettingInt(key string, fallback int64) int64 {
	settings, err := s.GetSettings()
	if err != nil {
		return fallback
	}
	raw := settings[key]
	if raw == "" {
		return fallback
	}
	n, err := strconv.ParseInt(raw, 10, 64)
	if err != nil {
		return fallback
	}
	return n
}

func (s *Store) FindOrderByNo(orderNo string) (Order, bool, error) {
	order, err := scanOrder(s.db.QueryRow(`SELECT `+orderCols+` FROM orders WHERE order_no = ?`, orderNo))
	if err == sql.ErrNoRows {
		return Order{}, false, nil
	}
	if err != nil {
		return Order{}, false, err
	}
	return order, true, nil
}

func (s *Store) MarkOrderPaid(orderNo, tradeNo string, now int64) (Order, bool, error) {
	if now == 0 {
		now = time.Now().UnixMilli()
	}
	pool := s.SettingInt("commission_pool_percent", 50)
	var order Order
	already := false
	err := s.tx(func(tx *sql.Tx) error {
		current, err := scanOrder(tx.QueryRow(`SELECT `+orderCols+` FROM orders WHERE order_no = ?`, orderNo))
		if err == sql.ErrNoRows {
			return errs.New(404, "NOT_FOUND", "订单不存在")
		}
		if err != nil {
			return err
		}
		if current.Status == "paid" || current.Status == "refunded" || current.Status == "partial_refund" {
			order = current
			already = true
			return nil
		}
		if current.Status != "pending" {
			return errs.New(400, "VALIDATION", "订单状态不可支付")
		}
		updated, err := scanOrder(tx.QueryRow(
			`UPDATE orders SET status = 'paid', pay_trade_no = ?, paid_at = ?,
				pay_channel = CASE WHEN pay_channel = '' THEN 'epay' ELSE pay_channel END
			 WHERE id = ? RETURNING `+orderCols,
			tradeNo, now, current.ID,
		))
		if err != nil {
			return err
		}
		if err := grantServiceTx(tx, updated, now); err != nil {
			return err
		}
		if err := createCommissionsTx(tx, updated, pool, now); err != nil {
			return err
		}
		order = updated
		return nil
	})
	return order, already, err
}

func grantServiceTx(tx *sql.Tx, order Order, now int64) error {
	var expire, total int64
	if err := tx.QueryRow(`SELECT expire_at, total FROM users WHERE id = ?`, order.UserID).Scan(&expire, &total); err != nil {
		return err
	}
	if order.DurationMs > 0 {
		if expire > now {
			expire += order.DurationMs
		} else {
			expire = now + order.DurationMs
		}
	}
	total += order.TrafficBytes
	_, err := tx.Exec(`UPDATE users SET total = ?, expire_at = ? WHERE id = ?`, total, expire, order.UserID)
	return err
}

func createCommissionsTx(tx *sql.Tx, order Order, poolPercent, now int64) error {
	buyer, ok, err := loadUserTx(tx, order.UserID)
	if err != nil || !ok {
		return err
	}
	chain, err := referrerChainTx(tx, buyer, 3)
	if err != nil || len(chain) == 0 {
		return err
	}
	direct := chain[0]
	if direct.IsDistributor == 1 {
		amount := order.Amount * int64(direct.DistributorRate) / 100
		if amount <= 0 {
			return nil
		}
		return insertCommission(tx, order, buyer, direct, 1, 1, direct.DistributorRate, amount, now)
	}
	if direct.IsDistributor == 0 && direct.DistributorID > 0 && direct.MemberRate >= 0 {
		amount := order.Amount * int64(direct.MemberRate) / 100
		if amount <= 0 {
			return nil
		}
		return insertCommission(tx, order, buyer, direct, 1, 1, direct.MemberRate, amount, now)
	}
	_, l1, l2, l3 := SplitCommission(order.Amount, poolPercent)
	shares := []int64{l1, l2, l3}
	for i, person := range chain {
		if person.WalletEnabled != 1 || shares[i] <= 0 {
			continue
		}
		rate := []int{Level1Percent, Level2Percent, Level3Percent}[i]
		if err := insertCommission(tx, order, buyer, person, i+1, 0, rate, shares[i], now); err != nil {
			return err
		}
	}
	return nil
}

func referrerChainTx(tx *sql.Tx, buyer User, limit int) ([]User, error) {
	var chain []User
	seen := map[int64]bool{buyer.ID: true}
	next := buyer.ReferrerID
	for len(chain) < limit && next > 0 && !seen[next] {
		person, ok, err := loadUserTx(tx, next)
		if err != nil || !ok {
			return chain, err
		}
		seen[person.ID] = true
		chain = append(chain, person)
		next = person.ReferrerID
	}
	return chain, nil
}

func insertCommission(tx *sql.Tx, order Order, buyer, person User, level, mode, rate int, amount, now int64) error {
	name := buyer.Nickname
	if name == "" {
		name = buyer.Username
	}
	_, err := tx.Exec(
		`INSERT INTO commission_records (
			order_id, order_no, buyer_id, buyer_name, beneficiary_id, level, mode, rate,
			base_amount, amount, reversed_amount, status, created_at, settled_at
		) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, 'pending', ?, 0)`,
		order.ID, order.OrderNo, buyer.ID, name, person.ID, level, mode, rate, order.Amount, amount, now,
	)
	return err
}

func (s *Store) clawbackTx(tx *sql.Tx, order Order, refundAmount, now int64) error {
	if order.Amount <= 0 || refundAmount <= 0 {
		return nil
	}
	rows, err := tx.Query(
		`SELECT id, beneficiary_id, amount, reversed_amount, status FROM commission_records
		 WHERE order_id = ? AND status != 'reversed'`, order.ID,
	)
	if err != nil {
		return err
	}
	defer rows.Close()
	type row struct {
		id, beneficiary, amount, reversed int64
		status                            string
	}
	var list []row
	for rows.Next() {
		var item row
		if err := rows.Scan(&item.id, &item.beneficiary, &item.amount, &item.reversed, &item.status); err != nil {
			return err
		}
		list = append(list, item)
	}
	if err := rows.Err(); err != nil {
		return err
	}
	if err := rows.Close(); err != nil {
		return err
	}
	for _, item := range list {
		remain := item.amount - item.reversed
		portion := item.amount * refundAmount / order.Amount
		if portion > remain {
			portion = remain
		}
		if portion <= 0 {
			continue
		}
		status := item.status
		if item.reversed+portion >= item.amount {
			status = "reversed"
		}
		if _, err := tx.Exec(
			`UPDATE commission_records SET reversed_amount = ?, status = ? WHERE id = ?`,
			item.reversed+portion, status, item.id,
		); err != nil {
			return err
		}
		if item.status == "settled" {
			if err := adjustWalletTx(tx, item.beneficiary, -portion, false, "refund_clawback", order.ID, "订单退款扣回佣金", now); err != nil {
				return err
			}
		}
	}
	return nil
}

func (s *Store) SettleDue(now time.Time) (int, error) {
	day := s.SettingInt("commission_settle_day", 1)
	if day < 1 {
		day = 1
	}
	if day > 28 {
		day = 28
	}
	if int64(now.Day()) < day {
		return 0, nil
	}
	period := now.AddDate(0, -1, 0).Format("2006-01")
	settings, err := s.GetSettings()
	if err != nil {
		return 0, err
	}
	if settings["commission_last_period"] >= period && settings["commission_last_period"] != "" {
		return 0, nil
	}
	start := time.Date(now.Year(), now.Month(), 1, 0, 0, 0, 0, now.Location()).UnixMilli()
	n, err := s.settleBefore(start, now.UnixMilli())
	if err != nil {
		return n, err
	}
	if _, err := s.SetSettings(map[string]string{"commission_last_period": period}); err != nil {
		return n, err
	}
	return n, nil
}

func (s *Store) SettlePending(now int64) (int, error) {
	if now == 0 {
		now = time.Now().UnixMilli()
	}
	return s.settleBefore(now+1, now)
}

func (s *Store) settleBefore(before, now int64) (int, error) {
	rows, err := s.db.Query(
		`SELECT id, beneficiary_id, amount, reversed_amount FROM commission_records
		 WHERE status = 'pending' AND created_at < ?`, before,
	)
	if err != nil {
		return 0, err
	}
	defer rows.Close()
	type row struct{ id, user, amount, reversed int64 }
	var list []row
	for rows.Next() {
		var item row
		if err := rows.Scan(&item.id, &item.user, &item.amount, &item.reversed); err != nil {
			return 0, err
		}
		list = append(list, item)
	}
	if err := rows.Err(); err != nil {
		return 0, err
	}
	if err := rows.Close(); err != nil {
		return 0, err
	}
	count := 0
	err = s.tx(func(tx *sql.Tx) error {
		for _, item := range list {
			net := item.amount - item.reversed
			status := "settled"
			if net <= 0 {
				status = "reversed"
				net = 0
			}
			if _, err := tx.Exec(
				`UPDATE commission_records SET status = ?, settled_at = ? WHERE id = ? AND status = 'pending'`,
				status, now, item.id,
			); err != nil {
				return err
			}
			if net > 0 {
				if err := adjustWalletTx(tx, item.user, net, true, "commission", item.id, "佣金结算入账", now); err != nil {
					return err
				}
			}
			count++
		}
		return nil
	})
	return count, err
}

func (s *Store) WalletOf(userID int64) (Wallet, error) {
	var wallet Wallet
	err := s.db.QueryRow(
		`SELECT user_id, earned, balance, frozen, updated_at FROM wallets WHERE user_id = ?`, userID,
	).Scan(&wallet.UserID, &wallet.Earned, &wallet.Balance, &wallet.Frozen, &wallet.UpdatedAt)
	if err == sql.ErrNoRows {
		return Wallet{UserID: userID}, nil
	}
	return wallet, err
}

func (s *Store) ListWalletEntries(userID int64, kind string) ([]WalletEntry, error) {
	query := `SELECT id, user_id, kind, amount, balance_after, ref_id, detail, created_at
		FROM wallet_entries WHERE user_id = ?`
	args := []any{userID}
	if kind != "" {
		query += ` AND kind = ?`
		args = append(args, kind)
	}
	query += ` ORDER BY id DESC LIMIT 100`
	rows, err := s.db.Query(query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	list := []WalletEntry{}
	for rows.Next() {
		var row WalletEntry
		if err := rows.Scan(&row.ID, &row.UserID, &row.Kind, &row.Amount, &row.BalanceAfter, &row.RefID, &row.Detail, &row.CreatedAt); err != nil {
			return nil, err
		}
		list = append(list, row)
	}
	return list, rows.Err()
}

func (s *Store) RequestWithdraw(userID, amount int64, account string, feePercent int, now int64) (Withdrawal, error) {
	if now == 0 {
		now = time.Now().UnixMilli()
	}
	if feePercent < 0 {
		feePercent = 0
	}
	fee := amount * int64(feePercent) / 100
	if fee >= amount {
		return Withdrawal{}, errs.New(400, "VALIDATION", "手续费不能大于等于提现金额")
	}
	var created Withdrawal
	err := s.tx(func(tx *sql.Tx) error {
		if err := ensureWalletTx(tx, userID, now); err != nil {
			return err
		}
		var balance int64
		if err := tx.QueryRow(`SELECT balance FROM wallets WHERE user_id = ?`, userID).Scan(&balance); err != nil {
			return err
		}
		if balance < amount {
			return errs.New(400, "VALIDATION", "可提现余额不足")
		}
		if err := adjustWalletTx(tx, userID, -amount, false, "withdraw", 0, "提交提现申请", now); err != nil {
			return err
		}
		if _, err := tx.Exec(`UPDATE wallets SET frozen = frozen + ? WHERE user_id = ?`, amount, userID); err != nil {
			return err
		}
		row, err := scanWithdrawal(tx.QueryRow(
			`INSERT INTO withdrawals (user_id, amount, fee, net_amount, account, status, created_at, reviewed_at)
			 VALUES (?, ?, ?, ?, ?, 'pending', ?, 0)
			 RETURNING id, user_id, amount, fee, net_amount, account, status, created_at, reviewed_at`,
			userID, amount, fee, amount-fee, account, now,
		))
		if err != nil {
			return err
		}
		if _, err := tx.Exec(`UPDATE wallet_entries SET ref_id = ? WHERE id = (
			SELECT id FROM wallet_entries WHERE user_id = ? AND kind = 'withdraw' ORDER BY id DESC LIMIT 1
		)`, row.ID, userID); err != nil {
			return err
		}
		created = row
		return nil
	})
	return created, err
}

func (s *Store) ReviewWithdraw(id int64, approve bool, now int64) (Withdrawal, error) {
	if now == 0 {
		now = time.Now().UnixMilli()
	}
	var updated Withdrawal
	err := s.tx(func(tx *sql.Tx) error {
		current, err := scanWithdrawal(tx.QueryRow(
			`SELECT id, user_id, amount, fee, net_amount, account, status, created_at, reviewed_at FROM withdrawals WHERE id = ?`, id,
		))
		if err == sql.ErrNoRows {
			return errs.New(404, "NOT_FOUND", "提现申请不存在")
		}
		if err != nil {
			return err
		}
		if current.Status != "pending" {
			return errs.New(400, "VALIDATION", "提现申请已处理")
		}
		status := "rejected"
		if approve {
			status = "approved"
		}
		row, err := scanWithdrawal(tx.QueryRow(
			`UPDATE withdrawals SET status = ?, reviewed_at = ? WHERE id = ?
			 RETURNING id, user_id, amount, fee, net_amount, account, status, created_at, reviewed_at`,
			status, now, id,
		))
		if err != nil {
			return err
		}
		if _, err := tx.Exec(`UPDATE wallets SET frozen = frozen - ? WHERE user_id = ? AND frozen >= ?`, current.Amount, current.UserID, current.Amount); err != nil {
			return err
		}
		if !approve {
			if err := adjustWalletTx(tx, current.UserID, current.Amount, false, "withdraw_reject", id, "提现驳回退回", now); err != nil {
				return err
			}
		}
		updated = row
		return nil
	})
	return updated, err
}

func (s *Store) ListWithdrawals(userID int64) ([]Withdrawal, error) {
	query := `SELECT id, user_id, amount, fee, net_amount, account, status, created_at, reviewed_at FROM withdrawals`
	args := []any{}
	if userID > 0 {
		query += ` WHERE user_id = ?`
		args = append(args, userID)
	}
	query += ` ORDER BY id DESC LIMIT 200`
	rows, err := s.db.Query(query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	list := []Withdrawal{}
	for rows.Next() {
		row, err := scanWithdrawal(rows)
		if err != nil {
			return nil, err
		}
		list = append(list, row)
	}
	return list, rows.Err()
}

func (s *Store) ListCommissions(beneficiaryID, distributorID int64) ([]Commission, error) {
	query := `SELECT id, order_id, order_no, buyer_id, buyer_name, beneficiary_id, level, mode, rate,
		base_amount, amount, reversed_amount, status, created_at, settled_at FROM commission_records`
	args := []any{}
	switch {
	case beneficiaryID > 0:
		query += ` WHERE beneficiary_id = ?`
		args = append(args, beneficiaryID)
	case distributorID > 0:
		query += ` WHERE buyer_id IN (SELECT id FROM users WHERE distributor_id = ?)`
		args = append(args, distributorID)
	}
	query += ` ORDER BY id DESC LIMIT 200`
	rows, err := s.db.Query(query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	list := []Commission{}
	for rows.Next() {
		row, err := scanCommission(rows)
		if err != nil {
			return nil, err
		}
		list = append(list, row)
	}
	return list, rows.Err()
}

func (s *Store) CreatePlatformRequest(requesterID, targetID int64, action, reason string, now int64) (PlatformRequest, error) {
	if now == 0 {
		now = time.Now().UnixMilli()
	}
	return scanRequest(s.db.QueryRow(
		`INSERT INTO platform_requests (requester_id, target_id, action, reason, status, created_at)
		 VALUES (?, ?, ?, ?, 'pending', ?)
		 RETURNING id, requester_id, target_id, action, reason, status, created_at`,
		requesterID, targetID, action, reason, now,
	))
}

func (s *Store) ListPlatformRequests() ([]PlatformRequest, error) {
	rows, err := s.db.Query(
		`SELECT id, requester_id, target_id, action, reason, status, created_at FROM platform_requests ORDER BY id DESC`,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	list := []PlatformRequest{}
	for rows.Next() {
		row, err := scanRequest(rows)
		if err != nil {
			return nil, err
		}
		list = append(list, row)
	}
	return list, rows.Err()
}

func (s *Store) ReviewPlatformRequest(id int64, approve bool) (PlatformRequest, error) {
	status := "rejected"
	if approve {
		status = "approved"
	}
	row, err := scanRequest(s.db.QueryRow(
		`UPDATE platform_requests SET status = ? WHERE id = ? AND status = 'pending'
		 RETURNING id, requester_id, target_id, action, reason, status, created_at`,
		status, id,
	))
	if err == sql.ErrNoRows {
		return PlatformRequest{}, errs.New(404, "NOT_FOUND", "申请不存在或已处理")
	}
	return row, err
}

func (s *Store) ListAllTickets() ([]Ticket, error) {
	rows, err := s.db.Query(
		`SELECT id, user_id, subject, body, contact, status, created_at FROM tickets ORDER BY id DESC LIMIT 200`,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	list := []Ticket{}
	for rows.Next() {
		row, err := scanTicket(rows)
		if err != nil {
			return nil, err
		}
		list = append(list, row)
	}
	return list, rows.Err()
}

func (s *Store) UpdateTicketStatus(id int64, status string) (Ticket, error) {
	row, err := scanTicket(s.db.QueryRow(
		`UPDATE tickets SET status = ? WHERE id = ?
		 RETURNING id, user_id, subject, body, contact, status, created_at`,
		status, id,
	))
	if err == sql.ErrNoRows {
		return Ticket{}, errs.New(404, "NOT_FOUND", "工单不存在")
	}
	return row, err
}

func adjustWalletTx(tx *sql.Tx, userID, delta int64, addEarned bool, kind string, refID int64, detail string, now int64) error {
	if err := ensureWalletTx(tx, userID, now); err != nil {
		return err
	}
	var balance, earned int64
	if err := tx.QueryRow(`SELECT balance, earned FROM wallets WHERE user_id = ?`, userID).Scan(&balance, &earned); err != nil {
		return err
	}
	balance += delta
	if addEarned && delta > 0 {
		earned += delta
	}
	if _, err := tx.Exec(`UPDATE wallets SET balance = ?, earned = ?, updated_at = ? WHERE user_id = ?`, balance, earned, now, userID); err != nil {
		return err
	}
	_, err := tx.Exec(
		`INSERT INTO wallet_entries (user_id, kind, amount, balance_after, ref_id, detail, created_at)
		 VALUES (?, ?, ?, ?, ?, ?, ?)`,
		userID, kind, delta, balance, refID, detail, now,
	)
	return err
}

func ensureWalletTx(tx *sql.Tx, userID, now int64) error {
	_, err := tx.Exec(
		`INSERT INTO wallets (user_id, earned, balance, frozen, updated_at) VALUES (?, 0, 0, 0, ?)
		 ON CONFLICT(user_id) DO NOTHING`, userID, now,
	)
	return err
}

func loadUserTx(tx *sql.Tx, id int64) (User, bool, error) {
	user, err := scanUser(tx.QueryRow(`SELECT `+userCols+` FROM users WHERE id = ?`, id))
	if err == sql.ErrNoRows {
		return User{}, false, nil
	}
	if err != nil {
		return User{}, false, err
	}
	return user, true, nil
}

func scanPlan(row interface{ Scan(...any) error }) (Plan, error) {
	var plan Plan
	var enabled int
	err := row.Scan(&plan.Code, &plan.Name, &plan.Price, &plan.TrafficGB, &plan.DurationDays, &plan.SortOrder, &enabled)
	plan.Enabled = enabled == 1
	return plan, err
}

func scanCommission(row interface{ Scan(...any) error }) (Commission, error) {
	var rowv Commission
	err := row.Scan(
		&rowv.ID, &rowv.OrderID, &rowv.OrderNo, &rowv.BuyerID, &rowv.BuyerName, &rowv.BeneficiaryID,
		&rowv.Level, &rowv.Mode, &rowv.Rate, &rowv.BaseAmount, &rowv.Amount, &rowv.ReversedAmount,
		&rowv.Status, &rowv.CreatedAt, &rowv.SettledAt,
	)
	return rowv, err
}

func scanWithdrawal(row interface{ Scan(...any) error }) (Withdrawal, error) {
	var item Withdrawal
	err := row.Scan(&item.ID, &item.UserID, &item.Amount, &item.Fee, &item.NetAmount, &item.Account, &item.Status, &item.CreatedAt, &item.ReviewedAt)
	return item, err
}

func scanRequest(row interface{ Scan(...any) error }) (PlatformRequest, error) {
	var item PlatformRequest
	err := row.Scan(&item.ID, &item.RequesterID, &item.TargetID, &item.Action, &item.Reason, &item.Status, &item.CreatedAt)
	return item, err
}
