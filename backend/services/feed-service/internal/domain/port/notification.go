package port

import (
	"context"

	"github.com/google/uuid"
)

type PostLikeNotificationInput struct {
	PostID           uuid.UUID
	PostSlug         string
	PostTitle        string
	PostCoverFileID  *uuid.UUID
	PostAuthorUserID uuid.UUID
	ActorUserID      uuid.UUID
	ActorDisplayName string
}

type StoryLikeNotificationInput struct {
	StoryID            uuid.UUID
	StoryCaption       string
	StoryPreviewFileID *uuid.UUID
	StoryAuthorUserID  uuid.UUID
	ActorUserID        uuid.UUID
	ActorDisplayName   string
}

type PostNotificationGateway interface {
	SendPostLikeNotification(ctx context.Context, input PostLikeNotificationInput) error
	SendStoryLikeNotification(ctx context.Context, input StoryLikeNotificationInput) error
}
