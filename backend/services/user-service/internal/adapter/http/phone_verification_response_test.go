package http

import (
	"testing"
	"time"

	"github.com/google/uuid"
	"kz/inflap/backend/services/user-service/internal/domain/enum"
	"kz/inflap/backend/services/user-service/internal/domain/model"
)

func TestUserResponseUsesMaskedVerifiedPhoneState(t *testing.T) {
	phone := "+77011234567"
	verifiedAt := time.Date(2026, 6, 8, 12, 0, 0, 0, time.UTC)
	user := &model.User{
		ID:                     uuid.New(),
		AuthSubjectID:          "auth-subject",
		Status:                 enum.UserStatusActive,
		PrimaryPhone:           &phone,
		PrimaryPhoneVerifiedAt: &verifiedAt,
		CreatedAt:              verifiedAt,
		UpdatedAt:              verifiedAt,
	}

	response := toUserResponse(user)

	if response.PrimaryPhone != nil {
		t.Fatalf("raw primary phone must not be exposed, got %q", *response.PrimaryPhone)
	}
	if response.PrimaryPhoneMasked == nil || *response.PrimaryPhoneMasked != "+7 *** *** 45 67" {
		t.Fatalf("unexpected masked phone: %#v", response.PrimaryPhoneMasked)
	}
	if !response.PrimaryPhoneVerified {
		t.Fatal("verified phone state must be exposed")
	}
	if response.PrimaryPhoneVerifiedAt == nil || *response.PrimaryPhoneVerifiedAt != verifiedAt.Format(time.RFC3339) {
		t.Fatalf("unexpected verified timestamp: %#v", response.PrimaryPhoneVerifiedAt)
	}
}
