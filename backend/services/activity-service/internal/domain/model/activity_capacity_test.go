package model

import (
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/activity-service/internal/domain/enum"
)

func TestNewActivityRejectsMaxParticipantsAboveLimit(t *testing.T) {
	maxParticipants := 101

	_, err := NewActivity(newValidActivityParams(maxParticipants))
	if !errors.Is(err, ErrInvalidCapacity) {
		t.Fatalf("expected ErrInvalidCapacity, got %v", err)
	}
}

func TestNewActivityAllowsMaxParticipantsAtLimit(t *testing.T) {
	maxParticipants := 100

	item, err := NewActivity(newValidActivityParams(maxParticipants))
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}
	if item.MaxParticipants == nil || *item.MaxParticipants != maxParticipants {
		t.Fatalf("expected max participants %d, got %+v", maxParticipants, item.MaxParticipants)
	}
}

func newValidActivityParams(maxParticipants int) NewActivityParams {
	now := time.Now().UTC()
	startAt := now.Add(2 * time.Hour)
	endAt := startAt.Add(2 * time.Hour)
	registrationDeadline := startAt.Add(-30 * time.Minute)
	minParticipants := 1

	return NewActivityParams{
		HostUserID:                uuid.New(),
		Title:                     "Sunrise walk",
		Description:               "A valid activity description for capacity validation.",
		Format:                    enum.ActivityFormatOffline,
		Visibility:                enum.ActivityVisibilityPublic,
		JoinMode:                  enum.ActivityJoinModeAutoApprove,
		CategorySlug:              "health-wellness",
		LanguageCode:              "ru",
		Timezone:                  "Asia/Almaty",
		StartAt:                   startAt,
		EndAt:                     endAt,
		RegistrationDeadline:      registrationDeadline,
		CapacityType:              enum.ActivityCapacityTypeLimited,
		MinParticipants:           &minParticipants,
		MaxParticipants:           &maxParticipants,
		PriceType:                 enum.ActivityPriceTypeFree,
		RequiresProfileCompletion: true,
		CountryCode:               stringPtr("KZ"),
		CityName:                  stringPtr("Алматы"),
		AddressText:               stringPtr("проспект Абая"),
	}
}

func stringPtr(value string) *string {
	return &value
}
