package enum

import "strings"

type PostFormat string

const (
	PostFormatPost       PostFormat = "POST"
	PostFormatGuide      PostFormat = "GUIDE"
	PostFormatPhotoEssay PostFormat = "PHOTO_ESSAY"
	PostFormatArticle    PostFormat = "ARTICLE"
	PostFormatCulinary   PostFormat = "CULINARY"
)

func (f PostFormat) IsValid() bool {
	switch f {
	case PostFormatPost, PostFormatGuide, PostFormatPhotoEssay, PostFormatArticle, PostFormatCulinary:
		return true
	default:
		return false
	}
}

func NormalizePostFormat(format PostFormat) PostFormat {
	normalized := PostFormat(strings.ToUpper(strings.TrimSpace(string(format))))
	if normalized == "" {
		return PostFormatArticle
	}
	return normalized
}
