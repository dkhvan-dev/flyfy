package repository

import (
	"context"
	"encoding/json"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"

	"kz/inflap/backend/services/feed-service/internal/domain/enum"
	"kz/inflap/backend/services/feed-service/internal/domain/model"
)

func enqueuePostActivityIntentForPostTx(ctx context.Context, tx pgx.Tx, post *model.Post) error {
	if post == nil ||
		post.PublishedAt == nil ||
		post.ActivityCreationStatus == nil ||
		*post.ActivityCreationStatus != enum.ActivityCreationStatusPending {
		return nil
	}

	createdAt := post.UpdatedAt
	if createdAt.IsZero() {
		createdAt = time.Now().UTC()
	}
	idempotencyKey := postActivityIntentIdempotencyKey(post.ID)
	payload, err := json.Marshal(map[string]any{
		"eventType":           model.PostActivityIntentEventRequested,
		"idempotencyKey":      idempotencyKey,
		"postId":              post.ID,
		"authorUserId":        post.AuthorUserID,
		"communityId":         post.CommunityID,
		"communityInstanceId": post.CommunityInstanceID,
		"postProfileKey":      post.PostProfileKey,
		"postProfileVersion":  post.PostProfileVersion,
		"structuredData":      post.StructuredData,
	})
	if err != nil {
		return fmt.Errorf("marshal post activity intent payload: %w", err)
	}

	const query = `
		INSERT INTO post_activity_intents (
			id, event_type, idempotency_key, post_id, author_user_id, community_id,
			community_instance_id, post_profile_key, post_profile_version,
			structured_data, payload, status, next_attempt_at, created_at
		) VALUES (
			$1, $2, $3, $4, $5, $6,
			$7, $8, $9,
			$10, $11, 'PENDING', $12, $12
		)
		ON CONFLICT (idempotency_key) DO UPDATE SET
			author_user_id = EXCLUDED.author_user_id,
			community_id = EXCLUDED.community_id,
			community_instance_id = EXCLUDED.community_instance_id,
			post_profile_key = EXCLUDED.post_profile_key,
			post_profile_version = EXCLUDED.post_profile_version,
			structured_data = EXCLUDED.structured_data,
			payload = EXCLUDED.payload,
			next_attempt_at = CASE
				WHEN post_activity_intents.status = 'DELIVERED' THEN post_activity_intents.next_attempt_at
				ELSE EXCLUDED.next_attempt_at
			END,
			status = CASE
				WHEN post_activity_intents.status = 'DELIVERED' THEN post_activity_intents.status
				ELSE 'PENDING'
			END,
			last_error = CASE
				WHEN post_activity_intents.status = 'DELIVERED' THEN post_activity_intents.last_error
				ELSE ''
			END
	`
	if _, err = tx.Exec(
		ctx,
		query,
		uuid.New(),
		model.PostActivityIntentEventRequested,
		idempotencyKey,
		post.ID,
		post.AuthorUserID,
		post.CommunityID,
		post.CommunityInstanceID,
		string(post.PostProfileKey),
		post.PostProfileVersion,
		post.StructuredData,
		payload,
		createdAt,
	); err != nil {
		return fmt.Errorf("insert post activity intent: %w", err)
	}
	return nil
}

func postActivityIntentIdempotencyKey(postID uuid.UUID) string {
	return "post:" + postID.String() + ":activity:v1"
}

func (r *PGPostRepository) ListDuePostActivityIntentEvents(
	ctx context.Context,
	limit int,
	now time.Time,
) ([]model.PostActivityIntentEvent, error) {
	if limit <= 0 {
		limit = 50
	}
	if now.IsZero() {
		now = time.Now().UTC()
	}

	rows, err := r.pool.Query(ctx, `
		WITH due AS (
			SELECT id
			FROM post_activity_intents
			WHERE status = 'PENDING'
			  AND next_attempt_at <= $1
			ORDER BY created_at ASC, id ASC
			LIMIT $2
			FOR UPDATE SKIP LOCKED
		)
		UPDATE post_activity_intents AS outbox
		SET next_attempt_at = $1 + INTERVAL '30 seconds'
		FROM due
		WHERE outbox.id = due.id
		RETURNING outbox.id, outbox.event_type, outbox.idempotency_key, outbox.post_id,
		          outbox.author_user_id, outbox.community_id, outbox.community_instance_id,
		          outbox.post_profile_key, outbox.post_profile_version, outbox.structured_data,
		          outbox.payload, outbox.status, outbox.attempt_count, outbox.next_attempt_at,
		          outbox.last_error, outbox.created_at, outbox.delivered_at
	`, now, limit)
	if err != nil {
		return nil, fmt.Errorf("list due post activity intent events: %w", err)
	}
	defer rows.Close()

	items := make([]model.PostActivityIntentEvent, 0)
	for rows.Next() {
		item, scanErr := scanPostActivityIntentEvent(rows)
		if scanErr != nil {
			return nil, fmt.Errorf("scan post activity intent event: %w", scanErr)
		}
		items = append(items, item)
	}
	return items, rows.Err()
}

func (r *PGPostRepository) MarkPostActivityIntentDelivered(
	ctx context.Context,
	eventID uuid.UUID,
	postID uuid.UUID,
	sourceActivityID uuid.UUID,
	deliveredAt time.Time,
) error {
	if deliveredAt.IsZero() {
		deliveredAt = time.Now().UTC()
	}
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return fmt.Errorf("begin post activity intent delivery transaction: %w", err)
	}
	defer func() { _ = tx.Rollback(ctx) }()

	if _, err = tx.Exec(ctx, `
		UPDATE post_activity_intents
		SET status = 'DELIVERED',
		    delivered_at = $2,
		    last_error = ''
		WHERE id = $1
		  AND status <> 'DELIVERED'
	`, eventID, deliveredAt); err != nil {
		return fmt.Errorf("mark post activity intent delivered: %w", err)
	}
	if _, err = tx.Exec(ctx, `
		UPDATE posts
		SET source_activity_id = $2,
		    activity_creation_status = 'CREATED',
		    activity_creation_error = NULL,
		    updated_at = now()
		WHERE id = $1
	`, postID, sourceActivityID); err != nil {
		return fmt.Errorf("mark post activity created: %w", err)
	}
	if err = tx.Commit(ctx); err != nil {
		return fmt.Errorf("commit post activity intent delivery transaction: %w", err)
	}
	return nil
}

func (r *PGPostRepository) MarkPostActivityIntentFailed(
	ctx context.Context,
	eventID uuid.UUID,
	postID uuid.UUID,
	reason string,
	nextAttemptAt time.Time,
	terminal bool,
) error {
	if nextAttemptAt.IsZero() {
		nextAttemptAt = time.Now().UTC().Add(time.Second)
	}
	status := "PENDING"
	postActivityStatus := "PENDING"
	if terminal {
		status = "DEAD"
		postActivityStatus = "FAILED"
	}
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return fmt.Errorf("begin post activity intent failure transaction: %w", err)
	}
	defer func() { _ = tx.Rollback(ctx) }()

	safeReason := safePostActivityIntentError(reason)
	if _, err = tx.Exec(ctx, `
		UPDATE post_activity_intents
		SET attempt_count = attempt_count + 1,
		    status = $4,
		    last_error = $2,
		    next_attempt_at = $3
		WHERE id = $1
		  AND status = 'PENDING'
	`, eventID, safeReason, nextAttemptAt, status); err != nil {
		return fmt.Errorf("mark post activity intent failed: %w", err)
	}
	if _, err = tx.Exec(ctx, `
		UPDATE posts
		SET activity_creation_status = $2,
		    activity_creation_error = $3,
		    updated_at = now()
		WHERE id = $1
	`, postID, postActivityStatus, safeReason); err != nil {
		return fmt.Errorf("mark post activity creation failed: %w", err)
	}
	if err = tx.Commit(ctx); err != nil {
		return fmt.Errorf("commit post activity intent failure transaction: %w", err)
	}
	return nil
}

func safePostActivityIntentError(reason string) string {
	value := strings.TrimSpace(reason)
	if len(value) > 512 {
		return value[:512]
	}
	return value
}

func scanPostActivityIntentEvent(scanner interface{ Scan(dest ...any) error }) (model.PostActivityIntentEvent, error) {
	var (
		item      model.PostActivityIntentEvent
		statusRaw string
	)
	if err := scanner.Scan(
		&item.ID,
		&item.EventType,
		&item.IdempotencyKey,
		&item.PostID,
		&item.AuthorUserID,
		&item.CommunityID,
		&item.CommunityInstanceID,
		&item.PostProfileKey,
		&item.PostProfileVersion,
		&item.StructuredData,
		&item.Payload,
		&statusRaw,
		&item.AttemptCount,
		&item.NextAttemptAt,
		&item.LastError,
		&item.CreatedAt,
		&item.DeliveredAt,
	); err != nil {
		return model.PostActivityIntentEvent{}, err
	}
	item.Status = model.PostActivityIntentStatus(statusRaw)
	return item, nil
}
