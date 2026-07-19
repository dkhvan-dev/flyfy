package http

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/saved-service/internal/app/cursor"
	"kz/inflap/backend/services/saved-service/internal/app/savedquery"
	"kz/inflap/backend/services/saved-service/internal/domain"
)

func TestSavedQueryHandlerListsStrictPublicAndUnavailableCards(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, time.July, 16, 12, 0, 0, 0, time.UTC)
	publicTarget := mustHTTPQueryTarget(t, domain.EntityTypeActivity)
	unavailableTarget := mustHTTPQueryTarget(t, domain.EntityTypeActivity)
	nextItemID := uuid.New()
	useCase := &stubSavedQueryUseCase{page: savedquery.Page{
		Items: []savedquery.Item{
			{
				ItemID: publicTargetID(publicTarget),
				Target: publicTarget,
				Relationship: savedquery.ActiveRelationship{
					Generation: uuid.New(), Version: 3, SavedAt: now, AttributionID: uuid.New(),
				},
				EffectiveCollectionCount: 2,
				Projection: savedquery.CardProjection{
					ContentState: savedquery.ContentStateAvailable,
					Revisions:    savedquery.SourceRevisions{Source: 7, Projection: 8, Visibility: 9},
					Public: &savedquery.PublicCardProjection{
						DisplayLocale: savedquery.LocaleRU,
						Title:         "Прогулка", CanonicalDetailRoute: "/activities/" + publicTarget.EntityID(),
						SourceUpdatedAt: now,
					},
				},
			},
			{
				ItemID: nextItemID,
				Target: unavailableTarget,
				Relationship: savedquery.ActiveRelationship{
					Generation: uuid.New(), Version: 4, SavedAt: now.Add(-time.Second), AttributionID: uuid.New(),
				},
				Projection: savedquery.CardProjection{
					ContentState: savedquery.ContentStateUnavailable,
					Revisions:    savedquery.SourceRevisions{Source: 10, Projection: 11, Visibility: 12},
				},
			},
		},
		Next:    &savedquery.Keyset{SavedAt: now.Add(-time.Second), ItemID: nextItemID},
		HasMore: true,
	}}
	handler := newSavedQueryTestHandler(t, useCase)
	request := queryRequestWithPrincipal(
		http.MethodGet,
		"/v1/users/me/saved-items?type=ACTIVITY&limit=2",
		nil,
	)
	request.Header.Set("Accept-Language", "ru-KZ")
	recorder := httptest.NewRecorder()
	handler.List(recorder, request)

	if recorder.Code != http.StatusOK {
		t.Fatalf("status=%d body=%s", recorder.Code, recorder.Body.String())
	}
	if useCase.listInput.OwnerUserID.String() != "22222222-2222-4222-8222-222222222222" ||
		useCase.listInput.Locale != savedquery.LocaleRU || useCase.listInput.Limit != 2 ||
		useCase.listInput.EntityType == nil || *useCase.listInput.EntityType != domain.EntityTypeActivity {
		t.Fatalf("list input = %#v", useCase.listInput)
	}
	body := recorder.Body.String()
	for _, required := range []string{`"canonical_detail_route":"/activities/`, `"content_state":"UNAVAILABLE"`, `"next_cursor":"`} {
		if !strings.Contains(body, required) {
			t.Errorf("response missing %s: %s", required, body)
		}
	}
	for _, forbidden := range []string{"attribution_id", "opaque_reference", "relationship_attribution_id"} {
		if strings.Contains(body, forbidden) {
			t.Errorf("response leaked %q: %s", forbidden, body)
		}
	}
}

func TestSavedQueryCursorIsBoundToOwnerFiltersAndLocale(t *testing.T) {
	t.Parallel()

	now := time.Now().UTC().Truncate(time.Microsecond)
	target := mustHTTPQueryTarget(t, domain.EntityTypeGuide)
	itemID := uuid.New()
	useCase := &stubSavedQueryUseCase{page: savedquery.Page{
		Items: []savedquery.Item{{
			ItemID: itemID,
			Target: target,
			Relationship: savedquery.ActiveRelationship{
				Generation: uuid.New(), Version: 1, SavedAt: now, AttributionID: uuid.New(),
			},
			Projection: savedquery.CardProjection{
				ContentState: savedquery.ContentStateUnavailable,
				Revisions:    savedquery.SourceRevisions{Projection: 1},
			},
		}},
		Next:    &savedquery.Keyset{SavedAt: now, ItemID: itemID},
		HasMore: true,
	}}
	handler := newSavedQueryTestHandler(t, useCase)
	first := httptest.NewRecorder()
	firstRequest := queryRequestWithPrincipal(http.MethodGet, "/v1/users/me/saved-items?type=GUIDE", nil)
	firstRequest.Header.Set("Accept-Language", "en")
	handler.List(first, firstRequest)
	if first.Code != http.StatusOK {
		t.Fatalf("first status=%d body=%s", first.Code, first.Body.String())
	}
	var page savedItemsPageResponse
	if err := json.NewDecoder(first.Body).Decode(&page); err != nil || page.NextCursor == nil {
		t.Fatalf("decode first page: cursor=%v err=%v", page.NextCursor, err)
	}

	wrongFilter := queryRequestWithPrincipal(
		http.MethodGet,
		"/v1/users/me/saved-items?type=ACTIVITY&cursor="+*page.NextCursor,
		nil,
	)
	wrongFilter.Header.Set("Accept-Language", "en")
	recorder := httptest.NewRecorder()
	handler.List(recorder, wrongFilter)
	if recorder.Code != http.StatusBadRequest || !strings.Contains(recorder.Body.String(), string(domain.ErrorCodeCursorInvalid)) {
		t.Fatalf("wrong-filter status=%d body=%s", recorder.Code, recorder.Body.String())
	}
	if useCase.listCalls != 1 {
		t.Fatalf("list calls=%d, cursor mismatch reached use case", useCase.listCalls)
	}
}

func TestSavedQueryBatchStatusPreservesUnknownDistinctFromUnsave(t *testing.T) {
	t.Parallel()

	unknown := mustHTTPQueryTarget(t, domain.EntityTypeGuide)
	unsaved := mustHTTPQueryTarget(t, domain.EntityTypeAttraction)
	useCase := &stubSavedQueryUseCase{statuses: []savedquery.TargetStatus{
		{
			Target: unknown, SavedState: savedquery.SavedStateUnknown,
			Eligibility: savedquery.EligibilityUnknown,
		},
		{
			Target: unsaved, SavedState: savedquery.SavedStateConfirmedUnsaved,
			Eligibility: savedquery.EligibilityEligible, ResourceVersion: 4,
		},
	}}
	handler := newSavedQueryTestHandler(t, useCase)
	body := `{"targets":[{"entity_type":"GUIDE","entity_id":"` + unknown.EntityID() + `"},{"entity_type":"ATTRACTION","entity_id":"` + unsaved.EntityID() + `"}]}`
	recorder := httptest.NewRecorder()
	handler.BatchStatus(recorder, queryRequestWithPrincipal(http.MethodPost, "/v1/users/me/saved-items/status:batch", strings.NewReader(body)))
	if recorder.Code != http.StatusOK {
		t.Fatalf("status=%d body=%s", recorder.Code, recorder.Body.String())
	}
	if !strings.Contains(recorder.Body.String(), `"saved_state":"UNKNOWN"`) ||
		!strings.Contains(recorder.Body.String(), `"saved_state":"CONFIRMED_UNSAVED"`) {
		t.Fatalf("response=%s", recorder.Body.String())
	}
}

func TestSavedQueryHandlerRejectsUnknownOrRepeatedListParameters(t *testing.T) {
	t.Parallel()

	useCase := &stubSavedQueryUseCase{}
	handler := newSavedQueryTestHandler(t, useCase)
	for _, path := range []string{
		"/v1/users/me/saved-items?owner_id=forged",
		"/v1/users/me/saved-items?limit=10&limit=20",
		"/v1/users/me/saved-items?collection_id=11111111-1111-4111-8111-111111111111&uncollected=true",
	} {
		recorder := httptest.NewRecorder()
		handler.List(recorder, queryRequestWithPrincipal(http.MethodGet, path, nil))
		if recorder.Code != http.StatusBadRequest {
			t.Errorf("path=%s status=%d", path, recorder.Code)
		}
	}
	if useCase.listCalls != 0 {
		t.Fatalf("list calls=%d", useCase.listCalls)
	}
}

func newSavedQueryTestHandler(t *testing.T, useCase SavedQueryUseCase) *SavedQueryHandler {
	t.Helper()
	key := bytes.Repeat([]byte{0x42}, 32)
	codec, err := cursor.NewCodec([]cursor.Key{{ID: 1, Secret: key}}, 1, 15*time.Minute)
	if err != nil {
		t.Fatalf("cursor.NewCodec() error=%v", err)
	}
	fingerprinter, err := cursor.NewFingerprinter(bytes.Repeat([]byte{0x24}, 32))
	if err != nil {
		t.Fatalf("cursor.NewFingerprinter() error=%v", err)
	}
	handler, err := NewSavedQueryHandler(useCase, codec, fingerprinter)
	if err != nil {
		t.Fatalf("NewSavedQueryHandler() error=%v", err)
	}
	return handler
}

func queryRequestWithPrincipal(method, path string, body *strings.Reader) *http.Request {
	var request *http.Request
	if body == nil {
		request = httptest.NewRequest(method, path, nil)
	} else {
		request = httptest.NewRequest(method, path, body)
	}
	return request.WithContext(personalResponseTestRequest().Context())
}

func mustHTTPQueryTarget(t *testing.T, entityType domain.EntityType) domain.SavedTarget {
	t.Helper()
	target, err := domain.NewSavedTarget(entityType, uuid.NewString())
	if err != nil {
		t.Fatalf("NewSavedTarget() error=%v", err)
	}
	return target
}

func publicTargetID(target domain.SavedTarget) uuid.UUID {
	return uuid.MustParse(target.EntityID())
}

type stubSavedQueryUseCase struct {
	statuses     []savedquery.TargetStatus
	page         savedquery.Page
	batchErr     error
	listErr      error
	batchOwner   uuid.UUID
	batchTargets []domain.SavedTarget
	listInput    savedquery.ListInput
	batchCalls   int
	listCalls    int
}

func (s *stubSavedQueryUseCase) BatchStatus(
	_ context.Context,
	owner uuid.UUID,
	targets []domain.SavedTarget,
) ([]savedquery.TargetStatus, error) {
	s.batchCalls++
	s.batchOwner = owner
	s.batchTargets = append([]domain.SavedTarget(nil), targets...)
	return s.statuses, s.batchErr
}

func (s *stubSavedQueryUseCase) ListItems(
	_ context.Context,
	input savedquery.ListInput,
) (savedquery.Page, error) {
	s.listCalls++
	s.listInput = input
	return s.page, s.listErr
}

var _ SavedQueryUseCase = (*stubSavedQueryUseCase)(nil)
