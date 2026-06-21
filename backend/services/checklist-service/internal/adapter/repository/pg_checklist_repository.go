package repository

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"kz/inflap/backend/services/checklist-service/internal/domain/model"
)

type PGChecklistRepository struct {
	pool             *pgxpool.Pool
	templates        []model.ChecklistTemplate
	seasonalProfiles []model.SeasonalProfile
	carryRules       []model.CarryRule
}

func NewPGChecklistRepository(pool *pgxpool.Pool, seeds ...model.CatalogSeed) *PGChecklistRepository {
	var seed model.CatalogSeed
	if len(seeds) > 0 {
		seed = seeds[0]
	}
	return &PGChecklistRepository{
		pool:             pool,
		templates:        append([]model.ChecklistTemplate(nil), seed.Templates...),
		seasonalProfiles: append([]model.SeasonalProfile(nil), seed.SeasonalProfiles...),
		carryRules:       append([]model.CarryRule(nil), seed.CarryRules...),
	}
}

func (r *PGChecklistRepository) Templates() []model.ChecklistTemplate {
	return append([]model.ChecklistTemplate(nil), r.templates...)
}

func (r *PGChecklistRepository) SeasonalProfiles() []model.SeasonalProfile {
	return append([]model.SeasonalProfile(nil), r.seasonalProfiles...)
}

func (r *PGChecklistRepository) CarryRules() []model.CarryRule {
	return append([]model.CarryRule(nil), r.carryRules...)
}

func (r *PGChecklistRepository) FindTripChecklistInstance(
	ctx context.Context,
	userID string,
	tripID string,
) (model.TripChecklist, bool, error) {
	const instanceQuery = `
		SELECT id, user_id, trip_id, COALESCE(destination, '{}'::jsonb),
		       COALESCE(start_at, generated_at), COALESCE(end_at, generated_at),
		       COALESCE(to_jsonb(transport_modes), '[]'::jsonb),
		       COALESCE(to_jsonb(activity_slugs), '[]'::jsonb),
		       COALESCE(has_children, false),
		       readiness, COALESCE(seasonal_profile, 'null'::jsonb),
		       trust_notice, generated_at, updated_at
		FROM checklist_instances
		WHERE user_id = $1 AND trip_id = $2
	`

	var checklist model.TripChecklist
	var readinessRaw []byte
	var seasonalRaw []byte
	var trustRaw []byte
	var destinationRaw []byte
	var transportModesRaw []byte
	var activitySlugsRaw []byte
	err := r.pool.QueryRow(ctx, instanceQuery, userID, tripID).Scan(
		&checklist.InstanceID,
		&checklist.UserID,
		&checklist.TripID,
		&destinationRaw,
		&checklist.StartAt,
		&checklist.EndAt,
		&transportModesRaw,
		&activitySlugsRaw,
		&checklist.TravelerProfile.HasChildren,
		&readinessRaw,
		&seasonalRaw,
		&trustRaw,
		&checklist.GeneratedAt,
		&checklist.UpdatedAt,
	)
	if errors.Is(err, pgx.ErrNoRows) {
		return model.TripChecklist{}, false, nil
	}
	if err != nil {
		return model.TripChecklist{}, false, fmt.Errorf("select checklist instance: %w", err)
	}
	if err = decodeJSON(destinationRaw, &checklist.Destination); err != nil {
		return model.TripChecklist{}, false, fmt.Errorf("decode checklist destination: %w", err)
	}
	if err = decodeJSON(transportModesRaw, &checklist.TransportModes); err != nil {
		return model.TripChecklist{}, false, fmt.Errorf("decode checklist transport modes: %w", err)
	}
	if err = decodeJSON(activitySlugsRaw, &checklist.ActivitySlugs); err != nil {
		return model.TripChecklist{}, false, fmt.Errorf("decode checklist activity slugs: %w", err)
	}
	if err = decodeJSON(readinessRaw, &checklist.Readiness); err != nil {
		return model.TripChecklist{}, false, fmt.Errorf("decode checklist readiness: %w", err)
	}
	if string(seasonalRaw) != "null" {
		var profile model.SeasonalProfile
		if err = decodeJSON(seasonalRaw, &profile); err != nil {
			return model.TripChecklist{}, false, fmt.Errorf("decode seasonal profile: %w", err)
		}
		checklist.SeasonalProfile = &profile
	}
	if err = decodeJSON(trustRaw, &checklist.TrustNotice); err != nil {
		return model.TripChecklist{}, false, fmt.Errorf("decode trust notice: %w", err)
	}

	items, err := r.listItems(ctx, checklist.InstanceID)
	if err != nil {
		return model.TripChecklist{}, false, err
	}
	checklist.Items = items

	return checklist, true, nil
}

func (r *PGChecklistRepository) SaveTripChecklistInstance(ctx context.Context, checklist model.TripChecklist) error {
	if checklist.InstanceID == "" {
		return fmt.Errorf("checklist instance id is required")
	}
	if checklist.UserID == "" {
		return fmt.Errorf("checklist user id is required")
	}
	if checklist.TripID == "" {
		return fmt.Errorf("checklist trip id is required")
	}

	readinessRaw, err := encodeJSON(checklist.Readiness)
	if err != nil {
		return fmt.Errorf("encode checklist readiness: %w", err)
	}
	destinationRaw, err := encodeJSON(checklist.Destination)
	if err != nil {
		return fmt.Errorf("encode checklist destination: %w", err)
	}
	seasonalRaw, err := encodeOptionalJSON(checklist.SeasonalProfile)
	if err != nil {
		return fmt.Errorf("encode seasonal profile: %w", err)
	}
	trustRaw, err := encodeJSON(checklist.TrustNotice)
	if err != nil {
		return fmt.Errorf("encode trust notice: %w", err)
	}
	transportModes := transportModeStrings(checklist.TransportModes)

	tx, err := r.pool.BeginTx(ctx, pgx.TxOptions{})
	if err != nil {
		return fmt.Errorf("begin checklist tx: %w", err)
	}
	defer func() {
		_ = tx.Rollback(ctx)
	}()

	const upsertInstance = `
		INSERT INTO checklist_instances (
			id, user_id, trip_id, destination, start_at, end_at,
			transport_modes, activity_slugs, has_children,
			readiness, seasonal_profile, trust_notice, generated_at, updated_at
		) VALUES (
			$1, $2, $3, $4, $5, $6,
			$7, $8, $9,
			$10, $11, $12, $13, $14
		)
		ON CONFLICT (user_id, trip_id) DO UPDATE
		SET
			destination = EXCLUDED.destination,
			start_at = EXCLUDED.start_at,
			end_at = EXCLUDED.end_at,
			transport_modes = EXCLUDED.transport_modes,
			activity_slugs = EXCLUDED.activity_slugs,
			has_children = EXCLUDED.has_children,
			readiness = EXCLUDED.readiness,
			seasonal_profile = EXCLUDED.seasonal_profile,
			trust_notice = EXCLUDED.trust_notice,
			updated_at = EXCLUDED.updated_at
		RETURNING id
	`
	var instanceID string
	if err = tx.QueryRow(
		ctx,
		upsertInstance,
		checklist.InstanceID,
		checklist.UserID,
		checklist.TripID,
		destinationRaw,
		checklist.StartAt,
		checklist.EndAt,
		transportModes,
		checklist.ActivitySlugs,
		checklist.TravelerProfile.HasChildren,
		readinessRaw,
		seasonalRaw,
		trustRaw,
		checklist.GeneratedAt,
		checklist.UpdatedAt,
	).Scan(&instanceID); err != nil {
		return fmt.Errorf("upsert checklist instance: %w", err)
	}

	if _, err = tx.Exec(ctx, `DELETE FROM checklist_instance_items WHERE instance_id = $1`, instanceID); err != nil {
		return fmt.Errorf("delete checklist items: %w", err)
	}

	for index, item := range checklist.Items {
		if err = insertChecklistItem(ctx, tx, instanceID, index, item); err != nil {
			return err
		}
	}

	if err = tx.Commit(ctx); err != nil {
		return fmt.Errorf("commit checklist tx: %w", err)
	}
	return nil
}

func (r *PGChecklistRepository) ListTripChecklistInstances(
	ctx context.Context,
	limit int,
) ([]model.TripChecklist, error) {
	if limit <= 0 {
		limit = 100
	}
	const query = `
		SELECT id, user_id, trip_id, COALESCE(destination, '{}'::jsonb),
		       COALESCE(start_at, generated_at), COALESCE(end_at, generated_at),
		       COALESCE(to_jsonb(transport_modes), '[]'::jsonb),
		       COALESCE(to_jsonb(activity_slugs), '[]'::jsonb),
		       COALESCE(has_children, false),
		       readiness, COALESCE(seasonal_profile, 'null'::jsonb),
		       trust_notice, generated_at, updated_at
		FROM checklist_instances
		ORDER BY COALESCE(start_at, generated_at) ASC, updated_at DESC, id ASC
		LIMIT $1
	`
	rows, err := r.pool.Query(ctx, query, limit)
	if err != nil {
		return nil, fmt.Errorf("select checklist instances: %w", err)
	}
	defer rows.Close()

	checklists := make([]model.TripChecklist, 0)
	for rows.Next() {
		var checklist model.TripChecklist
		var readinessRaw []byte
		var seasonalRaw []byte
		var trustRaw []byte
		var destinationRaw []byte
		var transportModesRaw []byte
		var activitySlugsRaw []byte
		if err = rows.Scan(
			&checklist.InstanceID,
			&checklist.UserID,
			&checklist.TripID,
			&destinationRaw,
			&checklist.StartAt,
			&checklist.EndAt,
			&transportModesRaw,
			&activitySlugsRaw,
			&checklist.TravelerProfile.HasChildren,
			&readinessRaw,
			&seasonalRaw,
			&trustRaw,
			&checklist.GeneratedAt,
			&checklist.UpdatedAt,
		); err != nil {
			return nil, fmt.Errorf("scan checklist instance: %w", err)
		}
		if err = decodeJSON(destinationRaw, &checklist.Destination); err != nil {
			return nil, fmt.Errorf("decode checklist destination: %w", err)
		}
		if err = decodeJSON(transportModesRaw, &checklist.TransportModes); err != nil {
			return nil, fmt.Errorf("decode checklist transport modes: %w", err)
		}
		if err = decodeJSON(activitySlugsRaw, &checklist.ActivitySlugs); err != nil {
			return nil, fmt.Errorf("decode checklist activity slugs: %w", err)
		}
		if err = decodeJSON(readinessRaw, &checklist.Readiness); err != nil {
			return nil, fmt.Errorf("decode checklist readiness: %w", err)
		}
		if string(seasonalRaw) != "null" {
			var profile model.SeasonalProfile
			if err = decodeJSON(seasonalRaw, &profile); err != nil {
				return nil, fmt.Errorf("decode seasonal profile: %w", err)
			}
			checklist.SeasonalProfile = &profile
		}
		if err = decodeJSON(trustRaw, &checklist.TrustNotice); err != nil {
			return nil, fmt.Errorf("decode trust notice: %w", err)
		}

		items, err := r.listItems(ctx, checklist.InstanceID)
		if err != nil {
			return nil, err
		}
		checklist.Items = items

		customItems, err := r.ListCustomChecklistItems(ctx, checklist.UserID, checklist.TripID)
		if err != nil {
			return nil, err
		}
		checklist.CustomItems = customItems

		checklists = append(checklists, checklist)
	}
	if err = rows.Err(); err != nil {
		return nil, fmt.Errorf("iterate checklist instances: %w", err)
	}
	return checklists, nil
}

func (r *PGChecklistRepository) ListTripChecklistInstancesByUser(
	ctx context.Context,
	userID string,
	limit int,
) ([]model.TripChecklist, error) {
	userID = strings.TrimSpace(userID)
	if limit <= 0 {
		limit = 50
	}
	const query = `
		SELECT id, user_id, trip_id, COALESCE(destination, '{}'::jsonb),
		       COALESCE(start_at, generated_at), COALESCE(end_at, generated_at),
		       COALESCE(to_jsonb(transport_modes), '[]'::jsonb),
		       COALESCE(to_jsonb(activity_slugs), '[]'::jsonb),
		       COALESCE(has_children, false),
		       readiness, COALESCE(seasonal_profile, 'null'::jsonb),
		       trust_notice, generated_at, updated_at
		FROM checklist_instances
		WHERE user_id = $1
		ORDER BY COALESCE(start_at, generated_at) ASC, updated_at DESC, id ASC
		LIMIT $2
	`
	rows, err := r.pool.Query(ctx, query, userID, limit)
	if err != nil {
		return nil, fmt.Errorf("select user checklist instances: %w", err)
	}
	defer rows.Close()

	checklists := make([]model.TripChecklist, 0)
	for rows.Next() {
		var checklist model.TripChecklist
		var readinessRaw []byte
		var seasonalRaw []byte
		var trustRaw []byte
		var destinationRaw []byte
		var transportModesRaw []byte
		var activitySlugsRaw []byte
		if err = rows.Scan(
			&checklist.InstanceID,
			&checklist.UserID,
			&checklist.TripID,
			&destinationRaw,
			&checklist.StartAt,
			&checklist.EndAt,
			&transportModesRaw,
			&activitySlugsRaw,
			&checklist.TravelerProfile.HasChildren,
			&readinessRaw,
			&seasonalRaw,
			&trustRaw,
			&checklist.GeneratedAt,
			&checklist.UpdatedAt,
		); err != nil {
			return nil, fmt.Errorf("scan user checklist instance: %w", err)
		}
		if err = decodeJSON(destinationRaw, &checklist.Destination); err != nil {
			return nil, fmt.Errorf("decode checklist destination: %w", err)
		}
		if err = decodeJSON(transportModesRaw, &checklist.TransportModes); err != nil {
			return nil, fmt.Errorf("decode checklist transport modes: %w", err)
		}
		if err = decodeJSON(activitySlugsRaw, &checklist.ActivitySlugs); err != nil {
			return nil, fmt.Errorf("decode checklist activity slugs: %w", err)
		}
		if err = decodeJSON(readinessRaw, &checklist.Readiness); err != nil {
			return nil, fmt.Errorf("decode checklist readiness: %w", err)
		}
		if string(seasonalRaw) != "null" {
			var profile model.SeasonalProfile
			if err = decodeJSON(seasonalRaw, &profile); err != nil {
				return nil, fmt.Errorf("decode seasonal profile: %w", err)
			}
			checklist.SeasonalProfile = &profile
		}
		if err = decodeJSON(trustRaw, &checklist.TrustNotice); err != nil {
			return nil, fmt.Errorf("decode trust notice: %w", err)
		}

		items, err := r.listItems(ctx, checklist.InstanceID)
		if err != nil {
			return nil, err
		}
		checklist.Items = items
		checklists = append(checklists, checklist)
	}
	if err = rows.Err(); err != nil {
		return nil, fmt.Errorf("iterate user checklist instances: %w", err)
	}
	return checklists, nil
}

func (r *PGChecklistRepository) SaveChecklistItemFeedback(
	ctx context.Context,
	feedback model.ChecklistItemFeedback,
) error {
	if feedback.ID == "" {
		return fmt.Errorf("feedback id is required")
	}
	if feedback.ChecklistInstanceID == "" {
		return fmt.Errorf("checklist instance id is required")
	}
	if feedback.UserID == "" {
		return fmt.Errorf("feedback user id is required")
	}
	if feedback.TripID == "" {
		return fmt.Errorf("feedback trip id is required")
	}
	if feedback.ItemID == "" {
		return fmt.Errorf("feedback item id is required")
	}

	const query = `
		INSERT INTO checklist_item_feedback (
			id, checklist_instance_id, user_id, trip_id, item_id, feedback_type, comment, created_at
		) VALUES (
			$1, $2, $3, $4, $5, $6, $7, $8
		)
	`
	if _, err := r.pool.Exec(
		ctx,
		query,
		feedback.ID,
		feedback.ChecklistInstanceID,
		feedback.UserID,
		feedback.TripID,
		feedback.ItemID,
		feedback.FeedbackType,
		feedback.Comment,
		feedback.CreatedAt,
	); err != nil {
		return fmt.Errorf("insert checklist item feedback: %w", err)
	}
	return nil
}

func (r *PGChecklistRepository) ListChecklistItemFeedback(
	ctx context.Context,
	feedbackType model.ChecklistFeedbackType,
	limit int,
) ([]model.ChecklistItemFeedback, error) {
	const query = `
		SELECT id, checklist_instance_id, user_id, trip_id, item_id, feedback_type, comment, created_at
		FROM checklist_item_feedback
		WHERE ($1 = '' OR feedback_type = $1)
		ORDER BY created_at DESC, id DESC
		LIMIT $2
	`
	rows, err := r.pool.Query(ctx, query, feedbackType, limit)
	if err != nil {
		return nil, fmt.Errorf("select checklist item feedback: %w", err)
	}
	defer rows.Close()

	items := make([]model.ChecklistItemFeedback, 0)
	for rows.Next() {
		var item model.ChecklistItemFeedback
		if err = rows.Scan(
			&item.ID,
			&item.ChecklistInstanceID,
			&item.UserID,
			&item.TripID,
			&item.ItemID,
			&item.FeedbackType,
			&item.Comment,
			&item.CreatedAt,
		); err != nil {
			return nil, fmt.Errorf("scan checklist item feedback: %w", err)
		}
		items = append(items, item)
	}
	if err = rows.Err(); err != nil {
		return nil, fmt.Errorf("iterate checklist item feedback: %w", err)
	}
	return items, nil
}

func (r *PGChecklistRepository) ListCustomChecklistItems(
	ctx context.Context,
	userID string,
	tripID string,
) ([]model.CustomChecklistItem, error) {
	const query = `
		SELECT id, checklist_instance_id, user_id, trip_id, title, note, category, priority,
		       status, COALESCE(assigned_user_id, ''), reuse_in_future,
		       COALESCE(personal_template_id, ''), created_at, updated_at, deleted_at
		FROM custom_checklist_items
		WHERE user_id = $1 AND trip_id = $2 AND deleted_at IS NULL
		ORDER BY updated_at DESC, id ASC
	`
	rows, err := r.pool.Query(ctx, query, userID, tripID)
	if err != nil {
		return nil, fmt.Errorf("select custom checklist items: %w", err)
	}
	defer rows.Close()

	items := make([]model.CustomChecklistItem, 0)
	for rows.Next() {
		item, scanErr := scanCustomChecklistItem(rows)
		if scanErr != nil {
			return nil, scanErr
		}
		items = append(items, item)
	}
	if err = rows.Err(); err != nil {
		return nil, fmt.Errorf("iterate custom checklist items: %w", err)
	}
	return items, nil
}

func (r *PGChecklistRepository) SaveCustomChecklistItem(
	ctx context.Context,
	item model.CustomChecklistItem,
) error {
	const query = `
		INSERT INTO custom_checklist_items (
			id, checklist_instance_id, user_id, trip_id, title, note, category, priority,
			status, assigned_user_id, reuse_in_future, personal_template_id,
			created_at, updated_at, deleted_at
		) VALUES (
			$1, $2, $3, $4, $5, $6, $7, $8,
			$9, $10, $11, $12,
			$13, $14, $15
		)
		ON CONFLICT (id) DO UPDATE
		SET
			checklist_instance_id = EXCLUDED.checklist_instance_id,
			title = EXCLUDED.title,
			note = EXCLUDED.note,
			category = EXCLUDED.category,
			priority = EXCLUDED.priority,
			status = EXCLUDED.status,
			assigned_user_id = EXCLUDED.assigned_user_id,
			reuse_in_future = EXCLUDED.reuse_in_future,
			personal_template_id = EXCLUDED.personal_template_id,
			updated_at = EXCLUDED.updated_at,
			deleted_at = EXCLUDED.deleted_at
		WHERE custom_checklist_items.user_id = EXCLUDED.user_id
		  AND custom_checklist_items.trip_id = EXCLUDED.trip_id
	`
	tag, err := r.pool.Exec(
		ctx,
		query,
		item.ID,
		item.ChecklistInstanceID,
		item.UserID,
		item.TripID,
		item.Title,
		item.Note,
		item.Category,
		item.Priority,
		item.Status,
		nullableString(item.AssignedUserID),
		item.ReuseInFuture,
		nullableString(item.PersonalTemplateID),
		item.CreatedAt,
		item.UpdatedAt,
		item.DeletedAt,
	)
	if err != nil {
		return fmt.Errorf("upsert custom checklist item: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return fmt.Errorf("custom checklist item owner mismatch")
	}
	return nil
}

func (r *PGChecklistRepository) SoftDeleteCustomChecklistItem(
	ctx context.Context,
	userID string,
	tripID string,
	itemID string,
	deletedAt time.Time,
) error {
	const query = `
		UPDATE custom_checklist_items
		SET deleted_at = $4, updated_at = $4
		WHERE user_id = $1 AND trip_id = $2 AND id = $3 AND deleted_at IS NULL
	`
	if _, err := r.pool.Exec(ctx, query, userID, tripID, itemID, deletedAt); err != nil {
		return fmt.Errorf("soft delete custom checklist item: %w", err)
	}
	return nil
}

func (r *PGChecklistRepository) FindCustomChecklistItem(
	ctx context.Context,
	userID string,
	tripID string,
	itemID string,
) (model.CustomChecklistItem, bool, error) {
	const query = `
		SELECT id, checklist_instance_id, user_id, trip_id, title, note, category, priority,
		       status, COALESCE(assigned_user_id, ''), reuse_in_future,
		       COALESCE(personal_template_id, ''), created_at, updated_at, deleted_at
		FROM custom_checklist_items
		WHERE user_id = $1 AND trip_id = $2 AND id = $3 AND deleted_at IS NULL
	`
	item, err := scanCustomChecklistItem(r.pool.QueryRow(ctx, query, userID, tripID, itemID))
	if errors.Is(err, pgx.ErrNoRows) {
		return model.CustomChecklistItem{}, false, nil
	}
	if err != nil {
		return model.CustomChecklistItem{}, false, err
	}
	return item, true, nil
}

func (r *PGChecklistRepository) SavePersonalChecklistTemplate(
	ctx context.Context,
	template model.PersonalChecklistTemplate,
) error {
	const query = `
		INSERT INTO personal_checklist_templates (
			id, user_id, title, note, category, priority, is_active, created_at, updated_at
		) VALUES (
			$1, $2, $3, $4, $5, $6, $7, $8, $9
		)
		ON CONFLICT (id) DO UPDATE
		SET
			title = EXCLUDED.title,
			note = EXCLUDED.note,
			category = EXCLUDED.category,
			priority = EXCLUDED.priority,
			is_active = EXCLUDED.is_active,
			updated_at = EXCLUDED.updated_at
		WHERE personal_checklist_templates.user_id = EXCLUDED.user_id
	`
	tag, err := r.pool.Exec(
		ctx,
		query,
		template.ID,
		template.UserID,
		template.Title,
		template.Note,
		template.Category,
		template.Priority,
		template.IsActive,
		template.CreatedAt,
		template.UpdatedAt,
	)
	if err != nil {
		return fmt.Errorf("upsert personal checklist template: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return fmt.Errorf("personal checklist template owner mismatch")
	}
	return nil
}

func (r *PGChecklistRepository) ListPersonalChecklistTemplates(
	ctx context.Context,
	userID string,
	activeOnly bool,
) ([]model.PersonalChecklistTemplate, error) {
	const query = `
		SELECT id, user_id, title, note, category, priority, is_active, created_at, updated_at
		FROM personal_checklist_templates
		WHERE user_id = $1 AND ($2 = false OR is_active = true)
		ORDER BY updated_at DESC, id ASC
	`
	rows, err := r.pool.Query(ctx, query, userID, activeOnly)
	if err != nil {
		return nil, fmt.Errorf("select personal checklist templates: %w", err)
	}
	defer rows.Close()

	templates := make([]model.PersonalChecklistTemplate, 0)
	for rows.Next() {
		var template model.PersonalChecklistTemplate
		if err = rows.Scan(
			&template.ID,
			&template.UserID,
			&template.Title,
			&template.Note,
			&template.Category,
			&template.Priority,
			&template.IsActive,
			&template.CreatedAt,
			&template.UpdatedAt,
		); err != nil {
			return nil, fmt.Errorf("scan personal checklist template: %w", err)
		}
		templates = append(templates, template)
	}
	if err = rows.Err(); err != nil {
		return nil, fmt.Errorf("iterate personal checklist templates: %w", err)
	}
	return templates, nil
}

func (r *PGChecklistRepository) listItems(ctx context.Context, instanceID string) ([]model.ChecklistItem, error) {
	const query = `
		SELECT item_id, category, priority, status, COALESCE(assigned_user_id, ''),
		       title, reason, trust_level, source,
		       requires_user_confirmation, deadline_at
		FROM checklist_instance_items
		WHERE instance_id = $1
		ORDER BY position ASC, item_id ASC
	`
	rows, err := r.pool.Query(ctx, query, instanceID)
	if err != nil {
		return nil, fmt.Errorf("select checklist items: %w", err)
	}
	defer rows.Close()

	items := make([]model.ChecklistItem, 0)
	for rows.Next() {
		var item model.ChecklistItem
		var titleRaw []byte
		var reasonRaw []byte
		var sourceRaw []byte
		if err = rows.Scan(
			&item.ID,
			&item.Category,
			&item.Priority,
			&item.Status,
			&item.AssignedUserID,
			&titleRaw,
			&reasonRaw,
			&item.TrustLevel,
			&sourceRaw,
			&item.RequiresUserConfirmation,
			&item.DeadlineAt,
		); err != nil {
			return nil, fmt.Errorf("scan checklist item: %w", err)
		}
		if err = decodeJSON(titleRaw, &item.Title); err != nil {
			return nil, fmt.Errorf("decode item title: %w", err)
		}
		if err = decodeJSON(reasonRaw, &item.Reason); err != nil {
			return nil, fmt.Errorf("decode item reason: %w", err)
		}
		if err = decodeJSON(sourceRaw, &item.Source); err != nil {
			return nil, fmt.Errorf("decode item source: %w", err)
		}
		items = append(items, item)
	}
	if err = rows.Err(); err != nil {
		return nil, fmt.Errorf("iterate checklist items: %w", err)
	}
	return items, nil
}

func insertChecklistItem(ctx context.Context, tx pgx.Tx, instanceID string, position int, item model.ChecklistItem) error {
	titleRaw, err := encodeJSON(item.Title)
	if err != nil {
		return fmt.Errorf("encode item title: %w", err)
	}
	reasonRaw, err := encodeJSON(item.Reason)
	if err != nil {
		return fmt.Errorf("encode item reason: %w", err)
	}
	sourceRaw, err := encodeJSON(item.Source)
	if err != nil {
		return fmt.Errorf("encode item source: %w", err)
	}

	const query = `
		INSERT INTO checklist_instance_items (
			instance_id, item_id, category, priority, status, assigned_user_id, title, reason, trust_level, source,
			requires_user_confirmation, deadline_at, position, created_at, updated_at
		) VALUES (
			$1, $2, $3, $4, $5, $6, $7, $8, $9, $10,
			$11, $12, $13, now(), now()
		)
	`
	if _, err = tx.Exec(
		ctx,
		query,
		instanceID,
		item.ID,
		item.Category,
		item.Priority,
		item.Status,
		item.AssignedUserID,
		titleRaw,
		reasonRaw,
		item.TrustLevel,
		sourceRaw,
		item.RequiresUserConfirmation,
		item.DeadlineAt,
		position,
	); err != nil {
		return fmt.Errorf("insert checklist item %q: %w", item.ID, err)
	}
	return nil
}

type rowScanner interface {
	Scan(dest ...any) error
}

func scanCustomChecklistItem(scanner rowScanner) (model.CustomChecklistItem, error) {
	var item model.CustomChecklistItem
	if err := scanner.Scan(
		&item.ID,
		&item.ChecklistInstanceID,
		&item.UserID,
		&item.TripID,
		&item.Title,
		&item.Note,
		&item.Category,
		&item.Priority,
		&item.Status,
		&item.AssignedUserID,
		&item.ReuseInFuture,
		&item.PersonalTemplateID,
		&item.CreatedAt,
		&item.UpdatedAt,
		&item.DeletedAt,
	); err != nil {
		return model.CustomChecklistItem{}, fmt.Errorf("scan custom checklist item: %w", err)
	}
	return item, nil
}

func nullableString(value string) any {
	if value == "" {
		return nil
	}
	return value
}

func encodeJSON(value any) ([]byte, error) {
	return json.Marshal(value)
}

func encodeOptionalJSON(value any) ([]byte, error) {
	if value == nil {
		return nil, nil
	}
	return json.Marshal(value)
}

func transportModeStrings(values []model.TransportMode) []string {
	result := make([]string, 0, len(values))
	for _, value := range values {
		normalized := strings.TrimSpace(string(value))
		if normalized == "" {
			continue
		}
		result = append(result, normalized)
	}
	return result
}

func decodeJSON(data []byte, target any) error {
	if len(data) == 0 {
		data = []byte("{}")
	}
	return json.Unmarshal(data, target)
}
