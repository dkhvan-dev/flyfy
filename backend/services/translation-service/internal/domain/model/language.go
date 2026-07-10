package model

import "strings"

type Language string

const (
	LanguageEnglish Language = "en"
	LanguageRussian Language = "ru"
	LanguageKazakh  Language = "kk"
)

func NormalizeLanguage(value string) (Language, bool) {
	normalized := strings.ToLower(strings.TrimSpace(value))
	normalized = strings.ReplaceAll(normalized, "_", "-")
	if index := strings.Index(normalized, "-"); index >= 0 {
		normalized = normalized[:index]
	}

	language := Language(normalized)
	if !language.IsSupported() {
		return "", false
	}
	return language, true
}

func (l Language) IsSupported() bool {
	switch l {
	case LanguageEnglish, LanguageRussian, LanguageKazakh:
		return true
	default:
		return false
	}
}

type ContentType string

const (
	ContentTypeAttraction   ContentType = "attraction"
	ContentTypeExcursion    ContentType = "excursion"
	ContentTypeActivity     ContentType = "activity"
	ContentTypeGuideProfile ContentType = "guide_profile"
	ContentTypeHelpArticle  ContentType = "help_article"
	ContentTypeAdminPublic  ContentType = "admin_public"
)

func NormalizeContentType(value string) (ContentType, bool) {
	contentType := ContentType(strings.ToLower(strings.TrimSpace(value)))
	if contentType == "" {
		return "", false
	}
	return contentType, contentType.IsPublicTranslatable()
}

func (t ContentType) IsPublicTranslatable() bool {
	switch t {
	case ContentTypeAttraction,
		ContentTypeExcursion,
		ContentTypeActivity,
		ContentTypeGuideProfile,
		ContentTypeHelpArticle,
		ContentTypeAdminPublic:
		return true
	default:
		return false
	}
}
