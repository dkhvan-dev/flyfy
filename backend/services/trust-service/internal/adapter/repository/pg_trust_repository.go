package repository

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"kz/inflap/backend/services/trust-service/internal/domain/model"
	"kz/inflap/backend/services/trust-service/internal/domain/port"
)

type PGTrustRepository struct {
	pool *pgxpool.Pool
}

func NewPGTrustRepository(pool *pgxpool.Pool) *PGTrustRepository {
	return &PGTrustRepository{pool: pool}
}

func (r *PGTrustRepository) GetTrustProfile(ctx context.Context, userID uuid.UUID) (model.TrustProfile, error) {
	const query = `
		SELECT user_id, score, band, status, calculated_at, created_at, updated_at
		FROM trust_profiles
		WHERE user_id = $1
		LIMIT 1
	`
	var (
		profile   model.TrustProfile
		bandRaw   string
		statusRaw string
	)
	err := r.pool.QueryRow(ctx, query, userID).Scan(
		&profile.UserID,
		&profile.Score,
		&bandRaw,
		&statusRaw,
		&profile.CalculatedAt,
		&profile.CreatedAt,
		&profile.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return model.TrustProfile{}, port.ErrNotFound
		}
		return model.TrustProfile{}, fmt.Errorf("select trust profile: %w", err)
	}
	profile.Band = model.TrustBand(bandRaw)
	profile.Status = model.TrustStatus(statusRaw)
	return profile, nil
}

func (r *PGTrustRepository) UpsertTrustProfile(ctx context.Context, profile model.TrustProfile) error {
	const query = `
		INSERT INTO trust_profiles (
			user_id, score, band, status, calculated_at, created_at, updated_at
		) VALUES (
			$1, $2, $3, $4, $5, $6, $7
		)
		ON CONFLICT (user_id) DO UPDATE SET
			score = EXCLUDED.score,
			band = EXCLUDED.band,
			status = EXCLUDED.status,
			calculated_at = EXCLUDED.calculated_at,
			updated_at = EXCLUDED.updated_at
	`
	calculatedAt := profile.CalculatedAt
	if calculatedAt.IsZero() {
		calculatedAt = time.Now().UTC()
	}
	if profile.CreatedAt.IsZero() {
		profile.CreatedAt = calculatedAt
	}
	if profile.UpdatedAt.IsZero() {
		profile.UpdatedAt = calculatedAt
	}
	if _, err := r.pool.Exec(
		ctx,
		query,
		profile.UserID,
		profile.Score,
		string(profile.Band),
		string(profile.Status),
		calculatedAt,
		profile.CreatedAt,
		profile.UpdatedAt,
	); err != nil {
		return fmt.Errorf("upsert trust profile: %w", err)
	}
	return nil
}

func (r *PGTrustRepository) ListActiveRestrictions(ctx context.Context, userID uuid.UUID, now time.Time) ([]model.RuntimeRestriction, error) {
	const query = `
		SELECT
			id, user_id, case_id, restriction_code, status, reason_code, source_event_id,
			created_by_staff_id, expires_at, created_at, lifted_at, lifted_by_staff_id
		FROM runtime_restrictions
		WHERE user_id = $1
			AND status = $2
			AND (expires_at IS NULL OR expires_at > $3)
		ORDER BY created_at ASC
	`
	rows, err := r.pool.Query(ctx, query, userID, string(model.RuntimeRestrictionActive), now)
	if err != nil {
		return nil, fmt.Errorf("select active restrictions: %w", err)
	}
	defer rows.Close()

	var items []model.RuntimeRestriction
	for rows.Next() {
		var (
			item      model.RuntimeRestriction
			statusRaw string
		)
		if err := rows.Scan(
			&item.ID,
			&item.UserID,
			&item.CaseID,
			&item.RestrictionCode,
			&statusRaw,
			&item.ReasonCode,
			&item.SourceEventID,
			&item.CreatedByStaffID,
			&item.ExpiresAt,
			&item.CreatedAt,
			&item.LiftedAt,
			&item.LiftedByStaffID,
		); err != nil {
			return nil, fmt.Errorf("scan active restriction: %w", err)
		}
		item.Status = model.RuntimeRestrictionStatus(statusRaw)
		items = append(items, item)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("iterate active restrictions: %w", err)
	}
	return items, nil
}

func (r *PGTrustRepository) SavePolicyDecision(ctx context.Context, decision model.PolicyDecisionRecord) error {
	const query = `
		INSERT INTO policy_decisions (
			id, user_id, action, resource_type, resource_id, idempotency_key,
			decision, reason_code, public_message_key, internal_message,
			trust_band, score, restriction_ids, created_at
		) VALUES (
			$1, $2, $3, $4, $5, $6,
			$7, $8, $9, $10,
			$11, $12, $13, $14
		)
		ON CONFLICT (user_id, action, idempotency_key)
			WHERE idempotency_key <> ''
		DO NOTHING
	`
	restrictionIDs := decision.RestrictionIDs
	if restrictionIDs == nil {
		restrictionIDs = []uuid.UUID{}
	}
	if _, err := r.pool.Exec(
		ctx,
		query,
		decision.ID,
		decision.UserID,
		string(decision.Action),
		decision.ResourceType,
		decision.ResourceID,
		decision.IdempotencyKey,
		string(decision.Decision),
		decision.ReasonCode,
		decision.PublicMessageKey,
		decision.InternalMessage,
		string(decision.TrustBand),
		decision.Score,
		restrictionIDs,
		decision.CreatedAt,
	); err != nil {
		return fmt.Errorf("insert policy decision: %w", err)
	}
	return nil
}

func (r *PGTrustRepository) HasProcessedEvent(ctx context.Context, eventID uuid.UUID) (bool, error) {
	const query = `
		SELECT EXISTS(
			SELECT 1
			FROM processed_trust_events
			WHERE event_id = $1
		)
	`
	var exists bool
	if err := r.pool.QueryRow(ctx, query, eventID).Scan(&exists); err != nil {
		return false, fmt.Errorf("check processed event: %w", err)
	}
	return exists, nil
}

func (r *PGTrustRepository) MarkProcessedEvent(ctx context.Context, eventID uuid.UUID, eventType string, occurredAt time.Time) error {
	if occurredAt.IsZero() {
		occurredAt = time.Now().UTC()
	}
	const query = `
		INSERT INTO processed_trust_events (event_id, event_type, occurred_at, processed_at)
		VALUES ($1, $2, $3, now())
		ON CONFLICT (event_id) DO NOTHING
	`
	if _, err := r.pool.Exec(ctx, query, eventID, eventType, occurredAt); err != nil {
		return fmt.Errorf("mark processed event: %w", err)
	}
	return nil
}

func (r *PGTrustRepository) UpsertRuntimeRestriction(ctx context.Context, restriction model.RuntimeRestriction) error {
	const query = `
		INSERT INTO runtime_restrictions (
			id, user_id, case_id, restriction_code, status, reason_code, source_event_id,
			created_by_staff_id, expires_at, created_at, lifted_at, lifted_by_staff_id
		) VALUES (
			$1, $2, $3, $4, $5, $6, $7,
			$8, $9, $10, $11, $12
		)
		ON CONFLICT (id) DO UPDATE SET
			user_id = EXCLUDED.user_id,
			case_id = EXCLUDED.case_id,
			restriction_code = EXCLUDED.restriction_code,
			status = EXCLUDED.status,
			reason_code = EXCLUDED.reason_code,
			source_event_id = EXCLUDED.source_event_id,
			created_by_staff_id = EXCLUDED.created_by_staff_id,
			expires_at = EXCLUDED.expires_at,
			created_at = EXCLUDED.created_at,
			lifted_at = EXCLUDED.lifted_at,
			lifted_by_staff_id = EXCLUDED.lifted_by_staff_id
	`
	if restriction.CreatedAt.IsZero() {
		restriction.CreatedAt = time.Now().UTC()
	}
	if _, err := r.pool.Exec(
		ctx,
		query,
		restriction.ID,
		restriction.UserID,
		restriction.CaseID,
		restriction.RestrictionCode,
		string(restriction.Status),
		restriction.ReasonCode,
		restriction.SourceEventID,
		restriction.CreatedByStaffID,
		restriction.ExpiresAt,
		restriction.CreatedAt,
		restriction.LiftedAt,
		restriction.LiftedByStaffID,
	); err != nil {
		return fmt.Errorf("upsert runtime restriction: %w", err)
	}
	return nil
}

func (r *PGTrustRepository) GetRuntimeRestrictionByID(ctx context.Context, restrictionID uuid.UUID) (model.RuntimeRestriction, error) {
	const query = `
		SELECT
			id, user_id, case_id, restriction_code, status, reason_code, source_event_id,
			created_by_staff_id, expires_at, created_at, lifted_at, lifted_by_staff_id
		FROM runtime_restrictions
		WHERE id = $1
		LIMIT 1
	`
	var (
		item      model.RuntimeRestriction
		statusRaw string
	)
	err := r.pool.QueryRow(ctx, query, restrictionID).Scan(
		&item.ID,
		&item.UserID,
		&item.CaseID,
		&item.RestrictionCode,
		&statusRaw,
		&item.ReasonCode,
		&item.SourceEventID,
		&item.CreatedByStaffID,
		&item.ExpiresAt,
		&item.CreatedAt,
		&item.LiftedAt,
		&item.LiftedByStaffID,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return model.RuntimeRestriction{}, port.ErrNotFound
		}
		return model.RuntimeRestriction{}, fmt.Errorf("select runtime restriction: %w", err)
	}
	item.Status = model.RuntimeRestrictionStatus(statusRaw)
	return item, nil
}

func (r *PGTrustRepository) LiftRuntimeRestriction(ctx context.Context, restrictionID uuid.UUID, _ uuid.UUID, liftedBy *uuid.UUID, liftedAt time.Time, reasonCode string) error {
	if liftedAt.IsZero() {
		liftedAt = time.Now().UTC()
	}
	const query = `
		UPDATE runtime_restrictions
		SET
			status = $2,
			lifted_by_staff_id = $3,
			lifted_at = $4,
			reason_code = CASE WHEN $5 <> '' THEN $5 ELSE reason_code END
		WHERE id = $1
			AND status = $6
	`
	if _, err := r.pool.Exec(
		ctx,
		query,
		restrictionID,
		string(model.RuntimeRestrictionLifted),
		liftedBy,
		liftedAt,
		reasonCode,
		string(model.RuntimeRestrictionActive),
	); err != nil {
		return fmt.Errorf("lift runtime restriction: %w", err)
	}
	return nil
}

func (r *PGTrustRepository) CreateRestrictionAppeal(ctx context.Context, appeal model.RestrictionAppeal) (model.RestrictionAppeal, error) {
	if appeal.CreatedAt.IsZero() {
		appeal.CreatedAt = time.Now().UTC()
	}
	if appeal.UpdatedAt.IsZero() {
		appeal.UpdatedAt = appeal.CreatedAt
	}
	const query = `
		INSERT INTO restriction_appeals (
			id, user_id, restriction_id, status, reason_code, user_message,
			idempotency_key, created_at, updated_at
		) VALUES (
			$1, $2, $3, $4, $5, $6,
			$7, $8, $9
		)
		ON CONFLICT (user_id, restriction_id, idempotency_key)
			WHERE idempotency_key <> ''
		DO UPDATE SET
			updated_at = restriction_appeals.updated_at
		RETURNING
			id, user_id, restriction_id, status, reason_code, user_message,
			idempotency_key, created_at, updated_at, decided_at, decided_by_staff_id,
			decision_reason_code, staff_comment
	`
	stored, err := scanRestrictionAppealRow(r.pool.QueryRow(
		ctx,
		query,
		appeal.ID,
		appeal.UserID,
		appeal.RestrictionID,
		string(appeal.Status),
		appeal.ReasonCode,
		appeal.UserMessage,
		appeal.IdempotencyKey,
		appeal.CreatedAt,
		appeal.UpdatedAt,
	))
	if err != nil {
		return model.RestrictionAppeal{}, fmt.Errorf("insert restriction appeal: %w", err)
	}
	return stored, nil
}

func (r *PGTrustRepository) GetRestrictionAppeal(ctx context.Context, appealID uuid.UUID) (model.RestrictionAppeal, error) {
	const query = `
		SELECT
			id, user_id, restriction_id, status, reason_code, user_message,
			idempotency_key, created_at, updated_at, decided_at, decided_by_staff_id,
			decision_reason_code, staff_comment
		FROM restriction_appeals
		WHERE id = $1
		LIMIT 1
	`
	appeal, err := scanRestrictionAppealRow(r.pool.QueryRow(ctx, query, appealID))
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return model.RestrictionAppeal{}, port.ErrNotFound
		}
		return model.RestrictionAppeal{}, fmt.Errorf("select restriction appeal: %w", err)
	}
	return appeal, nil
}

func (r *PGTrustRepository) ListRestrictionAppeals(ctx context.Context, input model.ListRestrictionAppealsInput) ([]model.RestrictionAppeal, error) {
	const query = `
		SELECT
			id, user_id, restriction_id, status, reason_code, user_message,
			idempotency_key, created_at, updated_at, decided_at, decided_by_staff_id,
			decision_reason_code, staff_comment
		FROM restriction_appeals
		WHERE ($1 = '' OR status = $1)
			AND ($2::uuid IS NULL OR user_id = $2)
		ORDER BY created_at DESC, id DESC
	`
	rows, err := r.pool.Query(ctx, query, string(input.Status), input.UserID)
	if err != nil {
		return nil, fmt.Errorf("list restriction appeals: %w", err)
	}
	defer rows.Close()

	var appeals []model.RestrictionAppeal
	for rows.Next() {
		appeal, err := scanRestrictionAppealRow(rows)
		if err != nil {
			return nil, fmt.Errorf("scan restriction appeal: %w", err)
		}
		appeals = append(appeals, appeal)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("iterate restriction appeals: %w", err)
	}
	return appeals, nil
}

func (r *PGTrustRepository) SaveRestrictionAppealDecision(ctx context.Context, appeal model.RestrictionAppeal) (model.RestrictionAppeal, error) {
	if appeal.UpdatedAt.IsZero() {
		appeal.UpdatedAt = time.Now().UTC()
	}
	const query = `
		UPDATE restriction_appeals
		SET
			status = $2,
			updated_at = $3,
			decided_at = $4,
			decided_by_staff_id = $5,
			decision_reason_code = $6,
			staff_comment = $7
		WHERE id = $1
			AND status = $8
		RETURNING
			id, user_id, restriction_id, status, reason_code, user_message,
			idempotency_key, created_at, updated_at, decided_at, decided_by_staff_id,
			decision_reason_code, staff_comment
	`
	stored, err := scanRestrictionAppealRow(r.pool.QueryRow(
		ctx,
		query,
		appeal.ID,
		string(appeal.Status),
		appeal.UpdatedAt,
		appeal.DecidedAt,
		appeal.DecidedByStaffID,
		appeal.DecisionReasonCode,
		appeal.StaffComment,
		string(model.RestrictionAppealStatusPending),
	))
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return model.RestrictionAppeal{}, port.ErrNotFound
		}
		return model.RestrictionAppeal{}, fmt.Errorf("update restriction appeal decision: %w", err)
	}
	return stored, nil
}

type appealRowScanner interface {
	Scan(dest ...any) error
}

func scanRestrictionAppealRow(row appealRowScanner) (model.RestrictionAppeal, error) {
	var (
		appeal    model.RestrictionAppeal
		statusRaw string
	)
	err := row.Scan(
		&appeal.ID,
		&appeal.UserID,
		&appeal.RestrictionID,
		&statusRaw,
		&appeal.ReasonCode,
		&appeal.UserMessage,
		&appeal.IdempotencyKey,
		&appeal.CreatedAt,
		&appeal.UpdatedAt,
		&appeal.DecidedAt,
		&appeal.DecidedByStaffID,
		&appeal.DecisionReasonCode,
		&appeal.StaffComment,
	)
	if err != nil {
		return model.RestrictionAppeal{}, err
	}
	appeal.Status = model.RestrictionAppealStatus(statusRaw)
	return appeal, nil
}
