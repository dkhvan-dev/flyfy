package sticker

import (
	"encoding/json"
	"io"
	"net/http"
	"strings"
	"testing"

	"github.com/google/uuid"
)

func TestValidateSendCallsStickerServiceInternalEndpoint(t *testing.T) {
	t.Parallel()

	senderID := uuid.New()
	stickerID := uuid.New()
	packID := uuid.New()
	fileID := uuid.New()
	fallbackID := uuid.New()
	previewID := uuid.New()

	transport := roundTripFunc(func(r *http.Request) (*http.Response, error) {
		if r.Method != http.MethodPost || r.URL.Path != "/internal/v1/stickers/validate-send" {
			t.Fatalf("unexpected request %s %s", r.Method, r.URL.Path)
		}
		if got := r.Header.Get("X-Internal-Service-Token"); got != "internal-token" {
			t.Fatalf("X-Internal-Service-Token = %q", got)
		}

		var req map[string]string
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			t.Fatalf("decode request: %v", err)
		}
		if req["userId"] != senderID.String() || req["stickerId"] != stickerID.String() {
			t.Fatalf("unexpected request body: %+v", req)
		}

		return jsonResponse(http.StatusOK, map[string]any{
			"stickerId":      stickerID.String(),
			"packId":         packID.String(),
			"packSlug":       "inflap-travel-basics",
			"slug":           "boarding-pass",
			"fileId":         fileID.String(),
			"fallbackFileId": fallbackID.String(),
			"previewFileId":  previewID.String(),
			"contentType":    "application/json",
			"width":          512,
			"height":         512,
			"durationMs":     1800,
			"status":         "ACTIVE",
		}), nil
	})

	client := NewClient("https://sticker-service.local", "internal-token", &http.Client{Transport: transport})

	result, err := client.ValidateSend(t.Context(), senderID, stickerID)
	if err != nil {
		t.Fatalf("ValidateSend error: %v", err)
	}
	if result.StickerID != stickerID || result.PackID != packID || result.FileID != fileID {
		t.Fatalf("unexpected result: %+v", result)
	}
	if result.PackSlug != "inflap-travel-basics" ||
		result.Slug != "boarding-pass" ||
		result.FallbackFileID != fallbackID ||
		result.PreviewFileID == nil ||
		*result.PreviewFileID != previewID ||
		result.ContentType != "application/json" ||
		result.Width != 512 ||
		result.Height != 512 ||
		result.DurationMS != 1800 {
		t.Fatalf("unexpected sticker payload metadata: %+v", result)
	}
}

type roundTripFunc func(*http.Request) (*http.Response, error)

func (f roundTripFunc) RoundTrip(r *http.Request) (*http.Response, error) {
	return f(r)
}

func jsonResponse(status int, payload any) *http.Response {
	builder := new(strings.Builder)
	_ = json.NewEncoder(builder).Encode(payload)

	return &http.Response{
		StatusCode: status,
		Header:     http.Header{"Content-Type": []string{"application/json"}},
		Body:       io.NopCloser(strings.NewReader(builder.String())),
	}
}
