package port

import (
	"context"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/stories-service/internal/domain/model"
)

type StoryRepository interface {
	CreateStory(ctx context.Context, story *model.Story) error
	UpdateStory(ctx context.Context, story *model.Story) error
	SoftDeleteStory(ctx context.Context, storyID uuid.UUID, authorUserID uuid.UUID) error
	GetStoryByID(ctx context.Context, storyID uuid.UUID) (*model.Story, error)
	GetStoryBySlug(ctx context.Context, slug string) (*model.Story, error)
	ListStories(ctx context.Context, filter model.StoryListFilter) ([]*model.Story, error)
	LikeStory(ctx context.Context, storyID uuid.UUID, userID uuid.UUID) (bool, int, error)
	UnlikeStory(ctx context.Context, storyID uuid.UUID, userID uuid.UUID) (bool, int, error)
	HasStoryLike(ctx context.Context, storyID uuid.UUID, userID uuid.UUID) (bool, error)
	TrackStoryView(ctx context.Context, storyID uuid.UUID, viewerUserID uuid.UUID) (bool, int, error)
	IncrementShareCount(ctx context.Context, storyID uuid.UUID) (int, error)
	CreateComment(ctx context.Context, comment *model.StoryComment) error
	UpdateComment(ctx context.Context, comment *model.StoryComment) error
	GetCommentByID(ctx context.Context, storyID uuid.UUID, commentID uuid.UUID) (*model.StoryComment, error)
	ListComments(ctx context.Context, storyID uuid.UUID, limit int, offset int) ([]*model.StoryComment, error)
	DeleteComment(ctx context.Context, storyID uuid.UUID, commentID uuid.UUID) (bool, error)
}
