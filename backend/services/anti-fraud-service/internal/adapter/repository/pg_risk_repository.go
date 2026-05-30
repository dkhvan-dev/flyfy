package repository

import (
	"context"
	"encoding/json"
	"fmt"
	"strings"

	"github.com/jackc/pgx/v5/pgxpool"

	"kz/inflap/backend/services/anti-fraud-service/internal/domain/model"
	"kz/inflap/backend/services/anti-fraud-service/internal/domain/port"
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
			decision, risk_score, reasons, policy_version, shadow_mode,
			review_status, updated_at,
			metadata, created_at
		) VALUES (
			$1, $2, $3, $4, $5, $6,
			$7, $8, $9, $10, $11,
			$12, $13,
			$14::jsonb, $15
		)
	`
	reviewStatus := model.NormalizeReviewStatus(assessment.ReviewStatus)
	if assessment.UpdatedAt.IsZero() {
		assessment.UpdatedAt = assessment.CreatedAt
	}

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
		string(reviewStatus),
		assessment.UpdatedAt,
		string(metadata),
		assessment.CreatedAt,
	)
	if err != nil {
		return fmt.Errorf("insert risk assessment: %w", err)
	}

	return nil
}

func (r *PGRiskRepository) ListAssessments(ctx context.Context, filter port.RiskAssessmentFilter) ([]*model.RiskAssessment, error) {
	query := riskAssessmentSelectSQL() + " WHERE TRUE"
	args := make([]any, 0, 8)
	argPos := 1

	if len(filter.SubjectTypes) > 0 {
		query += fmt.Sprintf(" AND subject_type = ANY($%d)", argPos)
		args = append(args, normalizedCodes(filter.SubjectTypes))
		argPos++
	}
	if len(filter.Decisions) > 0 {
		query += fmt.Sprintf(" AND decision = ANY($%d)", argPos)
		args = append(args, riskDecisionStrings(filter.Decisions))
		argPos++
	}
	if len(filter.ReviewStatuses) > 0 {
		query += fmt.Sprintf(" AND review_status = ANY($%d)", argPos)
		args = append(args, reviewStatusStrings(filter.ReviewStatuses))
		argPos++
	}
	if filter.EnforcedOnly {
		query += " AND shadow_mode = false"
	}

	limit := filter.Limit
	if limit <= 0 || limit > 500 {
		limit = 100
	}
	offset := filter.Offset
	if offset < 0 {
		offset = 0
	}
	query += fmt.Sprintf(" ORDER BY risk_score DESC, created_at DESC LIMIT $%d OFFSET $%d", argPos, argPos+1)
	args = append(args, limit, offset)

	rows, err := r.pool.Query(ctx, query, args...)
	if err != nil {
		return nil, fmt.Errorf("list risk assessments: %w", err)
	}
	defer rows.Close()

	items := make([]*model.RiskAssessment, 0)
	for rows.Next() {
		item, err := scanRiskAssessment(rows)
		if err != nil {
			return nil, err
		}
		items = append(items, item)
	}
	if err = rows.Err(); err != nil {
		return nil, fmt.Errorf("iterate risk assessments: %w", err)
	}
	return items, nil
}

func (r *PGRiskRepository) UpdateAssessmentReview(ctx context.Context, input port.RiskAssessmentReviewInput) (*model.RiskAssessment, error) {
	query := riskAssessmentSelectSQL() + `
		WHERE id = $1
	`
	update := `
		UPDATE risk_assessments
		SET review_status = $2,
		    reviewed_by_staff_id = $3,
		    review_reason_codes = $4,
		    review_comment = $5,
		    reviewed_at = $6,
		    updated_at = $6
		WHERE id = $1
	`
	if _, err := r.pool.Exec(
		ctx,
		update,
		input.AssessmentID,
		string(model.NormalizeReviewStatus(input.Status)),
		input.ReviewedByStaffID,
		input.ReasonCodes,
		strings.TrimSpace(input.Comment),
		input.ReviewedAt,
	); err != nil {
		return nil, fmt.Errorf("update risk assessment review: %w", err)
	}
	item, err := scanRiskAssessment(r.pool.QueryRow(ctx, query, input.AssessmentID))
	if err != nil {
		return nil, err
	}
	return item, nil
}

type riskAssessmentScanner interface {
	Scan(dest ...any) error
}

func riskAssessmentSelectSQL() string {
	return `
		SELECT
			id, event_id, action, actor_user_id, subject_type, subject_id,
			decision, risk_score, reasons, policy_version, shadow_mode,
			review_status, reviewed_by_staff_id, review_reason_codes, review_comment,
			reviewed_at, updated_at, metadata, created_at
		FROM risk_assessments
	`
}

func scanRiskAssessment(row riskAssessmentScanner) (*model.RiskAssessment, error) {
	var item model.RiskAssessment
	var decision string
	var reviewStatus string
	var metadataBytes []byte
	if err := row.Scan(
		&item.ID,
		&item.EventID,
		&item.Action,
		&item.ActorUserID,
		&item.SubjectType,
		&item.SubjectID,
		&decision,
		&item.RiskScore,
		&item.Reasons,
		&item.PolicyVersion,
		&item.ShadowMode,
		&reviewStatus,
		&item.ReviewedByStaffID,
		&item.ReviewReasonCodes,
		&item.ReviewComment,
		&item.ReviewedAt,
		&item.UpdatedAt,
		&metadataBytes,
		&item.CreatedAt,
	); err != nil {
		return nil, fmt.Errorf("scan risk assessment: %w", err)
	}
	item.Decision = model.RiskDecision(decision)
	item.ReviewStatus = model.NormalizeReviewStatus(model.RiskReviewStatus(reviewStatus))
	item.Metadata = map[string]any{}
	if len(metadataBytes) > 0 {
		if err := json.Unmarshal(metadataBytes, &item.Metadata); err != nil {
			return nil, fmt.Errorf("unmarshal risk assessment metadata: %w", err)
		}
	}
	return &item, nil
}

func normalizedCodes(values []string) []string {
	out := make([]string, 0, len(values))
	for _, value := range values {
		code := model.NormalizeCode(value)
		if code != "" {
			out = append(out, code)
		}
	}
	return out
}

func riskDecisionStrings(values []model.RiskDecision) []string {
	out := make([]string, 0, len(values))
	for _, value := range values {
		code := model.NormalizeCode(string(value))
		if code != "" {
			out = append(out, code)
		}
	}
	return out
}

func reviewStatusStrings(values []model.RiskReviewStatus) []string {
	out := make([]string, 0, len(values))
	for _, value := range values {
		status := model.NormalizeReviewStatus(value)
		out = append(out, string(status))
	}
	return out
}

var _ port.RiskRepository = (*PGRiskRepository)(nil)
