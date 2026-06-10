package enum

import "strings"

type StoryFormat string

const (
	StoryFormatStory      StoryFormat = "STORY"
	StoryFormatGuide      StoryFormat = "GUIDE"
	StoryFormatPhotoEssay StoryFormat = "PHOTO_ESSAY"
	StoryFormatArticle    StoryFormat = "ARTICLE"
	StoryFormatCulinary   StoryFormat = "CULINARY"
)

func (f StoryFormat) IsValid() bool {
	switch f {
	case StoryFormatStory, StoryFormatGuide, StoryFormatPhotoEssay, StoryFormatArticle, StoryFormatCulinary:
		return true
	default:
		return false
	}
}

func NormalizeStoryFormat(format StoryFormat) StoryFormat {
	normalized := StoryFormat(strings.ToUpper(strings.TrimSpace(string(format))))
	if normalized == "" {
		return StoryFormatStory
	}
	return normalized
}
