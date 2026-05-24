package repository

import (
	"context"
	"fmt"
	"strings"

	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/dkhvan-dev/flyfy/backend/services/admin-panel/internal/domain/model"
)

type PGAuditRepository struct {
	pool *pgxpool.Pool
}

func NewPGAuditRepository(pool *pgxpool.Pool) *PGAuditRepository {
	return &PGAuditRepository{pool: pool}
}

func (r *PGAuditRepository) Append(ctx context.Context, event *model.AuditEvent) error {
	_, err := r.pool.Exec(ctx, `
		INSERT INTO audit_log (
			id, actor_staff_id, action, entity_type, entity_id, request_id,
			ip_address_hash, user_agent_hash, before_json, after_json,
			metadata, created_at
		)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
	`, event.ID, event.ActorStaffID, event.Action, event.EntityType, event.EntityID,
		event.RequestID, event.IPAddressHash, event.UserAgentHash, jsonParam(event.BeforeJSON),
		jsonParam(event.AfterJSON), jsonParam(event.Metadata), event.CreatedAt)
	return err
}

func (r *PGAuditRepository) List(ctx context.Context, filter model.AuditFilter) ([]*model.AuditEvent, error) {
	parts := []string{`
		SELECT a.id, a.actor_staff_id, COALESCE(s.display_name, ''), COALESCE(s.email, ''),
		       a.action, a.entity_type, a.entity_id, a.request_id,
		       a.ip_address_hash, a.user_agent_hash, a.before_json, a.after_json,
		       a.metadata, a.created_at
		FROM audit_log a
		LEFT JOIN staff_users s ON s.id = a.actor_staff_id
		WHERE 1=1
	`}
	args := []any{}
	argPos := 1
	if filter.ActorStaffID != nil {
		parts = append(parts, fmt.Sprintf(" AND a.actor_staff_id = $%d", argPos))
		args = append(args, *filter.ActorStaffID)
		argPos++
	}
	if filter.EntityType != nil && strings.TrimSpace(*filter.EntityType) != "" {
		parts = append(parts, fmt.Sprintf(" AND a.entity_type = $%d", argPos))
		args = append(args, strings.TrimSpace(*filter.EntityType))
		argPos++
	}
	if filter.EntityID != nil {
		parts = append(parts, fmt.Sprintf(" AND a.entity_id = $%d", argPos))
		args = append(args, *filter.EntityID)
		argPos++
	}
	if filter.Action != nil && strings.TrimSpace(*filter.Action) != "" {
		parts = append(parts, fmt.Sprintf(" AND a.action = $%d", argPos))
		args = append(args, strings.TrimSpace(*filter.Action))
		argPos++
	}
	parts = append(parts, fmt.Sprintf(" ORDER BY a.created_at DESC LIMIT $%d OFFSET $%d", argPos, argPos+1))
	args = append(args, filter.Limit, filter.Offset)

	rows, err := r.pool.Query(ctx, strings.Join(parts, ""), args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var items []*model.AuditEvent
	for rows.Next() {
		var item model.AuditEvent
		if err = rows.Scan(
			&item.ID,
			&item.ActorStaffID,
			&item.ActorDisplayName,
			&item.ActorEmail,
			&item.Action,
			&item.EntityType,
			&item.EntityID,
			&item.RequestID,
			&item.IPAddressHash,
			&item.UserAgentHash,
			&item.BeforeJSON,
			&item.AfterJSON,
			&item.Metadata,
			&item.CreatedAt,
		); err != nil {
			return nil, err
		}
		items = append(items, &item)
	}
	return items, rows.Err()
}
