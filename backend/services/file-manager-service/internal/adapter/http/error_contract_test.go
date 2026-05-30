package http

import (
	"encoding/json"
	"errors"
	stdhttp "net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/google/uuid"

	"kz/inflap/backend/services/file-manager-service/internal/app"
)

func TestHTTPBusinessErrorUsesLocalizedContract(t *testing.T) {
	fileID := uuid.New()
	files := &fakeFileUseCase{
		publicContentURLErr: app.ErrFileNotPublic,
	}
	handler := NewHandler(files, nil)
	mux := stdhttp.NewServeMux()
	handler.Register(mux)

	req := httptest.NewRequest(
		stdhttp.MethodGet,
		"/v1/public/files/"+fileID.String()+"/content",
		nil,
	)
	req.Header.Set("Accept-Language", "en-US,en;q=0.9")
	rec := httptest.NewRecorder()

	mux.ServeHTTP(rec, req)

	assertErrorResponse(t, rec, stdhttp.StatusForbidden, map[string]string{
		"error":   "File is not public",
		"message": "File is not public",
		"code":    "file_not_public",
		"kind":    "business",
	})
}

func TestHTTPBusinessErrorFallsBackToRussian(t *testing.T) {
	fileID := uuid.New()
	files := &fakeFileUseCase{
		publicContentURLErr: app.ErrFileNotPublic,
	}
	handler := NewHandler(files, nil)
	mux := stdhttp.NewServeMux()
	handler.Register(mux)

	req := httptest.NewRequest(
		stdhttp.MethodGet,
		"/v1/public/files/"+fileID.String()+"/content",
		nil,
	)
	req.Header.Set("Accept-Language", "de-DE,de;q=0.9")
	rec := httptest.NewRecorder()

	mux.ServeHTTP(rec, req)

	assertErrorResponse(t, rec, stdhttp.StatusForbidden, map[string]string{
		"error":   "Файл не публичный",
		"message": "Файл не публичный",
		"code":    "file_not_public",
		"kind":    "business",
	})
}

func TestHTTPTechnicalErrorUsesGenericLocalizedContract(t *testing.T) {
	fileID := uuid.New()
	files := &fakeFileUseCase{
		publicContentURLErr: errors.New("s3 bucket secret leaked"),
	}
	handler := NewHandler(files, nil)
	mux := stdhttp.NewServeMux()
	handler.Register(mux)

	req := httptest.NewRequest(
		stdhttp.MethodGet,
		"/v1/public/files/"+fileID.String()+"/content",
		nil,
	)
	req.Header.Set("Accept-Language", "kk")
	rec := httptest.NewRecorder()

	mux.ServeHTTP(rec, req)

	assertErrorResponse(t, rec, stdhttp.StatusInternalServerError, map[string]string{
		"error":   "Техникалық қате",
		"message": "Серверде мәселе туындады. Кейінірек қайталап көріңіз.",
		"code":    "technical_error",
		"kind":    "technical",
	})
	if got := rec.Body.String(); strings.Contains(got, "s3 bucket secret leaked") {
		t.Fatal("technical error leaked raw message")
	}
}

func assertErrorResponse(
	t testing.TB,
	rec *httptest.ResponseRecorder,
	wantStatus int,
	want map[string]string,
) {
	t.Helper()

	if rec.Code != wantStatus {
		t.Fatalf("status = %d body=%s, want %d", rec.Code, rec.Body.String(), wantStatus)
	}

	var got map[string]string
	if err := json.Unmarshal(rec.Body.Bytes(), &got); err != nil {
		t.Fatalf("decode response: %v body=%s", err, rec.Body.String())
	}
	for key, wantValue := range want {
		if got[key] != wantValue {
			t.Fatalf("%s = %q, want %q; body=%s", key, got[key], wantValue, rec.Body.String())
		}
	}
}
