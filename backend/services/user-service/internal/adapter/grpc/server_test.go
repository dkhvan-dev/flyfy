package grpc

import (
	"context"
	"testing"
	"time"

	"github.com/google/uuid"

	"google.golang.org/protobuf/types/known/timestamppb"
	"kz/inflap/backend/services/user-service/internal/domain/model"
	userv1 "kz/inflap/proto/gen/go/user/v1"
)

func TestServerExposesAdminUserReadRPCs(t *testing.T) {
	var _ interface {
		ListAdminUsers(context.Context, *userv1.ListAdminUsersRequest) (*userv1.ListAdminUsersResponse, error)
		GetAdminUserDetail(context.Context, *userv1.GetAdminUserDetailRequest) (*userv1.GetAdminUserDetailResponse, error)
	} = NewServer(nil)
}

func TestToProtoPublicProfileIncludesLegalNameFields(t *testing.T) {
	firstName := "Aruzhan"
	lastName := "Tulegenova"
	nickname := "@nomad_aru"

	got := toProtoPublicProfile(&model.UserProfile{
		UserID:    uuid.New(),
		FirstName: &firstName,
		LastName:  &lastName,
		Nickname:  &nickname,
		Locale:    "ru",
		Timezone:  "Asia/Almaty",
	})

	if got.GetFirstName() != firstName {
		t.Fatalf("first name = %q, want %q", got.GetFirstName(), firstName)
	}
	if got.GetLastName() != lastName {
		t.Fatalf("last name = %q, want %q", got.GetLastName(), lastName)
	}
	if got.GetNickname() != nickname {
		t.Fatalf("nickname = %q, want %q", got.GetNickname(), nickname)
	}
}

func TestAdminFilterFromProtoMapsFields(t *testing.T) {
	createdFrom := time.Date(2026, 5, 1, 12, 0, 0, 0, time.UTC)
	lastActiveTo := time.Date(2026, 5, 29, 12, 0, 0, 0, time.UTC)

	got := adminFilterFromProto(&userv1.ListAdminUsersRequest{
		PageSize:     25,
		PageToken:    "cursor",
		Query:        " aru ",
		Status:       "ACTIVE",
		Role:         "GUIDE",
		CountryCode:  "kz",
		CreatedFrom:  timestamppb.New(createdFrom),
		LastActiveTo: timestamppb.New(lastActiveTo),
	})

	if got.PageSize != 25 || got.PageToken != "cursor" || got.Query != " aru " {
		t.Fatalf("basic filter fields = %+v", got)
	}
	if got.Status != "ACTIVE" || got.Role != "GUIDE" || got.CountryCode != "kz" {
		t.Fatalf("enum-like filter fields = %+v", got)
	}
	if got.CreatedFrom == nil || !got.CreatedFrom.Equal(createdFrom) {
		t.Fatalf("created from = %v, want %s", got.CreatedFrom, createdFrom)
	}
	if got.LastActiveTo == nil || !got.LastActiveTo.Equal(lastActiveTo) {
		t.Fatalf("last active to = %v, want %s", got.LastActiveTo, lastActiveTo)
	}
}

func TestToProtoAdminUserListItemMapsTimestamps(t *testing.T) {
	userID := uuid.New()
	createdAt := time.Date(2026, 5, 1, 12, 0, 0, 0, time.UTC)
	lastActiveAt := createdAt.Add(2 * time.Hour)

	got := toProtoAdminUserListItem(model.AdminUserListItem{
		UserID:        userID,
		Nickname:      "Aruzhan",
		MaskedPhone:   "+7******67",
		MaskedEmail:   "a***@***",
		CountryCode:   "KZ",
		Roles:         []string{"USER", "GUIDE"},
		AccountStatus: "ACTIVE",
		GuideStatus:   "APPROVED",
		CreatedAt:     createdAt,
		LastActiveAt:  &lastActiveAt,
	})

	if got.GetUserId() != userID.String() || got.GetNickname() != "Aruzhan" {
		t.Fatalf("basic response fields = %+v", got)
	}
	if got.GetCreatedAt().AsTime() != createdAt {
		t.Fatalf("created at = %s, want %s", got.GetCreatedAt().AsTime(), createdAt)
	}
	if got.GetLastActiveAt().AsTime() != lastActiveAt {
		t.Fatalf("last active at = %s, want %s", got.GetLastActiveAt().AsTime(), lastActiveAt)
	}
}
