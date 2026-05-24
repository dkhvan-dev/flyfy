package repository

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/dkhvan-dev/flyfy/backend/services/admin-panel/internal/domain/enum"
	"github.com/dkhvan-dev/flyfy/backend/services/admin-panel/internal/domain/model"
	"github.com/dkhvan-dev/flyfy/backend/services/admin-panel/internal/domain/port"
)

type PGModerationRepository struct {
	pool *pgxpool.Pool
}

func NewPGModerationRepository(pool *pgxpool.Pool) *PGModerationRepository {
	return &PGModerationRepository{pool: pool}
}

func (r *PGModerationRepository) UpsertExcursionCase(ctx context.Context, item model.ExcursionModerationItem) (*model.ModerationCase, error) {
	now := time.Now().UTC()
	snapshot, err := json.Marshal(item)
	if err != nil {
		return nil, err
	}
	caseID := uuid.New()
	row := r.pool.QueryRow(ctx, `
		INSERT INTO moderation_cases (
			id, target_type, target_id, source_service, source_revision, status,
			priority, snapshot, metadata, opened_at, created_at, updated_at
		)
		VALUES ($1, 'EXCURSION', $2, 'excursion-service', $3, 'OPEN',
		        $4, $5, '{}'::jsonb, $6, $6, $6)
		ON CONFLICT (target_type, target_id, source_revision)
		    WHERE status IN ('OPEN', 'IN_REVIEW', 'ESCALATED')
		DO UPDATE SET
		    snapshot = EXCLUDED.snapshot,
		    priority = GREATEST(moderation_cases.priority, EXCLUDED.priority),
		    updated_at = EXCLUDED.updated_at
		RETURNING id, target_type, target_id, source_service, source_revision, status,
		          priority, reason, snapshot, metadata, assigned_admin_id, opened_by,
		          opened_at, due_at, resolved_at, lock_version, created_at, updated_at
	`, caseID, item.ID, item.Revision, moderationPriority(item), string(snapshot), now)
	return scanModerationCase(row)
}

func (r *PGModerationRepository) CancelStaleExcursionCases(ctx context.Context, activeTargetIDs []uuid.UUID, now time.Time) error {
	ids := make([]uuid.UUID, 0, len(activeTargetIDs))
	seen := make(map[uuid.UUID]struct{}, len(activeTargetIDs))
	for _, id := range activeTargetIDs {
		if id == uuid.Nil {
			continue
		}
		if _, ok := seen[id]; ok {
			continue
		}
		seen[id] = struct{}{}
		ids = append(ids, id)
	}
	_, err := r.pool.Exec(ctx, `
		UPDATE moderation_cases
		SET status = 'CANCELLED',
		    resolved_at = $1,
		    updated_at = $1
		WHERE target_type = 'EXCURSION'
		  AND status IN ('OPEN', 'IN_REVIEW', 'ESCALATED')
		  AND NOT (target_id = ANY($2::uuid[]))
	`, now, ids)
	if err != nil {
		return fmt.Errorf("cancel stale excursion cases: %w", err)
	}
	return nil
}

func (r *PGModerationRepository) UpsertActivityCase(ctx context.Context, item model.ActivityModerationItem) (*model.ModerationCase, error) {
	now := time.Now().UTC()
	snapshot, err := json.Marshal(item)
	if err != nil {
		return nil, err
	}
	caseID := uuid.New()
	row := r.pool.QueryRow(ctx, `
		INSERT INTO moderation_cases (
			id, target_type, target_id, source_service, source_revision, status,
			priority, snapshot, metadata, opened_at, created_at, updated_at
		)
		VALUES ($1, 'ACTIVITY', $2, 'activity-service', $3, 'OPEN',
		        $4, $5, '{}'::jsonb, $6, $6, $6)
		ON CONFLICT (target_type, target_id, source_revision)
		    WHERE status IN ('OPEN', 'IN_REVIEW', 'ESCALATED')
		DO UPDATE SET
		    snapshot = EXCLUDED.snapshot,
		    priority = GREATEST(moderation_cases.priority, EXCLUDED.priority),
		    updated_at = EXCLUDED.updated_at
		RETURNING id, target_type, target_id, source_service, source_revision, status,
		          priority, reason, snapshot, metadata, assigned_admin_id, opened_by,
		          opened_at, due_at, resolved_at, lock_version, created_at, updated_at
	`, caseID, item.ID, item.Revision, activityModerationPriority(item), string(snapshot), now)
	return scanModerationCase(row)
}

func (r *PGModerationRepository) CancelStaleActivityCases(ctx context.Context, activeTargetIDs []uuid.UUID, now time.Time) error {
	ids := make([]uuid.UUID, 0, len(activeTargetIDs))
	seen := make(map[uuid.UUID]struct{}, len(activeTargetIDs))
	for _, id := range activeTargetIDs {
		if id == uuid.Nil {
			continue
		}
		if _, ok := seen[id]; ok {
			continue
		}
		seen[id] = struct{}{}
		ids = append(ids, id)
	}
	_, err := r.pool.Exec(ctx, `
		UPDATE moderation_cases
		SET status = 'CANCELLED',
		    resolved_at = $1,
		    updated_at = $1
		WHERE target_type = 'ACTIVITY'
		  AND status IN ('OPEN', 'IN_REVIEW', 'ESCALATED')
		  AND NOT (target_id = ANY($2::uuid[]))
	`, now, ids)
	if err != nil {
		return fmt.Errorf("cancel stale activity cases: %w", err)
	}
	return nil
}

func (r *PGModerationRepository) ListCases(ctx context.Context, filter model.ModerationQueueFilter) ([]*model.ModerationCase, error) {
	query, args := buildListCasesQuery(filter)
	rows, err := r.pool.Query(ctx, query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var items []*model.ModerationCase
	for rows.Next() {
		item, err := scanModerationCase(rows)
		if err != nil {
			return nil, err
		}
		items = append(items, item)
	}
	return items, rows.Err()
}

func buildListCasesQuery(filter model.ModerationQueueFilter) (string, []any) {
	parts := []string{`
		SELECT id, target_type, target_id, source_service, source_revision, status,
		       priority, reason, snapshot, metadata, assigned_admin_id, opened_by,
		       opened_at, due_at, resolved_at, lock_version, created_at, updated_at
		FROM moderation_cases
		WHERE 1=1
	`}
	args := []any{}
	addArg := func(value any) string {
		args = append(args, value)
		return fmt.Sprintf("$%d", len(args))
	}
	if filter.TargetType != nil {
		parts = append(parts, " AND target_type = "+addArg(string(*filter.TargetType)))
	}
	if len(filter.Statuses) > 0 {
		statuses := make([]string, 0, len(filter.Statuses))
		for _, status := range filter.Statuses {
			statuses = append(statuses, string(status))
		}
		parts = append(parts, " AND status = ANY("+addArg(statuses)+")")
	}
	if filter.AssignedAdminID != nil {
		parts = append(parts, " AND assigned_admin_id = "+addArg(*filter.AssignedAdminID))
	}
	if search := likePattern(filter.Search); search != "" {
		parts = append(parts, " AND "+moderationSearchSQL()+" LIKE "+addArg(search)+" ESCAPE '\\'")
	}
	if city := strings.TrimSpace(strings.ToLower(filter.City)); city != "" {
		parts = append(parts, " AND ("+
			"LOWER(COALESCE(snapshot->>'DepartureCityID', '')) = "+addArg(city)+
			" OR LOWER(COALESCE(snapshot->>'CityName', '')) LIKE "+addArg("%"+escapeLike(city)+"%")+" ESCAPE '\\')")
	}
	if signal := strings.TrimSpace(filter.Signal); signal != "" {
		parts = append(parts, " AND COALESCE(snapshot->'ModerationReasonCodes', '[]'::jsonb) ? "+addArg(signal))
	}
	switch filter.Risk {
	case model.ModerationRiskFilterFlagged:
		parts = append(parts, " AND "+moderationRiskScoreSQL()+" > 0")
	case model.ModerationRiskFilterHigh:
		parts = append(parts, " AND "+moderationRiskScoreSQL()+" >= 50")
	}
	parts = append(parts, " ORDER BY "+moderationQueueOrderBy(filter.Sort))
	parts = append(parts, " LIMIT "+addArg(filter.Limit)+" OFFSET "+addArg(filter.Offset))
	return strings.Join(parts, ""), args
}

func likePattern(value string) string {
	value = strings.TrimSpace(strings.ToLower(value))
	if value == "" {
		return ""
	}
	return "%" + escapeLike(value) + "%"
}

func escapeLike(value string) string {
	replacer := strings.NewReplacer(`\`, `\\`, `%`, `\%`, `_`, `\_`)
	return replacer.Replace(value)
}

func moderationRiskScoreSQL() string {
	return "CASE " +
		"WHEN jsonb_typeof(snapshot->'PublishRiskScore') = 'number' THEN (snapshot->>'PublishRiskScore')::int " +
		"WHEN jsonb_typeof(snapshot->'ModerationRiskScore') = 'number' THEN (snapshot->>'ModerationRiskScore')::int " +
		"ELSE 0 END"
}

func moderationSearchSQL() string {
	return "LOWER(" +
		"COALESCE(snapshot->>'Title', '') || ' ' || " +
		"COALESCE(snapshot->>'Summary', '') || ' ' || " +
		"COALESCE(snapshot->>'Description', '') || ' ' || " +
		"COALESCE(snapshot->>'LandmarkName', '') || ' ' || " +
		"COALESCE(snapshot->>'ProductTranslations', '') || ' ' || " +
		"COALESCE(snapshot->>'Translations', '') || ' ' || " +
		"COALESCE(snapshot->>'AttractionNames', '') || ' ' || " +
		"COALESCE(snapshot->>'AttractionNamesByLocale', '') || ' ' || " +
		"COALESCE(snapshot->>'GuideDisplayName', '') || ' ' || " +
		"COALESCE(snapshot->>'GuideNickname', '') || ' ' || " +
		"COALESCE(snapshot->>'GuideFirstName', '') || ' ' || " +
		"COALESCE(snapshot->>'GuideLastName', '') || ' ' || " +
		"COALESCE(snapshot->>'HostDisplayName', '') || ' ' || " +
		"COALESCE(snapshot->>'CategorySlug', '') || ' ' || " +
		"COALESCE(snapshot->>'AddressText', ''))"
}

func moderationQueueOrderBy(sort model.ModerationQueueSort) string {
	switch sort {
	case model.ModerationQueueSortOpenedDesc:
		return "opened_at DESC"
	case model.ModerationQueueSortOpenedAsc:
		return "opened_at ASC"
	case model.ModerationQueueSortRiskDesc:
		return moderationRiskScoreSQL() + " DESC, priority DESC, opened_at ASC"
	case model.ModerationQueueSortSubmittedDesc:
		return "COALESCE(NULLIF(snapshot->>'SubmittedForReviewAt', '')::timestamptz, NULLIF(snapshot->>'ModerationTriggeredAt', '')::timestamptz) DESC NULLS LAST, opened_at DESC"
	case model.ModerationQueueSortPriorityDesc:
		fallthrough
	default:
		return "priority DESC, opened_at ASC"
	}
}

func (r *PGModerationRepository) GetCase(ctx context.Context, id uuid.UUID) (*model.ModerationCase, error) {
	row := r.pool.QueryRow(ctx, `
		SELECT id, target_type, target_id, source_service, source_revision, status,
		       priority, reason, snapshot, metadata, assigned_admin_id, opened_by,
		       opened_at, due_at, resolved_at, lock_version, created_at, updated_at
		FROM moderation_cases
		WHERE id = $1
	`, id)
	return scanModerationCase(row)
}

func (r *PGModerationRepository) ListDecisions(ctx context.Context, caseID uuid.UUID) ([]*model.ModerationDecision, error) {
	rows, err := r.pool.Query(ctx, `
		SELECT d.id, d.case_id, d.decision_type, d.source_revision, d.reason_codes,
		       d.public_comment, d.internal_comment, d.idempotency_key, d.decided_by,
		       COALESCE(NULLIF(s.display_name, ''), ''),
		       d.apply_status, d.applied_at, d.source_response, d.created_at
		FROM moderation_decisions d
		LEFT JOIN staff_users s ON s.id = d.decided_by
		WHERE d.case_id = $1
		ORDER BY d.created_at DESC
	`, caseID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var items []*model.ModerationDecision
	for rows.Next() {
		item, err := scanModerationDecision(rows)
		if err != nil {
			return nil, err
		}
		items = append(items, item)
	}
	return items, rows.Err()
}

func (r *PGModerationRepository) CreateDecision(ctx context.Context, decision *model.ModerationDecision) error {
	tag, err := r.pool.Exec(ctx, `
		INSERT INTO moderation_decisions (
			id, case_id, decision_type, source_revision, reason_codes, public_comment,
			internal_comment, payload, idempotency_key, decided_by, apply_status, created_at
		)
		VALUES ($1, $2, $3, $4, $5, $6, $7, '{}'::jsonb, $8, $9, $10, $11)
		ON CONFLICT (idempotency_key) DO NOTHING
	`, decision.ID, decision.CaseID, string(decision.DecisionType), decision.SourceRevision,
		decision.ReasonCodes, decision.PublicComment, decision.InternalComment,
		decision.IdempotencyKey, decision.DecidedBy, string(decision.ApplyStatus), decision.CreatedAt)
	if err != nil {
		var pgErr *pgconn.PgError
		if errors.As(err, &pgErr) && pgErr.Code == "23505" {
			if pgErr.ConstraintName == "moderation_decisions_idempotency_key_key" {
				return port.ErrDuplicateDecision
			}
			return port.ErrModerationCaseConflict
		}
		return err
	}
	if tag.RowsAffected() == 0 {
		return port.ErrDuplicateDecision
	}
	return nil
}

func (r *PGModerationRepository) MarkDecisionApplied(ctx context.Context, decisionID uuid.UUID, response []byte, now time.Time) error {
	_, err := r.pool.Exec(ctx, `
		UPDATE moderation_decisions
		SET apply_status = 'APPLIED',
		    applied_at = $2,
		    source_response = $3::jsonb
		WHERE id = $1
	`, decisionID, now, jsonParam(response))
	return err
}

func (r *PGModerationRepository) MarkDecisionFailed(ctx context.Context, decisionID uuid.UUID, response []byte, now time.Time) error {
	_, err := r.pool.Exec(ctx, `
		UPDATE moderation_decisions
		SET apply_status = 'FAILED',
		    applied_at = $2,
		    source_response = $3::jsonb
		WHERE id = $1
	`, decisionID, now, jsonParam(response))
	return err
}

func (r *PGModerationRepository) SupersedeAppliedDecisions(ctx context.Context, caseID uuid.UUID, sourceRevision int, exceptDecisionID uuid.UUID, now time.Time) error {
	_, err := r.pool.Exec(ctx, `
		UPDATE moderation_decisions
		SET apply_status = 'SUPERSEDED',
		    applied_at = COALESCE(applied_at, $4)
		WHERE case_id = $1
		  AND source_revision = $2
		  AND id <> $3
		  AND apply_status = 'APPLIED'
	`, caseID, sourceRevision, exceptDecisionID, now)
	return err
}

func (r *PGModerationRepository) UpdateCaseStatus(ctx context.Context, caseID uuid.UUID, status enum.ModerationCaseStatus, resolvedAt *time.Time, now time.Time) error {
	tag, err := r.pool.Exec(ctx, `
		UPDATE moderation_cases
		SET status = $2,
		    resolved_at = $3,
		    updated_at = $4,
		    lock_version = lock_version + 1
		WHERE id = $1
		  AND status IN ('OPEN', 'IN_REVIEW', 'ESCALATED', 'APPROVED', 'REJECTED')
	`, caseID, string(status), resolvedAt, now)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return port.ErrModerationCaseConflict
	}
	return nil
}

func moderationPriority(item model.ExcursionModerationItem) int {
	priority := item.PublishRiskScore
	if item.GuideTrustScore < 30 {
		priority += 20
	}
	if priority > 100 {
		return 100
	}
	return priority
}

func activityModerationPriority(item model.ActivityModerationItem) int {
	if item.ModerationRiskScore > 100 {
		return 100
	}
	if item.ModerationRiskScore < 0 {
		return 0
	}
	return item.ModerationRiskScore
}

func scanModerationCase(row staffScanner) (*model.ModerationCase, error) {
	var item model.ModerationCase
	var targetType string
	var status string
	err := row.Scan(
		&item.ID,
		&targetType,
		&item.TargetID,
		&item.SourceService,
		&item.SourceRevision,
		&status,
		&item.Priority,
		&item.Reason,
		&item.Snapshot,
		&item.Metadata,
		&item.AssignedAdminID,
		&item.OpenedBy,
		&item.OpenedAt,
		&item.DueAt,
		&item.ResolvedAt,
		&item.LockVersion,
		&item.CreatedAt,
		&item.UpdatedAt,
	)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	item.TargetType = model.ModerationTargetType(targetType)
	item.Status = enum.ModerationCaseStatus(status)
	return &item, nil
}

func scanModerationDecision(row staffScanner) (*model.ModerationDecision, error) {
	var item model.ModerationDecision
	var decisionType string
	var applyStatus string
	err := row.Scan(
		&item.ID,
		&item.CaseID,
		&decisionType,
		&item.SourceRevision,
		&item.ReasonCodes,
		&item.PublicComment,
		&item.InternalComment,
		&item.IdempotencyKey,
		&item.DecidedBy,
		&item.DecidedByName,
		&applyStatus,
		&item.AppliedAt,
		&item.SourceResponse,
		&item.CreatedAt,
	)
	if err != nil {
		return nil, err
	}
	item.DecisionType = enum.ModerationDecisionType(decisionType)
	item.ApplyStatus = enum.ModerationApplyStatus(applyStatus)
	return &item, nil
}
