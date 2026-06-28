package filemanager

import (
	"context"
	"fmt"
	"io"
	"net/http"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"
)

func TestCreateDownloadURLPostsToFileManagerAndParsesExpiry(t *testing.T) {
	fileID := uuid.MustParse("44444444-4444-4444-4444-444444444444")
	expiresAt := time.Date(2026, 6, 20, 12, 10, 0, 0, time.UTC)
	client := NewClient("https://file-manager.internal", time.Second, "internal-token")
	client.httpClient = &http.Client{Transport: roundTripFunc(func(r *http.Request) (*http.Response, error) {
		if r.Method != http.MethodPost {
			t.Fatalf("method = %s, want POST", r.Method)
		}
		if r.URL.Path != "/v1/files/"+fileID.String()+"/download-url" {
			t.Fatalf("path = %s", r.URL.Path)
		}
		if got := r.Header.Get("X-Internal-Service"); got != "admin-panel" {
			t.Fatalf("X-Internal-Service = %q", got)
		}
		if got := r.Header.Get("Authorization"); got != "Bearer internal-token" {
			t.Fatalf("Authorization = %q", got)
		}
		return &http.Response{
			StatusCode: http.StatusOK,
			Header:     http.Header{"Content-Type": []string{"application/json"}},
			Body: io.NopCloser(strings.NewReader(
				fmt.Sprintf(`{"url":"https://files.inflap.test/support/receipt.jpg?signature=temporary","expiresAt":%q}`, expiresAt.Format(time.RFC3339)),
			)),
		}, nil
	})}

	download, err := client.CreateDownloadURL(context.Background(), fileID)

	if err != nil {
		t.Fatalf("CreateDownloadURL returned error: %v", err)
	}
	if download.URL != "https://files.inflap.test/support/receipt.jpg?signature=temporary" {
		t.Fatalf("URL = %q", download.URL)
	}
	if !download.ExpiresAt.Equal(expiresAt) {
		t.Fatalf("ExpiresAt = %s, want %s", download.ExpiresAt, expiresAt)
	}
}

type roundTripFunc func(*http.Request) (*http.Response, error)

func (f roundTripFunc) RoundTrip(r *http.Request) (*http.Response, error) {
	return f(r)
}
