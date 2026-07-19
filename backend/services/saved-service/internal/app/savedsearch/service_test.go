package savedsearch

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"

	savedqueryapp "kz/inflap/backend/services/saved-service/internal/app/savedquery"
	"kz/inflap/backend/services/saved-service/internal/domain"
)

type repositoryStub struct {
	page  Page
	err   error
	query Query
	calls int
}

type imageResolverStub struct {
	requests []savedqueryapp.ImageRequest
	resolved map[uuid.UUID]string
	err      error
}

type searchAccessPolicyStub struct {
	denied map[uuid.UUID]struct{}
	err    error
}

func (stub *searchAccessPolicyStub) DeniedUserIDs(
	context.Context,
	uuid.UUID,
	[]uuid.UUID,
) (map[uuid.UUID]struct{}, error) {
	return stub.denied, stub.err
}

func (r *imageResolverStub) ResolveItemImages(
	_ context.Context,
	requests []savedqueryapp.ImageRequest,
) (map[uuid.UUID]string, error) {
	r.requests = append([]savedqueryapp.ImageRequest(nil), requests...)
	return r.resolved, r.err
}

func (r *repositoryStub) Search(_ context.Context, query Query) (Page, error) {
	r.calls++
	r.query = query
	return r.page, r.err
}

func TestServiceNormalizesWithoutPassingRawQuery(t *testing.T) {
	t.Parallel()

	fixedNow := time.Date(2026, 7, 16, 10, 0, 0, 0, time.FixedZone("UTC+6", 6*60*60))
	item := validSearchItem(t, fixedNow.UTC().Add(-time.Minute), MatchRankTitleExact)
	repository := &repositoryStub{page: Page{Items: []Item{item}}}
	service, err := newService(repository, func() time.Time { return fixedNow })
	if err != nil {
		t.Fatalf("newService() error = %v", err)
	}

	page, err := service.Search(context.Background(), Input{
		OwnerUserID: uuid.New(),
		Locale:      savedqueryapp.LocaleEN,
		Search:      "  ＭＵＳＥＵＭ!!! ",
	})
	if err != nil || len(page.Items) != 1 {
		t.Fatalf("normalized service search failed its contract: %v", err)
	}
	if repository.calls != 1 || repository.query.Term.Normalized() != "museum" ||
		repository.query.Limit != DefaultPageLimit || !repository.query.ReadAt.Equal(fixedNow.UTC()) {
		t.Fatalf("repository received an invalid normalized query contract; calls = %d", repository.calls)
	}
	if repository.query.Term.Normalized() == "  ＭＵＳＥＵＭ!!! " {
		t.Fatal("repository received raw query")
	}
}

func TestServiceRejectsInvalidInputBeforeRepository(t *testing.T) {
	t.Parallel()

	repository := &repositoryStub{}
	service, err := newService(repository, time.Now)
	if err != nil {
		t.Fatalf("newService() error = %v", err)
	}
	_, err = service.Search(context.Background(), Input{
		OwnerUserID: uuid.New(),
		Locale:      savedqueryapp.LocaleEN,
		Search:      "---",
	})
	if !errors.Is(err, ErrInvalidQuery) || repository.calls != 0 {
		t.Fatalf("Search() error/calls = (%v, %d)", err, repository.calls)
	}
}

func TestServiceValidatesRankOrderKeysetAndAlternateDisplay(t *testing.T) {
	t.Parallel()

	now := time.Now().UTC().Truncate(time.Microsecond)
	first := validSearchItem(t, now.Add(-2*time.Minute), MatchRankTitleExact)
	second := validSearchItem(t, now.Add(-time.Minute), MatchRankTitleToken)
	repository := &repositoryStub{page: Page{
		Items:   []Item{first, second},
		HasMore: true,
		Next:    keysetPointer(keysetForItem(second)),
	}}
	service, err := newService(repository, func() time.Time { return now })
	if err != nil {
		t.Fatalf("newService() error = %v", err)
	}
	input := Input{OwnerUserID: uuid.New(), Locale: savedqueryapp.LocaleEN, Search: "museum", Limit: 2}
	if _, err := service.Search(context.Background(), input); err != nil {
		t.Fatalf("valid ranked page error = %v", err)
	}

	repository.page.Items[0], repository.page.Items[1] = repository.page.Items[1], repository.page.Items[0]
	repository.page.Next = keysetPointer(keysetForItem(repository.page.Items[1]))
	if _, err := service.Search(context.Background(), input); !errors.Is(err, ErrDataInvariant) {
		t.Fatalf("misordered page error = %v, want %v", err, ErrDataInvariant)
	}

	location := validSearchItem(t, now.Add(-time.Minute), MatchRankLocationExactOrToken)
	location.Match.Field = MatchedFieldCity
	location.Match.Kind = MatchKindExact
	location.Match.AlternatePublicDisplay = nil
	repository.page = Page{Items: []Item{location}}
	if _, err := service.Search(context.Background(), input); !errors.Is(err, ErrDataInvariant) {
		t.Fatalf("missing alternate display error = %v, want %v", err, ErrDataInvariant)
	}
}

func TestServiceHonorsCanceledContext(t *testing.T) {
	t.Parallel()

	repository := &repositoryStub{}
	service, err := newService(repository, time.Now)
	if err != nil {
		t.Fatalf("newService() error = %v", err)
	}
	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	_, err = service.Search(ctx, Input{
		OwnerUserID: uuid.New(), Locale: savedqueryapp.LocaleEN, Search: "museum",
	})
	if !errors.Is(err, context.Canceled) || repository.calls != 0 {
		t.Fatalf("Search() error/calls = (%v, %d)", err, repository.calls)
	}
}

func TestServiceResolvesAndScrubsOpaqueMediaReference(t *testing.T) {
	t.Parallel()

	now := time.Now().UTC().Truncate(time.Microsecond)
	item := validSearchItem(t, now.Add(-time.Minute), MatchRankTitleExact)
	item.Projection.Public.MediaReference = &savedqueryapp.MediaReference{
		OpaqueReference:   "private-media-reference",
		ReferenceRevision: 7,
		ValidUntil:        now.Add(time.Minute),
	}
	repository := &repositoryStub{page: Page{Items: []Item{item}}}
	resolver := &imageResolverStub{resolved: map[uuid.UUID]string{
		item.ItemID: "https://media.example.test/saved/card.jpg",
	}}
	service, err := newService(repository, func() time.Time { return now }, resolver)
	if err != nil {
		t.Fatalf("newService() error = %v", err)
	}

	page, err := service.Search(context.Background(), Input{
		OwnerUserID: uuid.New(), Locale: savedqueryapp.LocaleEN, Search: "museum",
	})
	if err != nil || len(page.Items) != 1 || len(resolver.requests) != 1 {
		t.Fatalf("media resolution failed its bounded contract: %v", err)
	}
	public := page.Items[0].Projection.Public
	if public == nil || public.MediaReference != nil || public.ResolvedImageURL == nil {
		t.Fatal("search page retained internal media state")
	}
	if repository.page.Items[0].Projection.Public.MediaReference == nil {
		t.Fatal("search service mutated repository-owned projection state")
	}
}

func TestServiceKeepsBlockedUserSearchResultAsUnavailablePlaceholder(t *testing.T) {
	t.Parallel()

	now := time.Now().UTC().Truncate(time.Microsecond)
	ownerUserID := uuid.New()
	blockedUserID := uuid.New()
	target, err := domain.NewSavedTarget(domain.EntityTypeUser, blockedUserID.String())
	if err != nil {
		t.Fatal(err)
	}
	item := validSearchItem(t, now.Add(-time.Minute), MatchRankTitleExact)
	item.Target = target
	item.Projection.Public.CanonicalDetailRoute = "/users/" + blockedUserID.String() + "/profile"
	item.Projection.Public.MediaReference = &savedqueryapp.MediaReference{
		OpaqueReference:   "user-avatar:" + blockedUserID.String() + ":1",
		ReferenceRevision: 1,
		ValidUntil:        now.Add(time.Minute),
	}
	repository := &repositoryStub{page: Page{Items: []Item{item}}}
	resolver := &imageResolverStub{resolved: map[uuid.UUID]string{
		item.ItemID: "https://media.example.test/blocked-avatar.jpg",
	}}
	service, err := newService(repository, func() time.Time { return now }, resolver)
	if err != nil {
		t.Fatalf("newService() error = %v", err)
	}
	service.accessPolicy = &searchAccessPolicyStub{
		denied: map[uuid.UUID]struct{}{blockedUserID: {}},
	}

	page, err := service.Search(context.Background(), Input{
		OwnerUserID: ownerUserID,
		Locale:      savedqueryapp.LocaleEN,
		Search:      "museum",
	})
	if err != nil || len(page.Items) != 1 {
		t.Fatalf("Search() = (%+v, %v)", page, err)
	}
	if page.Items[0].Target != target ||
		page.Items[0].Projection.ContentState != savedqueryapp.ContentStateUnavailable ||
		page.Items[0].Projection.Public != nil ||
		page.Items[0].Match.AlternatePublicDisplay != nil {
		t.Fatalf("blocked search item = %+v", page.Items[0])
	}
	if len(resolver.requests) != 0 {
		t.Fatalf("blocked avatar was sent to image resolver: %+v", resolver.requests)
	}
	if repository.page.Items[0].Projection.Public == nil {
		t.Fatal("search service mutated repository-owned projection")
	}
}

func validSearchItem(t testing.TB, savedAt time.Time, rank MatchRank) Item {
	t.Helper()
	target, err := domain.NewSavedTarget(domain.EntityTypeAttraction, uuid.NewString())
	if err != nil {
		t.Fatalf("NewSavedTarget() error = %v", err)
	}
	kind := MatchKindExact
	switch rank {
	case MatchRankTitleToken:
		kind = MatchKindToken
	case MatchRankTitlePrefix:
		kind = MatchKindPrefix
	case MatchRankLocationExactOrToken:
		kind = MatchKindExact
	case MatchRankLocationPrefix:
		kind = MatchKindPrefix
	}
	return Item{
		Item: savedqueryapp.Item{
			ItemID: uuid.New(),
			Target: target,
			Relationship: savedqueryapp.ActiveRelationship{
				Generation:    uuid.New(),
				Version:       1,
				SavedAt:       savedAt,
				AttributionID: uuid.New(),
			},
			Projection: savedqueryapp.CardProjection{
				ContentState: savedqueryapp.ContentStateAvailable,
				Revisions:    savedqueryapp.SourceRevisions{Source: 1, Projection: 1, Visibility: 1},
				Public: &savedqueryapp.PublicCardProjection{
					DisplayLocale:        savedqueryapp.LocaleEN,
					Title:                "Museum",
					CanonicalDetailRoute: "/saved/museum",
					SourceUpdatedAt:      savedAt,
				},
			},
		},
		Match: Match{
			Rank:   rank,
			Kind:   kind,
			Field:  MatchedFieldTitle,
			Locale: savedqueryapp.LocaleEN,
		},
	}
}

func keysetPointer(value Keyset) *Keyset {
	return &value
}
