package app

import (
	"context"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"kz/inflap/backend/services/feed-service/internal/domain/model"
	"kz/inflap/backend/services/feed-service/internal/domain/port"
)

const postLikeNotificationTimeout = 3 * time.Second

func (u *PostUseCase) notifyPostLiked(ctx context.Context, post *model.Post, actorUserID uuid.UUID) {
	if u == nil ||
		u.postNotifications == nil ||
		post == nil ||
		post.ID == uuid.Nil ||
		post.AuthorUserID == uuid.Nil ||
		actorUserID == uuid.Nil ||
		post.AuthorUserID == actorUserID {
		return
	}

	postID := post.ID
	postSlug := post.Slug
	postTitle := post.Title
	postAuthorUserID := post.AuthorUserID
	var coverFileID *uuid.UUID
	if post.CoverFileID != nil && *post.CoverFileID != uuid.Nil {
		value := *post.CoverFileID
		coverFileID = &value
	}

	notifyCtx, cancel := context.WithTimeout(context.WithoutCancel(ctx), postLikeNotificationTimeout)
	go func() {
		defer cancel()
		actorDisplayName := u.postNotificationActorName(notifyCtx, actorUserID)
		if err := u.postNotifications.SendPostLikeNotification(
			notifyCtx,
			port.PostLikeNotificationInput{
				PostID:           postID,
				PostSlug:         postSlug,
				PostTitle:        postTitle,
				PostCoverFileID:  coverFileID,
				PostAuthorUserID: postAuthorUserID,
				ActorUserID:      actorUserID,
				ActorDisplayName: actorDisplayName,
			},
		); err != nil {
			log.Warn().
				Err(err).
				Str("post_id", postID.String()).
				Str("actor_user_id", actorUserID.String()).
				Str("author_user_id", postAuthorUserID.String()).
				Msg("failed to send post like notification")
		}
	}()
}

func (u *PostUseCase) notifyStoryLiked(ctx context.Context, story *model.Story, actorUserID uuid.UUID) {
	if u == nil ||
		u.postNotifications == nil ||
		story == nil ||
		story.ID == uuid.Nil ||
		story.AuthorUserID == uuid.Nil ||
		actorUserID == uuid.Nil ||
		story.AuthorUserID == actorUserID {
		return
	}

	storyID := story.ID
	storyCaption := story.Caption
	storyAuthorUserID := story.AuthorUserID
	var previewFileID *uuid.UUID
	if story.CoverFileID != uuid.Nil {
		value := story.CoverFileID
		previewFileID = &value
	}

	notifyCtx, cancel := context.WithTimeout(context.WithoutCancel(ctx), postLikeNotificationTimeout)
	go func() {
		defer cancel()
		actorDisplayName := u.postNotificationActorName(notifyCtx, actorUserID)
		if err := u.postNotifications.SendStoryLikeNotification(
			notifyCtx,
			port.StoryLikeNotificationInput{
				StoryID:            storyID,
				StoryCaption:       storyCaption,
				StoryPreviewFileID: previewFileID,
				StoryAuthorUserID:  storyAuthorUserID,
				ActorUserID:        actorUserID,
				ActorDisplayName:   actorDisplayName,
			},
		); err != nil {
			log.Warn().
				Err(err).
				Str("story_id", storyID.String()).
				Str("actor_user_id", actorUserID.String()).
				Str("author_user_id", storyAuthorUserID.String()).
				Msg("failed to send story like notification")
		}
	}()
}

func (u *PostUseCase) postNotificationActorName(ctx context.Context, actorUserID uuid.UUID) string {
	fallback := postNotificationFallbackUserName(actorUserID)
	if u == nil || u.users == nil || actorUserID == uuid.Nil {
		return fallback
	}
	profiles, err := u.users.GetPublicUserProfiles(ctx, []uuid.UUID{actorUserID})
	if err != nil {
		log.Warn().Err(err).Str("actor_user_id", actorUserID.String()).Msg("failed to resolve post like actor profile")
		return fallback
	}
	profile := profiles[actorUserID]
	if profile.Nickname == nil {
		return fallback
	}
	nickname := strings.TrimSpace(*profile.Nickname)
	nickname = strings.TrimPrefix(nickname, "@")
	if nickname == "" {
		return fallback
	}
	return nickname
}

func postNotificationFallbackUserName(userID uuid.UUID) string {
	if userID == uuid.Nil {
		return "user"
	}
	compact := strings.ReplaceAll(userID.String(), "-", "")
	if len(compact) > 8 {
		compact = compact[:8]
	}
	return "user_" + compact
}
