package app

import (
	"context"
	"encoding/base64"
	"errors"
	"strings"
	"sync"
	"testing"
	"time"

	"kz/inflap/backend/services/search-service/internal/domain/model"
)

func TestSearchRejectsOutOfScopeDomainBeforeRepositoryCall(t *testing.T) {
	repo := &fakeSearchRepository{}
	uc := NewSearchUseCase(repo)

	_, err := uc.Search(context.Background(), SearchInput{
		Scope:   "global",
		Domains: []string{"routes"},
		Query:   "almaty",
	})
	if !errors.Is(err, model.ErrUnsupportedDomain) {
		t.Fatalf("Search error = %v, want ErrUnsupportedDomain", err)
	}
	if repo.searchCalls != 0 {
		t.Fatalf("repository calls = %d, want 0", repo.searchCalls)
	}
}

func TestSearchRejectsDomainOutsideEntityScope(t *testing.T) {
	repo := &fakeSearchRepository{}
	uc := NewSearchUseCase(repo)

	_, err := uc.Search(context.Background(), SearchInput{
		Scope:   "activity",
		Domains: []string{"activity", "place"},
		Query:   "hiking",
	})
	if !errors.Is(err, model.ErrScopeDomainMismatch) {
		t.Fatalf("Search error = %v, want ErrScopeDomainMismatch", err)
	}
	if repo.searchCalls != 0 {
		t.Fatalf("repository calls = %d, want 0", repo.searchCalls)
	}
}

func TestSearchDefaultsEntityScopeToItsDomain(t *testing.T) {
	repo := &fakeSearchRepository{}
	uc := NewSearchUseCase(repo)

	_, err := uc.Search(context.Background(), SearchInput{
		Scope: "guide",
		Query: "history",
	})
	if err != nil {
		t.Fatalf("Search returned error: %v", err)
	}
	if repo.searchCalls != 1 {
		t.Fatalf("repository calls = %d, want 1", repo.searchCalls)
	}
	if len(repo.lastQuery.Domains) != 1 || repo.lastQuery.Domains[0] != model.DomainGuide {
		t.Fatalf("domains = %#v, want guide only", repo.lastQuery.Domains)
	}
}

func TestSearchNormalizesQueryWithAliasesBeforeRepositoryCall(t *testing.T) {
	repo := &fakeSearchRepository{}
	uc := NewSearchUseCase(repo)

	_, err := uc.Search(context.Background(), SearchInput{
		Scope: "global",
		Query: "  Álmty  ",
	})
	if err != nil {
		t.Fatalf("Search returned error: %v", err)
	}
	assertQueryContainsTokens(t, repo.lastQuery.Query, "almty", "алматы", "алмата", "almaty", "almata")
}

func TestSearchNormalizesCyrillicQueryWithLatinAliasBeforeRepositoryCall(t *testing.T) {
	repo := &fakeSearchRepository{}
	uc := NewSearchUseCase(repo)

	_, err := uc.Search(context.Background(), SearchInput{
		Scope: "global",
		Query: "чарын",
	})
	if err != nil {
		t.Fatalf("Search returned error: %v", err)
	}
	if !strings.Contains(repo.lastQuery.Query, "charyn") {
		t.Fatalf("query = %q, want latin alias containing charyn", repo.lastQuery.Query)
	}
}

func TestSearchDecodesOpaquePageTokenBeforeRepositoryCall(t *testing.T) {
	repo := &fakeSearchRepository{}
	uc := NewSearchUseCase(repo)
	token := base64.RawURLEncoding.EncodeToString([]byte(`{"offset":25}`))

	_, err := uc.Search(context.Background(), SearchInput{
		Scope:     "global",
		Query:     "almaty",
		PageToken: token,
	})
	if err != nil {
		t.Fatalf("Search returned error: %v", err)
	}
	if repo.lastQuery.Offset != 25 {
		t.Fatalf("offset = %d, want 25", repo.lastQuery.Offset)
	}
}

func TestSearchRejectsInvalidPageTokenBeforeRepositoryCall(t *testing.T) {
	repo := &fakeSearchRepository{}
	uc := NewSearchUseCase(repo)

	_, err := uc.Search(context.Background(), SearchInput{
		Scope:     "global",
		Query:     "almaty",
		PageToken: "not-a-token",
	})
	if !errors.Is(err, ErrInvalidSearchPageToken) {
		t.Fatalf("Search error = %v, want ErrInvalidSearchPageToken", err)
	}
	if repo.searchCalls != 0 {
		t.Fatalf("repository calls = %d, want 0", repo.searchCalls)
	}
}

func TestSearchUsesReadThroughCacheForRepeatedQueries(t *testing.T) {
	repo := &fakeSearchRepository{
		page: SearchPage{
			Items: []model.SearchResult{
				{
					Domain:   model.DomainPlace,
					EntityID: "place-1",
					Title:    "Charyn Canyon",
					DeepLink: "/places/place-1",
					Score:    1,
				},
			},
		},
	}
	cache := newFakeSearchCache()
	uc := NewSearchUseCase(repo, WithSearchCache(cache, time.Minute))

	first, err := uc.Search(context.Background(), SearchInput{
		Scope:  "global",
		Query:  "чарын",
		Locale: "ru",
		Limit:  10,
	})
	if err != nil {
		t.Fatalf("first Search returned error: %v", err)
	}
	second, err := uc.Search(context.Background(), SearchInput{
		Scope:  "global",
		Query:  "чарын",
		Locale: "ru",
		Limit:  10,
	})
	if err != nil {
		t.Fatalf("second Search returned error: %v", err)
	}

	if repo.searchCalls != 1 {
		t.Fatalf("repository calls = %d, want 1", repo.searchCalls)
	}
	if cache.setCalls != 1 {
		t.Fatalf("cache set calls = %d, want 1", cache.setCalls)
	}
	if len(second.Items) != 1 || second.Items[0].EntityID != first.Items[0].EntityID {
		t.Fatalf("second page = %#v, want cached first page", second)
	}
}

func TestSearchContinuesWhenCacheFails(t *testing.T) {
	repo := &fakeSearchRepository{}
	cache := newFakeSearchCache()
	cache.failGet = true
	cache.failSet = true
	uc := NewSearchUseCase(repo, WithSearchCache(cache, time.Minute))

	_, err := uc.Search(context.Background(), SearchInput{
		Scope: "global",
		Query: "almaty",
	})
	if err != nil {
		t.Fatalf("Search returned error: %v", err)
	}
	if repo.searchCalls != 1 {
		t.Fatalf("repository calls = %d, want 1", repo.searchCalls)
	}
}

func TestSearchGroupedFetchesDomainGroupsConcurrently(t *testing.T) {
	repo := &fakeSearchRepository{delay: 50 * time.Millisecond}
	uc := NewSearchUseCase(repo)

	startedAt := time.Now()
	_, err := uc.SearchGrouped(context.Background(), SearchInput{
		Scope: "global",
		Query: "чарын",
		Limit: 5,
	}, 5)
	if err != nil {
		t.Fatalf("SearchGrouped returned error: %v", err)
	}
	elapsed := time.Since(startedAt)

	if elapsed >= 250*time.Millisecond {
		t.Fatalf("SearchGrouped elapsed = %s, want grouped repository calls to run concurrently", elapsed)
	}
	if repo.searchCalls != 7 {
		t.Fatalf("repository calls = %d, want top results + 6 domain groups", repo.searchCalls)
	}
}

type fakeSearchRepository struct {
	mu          sync.Mutex
	searchCalls int
	lastQuery   SearchQuery
	page        SearchPage
	delay       time.Duration
}

func (r *fakeSearchRepository) Search(ctx context.Context, query SearchQuery) (SearchPage, error) {
	if r.delay > 0 {
		select {
		case <-ctx.Done():
			return SearchPage{}, ctx.Err()
		case <-time.After(r.delay):
		}
	}

	r.mu.Lock()
	defer r.mu.Unlock()
	r.searchCalls++
	r.lastQuery = query
	return r.page, nil
}

func assertQueryContainsTokens(t *testing.T, value string, tokens ...string) {
	t.Helper()

	fields := strings.Fields(value)
	seen := make(map[string]struct{}, len(fields))
	for _, field := range fields {
		seen[field] = struct{}{}
	}
	for _, token := range tokens {
		if _, ok := seen[token]; !ok {
			t.Fatalf("query = %q, missing token %q", value, token)
		}
	}
}

type fakeSearchCache struct {
	pages    map[string]SearchPage
	setCalls int
	failGet  bool
	failSet  bool
}

func newFakeSearchCache() *fakeSearchCache {
	return &fakeSearchCache{pages: make(map[string]SearchPage)}
}

func (c *fakeSearchCache) GetSearchPage(_ context.Context, key string) (SearchPage, bool, error) {
	if c.failGet {
		return SearchPage{}, false, errors.New("cache get failed")
	}
	page, ok := c.pages[key]
	return page, ok, nil
}

func (c *fakeSearchCache) SetSearchPage(_ context.Context, key string, page SearchPage, ttl time.Duration) error {
	if c.failSet {
		return errors.New("cache set failed")
	}
	if ttl <= 0 {
		return errors.New("ttl must be positive")
	}
	c.pages[key] = page
	c.setCalls++
	return nil
}
