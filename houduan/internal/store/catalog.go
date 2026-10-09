package store

import (
	"database/sql"
	"encoding/json"
	"strconv"
	"time"

	"xvay/houduan/internal/auth"
	"xvay/houduan/internal/errs"
)

var catalogKinds = map[string]bool{
	"groups": true, "cores": true, "assets": true, "plans": true,
	"agents": true, "commissionRules": true, "commissions": true,
	"admins": true, "appSettings": true,
}

func ValidCatalogKind(kind string) bool {
	return catalogKinds[kind]
}

func (s *Store) ListCatalog(kind string) ([]map[string]any, error) {
	rows, err := s.db.Query(`SELECT id, body FROM catalog WHERE kind = ? ORDER BY id`, kind)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	list := []map[string]any{}
	for rows.Next() {
		var id int64
		var body string
		if err := rows.Scan(&id, &body); err != nil {
			return nil, err
		}
		item, err := decodeCatalog(id, body)
		if err != nil {
			return nil, err
		}
		list = append(list, item)
	}
	return list, rows.Err()
}

func (s *Store) GetCatalog(kind string, id int64) (map[string]any, bool, error) {
	var body string
	err := s.db.QueryRow(`SELECT body FROM catalog WHERE kind = ? AND id = ?`, kind, id).Scan(&body)
	if err == sql.ErrNoRows {
		return nil, false, nil
	}
	if err != nil {
		return nil, false, err
	}
	item, err := decodeCatalog(id, body)
	if err != nil {
		return nil, false, err
	}
	return item, true, nil
}

func (s *Store) GetSingleton(kind string) (map[string]any, bool, error) {
	return s.GetCatalog(kind, 1)
}

func (s *Store) PutSingleton(kind string, body map[string]any) (map[string]any, error) {
	cloned := cloneMap(body)
	delete(cloned, "id")
	raw, err := json.Marshal(cloned)
	if err != nil {
		return nil, err
	}
	_, err = s.db.Exec(
		`INSERT INTO catalog (kind, id, body) VALUES (?, 1, ?)
		 ON CONFLICT(kind, id) DO UPDATE SET body = excluded.body`,
		kind, string(raw),
	)
	if err != nil {
		return nil, err
	}
	cloned["id"] = int64(1)
	return cloned, nil
}

func (s *Store) InsertCatalog(kind string, body map[string]any) (map[string]any, error) {
	if !catalogKinds[kind] || kind == "appSettings" {
		return nil, errs.New(400, "VALIDATION", "不支持的数据类型")
	}
	cloned := cloneMap(body)
	id := int64(0)
	if raw, ok := cloned["id"]; ok {
		id = AsInt64(raw)
	}
	delete(cloned, "id")
	delete(cloned, "password")
	if id <= 0 {
		if err := s.db.QueryRow(`SELECT COALESCE(MAX(id), 0) + 1 FROM catalog WHERE kind = ?`, kind).Scan(&id); err != nil {
			return nil, err
		}
	}
	raw, err := json.Marshal(cloned)
	if err != nil {
		return nil, err
	}
	_, err = s.db.Exec(`INSERT INTO catalog (kind, id, body) VALUES (?, ?, ?)`, kind, id, string(raw))
	if errs.IsUnique(err) {
		return nil, errs.New(409, "CONFLICT", "记录已存在")
	}
	if err != nil {
		return nil, err
	}
	cloned["id"] = id
	return cloned, nil
}

func (s *Store) UpdateCatalog(kind string, id int64, patch map[string]any) (map[string]any, error) {
	current, ok, err := s.GetCatalog(kind, id)
	if err != nil {
		return nil, err
	}
	if !ok {
		return nil, errs.New(404, "NOT_FOUND", "记录不存在")
	}
	for key, value := range patch {
		if key == "id" || key == "password" || key == "passwordHash" {
			continue
		}
		current[key] = value
	}
	delete(current, "id")
	raw, err := json.Marshal(current)
	if err != nil {
		return nil, err
	}
	_, err = s.db.Exec(`UPDATE catalog SET body = ? WHERE kind = ? AND id = ?`, string(raw), kind, id)
	if err != nil {
		return nil, err
	}
	current["id"] = id
	return current, nil
}

func (s *Store) DeleteCatalog(kind string, id int64) error {
	res, err := s.db.Exec(`DELETE FROM catalog WHERE kind = ? AND id = ?`, kind, id)
	if err != nil {
		return err
	}
	n, err := res.RowsAffected()
	if err != nil {
		return err
	}
	if n == 0 {
		return errs.New(404, "NOT_FOUND", "记录不存在")
	}
	return nil
}

func (s *Store) DeleteCatalogKind(kind string) error {
	_, err := s.db.Exec(`DELETE FROM catalog WHERE kind = ?`, kind)
	return err
}

func (s *Store) CreateAdminSession(adminID int64, ttl time.Duration) (string, error) {
	token, err := auth.NewToken(24)
	if err != nil {
		return "", err
	}
	now := time.Now().UnixMilli()
	_, err = s.db.Exec(
		`INSERT INTO admin_sessions (token_hash, admin_id, created_at, expires_at) VALUES (?, ?, ?, ?)`,
		auth.HashToken(token), adminID, now, now+ttl.Milliseconds(),
	)
	if err != nil {
		return "", err
	}
	return token, nil
}

func (s *Store) AdminSessionValid(token string, now int64) (bool, error) {
	_, ok, err := s.AdminSessionAdminID(token, now)
	return ok, err
}

func (s *Store) AdminSessionAdminID(token string, now int64) (int64, bool, error) {
	if token == "" {
		return 0, false, nil
	}
	var id int64
	err := s.db.QueryRow(
		`SELECT admin_id FROM admin_sessions WHERE token_hash = ? AND expires_at > ?`,
		auth.HashToken(token), now,
	).Scan(&id)
	if err == sql.ErrNoRows {
		return 0, false, nil
	}
	if err != nil {
		return 0, false, err
	}
	return id, true, nil
}

func (s *Store) ClearAdminSessions() error {
	_, err := s.db.Exec(`DELETE FROM admin_sessions`)
	return err
}

func PublicAdmin(item map[string]any) map[string]any {
	out := cloneMap(item)
	delete(out, "password")
	delete(out, "passwordHash")
	return out
}

func decodeCatalog(id int64, body string) (map[string]any, error) {
	item := map[string]any{}
	if body != "" {
		if err := json.Unmarshal([]byte(body), &item); err != nil {
			return nil, err
		}
	}
	item["id"] = id
	return item, nil
}

func cloneMap(in map[string]any) map[string]any {
	out := make(map[string]any, len(in))
	for key, value := range in {
		out[key] = value
	}
	return out
}

func AsInt64(value any) int64 {
	switch n := value.(type) {
	case int64:
		return n
	case int:
		return int64(n)
	case float64:
		return int64(n)
	case json.Number:
		i, err := n.Int64()
		if err == nil {
			return i
		}
		f, err := n.Float64()
		if err == nil {
			return int64(f)
		}
	case string:
		i, err := strconv.ParseInt(n, 10, 64)
		if err == nil {
			return i
		}
	}
	return 0
}

func AsFloat(value any) float64 {
	switch n := value.(type) {
	case float64:
		return n
	case int64:
		return float64(n)
	case int:
		return float64(n)
	case json.Number:
		f, err := n.Float64()
		if err == nil {
			return f
		}
	case string:
		f, err := strconv.ParseFloat(n, 64)
		if err == nil {
			return f
		}
	}
	return 0
}

func AsString(value any) string {
	text, _ := value.(string)
	return text
}
