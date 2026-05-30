package grpc

import (
	"reflect"
	"testing"

	userv1 "kz/inflap/proto/gen/go/user/v1"
)

func TestUserProfileProtoDoesNotExposeVisibilityFlag(t *testing.T) {
	for _, tt := range []struct {
		name    string
		message any
	}{
		{name: "UpdateUserProfileRequest", message: userv1.UpdateUserProfileRequest{}},
		{name: "UserProfile", message: userv1.UserProfile{}},
		{name: "PublicProfile", message: userv1.PublicProfile{}},
	} {
		if _, ok := reflect.TypeOf(tt.message).FieldByName("IsPublic"); ok {
			t.Fatalf("%s must not expose profile visibility", tt.name)
		}
	}
}
