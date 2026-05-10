package enum

type TourStatus string

const (
	TourStatusDraft     TourStatus = "DRAFT"
	TourStatusPublished TourStatus = "PUBLISHED"
	TourStatusArchived  TourStatus = "ARCHIVED"
)

func (s TourStatus) IsValid() bool {
	switch s {
	case TourStatusDraft, TourStatusPublished, TourStatusArchived:
		return true
	default:
		return false
	}
}

type TourVisibility string

const (
	TourVisibilityPublic   TourVisibility = "PUBLIC"
	TourVisibilityUnlisted TourVisibility = "UNLISTED"
	TourVisibilityPrivate  TourVisibility = "PRIVATE"
)

func (v TourVisibility) IsValid() bool {
	switch v {
	case TourVisibilityPublic, TourVisibilityUnlisted, TourVisibilityPrivate:
		return true
	default:
		return false
	}
}

type TourEventType string

const (
	TourEventTypeCreated   TourEventType = "CREATED"
	TourEventTypeUpdated   TourEventType = "UPDATED"
	TourEventTypePublished TourEventType = "PUBLISHED"
	TourEventTypeArchived  TourEventType = "ARCHIVED"
	TourEventTypeDeleted   TourEventType = "DELETED"
)

func (e TourEventType) IsValid() bool {
	switch e {
	case TourEventTypeCreated,
		TourEventTypeUpdated,
		TourEventTypePublished,
		TourEventTypeArchived,
		TourEventTypeDeleted:
		return true
	default:
		return false
	}
}
