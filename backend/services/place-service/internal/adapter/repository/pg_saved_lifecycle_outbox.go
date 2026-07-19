package repository

import (
	"context"
	"errors"
	"fmt"
	"regexp"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"kz/inflap/backend/services/place-service/internal/domain/model"
)

const savedLifecycleTerminalRetentionSQL = "INTERVAL '14 days'"

var (
	ErrSavedLifecycleLeaseLost = errors.New("Saved lifecycle outbox lease lost")
	savedLifecycleErrorCodeRE  = regexp.MustCompile(`^[A-Z][A-Z0-9_]{0,63}$`)
)

type PGSavedLifecycleOutboxRepository struct {
	pool *pgxpool.Pool
}

func NewPGSavedLifecycleOutboxRepository(
	pool *pgxpool.Pool,
) *PGSavedLifecycleOutboxRepository {
	return &PGSavedLifecycleOutboxRepository{pool: pool}
}

func (repository *PGSavedLifecycleOutboxRepository) ClaimDueSavedLifecycleEvents(
	ctx context.Context,
	now time.Time,
	leaseCutoff time.Time,
	limit int,
) ([]model.ClaimedSavedLifecycleEvent, error) {
	if repository == nil || repository.pool == nil {
		return nil, errors.New("Saved lifecycle outbox repository is unavailable")
	}
	if now.IsZero() || leaseCutoff.IsZero() || leaseCutoff.After(now) || limit <= 0 || limit > 500 {
		return nil, errors.New("invalid Saved lifecycle outbox claim")
	}

	const query = `
		WITH due AS (
			SELECT event_id
			FROM place_saved_lifecycle_outbox
			WHERE status = 'PENDING'
			  AND next_attempt_at <= $1
			  AND (locked_at IS NULL OR locked_at <= $2)
			ORDER BY next_attempt_at, created_at, event_id
			LIMIT $3
			FOR UPDATE SKIP LOCKED
		), claimed AS (
			UPDATE place_saved_lifecycle_outbox outbox
			SET
				locked_at = $1,
				lease_id = gen_random_uuid(),
				updated_at = $1
			FROM due
			WHERE outbox.event_id = due.event_id
			RETURNING
				outbox.event_id,
				outbox.schema_version,
				outbox.event_type,
				outbox.entity_id,
				outbox.source_revision,
				outbox.projection_revision,
				outbox.visibility_revision,
				outbox.visibility,
				outbox.occurred_at,
				outbox.status,
				outbox.attempt_count,
				outbox.lease_id,
				outbox.next_attempt_at,
				outbox.created_at
		)
		SELECT
			event_id,
			schema_version,
			event_type,
			entity_id,
			source_revision,
			projection_revision,
			visibility_revision,
			visibility,
			occurred_at,
			status,
			attempt_count,
			lease_id
		FROM claimed
		ORDER BY next_attempt_at, created_at, event_id
	`
	rows, err := repository.pool.Query(ctx, query, now.UTC(), leaseCutoff.UTC(), limit)
	if err != nil {
		return nil, fmt.Errorf("claim Saved lifecycle outbox rows: %w", err)
	}
	defer rows.Close()

	claimed := make([]model.ClaimedSavedLifecycleEvent, 0, limit)
	for rows.Next() {
		var (
			item               model.ClaimedSavedLifecycleEvent
			schemaVersion      int16
			eventType          string
			sourceRevision     int64
			projectionRevision int64
			visibilityRevision int64
			visibility         string
			deliveryState      string
		)
		if err = rows.Scan(
			&item.Event.EventID,
			&schemaVersion,
			&eventType,
			&item.Event.EntityID,
			&sourceRevision,
			&projectionRevision,
			&visibilityRevision,
			&visibility,
			&item.Event.OccurredAt,
			&deliveryState,
			&item.AttemptCount,
			&item.LeaseID,
		); err != nil {
			return nil, fmt.Errorf("scan Saved lifecycle outbox row: %w", err)
		}
		if sourceRevision <= 0 || projectionRevision <= 0 || visibilityRevision <= 0 {
			return nil, errors.New("Saved lifecycle outbox contains invalid revisions")
		}
		item.Event.SchemaVersion = uint16(schemaVersion)
		item.Event.EventType = model.SavedLifecycleEventType(eventType)
		item.Event.SourceRevision = uint64(sourceRevision)
		item.Event.ProjectionRevision = uint64(projectionRevision)
		item.Event.VisibilityRevision = uint64(visibilityRevision)
		item.Event.Visibility = model.SavedLifecycleVisibility(visibility)
		item.Event.OccurredAt = item.Event.OccurredAt.UTC()
		item.DeliveryState = model.SavedLifecycleDeliveryState(deliveryState)
		if err = item.Validate(); err != nil {
			return nil, fmt.Errorf("validate Saved lifecycle outbox row: %w", err)
		}
		claimed = append(claimed, item)
	}
	if err = rows.Err(); err != nil {
		return nil, fmt.Errorf("iterate Saved lifecycle outbox rows: %w", err)
	}
	return claimed, nil
}

func (repository *PGSavedLifecycleOutboxRepository) MarkSavedLifecycleDelivered(
	ctx context.Context,
	eventID uuid.UUID,
	leaseID uuid.UUID,
	deliveredAt time.Time,
) error {
	if err := validateSavedLifecycleStateMutation(eventID, leaseID, deliveredAt); err != nil {
		return err
	}
	query := `
		UPDATE place_saved_lifecycle_outbox
		SET
			status = 'DELIVERED',
			delivered_at = $3::timestamptz,
			locked_at = NULL,
			lease_id = NULL,
			last_error_code = NULL,
			retention_expires_at = $3::timestamptz + ` + savedLifecycleTerminalRetentionSQL + `,
			updated_at = $3::timestamptz
		WHERE event_id = $1
		  AND lease_id = $2
		  AND status = 'PENDING'
	`
	return repository.execLeaseMutation(ctx, query, eventID, leaseID, deliveredAt.UTC())
}

func (repository *PGSavedLifecycleOutboxRepository) MarkSavedLifecycleFailure(
	ctx context.Context,
	eventID uuid.UUID,
	leaseID uuid.UUID,
	failedAt time.Time,
	nextAttemptAt time.Time,
	maxAttempts int,
	errorCode string,
) (model.SavedLifecycleDeliveryState, error) {
	if repository == nil || repository.pool == nil {
		return "", errors.New("Saved lifecycle outbox repository is unavailable")
	}
	if err := validateSavedLifecycleFailureMutation(
		eventID,
		leaseID,
		failedAt,
		nextAttemptAt,
		maxAttempts,
		errorCode,
	); err != nil {
		return "", err
	}
	const query = `
		UPDATE place_saved_lifecycle_outbox
		SET
			attempt_count = attempt_count + 1,
			status = CASE
				WHEN attempt_count + 1 >= $5 THEN 'DEAD'
				ELSE 'PENDING'
			END,
			next_attempt_at = CASE
				WHEN attempt_count + 1 >= $5 THEN $3::timestamptz
				ELSE $4::timestamptz
			END,
			dead_at = CASE
				WHEN attempt_count + 1 >= $5 THEN $3::timestamptz
				ELSE NULL
			END,
			locked_at = NULL,
			lease_id = NULL,
			last_error_code = $6,
			retention_expires_at = CASE
				WHEN attempt_count + 1 >= $5
					THEN $3::timestamptz + ` + savedLifecycleTerminalRetentionSQL + `
				ELSE NULL
			END,
			updated_at = $3::timestamptz
		WHERE event_id = $1
		  AND lease_id = $2
		  AND status = 'PENDING'
		RETURNING status
	`
	var state string
	err := repository.pool.QueryRow(
		ctx,
		query,
		eventID,
		leaseID,
		failedAt.UTC(),
		nextAttemptAt.UTC(),
		maxAttempts,
		errorCode,
	).Scan(&state)
	if errors.Is(err, pgx.ErrNoRows) {
		return "", ErrSavedLifecycleLeaseLost
	}
	if err != nil {
		return "", fmt.Errorf("mark Saved lifecycle failure: %w", err)
	}
	return model.SavedLifecycleDeliveryState(state), nil
}

func (repository *PGSavedLifecycleOutboxRepository) DeleteExpiredSavedLifecycleEvents(
	ctx context.Context,
	now time.Time,
	limit int,
) (int64, error) {
	if repository == nil || repository.pool == nil {
		return 0, errors.New("Saved lifecycle outbox repository is unavailable")
	}
	if now.IsZero() || limit <= 0 || limit > 5000 {
		return 0, errors.New("invalid Saved lifecycle cleanup request")
	}
	const query = `
		WITH expired AS (
			SELECT event_id
			FROM place_saved_lifecycle_outbox
			WHERE status IN ('DELIVERED', 'DEAD')
			  AND retention_expires_at <= $1
			ORDER BY retention_expires_at, event_id
			LIMIT $2
			FOR UPDATE SKIP LOCKED
		)
		DELETE FROM place_saved_lifecycle_outbox outbox
		USING expired
		WHERE outbox.event_id = expired.event_id
	`
	tag, err := repository.pool.Exec(ctx, query, now.UTC(), limit)
	if err != nil {
		return 0, fmt.Errorf("delete expired Saved lifecycle outbox rows: %w", err)
	}
	return tag.RowsAffected(), nil
}

func (repository *PGSavedLifecycleOutboxRepository) execLeaseMutation(
	ctx context.Context,
	query string,
	args ...any,
) error {
	if repository == nil || repository.pool == nil {
		return errors.New("Saved lifecycle outbox repository is unavailable")
	}
	tag, err := repository.pool.Exec(ctx, query, args...)
	if err != nil {
		return fmt.Errorf("update Saved lifecycle outbox state: %w", err)
	}
	if tag.RowsAffected() != 1 {
		return ErrSavedLifecycleLeaseLost
	}
	return nil
}

func validateSavedLifecycleStateMutation(
	eventID uuid.UUID,
	leaseID uuid.UUID,
	at time.Time,
) error {
	if eventID == uuid.Nil || leaseID == uuid.Nil || at.IsZero() {
		return errors.New("invalid Saved lifecycle outbox state mutation")
	}
	return nil
}

func validateSavedLifecycleFailureMutation(
	eventID uuid.UUID,
	leaseID uuid.UUID,
	failedAt time.Time,
	nextAttemptAt time.Time,
	maxAttempts int,
	errorCode string,
) error {
	if err := validateSavedLifecycleStateMutation(eventID, leaseID, failedAt); err != nil {
		return err
	}
	if nextAttemptAt.Before(failedAt) || maxAttempts <= 0 || !savedLifecycleErrorCodeRE.MatchString(errorCode) {
		return errors.New("invalid Saved lifecycle outbox failure mutation")
	}
	return nil
}
