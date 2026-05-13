package model

import (
	"errors"
	"strings"
	"time"

	"github.com/google/uuid"
)

var (
	ErrInvalidTourItineraryID          = errors.New("invalid tour itinerary id")
	ErrInvalidTourItineraryOffset      = errors.New("invalid tour itinerary offset")
	ErrInvalidTourItineraryTitle       = errors.New("invalid tour itinerary title")
	ErrInvalidTourItineraryDescription = errors.New("invalid tour itinerary description")
	ErrInvalidTourItineraryDuration    = errors.New("invalid tour itinerary duration")
)

type TourItineraryItem struct {
	ID                 uuid.UUID
	TourID             uuid.UUID
	SortOrder          int
	StartOffsetMinutes int
	DurationMinutes    *int
	Title              string
	Description        string
	Translations       TourItineraryTranslations
	CreatedAt          time.Time
	UpdatedAt          time.Time
}

type TourItineraryLocalizedCopy struct {
	Title       string `json:"title,omitempty"`
	Description string `json:"description,omitempty"`
}

type TourItineraryTranslations map[string]TourItineraryLocalizedCopy

type NewTourItineraryItemParams struct {
	TourID             uuid.UUID
	SortOrder          int
	StartOffsetMinutes int
	DurationMinutes    *int
	Title              string
	Description        string
	Translations       TourItineraryTranslations
}

func NewTourItineraryItem(params NewTourItineraryItemParams) (*TourItineraryItem, error) {
	now := time.Now().UTC()
	item := &TourItineraryItem{
		ID:                 uuid.New(),
		TourID:             params.TourID,
		SortOrder:          params.SortOrder,
		StartOffsetMinutes: params.StartOffsetMinutes,
		DurationMinutes:    params.DurationMinutes,
		Title:              strings.TrimSpace(params.Title),
		Description:        strings.TrimSpace(params.Description),
		Translations:       NormalizeTourItineraryTranslations(params.Translations),
		CreatedAt:          now,
		UpdatedAt:          now,
	}
	if err := item.Validate(); err != nil {
		return nil, err
	}
	return item, nil
}

func (i *TourItineraryItem) Validate() error {
	if i.ID == uuid.Nil || i.TourID == uuid.Nil {
		return ErrInvalidTourItineraryID
	}
	if i.SortOrder < 0 || i.StartOffsetMinutes < 0 {
		return ErrInvalidTourItineraryOffset
	}
	if i.DurationMinutes != nil && *i.DurationMinutes <= 0 {
		return ErrInvalidTourItineraryDuration
	}
	if len(strings.TrimSpace(i.Title)) < 2 {
		return ErrInvalidTourItineraryTitle
	}
	if len(strings.TrimSpace(i.Description)) < 5 {
		return ErrInvalidTourItineraryDescription
	}
	return nil
}

func NormalizeTourItineraryTranslations(input TourItineraryTranslations) TourItineraryTranslations {
	if len(input) == 0 {
		return nil
	}
	result := make(TourItineraryTranslations, len(input))
	for locale, copy := range input {
		normalizedLocale := normalizeLocaleCode(locale)
		normalizedCopy := TourItineraryLocalizedCopy{
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
