package enum

type PostCategory string

const (
	PostCategoryJournal    PostCategory = "JOURNAL"
	PostCategoryGuide      PostCategory = "GUIDE"
	PostCategoryPhotoEssay PostCategory = "PHOTO_ESSAY"
	PostCategoryCulinary   PostCategory = "CULINARY"
)

func (c PostCategory) IsValid() bool {
	switch c {
	case PostCategoryJournal, PostCategoryGuide, PostCategoryPhotoEssay, PostCategoryCulinary:
		return true
	default:
		return false
	}
}
