package feedservice

import (
	"net/http"
	"testing"
	"time"
)

func TestNewUsesProvidedHTTPClient(t *testing.T) {
	t.Parallel()

	customClient := &http.Client{Timeout: 150 * time.Millisecond}
	client := New(
		"http://feed-service:8087",
		"internal-token",
		"user-service",
		time.Second,
		WithHTTPClient(customClient),
	)

	if client.httpClient != customClient {
		t.Fatalf("http client = %#v, want provided client", client.httpClient)
	}
}
