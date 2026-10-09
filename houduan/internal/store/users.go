package store

import (
	"database/sql"
	"time"

	"xvay/houduan/internal/auth"
	"xvay/houduan/internal/errs"
)

const userCols = `id, email, password_hash, uuid, hy2_password, sub_token,
	upload, download, total, expire_at, status, device_limit, created_at`

func scanUser(row interface{ Scan(...any) error }) (User, error) {
	var user User
	err := row.Scan(
		&user.ID, &user.Email, &user.PasswordHash, &user.UUID, &user.Hy2Password, &user.SubToken,
		&user.Upload, &user.Download, &user.Total, &user.ExpireAt, &user.Status, &user.DeviceLimit, &user.CreatedAt,
	)
	return user, err
}

func (s *Store) CreateUser(input UserInput) (User, error) {
	hash, err := auth.HashPassword(input.Password)
	if err != nil {
		return User{}, err
	}
	uuid, err := auth.NewUUID()
	if err != nil {
		return User{}, err
	}
	hy2, err := auth.NewToken(18)
	if err != nil {
		return User{}, err
	}
	sub, err := auth.NewToken(24)
	if err != nil {
		return User{}, err
	}
	status := input.Status
	if status == "" {
		status = "active"
	}
	row := s.db.QueryRow(
		`INSERT INTO users (
			email, password_hash, uuid, hy2_password, sub_token,
			upload, download, total, expire_at, status, device_limit, created_at
		) VALUES (?, ?, ?, ?, ?, 0, 0, ?, ?, ?, ?, ?)
		RETURNING `+userCols,
		input.Email, hash, uuid, hy2, sub, input.Total, input.ExpireAt, status, input.DeviceLimit, time.Now().UnixMilli(),
	)
	user, err := scanUser(row)
	if errs.IsUnique(err) {
		return User{}, errs.New(409, "CONFLICT", "邮箱已注册")
	}
	return user, err
}

func (s *Store) FindUserByEmail(email string) (User, bool, error) {
	user, err := scanUser(s.db.QueryRow(`SELECT `+userCols+` FROM users WHERE email = ?`, email))
	return optionalUser(user, err)
}

func (s *Store) FindUserByID(id int64) (User, bool, error) {
	user, err := scanUser(s.db.QueryRow(`SELECT `+userCols+` FROM users WHERE id = ?`, id))
	return optionalUser(user, err)
}

func (s *Store) FindUserBySubToken(token string) (User, bool, error) {
	user, err := scanUser(s.db.QueryRow(`SELECT `+userCols+` FROM users WHERE sub_token = ?`, token))
	return optionalUser(user, err)
}

func (s *Store) FindUserBySession(token string, now int64) (User, bool, error) {
	user, err := scanUser(s.db.QueryRow(
		`SELECT users.id, users.email, users.password_hash, users.uuid, users.hy2_password, users.sub_token,
			users.upload, users.download, users.total, users.expire_at, users.status, users.device_limit, users.created_at
		 FROM sessions JOIN users ON users.id = sessions.user_id
		 WHERE sessions.token_hash = ? AND sessions.expires_at > ?`,
		auth.HashToken(token), now,
	))
	return optionalUser(user, err)
}

func optionalUser(user User, err error) (User, bool, error) {
	if err == sql.ErrNoRows {
		return User{}, false, nil
	}
	return user, err == nil, err
}

func (s *Store) CreateSession(user User, ttlMs int64) (string, error) {
	token, err := auth.NewToken(32)
	if err != nil {
		return "", err
	}
	now := time.Now().UnixMilli()
	err = s.tx(func(tx *sql.Tx) error {
		if _, err := tx.Exec(`DELETE FROM sessions WHERE expires_at <= ?`, now); err != nil {
			return err
		}
		if user.DeviceLimit > 0 {
			rows, err := tx.Query(
				`SELECT token_hash FROM sessions WHERE user_id = ? ORDER BY created_at ASC`, user.ID,
			)
			if err != nil {
				return err
			}
			var hashes []string
			for rows.Next() {
				var hash string
				if err := rows.Scan(&hash); err != nil {
					rows.Close()
					return err
				}
				hashes = append(hashes, hash)
			}
			rows.Close()
			if err := rows.Err(); err != nil {
				return err
			}
			overflow := len(hashes) - int(user.DeviceLimit) + 1
			for i := 0; i < overflow; i++ {
				if _, err := tx.Exec(`DELETE FROM sessions WHERE token_hash = ?`, hashes[i]); err != nil {
					return err
				}
			}
		}
		_, err := tx.Exec(
			`INSERT INTO sessions (token_hash, user_id, created_at, expires_at) VALUES (?, ?, ?, ?)`,
			auth.HashToken(token), user.ID, now, now+ttlMs,
		)
		return err
	})
	return token, err
}

func (s *Store) DeleteSession(token string) error {
	_, err := s.db.Exec(`DELETE FROM sessions WHERE token_hash = ?`, auth.HashToken(token))
	return err
}

func (s *Store) ListUsers(limit int) ([]User, error) {
	rows, err := s.db.Query(`SELECT `+userCols+` FROM users ORDER BY id DESC LIMIT ?`, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var users []User
	for rows.Next() {
		user, err := scanUser(rows)
		if err != nil {
			return nil, err
		}
		users = append(users, user)
	}
	if users == nil {
		users = []User{}
	}
	return users, rows.Err()
}

func (s *Store) UpdateUser(id int64, patch UserPatch) (User, error) {
	current, ok, err := s.FindUserByID(id)
	if err != nil {
		return User{}, err
	}
	if !ok {
		return User{}, errs.New(404, "NOT_FOUND", "用户不存在")
	}
	if patch.Email != nil {
		current.Email = *patch.Email
	}
	if patch.Password != nil {
		hash, err := auth.HashPassword(*patch.Password)
		if err != nil {
			return User{}, err
		}
		current.PasswordHash = hash
	}
	if patch.Total != nil {
		current.Total = *patch.Total
	}
	if patch.ExpireAt != nil {
		current.ExpireAt = *patch.ExpireAt
	}
	if patch.Status != nil {
		current.Status = *patch.Status
	}
	if patch.DeviceLimit != nil {
		current.DeviceLimit = *patch.DeviceLimit
	}
	if patch.Upload != nil {
		current.Upload = *patch.Upload
	}
	if patch.Download != nil {
		current.Download = *patch.Download
	}
	row := s.db.QueryRow(
		`UPDATE users SET
			email = ?, password_hash = ?, total = ?, expire_at = ?, status = ?,
			device_limit = ?, upload = ?, download = ?
		 WHERE id = ?
		 RETURNING `+userCols,
		current.Email, current.PasswordHash, current.Total, current.ExpireAt, current.Status,
		current.DeviceLimit, current.Upload, current.Download, id,
	)
	user, err := scanUser(row)
	if errs.IsUnique(err) {
		return User{}, errs.New(409, "CONFLICT", "邮箱已注册")
	}
	return user, err
}

func (s *Store) ResetTraffic(id int64) (User, error) {
	zero := int64(0)
	user, err := s.UpdateUser(id, UserPatch{Upload: &zero, Download: &zero})
	if err != nil {
		return User{}, err
	}
	if _, err := s.db.Exec(`DELETE FROM node_counters WHERE user_id = ?`, id); err != nil {
		return User{}, err
	}
	return user, nil
}

func (s *Store) ResetSubToken(id int64) (User, error) {
	if _, ok, err := s.FindUserByID(id); err != nil || !ok {
		if err != nil {
			return User{}, err
		}
		return User{}, errs.New(404, "NOT_FOUND", "用户不存在")
	}
	token, err := auth.NewToken(24)
	if err != nil {
		return User{}, err
	}
	return scanUser(s.db.QueryRow(
		`UPDATE users SET sub_token = ? WHERE id = ? RETURNING `+userCols, token, id,
	))
}

func (s *Store) DeleteUser(id int64) error {
	res, err := s.db.Exec(`DELETE FROM users WHERE id = ?`, id)
	if err != nil {
		return err
	}
	n, err := res.RowsAffected()
	if err != nil {
		return err
	}
	if n == 0 {
		return errs.New(404, "NOT_FOUND", "用户不存在")
	}
	return nil
}

func (s *Store) CountUsers() (int64, error) {
	var n int64
	err := s.db.QueryRow(`SELECT COUNT(*) FROM users`).Scan(&n)
	return n, err
}

func (s *Store) ListEligibleUsers(now int64) ([]User, error) {
	rows, err := s.db.Query(
		`SELECT `+userCols+` FROM users
		 WHERE status = 'active'
		   AND (expire_at = 0 OR expire_at > ?)
		   AND (total = 0 OR upload + download < total)
		 ORDER BY id ASC`, now,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var users []User
	for rows.Next() {
		user, err := scanUser(rows)
		if err != nil {
			return nil, err
		}
		users = append(users, user)
	}
	if users == nil {
		users = []User{}
	}
	return users, rows.Err()
}
