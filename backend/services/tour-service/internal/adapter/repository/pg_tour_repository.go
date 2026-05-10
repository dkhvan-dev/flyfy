package repository

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/dkhvan-dev/flyfy/backend/services/tour-service/internal/domain/enum"
	"github.com/dkhvan-dev/flyfy/backend/services/tour-service/internal/domain/model"
	"github.com/dkhvan-dev/flyfy/backend/services/tour-service/internal/domain/port"
)

type PGTourRepository struct {
	pool *pgxpool.Pool
}

func NewPGTourRepository(pool *pgxpool.Pool) *PGTourRepository {
	return &PGTourRepository{pool: pool}
}

const tourSelectColumns = `
	id, guide_profile_id, guide_user_id,
	landmark_id, landmark_name,
	title, summary, description, category_slug,
	status, visibility,
	duration_minutes, max_group_size,
	country_code, city_name, meeting_point, latitude, longitude, map_url,
	price_amount, currency,
	published_at, deleted_at, revision, created_at, updated_at
`

func (r *PGTourRepository) CreateTourAggregate(ctx context.Context, item *model.Tour, relations port.TourRelations) error {
	tx, err := r.pool.BeginTx(ctx, pgx.TxOptions{})
	if err != nil {
		return fmt.Errorf("begin create tour tx: %w", err)
	}
	defer func() {
		_ = tx.Rollback(ctx)
	}()

	if err = insertTour(ctx, tx, item); err != nil {
		return err
	}
	if err = replaceTourRelations(ctx, tx, item.ID, relations); err != nil {
		return err
	}
	if err = tx.Commit(ctx); err != nil {
		return fmt.Errorf("commit create tour tx: %w", err)
	}
	return nil
}

func (r *PGTourRepository) UpdateTourAggregate(ctx context.Context, item *model.Tour, relations port.TourRelations) error {
	tx, err := r.pool.BeginTx(ctx, pgx.TxOptions{})
	if err != nil {
		return fmt.Errorf("begin update tour tx: %w", err)
	}
	defer func() {
		_ = tx.Rollback(ctx)
	}()

	if err = updateTour(ctx, tx, item); err != nil {
		return err
	}
	if err = replaceTourRelations(ctx, tx, item.ID, relations); err != nil {
		return err
	}
	if err = tx.Commit(ctx); err != nil {
		return fmt.Errorf("commit update tour tx: %w", err)
	}
	return nil
}

func (r *PGTourRepository) UpdateTour(ctx context.Context, item *model.Tour) error {
	return updateTour(ctx, r.pool, item)
}

func (r *PGTourRepository) GetTourByID(ctx context.Context, tourID uuid.UUID) (*model.Tour, error) {
	query := `
		SELECT ` + tourSelectColumns + `
		FROM tours
		WHERE id = $1
		LIMIT 1
	`
	item, err := scanTour(r.pool.QueryRow(ctx, query, tourID))
	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, nil
		}
		return nil, fmt.Errorf("get tour by id: %w", err)
	}
	return item, nil
}

func (r *PGTourRepository) ListTours(ctx context.Context, filter port.TourFilter) ([]*model.Tour, error) {
	base := `
		SELECT ` + tourSelectColumns + `
		FROM tours
		WHERE deleted_at IS NULL
	`
	parts := []string{base}
	args := make([]any, 0, 12)
	argPos := 1

	if filter.GuideUserID != nil {
		parts = append(parts, fmt.Sprintf(" AND guide_user_id = $%d", argPos))
		args = append(args, *filter.GuideUserID)
		argPos++
	}
	if len(filter.Statuses) > 0 {
		parts = append(parts, fmt.Sprintf(" AND status = ANY($%d)", argPos))
		args = append(args, filter.Statuses)
		argPos++
	}
	if filter.Visibility != nil && strings.TrimSpace(*filter.Visibility) != "" {
		parts = append(parts, fmt.Sprintf(" AND visibility = $%d", argPos))
		args = append(args, strings.TrimSpace(*filter.Visibility))
		argPos++
	}
	if filter.CategorySlug != nil && strings.TrimSpace(*filter.CategorySlug) != "" {
		parts = append(parts, fmt.Sprintf(" AND category_slug = $%d", argPos))
		args = append(args, model.NormalizeSlug(*filter.CategorySlug))
		argPos++
	}
	if filter.CountryCode != nil && strings.TrimSpace(*filter.CountryCode) != "" {
		parts = append(parts, fmt.Sprintf(" AND country_code = $%d", argPos))
		args = append(args, strings.ToUpper(strings.TrimSpace(*filter.CountryCode)))
		argPos++
	}
	if filter.CityName != nil && strings.TrimSpace(*filter.CityName) != "" {
		parts = append(parts, fmt.Sprintf(" AND city_name ILIKE $%d", argPos))
		args = append(args, "%"+strings.TrimSpace(*filter.CityName)+"%")
		argPos++
	}
	if filter.LanguageCode != nil && strings.TrimSpace(*filter.LanguageCode) != "" {
		parts = append(parts, fmt.Sprintf(`
			AND EXISTS (
				SELECT 1 FROM tour_languages tl
				WHERE tl.tour_id = tours.id AND tl.language_code = $%d
			)
		`, argPos))
		args = append(args, strings.ToLower(strings.TrimSpace(*filter.LanguageCode)))
		argPos++
	}
	if filter.SearchQuery != nil && strings.TrimSpace(*filter.SearchQuery) != "" {
		parts = append(parts, fmt.Sprintf(" AND (title ILIKE $%d OR summary ILIKE $%d OR description ILIKE $%d)", argPos, argPos, argPos))
		args = append(args, "%"+strings.TrimSpace(*filter.SearchQuery)+"%")
		argPos++
	}
	if filter.PriceMin != nil {
		parts = append(parts, fmt.Sprintf(" AND price_amount >= $%d", argPos))
		args = append(args, *filter.PriceMin)
		argPos++
	}
	if filter.PriceMax != nil {
		parts = append(parts, fmt.Sprintf(" AND price_amount <= $%d", argPos))
		args = append(args, *filter.PriceMax)
		argPos++
	}
	if filter.DurationMin != nil {
		parts = append(parts, fmt.Sprintf(" AND duration_minutes >= $%d", argPos))
		args = append(args, *filter.DurationMin)
		argPos++
	}
	if filter.DurationMax != nil {
		parts = append(parts, fmt.Sprintf(" AND duration_minutes <= $%d", argPos))
		args = append(args, *filter.DurationMax)
		argPos++
	}
	if filter.MaxGroupSizeMin != nil {
		parts = append(parts, fmt.Sprintf(" AND max_group_size >= $%d", argPos))
		args = append(args, *filter.MaxGroupSizeMin)
		argPos++
	}

	if filter.Limit <= 0 {
		filter.Limit = 20
	}
	if filter.Offset < 0 {
		filter.Offset = 0
	}

	parts = append(parts, " ORDER BY published_at DESC NULLS LAST, created_at DESC")
	parts = append(parts, fmt.Sprintf(" LIMIT $%d OFFSET $%d", argPos, argPos+1))
	args = append(args, filter.Limit, filter.Offset)

	rows, err := r.pool.Query(ctx, strings.Join(parts, ""), args...)
	if err != nil {
		return nil, fmt.Errorf("list tours: %w", err)
	}
	defer rows.Close()

	items := make([]*model.Tour, 0)
	for rows.Next() {
		item, scanErr := scanTour(rows)
		if scanErr != nil {
			return nil, fmt.Errorf("scan listed tour: %w", scanErr)
		}
		items = append(items, item)
	}
	return items, rows.Err()
}

func (r *PGTourRepository) LoadTourRelations(ctx context.Context, tourID uuid.UUID) (port.TourRelations, error) {
	tags, err := r.listStrings(ctx, "tour_tags", "tag_slug", tourID)
	if err != nil {
		return port.TourRelations{}, err
	}
	languages, err := r.listStrings(ctx, "tour_languages", "language_code", tourID)
	if err != nil {
		return port.TourRelations{}, err
	}
	includedItems, err := r.listStrings(ctx, "tour_included_items", "item_text", tourID)
	if err != nil {
		return port.TourRelations{}, err
	}
	itinerary, err := r.listItinerary(ctx, tourID)
	if err != nil {
		return port.TourRelations{}, err
	}
	coverFileID, err := r.getCoverFileID(ctx, tourID)
	if err != nil {
		return port.TourRelations{}, err
	}
	return port.TourRelations{
		Tags:          tags,
		LanguageCodes: languages,
		IncludedItems: includedItems,
		Itinerary:     itinerary,
		CoverFileID:   coverFileID,
	}, nil
}

func (r *PGTourRepository) CreateTourEvent(ctx context.Context, item *model.TourEvent) error {
	const query = `
		INSERT INTO tour_events (id, tour_id, event_type, actor_user_id, payload, created_at)
		VALUES ($1, $2, $3, $4, $5::jsonb, $6)
	`
	_, err := r.pool.Exec(
		ctx,
		query,
		item.ID,
		item.TourID,
		string(item.EventType),
		item.ActorUserID,
		string(item.PayloadJSON),
		item.CreatedAt,
	)
	if err != nil {
		return fmt.Errorf("insert tour event: %w", err)
	}
	return nil
}

type dbExecutor interface {
	Exec(ctx context.Context, sql string, arguments ...any) (pgconn.CommandTag, error)
	QueryRow(ctx context.Context, sql string, args ...any) pgx.Row
}

func insertTour(ctx context.Context, exec dbExecutor, item *model.Tour) error {
	const query = `
		INSERT INTO tours (
			id, guide_profile_id, guide_user_id,
			landmark_id, landmark_name,
			title, summary, description, category_slug,
			status, visibility,
			duration_minutes, max_group_size,
			country_code, city_name, meeting_point, latitude, longitude, map_url,
			price_amount, currency,
			published_at, deleted_at, revision, created_at, updated_at
		) VALUES (
			$1, $2, $3,
			$4, $5,
			$6, $7, $8, $9,
			$10, $11,
			$12, $13,
			$14, $15, $16, $17, $18, $19,
			$20, $21,
			$22, $23, $24, $25, $26
		)
	`
	_, err := exec.Exec(ctx, query, tourArgs(item)...)
	if err != nil {
		return fmt.Errorf("insert tour: %w", err)
	}
	return nil
}

func updateTour(ctx context.Context, exec dbExecutor, item *model.Tour) error {
	const query = `
		UPDATE tours
		SET
			guide_profile_id = $2,
			guide_user_id = $3,
			landmark_id = $4,
			landmark_name = $5,
			title = $6,
			summary = $7,
			description = $8,
			category_slug = $9,
			status = $10,
			visibility = $11,
			duration_minutes = $12,
			max_group_size = $13,
			country_code = $14,
			city_name = $15,
			meeting_point = $16,
			latitude = $17,
			longitude = $18,
			map_url = $19,
			price_amount = $20,
			currency = $21,
			published_at = $22,
			deleted_at = $23,
			revision = $24,
			updated_at = $25
		WHERE id = $1
	`
	tag, err := exec.Exec(ctx, query, updateTourArgs(item)...)
	if err != nil {
		return fmt.Errorf("update tour: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return nil
	}
	return nil
}

func tourArgs(item *model.Tour) []any {
	return []any{
		item.ID,
		item.GuideProfileID,
		item.GuideUserID,
		item.LandmarkID,
		item.LandmarkName,
		item.Title,
		item.Summary,
		item.Description,
		item.CategorySlug,
		string(item.Status),
		string(item.Visibility),
		item.DurationMinutes,
		item.MaxGroupSize,
		item.CountryCode,
		item.CityName,
		item.MeetingPoint,
		item.Latitude,
		item.Longitude,
		item.MapURL,
		item.PriceAmount,
		item.Currency,
		item.PublishedAt,
		item.DeletedAt,
		item.Revision,
		item.CreatedAt,
		item.UpdatedAt,
	}
}

func updateTourArgs(item *model.Tour) []any {
	return []any{
		item.ID,
		item.GuideProfileID,
		item.GuideUserID,
		item.LandmarkID,
		item.LandmarkName,
		item.Title,
		item.Summary,
		item.Description,
		item.CategorySlug,
		string(item.Status),
		string(item.Visibility),
		item.DurationMinutes,
		item.MaxGroupSize,
		item.CountryCode,
		item.CityName,
		item.MeetingPoint,
		item.Latitude,
		item.Longitude,
		item.MapURL,
		item.PriceAmount,
		item.Currency,
		item.PublishedAt,
		item.DeletedAt,
		item.Revision,
		item.UpdatedAt,
	}
}

func replaceTourRelations(ctx context.Context, tx pgx.Tx, tourID uuid.UUID, relations port.TourRelations) error {
	if err := replaceStrings(ctx, tx, "tour_tags", "tag_slug", tourID, relations.Tags); err != nil {
		return err
	}
	if err := replaceStrings(ctx, tx, "tour_languages", "language_code", tourID, relations.LanguageCodes); err != nil {
		return err
	}
	if err := replaceStrings(ctx, tx, "tour_included_items", "item_text", tourID, relations.IncludedItems); err != nil {
		return err
	}
	if err := replaceItinerary(ctx, tx, tourID, relations.Itinerary); err != nil {
		return err
	}
	return replaceCover(ctx, tx, tourID, relations.CoverFileID)
}

func replaceStrings(ctx context.Context, tx pgx.Tx, table string, column string, tourID uuid.UUID, values []string) error {
	if _, err := tx.Exec(ctx, fmt.Sprintf("DELETE FROM %s WHERE tour_id = $1", table), tourID); err != nil {
		return fmt.Errorf("delete %s: %w", table, err)
	}
	for index, value := range values {
		value = strings.TrimSpace(value)
		if value == "" {
			continue
		}
		query := fmt.Sprintf(
			"INSERT INTO %s (id, tour_id, %s, sort_order, created_at) VALUES ($1, $2, $3, $4, $5)",
			table,
			column,
		)
		if _, err := tx.Exec(ctx, query, uuid.New(), tourID, value, index, time.Now().UTC()); err != nil {
			return fmt.Errorf("insert %s: %w", table, err)
		}
	}
	return nil
}

func replaceItinerary(ctx context.Context, tx pgx.Tx, tourID uuid.UUID, items []*model.TourItineraryItem) error {
	if _, err := tx.Exec(ctx, "DELETE FROM tour_itinerary_items WHERE tour_id = $1", tourID); err != nil {
		return fmt.Errorf("delete tour itinerary: %w", err)
	}
	for _, item := range items {
		const query = `
			INSERT INTO tour_itinerary_items (
				id, tour_id, sort_order, start_offset_minutes, duration_minutes,
				title, description, created_at, updated_at
			) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
		`
		if _, err := tx.Exec(
			ctx,
			query,
			item.ID,
			tourID,
			item.SortOrder,
			item.StartOffsetMinutes,
			item.DurationMinutes,
			item.Title,
			item.Description,
			item.CreatedAt,
			item.UpdatedAt,
		); err != nil {
			return fmt.Errorf("insert tour itinerary: %w", err)
		}
	}
	return nil
}

func replaceCover(ctx context.Context, tx pgx.Tx, tourID uuid.UUID, coverFileID *uuid.UUID) error {
	if _, err := tx.Exec(ctx, "DELETE FROM tour_covers WHERE tour_id = $1", tourID); err != nil {
		return fmt.Errorf("delete tour cover: %w", err)
	}
	if coverFileID == nil || *coverFileID == uuid.Nil {
		return nil
	}
	const query = `
		INSERT INTO tour_covers (id, tour_id, file_id, created_at)
		VALUES ($1, $2, $3, $4)
	`
	if _, err := tx.Exec(ctx, query, uuid.New(), tourID, *coverFileID, time.Now().UTC()); err != nil {
		return fmt.Errorf("insert tour cover: %w", err)
	}
	return nil
}

func (r *PGTourRepository) listStrings(ctx context.Context, table string, column string, tourID uuid.UUID) ([]string, error) {
	query := fmt.Sprintf("SELECT %s FROM %s WHERE tour_id = $1 ORDER BY sort_order ASC, created_at ASC", column, table)
	rows, err := r.pool.Query(ctx, query, tourID)
	if err != nil {
		return nil, fmt.Errorf("list %s: %w", table, err)
	}
	defer rows.Close()

	result := make([]string, 0)
	for rows.Next() {
		var value string
		if err = rows.Scan(&value); err != nil {
			return nil, fmt.Errorf("scan %s: %w", table, err)
		}
		result = append(result, value)
	}
	return result, rows.Err()
}

func (r *PGTourRepository) listItinerary(ctx context.Context, tourID uuid.UUID) ([]*model.TourItineraryItem, error) {
	const query = `
		SELECT id, tour_id, sort_order, start_offset_minutes, duration_minutes,
		       title, description, created_at, updated_at
		FROM tour_itinerary_items
		WHERE tour_id = $1
		ORDER BY sort_order ASC, start_offset_minutes ASC
	`
	rows, err := r.pool.Query(ctx, query, tourID)
	if err != nil {
		return nil, fmt.Errorf("list tour itinerary: %w", err)
	}
	defer rows.Close()

	result := make([]*model.TourItineraryItem, 0)
	for rows.Next() {
		item, scanErr := scanItineraryItem(rows)
		if scanErr != nil {
			return nil, fmt.Errorf("scan tour itinerary: %w", scanErr)
		}
		result = append(result, item)
	}
	return result, rows.Err()
}

func (r *PGTourRepository) getCoverFileID(ctx context.Context, tourID uuid.UUID) (*uuid.UUID, error) {
	const query = `
		SELECT file_id
		FROM tour_covers
		WHERE tour_id = $1
		LIMIT 1
	`
	var fileID uuid.UUID
	if err := r.pool.QueryRow(ctx, query, tourID).Scan(&fileID); err != nil {
		if err == pgx.ErrNoRows {
			return nil, nil
		}
		return nil, fmt.Errorf("get tour cover: %w", err)
	}
	return &fileID, nil
}

type tourScanner interface {
	Scan(dest ...any) error
}

func scanTour(row tourScanner) (*model.Tour, error) {
	var (
		item          model.Tour
		statusRaw     string
		visibilityRaw string
	)
	err := row.Scan(
		&item.ID,
		&item.GuideProfileID,
		&item.GuideUserID,
		&item.LandmarkID,
		&item.LandmarkName,
		&item.Title,
		&item.Summary,
		&item.Description,
		&item.CategorySlug,
		&statusRaw,
		&visibilityRaw,
		&item.DurationMinutes,
		&item.MaxGroupSize,
		&item.CountryCode,
		&item.CityName,
		&item.MeetingPoint,
		&item.Latitude,
		&item.Longitude,
		&item.MapURL,
		&item.PriceAmount,
		&item.Currency,
		&item.PublishedAt,
		&item.DeletedAt,
		&item.Revision,
		&item.CreatedAt,
		&item.UpdatedAt,
	)
	if err != nil {
		return nil, err
	}
	item.Status = enum.TourStatus(statusRaw)
	item.Visibility = enum.TourVisibility(visibilityRaw)
	return &item, nil
}

func scanItineraryItem(row tourScanner) (*model.TourItineraryItem, error) {
	var item model.TourItineraryItem
	if err := row.Scan(
		&item.ID,
		&item.TourID,
		&item.SortOrder,
		&item.StartOffsetMinutes,
		&item.DurationMinutes,
		&item.Title,
		&item.Description,
		&item.CreatedAt,
		&item.UpdatedAt,
	); err != nil {
		return nil, err
	}
	return &item, nil
}
