package repository

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"

	"kz/inflap/backend/services/guide-service/internal/domain/model"
	"kz/inflap/backend/services/guide-service/internal/domain/port"
)

const (
	maxSavedLifecycleBatch = 200
	maxSavedErrorCodeLen   = 64
)

var (
	_ port.SavedLifecycleOutboxRepository         = (*PGGuideRepository)(nil)
	_ port.SavedGuideUserReconciliationRepository = (*PGGuideRepository)(nil)
)

func (r *PGGuideRepository) ClaimSavedLifecycleOutbox(
	ctx context.Context,
	now time.Time,
	limit int,
	leaseDuration time.Duration,
) ([]*model.SavedLifecycleOutboxMessage, error) {
	if r == nil || r.pool == nil || now.IsZero() || leaseDuration <= 0 || limit < 1 || limit > maxSavedLifecycleBatch {
		return nil, model.ErrInvalidSavedLifecycleState
	}

	const query = `
		WITH due AS (
			SELECT event_id, status
			FROM guide_saved_lifecycle_outbox
			WHERE (status = 'PENDING' AND next_attempt_at <= $1)
			   OR (status = 'PROCESSING' AND leased_until <= $1)
			ORDER BY COALESCE(next_attempt_at, leased_until) ASC, created_at ASC, event_id ASC
			FOR UPDATE SKIP LOCKED
			LIMIT $2
		)
		UPDATE guide_saved_lifecycle_outbox AS outbox
		SET status = 'PROCESSING',
			attempt_count = CASE
				WHEN due.status = 'PENDING' THEN outbox.attempt_count + 1
				ELSE outbox.attempt_count
			END,
			next_attempt_at = NULL,
			lease_token = gen_random_uuid(),
			leased_until = $3,
			last_error_code = NULL,
			updated_at = $1
		FROM due
		WHERE outbox.event_id = due.event_id
		RETURNING
			outbox.event_id,
			outbox.event_kind,
			outbox.target_user_id,
			outbox.source_revision,
			outbox.projection_revision,
			outbox.visibility_revision,
			outbox.occurred_at,
			outbox.visibility,
			outbox.public_projection,
			outbox.attempt_count,
			outbox.max_attempts,
			outbox.lease_token
	`

	rows, err := r.pool.Query(ctx, query, now.UTC(), limit, now.UTC().Add(leaseDuration))
	if err != nil {
		return nil, fmt.Errorf("claim Saved lifecycle outbox: %w", err)
	}
	defer rows.Close()

	items := make([]*model.SavedLifecycleOutboxMessage, 0, limit)
	for rows.Next() {
		var (
			item               model.SavedLifecycleOutboxMessage
			kindRaw            string
			visibilityRaw      string
			sourceRevision     int64
			projectionRevision int64
			visibilityRevision int64
		)
		if err = rows.Scan(
			&item.EventID,
			&kindRaw,
			&item.TargetUserID,
			&sourceRevision,
			&projectionRevision,
			&visibilityRevision,
			&item.OccurredAt,
			&visibilityRaw,
			&item.PublicProjection,
			&item.AttemptCount,
			&item.MaxAttempts,
			&item.LeaseToken,
		); err != nil {
			return nil, fmt.Errorf("scan Saved lifecycle outbox: %w", err)
		}
		if sourceRevision <= 0 || projectionRevision <= 0 || visibilityRevision <= 0 {
			return nil, fmt.Errorf("scan Saved lifecycle outbox: %w", model.ErrInvalidSavedLifecycleState)
		}
		item.Kind = model.SavedLifecycleEventKind(kindRaw)
		item.Visibility = model.SavedLifecycleVisibility(visibilityRaw)
		item.SourceRevision = uint64(sourceRevision)
		item.ProjectionRevision = uint64(projectionRevision)
		item.VisibilityRevision = uint64(visibilityRevision)
		item.OccurredAt = item.OccurredAt.UTC()
		if err = item.Validate(); err != nil {
			return nil, fmt.Errorf("validate Saved lifecycle outbox: %w", err)
		}
		items = append(items, &item)
	}
	if err = rows.Err(); err != nil {
		return nil, fmt.Errorf("iterate Saved lifecycle outbox: %w", err)
	}
	return items, nil
}

func (r *PGGuideRepository) MarkSavedLifecycleDelivered(
	ctx context.Context,
	eventID uuid.UUID,
	leaseToken uuid.UUID,
	deliveredAt time.Time,
	retention time.Duration,
) error {
	if eventID == uuid.Nil || leaseToken == uuid.Nil || deliveredAt.IsZero() || retention <= 0 {
		return model.ErrInvalidSavedLifecycleState
	}
	const query = `
		UPDATE guide_saved_lifecycle_outbox
		SET status = 'DELIVERED',
			lease_token = NULL,
			leased_until = NULL,
			delivered_at = $3,
			retention_expires_at = $4,
			updated_at = $3
		WHERE event_id = $1
		  AND status = 'PROCESSING'
		  AND lease_token = $2
	`
	tag, err := r.pool.Exec(ctx, query, eventID, leaseToken, deliveredAt.UTC(), deliveredAt.UTC().Add(retention))
	if err != nil {
		return fmt.Errorf("mark Saved lifecycle delivered: %w", err)
	}
	if tag.RowsAffected() != 1 {
		return ErrLeaseLost
	}
	return nil
}

func (r *PGGuideRepository) MarkSavedLifecycleFailed(
	ctx context.Context,
	eventID uuid.UUID,
	leaseToken uuid.UUID,
	failedAt time.Time,
	nextAttemptAt time.Time,
	errorCode string,
	dead bool,
	retention time.Duration,
) error {
	errorCode = strings.ToUpper(strings.TrimSpace(errorCode))
	if eventID == uuid.Nil || leaseToken == uuid.Nil || failedAt.IsZero() || errorCode == "" ||
		len(errorCode) > maxSavedErrorCodeLen || (dead && retention <= 0) || (!dead && nextAttemptAt.Before(failedAt)) {
		return model.ErrInvalidSavedLifecycleState
	}

	if dead {
		const query = `
			UPDATE guide_saved_lifecycle_outbox
			SET status = 'DEAD',
				lease_token = NULL,
				leased_until = NULL,
				last_error_code = $4,
				dead_at = $3,
				retention_expires_at = $5,
				updated_at = $3
			WHERE event_id = $1
			  AND status = 'PROCESSING'
			  AND lease_token = $2
		`
		tag, err := r.pool.Exec(
			ctx,
			query,
			eventID,
			leaseToken,
			failedAt.UTC(),
			errorCode,
			failedAt.UTC().Add(retention),
		)
		if err != nil {
			return fmt.Errorf("mark Saved lifecycle dead: %w", err)
		}
		if tag.RowsAffected() != 1 {
			return ErrLeaseLost
		}
		return nil
	}

	const query = `
		UPDATE guide_saved_lifecycle_outbox
		SET status = 'PENDING',
			next_attempt_at = $4,
			lease_token = NULL,
			leased_until = NULL,
			last_error_code = $5,
			updated_at = $3
		WHERE event_id = $1
		  AND status = 'PROCESSING'
		  AND lease_token = $2
	`
	tag, err := r.pool.Exec(
		ctx,
		query,
		eventID,
		leaseToken,
		failedAt.UTC(),
		nextAttemptAt.UTC(),
		errorCode,
	)
	if err != nil {
		return fmt.Errorf("schedule Saved lifecycle retry: %w", err)
	}
	if tag.RowsAffected() != 1 {
		return ErrLeaseLost
	}
	return nil
}

func (r *PGGuideRepository) DeleteSavedLifecycleTerminal(
	ctx context.Context,
	now time.Time,
	limit int,
) (int64, error) {
	if now.IsZero() || limit < 1 || limit > maxSavedLifecycleBatch {
		return 0, model.ErrInvalidSavedLifecycleState
	}
	const query = `
		DELETE FROM guide_saved_lifecycle_outbox
		WHERE event_id IN (
			SELECT event_id
			FROM guide_saved_lifecycle_outbox
			WHERE status IN ('DELIVERED', 'DEAD')
			  AND retention_expires_at <= $1
			ORDER BY retention_expires_at ASC, event_id ASC
			LIMIT $2
		)
	`
	tag, err := r.pool.Exec(ctx, query, now.UTC(), limit)
	if err != nil {
		return 0, fmt.Errorf("delete terminal Saved lifecycle outbox: %w", err)
	}
	return tag.RowsAffected(), nil
}

func (r *PGGuideRepository) ClaimSavedGuideUserReconciliations(
	ctx context.Context,
	now time.Time,
	limit int,
	leaseDuration time.Duration,
) ([]*model.SavedGuideUserReconcileLease, error) {
	if now.IsZero() || leaseDuration <= 0 || limit < 1 || limit > maxSavedLifecycleBatch {
		return nil, model.ErrInvalidSavedLifecycleState
	}
	const query = `
		WITH due AS (
			SELECT state.guide_profile_id
			FROM guide_saved_lifecycle_state state
			JOIN guide_profiles profile ON profile.id = state.guide_profile_id
			WHERE NOT state.source_deleted
			  AND profile.deleted_at IS NULL
			  AND state.next_reconcile_at <= $1
			  AND (state.reconcile_lease_token IS NULL OR state.reconcile_leased_until <= $1)
			ORDER BY state.next_reconcile_at ASC, state.guide_profile_id ASC
			FOR UPDATE OF state SKIP LOCKED
			LIMIT $2
		)
		UPDATE guide_saved_lifecycle_state AS state
		SET reconcile_lease_token = gen_random_uuid(),
			reconcile_leased_until = $3,
			updated_at = $1
		FROM due
		WHERE state.guide_profile_id = due.guide_profile_id
		RETURNING state.guide_profile_id, state.user_id, state.reconcile_lease_token,
			state.reconcile_failure_count
	`
	rows, err := r.pool.Query(ctx, query, now.UTC(), limit, now.UTC().Add(leaseDuration))
	if err != nil {
		return nil, fmt.Errorf("claim Saved guide user reconciliations: %w", err)
	}
	defer rows.Close()

	items := make([]*model.SavedGuideUserReconcileLease, 0, limit)
	for rows.Next() {
		var item model.SavedGuideUserReconcileLease
		if err = rows.Scan(&item.GuideProfileID, &item.UserID, &item.LeaseToken, &item.FailureCount); err != nil {
			return nil, fmt.Errorf("scan Saved guide user reconciliation: %w", err)
		}
		if err = item.Validate(); err != nil {
			return nil, err
		}
		items = append(items, &item)
	}
	if err = rows.Err(); err != nil {
		return nil, fmt.Errorf("iterate Saved guide user reconciliations: %w", err)
	}
	return items, nil
}

func (r *PGGuideRepository) ApplySavedGuideExternalUserState(
	ctx context.Context,
	lease model.SavedGuideUserReconcileLease,
	state model.SavedGuideExternalUserState,
	nextReconcileAt time.Time,
) error {
	if err := lease.Validate(); err != nil {
		return err
	}
	if err := state.Validate(); err != nil {
		return err
	}
	if nextReconcileAt.Before(state.ObservedAt) {
		return model.ErrInvalidSavedLifecycleState
	}

	tx, err := r.pool.BeginTx(ctx, pgx.TxOptions{})
	if err != nil {
		return fmt.Errorf("begin Saved guide user reconciliation: %w", err)
	}
	defer tx.Rollback(ctx)

	const lockQuery = `
		SELECT external_known, external_account_status, external_is_deleted,
			external_account_updated_at, external_profile_updated_at
		FROM guide_saved_lifecycle_state
		WHERE guide_profile_id = $1
		  AND user_id = $2
		  AND reconcile_lease_token = $3
		  AND NOT source_deleted
		FOR UPDATE
	`
	var currentExternalKnown, currentExternalDeleted bool
	var currentAccountStatus *string
	var currentAccountUpdatedAt, currentProfileUpdatedAt *time.Time
	err = tx.QueryRow(ctx, lockQuery, lease.GuideProfileID, lease.UserID, lease.LeaseToken).Scan(
		&currentExternalKnown,
		&currentAccountStatus,
		&currentExternalDeleted,
		&currentAccountUpdatedAt,
		&currentProfileUpdatedAt,
	)
	if errors.Is(err, pgx.ErrNoRows) {
		return ErrLeaseLost
	}
	if err != nil {
		return fmt.Errorf("lock Saved guide user reconciliation: %w", err)
	}

	stale := currentAccountUpdatedAt != nil && state.AccountUpdatedAt.Before(currentAccountUpdatedAt.UTC())
	if state.ProfileUpdatedAt != nil && currentProfileUpdatedAt != nil &&
		state.ProfileUpdatedAt.Before(currentProfileUpdatedAt.UTC()) {
		stale = true
	}
	authoritativeNotFoundAlreadyApplied := state.AccountStatus == "DELETED" &&
		state.IsDeleted && state.ProfileUpdatedAt == nil &&
		len(state.ProjectionFingerprint) == 0 && state.AvatarFileID == nil &&
		currentExternalKnown && currentAccountStatus != nil &&
		*currentAccountStatus == "DELETED" && currentExternalDeleted
	if stale || authoritativeNotFoundAlreadyApplied {
		const releaseQuery = `
			UPDATE guide_saved_lifecycle_state
			SET last_reconciled_at = $4,
				next_reconcile_at = $5,
				reconcile_failure_count = 0,
				reconcile_lease_token = NULL,
				reconcile_leased_until = NULL,
				updated_at = $4
			WHERE guide_profile_id = $1 AND user_id = $2 AND reconcile_lease_token = $3
		`
		tag, releaseErr := tx.Exec(
			ctx,
			releaseQuery,
			lease.GuideProfileID,
			lease.UserID,
			lease.LeaseToken,
			state.ObservedAt.UTC(),
			nextReconcileAt.UTC(),
		)
		if releaseErr != nil {
			return fmt.Errorf("release unchanged Saved guide reconciliation: %w", releaseErr)
		}
		if tag.RowsAffected() != 1 {
			return ErrLeaseLost
		}
		if err = tx.Commit(ctx); err != nil {
			return fmt.Errorf("commit unchanged Saved guide reconciliation: %w", err)
		}
		return nil
	}

	const updateQuery = `
		UPDATE guide_saved_lifecycle_state
		SET external_known = TRUE,
			external_account_status = $4,
			external_is_deleted = $5,
			external_account_updated_at = $6,
			external_profile_updated_at = $7,
			external_projection_fingerprint = $8,
			external_avatar_file_id = $9,
			last_reconciled_at = $10,
			next_reconcile_at = $11,
			reconcile_failure_count = 0,
			reconcile_lease_token = NULL,
			reconcile_leased_until = NULL,
			semantic_occurred_at = $10,
			updated_at = $10
		WHERE guide_profile_id = $1
		  AND user_id = $2
		  AND reconcile_lease_token = $3
		  AND NOT source_deleted
	`
	tag, err := tx.Exec(
		ctx,
		updateQuery,
		lease.GuideProfileID,
		lease.UserID,
		lease.LeaseToken,
		state.AccountStatus,
		state.IsDeleted,
		state.AccountUpdatedAt.UTC(),
		state.ProfileUpdatedAt,
		state.ProjectionFingerprint,
		state.AvatarFileID,
		state.ObservedAt.UTC(),
		nextReconcileAt.UTC(),
	)
	if err != nil {
		return fmt.Errorf("apply Saved guide external user state: %w", err)
	}
	if tag.RowsAffected() != 1 {
		return ErrLeaseLost
	}
	if err = tx.Commit(ctx); err != nil {
		return fmt.Errorf("commit Saved guide external user state: %w", err)
	}
	return nil
}

func (r *PGGuideRepository) MarkSavedGuideUserReconcileFailed(
	ctx context.Context,
	lease model.SavedGuideUserReconcileLease,
	nextAttemptAt time.Time,
) error {
	if err := lease.Validate(); err != nil {
		return err
	}
	if nextAttemptAt.IsZero() {
		return model.ErrInvalidSavedLifecycleState
	}
	const query = `
		UPDATE guide_saved_lifecycle_state
		SET reconcile_failure_count = LEAST(reconcile_failure_count + 1, 1000000),
			next_reconcile_at = $4,
			reconcile_lease_token = NULL,
			reconcile_leased_until = NULL,
			updated_at = clock_timestamp()
		WHERE guide_profile_id = $1
		  AND user_id = $2
		  AND reconcile_lease_token = $3
	`
	tag, err := r.pool.Exec(
		ctx,
		query,
		lease.GuideProfileID,
		lease.UserID,
		lease.LeaseToken,
		nextAttemptAt.UTC(),
	)
	if err != nil {
		return fmt.Errorf("mark Saved guide reconciliation failed: %w", err)
	}
	if tag.RowsAffected() != 1 {
		return ErrLeaseLost
	}
	return nil
}
