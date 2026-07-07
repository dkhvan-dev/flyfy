package http

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"sync"
	"testing"
	"time"

	"kz/inflap/backend/pkg/serviceauth"
	"kz/inflap/backend/services/search-service/internal/app"
	"kz/inflap/backend/services/search-service/internal/domain/model"
)

func TestSearchRejectsUnsupportedDomains(t *testing.T) {
	handler := NewHandler(app.NewSearchUseCase(&fakeSearchRepository{}))
	req := httptest.NewRequest(http.MethodGet, "/v1/search?scope=global&domains=routes&q=almaty", nil)
	rec := httptest.NewRecorder()

	handler.Search(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("status = %d, want %d: %s", rec.Code, http.StatusBadRequest, rec.Body.String())
	}
}

func TestSearchAppliesEntityScope(t *testing.T) {
	repo := &fakeSearchRepository{
		page: app.SearchPage{
			Items: []model.SearchResult{
				{
					Domain:   model.DomainActivity,
					EntityID: "activity-1",
					Title:    "Mountain walk",
					DeepLink: "/activities/activity-1",
					Score:    1,
				},
			},
		},
	}
	handler := NewHandler(app.NewSearchUseCase(repo))
	req := httptest.NewRequest(http.MethodGet, "/v1/search?scope=activity&q=mountain", nil)
	rec := httptest.NewRecorder()

	handler.Search(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d: %s", rec.Code, http.StatusOK, rec.Body.String())
	}
	if len(repo.lastQuery.Domains) != 1 || repo.lastQuery.Domains[0] != model.DomainActivity {
		t.Fatalf("domains = %#v, want activity only", repo.lastQuery.Domains)
	}

	var payload map[string]any
	if err := json.Unmarshal(rec.Body.Bytes(), &payload); err != nil {
		t.Fatalf("decode response: %v", err)
	}
	groups := payload["groups"].(map[string]any)
	activities := groups["activities"].(map[string]any)
	if len(activities["items"].([]any)) != 1 {
		t.Fatalf("activities group = %#v, want one item", groups["activities"])
	}
	places := groups["places"].(map[string]any)
	if len(places["items"].([]any)) != 0 {
		t.Fatalf("places group = %#v, want empty", groups["places"])
	}
}

func TestSearchReturnsBackendOwnedPaginationPerGroup(t *testing.T) {
	repo := &fakeSearchRepository{
		page: app.SearchPage{
			Items: []model.SearchResult{
				{
					Domain:   model.DomainPlace,
					EntityID: "place-top",
					Title:    "Charyn Canyon",
					DeepLink: "/places/place-top",
					Score:    1,
				},
			},
			NextPageToken: "top-next",
		},
		pagesByDomain: map[model.Domain]app.SearchPage{
			model.DomainPlace: {
				Items: []model.SearchResult{
					{
						Domain:   model.DomainPlace,
						EntityID: "place-1",
						Title:    "Charyn Canyon",
						DeepLink: "/places/place-1",
						Score:    0.99,
					},
					{
						Domain:   model.DomainPlace,
						EntityID: "place-2",
						Title:    "Charyn Valley",
						DeepLink: "/places/place-2",
						Score:    0.93,
					},
				},
				NextPageToken: "places-next",
			},
			model.DomainActivity: {
				Items: []model.SearchResult{
					{
						Domain:   model.DomainActivity,
						EntityID: "activity-1",
						Title:    "Charyn hike",
						DeepLink: "/activities/activity-1",
						Score:    0.88,
					},
				},
			},
		},
	}
	handler := NewHandler(app.NewSearchUseCase(repo))
	req := httptest.NewRequest(
		http.MethodGet,
		"/v1/search?scope=global&q=charyn&page_size=3&group_page_size=2",
		nil,
	)
	rec := httptest.NewRecorder()

	handler.Search(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d: %s", rec.Code, http.StatusOK, rec.Body.String())
	}

	var payload struct {
		TopResults []searchResultResponse `json:"topResults"`
		Groups     struct {
			Places struct {
				Items         []searchResultResponse `json:"items"`
				NextPageToken string                 `json:"nextPageToken"`
				HasMore       bool                   `json:"hasMore"`
			} `json:"places"`
			Activities struct {
				Items         []searchResultResponse `json:"items"`
				NextPageToken string                 `json:"nextPageToken"`
				HasMore       bool                   `json:"hasMore"`
			} `json:"activities"`
		} `json:"groups"`
		NextPageToken string `json:"nextPageToken"`
	}
	if err := json.Unmarshal(rec.Body.Bytes(), &payload); err != nil {
		t.Fatalf("decode response: %v\n%s", err, rec.Body.String())
	}
	if payload.NextPageToken != "top-next" {
		t.Fatalf("top next page token = %q, want top-next", payload.NextPageToken)
	}
	if len(payload.Groups.Places.Items) != 2 {
		t.Fatalf("places items = %#v, want two backend-paged items", payload.Groups.Places.Items)
	}
	if payload.Groups.Places.NextPageToken != "places-next" || !payload.Groups.Places.HasMore {
		t.Fatalf("places pagination = token %q hasMore %v, want places-next/true", payload.Groups.Places.NextPageToken, payload.Groups.Places.HasMore)
	}
	if len(payload.Groups.Activities.Items) != 1 {
		t.Fatalf("activities items = %#v, want one item", payload.Groups.Activities.Items)
	}
	if payload.Groups.Activities.NextPageToken != "" || payload.Groups.Activities.HasMore {
		t.Fatalf("activities pagination = token %q hasMore %v, want empty/false", payload.Groups.Activities.NextPageToken, payload.Groups.Activities.HasMore)
	}
}

func TestSuggestRejectsUnsupportedDomains(t *testing.T) {
	handler := NewHandler(app.NewSearchUseCase(&fakeSearchRepository{}))
	req := httptest.NewRequest(http.MethodGet, "/v1/search/suggest?scope=global&domains=chats&q=hello", nil)
	rec := httptest.NewRecorder()

	handler.Suggest(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("status = %d, want %d: %s", rec.Code, http.StatusBadRequest, rec.Body.String())
	}
}

func TestTrendingUsesGlobalScopeByDefault(t *testing.T) {
	repo := &fakeSearchRepository{}
	handler := NewHandler(app.NewSearchUseCase(repo))
	req := httptest.NewRequest(http.MethodGet, "/v1/search/trending", nil)
	rec := httptest.NewRecorder()

	handler.Trending(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d: %s", rec.Code, http.StatusOK, rec.Body.String())
	}
	queries := repo.recordedQueries()
	if len(queries) == 0 {
		t.Fatal("repository queries = 0, want top-level search query")
	}
	hasGlobalQuery := false
	for _, query := range queries {
		if len(query.Domains) == 6 {
			hasGlobalQuery = true
			break
		}
	}
	if !hasGlobalQuery {
		t.Fatalf("queries = %#v, want one top-level query with all searchable domains", queries)
	}
}

func TestTrackEventAcceptsKnownSearchEvent(t *testing.T) {
	handler := NewHandler(app.NewSearchUseCase(&fakeSearchRepository{}))
	req := httptest.NewRequest(http.MethodPost, "/v1/search/events", strings.NewReader(`{"eventType":"search_submitted"}`))
	rec := httptest.NewRecorder()

	handler.TrackEvent(rec, req)

	if rec.Code != http.StatusAccepted {
		t.Fatalf("status = %d, want %d: %s", rec.Code, http.StatusAccepted, rec.Body.String())
	}
}

func TestTrackEventPersistsPrivacySafeEvent(t *testing.T) {
	eventRepo := &fakeSearchEventRepository{}
	handler := NewHandler(
		app.NewSearchUseCase(&fakeSearchRepository{}),
		WithEvents(app.NewSearchEventUseCase(eventRepo)),
	)
	req := httptest.NewRequest(
		http.MethodPost,
		"/v1/search/events",
		strings.NewReader(`{"eventType":"result_clicked","searchSessionId":"session-1","query":"ada@example.com","scope":"global","domain":"user","entityId":"user-1","resultPosition":2,"locale":"RU"}`),
	)
	req.Header.Set("X-Request-Id", "request-1")
	req.Header.Set("X-User-Id", "user-private-id")
	rec := httptest.NewRecorder()

	handler.TrackEvent(rec, req)

	if rec.Code != http.StatusAccepted {
		t.Fatalf("status = %d, want %d: %s", rec.Code, http.StatusAccepted, rec.Body.String())
	}
	if eventRepo.calls != 1 {
		t.Fatalf("event repository calls = %d, want 1", eventRepo.calls)
	}
	event := eventRepo.lastEvent
	if event.EventType != "result_clicked" ||
		event.SearchSessionID != "session-1" ||
		event.QueryHash == "" ||
		event.QueryHash == "ada@example.com" ||
		event.UserIDHash == "user-private-id" ||
		event.RequestID != "request-1" {
		t.Fatalf("event = %+v", event)
	}
}

func TestIndexDocumentRequiresInternalToken(t *testing.T) {
	handler := NewHandler(
		app.NewSearchUseCase(&fakeSearchRepository{}),
		WithIndexing(app.NewIndexingUseCase(&fakeIndexRepository{})),
		WithInternalToken("internal-token"),
	)
	mux := http.NewServeMux()
	handler.Register(mux)

	req := httptest.NewRequest(
		http.MethodPost,
		"/v1/search/index/documents",
		strings.NewReader(`{"domain":"place","entityId":"place-1","title":{"en":"Almaty"},"deepLink":"/places/place-1"}`),
	)
	rec := httptest.NewRecorder()

	mux.ServeHTTP(rec, req)

	if rec.Code != http.StatusUnauthorized {
		t.Fatalf("status = %d, want %d: %s", rec.Code, http.StatusUnauthorized, rec.Body.String())
	}
}

func TestIndexDocumentUpsertsWithInternalToken(t *testing.T) {
	indexRepo := &fakeIndexRepository{}
	handler := NewHandler(
		app.NewSearchUseCase(&fakeSearchRepository{}),
		WithIndexing(app.NewIndexingUseCase(indexRepo)),
		WithInternalToken("internal-token"),
	)
	mux := http.NewServeMux()
	handler.Register(mux)

	req := httptest.NewRequest(
		http.MethodPost,
		"/v1/search/index/documents",
		strings.NewReader(`{"domain":"place","entityId":"place-1","locale":"ru","title":{"ru":"Алматы"},"deepLink":"/places/place-1"}`),
	)
	req.Header.Set("Authorization", "Bearer internal-token")
	rec := httptest.NewRecorder()

	mux.ServeHTTP(rec, req)

	if rec.Code != http.StatusAccepted {
		t.Fatalf("status = %d, want %d: %s", rec.Code, http.StatusAccepted, rec.Body.String())
	}
	if indexRepo.upsertCalls != 1 {
		t.Fatalf("upsert calls = %d, want 1", indexRepo.upsertCalls)
	}
	if indexRepo.lastDocument.Domain != model.DomainPlace || indexRepo.lastDocument.EntityID != "place-1" {
		t.Fatalf("indexed document = %#v, want place/place-1", indexRepo.lastDocument)
	}
}

func TestDeleteIndexDocumentSoftDeletesWithInternalToken(t *testing.T) {
	indexRepo := &fakeIndexRepository{}
	handler := NewHandler(
		app.NewSearchUseCase(&fakeSearchRepository{}),
		WithIndexing(app.NewIndexingUseCase(indexRepo)),
		WithInternalToken("internal-token"),
	)
	mux := http.NewServeMux()
	handler.Register(mux)

	req := httptest.NewRequest(http.MethodDelete, "/v1/search/index/documents/guide/guide-1?locale=kk", nil)
	req.Header.Set("X-Internal-Service-Token", "internal-token")
	rec := httptest.NewRecorder()

	mux.ServeHTTP(rec, req)

	if rec.Code != http.StatusAccepted {
		t.Fatalf("status = %d, want %d: %s", rec.Code, http.StatusAccepted, rec.Body.String())
	}
	if indexRepo.deleteCalls != 1 {
		t.Fatalf("delete calls = %d, want 1", indexRepo.deleteCalls)
	}
	if indexRepo.lastDeleteDomain != model.DomainGuide ||
		indexRepo.lastDeleteEntityID != "guide-1" ||
		indexRepo.lastDeleteLocale != "kk" {
		t.Fatalf(
			"delete identity = %q/%q/%q, want guide/guide-1/kk",
			indexRepo.lastDeleteDomain,
			indexRepo.lastDeleteEntityID,
			indexRepo.lastDeleteLocale,
		)
	}
}

func TestIndexEventRequiresInternalToken(t *testing.T) {
	handler := NewHandler(
		app.NewSearchUseCase(&fakeSearchRepository{}),
		WithDocumentEvents(app.NewDocumentEventUseCase(&fakeDocumentEventRepository{}, app.NewIndexingUseCase(&fakeIndexRepository{}))),
		WithInternalToken("internal-token"),
	)
	mux := http.NewServeMux()
	handler.Register(mux)

	req := httptest.NewRequest(
		http.MethodPost,
		"/v1/search/index/events",
		strings.NewReader(`{"sourceService":"place-service","sourceEventId":"event-1","aggregateType":"place","aggregateId":"place-1","eventType":"search_document_upsert","payload":{"domain":"place","entityId":"place-1","title":{"en":"Almaty"},"deepLink":"/places/place-1"}}`),
	)
	rec := httptest.NewRecorder()

	mux.ServeHTTP(rec, req)

	if rec.Code != http.StatusUnauthorized {
		t.Fatalf("status = %d, want %d: %s", rec.Code, http.StatusUnauthorized, rec.Body.String())
	}
}

func TestIndexEventEnqueuesWithInternalToken(t *testing.T) {
	eventRepo := &fakeDocumentEventRepository{}
	handler := NewHandler(
		app.NewSearchUseCase(&fakeSearchRepository{}),
		WithDocumentEvents(app.NewDocumentEventUseCase(eventRepo, app.NewIndexingUseCase(&fakeIndexRepository{}))),
		WithInternalToken("internal-token"),
	)
	mux := http.NewServeMux()
	handler.Register(mux)

	req := httptest.NewRequest(
		http.MethodPost,
		"/v1/search/index/events",
		strings.NewReader(`{"sourceService":"place-service","sourceEventId":"event-1","aggregateType":"place","aggregateId":"place-1","eventType":"search_document_upsert","payload":{"domain":"place","entityId":"place-1","title":{"en":"Almaty"},"deepLink":"/places/place-1"}}`),
	)
	req.Header.Set("X-Internal-Service-Token", "internal-token")
	rec := httptest.NewRecorder()

	mux.ServeHTTP(rec, req)

	if rec.Code != http.StatusAccepted {
		t.Fatalf("status = %d, want %d: %s", rec.Code, http.StatusAccepted, rec.Body.String())
	}
	if eventRepo.enqueueCalls != 1 {
		t.Fatalf("enqueue calls = %d, want 1", eventRepo.enqueueCalls)
	}
	if eventRepo.enqueuedEvent.SourceService != "place-service" ||
		eventRepo.enqueuedEvent.SourceEventID != "event-1" ||
		eventRepo.enqueuedEvent.EventType != app.DocumentEventTypeUpsert {
		t.Fatalf("event = %+v", eventRepo.enqueuedEvent)
	}
}

func TestIndexEventEnqueuesWithServiceJWT(t *testing.T) {
	eventRepo := &fakeDocumentEventRepository{}
	authorizer := &fakeServiceAuthorizer{}
	handler := NewHandler(
		app.NewSearchUseCase(&fakeSearchRepository{}),
		WithDocumentEvents(app.NewDocumentEventUseCase(eventRepo, app.NewIndexingUseCase(&fakeIndexRepository{}))),
		WithServiceAuthorizer(authorizer),
	)
	mux := http.NewServeMux()
	handler.Register(mux)

	req := httptest.NewRequest(
		http.MethodPost,
		"/v1/search/index/events",
		strings.NewReader(`{"sourceService":"place-service","sourceEventId":"event-1","aggregateType":"place","aggregateId":"place-1","eventType":"search_document_upsert","payload":{"domain":"place","entityId":"place-1","title":{"en":"Almaty"},"deepLink":"/places/place-1"}}`),
	)
	req.Header.Set("Authorization", "Bearer service-jwt")
	rec := httptest.NewRecorder()

	mux.ServeHTTP(rec, req)

	if rec.Code != http.StatusAccepted {
		t.Fatalf("status = %d, want %d: %s", rec.Code, http.StatusAccepted, rec.Body.String())
	}
	if authorizer.lastAuthHeader != "Bearer service-jwt" {
		t.Fatalf("auth header = %q, want bearer service jwt", authorizer.lastAuthHeader)
	}
	if len(authorizer.lastRequiredRoles) != 1 || authorizer.lastRequiredRoles[0] != "search:index" {
		t.Fatalf("required roles = %#v, want search:index", authorizer.lastRequiredRoles)
	}
	if eventRepo.enqueueCalls != 1 {
		t.Fatalf("enqueue calls = %d, want 1", eventRepo.enqueueCalls)
	}
}

func TestIndexEventRejectsServiceJWTWithoutRequiredRole(t *testing.T) {
	authorizer := &fakeServiceAuthorizer{err: serviceauth.ErrForbiddenService}
	handler := NewHandler(
		app.NewSearchUseCase(&fakeSearchRepository{}),
		WithDocumentEvents(app.NewDocumentEventUseCase(&fakeDocumentEventRepository{}, app.NewIndexingUseCase(&fakeIndexRepository{}))),
		WithServiceAuthorizer(authorizer),
	)
	mux := http.NewServeMux()
	handler.Register(mux)

	req := httptest.NewRequest(
		http.MethodPost,
		"/v1/search/index/events",
		strings.NewReader(`{"sourceService":"place-service","sourceEventId":"event-1","aggregateType":"place","aggregateId":"place-1","eventType":"search_document_upsert","payload":{}}`),
	)
	req.Header.Set("Authorization", "Bearer service-jwt")
	rec := httptest.NewRecorder()

	mux.ServeHTTP(rec, req)

	if rec.Code != http.StatusForbidden {
		t.Fatalf("status = %d, want %d: %s", rec.Code, http.StatusForbidden, rec.Body.String())
	}
}

type fakeSearchRepository struct {
	mu            sync.Mutex
	lastQuery     app.SearchQuery
	queries       []app.SearchQuery
	page          app.SearchPage
	pagesByDomain map[model.Domain]app.SearchPage
}

type fakeServiceAuthorizer struct {
	err               error
	lastAuthHeader    string
	lastRequiredRoles []string
}

func (a *fakeServiceAuthorizer) ValidateBearer(
	_ context.Context,
	authHeader string,
	requiredRoles []string,
) (*serviceauth.Claims, error) {
	a.lastAuthHeader = authHeader
	a.lastRequiredRoles = append([]string(nil), requiredRoles...)
	if a.err != nil {
		return nil, a.err
	}
	return &serviceauth.Claims{Subject: "activity-service", Type: "service", Roles: requiredRoles}, nil
}

func (r *fakeSearchRepository) Search(_ context.Context, query app.SearchQuery) (app.SearchPage, error) {
	r.mu.Lock()
	r.lastQuery = query
	r.queries = append(r.queries, query)
	r.mu.Unlock()

	if len(query.Domains) == 1 && r.pagesByDomain != nil {
		if page, ok := r.pagesByDomain[query.Domains[0]]; ok {
			return page, nil
		}
	}
	return r.page, nil
}

func (r *fakeSearchRepository) recordedQueries() []app.SearchQuery {
	r.mu.Lock()
	defer r.mu.Unlock()
	return append([]app.SearchQuery(nil), r.queries...)
}

type fakeIndexRepository struct {
	upsertCalls        int
	deleteCalls        int
	lastDocument       model.SearchDocument
	lastDeleteDomain   model.Domain
	lastDeleteEntityID string
	lastDeleteLocale   string
}

func (r *fakeIndexRepository) UpsertDocument(_ context.Context, document model.SearchDocument) error {
	r.upsertCalls++
	r.lastDocument = document
	return nil
}

func (r *fakeIndexRepository) DeleteDocument(_ context.Context, domain model.Domain, entityID string, locale string) error {
	r.deleteCalls++
	r.lastDeleteDomain = domain
	r.lastDeleteEntityID = entityID
	r.lastDeleteLocale = locale
	return nil
}

type fakeDocumentEventRepository struct {
	enqueueCalls  int
	enqueuedEvent model.SearchDocumentEvent
}

func (r *fakeDocumentEventRepository) EnqueueDocumentEvent(_ context.Context, event model.SearchDocumentEvent) error {
	r.enqueueCalls++
	r.enqueuedEvent = event
	return nil
}

func (r *fakeDocumentEventRepository) ListDueDocumentEvents(context.Context, int, time.Time) ([]model.SearchDocumentEvent, error) {
	return nil, nil
}

func (r *fakeDocumentEventRepository) MarkDocumentEventDelivered(context.Context, string, time.Time) error {
	return nil
}

func (r *fakeDocumentEventRepository) MarkDocumentEventRetry(context.Context, string, string, time.Time) error {
	return nil
}

func (r *fakeDocumentEventRepository) MarkDocumentEventDead(context.Context, string, string, time.Time) error {
	return nil
}

type fakeSearchEventRepository struct {
	calls     int
	lastEvent model.SearchEvent
}

func (r *fakeSearchEventRepository) RecordSearchEvent(_ context.Context, event model.SearchEvent) error {
	r.calls++
	r.lastEvent = event
	return nil
}
