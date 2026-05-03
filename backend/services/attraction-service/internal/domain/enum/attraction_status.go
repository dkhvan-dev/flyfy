package enum

type AttractionStatus string

const (
	StatusDraft     AttractionStatus = "DRAFT"
	StatusPublished AttractionStatus = "PUBLISHED"
)

func (s AttractionStatus) IsValid() bool {
	return s == StatusDraft || s == StatusPublished
}

func (s AttractionStatus) String() string {
	return string(s)
}
