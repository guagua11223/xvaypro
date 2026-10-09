-- 飞连会员、订单、分佣、钱包与账号防丢失。
-- 本文件可重复执行。users / announcements 的新增列见 users_columns.sql，
-- 服务启动时也会按列名自动补齐，避免 SQLite 重复 ALTER 失败。

CREATE TABLE IF NOT EXISTS email_verification_codes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  email TEXT NOT NULL,
  code TEXT NOT NULL,
  scene TEXT NOT NULL,
  expires_at INTEGER NOT NULL,
  used_at INTEGER NOT NULL DEFAULT 0,
  ip TEXT NOT NULL DEFAULT '',
  device TEXT NOT NULL DEFAULT '',
  created_at INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_email_codes_email ON email_verification_codes(email, created_at);

CREATE TABLE IF NOT EXISTS user_relations (
  user_id INTEGER PRIMARY KEY,
  parent_id INTEGER NOT NULL DEFAULT 0,
  level1_id INTEGER NOT NULL DEFAULT 0,
  level2_id INTEGER NOT NULL DEFAULT 0,
  level3_id INTEGER NOT NULL DEFAULT 0,
  path TEXT NOT NULL DEFAULT ''
);

CREATE TABLE IF NOT EXISTS distributors (
  user_id INTEGER PRIMARY KEY,
  parent_distributor_id INTEGER NOT NULL DEFAULT 0,
  commission_rate REAL NOT NULL DEFAULT 55,
  can_authorize_agent INTEGER NOT NULL DEFAULT 1,
  total_members INTEGER NOT NULL DEFAULT 0,
  total_commission REAL NOT NULL DEFAULT 0,
  status INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS commission_rates (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  distributor_id INTEGER NOT NULL,
  member_id INTEGER NOT NULL,
  rate REAL NOT NULL,
  rate_type TEXT NOT NULL DEFAULT 'custom',
  max_rate REAL NOT NULL DEFAULT 0,
  created_by INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL,
  UNIQUE (distributor_id, member_id)
);

CREATE TABLE IF NOT EXISTS node_packages (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  duration_type TEXT NOT NULL UNIQUE,
  duration_days INTEGER NOT NULL,
  traffic_gb REAL NOT NULL,
  price REAL NOT NULL,
  status INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE IF NOT EXISTS orders (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  order_no TEXT NOT NULL UNIQUE,
  user_id INTEGER NOT NULL,
  package_id INTEGER NOT NULL,
  amount REAL NOT NULL,
  gateway_fee REAL NOT NULL DEFAULT 0,
  commission_base REAL NOT NULL DEFAULT 0,
  pay_channel TEXT NOT NULL DEFAULT 'fourth',
  pay_status INTEGER NOT NULL DEFAULT 0,
  pay_time INTEGER NOT NULL DEFAULT 0,
  refund_status INTEGER NOT NULL DEFAULT 0,
  commission_status INTEGER NOT NULL DEFAULT 0,
  node_start_at INTEGER NOT NULL DEFAULT 0,
  node_end_at INTEGER NOT NULL DEFAULT 0,
  traffic_gb REAL NOT NULL DEFAULT 0,
  traffic_used_gb REAL NOT NULL DEFAULT 0,
  service_status INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_orders_user ON orders(user_id, created_at);

CREATE TABLE IF NOT EXISTS commissions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  order_id INTEGER NOT NULL,
  user_id INTEGER NOT NULL,
  from_user_id INTEGER NOT NULL,
  level INTEGER NOT NULL,
  mode INTEGER NOT NULL,
  rate REAL NOT NULL,
  base_amount REAL NOT NULL,
  amount REAL NOT NULL,
  status INTEGER NOT NULL DEFAULT 0,
  settle_month TEXT NOT NULL DEFAULT '',
  created_at INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_commissions_user ON commissions(user_id, status);
CREATE INDEX IF NOT EXISTS idx_commissions_order ON commissions(order_id);

CREATE TABLE IF NOT EXISTS wallets (
  user_id INTEGER PRIMARY KEY,
  balance REAL NOT NULL DEFAULT 0,
  frozen REAL NOT NULL DEFAULT 0,
  total_income REAL NOT NULL DEFAULT 0,
  total_withdraw REAL NOT NULL DEFAULT 0,
  negative_balance REAL NOT NULL DEFAULT 0,
  version INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS withdrawals (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  amount REAL NOT NULL,
  fee REAL NOT NULL DEFAULT 0,
  fee_rate REAL NOT NULL DEFAULT 0,
  min_amount REAL NOT NULL DEFAULT 0,
  status INTEGER NOT NULL DEFAULT 0,
  apply_time INTEGER NOT NULL,
  audit_time INTEGER NOT NULL DEFAULT 0,
  pay_time INTEGER NOT NULL DEFAULT 0,
  month TEXT NOT NULL DEFAULT '',
  remark TEXT NOT NULL DEFAULT ''
);

CREATE TABLE IF NOT EXISTS refunds (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  order_id INTEGER NOT NULL,
  user_id INTEGER NOT NULL,
  amount REAL NOT NULL,
  reason TEXT NOT NULL DEFAULT '',
  status INTEGER NOT NULL DEFAULT 0,
  handled_by INTEGER NOT NULL DEFAULT 0,
  handled_at INTEGER NOT NULL DEFAULT 0,
  ban_user INTEGER NOT NULL DEFAULT 1,
  can_unban INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE IF NOT EXISTS system_configs (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS ads (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  slot TEXT NOT NULL,
  title TEXT NOT NULL,
  image_url TEXT NOT NULL DEFAULT '',
  link_url TEXT NOT NULL DEFAULT '',
  sort_order INTEGER NOT NULL DEFAULT 0,
  starts_at INTEGER NOT NULL DEFAULT 0,
  ends_at INTEGER NOT NULL DEFAULT 0,
  status INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE IF NOT EXISTS customer_services (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  channel TEXT NOT NULL,
  account TEXT NOT NULL DEFAULT '',
  qr_url TEXT NOT NULL DEFAULT '',
  enabled INTEGER NOT NULL DEFAULT 1,
  sort_order INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS support_tickets (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  status INTEGER NOT NULL DEFAULT 0,
  reply TEXT NOT NULL DEFAULT '',
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS operation_logs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  actor_type TEXT NOT NULL,
  actor_id INTEGER NOT NULL DEFAULT 0,
  action TEXT NOT NULL,
  detail TEXT NOT NULL DEFAULT '',
  ip TEXT NOT NULL DEFAULT '',
  created_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS login_logs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  actor_type TEXT NOT NULL,
  account TEXT NOT NULL,
  success INTEGER NOT NULL,
  ip TEXT NOT NULL DEFAULT '',
  device TEXT NOT NULL DEFAULT '',
  created_at INTEGER NOT NULL
);

INSERT INTO node_packages (name, duration_type, duration_days, traffic_gb, price, status)
SELECT '1周', 'week', 7, 50, 15, 1
WHERE NOT EXISTS (SELECT 1 FROM node_packages WHERE duration_type = 'week');

INSERT INTO node_packages (name, duration_type, duration_days, traffic_gb, price, status)
SELECT '1月', 'month', 30, 200, 45, 1
WHERE NOT EXISTS (SELECT 1 FROM node_packages WHERE duration_type = 'month');

INSERT INTO node_packages (name, duration_type, duration_days, traffic_gb, price, status)
SELECT '1季度', 'quarter', 90, 600, 120, 1
WHERE NOT EXISTS (SELECT 1 FROM node_packages WHERE duration_type = 'quarter');

INSERT INTO node_packages (name, duration_type, duration_days, traffic_gb, price, status)
SELECT '1年', 'year', 365, 2400, 360, 1
WHERE NOT EXISTS (SELECT 1 FROM node_packages WHERE duration_type = 'year');

INSERT OR IGNORE INTO system_configs (key, value) VALUES
  ('modes_exclusive', '1'),
  ('pool_rate', '50'),
  ('level1_rate', '60'),
  ('level2_rate', '30'),
  ('level3_rate', '10'),
  ('three_level_enabled', '1'),
  ('commission_cap', '0'),
  ('rate_cap', '100'),
  ('distributor_default_rate', '55'),
  ('withdraw_fee_rate', '0'),
  ('withdraw_min', '10'),
  ('settle_day', '1'),
  ('traffic_unit', 'GB'),
  ('expire_reset', '1'),
  ('ban_stops_node', '1'),
  ('fourth_mch_id', ''),
  ('fourth_gateway', ''),
  ('fourth_key', ''),
  ('fourth_notify_secret', ''),
  ('email_host', ''),
  ('email_port', '465'),
  ('email_user', ''),
  ('email_password', ''),
  ('email_from', '');
