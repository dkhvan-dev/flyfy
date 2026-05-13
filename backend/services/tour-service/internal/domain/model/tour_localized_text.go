package model

import "strings"

type TourLocalizedText map[string]string

func NormalizeTourLocalizedText(input TourLocalizedText) TourLocalizedText {
	if len(input) == 0 {
		return nil
	}
	result := make(TourLocalizedText, len(input))
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

type TourIncludedItem struct {
	Text         string
	Translations TourLocalizedText
}

func NewTourIncludedItem(text string, translations TourLocalizedText) TourIncludedItem {
	return TourIncludedItem{
		Text:         strings.TrimSpace(text),
		Translations: NormalizeTourLocalizedText(translations),
	}
}
