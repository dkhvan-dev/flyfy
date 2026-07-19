package http

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"kz/inflap/backend/services/saved-service/internal/app/productrollout"
	"kz/inflap/backend/services/saved-service/internal/app/saveditem"
	"kz/inflap/backend/services/saved-service/internal/domain"
)

func TestSavedItemMutationHandlerPassesTrustedOwnerAndReturnsTerminalReceipt(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, time.July, 16, 12, 0, 0, 0, time.UTC)
	receipt := newHTTPTestOperation(t, now, domain.OperationKindSave)
	if err := receipt.Succeed(now.Add(time.Second), domain.OperationOutcomeApplied, domain.RefreshScopeSavedItems, domain.OperationVersionEffects{}); err != nil {
		t.Fatalf("Succeed() error = %v", err)
	}
	useCase := &stubSavedMutationUseCase{saveReceipt: receipt}
	mux := newSavedMutationTestMux(t, useCase, now)
	request := savedMutationRequest(t, http.MethodPut, nil)
	recorder := httptest.NewRecorder()
	mux.ServeHTTP(recorder, request)

	if recorder.Code != http.StatusOK {
		t.Fatalf("status = %d body=%s", recorder.Code, recorder.Body.String())
	}
	if useCase.saveCalls != 1 || useCase.request.SubjectID.String() != "11111111-1111-4111-8111-111111111111" ||
		useCase.request.OwnerUserID.String() != "22222222-2222-4222-8222-222222222222" ||
		useCase.request.Target.EntityType() != domain.EntityTypeActivity ||
		useCase.request.SourceSurface != domain.SourceSurfaceDetail {
		t.Fatalf("request/calls = %#v / %d", useCase.request, useCase.saveCalls)
	}
}

func TestSavedItemMutationHandlerGlobalDeleteHasNoSourceOrVersionBody(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, time.July, 16, 12, 0, 0, 0, time.UTC)
	receipt := newHTTPTestOperation(t, now, domain.OperationKindUnsave)
	useCase := &stubSavedMutationUseCase{unsaveReceipt: receipt}
	mux := newSavedMutationTestMux(t, useCase, now)
	request := savedMutationRequest(t, http.MethodDelete, nil)
	recorder := httptest.NewRecorder()
	mux.ServeHTTP(recorder, request)

	if recorder.Code != http.StatusAccepted || useCase.unsaveCalls != 1 {
		t.Fatalf("status=%d calls=%d body=%s", recorder.Code, useCase.unsaveCalls, recorder.Body.String())
	}
	if strings.Contains(recorder.Body.String(), "membership") || strings.Contains(recorder.Body.String(), "version choreography") {
		t.Fatalf("response exposed removed choreography: %s", recorder.Body.String())
	}
}

func TestSavedItemMutationHandlerRolloutBlocksOnlySaveExpansion(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, time.July, 16, 12, 0, 0, 0, time.UTC)
	saveReceipt := newHTTPTestOperation(t, now, domain.OperationKindSave)
	unsaveReceipt := newHTTPTestOperation(t, now, domain.OperationKindUnsave)
	useCase := &stubSavedMutationUseCase{saveReceipt: saveReceipt, unsaveReceipt: unsaveReceipt}
	mux := newSavedMutationTestMux(t, useCase, now)

	for _, method := range []string{http.MethodPut, http.MethodDelete} {
		request := savedMutationRequest(t, method, nil)
		request = request.WithContext(context.WithValue(
			request.Context(),
			productRolloutContextKey{},
			productrollout.Decision{},
		))
		recorder := httptest.NewRecorder()
		mux.ServeHTTP(recorder, request)
		if recorder.Code != http.StatusAccepted {
			t.Fatalf("%s status=%d body=%s", method, recorder.Code, recorder.Body.String())
		}
		if method == http.MethodPut && !useCase.request.DisableExpansion {
			t.Fatal("save expansion remained enabled for disabled rollout")
		}
		if method == http.MethodDelete && useCase.request.DisableExpansion {
			t.Fatal("global unsave was incorrectly treated as expansion")
		}
	}
}

func TestSavedItemMutationHandlerRejectsAnyBodyBeforeUseCase(t *testing.T) {
	t.Parallel()

	useCase := &stubSavedMutationUseCase{}
	mux := newSavedMutationTestMux(t, useCase, time.Now().UTC())
	for _, method := range []string{http.MethodPut, http.MethodDelete} {
		request := savedMutationRequest(t, method, strings.NewReader(`{"relationship_version":12}`))
		recorder := httptest.NewRecorder()
		mux.ServeHTTP(recorder, request)
		if recorder.Code != http.StatusBadRequest {
			t.Errorf("%s status = %d", method, recorder.Code)
		}
	}
	if useCase.saveCalls != 0 || useCase.unsaveCalls != 0 {
		t.Fatalf("use case calls save=%d unsave=%d", useCase.saveCalls, useCase.unsaveCalls)
	}
}

func TestSavedItemMutationHandlerRejectsInvalidMutationHeaders(t *testing.T) {
	t.Parallel()

	useCase := &stubSavedMutationUseCase{}
	mux := newSavedMutationTestMux(t, useCase, time.Now().UTC())
	request := savedMutationRequest(t, http.MethodPut, nil)
	request.Header.Set(HeaderIdempotencyKey, "predictable")
	recorder := httptest.NewRecorder()
	mux.ServeHTTP(recorder, request)
	if recorder.Code != http.StatusBadRequest || useCase.saveCalls != 0 {
		t.Fatalf("status=%d calls=%d", recorder.Code, useCase.saveCalls)
	}
}

func TestSavedItemMutationHandlerMapsAcceptedDomainRejectionSafely(t *testing.T) {
	t.Parallel()

	useCase := &stubSavedMutationUseCase{saveErr: domain.ErrReplayMismatch}
	mux := newSavedMutationTestMux(t, useCase, time.Now().UTC())
	recorder := httptest.NewRecorder()
	mux.ServeHTTP(recorder, savedMutationRequest(t, http.MethodPut, nil))
	if recorder.Code != http.StatusConflict {
		t.Fatalf("status=%d body=%s", recorder.Code, recorder.Body.String())
	}
	var response errorEnvelope
	if err := json.NewDecoder(recorder.Body).Decode(&response); err != nil {
		t.Fatalf("decode response: %v", err)
	}
	if response.Code != string(domain.ErrorCodeReplayMismatch) || response.Retryable {
		t.Fatalf("response=%#v", response)
	}
}

func newSavedMutationTestMux(t *testing.T, useCase SavedItemMutationUseCase, now time.Time) *http.ServeMux {
	t.Helper()
	handler, err := NewSavedItemMutationHandler(useCase, fixedResponseClock{now: now})
	if err != nil {
		t.Fatalf("NewSavedItemMutationHandler() error = %v", err)
	}
	mux := http.NewServeMux()
	if err := handler.Register(mux); err != nil {
		t.Fatalf("Register() error = %v", err)
	}
	return mux
}

func savedMutationRequest(t *testing.T, method string, body *strings.Reader) *http.Request {
	t.Helper()
	var request *http.Request
	if body == nil {
		request = httptest.NewRequest(method, "/v1/users/me/saved-items/ACTIVITY/99999999-9999-4999-8999-999999999999", nil)
	} else {
		request = httptest.NewRequest(method, "/v1/users/me/saved-items/ACTIVITY/99999999-9999-4999-8999-999999999999", body)
	}
	principalRequest := personalResponseTestRequest()
	request = request.WithContext(principalRequest.Context())
	request.Header.Set(HeaderOperationID, "33333333-3333-4333-8333-333333333333")
	request.Header.Set(HeaderIdempotencyKey, "0123456789abcdefghijklmnopqrstuv")
	request.Header.Set(HeaderSourceSurface, string(domain.SourceSurfaceDetail))
	request.Header.Set("Accept-Language", "ru")
	return request
}

type stubSavedMutationUseCase struct {
	saveReceipt   *domain.SavedOperation
	unsaveReceipt *domain.SavedOperation
	saveErr       error
	unsaveErr     error
	request       saveditem.TargetMutationRequest
	saveCalls     int
	unsaveCalls   int
}

func (s *stubSavedMutationUseCase) Save(
	_ context.Context,
	request saveditem.TargetMutationRequest,
) (*domain.SavedOperation, error) {
	s.saveCalls++
	s.request = request
	return s.saveReceipt, s.saveErr
}

func (s *stubSavedMutationUseCase) GlobalUnsave(
	_ context.Context,
	request saveditem.TargetMutationRequest,
) (*domain.SavedOperation, error) {
	s.unsaveCalls++
	s.request = request
	return s.unsaveReceipt, s.unsaveErr
}

var _ SavedItemMutationUseCase = (*stubSavedMutationUseCase)(nil)
