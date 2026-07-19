package http

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/saved-service/internal/app/savedcollection"
	"kz/inflap/backend/services/saved-service/internal/domain"
)

func TestSavedCollectionHandlerListsOwnerCollectionsWithResolvedFirstItemCover(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, time.July, 16, 12, 0, 0, 0, time.UTC)
	target, err := domain.NewSavedTarget(domain.EntityTypeActivity, "99999999-9999-4999-8999-999999999999")
	if err != nil {
		t.Fatal(err)
	}
	title := "Public activity"
	imageURL := "https://api.example.test/v1/activities/99999999-9999-4999-8999-999999999999/saved-media?saved_revision=7"
	reader := &stubSavedCollectionReader{collections: []savedcollection.Collection{{
		ID:               uuid.MustParse("44444444-4444-4444-8444-444444444444"),
		Title:            "Almaty",
		LifecycleState:   savedcollection.CollectionLifecycleActive,
		MetadataVersion:  2,
		LifecycleVersion: 1,
		ActiveItemCount:  1,
		Cover: savedcollection.CoverPreview{
			Kind:             savedcollection.CoverKindItem,
			Target:           &target,
			Title:            &title,
			ResolvedImageURL: &imageURL,
		},
		OrganizedAt: now,
		CreatedAt:   now.Add(-time.Hour),
		UpdatedAt:   now,
	}}}
	mux := newSavedCollectionTestMux(t, reader, &stubSavedCollectionMutator{}, now)
	request := savedCollectionRequest(t, http.MethodGet, "/v1/users/me/saved-collections", "")
	recorder := httptest.NewRecorder()
	mux.ServeHTTP(recorder, request)

	if recorder.Code != http.StatusOK || reader.listQuery.OwnerUserID.String() != "22222222-2222-4222-8222-222222222222" {
		t.Fatalf("status=%d query=%#v body=%s", recorder.Code, reader.listQuery, recorder.Body.String())
	}
	var response map[string]any
	if err := json.NewDecoder(recorder.Body).Decode(&response); err != nil {
		t.Fatal(err)
	}
	collections := response["collections"].([]any)
	cover := collections[0].(map[string]any)["cover_preview"].(map[string]any)
	if cover["kind"] != "ITEM" || cover["image_url"] != imageURL || strings.Contains(recorder.Body.String(), "opaque") {
		t.Fatalf("unexpected cover response: %s", recorder.Body.String())
	}
}

func TestSavedCollectionHandlerReturnsTypedTargetSnapshot(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, time.July, 16, 12, 0, 0, 0, time.UTC)
	target, _ := domain.NewSavedTarget(domain.EntityTypeActivity, "99999999-9999-4999-8999-999999999999")
	reader := &stubSavedCollectionReader{targetSnapshot: savedcollection.TargetCollectionsSnapshot{
		Target: target,
		Relationship: savedcollection.RelationshipSnapshot{
			State:      savedcollection.RelationshipSnapshotActive,
			Generation: uuid.MustParse("55555555-5555-4555-8555-555555555555"),
			Version:    7,
		},
		DependentMembershipVersion: 9,
		EffectiveCollectionIDs: []uuid.UUID{
			uuid.MustParse("44444444-4444-4444-8444-444444444444"),
		},
		CollectionOptions: []savedcollection.CollectionOption{{
			ID:               uuid.MustParse("44444444-4444-4444-8444-444444444444"),
			Title:            "Almaty",
			MetadataVersion:  2,
			LifecycleVersion: 1,
		}},
		RecordedAt: now,
	}}
	mux := newSavedCollectionTestMux(t, reader, &stubSavedCollectionMutator{}, now)
	request := savedCollectionRequest(
		t,
		http.MethodGet,
		"/v1/users/me/saved-items/ACTIVITY/99999999-9999-4999-8999-999999999999/collections",
		"",
	)
	recorder := httptest.NewRecorder()
	mux.ServeHTTP(recorder, request)

	if recorder.Code != http.StatusOK {
		t.Fatalf("status=%d body=%s", recorder.Code, recorder.Body.String())
	}
	var response targetCollectionsSnapshotResponse
	if err := json.NewDecoder(recorder.Body).Decode(&response); err != nil {
		t.Fatal(err)
	}
	if response.SnapshotVersion != 9 || response.Relationship.Generation == nil ||
		response.DependentMembershipVersion != 9 || len(response.CollectionOptions) != 1 {
		t.Fatalf("response=%#v", response)
	}
}

func TestSavedCollectionHandlerCreatesCollectionFromTrustedPrincipal(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, time.July, 16, 12, 0, 0, 0, time.UTC)
	receipt := newHTTPTestOperation(t, now, domain.OperationKindCreateCollection)
	mutator := &stubSavedCollectionMutator{createReceipt: receipt}
	mux := newSavedCollectionTestMux(t, &stubSavedCollectionReader{}, mutator, now)
	request := savedCollectionRequest(
		t,
		http.MethodPost,
		"/v1/users/me/saved-collections",
		`{"client_creation_id":"66666666-6666-4666-8666-666666666666","title":"Summer trip"}`,
	)
	recorder := httptest.NewRecorder()
	mux.ServeHTTP(recorder, request)

	if recorder.Code != http.StatusAccepted || mutator.createCalls != 1 ||
		mutator.createRequest.Identity.OwnerUserID.String() != "22222222-2222-4222-8222-222222222222" ||
		mutator.createRequest.Identity.SourceSurface != domain.SourceSurfaceSavedAll ||
		mutator.createRequest.Title != "Summer trip" {
		t.Fatalf("status=%d request=%#v body=%s", recorder.Code, mutator.createRequest, recorder.Body.String())
	}
}

func TestSavedCollectionHandlerParsesAtomicInlineDesiredSet(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, time.July, 16, 12, 0, 0, 0, time.UTC)
	receipt := newHTTPTestOperation(t, now, domain.OperationKindSetTargetCollections)
	mutator := &stubSavedCollectionMutator{replaceReceipt: receipt}
	mux := newSavedCollectionTestMux(t, &stubSavedCollectionReader{}, mutator, now)
	body := `{
		"expected_relationship":{"state":"EXPECTED_ACTIVE","generation":"55555555-5555-4555-8555-555555555555","version":7},
		"expected_dependent_membership_version":9,
		"desired_collection_ids":["44444444-4444-4444-8444-444444444444"],
		"new_collection":{"client_creation_id":"66666666-6666-4666-8666-666666666666","title":"Summer trip"}
	}`
	request := savedCollectionRequest(
		t,
		http.MethodPut,
		"/v1/users/me/saved-items/ACTIVITY/99999999-9999-4999-8999-999999999999/collections",
		body,
	)
	recorder := httptest.NewRecorder()
	mux.ServeHTTP(recorder, request)

	if recorder.Code != http.StatusAccepted || mutator.replaceCalls != 1 ||
		mutator.replaceRequest.Desired.ExpectedRelationship.Version != 7 ||
		mutator.replaceRequest.Desired.NewCollection == nil ||
		mutator.replaceRequest.Desired.NewCollection.Title != "Summer trip" {
		t.Fatalf("status=%d request=%#v body=%s", recorder.Code, mutator.replaceRequest, recorder.Body.String())
	}
}

func TestSavedCollectionHandlerRejectsUnknownOrDuplicateDesiredSetInput(t *testing.T) {
	t.Parallel()

	mutator := &stubSavedCollectionMutator{}
	mux := newSavedCollectionTestMux(t, &stubSavedCollectionReader{}, mutator, time.Now().UTC())
	bodies := []string{
		`{"expected_relationship":{"state":"EXPECTED_ABSENT","generation":"55555555-5555-4555-8555-555555555555"},"expected_dependent_membership_version":0,"desired_collection_ids":[]}`,
		`{"expected_relationship":{"state":"EXPECTED_ABSENT"},"expected_dependent_membership_version":0,"desired_collection_ids":["44444444-4444-4444-8444-444444444444","44444444-4444-4444-8444-444444444444"]}`,
		`{"expected_relationship":{"state":"EXPECTED_ABSENT","future":true},"expected_dependent_membership_version":0,"desired_collection_ids":[]}`,
	}
	for _, body := range bodies {
		request := savedCollectionRequest(
			t,
			http.MethodPut,
			"/v1/users/me/saved-items/ACTIVITY/99999999-9999-4999-8999-999999999999/collections",
			body,
		)
		recorder := httptest.NewRecorder()
		mux.ServeHTTP(recorder, request)
		if recorder.Code != http.StatusBadRequest {
			t.Errorf("status=%d body=%s", recorder.Code, recorder.Body.String())
		}
	}
	if mutator.replaceCalls != 0 {
		t.Fatalf("replace calls=%d", mutator.replaceCalls)
	}
}

func newSavedCollectionTestMux(
	t *testing.T,
	reader SavedCollectionReadUseCase,
	mutator SavedCollectionMutationUseCase,
	now time.Time,
) *http.ServeMux {
	t.Helper()
	handler, err := NewSavedCollectionHandler(reader, mutator, fixedResponseClock{now: now})
	if err != nil {
		t.Fatalf("NewSavedCollectionHandler() error=%v", err)
	}
	mux := http.NewServeMux()
	if err := handler.Register(mux); err != nil {
		t.Fatalf("Register() error=%v", err)
	}
	return mux
}

func savedCollectionRequest(t *testing.T, method, path, body string) *http.Request {
	t.Helper()
	var reader *strings.Reader
	if body == "" {
		reader = strings.NewReader("")
	} else {
		reader = strings.NewReader(body)
	}
	request := httptest.NewRequest(method, path, reader)
	request = request.WithContext(personalResponseTestRequest().Context())
	request.Header.Set(HeaderOperationID, "33333333-3333-4333-8333-333333333333")
	request.Header.Set(HeaderIdempotencyKey, "0123456789abcdefghijklmnopqrstuv")
	request.Header.Set(HeaderSourceSurface, string(domain.SourceSurfaceSavedAll))
	request.Header.Set("Accept-Language", "ru")
	return request
}

type stubSavedCollectionReader struct {
	collections    []savedcollection.Collection
	collection     savedcollection.Collection
	targetSnapshot savedcollection.TargetCollectionsSnapshot
	err            error
	listQuery      savedcollection.ListQuery
}

func (stub *stubSavedCollectionReader) List(_ context.Context, query savedcollection.ListQuery) ([]savedcollection.Collection, error) {
	stub.listQuery = query
	return stub.collections, stub.err
}

func (stub *stubSavedCollectionReader) Get(context.Context, savedcollection.GetQuery) (savedcollection.Collection, error) {
	return stub.collection, stub.err
}

func (stub *stubSavedCollectionReader) TargetCollections(context.Context, savedcollection.TargetSnapshotQuery) (savedcollection.TargetCollectionsSnapshot, error) {
	return stub.targetSnapshot, stub.err
}

type stubSavedCollectionMutator struct {
	createReceipt  *domain.SavedOperation
	renameReceipt  *domain.SavedOperation
	deleteReceipt  *domain.SavedOperation
	replaceReceipt *domain.SavedOperation
	err            error
	createRequest  savedcollection.CreateRequest
	replaceRequest savedcollection.ReplaceDesiredSetRequest
	createCalls    int
	replaceCalls   int
}

func (stub *stubSavedCollectionMutator) Create(_ context.Context, request savedcollection.CreateRequest) (*domain.SavedOperation, error) {
	stub.createCalls++
	stub.createRequest = request
	return stub.createReceipt, stub.err
}

func (stub *stubSavedCollectionMutator) Rename(context.Context, savedcollection.RenameRequest) (*domain.SavedOperation, error) {
	return stub.renameReceipt, stub.err
}

func (stub *stubSavedCollectionMutator) Delete(context.Context, savedcollection.DeleteRequest) (*domain.SavedOperation, error) {
	return stub.deleteReceipt, stub.err
}

func (stub *stubSavedCollectionMutator) ReplaceDesiredSet(_ context.Context, request savedcollection.ReplaceDesiredSetRequest) (*domain.SavedOperation, error) {
	stub.replaceCalls++
	stub.replaceRequest = request
	return stub.replaceReceipt, stub.err
}

var _ SavedCollectionReadUseCase = (*stubSavedCollectionReader)(nil)
var _ SavedCollectionMutationUseCase = (*stubSavedCollectionMutator)(nil)
