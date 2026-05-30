package http

import (
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"

	"kz/inflap/backend/services/chat-service/internal/app"
)

func TestWriteAppErrorLocalizesBusinessErrors(t *testing.T) {
	tests := []struct {
		name        string
		err         error
		acceptLang  string
		wantStatus  int
		wantCode    string
		wantMessage string
	}{
		{
			name:        "english participant error",
			err:         app.ErrNotParticipant,
			acceptLang:  "en-US,en;q=0.9",
			wantStatus:  http.StatusForbidden,
			wantCode:    "not_participant",
			wantMessage: "You are not a participant of this chat",
		},
		{
			name:        "kazakh not found error",
			err:         app.ErrConversationNotFound,
			acceptLang:  "kk",
			wantStatus:  http.StatusNotFound,
			wantCode:    "conversation_not_found",
			wantMessage: "Чат табылмады",
		},
		{
			name:        "unsupported language falls back to russian",
			err:         app.ErrAccessDenied,
			acceptLang:  "de",
			wantStatus:  http.StatusForbidden,
			wantCode:    "access_denied",
			wantMessage: "Доступ запрещен",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			req := httptest.NewRequest(http.MethodGet, "/v1/conversations", nil)
			req.Header.Set("Accept-Language", tt.acceptLang)
			w := httptest.NewRecorder()

			(&Handler{}).writeAppError(w, req, tt.err, "test failed")

			if w.Code != tt.wantStatus {
				t.Fatalf("status = %d, want %d", w.Code, tt.wantStatus)
			}

			var body map[string]string
			if err := json.NewDecoder(w.Body).Decode(&body); err != nil {
				t.Fatalf("decode response: %v", err)
			}

			assertErrorBody(t, body, tt.wantMessage, tt.wantMessage, tt.wantCode, "business")
		})
	}
}

func TestWriteAppErrorHidesTechnicalDetails(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/v1/conversations", nil)
	req.Header.Set("Accept-Language", "kk")
	w := httptest.NewRecorder()

	(&Handler{}).writeAppError(w, req, errors.New("postgres password leaked"), "test failed")

	if w.Code != http.StatusInternalServerError {
		t.Fatalf("status = %d, want %d", w.Code, http.StatusInternalServerError)
	}

	var body map[string]string
	if err := json.NewDecoder(w.Body).Decode(&body); err != nil {
		t.Fatalf("decode response: %v", err)
	}

	assertErrorBody(
		t,
		body,
		"Техникалық қате",
		"Серверде мәселе туындады. Кейінірек қайталап көріңіз.",
		"technical_error",
		"technical",
	)
	if body["error"] == "postgres password leaked" || body["message"] == "postgres password leaked" {
		t.Fatalf("technical response leaked raw error: %#v", body)
	}
}

func TestWriteErrorLocalizesRequestValidationErrors(t *testing.T) {
	req := httptest.NewRequest(http.MethodPost, "/v1/conversations", nil)
	req.Header.Set("Accept-Language", "en")
	w := httptest.NewRecorder()

	writeError(w, req, http.StatusBadRequest, "invalid request body")

	if w.Code != http.StatusBadRequest {
		t.Fatalf("status = %d, want %d", w.Code, http.StatusBadRequest)
	}

	var body map[string]string
	if err := json.NewDecoder(w.Body).Decode(&body); err != nil {
		t.Fatalf("decode response: %v", err)
	}

	assertErrorBody(
		t,
		body,
		"Invalid request body",
		"Invalid request body",
		"invalid_request_body",
		"business",
	)
}

func assertErrorBody(
	t *testing.T,
	body map[string]string,
	wantError string,
	wantMessage string,
	wantCode string,
	wantKind string,
) {
	t.Helper()
	if body["error"] != wantError {
		t.Fatalf("error = %q, want %q; body=%#v", body["error"], wantError, body)
	}
	if body["message"] != wantMessage {
		t.Fatalf("message = %q, want %q; body=%#v", body["message"], wantMessage, body)
	}
	if body["code"] != wantCode {
		t.Fatalf("code = %q, want %q; body=%#v", body["code"], wantCode, body)
	}
	if body["kind"] != wantKind {
		t.Fatalf("kind = %q, want %q; body=%#v", body["kind"], wantKind, body)
	}
}
