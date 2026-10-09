package store

import (
	"crypto/rand"
	"database/sql"
	"encoding/binary"
	"fmt"
	"strings"

	"xvay/houduan/internal/auth"
	"xvay/houduan/internal/errs"
)

const (
	PurposeBind    = "bind"
	PurposeRecover = "recover"
	PurposeReset   = "reset"

	CodeTTLMs       int64 = 5 * 60 * 1000
	CodeResendMs    int64 = 60 * 1000
	CodeHourlyMs    int64 = 60 * 60 * 1000
	CodeHourlyLimit       = 10
	CodeMaxAttempts       = 5
)

type CodeIssue struct {
	Email   string
	Purpose string
	UserID  int64
	IP      string
	Device  string
	Now     int64
	Deliver bool
}

type SecurityLog struct {
	ID        int64
	UserID    int64
	Action    string
	IP        string
	Device    string
	Detail    string
	CreatedAt int64
}

func (s *Store) IssueEmailCode(in CodeIssue) (string, error) {
	var code string
	err := s.tx(func(tx *sql.Tx) error {
		var last int64
		if err := tx.QueryRow(
			`SELECT COALESCE(MAX(created_at), 0) FROM email_codes WHERE email = ? AND purpose = ?`,
			in.Email, in.Purpose,
		).Scan(&last); err != nil {
			return err
		}
		if last > 0 && in.Now-last < CodeResendMs {
			return errs.New(429, "RATE_LIMIT", "验证码 60 秒内不可重发")
		}
		if err := rejectHourly(tx,
			`SELECT COUNT(*) FROM email_codes WHERE email = ? AND created_at > ?`,
			in.Email, in.Now-CodeHourlyMs,
		); err != nil {
			return err
		}
		if in.UserID > 0 {
			if err := rejectHourly(tx,
				`SELECT COUNT(*) FROM email_codes WHERE user_id = ? AND created_at > ?`,
				in.UserID, in.Now-CodeHourlyMs,
			); err != nil {
				return err
			}
		}
		if in.IP != "" {
			if err := rejectHourly(tx,
				`SELECT COUNT(*) FROM email_codes WHERE ip = ? AND created_at > ?`,
				in.IP, in.Now-CodeHourlyMs,
			); err != nil {
				return err
			}
		}
		hash := "undelivered"
		expires := in.Now
		consumed := in.Now
		if in.Deliver {
			plain, err := newDigitCode()
			if err != nil {
				return err
			}
			code = plain
			hash = auth.HashToken(plain)
			expires = in.Now + CodeTTLMs
			consumed = 0
			if _, err := tx.Exec(
				`UPDATE email_codes SET consumed_at = ? WHERE email = ? AND purpose = ? AND consumed_at = 0`,
				in.Now, in.Email, in.Purpose,
			); err != nil {
				return err
			}
		}
		if _, err := tx.Exec(
			`INSERT INTO email_codes (
				purpose, email, user_id, code_hash, expires_at, created_at, ip, device, consumed_at, attempts
			) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 0)`,
			in.Purpose, in.Email, in.UserID, hash, expires, in.Now, clip(in.IP, 64), clip(in.Device, 200), consumed,
		); err != nil {
			return err
		}
		return insertLog(tx, in.UserID, "email_code", in.IP, in.Device, codeDetail(in.Purpose), in.Now)
	})
	if err != nil {
		return "", err
	}
	return code, nil
}

func rejectHourly(tx *sql.Tx, query string, args ...any) error {
	var n int
	if err := tx.QueryRow(query, args...).Scan(&n); err != nil {
		return err
	}
	if n >= CodeHourlyLimit {
		return errs.New(429, "RATE_LIMIT", "每小时最多发送 10 次验证码")
	}
	return nil
}

func (s *Store) ConsumeEmailCode(email, purpose, code string, userID int64, ip, device string, now int64) error {
	var failure error
	err := s.tx(func(tx *sql.Tx) error {
		var id, expires, consumed int64
		var attempts int
		var owner int64
		var hash string
		err := tx.QueryRow(
			`SELECT id, user_id, code_hash, expires_at, consumed_at, attempts
			 FROM email_codes WHERE email = ? AND purpose = ?
			 ORDER BY id DESC LIMIT 1`, email, purpose,
		).Scan(&id, &owner, &hash, &expires, &consumed, &attempts)
		if err == sql.ErrNoRows || consumed != 0 {
			failure = errs.New(400, "VALIDATION", "验证码不正确或已过期")
			return insertLog(tx, userID, "email_code_fail", ip, device, "验证码校验失败", now)
		}
		if err != nil {
			return err
		}
		if userID > 0 && owner > 0 && owner != userID {
			failure = errs.New(400, "VALIDATION", "验证码不正确或已过期")
			return insertLog(tx, userID, "email_code_fail", ip, device, "验证码校验失败", now)
		}
		if expires <= now {
			failure = errs.New(400, "VALIDATION", "验证码已过期")
			return insertLog(tx, owner, "email_code_fail", ip, device, "验证码已过期", now)
		}
		if attempts >= CodeMaxAttempts {
			failure = errs.New(400, "VALIDATION", "验证码已失效，请重新获取")
			return insertLog(tx, owner, "email_code_fail", ip, device, "验证码已失效", now)
		}
		if !auth.SafeEqual(hash, auth.HashToken(code)) {
			attempts++
			consumedAt := int64(0)
			if attempts >= CodeMaxAttempts {
				consumedAt = now
			}
			if _, err := tx.Exec(`UPDATE email_codes SET attempts = ?, consumed_at = ? WHERE id = ?`, attempts, consumedAt, id); err != nil {
				return err
			}
			failure = errs.New(400, "VALIDATION", "验证码不正确")
			if attempts >= CodeMaxAttempts {
				failure = errs.New(400, "VALIDATION", "验证码已失效，请重新获取")
			}
			return insertLog(tx, owner, "email_code_fail", ip, device, "验证码不正确", now)
		}
		if _, err := tx.Exec(`UPDATE email_codes SET consumed_at = ? WHERE id = ?`, now, id); err != nil {
			return err
		}
		return nil
	})
	if err != nil {
		return err
	}
	return failure
}

func (s *Store) DropLatestCode(email, purpose string) error {
	_, err := s.db.Exec(
		`DELETE FROM email_codes WHERE id = (
			SELECT id FROM email_codes WHERE email = ? AND purpose = ? AND consumed_at = 0 ORDER BY id DESC LIMIT 1
		)`, email, purpose,
	)
	return err
}

func (s *Store) AddSecurityLog(userID int64, action, ip, device, detail string, now int64) error {
	_, err := s.db.Exec(
		`INSERT INTO security_logs (user_id, action, ip, device, detail, created_at) VALUES (?, ?, ?, ?, ?, ?)`,
		userID, action, clip(ip, 64), clip(device, 200), clip(detail, 200), now,
	)
	return err
}

func (s *Store) ListSecurityLogs(userID int64, limit int) ([]SecurityLog, error) {
	if limit <= 0 || limit > 50 {
		limit = 20
	}
	rows, err := s.db.Query(
		`SELECT id, user_id, action, ip, device, detail, created_at
		 FROM security_logs WHERE user_id = ? ORDER BY id DESC LIMIT ?`, userID, limit,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	list := []SecurityLog{}
	for rows.Next() {
		var row SecurityLog
		if err := rows.Scan(&row.ID, &row.UserID, &row.Action, &row.IP, &row.Device, &row.Detail, &row.CreatedAt); err != nil {
			return nil, err
		}
		list = append(list, row)
	}
	return list, rows.Err()
}

func insertLog(tx *sql.Tx, userID int64, action, ip, device, detail string, now int64) error {
	_, err := tx.Exec(
		`INSERT INTO security_logs (user_id, action, ip, device, detail, created_at) VALUES (?, ?, ?, ?, ?, ?)`,
		userID, action, clip(ip, 64), clip(device, 200), clip(detail, 200), now,
	)
	return err
}

func newDigitCode() (string, error) {
	var buf [4]byte
	if _, err := rand.Read(buf[:]); err != nil {
		return "", err
	}
	n := binary.BigEndian.Uint32(buf[:]) % 1000000
	return fmt.Sprintf("%06d", n), nil
}

func codeDetail(purpose string) string {
	switch purpose {
	case PurposeBind:
		return "发送绑定邮箱验证码"
	case PurposeRecover:
		return "发送找回账号验证码"
	case PurposeReset:
		return "发送重置密码验证码"
	default:
		return "发送验证码"
	}
}

func clip(text string, n int) string {
	text = strings.TrimSpace(text)
	if len(text) <= n {
		return text
	}
	return text[:n]
}
