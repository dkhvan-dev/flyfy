package model

import "strings"

type ExcursionLocalizedText map[string]string

func NormalizeExcursionLocalizedText(input ExcursionLocalizedText) ExcursionLocalizedText {
	if len(input) == 0 {
		return nil
	}
	result := make(ExcursionLocalizedText, len(input))
	for locale, value := range input {
		normalizedLocale := normalizeLocaleCode(locale)
		normalizedValue := strings.Join(strings.Fields(strings.TrimSpace(value)), " ")
		if normalizedLocale == "" || normalizedValue == "" {
			continue
		}
		result[normalizedLocale] = normalizedValue
	}
	if len(result) == 0 {
		return nil
	}
	return result
}

type ExcursionIncludedItem struct {
	Text         string
	Translations ExcursionLocalizedText
}

func NewExcursionIncludedItem(text string, translations ExcursionLocalizedText) ExcursionIncludedItem {
	return ExcursionIncludedItem{
		Text:         strings.TrimSpace(text),
		Translations: NormalizeExcursionLocalizedText(translations),
	}
}
