package store

import "testing"

func TestSplitSystemPool(t *testing.T) {
	upline := []CommissionParty{{ID: 3}, {ID: 2}, {ID: 1}}
	plan := CommissionPlan{Pool: 50, Level1: 60, Level2: 30, Level3: 10, ThreeLevel: true}
	lines := SplitMemberCommission(100, upline, plan)
	if len(lines) != 3 || lines[0].Amount != 30 || lines[1].Amount != 15 || lines[2].Amount != 5 {
		t.Fatalf("pool 100: %+v", lines)
	}
	if lines[0].Mode != 0 || lines[0].UserID != 3 {
		t.Fatalf("level1: %+v", lines[0])
	}
	fee := SplitMemberCommission(98, upline, plan)
	if len(fee) != 3 || fee[0].Amount != 29.4 || fee[1].Amount != 14.7 || fee[2].Amount != 4.9 {
		t.Fatalf("pool 98: %+v", fee)
	}
}

func TestSplitModesDoNotStack(t *testing.T) {
	rate := 20.0
	upline := []CommissionParty{
		{ID: 8, IsDistributor: true, DistributorRate: 55, CustomRate: &rate},
		{ID: 7},
		{ID: 6},
	}
	plan := CommissionPlan{Pool: 50, Level1: 60, Level2: 30, Level3: 10, ThreeLevel: true}
	lines := SplitMemberCommission(100, upline, plan)
	if len(lines) != 1 || lines[0].UserID != 8 || lines[0].Amount != 55 || lines[0].Mode != 1 {
		t.Fatalf("distributor mode: %+v", lines)
	}
	upline[0].IsDistributor = false
	custom := SplitMemberCommission(100, upline, plan)
	if len(custom) != 1 || custom[0].Amount != 20 || custom[0].Mode != 1 {
		t.Fatalf("custom mode: %+v", custom)
	}
	zero := 0.0
	upline[0].CustomRate = &zero
	none := SplitMemberCommission(100, upline, plan)
	if len(none) != 1 || none[0].Amount != 0 {
		t.Fatalf("explicit zero must not fall through: %+v", none)
	}
}

func TestSplitCap(t *testing.T) {
	upline := []CommissionParty{{ID: 3}, {ID: 2}, {ID: 1}}
	plan := CommissionPlan{Pool: 50, Level1: 60, Level2: 30, Level3: 10, ThreeLevel: true, Cap: 40}
	lines := SplitMemberCommission(100, upline, plan)
	sum := 0.0
	for _, line := range lines {
		sum += line.Amount
	}
	if roundMoney(sum) != 40 {
		t.Fatalf("cap sum %v %+v", sum, lines)
	}
}
