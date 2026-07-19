package http

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/saved-service/internal/domain"
)

func TestWriteOperationResultUsesAcceptedForPending(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, time.July, 16, 12, 0, 0, 0, time.UTC)
	receipt := newHTTPTestOperation(t, now, domain.OperationKindSave)
	request := personalResponseTestRequest()
	recorder := httptest.NewRecorder()

	if err := writeOperationResult(recorder, request, receipt, nil, now); err != nil {
		t.Fatalf("writeOperationResult() error = %v", err)
	}
	if recorder.Code != http.StatusAccepted {
		t.Fatalf("status = %d", recorder.Code)
	}
	assertPersonalResponseHeaders(t, recorder.Header())
	if recorder.Header().Get("Retry-After") != "10" {
		t.Fatalf("Retry-After = %q", recorder.Header().Get("Retry-After"))
	}
}

func TestWriteDomainErrorMapsOnlySafeClassification(t *testing.T) {
	t.Parallel()

	retryAfter := int64(1250)
	request := personalResponseTestRequest()
	recorder := httptest.NewRecorder()
	writeDomainError(recorder, request, &domain.DomainError{
		Code:         domain.ErrorCodeRateLimited,
		Retryable:    true,
		RetryAfterMS: &retryAfter,
	})

	if recorder.Code != http.StatusTooManyRequests {
		t.Fatalf("status = %d", recorder.Code)
	}
	if recorder.Header().Get("Retry-After") != "2" {
		t.Fatalf("Retry-After = %q", recorder.Header().Get("Retry-After"))
	}
	var response errorEnvelope
	if err := json.NewDecoder(recorder.Body).Decode(&response); err != nil {
		t.Fatalf("decode response: %v", err)
	}
	if response.Code != string(domain.ErrorCodeRateLimited) || !response.Retryable || response.RequestID != "request-123" {
		t.Fatalf("response = %#v", response)
	}
}

func TestWriteDomainErrorFailsClosedForInternalError(t *testing.T) {
	t.Parallel()

	request := personalResponseTestRequest()
	recorder := httptest.NewRecorder()
	writeDomainError(recorder, request, errors.New("database contains secret target id"))

	if recorder.Code != http.StatusServiceUnavailable {
		t.Fatalf("status = %d", recorder.Code)
	}
	if body := recorder.Body.String(); body == "" || strings.Contains(body, "database") ||
		strings.Contains(body, "secret") || strings.Contains(body, "target id") {
		t.Fatalf("unsafe body = %q", body)
	}
}

func TestStatusForDomainErrorCoversEveryStableCode(t *testing.T) {
	t.Parallel()

	codes := []domain.ErrorCode{
		domain.ErrorCodeTargetTypeUnsupported,
		domain.ErrorCodeTargetUnavailable,
		domain.ErrorCodeDependencyUnavailable,
		domain.ErrorCodeMutationStale,
		domain.ErrorCodeReplayMismatch,
		domain.ErrorCodeCollectionNotFound,
		domain.ErrorCodeCollectionDeleted,
		domain.ErrorCodeCollectionTitleInvalid,
		domain.ErrorCodeCollectionTitleConflict,
		domain.ErrorCodeCollectionLimitReached,
		domain.ErrorCodeCollectionItemLimitReached,
		domain.ErrorCodeMembershipLimitReached,
		domain.ErrorCodeItemLimitReached,
		domain.ErrorCodeRequestInProgress,
		domain.ErrorCodeOperationExpired,
		domain.ErrorCodeCursorInvalid,
		domain.ErrorCodeRateLimited,
		domain.ErrorCodeTemporarilyUnavailable,
		domain.ErrorCodePlatformPersonalDataLocked,
	}
	for _, code := range codes {
		if status := statusForDomainError(code); status < 400 || status > 599 {
			t.Errorf("statusForDomainError(%s) = %d", code, status)
		}
	}
}

func personalResponseTestRequest() *http.Request {
	request := httptest.NewRequest(http.MethodGet, "/v1/users/me/saved-items", nil)
	request.Header.Set("Accept-Language", "kk-KZ,ru;q=0.8")
	principal := PersonalPrincipal{
		Subject:           uuid.MustParse("11111111-1111-4111-8111-111111111111"),
		UserID:            uuid.MustParse("22222222-2222-4222-8222-222222222222"),
		SessionGeneration: uuid.MustParse("33333333-3333-4333-8333-333333333333"),
		RequestID:         "request-123",
	}
	return request.WithContext(context.WithValue(request.Context(), principalContextKey{}, principal))
}

func assertPersonalResponseHeaders(t *testing.T, header http.Header) {
	t.Helper()
	for name, want := range map[string]string{
		"Cache-Control":    "private, no-store",
		"Content-Language": "kk",
		"Content-Type":     "application/json",
		"Pragma":           "no-cache",
		"Vary":             "Authorization, Accept-Language",
		HeaderRequestID:    "request-123",
	} {
		if got := header.Get(name); got != want {
			t.Errorf("%s = %q, want %q", name, got, want)
		}
	}
}
