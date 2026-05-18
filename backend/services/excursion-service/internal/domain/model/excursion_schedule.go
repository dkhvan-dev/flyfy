package model

import (
	"errors"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/excursion-service/internal/domain/enum"
)

var (
	ErrInvalidExcursionScheduleID            = errors.New("invalid excursion schedule id")
	ErrInvalidExcursionScheduleGuide         = errors.New("invalid excursion schedule guide")
	ErrInvalidExcursionScheduleOffer         = errors.New("invalid excursion schedule offer")
	ErrInvalidExcursionScheduleInterval      = errors.New("invalid excursion schedule interval")
	ErrInvalidExcursionScheduleTimezone      = errors.New("invalid excursion schedule timezone")
	ErrInvalidExcursionScheduleCapacity      = errors.New("invalid excursion schedule capacity")
	ErrExcursionScheduleCancelReasonRequired = errors.New("excursion schedule cancel reason is required")
	ErrExcursionScheduleBookedDeleteDenied   = errors.New("excursion schedule with booked seats cannot be deleted")
)

type ExcursionScheduleSeries struct {
	ID                uuid.UUID
	GuideProfileID    uuid.UUID
	GuideUserID       uuid.UUID
	OfferID           uuid.UUID
	ProductID         uuid.UUID
	LegacyExcursionID *uuid.UUID
	Timezone          string
	RecurrenceType    enum.ExcursionScheduleRecurrenceType
	Weekdays          []int
	StartsOn          time.Time
	EndsOn            *time.Time
	OccurrenceLimit   *int
	DefaultStartTime  string
	DefaultCapacity   *int
	Status            enum.ExcursionScheduleSeriesStatus
	CreatedAt         time.Time
	UpdatedAt         time.Time
}

type ExcursionScheduleSlot struct {
	ID                uuid.UUID
	SeriesID          *uuid.UUID
	GuideProfileID    uuid.UUID
	GuideUserID       uuid.UUID
	OfferID           uuid.UUID
	ProductID         uuid.UUID
	LegacyExcursionID *uuid.UUID
	StartAt           time.Time
	EndAt             time.Time
	Timezone          string
	Capacity          int
	BookedSeats       int
	Status            enum.ExcursionScheduleSlotStatus
	CancelReason      *string
	ClosedAt          *time.Time
	CancelledAt       *time.Time
	CreatedAt         time.Time
	UpdatedAt         time.Time
	Title             string
}

type NewExcursionScheduleSlotParams struct {
	SeriesID          *uuid.UUID
	GuideProfileID    uuid.UUID
	GuideUserID       uuid.UUID
	OfferID           uuid.UUID
	ProductID         uuid.UUID
	LegacyExcursionID *uuid.UUID
	StartAt           time.Time
	EndAt             time.Time
	Timezone          string
	Capacity          int
	BookedSeats       int
	Status            enum.ExcursionScheduleSlotStatus
}

func NewExcursionScheduleSlot(params NewExcursionScheduleSlotParams) (*ExcursionScheduleSlot, error) {
	now := time.Now().UTC()
	status := params.Status
	if status == "" {
		status = enum.ExcursionScheduleSlotStatusAvailable
	}

	slot := &ExcursionScheduleSlot{
		ID:                uuid.New(),
		SeriesID:          NormalizeUUIDPointer(params.SeriesID),
		GuideProfileID:    params.GuideProfileID,
		GuideUserID:       params.GuideUserID,
		OfferID:           params.OfferID,
		ProductID:         params.ProductID,
		LegacyExcursionID: NormalizeUUIDPointer(params.LegacyExcursionID),
		StartAt:           params.StartAt.UTC(),
		EndAt:             params.EndAt.UTC(),
		Timezone:          strings.TrimSpace(params.Timezone),
		Capacity:          params.Capacity,
		BookedSeats:       params.BookedSeats,
		Status:            status,
		CreatedAt:         now,
		UpdatedAt:         now,
	}
	if err := slot.Validate(); err != nil {
		return nil, err
	}
	return slot, nil
}

func (slot *ExcursionScheduleSlot) Validate() error {
	if slot == nil || slot.ID == uuid.Nil {
		return ErrInvalidExcursionScheduleID
	}
	if slot.GuideProfileID == uuid.Nil || slot.GuideUserID == uuid.Nil {
		return ErrInvalidExcursionScheduleGuide
	}
	if slot.OfferID == uuid.Nil || slot.ProductID == uuid.Nil {
		return ErrInvalidExcursionScheduleOffer
	}
	if !slot.EndAt.After(slot.StartAt) {
		return ErrInvalidExcursionScheduleInterval
	}
	slot.Timezone = strings.TrimSpace(slot.Timezone)
	if slot.Timezone == "" {
		return ErrInvalidExcursionScheduleTimezone
	}
	if slot.Capacity <= 0 || slot.BookedSeats < 0 || slot.BookedSeats > slot.Capacity {
		return ErrInvalidExcursionScheduleCapacity
	}
	if !slot.Status.IsValid() {
		return ErrInvalidExcursionScheduleID
	}
	return nil
}

func (series *ExcursionScheduleSeries) Validate() error {
	if series == nil || series.ID == uuid.Nil {
		return ErrInvalidExcursionScheduleID
	}
	if series.GuideProfileID == uuid.Nil || series.GuideUserID == uuid.Nil {
		return ErrInvalidExcursionScheduleGuide
	}
	if series.OfferID == uuid.Nil || series.ProductID == uuid.Nil {
		return ErrInvalidExcursionScheduleOffer
	}
	series.Timezone = strings.TrimSpace(series.Timezone)
	if series.Timezone == "" {
		return ErrInvalidExcursionScheduleTimezone
	}
	if !series.RecurrenceType.IsValid() || len(series.Weekdays) == 0 {
		return ErrInvalidExcursionScheduleInterval
	}
	for _, weekday := range series.Weekdays {
		if weekday < 1 || weekday > 7 {
			return ErrInvalidExcursionScheduleInterval
		}
	}
	if series.StartsOn.IsZero() {
		return ErrInvalidExcursionScheduleInterval
	}
	if series.EndsOn != nil && series.EndsOn.Before(series.StartsOn) {
		return ErrInvalidExcursionScheduleInterval
	}
	if series.OccurrenceLimit != nil && *series.OccurrenceLimit <= 0 {
		return ErrInvalidExcursionScheduleInterval
	}
	if strings.TrimSpace(series.DefaultStartTime) == "" {
		return ErrInvalidExcursionScheduleInterval
	}
	if series.DefaultCapacity != nil && *series.DefaultCapacity <= 0 {
		return ErrInvalidExcursionScheduleCapacity
	}
	if !series.Status.IsValid() {
		return ErrInvalidExcursionScheduleID
	}
	series.LegacyExcursionID = NormalizeUUIDPointer(series.LegacyExcursionID)
	return nil
}

func (slot *ExcursionScheduleSlot) IsBookable() bool {
	if slot == nil {
		return false
	}
	return slot.Status == enum.ExcursionScheduleSlotStatusAvailable ||
		slot.Status == enum.ExcursionScheduleSlotStatusBooked
}

func (slot *ExcursionScheduleSlot) Close() {
	now := time.Now().UTC()
	slot.Status = enum.ExcursionScheduleSlotStatusClosed
	slot.ClosedAt = &now
	slot.UpdatedAt = now
}

func (slot *ExcursionScheduleSlot) Cancel(reason string) error {
	reason = strings.TrimSpace(reason)
	if slot.BookedSeats > 0 && reason == "" {
		return ErrExcursionScheduleCancelReasonRequired
	}

	now := time.Now().UTC()
	slot.Status = enum.ExcursionScheduleSlotStatusCancelled
	slot.CancelledAt = &now
	slot.UpdatedAt = now
	if reason == "" {
		slot.CancelReason = nil
		return nil
	}
	slot.CancelReason = &reason
	return nil
}

func (slot *ExcursionScheduleSlot) CanHardDelete() bool {
	return slot != nil && slot.BookedSeats == 0
}
