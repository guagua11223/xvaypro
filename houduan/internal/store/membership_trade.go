package store

import (
	"database/sql"
	"fmt"
	"strconv"
	"time"

	"xvay/houduan/internal/errs"
)

type Package struct {
	ID           int64
	Name         string
	DurationType string
	DurationDays int
	TrafficGB    float64
	Price        float64
	Status       int
}

type CommerceOrder struct {
	ID               int64
	OrderNo          string
	UserID           int64
	PackageID        int64
	Amount           float64
	GatewayFee       float64
	CommissionBase   float64
	PayChannel       string
	PayStatus        int
	PayTime          int64
	RefundStatus     int
	CommissionStatus int
	NodeStartAt      int64
	NodeEndAt        int64
	TrafficGB        float64
	TrafficUsedGB    float64
	ServiceStatus    int
	CreatedAt        int64
}

type MemberWallet struct {
	UserID          int64
	Balance         float64
	Frozen          float64
	TotalIncome     float64
	TotalWithdraw   float64
	NegativeBalance float64
}

type CommissionRow struct {
	ID          int64
	OrderID     int64
	UserID      int64
	FromUserID  int64
	Level       int
	Mode        int
	Rate        float64
	BaseAmount  float64
	Amount      float64
	Status      int
	SettleMonth string
	CreatedAt   int64
}

func (s *Store) ListPackages(activeOnly bool) ([]Package, error) {
	query := `SELECT id, name, duration_type, duration_days, traffic_gb, price, status FROM node_packages`
	if activeOnly {
		query += ` WHERE status = 1`
	}
	query += ` ORDER BY duration_days`
	rows, err := s.db.Query(query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var list []Package
	for rows.Next() {
		var p Package
		if err := rows.Scan(&p.ID, &p.Name, &p.DurationType, &p.DurationDays, &p.TrafficGB, &p.Price, &p.Status); err != nil {
			return nil, err
		}
		list = append(list, p)
	}
	if list == nil {
		list = []Package{}
	}
	return list, rows.Err()
}

func (s *Store) CreateCommerceOrder(userID, packageID, now int64) (CommerceOrder, error) {
	var pkg Package
	err := s.db.QueryRow(`SELECT id, name, duration_type, duration_days, traffic_gb, price, status FROM node_packages WHERE id = ?`, packageID).
		Scan(&pkg.ID, &pkg.Name, &pkg.DurationType, &pkg.DurationDays, &pkg.TrafficGB, &pkg.Price, &pkg.Status)
	if err == sql.ErrNoRows || (err == nil && pkg.Status != 1) {
		return CommerceOrder{}, errs.New(404, "NOT_FOUND", "套餐不存在")
	}
	if err != nil {
		return CommerceOrder{}, err
	}
	var pending int
	if err := s.db.QueryRow(
		`SELECT COUNT(1) FROM orders WHERE user_id = ? AND pay_status = 0`, userID,
	).Scan(&pending); err != nil {
		return CommerceOrder{}, err
	}
	if pending > 0 {
		return CommerceOrder{}, errs.New(400, "PENDING_ORDER", "有待支付订单，请先完成支付")
	}
	orderNo := fmt.Sprintf("XV%s%06d", time.UnixMilli(now).Format("20060102"), now%1000000)
	var order CommerceOrder
	err = s.db.QueryRow(`INSERT INTO orders (
		order_no, user_id, package_id, amount, pay_channel, pay_status, refund_status, commission_status, service_status, created_at
	) VALUES (?, ?, ?, ?, 'fourth', 0, -1, 0, 0, ?)
	RETURNING id, order_no, user_id, package_id, amount, gateway_fee, commission_base, pay_channel, pay_status, pay_time,
		refund_status, commission_status, node_start_at, node_end_at, traffic_gb, traffic_used_gb, service_status, created_at`,
		orderNo, userID, pkg.ID, pkg.Price, now).Scan(
		&order.ID, &order.OrderNo, &order.UserID, &order.PackageID, &order.Amount, &order.GatewayFee, &order.CommissionBase,
		&order.PayChannel, &order.PayStatus, &order.PayTime, &order.RefundStatus, &order.CommissionStatus,
		&order.NodeStartAt, &order.NodeEndAt, &order.TrafficGB, &order.TrafficUsedGB, &order.ServiceStatus, &order.CreatedAt,
	)
	return order, err
}

func (s *Store) FindCommerceOrder(id int64) (CommerceOrder, bool, error) {
	order, err := scanCommerceOrder(s.db.QueryRow(orderSelect+` WHERE id = ?`, id))
	if err == sql.ErrNoRows {
		return CommerceOrder{}, false, nil
	}
	if err != nil {
		return CommerceOrder{}, false, err
	}
	return order, true, nil
}

func (s *Store) FindCommerceOrderByNo(orderNo string) (CommerceOrder, bool, error) {
	order, err := scanCommerceOrder(s.db.QueryRow(orderSelect+` WHERE order_no = ?`, orderNo))
	if err == sql.ErrNoRows {
		return CommerceOrder{}, false, nil
	}
	if err != nil {
		return CommerceOrder{}, false, err
	}
	return order, true, nil
}

const orderSelect = `SELECT id, order_no, user_id, package_id, amount, gateway_fee, commission_base, pay_channel, pay_status, pay_time,
	refund_status, commission_status, node_start_at, node_end_at, traffic_gb, traffic_used_gb, service_status, created_at FROM orders`

func scanCommerceOrder(row interface{ Scan(...any) error }) (CommerceOrder, error) {
	var o CommerceOrder
	err := row.Scan(&o.ID, &o.OrderNo, &o.UserID, &o.PackageID, &o.Amount, &o.GatewayFee, &o.CommissionBase,
		&o.PayChannel, &o.PayStatus, &o.PayTime, &o.RefundStatus, &o.CommissionStatus,
		&o.NodeStartAt, &o.NodeEndAt, &o.TrafficGB, &o.TrafficUsedGB, &o.ServiceStatus, &o.CreatedAt)
	return o, err
}

func (s *Store) ListCommerceOrders(userID int64, from, to int64, limit int) ([]CommerceOrder, error) {
	if limit <= 0 || limit > 2000 {
		limit = 200
	}
	query := orderSelect + ` WHERE 1 = 1`
	var args []any
	if userID > 0 {
		query += ` AND user_id = ?`
		args = append(args, userID)
	}
	if from > 0 {
		query += ` AND created_at >= ?`
		args = append(args, from)
	}
	if to > 0 {
		query += ` AND created_at <= ?`
		args = append(args, to)
	}
	query += ` ORDER BY id DESC LIMIT ?`
	args = append(args, limit)
	rows, err := s.db.Query(query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var list []CommerceOrder
	for rows.Next() {
		o, err := scanCommerceOrder(rows)
		if err != nil {
			return nil, err
		}
		list = append(list, o)
	}
	if list == nil {
		list = []CommerceOrder{}
	}
	return list, rows.Err()
}

func (s *Store) ListOrdersForUsers(ids []int64, limit int) ([]CommerceOrder, error) {
	if len(ids) == 0 {
		return []CommerceOrder{}, nil
	}
	if limit <= 0 || limit > 2000 {
		limit = 200
	}
	query := orderSelect + ` WHERE user_id IN (`
	args := make([]any, 0, len(ids)+1)
	for i, id := range ids {
		if i > 0 {
			query += ","
		}
		query += "?"
		args = append(args, id)
	}
	query += `) ORDER BY id DESC LIMIT ?`
	args = append(args, limit)
	rows, err := s.db.Query(query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var list []CommerceOrder
	for rows.Next() {
		o, err := scanCommerceOrder(rows)
		if err != nil {
			return nil, err
		}
		list = append(list, o)
	}
	if list == nil {
		list = []CommerceOrder{}
	}
	return list, rows.Err()
}

// MarkOrderPaid records the gateway fee and creates one commission mode.
// A second notify for the same order does nothing.
func (s *Store) MarkCommercePaid(orderNo string, gatewayFee float64, now int64) (CommerceOrder, error) {
	var paid CommerceOrder
	err := s.tx(func(tx *sql.Tx) error {
		order, err := scanCommerceOrder(tx.QueryRow(orderSelect+` WHERE order_no = ?`, orderNo))
		if err == sql.ErrNoRows {
			return errs.New(404, "NOT_FOUND", "订单不存在")
		}
		if err != nil {
			return err
		}
		if order.PayStatus == 1 {
			paid = order
			return nil
		}
		if order.PayStatus != 0 {
			return errs.New(400, "VALIDATION", "订单不能支付")
		}
		if gatewayFee < 0 || gatewayFee > order.Amount {
			return errs.New(400, "VALIDATION", "支付手续费不正确")
		}
		base := roundMoney(order.Amount - gatewayFee)
		var pkg Package
		if err := tx.QueryRow(`SELECT id, name, duration_type, duration_days, traffic_gb, price, status FROM node_packages WHERE id = ?`, order.PackageID).
			Scan(&pkg.ID, &pkg.Name, &pkg.DurationType, &pkg.DurationDays, &pkg.TrafficGB, &pkg.Price, &pkg.Status); err != nil {
			return err
		}
		end := now + int64(pkg.DurationDays)*86400000
		bytes := int64(pkg.TrafficGB * 1024 * 1024 * 1024)
		if _, err := tx.Exec(`UPDATE orders SET pay_status = 1, gateway_fee = ?, commission_base = ?, pay_time = ?,
			node_start_at = ?, node_end_at = ?, traffic_gb = ?, traffic_used_gb = 0, service_status = 1, commission_status = 0
			WHERE id = ?`, gatewayFee, base, now, now, end, pkg.TrafficGB, order.ID); err != nil {
			return err
		}
		if _, err := tx.Exec(`UPDATE users SET upload = 0, download = 0, total = ?, expire_at = ?, status = 'active' WHERE id = ?`,
			bytes, end, order.UserID); err != nil {
			return err
		}
		if err := s.writeCommissions(tx, order.ID, order.UserID, base, now); err != nil {
			return err
		}
		paid, err = scanCommerceOrder(tx.QueryRow(orderSelect+` WHERE id = ?`, order.ID))
		return err
	})
	return paid, err
}

func (s *Store) writeCommissions(tx *sql.Tx, orderID, buyerID int64, base float64, now int64) error {
	buyer, err := scanMember(tx.QueryRow(`SELECT `+memberCols+` FROM users WHERE id = ?`, buyerID))
	if err != nil {
		return err
	}
	var upline []CommissionParty
	cur := buyer.ParentID
	for len(upline) < 3 && cur > 0 {
		person, err := scanMember(tx.QueryRow(`SELECT `+memberCols+` FROM users WHERE id = ?`, cur))
		if err == sql.ErrNoRows {
			break
		}
		if err != nil {
			return err
		}
		party := CommissionParty{ID: person.ID, IsDistributor: person.IsDistributor == 1}
		if party.IsDistributor {
			_ = tx.QueryRow(`SELECT commission_rate FROM distributors WHERE user_id = ? AND status = 0`, person.ID).Scan(&party.DistributorRate)
		}
		if person.DistributorID > 0 {
			var rate float64
			err := tx.QueryRow(`SELECT rate FROM commission_rates WHERE distributor_id = ? AND member_id = ?`, person.DistributorID, person.ID).Scan(&rate)
			if err == nil {
				party.CustomRate = &rate
			} else if err != sql.ErrNoRows {
				return err
			}
		}
		upline = append(upline, party)
		cur = person.ParentID
	}
	plan, err := loadPlanTx(tx)
	if err != nil {
		return err
	}
	for _, line := range SplitMemberCommission(base, upline, plan) {
		if line.Amount < 0 {
			continue
		}
		if _, err := tx.Exec(`INSERT INTO commissions (order_id, user_id, from_user_id, level, mode, rate, base_amount, amount, status, settle_month, created_at)
			VALUES (?, ?, ?, ?, ?, ?, ?, ?, 0, '', ?)`,
			orderID, line.UserID, buyerID, line.Level, line.Mode, line.Rate, base, line.Amount, now); err != nil {
			return err
		}
		if err := creditFrozen(tx, line.UserID, line.Amount); err != nil {
			return err
		}
		if line.Mode == 1 {
			_, _ = tx.Exec(`UPDATE distributors SET total_commission = total_commission + ? WHERE user_id = ?`, line.Amount, line.UserID)
		}
	}
	return nil
}

func loadPlanTx(tx *sql.Tx) (CommissionPlan, error) {
	plan := CommissionPlan{Pool: 50, Level1: 60, Level2: 30, Level3: 10, ThreeLevel: true}
	rows, err := tx.Query(`SELECT key, value FROM system_configs WHERE key IN ('pool_rate','level1_rate','level2_rate','level3_rate','three_level_enabled','commission_cap')`)
	if err != nil {
		return plan, err
	}
	defer rows.Close()
	for rows.Next() {
		var key, value string
		if err := rows.Scan(&key, &value); err != nil {
			return plan, err
		}
		switch key {
		case "pool_rate":
			plan.Pool = parseFloat(value, plan.Pool)
		case "level1_rate":
			plan.Level1 = parseFloat(value, plan.Level1)
		case "level2_rate":
			plan.Level2 = parseFloat(value, plan.Level2)
		case "level3_rate":
			plan.Level3 = parseFloat(value, plan.Level3)
		case "three_level_enabled":
			plan.ThreeLevel = value != "0"
		case "commission_cap":
			plan.Cap = parseFloat(value, 0)
		}
	}
	return plan, rows.Err()
}

func creditFrozen(tx *sql.Tx, userID int64, amount float64) error {
	if _, err := tx.Exec(`INSERT INTO wallets (user_id, balance, frozen, total_income, total_withdraw, negative_balance, version)
		VALUES (?, 0, 0, 0, 0, 0, 0) ON CONFLICT(user_id) DO NOTHING`, userID); err != nil {
		return err
	}
	var negative float64
	if err := tx.QueryRow(`SELECT negative_balance FROM wallets WHERE user_id = ?`, userID).Scan(&negative); err != nil {
		return err
	}
	payDown := 0.0
	if negative > 0 {
		payDown = amount
		if payDown > negative {
			payDown = negative
		}
		negative = roundMoney(negative - payDown)
	}
	frozenAdd := roundMoney(amount - payDown)
	_, err := tx.Exec(`UPDATE wallets SET frozen = frozen + ?, total_income = total_income + ?, negative_balance = ?, version = version + 1 WHERE user_id = ?`,
		frozenAdd, amount, negative, userID)
	return err
}

func (s *Store) SettleMemberDue(now time.Time) (int, error) {
	day := int(s.mustConfigFloat("settle_day", 1))
	if day < 1 {
		day = 1
	}
	if now.Day() < day {
		return 0, nil
	}
	start := time.Date(now.Year(), now.Month(), 1, 0, 0, 0, 0, now.Location()).UnixMilli()
	label := now.AddDate(0, -1, 0).Format("2006-01")
	var n int
	err := s.tx(func(tx *sql.Tx) error {
		rows, err := tx.Query(`SELECT id, user_id, amount FROM commissions WHERE status = 0 AND created_at < ?`, start)
		if err != nil {
			return err
		}
		defer rows.Close()
		type item struct {
			id, user int64
			amount   float64
		}
		var items []item
		for rows.Next() {
			var it item
			if err := rows.Scan(&it.id, &it.user, &it.amount); err != nil {
				return err
			}
			items = append(items, it)
		}
		if err := rows.Err(); err != nil {
			return err
		}
		for _, it := range items {
			if _, err := tx.Exec(`UPDATE wallets SET frozen = CASE WHEN frozen > ? THEN frozen - ? ELSE 0 END, balance = balance + ?, version = version + 1 WHERE user_id = ?`,
				it.amount, it.amount, it.amount, it.user); err != nil {
				return err
			}
			if _, err := tx.Exec(`UPDATE commissions SET status = 1, settle_month = ? WHERE id = ?`, label, it.id); err != nil {
				return err
			}
			n++
		}
		if _, err := tx.Exec(`UPDATE orders SET commission_status = 1
			WHERE commission_status = 0
			AND id IN (SELECT order_id FROM commissions WHERE status = 1)
			AND id NOT IN (SELECT order_id FROM commissions WHERE status = 0)`); err != nil {
			return err
		}
		return nil
	})
	return n, err
}

func (s *Store) MemberWallet(userID int64) (MemberWallet, error) {
	var w MemberWallet
	err := s.db.QueryRow(`SELECT user_id, balance, frozen, total_income, total_withdraw, negative_balance FROM wallets WHERE user_id = ?`, userID).
		Scan(&w.UserID, &w.Balance, &w.Frozen, &w.TotalIncome, &w.TotalWithdraw, &w.NegativeBalance)
	if err == sql.ErrNoRows {
		return MemberWallet{UserID: userID}, nil
	}
	return w, err
}

func (s *Store) RequestMemberWithdraw(userID int64, amount float64, now int64) (int64, error) {
	member, ok, err := s.LoadMember(userID)
	if err != nil {
		return 0, err
	}
	if !ok {
		return 0, errs.New(404, "NOT_FOUND", "会员不存在")
	}
	if member.WalletEnabled != 1 {
		return 0, errs.New(403, "FORBIDDEN", "钱包未开通")
	}
	if member.MemberStatus == 1 {
		return 0, errs.New(403, "FORBIDDEN", "账号已封禁")
	}
	feeRate, err := s.ConfigFloat("withdraw_fee_rate", 0)
	if err != nil {
		return 0, err
	}
	minAmount, err := s.ConfigFloat("withdraw_min", 0)
	if err != nil {
		return 0, err
	}
	if amount < minAmount {
		return 0, errs.New(400, "VALIDATION", "低于最低提现金额")
	}
	fee := roundMoney(amount * feeRate / 100)
	if fee >= amount {
		return 0, errs.New(400, "VALIDATION", "手续费不能高于提现金额")
	}
	var id int64
	err = s.tx(func(tx *sql.Tx) error {
		res, err := tx.Exec(`UPDATE wallets SET balance = balance - ?, frozen = frozen + ?, version = version + 1 WHERE user_id = ? AND balance >= ?`,
			amount, amount, userID, amount)
		if err != nil {
			return err
		}
		n, _ := res.RowsAffected()
		if n == 0 {
			return errs.New(400, "VALIDATION", "可提现余额不足")
		}
		month := time.UnixMilli(now).Format("2006-01")
		return tx.QueryRow(`INSERT INTO withdrawals (user_id, amount, fee, fee_rate, min_amount, status, apply_time, month)
			VALUES (?, ?, ?, ?, ?, 0, ?, ?) RETURNING id`, userID, amount, fee, feeRate, minAmount, now, month).Scan(&id)
	})
	return id, err
}

func (s *Store) AuditWithdrawal(id int64, action string, now int64) error {
	return s.tx(func(tx *sql.Tx) error {
		var userID int64
		var amount float64
		var status int
		err := tx.QueryRow(`SELECT user_id, amount, status FROM withdrawals WHERE id = ?`, id).Scan(&userID, &amount, &status)
		if err == sql.ErrNoRows {
			return errs.New(404, "NOT_FOUND", "提现不存在")
		}
		if err != nil {
			return err
		}
		switch action {
		case "approve":
			if status != 0 {
				return errs.New(400, "VALIDATION", "当前状态不能审核")
			}
			_, err = tx.Exec(`UPDATE withdrawals SET status = 1, audit_time = ? WHERE id = ?`, now, id)
		case "reject", "cancel":
			if status != 0 && !(action == "cancel" && status == 0) {
				if status != 0 {
					return errs.New(400, "VALIDATION", "当前状态不能拒绝")
				}
			}
			if status != 0 {
				return errs.New(400, "VALIDATION", "当前状态不能取消")
			}
			next := 3
			if action == "cancel" {
				next = 4
			}
			if _, err = tx.Exec(`UPDATE wallets SET frozen = CASE WHEN frozen > ? THEN frozen - ? ELSE 0 END, balance = balance + ? WHERE user_id = ?`,
				amount, amount, amount, userID); err != nil {
				return err
			}
			_, err = tx.Exec(`UPDATE withdrawals SET status = ?, audit_time = ? WHERE id = ?`, next, now, id)
		case "pay":
			if status != 1 && status != 0 {
				return errs.New(400, "VALIDATION", "当前状态不能打款")
			}
			if _, err = tx.Exec(`UPDATE wallets SET frozen = CASE WHEN frozen > ? THEN frozen - ? ELSE 0 END, total_withdraw = total_withdraw + ? WHERE user_id = ?`,
				amount, amount, amount, userID); err != nil {
				return err
			}
			_, err = tx.Exec(`UPDATE withdrawals SET status = 2, audit_time = CASE WHEN audit_time = 0 THEN ? ELSE audit_time END, pay_time = ? WHERE id = ?`, now, now, id)
		default:
			return errs.New(400, "VALIDATION", "未知操作")
		}
		return err
	})
}

func withdrawalStatusCode(status string) int {
	switch status {
	case "", "0", "pending":
		return 0
	case "1", "approved", "success":
		return 1
	case "2", "paid":
		return 2
	case "3", "rejected":
		return 3
	default:
		n, _ := strconv.Atoi(status)
		return n
	}
}

func (s *Store) ListMemberWithdrawals(userID int64, limit int) ([]map[string]any, error) {
	if limit <= 0 || limit > 500 {
		limit = 100
	}
	query := `SELECT w.id, w.user_id, u.username, w.amount, w.fee, w.fee_rate, w.status, w.apply_time, w.audit_time, w.pay_time, w.month, w.remark
		FROM withdrawals w JOIN users u ON u.id = w.user_id`
	var args []any
	if userID > 0 {
		query += ` WHERE w.user_id = ?`
		args = append(args, userID)
	}
	query += ` ORDER BY w.id DESC LIMIT ?`
	args = append(args, limit)
	rows, err := s.db.Query(query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var list []map[string]any
	for rows.Next() {
		var id, uid, apply, audit, pay int64
		var amount, fee, feeRate float64
		var statusText, username, month, remark string
		if err := rows.Scan(&id, &uid, &username, &amount, &fee, &feeRate, &statusText, &apply, &audit, &pay, &month, &remark); err != nil {
			return nil, err
		}
		list = append(list, map[string]any{
			"id": id, "userId": uid, "username": username, "amount": amount, "fee": fee, "feeRate": feeRate,
			"status": withdrawalStatusCode(statusText), "applyTime": apply, "auditTime": audit, "payTime": pay, "month": month, "remark": remark,
		})
	}
	if list == nil {
		list = []map[string]any{}
	}
	return list, rows.Err()
}

func (s *Store) ListCommissionRows(userID int64, limit int) ([]CommissionRow, error) {
	if limit <= 0 || limit > 500 {
		limit = 100
	}
	query := `SELECT id, order_id, user_id, from_user_id, level, mode, rate, base_amount, amount, status, settle_month, created_at FROM commissions`
	var args []any
	if userID > 0 {
		query += ` WHERE user_id = ?`
		args = append(args, userID)
	}
	query += ` ORDER BY id DESC LIMIT ?`
	args = append(args, limit)
	rows, err := s.db.Query(query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var list []CommissionRow
	for rows.Next() {
		var c CommissionRow
		if err := rows.Scan(&c.ID, &c.OrderID, &c.UserID, &c.FromUserID, &c.Level, &c.Mode, &c.Rate, &c.BaseAmount, &c.Amount, &c.Status, &c.SettleMonth, &c.CreatedAt); err != nil {
			return nil, err
		}
		list = append(list, c)
	}
	if list == nil {
		list = []CommissionRow{}
	}
	return list, rows.Err()
}

func (s *Store) ApplyRefund(orderID, userID int64, reason string) (int64, error) {
	var id int64
	err := s.tx(func(tx *sql.Tx) error {
		order, err := scanCommerceOrder(tx.QueryRow(orderSelect+` WHERE id = ?`, orderID))
		if err == sql.ErrNoRows {
			return errs.New(404, "NOT_FOUND", "订单不存在")
		}
		if err != nil {
			return err
		}
		if userID > 0 && order.UserID != userID {
			return errs.New(403, "FORBIDDEN", "不能申请他人的订单")
		}
		if order.PayStatus != 1 {
			return errs.New(400, "VALIDATION", "只有已支付订单可以退款")
		}
		var existing int
		if err := tx.QueryRow(`SELECT COUNT(*) FROM refunds WHERE order_id = ? AND status IN (0, 1, 2)`, orderID).Scan(&existing); err != nil {
			return err
		}
		if existing > 0 {
			return errs.New(400, "VALIDATION", "退款已在处理")
		}
		if _, err := tx.Exec(`UPDATE orders SET refund_status = 0 WHERE id = ?`, orderID); err != nil {
			return err
		}
		return tx.QueryRow(`INSERT INTO refunds (order_id, user_id, amount, reason, status, ban_user, can_unban) VALUES (?, ?, ?, ?, 0, 1, 1) RETURNING id`,
			orderID, order.UserID, order.Amount, reason).Scan(&id)
	})
	return id, err
}

func (s *Store) HandleRefund(id int64, approve bool, actor, now int64) error {
	return s.tx(func(tx *sql.Tx) error {
		var orderID, userID int64
		var amount float64
		var status int
		err := tx.QueryRow(`SELECT order_id, user_id, amount, status FROM refunds WHERE id = ?`, id).Scan(&orderID, &userID, &amount, &status)
		if err == sql.ErrNoRows {
			return errs.New(404, "NOT_FOUND", "退款不存在")
		}
		if err != nil {
			return err
		}
		if status != 0 && status != 1 {
			return errs.New(400, "VALIDATION", "退款已处理")
		}
		if !approve {
			if _, err := tx.Exec(`UPDATE refunds SET status = 3, handled_by = ?, handled_at = ? WHERE id = ?`, actor, now, id); err != nil {
				return err
			}
			_, err = tx.Exec(`UPDATE orders SET refund_status = 3 WHERE id = ?`, orderID)
			return err
		}
		if _, err := tx.Exec(`UPDATE refunds SET status = 2, handled_by = ?, handled_at = ?, ban_user = 1, can_unban = 1 WHERE id = ?`, actor, now, id); err != nil {
			return err
		}
		if _, err := tx.Exec(`UPDATE orders SET pay_status = 2, refund_status = 2, commission_status = 2, service_status = 4 WHERE id = ?`, orderID); err != nil {
			return err
		}
		if err := clawback(tx, orderID); err != nil {
			return err
		}
		if _, err := tx.Exec(`UPDATE users SET status = 'disabled', member_status = 1, banned_at = ?, ban_reason = ? WHERE id = ?`, now, "退款封禁", userID); err != nil {
			return err
		}
		_, err = tx.Exec(`UPDATE orders SET service_status = 4 WHERE user_id = ? AND id = ?`, userID, orderID)
		return err
	})
}

func clawback(tx *sql.Tx, orderID int64) error {
	rows, err := tx.Query(`SELECT id, user_id, amount, status FROM commissions WHERE order_id = ? AND status IN (0, 1)`, orderID)
	if err != nil {
		return err
	}
	defer rows.Close()
	type item struct {
		id, user int64
		amount   float64
		status   int
	}
	var items []item
	for rows.Next() {
		var it item
		if err := rows.Scan(&it.id, &it.user, &it.amount, &it.status); err != nil {
			return err
		}
		items = append(items, it)
	}
	if err := rows.Err(); err != nil {
		return err
	}
	for _, it := range items {
		if err := debitWallet(tx, it.user, it.amount, it.status == 0); err != nil {
			return err
		}
		if _, err := tx.Exec(`UPDATE commissions SET status = 2 WHERE id = ?`, it.id); err != nil {
			return err
		}
		_, _ = tx.Exec(`UPDATE distributors SET total_commission = CASE WHEN total_commission > ? THEN total_commission - ? ELSE 0 END WHERE user_id = ?`,
			it.amount, it.amount, it.user)
	}
	return nil
}

func debitWallet(tx *sql.Tx, userID int64, amount float64, fromFrozen bool) error {
	if _, err := tx.Exec(`INSERT INTO wallets (user_id, balance, frozen, total_income, total_withdraw, negative_balance, version)
		VALUES (?, 0, 0, 0, 0, 0, 0) ON CONFLICT(user_id) DO NOTHING`, userID); err != nil {
		return err
	}
	var balance, frozen, negative float64
	if err := tx.QueryRow(`SELECT balance, frozen, negative_balance FROM wallets WHERE user_id = ?`, userID).Scan(&balance, &frozen, &negative); err != nil {
		return err
	}
	left := amount
	if fromFrozen {
		take := frozen
		if take > left {
			take = left
		}
		frozen = roundMoney(frozen - take)
		left = roundMoney(left - take)
	}
	take := balance
	if take > left {
		take = left
	}
	balance = roundMoney(balance - take)
	left = roundMoney(left - take)
	if left > 0 {
		negative = roundMoney(negative + left)
	}
	_, err := tx.Exec(`UPDATE wallets SET balance = ?, frozen = ?, negative_balance = ?, version = version + 1 WHERE user_id = ?`,
		balance, frozen, negative, userID)
	return err
}

func (s *Store) ListMemberRefunds(limit int) ([]map[string]any, error) {
	if limit <= 0 || limit > 500 {
		limit = 100
	}
	rows, err := s.db.Query(`SELECT r.id, r.order_id, o.order_no, r.user_id, u.username, r.amount, r.reason, r.status, r.handled_by, r.handled_at, r.ban_user, r.can_unban
		FROM refunds r JOIN orders o ON o.id = r.order_id JOIN users u ON u.id = r.user_id ORDER BY r.id DESC LIMIT ?`, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var list []map[string]any
	for rows.Next() {
		var id, orderID, userID, handledBy, handledAt int64
		var amount float64
		var status, banUser, canUnban int
		var orderNo, username, reason string
		if err := rows.Scan(&id, &orderID, &orderNo, &userID, &username, &amount, &reason, &status, &handledBy, &handledAt, &banUser, &canUnban); err != nil {
			return nil, err
		}
		list = append(list, map[string]any{
			"id": id, "orderId": orderID, "orderNo": orderNo, "userId": userID, "username": username,
			"amount": amount, "reason": reason, "status": status, "handledBy": handledBy, "handledAt": handledAt,
			"banUser": banUser, "canUnban": canUnban,
		})
	}
	if list == nil {
		list = []map[string]any{}
	}
	return list, rows.Err()
}

func (s *Store) ServiceBlocked(userID, now int64) (bool, string, error) {
	var memberStatus int
	var status string
	if err := s.db.QueryRow(`SELECT member_status, status FROM users WHERE id = ?`, userID).Scan(&memberStatus, &status); err != nil {
		return false, "", err
	}
	if memberStatus == 1 || status != "active" {
		return true, "账号已封禁，节点已停用", nil
	}
	var paid int
	if err := s.db.QueryRow(`SELECT COUNT(*) FROM orders WHERE user_id = ? AND pay_status = 1`, userID).Scan(&paid); err != nil {
		return false, "", err
	}
	if paid == 0 {
		return false, "", nil
	}
	var active int
	if err := s.db.QueryRow(`SELECT COUNT(*) FROM orders WHERE user_id = ? AND pay_status = 1 AND service_status = 1 AND node_end_at > ?`, userID, now).Scan(&active); err != nil {
		return false, "", err
	}
	if active == 0 {
		return true, "节点已停用或已到期", nil
	}
	return false, "", nil
}

func (s *Store) mustConfigFloat(key string, fallback float64) float64 {
	v, err := s.ConfigFloat(key, fallback)
	if err != nil {
		return fallback
	}
	return v
}
