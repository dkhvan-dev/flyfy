package http

import (
	"encoding/json"
	"errors"
	stdhttp "net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/dkhvan-dev/flyfy/backend/services/stories-service/internal/app"
)

func TestLocaleFromRequestUsesSupportedAcceptLanguage(t *testing.T) {
	req := httptest.NewRequest(stdhttp.MethodGet, "/v1/stories", nil)
	req.Header.Set("Accept-Language", "kk-KZ,ru;q=0.8,en;q=0.7")

	if got := localeFromRequest(req); got != "kk" {
		t.Fatalf("localeFromRequest() = %q, want kk", got)
	}
}

func TestLocaleFromRequestFallsBackToRussian(t *testing.T) {
	req := httptest.NewRequest(stdhttp.MethodGet, "/v1/stories", nil)
	req.Header.Set("Accept-Language", "fr-CA, de;q=0.9")

	if got := localeFromRequest(req); got != "ru" {
		t.Fatalf("localeFromRequest() = %q, want ru", got)
	}
}

func TestLocaleFromRequestHonorsLanguageQuality(t *testing.T) {
	req := httptest.NewRequest(stdhttp.MethodGet, "/v1/stories", nil)
	req.Header.Set("Accept-Language", "en;q=0.4,kk;q=0.9,ru;q=0.8")

	if got := localeFromRequest(req); got != "kk" {
		t.Fatalf("localeFromRequest() = %q, want kk", got)
	}
}

func TestWriteUseCaseErrorLocalizesBusinessError(t *testing.T) {
	req := httptest.NewRequest(stdhttp.MethodPost, "/v1/stories", nil)
	req.Header.Set("Accept-Language", "en-US,en;q=0.9")
	rec := httptest.NewRecorder()

	h := &Handler{}
	h.writeUseCaseError(rec, req, app.ErrInvalidStoryTitle)

	assertErrorResponse(t, rec, stdhttp.StatusBadRequest, map[string]string{
		"error":   "Check the story title.",
		"message": "Check the story title.",
		"code":    "invalid_story_title",
		"kind":    "business",
	})
}

func TestWriteUseCaseErrorMasksTechnicalError(t *testing.T) {
	req := httptest.NewRequest(stdhttp.MethodGet, "/v1/stories", nil)
	req.Header.Set("Accept-Language", "ru")
	rec := httptest.NewRecorder()

	h := &Handler{}
	h.writeUseCaseError(rec, req, errors.New("rpc error: code = Unavailable desc = user-service exploded"))

	assertErrorResponse(t, rec, stdhttp.StatusInternalServerError, map[string]string{
		"error":   "Техническая ошибка",
		"message": "На сервере возникла проблема. Попробуйте позже.",
		"code":    "technical_error",
		"kind":    "technical",
	})

	body := rec.Body.String()
	if containsAny(body, "user-service exploded", "Unavailable") {
		t.Fatalf("technical response leaked raw error: %s", body)
	}
}

func assertErrorResponse(t *testing.T, rec *httptest.ResponseRecorder, wantStatus int, want map[string]string) {
	t.Helper()

	if rec.Code != wantStatus {
		t.Fatalf("status = %d, want %d; body: %s", rec.Code, wantStatus, rec.Body.String())
	}

	var got map[string]string
	if err := json.Unmarshal(rec.Body.Bytes(), &got); err != nil {
		t.Fatalf("decode response: %v; body: %s", err, rec.Body.String())
	}

	for key, wantValue := range want {
		if got[key] != wantValue {
			t.Fatalf("%s = %q, want %q; full response: %#v", key, got[key], wantValue, got)
		}
	}
}

func containsAny(s string, needles ...string) bool {
	for _, needle := range needles {
		if strings.Contains(s, needle) {
			return true
		}
	}
	return false
}
