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

	"kz/inflap/backend/services/place-service/internal/domain/enum"
	"kz/inflap/backend/services/place-service/internal/domain/model"
)

type PGPlaceRepository struct {
	pool *pgxpool.Pool
}

func NewPGPlaceRepository(pool *pgxpool.Pool) *PGPlaceRepository {
	return &PGPlaceRepository{pool: pool}
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
// Places CRUD
// ---------------------------------------------------------------------------

func (r *PGPlaceRepository) CreatePlace(ctx context.Context, place *model.Place) error {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return fmt.Errorf("begin tx: %w", err)
	}
	defer tx.Rollback(ctx)

	const query = `
		INSERT INTO places (
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
	if place.DurationUnit != nil {
		s := string(*place.DurationUnit)
		durationUnit = &s
	}
	visitInfoJSON, err := marshalVisitInfo(place.VisitInfo)
	if err != nil {
		return err
	}

	if _, err = tx.Exec(ctx, query,
		place.ID,
		place.AuthorUserID,
		normalizeDBLocale(place.DefaultLocale),
		place.CountryCode,
		place.CityID,
		place.Latitude,
		place.Longitude,
		place.LocationSourceURL,
		string(place.Category),
		place.PriceAmount,
		place.PriceCurrency,
		place.DurationValue,
		durationUnit,
		place.Rating,
		place.ReviewCount,
		place.Spots,
		string(place.Source),
		string(place.Status),
		place.Tags,
		visitInfoJSON,
		place.CreatedAt,
		place.UpdatedAt,
	); err != nil {
		err = classifyPGError(err)
		if errors.Is(err, ErrUniqueViolation) {
			return ErrConflict
		}
		return fmt.Errorf("insert place: %w", err)
	}

	if err = upsertPlaceTranslations(ctx, tx, place); err != nil {
		return err
	}
	if err = replacePlaceCityLinks(ctx, tx, place.ID, place.AccessCities, place.DepartureCities); err != nil {
		return err
	}

	if len(place.Media) > 0 {
		if err = insertPlaceMedia(ctx, tx, place.ID, place.Media); err != nil {
			return err
		}
	}

	if err = tx.Commit(ctx); err != nil {
		return fmt.Errorf("commit place create tx: %w", err)
	}
	return nil
}

func (r *PGPlaceRepository) UpdatePlace(ctx context.Context, place *model.Place) error {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return fmt.Errorf("begin update tx: %w", err)
	}
	defer tx.Rollback(ctx)

	const query = `
		UPDATE places
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
	if place.DurationUnit != nil {
		s := string(*place.DurationUnit)
		durationUnit = &s
	}
	visitInfoJSON, err := marshalVisitInfo(place.VisitInfo)
	if err != nil {
		return err
	}

	tag, err := tx.Exec(ctx, query,
		place.ID,
		normalizeDBLocale(place.DefaultLocale),
		place.CountryCode,
		place.CityID,
		place.Latitude,
		place.Longitude,
		place.LocationSourceURL,
		string(place.Category),
		place.PriceAmount,
		place.PriceCurrency,
		place.DurationValue,
		durationUnit,
		place.Spots,
		string(place.Status),
		place.Tags,
		visitInfoJSON,
		place.UpdatedAt,
	)
	if err != nil {
		err = classifyPGError(err)
		if errors.Is(err, ErrUniqueViolation) {
			return ErrConflict
		}
		return fmt.Errorf("update place: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return ErrNotFound
	}

	if err = upsertPlaceTranslations(ctx, tx, place); err != nil {
		return err
	}
	if err = replacePlaceCityLinks(ctx, tx, place.ID, place.AccessCities, place.DepartureCities); err != nil {
		return err
	}

	if err = tx.Commit(ctx); err != nil {
		return fmt.Errorf("commit place update tx: %w", err)
	}
	return nil
}

func (r *PGPlaceRepository) SoftDeletePlace(ctx context.Context, placeID uuid.UUID) error {
	const query = `
		UPDATE places
		SET deleted_at = NOW(), updated_at = NOW()
		WHERE id = $1 AND deleted_at IS NULL
	`
	tag, err := r.pool.Exec(ctx, query, placeID)
	if err != nil {
		return fmt.Errorf("soft delete place: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return ErrNotFound
	}
	return nil
}

func (r *PGPlaceRepository) RecoverPlace(ctx context.Context, placeID uuid.UUID) error {
	const query = `
		UPDATE places
		SET deleted_at = NULL, updated_at = NOW()
		WHERE id = $1 AND deleted_at IS NOT NULL
	`
	tag, err := r.pool.Exec(ctx, query, placeID)
	if err != nil {
		return fmt.Errorf("recover place: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return ErrNotFound
	}
	return nil
}

func (r *PGPlaceRepository) GetPlaceByID(ctx context.Context, id uuid.UUID, locale string) (*model.Place, error) {
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
		FROM places a
		LEFT JOIN place_translations requested
			ON requested.place_id = a.id AND requested.locale = $2
		LEFT JOIN place_translations fallback
			ON fallback.place_id = a.id AND fallback.locale = a.default_locale
		WHERE a.id = $1
		LIMIT 1
	`
	row := r.pool.QueryRow(ctx, query, id, normalizeDBLocale(locale))
	item, err := scanPlace(row)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, fmt.Errorf("select place by id: %w", err)
	}

	media, err := r.getPlaceMedia(ctx, id)
	if err != nil {
		return nil, err
	}
	item.Media = media

	translations, err := r.getPlaceTranslations(ctx, id)
	if err != nil {
		return nil, err
	}
	item.Translations = translations

	if err = r.loadPlaceCityLinks(ctx, item); err != nil {
		return nil, err
	}

	return item, nil
}

func (r *PGPlaceRepository) ListPlaces(ctx context.Context, filter model.PlaceListFilter) ([]*model.Place, int, error) {
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
			SELECT 1 FROM place_city_links acl
			WHERE acl.place_id = a.id AND acl.kind = 'ACCESS' AND acl.city_id = $%d
		)`, len(args)))
	}
	if filter.DepartureCityID != "" {
		args = append(args, filter.DepartureCityID)
		clauses = append(clauses, fmt.Sprintf(`EXISTS (
			SELECT 1 FROM place_city_links dcl
			WHERE dcl.place_id = a.id AND dcl.kind = 'DEPARTURE' AND dcl.city_id = $%d
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
					FROM place_translations partial_translation
					WHERE partial_translation.place_id = a.id
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
			FROM place_translations search_translation
			WHERE search_translation.place_id = a.id
				AND COALESCE(search_translation.search_vector, ''::tsvector) @@ websearch_to_tsquery('simple', $%d)
		)`, fullTextArg)
		if len(tokenClauses) > 0 {
			searchClause = fmt.Sprintf(`(%s OR (%s))`, searchClause, strings.Join(tokenClauses, " AND "))
		}
		clauses = append(clauses, searchClause)
	}

	where := strings.Join(clauses, " AND ")

	// Count query
	countQuery := fmt.Sprintf(`SELECT COUNT(*) FROM places a WHERE %s`, where)
	var total int
	if err := r.pool.QueryRow(ctx, countQuery, args...).Scan(&total); err != nil {
		return nil, 0, fmt.Errorf("count places: %w", err)
	}

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
	latitudePos := 0
	longitudePos := 0
	if filter.Latitude != nil && filter.Longitude != nil {
		selectArgs = append(selectArgs, *filter.Latitude, *filter.Longitude)
		latitudePos = len(selectArgs) - 1
		longitudePos = len(selectArgs)
	}
	orderBy := placeListOrderBy(filter, latitudePos, longitudePos)
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
		FROM places a
		LEFT JOIN place_translations requested
			ON requested.place_id = a.id AND requested.locale = $%d
		LEFT JOIN place_translations fallback
			ON fallback.place_id = a.id AND fallback.locale = a.default_locale
		WHERE %s
		ORDER BY %s
		LIMIT $%d OFFSET $%d
	`, localePos, where, orderBy, limitPos, offsetPos)

	rows, err := r.pool.Query(ctx, query, selectArgs...)
	if err != nil {
		return nil, 0, fmt.Errorf("query places: %w", err)
	}
	defer rows.Close()

	items := make([]*model.Place, 0)
	for rows.Next() {
		item, scanErr := scanPlace(rows)
		if scanErr != nil {
			return nil, 0, fmt.Errorf("scan place list: %w", scanErr)
		}
		items = append(items, item)
	}
	if err = rows.Err(); err != nil {
		return nil, 0, fmt.Errorf("rows iteration: %w", err)
	}

	// Load media for each place
	for _, item := range items {
		media, mErr := r.getPlaceMedia(ctx, item.ID)
		if mErr != nil {
			return nil, 0, mErr
		}
		item.Media = media

		translations, tErr := r.getPlaceTranslations(ctx, item.ID)
		if tErr != nil {
			return nil, 0, tErr
		}
		item.Translations = translations
		if linkErr := r.loadPlaceCityLinks(ctx, item); linkErr != nil {
			return nil, 0, linkErr
		}
	}

	return items, total, nil
}

func placeListOrderBy(filter model.PlaceListFilter, latitudePos int, longitudePos int) string {
	const durationInHours = "CASE WHEN a.duration_unit = 'DAYS' THEN a.duration_value * 24 ELSE a.duration_value END"

	switch strings.TrimSpace(filter.Sort) {
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
	case "distance":
		if filter.Latitude == nil || filter.Longitude == nil || latitudePos <= 0 || longitudePos <= 0 {
			return "a.created_at DESC"
		}
		return fmt.Sprintf(
			"CASE WHEN a.latitude IS NULL OR a.longitude IS NULL THEN NULL ELSE ((a.latitude - $%d) * (a.latitude - $%d)) + ((a.longitude - $%d) * (a.longitude - $%d) * COS(RADIANS($%d)) * COS(RADIANS($%d))) END ASC NULLS LAST, a.rating DESC, a.review_count DESC, a.created_at DESC",
			latitudePos,
			latitudePos,
			longitudePos,
			longitudePos,
			latitudePos,
			latitudePos,
		)
	case "latest":
		return "a.created_at DESC"
	default:
		return "a.created_at DESC"
	}
}

// ---------------------------------------------------------------------------
// Media
// ---------------------------------------------------------------------------

func (r *PGPlaceRepository) ReplacePlaceMedia(ctx context.Context, placeID uuid.UUID, media []model.PlaceMedia) error {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return fmt.Errorf("begin media tx: %w", err)
	}
	defer tx.Rollback(ctx)

	if _, err = tx.Exec(ctx, `DELETE FROM place_media WHERE place_id = $1`, placeID); err != nil {
		return fmt.Errorf("delete old place media: %w", err)
	}

	if len(media) > 0 {
		if err = insertPlaceMedia(ctx, tx, placeID, media); err != nil {
			return err
		}
	}

	if err = tx.Commit(ctx); err != nil {
		return fmt.Errorf("commit media replace tx: %w", err)
	}
	return nil
}

func (r *PGPlaceRepository) ListVisitReferenceValues(ctx context.Context, locale string) ([]model.PlaceVisitReferenceValue, error) {
	locale = normalizeDBLocale(locale)
	const query = `
		SELECT
			v.category,
			v.code,
			COALESCE(current_locale.label, fallback_locale.label, v.code) AS label,
			COALESCE(
				jsonb_object_agg(all_locale.locale, all_locale.label)
					FILTER (WHERE all_locale.locale IS NOT NULL),
				'{}'::jsonb
			) AS labels,
			v.sort_order,
			v.is_active
		FROM place_visit_reference_values v
		LEFT JOIN place_visit_reference_translations current_locale
			ON current_locale.category = v.category
			AND current_locale.code = v.code
			AND current_locale.locale = $1
		LEFT JOIN place_visit_reference_translations fallback_locale
			ON fallback_locale.category = v.category
			AND fallback_locale.code = v.code
			AND fallback_locale.locale = 'en'
		LEFT JOIN place_visit_reference_translations all_locale
			ON all_locale.category = v.category
			AND all_locale.code = v.code
		WHERE v.is_active = true
		GROUP BY v.category, v.code, current_locale.label, fallback_locale.label, v.sort_order, v.is_active
		ORDER BY v.category, v.sort_order, v.code
	`
	rows, err := r.pool.Query(ctx, query, locale)
	if err != nil {
		return nil, fmt.Errorf("query place visit references: %w", err)
	}
	defer rows.Close()

	items := make([]model.PlaceVisitReferenceValue, 0)
	for rows.Next() {
		var item model.PlaceVisitReferenceValue
		var labelsJSON []byte
		if err = rows.Scan(
			&item.Category,
			&item.Code,
			&item.Label,
			&labelsJSON,
			&item.SortOrder,
			&item.Active,
		); err != nil {
			return nil, fmt.Errorf("scan place visit reference: %w", err)
		}
		if len(labelsJSON) > 0 {
			if err = json.Unmarshal(labelsJSON, &item.Labels); err != nil {
				return nil, fmt.Errorf("decode place visit reference labels: %w", err)
			}
		}
		items = append(items, item)
	}
	return items, rows.Err()
}

func (r *PGPlaceRepository) getPlaceMedia(ctx context.Context, placeID uuid.UUID) ([]model.PlaceMedia, error) {
	const query = `
		SELECT id, place_id, file_id, external_url, source_url, credit, license, media_type, position, created_at
		FROM place_media
		WHERE place_id = $1
		ORDER BY position
	`
	rows, err := r.pool.Query(ctx, query, placeID)
	if err != nil {
		return nil, fmt.Errorf("query place media: %w", err)
	}
	defer rows.Close()

	items := make([]model.PlaceMedia, 0)
	for rows.Next() {
		var m model.PlaceMedia
		var mediaTypeRaw string
		if err = rows.Scan(
			&m.ID,
			&m.PlaceID,
			&m.FileID,
			&m.ExternalURL,
			&m.SourceURL,
			&m.Credit,
			&m.License,
			&mediaTypeRaw,
			&m.Position,
			&m.CreatedAt,
		); err != nil {
			return nil, fmt.Errorf("scan place media: %w", err)
		}
		m.MediaType = enum.MediaType(mediaTypeRaw)
		items = append(items, m)
	}
	return items, rows.Err()
}

func (r *PGPlaceRepository) getPlaceTranslations(ctx context.Context, placeID uuid.UUID) (map[string]model.PlaceTranslation, error) {
	const query = `
		SELECT place_id, locale, title, description, created_at, updated_at
		FROM place_translations
		WHERE place_id = $1
		ORDER BY locale
	`
	rows, err := r.pool.Query(ctx, query, placeID)
	if err != nil {
		return nil, fmt.Errorf("query place translations: %w", err)
	}
	defer rows.Close()

	items := make(map[string]model.PlaceTranslation)
	for rows.Next() {
		var translation model.PlaceTranslation
		if err = rows.Scan(
			&translation.PlaceID,
			&translation.Locale,
			&translation.Title,
			&translation.Description,
			&translation.CreatedAt,
			&translation.UpdatedAt,
		); err != nil {
			return nil, fmt.Errorf("scan place translation: %w", err)
		}
		items[translation.Locale] = translation
	}
	return items, rows.Err()
}

func upsertPlaceTranslations(ctx context.Context, tx pgx.Tx, place *model.Place) error {
	translations := place.Translations
	if len(translations) == 0 && strings.TrimSpace(place.Title) != "" {
		locale := normalizeDBLocale(place.DefaultLocale)
		translations = map[string]model.PlaceTranslation{
			locale: {
				Locale:      locale,
				Title:       strings.TrimSpace(place.Title),
				Description: strings.TrimSpace(place.Description),
			},
		}
	}

	if len(translations) == 0 {
		return nil
	}

	const query = `
		INSERT INTO place_translations (
			place_id, locale, title, description, created_at, updated_at
		) VALUES (
			$1, $2, $3, $4, $5, $6
		)
		ON CONFLICT (place_id, locale) DO UPDATE
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
			createdAt = place.CreatedAt
		}
		if createdAt.IsZero() {
			createdAt = place.UpdatedAt
		}
		updatedAt := translation.UpdatedAt
		if updatedAt.IsZero() {
			updatedAt = place.UpdatedAt
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
			place.ID,
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
			return fmt.Errorf("upsert place translation: %w", err)
		}
	}
	return nil
}

func replacePlaceCityLinks(
	ctx context.Context,
	tx pgx.Tx,
	placeID uuid.UUID,
	accessCities []model.PlaceCityLink,
	departureCities []model.PlaceCityLink,
) error {
	if _, err := tx.Exec(ctx, `DELETE FROM place_city_links WHERE place_id = $1`, placeID); err != nil {
		return fmt.Errorf("delete place city links: %w", err)
	}
	if err := insertPlaceCityLinks(ctx, tx, placeID, "ACCESS", accessCities); err != nil {
		return err
	}
	return insertPlaceCityLinks(ctx, tx, placeID, "DEPARTURE", departureCities)
}

func insertPlaceCityLinks(
	ctx context.Context,
	tx pgx.Tx,
	placeID uuid.UUID,
	kind string,
	items []model.PlaceCityLink,
) error {
	const query = `
		INSERT INTO place_city_links (
			id, place_id, kind, country_code, city_id, position, created_at
		) VALUES (
			$1, $2, $3, $4, $5, $6, $7
		)
		ON CONFLICT (place_id, kind, city_id) DO UPDATE
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
			placeID,
			kind,
			strings.ToUpper(strings.TrimSpace(item.CountryCode)),
			strings.ToLower(strings.TrimSpace(item.CityID)),
			position,
			createdAt,
		); err != nil {
			return fmt.Errorf("insert place city link: %w", err)
		}
	}
	return nil
}

func (r *PGPlaceRepository) loadPlaceCityLinks(ctx context.Context, place *model.Place) error {
	if place == nil {
		return nil
	}
	const query = `
		SELECT place_id, kind, country_code, city_id, position, created_at
		FROM place_city_links
		WHERE place_id = $1
		ORDER BY kind, position, city_id
	`
	rows, err := r.pool.Query(ctx, query, place.ID)
	if err != nil {
		return fmt.Errorf("query place city links: %w", err)
	}
	defer rows.Close()

	place.AccessCities = nil
	place.DepartureCities = nil
	for rows.Next() {
		var item model.PlaceCityLink
		if err = rows.Scan(
			&item.PlaceID,
			&item.Kind,
			&item.CountryCode,
			&item.CityID,
			&item.Position,
			&item.CreatedAt,
		); err != nil {
			return fmt.Errorf("scan place city link: %w", err)
		}
		switch item.Kind {
		case "ACCESS":
			place.AccessCities = append(place.AccessCities, item)
		case "DEPARTURE":
			place.DepartureCities = append(place.DepartureCities, item)
		}
	}
	return rows.Err()
}

func insertPlaceMedia(ctx context.Context, tx pgx.Tx, placeID uuid.UUID, media []model.PlaceMedia) error {
	for _, m := range media {
		const q = `
			INSERT INTO place_media (
				id, place_id, file_id, external_url, source_url, credit, license, media_type, position, created_at
			)
			VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
		`
		if _, err := tx.Exec(
			ctx,
			q,
			m.ID,
			placeID,
			m.FileID,
			strings.TrimSpace(m.ExternalURL),
			strings.TrimSpace(m.SourceURL),
			strings.TrimSpace(m.Credit),
			strings.TrimSpace(m.License),
			string(m.MediaType),
			m.Position,
			m.CreatedAt,
		); err != nil {
			return fmt.Errorf("insert place media: %w", err)
		}
	}
	return nil
}

func marshalVisitInfo(visitInfo model.PlaceVisitInfo) ([]byte, error) {
	payload, err := json.Marshal(visitInfo)
	if err != nil {
		return nil, fmt.Errorf("marshal place visit info: %w", err)
	}
	return payload, nil
}

func unmarshalVisitInfo(payload []byte) (model.PlaceVisitInfo, error) {
	var visitInfo model.PlaceVisitInfo
	if len(payload) == 0 {
		return visitInfo, nil
	}
	if err := json.Unmarshal(payload, &visitInfo); err != nil {
		return model.PlaceVisitInfo{}, fmt.Errorf("unmarshal place visit info: %w", err)
	}
	return visitInfo, nil
}

// ---------------------------------------------------------------------------
// Tags
// ---------------------------------------------------------------------------

func (r *PGPlaceRepository) ReplaceTags(ctx context.Context, placeID uuid.UUID, tags []string) error {
	const query = `
		UPDATE places SET tags = $2, updated_at = NOW()
		WHERE id = $1 AND deleted_at IS NULL
	`
	tag, err := r.pool.Exec(ctx, query, placeID, tags)
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

func (r *PGPlaceRepository) CreateReview(ctx context.Context, review *model.PlaceReview) error {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return fmt.Errorf("begin review tx: %w", err)
	}
	defer tx.Rollback(ctx)

	const query = `
		INSERT INTO place_reviews (id, place_id, author_user_id, rating, comment, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
	`
	if _, err = tx.Exec(ctx, query,
		review.ID,
		review.PlaceID,
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
		UPDATE places
		SET
			rating = COALESCE((SELECT ROUND(AVG(rating)::numeric, 1) FROM place_reviews WHERE place_id = $1 AND deleted_at IS NULL), 0),
			review_count = (SELECT COUNT(*) FROM place_reviews WHERE place_id = $1 AND deleted_at IS NULL),
			updated_at = NOW()
		WHERE id = $1
	`
	if _, err = tx.Exec(ctx, recalcQuery, review.PlaceID); err != nil {
		return fmt.Errorf("recalc rating after review create: %w", err)
	}

	if err = tx.Commit(ctx); err != nil {
		return fmt.Errorf("commit review create tx: %w", err)
	}
	return nil
}

func (r *PGPlaceRepository) SoftDeleteReview(ctx context.Context, reviewID, authorUserID uuid.UUID) error {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return fmt.Errorf("begin delete review tx: %w", err)
	}
	defer tx.Rollback(ctx)

	var placeID uuid.UUID
	err = tx.QueryRow(ctx,
		`UPDATE place_reviews SET deleted_at = NOW(), updated_at = NOW() WHERE id = $1 AND author_user_id = $2 AND deleted_at IS NULL RETURNING place_id`,
		reviewID, authorUserID,
	).Scan(&placeID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return ErrNotFound
		}
		return fmt.Errorf("soft delete review: %w", err)
	}

	const recalcQuery = `
		UPDATE places
		SET
			rating = COALESCE((SELECT ROUND(AVG(rating)::numeric, 1) FROM place_reviews WHERE place_id = $1 AND deleted_at IS NULL), 0),
			review_count = (SELECT COUNT(*) FROM place_reviews WHERE place_id = $1 AND deleted_at IS NULL),
			updated_at = NOW()
		WHERE id = $1
	`
	if _, err = tx.Exec(ctx, recalcQuery, placeID); err != nil {
		return fmt.Errorf("recalc rating after review delete: %w", err)
	}

	if err = tx.Commit(ctx); err != nil {
		return fmt.Errorf("commit delete review tx: %w", err)
	}
	return nil
}

func (r *PGPlaceRepository) GetReviewByID(ctx context.Context, reviewID uuid.UUID) (*model.PlaceReview, error) {
	const query = `
		SELECT id, place_id, author_user_id, rating, comment, created_at, updated_at, deleted_at
		FROM place_reviews
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

func (r *PGPlaceRepository) GetReviewByPlaceAndAuthor(ctx context.Context, placeID, authorUserID uuid.UUID) (*model.PlaceReview, error) {
	const query = `
		SELECT id, place_id, author_user_id, rating, comment, created_at, updated_at, deleted_at
		FROM place_reviews
		WHERE place_id = $1
		  AND author_user_id = $2
		  AND deleted_at IS NULL
		LIMIT 1
	`
	row := r.pool.QueryRow(ctx, query, placeID, authorUserID)
	review, err := scanReview(row)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, fmt.Errorf("select review by place and author: %w", err)
	}

	media, err := r.getReviewMedia(ctx, review.ID)
	if err != nil {
		return nil, err
	}
	review.Media = media

	return review, nil
}

func (r *PGPlaceRepository) ListReviews(ctx context.Context, placeID uuid.UUID, limit, offset int) ([]*model.PlaceReview, int, error) {
	// Count
	var total int
	if err := r.pool.QueryRow(ctx,
		`SELECT COUNT(*) FROM place_reviews WHERE place_id = $1 AND deleted_at IS NULL`,
		placeID,
	).Scan(&total); err != nil {
		return nil, 0, fmt.Errorf("count reviews: %w", err)
	}

	const query = `
		SELECT id, place_id, author_user_id, rating, comment, created_at, updated_at, deleted_at
		FROM place_reviews
		WHERE place_id = $1 AND deleted_at IS NULL
		ORDER BY created_at DESC
		LIMIT $2 OFFSET $3
	`
	rows, err := r.pool.Query(ctx, query, placeID, limit, offset)
	if err != nil {
		return nil, 0, fmt.Errorf("query reviews: %w", err)
	}
	defer rows.Close()

	items := make([]*model.PlaceReview, 0)
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

func (r *PGPlaceRepository) ReplaceReviewMedia(ctx context.Context, reviewID uuid.UUID, media []model.ReviewMedia) error {
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

func (r *PGPlaceRepository) getReviewMedia(ctx context.Context, reviewID uuid.UUID) ([]model.ReviewMedia, error) {
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

func (r *PGPlaceRepository) RecalcRating(ctx context.Context, placeID uuid.UUID) (float64, int, error) {
	return recalcPlaceRating(ctx, r.pool, placeID)
}

func (r *PGPlaceRepository) ApplyRatingSourceSnapshot(
	ctx context.Context,
	placeID uuid.UUID,
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
		INSERT INTO place_rating_sources (
			place_id, source, rating_sum, review_count, updated_at
		)
		SELECT $1, $2, $3, $4, NOW()
		WHERE EXISTS (SELECT 1 FROM places WHERE id = $1)
		ON CONFLICT (place_id, source)
		DO UPDATE SET
			rating_sum = EXCLUDED.rating_sum,
			review_count = EXCLUDED.review_count,
			updated_at = NOW()
	`
	tag, err := tx.Exec(ctx, upsertQuery, placeID, source, ratingSum, reviewCount)
	if err != nil {
		return 0, 0, fmt.Errorf("upsert place rating source: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return 0, 0, ErrNotFound
	}

	rating, count, err := recalcPlaceRating(ctx, tx, placeID)
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

func recalcPlaceRating(ctx context.Context, q ratingQueryRower, placeID uuid.UUID) (float64, int, error) {
	const query = `
		WITH direct_reviews AS (
			SELECT
				COALESCE(SUM(rating), 0)::numeric AS rating_sum,
				COUNT(*)::int AS review_count
			FROM place_reviews
			WHERE place_id = $1
			  AND deleted_at IS NULL
		),
		external_sources AS (
			SELECT
				COALESCE(SUM(rating_sum), 0)::numeric AS rating_sum,
				COALESCE(SUM(review_count), 0)::int AS review_count
			FROM place_rating_sources
			WHERE place_id = $1
		),
		total_rating AS (
			SELECT
				direct_reviews.rating_sum + external_sources.rating_sum AS rating_sum,
				direct_reviews.review_count + external_sources.review_count AS review_count
			FROM direct_reviews, external_sources
		)
		UPDATE places
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
	err := q.QueryRow(ctx, query, placeID).Scan(&rating, &count)
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

func scanPlace(scanner interface{ Scan(dest ...any) error }) (*model.Place, error) {
	var (
		item              model.Place
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

	item.Category = enum.PlaceCategory(categoryRaw)
	item.Source = enum.ContentSource(sourceRaw)
	item.Status = enum.PlaceStatus(statusRaw)
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

func scanReview(scanner interface{ Scan(dest ...any) error }) (*model.PlaceReview, error) {
	var item model.PlaceReview
	if err := scanner.Scan(
		&item.ID,
		&item.PlaceID,
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
