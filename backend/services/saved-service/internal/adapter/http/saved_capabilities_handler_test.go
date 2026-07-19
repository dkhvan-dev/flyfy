package http

import (
	"context"
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/google/uuid"

	"kz/inflap/backend/services/saved-service/internal/app/productrollout"
	"kz/inflap/backend/services/saved-service/internal/app/savedcapability"
	"kz/inflap/backend/services/saved-service/internal/domain"
)

type savedCapabilitiesUseCaseStub struct {
	snapshot savedcapability.Snapshot
	err      error
	owner    uuid.UUID
	calls    int
}

func (stub *savedCapabilitiesUseCaseStub) Get(
	_ context.Context,
	owner uuid.UUID,
) (savedcapability.Snapshot, error) {
	stub.owner = owner
	stub.calls++
	return stub.snapshot, stub.err
}

func TestSavedCapabilitiesHandlerReturnsEffectiveSnapshot(t *testing.T) {
	t.Parallel()
	useCase := &savedCapabilitiesUseCaseStub{snapshot: savedcapability.Snapshot{
		CapabilityRevision: "saved-2026.07-v1",
		ProductFlags: savedcapability.ProductFlags{
			SavedItemsEnabled: true,
		},
		HasConfirmedSavedData: true,
		SupportedEntityTypes: []domain.EntityType{
			domain.EntityTypeAttraction,
			domain.EntityTypeActivity,
			domain.EntityTypeUser,
		},
		QuotaWarning: &savedcapability.QuotaWarning{
			Resource: "SAVED_ITEMS", Limit: 10_000, Remaining: 91,
		},
	}}
	handler, err := NewSavedCapabilitiesHandler(useCase)
	if err != nil {
		t.Fatalf("NewSavedCapabilitiesHandler() error = %v", err)
	}
	request := queryRequestWithPrincipal(http.MethodGet, "/v1/users/me/saved-items/capabilities", nil)
	request.Header.Set("Accept-Language", "kk-KZ,ru;q=0.8")
	recorder := httptest.NewRecorder()

	handler.Get(recorder, request)

	if recorder.Code != http.StatusOK {
		t.Fatalf("status=%d body=%s", recorder.Code, recorder.Body.String())
	}
	if useCase.owner.String() != "22222222-2222-4222-8222-222222222222" || useCase.calls != 1 {
		t.Fatalf("owner=%s calls=%d", useCase.owner, useCase.calls)
	}
	body := recorder.Body.String()
	for _, expected := range []string{
		`"capability_revision":"saved-2026.07-v1"`,
		`"saved_items_enabled":true`,
		`"search_enabled":false`,
		`"collections_enabled":false`,
		`"has_confirmed_saved_data":true`,
		`"supported_entity_types":["ATTRACTION","ACTIVITY","USER"]`,
		`"effective_locale":"kk"`,
		`"remaining":91`,
	} {
		if !strings.Contains(body, expected) {
			t.Errorf("response missing %s: %s", expected, body)
		}
	}
	if strings.Contains(body, "EXCURSION") {
		t.Fatalf("response advertised unsupported Excursion: %s", body)
	}
	if recorder.Header().Get("Cache-Control") != "private, no-store" {
		t.Fatalf("Cache-Control=%q", recorder.Header().Get("Cache-Control"))
	}
}

func TestSavedCapabilitiesHandlerRejectsUnexpectedInputBeforeUseCase(t *testing.T) {
	t.Parallel()
	useCase := &savedCapabilitiesUseCaseStub{}
	handler, err := NewSavedCapabilitiesHandler(useCase)
	if err != nil {
		t.Fatalf("NewSavedCapabilitiesHandler() error = %v", err)
	}
	for _, request := range []*http.Request{
		queryRequestWithPrincipal(http.MethodGet, "/v1/users/me/saved-items/capabilities?owner_id=forged", nil),
		queryRequestWithPrincipal(http.MethodGet, "/v1/users/me/saved-items/capabilities", strings.NewReader("{}")),
	} {
		recorder := httptest.NewRecorder()
		handler.Get(recorder, request)
		if recorder.Code != http.StatusBadRequest {
			t.Errorf("status=%d body=%s", recorder.Code, recorder.Body.String())
		}
	}
	if useCase.calls != 0 {
		t.Fatalf("use case calls=%d", useCase.calls)
	}
}

func TestSavedCapabilitiesHandlerMasksFlagsAndEntityTypesByRollout(t *testing.T) {
	t.Parallel()

	useCase := &savedCapabilitiesUseCaseStub{snapshot: savedcapability.Snapshot{
		CapabilityRevision: "saved-v1",
		ProductFlags: savedcapability.ProductFlags{
			SavedItemsEnabled:  true,
			SearchEnabled:      true,
			CollectionsEnabled: true,
		},
		SupportedEntityTypes: []domain.EntityType{
			domain.EntityTypeAttraction,
			domain.EntityTypeActivity,
			domain.EntityTypeUser,
		},
	}}
	handler, err := NewSavedCapabilitiesHandler(useCase)
	if err != nil {
		t.Fatalf("NewSavedCapabilitiesHandler() error = %v", err)
	}
	request := queryRequestWithPrincipal(http.MethodGet, "/v1/users/me/saved-items/capabilities", nil)
	request = request.WithContext(context.WithValue(
		request.Context(),
		productRolloutContextKey{},
		productrollout.Decision{
			SavedCore:   true,
			SavedSearch: true,
			Entities:    productrollout.EntityDecision{Activity: true},
		},
	))
	recorder := httptest.NewRecorder()

	handler.Get(recorder, request)

	if recorder.Code != http.StatusOK {
		t.Fatalf("status=%d body=%s", recorder.Code, recorder.Body.String())
	}
	body := recorder.Body.String()
	for _, expected := range []string{
		`"saved_items_enabled":true`,
		`"search_enabled":true`,
		`"collections_enabled":false`,
		`"supported_entity_types":["ACTIVITY"]`,
	} {
		if !strings.Contains(body, expected) {
			t.Errorf("response missing %s: %s", expected, body)
		}
	}
}

func TestSavedCapabilitiesHandlerFailsClosedOnRepositoryError(t *testing.T) {
	t.Parallel()
	useCase := &savedCapabilitiesUseCaseStub{err: errors.New("database unavailable")}
	handler, err := NewSavedCapabilitiesHandler(useCase)
	if err != nil {
		t.Fatalf("NewSavedCapabilitiesHandler() error = %v", err)
	}
	recorder := httptest.NewRecorder()
	handler.Get(recorder, queryRequestWithPrincipal(http.MethodGet, "/v1/users/me/saved-items/capabilities", nil))
	if recorder.Code != http.StatusServiceUnavailable || strings.Contains(recorder.Body.String(), "database") {
		t.Fatalf("status=%d body=%s", recorder.Code, recorder.Body.String())
	}
}
