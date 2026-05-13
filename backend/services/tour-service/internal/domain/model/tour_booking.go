package model

import (
	"errors"
	"math"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/tour-service/internal/domain/enum"
)

var (
	ErrInvalidTourBookingID       = errors.New("invalid tour booking id")
	ErrInvalidTourBookingOfferID  = errors.New("invalid tour booking offer id")
	ErrInvalidTourBookingUserID   = errors.New("invalid tour booking user id")
	ErrInvalidTourBookingSchedule = errors.New("invalid tour booking schedule")
	ErrInvalidTourBookingGuests   = errors.New("invalid tour booking guests")
	ErrInvalidTourBookingPrice    = errors.New("invalid tour booking price")
	ErrInvalidTourBookingStatus   = errors.New("invalid tour booking status")
)

const tourBookingServiceFeeRate = 0.05

type TourBooking struct {
	ID uuid.UUID

	ProductID    uuid.UUID
	OfferID      uuid.UUID
	LegacyTourID *uuid.UUID

	GuideProfileID uuid.UUID
	GuideUserID    uuid.UUID
	TouristUserID  uuid.UUID

	ScheduledFor time.Time
	Adults       int
	Children     int
	TotalSeats   int

	UnitPriceAmount  float64
	ServiceFeeAmount float64
	TotalPriceAmount float64
	Currency         string
	Status           enum.TourBookingStatus
	IdempotencyKey   *string
	CancelledAt      *time.Time
	CancelReason     *string
	CreatedAt        time.Time
	UpdatedAt        time.Time
}

type NewTourBookingParams struct {
	ProductID       uuid.UUID
	OfferID         uuid.UUID
	LegacyTourID    *uuid.UUID
	GuideProfileID  uuid.UUID
	GuideUserID     uuid.UUID
	TouristUserID   uuid.UUID
	ScheduledFor    time.Time
	Adults          int
	Children        int
	UnitPriceAmount float64
	Currency        string
	IdempotencyKey  *string
}

func NewTourBooking(params NewTourBookingParams) (*TourBooking, error) {
	now := time.Now().UTC()
	totalSeats := params.Adults + params.Children
	subtotal := roundMoney(params.UnitPriceAmount * float64(totalSeats))
	serviceFee := roundMoney(subtotal * tourBookingServiceFeeRate)

	item := &TourBooking{
		ID:               uuid.New(),
		ProductID:        params.ProductID,
		OfferID:          params.OfferID,
		LegacyTourID:     NormalizeUUIDPointer(params.LegacyTourID),
		GuideProfileID:   params.GuideProfileID,
		GuideUserID:      params.GuideUserID,
		TouristUserID:    params.TouristUserID,
		ScheduledFor:     params.ScheduledFor.UTC(),
		Adults:           params.Adults,
		Children:         params.Children,
		TotalSeats:       totalSeats,
		UnitPriceAmount:  params.UnitPriceAmount,
		ServiceFeeAmount: serviceFee,
		TotalPriceAmount: roundMoney(subtotal + serviceFee),
		Currency:         strings.ToUpper(strings.TrimSpace(params.Currency)),
		Status:           enum.TourBookingStatusRequested,
		IdempotencyKey:   NormalizeOptionalString(params.IdempotencyKey),
		CreatedAt:        now,
		UpdatedAt:        now,
	}
	if err := item.Validate(); err != nil {
		return nil, err
	}
	return item, nil
}

func (b *TourBooking) Validate() error {
	if b.ID == uuid.Nil {
		return ErrInvalidTourBookingID
	}
	if b.ProductID == uuid.Nil || b.OfferID == uuid.Nil {
		return ErrInvalidTourBookingOfferID
	}
	if b.GuideProfileID == uuid.Nil || b.GuideUserID == uuid.Nil || b.TouristUserID == uuid.Nil {
		return ErrInvalidTourBookingUserID
	}
	if b.ScheduledFor.IsZero() {
		return ErrInvalidTourBookingSchedule
	}
	if b.Adults < 1 || b.Children < 0 || b.TotalSeats != b.Adults+b.Children || b.TotalSeats < 1 {
		return ErrInvalidTourBookingGuests
	}
	if b.UnitPriceAmount < 0 || b.ServiceFeeAmount < 0 || b.TotalPriceAmount < 0 || strings.TrimSpace(b.Currency) == "" {
		return ErrInvalidTourBookingPrice
	}
	if !b.Status.IsValid() {
		return ErrInvalidTourBookingStatus
	}
	return nil
}

func roundMoney(value float64) float64 {
	return math.Round(value*100) / 100
}
