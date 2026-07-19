package http

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"kz/inflap/backend/services/saved-service/internal/app/saveditem"
	"kz/inflap/backend/services/saved-service/internal/domain"
)

func TestOperationHandlerReturnsOwnerSessionReceipt(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, time.July, 16, 12, 0, 0, 0, time.UTC)
	receipt := newHTTPTestOperation(t, now, domain.OperationKindSave)
	reader := &stubOperationReader{receipt: receipt}
	handler, err := NewOperationHandler(reader, fixedResponseClock{now: now})
	if err != nil {
		t.Fatalf("NewOperationHandler() error = %v", err)
	}
	mux := http.NewServeMux()
	if err := handler.Register(mux); err != nil {
		t.Fatalf("Register() error = %v", err)
	}

	request := personalResponseTestRequest()
	request = httptest.NewRequest(
		http.MethodGet,
		"/v1/users/me/saved-operations/33333333-3333-4333-8333-333333333333",
		nil,
	).WithContext(request.Context())
	recorder := httptest.NewRecorder()
	mux.ServeHTTP(recorder, request)

	if recorder.Code != http.StatusAccepted {
		t.Fatalf("status = %d, body = %s", recorder.Code, recorder.Body.String())
	}
	if reader.lookup.SubjectID.String() != "11111111-1111-4111-8111-111111111111" ||
		reader.lookup.SessionGeneration.String() != "33333333-3333-4333-8333-333333333333" ||
		!reader.lookup.ServerNow.Equal(now) {
		t.Fatalf("lookup = %#v", reader.lookup)
	}
	var response operationResultResponse
	if err := json.NewDecoder(recorder.Body).Decode(&response); err != nil {
		t.Fatalf("decode response: %v", err)
	}
	if response.OperationID != receipt.OperationID().String() || response.CurrentResourceSnapshot != nil {
		t.Fatalf("response = %#v", response)
	}
}

func TestOperationHandlerUsesNeutralNotFound(t *testing.T) {
	t.Parallel()

	handler, err := NewOperationHandler(
		&stubOperationReader{err: saveditem.ErrOperationNotFound},
		fixedResponseClock{now: time.Now()},
	)
	if err != nil {
		t.Fatalf("NewOperationHandler() error = %v", err)
	}
	mux := http.NewServeMux()
	if err := handler.Register(mux); err != nil {
		t.Fatalf("Register() error = %v", err)
	}

	principalRequest := personalResponseTestRequest()
	request := httptest.NewRequest(
		http.MethodGet,
		"/v1/users/me/saved-operations/aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa",
		nil,
	).WithContext(principalRequest.Context())
	recorder := httptest.NewRecorder()
	mux.ServeHTTP(recorder, request)

	if recorder.Code != http.StatusNotFound {
		t.Fatalf("status = %d", recorder.Code)
	}
	var response errorEnvelope
	if err := json.NewDecoder(recorder.Body).Decode(&response); err != nil {
		t.Fatalf("decode response: %v", err)
	}
	if response.Code != "NOT_FOUND" || response.Retryable {
		t.Fatalf("response = %#v", response)
	}
}

func TestOperationHandlerRejectsNonCanonicalOrNonV4IDBeforeRepository(t *testing.T) {
	t.Parallel()

	reader := &stubOperationReader{}
	handler, err := NewOperationHandler(reader, fixedResponseClock{now: time.Now()})
	if err != nil {
		t.Fatalf("NewOperationHandler() error = %v", err)
	}
	mux := http.NewServeMux()
	if err := handler.Register(mux); err != nil {
		t.Fatalf("Register() error = %v", err)
	}

	for _, operationID := range []string{
		"33333333-3333-1333-8333-333333333333",
		"not-a-uuid",
		"33333333-3333-4333-8333-33333333333A",
	} {
		principalRequest := personalResponseTestRequest()
		request := httptest.NewRequest(
			http.MethodGet,
			"/v1/users/me/saved-operations/"+operationID,
			nil,
		).WithContext(principalRequest.Context())
		recorder := httptest.NewRecorder()
		mux.ServeHTTP(recorder, request)
		if recorder.Code != http.StatusBadRequest {
			t.Errorf("id %q status = %d", operationID, recorder.Code)
		}
	}
	if reader.calls != 0 {
		t.Fatalf("repository calls = %d", reader.calls)
	}
}

func TestOperationHandlerFailsClosedWithoutPrincipal(t *testing.T) {
	t.Parallel()

	handler, err := NewOperationHandler(&stubOperationReader{}, fixedResponseClock{now: time.Now()})
	if err != nil {
		t.Fatalf("NewOperationHandler() error = %v", err)
	}
	request := httptest.NewRequest(
		http.MethodGet,
		"/v1/users/me/saved-operations/33333333-3333-4333-8333-333333333333",
		nil,
	)
	request.SetPathValue("operationId", "33333333-3333-4333-8333-333333333333")
	recorder := httptest.NewRecorder()
	handler.Get(recorder, request)
	if recorder.Code != http.StatusUnauthorized {
		t.Fatalf("status = %d", recorder.Code)
	}
}

type stubOperationReader struct {
	receipt *domain.SavedOperation
	err     error
	lookup  saveditem.OperationLookup
	calls   int
}

func (s *stubOperationReader) GetOperation(
	_ context.Context,
	lookup saveditem.OperationLookup,
) (*domain.SavedOperation, error) {
	s.calls++
	s.lookup = lookup
	return s.receipt, s.err
}

type fixedResponseClock struct{ now time.Time }

func (c fixedResponseClock) Now() time.Time { return c.now }

var _ OperationReader = (*stubOperationReader)(nil)
var _ ResponseClock = fixedResponseClock{}
