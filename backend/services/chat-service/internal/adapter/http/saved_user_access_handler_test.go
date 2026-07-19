package http

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/google/uuid"

	"kz/inflap/backend/services/chat-service/internal/transport/dto"
)

type savedUserAccessUseCaseFake struct {
	owner       uuid.UUID
	targets     []uuid.UUID
	denied      []uuid.UUID
	returnedErr error
}

func (fake *savedUserAccessUseCaseFake) ListSavedUserIDsDenyingAccess(
	_ context.Context,
	ownerUserID uuid.UUID,
	targetUserIDs []uuid.UUID,
) ([]uuid.UUID, error) {
	fake.owner = ownerUserID
	fake.targets = append([]uuid.UUID(nil), targetUserIDs...)
	return append([]uuid.UUID(nil), fake.denied...), fake.returnedErr
}

func TestCheckSavedUserAccessReturnsOnlyDeniedTargets(t *testing.T) {
	t.Parallel()

	ownerUserID := uuid.New()
	allowedUserID := uuid.New()
	deniedUserID := uuid.New()
	useCase := &savedUserAccessUseCaseFake{denied: []uuid.UUID{deniedUserID}}
	handler := &Handler{savedAccessUC: useCase}
	body := `{"ownerUserId":"` + ownerUserID.String() + `","targetUserIds":["` +
		allowedUserID.String() + `","` + deniedUserID.String() + `"]}`
	request := httptest.NewRequest(http.MethodPost, "/v1/internal/saved-user-access/check", strings.NewReader(body))
	request.Header.Set("X-Service-Name", "saved-service")
	request = request.WithContext(withInternalCall(request.Context()))
	response := httptest.NewRecorder()

	handler.CheckSavedUserAccess(response, request)

	if response.Code != http.StatusOK {
		t.Fatalf("status = %d, body = %s", response.Code, response.Body.String())
	}
	if response.Header().Get("Cache-Control") != "no-store" {
		t.Fatalf("Cache-Control = %q", response.Header().Get("Cache-Control"))
	}
	if useCase.owner != ownerUserID || len(useCase.targets) != 2 ||
		useCase.targets[0] != allowedUserID || useCase.targets[1] != deniedUserID {
		t.Fatalf("captured owner=%s targets=%v", useCase.owner, useCase.targets)
	}
	var payload dto.SavedUserAccessCheckResponse
	if err := json.Unmarshal(response.Body.Bytes(), &payload); err != nil {
		t.Fatalf("decode response: %v", err)
	}
	if len(payload.DeniedTargetUserIDs) != 1 || payload.DeniedTargetUserIDs[0] != deniedUserID.String() {
		t.Fatalf("payload = %+v", payload)
	}
}

func TestCheckSavedUserAccessRejectsUntrustedOrMalformedRequests(t *testing.T) {
	t.Parallel()

	ownerUserID := uuid.New()
	targetUserID := uuid.New()
	validBody := `{"ownerUserId":"` + ownerUserID.String() + `","targetUserIds":["` + targetUserID.String() + `"]}`
	tests := []struct {
		name       string
		body       string
		internal   bool
		caller     string
		wantStatus int
	}{
		{name: "missing internal auth", body: validBody, caller: "saved-service", wantStatus: http.StatusUnauthorized},
		{name: "wrong caller", body: validBody, internal: true, caller: "guide-service", wantStatus: http.StatusForbidden},
		{name: "unknown field", body: strings.TrimSuffix(validBody, "}") + `,"unexpected":true}`, internal: true, caller: "saved-service", wantStatus: http.StatusBadRequest},
		{name: "duplicate target", body: `{"ownerUserId":"` + ownerUserID.String() + `","targetUserIds":["` + targetUserID.String() + `","` + targetUserID.String() + `"]}`, internal: true, caller: "saved-service", wantStatus: http.StatusBadRequest},
	}
	for _, testCase := range tests {
		t.Run(testCase.name, func(t *testing.T) {
			handler := &Handler{savedAccessUC: &savedUserAccessUseCaseFake{}}
			request := httptest.NewRequest(http.MethodPost, "/v1/internal/saved-user-access/check", strings.NewReader(testCase.body))
			request.Header.Set("X-Service-Name", testCase.caller)
			if testCase.internal {
				request = request.WithContext(withInternalCall(request.Context()))
			}
			response := httptest.NewRecorder()

			handler.CheckSavedUserAccess(response, request)

			if response.Code != testCase.wantStatus {
				t.Fatalf("status = %d, want %d; body=%s", response.Code, testCase.wantStatus, response.Body.String())
			}
		})
	}
}

func TestCheckSavedUserAccessFailsClosedWhenUseCaseFails(t *testing.T) {
	t.Parallel()

	ownerUserID := uuid.New()
	targetUserID := uuid.New()
	handler := &Handler{savedAccessUC: &savedUserAccessUseCaseFake{returnedErr: errors.New("database unavailable")}}
	body := `{"ownerUserId":"` + ownerUserID.String() + `","targetUserIds":["` + targetUserID.String() + `"]}`
	request := httptest.NewRequest(http.MethodPost, "/v1/internal/saved-user-access/check", strings.NewReader(body))
	request.Header.Set("X-Service-Name", "saved-service")
	request = request.WithContext(withInternalCall(request.Context()))
	response := httptest.NewRecorder()

	handler.CheckSavedUserAccess(response, request)

	if response.Code != http.StatusInternalServerError {
		t.Fatalf("status = %d, body = %s", response.Code, response.Body.String())
	}
}
