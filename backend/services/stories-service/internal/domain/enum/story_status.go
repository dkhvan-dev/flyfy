package enum

type StoryStatus string

const (
	StoryStatusDraft     StoryStatus = "DRAFT"
	StoryStatusPublished StoryStatus = "PUBLISHED"
	StoryStatusArchived  StoryStatus = "ARCHIVED"
)

func (s StoryStatus) IsValid() bool {
	switch s {
	case StoryStatusDraft, StoryStatusPublished, StoryStatusArchived:
		return true
	default:
		return false
	}
}
