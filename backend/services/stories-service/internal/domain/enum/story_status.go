package enum

type StoryStatus string

const (
	StoryStatusDraft     StoryStatus = "DRAFT"
	StoryStatusPublished StoryStatus = "PUBLISHED"
)

func (s StoryStatus) IsValid() bool {
	switch s {
	case StoryStatusDraft, StoryStatusPublished:
		return true
	default:
		return false
	}
}
