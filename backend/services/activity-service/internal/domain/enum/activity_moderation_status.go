package enum

type ActivityModerationStatus string

const (
	ActivityModerationStatusNotRequired   ActivityModerationStatus = "NOT_REQUIRED"
	ActivityModerationStatusPendingReview ActivityModerationStatus = "PENDING_REVIEW"
	ActivityModerationStatusApproved      ActivityModerationStatus = "APPROVED"
	ActivityModerationStatusRejected      ActivityModerationStatus = "REJECTED"
)

func (v ActivityModerationStatus) IsValid() bool {
	switch v {
	case ActivityModerationStatusNotRequired,
		ActivityModerationStatusPendingReview,
		ActivityModerationStatusApproved,
		ActivityModerationStatusRejected:
		return true
	default:
		return false
	}
}
