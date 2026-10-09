package access

import "time"

type State struct {
	OK      bool
	Status  int
	Code    string
	Message string
}

func StateOf(status string, expireAt, upload, download, total int64, now time.Time) State {
	ms := now.UnixMilli()
	if status != "active" {
		return State{Status: 403, Code: "DISABLED", Message: "账号已停用"}
	}
	if expireAt != 0 && expireAt <= ms {
		return State{Status: 403, Code: "EXPIRED", Message: "套餐已到期"}
	}
	if total > 0 && upload+download >= total {
		return State{Status: 403, Code: "QUOTA", Message: "流量已用完"}
	}
	return State{OK: true, Status: 200, Code: "OK", Message: "可用"}
}

// AbsoluteDelta turns a monotonic counter into the bytes added since the last report.
// A counter that goes backwards is treated as a reset.
func AbsoluteDelta(previous *int64, reported int64) int64 {
	if previous == nil || reported < *previous {
		return reported
	}
	return reported - *previous
}
