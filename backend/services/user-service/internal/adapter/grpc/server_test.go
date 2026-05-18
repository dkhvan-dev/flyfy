package grpc

import (
	"testing"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/user-service/internal/domain/model"
)

func TestToProtoPublicProfileIncludesLegalNameFields(t *testing.T) {
	firstName := "Aruzhan"
	lastName := "Tulegenova"
	displayName := "@nomad_aru"

	got := toProtoPublicProfile(&model.UserProfile{
		UserID:      uuid.New(),
		FirstName:   &firstName,
		LastName:    &lastName,
		DisplayName: &displayName,
		Locale:      "ru",
		Timezone:    "Asia/Almaty",
	})

	if got.GetFirstName() != firstName {
		t.Fatalf("first name = %q, want %q", got.GetFirstName(), firstName)
	}
	if got.GetLastName() != lastName {
		t.Fatalf("last name = %q, want %q", got.GetLastName(), lastName)
	}
	if got.GetDisplayName() != displayName {
		t.Fatalf("display name = %q, want %q", got.GetDisplayName(), displayName)
	}
}
