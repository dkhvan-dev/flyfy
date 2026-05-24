package enum

import "testing"

func TestGuideSystemRoleIsValid(t *testing.T) {
	if !SystemRole("GUIDE").IsValid() {
		t.Fatal("GUIDE role must be valid so guide-service can grant it after moderation approval")
	}
}
