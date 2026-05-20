package model

import (
	"strings"
	"time"

	"github.com/google/uuid"
)

type GuideReview struct {
	ID uuid.UUID

	BookingID uuid.UUID
	ProductID uuid.UUID
	OfferID   uuid.UUID

	GuideProfileID uuid.UUID
	GuideUserID    uuid.UUID
	TouristUserID  uuid.UUID
	Author         ExcursionReviewAuthor

	Rating    float64
	Comment   string
	CreatedAt time.Time
	UpdatedAt time.Time
	DeletedAt *time.Time
}

type NewGuideReviewParams struct {
	Booking *ExcursionBooking
	Rating  float64
	Comment string
}

func NewGuideReview(params NewGuideReviewParams) (*GuideReview, error) {
	now := time.Now().UTC()
	booking := params.Booking
	if booking == nil {
		return nil, ErrInvalidExcursionReviewBooking
	}
	item := &GuideReview{
		ID:             uuid.New(),
		BookingID:      booking.ID,
		ProductID:      booking.ProductID,
		OfferID:        booking.OfferID,
		GuideProfileID: booking.GuideProfileID,
		GuideUserID:    booking.GuideUserID,
		TouristUserID:  booking.TouristUserID,
		Author: ExcursionReviewAuthor{
			UserID: booking.TouristUserID,
		},
		Rating:    params.Rating,
		Comment:   strings.TrimSpace(params.Comment),
		CreatedAt: now,
		UpdatedAt: now,
	}
	if err := item.Validate(); err != nil {
		return nil, err
	}
	return item, nil
}

func (r *GuideReview) Validate() error {
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
	if len([]rune(r.Comment)) > maxExcursionReviewCommentLength {
		return ErrInvalidExcursionReviewComment
	}
	return nil
}

func (r *GuideReview) Update(rating float64, comment string) error {
	r.Rating = rating
	r.Comment = strings.TrimSpace(comment)
	r.UpdatedAt = time.Now().UTC()
	return r.Validate()
}

func (r *GuideReview) SoftDelete() {
	now := time.Now().UTC()
	r.DeletedAt = &now
	r.UpdatedAt = now
}
