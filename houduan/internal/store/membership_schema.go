package store

import (
	"crypto/rand"
	"database/sql"
	"embed"
	"fmt"
	"strings"
)

//go:embed membership.sql
var membershipSQL embed.FS

var userColumnDDL = []struct{ name, ddl string }{
	{"username", "TEXT NOT NULL DEFAULT ''"},
	{"avatar", "TEXT NOT NULL DEFAULT ''"},
	{"phone", "TEXT NOT NULL DEFAULT ''"},
	{"bind_email", "TEXT NOT NULL DEFAULT ''"},
	{"email_verified_at", "INTEGER NOT NULL DEFAULT 0"},
	{"email_bind_at", "INTEGER NOT NULL DEFAULT 0"},
	{"email_status", "INTEGER NOT NULL DEFAULT 0"},
	{"is_distributor", "INTEGER NOT NULL DEFAULT 0"},
	{"is_agent", "INTEGER NOT NULL DEFAULT 0"},
	{"commission_mode", "INTEGER NOT NULL DEFAULT 0"},
	{"wallet_enabled", "INTEGER NOT NULL DEFAULT 0"},
	{"can_authorize_agent", "INTEGER NOT NULL DEFAULT 0"},
	{"parent_id", "INTEGER NOT NULL DEFAULT 0"},
	{"distributor_id", "INTEGER NOT NULL DEFAULT 0"},
	{"relation_path", "TEXT NOT NULL DEFAULT ''"},
	{"member_status", "INTEGER NOT NULL DEFAULT 0"},
	{"banned_at", "INTEGER NOT NULL DEFAULT 0"},
	{"ban_reason", "TEXT NOT NULL DEFAULT ''"},
	{"invite_code", "TEXT NOT NULL DEFAULT ''"},
}

func (s *Store) migrateMembership() error {
	if err := s.addColumns("users", userColumnDDL); err != nil {
		return err
	}
	if err := s.addColumns("announcements", []struct{ name, ddl string }{
		{"notice_type", "TEXT NOT NULL DEFAULT 'notice'"},
		{"starts_at", "INTEGER NOT NULL DEFAULT 0"},
		{"ends_at", "INTEGER NOT NULL DEFAULT 0"},
	}); err != nil {
		return err
	}
	script, err := membershipSQL.ReadFile("membership.sql")
	if err != nil {
		return err
	}
	if err := execScript(s.db, string(script)); err != nil {
		return err
	}
	if _, err := s.db.Exec(`UPDATE users SET username = email WHERE username = ''`); err != nil {
		return err
	}
	if _, err := s.db.Exec(`UPDATE users SET wallet_enabled = 1, commission_mode = 0
		WHERE distributor_id = 0 AND is_distributor = 0 AND is_agent = 0 AND parent_id = 0 AND wallet_enabled = 0`); err != nil {
		return err
	}
	if err := s.ensureInviteCodes(); err != nil {
		return err
	}
	for _, stmt := range []string{
		`CREATE UNIQUE INDEX IF NOT EXISTS idx_users_username ON users(username) WHERE username <> ''`,
		`CREATE UNIQUE INDEX IF NOT EXISTS idx_users_bind_email ON users(bind_email) WHERE bind_email <> ''`,
		`CREATE UNIQUE INDEX IF NOT EXISTS idx_users_invite ON users(invite_code) WHERE invite_code <> ''`,
	} {
		if _, err := s.db.Exec(stmt); err != nil {
			return err
		}
	}
	return nil
}

func (s *Store) addColumns(table string, cols []struct{ name, ddl string }) error {
	have, err := tableColumns(s.db, table)
	if err != nil {
		return err
	}
	for _, col := range cols {
		if have[col.name] {
			continue
		}
		if _, err := s.db.Exec(`ALTER TABLE ` + table + ` ADD COLUMN ` + col.name + ` ` + col.ddl); err != nil {
			return err
		}
	}
	return nil
}

func tableColumns(db *sql.DB, table string) (map[string]bool, error) {
	rows, err := db.Query(`PRAGMA table_info(` + table + `)`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := map[string]bool{}
	for rows.Next() {
		var cid int
		var name, typ string
		var notNull, pk int
		var dflt sql.NullString
		if err := rows.Scan(&cid, &name, &typ, &notNull, &dflt, &pk); err != nil {
			return nil, err
		}
		out[name] = true
	}
	return out, rows.Err()
}

func execScript(db *sql.DB, script string) error {
	for _, part := range strings.Split(script, ";") {
		stmt := stripSQLComments(part)
		if stmt == "" {
			continue
		}
		if _, err := db.Exec(stmt); err != nil {
			return fmt.Errorf("sql: %w", err)
		}
	}
	return nil
}

func stripSQLComments(stmt string) string {
	var b strings.Builder
	for _, line := range strings.Split(stmt, "\n") {
		if strings.HasPrefix(strings.TrimSpace(line), "--") {
			continue
		}
		b.WriteString(line)
		b.WriteByte('\n')
	}
	return strings.TrimSpace(b.String())
}

func (s *Store) ensureInviteCodes() error {
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
	for _, id := range ids {
		code, err := uniqueInvite(s.db)
		if err != nil {
			return err
		}
		if _, err := s.db.Exec(`UPDATE users SET invite_code = ? WHERE id = ? AND invite_code = ''`, code, id); err != nil {
			return err
		}
	}
	return nil
}

func uniqueInvite(db *sql.DB) (string, error) {
	for range 8 {
		code, err := randomAlphabet(8)
		if err != nil {
			return "", err
		}
		var n int
		if err := db.QueryRow(`SELECT COUNT(*) FROM users WHERE invite_code = ?`, code).Scan(&n); err != nil {
			return "", err
		}
		if n == 0 {
			return code, nil
		}
	}
	return "", fmt.Errorf("邀请码生成失败")
}

func randomAlphabet(n int) (string, error) {
	const alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
	buf := make([]byte, n)
	if _, err := rand.Read(buf); err != nil {
		return "", err
	}
	out := make([]byte, n)
	for i, b := range buf {
		out[i] = alphabet[int(b)%len(alphabet)]
	}
	return string(out), nil
}

func randomDigits(n int) (string, error) {
	buf := make([]byte, n)
	if _, err := rand.Read(buf); err != nil {
		return "", err
	}
	out := make([]byte, n)
	for i, b := range buf {
		out[i] = '0' + b%10
	}
	return string(out), nil
}
