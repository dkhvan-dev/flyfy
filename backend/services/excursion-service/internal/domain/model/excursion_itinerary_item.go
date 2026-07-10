package model

import (
	"errors"
	"strings"
	"time"

	"github.com/google/uuid"
)

var (
	ErrInvalidExcursionItineraryID          = errors.New("invalid excursion itinerary id")
	ErrInvalidExcursionItineraryOffset      = errors.New("invalid excursion itinerary offset")
	ErrInvalidExcursionItineraryTitle       = errors.New("invalid excursion itinerary title")
	ErrInvalidExcursionItineraryDescription = errors.New("invalid excursion itinerary description")
	ErrInvalidExcursionItineraryDuration    = errors.New("invalid excursion itinerary duration")
	ErrInvalidExcursionItineraryTravelTime  = errors.New("invalid excursion itinerary travel time")
)

type ExcursionItineraryItem struct {
	ID                        uuid.UUID
	ExcursionID               uuid.UUID
	SortOrder                 int
	StartOffsetMinutes        int
	DurationMinutes           *int
	PlaceID                   *uuid.UUID
	PlaceName                 *string
	Latitude                  *float64
	Longitude                 *float64
	TravelFromPreviousMinutes *int
	Title                     string
	Description               string
	Translations              ExcursionItineraryTranslations
	CreatedAt                 time.Time
	UpdatedAt                 time.Time
}

type ExcursionItineraryLocalizedCopy struct {
	Title       string `json:"title,omitempty"`
	Description string `json:"description,omitempty"`
}

type ExcursionItineraryTranslations map[string]ExcursionItineraryLocalizedCopy

type NewExcursionItineraryItemParams struct {
	ExcursionID               uuid.UUID
	SortOrder                 int
	StartOffsetMinutes        int
	DurationMinutes           *int
	PlaceID                   *uuid.UUID
	PlaceName                 *string
	Latitude                  *float64
	Longitude                 *float64
	TravelFromPreviousMinutes *int
	Title                     string
	Description               string
	Translations              ExcursionItineraryTranslations
}

func NewExcursionItineraryItem(params NewExcursionItineraryItemParams) (*ExcursionItineraryItem, error) {
	now := time.Now().UTC()
	item := &ExcursionItineraryItem{
		ID:                        uuid.New(),
		ExcursionID:               params.ExcursionID,
		SortOrder:                 params.SortOrder,
		StartOffsetMinutes:        params.StartOffsetMinutes,
		DurationMinutes:           copyOptionalInt(params.DurationMinutes),
		PlaceID:                   normalizeOptionalUUID(params.PlaceID),
		PlaceName:                 NormalizeOptionalString(params.PlaceName),
		Latitude:                  copyOptionalFloat64(params.Latitude),
		Longitude:                 copyOptionalFloat64(params.Longitude),
		TravelFromPreviousMinutes: copyOptionalInt(params.TravelFromPreviousMinutes),
		Title:                     strings.TrimSpace(params.Title),
		Description:               strings.TrimSpace(params.Description),
		Translations:              NormalizeExcursionItineraryTranslations(params.Translations),
		CreatedAt:                 now,
		UpdatedAt:                 now,
	}
	if err := item.Validate(); err != nil {
		return nil, err
	}
	return item, nil
}

func (i *ExcursionItineraryItem) Validate() error {
	if i.ID == uuid.Nil || i.ExcursionID == uuid.Nil {
		return ErrInvalidExcursionItineraryID
	}
	if i.SortOrder < 0 || i.StartOffsetMinutes < 0 {
		return ErrInvalidExcursionItineraryOffset
	}
	if i.DurationMinutes != nil && *i.DurationMinutes <= 0 {
		return ErrInvalidExcursionItineraryDuration
	}
	if i.TravelFromPreviousMinutes != nil && *i.TravelFromPreviousMinutes < 0 {
		return ErrInvalidExcursionItineraryTravelTime
	}
	if len(strings.TrimSpace(i.Title)) < 2 {
		return ErrInvalidExcursionItineraryTitle
	}
	if len(strings.TrimSpace(i.Description)) < 5 {
		return ErrInvalidExcursionItineraryDescription
	}
	return nil
}

func normalizeOptionalUUID(input *uuid.UUID) *uuid.UUID {
	if input == nil || *input == uuid.Nil {
		return nil
	}
	value := *input
	return &value
}

func copyOptionalInt(input *int) *int {
	if input == nil {
		return nil
	}
	value := *input
	return &value
}

func copyOptionalFloat64(input *float64) *float64 {
	if input == nil {
		return nil
	}
	value := *input
	return &value
}

func NormalizeExcursionItineraryTranslations(input ExcursionItineraryTranslations) ExcursionItineraryTranslations {
	if len(input) == 0 {
		return nil
	}
	result := make(ExcursionItineraryTranslations, len(input))
	for locale, copy := range input {
		normalizedLocale := normalizeLocaleCode(locale)
		normalizedCopy := ExcursionItineraryLocalizedCopy{
			Title:       strings.Join(strings.Fields(strings.TrimSpace(copy.Title)), " "),
			Description: strings.TrimSpace(copy.Description),
		}
		if normalizedLocale == "" || (normalizedCopy.Title == "" && normalizedCopy.Description == "") {
			continue
		}
		result[normalizedLocale] = normalizedCopy
	}
	if len(result) == 0 {
		return nil
	}
	return result
}

func (i *ExcursionItineraryItem) SourceCopyForLanguage(language string) ExcursionItineraryLocalizedCopy {
	if i == nil {
		return ExcursionItineraryLocalizedCopy{}
	}
	normalizedLanguage, ok := NormalizeExcursionTranslationLanguage(language)
	if !ok {
		return ExcursionItineraryLocalizedCopy{}
	}
	copy := NormalizeExcursionItineraryTranslations(i.Translations)[normalizedLanguage]
	if strings.TrimSpace(copy.Title) == "" {
		copy.Title = strings.TrimSpace(i.Title)
	}
	if strings.TrimSpace(copy.Description) == "" {
		copy.Description = strings.TrimSpace(i.Description)
	}
	return copy
}

func (i *ExcursionItineraryItem) HasCompleteTranslationForLanguage(language string) bool {
	if i == nil {
		return false
	}
	normalizedLanguage, ok := NormalizeExcursionTranslationLanguage(language)
	if !ok {
		return false
	}
	copy, exists := NormalizeExcursionItineraryTranslations(i.Translations)[normalizedLanguage]
	return exists && strings.TrimSpace(copy.Title) != "" && strings.TrimSpace(copy.Description) != ""
}
