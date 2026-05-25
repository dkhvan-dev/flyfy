package repository

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"time"
	"unicode"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/dkhvan-dev/flyfy/backend/services/attraction-service/internal/domain/enum"
	"github.com/dkhvan-dev/flyfy/backend/services/attraction-service/internal/domain/model"
)

type PGAttractionRepository struct {
	pool *pgxpool.Pool
}

func NewPGAttractionRepository(pool *pgxpool.Pool) *PGAttractionRepository {
	return &PGAttractionRepository{pool: pool}
}

func normalizeDBLocale(raw string) string {
	raw = strings.ToLower(strings.TrimSpace(raw))
	if raw == "" {
		return "en"
	}
	raw = strings.ReplaceAll(raw, "_", "-")
	if idx := strings.Index(raw, "-"); idx > 0 {
		raw = raw[:idx]
	}
	switch raw {
	case "en", "ru", "kk":
		return raw
	default:
		return "en"
	}
}

func searchTextTokens(raw string) []string {
	raw = strings.ToLower(strings.TrimSpace(raw))
	if raw == "" {
		return nil
	}

	seen := make(map[string]struct{})
	tokens := make([]string, 0, 6)
	for _, token := range strings.FieldsFunc(raw, func(r rune) bool {
		return !unicode.IsLetter(r) && !unicode.IsDigit(r)
	}) {
		token = strings.TrimSpace(token)
		if token == "" {
			continue
		}
		if _, ok := seen[token]; ok {
			continue
		}
		seen[token] = struct{}{}
		tokens = append(tokens, token)
		if len(tokens) == 6 {
			break
		}
	}
	return tokens
}

func escapePostgresLikePattern(value string) string {
	var b strings.Builder
	b.Grow(len(value))
	for _, r := range value {
		switch r {
		case '\\', '%', '_':
			b.WriteRune('\\')
		}
		b.WriteRune(r)
	}
	return b.String()
}

// ---------------------------------------------------------------------------
// Attractions CRUD
// ---------------------------------------------------------------------------

func (r *PGAttractionRepository) CreateAttraction(ctx context.Context, attraction *model.Attraction) error {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return fmt.Errorf("begin tx: %w", err)
	}
	defer tx.Rollback(ctx)

	const query = `
		INSERT INTO attractions (
			id, author_user_id, default_locale,
			country_code, city_id, latitude, longitude, location_source_url, category,
			price_amount, price_currency,
			duration_value, duration_unit,
			rating, review_count, spots, source, status, tags, visit_info,
			created_at, updated_at
		) VALUES (
			$1, $2, $3,
			$4, $5, $6, $7, $8, $9,
			$10, $11,
			$12, $13,
			$14, $15, $16, $17, $18, $19, $20,
			$21, $22
		)
	`

	var durationUnit *string
	if attraction.DurationUnit != nil {
		s := string(*attraction.DurationUnit)
		durationUnit = &s
	}
	visitInfoJSON, err := marshalVisitInfo(attraction.VisitInfo)
	if err != nil {
		return err
	}

	if _, err = tx.Exec(ctx, query,
		attraction.ID,
		attraction.AuthorUserID,
		normalizeDBLocale(attraction.DefaultLocale),
		attraction.CountryCode,
		attraction.CityID,
		attraction.Latitude,
		attraction.Longitude,
		attraction.LocationSourceURL,
		string(attraction.Category),
		attraction.PriceAmount,
		attraction.PriceCurrency,
		attraction.DurationValue,
		durationUnit,
		attraction.Rating,
		attraction.ReviewCount,
		attraction.Spots,
		string(attraction.Source),
		string(attraction.Status),
		attraction.Tags,
		visitInfoJSON,
		attraction.CreatedAt,
		attraction.UpdatedAt,
	); err != nil {
		err = classifyPGError(err)
		if errors.Is(err, ErrUniqueViolation) {
			return ErrConflict
		}
		return fmt.Errorf("insert attraction: %w", err)
	}

	if err = upsertAttractionTranslations(ctx, tx, attraction); err != nil {
		return err
	}
	if err = replaceAttractionCityLinks(ctx, tx, attraction.ID, attraction.AccessCities, attraction.DepartureCities); err != nil {
		return err
	}

	if len(attraction.Media) > 0 {
		if err = insertAttractionMedia(ctx, tx, attraction.ID, attraction.Media); err != nil {
			return err
		}
	}

	if err = tx.Commit(ctx); err != nil {
		return fmt.Errorf("commit attraction create tx: %w", err)
	}
	return nil
}

func (r *PGAttractionRepository) UpdateAttraction(ctx context.Context, attraction *model.Attraction) error {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return fmt.Errorf("begin update tx: %w", err)
	}
	defer tx.Rollback(ctx)

	const query = `
		UPDATE attractions
		SET
			default_locale = $2,
			country_code = $3,
			city_id = $4,
			latitude = $5,
			longitude = $6,
			location_source_url = $7,
			category = $8,
			price_amount = $9,
			price_currency = $10,
			duration_value = $11,
			duration_unit = $12,
			spots = $13,
			status = $14,
			tags = $15,
			visit_info = $16,
			updated_at = $17
		WHERE id = $1 AND deleted_at IS NULL
	`

	var durationUnit *string
	if attraction.DurationUnit != nil {
		s := string(*attraction.DurationUnit)
		durationUnit = &s
	}
	visitInfoJSON, err := marshalVisitInfo(attraction.VisitInfo)
	if err != nil {
		return err
	}

	tag, err := tx.Exec(ctx, query,
		attraction.ID,
		normalizeDBLocale(attraction.DefaultLocale),
		attraction.CountryCode,
		attraction.CityID,
		attraction.Latitude,
		attraction.Longitude,
		attraction.LocationSourceURL,
		string(attraction.Category),
		attraction.PriceAmount,
		attraction.PriceCurrency,
		attraction.DurationValue,
		durationUnit,
		attraction.Spots,
		string(attraction.Status),
		attraction.Tags,
		visitInfoJSON,
		attraction.UpdatedAt,
	)
	if err != nil {
		err = classifyPGError(err)
		if errors.Is(err, ErrUniqueViolation) {
			return ErrConflict
		}
		return fmt.Errorf("update attraction: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return ErrNotFound
	}

	if err = upsertAttractionTranslations(ctx, tx, attraction); err != nil {
		return err
	}
	if err = replaceAttractionCityLinks(ctx, tx, attraction.ID, attraction.AccessCities, attraction.DepartureCities); err != nil {
		return err
	}

	if err = tx.Commit(ctx); err != nil {
		return fmt.Errorf("commit attraction update tx: %w", err)
	}
	return nil
}

func (r *PGAttractionRepository) SoftDeleteAttraction(ctx context.Context, attractionID uuid.UUID) error {
	const query = `
		UPDATE attractions
		SET deleted_at = NOW(), updated_at = NOW()
		WHERE id = $1 AND deleted_at IS NULL
	`
	tag, err := r.pool.Exec(ctx, query, attractionID)
	if err != nil {
		return fmt.Errorf("soft delete attraction: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return ErrNotFound
	}
	return nil
}

func (r *PGAttractionRepository) RecoverAttraction(ctx context.Context, attractionID uuid.UUID) error {
	const query = `
		UPDATE attractions
		SET deleted_at = NULL, updated_at = NOW()
		WHERE id = $1 AND deleted_at IS NOT NULL
	`
	tag, err := r.pool.Exec(ctx, query, attractionID)
	if err != nil {
		return fmt.Errorf("recover attraction: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return ErrNotFound
	}
	return nil
}

func (r *PGAttractionRepository) GetAttractionByID(ctx context.Context, id uuid.UUID, locale string) (*model.Attraction, error) {
	const query = `
		SELECT
			a.id, a.author_user_id, a.default_locale,
			COALESCE(requested.title, fallback.title, '') AS title,
			COALESCE(requested.description, fallback.description, '') AS description,
			COALESCE(requested.locale, fallback.locale, a.default_locale) AS locale,
			a.country_code, a.city_id, a.latitude, a.longitude, a.location_source_url, a.category,
			a.price_amount, a.price_currency,
			a.duration_value, a.duration_unit,
			a.rating, a.review_count, a.spots, a.source, a.status, a.tags, a.visit_info,
			a.created_at, a.updated_at, a.deleted_at
		FROM attractions a
		LEFT JOIN attraction_translations requested
			ON requested.attraction_id = a.id AND requested.locale = $2
		LEFT JOIN attraction_translations fallback
			ON fallback.attraction_id = a.id AND fallback.locale = a.default_locale
		WHERE a.id = $1
		LIMIT 1
	`
	row := r.pool.QueryRow(ctx, query, id, normalizeDBLocale(locale))
	item, err := scanAttraction(row)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, fmt.Errorf("select attraction by id: %w", err)
	}

	media, err := r.getAttractionMedia(ctx, id)
	if err != nil {
		return nil, err
	}
	item.Media = media

	translations, err := r.getAttractionTranslations(ctx, id)
	if err != nil {
		return nil, err
	}
	item.Translations = translations

	if err = r.loadAttractionCityLinks(ctx, item); err != nil {
		return nil, err
	}

	return item, nil
}

func (r *PGAttractionRepository) ListAttractions(ctx context.Context, filter model.AttractionListFilter) ([]*model.Attraction, int, error) {
	args := make([]any, 0, 16)
	clauses := []string{"1=1"}

	if !filter.IncludeDeleted {
		clauses = append(clauses, "a.deleted_at IS NULL")
	}

	if filter.Category != "" {
		args = append(args, filter.Category)
		clauses = append(clauses, fmt.Sprintf("a.category = $%d", len(args)))
	}
	if filter.CountryCode != "" {
		args = append(args, strings.ToUpper(strings.TrimSpace(filter.CountryCode)))
		clauses = append(clauses, fmt.Sprintf("a.country_code = $%d", len(args)))
	}
	if filter.CityID != "" {
		args = append(args, filter.CityID)
		clauses = append(clauses, fmt.Sprintf("a.city_id = $%d", len(args)))
	}
	if filter.RegionID != "" {
		args = append(args, strings.ToLower(strings.TrimSpace(filter.RegionID)))
		clauses = append(clauses, fmt.Sprintf("a.tags @> ARRAY[$%d]::text[]", len(args)))
	}
	if filter.AccessCityID != "" {
		args = append(args, filter.AccessCityID)
		clauses = append(clauses, fmt.Sprintf(`EXISTS (
			SELECT 1 FROM attraction_city_links acl
			WHERE acl.attraction_id = a.id AND acl.kind = 'ACCESS' AND acl.city_id = $%d
		)`, len(args)))
	}
	if filter.DepartureCityID != "" {
		args = append(args, filter.DepartureCityID)
		clauses = append(clauses, fmt.Sprintf(`EXISTS (
			SELECT 1 FROM attraction_city_links dcl
			WHERE dcl.attraction_id = a.id AND dcl.kind = 'DEPARTURE' AND dcl.city_id = $%d
		)`, len(args)))
	}
	if filter.PriceMin != nil {
		args = append(args, *filter.PriceMin)
		clauses = append(clauses, fmt.Sprintf("a.price_amount >= $%d", len(args)))
	}
	if filter.PriceMax != nil {
		args = append(args, *filter.PriceMax)
		clauses = append(clauses, fmt.Sprintf("a.price_amount <= $%d", len(args)))
	}
	if filter.DurationMin != nil {
		args = append(args, *filter.DurationMin)
		clauses = append(clauses, fmt.Sprintf("a.duration_value >= $%d", len(args)))
	}
	if filter.DurationMax != nil {
		args = append(args, *filter.DurationMax)
		clauses = append(clauses, fmt.Sprintf("a.duration_value <= $%d", len(args)))
	}
	if filter.DurationUnit != nil {
		args = append(args, string(*filter.DurationUnit))
		clauses = append(clauses, fmt.Sprintf("a.duration_unit = $%d", len(args)))
	}
	if filter.SpotsMin != nil {
		args = append(args, *filter.SpotsMin)
		clauses = append(clauses, fmt.Sprintf("a.spots >= $%d", len(args)))
	}
	if filter.MinRating != nil {
		args = append(args, *filter.MinRating)
		clauses = append(clauses, fmt.Sprintf("a.rating >= $%d", len(args)))
	}
	if filter.AuthorUserID != nil && *filter.AuthorUserID != uuid.Nil {
		args = append(args, *filter.AuthorUserID)
		clauses = append(clauses, fmt.Sprintf("a.author_user_id = $%d", len(args)))
	}
	if strings.TrimSpace(filter.Search) != "" {
		term := strings.TrimSpace(filter.Search)
		args = append(args, term)
		fullTextArg := len(args)

		tokenClauses := make([]string, 0)
		for _, token := range searchTextTokens(term) {
			args = append(args, "%"+escapePostgresLikePattern(token)+"%")
			likeArg := len(args)
			tokenClauses = append(tokenClauses, fmt.Sprintf(`(
				EXISTS (
					SELECT 1
					FROM attraction_translations partial_translation
					WHERE partial_translation.attraction_id = a.id
						AND (
							partial_translation.title ILIKE $%d ESCAPE '\'
							OR partial_translation.description ILIKE $%d ESCAPE '\'
						)
				)
				OR EXISTS (
					SELECT 1
					FROM unnest(a.tags) AS search_tag
					WHERE search_tag ILIKE $%d ESCAPE '\'
				)
			)`, likeArg, likeArg, likeArg))
		}

		searchClause := fmt.Sprintf(`EXISTS (
			SELECT 1
			FROM attraction_translations search_translation
			WHERE search_translation.attraction_id = a.id
				AND COALESCE(search_translation.search_vector, ''::tsvector) @@ websearch_to_tsquery('simple', $%d)
		)`, fullTextArg)
		if len(tokenClauses) > 0 {
			searchClause = fmt.Sprintf(`(%s OR (%s))`, searchClause, strings.Join(tokenClauses, " AND "))
		}
		clauses = append(clauses, searchClause)
	}

	where := strings.Join(clauses, " AND ")

	// Count query
	countQuery := fmt.Sprintf(`SELECT COUNT(*) FROM attractions a WHERE %s`, where)
	var total int
	if err := r.pool.QueryRow(ctx, countQuery, args...).Scan(&total); err != nil {
		return nil, 0, fmt.Errorf("count attractions: %w", err)
	}

	// Order
	orderBy := attractionListOrderBy(filter.Sort)

	// Pagination
	if filter.Limit <= 0 {
		filter.Limit = 20
	}
	if filter.Offset < 0 {
		filter.Offset = 0
	}

	selectArgs := append([]any{}, args...)
	selectArgs = append(selectArgs, normalizeDBLocale(filter.Locale))
	localePos := len(selectArgs)
	selectArgs = append(selectArgs, filter.Limit, filter.Offset)
	limitPos := len(selectArgs) - 1
	offsetPos := len(selectArgs)

	query := fmt.Sprintf(`
		SELECT
			a.id, a.author_user_id, a.default_locale,
			COALESCE(requested.title, fallback.title, '') AS title,
			COALESCE(requested.description, fallback.description, '') AS description,
			COALESCE(requested.locale, fallback.locale, a.default_locale) AS locale,
			a.country_code, a.city_id, a.latitude, a.longitude, a.location_source_url, a.category,
			a.price_amount, a.price_currency,
			a.duration_value, a.duration_unit,
			a.rating, a.review_count, a.spots, a.source, a.status, a.tags, a.visit_info,
			a.created_at, a.updated_at, a.deleted_at
		FROM attractions a
		LEFT JOIN attraction_translations requested
			ON requested.attraction_id = a.id AND requested.locale = $%d
		LEFT JOIN attraction_translations fallback
			ON fallback.attraction_id = a.id AND fallback.locale = a.default_locale
		WHERE %s
		ORDER BY %s
		LIMIT $%d OFFSET $%d
	`, localePos, where, orderBy, limitPos, offsetPos)

	rows, err := r.pool.Query(ctx, query, selectArgs...)
	if err != nil {
		return nil, 0, fmt.Errorf("query attractions: %w", err)
	}
	defer rows.Close()

	items := make([]*model.Attraction, 0)
	for rows.Next() {
		item, scanErr := scanAttraction(rows)
		if scanErr != nil {
			return nil, 0, fmt.Errorf("scan attraction list: %w", scanErr)
		}
		items = append(items, item)
	}
	if err = rows.Err(); err != nil {
		return nil, 0, fmt.Errorf("rows iteration: %w", err)
	}

	// Load media for each attraction
	for _, item := range items {
		media, mErr := r.getAttractionMedia(ctx, item.ID)
		if mErr != nil {
			return nil, 0, mErr
		}
		item.Media = media

		translations, tErr := r.getAttractionTranslations(ctx, item.ID)
		if tErr != nil {
			return nil, 0, tErr
		}
		item.Translations = translations
		if linkErr := r.loadAttractionCityLinks(ctx, item); linkErr != nil {
			return nil, 0, linkErr
		}
	}

	return items, total, nil
}

func attractionListOrderBy(sort string) string {
	const durationInHours = "CASE WHEN a.duration_unit = 'DAYS' THEN a.duration_value * 24 ELSE a.duration_value END"

	switch sort {
	case "price_asc":
		return "a.price_amount ASC NULLS LAST, a.created_at DESC"
	case "price_desc":
		return "a.price_amount DESC NULLS LAST, a.created_at DESC"
	case "duration_asc":
		return durationInHours + " ASC NULLS LAST, a.created_at DESC"
	case "duration_desc":
		return durationInHours + " DESC NULLS LAST, a.created_at DESC"
	case "rating", "rating_desc":
		return "a.rating DESC, a.review_count DESC, a.created_at DESC"
	case "rating_asc":
		return "a.rating ASC, a.review_count DESC, a.created_at DESC"
	case "latest":
		return "a.created_at DESC"
	default:
		return "a.created_at DESC"
	}
}

// ---------------------------------------------------------------------------
// Media
// ---------------------------------------------------------------------------

func (r *PGAttractionRepository) ReplaceAttractionMedia(ctx context.Context, attractionID uuid.UUID, media []model.AttractionMedia) error {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return fmt.Errorf("begin media tx: %w", err)
	}
	defer tx.Rollback(ctx)

	if _, err = tx.Exec(ctx, `DELETE FROM attraction_media WHERE attraction_id = $1`, attractionID); err != nil {
		return fmt.Errorf("delete old attraction media: %w", err)
	}

	if len(media) > 0 {
		if err = insertAttractionMedia(ctx, tx, attractionID, media); err != nil {
			return err
		}
	}

	if err = tx.Commit(ctx); err != nil {
		return fmt.Errorf("commit media replace tx: %w", err)
	}
	return nil
}

func (r *PGAttractionRepository) getAttractionMedia(ctx context.Context, attractionID uuid.UUID) ([]model.AttractionMedia, error) {
	const query = `
		SELECT id, attraction_id, file_id, external_url, source_url, credit, license, media_type, position, created_at
		FROM attraction_media
		WHERE attraction_id = $1
		ORDER BY position
	`
	rows, err := r.pool.Query(ctx, query, attractionID)
	if err != nil {
		return nil, fmt.Errorf("query attraction media: %w", err)
	}
	defer rows.Close()

	items := make([]model.AttractionMedia, 0)
	for rows.Next() {
		var m model.AttractionMedia
		var mediaTypeRaw string
		if err = rows.Scan(
			&m.ID,
			&m.AttractionID,
			&m.FileID,
			&m.ExternalURL,
			&m.SourceURL,
			&m.Credit,
			&m.License,
			&mediaTypeRaw,
			&m.Position,
			&m.CreatedAt,
		); err != nil {
			return nil, fmt.Errorf("scan attraction media: %w", err)
		}
		m.MediaType = enum.MediaType(mediaTypeRaw)
		items = append(items, m)
	}
	return items, rows.Err()
}

func (r *PGAttractionRepository) getAttractionTranslations(ctx context.Context, attractionID uuid.UUID) (map[string]model.AttractionTranslation, error) {
	const query = `
		SELECT attraction_id, locale, title, description, created_at, updated_at
		FROM attraction_translations
		WHERE attraction_id = $1
		ORDER BY locale
	`
	rows, err := r.pool.Query(ctx, query, attractionID)
	if err != nil {
		return nil, fmt.Errorf("query attraction translations: %w", err)
	}
	defer rows.Close()

	items := make(map[string]model.AttractionTranslation)
	for rows.Next() {
		var translation model.AttractionTranslation
		if err = rows.Scan(
			&translation.AttractionID,
			&translation.Locale,
			&translation.Title,
			&translation.Description,
			&translation.CreatedAt,
			&translation.UpdatedAt,
		); err != nil {
			return nil, fmt.Errorf("scan attraction translation: %w", err)
		}
		items[translation.Locale] = translation
	}
	return items, rows.Err()
}

func upsertAttractionTranslations(ctx context.Context, tx pgx.Tx, attraction *model.Attraction) error {
	translations := attraction.Translations
	if len(translations) == 0 && strings.TrimSpace(attraction.Title) != "" {
		locale := normalizeDBLocale(attraction.DefaultLocale)
		translations = map[string]model.AttractionTranslation{
			locale: {
				Locale:      locale,
				Title:       strings.TrimSpace(attraction.Title),
				Description: strings.TrimSpace(attraction.Description),
			},
		}
	}

	if len(translations) == 0 {
		return nil
	}

	const query = `
		INSERT INTO attraction_translations (
			attraction_id, locale, title, description, created_at, updated_at
		) VALUES (
			$1, $2, $3, $4, $5, $6
		)
		ON CONFLICT (attraction_id, locale) DO UPDATE
		SET
			title = EXCLUDED.title,
			description = EXCLUDED.description,
			updated_at = EXCLUDED.updated_at
	`
	for rawLocale, translation := range translations {
		locale := normalizeDBLocale(translation.Locale)
		if locale == "" {
			locale = normalizeDBLocale(rawLocale)
		}
		if locale == "" {
			continue
		}

		createdAt := translation.CreatedAt
		if createdAt.IsZero() {
			createdAt = attraction.CreatedAt
		}
		if createdAt.IsZero() {
			createdAt = attraction.UpdatedAt
		}
		updatedAt := translation.UpdatedAt
		if updatedAt.IsZero() {
			updatedAt = attraction.UpdatedAt
		}
		if updatedAt.IsZero() {
			updatedAt = time.Now().UTC()
		}
		if createdAt.IsZero() {
			createdAt = updatedAt
		}

		if _, err := tx.Exec(
			ctx,
			query,
			attraction.ID,
			locale,
			strings.TrimSpace(translation.Title),
			strings.TrimSpace(translation.Description),
			createdAt,
			updatedAt,
		); err != nil {
			err = classifyPGError(err)
			if errors.Is(err, ErrUniqueViolation) {
				return ErrConflict
			}
			return fmt.Errorf("upsert attraction translation: %w", err)
		}
	}
	return nil
}

func replaceAttractionCityLinks(
	ctx context.Context,
	tx pgx.Tx,
	attractionID uuid.UUID,
	accessCities []model.AttractionCityLink,
	departureCities []model.AttractionCityLink,
) error {
	if _, err := tx.Exec(ctx, `DELETE FROM attraction_city_links WHERE attraction_id = $1`, attractionID); err != nil {
		return fmt.Errorf("delete attraction city links: %w", err)
	}
	if err := insertAttractionCityLinks(ctx, tx, attractionID, "ACCESS", accessCities); err != nil {
		return err
	}
	return insertAttractionCityLinks(ctx, tx, attractionID, "DEPARTURE", departureCities)
}

func insertAttractionCityLinks(
	ctx context.Context,
	tx pgx.Tx,
	attractionID uuid.UUID,
	kind string,
	items []model.AttractionCityLink,
) error {
	const query = `
		INSERT INTO attraction_city_links (
			id, attraction_id, kind, country_code, city_id, position, created_at
		) VALUES (
			$1, $2, $3, $4, $5, $6, $7
		)
		ON CONFLICT (attraction_id, kind, city_id) DO UPDATE
		SET country_code = EXCLUDED.country_code,
			position = EXCLUDED.position
	`
	for index, item := range items {
		createdAt := item.CreatedAt
		if createdAt.IsZero() {
			createdAt = time.Now().UTC()
		}
		position := item.Position
		if position < 0 {
			position = index
		}
		if _, err := tx.Exec(
			ctx,
			query,
			uuid.New(),
			attractionID,
			kind,
			strings.ToUpper(strings.TrimSpace(item.CountryCode)),
			strings.ToLower(strings.TrimSpace(item.CityID)),
			position,
			createdAt,
		); err != nil {
			return fmt.Errorf("insert attraction city link: %w", err)
		}
	}
	return nil
}

func (r *PGAttractionRepository) loadAttractionCityLinks(ctx context.Context, attraction *model.Attraction) error {
	if attraction == nil {
		return nil
	}
	const query = `
		SELECT attraction_id, kind, country_code, city_id, position, created_at
		FROM attraction_city_links
		WHERE attraction_id = $1
		ORDER BY kind, position, city_id
	`
	rows, err := r.pool.Query(ctx, query, attraction.ID)
	if err != nil {
		return fmt.Errorf("query attraction city links: %w", err)
	}
	defer rows.Close()

	attraction.AccessCities = nil
	attraction.DepartureCities = nil
	for rows.Next() {
		var item model.AttractionCityLink
		if err = rows.Scan(
			&item.AttractionID,
			&item.Kind,
			&item.CountryCode,
			&item.CityID,
			&item.Position,
			&item.CreatedAt,
		); err != nil {
			return fmt.Errorf("scan attraction city link: %w", err)
		}
		switch item.Kind {
		case "ACCESS":
			attraction.AccessCities = append(attraction.AccessCities, item)
		case "DEPARTURE":
			attraction.DepartureCities = append(attraction.DepartureCities, item)
		}
	}
	return rows.Err()
}

func insertAttractionMedia(ctx context.Context, tx pgx.Tx, attractionID uuid.UUID, media []model.AttractionMedia) error {
	for _, m := range media {
		const q = `
			INSERT INTO attraction_media (
				id, attraction_id, file_id, external_url, source_url, credit, license, media_type, position, created_at
			)
			VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
		`
		if _, err := tx.Exec(
			ctx,
			q,
			m.ID,
			attractionID,
			m.FileID,
			strings.TrimSpace(m.ExternalURL),
			strings.TrimSpace(m.SourceURL),
			strings.TrimSpace(m.Credit),
			strings.TrimSpace(m.License),
			string(m.MediaType),
			m.Position,
			m.CreatedAt,
		); err != nil {
			return fmt.Errorf("insert attraction media: %w", err)
		}
	}
	return nil
}

func marshalVisitInfo(visitInfo model.AttractionVisitInfo) ([]byte, error) {
	payload, err := json.Marshal(visitInfo)
	if err != nil {
		return nil, fmt.Errorf("marshal attraction visit info: %w", err)
	}
	return payload, nil
}

func unmarshalVisitInfo(payload []byte) (model.AttractionVisitInfo, error) {
	var visitInfo model.AttractionVisitInfo
	if len(payload) == 0 {
		return visitInfo, nil
	}
	if err := json.Unmarshal(payload, &visitInfo); err != nil {
		return model.AttractionVisitInfo{}, fmt.Errorf("unmarshal attraction visit info: %w", err)
	}
	return visitInfo, nil
}

// ---------------------------------------------------------------------------
// Tags
// ---------------------------------------------------------------------------

func (r *PGAttractionRepository) ReplaceTags(ctx context.Context, attractionID uuid.UUID, tags []string) error {
	const query = `
		UPDATE attractions SET tags = $2, updated_at = NOW()
		WHERE id = $1 AND deleted_at IS NULL
	`
	tag, err := r.pool.Exec(ctx, query, attractionID, tags)
	if err != nil {
		return fmt.Errorf("replace tags: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return ErrNotFound
	}
	return nil
}

// ---------------------------------------------------------------------------
// Reviews
// ---------------------------------------------------------------------------

func (r *PGAttractionRepository) CreateReview(ctx context.Context, review *model.AttractionReview) error {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return fmt.Errorf("begin review tx: %w", err)
	}
	defer tx.Rollback(ctx)

	const query = `
		INSERT INTO attraction_reviews (id, attraction_id, author_user_id, rating, comment, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
	`
	if _, err = tx.Exec(ctx, query,
		review.ID,
		review.AttractionID,
		review.AuthorUserID,
		review.Rating,
		review.Comment,
		review.CreatedAt,
		review.UpdatedAt,
	); err != nil {
		err = classifyPGError(err)
		if errors.Is(err, ErrUniqueViolation) {
			return ErrConflict
		}
		return fmt.Errorf("insert review: %w", err)
	}

	if len(review.Media) > 0 {
		if err = insertReviewMedia(ctx, tx, review.ID, review.Media); err != nil {
			return err
		}
	}

	// Recalc rating within the same transaction
	const recalcQuery = `
		UPDATE attractions
		SET
			rating = COALESCE((SELECT ROUND(AVG(rating)::numeric, 1) FROM attraction_reviews WHERE attraction_id = $1 AND deleted_at IS NULL), 0),
			review_count = (SELECT COUNT(*) FROM attraction_reviews WHERE attraction_id = $1 AND deleted_at IS NULL),
			updated_at = NOW()
		WHERE id = $1
	`
	if _, err = tx.Exec(ctx, recalcQuery, review.AttractionID); err != nil {
		return fmt.Errorf("recalc rating after review create: %w", err)
	}

	if err = tx.Commit(ctx); err != nil {
		return fmt.Errorf("commit review create tx: %w", err)
	}
	return nil
}

func (r *PGAttractionRepository) SoftDeleteReview(ctx context.Context, reviewID, authorUserID uuid.UUID) error {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return fmt.Errorf("begin delete review tx: %w", err)
	}
	defer tx.Rollback(ctx)

	var attractionID uuid.UUID
	err = tx.QueryRow(ctx,
		`UPDATE attraction_reviews SET deleted_at = NOW(), updated_at = NOW() WHERE id = $1 AND author_user_id = $2 AND deleted_at IS NULL RETURNING attraction_id`,
		reviewID, authorUserID,
	).Scan(&attractionID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return ErrNotFound
		}
		return fmt.Errorf("soft delete review: %w", err)
	}

	const recalcQuery = `
		UPDATE attractions
		SET
			rating = COALESCE((SELECT ROUND(AVG(rating)::numeric, 1) FROM attraction_reviews WHERE attraction_id = $1 AND deleted_at IS NULL), 0),
			review_count = (SELECT COUNT(*) FROM attraction_reviews WHERE attraction_id = $1 AND deleted_at IS NULL),
			updated_at = NOW()
		WHERE id = $1
	`
	if _, err = tx.Exec(ctx, recalcQuery, attractionID); err != nil {
		return fmt.Errorf("recalc rating after review delete: %w", err)
	}

	if err = tx.Commit(ctx); err != nil {
		return fmt.Errorf("commit delete review tx: %w", err)
	}
	return nil
}

func (r *PGAttractionRepository) GetReviewByID(ctx context.Context, reviewID uuid.UUID) (*model.AttractionReview, error) {
	const query = `
		SELECT id, attraction_id, author_user_id, rating, comment, created_at, updated_at, deleted_at
		FROM attraction_reviews
		WHERE id = $1
		LIMIT 1
	`
	row := r.pool.QueryRow(ctx, query, reviewID)
	review, err := scanReview(row)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, fmt.Errorf("select review by id: %w", err)
	}

	media, err := r.getReviewMedia(ctx, reviewID)
	if err != nil {
		return nil, err
	}
	review.Media = media

	return review, nil
}

func (r *PGAttractionRepository) GetReviewByAttractionAndAuthor(ctx context.Context, attractionID, authorUserID uuid.UUID) (*model.AttractionReview, error) {
	const query = `
		SELECT id, attraction_id, author_user_id, rating, comment, created_at, updated_at, deleted_at
		FROM attraction_reviews
		WHERE attraction_id = $1
		  AND author_user_id = $2
		  AND deleted_at IS NULL
		LIMIT 1
	`
	row := r.pool.QueryRow(ctx, query, attractionID, authorUserID)
	review, err := scanReview(row)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, fmt.Errorf("select review by attraction and author: %w", err)
	}

	media, err := r.getReviewMedia(ctx, review.ID)
	if err != nil {
		return nil, err
	}
	review.Media = media

	return review, nil
}

func (r *PGAttractionRepository) ListReviews(ctx context.Context, attractionID uuid.UUID, limit, offset int) ([]*model.AttractionReview, int, error) {
	// Count
	var total int
	if err := r.pool.QueryRow(ctx,
		`SELECT COUNT(*) FROM attraction_reviews WHERE attraction_id = $1 AND deleted_at IS NULL`,
		attractionID,
	).Scan(&total); err != nil {
		return nil, 0, fmt.Errorf("count reviews: %w", err)
	}

	const query = `
		SELECT id, attraction_id, author_user_id, rating, comment, created_at, updated_at, deleted_at
		FROM attraction_reviews
		WHERE attraction_id = $1 AND deleted_at IS NULL
		ORDER BY created_at DESC
		LIMIT $2 OFFSET $3
	`
	rows, err := r.pool.Query(ctx, query, attractionID, limit, offset)
	if err != nil {
		return nil, 0, fmt.Errorf("query reviews: %w", err)
	}
	defer rows.Close()

	items := make([]*model.AttractionReview, 0)
	for rows.Next() {
		item, scanErr := scanReview(rows)
		if scanErr != nil {
			return nil, 0, fmt.Errorf("scan review list: %w", scanErr)
		}
		items = append(items, item)
	}
	if err = rows.Err(); err != nil {
		return nil, 0, fmt.Errorf("review rows iteration: %w", err)
	}

	// Load media for each review
	for _, item := range items {
		media, mErr := r.getReviewMedia(ctx, item.ID)
		if mErr != nil {
			return nil, 0, mErr
		}
		item.Media = media
	}

	return items, total, nil
}

func (r *PGAttractionRepository) ReplaceReviewMedia(ctx context.Context, reviewID uuid.UUID, media []model.ReviewMedia) error {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return fmt.Errorf("begin review media tx: %w", err)
	}
	defer tx.Rollback(ctx)

	if _, err = tx.Exec(ctx, `DELETE FROM review_media WHERE review_id = $1`, reviewID); err != nil {
		return fmt.Errorf("delete old review media: %w", err)
	}

	if len(media) > 0 {
		if err = insertReviewMedia(ctx, tx, reviewID, media); err != nil {
			return err
		}
	}

	if err = tx.Commit(ctx); err != nil {
		return fmt.Errorf("commit review media replace tx: %w", err)
	}
	return nil
}

func (r *PGAttractionRepository) getReviewMedia(ctx context.Context, reviewID uuid.UUID) ([]model.ReviewMedia, error) {
	const query = `
		SELECT id, review_id, file_id, media_type, position, created_at
		FROM review_media
		WHERE review_id = $1
		ORDER BY position
	`
	rows, err := r.pool.Query(ctx, query, reviewID)
	if err != nil {
		return nil, fmt.Errorf("query review media: %w", err)
	}
	defer rows.Close()

	items := make([]model.ReviewMedia, 0)
	for rows.Next() {
		var m model.ReviewMedia
		var mediaTypeRaw string
		if err = rows.Scan(&m.ID, &m.ReviewID, &m.FileID, &mediaTypeRaw, &m.Position, &m.CreatedAt); err != nil {
			return nil, fmt.Errorf("scan review media: %w", err)
		}
		m.MediaType = enum.MediaType(mediaTypeRaw)
		items = append(items, m)
	}
	return items, rows.Err()
}

func insertReviewMedia(ctx context.Context, tx pgx.Tx, reviewID uuid.UUID, media []model.ReviewMedia) error {
	for _, m := range media {
		const q = `
			INSERT INTO review_media (id, review_id, file_id, media_type, position, created_at)
			VALUES ($1, $2, $3, $4, $5, $6)
		`
		if _, err := tx.Exec(ctx, q, m.ID, reviewID, m.FileID, string(m.MediaType), m.Position, m.CreatedAt); err != nil {
			return fmt.Errorf("insert review media: %w", err)
		}
	}
	return nil
}

// ---------------------------------------------------------------------------
// Rating
// ---------------------------------------------------------------------------

func (r *PGAttractionRepository) RecalcRating(ctx context.Context, attractionID uuid.UUID) (float64, int, error) {
	return recalcAttractionRating(ctx, r.pool, attractionID)
}

func (r *PGAttractionRepository) ApplyRatingSourceSnapshot(
	ctx context.Context,
	attractionID uuid.UUID,
	source string,
	ratingAvg float64,
	reviewCount int,
) (float64, int, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return 0, 0, fmt.Errorf("begin tx: %w", err)
	}
	defer tx.Rollback(ctx)

	ratingSum := 0.0
	if reviewCount > 0 {
		ratingSum = ratingAvg * float64(reviewCount)
	}

	const upsertQuery = `
		INSERT INTO attraction_rating_sources (
			attraction_id, source, rating_sum, review_count, updated_at
		)
		SELECT $1, $2, $3, $4, NOW()
		WHERE EXISTS (SELECT 1 FROM attractions WHERE id = $1)
		ON CONFLICT (attraction_id, source)
		DO UPDATE SET
			rating_sum = EXCLUDED.rating_sum,
			review_count = EXCLUDED.review_count,
			updated_at = NOW()
	`
	tag, err := tx.Exec(ctx, upsertQuery, attractionID, source, ratingSum, reviewCount)
	if err != nil {
		return 0, 0, fmt.Errorf("upsert attraction rating source: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return 0, 0, ErrNotFound
	}

	rating, count, err := recalcAttractionRating(ctx, tx, attractionID)
	if err != nil {
		return 0, 0, err
	}
	if err = tx.Commit(ctx); err != nil {
		return 0, 0, fmt.Errorf("commit rating source snapshot: %w", err)
	}
	return rating, count, nil
}

type ratingQueryRower interface {
	QueryRow(ctx context.Context, sql string, args ...any) pgx.Row
}

func recalcAttractionRating(ctx context.Context, q ratingQueryRower, attractionID uuid.UUID) (float64, int, error) {
	const query = `
		WITH direct_reviews AS (
			SELECT
				COALESCE(SUM(rating), 0)::numeric AS rating_sum,
				COUNT(*)::int AS review_count
			FROM attraction_reviews
			WHERE attraction_id = $1
			  AND deleted_at IS NULL
		),
		external_sources AS (
			SELECT
				COALESCE(SUM(rating_sum), 0)::numeric AS rating_sum,
				COALESCE(SUM(review_count), 0)::int AS review_count
			FROM attraction_rating_sources
			WHERE attraction_id = $1
		),
		total_rating AS (
			SELECT
				direct_reviews.rating_sum + external_sources.rating_sum AS rating_sum,
				direct_reviews.review_count + external_sources.review_count AS review_count
			FROM direct_reviews, external_sources
		)
		UPDATE attractions
		SET
			rating = CASE
				WHEN total_rating.review_count = 0 THEN 0
				ELSE ROUND((total_rating.rating_sum / total_rating.review_count)::numeric, 1)
			END,
			review_count = total_rating.review_count,
			updated_at = NOW()
		FROM total_rating
		WHERE id = $1
		RETURNING rating, review_count
	`
	var rating float64
	var count int
	err := q.QueryRow(ctx, query, attractionID).Scan(&rating, &count)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return 0, 0, ErrNotFound
		}
		return 0, 0, fmt.Errorf("recalc rating: %w", err)
	}
	return rating, count, nil
}

// ---------------------------------------------------------------------------
// Scanners
// ---------------------------------------------------------------------------

func scanAttraction(scanner interface{ Scan(dest ...any) error }) (*model.Attraction, error) {
	var (
		item              model.Attraction
		categoryRaw       string
		sourceRaw         string
		statusRaw         string
		durationUnit      *string
		priceCurrency     *string
		priceAmount       *float64
		durationValue     *int
		spots             *int
		latitude          *float64
		longitude         *float64
		locationSourceURL string
		visitInfoJSON     []byte
		deletedAt         *time.Time
	)

	if err := scanner.Scan(
		&item.ID,
		&item.AuthorUserID,
		&item.DefaultLocale,
		&item.Title,
		&item.Description,
		&item.Locale,
		&item.CountryCode,
		&item.CityID,
		&latitude,
		&longitude,
		&locationSourceURL,
		&categoryRaw,
		&priceAmount,
		&priceCurrency,
		&durationValue,
		&durationUnit,
		&item.Rating,
		&item.ReviewCount,
		&spots,
		&sourceRaw,
		&statusRaw,
		&item.Tags,
		&visitInfoJSON,
		&item.CreatedAt,
		&item.UpdatedAt,
		&deletedAt,
	); err != nil {
		return nil, err
	}

	item.Category = enum.AttractionCategory(categoryRaw)
	item.Source = enum.ContentSource(sourceRaw)
	item.Status = enum.AttractionStatus(statusRaw)
	item.PriceAmount = priceAmount
	item.PriceCurrency = priceCurrency
	item.DurationValue = durationValue
	item.Spots = spots
	item.Latitude = latitude
	item.Longitude = longitude
	item.LocationSourceURL = locationSourceURL
	item.DeletedAt = deletedAt
	visitInfo, err := unmarshalVisitInfo(visitInfoJSON)
	if err != nil {
		return nil, err
	}
	item.VisitInfo = visitInfo

	if durationUnit != nil {
		du := enum.DurationUnit(*durationUnit)
		item.DurationUnit = &du
	}

	return &item, nil
}

func scanReview(scanner interface{ Scan(dest ...any) error }) (*model.AttractionReview, error) {
	var item model.AttractionReview
	if err := scanner.Scan(
		&item.ID,
		&item.AttractionID,
		&item.AuthorUserID,
		&item.Rating,
		&item.Comment,
		&item.CreatedAt,
		&item.UpdatedAt,
		&item.DeletedAt,
	); err != nil {
		return nil, err
	}
	return &item, nil
}
