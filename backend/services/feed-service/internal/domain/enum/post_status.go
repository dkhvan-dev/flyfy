package enum

type PostStatus string

const (
	PostStatusDraft     PostStatus = "DRAFT"
	PostStatusPublished PostStatus = "PUBLISHED"
	PostStatusArchived  PostStatus = "ARCHIVED"
)

func (s PostStatus) IsValid() bool {
	switch s {
	case PostStatusDraft, PostStatusPublished, PostStatusArchived:
		return true
	default:
		return false
	}
}
