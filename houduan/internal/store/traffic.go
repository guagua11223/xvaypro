package store

import (
	"database/sql"
	"regexp"
	"strconv"
	"time"

	"xvay/houduan/internal/access"
	"xvay/houduan/internal/errs"
)

func nowMillis() int64 { return time.Now().UnixMilli() }

var taggedEmail = regexp.MustCompile(`^u(\d+)$`)

func (s *Store) ApplyTraffic(nodeID int64, entries []TrafficEntry, mode string) (TrafficResult, error) {
	result := TrafficResult{Updated: []TrafficRow{}, Unknown: []any{}}
	err := s.tx(func(tx *sql.Tx) error {
		for _, entry := range entries {
			user, ok, err := resolveTrafficUser(tx, entry)
			if err != nil {
				return err
			}
			if !ok {
				result.Unknown = append(result.Unknown, unknownID(entry))
				continue
			}
			if entry.Upload < 0 || entry.Download < 0 {
				return errs.New(400, "VALIDATION", "流量计数必须是非负整数")
			}
			uploadDelta, downloadDelta := entry.Upload, entry.Download
			if mode == "absolute" {
				var lastUp, lastDown int64
				err := tx.QueryRow(
					`SELECT last_upload, last_download FROM node_counters WHERE node_id = ? AND user_id = ?`,
					nodeID, user.ID,
				).Scan(&lastUp, &lastDown)
				var prevUp, prevDown *int64
				if err == nil {
					prevUp, prevDown = &lastUp, &lastDown
				} else if err != sql.ErrNoRows {
					return err
				}
				uploadDelta = access.AbsoluteDelta(prevUp, entry.Upload)
				downloadDelta = access.AbsoluteDelta(prevDown, entry.Download)
				if _, err := tx.Exec(
					`INSERT INTO node_counters (node_id, user_id, last_upload, last_download)
					 VALUES (?, ?, ?, ?)
					 ON CONFLICT(node_id, user_id) DO UPDATE SET
					   last_upload = excluded.last_upload,
					   last_download = excluded.last_download`,
					nodeID, user.ID, entry.Upload, entry.Download,
				); err != nil {
					return err
				}
			}
			var row TrafficRow
			if err := tx.QueryRow(
				`UPDATE users SET upload = upload + ?, download = download + ?
				 WHERE id = ? RETURNING id, email, upload, download, total`,
				uploadDelta, downloadDelta, user.ID,
			).Scan(&row.ID, &row.Email, &row.Upload, &row.Download, &row.Total); err != nil {
				return err
			}
			result.Updated = append(result.Updated, row)
		}
		return nil
	})
	return result, err
}

func resolveTrafficUser(tx *sql.Tx, entry TrafficEntry) (User, bool, error) {
	switch {
	case entry.UUID != "":
		user, err := scanUser(tx.QueryRow(`SELECT `+userCols+` FROM users WHERE uuid = ?`, entry.UUID))
		return optionalUser(user, err)
	case entry.UserID != nil:
		user, err := scanUser(tx.QueryRow(`SELECT `+userCols+` FROM users WHERE id = ?`, *entry.UserID))
		return optionalUser(user, err)
	case entry.Email != "":
		if match := taggedEmail.FindStringSubmatch(entry.Email); match != nil {
			id, _ := strconv.ParseInt(match[1], 10, 64)
			user, err := scanUser(tx.QueryRow(`SELECT `+userCols+` FROM users WHERE id = ?`, id))
			return optionalUser(user, err)
		}
		user, err := scanUser(tx.QueryRow(`SELECT `+userCols+` FROM users WHERE email = ?`, entry.Email))
		return optionalUser(user, err)
	default:
		return User{}, false, nil
	}
}

func unknownID(entry TrafficEntry) any {
	if entry.UUID != "" {
		return entry.UUID
	}
	if entry.UserID != nil {
		return *entry.UserID
	}
	if entry.Email != "" {
		return entry.Email
	}
	return nil
}

func (s *Store) TrafficSummary() (upload, download int64, err error) {
	err = s.db.QueryRow(
		`SELECT COALESCE(SUM(upload), 0), COALESCE(SUM(download), 0) FROM users`,
	).Scan(&upload, &download)
	return upload, download, err
}

func (s *Store) GetSettings() (map[string]string, error) {
	rows, err := s.db.Query(`SELECT key, value FROM settings`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	settings := map[string]string{}
	for rows.Next() {
		var key, value string
		if err := rows.Scan(&key, &value); err != nil {
			return nil, err
		}
		settings[key] = value
	}
	return settings, rows.Err()
}

func (s *Store) SetSettings(patch map[string]string) (map[string]string, error) {
	allowed := map[string]bool{
		"profile_name": true, "support_url": true, "profile_web_page_url": true,
		"auto_update_interval": true, "trial_bytes": true, "trial_days": true,
	}
	err := s.tx(func(tx *sql.Tx) error {
		for key, value := range patch {
			if !allowed[key] {
				return errs.New(400, "VALIDATION", "不支持的设置项 "+key)
			}
			if _, err := tx.Exec(
				`INSERT INTO settings (key, value) VALUES (?, ?)
				 ON CONFLICT(key) DO UPDATE SET value = excluded.value`, key, value,
			); err != nil {
				return err
			}
		}
		return nil
	})
	if err != nil {
		return nil, err
	}
	return s.GetSettings()
}

func (s *Store) ListAnnouncements(enabledOnly bool) ([]Announcement, error) {
	query := `SELECT id, title, body, enabled, created_at FROM announcements ORDER BY id DESC`
	if enabledOnly {
		query = `SELECT id, title, body, enabled, created_at FROM announcements WHERE enabled = 1 ORDER BY id DESC`
	}
	rows, err := s.db.Query(query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var list []Announcement
	for rows.Next() {
		var row Announcement
		if err := rows.Scan(&row.ID, &row.Title, &row.Body, &row.Enabled, &row.CreatedAt); err != nil {
			return nil, err
		}
		list = append(list, row)
	}
	if list == nil {
		list = []Announcement{}
	}
	return list, rows.Err()
}

func (s *Store) CreateAnnouncement(title, body string, enabled bool) (Announcement, error) {
	var row Announcement
	err := s.db.QueryRow(
		`INSERT INTO announcements (title, body, enabled, created_at) VALUES (?, ?, ?, ?)
		 RETURNING id, title, body, enabled, created_at`,
		title, body, bit(enabled), nowMillis(),
	).Scan(&row.ID, &row.Title, &row.Body, &row.Enabled, &row.CreatedAt)
	return row, err
}

func (s *Store) UpdateAnnouncement(id int64, title, body *string, enabled *bool) (Announcement, error) {
	var current Announcement
	err := s.db.QueryRow(
		`SELECT id, title, body, enabled, created_at FROM announcements WHERE id = ?`, id,
	).Scan(&current.ID, &current.Title, &current.Body, &current.Enabled, &current.CreatedAt)
	if err == sql.ErrNoRows {
		return Announcement{}, errs.New(404, "NOT_FOUND", "公告不存在")
	}
	if err != nil {
		return Announcement{}, err
	}
	if title != nil {
		current.Title = *title
	}
	if body != nil {
		current.Body = *body
	}
	if enabled != nil {
		current.Enabled = bit(*enabled)
	}
	var row Announcement
	err = s.db.QueryRow(
		`UPDATE announcements SET title = ?, body = ?, enabled = ? WHERE id = ?
		 RETURNING id, title, body, enabled, created_at`,
		current.Title, current.Body, current.Enabled, id,
	).Scan(&row.ID, &row.Title, &row.Body, &row.Enabled, &row.CreatedAt)
	return row, err
}

func (s *Store) DeleteAnnouncement(id int64) error {
	res, err := s.db.Exec(`DELETE FROM announcements WHERE id = ?`, id)
	if err != nil {
		return err
	}
	n, err := res.RowsAffected()
	if err != nil {
		return err
	}
	if n == 0 {
		return errs.New(404, "NOT_FOUND", "公告不存在")
	}
	return nil
}
