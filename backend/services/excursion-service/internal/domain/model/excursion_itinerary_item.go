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
)

type ExcursionItineraryItem struct {
	ID                 uuid.UUID
	ExcursionID        uuid.UUID
	SortOrder          int
	StartOffsetMinutes int
	DurationMinutes    *int
	Title              string
	Description        string
	Translations       ExcursionItineraryTranslations
	CreatedAt          time.Time
	UpdatedAt          time.Time
}

type ExcursionItineraryLocalizedCopy struct {
	Title       string `json:"title,omitempty"`
	Description string `json:"description,omitempty"`
}

type ExcursionItineraryTranslations map[string]ExcursionItineraryLocalizedCopy

type NewExcursionItineraryItemParams struct {
	ExcursionID        uuid.UUID
	SortOrder          int
	StartOffsetMinutes int
	DurationMinutes    *int
	Title              string
	Description        string
	Translations       ExcursionItineraryTranslations
}

func NewExcursionItineraryItem(params NewExcursionItineraryItemParams) (*ExcursionItineraryItem, error) {
	now := time.Now().UTC()
	item := &ExcursionItineraryItem{
		ID:                 uuid.New(),
		ExcursionID:        params.ExcursionID,
		SortOrder:          params.SortOrder,
		StartOffsetMinutes: params.StartOffsetMinutes,
		DurationMinutes:    params.DurationMinutes,
		Title:              strings.TrimSpace(params.Title),
		Description:        strings.TrimSpace(params.Description),
		Translations:       NormalizeExcursionItineraryTranslations(params.Translations),
		CreatedAt:          now,
		UpdatedAt:          now,
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
	if len(strings.TrimSpace(i.Title)) < 2 {
		return ErrInvalidExcursionItineraryTitle
	}
	if len(strings.TrimSpace(i.Description)) < 5 {
		return ErrInvalidExcursionItineraryDescription
	}
	return nil
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
