package app

import (
	"context"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/feed-service/internal/domain/model"
)

const (
	defaultFeedLimit               = 20
	maxFeedLimit                   = 30
	feedCursorVersion              = 1
	postsTrayLimit                 = 12
	communityLimit                 = 10
	maxFeedEventBatch              = 50
	maxFeedMetadata                = 20
	defaultFeedInterestLimit       = 50
	maxFeedInterestLimit           = 200
	defaultFeedQualityMetricsLimit = 50
	maxFeedQualityMetricsLimit     = 200
	postFeedCacheGlobalScope       = "post-feed:global"
	defaultFeedExperimentKey       = "control"
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
	Post *PostView
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

func DefaultFeedCuratedBlockPolicy() FeedCuratedBlockPolicy {
	return FeedCuratedBlockPolicy{
		MaxConversionBlocksPerPage:  2,
		MaxOfficialNewsCardsPerPage: 1,
		MaxProfileCardsPerPage:      1,
	}
}

func (p FeedCuratedBlockPolicy) Normalized() FeedCuratedBlockPolicy {
	defaults := DefaultFeedCuratedBlockPolicy()
	p.MaxConversionBlocksPerPage = normalizeCuratedBlockCap(p.MaxConversionBlocksPerPage, defaults.MaxConversionBlocksPerPage, 10)
	p.MaxOfficialNewsCardsPerPage = normalizeCuratedBlockCap(p.MaxOfficialNewsCardsPerPage, defaults.MaxOfficialNewsCardsPerPage, 5)
	p.MaxProfileCardsPerPage = normalizeCuratedBlockCap(p.MaxProfileCardsPerPage, defaults.MaxProfileCardsPerPage, 5)
	return p
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
	Version     int       `json:"v"`
	Surface     string    `json:"surface"`
	Tab         string    `json:"tab"`
	PublishedAt time.Time `json:"publishedAt"`
	PostID      uuid.UUID `json:"postId"`
}

func (u *PostUseCase) BuildFeed(ctx context.Context, subject string, input BuildFeedInput) (*FeedPage, error) {
	viewerUserID, err := u.optionalUserID(ctx, subject)
	if err != nil {
		return nil, err
	}

	surface := normalizeFeedSurface(input.Surface)
	tab := normalizeFeedTab(input.Tab)
	limit := normalizeFeedLimit(input.Limit)
	cursor, err := decodeFeedCursor(input.Cursor, surface, tab)
	if err != nil {
		return nil, err
	}
	isFirstPage := cursor == nil

	blocks := make([]FeedBlock, 0, limit+4)
	rank := 0
	postCardsCursor := cursor

	if viewerUserID != nil && feedSurfaceSupportsStoriesTray(surface) && isFirstPage {
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

	if isFirstPage && tab != "following" {
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

	var followedByUserID *uuid.UUID
	if tab == "following" {
		if viewerUserID == nil || *viewerUserID == uuid.Nil {
			return &FeedPage{Items: blocks, Assignment: u.feedExperimentAssignment}, nil
		}
		followedByUserID = viewerUserID
	}

	posts, err := u.latestPostViews(ctx, viewerUserID, limit+1, 0, nil, followedByUserID, postCardsCursor, postFeedExpiryPersistent)
	if err != nil {
		return nil, err
	}
	hasNextPage := len(posts) > limit
	if hasNextPage {
		posts = posts[:limit]
	}
	for _, post := range posts {
		if post == nil || post.Post == nil {
			continue
		}
		blocks = append(blocks, FeedBlock{
			Type: model.FeedBlockTypePostCard,
			ID:   "post:" + post.Post.ID.String(),
			Data: PostCardFeedData{Post: post},
			Rank: rank,
		})
		rank++
	}

	nextCursor := ""
	if hasNextPage && len(posts) > 0 {
		nextCursor = encodeFeedCursor(posts[len(posts)-1], surface, tab)
	}

	return &FeedPage{Items: blocks, NextCursor: nextCursor, Assignment: u.feedExperimentAssignment}, nil
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

func (u *PostUseCase) latestPostViews(ctx context.Context, viewerUserID *uuid.UUID, limit int, offset int, communityIDs []uuid.UUID, followedByUserID *uuid.UUID, cursor *feedCursor, expiryMode postFeedExpiryMode) ([]*PostView, error) {
	filter := model.PostListFilter{
		OnlyPublished:    true,
		Sort:             "latest_desc",
		Limit:            limit,
		Offset:           offset,
		CommunityIDs:     communityIDs,
		FollowedByUserID: followedByUserID,
		ViewerUserID:     viewerUserID,
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
	cacheKey, cacheTTL, cacheable := u.postFeedPostListCacheKey(ctx, viewerUserID, limit, offset, communityIDs, followedByUserID, cursor, expiryMode)
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

func (u *PostUseCase) postFeedPostListCacheKey(ctx context.Context, viewerUserID *uuid.UUID, limit int, offset int, communityIDs []uuid.UUID, followedByUserID *uuid.UUID, cursor *feedCursor, expiryMode postFeedExpiryMode) (string, time.Duration, bool) {
	if u == nil ||
		u.postFeedCache == nil ||
		cursor != nil ||
		offset != 0 ||
		len(communityIDs) > 0 ||
		limit <= 0 {
		return "", 0, false
	}

	kind := "feed"
	ttl := u.postFeedCacheTTL
	if expiryMode == postFeedExpiryExpiring {
		kind = "tray"
		ttl = u.postsTrayCacheTTL
	}
	if ttl <= 0 {
		return "", 0, false
	}

	scopes := []string{postFeedCacheGlobalScope}
	owner := "anonymous"
	if followedByUserID != nil && *followedByUserID != uuid.Nil {
		kind = "following"
		owner = followedByUserID.String()
		scopes = append(scopes, postFeedCacheFollowingScope(*followedByUserID))
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
	return fmt.Sprintf("post-feed:v2:%s:%s:%s:%s:limit:%d", kind, owner, expiryMode, strings.Join(versionParts, ","), limit), ttl, true
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
		case model.FeedEventTypeHide, model.FeedEventTypeNotInterested:
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
	case model.FeedInterestEntityTypeCommunity:
		return model.FeedInterestEntityTypeCommunity
	case model.FeedInterestEntityTypeActivity:
		return model.FeedInterestEntityTypeActivity
	case model.FeedInterestEntityTypeAttraction:
		return model.FeedInterestEntityTypeAttraction
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

func encodeFeedCursor(post *PostView, surface string, tab string) string {
	cursor := feedCursorFromPostView(post)
	if cursor == nil {
		return ""
	}
	cursor.Version = feedCursorVersion
	cursor.Surface = surface
	cursor.Tab = tab
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

func decodeFeedCursor(cursor string, surface string, tab string) (*feedCursor, error) {
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
	if decoded.Version != feedCursorVersion || decoded.Surface != surface || decoded.Tab != tab {
		return nil, ErrInvalidFeedCursor
	}
	decoded.PublishedAt = decoded.PublishedAt.UTC()
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
	case model.FeedEventTypeHide:
		return model.FeedEventTypeHide
	case model.FeedEventTypeNotInterested:
		return model.FeedEventTypeNotInterested
	default:
		return ""
	}
}

func isFeedBlockType(value string) bool {
	switch strings.TrimSpace(value) {
	case model.FeedBlockTypeStoriesTray,
		model.FeedBlockTypeSuggestedCommunities,
		model.FeedBlockTypeMySubscriptions,
		model.FeedBlockTypePostCard,
		model.FeedBlockTypeActivityCard,
		model.FeedBlockTypeAttractionCard,
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
