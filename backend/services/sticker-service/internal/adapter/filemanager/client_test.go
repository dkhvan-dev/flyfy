package filemanager

import (
	"encoding/json"
	"io"
	"net/http"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"
	"kz/inflap/backend/services/sticker-service/internal/domain/port"
)

func TestCreateStickerUploadRequestUsesAuthenticatedOwner(t *testing.T) {
	t.Parallel()

	userID := uuid.New()
	fileID := uuid.New()
	expiresAt := time.Now().UTC().Add(10 * time.Minute).Format(time.RFC3339)

	transport := roundTripFunc(func(r *http.Request) (*http.Response, error) {
		if r.Method != http.MethodPost || r.URL.Path != "/v1/files/upload-requests" {
			t.Fatalf("unexpected request %s %s", r.Method, r.URL.Path)
		}
		if got := r.Header.Get("X-User-Id"); got != userID.String() {
			t.Fatalf("X-User-Id = %q, want %q", got, userID.String())
		}

		var req map[string]any
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			t.Fatalf("decode request: %v", err)
		}
		if req["purpose"] != "CHAT_STICKER" {
			t.Fatalf("purpose = %v, want CHAT_STICKER", req["purpose"])
		}
		if req["visibility"] != "PUBLIC" {
			t.Fatalf("visibility = %v, want PUBLIC", req["visibility"])
		}
		if req["ownerType"] != "USER" {
			t.Fatalf("ownerType = %v, want USER", req["ownerType"])
		}
		if req["ownerId"] != userID.String() {
			t.Fatalf("ownerId = %v, want %s", req["ownerId"], userID)
		}

		return jsonResponse(http.StatusCreated, map[string]any{
			"fileId": fileID.String(),
			"status": "PENDING_UPLOAD",
			"upload": map[string]any{
				"method":    "PUT",
				"url":       "https://storage.local/upload",
				"headers":   map[string]string{"Content-Type": "image/webp"},
				"expiresAt": expiresAt,
			},
		}), nil
	})

	client := NewClient("https://file-manager.local", "internal-token", &http.Client{Transport: transport})

	resp, err := client.CreateStickerUploadRequest(t.Context(), port.CreateStickerUploadRequest{
		UserID:       userID,
		OriginalName: "sticker.webp",
		ContentType:  "image/webp",
		SizeBytes:    1234,
	})
	if err != nil {
		t.Fatalf("CreateStickerUploadRequest() error = %v", err)
	}
	if resp.FileID != fileID {
		t.Fatalf("FileID = %s, want %s", resp.FileID, fileID)
	}
	if resp.Method != "PUT" || resp.URL == "" {
		t.Fatalf("unexpected upload descriptor: %+v", resp)
	}
}

func TestBindStickerFileToUserUsesInternalEndpoint(t *testing.T) {
	t.Parallel()

	userID := uuid.New()
	fileID := uuid.New()

	transport := roundTripFunc(func(r *http.Request) (*http.Response, error) {
		if r.Method != http.MethodPost || r.URL.Path != "/v1/internal/files/"+fileID.String()+"/bindings" {
			t.Fatalf("unexpected request %s %s", r.Method, r.URL.Path)
		}
		if got := r.Header.Get("X-Internal-Service-Token"); got != "internal-token" {
			t.Fatalf("X-Internal-Service-Token = %q", got)
		}
		if got := r.Header.Get("X-User-Id"); got != userID.String() {
			t.Fatalf("X-User-Id = %q, want %q", got, userID.String())
		}

		var req map[string]any
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			t.Fatalf("decode request: %v", err)
		}
		if req["ownerType"] != "USER" || req["ownerId"] != userID.String() || req["purpose"] != "CHAT_STICKER" {
			t.Fatalf("unexpected binding request: %+v", req)
		}

		return jsonResponse(http.StatusCreated, map[string]any{"id": uuid.NewString()}), nil
	})

	client := NewClient("https://file-manager.local", "internal-token", &http.Client{Transport: transport})

	if err := client.BindStickerFileToUser(t.Context(), fileID, userID); err != nil {
		t.Fatalf("BindStickerFileToUser() error = %v", err)
	}
}

type roundTripFunc func(*http.Request) (*http.Response, error)

func (f roundTripFunc) RoundTrip(r *http.Request) (*http.Response, error) {
	return f(r)
}

func jsonResponse(status int, payload any) *http.Response {
	buf := new(strings.Builder)
	_ = json.NewEncoder(buf).Encode(payload)

	return &http.Response{
		StatusCode: status,
		Header:     http.Header{"Content-Type": []string{"application/json"}},
		Body:       io.NopCloser(strings.NewReader(buf.String())),
	}
}
