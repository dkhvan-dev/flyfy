package http

import (
	"os"
	"strings"
	"testing"
)

func TestPhoneVerificationHTTPContractIsAuthenticatedProfileFlow(t *testing.T) {
	source, err := os.ReadFile("handler.go")
	if err != nil {
		t.Fatal(err)
	}
	text := string(source)

	for _, route := range []string{
		`POST /v1/users/me/phone/verification/start`,
		`POST /v1/users/me/phone/verification/verify`,
		`POST /v1/users/me/phone/verification/resend`,
		`DELETE /v1/users/me/phone/pending`,
	} {
		if !strings.Contains(text, route) {
			t.Fatalf("handler.go does not register %s", route)
		}
	}

	if !strings.Contains(text, "PhoneVerificationResponse") {
		t.Fatal("phone verification responses must use an explicit DTO")
	}
	if !strings.Contains(text, "SubjectFromContext") {
		t.Fatal("phone verification endpoints must resolve the authenticated subject")
	}
}
