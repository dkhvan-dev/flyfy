package model

import (
	"errors"
	"math"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/excursion-service/internal/domain/enum"
)

var (
	ErrInvalidExcursionBookingID       = errors.New("invalid excursion booking id")
	ErrInvalidExcursionBookingOfferID  = errors.New("invalid excursion booking offer id")
	ErrInvalidExcursionBookingUserID   = errors.New("invalid excursion booking user id")
	ErrInvalidExcursionBookingSchedule = errors.New("invalid excursion booking schedule")
	ErrInvalidExcursionBookingGuests   = errors.New("invalid excursion booking guests")
	ErrInvalidExcursionBookingPrice    = errors.New("invalid excursion booking price")
	ErrInvalidExcursionBookingStatus   = errors.New("invalid excursion booking status")
)

const excursionBookingServiceFeeRate = 0.05

type ExcursionBooking struct {
	ID uuid.UUID

	ProductID         uuid.UUID
	OfferID           uuid.UUID
	ScheduleSlotID    *uuid.UUID
	LegacyExcursionID *uuid.UUID

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
	Status           enum.ExcursionBookingStatus
	IdempotencyKey   *string
	CancelledAt      *time.Time
	CancelledBy      *enum.ExcursionBookingCancelledBy
	CancelReason     *string
	RefundPercent    int
	RefundAmount     float64
	RefundCurrency   *string
	RefundPolicyCode *string
	RefundStatus     *string
	CheckedInAt      *time.Time
	CreatedAt        time.Time
	UpdatedAt        time.Time
}

type NewExcursionBookingParams struct {
	ProductID         uuid.UUID
	OfferID           uuid.UUID
	ScheduleSlotID    *uuid.UUID
	LegacyExcursionID *uuid.UUID
	GuideProfileID    uuid.UUID
	GuideUserID       uuid.UUID
	TouristUserID     uuid.UUID
	ScheduledFor      time.Time
	Adults            int
	Children          int
	UnitPriceAmount   float64
	Currency          string
	IdempotencyKey    *string
}

func NewExcursionBooking(params NewExcursionBookingParams) (*ExcursionBooking, error) {
	now := time.Now().UTC()
	totalSeats := params.Adults + params.Children
	subtotal := roundMoney(params.UnitPriceAmount * float64(totalSeats))
	serviceFee := roundMoney(subtotal * excursionBookingServiceFeeRate)

	item := &ExcursionBooking{
		ID:                uuid.New(),
		ProductID:         params.ProductID,
		OfferID:           params.OfferID,
		ScheduleSlotID:    NormalizeUUIDPointer(params.ScheduleSlotID),
		LegacyExcursionID: NormalizeUUIDPointer(params.LegacyExcursionID),
		GuideProfileID:    params.GuideProfileID,
		GuideUserID:       params.GuideUserID,
		TouristUserID:     params.TouristUserID,
		ScheduledFor:      params.ScheduledFor.UTC(),
		Adults:            params.Adults,
		Children:          params.Children,
		TotalSeats:        totalSeats,
		UnitPriceAmount:   params.UnitPriceAmount,
		ServiceFeeAmount:  serviceFee,
		TotalPriceAmount:  roundMoney(subtotal + serviceFee),
		Currency:          strings.ToUpper(strings.TrimSpace(params.Currency)),
		Status:            enum.ExcursionBookingStatusRequested,
		IdempotencyKey:    NormalizeOptionalString(params.IdempotencyKey),
		CreatedAt:         now,
		UpdatedAt:         now,
	}
	if err := item.Validate(); err != nil {
		return nil, err
	}
	return item, nil
}

func (b *ExcursionBooking) Validate() error {
	if b.ID == uuid.Nil {
		return ErrInvalidExcursionBookingID
	}
	if b.ProductID == uuid.Nil || b.OfferID == uuid.Nil {
		return ErrInvalidExcursionBookingOfferID
	}
	if b.GuideProfileID == uuid.Nil || b.GuideUserID == uuid.Nil || b.TouristUserID == uuid.Nil {
		return ErrInvalidExcursionBookingUserID
	}
	if b.ScheduledFor.IsZero() {
		return ErrInvalidExcursionBookingSchedule
	}
	if b.Adults < 1 || b.Children < 0 || b.TotalSeats != b.Adults+b.Children || b.TotalSeats < 1 {
		return ErrInvalidExcursionBookingGuests
	}
	if b.UnitPriceAmount < 0 || b.ServiceFeeAmount < 0 || b.TotalPriceAmount < 0 || strings.TrimSpace(b.Currency) == "" {
		return ErrInvalidExcursionBookingPrice
	}
	if !b.Status.IsValid() {
		return ErrInvalidExcursionBookingStatus
	}
	if b.CancelledBy != nil && !b.CancelledBy.IsValid() {
		return ErrInvalidExcursionBookingStatus
	}
	if b.RefundPercent < 0 || b.RefundPercent > 100 || b.RefundAmount < 0 {
		return ErrInvalidExcursionBookingPrice
	}
	return nil
}

func (b *ExcursionBooking) UpdateGuests(adults int, children int) error {
	totalSeats := adults + children
	subtotal := roundMoney(b.UnitPriceAmount * float64(totalSeats))
	serviceFee := roundMoney(subtotal * excursionBookingServiceFeeRate)

	b.Adults = adults
	b.Children = children
	b.TotalSeats = totalSeats
	b.ServiceFeeAmount = serviceFee
	b.TotalPriceAmount = roundMoney(subtotal + serviceFee)
	b.UpdatedAt = time.Now().UTC()

	return b.Validate()
}

func (b *ExcursionBooking) Cancel(
	cancelledBy enum.ExcursionBookingCancelledBy,
	reason string,
	refundPercent int,
	refundAmount float64,
	refundCurrency string,
	refundPolicyCode string,
	refundStatus string,
) error {
	now := time.Now().UTC()
	normalizedReason := strings.TrimSpace(reason)
	normalizedRefundCurrency := strings.ToUpper(strings.TrimSpace(refundCurrency))
	normalizedPolicy := strings.TrimSpace(refundPolicyCode)
	normalizedRefundStatus := strings.TrimSpace(refundStatus)

	b.Status = enum.ExcursionBookingStatusCancelled
	b.CancelledAt = &now
	b.CancelledBy = &cancelledBy
	b.CancelReason = NormalizeOptionalString(&normalizedReason)
	b.RefundPercent = refundPercent
	b.RefundAmount = roundMoney(refundAmount)
	b.RefundCurrency = NormalizeOptionalString(&normalizedRefundCurrency)
	b.RefundPolicyCode = NormalizeOptionalString(&normalizedPolicy)
	b.RefundStatus = NormalizeOptionalString(&normalizedRefundStatus)
	b.UpdatedAt = now

	return b.Validate()
}

func (b *ExcursionBooking) MarkCheckedIn(checkedInAt time.Time) error {
	if b.Status != enum.ExcursionBookingStatusRequested || b.CancelledAt != nil {
		return ErrInvalidExcursionBookingStatus
	}
	ts := checkedInAt.UTC()
	b.CheckedInAt = &ts
	b.UpdatedAt = ts
	return b.Validate()
}

func roundMoney(value float64) float64 {
	return math.Round(value*100) / 100
}
