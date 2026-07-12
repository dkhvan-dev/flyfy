package app

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"regexp"
	"sort"
	"strings"
	"time"
	"unicode"
	"unicode/utf8"

	"github.com/google/uuid"

	"kz/inflap/backend/services/feed-service/internal/domain/enum"
	"kz/inflap/backend/services/feed-service/internal/domain/model"
	"kz/inflap/backend/services/feed-service/internal/domain/port"
)

const (
	maxPostTitleChars                  = 160
	maxPostContentChars                = 2500
	maxCommentBodyChars                = 800
	maxPostReportDetailsChars          = 800
	maxPostReportResolutionNoteChars   = 800
	maxPostTags                        = 8
	maxTagChars                        = 32
	defaultListLimit                   = 20
	maxListLimit                       = 100
	defaultRelatedLimit                = 3
	defaultCommentLimit                = 20
	defaultPostReportAutoHideThreshold = 3
	postCreateRateLimitMax             = 10
	postCreateRateLimitWindow          = time.Hour
	defaultPostCreateCooldown          = 5 * time.Minute
	commentCreateWindow                = 3 * time.Hour
	defaultStoryTTL                    = 24 * time.Hour
)

var (
	nonSlugPattern        = regexp.MustCompile(`[^a-z0-9]+`)
	postImageMarkerRegexp = regexp.MustCompile(`\[\[post-image:[^\]]+\]\]`)
	postSpacingRegexp     = regexp.MustCompile(`\n{3,}`)
	postPostFormats       = []enum.PostFormat{
		enum.PostFormatArticle,
		enum.PostFormatGuide,
		enum.PostFormatPhotoEssay,
		enum.PostFormatCulinary,
	}
)

type PostAuthor struct {
	UserID           uuid.UUID
	Nickname         *string
	AvatarFileID     *uuid.UUID
	CountryCode      *string
	Locale           string
	Timezone         string
	IsFriendOfViewer bool
}

type PostView struct {
	Post          *model.Post
	Author        PostAuthor
	LikedByViewer bool
	Editable      bool
	SeenByViewer  bool
	SeenAt        *time.Time
	ShareURL      string
}

type StoryView struct {
	Story        *model.Story
	Author       PostAuthor
	SeenByViewer bool
	SeenAt       *time.Time
	ShareURL     string
}

type PostCreateEligibility struct {
	CanCreate       bool
	Limit           int
	Remaining       int
	Window          time.Duration
	Cooldown        time.Duration
	BlockReason     string
	RetryAfter      time.Duration
	NextAvailableAt *time.Time
}

const (
	PostCreateBlockReasonCooldown   = "cooldown"
	PostCreateBlockReasonHourlyRate = "hourly_limit"
)

type PostCommentView struct {
	Comment       *model.PostComment
	Author        PostAuthor
	Editable      bool
	Deletable     bool
	LikedByViewer bool
	ShareURL      string
}

type PostDetail struct {
	Post     *PostView
	Related  []*PostView
	Comments []*PostCommentView
}

type CreatePostInput struct {
	Title               string
	Content             string
	Format              enum.PostFormat
	ContentBlocks       json.RawMessage
	Category            enum.PostCategory
	Status              enum.PostStatus
	PublishIntent       bool
	AllowArchivedStatus bool
	Revision            int64
	CommunityID         *uuid.UUID
	CommunityInstanceID *uuid.UUID
	PostProfileKey      enum.PostProfileKey
	StructuredData      json.RawMessage
	CoverFileID         *uuid.UUID
	PlaceName           *string
	PlaceCountryCode    *string
	PlaceCityID         *string
	Tags                []string
	ExpiresAt           *time.Time
}

type CreateStoryInput struct {
	Caption     string
	MediaFileID uuid.UUID
	CoverFileID uuid.UUID
	MediaType   enum.PostMediaType
	ExpiresAt   *time.Time
}

type ListStoriesInput struct {
	Limit  int
	Offset int
}

type StoryListPage struct {
	Items   []*StoryView
	Limit   int
	Offset  int
	HasMore bool
}

type UpdatePostInput struct {
	Title                  *string
	Content                *string
	Format                 *enum.PostFormat
	ContentBlocks          *json.RawMessage
	Category               *enum.PostCategory
	Status                 *enum.PostStatus
	PublishIntent          bool
	AllowArchivedStatus    bool
	Revision               int64
	CommunityID            *uuid.UUID
	CommunityIDSet         bool
	CommunityInstanceID    *uuid.UUID
	CommunityInstanceIDSet bool
	PostProfileKey         *enum.PostProfileKey
	StructuredData         *json.RawMessage
	CoverFileID            *uuid.UUID
	CoverFileIDSet         bool
	PlaceName              *string
	PlaceNameSet           bool
	PlaceCountryCode       *string
	PlaceCountryCodeSet    bool
	PlaceCityID            *string
	PlaceCityIDSet         bool
	Tags                   []string
	TagsSet                bool
	ExpiresAt              *time.Time
	ExpiresAtSet           bool
}

type ListPostsInput struct {
	Search           string
	Format           []string
	Category         []string
	Status           string
	ModerationStatus []string
	Place            string
	CountryCode      string
	CityID           string
	AuthorID         *uuid.UUID
	CommunityID      *uuid.UUID
	Sort             string
	Limit            int
	Offset           int
	IncludeMine      bool
}

type ListCommunityModerationPostsInput struct {
	CommunityID uuid.UUID
	Limit       int
	Offset      int
}

type ReviewCommunityPostInput struct {
	CommunityID uuid.UUID
	Decision    string
	Reason      string
}

type ListCommunityPostModerationDecisionsInput struct {
	CommunityID uuid.UUID
	PostID      uuid.UUID
	Limit       int
	Offset      int
}

type SubmitPostReportInput struct {
	Reason  string
	Details string
}

type PostReportView struct {
	Report           *model.PostReport
	Post             *model.Post
	OpenReportsCount int
	AutoHidden       bool
}

type ListCommunityPostReportsInput struct {
	CommunityID uuid.UUID
	Status      string
	Limit       int
	Offset      int
}

type ResolveCommunityPostReportInput struct {
	CommunityID    uuid.UUID
	ReportID       uuid.UUID
	Decision       string
	ResolutionNote string
}

type ListAdminPostReportsInput struct {
	Status string
	Limit  int
	Offset int
}

type ListAdminCommunityModerationPostsInput struct {
	Limit  int
	Offset int
}

type ReviewAdminCommunityPostInput struct {
	PostID       uuid.UUID
	ActorStaffID uuid.UUID
	Decision     string
	Reason       string
}

type ResolveAdminPostReportInput struct {
	ReportID       uuid.UUID
	ActorStaffID   uuid.UUID
	Decision       string
	ResolutionNote string
}

type PostUseCase struct {
	repo                     port.PostRepository
	users                    UserServiceClient
	mediaBinder              PostMediaBinder
	routeReferenceValidator  PostRouteReferenceValidator
	postNotifications        port.PostNotificationGateway
	communitySearchIndexer   CommunitySearchIndexer
	postFeedCache            port.PostFeedCache
	postFeedCacheTTL         time.Duration
	postsTrayCacheTTL        time.Duration
	postsBaseURL             string
	feedExperimentAssignment FeedExperimentAssignment
	feedExperimentVariants   []feedExperimentVariant
	feedExperimentPolicies   map[string]model.FeedRankingPolicyOverride
	feedCuratedBlockPolicy   FeedCuratedBlockPolicy
	feedDiversityPolicy      FeedDiversityPolicy
	postCreateCooldown       time.Duration
}

func NewPostUseCase(repo port.PostRepository, users UserServiceClient, postsBaseURL string) *PostUseCase {
	return &PostUseCase{
		repo:                   repo,
		users:                  users,
		postsBaseURL:           strings.TrimRight(strings.TrimSpace(postsBaseURL), "/"),
		feedCuratedBlockPolicy: DefaultFeedCuratedBlockPolicy(),
		feedDiversityPolicy:    DefaultFeedDiversityPolicy(),
		postCreateCooldown:     defaultPostCreateCooldown,
		feedExperimentAssignment: FeedExperimentAssignment{
			RankingExperiment: defaultFeedExperimentKey,
		},
	}
}

func (u *PostUseCase) WithPostCreateCooldown(cooldown time.Duration) *PostUseCase {
	if cooldown > 0 {
		u.postCreateCooldown = cooldown
	}
	return u
}

func (u *PostUseCase) WithCommunitySearchIndexer(indexer CommunitySearchIndexer) *PostUseCase {
	u.communitySearchIndexer = indexer
	return u
}

func (u *PostUseCase) WithPostMediaBinder(binder PostMediaBinder) *PostUseCase {
	u.mediaBinder = binder
	return u
}

func (u *PostUseCase) WithPostNotificationGateway(gateway port.PostNotificationGateway) *PostUseCase {
	u.postNotifications = gateway
	return u
}

func (u *PostUseCase) WithPostFeedCache(cache port.PostFeedCache, feedTTL time.Duration, trayTTL time.Duration) *PostUseCase {
	u.postFeedCache = cache
	u.postFeedCacheTTL = feedTTL
	u.postsTrayCacheTTL = trayTTL
	return u
}

func (u *PostUseCase) WithFeedExperimentAssignment(rankingExperiment string) *PostUseCase {
	assignment := strings.TrimSpace(rankingExperiment)
	if assignment == "" {
		assignment = defaultFeedExperimentKey
	}
	u.feedExperimentAssignment = FeedExperimentAssignment{RankingExperiment: assignment}
	return u
}

func (u *PostUseCase) WithFeedExperimentVariants(spec string) *PostUseCase {
	u.feedExperimentVariants = parseFeedExperimentVariants(spec)
	return u
}

func (u *PostUseCase) WithFeedExperimentPolicyOverrides(spec string) *PostUseCase {
	u.feedExperimentPolicies = parseFeedExperimentPolicyOverrides(spec)
	return u
}

func (u *PostUseCase) WithFeedCuratedBlockPolicy(policy FeedCuratedBlockPolicy) *PostUseCase {
	u.feedCuratedBlockPolicy = policy.Normalized()
	return u
}

func (u *PostUseCase) WithFeedDiversityPolicy(policy FeedDiversityPolicy) *PostUseCase {
	u.feedDiversityPolicy = policy.Normalized()
	return u
}

func (u *PostUseCase) bumpPostFeedCacheScopes(ctx context.Context, scopes ...string) {
	if u == nil || u.postFeedCache == nil || len(scopes) == 0 {
		return
	}
	_ = u.postFeedCache.BumpVersion(ctx, scopes...)
}

func (u *PostUseCase) bumpPostFeedMutationCacheScopes(ctx context.Context, post *model.Post) {
	scopes := []string{postFeedCacheGlobalScope}
	if post != nil {
		if post.AuthorUserID != uuid.Nil {
			scopes = append(scopes, postFeedCacheAuthorScope(post.AuthorUserID))
		}
		if post.CommunityID != nil && *post.CommunityID != uuid.Nil {
			scopes = append(scopes, postFeedCacheCommunityScope(*post.CommunityID))
		}
	}
	u.bumpPostFeedCacheScopes(ctx, scopes...)
}

func (u *PostUseCase) CreatePost(ctx context.Context, subject string, input CreatePostInput) (*PostView, error) {
	if err := validatePostPostInput(input); err != nil {
		return nil, err
	}
	return u.createPost(ctx, subject, input)
}

func (u *PostUseCase) CheckPostCreateEligibility(ctx context.Context, subject string) (*PostCreateEligibility, error) {
	authorUserID, err := u.requireUserID(ctx, subject)
	if err != nil {
		return nil, err
	}
	return u.postCreateEligibility(ctx, authorUserID, time.Now().UTC())
}

func (u *PostUseCase) CreateStory(ctx context.Context, subject string, input CreateStoryInput) (*StoryView, error) {
	actorUserID, err := u.requireUserID(ctx, subject)
	if err != nil {
		return nil, err
	}
	if input.MediaFileID == uuid.Nil || input.CoverFileID == uuid.Nil {
		return nil, ErrInvalidPostMedia
	}
	mediaType := input.MediaType
	if mediaType == "" {
		mediaType = enum.PostMediaTypeImage
	}
	if mediaType != enum.PostMediaTypeImage && mediaType != enum.PostMediaTypeVideo {
		return nil, ErrInvalidPostMedia
	}

	caption := strings.TrimSpace(input.Caption)
	now := time.Now().UTC()
	expiresAt := now.Add(defaultStoryTTL)
	if input.ExpiresAt != nil && input.ExpiresAt.After(now) {
		expiresAt = input.ExpiresAt.UTC()
	}

	story := &model.Story{
		ID:           uuid.New(),
		AuthorUserID: actorUserID,
		Caption:      caption,
		MediaFileID:  input.MediaFileID,
		CoverFileID:  input.CoverFileID,
		MediaType:    mediaType,
		ExpiresAt:    expiresAt,
		CreatedAt:    now,
		UpdatedAt:    now,
	}
	if err = u.repo.CreateStory(ctx, story); err != nil {
		return nil, fmt.Errorf("create story: %w", err)
	}
	u.bumpPostFeedCacheScopes(ctx, postFeedCacheGlobalScope, postFeedCacheAuthorScope(actorUserID))
	views, err := u.buildStoryViews(ctx, []*model.Story{story}, &actorUserID)
	if err != nil {
		return nil, err
	}
	if len(views) == 0 {
		return nil, ErrStoryNotFound
	}
	return views[0], nil
}

func (u *PostUseCase) ListMyArchivedStories(ctx context.Context, subject string, input ListStoriesInput) (*StoryListPage, error) {
	authorUserID, err := u.requireUserID(ctx, subject)
	if err != nil {
		return nil, err
	}

	return u.listMyStories(ctx, authorUserID, input, true)
}

func (u *PostUseCase) ListMyActiveStories(ctx context.Context, subject string, input ListStoriesInput) (*StoryListPage, error) {
	authorUserID, err := u.requireUserID(ctx, subject)
	if err != nil {
		return nil, err
	}

	return u.listMyStories(ctx, authorUserID, input, false)
}

func (u *PostUseCase) listMyStories(ctx context.Context, authorUserID uuid.UUID, input ListStoriesInput, archived bool) (*StoryListPage, error) {
	limit := input.Limit
	if limit <= 0 {
		limit = defaultListLimit
	}
	if limit > maxListLimit {
		limit = maxListLimit
	}
	offset := input.Offset
	if offset < 0 {
		offset = 0
	}

	queryLimit := limit + 1
	if queryLimit > maxListLimit {
		queryLimit = maxListLimit
	}
	filter := model.StoryListFilter{
		AuthorUserID:   &authorUserID,
		ViewerUserID:   &authorUserID,
		Limit:          queryLimit,
		Offset:         offset,
		IncludeExpired: archived,
		OnlyExpired:    archived,
	}
	stories, err := u.repo.ListStories(ctx, filter)
	if err != nil {
		if archived {
			return nil, fmt.Errorf("list archived stories: %w", err)
		}
		return nil, fmt.Errorf("list active stories: %w", err)
	}

	hasMore := len(stories) > limit
	if hasMore {
		stories = stories[:limit]
	}
	views, err := u.buildStoryViews(ctx, stories, &authorUserID)
	if err != nil {
		return nil, err
	}

	return &StoryListPage{
		Items:   views,
		Limit:   limit,
		Offset:  offset,
		HasMore: hasMore,
	}, nil
}

func (u *PostUseCase) createPost(ctx context.Context, subject string, input CreatePostInput) (*PostView, error) {
	authorUserID, err := u.requireUserID(ctx, subject)
	if err != nil {
		return nil, err
	}
	now := time.Now().UTC()
	profile, err := u.resolvePostProfileDefaults(ctx, input.PostProfileKey)
	if err != nil {
		return nil, err
	}

	postID := uuid.New()
	post, err := normalizePostInputWithProfile(postID, input, profile)
	if err != nil {
		return nil, err
	}
	if post.Status == enum.PostStatusPublished {
		if err := u.ensurePostCreateRateLimit(ctx, authorUserID, now); err != nil {
			return nil, err
		}
	}
	document, err := postDocumentFromNormalizedBlocks(post.ContentBlocks)
	if err != nil {
		return nil, ErrInvalidPostContent
	}
	if err := u.validatePostRouteReferences(ctx, authorUserID, document); err != nil {
		return nil, err
	}

	post.ID = postID
	post.AuthorUserID = authorUserID
	post.Slug = buildPostSlug(post.Title, post.ID)
	post.CreatedAt = now
	post.UpdatedAt = now
	post.ViewHLL = model.NewHyperLogLog().Bytes()
	moderationStatus, err := u.resolvePostModerationStatus(ctx, authorUserID, post, post.ModerationStatus)
	if err != nil {
		return nil, err
	}
	post.ModerationStatus = moderationStatus
	if post.Status == enum.PostStatusPublished {
		post.PublishedAt = &now
	}
	applyPostActivityCreationState(post, profile)

	mediaPlan, err := buildPostMediaPlan(post, authorUserID)
	if err != nil {
		return nil, err
	}
	desiredStatus := post.Status
	desiredPublishedAt := post.PublishedAt
	if postHasMedia(mediaPlan) {
		applyPostMediaPlan(
			post,
			mediaPlan,
			enum.PostMediaStatusPendingBind,
			enum.PostMediaProcessingStatusPendingBind,
		)
		post.Status = enum.PostStatusDraft
		post.PublishedAt = nil
	} else {
		applyPostMediaPlan(
			post,
			mediaPlan,
			enum.PostMediaStatusReady,
			enum.PostMediaProcessingStatusBound,
		)
	}

	if err = u.repo.CreatePost(ctx, post); err != nil {
		if rateLimitErr := postRateLimitErrorFromRepository(err, time.Now().UTC()); rateLimitErr != nil {
			return nil, rateLimitErr
		}
		return nil, fmt.Errorf("create post: %w", err)
	}
	if postHasMedia(mediaPlan) {
		boundPlan, bindErr := u.bindPostMediaPlan(ctx, mediaPlan)
		if bindErr != nil {
			applyPostMediaPlan(
				post,
				mediaPlan,
				enum.PostMediaStatusFailed,
				enum.PostMediaProcessingStatusBindFailed,
			)
			post.Status = enum.PostStatusDraft
			post.PublishedAt = nil
			post.UpdatedAt = time.Now().UTC()
			if updateErr := u.repo.UpdatePost(ctx, post); updateErr != nil {
				return nil, errors.Join(bindErr, fmt.Errorf("mark post media failed: %w", updateErr))
			}
			return nil, bindErr
		}
		mediaPlan = boundPlan
		applyPostMediaPlan(
			post,
			mediaPlan,
			enum.PostMediaStatusReady,
			enum.PostMediaProcessingStatusBound,
		)
		post.Status = desiredStatus
		post.PublishedAt = desiredPublishedAt
		applyPostActivityCreationState(post, profile)
		post.UpdatedAt = time.Now().UTC()
		if err = u.repo.UpdatePost(ctx, post); err != nil {
			if rateLimitErr := postRateLimitErrorFromRepository(err, time.Now().UTC()); rateLimitErr != nil {
				return nil, rateLimitErr
			}
			return nil, fmt.Errorf("finalize post media: %w", err)
		}
		post.Revision++
	}

	u.bumpPostFeedMutationCacheScopes(ctx, post)
	return u.postMutationView(post), nil
}

func (u *PostUseCase) ensurePostCreateRateLimit(ctx context.Context, authorUserID uuid.UUID, now time.Time) error {
	eligibility, err := u.postCreateEligibility(ctx, authorUserID, now)
	if err != nil {
		return err
	}
	if !eligibility.CanCreate {
		return newPostRateLimitError(now, eligibility.NextAvailableAt)
	}
	return nil
}

func (u *PostUseCase) postCreateEligibility(ctx context.Context, authorUserID uuid.UUID, now time.Time) (*PostCreateEligibility, error) {
	cooldown := u.postCreateCooldown
	if cooldown <= 0 {
		cooldown = defaultPostCreateCooldown
	}
	cooldownUntil, err := u.repo.PostPublishCooldownUntil(ctx, authorUserID)
	if err != nil {
		return nil, fmt.Errorf("get post publish cooldown: %w", err)
	}

	windowStart := now.Add(-postCreateRateLimitWindow)
	count, err := u.repo.CountPostsPublishedByAuthorSince(ctx, authorUserID, windowStart)
	if err != nil {
		return nil, fmt.Errorf("count recent published posts by author: %w", err)
	}

	remaining := postCreateRateLimitMax - count
	if remaining < 0 {
		remaining = 0
	}
	eligibility := &PostCreateEligibility{
		CanCreate: true,
		Limit:     postCreateRateLimitMax,
		Remaining: remaining,
		Window:    postCreateRateLimitWindow,
		Cooldown:  cooldown,
	}

	var blockedUntil *time.Time
	if cooldownUntil != nil && cooldownUntil.After(now) {
		next := cooldownUntil.UTC()
		blockedUntil = &next
		eligibility.BlockReason = PostCreateBlockReasonCooldown
	}

	if count >= postCreateRateLimitMax {
		oldest, oldestErr := u.repo.OldestPostPublishedAtByAuthorSince(ctx, authorUserID, windowStart)
		if oldestErr != nil {
			return nil, fmt.Errorf("get oldest recent published post by author: %w", oldestErr)
		}
		hourlyNext := now.Add(postCreateRateLimitWindow)
		if oldest != nil {
			hourlyNext = oldest.UTC().Add(postCreateRateLimitWindow)
		}
		if blockedUntil == nil || hourlyNext.After(*blockedUntil) {
			blockedUntil = &hourlyNext
			eligibility.BlockReason = PostCreateBlockReasonHourlyRate
		}
	}

	if blockedUntil != nil && blockedUntil.After(now) {
		eligibility.CanCreate = false
		next := blockedUntil.UTC()
		eligibility.NextAvailableAt = &next
		eligibility.RetryAfter = next.Sub(now)
	}
	return eligibility, nil
}

func newPostRateLimitError(now time.Time, nextAvailableAt *time.Time) error {
	next := now.Add(defaultPostCreateCooldown)
	if nextAvailableAt != nil && nextAvailableAt.After(now) {
		next = nextAvailableAt.UTC()
	}
	return &PostRateLimitError{
		RetryAfter:      next.Sub(now),
		NextAvailableAt: next,
	}
}

func postRateLimitErrorFromRepository(err error, now time.Time) error {
	var cooldownErr *port.PostPublishCooldownError
	if !errors.As(err, &cooldownErr) {
		return nil
	}
	next := cooldownErr.NextAvailableAt.UTC()
	return newPostRateLimitError(now, &next)
}

func (u *PostUseCase) UpdatePost(ctx context.Context, subject string, postID uuid.UUID, input UpdatePostInput) (*PostView, error) {
	return u.updateOwnedPost(ctx, subject, postID, input.Revision, func(*model.Post) (UpdatePostInput, error) {
		return input, nil
	}, nil)
}

func (u *PostUseCase) AutosavePost(ctx context.Context, subject string, postID uuid.UUID, input UpdatePostInput) (*PostView, error) {
	return u.updateOwnedPost(ctx, subject, postID, input.Revision, func(existing *model.Post) (UpdatePostInput, error) {
		return input, nil
	}, func(post *model.Post, now time.Time) {
		post.LastAutosavedAt = &now
	})
}

func (u *PostUseCase) PublishPost(ctx context.Context, subject string, postID uuid.UUID, revision int64) (*PostView, error) {
	return u.updateOwnedPost(ctx, subject, postID, revision, func(existing *model.Post) (UpdatePostInput, error) {
		status := enum.PostStatusPublished
		input := UpdatePostInput{Status: &status}
		input.PublishIntent = true
		return input, nil
	}, nil)
}

func (u *PostUseCase) ArchivePost(ctx context.Context, subject string, postID uuid.UUID, revision int64) (*PostView, error) {
	return u.updateOwnedPost(ctx, subject, postID, revision, func(existing *model.Post) (UpdatePostInput, error) {
		status := enum.PostStatusArchived
		return UpdatePostInput{Status: &status, AllowArchivedStatus: true}, nil
	}, func(post *model.Post, now time.Time) {
		post.ArchivedAt = &now
	})
}

func (u *PostUseCase) DeletePost(ctx context.Context, subject string, postID uuid.UUID) error {
	actorUserID, err := u.requireUserID(ctx, subject)
	if err != nil {
		return err
	}
	if postID == uuid.Nil {
		return ErrInvalidPostID
	}

	if err = u.repo.SoftDeletePost(ctx, postID, actorUserID); err != nil {
		return fmt.Errorf("delete post: %w", err)
	}

	u.bumpPostFeedCacheScopes(
		ctx,
		postFeedCacheGlobalScope,
		postFeedCacheAuthorScope(actorUserID),
	)
	return nil
}

func (u *PostUseCase) GetPostByID(ctx context.Context, subject string, postID uuid.UUID) (*PostView, error) {
	if postID == uuid.Nil {
		return nil, ErrInvalidPostID
	}

	viewerUserID, err := u.optionalUserID(ctx, subject)
	if err != nil {
		return nil, err
	}

	post, err := u.repo.GetPostByID(ctx, postID)
	if err != nil {
		return nil, fmt.Errorf("get post by id: %w", err)
	}
	if post == nil || post.DeletedAt != nil {
		return nil, ErrPostNotFound
	}
	if !post.IsPubliclyVisible() && (viewerUserID == nil || !post.IsOwnedBy(*viewerUserID)) {
		return nil, ErrPostNotFound
	}

	view, err := u.buildPostViews(ctx, []*model.Post{post}, viewerUserID)
	if err != nil {
		return nil, err
	}
	if len(view) == 0 {
		return nil, ErrPostNotFound
	}

	return view[0], nil
}

func (u *PostUseCase) GetPostBySlug(ctx context.Context, slug string, subject string) (*PostDetail, error) {
	post, err := u.repo.GetPostBySlug(ctx, strings.TrimSpace(slug))
	if err != nil {
		return nil, fmt.Errorf("get post by slug: %w", err)
	}
	if post == nil || !post.IsPubliclyVisible() {
		return nil, ErrPostNotFound
	}

	viewerUserID, err := u.optionalUserID(ctx, subject)
	if err != nil {
		return nil, err
	}

	postViews, err := u.buildPostViews(ctx, []*model.Post{post}, viewerUserID)
	if err != nil {
		return nil, err
	}
	if len(postViews) == 0 {
		return nil, ErrPostNotFound
	}

	relatedPosts, err := u.repo.ListPosts(ctx, relatedPostsFilterFor(post))
	if err != nil {
		return nil, fmt.Errorf("list related posts: %w", err)
	}

	relatedViews, err := u.buildPostViews(ctx, relatedPosts, viewerUserID)
	if err != nil {
		return nil, err
	}

	comments, err := u.repo.ListComments(ctx, post.ID, defaultCommentLimit, 0)
	if err != nil {
		return nil, fmt.Errorf("list post comments: %w", err)
	}

	commentViews, err := u.buildCommentViews(ctx, post, comments, viewerUserID)
	if err != nil {
		return nil, err
	}

	return &PostDetail{
		Post:     postViews[0],
		Related:  relatedViews,
		Comments: commentViews,
	}, nil
}

func (u *PostUseCase) ListPosts(ctx context.Context, subject string, input ListPostsInput) ([]*PostView, error) {
	viewerUserID, err := u.optionalUserID(ctx, subject)
	if err != nil {
		return nil, err
	}

	filter, err := u.normalizeListInput(input, viewerUserID)
	if err != nil {
		return nil, err
	}

	items, err := u.repo.ListPosts(ctx, filter)
	if err != nil {
		return nil, fmt.Errorf("list posts: %w", err)
	}

	return u.buildPostViews(ctx, items, viewerUserID)
}

func (u *PostUseCase) CountPosts(ctx context.Context, subject string, input ListPostsInput) (int, error) {
	viewerUserID, err := u.optionalUserID(ctx, subject)
	if err != nil {
		return 0, err
	}

	filter, err := u.normalizeListInput(input, viewerUserID)
	if err != nil {
		return 0, err
	}

	count, err := u.repo.CountPosts(ctx, filter)
	if err != nil {
		return 0, fmt.Errorf("count posts: %w", err)
	}
	return count, nil
}

func (u *PostUseCase) ListCommunityModerationPosts(ctx context.Context, subject string, input ListCommunityModerationPostsInput) ([]*PostView, error) {
	actorUserID, err := u.requireUserID(ctx, subject)
	if err != nil {
		return nil, err
	}
	if err = u.requireCommunityModerator(ctx, actorUserID, input.CommunityID); err != nil {
		return nil, err
	}

	limit := input.Limit
	if limit <= 0 {
		limit = defaultListLimit
	}
	if limit > maxListLimit {
		limit = maxListLimit
	}
	offset := input.Offset
	if offset < 0 {
		offset = 0
	}

	status := enum.PostStatusPublished
	items, err := u.repo.ListPosts(ctx, model.PostListFilter{
		CommunityIDs:       []uuid.UUID{input.CommunityID},
		Status:             &status,
		ModerationStatuses: []enum.ModerationStatus{enum.ModerationStatusPending},
		ExcludeArchived:    true,
		Sort:               "latest_desc",
		Limit:              limit,
		Offset:             offset,
	})
	if err != nil {
		return nil, fmt.Errorf("list community moderation posts: %w", err)
	}

	return u.buildPostViews(ctx, items, &actorUserID)
}

func (u *PostUseCase) ReviewCommunityPost(ctx context.Context, subject string, postID uuid.UUID, input ReviewCommunityPostInput) (*PostView, error) {
	actorUserID, err := u.requireUserID(ctx, subject)
	if err != nil {
		return nil, err
	}
	if postID == uuid.Nil {
		return nil, ErrInvalidPostID
	}
	if err = u.requireCommunityModerator(ctx, actorUserID, input.CommunityID); err != nil {
		return nil, err
	}

	decision, nextStatus, err := moderationDecisionForReviewInput(input.Decision)
	if err != nil {
		return nil, err
	}

	post, err := u.repo.GetPostByID(ctx, postID)
	if err != nil {
		return nil, fmt.Errorf("get post for community review: %w", err)
	}
	if post == nil || post.DeletedAt != nil || post.CommunityID == nil || *post.CommunityID != input.CommunityID {
		return nil, ErrPostNotFound
	}
	if post.Status != enum.PostStatusPublished ||
		post.ArchivedAt != nil ||
		post.ModerationStatus != enum.ModerationStatusPending {
		return nil, ErrInvalidPostStatus
	}

	now := time.Now().UTC()
	previousStatus := post.ModerationStatus
	post.ModerationStatus = nextStatus
	post.UpdatedAt = now
	moderationDecision := &model.PostModerationDecision{
		ID:              uuid.New(),
		PostID:          post.ID,
		CommunityID:     input.CommunityID,
		ModeratorUserID: actorUserID,
		Decision:        decision,
		PreviousStatus:  previousStatus,
		NextStatus:      nextStatus,
		PostRevision:    post.Revision,
		Reason:          strings.TrimSpace(input.Reason),
		CreatedAt:       now,
	}
	if err = u.repo.ReviewCommunityPost(ctx, post, moderationDecision); err != nil {
		if errors.Is(err, port.ErrPostRevisionConflict) {
			return nil, ErrPostRevisionConflict
		}
		return nil, fmt.Errorf("review community post: %w", err)
	}

	updated, err := u.repo.GetPostByID(ctx, postID)
	if err != nil {
		return nil, fmt.Errorf("get reviewed community post: %w", err)
	}
	if updated == nil || updated.DeletedAt != nil || updated.CommunityID == nil || *updated.CommunityID != input.CommunityID {
		return nil, ErrPostNotFound
	}

	views, err := u.buildPostViews(ctx, []*model.Post{updated}, &actorUserID)
	if err != nil {
		return nil, err
	}
	if len(views) == 0 {
		return nil, ErrPostNotFound
	}
	return views[0], nil
}

func (u *PostUseCase) ListCommunityPostModerationDecisions(ctx context.Context, subject string, input ListCommunityPostModerationDecisionsInput) ([]*model.PostModerationDecision, error) {
	actorUserID, err := u.requireUserID(ctx, subject)
	if err != nil {
		return nil, err
	}
	if input.PostID == uuid.Nil {
		return nil, ErrInvalidPostID
	}
	if err = u.requireCommunityModerator(ctx, actorUserID, input.CommunityID); err != nil {
		return nil, err
	}

	post, err := u.repo.GetPostByID(ctx, input.PostID)
	if err != nil {
		return nil, fmt.Errorf("get post for moderation decision hipost: %w", err)
	}
	if post == nil || post.DeletedAt != nil || post.CommunityID == nil || *post.CommunityID != input.CommunityID {
		return nil, ErrPostNotFound
	}

	limit := input.Limit
	if limit <= 0 {
		limit = defaultListLimit
	}
	if limit > maxListLimit {
		limit = maxListLimit
	}
	offset := input.Offset
	if offset < 0 {
		offset = 0
	}

	items, err := u.repo.ListCommunityPostModerationDecisions(ctx, model.PostModerationDecisionListFilter{
		CommunityID: input.CommunityID,
		PostID:      input.PostID,
		Limit:       limit,
		Offset:      offset,
	})
	if err != nil {
		return nil, fmt.Errorf("list community post moderation decisions: %w", err)
	}
	return items, nil
}

func (u *PostUseCase) SubmitPostReport(ctx context.Context, subject string, postID uuid.UUID, input SubmitPostReportInput) (*PostReportView, error) {
	reporterUserID, err := u.requireUserID(ctx, subject)
	if err != nil {
		return nil, err
	}
	if postID == uuid.Nil {
		return nil, ErrInvalidPostID
	}

	post, err := u.repo.GetPostByID(ctx, postID)
	if err != nil {
		return nil, fmt.Errorf("get report post: %w", err)
	}
	if post == nil || post.DeletedAt != nil || !post.IsPubliclyVisible() {
		return nil, ErrPostNotFound
	}
	if post.IsOwnedBy(reporterUserID) {
		return nil, ErrPostReportOwnContent
	}

	reason := enum.NormalizePostReportReason(enum.PostReportReason(input.Reason))
	if !reason.IsValid() {
		return nil, ErrInvalidPostReportReason
	}
	details := strings.TrimSpace(input.Details)
	if utf8.RuneCountInString(details) > maxPostReportDetailsChars {
		return nil, ErrInvalidPostReportDetails
	}

	report := model.NewPostReport(model.NewPostReportParams{
		PostID:         post.ID,
		CommunityID:    post.CommunityID,
		ReporterUserID: reporterUserID,
		AuthorUserID:   post.AuthorUserID,
		Reason:         reason,
		Details:        details,
	})

	result, err := u.repo.CreatePostReport(ctx, report, defaultPostReportAutoHideThreshold)
	if err != nil {
		return nil, fmt.Errorf("create post report: %w", err)
	}
	if result == nil {
		result = &model.PostReportSubmissionResult{Report: report, Post: post}
	}
	if err = u.trackPostReportNegativeFeedSignal(ctx, reporterUserID, post, reason); err != nil {
		return nil, err
	}

	return &PostReportView{
		Report:           result.Report,
		Post:             result.Post,
		OpenReportsCount: result.OpenReportsCount,
		AutoHidden:       result.AutoHidden,
	}, nil
}

func (u *PostUseCase) trackPostReportNegativeFeedSignal(ctx context.Context, reporterUserID uuid.UUID, post *model.Post, reason enum.PostReportReason) error {
	if post == nil || post.ID == uuid.Nil || reporterUserID == uuid.Nil {
		return nil
	}
	now := time.Now().UTC()
	metadata := postFeedMetadata("post_report", post)
	if strings.TrimSpace(string(reason)) != "" {
		metadata["reason"] = string(reason)
	}
	event := model.FeedEvent{
		ID:           uuid.New(),
		EventID:      uuid.New(),
		ViewerUserID: &reporterUserID,
		EventType:    model.FeedEventTypeReport,
		Surface:      "content",
		Tab:          "for_you",
		BlockID:      "post:" + post.ID.String(),
		BlockType:    model.FeedBlockTypePostCard,
		PostID:       &post.ID,
		CommunityID:  copyUUIDPtr(post.CommunityID),
		Rank:         0,
		OccurredAt:   now,
		ReceivedAt:   now,
		Metadata:     metadata,
	}
	if err := u.repo.CreateFeedEvents(ctx, []model.FeedEvent{event}); err != nil {
		return fmt.Errorf("track post report feed signal: %w", err)
	}
	u.bumpPostFeedCacheScopes(
		ctx,
		postFeedCacheViewerScope(reporterUserID),
		postFeedCacheFollowingScope(reporterUserID),
		postFeedCacheDiscoveryScope(reporterUserID),
	)
	return nil
}

func (u *PostUseCase) trackPostPositiveFeedSignal(ctx context.Context, viewerUserID uuid.UUID, post *model.Post, eventType string) error {
	if post == nil || post.ID == uuid.Nil || viewerUserID == uuid.Nil {
		return nil
	}
	eventType = strings.TrimSpace(eventType)
	if eventType != model.FeedEventTypeLike && eventType != model.FeedEventTypeComment {
		return nil
	}
	now := time.Now().UTC()
	metadata := postFeedMetadata("post_interaction", post)
	metadata["engagementType"] = eventType
	event := model.FeedEvent{
		ID:           uuid.New(),
		EventID:      uuid.New(),
		ViewerUserID: &viewerUserID,
		EventType:    eventType,
		Surface:      "content",
		Tab:          "for_you",
		BlockID:      "post:" + post.ID.String(),
		BlockType:    model.FeedBlockTypePostCard,
		PostID:       &post.ID,
		CommunityID:  copyUUIDPtr(post.CommunityID),
		Rank:         0,
		OccurredAt:   now,
		ReceivedAt:   now,
		Metadata:     metadata,
	}
	if err := u.repo.CreateFeedEvents(ctx, []model.FeedEvent{event}); err != nil {
		return fmt.Errorf("track post %s feed signal: %w", eventType, err)
	}
	return nil
}

func (u *PostUseCase) trackCommunityNegativeFeedSignal(ctx context.Context, userID uuid.UUID, communityID uuid.UUID, source string, reason string) error {
	if userID == uuid.Nil || communityID == uuid.Nil {
		return nil
	}
	now := time.Now().UTC()
	metadata := map[string]any{
		"entityType": model.FeedInterestEntityTypeCommunity,
		"entityId":   communityID.String(),
		"source":     source,
	}
	if strings.TrimSpace(reason) != "" {
		metadata["reason"] = strings.TrimSpace(reason)
	}
	event := model.FeedEvent{
		ID:           uuid.New(),
		EventID:      uuid.New(),
		ViewerUserID: &userID,
		EventType:    model.FeedEventTypeHide,
		Surface:      "content",
		Tab:          "for_you",
		BlockID:      "community:" + communityID.String(),
		BlockType:    model.FeedBlockTypeSuggestedCommunities,
		CommunityID:  &communityID,
		Rank:         0,
		OccurredAt:   now,
		ReceivedAt:   now,
		Metadata:     metadata,
	}
	if err := u.repo.CreateFeedEvents(ctx, []model.FeedEvent{event}); err != nil {
		return fmt.Errorf("track community negative feed signal: %w", err)
	}
	return nil
}

func postFeedMetadata(source string, post *model.Post) map[string]any {
	metadata := map[string]any{
		"source": source,
	}
	if post == nil {
		return metadata
	}
	if post.CommunityID != nil && *post.CommunityID != uuid.Nil {
		metadata["communityId"] = post.CommunityID.String()
	}
	if post.PostProfileKey != "" {
		metadata["postProfileKey"] = string(post.PostProfileKey)
	}
	if post.Category != "" {
		metadata["category"] = string(post.Category)
	}
	if post.PlaceCityID != nil && strings.TrimSpace(*post.PlaceCityID) != "" {
		metadata["cityId"] = strings.TrimSpace(*post.PlaceCityID)
	}
	if post.PlaceCountryCode != nil && strings.TrimSpace(*post.PlaceCountryCode) != "" {
		metadata["countryCode"] = strings.TrimSpace(*post.PlaceCountryCode)
	}
	if len(post.Tags) > 0 {
		metadata["tags"] = append([]string(nil), post.Tags...)
	}
	return metadata
}

func (u *PostUseCase) ListCommunityPostReports(ctx context.Context, subject string, input ListCommunityPostReportsInput) ([]*model.PostReport, error) {
	actorUserID, err := u.requireUserID(ctx, subject)
	if err != nil {
		return nil, err
	}
	if input.CommunityID == uuid.Nil {
		return nil, ErrInvalidCommunityID
	}
	if err = u.requireCommunityModerator(ctx, actorUserID, input.CommunityID); err != nil {
		return nil, err
	}

	var status *enum.PostReportStatus
	if strings.TrimSpace(input.Status) != "" {
		normalized := enum.NormalizePostReportStatus(enum.PostReportStatus(input.Status))
		if !normalized.IsValid() {
			return nil, ErrInvalidPostReportStatus
		}
		status = &normalized
	}

	limit := input.Limit
	if limit <= 0 {
		limit = defaultListLimit
	}
	if limit > maxListLimit {
		limit = maxListLimit
	}
	offset := input.Offset
	if offset < 0 {
		offset = 0
	}

	return u.repo.ListCommunityPostReports(ctx, model.PostReportListFilter{
		CommunityID: input.CommunityID,
		Status:      status,
		Limit:       limit,
		Offset:      offset,
	})
}

func (u *PostUseCase) ResolveCommunityPostReport(ctx context.Context, subject string, input ResolveCommunityPostReportInput) (*model.PostReport, error) {
	actorUserID, err := u.requireUserID(ctx, subject)
	if err != nil {
		return nil, err
	}
	if input.CommunityID == uuid.Nil {
		return nil, ErrInvalidCommunityID
	}
	if input.ReportID == uuid.Nil {
		return nil, ErrPostReportNotFound
	}
	if err = u.requireCommunityModerator(ctx, actorUserID, input.CommunityID); err != nil {
		return nil, err
	}

	status, err := postReportStatusForResolutionDecision(input.Decision)
	if err != nil {
		return nil, err
	}
	note := strings.TrimSpace(input.ResolutionNote)
	if utf8.RuneCountInString(note) > maxPostReportResolutionNoteChars {
		return nil, ErrInvalidPostReportResolution
	}

	resolved, err := u.repo.ResolvePostReport(ctx, &model.PostReportResolution{
		ReportID:         input.ReportID,
		CommunityID:      input.CommunityID,
		Status:           status,
		ResolvedByUserID: actorUserID,
		ResolutionNote:   note,
		ResolvedAt:       time.Now().UTC(),
	})
	if err != nil {
		switch {
		case errors.Is(err, port.ErrPostReportNotFound):
			return nil, ErrPostReportNotFound
		case errors.Is(err, port.ErrPostReportAlreadyResolved):
			return nil, ErrPostReportAlreadyResolved
		default:
			return nil, fmt.Errorf("resolve post report: %w", err)
		}
	}
	if resolved == nil {
		return nil, ErrPostReportNotFound
	}

	return resolved, nil
}

func (u *PostUseCase) ListAdminPostReports(ctx context.Context, input ListAdminPostReportsInput) ([]*model.PostReport, error) {
	var status *enum.PostReportStatus
	if strings.TrimSpace(input.Status) != "" {
		normalized := enum.NormalizePostReportStatus(enum.PostReportStatus(input.Status))
		if !normalized.IsValid() {
			return nil, ErrInvalidPostReportStatus
		}
		status = &normalized
	}

	limit := input.Limit
	if limit <= 0 {
		limit = defaultListLimit
	}
	if limit > maxListLimit {
		limit = maxListLimit
	}
	offset := input.Offset
	if offset < 0 {
		offset = 0
	}

	return u.repo.ListCommunityPostReports(ctx, model.PostReportListFilter{
		Status: status,
		Limit:  limit,
		Offset: offset,
	})
}

func (u *PostUseCase) GetAdminPostReport(ctx context.Context, reportID uuid.UUID) (*model.PostReport, error) {
	if reportID == uuid.Nil {
		return nil, ErrPostReportNotFound
	}
	item, err := u.repo.GetPostReport(ctx, reportID)
	if err != nil {
		if errors.Is(err, port.ErrPostReportNotFound) {
			return nil, ErrPostReportNotFound
		}
		return nil, fmt.Errorf("get post report: %w", err)
	}
	if item == nil {
		return nil, ErrPostReportNotFound
	}
	return item, nil
}

func (u *PostUseCase) ListAdminCommunityModerationPosts(ctx context.Context, input ListAdminCommunityModerationPostsInput) ([]*PostView, error) {
	limit := input.Limit
	if limit <= 0 {
		limit = defaultListLimit
	}
	if limit > maxListLimit {
		limit = maxListLimit
	}
	offset := input.Offset
	if offset < 0 {
		offset = 0
	}

	status := enum.PostStatusPublished
	items, err := u.repo.ListPosts(ctx, model.PostListFilter{
		Status:             &status,
		ModerationStatuses: []enum.ModerationStatus{enum.ModerationStatusPending},
		OnlyCommunityPosts: true,
		ExcludeArchived:    true,
		Sort:               "latest_desc",
		Limit:              limit,
		Offset:             offset,
	})
	if err != nil {
		return nil, fmt.Errorf("list admin community moderation posts: %w", err)
	}

	return u.buildPostViews(ctx, items, nil)
}

func (u *PostUseCase) GetAdminCommunityModerationPost(ctx context.Context, postID uuid.UUID) (*PostView, error) {
	if postID == uuid.Nil {
		return nil, ErrInvalidPostID
	}
	post, err := u.repo.GetPostByID(ctx, postID)
	if err != nil {
		return nil, fmt.Errorf("get admin community moderation post: %w", err)
	}
	if post == nil || post.DeletedAt != nil || post.CommunityID == nil {
		return nil, ErrPostNotFound
	}
	views, err := u.buildPostViews(ctx, []*model.Post{post}, nil)
	if err != nil {
		return nil, err
	}
	if len(views) == 0 {
		return nil, ErrPostNotFound
	}
	return views[0], nil
}

func (u *PostUseCase) ReviewAdminCommunityPost(ctx context.Context, input ReviewAdminCommunityPostInput) (*PostView, error) {
	if input.ActorStaffID == uuid.Nil {
		return nil, ErrUnauthenticatedWriter
	}
	if input.PostID == uuid.Nil {
		return nil, ErrInvalidPostID
	}
	decision, nextStatus, err := moderationDecisionForReviewInput(input.Decision)
	if err != nil {
		return nil, err
	}

	post, err := u.repo.GetPostByID(ctx, input.PostID)
	if err != nil {
		return nil, fmt.Errorf("get admin community post for review: %w", err)
	}
	if post == nil || post.DeletedAt != nil || post.CommunityID == nil {
		return nil, ErrPostNotFound
	}
	if post.Status != enum.PostStatusPublished ||
		post.ArchivedAt != nil ||
		post.ModerationStatus != enum.ModerationStatusPending {
		return nil, ErrInvalidPostStatus
	}

	now := time.Now().UTC()
	previousStatus := post.ModerationStatus
	post.ModerationStatus = nextStatus
	post.UpdatedAt = now
	moderationDecision := &model.PostModerationDecision{
		ID:              uuid.New(),
		PostID:          post.ID,
		CommunityID:     *post.CommunityID,
		ModeratorUserID: input.ActorStaffID,
		Decision:        decision,
		PreviousStatus:  previousStatus,
		NextStatus:      nextStatus,
		PostRevision:    post.Revision,
		Reason:          strings.TrimSpace(input.Reason),
		CreatedAt:       now,
	}
	if err = u.repo.ReviewCommunityPost(ctx, post, moderationDecision); err != nil {
		if errors.Is(err, port.ErrPostRevisionConflict) {
			return nil, ErrPostRevisionConflict
		}
		return nil, fmt.Errorf("review admin community post: %w", err)
	}

	return u.GetAdminCommunityModerationPost(ctx, input.PostID)
}

func (u *PostUseCase) ResolveAdminPostReport(ctx context.Context, input ResolveAdminPostReportInput) (*model.PostReport, error) {
	if input.ActorStaffID == uuid.Nil {
		return nil, ErrUnauthenticatedWriter
	}
	if input.ReportID == uuid.Nil {
		return nil, ErrPostReportNotFound
	}
	status, err := postReportStatusForResolutionDecision(input.Decision)
	if err != nil {
		return nil, err
	}
	note := strings.TrimSpace(input.ResolutionNote)
	if utf8.RuneCountInString(note) > maxPostReportResolutionNoteChars {
		return nil, ErrInvalidPostReportResolution
	}

	resolved, err := u.repo.ResolvePostReport(ctx, &model.PostReportResolution{
		ReportID:         input.ReportID,
		Status:           status,
		ResolvedByUserID: input.ActorStaffID,
		ResolutionNote:   note,
		ResolvedAt:       time.Now().UTC(),
	})
	if err != nil {
		switch {
		case errors.Is(err, port.ErrPostReportNotFound):
			return nil, ErrPostReportNotFound
		case errors.Is(err, port.ErrPostReportAlreadyResolved):
			return nil, ErrPostReportAlreadyResolved
		default:
			return nil, fmt.Errorf("resolve post report: %w", err)
		}
	}
	if resolved == nil {
		return nil, ErrPostReportNotFound
	}

	return resolved, nil
}

func relatedPostsFilterFor(post *model.Post) model.PostListFilter {
	if post == nil {
		return model.PostListFilter{
			OnlyPublished: true,
			Limit:         defaultRelatedLimit,
			Sort:          "popular_desc",
		}
	}

	filter := model.PostListFilter{
		ExcludePostID: &post.ID,
		OnlyPublished: true,
		Limit:         defaultRelatedLimit,
		Offset:        0,
		Sort:          "related",
		RelatedToCountry: strings.ToUpper(
			strings.TrimSpace(derefString(post.PlaceCountryCode)),
		),
		RelatedToCityID: strings.TrimSpace(derefString(post.PlaceCityID)),
		RelatedToTags:   sanitizeRelatedTags(post.Tags),
	}
	if post.AuthorUserID != uuid.Nil {
		filter.RelatedToAuthor = &post.AuthorUserID
	}

	format := enum.NormalizePostFormat(post.Format)
	if format.IsValid() {
		filter.RelatedToFormat = &format
	}
	if post.Category.IsValid() {
		category := post.Category
		filter.RelatedToCategory = &category
	}

	return filter
}

func (u *PostUseCase) CountPublishedPostsByAuthorID(ctx context.Context, authorUserID uuid.UUID) (int, error) {
	if authorUserID == uuid.Nil {
		return 0, ErrInvalidPostAuthorID
	}

	count, err := u.repo.CountPublishedPostsByAuthorID(ctx, authorUserID)
	if err != nil {
		return 0, fmt.Errorf("count published posts: %w", err)
	}

	return count, nil
}

func (u *PostUseCase) TrackPostView(ctx context.Context, subject string, postID uuid.UUID) (int, error) {
	viewerUserID, err := u.requireUserID(ctx, subject)
	if err != nil {
		return 0, err
	}
	if postID == uuid.Nil {
		return 0, ErrInvalidPostID
	}

	post, err := u.repo.GetPostByID(ctx, postID)
	if err != nil {
		return 0, fmt.Errorf("get post for view: %w", err)
	}
	if post == nil || !post.IsPubliclyVisible() {
		return 0, ErrPostNotFound
	}
	if post.IsOwnedBy(viewerUserID) {
		return post.ViewCount, nil
	}

	_, count, err := u.repo.TrackPostView(ctx, postID, viewerUserID)
	if err != nil {
		return 0, fmt.Errorf("track post view: %w", err)
	}

	return count, nil
}

func (u *PostUseCase) MarkPostSeen(ctx context.Context, subject string, postID uuid.UUID) (time.Time, error) {
	viewerUserID, err := u.requireUserID(ctx, subject)
	if err != nil {
		return time.Time{}, err
	}
	if postID == uuid.Nil {
		return time.Time{}, ErrInvalidPostID
	}

	post, err := u.repo.GetPostByID(ctx, postID)
	if err != nil {
		return time.Time{}, fmt.Errorf("get post for seen marker: %w", err)
	}
	if post == nil || !post.IsPubliclyVisible() {
		return time.Time{}, ErrPostNotFound
	}

	seenAt := time.Now().UTC().Truncate(time.Second)
	storedSeenAt, err := u.repo.MarkPostSeen(ctx, postID, viewerUserID, seenAt)
	if err != nil {
		return time.Time{}, fmt.Errorf("mark post seen: %w", err)
	}
	return storedSeenAt.UTC(), nil
}

func (u *PostUseCase) MarkStorySeen(ctx context.Context, subject string, storyID uuid.UUID) (time.Time, error) {
	viewerUserID, err := u.requireUserID(ctx, subject)
	if err != nil {
		return time.Time{}, err
	}
	if storyID == uuid.Nil {
		return time.Time{}, ErrInvalidPostID
	}

	stories, err := u.repo.ListStories(ctx, model.StoryListFilter{
		StoryID:      &storyID,
		ViewerUserID: &viewerUserID,
		Limit:        1,
	})
	if err != nil {
		return time.Time{}, fmt.Errorf("list stories before seen marker: %w", err)
	}
	found := false
	for _, story := range stories {
		if story != nil && story.ID == storyID {
			found = true
			break
		}
	}
	if !found {
		return time.Time{}, ErrStoryNotFound
	}

	seenAt := time.Now().UTC().Truncate(time.Second)
	storedSeenAt, err := u.repo.MarkStorySeen(ctx, storyID, viewerUserID, seenAt)
	if err != nil {
		return time.Time{}, fmt.Errorf("mark story seen: %w", err)
	}
	return storedSeenAt.UTC(), nil
}

func (u *PostUseCase) LikeStory(ctx context.Context, subject string, storyID uuid.UUID) (int, error) {
	viewerUserID, err := u.requireUserID(ctx, subject)
	if err != nil {
		return 0, err
	}
	if storyID == uuid.Nil {
		return 0, ErrInvalidPostID
	}

	stories, err := u.repo.ListStories(ctx, model.StoryListFilter{
		StoryID:      &storyID,
		ViewerUserID: &viewerUserID,
		Limit:        1,
	})
	if err != nil {
		return 0, fmt.Errorf("list stories before like: %w", err)
	}
	var story *model.Story
	for _, item := range stories {
		if item != nil && item.ID == storyID {
			story = item
			break
		}
	}
	if story == nil {
		return 0, ErrStoryNotFound
	}
	if story.IsOwnedBy(viewerUserID) {
		return 0, ErrCannotLikeOwnStory
	}

	changed, count, err := u.repo.LikeStory(ctx, storyID, viewerUserID)
	if err != nil {
		return 0, fmt.Errorf("like story: %w", err)
	}
	if changed {
		u.notifyStoryLiked(ctx, story, viewerUserID)
	}

	return count, nil
}

func (u *PostUseCase) LikePost(ctx context.Context, subject string, postID uuid.UUID) (int, error) {
	viewerUserID, err := u.requireUserID(ctx, subject)
	if err != nil {
		return 0, err
	}
	if postID == uuid.Nil {
		return 0, ErrInvalidPostID
	}

	post, err := u.repo.GetPostByID(ctx, postID)
	if err != nil {
		return 0, fmt.Errorf("get post for like: %w", err)
	}
	if post == nil || !post.IsPubliclyVisible() {
		return 0, ErrPostNotFound
	}
	if err = u.ensureCommunityInteractionAllowed(ctx, viewerUserID, post); err != nil {
		return 0, err
	}

	changed, count, err := u.repo.LikePost(ctx, postID, viewerUserID)
	if err != nil {
		return 0, fmt.Errorf("like post: %w", err)
	}
	if changed {
		// Feed ranking signals are secondary; the user-facing like has already succeeded.
		_ = u.trackPostPositiveFeedSignal(ctx, viewerUserID, post, model.FeedEventTypeLike)
		u.notifyPostLiked(ctx, post, viewerUserID)
	}

	return count, nil
}

func (u *PostUseCase) UnlikePost(ctx context.Context, subject string, postID uuid.UUID) (int, error) {
	viewerUserID, err := u.requireUserID(ctx, subject)
	if err != nil {
		return 0, err
	}
	if postID == uuid.Nil {
		return 0, ErrInvalidPostID
	}

	post, err := u.repo.GetPostByID(ctx, postID)
	if err != nil {
		return 0, fmt.Errorf("get post for unlike: %w", err)
	}
	if post == nil || !post.IsPubliclyVisible() {
		return 0, ErrPostNotFound
	}

	_, count, err := u.repo.UnlikePost(ctx, postID, viewerUserID)
	if err != nil {
		return 0, fmt.Errorf("unlike post: %w", err)
	}

	return count, nil
}

func (u *PostUseCase) ListComments(ctx context.Context, subject string, postID uuid.UUID, limit int, offset int) ([]*PostCommentView, error) {
	if postID == uuid.Nil {
		return nil, ErrInvalidPostID
	}

	viewerUserID, err := u.optionalUserID(ctx, subject)
	if err != nil {
		return nil, err
	}

	post, err := u.repo.GetPostByID(ctx, postID)
	if err != nil {
		return nil, fmt.Errorf("get post for comments: %w", err)
	}
	if post == nil || post.DeletedAt != nil {
		return nil, ErrPostNotFound
	}
	if !post.IsPubliclyVisible() && (viewerUserID == nil || !post.IsOwnedBy(*viewerUserID)) {
		return nil, ErrPostNotFound
	}

	if limit <= 0 || limit > maxListLimit {
		limit = defaultCommentLimit
	}
	if offset < 0 {
		offset = 0
	}

	items, err := u.repo.ListComments(ctx, postID, limit, offset)
	if err != nil {
		return nil, fmt.Errorf("list comments: %w", err)
	}

	return u.buildCommentViews(ctx, post, items, viewerUserID)
}

func (u *PostUseCase) CreateComment(ctx context.Context, subject string, postID uuid.UUID, body string) (*PostCommentView, error) {
	authorUserID, err := u.requireUserID(ctx, subject)
	if err != nil {
		return nil, err
	}
	if postID == uuid.Nil {
		return nil, ErrInvalidPostID
	}

	post, err := u.repo.GetPostByID(ctx, postID)
	if err != nil {
		return nil, fmt.Errorf("get post for comment: %w", err)
	}
	if post == nil || !post.IsPubliclyVisible() {
		return nil, ErrPostNotFound
	}
	if err = u.ensureCommunityInteractionAllowed(ctx, authorUserID, post); err != nil {
		return nil, err
	}

	body = strings.TrimSpace(body)
	if body == "" || utf8.RuneCountInString(body) > maxCommentBodyChars {
		return nil, ErrInvalidCommentBody
	}

	now := time.Now().UTC()
	comment := &model.PostComment{
		ID:           uuid.New(),
		PostID:       postID,
		AuthorUserID: authorUserID,
		Body:         body,
		CreatedAt:    now,
		UpdatedAt:    now,
	}

	if err = u.repo.CreateComment(ctx, comment, now.Add(-commentCreateWindow)); err != nil {
		if errors.Is(err, port.ErrPostCommentRateLimited) {
			return nil, ErrPostCommentRateLimited
		}
		return nil, fmt.Errorf("create comment: %w", err)
	}
	if err = u.trackPostPositiveFeedSignal(ctx, authorUserID, post, model.FeedEventTypeComment); err != nil {
		return nil, err
	}

	views, err := u.buildCommentViews(ctx, post, []*model.PostComment{comment}, &authorUserID)
	if err != nil {
		return nil, err
	}
	return views[0], nil
}

func (u *PostUseCase) UpdateComment(ctx context.Context, subject string, postID uuid.UUID, commentID uuid.UUID, body string) (*PostCommentView, error) {
	actorUserID, err := u.requireUserID(ctx, subject)
	if err != nil {
		return nil, err
	}
	if postID == uuid.Nil {
		return nil, ErrInvalidPostID
	}
	if commentID == uuid.Nil {
		return nil, ErrInvalidCommentID
	}

	comment, err := u.repo.GetCommentByID(ctx, postID, commentID)
	if err != nil {
		return nil, fmt.Errorf("get comment: %w", err)
	}
	if comment == nil || comment.DeletedAt != nil {
		return nil, ErrPostCommentNotFound
	}
	if !comment.IsOwnedBy(actorUserID) {
		return nil, ErrPostCommentAccessDenied
	}

	body = strings.TrimSpace(body)
	if body == "" || utf8.RuneCountInString(body) > maxCommentBodyChars {
		return nil, ErrInvalidCommentBody
	}

	comment.Body = body
	comment.UpdatedAt = time.Now().UTC()

	if err = u.repo.UpdateComment(ctx, comment); err != nil {
		return nil, fmt.Errorf("update comment: %w", err)
	}

	post, err := u.repo.GetPostByID(ctx, postID)
	if err != nil {
		return nil, fmt.Errorf("get post for comment update: %w", err)
	}

	views, err := u.buildCommentViews(ctx, post, []*model.PostComment{comment}, &actorUserID)
	if err != nil {
		return nil, err
	}
	return views[0], nil
}

func (u *PostUseCase) DeleteComment(ctx context.Context, subject string, postID uuid.UUID, commentID uuid.UUID) error {
	actorUserID, err := u.requireUserID(ctx, subject)
	if err != nil {
		return err
	}
	if postID == uuid.Nil {
		return ErrInvalidPostID
	}
	if commentID == uuid.Nil {
		return ErrInvalidCommentID
	}

	post, err := u.repo.GetPostByID(ctx, postID)
	if err != nil {
		return fmt.Errorf("get post for comment delete: %w", err)
	}
	if post == nil || post.DeletedAt != nil {
		return ErrPostNotFound
	}

	comment, err := u.repo.GetCommentByID(ctx, postID, commentID)
	if err != nil {
		return fmt.Errorf("get comment for delete: %w", err)
	}
	if comment == nil || comment.DeletedAt != nil {
		return ErrPostCommentNotFound
	}
	if !comment.IsOwnedBy(actorUserID) {
		return ErrPostCommentAccessDenied
	}

	if _, err = u.repo.DeleteComment(ctx, postID, commentID); err != nil {
		return fmt.Errorf("delete comment: %w", err)
	}

	return nil
}

func (u *PostUseCase) LikeComment(ctx context.Context, subject string, postID uuid.UUID, commentID uuid.UUID) (int, bool, error) {
	viewerUserID, err := u.requireUserID(ctx, subject)
	if err != nil {
		return 0, false, err
	}
	if postID == uuid.Nil {
		return 0, false, ErrInvalidPostID
	}
	if commentID == uuid.Nil {
		return 0, false, ErrInvalidCommentID
	}

	post, err := u.repo.GetPostByID(ctx, postID)
	if err != nil {
		return 0, false, fmt.Errorf("get post for comment like: %w", err)
	}
	if post == nil || !post.IsPubliclyVisible() {
		return 0, false, ErrPostNotFound
	}
	if err = u.ensureCommunityInteractionAllowed(ctx, viewerUserID, post); err != nil {
		return 0, false, err
	}

	comment, err := u.repo.GetCommentByID(ctx, postID, commentID)
	if err != nil {
		return 0, false, fmt.Errorf("get comment for like: %w", err)
	}
	if comment == nil || comment.DeletedAt != nil {
		return 0, false, ErrPostCommentNotFound
	}

	_, count, err := u.repo.LikeComment(ctx, postID, commentID, viewerUserID)
	if err != nil {
		return 0, false, fmt.Errorf("like comment: %w", err)
	}

	return count, true, nil
}

func (u *PostUseCase) UnlikeComment(ctx context.Context, subject string, postID uuid.UUID, commentID uuid.UUID) (int, bool, error) {
	viewerUserID, err := u.requireUserID(ctx, subject)
	if err != nil {
		return 0, false, err
	}
	if postID == uuid.Nil {
		return 0, false, ErrInvalidPostID
	}
	if commentID == uuid.Nil {
		return 0, false, ErrInvalidCommentID
	}

	post, err := u.repo.GetPostByID(ctx, postID)
	if err != nil {
		return 0, false, fmt.Errorf("get post for comment unlike: %w", err)
	}
	if post == nil || !post.IsPubliclyVisible() {
		return 0, false, ErrPostNotFound
	}

	comment, err := u.repo.GetCommentByID(ctx, postID, commentID)
	if err != nil {
		return 0, false, fmt.Errorf("get comment for unlike: %w", err)
	}
	if comment == nil || comment.DeletedAt != nil {
		return 0, false, ErrPostCommentNotFound
	}

	_, count, err := u.repo.UnlikeComment(ctx, postID, commentID, viewerUserID)
	if err != nil {
		return 0, false, fmt.Errorf("unlike comment: %w", err)
	}

	return count, false, nil
}

func (u *PostUseCase) SharePost(ctx context.Context, postID uuid.UUID) (string, int, error) {
	if postID == uuid.Nil {
		return "", 0, ErrInvalidPostID
	}

	post, err := u.repo.GetPostByID(ctx, postID)
	if err != nil {
		return "", 0, fmt.Errorf("get post for share: %w", err)
	}
	if post == nil || !post.IsPubliclyVisible() {
		return "", 0, ErrPostNotFound
	}

	count, err := u.repo.IncrementShareCount(ctx, postID)
	if err != nil {
		return "", 0, fmt.Errorf("increment share count: %w", err)
	}

	return u.shareURL(post.Slug), count, nil
}

func (u *PostUseCase) normalizeListInput(input ListPostsInput, viewerUserID *uuid.UUID) (model.PostListFilter, error) {
	placeQuery, placeCountryCode := normalizePlaceFilters(input.Place)
	if explicitCountryCode := normalizeCountryCode(input.CountryCode); explicitCountryCode != "" {
		placeCountryCode = explicitCountryCode
	}

	filter := model.PostListFilter{
		Search:           strings.TrimSpace(input.Search),
		PlaceQuery:       placeQuery,
		PlaceCountryCode: placeCountryCode,
		PlaceCityID:      strings.TrimSpace(input.CityID),
		AuthorUserID:     input.AuthorID,
		ViewerUserID:     viewerUserID,
		CommunityIDs:     nullableUUIDSlice(input.CommunityID),
		IncludeDrafts:    false,
		OnlyPublished:    true,
		Limit:            input.Limit,
		Offset:           input.Offset,
	}

	if filter.Limit <= 0 {
		filter.Limit = defaultListLimit
	}
	if filter.Limit > maxListLimit {
		filter.Limit = maxListLimit
	}
	if filter.Offset < 0 {
		filter.Offset = 0
	}

	switch strings.ToLower(strings.TrimSpace(input.Sort)) {
	case "", "latest", "latest_desc":
		filter.Sort = "latest_desc"
	case "latest_asc":
		filter.Sort = "latest_asc"
	case "popular", "popular_desc":
		filter.Sort = "popular_desc"
	case "popular_asc":
		filter.Sort = "popular_asc"
	case "discussed", "discussed_desc":
		filter.Sort = "discussed_desc"
	case "discussed_asc":
		filter.Sort = "discussed_asc"
	default:
		filter.Sort = "latest_desc"
	}

	filter.Formats = make([]enum.PostFormat, 0, len(input.Format))
	for _, raw := range input.Format {
		format := enum.NormalizePostFormat(enum.PostFormat(raw))
		if strings.TrimSpace(raw) == "" {
			continue
		}
		if !format.IsValid() || format == enum.PostFormatPost {
			return model.PostListFilter{}, ErrInvalidPostFormat
		}
		filter.Formats = append(filter.Formats, format)
	}
	if len(filter.Formats) == 0 {
		filter.Formats = defaultPostListFormats(input)
	}
	filter.ExcludeExpiring = true

	filter.Categories = make([]enum.PostCategory, 0, len(input.Category))
	for _, raw := range input.Category {
		category := enum.PostCategory(strings.ToUpper(strings.TrimSpace(raw)))
		if category == "" {
			continue
		}
		if !category.IsValid() {
			return model.PostListFilter{}, ErrInvalidPostCategory
		}
		filter.Categories = append(filter.Categories, category)
	}

	filter.ModerationStatuses = make([]enum.ModerationStatus, 0, len(input.ModerationStatus))
	for _, raw := range input.ModerationStatus {
		status := enum.NormalizeModerationStatus(enum.ModerationStatus(raw))
		if strings.TrimSpace(raw) == "" {
			continue
		}
		if !status.IsValid() {
			return model.PostListFilter{}, ErrInvalidPostStatus
		}
		filter.ModerationStatuses = append(filter.ModerationStatuses, status)
	}

	if input.IncludeMine {
		if viewerUserID == nil || *viewerUserID == uuid.Nil {
			return model.PostListFilter{}, ErrUnauthenticatedWriter
		}
		filter.AuthorUserID = viewerUserID
		filter.IncludeDrafts = true
		filter.OnlyPublished = false
		filter.ExcludeArchived = true
	}

	switch strings.ToUpper(strings.TrimSpace(input.Status)) {
	case "":
	case "ARCHIVED":
		filter.ArchivedOnly = true
		filter.ExcludeArchived = false
		if input.IncludeMine {
			filter.OnlyPublished = false
		}
	case string(enum.PostStatusDraft):
		status := enum.PostStatusDraft
		filter.Status = &status
		if input.IncludeMine {
			filter.OnlyPublished = false
		}
	case string(enum.PostStatusPublished):
		status := enum.PostStatusPublished
		filter.Status = &status
	default:
		return model.PostListFilter{}, ErrInvalidPostStatus
	}

	return filter, nil
}

func defaultPostListFormats(input ListPostsInput) []enum.PostFormat {
	formats := make([]enum.PostFormat, 0, len(postPostFormats)+1)
	formats = append(formats, postPostFormats...)
	if input.IncludeMine || input.CommunityID != nil {
		formats = append(formats, enum.PostFormatPost)
	}
	return formats
}

func validatePostPostInput(input CreatePostInput) error {
	format := enum.NormalizePostFormat(input.Format)
	profileKey := enum.NormalizePostProfileKey(input.PostProfileKey)
	profileAllowsPostFormat := profileKey.IsValid() && profileKey != enum.PostProfileArticleV1
	if format == enum.PostFormatPost && !profileAllowsPostFormat {
		return ErrInvalidPostFormat
	}
	if input.ExpiresAt != nil {
		return ErrInvalidPostFormat
	}
	return nil
}

func storyContentBlocks(fileID uuid.UUID, mediaType enum.PostMediaType, caption string) json.RawMessage {
	blocks := []model.PostBlock{{
		ID:   "story-caption",
		Type: model.PostBlockTypeParagraph,
		Text: strings.TrimSpace(caption),
	}}
	if mediaType == enum.PostMediaTypeImage {
		blocks = append([]model.PostBlock{{
			ID:     "story-media",
			Type:   model.PostBlockTypeImage,
			FileID: fileID.String(),
		}}, blocks...)
	}
	payload, err := json.Marshal(model.PostDocument{
		Version: model.PostDocumentVersion,
		Blocks:  blocks,
	})
	if err != nil {
		return nil
	}
	return payload
}

func nullableUUIDSlice(value *uuid.UUID) []uuid.UUID {
	if value == nil || *value == uuid.Nil {
		return nil
	}
	return []uuid.UUID{*value}
}

func (u *PostUseCase) updateOwnedPost(
	ctx context.Context,
	subject string,
	postID uuid.UUID,
	revision int64,
	inputForExisting func(*model.Post) (UpdatePostInput, error),
	mutate func(*model.Post, time.Time),
) (*PostView, error) {
	actorUserID, err := u.requireUserID(ctx, subject)
	if err != nil {
		return nil, err
	}
	if postID == uuid.Nil {
		return nil, ErrInvalidPostID
	}

	existing, err := u.repo.GetPostByID(ctx, postID)
	if err != nil {
		return nil, fmt.Errorf("get post: %w", err)
	}
	if existing == nil || existing.DeletedAt != nil {
		return nil, ErrPostNotFound
	}
	if !existing.IsOwnedBy(actorUserID) {
		return nil, ErrPostAccessDenied
	}
	if revision <= 0 {
		return nil, ErrPostRevisionConflict
	}
	if existing.Revision != revision {
		return nil, ErrPostRevisionConflict
	}
	wasNeverPublished := existing.Status != enum.PostStatusPublished && existing.PublishedAt == nil

	input, err := inputForExisting(existing)
	if err != nil {
		return nil, err
	}
	input.Revision = revision

	mergedInput := mergePostUpdateInput(existing, input)
	profile, err := u.resolvePostProfileDefaults(ctx, mergedInput.PostProfileKey)
	if err != nil {
		return nil, err
	}
	next, err := normalizePostInputWithProfile(existing.ID, mergedInput, profile)
	if err != nil {
		return nil, err
	}
	document, err := postDocumentFromNormalizedBlocks(next.ContentBlocks)
	if err != nil {
		return nil, ErrInvalidPostContent
	}
	if err := u.validatePostRouteReferences(ctx, actorUserID, document); err != nil {
		return nil, err
	}

	moderationStatus, err := u.resolvePostModerationStatus(ctx, actorUserID, next, existing.ModerationStatus)
	if err != nil {
		return nil, err
	}

	applyPostUpdate(existing, next, revision, moderationStatus)
	now := time.Now().UTC()
	existing.UpdatedAt = now
	if mutate != nil {
		mutate(existing, now)
	}
	if existing.Status == enum.PostStatusPublished && existing.PublishedAt == nil {
		existing.PublishedAt = &now
	}
	if wasNeverPublished && existing.Status == enum.PostStatusPublished {
		if err := u.ensurePostCreateRateLimit(ctx, actorUserID, now); err != nil {
			return nil, err
		}
	}
	applyPostActivityCreationState(existing, profile)

	mediaPlan, err := buildPostMediaPlan(existing, actorUserID)
	if err != nil {
		return nil, err
	}
	mediaPlan, err = u.bindPostMediaPlan(ctx, mediaPlan)
	if err != nil {
		return nil, err
	}
	applyPostMediaPlan(
		existing,
		mediaPlan,
		enum.PostMediaStatusReady,
		enum.PostMediaProcessingStatusBound,
	)

	if err = u.repo.UpdatePost(ctx, existing); err != nil {
		if errors.Is(err, port.ErrPostRevisionConflict) {
			return nil, ErrPostRevisionConflict
		}
		if rateLimitErr := postRateLimitErrorFromRepository(err, time.Now().UTC()); rateLimitErr != nil {
			return nil, rateLimitErr
		}
		return nil, fmt.Errorf("update post: %w", err)
	}

	u.bumpPostFeedMutationCacheScopes(ctx, existing)
	return u.GetPostByID(ctx, subject, postID)
}

func (u *PostUseCase) resolvePostModerationStatus(ctx context.Context, actorUserID uuid.UUID, post *model.Post, current enum.ModerationStatus) (enum.ModerationStatus, error) {
	if post == nil || post.CommunityID == nil {
		return current, nil
	}

	community, err := u.repo.GetCommunityByID(ctx, *post.CommunityID)
	if err != nil {
		return current, fmt.Errorf("get post community: %w", err)
	}
	if community == nil || !community.IsPubliclyVisible() {
		return current, ErrCommunityNotFound
	}
	if post.Status != enum.PostStatusPublished {
		return current, nil
	}

	membership, err := u.repo.GetCommunityMembership(ctx, community.ID, actorUserID)
	if err != nil {
		return current, fmt.Errorf("get post community membership: %w", err)
	}
	if membership == nil || membership.Status != enum.CommunityMembershipStatusActive {
		return current, ErrCommunityPostingDenied
	}

	return moderationStatusForCommunityPost(community.PostingPolicy, membership.Role, post.ModerationMode)
}

func (u *PostUseCase) requireCommunityModerator(ctx context.Context, actorUserID uuid.UUID, communityID uuid.UUID) error {
	if actorUserID == uuid.Nil {
		return ErrUnauthenticatedWriter
	}
	if communityID == uuid.Nil {
		return ErrInvalidCommunityID
	}

	community, err := u.repo.GetCommunityByID(ctx, communityID)
	if err != nil {
		return fmt.Errorf("get moderation community: %w", err)
	}
	if community == nil || !community.IsPubliclyVisible() {
		return ErrCommunityNotFound
	}

	membership, err := u.repo.GetCommunityMembership(ctx, communityID, actorUserID)
	if err != nil {
		return fmt.Errorf("get moderation community membership: %w", err)
	}
	if membership == nil || membership.Status != enum.CommunityMembershipStatusActive {
		return ErrCommunityModerationDenied
	}
	switch membership.Role {
	case enum.CommunityMembershipRoleModerator, enum.CommunityMembershipRoleAdmin:
		return nil
	default:
		return ErrCommunityModerationDenied
	}
}

func (u *PostUseCase) ensureCommunityInteractionAllowed(ctx context.Context, actorUserID uuid.UUID, post *model.Post) error {
	if post == nil || post.CommunityID == nil {
		return nil
	}

	membership, err := u.repo.GetCommunityMembership(ctx, *post.CommunityID, actorUserID)
	if err != nil {
		return fmt.Errorf("get community interaction membership: %w", err)
	}
	if membership == nil {
		return nil
	}
	switch membership.Status {
	case enum.CommunityMembershipStatusMuted, enum.CommunityMembershipStatusBanned:
		return ErrCommunityInteractionDenied
	default:
		return nil
	}
}

func moderationStatusForCommunityPost(policy enum.CommunityPostingPolicy, role enum.CommunityMembershipRole, mode enum.ModerationMode) (enum.ModerationStatus, error) {
	if err := ensureCommunityPostingAllowed(policy, role); err != nil {
		return enum.ModerationStatusNotRequired, err
	}
	switch role {
	case enum.CommunityMembershipRoleAdmin, enum.CommunityMembershipRoleModerator, enum.CommunityMembershipRoleTrustedMember:
		return enum.ModerationStatusNotRequired, nil
	}

	if policy == enum.CommunityPostingPolicyOpenMembers {
		return enum.ModerationStatusNotRequired, nil
	}

	switch mode {
	case enum.ModerationModePublishFirst, enum.ModerationModePublishFirstWithRiskHold:
		return enum.ModerationStatusNotRequired, nil
	default:
		return enum.ModerationStatusPending, nil
	}
}

func ensureCommunityPostingAllowed(policy enum.CommunityPostingPolicy, role enum.CommunityMembershipRole) error {
	switch role {
	case enum.CommunityMembershipRoleAdmin, enum.CommunityMembershipRoleModerator:
		return nil
	case enum.CommunityMembershipRoleTrustedMember:
		switch policy {
		case enum.CommunityPostingPolicyAdminsOnly:
			return ErrCommunityPostingDenied
		default:
			return nil
		}
	case enum.CommunityMembershipRoleMember:
		switch policy {
		case enum.CommunityPostingPolicyOpenMembers, enum.CommunityPostingPolicyMembersAfterModeration:
			return nil
		default:
			return ErrCommunityPostingDenied
		}
	default:
		return ErrCommunityPostingDenied
	}
}

func moderationDecisionForReviewInput(decision string) (enum.PostModerationDecision, enum.ModerationStatus, error) {
	switch strings.ToLower(strings.TrimSpace(decision)) {
	case "approve", "approved":
		return enum.PostModerationDecisionApprove, enum.ModerationStatusApproved, nil
	case "reject", "rejected":
		return enum.PostModerationDecisionReject, enum.ModerationStatusRejected, nil
	default:
		return "", enum.ModerationStatusNotRequired, ErrInvalidModerationDecision
	}
}

func postReportStatusForResolutionDecision(decision string) (enum.PostReportStatus, error) {
	switch strings.ToLower(strings.TrimSpace(decision)) {
	case "review", "reviewed":
		return enum.PostReportStatusReviewed, nil
	case "dismiss", "dismissed":
		return enum.PostReportStatusDismissed, nil
	default:
		return "", ErrInvalidPostReportDecision
	}
}

func applyPostUpdate(existing *model.Post, next *model.Post, revision int64, moderationStatus enum.ModerationStatus) {
	existing.Title = next.Title
	existing.Excerpt = next.Excerpt
	existing.Content = next.Content
	existing.Format = next.Format
	existing.ContentSchemaVersion = next.ContentSchemaVersion
	existing.ContentBlocks = next.ContentBlocks
	existing.ContentPlainText = next.ContentPlainText
	existing.Category = next.Category
	existing.Status = next.Status
	existing.MediaStatus = next.MediaStatus
	existing.Media = append([]model.PostMedia(nil), next.Media...)
	existing.Revision = revision
	existing.ModerationStatus = moderationStatus
	existing.CommunityID = next.CommunityID
	existing.CommunityInstanceID = next.CommunityInstanceID
	existing.PostKind = next.PostKind
	existing.PostProfileKey = next.PostProfileKey
	existing.PostProfileVersion = next.PostProfileVersion
	existing.StructuredData = append(json.RawMessage(nil), next.StructuredData...)
	existing.ModerationMode = next.ModerationMode
	existing.CoverFileID = next.CoverFileID
	existing.PlaceName = next.PlaceName
	existing.PlaceCountryCode = next.PlaceCountryCode
	existing.PlaceCityID = next.PlaceCityID
	existing.Tags = next.Tags
	existing.ExpiresAt = next.ExpiresAt
	existing.Slug = buildPostSlug(next.Title, existing.ID)
}

func applyPostActivityCreationState(post *model.Post, profile postProfileDefaults) {
	if post == nil {
		return
	}
	if post.Status != enum.PostStatusPublished || !postRequiresActivityIntent(post, profile) {
		post.ActivityCreationStatus = nil
		post.ActivityCreationError = nil
		return
	}
	if post.ActivityCreationStatus == nil {
		status := enum.ActivityCreationStatusPending
		post.ActivityCreationStatus = &status
	}
}

func postRequiresActivityIntent(post *model.Post, profile postProfileDefaults) bool {
	if post == nil {
		return false
	}
	switch profile.ActivityCreationMode {
	case enum.ActivityCreationModeRequired:
		return true
	case enum.ActivityCreationModeOptional:
		return structuredBool(post.StructuredData, "createActivity") ||
			structuredBool(post.StructuredData, "create_activity")
	default:
		return false
	}
}

func postInputFromExisting(post *model.Post) CreatePostInput {
	if post == nil {
		return CreatePostInput{}
	}
	return CreatePostInput{
		Title:               post.Title,
		Content:             post.Content,
		Format:              post.Format,
		ContentBlocks:       append(json.RawMessage(nil), post.ContentBlocks...),
		Category:            post.Category,
		Status:              post.Status,
		CommunityID:         post.CommunityID,
		CommunityInstanceID: post.CommunityInstanceID,
		PostProfileKey:      post.PostProfileKey,
		StructuredData:      append(json.RawMessage(nil), post.StructuredData...),
		CoverFileID:         post.CoverFileID,
		PlaceName:           post.PlaceName,
		PlaceCountryCode:    post.PlaceCountryCode,
		PlaceCityID:         post.PlaceCityID,
		Tags:                append([]string(nil), post.Tags...),
		ExpiresAt:           post.ExpiresAt,
	}
}

func mergePostUpdateInput(post *model.Post, input UpdatePostInput) CreatePostInput {
	merged := postInputFromExisting(post)
	if input.Title != nil {
		merged.Title = *input.Title
	}
	if input.Content != nil {
		merged.Content = *input.Content
		if input.ContentBlocks == nil {
			merged.ContentBlocks = nil
		}
	}
	if input.Format != nil {
		merged.Format = *input.Format
	}
	if input.ContentBlocks != nil {
		merged.ContentBlocks = append(json.RawMessage(nil), (*input.ContentBlocks)...)
	}
	if input.Category != nil {
		merged.Category = *input.Category
	}
	if input.Status != nil {
		merged.Status = *input.Status
	}
	merged.PublishIntent = input.PublishIntent
	merged.AllowArchivedStatus = input.AllowArchivedStatus
	merged.Revision = input.Revision
	if input.CommunityIDSet {
		merged.CommunityID = input.CommunityID
	}
	if input.CommunityInstanceIDSet {
		merged.CommunityInstanceID = input.CommunityInstanceID
	}
	if input.PostProfileKey != nil {
		merged.PostProfileKey = *input.PostProfileKey
	}
	if input.StructuredData != nil {
		merged.StructuredData = append(json.RawMessage(nil), (*input.StructuredData)...)
	}
	if input.CoverFileIDSet {
		merged.CoverFileID = input.CoverFileID
	}
	if input.PlaceNameSet {
		merged.PlaceName = input.PlaceName
	}
	if input.PlaceCountryCodeSet {
		merged.PlaceCountryCode = input.PlaceCountryCode
	}
	if input.PlaceCityIDSet {
		merged.PlaceCityID = input.PlaceCityID
	}
	if input.TagsSet {
		merged.Tags = append([]string(nil), input.Tags...)
	}
	if input.ExpiresAtSet {
		merged.ExpiresAt = input.ExpiresAt
	}
	return merged
}

func normalizePlaceFilters(raw string) (placeQuery string, placeCountryCode string) {
	trimmed := strings.TrimSpace(raw)
	if trimmed == "" {
		return "", ""
	}

	if looksLikeCountryCode(trimmed) {
		return "", strings.ToUpper(trimmed)
	}

	return trimmed, ""
}

func looksLikeCountryCode(value string) bool {
	if utf8.RuneCountInString(value) != 2 {
		return false
	}

	for _, r := range value {
		if r > unicode.MaxASCII || !unicode.IsLetter(r) {
			return false
		}
	}

	return true
}

type postProfileDefaults struct {
	Key                  enum.PostProfileKey
	Version              int
	Kind                 enum.PostKind
	ModerationMode       enum.ModerationMode
	ActivityCreationMode enum.ActivityCreationMode
	RequiredFields       []string
}

func (u *PostUseCase) resolvePostProfileDefaults(ctx context.Context, key enum.PostProfileKey) (postProfileDefaults, error) {
	normalized := enum.NormalizePostProfileKey(key)
	if !normalized.IsValid() {
		return postProfileDefaults{}, ErrInvalidPostContent
	}
	if u == nil || u.repo == nil {
		return postProfileDefaults{}, ErrInvalidPostContent
	}

	profiles, err := u.repo.ListCommunityPostProfiles(ctx, model.CommunityPostProfileListFilter{
		Limit:  100,
		Offset: 0,
	})
	if err != nil {
		return postProfileDefaults{}, fmt.Errorf("list community post profiles: %w", err)
	}
	for _, profile := range profiles {
		if profile == nil || enum.NormalizePostProfileKey(profile.Key) != normalized {
			continue
		}
		resolved, err := postProfileDefaultsFromCommunityProfile(*profile)
		if err != nil {
			return postProfileDefaults{}, err
		}
		return resolved, nil
	}
	return postProfileDefaults{}, ErrInvalidPostContent
}

func postProfileDefaultsFromCommunityProfile(profile model.CommunityPostProfile) (postProfileDefaults, error) {
	key := enum.NormalizePostProfileKey(profile.Key)
	if !key.IsValid() ||
		profile.Version <= 0 ||
		!profile.PostKind.IsValid() ||
		!profile.ModerationMode.IsValid() ||
		!profile.ActivityCreationMode.IsValid() {
		return postProfileDefaults{}, ErrInvalidPostContent
	}

	requiredFields, err := postProfileRequiredStructuredFieldsFromValidation(profile.ValidationJSON)
	if err != nil {
		return postProfileDefaults{}, ErrInvalidPostContent
	}

	return postProfileDefaults{
		Key:                  key,
		Version:              profile.Version,
		Kind:                 profile.PostKind,
		ModerationMode:       profile.ModerationMode,
		ActivityCreationMode: profile.ActivityCreationMode,
		RequiredFields:       requiredFields,
	}, nil
}

func postProfileRequiredStructuredFieldsFromValidation(raw json.RawMessage) ([]string, error) {
	trimmed := bytes.TrimSpace(raw)
	if len(trimmed) == 0 || bytes.Equal(trimmed, []byte("null")) {
		return nil, nil
	}

	var payload struct {
		Required []string `json:"required"`
	}
	if err := json.Unmarshal(trimmed, &payload); err != nil {
		return nil, err
	}
	result := make([]string, 0, len(payload.Required))
	seen := make(map[string]struct{}, len(payload.Required))
	for _, field := range payload.Required {
		field = strings.TrimSpace(field)
		if field == "" {
			continue
		}
		if _, exists := seen[field]; exists {
			continue
		}
		seen[field] = struct{}{}
		result = append(result, field)
	}
	return result, nil
}

func normalizePostInputWithProfile(postID uuid.UUID, input CreatePostInput, profile postProfileDefaults) (*model.Post, error) {
	if !profile.Key.IsValid() || profile.Version <= 0 || !profile.Kind.IsValid() || !profile.ModerationMode.IsValid() || !profile.ActivityCreationMode.IsValid() {
		return nil, ErrInvalidPostContent
	}
	structuredData, err := normalizePostStructuredData(input.StructuredData)
	if err != nil {
		return nil, ErrInvalidPostContent
	}
	input = applyPostProfileInputDefaults(input, profile, structuredData)

	title := strings.TrimSpace(input.Title)
	if utf8.RuneCountInString(title) > maxPostTitleChars {
		return nil, ErrInvalidPostTitle
	}

	format := enum.NormalizePostFormat(input.Format)
	if !format.IsValid() {
		return nil, ErrInvalidPostContent
	}

	category := enum.PostCategory(strings.ToUpper(strings.TrimSpace(string(input.Category))))
	if category != "" && !category.IsValid() {
		return nil, ErrInvalidPostCategory
	}

	status := enum.PostStatus(strings.ToUpper(strings.TrimSpace(string(input.Status))))
	if status == "" {
		status = enum.PostStatusDraft
	}
	if input.PublishIntent {
		status = enum.PostStatusPublished
	}
	if !status.IsValid() {
		return nil, ErrInvalidPostStatus
	}
	if status == enum.PostStatusArchived && !input.AllowArchivedStatus {
		return nil, ErrInvalidPostStatus
	}

	document, contentBlocks, err := normalizePostDocumentInput(postID, input.ContentBlocks, input.Content)
	if err != nil {
		return nil, ErrInvalidPostContent
	}

	contentPlainText := strings.TrimSpace(document.PlainText())
	content := strings.TrimSpace(document.LegacyContent())
	hasPublishableContent := !document.IsEmptyForPublish()
	if utf8.RuneCountInString(visiblePostContent(content)) > maxPostContentChars {
		return nil, ErrInvalidPostContent
	}
	if status != enum.PostStatusPublished && title == "" && !hasPublishableContent {
		return nil, ErrInvalidPostContent
	}

	placeName := trimOptionalString(input.PlaceName)
	if status == enum.PostStatusPublished {
		if err := validatePublishablePostForProfile(profile, structuredData, title, category, placeName, input.CoverFileID, hasPublishableContent); err != nil {
			return nil, err
		}
	}

	tags, err := sanitizeTags(input.Tags)
	if err != nil {
		return nil, err
	}

	return &model.Post{
		Title:                title,
		Excerpt:              buildExcerpt(content, title),
		Content:              content,
		Format:               format,
		ContentSchemaVersion: model.PostDocumentVersion,
		ContentBlocks:        contentBlocks,
		ContentPlainText:     contentPlainText,
		Category:             category,
		Status:               status,
		MediaStatus:          enum.PostMediaStatusReady,
		ModerationStatus:     enum.ModerationStatusNotRequired,
		Revision:             1,
		CommunityID:          input.CommunityID,
		CommunityInstanceID:  input.CommunityInstanceID,
		PostKind:             profile.Kind,
		PostProfileKey:       profile.Key,
		PostProfileVersion:   profile.Version,
		StructuredData:       structuredData,
		ModerationMode:       profile.ModerationMode,
		CoverFileID:          input.CoverFileID,
		PlaceName:            placeName,
		PlaceCountryCode:     trimOptionalString(input.PlaceCountryCode),
		PlaceCityID:          trimOptionalString(input.PlaceCityID),
		Tags:                 tags,
		ExpiresAt:            input.ExpiresAt,
	}, nil
}

func normalizePostStructuredData(raw json.RawMessage) (json.RawMessage, error) {
	trimmed := bytes.TrimSpace(raw)
	if len(trimmed) == 0 || bytes.Equal(trimmed, []byte("null")) {
		return json.RawMessage(`{}`), nil
	}
	var value map[string]any
	if err := json.Unmarshal(trimmed, &value); err != nil {
		return nil, err
	}
	normalized, err := json.Marshal(value)
	if err != nil {
		return nil, err
	}
	return normalized, nil
}

func applyPostProfileInputDefaults(input CreatePostInput, profile postProfileDefaults, structuredData json.RawMessage) CreatePostInput {
	if profile.Kind == enum.PostKindArticle {
		return input
	}
	if input.Format == "" {
		input.Format = enum.PostFormatPost
	}
	if input.Category == "" {
		input.Category = enum.PostCategoryGuide
	}
	if strings.TrimSpace(input.Title) == "" {
		input.Title = postProfileStructuredTitle(profile.Kind, structuredData)
	}
	if strings.TrimSpace(input.Content) == "" && len(bytes.TrimSpace(input.ContentBlocks)) == 0 {
		input.Content = postProfileStructuredBody(profile.Kind, structuredData)
	}
	return input
}

func postProfileStructuredTitle(kind enum.PostKind, data json.RawMessage) string {
	switch kind {
	case enum.PostKindQuickPost:
		return truncateRunes(firstNonEmptyStructuredString(data, "body", "text"), maxPostTitleChars)
	case enum.PostKindListing, enum.PostKindEventAnnouncement, enum.PostKindTripPlan:
		return firstNonEmptyStructuredString(data, "title")
	case enum.PostKindQuestionAnswer:
		return firstNonEmptyStructuredString(data, "question")
	default:
		return ""
	}
}

func postProfileStructuredBody(kind enum.PostKind, data json.RawMessage) string {
	switch kind {
	case enum.PostKindQuickPost:
		return firstNonEmptyStructuredString(data, "body", "text")
	case enum.PostKindListing:
		return firstNonEmptyStructuredString(data, "body", "description")
	case enum.PostKindEventAnnouncement:
		return firstNonEmptyStructuredString(data, "description", "body")
	case enum.PostKindTripPlan:
		return firstNonEmptyStructuredString(data, "description", "route")
	case enum.PostKindQuestionAnswer:
		return firstNonEmptyStructuredString(data, "details", "question")
	default:
		return ""
	}
}

func firstNonEmptyStructuredString(data json.RawMessage, keys ...string) string {
	var values map[string]any
	if err := json.Unmarshal(data, &values); err != nil {
		return ""
	}
	for _, key := range keys {
		if value, ok := values[key]; ok {
			switch typed := value.(type) {
			case string:
				if trimmed := strings.TrimSpace(typed); trimmed != "" {
					return trimmed
				}
			case []any:
				if len(typed) > 0 {
					if encoded, err := json.Marshal(typed); err == nil {
						return string(encoded)
					}
				}
			case map[string]any:
				if len(typed) > 0 {
					if encoded, err := json.Marshal(typed); err == nil {
						return string(encoded)
					}
				}
			}
		}
	}
	return ""
}

func structuredHasField(data json.RawMessage, key string) bool {
	var values map[string]any
	if err := json.Unmarshal(data, &values); err != nil {
		return false
	}
	value, ok := values[key]
	if !ok || value == nil {
		return false
	}
	switch typed := value.(type) {
	case string:
		return strings.TrimSpace(typed) != ""
	case []any:
		return len(typed) > 0
	case map[string]any:
		return len(typed) > 0
	default:
		return true
	}
}

func structuredBool(data json.RawMessage, key string) bool {
	var values map[string]any
	if err := json.Unmarshal(data, &values); err != nil {
		return false
	}
	value, ok := values[key]
	if !ok {
		return false
	}
	switch typed := value.(type) {
	case bool:
		return typed
	case string:
		switch strings.ToLower(strings.TrimSpace(typed)) {
		case "true", "1", "yes":
			return true
		default:
			return false
		}
	default:
		return false
	}
}

func truncateRunes(value string, limit int) string {
	value = strings.TrimSpace(value)
	if limit <= 0 || utf8.RuneCountInString(value) <= limit {
		return value
	}
	runes := []rune(value)
	return strings.TrimSpace(string(runes[:limit]))
}

func validatePublishablePost(
	title string,
	category enum.PostCategory,
	placeName *string,
	coverFileID *uuid.UUID,
	hasPublishableContent bool,
) error {
	fields := make(map[string]string, 5)
	causes := make([]error, 0, 5)
	if title == "" {
		fields["title"] = "required_for_publish"
		causes = append(causes, ErrInvalidPostTitle)
	}
	if !category.IsValid() {
		fields["category"] = "required_for_publish"
		causes = append(causes, ErrInvalidPostCategory)
	}
	if placeName == nil {
		fields["placeName"] = "required_for_publish"
		causes = append(causes, ErrInvalidPostPlace)
	}
	if coverFileID == nil {
		fields["coverFileId"] = "required_for_publish"
		causes = append(causes, ErrInvalidPostCover)
	}
	if !hasPublishableContent {
		fields["contentBlocks"] = "required_for_publish"
		causes = append(causes, ErrInvalidPostContent)
	}
	if len(fields) == 0 {
		return nil
	}
	return NewPostValidationError(fields, causes...)
}

func validatePublishablePostForProfile(
	profile postProfileDefaults,
	structuredData json.RawMessage,
	title string,
	category enum.PostCategory,
	placeName *string,
	coverFileID *uuid.UUID,
	hasPublishableContent bool,
) error {
	if profile.Kind == enum.PostKindArticle {
		return validatePublishablePost(title, category, placeName, coverFileID, hasPublishableContent)
	}

	fields := make(map[string]string)
	causes := make([]error, 0, 4)
	required := postProfileRequiredStructuredFields(profile)
	for _, field := range required {
		if !structuredHasField(structuredData, field) {
			fields[field] = "required_for_publish"
			causes = append(causes, ErrInvalidPostContent)
		}
	}
	if strings.TrimSpace(title) == "" {
		fields["title"] = "required_for_publish"
		causes = append(causes, ErrInvalidPostTitle)
	}
	if !category.IsValid() {
		fields["category"] = "invalid"
		causes = append(causes, ErrInvalidPostCategory)
	}
	if len(fields) > 0 {
		return NewPostValidationError(fields, causes...)
	}
	return nil
}

func postProfileRequiredStructuredFields(profile postProfileDefaults) []string {
	if len(profile.RequiredFields) > 0 {
		return append([]string(nil), profile.RequiredFields...)
	}
	switch profile.Kind {
	case enum.PostKindQuickPost:
		return []string{"body"}
	case enum.PostKindListing:
		return []string{"title", "body", "location"}
	case enum.PostKindEventAnnouncement:
		return []string{"title", "starts_at", "location"}
	case enum.PostKindTripPlan:
		return []string{"title", "route", "starts_at", "meeting_point"}
	case enum.PostKindQuestionAnswer:
		return []string{"question"}
	default:
		return nil
	}
}

func normalizePostDocumentInput(
	postID uuid.UUID,
	contentBlocks json.RawMessage,
	legacyContent string,
) (model.PostDocument, json.RawMessage, error) {
	var document model.PostDocument

	if len(contentBlocks) > 0 {
		trimmedContentBlocks := bytes.TrimSpace(contentBlocks)
		if len(trimmedContentBlocks) > 0 && trimmedContentBlocks[0] == '[' {
			var blocks []model.PostBlock
			if err := json.Unmarshal(trimmedContentBlocks, &blocks); err != nil {
				return model.PostDocument{}, nil, err
			}
			document = model.PostDocument{
				Version: model.PostDocumentVersion,
				Blocks:  blocks,
			}
		} else {
			if err := json.Unmarshal(trimmedContentBlocks, &document); err != nil {
				return model.PostDocument{}, nil, err
			}
		}
		if err := document.Validate(); err != nil {
			return model.PostDocument{}, nil, err
		}
		normalizedContentBlocks, err := marshalPostDocument(document)
		return document, normalizedContentBlocks, err
	}

	document, err := LegacyPostContentToDocument(postID, legacyContent)
	if err != nil {
		return model.PostDocument{}, nil, err
	}
	normalizedContentBlocks, err := marshalPostDocument(document)
	return document, normalizedContentBlocks, err
}

func marshalPostDocument(document model.PostDocument) (json.RawMessage, error) {
	data, err := json.Marshal(document)
	if err != nil {
		return nil, err
	}
	return json.RawMessage(data), nil
}

func normalizeCountryCode(raw string) string {
	trimmed := strings.TrimSpace(raw)
	if trimmed == "" || !looksLikeCountryCode(trimmed) {
		return ""
	}
	return strings.ToUpper(trimmed)
}

func sanitizeTags(tags []string) ([]string, error) {
	if len(tags) == 0 {
		return []string{}, nil
	}

	seen := make(map[string]struct{}, len(tags))
	result := make([]string, 0, len(tags))

	for _, tag := range tags {
		tag = strings.TrimSpace(tag)
		if tag == "" {
			continue
		}
		if utf8.RuneCountInString(tag) > maxTagChars {
			return nil, ErrInvalidPostTags
		}

		key := strings.ToLower(tag)
		if _, exists := seen[key]; exists {
			continue
		}
		seen[key] = struct{}{}
		result = append(result, tag)
	}

	if len(result) > maxPostTags {
		return nil, ErrInvalidPostTags
	}

	if result == nil {
		return []string{}, nil
	}

	return result, nil
}

func sanitizeRelatedTags(tags []string) []string {
	if len(tags) == 0 {
		return nil
	}
	seen := make(map[string]struct{}, len(tags))
	result := make([]string, 0, len(tags))
	for _, tag := range tags {
		normalized := strings.ToLower(strings.TrimSpace(tag))
		if normalized == "" {
			continue
		}
		if _, exists := seen[normalized]; exists {
			continue
		}
		seen[normalized] = struct{}{}
		result = append(result, normalized)
	}
	if len(result) == 0 {
		return nil
	}
	return result
}

func derefString(value *string) string {
	if value == nil {
		return ""
	}
	return *value
}

func buildExcerpt(content string, title string) string {
	source := visiblePostContent(content)
	if source == "" {
		source = strings.TrimSpace(title)
	}
	if utf8.RuneCountInString(source) <= 180 {
		return source
	}

	runes := []rune(source)
	return strings.TrimSpace(string(runes[:180])) + "..."
}

func visiblePostContent(content string) string {
	cleaned := postImageMarkerRegexp.ReplaceAllString(content, "\n\n")
	cleaned = strings.ReplaceAll(cleaned, "\r\n", "\n")
	cleaned = postSpacingRegexp.ReplaceAllString(cleaned, "\n\n")
	return strings.TrimSpace(cleaned)
}

func buildPostSlug(title string, postID uuid.UUID) string {
	title = strings.ToLower(strings.TrimSpace(title))
	title = strings.Map(func(r rune) rune {
		switch {
		case unicode.IsLetter(r), unicode.IsDigit(r):
			if r > unicode.MaxASCII {
				return '-'
			}
			return r
		case unicode.IsSpace(r), r == '-', r == '_':
			return '-'
		default:
			return '-'
		}
	}, title)
	title = nonSlugPattern.ReplaceAllString(title, "-")
	title = strings.Trim(title, "-")
	if title == "" {
		title = "post"
	}

	suffix := strings.ReplaceAll(postID.String()[:8], "-", "")
	return fmt.Sprintf("%s-%s", title, suffix)
}

func trimOptionalString(v *string) *string {
	if v == nil {
		return nil
	}
	trimmed := strings.TrimSpace(*v)
	if trimmed == "" {
		return nil
	}
	return &trimmed
}

func (u *PostUseCase) requireUserID(ctx context.Context, subject string) (uuid.UUID, error) {
	subject = strings.TrimSpace(subject)
	if subject == "" {
		return uuid.Nil, ErrUnauthenticatedWriter
	}

	userID, err := u.users.ResolveUserIDBySubject(ctx, subject)
	if err != nil {
		if err == ErrUserNotFound {
			return uuid.Nil, err
		}
		return uuid.Nil, fmt.Errorf("resolve user by subject: %w", err)
	}
	return userID, nil
}

func (u *PostUseCase) optionalUserID(ctx context.Context, subject string) (*uuid.UUID, error) {
	subject = strings.TrimSpace(subject)
	if subject == "" {
		return nil, nil
	}

	userID, err := u.users.ResolveUserIDBySubject(ctx, subject)
	if err != nil {
		if err == ErrUserNotFound {
			return nil, nil
		}
		return nil, fmt.Errorf("resolve optional user by subject: %w", err)
	}

	return &userID, nil
}

func (u *PostUseCase) buildPostViews(ctx context.Context, posts []*model.Post, viewerUserID *uuid.UUID) ([]*PostView, error) {
	if len(posts) == 0 {
		return []*PostView{}, nil
	}

	authorIDs := make([]uuid.UUID, 0, len(posts))
	postIDs := make([]uuid.UUID, 0, len(posts))
	seenAuthors := make(map[uuid.UUID]struct{}, len(posts))
	seenPostIDs := make(map[uuid.UUID]struct{}, len(posts))
	for _, post := range posts {
		if post == nil {
			continue
		}
		if post.ID != uuid.Nil {
			if _, exists := seenPostIDs[post.ID]; !exists {
				seenPostIDs[post.ID] = struct{}{}
				postIDs = append(postIDs, post.ID)
			}
		}
		if _, exists := seenAuthors[post.AuthorUserID]; exists {
			continue
		}
		seenAuthors[post.AuthorUserID] = struct{}{}
		authorIDs = append(authorIDs, post.AuthorUserID)
	}
	sort.Slice(authorIDs, func(i, j int) bool { return authorIDs[i].String() < authorIDs[j].String() })

	profiles, err := u.users.GetPublicUserProfiles(ctx, authorIDs)
	if err != nil {
		return nil, fmt.Errorf("get public post author profiles: %w", err)
	}

	socialEdges := map[uuid.UUID]model.FeedSocialEdgeSet{}
	likedPosts := map[uuid.UUID]bool{}
	seenPosts := map[uuid.UUID]time.Time{}
	if viewerUserID != nil && *viewerUserID != uuid.Nil && len(postIDs) > 0 {
		if len(authorIDs) > 0 {
			socialEdges, err = u.repo.ListFeedSocialEdges(ctx, *viewerUserID, authorIDs)
			if err != nil {
				return nil, fmt.Errorf("list viewer feed social edges: %w", err)
			}
			u.repairUserServiceSocialEdges(ctx, *viewerUserID, authorIDs, socialEdges)
		}
		likedPosts, err = u.repo.ListPostLikesByUser(ctx, postIDs, *viewerUserID)
		if err != nil {
			return nil, fmt.Errorf("list viewer post likes: %w", err)
		}
		seenPosts, err = u.repo.ListPostSeenByUser(ctx, postIDs, *viewerUserID)
		if err != nil {
			return nil, fmt.Errorf("list viewer post seen markers: %w", err)
		}
	}

	items := make([]*PostView, 0, len(posts))
	for _, post := range posts {
		if post == nil {
			continue
		}
		author := toPostAuthor(post.AuthorUserID, profiles[post.AuthorUserID])
		author.IsFriendOfViewer = socialEdges[post.AuthorUserID].Friend
		likedByViewer := likedPosts[post.ID]
		seenAt, seenByViewer := seenPosts[post.ID]
		var seenAtPtr *time.Time
		if seenByViewer {
			value := seenAt.UTC()
			seenAtPtr = &value
		}

		items = append(items, &PostView{
			Post:          post,
			Author:        author,
			LikedByViewer: likedByViewer,
			Editable:      viewerUserID != nil && post.IsOwnedBy(*viewerUserID),
			SeenByViewer:  seenByViewer,
			SeenAt:        seenAtPtr,
			ShareURL:      u.shareURL(post.Slug),
		})
	}

	return items, nil
}

func (u *PostUseCase) repairUserServiceSocialEdges(
	ctx context.Context,
	viewerUserID uuid.UUID,
	authorIDs []uuid.UUID,
	socialEdges map[uuid.UUID]model.FeedSocialEdgeSet,
) {
	if u.users == nil || viewerUserID == uuid.Nil || len(authorIDs) == 0 {
		return
	}
	sourceUpdatedAt := time.Now().UTC()
	repaired := false

	friendUserIDs, err := u.users.FilterFriendUserIDs(ctx, viewerUserID, authorIDs)
	if err == nil {
		repaired = u.repairSocialEdgeSet(ctx, viewerUserID, friendUserIDs, socialEdges, model.FeedSocialEdgeTypeFriend, sourceUpdatedAt) || repaired
	}

	followingUserIDs, err := u.users.FilterFollowingUserIDs(ctx, viewerUserID, authorIDs)
	if err == nil {
		repaired = u.repairSocialEdgeSet(ctx, viewerUserID, followingUserIDs, socialEdges, model.FeedSocialEdgeTypeFollowing, sourceUpdatedAt) || repaired
	}

	if repaired {
		u.bumpPostFeedCacheScopes(
			ctx,
			postFeedCacheViewerScope(viewerUserID),
			postFeedCacheFollowingScope(viewerUserID),
			postFeedCacheDiscoveryScope(viewerUserID),
		)
	}
}

func (u *PostUseCase) repairSocialEdgeSet(
	ctx context.Context,
	viewerUserID uuid.UUID,
	userIDs map[uuid.UUID]bool,
	socialEdges map[uuid.UUID]model.FeedSocialEdgeSet,
	edgeType string,
	sourceUpdatedAt time.Time,
) bool {
	repaired := false
	for targetUserID, edgeSet := range socialEdges {
		if targetUserID == uuid.Nil || targetUserID == viewerUserID || userIDs[targetUserID] {
			continue
		}
		stale := false
		switch edgeType {
		case model.FeedSocialEdgeTypeFriend:
			stale = edgeSet.Friend
			edgeSet.Friend = false
		case model.FeedSocialEdgeTypeFollowing:
			stale = edgeSet.Following
			edgeSet.Following = false
		default:
			continue
		}
		if !stale {
			continue
		}
		socialEdges[targetUserID] = edgeSet
		changed, _ := u.repo.DeleteFeedSocialEdge(ctx, viewerUserID, targetUserID, edgeType, sourceUpdatedAt)
		repaired = changed || repaired
	}
	for targetUserID, active := range userIDs {
		if !active || targetUserID == uuid.Nil || targetUserID == viewerUserID {
			continue
		}
		edgeSet := socialEdges[targetUserID]
		if edgeType == model.FeedSocialEdgeTypeFriend && edgeSet.Friend {
			continue
		}
		if edgeType == model.FeedSocialEdgeTypeFollowing && edgeSet.Following {
			continue
		}
		switch edgeType {
		case model.FeedSocialEdgeTypeFriend:
			edgeSet.Friend = true
		case model.FeedSocialEdgeTypeFollowing:
			edgeSet.Following = true
		default:
			continue
		}
		socialEdges[targetUserID] = edgeSet
		changed, _ := u.repo.UpsertFeedSocialEdge(ctx, model.FeedSocialEdge{
			ViewerUserID:    viewerUserID,
			TargetUserID:    targetUserID,
			EdgeType:        edgeType,
			SourceUpdatedAt: sourceUpdatedAt,
		})
		repaired = changed || repaired
	}
	return repaired
}

func (u *PostUseCase) buildStoryViews(ctx context.Context, stories []*model.Story, viewerUserID *uuid.UUID) ([]*StoryView, error) {
	if len(stories) == 0 {
		return []*StoryView{}, nil
	}

	authorIDs := make([]uuid.UUID, 0, len(stories))
	storyIDs := make([]uuid.UUID, 0, len(stories))
	seenAuthors := make(map[uuid.UUID]struct{}, len(stories))
	seenStoryIDs := make(map[uuid.UUID]struct{}, len(stories))
	for _, story := range stories {
		if story == nil {
			continue
		}
		if story.ID != uuid.Nil {
			if _, exists := seenStoryIDs[story.ID]; !exists {
				seenStoryIDs[story.ID] = struct{}{}
				storyIDs = append(storyIDs, story.ID)
			}
		}
		if _, exists := seenAuthors[story.AuthorUserID]; exists {
			continue
		}
		seenAuthors[story.AuthorUserID] = struct{}{}
		authorIDs = append(authorIDs, story.AuthorUserID)
	}
	sort.Slice(authorIDs, func(i, j int) bool { return authorIDs[i].String() < authorIDs[j].String() })

	profiles, err := u.users.GetPublicUserProfiles(ctx, authorIDs)
	if err != nil {
		return nil, fmt.Errorf("get public story author profiles: %w", err)
	}

	seenStories := map[uuid.UUID]time.Time{}
	if viewerUserID != nil && *viewerUserID != uuid.Nil && len(storyIDs) > 0 {
		seenStories, err = u.repo.ListStorySeenByUser(ctx, storyIDs, *viewerUserID)
		if err != nil {
			return nil, fmt.Errorf("list viewer story seen markers: %w", err)
		}
	}

	items := make([]*StoryView, 0, len(stories))
	for _, story := range stories {
		if story == nil {
			continue
		}
		seenAt, seenByViewer := seenStories[story.ID]
		var seenAtPtr *time.Time
		if seenByViewer {
			value := seenAt.UTC()
			seenAtPtr = &value
		}
		items = append(items, &StoryView{
			Story:        story,
			Author:       toPostAuthor(story.AuthorUserID, profiles[story.AuthorUserID]),
			SeenByViewer: seenByViewer,
			SeenAt:       seenAtPtr,
			ShareURL:     u.shareStoryURL(story.ID),
		})
	}

	return items, nil
}

func (u *PostUseCase) postMutationView(post *model.Post) *PostView {
	if post == nil {
		return nil
	}
	return &PostView{
		Post:     post,
		Author:   toPostAuthor(post.AuthorUserID, PublicUserProfile{UserID: post.AuthorUserID}),
		Editable: true,
		ShareURL: u.shareURL(post.Slug),
	}
}

func (u *PostUseCase) buildCommentViews(
	ctx context.Context,
	post *model.Post,
	comments []*model.PostComment,
	viewerUserID *uuid.UUID,
) ([]*PostCommentView, error) {
	if len(comments) == 0 {
		return []*PostCommentView{}, nil
	}

	authorIDs := make([]uuid.UUID, 0, len(comments))
	seen := make(map[uuid.UUID]struct{}, len(comments))
	for _, comment := range comments {
		if comment == nil {
			continue
		}
		if _, exists := seen[comment.AuthorUserID]; exists {
			continue
		}
		seen[comment.AuthorUserID] = struct{}{}
		authorIDs = append(authorIDs, comment.AuthorUserID)
	}

	profiles, err := u.users.GetPublicUserProfiles(ctx, authorIDs)
	if err != nil {
		return nil, fmt.Errorf("get public comment author profiles: %w", err)
	}

	items := make([]*PostCommentView, 0, len(comments))
	for _, comment := range comments {
		if comment == nil {
			continue
		}
		editable := false
		deletable := false
		likedByViewer := false
		if viewerUserID != nil && *viewerUserID != uuid.Nil {
			editable = comment.IsOwnedBy(*viewerUserID)
			deletable = editable
			likedByViewer, err = u.repo.HasCommentLike(ctx, comment.ID, *viewerUserID)
			if err != nil {
				return nil, fmt.Errorf("check viewer comment like: %w", err)
			}
		}

		items = append(items, &PostCommentView{
			Comment:       comment,
			Author:        toPostAuthor(comment.AuthorUserID, profiles[comment.AuthorUserID]),
			Editable:      editable,
			Deletable:     deletable,
			LikedByViewer: likedByViewer,
			ShareURL:      u.shareCommentURL(post, comment.ID),
		})
	}

	return items, nil
}

func toPostAuthor(userID uuid.UUID, profile PublicUserProfile) PostAuthor {
	return PostAuthor{
		UserID:       userID,
		Nickname:     profile.Nickname,
		AvatarFileID: profile.AvatarFileID,
		CountryCode:  profile.CountryCode,
		Locale:       profile.Locale,
		Timezone:     profile.Timezone,
	}
}

func (u *PostUseCase) shareURL(slug string) string {
	if u.postsBaseURL == "" {
		return ""
	}
	return u.postsBaseURL + "/" + strings.TrimLeft(strings.TrimSpace(slug), "/")
}

func (u *PostUseCase) shareStoryURL(storyID uuid.UUID) string {
	if u.postsBaseURL == "" || storyID == uuid.Nil {
		return ""
	}
	return u.postsBaseURL + "/stories/" + storyID.String()
}

func (u *PostUseCase) shareCommentURL(post *model.Post, commentID uuid.UUID) string {
	if post == nil || commentID == uuid.Nil {
		return ""
	}
	base := u.shareURL(post.Slug)
	if base == "" {
		return ""
	}
	return base + "?comment=" + commentID.String()
}
