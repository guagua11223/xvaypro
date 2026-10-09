package store

import "math"

// CommissionParty is one ancestor. CustomRate is set when a distributor
// stored a rate for this member, including an explicit zero.
type CommissionParty struct {
	ID              int64
	IsDistributor   bool
	DistributorRate float64
	CustomRate      *float64
}

// CommissionPlan is the system pool. Level rates are percents of the pool.
// Cap is the max yuan for one order; 0 means no cap.
type CommissionPlan struct {
	Pool, Level1, Level2, Level3 float64
	ThreeLevel                   bool
	Cap                          float64
}

type CommissionShare struct {
	UserID int64
	Level  int
	Mode   int
	Rate   float64
	Amount float64
}

func roundMoney(v float64) float64 {
	return math.Round(v*100) / 100
}

// SplitCommission picks exactly one mode.
// Distributor direct referral, else a custom rate on the direct referrer, else the system pool.
func SplitMemberCommission(base float64, upline []CommissionParty, plan CommissionPlan) []CommissionShare {
	base = roundMoney(base)
	if base <= 0 || len(upline) == 0 {
		return nil
	}
	direct := upline[0]
	var lines []CommissionShare
	switch {
	case direct.IsDistributor:
		lines = append(lines, shareOf(direct.ID, 1, 1, direct.DistributorRate, base))
	case direct.CustomRate != nil:
		lines = append(lines, shareOf(direct.ID, 1, 1, *direct.CustomRate, base))
	case plan.ThreeLevel:
		pool := roundMoney(base * plan.Pool / 100)
		weights := []float64{plan.Level1, plan.Level2, plan.Level3}
		for i := 0; i < len(upline) && i < 3; i++ {
			if upline[i].ID == 0 || weights[i] <= 0 {
				continue
			}
			amount := roundMoney(pool * weights[i] / 100)
			if amount <= 0 {
				continue
			}
			lines = append(lines, CommissionShare{
				UserID: upline[i].ID,
				Level:  i + 1,
				Mode:   0,
				Rate:   roundMoney(plan.Pool * weights[i] / 100),
				Amount: amount,
			})
		}
	}
	return capShares(lines, plan.Cap)
}

func shareOf(id int64, level, mode int, rate, base float64) CommissionShare {
	if rate < 0 {
		rate = 0
	}
	return CommissionShare{
		UserID: id,
		Level:  level,
		Mode:   mode,
		Rate:   roundMoney(rate),
		Amount: roundMoney(base * rate / 100),
	}
}

func capShares(lines []CommissionShare, cap float64) []CommissionShare {
	if cap <= 0 || len(lines) == 0 {
		return lines
	}
	sum := 0.0
	for _, line := range lines {
		sum += line.Amount
	}
	sum = roundMoney(sum)
	if sum <= cap {
		return lines
	}
	scale := cap / sum
	used := 0.0
	for i := range lines {
		if i == len(lines)-1 {
			lines[i].Amount = roundMoney(cap - used)
		} else {
			lines[i].Amount = roundMoney(lines[i].Amount * scale)
			used += lines[i].Amount
		}
		if lines[i].Amount < 0 {
			lines[i].Amount = 0
		}
	}
	return lines
}
