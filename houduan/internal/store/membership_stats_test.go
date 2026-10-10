package store

import (
	"testing"
	"time"

	"xvay/houduan/internal/config"
)

func TestMemberStatsAndTextWithdrawal(t *testing.T) {
	db, err := Open(config.Config{
		DataDir: t.TempDir(), DatabasePath: ":memory:",
		TrialBytes: 1024, TrialDays: 7,
	})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { db.Close() })
	now := time.Now().UnixMilli()
	if _, err := db.db.Exec(`INSERT INTO wallets (user_id, balance, frozen, total_income, total_withdraw, negative_balance) VALUES (9, 20, 5, 30, 0, 2)`); err != nil {
		t.Fatal(err)
	}
	if _, err := db.db.Exec(`INSERT INTO withdrawals (user_id, amount, status, apply_time, pay_time) VALUES (9, 12.5, 'pending', ?, 0)`, now); err != nil {
		t.Fatal(err)
	}
	res, err := db.db.Exec(`INSERT INTO withdrawals (user_id, amount, status, apply_time, pay_time) VALUES (9, 8, 'paid', ?, ?)`, now, now)
	if err != nil {
		t.Fatal(err)
	}
	paidID, _ := res.LastInsertId()
	stats, err := db.MemberStats(time.Now())
	if err != nil {
		t.Fatal(err)
	}
	if stats["pendingWithdraw"].(float64) != 1 || stats["todayWithdraw"].(float64) != 8 {
		t.Fatalf("withdraw stats %+v", stats)
	}
	if stats["walletBalance"].(float64) != 20 || stats["walletFrozen"].(float64) != 5 || stats["negativeBalance"].(float64) != 2 {
		t.Fatalf("wallet stats %+v", stats)
	}
	var pendingID int64
	if err := db.db.QueryRow(`SELECT id FROM withdrawals WHERE status = 'pending'`).Scan(&pendingID); err != nil {
		t.Fatal(err)
	}
	if err := db.AuditWithdrawal(pendingID, "reject", now); err != nil {
		t.Fatal(err)
	}
	var balance float64
	if err := db.db.QueryRow(`SELECT balance FROM wallets WHERE user_id = 9`).Scan(&balance); err != nil {
		t.Fatal(err)
	}
	if balance != 32.5 {
		t.Fatalf("reject should return 12.5 to balance, got %v", balance)
	}
	if paidID == 0 {
		t.Fatal("missing paid id")
	}
}
