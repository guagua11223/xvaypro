package store

import (
	"database/sql"
	"errors"
)

// ErrDeviceLimit means another device is already using the last free slot.
var ErrDeviceLimit = errors.New("device limit")

// BeginConnect closes this device's previous session and opens a new one.
// Other devices still holding a session count toward deviceLimit. Zero means no cap.
func (s *Store) BeginConnect(userID int64, deviceID string, nodeID int64, protocol string, now, deviceLimit int64) error {
	return s.tx(func(tx *sql.Tx) error {
		if _, err := tx.Exec(
			`UPDATE connect_sessions SET stopped_at = ? WHERE user_id = ? AND device_id = ? AND stopped_at = 0`,
			now, userID, deviceID,
		); err != nil {
			return err
		}
		var others int64
		if err := tx.QueryRow(
			`SELECT COUNT(DISTINCT device_id) FROM connect_sessions WHERE user_id = ? AND stopped_at = 0`,
			userID,
		).Scan(&others); err != nil {
			return err
		}
		if deviceLimit > 0 && others >= deviceLimit {
			return ErrDeviceLimit
		}
		_, err := tx.Exec(
			`INSERT INTO connect_sessions (user_id, device_id, node_id, protocol, started_at, stopped_at)
			 VALUES (?, ?, ?, ?, ?, 0)`,
			userID, deviceID, nodeID, protocol, now,
		)
		return err
	})
}

// EndConnect marks this device's open session as stopped.
func (s *Store) EndConnect(userID int64, deviceID string, now int64) error {
	_, err := s.db.Exec(
		`UPDATE connect_sessions SET stopped_at = ? WHERE user_id = ? AND device_id = ? AND stopped_at = 0`,
		now, userID, deviceID,
	)
	return err
}
