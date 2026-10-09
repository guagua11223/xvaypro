package store

import (
	"database/sql"
	"strings"
	"time"

	"xvay/houduan/internal/auth"
	"xvay/houduan/internal/errs"
)

const userCols = `id, username, email, password_hash, uuid, hy2_password, sub_token,
	upload, download, total, expire_at, status, device_limit, created_at,
	nickname, avatar, user_type, referrer_id, distributor_id, is_distributor, is_agent,
	commission_mode, wallet_enabled, can_authorize_agent, email_status, invite_code,
	distributor_rate, member_rate`

func colsWith(alias, cols string) string {
	parts := strings.Split(cols, ",")
	out := make([]string, len(parts))
	for i, part := range parts {
		out[i] = alias + "." + strings.TrimSpace(part)
	}
	return strings.Join(out, ", ")
}

func scanUser(row interface{ Scan(...any) error }) (User, error) {
	var user User
	var email sql.NullString
	err := row.Scan(
		&user.ID, &user.Username, &email, &user.PasswordHash, &user.UUID, &user.Hy2Password, &user.SubToken,
		&user.Upload, &user.Download, &user.Total, &user.ExpireAt, &user.Status, &user.DeviceLimit, &user.CreatedAt,
		&user.Nickname, &user.Avatar, &user.UserType, &user.ReferrerID, &user.DistributorID,
		&user.IsDistributor, &user.IsAgent, &user.CommissionMode, &user.WalletEnabled,
		&user.CanAuthorizeAgent, &user.EmailStatus, &user.InviteCode, &user.DistributorRate, &user.MemberRate,
	)
	user.Email = email.String
	return user, err
}

func emailArg(email string) any {
	email = strings.TrimSpace(email)
	if email == "" {
		return nil
	}
	return email
}

func userConflict(err error) error {
	if err == nil {
		return nil
	}
	msg := err.Error()
	switch {
	case strings.Contains(msg, "users.username"):
		return errs.New(409, "CONFLICT", "用户名已存在")
	case strings.Contains(msg, "users.email"):
		return errs.New(409, "CONFLICT", "该邮箱已绑定其他账号")
	case errs.IsUnique(err):
		return errs.New(409, "CONFLICT", "账号已存在")
	default:
		return err
	}
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
	username := strings.TrimSpace(input.Username)
	if username == "" {
		username = strings.TrimSpace(input.Email)
	}
	if username == "" {
		return User{}, errs.New(400, "VALIDATION", "请输入用户名")
	}
	nickname := strings.TrimSpace(input.Nickname)
	if nickname == "" {
		nickname = username
	}
	userType := input.UserType
	if userType == "" {
		userType = "member"
	}
	status := input.Status
	if status == "" {
		status = "active"
	}
	row := s.db.QueryRow(
		`INSERT INTO users (
			username, email, password_hash, uuid, hy2_password, sub_token,
			upload, download, total, expire_at, status, device_limit, created_at,
			nickname, avatar, user_type
		) VALUES (?, ?, ?, ?, ?, ?, 0, 0, ?, ?, ?, ?, ?, ?, ?, ?)
		RETURNING `+userCols,
		username, emailArg(input.Email), hash, uuid, hy2, sub,
		input.Total, input.ExpireAt, status, input.DeviceLimit, time.Now().UnixMilli(),
		nickname, input.Avatar, userType,
	)
	user, err := scanUser(row)
	if err != nil {
		return User{}, userConflict(err)
	}
	return s.finishNewUser(user)
}

func (s *Store) FindUserByEmail(email string) (User, bool, error) {
	user, err := scanUser(s.db.QueryRow(`SELECT `+userCols+` FROM users WHERE email = ?`, email))
	return optionalUser(user, err)
}

func (s *Store) FindUserByUsername(username string) (User, bool, error) {
	user, err := scanUser(s.db.QueryRow(`SELECT `+userCols+` FROM users WHERE username = ?`, username))
	return optionalUser(user, err)
}

func (s *Store) FindUserByAccount(account string) (User, bool, error) {
	account = strings.ToLower(strings.TrimSpace(account))
	if account == "" {
		return User{}, false, nil
	}
	user, ok, err := s.FindUserByUsername(account)
	if err != nil || ok {
		return user, ok, err
	}
	return s.FindUserByEmail(account)
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
		`SELECT `+colsWith("users", userCols)+`
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

func (s *Store) DeleteUserSessions(userID int64) error {
	_, err := s.db.Exec(`DELETE FROM sessions WHERE user_id = ?`, userID)
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
	if patch.Username != nil {
		current.Username = *patch.Username
	}
	if patch.Email != nil {
		current.Email = *patch.Email
	}
	if patch.Nickname != nil {
		current.Nickname = *patch.Nickname
	}
	if patch.Avatar != nil {
		current.Avatar = *patch.Avatar
	}
	if patch.UserType != nil {
		current.UserType = *patch.UserType
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
			username = ?, email = ?, password_hash = ?, total = ?, expire_at = ?, status = ?,
			device_limit = ?, upload = ?, download = ?, nickname = ?, avatar = ?, user_type = ?
		 WHERE id = ?
		 RETURNING `+userCols,
		current.Username, emailArg(current.Email), current.PasswordHash, current.Total, current.ExpireAt, current.Status,
		current.DeviceLimit, current.Upload, current.Download, current.Nickname, current.Avatar, current.UserType, id,
	)
	user, err := scanUser(row)
	if err != nil {
		return User{}, userConflict(err)
	}
	return user, nil
}

func (s *Store) BindUserEmail(userID int64, email string) (User, error) {
	other, ok, err := s.FindUserByEmail(email)
	if err != nil {
		return User{}, err
	}
	if ok && other.ID == userID {
		return other, errs.New(409, "CONFLICT", "该邮箱已绑定当前账号")
	}
	if ok {
		return User{}, errs.New(409, "CONFLICT", "该邮箱已绑定其他账号")
	}
	if _, err := s.UpdateUser(userID, UserPatch{Email: &email}); err != nil {
		return User{}, err
	}
	if _, err := s.db.Exec(`UPDATE users SET email_status = 2 WHERE id = ?`, userID); err != nil {
		return User{}, err
	}
	user, _, err := s.FindUserByID(userID)
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
