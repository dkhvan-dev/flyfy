package repository

import (
	"context"
	"encoding/json"
	"fmt"
	"strings"

	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/dkhvan-dev/flyfy/backend/services/anti-fraud-service/internal/domain/model"
	"github.com/dkhvan-dev/flyfy/backend/services/anti-fraud-service/internal/domain/port"
)

type PGRiskRepository struct {
	pool *pgxpool.Pool
}

func NewPGRiskRepository(pool *pgxpool.Pool) *PGRiskRepository {
	return &PGRiskRepository{pool: pool}
}

func (r *PGRiskRepository) CreateEvent(ctx context.Context, event *model.RiskEvent) error {
	signalHashes, err := json.Marshal(event.SignalHashes)
	if err != nil {
		return fmt.Errorf("marshal risk event signal hashes: %w", err)
	}
	metadata, err := json.Marshal(event.Metadata)
	if err != nil {
		return fmt.Errorf("marshal risk event metadata: %w", err)
	}

	const query = `
		INSERT INTO risk_events (
			id, action, actor_user_id, subject_type, subject_id,
			source_service, idempotency_key,
			amount_minor, currency, signal_hashes, metadata, created_at
		) VALUES (
			$1, $2, $3, $4, $5,
			$6, $7,
			$8, $9, $10::jsonb, $11::jsonb, $12
		)
	`

	_, err = r.pool.Exec(
		ctx,
		query,
		event.ID,
		event.Action,
		event.ActorUserID,
		event.SubjectType,
		event.SubjectID,
		event.SourceService,
		event.IdempotencyKey,
		event.AmountMinor,
		event.Currency,
		string(signalHashes),
		string(metadata),
		event.CreatedAt,
	)
	if err != nil {
		return fmt.Errorf("insert risk event: %w", err)
	}

	return nil
}

func (r *PGRiskRepository) CountEvents(ctx context.Context, filter port.RiskEventFilter) (int, error) {
	query := `
		SELECT COUNT(*)
		FROM risk_events
		WHERE created_at >= $1
	`
	args := []any{filter.Since}
	argPos := 2

	if strings.TrimSpace(filter.Action) != "" {
		query += fmt.Sprintf(" AND action = $%d", argPos)
		args = append(args, model.NormalizeCode(filter.Action))
		argPos++
	}
	if filter.ActorUserID != nil {
		query += fmt.Sprintf(" AND actor_user_id = $%d", argPos)
		args = append(args, *filter.ActorUserID)
		argPos++
	}
	if strings.TrimSpace(filter.SignalKey) != "" {
		query += fmt.Sprintf(" AND signal_hashes ->> $%d = $%d", argPos, argPos+1)
		args = append(args, strings.TrimSpace(filter.SignalKey), strings.TrimSpace(filter.SignalHash))
	}

	var count int
	if err := r.pool.QueryRow(ctx, query, args...).Scan(&count); err != nil {
		return 0, fmt.Errorf("count risk events: %w", err)
	}

	return count, nil
}

func (r *PGRiskRepository) CreateAssessment(ctx context.Context, assessment *model.RiskAssessment) error {
	metadata, err := json.Marshal(assessment.Metadata)
	if err != nil {
		return fmt.Errorf("marshal risk assessment metadata: %w", err)
	}

	const query = `
		INSERT INTO risk_assessments (
			id, event_id, action, actor_user_id, subject_type, subject_id,
			decision, risk_score, reasons, policy_version, shadow_mode, metadata, created_at
		) VALUES (
			$1, $2, $3, $4, $5, $6,
			$7, $8, $9, $10, $11, $12::jsonb, $13
		)
	`

	_, err = r.pool.Exec(
		ctx,
		query,
		assessment.ID,
		assessment.EventID,
		assessment.Action,
		assessment.ActorUserID,
		assessment.SubjectType,
		assessment.SubjectID,
		string(assessment.Decision),
		assessment.RiskScore,
		assessment.Reasons,
		assessment.PolicyVersion,
		assessment.ShadowMode,
		string(metadata),
		assessment.CreatedAt,
	)
	if err != nil {
		return fmt.Errorf("insert risk assessment: %w", err)
	}

	return nil
}

var _ port.RiskRepository = (*PGRiskRepository)(nil)
