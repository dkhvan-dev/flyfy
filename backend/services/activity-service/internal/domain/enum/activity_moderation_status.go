package enum

type ActivityModerationStatus string

const (
	ActivityModerationStatusNotRequired ActivityModerationStatus = "NOT_REQUIRED"
	ActivityModerationStatusFlagged     ActivityModerationStatus = "FLAGGED"
	ActivityModerationStatusInReview    ActivityModerationStatus = "IN_REVIEW"
	ActivityModerationStatusApproved    ActivityModerationStatus = "APPROVED"
	ActivityModerationStatusRejected    ActivityModerationStatus = "REJECTED"
)

func (v ActivityModerationStatus) IsValid() bool {
	switch v {
	case ActivityModerationStatusNotRequired,
		ActivityModerationStatusFlagged,
		ActivityModerationStatusInReview,
		ActivityModerationStatusApproved,
		ActivityModerationStatusRejected:
		return true
	default:
		return false
	}
}
