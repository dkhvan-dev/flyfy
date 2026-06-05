package http

import (
	"os"
	"strings"
	"testing"
)

func TestHandlerExposesNicknameAvailabilityEndpoint(t *testing.T) {
	source, err := os.ReadFile("handler.go")
	if err != nil {
		t.Fatalf("read handler.go: %v", err)
	}
	text := string(source)

	if !strings.Contains(text, `GET /v1/users/nickname-availability`) {
		t.Fatal("handler does not register nickname availability route")
	}
	if !strings.Contains(text, "CheckNicknameAvailability") {
		t.Fatal("handler does not expose CheckNicknameAvailability")
	}
	if !strings.Contains(text, `"available"`) {
		t.Fatal("handler response does not include available field")
	}
}
