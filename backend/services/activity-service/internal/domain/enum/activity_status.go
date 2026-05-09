package enum

type ActivityStatus string

const (
	ActivityStatusPublished           ActivityStatus = "PUBLISHED"
	ActivityStatusEnrollmentOpen      ActivityStatus = "ENROLLMENT_OPEN"
	ActivityStatusFull                ActivityStatus = "FULL"
	ActivityStatusRegistrationClosed  ActivityStatus = "REGISTRATION_CLOSED"
	ActivityStatusConfirmationPending ActivityStatus = "CONFIRMATION_PENDING"
	ActivityStatusConfirmed           ActivityStatus = "CONFIRMED"
	ActivityStatusStarted             ActivityStatus = "STARTED"
	ActivityStatusCompleted           ActivityStatus = "COMPLETED"
	ActivityStatusCancelled           ActivityStatus = "CANCELLED"
	ActivityStatusArchived            ActivityStatus = "ARCHIVED"
)

func (v ActivityStatus) IsValid() bool {
	switch v {
	case ActivityStatusPublished,
		ActivityStatusEnrollmentOpen,
		ActivityStatusFull,
		ActivityStatusRegistrationClosed,
		ActivityStatusConfirmationPending,
		ActivityStatusConfirmed,
		ActivityStatusStarted,
		ActivityStatusCompleted,
		ActivityStatusCancelled,
		ActivityStatusArchived:
		return true
	default:
		return false
	}
}

func (v ActivityStatus) IsTerminal() bool {
	switch v {
	case ActivityStatusCompleted, ActivityStatusCancelled, ActivityStatusArchived:
		return true
	default:
		return false
	}
}
