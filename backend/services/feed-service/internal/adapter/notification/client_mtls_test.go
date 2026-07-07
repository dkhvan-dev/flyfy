package notification

import (
	"net/http"
	"testing"
	"time"
)

func TestNewAllowsCustomHTTPClient(t *testing.T) {
	t.Parallel()

	customClient := &http.Client{Timeout: 750 * time.Millisecond}

	client := New(
		"http://notification-service:8097",
		"internal-token",
		"feed-service",
		2*time.Second,
		WithHTTPClient(customClient),
	)

	if client.httpClient != customClient {
		t.Fatal("New did not preserve custom HTTP client")
	}
}
