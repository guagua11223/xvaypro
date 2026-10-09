package store

import (
	"database/sql"
	"strings"
	"testing"

	_ "modernc.org/sqlite"
)

func TestLegacyUserMigration(t *testing.T) {
	name := strings.ReplaceAll(t.Name(), "/", "_")
	db, err := sql.Open("sqlite", "file:"+name+"?mode=memory&cache=shared&_pragma=busy_timeout(5000)&_pragma=foreign_keys(1)")
	if err != nil {
		t.Fatal(err)
	}
	db.SetMaxOpenConns(1)
	t.Cleanup(func() { db.Close() })
	if _, err := db.Exec(`
		CREATE TABLE users (
		  id INTEGER PRIMARY KEY AUTOINCREMENT,
		  email TEXT NOT NULL UNIQUE,
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
		  created_at INTEGER NOT NULL
		)`); err != nil {
		t.Fatal(err)
	}
	if _, err := db.Exec(
		`INSERT INTO users (
			email, password_hash, uuid, hy2_password, sub_token, created_at
		) VALUES ('legacy@example.com', 'hash', 'uuid-1', 'hy2', 'sub', 10)`,
	); err != nil {
		t.Fatal(err)
	}
	store := &Store{db: db}
	if _, err := db.Exec(schema); err != nil {
		t.Fatal(err)
	}
	if _, err := db.Exec(
		`INSERT INTO sessions (token_hash, user_id, created_at, expires_at) VALUES ('sess', 1, 10, 9999999999999)`,
	); err != nil {
		t.Fatal(err)
	}
	if err := store.migrate(); err != nil {
		t.Fatal(err)
	}
	user, ok, err := store.FindUserByUsername("legacy@example.com")
	if err != nil || !ok || user.Email != "legacy@example.com" || user.UserType != "member" {
		t.Fatalf("migrated user: %+v ok=%v err=%v", user, ok, err)
	}
	var sessions int
	if err := db.QueryRow(`SELECT COUNT(*) FROM sessions`).Scan(&sessions); err != nil || sessions != 1 {
		t.Fatalf("sessions %d %v", sessions, err)
	}
}
