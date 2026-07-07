package guiderating

import (
	"net/http"
	"testing"
	"time"
)

func TestNewClientUsesProvidedHTTPClient(t *testing.T) {
	t.Parallel()

	customClient := &http.Client{Timeout: 150 * time.Millisecond}
	client := NewClient(
		"http://guide-service:8085",
		"internal-token",
		WithHTTPClient(customClient),
	)

	if client.httpClient != customClient {
		t.Fatalf("http client = %#v, want provided client", client.httpClient)
	}
}
