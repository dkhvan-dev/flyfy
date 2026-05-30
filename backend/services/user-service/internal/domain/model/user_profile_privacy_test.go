package model

import (
	"reflect"
	"testing"
)

func TestUserProfileDoesNotExposeVisibilityFlag(t *testing.T) {
	if _, ok := reflect.TypeOf(UserProfile{}).FieldByName("IsPublic"); ok {
		t.Fatal("UserProfile must not expose profile visibility; Inflap user profiles are always public")
	}
	if _, ok := reflect.TypeOf(UpdateUserProfileParams{}).FieldByName("IsPublic"); ok {
		t.Fatal("UpdateUserProfileParams must not accept profile visibility changes")
	}
}
