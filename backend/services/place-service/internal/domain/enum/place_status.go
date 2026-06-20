package enum

type PlaceStatus string

const (
	StatusDraft     PlaceStatus = "DRAFT"
	StatusPublished PlaceStatus = "PUBLISHED"
)

func (s PlaceStatus) IsValid() bool {
	return s == StatusDraft || s == StatusPublished
}

func (s PlaceStatus) String() string {
	return string(s)
}
