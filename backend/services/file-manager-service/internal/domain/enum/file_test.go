package enum

import "testing"

func TestPostOwnerTypeIsValid(t *testing.T) {
	if !OwnerType("POST").IsValid() {
		t.Fatal("POST owner type must be valid for post media bindings")
	}
}
