package enum

type ActivityJoinMode string

const (
	ActivityJoinModeAutoApprove   ActivityJoinMode = "AUTO_APPROVE"
	ActivityJoinModeManualApprove ActivityJoinMode = "MANUAL_APPROVE"
)

func (v ActivityJoinMode) IsValid() bool {
	switch v {
	case ActivityJoinModeAutoApprove, ActivityJoinModeManualApprove:
		return true
	default:
		return false
	}
}
