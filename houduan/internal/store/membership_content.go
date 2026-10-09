package store

import (
	"database/sql"

	"xvay/houduan/internal/errs"
)

func (s *Store) ListAds(activeOnly bool, now int64) ([]map[string]any, error) {
	query := `SELECT id, slot, title, image_url, link_url, sort_order, starts_at, ends_at, status FROM ads`
	if activeOnly {
		query += ` WHERE status = 1 AND (starts_at = 0 OR starts_at <= ?) AND (ends_at = 0 OR ends_at >= ?)`
	}
	query += ` ORDER BY sort_order, id`
	var rows *sql.Rows
	var err error
	if activeOnly {
		rows, err = s.db.Query(query, now, now)
	} else {
		rows, err = s.db.Query(query)
	}
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	return scanMaps(rows, []string{"id", "slot", "title", "imageUrl", "linkUrl", "sortOrder", "startsAt", "endsAt", "status"})
}

func (s *Store) SaveAd(id int64, slot, title, image, link string, sort, starts, ends int64, status int) (int64, error) {
	if id == 0 {
		err := s.db.QueryRow(`INSERT INTO ads (slot, title, image_url, link_url, sort_order, starts_at, ends_at, status)
			VALUES (?, ?, ?, ?, ?, ?, ?, ?) RETURNING id`, slot, title, image, link, sort, starts, ends, status).Scan(&id)
		return id, err
	}
	_, err := s.db.Exec(`UPDATE ads SET slot = ?, title = ?, image_url = ?, link_url = ?, sort_order = ?, starts_at = ?, ends_at = ?, status = ? WHERE id = ?`,
		slot, title, image, link, sort, starts, ends, status, id)
	return id, err
}

func (s *Store) DeleteAd(id int64) error {
	_, err := s.db.Exec(`DELETE FROM ads WHERE id = ?`, id)
	return err
}

func (s *Store) ListServices(activeOnly bool) ([]map[string]any, error) {
	query := `SELECT id, channel, account, qr_url, enabled, sort_order FROM customer_services`
	if activeOnly {
		query += ` WHERE enabled = 1`
	}
	query += ` ORDER BY sort_order, id`
	rows, err := s.db.Query(query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	return scanMaps(rows, []string{"id", "channel", "account", "qrUrl", "enabled", "sortOrder"})
}

func (s *Store) SaveService(id int64, channel, account, qr string, enabled, sort int) (int64, error) {
	if id == 0 {
		err := s.db.QueryRow(`INSERT INTO customer_services (channel, account, qr_url, enabled, sort_order) VALUES (?, ?, ?, ?, ?) RETURNING id`,
			channel, account, qr, enabled, sort).Scan(&id)
		return id, err
	}
	_, err := s.db.Exec(`UPDATE customer_services SET channel = ?, account = ?, qr_url = ?, enabled = ?, sort_order = ? WHERE id = ?`,
		channel, account, qr, enabled, sort, id)
	return id, err
}

func (s *Store) ListNotices(activeOnly bool, now int64) ([]map[string]any, error) {
	query := `SELECT id, title, body, enabled, created_at, notice_type, starts_at, ends_at FROM announcements`
	if activeOnly {
		query += ` WHERE enabled = 1 AND (starts_at = 0 OR starts_at <= ?) AND (ends_at = 0 OR ends_at >= ?)`
	}
	query += ` ORDER BY id DESC`
	var rows *sql.Rows
	var err error
	if activeOnly {
		rows, err = s.db.Query(query, now, now)
	} else {
		rows, err = s.db.Query(query)
	}
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	return scanMaps(rows, []string{"id", "title", "body", "enabled", "createdAt", "noticeType", "startsAt", "endsAt"})
}

func (s *Store) SaveNotice(id int64, title, body, kind string, enabled int, starts, ends, now int64) (int64, error) {
	if kind == "" {
		kind = "notice"
	}
	if id == 0 {
		err := s.db.QueryRow(`INSERT INTO announcements (title, body, enabled, created_at, notice_type, starts_at, ends_at)
			VALUES (?, ?, ?, ?, ?, ?, ?) RETURNING id`, title, body, enabled, now, kind, starts, ends).Scan(&id)
		return id, err
	}
	_, err := s.db.Exec(`UPDATE announcements SET title = ?, body = ?, enabled = ?, notice_type = ?, starts_at = ?, ends_at = ? WHERE id = ?`,
		title, body, enabled, kind, starts, ends, id)
	return id, err
}

func (s *Store) CreateMemberTicket(userID int64, title, body string, now int64) (int64, error) {
	var id int64
	err := s.db.QueryRow(`INSERT INTO support_tickets (user_id, title, body, status, reply, created_at, updated_at) VALUES (?, ?, ?, 0, '', ?, ?) RETURNING id`,
		userID, title, body, now, now).Scan(&id)
	return id, err
}

func (s *Store) ListMemberTickets(userID int64) ([]map[string]any, error) {
	query := `SELECT t.id, t.user_id, u.username, t.title, t.body, t.status, t.reply, t.created_at, t.updated_at
		FROM support_tickets t JOIN users u ON u.id = t.user_id`
	var args []any
	if userID > 0 {
		query += ` WHERE t.user_id = ?`
		args = append(args, userID)
	}
	query += ` ORDER BY t.id DESC LIMIT 200`
	rows, err := s.db.Query(query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	return scanMaps(rows, []string{"id", "userId", "username", "title", "body", "status", "reply", "createdAt", "updatedAt"})
}

func (s *Store) ReplyTicket(id int64, reply string, close bool, now int64) error {
	status := 1
	if close {
		status = 2
	}
	res, err := s.db.Exec(`UPDATE support_tickets SET reply = ?, status = ?, updated_at = ? WHERE id = ?`, reply, status, now, id)
	if err != nil {
		return err
	}
	n, _ := res.RowsAffected()
	if n == 0 {
		return errs.New(404, "NOT_FOUND", "工单不存在")
	}
	return nil
}

func scanMaps(rows *sql.Rows, keys []string) ([]map[string]any, error) {
	var list []map[string]any
	for rows.Next() {
		vals := make([]any, len(keys))
		ptrs := make([]any, len(keys))
		for i := range vals {
			ptrs[i] = &vals[i]
		}
		if err := rows.Scan(ptrs...); err != nil {
			return nil, err
		}
		item := map[string]any{}
		for i, key := range keys {
			item[key] = normalizeSQL(vals[i])
		}
		list = append(list, item)
	}
	if list == nil {
		list = []map[string]any{}
	}
	return list, rows.Err()
}

func normalizeSQL(v any) any {
	switch n := v.(type) {
	case []byte:
		return string(n)
	default:
		return v
	}
}
