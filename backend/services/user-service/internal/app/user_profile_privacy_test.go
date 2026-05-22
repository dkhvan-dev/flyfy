package app

import (
	"reflect"
	"testing"

	"github.com/dkhvan-dev/flyfy/backend/services/user-service/internal/domain/model"
)

func TestUpdateProfileInputDoesNotAcceptVisibilityFlag(t *testing.T) {
	if _, ok := reflect.TypeOf(UpdateProfileInput{}).FieldByName("IsPublic"); ok {
		t.Fatal("UpdateProfileInput must not accept profile visibility changes")
	}
}

func TestComputeProfileCompletedRequiresCountry(t *testing.T) {
	firstName := "Ada"
	lastName := "Lovelace"
	countryCode := " KZ "

	profile := &model.UserProfile{
		FirstName:   &firstName,
		LastName:    &lastName,
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
