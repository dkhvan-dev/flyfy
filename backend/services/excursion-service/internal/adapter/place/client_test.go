package place

import (
	"net/http"
	"testing"
	"time"
)

func TestNewClientUsesProvidedHTTPClient(t *testing.T) {
	t.Parallel()

	customClient := &http.Client{Timeout: 150 * time.Millisecond}
	client := NewClient(
		"http://place-service:8090",
		"internal-token",
		WithHTTPClient(customClient),
	)

	if client.httpClient != customClient {
		t.Fatalf("http client = %#v, want provided client", client.httpClient)
	}
}
