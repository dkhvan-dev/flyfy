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
	CreatedAt          time.Time
	UpdatedAt          time.Time
}

type NewTourItineraryItemParams struct {
	TourID             uuid.UUID
	SortOrder          int
	StartOffsetMinutes int
	DurationMinutes    *int
	Title              string
	Description        string
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
