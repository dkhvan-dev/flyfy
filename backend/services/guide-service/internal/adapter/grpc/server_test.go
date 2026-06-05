package grpc

import (
	"testing"

	"github.com/google/uuid"

	"kz/inflap/backend/services/guide-service/internal/app"
	"kz/inflap/backend/services/guide-service/internal/domain/enum"
	"kz/inflap/backend/services/guide-service/internal/domain/model"
)

func TestToProtoAggregateIncludesPublicUserProfile(t *testing.T) {
	userID := uuid.New()
	profile, err := model.NewGuideProfile(model.NewGuideProfileParams{
		UserID: userID,
		Type:   enum.GuideTypeLocalExpert,
	})
	if err != nil {
		t.Fatalf("NewGuideProfile() error = %v", err)
	}
	nickname := "Aruzhan T."
	firstName := "Aruzhan"
	lastName := "Tulegenova"

	got := toProtoAggregate(&app.GuideAggregate{
		Profile: profile,
		UserProfile: &app.PublicUserProfile{
			UserID:    userID,
			FirstName: &firstName,
			LastName:  &lastName,
			Nickname:  &nickname,
		},
	})

	if got.GetUserProfile() == nil {
		t.Fatal("user profile is nil, want public user profile in guide aggregate proto")
	}
	if got.GetUserProfile().GetNickname() != nickname {
		t.Fatalf("nickname = %q, want %q", got.GetUserProfile().GetNickname(), nickname)
	}
	if got.GetUserProfile().GetFirstName() != firstName {
		t.Fatalf("first name = %q, want %q", got.GetUserProfile().GetFirstName(), firstName)
	}
	if got.GetUserProfile().GetLastName() != lastName {
		t.Fatalf("last name = %q, want %q", got.GetUserProfile().GetLastName(), lastName)
	}
}
