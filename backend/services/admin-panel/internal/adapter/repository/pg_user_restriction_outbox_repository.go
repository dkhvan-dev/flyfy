package repository

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/dkhvan-dev/flyfy/backend/services/admin-panel/internal/domain/model"
)

type PGUserRestrictionOutboxRepository struct {
	pool *pgxpool.Pool
}

func NewPGUserRestrictionOutboxRepository(pool *pgxpool.Pool) *PGUserRestrictionOutboxRepository {
	return &PGUserRestrictionOutboxRepository{pool: pool}
}

func (r *PGUserRestrictionOutboxRepository) ListDueUserRestrictionEvents(
	ctx context.Context,
	limit int,
	now time.Time,
) ([]model.UserRestrictionOutboxEvent, error) {
	if limit <= 0 {
		limit = 50
	}
	if now.IsZero() {
		now = time.Now().UTC()
	}

	rows, err := r.pool.Query(ctx, `
		WITH due AS (
			SELECT id
			FROM user_restriction_outbox
			WHERE status = 'PENDING'
			  AND next_attempt_at <= $1
			ORDER BY created_at ASC, id ASC
			LIMIT $2
			FOR UPDATE SKIP LOCKED
		)
		UPDATE user_restriction_outbox AS outbox
		SET next_attempt_at = $1 + INTERVAL '30 seconds'
		FROM due
		WHERE outbox.id = due.id
		RETURNING outbox.id, outbox.event_type, outbox.aggregate_id, outbox.user_id,
		          outbox.payload, outbox.status, outbox.attempt_count,
		          outbox.next_attempt_at, outbox.last_error, outbox.created_at,
		          outbox.delivered_at
	`, now, limit)
	if err != nil {
		return nil, fmt.Errorf("list due user restriction outbox events: %w", err)
	}
	defer rows.Close()

	items := make([]model.UserRestrictionOutboxEvent, 0)
	for rows.Next() {
		item, scanErr := scanUserRestrictionOutboxEvent(rows)
		if scanErr != nil {
			return nil, scanErr
		}
		items = append(items, item)
	}
	return items, rows.Err()
}

func (r *PGUserRestrictionOutboxRepository) MarkUserRestrictionEventDelivered(
	ctx context.Context,
	eventID uuid.UUID,
	deliveredAt time.Time,
) error {
	if deliveredAt.IsZero() {
		deliveredAt = time.Now().UTC()
	}
	if _, err := r.pool.Exec(ctx, `
		UPDATE user_restriction_outbox
		SET status = 'DELIVERED',
		    delivered_at = $2,
		    last_error = ''
		WHERE id = $1
		  AND status <> 'DELIVERED'
	`, eventID, deliveredAt); err != nil {
		return fmt.Errorf("mark user restriction outbox delivered: %w", err)
	}
	return nil
}

func (r *PGUserRestrictionOutboxRepository) MarkUserRestrictionEventFailed(
	ctx context.Context,
	eventID uuid.UUID,
	reason string,
	nextAttemptAt time.Time,
) error {
	if nextAttemptAt.IsZero() {
		nextAttemptAt = time.Now().UTC().Add(time.Second)
	}
	if _, err := r.pool.Exec(ctx, `
		UPDATE user_restriction_outbox
		SET attempt_count = attempt_count + 1,
		    status = CASE WHEN attempt_count + 1 >= 20 THEN 'DEAD' ELSE 'PENDING' END,
		    last_error = $2,
		    next_attempt_at = $3
		WHERE id = $1
		  AND status = 'PENDING'
	`, eventID, reason, nextAttemptAt); err != nil {
		return fmt.Errorf("mark user restriction outbox failed: %w", err)
	}
	return nil
}

func scanUserRestrictionOutboxEvent(row staffScanner) (model.UserRestrictionOutboxEvent, error) {
	var item model.UserRestrictionOutboxEvent
	var status string
	if err := row.Scan(
		&item.ID,
		&item.EventType,
		&item.AggregateID,
		&item.UserID,
		&item.Payload,
		&status,
		&item.AttemptCount,
		&item.NextAttemptAt,
		&item.LastError,
		&item.CreatedAt,
		&item.DeliveredAt,
	); err != nil {
		return model.UserRestrictionOutboxEvent{}, err
	}
	item.Status = model.UserRestrictionOutboxStatus(status)
	return item, nil
}
