package savedquery

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/saved-service/internal/domain"
)

type savedQueryRepositoryStub struct {
	statusResult TargetStatus
	statusErr    error
	batchResult  []TargetStatus
	batchErr     error
	pageResult   Page
	pageErr      error
	listQuery    ListQuery
	batchCalls   int
	listCalls    int
}

type savedQueryImageResolverStub struct {
	result   map[uuid.UUID]string
	err      error
	requests []ImageRequest
}

type savedQueryAccessPolicyStub struct {
	denied map[uuid.UUID]struct{}
	err    error
}

func (stub *savedQueryAccessPolicyStub) DeniedUserIDs(
	context.Context,
	uuid.UUID,
	[]uuid.UUID,
) (map[uuid.UUID]struct{}, error) {
	return stub.denied, stub.err
}

func (r *savedQueryImageResolverStub) ResolveItemImages(
	_ context.Context,
	requests []ImageRequest,
) (map[uuid.UUID]string, error) {
	r.requests = append([]ImageRequest(nil), requests...)
	return r.result, r.err
}

func (r *savedQueryRepositoryStub) GetStatus(context.Context, StatusQuery) (TargetStatus, error) {
	return r.statusResult, r.statusErr
}

func (r *savedQueryRepositoryStub) BatchStatus(_ context.Context, _ BatchStatusQuery) ([]TargetStatus, error) {
	r.batchCalls++
	return r.batchResult, r.batchErr
}

func (r *savedQueryRepositoryStub) ListItems(_ context.Context, query ListQuery) (Page, error) {
	r.listCalls++
	r.listQuery = query
	return r.pageResult, r.pageErr
}

func TestServiceBatchStatusPreservesRequestOrder(t *testing.T) {
	owner := uuid.New()
	first := savedQueryTestTarget(t, domain.EntityTypeAttraction)
	second := savedQueryTestTarget(t, domain.EntityTypeGuide)
	repository := &savedQueryRepositoryStub{batchResult: []TargetStatus{
		{
			Target:          first,
			SavedState:      SavedStateConfirmedUnsaved,
			Eligibility:     EligibilityEligible,
			ResourceVersion: 2,
		},
		{
			Target:      second,
			SavedState:  SavedStateUnknown,
			Eligibility: EligibilityUnknown,
		},
	}}
	service, err := newService(repository, time.Now)
	if err != nil {
		t.Fatalf("newService() error = %v", err)
	}

	statuses, err := service.BatchStatus(context.Background(), owner, []domain.SavedTarget{first, second})
	if err != nil || len(statuses) != 2 || statuses[0].Target != first || statuses[1].Target != second {
		t.Fatalf("BatchStatus() = (%+v, %v)", statuses, err)
	}

	repository.batchResult[0].Target = second
	if _, err := service.BatchStatus(context.Background(), owner, []domain.SavedTarget{first, second}); !errors.Is(err, ErrDataInvariant) {
		t.Fatalf("reordered adapter output error = %v, want %v", err, ErrDataInvariant)
	}
}

func TestServiceBlockedUserStatusPreservesManualReduction(t *testing.T) {
	t.Parallel()

	ownerUserID := uuid.New()
	blockedUserID := uuid.New()
	target, err := domain.NewSavedTarget(domain.EntityTypeUser, blockedUserID.String())
	if err != nil {
		t.Fatal(err)
	}
	generation := uuid.New()
	repository := &savedQueryRepositoryStub{batchResult: []TargetStatus{{
		Target:                   target,
		SavedState:               SavedStateSaved,
		Eligibility:              EligibilityEligible,
		EffectiveCollectionCount: 2,
		ResourceVersion:          7,
		RelationshipGeneration:   &generation,
	}}}
	service, err := newService(repository, time.Now)
	if err != nil {
		t.Fatalf("newService() error = %v", err)
	}
	service.accessPolicy = &savedQueryAccessPolicyStub{
		denied: map[uuid.UUID]struct{}{blockedUserID: {}},
	}

	statuses, err := service.BatchStatus(
		context.Background(),
		ownerUserID,
		[]domain.SavedTarget{target},
	)
	if err != nil || len(statuses) != 1 {
		t.Fatalf("BatchStatus() = (%+v, %v)", statuses, err)
	}
	if statuses[0].SavedState != SavedStateSaved ||
		statuses[0].Eligibility != EligibilityReductionOnly ||
		statuses[0].EffectiveCollectionCount != 2 {
		t.Fatalf("blocked status = %+v", statuses[0])
	}
}

func TestServiceRejectsBatchBeforeRepository(t *testing.T) {
	repository := &savedQueryRepositoryStub{}
	service, err := newService(repository, time.Now)
	if err != nil {
		t.Fatalf("newService() error = %v", err)
	}
	target := savedQueryTestTarget(t, domain.EntityTypeActivity)
	_, err = service.BatchStatus(context.Background(), uuid.New(), []domain.SavedTarget{target, target})
	if !errors.Is(err, ErrInvalidQuery) || repository.batchCalls != 0 {
		t.Fatalf("BatchStatus() error/calls = (%v, %d)", err, repository.batchCalls)
	}
}

func TestServiceListNormalizesQueryAndValidatesPage(t *testing.T) {
	fixedNow := time.Date(2026, 7, 16, 10, 0, 0, 0, time.FixedZone("UTC+6", 6*60*60))
	owner := uuid.New()
	target := savedQueryTestTarget(t, domain.EntityTypeAttraction)
	item := validSavedQueryItem(target, fixedNow.UTC().Add(-time.Minute))
	repository := &savedQueryRepositoryStub{pageResult: Page{Items: []Item{item}}}
	service, err := newService(repository, func() time.Time { return fixedNow })
	if err != nil {
		t.Fatalf("newService() error = %v", err)
	}

	page, err := service.ListItems(context.Background(), ListInput{
		OwnerUserID: owner,
		Locale:      LocaleEN,
	})
	if err != nil || len(page.Items) != 1 {
		t.Fatalf("ListItems() = (%+v, %v)", page, err)
	}
	if repository.listQuery.Limit != DefaultPageLimit || !repository.listQuery.ReadAt.Equal(fixedNow.UTC()) {
		t.Fatalf("normalized query = %+v", repository.listQuery)
	}

	repository.pageResult = Page{
		Items:   []Item{item},
		HasMore: true,
		Next:    &Keyset{SavedAt: item.Relationship.SavedAt, ItemID: uuid.New()},
	}
	if _, err := service.ListItems(context.Background(), ListInput{OwnerUserID: owner, Locale: LocaleEN}); !errors.Is(err, ErrDataInvariant) {
		t.Fatalf("wrong next key error = %v, want %v", err, ErrDataInvariant)
	}
}

func TestServiceListRejectsOpaqueTokenAsResolvedImageURL(t *testing.T) {
	now := time.Now().UTC()
	target := savedQueryTestTarget(t, domain.EntityTypeGuide)
	item := validSavedQueryItem(target, now.Add(-time.Minute))
	item.Projection = CardProjection{
		ContentState: ContentStateAvailable,
		Revisions:    SourceRevisions{Source: 1, Projection: 1, Visibility: 1},
		Public: &PublicCardProjection{
			DisplayLocale:        LocaleEN,
			Title:                "Guide",
			CanonicalDetailRoute: "/users/00000000-0000-4000-8000-000000000001/profile",
			SourceUpdatedAt:      now.Add(-time.Minute),
			ResolvedImageURL:     savedQueryStringPointer("guide-avatar:opaque-token"),
		},
	}
	repository := &savedQueryRepositoryStub{pageResult: Page{Items: []Item{item}}}
	service, err := newService(repository, func() time.Time { return now })
	if err != nil {
		t.Fatalf("newService() error = %v", err)
	}
	_, err = service.ListItems(context.Background(), ListInput{OwnerUserID: uuid.New(), Locale: LocaleEN})
	if !errors.Is(err, ErrDataInvariant) {
		t.Fatalf("opaque image token error = %v, want %v", err, ErrDataInvariant)
	}
}

func TestServiceListResolvesAndScrubsOpaqueMediaReference(t *testing.T) {
	now := time.Now().UTC()
	target := savedQueryTestTarget(t, domain.EntityTypeAttraction)
	item := validSavedQueryItem(target, now.Add(-time.Minute))
	item.Projection = CardProjection{
		ContentState: ContentStateAvailable,
		Revisions:    SourceRevisions{Source: 1, Projection: 2, Visibility: 3},
		Public: &PublicCardProjection{
			DisplayLocale: LocaleEN,
			Title:         "Museum",
			MediaReference: &MediaReference{
				OpaqueReference:   "attraction-cover:" + target.EntityID() + ":7",
				ReferenceRevision: 7,
				ValidUntil:        now.Add(-time.Minute),
			},
			CanonicalDetailRoute: "/attractions/" + target.EntityID(),
			SourceUpdatedAt:      now.Add(-time.Hour),
		},
	}
	repository := &savedQueryRepositoryStub{pageResult: Page{Items: []Item{item}}}
	imageURL := "https://api.inflap.example/api/v1/places/" + target.EntityID() + "/saved-cover?saved_revision=7"
	resolver := &savedQueryImageResolverStub{result: map[uuid.UUID]string{item.ItemID: imageURL}}
	service, err := newService(repository, func() time.Time { return now }, resolver)
	if err != nil {
		t.Fatalf("newService() error = %v", err)
	}

	page, err := service.ListItems(context.Background(), ListInput{
		OwnerUserID: uuid.New(),
		Locale:      LocaleEN,
	})
	if err != nil {
		t.Fatalf("ListItems() error = %v", err)
	}
	public := page.Items[0].Projection.Public
	if len(resolver.requests) != 1 || resolver.requests[0].OpaqueReference == "" ||
		public == nil || public.MediaReference != nil || public.ResolvedImageURL == nil ||
		*public.ResolvedImageURL != imageURL {
		t.Fatalf("resolved page/requests = (%+v, %+v)", page, resolver.requests)
	}
}

func TestServiceListScrubsBlockedUserWithoutDroppingSavedRow(t *testing.T) {
	t.Parallel()

	now := time.Now().UTC()
	ownerUserID := uuid.New()
	blockedUserID := uuid.New()
	target, err := domain.NewSavedTarget(domain.EntityTypeUser, blockedUserID.String())
	if err != nil {
		t.Fatal(err)
	}
	item := validSavedQueryItem(target, now.Add(-time.Minute))
	item.Projection = CardProjection{
		ContentState: ContentStateAvailable,
		Revisions:    SourceRevisions{Source: 1, Projection: 2, Visibility: 3},
		Public: &PublicCardProjection{
			DisplayLocale: LocaleEN,
			Title:         "Hidden profile name",
			MediaReference: &MediaReference{
				OpaqueReference:   "user-avatar:" + blockedUserID.String() + ":1",
				ReferenceRevision: 1,
				ValidUntil:        now.Add(time.Minute),
			},
			CanonicalDetailRoute: "/users/" + blockedUserID.String() + "/profile",
			SourceUpdatedAt:      now.Add(-time.Minute),
		},
	}
	repository := &savedQueryRepositoryStub{pageResult: Page{Items: []Item{item}}}
	resolver := &savedQueryImageResolverStub{result: map[uuid.UUID]string{
		item.ItemID: "https://media.example.test/blocked-avatar.jpg",
	}}
	service, err := newService(repository, func() time.Time { return now }, resolver)
	if err != nil {
		t.Fatalf("newService() error = %v", err)
	}
	service.accessPolicy = &savedQueryAccessPolicyStub{
		denied: map[uuid.UUID]struct{}{blockedUserID: {}},
	}

	page, err := service.ListItems(context.Background(), ListInput{
		OwnerUserID: ownerUserID,
		Locale:      LocaleEN,
	})
	if err != nil || len(page.Items) != 1 {
		t.Fatalf("ListItems() = (%+v, %v)", page, err)
	}
	if page.Items[0].Target != target ||
		page.Items[0].Projection.ContentState != ContentStateUnavailable ||
		page.Items[0].Projection.Public != nil {
		t.Fatalf("blocked item = %+v", page.Items[0])
	}
	if len(resolver.requests) != 0 {
		t.Fatalf("blocked avatar was sent to image resolver: %+v", resolver.requests)
	}
	if repository.pageResult.Items[0].Projection.Public == nil {
		t.Fatal("service mutated repository-owned projection")
	}
}

func TestResolveItemImagesRejectsUnknownResolverOutput(t *testing.T) {
	now := time.Now().UTC()
	target := savedQueryTestTarget(t, domain.EntityTypeGuide)
	item := validSavedQueryItem(target, now.Add(-time.Minute))
	item.Projection.Public = &PublicCardProjection{
		MediaReference: &MediaReference{
			OpaqueReference:   "guide-avatar:" + target.EntityID() + ":" + uuid.NewString() + ":1",
			ReferenceRevision: 1,
			ValidUntil:        now,
		},
	}
	resolver := &savedQueryImageResolverStub{result: map[uuid.UUID]string{
		uuid.New(): "https://api.inflap.example/image",
	}}
	if err := ResolveItemImages(context.Background(), resolver, []*Item{&item}); !errors.Is(err, ErrDataInvariant) {
		t.Fatalf("ResolveItemImages() error = %v, want %v", err, ErrDataInvariant)
	}
}

func savedQueryStringPointer(value string) *string {
	return &value
}

func TestServiceHonorsCanceledContext(t *testing.T) {
	repository := &savedQueryRepositoryStub{}
	service, err := newService(repository, time.Now)
	if err != nil {
		t.Fatalf("newService() error = %v", err)
	}
	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	_, err = service.ListItems(ctx, ListInput{OwnerUserID: uuid.New(), Locale: LocaleEN})
	if !errors.Is(err, context.Canceled) || repository.listCalls != 0 {
		t.Fatalf("ListItems() error/calls = (%v, %d)", err, repository.listCalls)
	}
}

func validSavedQueryItem(target domain.SavedTarget, savedAt time.Time) Item {
	return Item{
		ItemID: uuid.New(),
		Target: target,
		Relationship: ActiveRelationship{
			Generation:                 uuid.New(),
			Version:                    1,
			DependentMembershipVersion: 0,
			SavedAt:                    savedAt,
			AttributionID:              uuid.New(),
		},
		Projection: CardProjection{
			ContentState: ContentStateUnavailable,
			Revisions:    SourceRevisions{Source: 1, Projection: 1, Visibility: 1},
		},
	}
}
