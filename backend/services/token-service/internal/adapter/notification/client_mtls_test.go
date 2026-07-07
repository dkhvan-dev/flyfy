package notification

import (
	"net/http"
	"testing"
	"time"
)

func TestNewClientAllowsCustomHTTPClient(t *testing.T) {
	t.Parallel()

	customClient := &http.Client{Timeout: 750 * time.Millisecond}

	client := NewClient(
		"http://notification-service:8097",
		"internal-token",
		2*time.Second,
		WithHTTPClient(customClient),
	)

	if client.httpClient != customClient {
		t.Fatal("NewClient did not preserve custom HTTP client")
	}
}
