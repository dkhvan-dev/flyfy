package app

import (
	"context"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"hash/fnv"
	"sort"
	"strconv"
	"strings"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/feed-service/internal/domain/enum"
	"kz/inflap/backend/services/feed-service/internal/domain/model"
)

const (
	defaultFeedLimit               = 20
	maxFeedLimit                   = 30
	feedCursorVersion              = 5
	postsTrayLimit                 = 12
	communityLimit                 = 10
	maxFeedEventBatch              = 50
	maxFeedMetadata                = 20
	defaultFeedInterestLimit       = 50
	maxFeedInterestLimit           = 200
	defaultFeedQualityMetricsLimit = 50
	maxFeedQualityMetricsLimit     = 200
	maxFeedSystemPostsPerPage      = 5
	maxMixedFeedSystemPostsPerPage = 2
	postFeedCacheGlobalScope       = "post-feed:global"
	defaultFeedExperimentKey       = "control"
	feedCandidateMixerPolicy       = "candidate-mixer:v12"
)

type postFeedExpiryMode string

const (
	postFeedExpiryAny        postFeedExpiryMode = "any"
	postFeedExpiryExpiring   postFeedExpiryMode = "expiring"
	postFeedExpiryPersistent postFeedExpiryMode = "persistent"
)

type BuildFeedInput struct {
	Surface     string
	Tab         string
	Cursor      string
	CountryCode string
	CityID      string
	Limit       int
}

type FeedPage struct {
	Items      []FeedBlock
	NextCursor string
	Assignment FeedExperimentAssignment
}

type FeedExperimentAssignment struct {
	RankingExperiment string
}

type feedExperimentVariant struct {
	RankingExperiment string
	Weight            int
}

type FeedBlock struct {
	Type string
	ID   string
	Data any
	Rank int
}

type StoriesTrayFeedData struct {
	Stories []*StoryView
}

type SuggestedCommunitiesFeedData struct {
	Communities []*CommunityView
}

type PostCardFeedData struct {
	Post            *PostView
	CandidateSource string
}

type ConversionFeedData struct {
	Title        string
	Subtitle     string
	ActionLabel  string
	EntityType   string
	EntityID     string
	Route        string
	Source       string
	SemanticTags []string
}

type FeedCuratedBlockPolicy struct {
	MaxConversionBlocksPerPage  int
	MaxOfficialNewsCardsPerPage int
	MaxProfileCardsPerPage      int
}

type FeedDiversityPolicy struct {
	MaxPostsPerCommunityPerPage int
	MaxPostsPerCategoryPerPage  int
	MaxPostsPerAuthorPerPage    int
	MaxPostsPerProfilePerPage   int
	MaxPostsPerTagPerPage       int
}

type feedPostCandidateSource struct {
	Name                       string
	FollowedByUserID           *uuid.UUID
	ExcludeFollowedByUserID    *uuid.UUID
	RandomSeed                 int64
	DisablePersonalizedRanking bool
}

func DefaultFeedCuratedBlockPolicy() FeedCuratedBlockPolicy {
	return FeedCuratedBlockPolicy{
		MaxConversionBlocksPerPage:  2,
		MaxOfficialNewsCardsPerPage: 1,
		MaxProfileCardsPerPage:      1,
	}
}

func DefaultFeedDiversityPolicy() FeedDiversityPolicy {
	return FeedDiversityPolicy{
		MaxPostsPerCommunityPerPage: 2,
		MaxPostsPerCategoryPerPage:  8,
		MaxPostsPerAuthorPerPage:    4,
		MaxPostsPerProfilePerPage:   10,
		MaxPostsPerTagPerPage:       2,
	}
}

func (p FeedCuratedBlockPolicy) Normalized() FeedCuratedBlockPolicy {
	defaults := DefaultFeedCuratedBlockPolicy()
	p.MaxConversionBlocksPerPage = normalizeCuratedBlockCap(p.MaxConversionBlocksPerPage, defaults.MaxConversionBlocksPerPage, 10)
	p.MaxOfficialNewsCardsPerPage = normalizeCuratedBlockCap(p.MaxOfficialNewsCardsPerPage, defaults.MaxOfficialNewsCardsPerPage, 5)
	p.MaxProfileCardsPerPage = normalizeCuratedBlockCap(p.MaxProfileCardsPerPage, defaults.MaxProfileCardsPerPage, 5)
	return p
}

func (p FeedDiversityPolicy) Normalized() FeedDiversityPolicy {
	defaults := DefaultFeedDiversityPolicy()
	p.MaxPostsPerCommunityPerPage = normalizeFeedDiversityCap(p.MaxPostsPerCommunityPerPage, defaults.MaxPostsPerCommunityPerPage, 20)
	p.MaxPostsPerCategoryPerPage = normalizeFeedDiversityCap(p.MaxPostsPerCategoryPerPage, defaults.MaxPostsPerCategoryPerPage, 50)
	p.MaxPostsPerAuthorPerPage = normalizeFeedDiversityCap(p.MaxPostsPerAuthorPerPage, defaults.MaxPostsPerAuthorPerPage, 20)
	p.MaxPostsPerProfilePerPage = normalizeFeedDiversityCap(p.MaxPostsPerProfilePerPage, defaults.MaxPostsPerProfilePerPage, 50)
	p.MaxPostsPerTagPerPage = normalizeFeedDiversityCap(p.MaxPostsPerTagPerPage, defaults.MaxPostsPerTagPerPage, 20)
	return p
}

func feedDiversityPolicyWithOverride(base FeedDiversityPolicy, override *model.FeedRankingPolicyOverride) FeedDiversityPolicy {
	p := base.Normalized()
	if override == nil {
		return p
	}
	if override.MaxPostsPerCommunityPerPage != nil {
		p.MaxPostsPerCommunityPerPage = *override.MaxPostsPerCommunityPerPage
	}
	if override.MaxPostsPerCategoryPerPage != nil {
		p.MaxPostsPerCategoryPerPage = *override.MaxPostsPerCategoryPerPage
	}
	if override.MaxPostsPerAuthorPerPage != nil {
		p.MaxPostsPerAuthorPerPage = *override.MaxPostsPerAuthorPerPage
	}
	if override.MaxPostsPerProfilePerPage != nil {
		p.MaxPostsPerProfilePerPage = *override.MaxPostsPerProfilePerPage
	}
	return p.Normalized()
}

type TrackFeedEventsInput struct {
	Events []FeedEventInput
}

type FeedEventInput struct {
	EventID     uuid.UUID
	EventType   string
	Surface     string
	Tab         string
	BlockID     string
	BlockType   string
	PostID      uuid.UUID
	CommunityID *uuid.UUID
	Rank        int
	OccurredAt  time.Time
	RequestID   string
	Metadata    map[string]any
}

type ListFeedUserInterestsInput struct {
	EntityTypes []string
	Limit       int
}

type ListFeedQualityMetricsInput struct {
	Since   time.Time
	Until   time.Time
	Surface string
	Limit   int
}

type feedCursor struct {
	Version                  int                         `json:"v"`
	Surface                  string                      `json:"surface"`
	Tab                      string                      `json:"tab"`
	CandidatePolicy          string                      `json:"candidatePolicy"`
	RankingExperiment        string                      `json:"rankingExperiment,omitempty"`
	PublishedAt              time.Time                   `json:"publishedAt"`
	PostID                   uuid.UUID                   `json:"postId"`
	Sources                  map[string]feedSourceCursor `json:"sources,omitempty"`
	DeliveredPostIDs         []uuid.UUID                 `json:"deliveredPostIds,omitempty"`
	DeliveredAuthorUserIDs   []uuid.UUID                 `json:"deliveredAuthorUserIds,omitempty"`
	DeliveredCommunityIDs    []uuid.UUID                 `json:"deliveredCommunityIds,omitempty"`
	DeliveredPostProfileKeys []enum.PostProfileKey       `json:"deliveredPostProfileKeys,omitempty"`
	DeliveredCategories      []enum.PostCategory         `json:"deliveredCategories,omitempty"`
	DeliveredTags            []string                    `json:"deliveredTags,omitempty"`
	ColdStartRandomSeed      int64                       `json:"coldStartRandomSeed,omitempty"`
}

type feedSourceCursor struct {
	PublishedAt time.Time `json:"publishedAt"`
	PostID      uuid.UUID `json:"postId"`
}

type feedPostPage struct {
	Posts                   []*PostView
	CandidateSourceByPostID map[uuid.UUID]string
	NextCursor              *feedCursor
}

type feedPostCandidateItem struct {
	SourceName string
	Index      int
	Post       *PostView
}

func (u *PostUseCase) BuildFeed(ctx context.Context, subject string, input BuildFeedInput) (*FeedPage, error) {
	viewerUserID, err := u.optionalUserID(ctx, subject)
	if err != nil {
		return nil, err
	}
	assignment := u.feedExperimentAssignmentForViewer(viewerUserID)
	rankingPolicyOverride := u.feedExperimentPolicyOverride(assignment.RankingExperiment)
	diversityPolicy := feedDiversityPolicyWithOverride(u.feedDiversityPolicy, rankingPolicyOverride)

	surface := normalizeFeedSurface(input.Surface)
	tab := normalizeFeedTab(input.Tab)
	limit := normalizeFeedLimit(input.Limit)
	cursor, err := decodeFeedCursor(input.Cursor, surface, tab, assignment.RankingExperiment)
	if err != nil {
		return nil, err
	}
	isFirstPage := cursor == nil

	blocks := make([]FeedBlock, 0, limit+4)
	rank := 0
	postCardsCursor := cursor

	if viewerUserID != nil && tab != "trending" && feedSurfaceSupportsStoriesTray(surface) && isFirstPage {
		tray, err := u.latestStoryViews(ctx, viewerUserID, postsTrayLimit, 0)
		if err != nil {
			return nil, err
		}
		if len(tray) > 0 {
			blocks = append(blocks, FeedBlock{
				Type: model.FeedBlockTypeStoriesTray,
				ID:   "posts:tray:" + surface,
				Data: StoriesTrayFeedData{Stories: tray},
				Rank: rank,
			})
			rank++
		}
	}

	if isFirstPage && tab == "for_you" {
		communities, err := u.ListCommunities(ctx, subject, ListCommunitiesInput{
			CountryCode:     input.CountryCode,
			CityID:          input.CityID,
			ExcludeFollowed: true,
			Limit:           communityLimit,
		})
		if err != nil {
			return nil, err
		}
		if len(communities) > 0 {
			blocks = append(blocks, FeedBlock{
				Type: model.FeedBlockTypeSuggestedCommunities,
				ID:   "communities:suggested",
				Data: SuggestedCommunitiesFeedData{Communities: communities},
				Rank: rank,
			})
			rank++
		}
	}

	if tab == "following" {
		if viewerUserID == nil || *viewerUserID == uuid.Nil {
			return &FeedPage{Items: blocks, Assignment: assignment}, nil
		}
	}

	candidateSources := feedPostCandidateSources(tab, viewerUserID, input.CountryCode, input.CityID)
	coldStartRandomSeed := int64(0)
	if cursor != nil {
		coldStartRandomSeed = cursor.ColdStartRandomSeed
	}
	if coldStartRandomSeed <= 0 {
		coldStartRandomSeed = feedColdStartRandomSeed(
			viewerUserID,
			input.CountryCode,
			input.CityID,
			surface,
			time.Now().UTC(),
		)
	}
	candidateSources = withColdStartRandomSeed(candidateSources, coldStartRandomSeed)
	postPage, err := u.latestPostPageFromCandidateSources(ctx, viewerUserID, limit, 0, nil, candidateSources, input.CountryCode, input.CityID, postCardsCursor, postFeedExpiryPersistent, rankingPolicyOverride, diversityPolicy)
	if err != nil {
		return nil, err
	}
	posts := postPage.Posts
	for _, post := range posts {
		if post == nil || post.Post == nil {
			continue
		}
		candidateSource := ""
		if postPage.CandidateSourceByPostID != nil {
			candidateSource = postPage.CandidateSourceByPostID[post.Post.ID]
		}
		blocks = append(blocks, FeedBlock{
			Type: model.FeedBlockTypePostCard,
			ID:   "post:" + post.Post.ID.String(),
			Data: PostCardFeedData{
				Post:            post,
				CandidateSource: candidateSource,
			},
			Rank: rank,
		})
		rank++
	}

	nextCursor := ""
	if postPage.NextCursor != nil && len(posts) > 0 {
		nextCursor = encodeFeedCursor(postPage.NextCursor, surface, tab, assignment.RankingExperiment)
	}

	return &FeedPage{Items: blocks, NextCursor: nextCursor, Assignment: assignment}, nil
}

func (u *PostUseCase) TrackFeedEvents(ctx context.Context, subject string, input TrackFeedEventsInput) (int, error) {
	viewerUserID, err := u.optionalUserID(ctx, subject)
	if err != nil {
		return 0, err
	}
	if len(input.Events) == 0 {
		return 0, nil
	}
	if len(input.Events) > maxFeedEventBatch {
		return 0, ErrInvalidFeedEvent
	}

	now := time.Now().UTC()
	events := make([]model.FeedEvent, 0, len(input.Events))
	for _, raw := range input.Events {
		event, err := normalizeFeedEventInput(raw, viewerUserID, now)
		if err != nil {
			return 0, err
		}
		events = append(events, event)
	}

	if err = u.repo.CreateFeedEvents(ctx, events); err != nil {
		return 0, fmt.Errorf("create feed events: %w", err)
	}
	if err = u.trackPostViewsFromFeedEvents(ctx, events); err != nil {
		return 0, fmt.Errorf("track post views from feed events: %w", err)
	}
	if viewerUserID != nil && feedEventsInvalidateViewerFeedCache(events) {
		u.bumpPostFeedCacheScopes(
			ctx,
			postFeedCacheViewerScope(*viewerUserID),
			postFeedCacheFollowingScope(*viewerUserID),
			postFeedCacheDiscoveryScope(*viewerUserID),
		)
	}
	return len(events), nil
}

func (u *PostUseCase) trackPostViewsFromFeedEvents(ctx context.Context, events []model.FeedEvent) error {
	seenPostIDs := make(map[uuid.UUID]struct{})
	for _, event := range events {
		if event.ViewerUserID == nil ||
			event.PostID == nil ||
			event.EventType != model.FeedEventTypeImpression ||
			event.BlockType != model.FeedBlockTypePostCard {
			continue
		}
		postID := *event.PostID
		if postID == uuid.Nil {
			continue
		}
		if _, ok := seenPostIDs[postID]; ok {
			continue
		}
		seenPostIDs[postID] = struct{}{}

		post, err := u.repo.GetPostByID(ctx, postID)
		if err != nil {
			return err
		}
		if post == nil || !post.IsPubliclyVisible() || post.IsOwnedBy(*event.ViewerUserID) {
			continue
		}
		if _, _, err := u.repo.TrackPostView(ctx, postID, *event.ViewerUserID); err != nil {
			return err
		}
	}
	return nil
}

func (u *PostUseCase) ListFeedUserInterests(ctx context.Context, subject string, input ListFeedUserInterestsInput) ([]model.FeedUserInterest, error) {
	viewerUserID, err := u.optionalUserID(ctx, subject)
	if err != nil {
		return nil, err
	}
	if viewerUserID == nil || *viewerUserID == uuid.Nil {
		return []model.FeedUserInterest{}, nil
	}

	interests, err := u.repo.ListFeedUserInterests(ctx, model.FeedUserInterestListFilter{
		ViewerUserID: *viewerUserID,
		EntityTypes:  normalizeFeedInterestEntityTypes(input.EntityTypes),
		Limit:        normalizeFeedInterestLimit(input.Limit),
	})
	if err != nil {
		return nil, fmt.Errorf("list feed user interests: %w", err)
	}
	return interests, nil
}

func (u *PostUseCase) ListFeedQualityMetrics(ctx context.Context, input ListFeedQualityMetricsInput) ([]model.FeedQualityMetric, error) {
	until := input.Until
	if until.IsZero() {
		until = time.Now().UTC()
	} else {
		until = until.UTC()
	}
	since := input.Since
	if since.IsZero() {
		since = until.Add(-7 * 24 * time.Hour)
	} else {
		since = since.UTC()
	}
	if !since.Before(until) {
		return nil, ErrInvalidFeedEvent
	}

	metrics, err := u.repo.ListFeedQualityMetrics(ctx, model.FeedQualityMetricsFilter{
		Since:   since,
		Until:   until,
		Surface: normalizeOptionalFeedSurface(input.Surface),
		Limit:   normalizeFeedQualityMetricsLimit(input.Limit),
	})
	if err != nil {
		return nil, fmt.Errorf("list feed quality metrics: %w", err)
	}
	return metrics, nil
}

func feedPostCandidateSources(tab string, viewerUserID *uuid.UUID, countryCode string, cityID string) []feedPostCandidateSource {
	if tab == "trending" {
		sources := []feedPostCandidateSource{
			{Name: model.PostCandidateSourceSystem, DisablePersonalizedRanking: true},
		}
		hasGeoContext := normalizeCountryCode(countryCode) != "" || normalizeFeedCityID(cityID) != ""
		if hasGeoContext {
			sources = append(sources, feedPostCandidateSource{
				Name:                       model.PostCandidateSourceGeo,
				DisablePersonalizedRanking: true,
			})
		}
		return append(
			sources,
			feedPostCandidateSource{Name: model.PostCandidateSourcePopular, DisablePersonalizedRanking: true},
			feedPostCandidateSource{Name: model.PostCandidateSourceGlobal, DisablePersonalizedRanking: true},
		)
	}
	if tab == "following" {
		if viewerUserID == nil || *viewerUserID == uuid.Nil {
			return nil
		}
		return []feedPostCandidateSource{
			{
				Name:             model.PostCandidateSourceFollowing,
				FollowedByUserID: viewerUserID,
			},
			{
				Name: model.PostCandidateSourceSocial,
			},
		}
	}
	if viewerUserID == nil || *viewerUserID == uuid.Nil {
		hasGeoContext := normalizeCountryCode(countryCode) != "" || normalizeFeedCityID(cityID) != ""
		if hasGeoContext {
			return []feedPostCandidateSource{
				{Name: model.PostCandidateSourceSystem},
				{Name: model.PostCandidateSourceGeo},
				{Name: model.PostCandidateSourceColdStart},
				{Name: model.PostCandidateSourcePopular},
			}
		}
		return []feedPostCandidateSource{
			{Name: model.PostCandidateSourceSystem},
			{Name: model.PostCandidateSourceColdStart},
			{Name: model.PostCandidateSourcePopular},
			{Name: model.PostCandidateSourceGlobal},
		}
	}
	sources := []feedPostCandidateSource{
		{
			Name:             model.PostCandidateSourceFollowed,
			FollowedByUserID: viewerUserID,
		},
		{
			Name: model.PostCandidateSourceSocial,
		},
		{
			Name: model.PostCandidateSourceSystem,
		},
	}
	hasGeoContext := normalizeCountryCode(countryCode) != "" || normalizeFeedCityID(cityID) != ""
	if hasGeoContext {
		sources = append(sources, feedPostCandidateSource{Name: model.PostCandidateSourceGeo})
	}
	sources = append(
		sources,
		feedPostCandidateSource{Name: model.PostCandidateSourceInterest},
		feedPostCandidateSource{Name: model.PostCandidateSourceColdStart},
		feedPostCandidateSource{Name: model.PostCandidateSourcePopular},
	)
	return sources
}

func withColdStartRandomSeed(sources []feedPostCandidateSource, seed int64) []feedPostCandidateSource {
	if seed <= 0 || len(sources) == 0 {
		return sources
	}
	seeded := make([]feedPostCandidateSource, len(sources))
	copy(seeded, sources)
	for idx := range seeded {
		if normalizePostCandidateSource(seeded[idx].Name) == model.PostCandidateSourceColdStart {
			seeded[idx].RandomSeed = seed
		}
	}
	return seeded
}

func feedColdStartRandomSeed(viewerUserID *uuid.UUID, countryCode string, cityID string, surface string, now time.Time) int64 {
	viewer := "guest"
	if viewerUserID != nil && *viewerUserID != uuid.Nil {
		viewer = viewerUserID.String()
	}
	payload := strings.Join([]string{
		viewer,
		normalizeCountryCode(countryCode),
		strings.ToLower(normalizeFeedCityID(cityID)),
		normalizeFeedSurface(surface),
		now.UTC().Format("2006-01-02"),
	}, "|")
	hash := fnv.New64a()
	_, _ = hash.Write([]byte(payload))
	seed := int64(hash.Sum64() & uint64(1<<63-1))
	if seed == 0 {
		return 1
	}
	return seed
}

func (u *PostUseCase) latestPostPageFromCandidateSources(ctx context.Context, viewerUserID *uuid.UUID, limit int, offset int, communityIDs []uuid.UUID, sources []feedPostCandidateSource, countryCode string, cityID string, cursor *feedCursor, expiryMode postFeedExpiryMode, rankingPolicyOverride *model.FeedRankingPolicyOverride, diversityPolicy FeedDiversityPolicy) (feedPostPage, error) {
	if len(sources) == 0 {
		return feedPostPage{Posts: []*PostView{}}, nil
	}
	if len(sources) == 1 || offset != 0 || len(communityIDs) > 0 {
		sourceName := normalizePostCandidateSource(sources[0].Name)
		if sourceName == "" {
			sourceName = model.PostCandidateSourceGlobal
		}
		posts, err := u.latestPostViewsForCandidateSource(ctx, viewerUserID, limit+1, offset, communityIDs, sources[0], countryCode, cityID, cursor, expiryMode, rankingPolicyOverride)
		if err != nil {
			return feedPostPage{}, err
		}
		return feedPostPageFromSingleSource(posts, limit, sourceName, sources[0].RandomSeed), nil
	}

	fetchLimit := feedPostCandidateFetchLimit(limit)
	candidatesBySource := make(map[string][]*PostView, len(sources))
	sourceOrder := make([]string, 0, len(sources))
	for _, source := range sources {
		sourceName := normalizePostCandidateSource(source.Name)
		if sourceName == "" {
			sourceName = model.PostCandidateSourceGlobal
		}
		sourceCursor := feedCursorForCandidateSource(cursor, sourceName)
		sourcePosts, err := u.latestPostViewsForCandidateSource(ctx, viewerUserID, fetchLimit, offset, communityIDs, source, countryCode, cityID, sourceCursor, expiryMode, rankingPolicyOverride)
		if err != nil {
			return feedPostPage{}, err
		}
		if _, exists := candidatesBySource[sourceName]; !exists {
			sourceOrder = append(sourceOrder, sourceName)
		}
		candidatesBySource[sourceName] = sourcePosts
	}
	return mixFeedPostCandidateSources(limit, cursor, sources, sourceOrder, candidatesBySource, diversityPolicy), nil
}

func feedPostPageFromSingleSource(posts []*PostView, limit int, sourceName string, randomSeed int64) feedPostPage {
	if limit <= 0 {
		return feedPostPage{
			Posts:                   posts,
			CandidateSourceByPostID: feedPostCandidateSourceMap(posts, sourceName),
		}
	}
	hasNext := len(posts) > limit
	if hasNext {
		posts = posts[:limit]
	}
	page := feedPostPage{
		Posts:                   posts,
		CandidateSourceByPostID: feedPostCandidateSourceMap(posts, sourceName),
	}
	if hasNext && len(posts) > 0 {
		page.NextCursor = feedCursorFromPostView(posts[len(posts)-1])
		if page.NextCursor != nil && normalizePostCandidateSource(sourceName) == model.PostCandidateSourceColdStart {
			page.NextCursor.ColdStartRandomSeed = randomSeed
		}
	}
	return page
}

func feedPostCandidateSourceMap(posts []*PostView, sourceName string) map[uuid.UUID]string {
	sourceName = normalizePostCandidateSource(sourceName)
	if sourceName == "" {
		sourceName = model.PostCandidateSourceGlobal
	}
	result := make(map[uuid.UUID]string, len(posts))
	for _, post := range posts {
		postID := feedPostViewPostID(post)
		if postID == uuid.Nil {
			continue
		}
		result[postID] = sourceName
	}
	return result
}

func mixFeedPostCandidateSources(limit int, cursor *feedCursor, sources []feedPostCandidateSource, sourceOrder []string, candidatesBySource map[string][]*PostView, diversityPolicies ...FeedDiversityPolicy) feedPostPage {
	if limit <= 0 {
		limit = defaultFeedLimit
	}
	previouslyDeliveredPostIDs := feedCursorDeliveredPostIDSet(cursor)
	seenPostIDs := make(map[uuid.UUID]struct{}, len(previouslyDeliveredPostIDs)+limit)
	for postID := range previouslyDeliveredPostIDs {
		seenPostIDs[postID] = struct{}{}
	}
	selectedPostIDs := make(map[uuid.UUID]struct{}, limit)
	selectedCountBySource := make(map[string]int, len(sourceOrder))
	sourceCount := len(sourceOrder)
	if sourceCount <= 0 {
		sourceCount = len(sources)
	}
	diversityPolicy := DefaultFeedDiversityPolicy()
	if len(diversityPolicies) > 0 {
		diversityPolicy = diversityPolicies[0].Normalized()
	}
	diversity := newFeedDiversityTracker(limit, diversityPolicy)
	selected := make([]feedPostCandidateItem, 0, limit)

	selectCandidate := func(candidate feedPostCandidateItem, enforceDiversity bool) bool {
		sourceName := normalizePostCandidateSource(candidate.SourceName)
		if sourceName == "" {
			sourceName = model.PostCandidateSourceGlobal
		}
		if len(selected) >= limit || !feedPostViewIsSelectable(candidate.Post) {
			return false
		}
		if sourceMax := feedPostCandidateSourceMaxPerPage(sourceName, sourceCount); sourceMax > 0 && selectedCountBySource[sourceName] >= sourceMax {
			return false
		}
		postID := feedPostViewPostID(candidate.Post)
		if _, exists := seenPostIDs[postID]; exists {
			return false
		}
		if enforceDiversity && !diversity.Allows(candidate.Post) {
			return false
		}
		seenPostIDs[postID] = struct{}{}
		selectedPostIDs[postID] = struct{}{}
		selected = append(selected, candidate)
		selectedCountBySource[sourceName]++
		diversity.Add(candidate.Post)
		return true
	}

	selectFromSource := func(sourceName string, quota int) {
		if quota <= 0 || len(selected) >= limit {
			return
		}
		added := 0
		for idx, post := range candidatesBySource[sourceName] {
			if added >= quota || len(selected) >= limit {
				return
			}
			if selectCandidate(feedPostCandidateItem{SourceName: sourceName, Index: idx, Post: post}, true) {
				added++
			}
		}
	}

	for _, source := range sources {
		sourceName := normalizePostCandidateSource(source.Name)
		if sourceName == "" {
			sourceName = model.PostCandidateSourceGlobal
		}
		selectFromSource(sourceName, feedPostCandidateSourceQuota(limit, sourceName, sourceCount))
	}

	remaining := make([]feedPostCandidateItem, 0, limit*len(sourceOrder))
	for _, sourceName := range sourceOrder {
		for idx, post := range candidatesBySource[sourceName] {
			if !feedPostViewIsSelectable(post) {
				continue
			}
			remaining = append(remaining, feedPostCandidateItem{SourceName: sourceName, Index: idx, Post: post})
		}
	}
	sort.SliceStable(remaining, func(i, j int) bool {
		return feedPostViewRanksBefore(remaining[i].Post, remaining[j].Post)
	})
	for _, candidate := range remaining {
		if len(selected) >= limit {
			break
		}
		selectCandidate(candidate, true)
	}
	for _, candidate := range remaining {
		if len(selected) >= limit {
			break
		}
		selectCandidate(candidate, false)
	}

	posts := make([]*PostView, 0, len(selected))
	candidateSourceByPostID := make(map[uuid.UUID]string, len(selected))
	deliveredPostIDs := feedCursorDeliveredPostIDs(cursor)
	for _, item := range selected {
		posts = append(posts, item.Post)
		postID := feedPostViewPostID(item.Post)
		deliveredPostIDs = append(deliveredPostIDs, postID)
		if postID != uuid.Nil {
			sourceName := normalizePostCandidateSource(item.SourceName)
			if sourceName == "" {
				sourceName = model.PostCandidateSourceGlobal
			}
			candidateSourceByPostID[postID] = sourceName
		}
	}
	sourcePositions, consumedIndexBySource := feedCandidateSourcePositions(candidatesBySource, sourceOrder, previouslyDeliveredPostIDs, selectedPostIDs)

	page := feedPostPage{
		Posts:                   posts,
		CandidateSourceByPostID: candidateSourceByPostID,
	}
	if feedPostCandidateSourcesHaveNext(candidatesBySource, consumedIndexBySource) && len(posts) > 0 {
		next := feedCursorFromPostView(posts[len(posts)-1])
		if next != nil {
			next.Sources = sourcePositions
			next.ColdStartRandomSeed = coldStartRandomSeedFromSources(sources)
			next.DeliveredPostIDs = trimFeedDeliveredPostIDs(deliveredPostIDs)
			page.NextCursor = next
		}
	}
	return page
}

type feedDiversityTracker struct {
	maxAuthorPosts    int
	maxCommunityPosts int
	maxProfilePosts   int
	maxCategoryPosts  int
	maxTagPosts       int
	authorCounts      map[uuid.UUID]int
	communityCounts   map[uuid.UUID]int
	profileCounts     map[enum.PostProfileKey]int
	categoryCounts    map[enum.PostCategory]int
	tagCounts         map[string]int
}

func newFeedDiversityTracker(limit int, policy FeedDiversityPolicy) feedDiversityTracker {
	if limit <= 0 {
		limit = defaultFeedLimit
	}
	policy = policy.Normalized()
	return feedDiversityTracker{
		maxAuthorPosts:    min(limit, policy.MaxPostsPerAuthorPerPage),
		maxCommunityPosts: min(limit, policy.MaxPostsPerCommunityPerPage),
		maxProfilePosts:   min(limit, policy.MaxPostsPerProfilePerPage),
		maxCategoryPosts:  min(limit, policy.MaxPostsPerCategoryPerPage),
		maxTagPosts:       min(limit, policy.MaxPostsPerTagPerPage),
		authorCounts:      make(map[uuid.UUID]int),
		communityCounts:   make(map[uuid.UUID]int),
		profileCounts:     make(map[enum.PostProfileKey]int),
		categoryCounts:    make(map[enum.PostCategory]int),
		tagCounts:         make(map[string]int),
	}
}

func (t *feedDiversityTracker) Allows(view *PostView) bool {
	if t == nil || view == nil || view.Post == nil {
		return false
	}
	post := view.Post
	if post.AuthorUserID != uuid.Nil && t.authorCounts[post.AuthorUserID] >= t.maxAuthorPosts {
		return false
	}
	if post.CommunityID != nil && *post.CommunityID != uuid.Nil && t.communityCounts[*post.CommunityID] >= t.maxCommunityPosts {
		return false
	}
	if post.PostProfileKey != "" && t.profileCounts[post.PostProfileKey] >= t.maxProfilePosts {
		return false
	}
	if post.Category != "" && t.categoryCounts[post.Category] >= t.maxCategoryPosts {
		return false
	}
	for _, tag := range feedDiversityTags(post.Tags) {
		if t.tagCounts[tag] >= t.maxTagPosts {
			return false
		}
	}
	return true
}

func (t *feedDiversityTracker) Add(view *PostView) {
	if t == nil || view == nil || view.Post == nil {
		return
	}
	post := view.Post
	if post.AuthorUserID != uuid.Nil {
		t.authorCounts[post.AuthorUserID]++
	}
	if post.CommunityID != nil && *post.CommunityID != uuid.Nil {
		t.communityCounts[*post.CommunityID]++
	}
	if post.PostProfileKey != "" {
		t.profileCounts[post.PostProfileKey]++
	}
	if post.Category != "" {
		t.categoryCounts[post.Category]++
	}
	for _, tag := range feedDiversityTags(post.Tags) {
		t.tagCounts[tag]++
	}
}

func (t *feedDiversityTracker) AddAuthorUserIDs(authorUserIDs []uuid.UUID) {
	if t == nil {
		return
	}
	for _, authorUserID := range authorUserIDs {
		if authorUserID == uuid.Nil {
			continue
		}
		t.authorCounts[authorUserID]++
	}
}

func (t *feedDiversityTracker) AddCommunityIDs(communityIDs []uuid.UUID) {
	if t == nil {
		return
	}
	for _, communityID := range communityIDs {
		if communityID == uuid.Nil {
			continue
		}
		t.communityCounts[communityID]++
	}
}

func (t *feedDiversityTracker) AddPostProfileKeys(profileKeys []enum.PostProfileKey) {
	if t == nil {
		return
	}
	for _, profileKey := range profileKeys {
		if profileKey == "" {
			continue
		}
		t.profileCounts[profileKey]++
	}
}

func (t *feedDiversityTracker) AddCategories(categories []enum.PostCategory) {
	if t == nil {
		return
	}
	for _, category := range categories {
		if category == "" {
			continue
		}
		t.categoryCounts[category]++
	}
}

func (t *feedDiversityTracker) AddTags(tags []string) {
	if t == nil {
		return
	}
	for _, tag := range tags {
		tag = strings.ToLower(strings.TrimSpace(tag))
		if tag == "" {
			continue
		}
		t.tagCounts[tag]++
	}
}

func feedDiversityTags(tags []string) []string {
	if len(tags) == 0 {
		return nil
	}
	seen := make(map[string]struct{}, len(tags))
	normalized := make([]string, 0, len(tags))
	for _, tag := range tags {
		tag = strings.ToLower(strings.TrimSpace(tag))
		if tag == "" {
			continue
		}
		if _, exists := seen[tag]; exists {
			continue
		}
		seen[tag] = struct{}{}
		normalized = append(normalized, tag)
	}
	return normalized
}

func feedCandidateSourcePositions(candidatesBySource map[string][]*PostView, sourceOrder []string, previouslyDeliveredPostIDs map[uuid.UUID]struct{}, selectedPostIDs map[uuid.UUID]struct{}) (map[string]feedSourceCursor, map[string]int) {
	positions := make(map[string]feedSourceCursor)
	consumedIndexBySource := make(map[string]int, len(sourceOrder))
	for _, sourceName := range sourceOrder {
		consumedIndexBySource[sourceName] = -1
		for idx, post := range candidatesBySource[sourceName] {
			if !feedPostViewIsSelectable(post) {
				continue
			}
			postID := feedPostViewPostID(post)
			_, delivered := previouslyDeliveredPostIDs[postID]
			_, selected := selectedPostIDs[postID]
			if !delivered && !selected {
				break
			}
			positions[sourceName] = feedSourceCursorFromPostView(post)
			consumedIndexBySource[sourceName] = idx
		}
	}
	return positions, consumedIndexBySource
}

func feedPostCandidateFetchLimit(limit int) int {
	if limit <= 0 {
		return defaultFeedLimit + 1
	}
	return limit*2 + 1
}

func feedPostCandidateSourceQuota(limit int, sourceName string, sourceCount int) int {
	if limit <= 0 {
		return 0
	}
	switch normalizePostCandidateSource(sourceName) {
	case model.PostCandidateSourceFollowing:
		return 1
	case model.PostCandidateSourceFollowed, model.PostCandidateSourceSocial:
		return 1
	case model.PostCandidateSourceSystem:
		if sourceCount > 1 {
			if limit < maxMixedFeedSystemPostsPerPage {
				return limit
			}
			return maxMixedFeedSystemPostsPerPage
		}
		if limit < maxFeedSystemPostsPerPage {
			return limit
		}
		return maxFeedSystemPostsPerPage
	case model.PostCandidateSourceGeo, model.PostCandidateSourceInterest, model.PostCandidateSourceColdStart:
		if limit >= 5 {
			return 1
		}
	}
	return 0
}

func feedPostCandidateSourceMaxPerPage(sourceName string, sourceCount int) int {
	if normalizePostCandidateSource(sourceName) == model.PostCandidateSourceSystem {
		if sourceCount > 1 {
			return maxMixedFeedSystemPostsPerPage
		}
		return maxFeedSystemPostsPerPage
	}
	return 0
}

func feedPostCandidateSourcesHaveNext(candidatesBySource map[string][]*PostView, consumedIndexBySource map[string]int) bool {
	for sourceName, candidates := range candidatesBySource {
		consumedIndex := consumedIndexBySource[sourceName]
		for idx := consumedIndex + 1; idx < len(candidates); idx++ {
			if feedPostViewIsSelectable(candidates[idx]) {
				return true
			}
		}
	}
	return false
}

func (u *PostUseCase) latestPostViews(ctx context.Context, viewerUserID *uuid.UUID, limit int, offset int, communityIDs []uuid.UUID, followedByUserID *uuid.UUID, countryCode string, cityID string, cursor *feedCursor, expiryMode postFeedExpiryMode) ([]*PostView, error) {
	return u.latestPostViewsForCandidateSource(ctx, viewerUserID, limit, offset, communityIDs, feedPostCandidateSource{
		Name:             "legacy",
		FollowedByUserID: followedByUserID,
	}, countryCode, cityID, cursor, expiryMode, nil)
}

func (u *PostUseCase) latestPostViewsForCandidateSource(ctx context.Context, viewerUserID *uuid.UUID, limit int, offset int, communityIDs []uuid.UUID, source feedPostCandidateSource, countryCode string, cityID string, cursor *feedCursor, expiryMode postFeedExpiryMode, rankingPolicyOverrides ...*model.FeedRankingPolicyOverride) ([]*PostView, error) {
	rankingPolicyOverride := firstFeedRankingPolicyOverride(rankingPolicyOverrides)
	currentCountryCode := normalizeCountryCode(countryCode)
	currentCityID := normalizeFeedCityID(cityID)
	filter := model.PostListFilter{
		OnlyPublished:              true,
		Sort:                       "latest_desc",
		Limit:                      limit,
		Offset:                     offset,
		CommunityIDs:               communityIDs,
		CandidateSource:            normalizePostCandidateSource(source.Name),
		ColdStartRandomSeed:        source.RandomSeed,
		FollowedByUserID:           source.FollowedByUserID,
		ExcludeFollowedByUserID:    source.ExcludeFollowedByUserID,
		ViewerUserID:               viewerUserID,
		CurrentCountryCode:         currentCountryCode,
		CurrentCityID:              currentCityID,
		DisablePersonalizedRanking: source.DisablePersonalizedRanking,
		FeedRankingPolicyOverride:  cloneFeedRankingPolicyOverride(rankingPolicyOverride),
	}
	switch expiryMode {
	case postFeedExpiryExpiring:
		filter.OnlyExpiring = true
	case postFeedExpiryPersistent:
		filter.ExcludeExpiring = true
	}
	if cursor != nil && cursor.PostID != uuid.Nil && !cursor.PublishedAt.IsZero() {
		publishedAt := cursor.PublishedAt.UTC()
		postID := cursor.PostID
		filter.FeedCursorPublishedAt = &publishedAt
		filter.FeedCursorPostID = &postID
	}
	cacheKey, cacheTTL, cacheable := u.postFeedPostListCacheKey(ctx, viewerUserID, limit, offset, communityIDs, source, currentCountryCode, currentCityID, cursor, expiryMode)
	if cacheable {
		if cached, ok, cacheErr := u.postFeedCache.GetPosts(ctx, cacheKey); cacheErr == nil && ok {
			return u.buildPostViews(ctx, cached, viewerUserID)
		}
	}
	posts, err := u.repo.ListFeedPosts(ctx, filter)
	if err != nil {
		return nil, fmt.Errorf("list feed posts: %w", err)
	}
	if cacheable {
		_ = u.postFeedCache.SetPosts(ctx, cacheKey, posts, cacheTTL)
	}
	return u.buildPostViews(ctx, posts, viewerUserID)
}

func feedPostViewRanksBefore(left *PostView, right *PostView) bool {
	leftTime := feedPostViewRankedAt(left)
	rightTime := feedPostViewRankedAt(right)
	if !leftTime.Equal(rightTime) {
		return leftTime.After(rightTime)
	}
	return feedPostViewPostID(left).String() > feedPostViewPostID(right).String()
}

func feedPostViewRankedAt(view *PostView) time.Time {
	if view == nil || view.Post == nil {
		return time.Time{}
	}
	if view.Post.FeedRankedAt != nil && !view.Post.FeedRankedAt.IsZero() {
		return view.Post.FeedRankedAt.UTC()
	}
	if view.Post.PublishedAt != nil && !view.Post.PublishedAt.IsZero() {
		return view.Post.PublishedAt.UTC()
	}
	return view.Post.CreatedAt.UTC()
}

func feedPostViewPostID(view *PostView) uuid.UUID {
	if view == nil || view.Post == nil {
		return uuid.Nil
	}
	return view.Post.ID
}

func feedPostViewIsSelectable(view *PostView) bool {
	return view != nil && view.Post != nil && view.Post.ID != uuid.Nil
}

func feedCursorForCandidateSource(cursor *feedCursor, sourceName string) *feedCursor {
	if cursor == nil {
		return nil
	}
	sourceName = normalizePostCandidateSource(sourceName)
	if sourceName != "" && len(cursor.Sources) > 0 {
		if sourceCursor, ok := cursor.Sources[sourceName]; ok && sourceCursor.PostID != uuid.Nil && !sourceCursor.PublishedAt.IsZero() {
			return &feedCursor{
				Version:     cursor.Version,
				Surface:     cursor.Surface,
				Tab:         cursor.Tab,
				PublishedAt: sourceCursor.PublishedAt.UTC(),
				PostID:      sourceCursor.PostID,
			}
		}
		return nil
	}
	if cursor.PostID == uuid.Nil || cursor.PublishedAt.IsZero() {
		return nil
	}
	return cursor
}

func coldStartRandomSeedFromSources(sources []feedPostCandidateSource) int64 {
	for _, source := range sources {
		if normalizePostCandidateSource(source.Name) == model.PostCandidateSourceColdStart && source.RandomSeed > 0 {
			return source.RandomSeed
		}
	}
	return 0
}

func feedCursorSourcePositions(cursor *feedCursor) map[string]feedSourceCursor {
	positions := make(map[string]feedSourceCursor)
	if cursor == nil {
		return positions
	}
	for sourceName, sourceCursor := range cursor.Sources {
		normalized := normalizePostCandidateSource(sourceName)
		if normalized == "" || sourceCursor.PostID == uuid.Nil || sourceCursor.PublishedAt.IsZero() {
			continue
		}
		sourceCursor.PublishedAt = sourceCursor.PublishedAt.UTC()
		positions[normalized] = sourceCursor
	}
	return positions
}

func feedSourceCursorFromPostView(view *PostView) feedSourceCursor {
	cursor := feedCursorFromPostView(view)
	if cursor == nil {
		return feedSourceCursor{}
	}
	return feedSourceCursor{
		PublishedAt: cursor.PublishedAt,
		PostID:      cursor.PostID,
	}
}

func feedCursorDeliveredPostIDSet(cursor *feedCursor) map[uuid.UUID]struct{} {
	items := feedCursorDeliveredPostIDs(cursor)
	seen := make(map[uuid.UUID]struct{}, len(items))
	for _, postID := range items {
		if postID == uuid.Nil {
			continue
		}
		seen[postID] = struct{}{}
	}
	return seen
}

func feedCursorDeliveredPostIDs(cursor *feedCursor) []uuid.UUID {
	if cursor == nil || len(cursor.DeliveredPostIDs) == 0 {
		return nil
	}
	items := make([]uuid.UUID, 0, len(cursor.DeliveredPostIDs))
	seen := make(map[uuid.UUID]struct{}, len(cursor.DeliveredPostIDs))
	for _, postID := range cursor.DeliveredPostIDs {
		if postID == uuid.Nil {
			continue
		}
		if _, exists := seen[postID]; exists {
			continue
		}
		seen[postID] = struct{}{}
		items = append(items, postID)
	}
	return items
}

func trimFeedDeliveredPostIDs(items []uuid.UUID) []uuid.UUID {
	const maxDeliveredPostIDs = 120
	if len(items) == 0 {
		return nil
	}
	seen := make(map[uuid.UUID]struct{}, len(items))
	unique := make([]uuid.UUID, 0, len(items))
	for _, postID := range items {
		if postID == uuid.Nil {
			continue
		}
		if _, exists := seen[postID]; exists {
			continue
		}
		seen[postID] = struct{}{}
		unique = append(unique, postID)
	}
	if len(unique) > maxDeliveredPostIDs {
		unique = unique[len(unique)-maxDeliveredPostIDs:]
	}
	return unique
}

func feedCursorDeliveredAuthorUserIDs(cursor *feedCursor) []uuid.UUID {
	if cursor == nil || len(cursor.DeliveredAuthorUserIDs) == 0 {
		return nil
	}
	return normalizeFeedDeliveredUUIDs(cursor.DeliveredAuthorUserIDs)
}

func feedCursorDeliveredCommunityIDs(cursor *feedCursor) []uuid.UUID {
	if cursor == nil || len(cursor.DeliveredCommunityIDs) == 0 {
		return nil
	}
	return normalizeFeedDeliveredUUIDs(cursor.DeliveredCommunityIDs)
}

func trimFeedDeliveredUUIDs(items []uuid.UUID) []uuid.UUID {
	const maxDeliveredUUIDs = 120
	normalized := normalizeFeedDeliveredUUIDs(items)
	if len(normalized) > maxDeliveredUUIDs {
		normalized = normalized[len(normalized)-maxDeliveredUUIDs:]
	}
	return normalized
}

func normalizeFeedDeliveredUUIDs(items []uuid.UUID) []uuid.UUID {
	if len(items) == 0 {
		return nil
	}
	normalized := make([]uuid.UUID, 0, len(items))
	for _, item := range items {
		if item == uuid.Nil {
			continue
		}
		normalized = append(normalized, item)
	}
	return normalized
}

func feedCursorDeliveredPostProfileKeys(cursor *feedCursor) []enum.PostProfileKey {
	if cursor == nil || len(cursor.DeliveredPostProfileKeys) == 0 {
		return nil
	}
	return normalizeFeedDeliveredPostProfileKeys(cursor.DeliveredPostProfileKeys)
}

func trimFeedDeliveredPostProfileKeys(items []enum.PostProfileKey) []enum.PostProfileKey {
	const maxDeliveredPostProfiles = 120
	normalized := normalizeFeedDeliveredPostProfileKeys(items)
	if len(normalized) > maxDeliveredPostProfiles {
		normalized = normalized[len(normalized)-maxDeliveredPostProfiles:]
	}
	return normalized
}

func normalizeFeedDeliveredPostProfileKeys(items []enum.PostProfileKey) []enum.PostProfileKey {
	if len(items) == 0 {
		return nil
	}
	normalized := make([]enum.PostProfileKey, 0, len(items))
	for _, item := range items {
		if item == "" {
			continue
		}
		normalized = append(normalized, item)
	}
	return normalized
}

func feedCursorDeliveredCategories(cursor *feedCursor) []enum.PostCategory {
	if cursor == nil || len(cursor.DeliveredCategories) == 0 {
		return nil
	}
	return normalizeFeedDeliveredCategories(cursor.DeliveredCategories)
}

func trimFeedDeliveredCategories(items []enum.PostCategory) []enum.PostCategory {
	const maxDeliveredCategories = 120
	normalized := normalizeFeedDeliveredCategories(items)
	if len(normalized) > maxDeliveredCategories {
		normalized = normalized[len(normalized)-maxDeliveredCategories:]
	}
	return normalized
}

func normalizeFeedDeliveredCategories(items []enum.PostCategory) []enum.PostCategory {
	if len(items) == 0 {
		return nil
	}
	normalized := make([]enum.PostCategory, 0, len(items))
	for _, item := range items {
		if item == "" {
			continue
		}
		normalized = append(normalized, item)
	}
	return normalized
}

func feedCursorDeliveredTags(cursor *feedCursor) []string {
	if cursor == nil || len(cursor.DeliveredTags) == 0 {
		return nil
	}
	return normalizeFeedDeliveredTags(cursor.DeliveredTags)
}

func trimFeedDeliveredTags(tags []string) []string {
	const maxDeliveredTags = 120
	normalized := normalizeFeedDeliveredTags(tags)
	if len(normalized) > maxDeliveredTags {
		normalized = normalized[len(normalized)-maxDeliveredTags:]
	}
	return normalized
}

func normalizeFeedDeliveredTags(tags []string) []string {
	if len(tags) == 0 {
		return nil
	}
	normalized := make([]string, 0, len(tags))
	for _, tag := range tags {
		tag = strings.ToLower(strings.TrimSpace(tag))
		if tag == "" {
			continue
		}
		normalized = append(normalized, tag)
	}
	return normalized
}

func (u *PostUseCase) latestStoryViews(ctx context.Context, viewerUserID *uuid.UUID, limit int, offset int) ([]*StoryView, error) {
	if limit <= 0 {
		limit = postsTrayLimit
	}
	stories, err := u.repo.ListStories(ctx, model.StoryListFilter{
		ViewerUserID: viewerUserID,
		Limit:        limit,
		Offset:       offset,
	})
	if err != nil {
		return nil, fmt.Errorf("list stories: %w", err)
	}
	return u.buildStoryViews(ctx, stories, viewerUserID)
}

func (u *PostUseCase) postFeedPostListCacheKey(ctx context.Context, viewerUserID *uuid.UUID, limit int, offset int, communityIDs []uuid.UUID, source feedPostCandidateSource, countryCode string, cityID string, cursor *feedCursor, expiryMode postFeedExpiryMode) (string, time.Duration, bool) {
	if u == nil ||
		u.postFeedCache == nil ||
		cursor != nil ||
		offset != 0 ||
		len(communityIDs) > 0 ||
		limit <= 0 {
		return "", 0, false
	}

	sourceName := normalizePostCandidateSource(source.Name)
	if sourceName == "" {
		sourceName = model.PostCandidateSourceGlobal
	}
	kind := sourceName
	ttl := u.postFeedCacheTTL
	if expiryMode == postFeedExpiryExpiring {
		kind = "tray:" + sourceName
		ttl = u.postsTrayCacheTTL
	}
	if source.DisablePersonalizedRanking {
		kind = "nonpersonalized:" + kind
	}
	if ttl <= 0 {
		return "", 0, false
	}

	scopes := []string{postFeedCacheGlobalScope}
	owner := "anonymous"
	if source.FollowedByUserID != nil && *source.FollowedByUserID != uuid.Nil {
		owner = source.FollowedByUserID.String()
		scopes = append(scopes, postFeedCacheFollowingScope(*source.FollowedByUserID))
	} else if source.ExcludeFollowedByUserID != nil && *source.ExcludeFollowedByUserID != uuid.Nil {
		owner = source.ExcludeFollowedByUserID.String()
		scopes = append(scopes, postFeedCacheDiscoveryScope(*source.ExcludeFollowedByUserID))
	} else if viewerUserID != nil && *viewerUserID != uuid.Nil {
		owner = viewerUserID.String()
		scopes = append(scopes, postFeedCacheViewerScope(*viewerUserID))
	}

	versionParts := make([]string, 0, len(scopes))
	for _, scope := range scopes {
		version, err := u.postFeedCache.CurrentVersion(ctx, scope)
		if err != nil || version < 0 {
			version = 0
		}
		versionParts = append(versionParts, postFeedCacheVersionSegment(scope, version))
	}
	if expiryMode == "" {
		expiryMode = postFeedExpiryAny
	}
	geoSegment := fmt.Sprintf("%s:%s", strings.ToUpper(strings.TrimSpace(countryCode)), strings.ToLower(strings.TrimSpace(cityID)))
	rankingExperiment := feedCacheRankingExperimentSegment(u.feedExperimentAssignmentForViewer(viewerUserID).RankingExperiment)
	policySegment := feedRankingPolicyOverrideCacheSegment(u.feedExperimentPolicyOverride(rankingExperiment))
	randomSeedSegment := "0"
	if sourceName == model.PostCandidateSourceColdStart && source.RandomSeed > 0 {
		randomSeedSegment = strconv.FormatInt(source.RandomSeed, 10)
	}
	return fmt.Sprintf("post-feed:v2:%s:%s:%s:policy:%s:%s:rank:%s:random:%s:geo:%s:%s:limit:%d", kind, owner, expiryMode, feedCandidateMixerPolicy, policySegment, rankingExperiment, randomSeedSegment, geoSegment, strings.Join(versionParts, ","), limit), ttl, true
}

func (u *PostUseCase) feedExperimentAssignmentForViewer(viewerUserID *uuid.UUID) FeedExperimentAssignment {
	defaultAssignment := u.feedExperimentAssignment
	if strings.TrimSpace(defaultAssignment.RankingExperiment) == "" {
		defaultAssignment.RankingExperiment = defaultFeedExperimentKey
	}
	if viewerUserID == nil || *viewerUserID == uuid.Nil || len(u.feedExperimentVariants) == 0 {
		return defaultAssignment
	}
	totalWeight := 0
	for _, variant := range u.feedExperimentVariants {
		if variant.Weight > 0 && strings.TrimSpace(variant.RankingExperiment) != "" {
			totalWeight += variant.Weight
		}
	}
	if totalWeight <= 0 {
		return defaultAssignment
	}

	bucket := feedExperimentViewerBucket(*viewerUserID, totalWeight)
	cumulative := 0
	for _, variant := range u.feedExperimentVariants {
		if variant.Weight <= 0 || strings.TrimSpace(variant.RankingExperiment) == "" {
			continue
		}
		cumulative += variant.Weight
		if bucket < cumulative {
			return FeedExperimentAssignment{RankingExperiment: variant.RankingExperiment}
		}
	}
	return defaultAssignment
}

func parseFeedExperimentVariants(spec string) []feedExperimentVariant {
	parts := strings.Split(spec, ",")
	variants := make([]feedExperimentVariant, 0, len(parts))
	for _, part := range parts {
		name, weightText, ok := strings.Cut(part, "=")
		if !ok {
			continue
		}
		name = strings.TrimSpace(name)
		if name == "" {
			continue
		}
		weight, err := strconv.Atoi(strings.TrimSpace(weightText))
		if err != nil || weight <= 0 {
			continue
		}
		variants = append(variants, feedExperimentVariant{
			RankingExperiment: name,
			Weight:            weight,
		})
	}
	return variants
}

func parseFeedExperimentPolicyOverrides(spec string) map[string]model.FeedRankingPolicyOverride {
	groups := strings.Split(spec, ";")
	overrides := make(map[string]model.FeedRankingPolicyOverride, len(groups))
	for _, group := range groups {
		name, fieldsText, ok := strings.Cut(group, ":")
		if !ok {
			continue
		}
		name = feedCacheRankingExperimentSegment(name)
		if name == "" {
			continue
		}
		override := model.FeedRankingPolicyOverride{ExperimentKey: name}
		hasFields := false
		for _, fieldText := range strings.Split(fieldsText, ",") {
			fieldName, fieldValue, ok := strings.Cut(fieldText, "=")
			if !ok {
				continue
			}
			if applyFeedExperimentPolicyOverrideField(&override, fieldName, fieldValue) {
				hasFields = true
			}
		}
		if hasFields {
			overrides[name] = override
		}
	}
	if len(overrides) == 0 {
		return nil
	}
	return overrides
}

func applyFeedExperimentPolicyOverrideField(override *model.FeedRankingPolicyOverride, fieldName string, fieldValue string) bool {
	if override == nil {
		return false
	}
	key := normalizeFeedExperimentPolicyFieldKey(fieldName)
	value := strings.TrimSpace(fieldValue)
	if key == "" || value == "" {
		return false
	}
	switch key {
	case "postinterestweight":
		return setFeedRankingFloatOverride(value, &override.PostInterestWeight)
	case "communityinterestweight":
		return setFeedRankingFloatOverride(value, &override.CommunityInterestWeight)
	case "communityinterestminscore":
		return setFeedRankingFloatOverride(value, &override.CommunityInterestMinScore)
	case "frequentcommunityminvisits":
		return setFeedRankingIntOverride(value, &override.FrequentCommunityMinVisits)
	case "frequentcommunityminvisitdays":
		return setFeedRankingIntOverride(value, &override.FrequentCommunityMinVisitDays)
	case "frequentcommunityfreshnesswindow":
		return setFeedRankingDurationOverride(value, &override.FrequentCommunityFreshnessWindow)
	case "frequentcommunityhalflife":
		return setFeedRankingDurationOverride(value, &override.FrequentCommunityHalfLife)
	case "frequentcommunityboosthours":
		return setFeedRankingIntOverride(value, &override.FrequentCommunityBoostHours)
	case "postprofileaffinityweight":
		return setFeedRankingFloatOverride(value, &override.PostProfileAffinityWeight)
	case "cityaffinityweight":
		return setFeedRankingFloatOverride(value, &override.CityAffinityWeight)
	case "countryaffinityweight":
		return setFeedRankingFloatOverride(value, &override.CountryAffinityWeight)
	case "categoryaffinityweight":
		return setFeedRankingFloatOverride(value, &override.CategoryAffinityWeight)
	case "tagaffinityweight":
		return setFeedRankingFloatOverride(value, &override.TagAffinityWeight)
	case "authoraffinityweight":
		return setFeedRankingFloatOverride(value, &override.AuthorAffinityWeight)
	case "maxboosthours":
		return setFeedRankingIntOverride(value, &override.MaxBoostHours)
	case "maxpenaltyhours":
		return setFeedRankingIntOverride(value, &override.MaxPenaltyHours)
	case "interestfreshnessdelay":
		return setFeedRankingDurationOverride(value, &override.InterestFreshnessDelay)
	case "notinterestedpenalty":
		return setFeedRankingDurationOverride(value, &override.NotInterestedPenalty)
	case "recentpostimpressionwindow":
		return setFeedRankingDurationOverride(value, &override.RecentPostImpressionWindow)
	case "recentpostimpressionpenaltyhours":
		return setFeedRankingIntOverride(value, &override.RecentPostImpressionPenaltyHours)
	case "recentcommunityeventwindow":
		return setFeedRankingDurationOverride(value, &override.RecentCommunityEventWindow)
	case "recentcommunitypenaltyhours":
		return setFeedRankingIntOverride(value, &override.RecentCommunityPenaltyHours)
	case "communitymembershipboosthours":
		return setFeedRankingIntOverride(value, &override.CommunityMembershipBoostHours)
	case "socialfriendboosthours":
		return setFeedRankingIntOverride(value, &override.SocialFriendBoostHours)
	case "socialfollowingboosthours":
		return setFeedRankingIntOverride(value, &override.SocialFollowingBoostHours)
	case "currentcityboosthours":
		return setFeedRankingIntOverride(value, &override.CurrentCityBoostHours)
	case "currentcountryboosthours":
		return setFeedRankingIntOverride(value, &override.CurrentCountryBoostHours)
	case "explorationfreshnesswindow":
		return setFeedRankingDurationOverride(value, &override.ExplorationFreshnessWindow)
	case "explorationlowviewthreshold":
		return setFeedRankingIntOverride(value, &override.ExplorationLowViewThreshold)
	case "explorationmaxboosthours":
		return setFeedRankingIntOverride(value, &override.ExplorationMaxBoostHours)
	case "qualitypenaltywindow":
		return setFeedRankingDurationOverride(value, &override.QualityPenaltyWindow)
	case "qualityminnegativeevents":
		return setFeedRankingIntOverride(value, &override.QualityMinNegativeEvents)
	case "qualitynegativepenaltyhours":
		return setFeedRankingIntOverride(value, &override.QualityNegativePenaltyHours)
	case "qualitymaxpenaltyhours":
		return setFeedRankingIntOverride(value, &override.QualityMaxPenaltyHours)
	case "maxpostspercommunityperpage":
		return setFeedRankingIntOverride(value, &override.MaxPostsPerCommunityPerPage)
	case "maxpostspercategoryperpage":
		return setFeedRankingIntOverride(value, &override.MaxPostsPerCategoryPerPage)
	case "maxpostsperauthorperpage":
		return setFeedRankingIntOverride(value, &override.MaxPostsPerAuthorPerPage)
	case "maxpostsperprofileperpage":
		return setFeedRankingIntOverride(value, &override.MaxPostsPerProfilePerPage)
	case "coldstartmaxboosthours":
		return setFeedRankingIntOverride(value, &override.ColdStartMaxBoostHours)
	case "coldstartengagementweight":
		return setFeedRankingFloatOverride(value, &override.ColdStartEngagementWeight)
	case "engagementmaxboosthours":
		return setFeedRankingIntOverride(value, &override.EngagementMaxBoostHours)
	case "engagementweight":
		return setFeedRankingFloatOverride(value, &override.EngagementWeight)
	case "engagementfreshnesswindow":
		return setFeedRankingDurationOverride(value, &override.EngagementFreshnessWindow)
	case "negativeinterestdecaywindow":
		return setFeedRankingDurationOverride(value, &override.NegativeInterestDecayWindow)
	case "negativeinterestminweight":
		return setFeedRankingFloatOverride(value, &override.NegativeInterestMinWeight)
	case "directnegativefeedbackdecaywindow":
		return setFeedRankingDurationOverride(value, &override.DirectNegativeFeedbackDecayWindow)
	default:
		return false
	}
}

func normalizeFeedExperimentPolicyFieldKey(value string) string {
	value = strings.ToLower(strings.TrimSpace(value))
	value = strings.TrimPrefix(value, "feed_ranking_")
	replacer := strings.NewReplacer("_", "", "-", "", ".", "")
	return replacer.Replace(value)
}

func setFeedRankingFloatOverride(value string, target **float64) bool {
	parsed, err := strconv.ParseFloat(strings.TrimSpace(value), 64)
	if err != nil {
		return false
	}
	*target = &parsed
	return true
}

func setFeedRankingIntOverride(value string, target **int) bool {
	parsed, err := strconv.Atoi(strings.TrimSpace(value))
	if err != nil {
		return false
	}
	*target = &parsed
	return true
}

func setFeedRankingDurationOverride(value string, target **time.Duration) bool {
	parsed, err := time.ParseDuration(strings.TrimSpace(value))
	if err != nil {
		return false
	}
	*target = &parsed
	return true
}

func feedExperimentViewerBucket(viewerUserID uuid.UUID, modulo int) int {
	if modulo <= 0 {
		return 0
	}
	hash := fnv.New32a()
	_, _ = hash.Write([]byte(viewerUserID.String()))
	return int(hash.Sum32() % uint32(modulo))
}

func (u *PostUseCase) feedExperimentPolicyOverride(rankingExperiment string) *model.FeedRankingPolicyOverride {
	if u == nil || len(u.feedExperimentPolicies) == 0 {
		return nil
	}
	key := feedCacheRankingExperimentSegment(rankingExperiment)
	override, ok := u.feedExperimentPolicies[key]
	if !ok {
		return nil
	}
	return cloneFeedRankingPolicyOverride(&override)
}

func firstFeedRankingPolicyOverride(overrides []*model.FeedRankingPolicyOverride) *model.FeedRankingPolicyOverride {
	if len(overrides) == 0 || overrides[0] == nil {
		return nil
	}
	return overrides[0]
}

func cloneFeedRankingPolicyOverride(override *model.FeedRankingPolicyOverride) *model.FeedRankingPolicyOverride {
	if override == nil {
		return nil
	}
	copy := *override
	return &copy
}

func feedRankingPolicyOverrideCacheSegment(override *model.FeedRankingPolicyOverride) string {
	if override == nil {
		return "baseline"
	}
	raw, err := json.Marshal(override)
	if err != nil || len(raw) == 0 {
		return "override"
	}
	hash := fnv.New32a()
	_, _ = hash.Write(raw)
	return fmt.Sprintf("%s-%x", feedCacheRankingExperimentSegment(override.ExperimentKey), hash.Sum32())
}

func normalizePostCandidateSource(value string) string {
	switch strings.ToLower(strings.TrimSpace(value)) {
	case model.PostCandidateSourceFollowing:
		return model.PostCandidateSourceFollowing
	case model.PostCandidateSourceFollowed:
		return model.PostCandidateSourceFollowed
	case model.PostCandidateSourceSocial:
		return model.PostCandidateSourceSocial
	case model.PostCandidateSourceSystem:
		return model.PostCandidateSourceSystem
	case model.PostCandidateSourceGeo:
		return model.PostCandidateSourceGeo
	case model.PostCandidateSourceInterest:
		return model.PostCandidateSourceInterest
	case model.PostCandidateSourceColdStart:
		return model.PostCandidateSourceColdStart
	case model.PostCandidateSourcePopular:
		return model.PostCandidateSourcePopular
	case model.PostCandidateSourceGlobal:
		return model.PostCandidateSourceGlobal
	default:
		return ""
	}
}

func normalizeFeedCityID(value string) string {
	return strings.TrimSpace(value)
}

func feedCacheRankingExperimentSegment(value string) string {
	value = strings.ToLower(strings.TrimSpace(value))
	if value == "" {
		return defaultFeedExperimentKey
	}
	var builder strings.Builder
	builder.Grow(len(value))
	for _, r := range value {
		switch {
		case r >= 'a' && r <= 'z':
			builder.WriteRune(r)
		case r >= '0' && r <= '9':
			builder.WriteRune(r)
		case r == '-' || r == '_' || r == '.':
			builder.WriteRune(r)
		default:
			builder.WriteByte('-')
		}
	}
	normalized := strings.Trim(builder.String(), "-._")
	if normalized == "" {
		return defaultFeedExperimentKey
	}
	return normalized
}

func normalizeFeedSurface(surface string) string {
	switch strings.ToLower(strings.TrimSpace(surface)) {
	case "activities", "excursions", "home":
		return strings.ToLower(strings.TrimSpace(surface))
	default:
		return "content"
	}
}

func feedSurfaceSupportsStoriesTray(surface string) bool {
	switch surface {
	case "activities", "excursions", "home":
		return true
	default:
		return false
	}
}

func normalizeFeedTab(tab string) string {
	switch strings.ToLower(strings.TrimSpace(tab)) {
	case "following":
		return "following"
	case "trending":
		return "trending"
	default:
		return "for_you"
	}
}

func normalizeFeedLimit(limit int) int {
	if limit <= 0 {
		return defaultFeedLimit
	}
	if limit > maxFeedLimit {
		return maxFeedLimit
	}
	return limit
}

func normalizeFeedInterestLimit(limit int) int {
	if limit <= 0 {
		return defaultFeedInterestLimit
	}
	if limit > maxFeedInterestLimit {
		return maxFeedInterestLimit
	}
	return limit
}

func normalizeFeedQualityMetricsLimit(limit int) int {
	if limit <= 0 {
		return defaultFeedQualityMetricsLimit
	}
	if limit > maxFeedQualityMetricsLimit {
		return maxFeedQualityMetricsLimit
	}
	return limit
}

func normalizeCuratedBlockCap(value int, fallback int, max int) int {
	if value < 0 || value > max {
		return fallback
	}
	return value
}

func normalizeFeedDiversityCap(value int, fallback int, max int) int {
	if value <= 0 || value > max {
		return fallback
	}
	return value
}

func normalizeOptionalFeedSurface(surface string) string {
	trimmed := strings.ToLower(strings.TrimSpace(surface))
	switch trimmed {
	case "", "home", "content":
		return trimmed
	default:
		return ""
	}
}

func feedEventsInvalidateViewerFeedCache(events []model.FeedEvent) bool {
	for _, event := range events {
		switch event.EventType {
		case model.FeedEventTypeClick,
			model.FeedEventTypeDwell,
			model.FeedEventTypeLike,
			model.FeedEventTypeComment,
			model.FeedEventTypeShare,
			model.FeedEventTypeSubscribe,
			model.FeedEventTypeHide,
			model.FeedEventTypeNotInterested,
			model.FeedEventTypeReport:
			return true
		}
	}
	return false
}

func normalizeFeedInterestEntityTypes(values []string) []string {
	if len(values) == 0 {
		return nil
	}

	seen := make(map[string]bool, len(values))
	normalized := make([]string, 0, len(values))
	for _, value := range values {
		entityType := normalizeFeedInterestEntityType(value)
		if entityType == "" || seen[entityType] {
			continue
		}
		seen[entityType] = true
		normalized = append(normalized, entityType)
	}
	return normalized
}

func normalizeFeedInterestEntityType(value string) string {
	switch strings.ToLower(strings.TrimSpace(value)) {
	case model.FeedInterestEntityTypePost:
		return model.FeedInterestEntityTypePost
	case model.FeedInterestEntityTypePostProfile:
		return model.FeedInterestEntityTypePostProfile
	case model.FeedInterestEntityTypeCommunity:
		return model.FeedInterestEntityTypeCommunity
	case model.FeedInterestEntityTypeActivity:
		return model.FeedInterestEntityTypeActivity
	case model.FeedInterestEntityTypePlace:
		return model.FeedInterestEntityTypePlace
	case model.FeedInterestEntityTypeTour:
		return model.FeedInterestEntityTypeTour
	case model.FeedInterestEntityTypeGuide:
		return model.FeedInterestEntityTypeGuide
	case model.FeedInterestEntityTypeProfile:
		return model.FeedInterestEntityTypeProfile
	case model.FeedInterestEntityTypeCity:
		return model.FeedInterestEntityTypeCity
	case model.FeedInterestEntityTypeCountry:
		return model.FeedInterestEntityTypeCountry
	case model.FeedInterestEntityTypeCategory:
		return model.FeedInterestEntityTypeCategory
	case model.FeedInterestEntityTypeTag:
		return model.FeedInterestEntityTypeTag
	default:
		return ""
	}
}

func encodeFeedCursor(cursor *feedCursor, surface string, tab string, rankingExperiment string) string {
	if cursor == nil {
		return ""
	}
	cursor.Version = feedCursorVersion
	cursor.Surface = surface
	cursor.Tab = tab
	cursor.CandidatePolicy = feedCandidateMixerPolicy
	cursor.RankingExperiment = feedCacheRankingExperimentSegment(rankingExperiment)
	payload, err := json.Marshal(cursor)
	if err != nil {
		return ""
	}
	return base64.RawURLEncoding.EncodeToString(payload)
}

func feedCursorFromPostView(post *PostView) *feedCursor {
	if post == nil || post.Post == nil || post.Post.ID == uuid.Nil {
		return nil
	}
	publishedAt := post.Post.CreatedAt
	if post.Post.PublishedAt != nil {
		publishedAt = *post.Post.PublishedAt
	}
	if post.Post.FeedRankedAt != nil {
		publishedAt = *post.Post.FeedRankedAt
	}
	if publishedAt.IsZero() {
		return nil
	}
	return &feedCursor{
		PublishedAt: publishedAt.UTC(),
		PostID:      post.Post.ID,
	}
}

func decodeFeedCursor(cursor string, surface string, tab string, rankingExperiment string) (*feedCursor, error) {
	trimmed := strings.TrimSpace(cursor)
	if trimmed == "" {
		return nil, nil
	}
	payload, err := base64.RawURLEncoding.DecodeString(trimmed)
	if err != nil {
		return nil, ErrInvalidFeedCursor
	}
	var decoded feedCursor
	if err = json.Unmarshal(payload, &decoded); err != nil {
		return nil, ErrInvalidFeedCursor
	}
	if decoded.PostID == uuid.Nil || decoded.PublishedAt.IsZero() {
		return nil, ErrInvalidFeedCursor
	}
	if decoded.Version != feedCursorVersion {
		return nil, ErrInvalidFeedCursor
	}
	if decoded.CandidatePolicy != feedCandidateMixerPolicy {
		return nil, ErrInvalidFeedCursor
	}
	cursorRankingExperiment := feedCacheRankingExperimentSegment(decoded.RankingExperiment)
	expectedRankingExperiment := feedCacheRankingExperimentSegment(rankingExperiment)
	if cursorRankingExperiment != expectedRankingExperiment {
		return nil, ErrInvalidFeedCursor
	}
	if decoded.Surface != surface || decoded.Tab != tab {
		return nil, ErrInvalidFeedCursor
	}
	decoded.PublishedAt = decoded.PublishedAt.UTC()
	for sourceName, sourceCursor := range decoded.Sources {
		if sourceCursor.PostID == uuid.Nil || sourceCursor.PublishedAt.IsZero() {
			delete(decoded.Sources, sourceName)
			continue
		}
		sourceCursor.PublishedAt = sourceCursor.PublishedAt.UTC()
		decoded.Sources[sourceName] = sourceCursor
	}
	decoded.DeliveredPostIDs = trimFeedDeliveredPostIDs(decoded.DeliveredPostIDs)
	decoded.DeliveredAuthorUserIDs = trimFeedDeliveredUUIDs(decoded.DeliveredAuthorUserIDs)
	decoded.DeliveredCommunityIDs = trimFeedDeliveredUUIDs(decoded.DeliveredCommunityIDs)
	decoded.DeliveredPostProfileKeys = trimFeedDeliveredPostProfileKeys(decoded.DeliveredPostProfileKeys)
	decoded.DeliveredCategories = trimFeedDeliveredCategories(decoded.DeliveredCategories)
	decoded.DeliveredTags = trimFeedDeliveredTags(decoded.DeliveredTags)
	return &decoded, nil
}

func normalizeFeedEventInput(input FeedEventInput, viewerUserID *uuid.UUID, receivedAt time.Time) (model.FeedEvent, error) {
	eventType := normalizeFeedEventType(input.EventType)
	surface := normalizeFeedSurface(input.Surface)
	tab := normalizeFeedTab(input.Tab)
	blockID := strings.TrimSpace(input.BlockID)
	blockType := strings.TrimSpace(input.BlockType)
	requestID := strings.TrimSpace(input.RequestID)
	occurredAt := input.OccurredAt.UTC()
	if occurredAt.IsZero() {
		occurredAt = receivedAt
	}

	if input.EventID == uuid.Nil ||
		eventType == "" ||
		blockID == "" ||
		len(blockID) > 200 ||
		!isFeedBlockType(blockType) ||
		input.Rank < 0 ||
		len(requestID) > 128 ||
		len(input.Metadata) > maxFeedMetadata {
		return model.FeedEvent{}, ErrInvalidFeedEvent
	}

	var postID *uuid.UUID
	if input.PostID != uuid.Nil {
		post := input.PostID
		postID = &post
	}
	if blockType == model.FeedBlockTypePostCard && postID == nil {
		return model.FeedEvent{}, ErrInvalidFeedEvent
	}

	return model.FeedEvent{
		ID:           uuid.New(),
		EventID:      input.EventID,
		ViewerUserID: copyUUIDPtr(viewerUserID),
		EventType:    eventType,
		Surface:      surface,
		Tab:          tab,
		BlockID:      blockID,
		BlockType:    blockType,
		PostID:       postID,
		CommunityID:  copyUUIDPtr(input.CommunityID),
		Rank:         input.Rank,
		OccurredAt:   occurredAt,
		ReceivedAt:   receivedAt,
		RequestID:    requestID,
		Metadata:     copyFeedMetadata(input.Metadata),
	}, nil
}

func normalizeFeedEventType(value string) string {
	switch strings.ToLower(strings.TrimSpace(value)) {
	case model.FeedEventTypeImpression:
		return model.FeedEventTypeImpression
	case model.FeedEventTypeClick:
		return model.FeedEventTypeClick
	case model.FeedEventTypeDwell:
		return model.FeedEventTypeDwell
	case model.FeedEventTypeLike:
		return model.FeedEventTypeLike
	case model.FeedEventTypeComment:
		return model.FeedEventTypeComment
	case model.FeedEventTypeShare:
		return model.FeedEventTypeShare
	case model.FeedEventTypeSubscribe:
		return model.FeedEventTypeSubscribe
	case model.FeedEventTypeHide:
		return model.FeedEventTypeHide
	case model.FeedEventTypeNotInterested:
		return model.FeedEventTypeNotInterested
	case model.FeedEventTypeReport:
		return model.FeedEventTypeReport
	default:
		return ""
	}
}

func isFeedBlockType(value string) bool {
	switch strings.TrimSpace(value) {
	case model.FeedBlockTypeStoriesTray,
		model.FeedBlockTypeCommunityCard,
		model.FeedBlockTypeSuggestedCommunities,
		model.FeedBlockTypeMySubscriptions,
		model.FeedBlockTypePostCard,
		model.FeedBlockTypeActivityCard,
		model.FeedBlockTypePlaceCard,
		model.FeedBlockTypeTourCard,
		model.FeedBlockTypeGuideCard,
		model.FeedBlockTypeProfileCard,
		model.FeedBlockTypeOfficialNewsCard:
		return true
	default:
		return false
	}
}

func copyUUIDPtr(value *uuid.UUID) *uuid.UUID {
	if value == nil || *value == uuid.Nil {
		return nil
	}
	copied := *value
	return &copied
}

func copyFeedMetadata(metadata map[string]any) map[string]any {
	if len(metadata) == 0 {
		return map[string]any{}
	}
	copied := make(map[string]any, len(metadata))
	for key, value := range metadata {
		trimmedKey := strings.TrimSpace(key)
		if trimmedKey == "" || len(trimmedKey) > 64 {
			continue
		}
		switch typed := value.(type) {
		case string:
			if len(typed) <= 256 {
				copied[trimmedKey] = typed
			}
		case bool, float64, int, int64:
			copied[trimmedKey] = typed
		case []any:
			if items := copyFeedMetadataStringList(typed); len(items) > 0 {
				copied[trimmedKey] = items
			}
		case []string:
			values := make([]any, 0, len(typed))
			for _, item := range typed {
				values = append(values, item)
			}
			if items := copyFeedMetadataStringList(values); len(items) > 0 {
				copied[trimmedKey] = items
			}
		}
	}
	return copied
}

func copyFeedMetadataStringList(values []any) []string {
	if len(values) == 0 {
		return nil
	}
	const maxItems = 20
	items := make([]string, 0, min(len(values), maxItems))
	seen := make(map[string]bool, min(len(values), maxItems))
	for _, value := range values {
		raw, ok := value.(string)
		if !ok {
			continue
		}
		item := strings.TrimSpace(raw)
		if item == "" || len(item) > 64 || seen[item] {
			continue
		}
		seen[item] = true
		items = append(items, item)
		if len(items) >= maxItems {
			break
		}
	}
	return items
}
