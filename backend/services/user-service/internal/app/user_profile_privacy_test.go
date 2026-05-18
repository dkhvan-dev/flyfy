package app

import (
	"reflect"
	"testing"
)

func TestUpdateProfileInputDoesNotAcceptVisibilityFlag(t *testing.T) {
	if _, ok := reflect.TypeOf(UpdateProfileInput{}).FieldByName("IsPublic"); ok {
		t.Fatal("UpdateProfileInput must not accept profile visibility changes")
	}
}
