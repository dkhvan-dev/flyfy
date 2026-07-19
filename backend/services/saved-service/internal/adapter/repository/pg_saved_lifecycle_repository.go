package repository

import (
	"context"
	"crypto/subtle"
	"errors"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"

	savedlifecycle "kz/inflap/backend/services/saved-service/internal/app/savedlifecycle"
	"kz/inflap/backend/services/saved-service/internal/domain"
)

const insertSavedLifecycleInboxSQL = `
INSERT INTO saved_inbox_dedup (
    source_service,
    event_id,
    event_type,
    processing_state,
    processed_at,
    retention_expires_at,
    subject,
    schema_version,
    target_entity_type,
    envelope_fingerprint,
    source_revision,
    projection_revision,
    visibility_revision,
    source_applied,
    projection_applied,
    visibility_applied
) VALUES (
    $1, $2, $3, 'IGNORED_STALE_REVISION', $4, $5,
    $6, $7, $8, $9, $10, $11, $12, FALSE, FALSE, FALSE
)
ON CONFLICT (source_service, event_id) DO NOTHING`

const selectSavedLifecycleInboxSQL = `
SELECT envelope_fingerprint, processing_state
FROM saved_inbox_dedup
WHERE source_service = $1
  AND event_id = $2`

const finalizeSavedLifecycleInboxSQL = `
UPDATE saved_inbox_dedup
SET processing_state = $3,
    source_applied = $4,
    projection_applied = $5,
    visibility_applied = $6
WHERE source_service = $1
  AND event_id = $2`

const lockSavedLifecycleProjectionSQL = `
SELECT source_service,
       source_revision,
       projection_revision,
       visibility_revision,
       visibility_status,
       visibility_validated_at,
       reconciliation_fail_closed_at
FROM saved_content_projections
WHERE entity_type = $1
  AND entity_id = $2
FOR UPDATE`

const deleteExpiredSavedLifecycleInboxSQL = `
WITH expired AS (
    SELECT source_service, event_id
    FROM saved_inbox_dedup
    WHERE retention_expires_at <= $1
    ORDER BY retention_expires_at ASC, source_service ASC, event_id ASC
    FOR UPDATE SKIP LOCKED
    LIMIT $2
)
DELETE FROM saved_inbox_dedup AS inbox
USING expired
WHERE inbox.source_service = expired.source_service
  AND inbox.event_id = expired.event_id`

type PGSavedLifecycleRepository struct {
	pool *pgxpool.Pool
}

var _ savedlifecycle.Repository = (*PGSavedLifecycleRepository)(nil)

func NewPGSavedLifecycleRepository(pool *pgxpool.Pool) (*PGSavedLifecycleRepository, error) {
	if pool == nil {
		return nil, savedlifecycle.NewPermanentError(savedlifecycle.ErrorCodePersistenceInvariant)
	}
	return &PGSavedLifecycleRepository{pool: pool}, nil
}

func (r *PGSavedLifecycleRepository) Apply(
	ctx context.Context,
	event savedlifecycle.Event,
	processedAt time.Time,
) (savedlifecycle.Outcome, error) {
	if ctx == nil || r == nil || r.pool == nil {
		return savedlifecycle.Outcome{}, savedlifecycle.ErrRepositoryUnavailable
	}
	if err := ctx.Err(); err != nil {
		return savedlifecycle.Outcome{}, err
	}
	if err := event.Validate(processedAt); err != nil {
		return savedlifecycle.Outcome{}, err
	}

	tx, err := r.pool.BeginTx(ctx, pgx.TxOptions{
		IsoLevel:   pgx.ReadCommitted,
		AccessMode: pgx.ReadWrite,
	})
	if err != nil {
		return savedlifecycle.Outcome{}, mapSavedLifecyclePGError(err)
	}
	defer rollbackSavedLifecycleTx(tx)

	if _, err = tx.Exec(ctx, "SELECT pg_advisory_xact_lock($1)", savedProjectionLockKey(event.Target)); err != nil {
		return savedlifecycle.Outcome{}, mapSavedLifecyclePGError(err)
	}

	inserted, err := insertSavedLifecycleInbox(ctx, tx, event, processedAt)
	if err != nil {
		return savedlifecycle.Outcome{}, err
	}
	if !inserted {
		return duplicateSavedLifecycleOutcome(ctx, tx, event)
	}

	state, found, err := lockSavedLifecycleProjection(ctx, tx, event.Target)
	if err != nil {
		return savedlifecycle.Outcome{}, err
	}
	if !found {
		outcome := savedlifecycle.Outcome{Code: savedlifecycle.OutcomeIgnoredUnknownTarget}
		if err = finalizeSavedLifecycleInbox(ctx, tx, event, outcome); err != nil {
			return savedlifecycle.Outcome{}, err
		}
		if err = tx.Commit(ctx); err != nil {
			return savedlifecycle.Outcome{}, mapSavedLifecyclePGError(err)
		}
		return outcome, nil
	}
	if state.sourceService != event.SourceService {
		return savedlifecycle.Outcome{}, savedlifecycle.NewPermanentError(
			savedlifecycle.ErrorCodeProjectionSourceConflict,
		)
	}

	decision, err := decideSavedLifecycleProjection(event, state)
	if err != nil {
		return savedlifecycle.Outcome{}, err
	}
	if err = applySavedLifecycleDecision(ctx, tx, event, state, decision, processedAt); err != nil {
		return savedlifecycle.Outcome{}, err
	}
	outcome := decision.outcome(event, state)
	if err = finalizeSavedLifecycleInbox(ctx, tx, event, outcome); err != nil {
		return savedlifecycle.Outcome{}, err
	}
	if err = tx.Commit(ctx); err != nil {
		return savedlifecycle.Outcome{}, mapSavedLifecyclePGError(err)
	}
	return outcome, nil
}

func (r *PGSavedLifecycleRepository) DeleteExpired(
	ctx context.Context,
	now time.Time,
	limit int,
) (int64, error) {
	if ctx == nil || r == nil || r.pool == nil {
		return 0, savedlifecycle.ErrRepositoryUnavailable
	}
	if err := ctx.Err(); err != nil {
		return 0, err
	}
	if now.IsZero() || limit < 1 || limit > savedlifecycle.MaxInboxCleanupBatch {
		return 0, savedlifecycle.NewPermanentError(savedlifecycle.ErrorCodePersistenceInvariant)
	}
	tag, err := r.pool.Exec(ctx, deleteExpiredSavedLifecycleInboxSQL, now.UTC(), limit)
	if err != nil {
		return 0, mapSavedLifecyclePGError(err)
	}
	return tag.RowsAffected(), nil
}

func insertSavedLifecycleInbox(
	ctx context.Context,
	tx pgx.Tx,
	event savedlifecycle.Event,
	processedAt time.Time,
) (bool, error) {
	tag, err := tx.Exec(
		ctx,
		insertSavedLifecycleInboxSQL,
		event.SourceService,
		event.EventID,
		string(event.Kind),
		processedAt.UTC(),
		processedAt.UTC().Add(savedlifecycle.InboxRetention),
		event.Subject,
		int16(event.SchemaVersion),
		string(event.Target.EntityType()),
		event.EnvelopeFingerprint[:],
		int64(event.Revisions.Source),
		int64(event.Revisions.Projection),
		int64(event.Revisions.Visibility),
	)
	if err != nil {
		return false, mapSavedLifecyclePGError(err)
	}
	return tag.RowsAffected() == 1, nil
}

func duplicateSavedLifecycleOutcome(
	ctx context.Context,
	tx pgx.Tx,
	event savedlifecycle.Event,
) (savedlifecycle.Outcome, error) {
	var persistedFingerprint []byte
	var persistedCode string
	err := tx.QueryRow(
		ctx,
		selectSavedLifecycleInboxSQL,
		event.SourceService,
		event.EventID,
	).Scan(&persistedFingerprint, &persistedCode)
	if err != nil {
		return savedlifecycle.Outcome{}, mapSavedLifecyclePGError(err)
	}
	if len(persistedFingerprint) != len(event.EnvelopeFingerprint) ||
		subtle.ConstantTimeCompare(persistedFingerprint, event.EnvelopeFingerprint[:]) != 1 {
		return savedlifecycle.Outcome{}, savedlifecycle.NewPermanentError(
			savedlifecycle.ErrorCodeEventIdentityConflict,
		)
	}
	originalCode := savedlifecycle.OutcomeCode(persistedCode)
	duplicate := savedlifecycle.Outcome{
		Code:         savedlifecycle.OutcomeDuplicate,
		OriginalCode: originalCode,
	}
	if !duplicate.IsValid() {
		return savedlifecycle.Outcome{}, savedlifecycle.NewPermanentError(
			savedlifecycle.ErrorCodePersistenceInvariant,
		)
	}
	return duplicate, nil
}

func finalizeSavedLifecycleInbox(
	ctx context.Context,
	tx pgx.Tx,
	event savedlifecycle.Event,
	outcome savedlifecycle.Outcome,
) error {
	if !outcome.IsValid() || outcome.Code == savedlifecycle.OutcomeDuplicate {
		return savedlifecycle.NewPermanentError(savedlifecycle.ErrorCodePersistenceInvariant)
	}
	tag, err := tx.Exec(
		ctx,
		finalizeSavedLifecycleInboxSQL,
		event.SourceService,
		event.EventID,
		string(outcome.Code),
		outcome.SourceApplied,
		outcome.ProjectionApplied,
		outcome.VisibilityApplied,
	)
	if err != nil {
		return mapSavedLifecyclePGError(err)
	}
	if tag.RowsAffected() != 1 {
		return savedlifecycle.NewPermanentError(savedlifecycle.ErrorCodePersistenceInvariant)
	}
	return nil
}

type savedLifecycleProjectionState struct {
	sourceService         string
	sourceRevision        uint64
	projectionRevision    uint64
	visibilityRevision    uint64
	visibility            domain.VisibilityStatus
	visibilityValidatedAt time.Time
	failClosed            bool
}

func lockSavedLifecycleProjection(
	ctx context.Context,
	tx pgx.Tx,
	target domain.SavedTarget,
) (savedLifecycleProjectionState, bool, error) {
	var sourceRevision, projectionRevision, visibilityRevision int64
	var visibility string
	var validatedAt, failClosedAt pgtype.Timestamptz
	var state savedLifecycleProjectionState
	err := tx.QueryRow(
		ctx,
		lockSavedLifecycleProjectionSQL,
		string(target.EntityType()),
		target.EntityID(),
	).Scan(
		&state.sourceService,
		&sourceRevision,
		&projectionRevision,
		&visibilityRevision,
		&visibility,
		&validatedAt,
		&failClosedAt,
	)
	if errors.Is(err, pgx.ErrNoRows) {
		return savedLifecycleProjectionState{}, false, nil
	}
	if err != nil {
		return savedLifecycleProjectionState{}, false, mapSavedLifecyclePGError(err)
	}
	if sourceRevision < 0 || projectionRevision < 0 || visibilityRevision < 0 {
		return savedLifecycleProjectionState{}, false, savedlifecycle.NewPermanentError(
			savedlifecycle.ErrorCodePersistenceInvariant,
		)
	}
	state.sourceRevision = uint64(sourceRevision)
	state.projectionRevision = uint64(projectionRevision)
	state.visibilityRevision = uint64(visibilityRevision)
	state.visibility = domain.VisibilityStatus(visibility)
	if !state.visibility.IsValid() {
		return savedLifecycleProjectionState{}, false, savedlifecycle.NewPermanentError(
			savedlifecycle.ErrorCodePersistenceInvariant,
		)
	}
	if validatedAt.Valid {
		state.visibilityValidatedAt = validatedAt.Time.UTC()
	}
	state.failClosed = failClosedAt.Valid
	if state.visibility != domain.VisibilityUnknown && state.visibilityValidatedAt.IsZero() {
		return savedLifecycleProjectionState{}, false, savedlifecycle.NewPermanentError(
			savedlifecycle.ErrorCodePersistenceInvariant,
		)
	}
	return state, true, nil
}

func rollbackSavedLifecycleTx(tx pgx.Tx) {
	_ = tx.Rollback(context.Background())
}

func mapSavedLifecyclePGError(err error) error {
	if err == nil {
		return nil
	}
	if errors.Is(err, context.Canceled) || errors.Is(err, context.DeadlineExceeded) {
		return err
	}
	var postgresError *pgconn.PgError
	if errors.As(err, &postgresError) {
		switch postgresError.Code {
		case "22003", "22P02", "23502", "23503", "23505", "23514":
			return savedlifecycle.NewPermanentError(savedlifecycle.ErrorCodePersistenceInvariant)
		}
	}
	return savedlifecycle.ErrRepositoryUnavailable
}
