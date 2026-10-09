package store

import (
	"strings"
	"testing"
	"time"

	"xvay/houduan/internal/config"
)

func TestEmailCodeRules(t *testing.T) {
	db, err := Open(config.Config{DatabasePath: ":memory:", TrialBytes: 1, TrialDays: 1})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { db.Close() })

	now := time.Now().UnixMilli()
	first, err := db.IssueEmailCode(CodeIssue{
		Email: "a@b.c", Purpose: PurposeBind, Now: now, Deliver: true, IP: "10.0.0.8", Device: "phone",
	})
	if err != nil || len(first) != 6 {
		t.Fatalf("issue: %v %q", err, first)
	}
	if _, err := db.IssueEmailCode(CodeIssue{
		Email: "a@b.c", Purpose: PurposeBind, Now: now + 1000, Deliver: true, IP: "10.0.0.8", Device: "phone",
	}); err == nil || !strings.Contains(err.Error(), "60") {
		t.Fatalf("cooldown: %v", err)
	}
	if _, err := db.IssueEmailCode(CodeIssue{
		Email: "a@b.c", Purpose: PurposeReset, Now: now + 1000, Deliver: true, IP: "10.0.0.9", Device: "phone",
	}); err != nil {
		t.Fatalf("other purpose: %v", err)
	}

	base := now + CodeHourlyMs
	for i := 0; i < CodeHourlyLimit; i++ {
		if _, err := db.IssueEmailCode(CodeIssue{
			Email: "hour@b.c", Purpose: PurposeReset, IP: "10.1.0.1", Device: "pc",
			Now: base + int64(i)*CodeResendMs, Deliver: true,
		}); err != nil {
			t.Fatalf("send %d: %v", i, err)
		}
	}
	if _, err := db.IssueEmailCode(CodeIssue{
		Email: "hour@b.c", Purpose: PurposeReset, IP: "10.1.0.1", Device: "pc",
		Now: base + int64(CodeHourlyLimit)*CodeResendMs, Deliver: true,
	}); err == nil || !strings.Contains(err.Error(), "10") {
		t.Fatalf("hourly: %v", err)
	}

	code, err := db.IssueEmailCode(CodeIssue{
		Email: "exp@b.c", Purpose: PurposeRecover, Now: now, Deliver: true, IP: "10.2.0.1", Device: "pc",
	})
	if err != nil {
		t.Fatal(err)
	}
	if err := db.ConsumeEmailCode("exp@b.c", PurposeRecover, code, 0, "10.2.0.1", "pc", now+CodeTTLMs); err == nil || !strings.Contains(err.Error(), "过期") {
		t.Fatalf("expiry: %v", err)
	}

	freshAt := now + 2*CodeResendMs
	fresh, err := db.IssueEmailCode(CodeIssue{
		Email: "try@b.c", Purpose: PurposeReset, Now: freshAt, Deliver: true, IP: "10.3.0.1", Device: "pc",
	})
	if err != nil {
		t.Fatal(err)
	}
	wrong := "000000"
	if fresh == wrong {
		wrong = "111111"
	}
	for i := 0; i < CodeMaxAttempts-1; i++ {
		if err := db.ConsumeEmailCode("try@b.c", PurposeReset, wrong, 0, "10.3.0.1", "pc", freshAt); err == nil {
			t.Fatalf("attempt %d accepted", i)
		}
	}
	if err := db.ConsumeEmailCode("try@b.c", PurposeReset, wrong, 0, "10.3.0.1", "pc", freshAt); err == nil || !strings.Contains(err.Error(), "失效") {
		t.Fatalf("lockout: %v", err)
	}
	if err := db.ConsumeEmailCode("try@b.c", PurposeReset, fresh, 0, "10.3.0.1", "pc", freshAt); err == nil {
		t.Fatal("locked code still accepted")
	}

	okAt := now + 3*CodeResendMs
	okCode, err := db.IssueEmailCode(CodeIssue{
		Email: "ok@b.c", Purpose: PurposeBind, UserID: 7, Now: okAt, Deliver: true, IP: "10.4.0.1", Device: "Pixel",
	})
	if err != nil {
		t.Fatal(err)
	}
	if err := db.ConsumeEmailCode("ok@b.c", PurposeBind, okCode, 7, "10.4.0.1", "Pixel", okAt+1000); err != nil {
		t.Fatal(err)
	}
	logs, err := db.ListSecurityLogs(7, 10)
	if err != nil || len(logs) == 0 || logs[0].IP != "10.4.0.1" || logs[0].Device != "Pixel" {
		t.Fatalf("logs: %+v %v", logs, err)
	}
}
