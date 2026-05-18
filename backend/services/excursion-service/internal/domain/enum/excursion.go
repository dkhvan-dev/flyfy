package enum

type ExcursionStatus string

const (
	ExcursionStatusDraft     ExcursionStatus = "DRAFT"
	ExcursionStatusPublished ExcursionStatus = "PUBLISHED"
	ExcursionStatusArchived  ExcursionStatus = "ARCHIVED"
)

func (s ExcursionStatus) IsValid() bool {
	switch s {
	case ExcursionStatusDraft, ExcursionStatusPublished, ExcursionStatusArchived:
		return true
	default:
		return false
	}
}

type ExcursionVisibility string

const (
	ExcursionVisibilityPublic   ExcursionVisibility = "PUBLIC"
	ExcursionVisibilityUnlisted ExcursionVisibility = "UNLISTED"
	ExcursionVisibilityPrivate  ExcursionVisibility = "PRIVATE"
)

func (v ExcursionVisibility) IsValid() bool {
	switch v {
	case ExcursionVisibilityPublic, ExcursionVisibilityUnlisted, ExcursionVisibilityPrivate:
		return true
	default:
		return false
	}
}

type ExcursionEventType string

const (
	ExcursionEventTypeCreated   ExcursionEventType = "CREATED"
	ExcursionEventTypeUpdated   ExcursionEventType = "UPDATED"
	ExcursionEventTypePublished ExcursionEventType = "PUBLISHED"
	ExcursionEventTypeArchived  ExcursionEventType = "ARCHIVED"
	ExcursionEventTypeDeleted   ExcursionEventType = "DELETED"
)

func (e ExcursionEventType) IsValid() bool {
	switch e {
	case ExcursionEventTypeCreated,
		ExcursionEventTypeUpdated,
		ExcursionEventTypePublished,
		ExcursionEventTypeArchived,
		ExcursionEventTypeDeleted:
		return true
	default:
		return false
	}
}

type ExcursionBookingStatus string

const (
	ExcursionBookingStatusRequested ExcursionBookingStatus = "REQUESTED"
	ExcursionBookingStatusCancelled ExcursionBookingStatus = "CANCELLED"
)

func (s ExcursionBookingStatus) IsValid() bool {
	switch s {
	case ExcursionBookingStatusRequested, ExcursionBookingStatusCancelled:
		return true
	default:
		return false
	}
}

type ExcursionBookingCancelledBy string

const (
	ExcursionBookingCancelledByTourist ExcursionBookingCancelledBy = "TOURIST"
	ExcursionBookingCancelledByGuide   ExcursionBookingCancelledBy = "GUIDE"
	ExcursionBookingCancelledBySystem  ExcursionBookingCancelledBy = "SYSTEM"
)

func (s ExcursionBookingCancelledBy) IsValid() bool {
	switch s {
	case ExcursionBookingCancelledByTourist,
		ExcursionBookingCancelledByGuide,
		ExcursionBookingCancelledBySystem:
		return true
	default:
		return false
	}
}
