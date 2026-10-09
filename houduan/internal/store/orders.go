package store

import (
	"crypto/rand"
	"database/sql"
	"fmt"
	"time"

	"xvay/houduan/internal/errs"
)

type Order struct {
	ID           int64
	UserID       int64
	OrderNo      string
	Title        string
	Amount       int64
	Currency     string
	Status       string
	PayChannel   string
	PayTradeNo   string
	PaidAt       int64
	CreatedAt    int64
	PlanCode     string
	TrafficBytes int64
	DurationMs   int64
	Renew        int
}

type Refund struct {
	ID        int64
	OrderID   int64
	UserID    int64
	Amount    int64
	Status    string
	Reason    string
	CreatedAt int64
}

type Ticket struct {
	ID        int64
	UserID    int64
	Subject   string
	Body      string
	Contact   string
	Status    string
	CreatedAt int64
}

type OrderInput struct {
	UserID       int64
	Title        string
	Amount       int64
	Status       string
	PayChannel   string
	PayTradeNo   string
	PaidAt       int64
	Now          int64
	PlanCode     string
	TrafficBytes int64
	DurationMs   int64
	Renew        bool
}

const orderCols = `id, user_id, order_no, title, amount, currency, status, pay_channel, pay_trade_no, paid_at, created_at, plan_code, traffic_bytes, duration_ms, renew`

func (s *Store) CreateOrder(input OrderInput) (Order, error) {
	if input.Now == 0 {
		input.Now = time.Now().UnixMilli()
	}
	if input.Status == "" {
		input.Status = "pending"
	}
	if input.Status == "paid" && input.PaidAt == 0 {
		input.PaidAt = input.Now
	}
	orderNo, err := newOrderNo(input.Now)
	if err != nil {
		return Order{}, err
	}
	row := s.db.QueryRow(
		`INSERT INTO orders (
			user_id, order_no, title, amount, currency, status, pay_channel, pay_trade_no, paid_at, created_at,
			plan_code, traffic_bytes, duration_ms, renew
		) VALUES (?, ?, ?, ?, 'CNY', ?, ?, ?, ?, ?, ?, ?, ?, ?)
		RETURNING `+orderCols,
		input.UserID, orderNo, input.Title, input.Amount, input.Status, input.PayChannel, input.PayTradeNo, input.PaidAt, input.Now,
		input.PlanCode, input.TrafficBytes, input.DurationMs, bit(input.Renew),
	)
	order, err := scanOrder(row)
	if errs.IsUnique(err) {
		return Order{}, errs.New(409, "CONFLICT", "订单号冲突，请重试")
	}
	return order, err
}

func (s *Store) ListOrders(userID int64, limit int) ([]Order, error) {
	if limit <= 0 || limit > 200 {
		limit = 100
	}
	rows, err := s.db.Query(
		`SELECT `+orderCols+`
		 FROM orders WHERE user_id = ? ORDER BY id DESC LIMIT ?`, userID, limit,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	return collectOrders(rows)
}

func (s *Store) FindOrder(id int64) (Order, bool, error) {
	order, err := scanOrder(s.db.QueryRow(
		`SELECT `+orderCols+`
		 FROM orders WHERE id = ?`, id,
	))
	if err == sql.ErrNoRows {
		return Order{}, false, nil
	}
	if err != nil {
		return Order{}, false, err
	}
	return order, true, nil
}

func (s *Store) ListRefunds(userID int64) ([]Refund, error) {
	rows, err := s.db.Query(
		`SELECT id, order_id, user_id, amount, status, reason, created_at
		 FROM refunds WHERE user_id = ? ORDER BY id DESC`, userID,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	list := []Refund{}
	for rows.Next() {
		row, err := scanRefund(rows)
		if err != nil {
			return nil, err
		}
		list = append(list, row)
	}
	return list, rows.Err()
}

func (s *Store) AddRefund(orderID, amount int64, status, reason string, now int64) (Refund, Order, error) {
	if status == "" {
		status = "success"
	}
	if now == 0 {
		now = time.Now().UnixMilli()
	}
	var refund Refund
	var order Order
	err := s.tx(func(tx *sql.Tx) error {
		current, err := scanOrder(tx.QueryRow(
			`SELECT `+orderCols+`
			 FROM orders WHERE id = ?`, orderID,
		))
		if err == sql.ErrNoRows {
			return errs.New(404, "NOT_FOUND", "订单不存在")
		}
		if err != nil {
			return err
		}
		var refunded int64
		if err := tx.QueryRow(
			`SELECT COALESCE(SUM(amount), 0) FROM refunds WHERE order_id = ? AND status = 'success'`, orderID,
		).Scan(&refunded); err != nil {
			return err
		}
		if status == "success" && amount > current.Amount-refunded {
			return errs.New(400, "VALIDATION", "退款金额超过可退余额")
		}
		created, err := scanRefund(tx.QueryRow(
			`INSERT INTO refunds (order_id, user_id, amount, status, reason, created_at)
			 VALUES (?, ?, ?, ?, ?, ?)
			 RETURNING id, order_id, user_id, amount, status, reason, created_at`,
			orderID, current.UserID, amount, status, reason, now,
		))
		if err != nil {
			return err
		}
		if status == "success" {
			next := "partial_refund"
			if refunded+amount >= current.Amount {
				next = "refunded"
			}
			updated, err := scanOrder(tx.QueryRow(
				`UPDATE orders SET status = ? WHERE id = ?
				 RETURNING `+orderCols+``,
				next, orderID,
			))
			if err != nil {
				return err
			}
			current = updated
			if err := s.clawbackTx(tx, current, amount, now); err != nil {
				return err
			}
		}
		refund = created
		order = current
		return nil
	})
	return refund, order, err
}

func (s *Store) CreateTicket(userID int64, subject, body, contact string, now int64) (Ticket, error) {
	if now == 0 {
		now = time.Now().UnixMilli()
	}
	return scanTicket(s.db.QueryRow(
		`INSERT INTO tickets (user_id, subject, body, contact, status, created_at)
		 VALUES (?, ?, ?, ?, 'open', ?)
		 RETURNING id, user_id, subject, body, contact, status, created_at`,
		userID, subject, body, contact, now,
	))
}

func (s *Store) ListTickets(userID int64) ([]Ticket, error) {
	rows, err := s.db.Query(
		`SELECT id, user_id, subject, body, contact, status, created_at
		 FROM tickets WHERE user_id = ? ORDER BY id DESC`, userID,
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

func newOrderNo(now int64) (string, error) {
	var buf [3]byte
	if _, err := rand.Read(buf[:]); err != nil {
		return "", err
	}
	n := int(buf[0])<<16 | int(buf[1])<<8 | int(buf[2])
	return fmt.Sprintf("XV%s%06d", time.UnixMilli(now).UTC().Format("20060102150405"), n%1000000), nil
}

func collectOrders(rows *sql.Rows) ([]Order, error) {
	list := []Order{}
	for rows.Next() {
		order, err := scanOrder(rows)
		if err != nil {
			return nil, err
		}
		list = append(list, order)
	}
	return list, rows.Err()
}

func scanOrder(row interface{ Scan(...any) error }) (Order, error) {
	var order Order
	err := row.Scan(
		&order.ID, &order.UserID, &order.OrderNo, &order.Title, &order.Amount, &order.Currency,
		&order.Status, &order.PayChannel, &order.PayTradeNo, &order.PaidAt, &order.CreatedAt,
		&order.PlanCode, &order.TrafficBytes, &order.DurationMs, &order.Renew,
	)
	return order, err
}

func scanRefund(row interface{ Scan(...any) error }) (Refund, error) {
	var refund Refund
	err := row.Scan(&refund.ID, &refund.OrderID, &refund.UserID, &refund.Amount, &refund.Status, &refund.Reason, &refund.CreatedAt)
	return refund, err
}

func scanTicket(row interface{ Scan(...any) error }) (Ticket, error) {
	var ticket Ticket
	err := row.Scan(&ticket.ID, &ticket.UserID, &ticket.Subject, &ticket.Body, &ticket.Contact, &ticket.Status, &ticket.CreatedAt)
	return ticket, err
}
