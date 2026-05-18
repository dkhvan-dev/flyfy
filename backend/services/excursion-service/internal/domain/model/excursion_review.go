package model

import (
	"errors"
	"strings"
	"time"

	"github.com/google/uuid"
)

var (
	ErrInvalidExcursionReviewID      = errors.New("invalid excursion review id")
	ErrInvalidExcursionReviewBooking = errors.New("invalid excursion review booking")
	ErrInvalidExcursionReviewUser    = errors.New("invalid excursion review user")
	ErrInvalidExcursionReviewRating  = errors.New("invalid excursion review rating")
	ErrInvalidExcursionReviewComment = errors.New("invalid excursion review comment")
	ErrExcursionReviewAlreadyExists  = errors.New("excursion review already exists")
)

const maxExcursionReviewCommentLength = 2000

type ExcursionReview struct {
	ID uuid.UUID

	BookingID         uuid.UUID
	ProductID         uuid.UUID
	OfferID           uuid.UUID
	LegacyExcursionID *uuid.UUID
	LandmarkID        *uuid.UUID
	LandmarkName      *string

	GuideProfileID   uuid.UUID
	GuideUserID      uuid.UUID
	GuideDisplayName string
	TouristUserID    uuid.UUID

	Rating    float64
	Comment   string
	CreatedAt time.Time
	UpdatedAt time.Time
}

type ExcursionBookingListItem struct {
	Booking *ExcursionBooking
	Review  *ExcursionReview

	Title            string
	Summary          string
	LandmarkID       *uuid.UUID
	LandmarkName     *string
	CategorySlug     string
	CountryCode      *string
	CityName         *string
	CoverFileID      *uuid.UUID
	GuideDisplayName string
	MaxGroupSize     int
}

type NewExcursionReviewParams struct {
	Booking *ExcursionBooking
	Rating  float64
	Comment string
}

func NewExcursionReview(params NewExcursionReviewParams) (*ExcursionReview, error) {
	now := time.Now().UTC()
	booking := params.Booking
	if booking == nil {
		return nil, ErrInvalidExcursionReviewBooking
	}
	item := &ExcursionReview{
		ID:                uuid.New(),
		BookingID:         booking.ID,
		ProductID:         booking.ProductID,
		OfferID:           booking.OfferID,
		LegacyExcursionID: NormalizeUUIDPointer(booking.LegacyExcursionID),
		GuideProfileID:    booking.GuideProfileID,
		GuideUserID:       booking.GuideUserID,
		TouristUserID:     booking.TouristUserID,
		Rating:            params.Rating,
		Comment:           strings.TrimSpace(params.Comment),
		CreatedAt:         now,
		UpdatedAt:         now,
	}
	if err := item.Validate(); err != nil {
		return nil, err
	}
	return item, nil
}

func (r *ExcursionReview) Validate() error {
	if r.ID == uuid.Nil {
		return ErrInvalidExcursionReviewID
	}
	if r.BookingID == uuid.Nil || r.ProductID == uuid.Nil || r.OfferID == uuid.Nil {
		return ErrInvalidExcursionReviewBooking
	}
	if r.GuideProfileID == uuid.Nil || r.GuideUserID == uuid.Nil || r.TouristUserID == uuid.Nil {
		return ErrInvalidExcursionReviewUser
	}
	if r.Rating < 1 || r.Rating > 5 {
		return ErrInvalidExcursionReviewRating
	}
	r.Comment = strings.TrimSpace(r.Comment)
	if r.Comment == "" || len([]rune(r.Comment)) > maxExcursionReviewCommentLength {
		return ErrInvalidExcursionReviewComment
	}
	return nil
}
