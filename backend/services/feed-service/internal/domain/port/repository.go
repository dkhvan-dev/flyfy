package port

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/feed-service/internal/domain/enum"
	"kz/inflap/backend/services/feed-service/internal/domain/model"
)

var (
	ErrPostRevisionConflict      = errors.New("post revision conflict")
	ErrPostCommentRateLimited    = errors.New("post comment rate limited")
	ErrPostReportNotFound        = errors.New("post report not found")
	ErrPostReportAlreadyResolved = errors.New("post report already resolved")
)

type PostRepository interface {
	CreatePost(ctx context.Context, post *model.Post) error
	CreateStory(ctx context.Context, story *model.Story) error
	UpdatePost(ctx context.Context, post *model.Post) error
	ReviewCommunityPost(ctx context.Context, post *model.Post, decision *model.PostModerationDecision) error
	ListCommunityPostModerationDecisions(ctx context.Context, filter model.PostModerationDecisionListFilter) ([]*model.PostModerationDecision, error)
	CreatePostReport(ctx context.Context, report *model.PostReport, autoHideThreshold int) (*model.PostReportSubmissionResult, error)
	GetPostReport(ctx context.Context, reportID uuid.UUID) (*model.PostReport, error)
	ListCommunityPostReports(ctx context.Context, filter model.PostReportListFilter) ([]*model.PostReport, error)
	ResolvePostReport(ctx context.Context, resolution *model.PostReportResolution) (*model.PostReport, error)
	SoftDeletePost(ctx context.Context, postID uuid.UUID, authorUserID uuid.UUID) error
	GetPostByID(ctx context.Context, postID uuid.UUID) (*model.Post, error)
	GetPostBySlug(ctx context.Context, slug string) (*model.Post, error)
	ListPosts(ctx context.Context, filter model.PostListFilter) ([]*model.Post, error)
	ListFeedPosts(ctx context.Context, filter model.PostListFilter) ([]*model.Post, error)
	ListStories(ctx context.Context, filter model.StoryListFilter) ([]*model.Story, error)
	CreateFeedEvents(ctx context.Context, events []model.FeedEvent) error
	ListFeedUserInterests(ctx context.Context, filter model.FeedUserInterestListFilter) ([]model.FeedUserInterest, error)
	ListFeedQualityMetrics(ctx context.Context, filter model.FeedQualityMetricsFilter) ([]model.FeedQualityMetric, error)
	CountPosts(ctx context.Context, filter model.PostListFilter) (int, error)
	CountPublishedPostsByAuthorID(ctx context.Context, authorUserID uuid.UUID) (int, error)
	CountPostsCreatedByAuthorSince(ctx context.Context, authorUserID uuid.UUID, since time.Time) (int, error)
	OldestPostCreatedAtByAuthorSince(ctx context.Context, authorUserID uuid.UUID, since time.Time) (*time.Time, error)
	CreateCommunity(ctx context.Context, community *model.Community) error
	UpdateCommunity(ctx context.Context, community *model.Community) error
	ListCommunities(ctx context.Context, filter model.CommunityListFilter) ([]*model.Community, error)
	GetCommunityByID(ctx context.Context, communityID uuid.UUID) (*model.Community, error)
	GetCommunityBySlug(ctx context.Context, slug string) (*model.Community, error)
	ListCommunityPostProfiles(ctx context.Context, filter model.CommunityPostProfileListFilter) ([]*model.CommunityPostProfile, error)
	ListCommunityBlueprints(ctx context.Context, filter model.CommunityBlueprintListFilter) ([]*model.CommunityBlueprint, error)
	ListCommunityGeoHubs(ctx context.Context, filter model.CommunityGeoHubListFilter) ([]*model.CommunityGeoHub, error)
	ListCommunityInstances(ctx context.Context, filter model.CommunityInstanceListFilter) ([]*model.CommunityInstance, error)
	MaterializeCommunityInstances(ctx context.Context, filter model.CommunityInstanceMaterializationFilter) (*model.CommunityInstanceMaterializationResult, error)
	CreateCommunityReport(ctx context.Context, report *model.CommunityReport) (*model.CommunityReportSubmissionResult, error)
	SetCommunityMuted(ctx context.Context, communityID uuid.UUID, userID uuid.UUID, muted bool) (*model.CommunityMembership, error)
	FollowCommunity(ctx context.Context, communityID uuid.UUID, userID uuid.UUID) (bool, int, error)
	UnfollowCommunity(ctx context.Context, communityID uuid.UUID, userID uuid.UUID) (bool, int, error)
	ListFollowedCommunityIDs(ctx context.Context, userID uuid.UUID, communityIDs []uuid.UUID) (map[uuid.UUID]bool, error)
	ListUserCommunityIDs(ctx context.Context, userID uuid.UUID, limit int, offset int) ([]uuid.UUID, error)
	GetCommunityMembership(ctx context.Context, communityID uuid.UUID, userID uuid.UUID) (*model.CommunityMembership, error)
	ListCommunityMemberships(ctx context.Context, filter model.CommunityMemberListFilter) ([]*model.CommunityMembership, error)
	ListCommunityMemberRoleChanges(ctx context.Context, filter model.CommunityMemberRoleChangeListFilter) ([]*model.CommunityMemberRoleChange, error)
	UpdateCommunityMembershipRole(ctx context.Context, communityID uuid.UUID, userID uuid.UUID, actorUserID uuid.UUID, role enum.CommunityMembershipRole) (*model.CommunityMembership, error)
	UpdateCommunityMembershipStatus(ctx context.Context, communityID uuid.UUID, userID uuid.UUID, actorUserID uuid.UUID, status enum.CommunityMembershipStatus) (*model.CommunityMembership, error)
	LikePost(ctx context.Context, postID uuid.UUID, userID uuid.UUID) (bool, int, error)
	UnlikePost(ctx context.Context, postID uuid.UUID, userID uuid.UUID) (bool, int, error)
	HasPostLike(ctx context.Context, postID uuid.UUID, userID uuid.UUID) (bool, error)
	ListPostLikesByUser(ctx context.Context, postIDs []uuid.UUID, userID uuid.UUID) (map[uuid.UUID]bool, error)
	TrackPostView(ctx context.Context, postID uuid.UUID, viewerUserID uuid.UUID) (bool, int, error)
	MarkPostSeen(ctx context.Context, postID uuid.UUID, viewerUserID uuid.UUID, seenAt time.Time) (time.Time, error)
	ListPostSeenByUser(ctx context.Context, postIDs []uuid.UUID, userID uuid.UUID) (map[uuid.UUID]time.Time, error)
	MarkStorySeen(ctx context.Context, storyID uuid.UUID, viewerUserID uuid.UUID, seenAt time.Time) (time.Time, error)
	ListStorySeenByUser(ctx context.Context, storyIDs []uuid.UUID, userID uuid.UUID) (map[uuid.UUID]time.Time, error)
	LikeStory(ctx context.Context, storyID uuid.UUID, userID uuid.UUID) (bool, int, error)
	IncrementShareCount(ctx context.Context, postID uuid.UUID) (int, error)
	CreateComment(ctx context.Context, comment *model.PostComment, rateLimitAfter time.Time) error
	UpdateComment(ctx context.Context, comment *model.PostComment) error
	GetLatestActiveCommentByAuthor(ctx context.Context, postID uuid.UUID, authorUserID uuid.UUID) (*model.PostComment, error)
	GetCommentByID(ctx context.Context, postID uuid.UUID, commentID uuid.UUID) (*model.PostComment, error)
	ListComments(ctx context.Context, postID uuid.UUID, limit int, offset int) ([]*model.PostComment, error)
	DeleteComment(ctx context.Context, postID uuid.UUID, commentID uuid.UUID) (bool, error)
	LikeComment(ctx context.Context, postID uuid.UUID, commentID uuid.UUID, userID uuid.UUID) (bool, int, error)
	UnlikeComment(ctx context.Context, postID uuid.UUID, commentID uuid.UUID, userID uuid.UUID) (bool, int, error)
	HasCommentLike(ctx context.Context, commentID uuid.UUID, userID uuid.UUID) (bool, error)
}

type PostModerationOutboxRepository interface {
	ListDuePostModerationOutboxEvents(ctx context.Context, limit int, now time.Time) ([]model.PostModerationOutboxEvent, error)
	MarkPostModerationOutboxDelivered(ctx context.Context, eventID uuid.UUID, deliveredAt time.Time) error
	MarkPostModerationOutboxFailed(ctx context.Context, eventID uuid.UUID, reason string, nextAttemptAt time.Time) error
}

type PostModerationOutboxPublisher interface {
	PublishPostModerationOutboxEvent(ctx context.Context, event model.PostModerationOutboxEvent) (bool, error)
}

type PostFeedProjectionRepository interface {
	ListDuePostFeedProjectionEvents(ctx context.Context, limit int, now time.Time) ([]model.PostFeedProjectionOutboxEvent, error)
	ProjectPostFeedItem(ctx context.Context, event model.PostFeedProjectionOutboxEvent) (bool, error)
	MarkPostFeedProjectionOutboxDelivered(ctx context.Context, eventID uuid.UUID, deliveredAt time.Time) error
	MarkPostFeedProjectionOutboxFailed(ctx context.Context, eventID uuid.UUID, reason string, nextAttemptAt time.Time) error
}

type PostActivityIntentRepository interface {
	ListDuePostActivityIntentEvents(ctx context.Context, limit int, now time.Time) ([]model.PostActivityIntentEvent, error)
	MarkPostActivityIntentDelivered(ctx context.Context, eventID uuid.UUID, postID uuid.UUID, sourceActivityID uuid.UUID, deliveredAt time.Time) error
	MarkPostActivityIntentFailed(ctx context.Context, eventID uuid.UUID, postID uuid.UUID, reason string, nextAttemptAt time.Time, terminal bool) error
}

type PostActivityIntentPublisher interface {
	PublishPostActivityIntent(ctx context.Context, event model.PostActivityIntentEvent) (uuid.UUID, error)
}

type PostFeedCache interface {
	GetPosts(ctx context.Context, key string) ([]*model.Post, bool, error)
	SetPosts(ctx context.Context, key string, posts []*model.Post, ttl time.Duration) error
	CurrentVersion(ctx context.Context, scope string) (int64, error)
	BumpVersion(ctx context.Context, scopes ...string) error
}
