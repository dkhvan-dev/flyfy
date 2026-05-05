package enum

type ActivityEventType string

const (
	ActivityEventTypeCreated               ActivityEventType = "CREATED"
	ActivityEventTypeUpdated               ActivityEventType = "UPDATED"
	ActivityEventTypeSubmittedForReview    ActivityEventType = "SUBMITTED_FOR_REVIEW"
	ActivityEventTypeModerationApproved    ActivityEventType = "MODERATION_APPROVED"
	ActivityEventTypeModerationRejected    ActivityEventType = "MODERATION_REJECTED"
	ActivityEventTypePublished             ActivityEventType = "PUBLISHED"
	ActivityEventTypeUnpublished           ActivityEventType = "UNPUBLISHED"
	ActivityEventTypeStarted               ActivityEventType = "STARTED"
	ActivityEventTypeCompleted             ActivityEventType = "COMPLETED"
	ActivityEventTypeCancelled             ActivityEventType = "CANCELLED"
	ActivityEventTypeExtended              ActivityEventType = "EXTENDED"
	ActivityEventTypeDuplicated            ActivityEventType = "DUPLICATED"
	ActivityEventTypeCapacityChanged       ActivityEventType = "CAPACITY_CHANGED"
	ActivityEventTypePriceChanged          ActivityEventType = "PRICE_CHANGED"
	ActivityEventTypeLocationChanged       ActivityEventType = "LOCATION_CHANGED"
	ActivityEventTypeRegistrationClosed    ActivityEventType = "REGISTRATION_CLOSED"
	ActivityEventTypeRegistrationReopened  ActivityEventType = "REGISTRATION_REOPENED"
	ActivityEventTypeRegistrationFinalized ActivityEventType = "REGISTRATION_FINALIZED"
)

func (v ActivityEventType) IsValid() bool {
	switch v {
	case ActivityEventTypeCreated,
		ActivityEventTypeUpdated,
		ActivityEventTypeSubmittedForReview,
		ActivityEventTypeModerationApproved,
		ActivityEventTypeModerationRejected,
		ActivityEventTypePublished,
		ActivityEventTypeUnpublished,
		ActivityEventTypeStarted,
		ActivityEventTypeCompleted,
		ActivityEventTypeCancelled,
		ActivityEventTypeExtended,
		ActivityEventTypeDuplicated,
		ActivityEventTypeCapacityChanged,
		ActivityEventTypePriceChanged,
		ActivityEventTypeLocationChanged,
		ActivityEventTypeRegistrationClosed,
		ActivityEventTypeRegistrationReopened,
		ActivityEventTypeRegistrationFinalized:
		return true
	default:
		return false
	}
}
