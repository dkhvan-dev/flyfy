package enum

type ActivityJoinMode string

const (
	ActivityJoinModeAutoApprove ActivityJoinMode = "AUTO_APPROVE"
)

func (v ActivityJoinMode) IsValid() bool {
	switch v {
	case ActivityJoinModeAutoApprove:
		return true
	default:
		return false
	}
}
