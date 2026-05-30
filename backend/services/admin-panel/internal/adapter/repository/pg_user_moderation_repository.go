package repository

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/dkhvan-dev/flyfy/backend/services/admin-panel/internal/domain/model"
)

type PGUserModerationRepository struct {
	pool *pgxpool.Pool
}

func NewPGUserModerationRepository(pool *pgxpool.Pool) *PGUserModerationRepository {
	return &PGUserModerationRepository{pool: pool}
}

func (r *PGUserModerationRepository) CreateUserModerationCase(
	ctx context.Context,
	params model.CreateUserModerationCaseParams,
) (model.UserModerationCase, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return model.UserModerationCase{}, fmt.Errorf("begin user moderation case tx: %w", err)
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
		INSERT INTO user_moderation_cases (
			target_user_id, source, reason_code, priority, status,
			assigned_staff_id, staff_comment, created_at, updated_at
		)
		VALUES ($1, $2, $3, $4, 'OPEN', $5, $6, now(), now())
		RETURNING id, target_user_id, source, reason_code, priority, status,
		          assigned_staff_id, decision, staff_comment,
		          created_at, updated_at, resolved_at
	`, params.TargetUserID, string(params.Source), params.ReasonCode, string(params.Priority),
		params.AssignedStaffID, params.StaffComment)

	item, err := scanUserModerationCase(row)
	if err != nil {
		return model.UserModerationCase{}, err
	}

	if params.CreatedByStaffID != uuid.Nil {
		if _, err = tx.Exec(ctx, `
			INSERT INTO user_moderation_case_events (
				case_id, actor_staff_id, event_type, to_status, reason_code, comment, created_at
			)
			VALUES ($1, $2, 'CREATED', 'OPEN', $3, $4, now())
		`, item.ID, params.CreatedByStaffID, params.ReasonCode, params.StaffComment); err != nil {
			return model.UserModerationCase{}, fmt.Errorf("insert user moderation case created event: %w", err)
		}
	}

	if err = tx.Commit(ctx); err != nil {
		return model.UserModerationCase{}, fmt.Errorf("commit user moderation case tx: %w", err)
	}

	return item, nil
}

func (r *PGUserModerationRepository) GetUserModerationCase(
	ctx context.Context,
	id uuid.UUID,
) (model.UserModerationCase, error) {
	row := r.pool.QueryRow(ctx, `
		SELECT id, target_user_id, source, reason_code, priority, status,
		       assigned_staff_id, decision, staff_comment,
		       created_at, updated_at, resolved_at
		FROM user_moderation_cases
		WHERE id = $1
		LIMIT 1
	`, id)

	item, err := scanUserModerationCase(row)
	if errors.Is(err, pgx.ErrNoRows) {
		return model.UserModerationCase{}, nil
	}
	if err != nil {
		return model.UserModerationCase{}, err
	}
	return item, nil
}

func (r *PGUserModerationRepository) ListUserModerationCases(
	ctx context.Context,
	userID uuid.UUID,
) ([]model.UserModerationCase, error) {
	rows, err := r.pool.Query(ctx, `
		SELECT id, target_user_id, source, reason_code, priority, status,
		       assigned_staff_id, decision, staff_comment,
		       created_at, updated_at, resolved_at
		FROM user_moderation_cases
		WHERE target_user_id = $1
		ORDER BY created_at DESC, id DESC
	`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	items := make([]model.UserModerationCase, 0)
	for rows.Next() {
		item, scanErr := scanUserModerationCase(rows)
		if scanErr != nil {
			return nil, scanErr
		}
		items = append(items, item)
	}
	return items, rows.Err()
}

func (r *PGUserModerationRepository) ResolveUserModerationCase(
	ctx context.Context,
	params model.ResolveUserModerationCaseParams,
) (model.UserModerationCase, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return model.UserModerationCase{}, fmt.Errorf("begin resolve user moderation case tx: %w", err)
	}
	defer tx.Rollback(ctx)

	var previousStatus string
	if err = tx.QueryRow(ctx, `
		SELECT status
		FROM user_moderation_cases
		WHERE id = $1
		FOR UPDATE
	`, params.CaseID).Scan(&previousStatus); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return model.UserModerationCase{}, nil
		}
		return model.UserModerationCase{}, fmt.Errorf("lock user moderation case: %w", err)
	}

	row := tx.QueryRow(ctx, `
		UPDATE user_moderation_cases
		SET status = 'RESOLVED',
		    decision = $2,
		    reason_code = $3,
		    staff_comment = $4,
		    updated_at = now(),
		    resolved_at = now()
		WHERE id = $1
		RETURNING id, target_user_id, source, reason_code, priority, status,
		          assigned_staff_id, decision, staff_comment,
		          created_at, updated_at, resolved_at
	`, params.CaseID, string(params.Decision), params.ReasonCode, params.StaffComment)

	item, err := scanUserModerationCase(row)
	if err != nil {
		return model.UserModerationCase{}, err
	}

	if _, err = tx.Exec(ctx, `
		INSERT INTO user_moderation_case_events (
			case_id, actor_staff_id, event_type, from_status, to_status,
			decision, reason_code, comment, created_at
		)
		VALUES ($1, $2, 'RESOLVED', $3, 'RESOLVED', $4, $5, $6, now())
	`, params.CaseID, params.ActorStaffID, previousStatus, string(params.Decision),
		params.ReasonCode, params.StaffComment); err != nil {
		return model.UserModerationCase{}, fmt.Errorf("insert user moderation case resolved event: %w", err)
	}

	if err = tx.Commit(ctx); err != nil {
		return model.UserModerationCase{}, fmt.Errorf("commit resolve user moderation case tx: %w", err)
	}

	return item, nil
}

func (r *PGUserModerationRepository) CreateUserRestriction(
	ctx context.Context,
	params model.CreateUserRestrictionParams,
) (model.UserManualRestriction, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return model.UserManualRestriction{}, fmt.Errorf("begin create user restriction tx: %w", err)
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
		INSERT INTO user_manual_restrictions (
			user_id, case_id, restriction_code, status, reason_code,
			staff_comment, created_by_staff_id, expires_at, created_at
		)
		VALUES ($1, $2, $3, 'ACTIVE', $4, $5, $6, $7, now())
		RETURNING id, user_id, case_id, restriction_code, status, reason_code,
		          staff_comment, created_by_staff_id, expires_at, created_at,
		          lifted_at, lifted_by_staff_id
	`, params.UserID, params.CaseID, string(params.RestrictionCode), params.ReasonCode,
		params.StaffComment, params.CreatedByStaffID, params.ExpiresAt)

	item, err := scanUserManualRestriction(row)
	if err != nil {
		return model.UserManualRestriction{}, err
	}
	if err := insertUserRestrictionOutboxEvent(ctx, tx, model.UserRestrictionOutboxEventCreated, item, params.ReasonCode); err != nil {
		return model.UserManualRestriction{}, err
	}
	if err = tx.Commit(ctx); err != nil {
		return model.UserManualRestriction{}, fmt.Errorf("commit create user restriction tx: %w", err)
	}
	return item, nil
}

func (r *PGUserModerationRepository) LiftUserRestriction(
	ctx context.Context,
	params model.LiftUserRestrictionParams,
) (model.UserManualRestriction, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return model.UserManualRestriction{}, fmt.Errorf("begin lift user restriction tx: %w", err)
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
		UPDATE user_manual_restrictions
		SET status = 'LIFTED',
		    lifted_at = now(),
		    lifted_by_staff_id = $2
		WHERE id = $1
		  AND status = 'ACTIVE'
		RETURNING id, user_id, case_id, restriction_code, status, reason_code,
		          staff_comment, created_by_staff_id, expires_at, created_at,
	          lifted_at, lifted_by_staff_id
	`, params.RestrictionID, params.LiftedByStaffID)

	item, err := scanUserManualRestriction(row)
	if errors.Is(err, pgx.ErrNoRows) {
		return model.UserManualRestriction{}, nil
	}
	if err != nil {
		return model.UserManualRestriction{}, err
	}
	if err := insertUserRestrictionOutboxEvent(ctx, tx, model.UserRestrictionOutboxEventLifted, item, params.ReasonCode); err != nil {
		return model.UserManualRestriction{}, err
	}
	if err = tx.Commit(ctx); err != nil {
		return model.UserManualRestriction{}, fmt.Errorf("commit lift user restriction tx: %w", err)
	}
	return item, nil
}

func (r *PGUserModerationRepository) ListActiveUserRestrictions(
	ctx context.Context,
	userID uuid.UUID,
) ([]model.UserManualRestriction, error) {
	rows, err := r.pool.Query(ctx, `
		SELECT id, user_id, case_id, restriction_code, status, reason_code,
		       staff_comment, created_by_staff_id, expires_at, created_at,
		       lifted_at, lifted_by_staff_id
		FROM user_manual_restrictions
		WHERE user_id = $1
		  AND status = 'ACTIVE'
		  AND (expires_at IS NULL OR expires_at > now())
		ORDER BY created_at DESC, id DESC
	`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	items := make([]model.UserManualRestriction, 0)
	for rows.Next() {
		item, scanErr := scanUserManualRestriction(rows)
		if scanErr != nil {
			return nil, scanErr
		}
		items = append(items, item)
	}
	return items, rows.Err()
}

func scanUserModerationCase(row staffScanner) (model.UserModerationCase, error) {
	var item model.UserModerationCase
	var source string
	var priority string
	var status string
	var decision *string
	err := row.Scan(
		&item.ID,
		&item.TargetUserID,
		&source,
		&item.ReasonCode,
		&priority,
		&status,
		&item.AssignedStaffID,
		&decision,
		&item.StaffComment,
		&item.CreatedAt,
		&item.UpdatedAt,
		&item.ResolvedAt,
	)
	if err != nil {
		return model.UserModerationCase{}, err
	}
	item.Source = model.UserModerationSource(source)
	item.Priority = model.UserModerationPriority(priority)
	item.Status = model.UserModerationStatus(status)
	if decision != nil {
		value := model.UserModerationDecision(*decision)
		item.Decision = &value
	}
	return item, nil
}

func scanUserManualRestriction(row staffScanner) (model.UserManualRestriction, error) {
	var item model.UserManualRestriction
	var restrictionCode string
	var status string
	err := row.Scan(
		&item.ID,
		&item.UserID,
		&item.CaseID,
		&restrictionCode,
		&status,
		&item.ReasonCode,
		&item.StaffComment,
		&item.CreatedByStaffID,
		&item.ExpiresAt,
		&item.CreatedAt,
		&item.LiftedAt,
		&item.LiftedByStaffID,
	)
	if err != nil {
		return model.UserManualRestriction{}, err
	}
	item.RestrictionCode = model.UserRestrictionCode(restrictionCode)
	item.Status = model.UserRestrictionStatus(status)
	return item, nil
}

type userRestrictionOutboxPayload struct {
	RestrictionID    uuid.UUID                 `json:"restrictionId"`
	UserID           uuid.UUID                 `json:"userId"`
	CaseID           *uuid.UUID                `json:"caseId,omitempty"`
	RestrictionCode  model.UserRestrictionCode `json:"restrictionCode"`
	ReasonCode       string                    `json:"reasonCode"`
	CreatedByStaffID uuid.UUID                 `json:"createdByStaffId"`
	LiftedByStaffID  *uuid.UUID                `json:"liftedByStaffId,omitempty"`
	ExpiresAt        *time.Time                `json:"expiresAt,omitempty"`
	OccurredAt       time.Time                 `json:"occurredAt"`
}

func insertUserRestrictionOutboxEvent(
	ctx context.Context,
	tx pgx.Tx,
	eventType string,
	item model.UserManualRestriction,
	reasonCode string,
) error {
	occurredAt := item.CreatedAt
	if item.LiftedAt != nil {
		occurredAt = *item.LiftedAt
	}
	payload, err := json.Marshal(userRestrictionOutboxPayload{
		RestrictionID:    item.ID,
		UserID:           item.UserID,
		CaseID:           item.CaseID,
		RestrictionCode:  item.RestrictionCode,
		ReasonCode:       reasonCode,
		CreatedByStaffID: item.CreatedByStaffID,
		LiftedByStaffID:  item.LiftedByStaffID,
		ExpiresAt:        item.ExpiresAt,
		OccurredAt:       occurredAt,
	})
	if err != nil {
		return fmt.Errorf("marshal user restriction outbox payload: %w", err)
	}
	if _, err = tx.Exec(ctx, `
		INSERT INTO user_restriction_outbox (
			event_type, aggregate_id, user_id, payload, status, next_attempt_at, created_at
		)
		VALUES ($1, $2, $3, $4, 'PENDING', now(), now())
	`, eventType, item.ID, item.UserID, payload); err != nil {
		return fmt.Errorf("insert user restriction outbox event: %w", err)
	}
	return nil
}
