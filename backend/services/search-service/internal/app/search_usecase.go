package app

import (
	"context"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"sort"
	"strings"
	"sync"
	"time"

	"kz/inflap/backend/services/search-service/internal/domain/model"
)

var ErrInvalidSearchPageToken = errors.New("invalid search page token")

const (
	defaultSearchLimit             = 20
	maxSearchLimit                 = 100
	defaultSearchGroupLimit        = 5
	maxSearchGroupLimit            = 20
	minSearchCandidateLimit        = 100
	maxSearchCandidateLimit        = 1000
	searchCandidateLimitMultiplier = 5
)

type SearchRepository interface {
	Search(ctx context.Context, query SearchQuery) (SearchPage, error)
}

type SearchCache interface {
	GetSearchPage(ctx context.Context, key string) (SearchPage, bool, error)
	SetSearchPage(ctx context.Context, key string, page SearchPage, ttl time.Duration) error
}

type SearchUseCaseOption func(*SearchUseCase)

type SearchUseCase struct {
	repo     SearchRepository
	cache    SearchCache
	cacheTTL time.Duration
}

func NewSearchUseCase(repo SearchRepository, opts ...SearchUseCaseOption) *SearchUseCase {
	useCase := &SearchUseCase{repo: repo}
	for _, opt := range opts {
		opt(useCase)
	}
	return useCase
}

func WithSearchCache(cache SearchCache, ttl time.Duration) SearchUseCaseOption {
	return func(u *SearchUseCase) {
		if cache == nil || ttl <= 0 {
			return
		}
		u.cache = cache
		u.cacheTTL = ttl
	}
}

type SearchInput struct {
	Scope     string
	Domains   []string
	Query     string
	Locale    string
	Latitude  *float64
	Longitude *float64
	Limit     int
	PageToken string
}

type SearchQuery struct {
	Scope          model.Scope
	Domains        []model.Domain
	Query          string
	Locale         string
	Latitude       *float64
	Longitude      *float64
	Limit          int
	PageToken      string
	Offset         int
	CandidateLimit int
}

type SearchPage struct {
	Items         []model.SearchResult
	NextPageToken string
}

type GroupedSearchPage struct {
	TopResults SearchPage
	Groups     map[model.Domain]SearchPage
}

func (u *SearchUseCase) Search(ctx context.Context, input SearchInput) (SearchPage, error) {
	scope, domains, err := resolveSearchTargets(input)
	if err != nil {
		return SearchPage{}, err
	}

	limit := normalizeSearchLimit(input.Limit, defaultSearchLimit, maxSearchLimit)

	offset, err := decodeSearchPageToken(input.PageToken)
	if err != nil {
		return SearchPage{}, err
	}

	query := SearchQuery{
		Scope:          scope,
		Domains:        domains,
		Query:          normalizeSearchText(input.Query),
		Locale:         normalizeLocale(input.Locale),
		Latitude:       input.Latitude,
		Longitude:      input.Longitude,
		Limit:          limit,
		PageToken:      strings.TrimSpace(input.PageToken),
		Offset:         offset,
		CandidateLimit: searchCandidateLimit(limit, offset),
	}

	cacheKey := searchCacheKey(query)
	if u.cache != nil && u.cacheTTL > 0 {
		if page, ok, cacheErr := u.cache.GetSearchPage(ctx, cacheKey); cacheErr == nil && ok {
			return page, nil
		}
	}

	page, err := u.repo.Search(ctx, query)
	if err != nil {
		return SearchPage{}, err
	}
	if u.cache != nil && u.cacheTTL > 0 {
		_ = u.cache.SetSearchPage(ctx, cacheKey, page, u.cacheTTL)
	}
	return page, nil
}

func (u *SearchUseCase) SearchGrouped(ctx context.Context, input SearchInput, groupLimit int) (GroupedSearchPage, error) {
	_, domains, err := resolveSearchTargets(input)
	if err != nil {
		return GroupedSearchPage{}, err
	}

	groupLimit = normalizeSearchLimit(groupLimit, defaultSearchGroupLimit, maxSearchGroupLimit)
	groups := make(map[model.Domain]SearchPage, len(domains))
	pageTokenAppliesToGroup := len(domains) == 1

	type groupedSearchResult struct {
		domain model.Domain
		page   SearchPage
		top    bool
		err    error
	}

	results := make(chan groupedSearchResult, len(domains)+1)
	var wg sync.WaitGroup

	wg.Add(1)
	go func() {
		defer wg.Done()
		page, searchErr := u.Search(ctx, input)
		results <- groupedSearchResult{page: page, top: true, err: searchErr}
	}()

	for _, domain := range domains {
		domain := domain
		groupInput := input
		groupInput.Domains = []string{string(domain)}
		groupInput.Limit = groupLimit
		if !pageTokenAppliesToGroup {
			groupInput.PageToken = ""
		}

		wg.Add(1)
		go func() {
			defer wg.Done()
			page, searchErr := u.Search(ctx, groupInput)
			results <- groupedSearchResult{domain: domain, page: page, err: searchErr}
		}()
	}

	go func() {
		wg.Wait()
		close(results)
	}()

	var topPage SearchPage
	var firstErr error
	for result := range results {
		if result.err != nil && firstErr == nil {
			firstErr = result.err
			continue
		}
		if result.top {
			topPage = result.page
			continue
		}
		groups[result.domain] = result.page
	}
	if firstErr != nil {
		return GroupedSearchPage{}, firstErr
	}

	return GroupedSearchPage{
		TopResults: topPage,
		Groups:     groups,
	}, nil
}

func normalizeSearchLimit(limit int, defaultLimit int, maxLimit int) int {
	if limit <= 0 {
		return defaultLimit
	}
	if limit > maxLimit {
		return maxLimit
	}
	return limit
}

func searchCandidateLimit(limit int, offset int) int {
	if limit <= 0 {
		limit = defaultSearchLimit
	}
	if offset < 0 {
		offset = 0
	}
	candidateLimit := (offset + limit + 1) * searchCandidateLimitMultiplier
	if candidateLimit < minSearchCandidateLimit {
		return minSearchCandidateLimit
	}
	if candidateLimit > maxSearchCandidateLimit {
		return maxSearchCandidateLimit
	}
	return candidateLimit
}

func searchCacheKey(query SearchQuery) string {
	domains := make([]string, 0, len(query.Domains))
	for _, domain := range query.Domains {
		domains = append(domains, string(domain))
	}
	sort.Strings(domains)

	lat := ""
	if query.Latitude != nil {
		lat = fmt.Sprintf("%.4f", *query.Latitude)
	}
	lng := ""
	if query.Longitude != nil {
		lng = fmt.Sprintf("%.4f", *query.Longitude)
	}

	payload := strings.Join([]string{
		string(query.Scope),
		strings.Join(domains, ","),
		query.Query,
		query.Locale,
		lat,
		lng,
		fmt.Sprintf("%d", query.Limit),
		fmt.Sprintf("%d", query.Offset),
	}, "\x00")
	sum := sha256.Sum256([]byte(payload))
	return hex.EncodeToString(sum[:])
}

func resolveSearchTargets(input SearchInput) (model.Scope, []model.Domain, error) {
	scope, err := model.ParseScope(input.Scope)
	if err != nil {
		return "", nil, err
	}

	requestedDomains, err := parseDomains(input.Domains)
	if err != nil {
		return "", nil, err
	}

	domains, err := model.DomainsForScope(scope, requestedDomains)
	if err != nil {
		return "", nil, err
	}
	return scope, domains, nil
}

func parseDomains(rawDomains []string) ([]model.Domain, error) {
	if len(rawDomains) == 0 {
		return nil, nil
	}

	result := make([]model.Domain, 0, len(rawDomains))
	for _, raw := range rawDomains {
		raw = strings.TrimSpace(raw)
		if raw == "" {
			continue
		}
		parts := strings.Split(raw, ",")
		for _, part := range parts {
			domain, err := model.ParseDomain(part)
			if err != nil {
				return nil, err
			}
			result = append(result, domain)
		}
	}
	return result, nil
}

func normalizeLocale(locale string) string {
	locale = strings.ToLower(strings.TrimSpace(locale))
	switch locale {
	case "ru", "kk", "en":
		return locale
	default:
		return "en"
	}
}

type searchPageToken struct {
	Offset int `json:"offset"`
}

func EncodeSearchPageToken(offset int) string {
	if offset <= 0 {
		return ""
	}
	payload, err := json.Marshal(searchPageToken{Offset: offset})
	if err != nil {
		return ""
	}
	return base64.RawURLEncoding.EncodeToString(payload)
}

func decodeSearchPageToken(raw string) (int, error) {
	raw = strings.TrimSpace(raw)
	if raw == "" {
		return 0, nil
	}
	payload, err := base64.RawURLEncoding.DecodeString(raw)
	if err != nil {
		return 0, fmt.Errorf("%w: malformed token", ErrInvalidSearchPageToken)
	}
	var token searchPageToken
	if err = json.Unmarshal(payload, &token); err != nil {
		return 0, fmt.Errorf("%w: malformed payload", ErrInvalidSearchPageToken)
	}
	if token.Offset < 0 {
		return 0, fmt.Errorf("%w: negative offset", ErrInvalidSearchPageToken)
	}
	return token.Offset, nil
}
