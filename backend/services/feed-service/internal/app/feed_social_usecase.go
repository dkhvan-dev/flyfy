package app

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/feed-service/internal/domain/model"
)

type ApplyFeedSocialEventInput struct {
	EventID         uuid.UUID
	ViewerUserID    uuid.UUID
	TargetUserID    uuid.UUID
	EdgeType        string
	Active          bool
	SourceUpdatedAt time.Time
}

func (u *PostUseCase) ApplyFeedSocialEvent(ctx context.Context, input ApplyFeedSocialEventInput) error {
	edgeType := normalizeFeedSocialEdgeInputType(input.EdgeType)
	if input.EventID == uuid.Nil ||
		input.ViewerUserID == uuid.Nil ||
		input.TargetUserID == uuid.Nil ||
		input.ViewerUserID == input.TargetUserID ||
		edgeType == "" {
		return ErrInvalidFeedEvent
	}

	sourceUpdatedAt := input.SourceUpdatedAt.UTC()
	if sourceUpdatedAt.IsZero() {
		sourceUpdatedAt = time.Now().UTC()
	}

	changed := false
	var err error
	if input.Active {
		changed, err = u.repo.UpsertFeedSocialEdge(ctx, model.FeedSocialEdge{
			ViewerUserID:    input.ViewerUserID,
			TargetUserID:    input.TargetUserID,
			EdgeType:        edgeType,
			SourceEventID:   &input.EventID,
			SourceUpdatedAt: sourceUpdatedAt,
		})
	} else {
		changed, err = u.repo.DeleteFeedSocialEdge(
			ctx,
			input.ViewerUserID,
			input.TargetUserID,
			edgeType,
			sourceUpdatedAt,
		)
	}
	if err != nil {
		return fmt.Errorf("apply feed social edge: %w", err)
	}
	if !changed {
		return nil
	}

	u.bumpPostFeedCacheScopes(
		ctx,
		postFeedCacheViewerScope(input.ViewerUserID),
		postFeedCacheFollowingScope(input.ViewerUserID),
		postFeedCacheDiscoveryScope(input.ViewerUserID),
	)
	return nil
}

func normalizeFeedSocialEdgeInputType(value string) string {
	switch strings.ToLower(strings.TrimSpace(value)) {
	case model.FeedSocialEdgeTypeFriend:
		return model.FeedSocialEdgeTypeFriend
	case model.FeedSocialEdgeTypeFollowing:
		return model.FeedSocialEdgeTypeFollowing
	default:
		return ""
	}
}
