package repository

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/feed-service/internal/domain/model"
)

func (r *PGPostRepository) UpsertFeedSocialEdge(ctx context.Context, edge model.FeedSocialEdge) (bool, error) {
	edgeType := normalizeFeedSocialEdgeType(edge.EdgeType)
	if edge.ViewerUserID == uuid.Nil || edge.TargetUserID == uuid.Nil || edge.ViewerUserID == edge.TargetUserID || edgeType == "" {
		return false, fmt.Errorf("invalid feed social edge")
	}
	sourceUpdatedAt := edge.SourceUpdatedAt.UTC()
	if sourceUpdatedAt.IsZero() {
		sourceUpdatedAt = time.Now().UTC()
	}

	const query = `
		INSERT INTO post_feed_social_edges (
			viewer_user_id, target_user_id, edge_type, active, source_event_id, source_updated_at, created_at, updated_at
		)
		VALUES ($1, $2, $3, true, $4, $5, NOW(), NOW())
		ON CONFLICT (viewer_user_id, target_user_id, edge_type) DO UPDATE
		SET active = true,
		    source_event_id = EXCLUDED.source_event_id,
		    source_updated_at = EXCLUDED.source_updated_at,
		    updated_at = NOW()
		WHERE post_feed_social_edges.source_updated_at < EXCLUDED.source_updated_at
		   OR (
		       post_feed_social_edges.source_updated_at = EXCLUDED.source_updated_at
		       AND (
		           post_feed_social_edges.active IS DISTINCT FROM true
		           OR post_feed_social_edges.source_event_id IS DISTINCT FROM EXCLUDED.source_event_id
		       )
		   )
	`

	tag, err := r.pool.Exec(ctx, query, edge.ViewerUserID, edge.TargetUserID, edgeType, edge.SourceEventID, sourceUpdatedAt)
	if err != nil {
		return false, fmt.Errorf("upsert feed social edge: %w", err)
	}
	return tag.RowsAffected() > 0, nil
}

func (r *PGPostRepository) DeleteFeedSocialEdge(
	ctx context.Context,
	viewerUserID uuid.UUID,
	targetUserID uuid.UUID,
	edgeType string,
	sourceUpdatedAt time.Time,
) (bool, error) {
	normalizedEdgeType := normalizeFeedSocialEdgeType(edgeType)
	if viewerUserID == uuid.Nil || targetUserID == uuid.Nil || viewerUserID == targetUserID || normalizedEdgeType == "" {
		return false, fmt.Errorf("invalid feed social edge")
	}
	sourceUpdatedAt = sourceUpdatedAt.UTC()
	if sourceUpdatedAt.IsZero() {
		sourceUpdatedAt = time.Now().UTC()
	}

	const query = `
		INSERT INTO post_feed_social_edges (
			viewer_user_id, target_user_id, edge_type, active, source_updated_at, created_at, updated_at
		)
		VALUES ($1, $2, $3, false, $4, NOW(), NOW())
		ON CONFLICT (viewer_user_id, target_user_id, edge_type) DO UPDATE
		SET active = false,
		    source_updated_at = EXCLUDED.source_updated_at,
		    updated_at = NOW()
		WHERE post_feed_social_edges.source_updated_at < EXCLUDED.source_updated_at
		   OR (
		       post_feed_social_edges.source_updated_at = EXCLUDED.source_updated_at
		       AND post_feed_social_edges.active IS DISTINCT FROM false
		   )
	`

	tag, err := r.pool.Exec(ctx, query, viewerUserID, targetUserID, normalizedEdgeType, sourceUpdatedAt)
	if err != nil {
		return false, fmt.Errorf("delete feed social edge: %w", err)
	}
	return tag.RowsAffected() > 0, nil
}

func (r *PGPostRepository) ListFeedSocialEdges(
	ctx context.Context,
	viewerUserID uuid.UUID,
	targetUserIDs []uuid.UUID,
) (map[uuid.UUID]model.FeedSocialEdgeSet, error) {
	if viewerUserID == uuid.Nil || len(targetUserIDs) == 0 {
		return map[uuid.UUID]model.FeedSocialEdgeSet{}, nil
	}

	seen := make(map[uuid.UUID]struct{}, len(targetUserIDs))
	ids := make([]uuid.UUID, 0, len(targetUserIDs))
	for _, id := range targetUserIDs {
		if id == uuid.Nil || id == viewerUserID {
			continue
		}
		if _, ok := seen[id]; ok {
			continue
		}
		seen[id] = struct{}{}
		ids = append(ids, id)
	}
	if len(ids) == 0 {
		return map[uuid.UUID]model.FeedSocialEdgeSet{}, nil
	}

	const query = `
		SELECT target_user_id, edge_type
		FROM post_feed_social_edges
		WHERE viewer_user_id = $1
		  AND target_user_id = ANY($2::uuid[])
		  AND active = true
	`

	rows, err := r.pool.Query(ctx, query, viewerUserID, ids)
	if err != nil {
		return nil, fmt.Errorf("query feed social edges: %w", err)
	}
	defer rows.Close()

	result := make(map[uuid.UUID]model.FeedSocialEdgeSet, len(ids))
	for rows.Next() {
		var targetUserID uuid.UUID
		var edgeType string
		if err = rows.Scan(&targetUserID, &edgeType); err != nil {
			return nil, fmt.Errorf("scan feed social edge: %w", err)
		}
		set := result[targetUserID]
		switch normalizeFeedSocialEdgeType(edgeType) {
		case model.FeedSocialEdgeTypeFriend:
			set.Friend = true
		case model.FeedSocialEdgeTypeFollowing:
			set.Following = true
		}
		result[targetUserID] = set
	}

	return result, rows.Err()
}

func normalizeFeedSocialEdgeType(value string) string {
	switch strings.ToLower(strings.TrimSpace(value)) {
	case model.FeedSocialEdgeTypeFriend:
		return model.FeedSocialEdgeTypeFriend
	case model.FeedSocialEdgeTypeFollowing:
		return model.FeedSocialEdgeTypeFollowing
	default:
		return ""
	}
}
