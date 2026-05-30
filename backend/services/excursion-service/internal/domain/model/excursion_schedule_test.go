package model

import (
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/excursion-service/internal/domain/enum"
)

func TestNewExcursionScheduleSlotCreatesAvailableBookableSlot(t *testing.T) {
	startAt := time.Date(2026, 6, 1, 10, 0, 0, 0, time.FixedZone("ALMT", 5*60*60))
	endAt := startAt.Add(2 * time.Hour)
	seriesID := uuid.New()
	legacyExcursionID := uuid.New()

	slot, err := NewExcursionScheduleSlot(NewExcursionScheduleSlotParams{
		SeriesID:          &seriesID,
		GuideProfileID:    uuid.New(),
		GuideUserID:       uuid.New(),
		OfferID:           uuid.New(),
		ProductID:         uuid.New(),
		LegacyExcursionID: &legacyExcursionID,
		StartAt:           startAt,
		EndAt:             endAt,
		Timezone:          " Asia/Almaty ",
		Capacity:          8,
	})
	if err != nil {
		t.Fatalf("NewExcursionScheduleSlot() error = %v", err)
	}

	if slot.ID == uuid.Nil {
		t.Fatal("slot ID is nil")
	}
	if slot.SeriesID == nil || *slot.SeriesID != seriesID {
		t.Fatalf("series id = %v, want %s", slot.SeriesID, seriesID)
	}
	if slot.LegacyExcursionID == nil || *slot.LegacyExcursionID != legacyExcursionID {
		t.Fatalf("legacy excursion id = %v, want %s", slot.LegacyExcursionID, legacyExcursionID)
	}
	if slot.StartAt.Location() != time.UTC || slot.EndAt.Location() != time.UTC {
		t.Fatalf("times are not normalized to UTC: start=%s end=%s", slot.StartAt.Location(), slot.EndAt.Location())
	}
	if slot.Timezone != "Asia/Almaty" {
		t.Fatalf("timezone = %q, want trimmed Asia/Almaty", slot.Timezone)
	}
	if slot.Status != enum.ExcursionScheduleSlotStatusAvailable {
		t.Fatalf("status = %q, want %q", slot.Status, enum.ExcursionScheduleSlotStatusAvailable)
	}
	if !slot.IsBookable() {
		t.Fatal("new available slot must be bookable")
	}
	if slot.CreatedAt.IsZero() || slot.UpdatedAt.IsZero() {
		t.Fatalf("timestamps not set: created=%v updated=%v", slot.CreatedAt, slot.UpdatedAt)
	}
}

func TestNewExcursionScheduleSlotAcceptsOfferWithoutSeriesOrLegacy(t *testing.T) {
	startAt := time.Date(2026, 6, 1, 10, 0, 0, 0, time.UTC)

	slot, err := NewExcursionScheduleSlot(NewExcursionScheduleSlotParams{
		GuideProfileID: uuid.New(),
		GuideUserID:    uuid.New(),
		OfferID:        uuid.New(),
		ProductID:      uuid.New(),
		StartAt:        startAt,
		EndAt:          startAt.Add(2 * time.Hour),
		Timezone:       "Asia/Almaty",
		Capacity:       8,
	})
	if err != nil {
		t.Fatalf("NewExcursionScheduleSlot() error = %v", err)
	}

	if slot.SeriesID != nil {
		t.Fatalf("series id = %v, want nil", slot.SeriesID)
	}
	if slot.LegacyExcursionID != nil {
		t.Fatalf("legacy excursion id = %v, want nil", slot.LegacyExcursionID)
	}
}

func TestNewExcursionScheduleSlotRejectsInvalidInterval(t *testing.T) {
	startAt := time.Date(2026, 6, 1, 10, 0, 0, 0, time.UTC)
	seriesID := uuid.New()
	legacyExcursionID := uuid.New()

	_, err := NewExcursionScheduleSlot(NewExcursionScheduleSlotParams{
		SeriesID:          &seriesID,
		GuideProfileID:    uuid.New(),
		GuideUserID:       uuid.New(),
		OfferID:           uuid.New(),
		ProductID:         uuid.New(),
		LegacyExcursionID: &legacyExcursionID,
		StartAt:           startAt,
		EndAt:             startAt,
		Timezone:          "Asia/Almaty",
		Capacity:          8,
	})

	if !errors.Is(err, ErrInvalidExcursionScheduleInterval) {
		t.Fatalf("error = %v, want %v", err, ErrInvalidExcursionScheduleInterval)
	}
}

func TestExcursionScheduleSlotCancelRequiresReasonWhenBooked(t *testing.T) {
	slot := validScheduleSlot(t)
	slot.BookedSeats = 2

	err := slot.Cancel("")

	if !errors.Is(err, ErrExcursionScheduleCancelReasonRequired) {
		t.Fatalf("error = %v, want %v", err, ErrExcursionScheduleCancelReasonRequired)
	}
}

func validScheduleSlot(t *testing.T) *ExcursionScheduleSlot {
	t.Helper()

	startAt := time.Date(2026, 6, 1, 10, 0, 0, 0, time.UTC)
	seriesID := uuid.New()
	legacyExcursionID := uuid.New()
	slot, err := NewExcursionScheduleSlot(NewExcursionScheduleSlotParams{
		SeriesID:          &seriesID,
		GuideProfileID:    uuid.New(),
		GuideUserID:       uuid.New(),
		OfferID:           uuid.New(),
		ProductID:         uuid.New(),
		LegacyExcursionID: &legacyExcursionID,
		StartAt:           startAt,
		EndAt:             startAt.Add(2 * time.Hour),
		Timezone:          "Asia/Almaty",
		Capacity:          8,
	})
	if err != nil {
		t.Fatalf("NewExcursionScheduleSlot() error = %v", err)
	}
	return slot
}
