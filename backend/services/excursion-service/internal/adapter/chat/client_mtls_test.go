package chat

import (
	"net/http"
	"testing"
	"time"
)

func TestNewUsesProvidedHTTPClient(t *testing.T) {
	customClient := &http.Client{Timeout: 150 * time.Millisecond}

	client := New(
		"http://chat-service:8088",
		"internal-token",
		time.Second,
		WithHTTPClient(customClient),
	)

	if client.httpClient != customClient {
		t.Fatalf("http client = %#v, want provided client", client.httpClient)
	}
}
