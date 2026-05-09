package enum

type ActivityModerationStatus string

const (
	ActivityModerationStatusNotRequired ActivityModerationStatus = "NOT_REQUIRED"
	ActivityModerationStatusApproved    ActivityModerationStatus = "APPROVED"
	ActivityModerationStatusRejected    ActivityModerationStatus = "REJECTED"
)

func (v ActivityModerationStatus) IsValid() bool {
	switch v {
	case ActivityModerationStatusNotRequired,
		ActivityModerationStatusApproved,
		ActivityModerationStatusRejected:
		return true
	default:
		return false
	}
}
