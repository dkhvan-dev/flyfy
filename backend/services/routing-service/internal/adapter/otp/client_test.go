package otp

import (
	"context"
	"testing"

	"kz/inflap/backend/services/routing-service/internal/app"
)

func TestStatusReportsTransitAdapterNotImplemented(t *testing.T) {
	client := New("http://otp:8080")

	status := client.Status(context.Background())

	if status.Name != string(app.EngineOTP) || status.Reachable || status.Status != "not_implemented" {
		t.Fatalf("status = %#v", status)
	}
}
