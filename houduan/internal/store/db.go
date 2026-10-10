package store

import (
	"database/sql"
	"fmt"
	"net/url"
	"os"
	"path/filepath"
	"strings"
	"sync/atomic"

	"xvay/houduan/internal/config"

	_ "modernc.org/sqlite"
)

var memorySeq atomic.Int64

const schema = `
PRAGMA foreign_keys = ON;
PRAGMA busy_timeout = 5000;

CREATE TABLE IF NOT EXISTS users (
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
);

CREATE TABLE IF NOT EXISTS sessions (
  token_hash TEXT PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at INTEGER NOT NULL,
  expires_at INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_sessions_user ON sessions(user_id);

CREATE TABLE IF NOT EXISTS nodes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  region TEXT NOT NULL DEFAULT '',
  country_code TEXT NOT NULL DEFAULT '',
  host TEXT NOT NULL,
  sort_order INTEGER NOT NULL DEFAULT 0,
  enabled INTEGER NOT NULL DEFAULT 1,
  remark TEXT NOT NULL DEFAULT '',
  secret TEXT NOT NULL,
  xray_enabled INTEGER NOT NULL DEFAULT 1,
  xray_port INTEGER NOT NULL DEFAULT 443,
  xray_api_port INTEGER NOT NULL DEFAULT 10085,
  reality_private_key TEXT NOT NULL,
  reality_public_key TEXT NOT NULL,
  reality_short_ids TEXT NOT NULL,
  reality_sni TEXT NOT NULL,
  reality_dest TEXT NOT NULL,
  reality_spider_x TEXT NOT NULL DEFAULT '/',
  reality_fingerprint TEXT NOT NULL DEFAULT 'chrome',
  reality_flow TEXT NOT NULL DEFAULT 'xtls-rprx-vision',
  hy2_enabled INTEGER NOT NULL DEFAULT 1,
  hy2_port INTEGER NOT NULL DEFAULT 8443,
  hy2_sni TEXT NOT NULL,
  hy2_insecure INTEGER NOT NULL DEFAULT 0,
  hy2_obfs_password TEXT NOT NULL DEFAULT '',
  hy2_up_mbps INTEGER NOT NULL DEFAULT 100,
  hy2_down_mbps INTEGER NOT NULL DEFAULT 100,
  hy2_cert_path TEXT NOT NULL DEFAULT '',
  hy2_key_path TEXT NOT NULL DEFAULT '',
  hy2_masquerade TEXT NOT NULL DEFAULT '',
  hy2_stats_secret TEXT NOT NULL DEFAULT '',
  last_seen_at INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS node_counters (
  node_id INTEGER NOT NULL REFERENCES nodes(id) ON DELETE CASCADE,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  last_upload INTEGER NOT NULL DEFAULT 0,
  last_download INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (node_id, user_id)
);

CREATE TABLE IF NOT EXISTS announcements (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  enabled INTEGER NOT NULL DEFAULT 1,
  created_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS connect_sessions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  device_id TEXT NOT NULL,
  node_id INTEGER NOT NULL,
  protocol TEXT NOT NULL,
  started_at INTEGER NOT NULL,
  stopped_at INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX IF NOT EXISTS idx_connect_user ON connect_sessions(user_id, stopped_at);

CREATE TABLE IF NOT EXISTS user_profiles (
  user_id INTEGER PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  display_name TEXT NOT NULL DEFAULT '',
  phone TEXT NOT NULL DEFAULT '',
  plan_id INTEGER NOT NULL DEFAULT 0,
  agent_id INTEGER NOT NULL DEFAULT 0,
  device TEXT NOT NULL DEFAULT '',
  platform TEXT NOT NULL DEFAULT '',
  region TEXT NOT NULL DEFAULT '',
  last_login_at INTEGER NOT NULL DEFAULT 0,
  demo INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS node_meta (
  node_id INTEGER PRIMARY KEY REFERENCES nodes(id) ON DELETE CASCADE,
  group_id INTEGER NOT NULL DEFAULT 0,
  core_type TEXT NOT NULL DEFAULT '',
  line_key TEXT NOT NULL DEFAULT '',
  line_type TEXT NOT NULL DEFAULT '',
  latency INTEGER NOT NULL DEFAULT 0,
  line_status TEXT NOT NULL DEFAULT '',
  url TEXT NOT NULL DEFAULT ''
);

CREATE TABLE IF NOT EXISTS catalog (
  kind TEXT NOT NULL,
  id INTEGER NOT NULL,
  body TEXT NOT NULL,
  PRIMARY KEY (kind, id)
);

CREATE TABLE IF NOT EXISTS admin_sessions (
  token_hash TEXT PRIMARY KEY,
  admin_id INTEGER NOT NULL,
  created_at INTEGER NOT NULL,
  expires_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS security_logs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL DEFAULT 0,
  action TEXT NOT NULL,
  ip TEXT NOT NULL DEFAULT '',
  device TEXT NOT NULL DEFAULT '',
  detail TEXT NOT NULL DEFAULT '',
  created_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS email_codes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  purpose TEXT NOT NULL,
  email TEXT NOT NULL,
  user_id INTEGER NOT NULL DEFAULT 0,
  code_hash TEXT NOT NULL,
  expires_at INTEGER NOT NULL,
  created_at INTEGER NOT NULL,
  ip TEXT NOT NULL DEFAULT '',
  device TEXT NOT NULL DEFAULT '',
  consumed_at INTEGER NOT NULL DEFAULT 0,
  attempts INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS service_plans (
  code TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  price INTEGER NOT NULL,
  traffic_gb INTEGER NOT NULL,
  duration_days INTEGER NOT NULL,
  sort_order INTEGER NOT NULL DEFAULT 0,
  enabled INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE IF NOT EXISTS commission_records (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  order_id INTEGER NOT NULL,
  order_no TEXT NOT NULL DEFAULT '',
  buyer_id INTEGER NOT NULL DEFAULT 0,
  buyer_name TEXT NOT NULL DEFAULT '',
  beneficiary_id INTEGER NOT NULL DEFAULT 0,
  level INTEGER NOT NULL DEFAULT 0,
  mode INTEGER NOT NULL DEFAULT 0,
  rate INTEGER NOT NULL DEFAULT 0,
  base_amount INTEGER NOT NULL DEFAULT 0,
  amount INTEGER NOT NULL DEFAULT 0,
  reversed_amount INTEGER NOT NULL DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'pending',
  created_at INTEGER NOT NULL,
  settled_at INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS platform_requests (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  requester_id INTEGER NOT NULL,
  target_id INTEGER NOT NULL,
  action TEXT NOT NULL,
  reason TEXT NOT NULL DEFAULT '',
  status TEXT NOT NULL DEFAULT 'pending',
  created_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS wallet_entries (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  kind TEXT NOT NULL,
  amount INTEGER NOT NULL,
  balance_after INTEGER NOT NULL DEFAULT 0,
  ref_id INTEGER NOT NULL DEFAULT 0,
  detail TEXT NOT NULL DEFAULT '',
  created_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS tickets (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  subject TEXT NOT NULL,
  body TEXT NOT NULL DEFAULT '',
  contact TEXT NOT NULL DEFAULT '',
  status TEXT NOT NULL DEFAULT 'open',
  created_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS agent_sessions (
  token_hash TEXT PRIMARY KEY,
  agent_id INTEGER NOT NULL,
  created_at INTEGER NOT NULL,
  expires_at INTEGER NOT NULL
);
`

type Store struct {
	db *sql.DB
}

func Open(cfg config.Config) (*Store, error) {
	dsn, err := sqliteDSN(cfg.DatabasePath)
	if err != nil {
		return nil, err
	}
	db, err := sql.Open("sqlite", dsn)
	if err != nil {
		return nil, err
	}
	db.SetMaxOpenConns(1)
	if _, err := db.Exec(schema); err != nil {
		db.Close()
		return nil, err
	}
	if cfg.DatabasePath != ":memory:" {
		_, _ = db.Exec(`PRAGMA journal_mode = WAL`)
	}
	store := &Store{db: db}
	if err := store.seedSettings(cfg); err != nil {
		db.Close()
		return nil, err
	}
	if err := store.migrate(); err != nil {
		db.Close()
		return nil, err
	}
	if err := store.migrateMembership(); err != nil {
		db.Close()
		return nil, err
	}
	if err := store.seedPlans(); err != nil {
		db.Close()
		return nil, err
	}
	return store, nil
}

func (s *Store) Close() error { return s.db.Close() }

func (s *Store) BackupTo(path string) error {
	escaped := strings.ReplaceAll(path, "'", "''")
	_, err := s.db.Exec(`VACUUM INTO '` + escaped + `'`)
	return err
}

func sqliteDSN(path string) (string, error) {
	query := "_pragma=busy_timeout(5000)&_pragma=foreign_keys(1)"
	if path == ":memory:" {
		name := fmt.Sprintf("mem%d", memorySeq.Add(1))
		return "file:" + name + "?mode=memory&cache=shared&" + query, nil
	}
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		return "", err
	}
	abs, err := filepath.Abs(path)
	if err != nil {
		return "", err
	}
	slash := filepath.ToSlash(abs)
	if !strings.HasPrefix(slash, "/") {
		slash = "/" + slash
	}
	u := url.URL{Scheme: "file", Path: slash, RawQuery: query}
	return u.String(), nil
}

func (s *Store) seedSettings(cfg config.Config) error {
	defaults := map[string]string{
		"profile_name":         "讯连宝",
		"support_url":          "",
		"profile_web_page_url": "",
		"auto_update_interval": "86400",
		"trial_bytes":          fmt.Sprintf("%d", cfg.TrialBytes),
		"trial_days":           fmt.Sprintf("%d", cfg.TrialDays),
	}
	stmt, err := s.db.Prepare(`INSERT OR IGNORE INTO settings (key, value) VALUES (?, ?)`)
	if err != nil {
		return err
	}
	defer stmt.Close()
	for key, value := range defaults {
		if _, err := stmt.Exec(key, value); err != nil {
			return err
		}
	}
	return nil
}

func (s *Store) tx(fn func(*sql.Tx) error) error {
	tx, err := s.db.Begin()
	if err != nil {
		return err
	}
	if err := fn(tx); err != nil {
		_ = tx.Rollback()
		return err
	}
	return tx.Commit()
}

func bit(v bool) int {
	if v {
		return 1
	}
	return 0
}
