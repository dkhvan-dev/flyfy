package enum

type StoryCategory string

const (
	StoryCategoryJournal    StoryCategory = "JOURNAL"
	StoryCategoryGuide      StoryCategory = "GUIDE"
	StoryCategoryPhotoEssay StoryCategory = "PHOTO_ESSAY"
	StoryCategoryCulinary   StoryCategory = "CULINARY"
)

func (c StoryCategory) IsValid() bool {
	switch c {
	case StoryCategoryJournal, StoryCategoryGuide, StoryCategoryPhotoEssay, StoryCategoryCulinary:
		return true
	default:
		return false
	}
}
