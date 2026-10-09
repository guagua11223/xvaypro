package store

import (
	"database/sql"
	"fmt"
)

type columnMeta struct {
	notNull bool
}

func (s *Store) migrate() error {
	if _, err := s.db.Exec(`PRAGMA foreign_keys = OFF`); err != nil {
		return err
	}
	defer s.db.Exec(`PRAGMA foreign_keys = ON`)
	if err := s.migrateUsers(); err != nil {
		return err
	}
	_, err := s.db.Exec(`PRAGMA foreign_keys = ON`)
	return err
}

func (s *Store) migrateUsers() error {
	info, err := s.userColumns()
	if err != nil {
		return err
	}
	_, hasUsername := info["username"]
	if hasUsername && !info["email"].notNull {
		if err := s.ensureUserColumns(info); err != nil {
			return err
		}
	} else if err := s.rebuildUsers(info); err != nil {
		return err
	}
	info, err = s.userColumns()
	if err != nil {
		return err
	}
	if err := s.ensureUserColumns(info); err != nil {
		return err
	}
	if err := s.migrateOrders(); err != nil {
		return err
	}
	_, err = s.db.Exec(`CREATE UNIQUE INDEX IF NOT EXISTS idx_users_invite ON users(invite_code) WHERE invite_code != ''`)
	if err != nil {
		return err
	}
	return s.backfillInvites()
}

func (s *Store) userColumns() (map[string]columnMeta, error) {
	rows, err := s.db.Query(`PRAGMA table_info(users)`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	info := map[string]columnMeta{}
	for rows.Next() {
		var cid, notNull, pk int
		var name, colType string
		var dflt any
		if err := rows.Scan(&cid, &name, &colType, &notNull, &dflt, &pk); err != nil {
			return nil, err
		}
		info[name] = columnMeta{notNull: notNull == 1}
	}
	return info, rows.Err()
}

func (s *Store) ensureUserColumns(info map[string]columnMeta) error {
	missing := []struct {
		name string
		ddl  string
	}{
		{"nickname", `ALTER TABLE users ADD COLUMN nickname TEXT NOT NULL DEFAULT ''`},
		{"avatar", `ALTER TABLE users ADD COLUMN avatar TEXT NOT NULL DEFAULT ''`},
		{"user_type", `ALTER TABLE users ADD COLUMN user_type TEXT NOT NULL DEFAULT 'member'`},
		{"referrer_id", `ALTER TABLE users ADD COLUMN referrer_id INTEGER NOT NULL DEFAULT 0`},
		{"distributor_id", `ALTER TABLE users ADD COLUMN distributor_id INTEGER NOT NULL DEFAULT 0`},
		{"is_distributor", `ALTER TABLE users ADD COLUMN is_distributor INTEGER NOT NULL DEFAULT 0`},
		{"is_agent", `ALTER TABLE users ADD COLUMN is_agent INTEGER NOT NULL DEFAULT 0`},
		{"commission_mode", `ALTER TABLE users ADD COLUMN commission_mode INTEGER NOT NULL DEFAULT 0`},
		{"wallet_enabled", `ALTER TABLE users ADD COLUMN wallet_enabled INTEGER NOT NULL DEFAULT 1`},
		{"can_authorize_agent", `ALTER TABLE users ADD COLUMN can_authorize_agent INTEGER NOT NULL DEFAULT 0`},
		{"email_status", `ALTER TABLE users ADD COLUMN email_status INTEGER NOT NULL DEFAULT 0`},
		{"invite_code", `ALTER TABLE users ADD COLUMN invite_code TEXT NOT NULL DEFAULT ''`},
		{"distributor_rate", `ALTER TABLE users ADD COLUMN distributor_rate INTEGER NOT NULL DEFAULT 0`},
		{"member_rate", `ALTER TABLE users ADD COLUMN member_rate INTEGER NOT NULL DEFAULT -1`},
	}
	for _, col := range missing {
		if _, ok := info[col.name]; ok {
			continue
		}
		if _, err := s.db.Exec(col.ddl); err != nil {
			return err
		}
	}
	return nil
}

func (s *Store) rebuildUsers(info map[string]columnMeta) error {
	usernameExpr := "email"
	if _, ok := info["username"]; ok {
		usernameExpr = "CASE WHEN username IS NULL OR username = '' THEN email ELSE username END"
	}
	nicknameExpr := "''"
	if _, ok := info["nickname"]; ok {
		nicknameExpr = "COALESCE(nickname, '')"
	}
	avatarExpr := "''"
	if _, ok := info["avatar"]; ok {
		avatarExpr = "COALESCE(avatar, '')"
	}
	typeExpr := "'member'"
	if _, ok := info["user_type"]; ok {
		typeExpr = "COALESCE(NULLIF(user_type, ''), 'member')"
	}
	insert := fmt.Sprintf(`
		INSERT INTO users_new (
			id, username, email, password_hash, uuid, hy2_password, sub_token,
			upload, download, total, expire_at, status, device_limit, created_at,
			nickname, avatar, user_type
		)
		SELECT
			id, %s, NULLIF(email, ''), password_hash, uuid, hy2_password, sub_token,
			upload, download, total, expire_at, status, device_limit, created_at,
			%s, %s, %s
		FROM users`, usernameExpr, nicknameExpr, avatarExpr, typeExpr)
	return s.tx(func(tx *sql.Tx) error {
		if _, err := tx.Exec(`DROP TABLE IF EXISTS users_new`); err != nil {
			return err
		}
		if _, err := tx.Exec(`
			CREATE TABLE users_new (
			  id INTEGER PRIMARY KEY AUTOINCREMENT,
			  username TEXT NOT NULL UNIQUE,
			  email TEXT UNIQUE,
			  password_hash TEXT NOT NULL,
			  uuid TEXT NOT NULL UNIQUE,
			  hy2_password TEXT NOT NULL,
			  sub_token TEXT NOT NULL UNIQUE,
			  upload INTEGER NOT NULL DEFAULT 0,
			  download INTEGER NOT NULL DEFAULT 0,
			  total INTEGER NOT NULL DEFAULT 0,
			  expire_at INTEGER NOT NULL DEFAULT 0,
			  status TEXT NOT NULL DEFAULT 'active',
			  device_limit INTEGER NOT NULL DEFAULT 3,
			  created_at INTEGER NOT NULL,
			  nickname TEXT NOT NULL DEFAULT '',
			  avatar TEXT NOT NULL DEFAULT '',
			  user_type TEXT NOT NULL DEFAULT 'member'
			)`); err != nil {
			return err
		}
		if _, err := tx.Exec(insert); err != nil {
			return err
		}
		if _, err := tx.Exec(`DROP TABLE users`); err != nil {
			return err
		}
		_, err := tx.Exec(`ALTER TABLE users_new RENAME TO users`)
		return err
	})
}

func (s *Store) migrateOrders() error {
	rows, err := s.db.Query(`PRAGMA table_info(orders)`)
	if err != nil {
		return err
	}
	defer rows.Close()
	have := map[string]bool{}
	for rows.Next() {
		var cid, notNull, pk int
		var name, colType string
		var dflt any
		if err := rows.Scan(&cid, &name, &colType, &notNull, &dflt, &pk); err != nil {
			return err
		}
		have[name] = true
	}
	if err := rows.Err(); err != nil {
		return err
	}
	missing := []struct{ name, ddl string }{
		{"plan_code", `ALTER TABLE orders ADD COLUMN plan_code TEXT NOT NULL DEFAULT ''`},
		{"traffic_bytes", `ALTER TABLE orders ADD COLUMN traffic_bytes INTEGER NOT NULL DEFAULT 0`},
		{"duration_ms", `ALTER TABLE orders ADD COLUMN duration_ms INTEGER NOT NULL DEFAULT 0`},
		{"renew", `ALTER TABLE orders ADD COLUMN renew INTEGER NOT NULL DEFAULT 0`},
	}
	for _, col := range missing {
		if have[col.name] {
			continue
		}
		if _, err := s.db.Exec(col.ddl); err != nil {
			return err
		}
	}
	return nil
}

func (s *Store) backfillInvites() error {
	if _, err := s.db.Exec(`UPDATE users SET email_status = 2 WHERE email IS NOT NULL AND email != '' AND email_status = 0`); err != nil {
		return err
	}
	rows, err := s.db.Query(`SELECT id FROM users WHERE invite_code = ''`)
	if err != nil {
		return err
	}
	defer rows.Close()
	var ids []int64
	for rows.Next() {
		var id int64
		if err := rows.Scan(&id); err != nil {
			return err
		}
		ids = append(ids, id)
	}
	if err := rows.Err(); err != nil {
		return err
	}
	if err := rows.Close(); err != nil {
		return err
	}
	for _, id := range ids {
		code, err := s.uniqueInviteCode()
		if err != nil {
			return err
		}
		if _, err := s.db.Exec(`UPDATE users SET invite_code = ? WHERE id = ? AND invite_code = ''`, code, id); err != nil {
			return err
		}
	}
	return nil
}
