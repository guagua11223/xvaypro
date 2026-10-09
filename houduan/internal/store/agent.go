package store

import (
	"database/sql"
	"time"

	"xvay/houduan/internal/auth"
)

func (s *Store) CreateAgentSession(agentID int64, ttl time.Duration) (string, error) {
	token, err := auth.NewToken(24)
	if err != nil {
		return "", err
	}
	now := time.Now().UnixMilli()
	_, err = s.db.Exec(
		`INSERT INTO agent_sessions (token_hash, agent_id, created_at, expires_at) VALUES (?, ?, ?, ?)`,
		auth.HashToken(token), agentID, now, now+ttl.Milliseconds(),
	)
	if err != nil {
		return "", err
	}
	return token, nil
}

func (s *Store) AgentIDBySession(token string, now int64) (int64, bool, error) {
	if token == "" {
		return 0, false, nil
	}
	var id int64
	err := s.db.QueryRow(
		`SELECT agent_id FROM agent_sessions WHERE token_hash = ? AND expires_at > ?`,
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

func (s *Store) DeleteAgentSession(token string) error {
	if token == "" {
		return nil
	}
	_, err := s.db.Exec(`DELETE FROM agent_sessions WHERE token_hash = ?`, auth.HashToken(token))
	return err
}

func PublicAgent(item map[string]any) map[string]any {
	out := cloneMap(item)
	delete(out, "password")
	delete(out, "passwordHash")
	return out
}
