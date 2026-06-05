package app

import (
	"context"
	"errors"
	"reflect"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/user-service/internal/domain/model"
)

func TestUpdateProfileInputDoesNotAcceptVisibilityFlag(t *testing.T) {
	if _, ok := reflect.TypeOf(UpdateProfileInput{}).FieldByName("IsPublic"); ok {
		t.Fatal("UpdateProfileInput must not accept profile visibility changes")
	}
}

func TestComputeProfileCompletedRequiresCountry(t *testing.T) {
	firstName := "Ada"
	lastName := "Lovelace"
	nickname := "@ada"
	countryCode := " KZ "

	profile := &model.UserProfile{
		FirstName:   &firstName,
		LastName:    &lastName,
		Nickname:    &nickname,
		CountryCode: &countryCode,
	}

	if !computeProfileCompleted(profile) {
		t.Fatal("expected profile with first name, last name, and country to be completed")
	}

	profile.CountryCode = nil
	if computeProfileCompleted(profile) {
		t.Fatal("expected profile without country to be incomplete")
	}

	blankCountryCode := " "
	profile.CountryCode = &blankCountryCode
	if computeProfileCompleted(profile) {
		t.Fatal("expected profile with blank country to be incomplete")
	}
}

func TestComputeProfileCompletedRequiresNickname(t *testing.T) {
	firstName := "Ada"
	lastName := "Lovelace"
	countryCode := "KZ"

	profile := &model.UserProfile{
		FirstName:   &firstName,
		LastName:    &lastName,
		CountryCode: &countryCode,
	}

	if computeProfileCompleted(profile) {
		t.Fatal("expected profile without nickname to be incomplete")
	}

	blankNickname := " "
	profile.Nickname = &blankNickname
	if computeProfileCompleted(profile) {
		t.Fatal("expected profile with blank nickname to be incomplete")
	}

	nickname := "@ada"
	profile.Nickname = &nickname
	if !computeProfileCompleted(profile) {
		t.Fatal("expected profile with nickname to be complete")
	}
}

func TestUpdateProfileRequiresNicknameBeforeFirstSet(t *testing.T) {
	ctx := context.Background()
	userID := uuid.New()
	firstName := "Ada"
	lastName := "Lovelace"
	countryCode := "KZ"
	repo := newFriendshipTestRepository(userID)
	repo.profiles[userID] = &model.UserProfile{
		UserID:      userID,
		FirstName:   &firstName,
		LastName:    &lastName,
		CountryCode: &countryCode,
		Locale:      "en",
		Timezone:    "UTC",
		CreatedAt:   time.Now().UTC(),
		UpdatedAt:   time.Now().UTC(),
	}

	useCase := NewUserUseCase(repo, nil)

	_, err := useCase.UpdateProfile(ctx, userID, UpdateProfileInput{
		FirstName:   &firstName,
		LastName:    &lastName,
		CountryCode: &countryCode,
	})
	if err == nil || !strings.Contains(err.Error(), "nickname is required") {
		t.Fatalf("error = %v, want nickname is required", err)
	}
}

func TestUpdateProfileSetsNicknameOnlyOnce(t *testing.T) {
	ctx := context.Background()
	userID := uuid.New()
	firstName := "Ada"
	lastName := "Lovelace"
	countryCode := "KZ"
	nickname := "@ada"
	repo := newFriendshipTestRepository(userID)
	repo.profiles[userID] = &model.UserProfile{
		UserID:    userID,
		Locale:    "en",
		Timezone:  "UTC",
		CreatedAt: time.Now().UTC(),
		UpdatedAt: time.Now().UTC(),
	}

	useCase := NewUserUseCase(repo, nil)

	updated, err := useCase.UpdateProfile(ctx, userID, UpdateProfileInput{
		FirstName:   &firstName,
		LastName:    &lastName,
		Nickname:    &nickname,
		CountryCode: &countryCode,
	})
	if err != nil {
		t.Fatalf("update profile: %v", err)
	}
	if updated.Profile.Nickname == nil || *updated.Profile.Nickname != nickname {
		t.Fatalf("nickname = %v, want %q", updated.Profile.Nickname, nickname)
	}

	changedNickname := "@ada_travels"
	_, err = useCase.UpdateProfile(ctx, userID, UpdateProfileInput{
		FirstName:   &firstName,
		LastName:    &lastName,
		Nickname:    &changedNickname,
		CountryCode: &countryCode,
	})
	if err == nil || !strings.Contains(err.Error(), "nickname cannot be changed") {
		t.Fatalf("error = %v, want nickname cannot be changed", err)
	}
}

func TestUpdateProfileRejectsTakenNickname(t *testing.T) {
	ctx := context.Background()
	userID := uuid.New()
	otherUserID := uuid.New()
	firstName := "Ada"
	lastName := "Lovelace"
	countryCode := "KZ"
	nickname := "@ada"
	repo := newFriendshipTestRepository(userID, otherUserID)
	repo.nicknameOwners[strings.ToLower(nickname)] = otherUserID
	repo.profiles[userID] = &model.UserProfile{
		UserID:    userID,
		Locale:    "en",
		Timezone:  "UTC",
		CreatedAt: time.Now().UTC(),
		UpdatedAt: time.Now().UTC(),
	}

	useCase := NewUserUseCase(repo, nil)

	_, err := useCase.UpdateProfile(ctx, userID, UpdateProfileInput{
		FirstName:   &firstName,
		LastName:    &lastName,
		Nickname:    &nickname,
		CountryCode: &countryCode,
	})
	if !errors.Is(err, ErrNicknameAlreadyTaken) {
		t.Fatalf("error = %v, want %v", err, ErrNicknameAlreadyTaken)
	}
}
