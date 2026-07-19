package savedcollection

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/saved-service/internal/domain"
)

type stubCollectionReadRepository struct {
	records      []CollectionRecord
	targetResult TargetCollectionsSnapshot
	err          error
	calls        int
	targetCalls  int
}

func (stub *stubCollectionReadRepository) ListCollectionRecords(context.Context, ListQuery) ([]CollectionRecord, error) {
	stub.calls++
	return stub.records, stub.err
}

func (stub *stubCollectionReadRepository) GetCollectionRecord(context.Context, GetQuery) (CollectionRecord, error) {
	stub.calls++
	if stub.err != nil {
		return CollectionRecord{}, stub.err
	}
	if len(stub.records) == 0 {
		return CollectionRecord{}, ErrDataInvariant
	}
	return stub.records[0], nil
}

func (stub *stubCollectionReadRepository) GetTargetCollections(context.Context, TargetSnapshotQuery) (TargetCollectionsSnapshot, error) {
	stub.targetCalls++
	return stub.targetResult, stub.err
}

type stubThumbnailResolver struct {
	resolved map[uuid.UUID]string
	err      error
	requests []ThumbnailRequest
}

func (stub *stubThumbnailResolver) ResolveCollectionThumbnails(
	_ context.Context,
	requests []ThumbnailRequest,
) (map[uuid.UUID]string, error) {
	stub.requests = append([]ThumbnailRequest(nil), requests...)
	return stub.resolved, stub.err
}

func TestReadServiceResolvesOnlyExplicitHTTPResult(t *testing.T) {
	now := time.Now().UTC()
	owner := uuid.New()
	collectionID := uuid.New()
	target, err := domain.NewSavedTarget(domain.EntityTypeGuide, uuid.NewString())
	if err != nil {
		t.Fatal(err)
	}
	record := CollectionRecord{
		OwnerUserID: owner,
		Collection:  validTestCollection(collectionID, "Guides", now),
		CoverCandidate: &CoverCandidate{
			CollectionID:          collectionID,
			Target:                target,
			Title:                 "A guide",
			OpaqueReference:       "opaque:not-a-url",
			ReferenceRevision:     3,
			VisibilityValidatedAt: now,
			ValidUntil:            now.Add(time.Minute),
		},
	}
	resolver := &stubThumbnailResolver{resolved: map[uuid.UUID]string{
		collectionID: "https://media.example.test/cover.jpg",
	}}
	repository := &stubCollectionReadRepository{records: []CollectionRecord{record}}
	service, err := NewReadService(repository, resolver)
	if err != nil {
		t.Fatal(err)
	}
	query := validListQuery(owner, now)
	collections, err := service.List(context.Background(), query)
	if err != nil {
		t.Fatalf("List() error = %v", err)
	}
	if len(collections) != 1 || collections[0].Cover.Kind != CoverKindItem ||
		collections[0].Cover.ResolvedImageURL == nil ||
		*collections[0].Cover.ResolvedImageURL != resolver.resolved[collectionID] {
		t.Fatalf("resolved collection = %+v", collections)
	}
	if len(resolver.requests) != 1 || resolver.requests[0].OpaqueReference != "opaque:not-a-url" {
		t.Fatalf("resolver requests = %+v", resolver.requests)
	}

	resolver.resolved[collectionID] = "http://localhost:8080/api/v1/places/cover"
	collections, err = service.List(context.Background(), query)
	if err != nil {
		t.Fatal(err)
	}
	if collections[0].Cover.Kind != CoverKindItem || collections[0].Cover.ResolvedImageURL == nil {
		t.Fatalf("development HTTP cover = %+v", collections[0].Cover)
	}

	resolver.resolved[collectionID] = "opaque:not-a-public-url"
	collections, err = service.List(context.Background(), query)
	if err != nil {
		t.Fatal(err)
	}
	if collections[0].Cover.Kind != CoverKindGeneric {
		t.Fatalf("opaque resolver result cover = %+v", collections[0].Cover)
	}
}

func TestReadServiceUsesGenericCoverForBlockedUser(t *testing.T) {
	t.Parallel()

	now := time.Now().UTC()
	ownerUserID := uuid.New()
	blockedUserID := uuid.New()
	collectionID := uuid.New()
	target, err := domain.NewSavedTarget(domain.EntityTypeUser, blockedUserID.String())
	if err != nil {
		t.Fatal(err)
	}
	record := CollectionRecord{
		OwnerUserID: ownerUserID,
		Collection:  validTestCollection(collectionID, "People", now),
		CoverCandidate: &CoverCandidate{
			CollectionID:          collectionID,
			Target:                target,
			Title:                 "Hidden profile name",
			OpaqueReference:       "user-avatar:" + blockedUserID.String() + ":1",
			ReferenceRevision:     1,
			VisibilityValidatedAt: now,
			ValidUntil:            now.Add(time.Minute),
		},
	}
	resolver := &stubThumbnailResolver{resolved: map[uuid.UUID]string{
		collectionID: "https://media.example.test/blocked-avatar.jpg",
	}}
	service, err := NewReadService(
		&stubCollectionReadRepository{records: []CollectionRecord{record}},
		resolver,
		&stubCollectionUserAccessPolicy{
			denied: map[uuid.UUID]struct{}{blockedUserID: {}},
		},
	)
	if err != nil {
		t.Fatal(err)
	}

	collections, err := service.List(
		context.Background(),
		validListQuery(ownerUserID, now),
	)
	if err != nil || len(collections) != 1 {
		t.Fatalf("List() = (%+v, %v)", collections, err)
	}
	if collections[0].Cover.Kind != CoverKindGeneric ||
		collections[0].Cover.Target != nil || collections[0].Cover.Title != nil ||
		collections[0].Cover.ResolvedImageURL != nil {
		t.Fatalf("blocked USER cover = %+v", collections[0].Cover)
	}
	if len(resolver.requests) != 0 {
		t.Fatalf("blocked cover was sent to resolver: %+v", resolver.requests)
	}
}

func TestReadServiceResolverFailureFallsBackWithoutLeakingCandidate(t *testing.T) {
	now := time.Now().UTC()
	owner := uuid.New()
	collectionID := uuid.New()
	target, _ := domain.NewSavedTarget(domain.EntityTypeActivity, uuid.NewString())
	record := CollectionRecord{
		OwnerUserID: owner,
		Collection:  validTestCollection(collectionID, "Plans", now),
		CoverCandidate: &CoverCandidate{
			CollectionID: collectionID, Target: target, Title: "Private intent",
			OpaqueReference: "opaque:secret", ReferenceRevision: 1,
			VisibilityValidatedAt: now, ValidUntil: now.Add(time.Minute),
		},
	}
	service, err := NewReadService(
		&stubCollectionReadRepository{records: []CollectionRecord{record}},
		&stubThumbnailResolver{err: errors.New("resolver unavailable")},
	)
	if err != nil {
		t.Fatal(err)
	}
	collections, err := service.List(context.Background(), validListQuery(owner, now))
	if err != nil {
		t.Fatal(err)
	}
	if collections[0].Cover.Kind != CoverKindGeneric || collections[0].Cover.Title != nil ||
		collections[0].Cover.ResolvedImageURL != nil {
		t.Fatalf("fallback cover = %+v", collections[0].Cover)
	}
}

func TestReadServiceResolvesCoherentExpiredSourceLease(t *testing.T) {
	now := time.Now().UTC()
	owner := uuid.New()
	collectionID := uuid.New()
	target, _ := domain.NewSavedTarget(domain.EntityTypeAttraction, uuid.NewString())
	record := CollectionRecord{
		OwnerUserID: owner,
		Collection:  validTestCollection(collectionID, "Landmarks", now),
		CoverCandidate: &CoverCandidate{
			CollectionID: collectionID, Target: target, Title: "Landmark",
			OpaqueReference: "opaque:expired-source-lease", ReferenceRevision: 7,
			VisibilityValidatedAt: now.Add(-10 * time.Minute),
			ValidUntil:            now.Add(-time.Minute),
		},
	}
	resolver := &stubThumbnailResolver{resolved: map[uuid.UUID]string{
		collectionID: "https://media.example.test/public/collection-cover/7",
	}}
	service, err := NewReadService(
		&stubCollectionReadRepository{records: []CollectionRecord{record}},
		resolver,
	)
	if err != nil {
		t.Fatal(err)
	}
	collections, err := service.List(context.Background(), validListQuery(owner, now))
	if err != nil {
		t.Fatalf("List(expired source lease) error = %v", err)
	}
	if len(resolver.requests) != 1 || collections[0].Cover.Kind != CoverKindItem ||
		collections[0].Cover.ResolvedImageURL == nil ||
		*collections[0].Cover.ResolvedImageURL == record.CoverCandidate.OpaqueReference {
		t.Fatalf("expired source lease result = %+v requests=%+v", collections, resolver.requests)
	}
}

func TestReadServiceRejectsMalformedAndOutOfOrderRepositoryData(t *testing.T) {
	now := time.Now().UTC()
	owner := uuid.New()
	first := validTestCollection(uuid.New(), "First", now)
	second := validTestCollection(uuid.New(), "Second", now.Add(time.Second))
	repository := &stubCollectionReadRepository{records: []CollectionRecord{
		{OwnerUserID: owner, Collection: first},
		{OwnerUserID: owner, Collection: second},
	}}
	service, err := NewReadService(repository, nil)
	if err != nil {
		t.Fatal(err)
	}
	if _, err := service.List(context.Background(), validListQuery(owner, now.Add(2*time.Second))); !errors.Is(err, ErrDataInvariant) {
		t.Fatalf("out-of-order List() error = %v", err)
	}

	malformed := validTestCollection(uuid.New(), "Malformed", now)
	malformed.MetadataVersion = 0
	repository.records = []CollectionRecord{{OwnerUserID: owner, Collection: malformed}}
	if _, err := service.List(context.Background(), validListQuery(owner, now)); !errors.Is(err, ErrDataInvariant) {
		t.Fatalf("malformed List() error = %v", err)
	}

	target, _ := domain.NewSavedTarget(domain.EntityTypeAttraction, uuid.NewString())
	valid := validTestCollection(uuid.New(), "Candidate", now)
	repository.records = []CollectionRecord{{
		OwnerUserID: owner,
		Collection:  valid,
		CoverCandidate: &CoverCandidate{
			CollectionID: uuid.New(), Target: target, Title: "Wrong owner row",
			OpaqueReference: "opaque:cover", ReferenceRevision: 1,
			VisibilityValidatedAt: now, ValidUntil: now.Add(time.Minute),
		},
	}}
	if _, err := service.List(context.Background(), validListQuery(owner, now)); !errors.Is(err, ErrDataInvariant) {
		t.Fatalf("mismatched candidate List() error = %v", err)
	}

	repository.records = []CollectionRecord{{OwnerUserID: uuid.New(), Collection: valid}}
	if _, err := service.List(context.Background(), validListQuery(owner, now)); !errors.Is(err, ErrDataInvariant) {
		t.Fatalf("foreign owner List() error = %v", err)
	}

	repository.records = []CollectionRecord{{
		OwnerUserID: owner,
		Collection:  valid,
		CoverCandidate: &CoverCandidate{
			CollectionID: valid.ID, Target: target, Title: "Invalid lease",
			OpaqueReference: "opaque:cover", ReferenceRevision: 1,
			VisibilityValidatedAt: now,
			ValidUntil:            now.Add(16 * time.Minute),
		},
	}}
	if _, err := service.List(context.Background(), validListQuery(owner, now)); !errors.Is(err, ErrDataInvariant) {
		t.Fatalf("incoherent media lease List() error = %v", err)
	}

	repository.records = make([]CollectionRecord, int(DefaultMaxActiveCollections)+1)
	if _, err := service.List(context.Background(), validListQuery(owner, now)); !errors.Is(err, ErrDataInvariant) {
		t.Fatalf("oversized repository result List() error = %v", err)
	}
}

func TestReadServiceRejectsNilCanceledContextAndInvalidQueryBeforeRepository(t *testing.T) {
	now := time.Now().UTC()
	repository := &stubCollectionReadRepository{}
	service, err := NewReadService(repository, nil)
	if err != nil {
		t.Fatal(err)
	}
	owner := uuid.New()
	if _, err := service.List(nil, validListQuery(owner, now)); !errors.Is(err, ErrInvalidCommand) {
		t.Fatalf("nil context error = %v", err)
	}
	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	if _, err := service.List(ctx, validListQuery(owner, now)); !errors.Is(err, context.Canceled) {
		t.Fatalf("canceled context error = %v", err)
	}
	if _, err := service.List(context.Background(), ListQuery{}); !errors.Is(err, ErrInvalidCommand) {
		t.Fatalf("invalid query error = %v", err)
	}
	if _, err := service.Get(nil, GetQuery{}); !errors.Is(err, ErrInvalidCommand) {
		t.Fatalf("Get(nil context) error = %v", err)
	}
	getContext, cancelGet := context.WithCancel(context.Background())
	cancelGet()
	if _, err := service.Get(getContext, GetQuery{}); !errors.Is(err, context.Canceled) {
		t.Fatalf("Get(canceled context) error = %v", err)
	}
	if repository.calls != 0 {
		t.Fatalf("repository calls = %d, want 0", repository.calls)
	}
}

func TestReadServiceTargetCollectionsValidatesAndClonesSnapshot(t *testing.T) {
	now := time.Now().UTC()
	owner := uuid.New()
	target, _ := domain.NewSavedTarget(domain.EntityTypeGuide, uuid.NewString())
	collectionID := uuid.New()
	generation := uuid.New()
	repository := &stubCollectionReadRepository{targetResult: TargetCollectionsSnapshot{
		Target: target,
		Relationship: RelationshipSnapshot{
			State: RelationshipSnapshotActive, Generation: generation, Version: 4,
		},
		DependentMembershipVersion: 2,
		EffectiveCollectionIDs:     []uuid.UUID{collectionID},
		CollectionOptions: []CollectionOption{{
			ID: collectionID, Title: "Guides", MetadataVersion: 1, LifecycleVersion: 1,
		}},
		RecordedAt: now,
	}}
	service, err := NewReadService(repository, nil)
	if err != nil {
		t.Fatal(err)
	}
	query := TargetSnapshotQuery{OwnerUserID: owner, Target: target, ReadAt: now}

	snapshot, err := service.TargetCollections(context.Background(), query)
	if err != nil || len(snapshot.EffectiveCollectionIDs) != 1 || repository.targetCalls != 1 {
		t.Fatalf("TargetCollections() = (%+v, %v), calls=%d", snapshot, err, repository.targetCalls)
	}
	repository.targetResult.EffectiveCollectionIDs[0] = uuid.New()
	if snapshot.EffectiveCollectionIDs[0] != collectionID {
		t.Fatal("TargetCollections() returned aliased repository state")
	}

	repository.targetResult = TargetCollectionsSnapshot{
		Target: target, Relationship: RelationshipSnapshot{State: RelationshipSnapshotAbsent},
		EffectiveCollectionIDs: []uuid.UUID{collectionID}, RecordedAt: now,
	}
	if _, err := service.TargetCollections(context.Background(), query); !errors.Is(err, ErrDataInvariant) {
		t.Fatalf("malformed absent snapshot error = %v", err)
	}
}

func validTestCollection(id uuid.UUID, title string, organizedAt time.Time) Collection {
	createdAt := organizedAt.Add(-time.Minute)
	return Collection{
		ID: id, Title: title, LifecycleState: CollectionLifecycleActive,
		MetadataVersion: 1, LifecycleVersion: 1, ActiveItemCount: 0,
		Cover: GenericCover(), CreatedAt: createdAt, OrganizedAt: organizedAt, UpdatedAt: organizedAt,
	}
}

func validListQuery(ownerUserID uuid.UUID, readAt time.Time) ListQuery {
	return ListQuery{OwnerUserID: ownerUserID, Locale: LocaleEN, ReadAt: readAt}
}
