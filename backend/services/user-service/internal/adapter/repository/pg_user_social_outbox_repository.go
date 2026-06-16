package repository

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"

	"kz/inflap/backend/services/user-service/internal/domain/model"
)

func (r *PGUserRepository) ListDueUserSocialOutboxEvents(
	ctx context.Context,
	limit int,
	now time.Time,
) ([]model.UserSocialOutboxEvent, error) {
	if limit <= 0 || limit > 500 {
		limit = 50
	}
	if now.IsZero() {
		now = time.Now().UTC()
	}

	rows, err := r.pool.Query(ctx, `
		WITH due AS (
			SELECT id
			FROM user_social_outbox
			WHERE status = 'PENDING'
			  AND next_attempt_at <= $1
			ORDER BY created_at ASC, id ASC
			LIMIT $2
			FOR UPDATE SKIP LOCKED
		)
		UPDATE user_social_outbox AS outbox
		SET next_attempt_at = $1 + INTERVAL '30 seconds'
		FROM due
		WHERE outbox.id = due.id
		RETURNING outbox.id, outbox.event_type, outbox.viewer_user_id, outbox.target_user_id,
		          outbox.edge_type, outbox.active, outbox.source_updated_at, outbox.status,
		          outbox.attempt_count, outbox.next_attempt_at, outbox.last_error,
		          outbox.created_at, outbox.delivered_at
	`, now, limit)
	if err != nil {
		return nil, fmt.Errorf("list due user social outbox events: %w", err)
	}
	defer rows.Close()

	items := make([]model.UserSocialOutboxEvent, 0)
	for rows.Next() {
		item, scanErr := scanUserSocialOutboxEvent(rows)
		if scanErr != nil {
			return nil, fmt.Errorf("scan user social outbox event: %w", scanErr)
		}
		items = append(items, item)
	}
	return items, rows.Err()
}

func (r *PGUserRepository) BackfillFeedSocialOutbox(ctx context.Context, now time.Time) (int64, error) {
	if now.IsZero() {
		now = time.Now().UTC()
	}
	tag, err := r.pool.Exec(ctx, `
		WITH follow_edges AS (
			SELECT
				concat('backfill:following:', follower_user_id::text, ':', followed_user_id::text) AS source_key,
				'user.follow.created'::text AS event_type,
				follower_user_id AS viewer_user_id,
				followed_user_id AS target_user_id,
				'following'::text AS edge_type,
				true AS active,
				created_at AS source_updated_at
			FROM user_follows
			WHERE follower_user_id <> followed_user_id
		),
		friend_edges AS (
			SELECT
				concat('backfill:friend:', requester_user_id::text, ':', addressee_user_id::text) AS source_key,
				'user.friendship.created'::text AS event_type,
				requester_user_id AS viewer_user_id,
				addressee_user_id AS target_user_id,
				'friend'::text AS edge_type,
				true AS active,
				COALESCE(responded_at, updated_at, requested_at, $1) AS source_updated_at
			FROM user_friendships
			WHERE status = 'ACCEPTED'
			  AND requester_user_id <> addressee_user_id
			UNION ALL
			SELECT
				concat('backfill:friend:', addressee_user_id::text, ':', requester_user_id::text) AS source_key,
				'user.friendship.created'::text AS event_type,
				addressee_user_id AS viewer_user_id,
				requester_user_id AS target_user_id,
				'friend'::text AS edge_type,
				true AS active,
				COALESCE(responded_at, updated_at, requested_at, $1) AS source_updated_at
			FROM user_friendships
			WHERE status = 'ACCEPTED'
			  AND requester_user_id <> addressee_user_id
		),
		edges AS (
			SELECT * FROM follow_edges
			UNION ALL
			SELECT * FROM friend_edges
		)
		INSERT INTO user_social_outbox (
			id, event_type, viewer_user_id, target_user_id, edge_type, active, source_key,
			source_updated_at, next_attempt_at, created_at
		)
		SELECT gen_random_uuid(), event_type, viewer_user_id, target_user_id, edge_type, active, source_key,
		       source_updated_at, $1, $1
		FROM edges
		ON CONFLICT (source_key) DO NOTHING
	`, now.UTC())
	if err != nil {
		return 0, fmt.Errorf("backfill feed social outbox: %w", err)
	}
	return tag.RowsAffected(), nil
}

func (r *PGUserRepository) MarkUserSocialOutboxDelivered(ctx context.Context, eventID uuid.UUID, deliveredAt time.Time) error {
	if deliveredAt.IsZero() {
		deliveredAt = time.Now().UTC()
	}
	if _, err := r.pool.Exec(ctx, `
		UPDATE user_social_outbox
		SET status = 'DELIVERED',
		    delivered_at = $2,
		    last_error = ''
		WHERE id = $1
		  AND status <> 'DELIVERED'
	`, eventID, deliveredAt); err != nil {
		return fmt.Errorf("mark user social outbox delivered: %w", err)
	}
	return nil
}

func (r *PGUserRepository) MarkUserSocialOutboxFailed(
	ctx context.Context,
	eventID uuid.UUID,
	reason string,
	nextAttemptAt time.Time,
) error {
	if nextAttemptAt.IsZero() {
		nextAttemptAt = time.Now().UTC().Add(time.Second)
	}
	if _, err := r.pool.Exec(ctx, `
		UPDATE user_social_outbox
		SET attempt_count = attempt_count + 1,
		    status = CASE WHEN attempt_count + 1 >= 20 THEN 'DEAD' ELSE 'PENDING' END,
		    last_error = $2,
		    next_attempt_at = $3
		WHERE id = $1
		  AND status = 'PENDING'
	`, eventID, strings.TrimSpace(reason), nextAttemptAt); err != nil {
		return fmt.Errorf("mark user social outbox failed: %w", err)
	}
	return nil
}

func scanUserSocialOutboxEvent(row pgx.Row) (model.UserSocialOutboxEvent, error) {
	var item model.UserSocialOutboxEvent
	err := row.Scan(
		&item.ID,
		&item.EventType,
		&item.ViewerUserID,
		&item.TargetUserID,
		&item.EdgeType,
		&item.Active,
		&item.SourceUpdatedAt,
		&item.Status,
		&item.AttemptCount,
		&item.NextAttemptAt,
		&item.LastError,
		&item.CreatedAt,
		&item.DeliveredAt,
	)
	return item, err
}
