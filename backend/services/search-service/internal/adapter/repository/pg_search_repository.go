package repository

import (
	"context"
	"encoding/json"
	"strings"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"

	"kz/inflap/backend/services/search-service/internal/app"
	"kz/inflap/backend/services/search-service/internal/domain/model"
)

type PGSearchRepository struct {
	pool *pgxpool.Pool
}

func NewPGSearchRepository(pool *pgxpool.Pool) *PGSearchRepository {
	return &PGSearchRepository{pool: pool}
}

func (r *PGSearchRepository) Search(ctx context.Context, query app.SearchQuery) (app.SearchPage, error) {
	domains := domainStrings(query.Domains)
	locale := normalizeLocale(query.Locale)
	limit := query.Limit
	if limit <= 0 {
		limit = 20
	}
	offset := query.Offset
	if offset < 0 {
		offset = 0
	}
	fetchLimit := limit + 1
	candidateLimit := query.CandidateLimit

	if strings.TrimSpace(query.Query) == "" {
		return r.searchTrending(ctx, query, domains, locale, limit, offset, fetchLimit)
	}

	tokenQuery := searchTokenQuery(query.Query)
	strongPage, err := r.searchTextStrong(ctx, query, domains, locale, fetchLimit, offset, candidateLimit, tokenQuery)
	if err != nil {
		return app.SearchPage{}, err
	}
	if len(strongPage.Items) > limit {
		return finalizeSearchPage(strongPage, limit, offset), nil
	}
	if len(strongPage.Items) == 0 {
		hasDocuments, err := r.hasActiveDocuments(ctx, domains)
		if err != nil {
			return app.SearchPage{}, err
		}
		if !hasDocuments {
			return strongPage, nil
		}
	}

	return r.searchTextWithFuzzy(ctx, query, domains, locale, limit, fetchLimit, offset, candidateLimit, tokenQuery)
}

func (r *PGSearchRepository) searchTrending(
	ctx context.Context,
	query app.SearchQuery,
	domains []string,
	locale string,
	limit int,
	offset int,
	fetchLimit int,
) (app.SearchPage, error) {
	rows, err := r.pool.Query(ctx, `
WITH ranked AS (
    SELECT
        domain,
        entity_id,
        COALESCE(NULLIF(title ->> $2, ''), NULLIF(title ->> 'en', ''), search_text) AS title,
        COALESCE(NULLIF(subtitle ->> $2, ''), NULLIF(subtitle ->> 'en', ''), '') AS subtitle,
        deep_link,
        updated_at,
        (
            LEAST(GREATEST(popularity_score, 0), 1) * 0.15
            + LEAST(GREATEST(freshness_score, 0), 1) * 0.10
            + LEAST(GREATEST(trust_score, 0), 1) * 0.05
        ) AS trending_score
    FROM search_documents
    WHERE deleted_at IS NULL
      AND visibility = 'public'
      AND moderation_status = 'approved'
      AND domain = ANY($1)
)
SELECT domain, entity_id, title, subtitle, deep_link, trending_score AS score
FROM ranked
ORDER BY trending_score DESC, updated_at DESC
LIMIT $3
OFFSET $4
`, domains, locale, fetchLimit, offset)
	if err != nil {
		return app.SearchPage{}, err
	}

	page, err := scanSearchRows(rows)
	if err != nil {
		return app.SearchPage{}, err
	}
	return finalizeSearchPage(page, limit, offset), nil
}

func (r *PGSearchRepository) searchTextStrong(
	ctx context.Context,
	query app.SearchQuery,
	domains []string,
	locale string,
	fetchLimit int,
	offset int,
	candidateLimit int,
	tokenQuery string,
) (app.SearchPage, error) {
	rows, err := r.pool.Query(ctx, `
WITH normalized AS (
    SELECT
        lower(trim($2::text)) AS q,
        regexp_split_to_array(lower(trim($2::text)), '\s+') AS tokens
),
matching_ids AS MATERIALIZED (
    SELECT d.id
    FROM search_documents d
    WHERE d.deleted_at IS NULL
      AND d.visibility = 'public'
      AND d.moderation_status = 'approved'
      AND d.domain = ANY($1)
      AND d.search_vector @@ websearch_to_tsquery('simple', $9)

    UNION

    SELECT d.id
    FROM search_documents d
    CROSS JOIN normalized
    WHERE d.deleted_at IS NULL
      AND d.visibility = 'public'
      AND d.moderation_status = 'approved'
      AND d.domain = ANY($1)
      AND d.search_text_normalized LIKE normalized.q || '%'
),
candidate_pool AS (
    SELECT
        d.domain,
        d.entity_id,
        d.title,
        d.subtitle,
        d.search_text,
        d.deep_link,
        d.geo_point,
        d.updated_at,
        (
            CASE
                WHEN normalized.q = '' THEN 0
                WHEN EXISTS (
                    SELECT 1
                    FROM unnest(normalized.tokens) AS token(value)
                    WHERE token.value <> ''
                      AND d.search_text_normalized = token.value
                ) THEN 0.50
                WHEN EXISTS (
                    SELECT 1
                    FROM unnest(normalized.tokens) AS token(value)
                    WHERE token.value <> ''
                      AND d.search_text_normalized LIKE token.value || '%'
                ) THEN 0.35
                WHEN EXISTS (
                    SELECT 1
                    FROM unnest(d.search_variants) AS variant(value)
                    CROSS JOIN unnest(normalized.tokens) AS token(value)
                    WHERE token.value <> ''
                      AND lower(variant.value) = token.value
                ) THEN 0.30
                ELSE 0
            END
            + CASE
                WHEN normalized.q = '' THEN 0
                ELSE ts_rank_cd(d.search_vector, websearch_to_tsquery('simple', $9)) * 0.40
            END
            + CASE
                WHEN normalized.q = '' THEN 0
                ELSE GREATEST(
                    similarity(d.search_text_normalized, normalized.q),
                    word_similarity(normalized.q, d.search_text_normalized),
                    COALESCE((
                        SELECT MAX(GREATEST(
                            similarity(d.search_text_normalized, token.value),
                            word_similarity(token.value, d.search_text_normalized)
                        ))
                        FROM unnest(normalized.tokens) AS token(value)
                        WHERE token.value <> ''
                    ), 0)
                ) * 0.20
            END
            + LEAST(GREATEST(d.popularity_score, 0), 1) * 0.15
            + LEAST(GREATEST(d.freshness_score, 0), 1) * 0.10
            + LEAST(GREATEST(d.trust_score, 0), 1) * 0.05
        ) AS candidate_score
    FROM search_documents d
    JOIN matching_ids m ON m.id = d.id
    CROSS JOIN normalized
    ORDER BY candidate_score DESC, d.updated_at DESC
    LIMIT LEAST(GREATEST($8::int, $4::int + $5::int + 1), 1000)
),
ranked AS (
    SELECT
        d.domain,
        d.entity_id,
        COALESCE(NULLIF(d.title ->> $3, ''), NULLIF(d.title ->> 'en', ''), d.search_text) AS title,
        COALESCE(NULLIF(d.subtitle ->> $3, ''), NULLIF(d.subtitle ->> 'en', ''), '') AS subtitle,
        d.deep_link,
        (
            d.candidate_score
            + CASE
                WHEN $6::double precision IS NULL
                  OR $7::double precision IS NULL
                  OR d.geo_point IS NULL THEN 0
                ELSE GREATEST(
                    0,
                    1 - LEAST(
                        ST_Distance(
                            d.geo_point,
                            ST_SetSRID(ST_MakePoint($7::double precision, $6::double precision), 4326)::geography
                        ),
                        50000
                    ) / 50000
                ) * 0.20
            END
        ) AS score
    FROM candidate_pool d
    CROSS JOIN normalized
)
SELECT domain, entity_id, title, subtitle, deep_link, score
FROM ranked
ORDER BY score DESC, title ASC
LIMIT $4
OFFSET $5
`, domains, strings.TrimSpace(query.Query), locale, fetchLimit, offset, query.Latitude, query.Longitude, candidateLimit, tokenQuery)
	if err != nil {
		return app.SearchPage{}, err
	}
	return scanSearchRows(rows)
}

func (r *PGSearchRepository) searchTextWithFuzzy(
	ctx context.Context,
	query app.SearchQuery,
	domains []string,
	locale string,
	limit int,
	fetchLimit int,
	offset int,
	candidateLimit int,
	tokenQuery string,
) (app.SearchPage, error) {
	rows, err := r.pool.Query(ctx, `
WITH normalized AS (
    SELECT
        lower(trim($2::text)) AS q,
        regexp_split_to_array(lower(trim($2::text)), '\s+') AS tokens
),
matching_ids AS MATERIALIZED (
    SELECT d.id
    FROM search_documents d
    WHERE d.deleted_at IS NULL
      AND d.visibility = 'public'
      AND d.moderation_status = 'approved'
      AND d.domain = ANY($1)
      AND d.search_vector @@ websearch_to_tsquery('simple', $9)

    UNION

    SELECT d.id
    FROM search_documents d
    CROSS JOIN normalized
    WHERE d.deleted_at IS NULL
      AND d.visibility = 'public'
      AND d.moderation_status = 'approved'
      AND d.domain = ANY($1)
      AND d.search_text_normalized LIKE normalized.q || '%'

    UNION

    SELECT fuzzy.id
    FROM (
        SELECT d.id, d.search_text_normalized
        FROM search_documents d
        WHERE d.deleted_at IS NULL
          AND d.visibility = 'public'
          AND d.moderation_status = 'approved'
          AND d.domain = ANY($1)
        ORDER BY d.search_text_normalized <-> lower(trim($2::text))
        LIMIT LEAST(GREATEST($8::int, $4::int + $5::int + 1), 1000)
    ) fuzzy
    CROSS JOIN normalized
    WHERE fuzzy.search_text_normalized % normalized.q
       OR EXISTS (
          SELECT 1
          FROM unnest(normalized.tokens) AS token(value)
          WHERE token.value <> ''
            AND word_similarity(token.value, fuzzy.search_text_normalized) >= 0.45
            AND strict_word_similarity(token.value, fuzzy.search_text_normalized) >= 0.38
       )
),
candidate_pool AS (
    SELECT
        d.domain,
        d.entity_id,
        d.title,
        d.subtitle,
        d.search_text,
        d.deep_link,
        d.geo_point,
        d.updated_at,
        (
            CASE
                WHEN normalized.q = '' THEN 0
                WHEN EXISTS (
                    SELECT 1
                    FROM unnest(normalized.tokens) AS token(value)
                    WHERE token.value <> ''
                      AND d.search_text_normalized = token.value
                ) THEN 0.50
                WHEN EXISTS (
                    SELECT 1
                    FROM unnest(normalized.tokens) AS token(value)
                    WHERE token.value <> ''
                      AND d.search_text_normalized LIKE token.value || '%'
                ) THEN 0.35
                WHEN EXISTS (
                    SELECT 1
                    FROM unnest(d.search_variants) AS variant(value)
                    CROSS JOIN unnest(normalized.tokens) AS token(value)
                    WHERE token.value <> ''
                      AND lower(variant.value) = token.value
                ) THEN 0.30
                ELSE 0
            END
            + CASE
                WHEN normalized.q = '' THEN 0
                ELSE ts_rank_cd(d.search_vector, websearch_to_tsquery('simple', $9)) * 0.40
            END
            + CASE
                WHEN normalized.q = '' THEN 0
                ELSE GREATEST(
                    similarity(d.search_text_normalized, normalized.q),
                    word_similarity(normalized.q, d.search_text_normalized),
                    COALESCE((
                        SELECT MAX(GREATEST(
                            similarity(d.search_text_normalized, token.value),
                            word_similarity(token.value, d.search_text_normalized)
                        ))
                        FROM unnest(normalized.tokens) AS token(value)
                        WHERE token.value <> ''
                    ), 0)
                ) * 0.20
            END
            + LEAST(GREATEST(d.popularity_score, 0), 1) * 0.15
            + LEAST(GREATEST(d.freshness_score, 0), 1) * 0.10
            + LEAST(GREATEST(d.trust_score, 0), 1) * 0.05
        ) AS candidate_score
    FROM search_documents d
    JOIN matching_ids m ON m.id = d.id
    CROSS JOIN normalized
    ORDER BY candidate_score DESC, d.updated_at DESC
    LIMIT LEAST(GREATEST($8::int, $4::int + $5::int + 1), 1000)
),
ranked AS (
    SELECT
        d.domain,
        d.entity_id,
        COALESCE(NULLIF(d.title ->> $3, ''), NULLIF(d.title ->> 'en', ''), d.search_text) AS title,
        COALESCE(NULLIF(d.subtitle ->> $3, ''), NULLIF(d.subtitle ->> 'en', ''), '') AS subtitle,
        d.deep_link,
        (
            d.candidate_score
            + CASE
                WHEN $6::double precision IS NULL
                  OR $7::double precision IS NULL
                  OR d.geo_point IS NULL THEN 0
                ELSE GREATEST(
                    0,
                    1 - LEAST(
                        ST_Distance(
                            d.geo_point,
                            ST_SetSRID(ST_MakePoint($7::double precision, $6::double precision), 4326)::geography
                        ),
                        50000
                    ) / 50000
                ) * 0.20
            END
        ) AS score
    FROM candidate_pool d
    CROSS JOIN normalized
)
SELECT domain, entity_id, title, subtitle, deep_link, score
FROM ranked
ORDER BY score DESC, title ASC
LIMIT $4
OFFSET $5
`, domains, strings.TrimSpace(query.Query), locale, fetchLimit, offset, query.Latitude, query.Longitude, candidateLimit, tokenQuery)
	if err != nil {
		return app.SearchPage{}, err
	}

	page, err := scanSearchRows(rows)
	if err != nil {
		return app.SearchPage{}, err
	}
	return finalizeSearchPage(page, limit, offset), nil
}

type searchRows interface {
	Close()
	Next() bool
	Scan(dest ...any) error
	Err() error
}

func scanSearchRows(rows searchRows) (app.SearchPage, error) {
	defer rows.Close()

	page := app.SearchPage{
		Items: make([]model.SearchResult, 0),
	}
	for rows.Next() {
		var item model.SearchResult
		var domain string
		if err := rows.Scan(
			&domain,
			&item.EntityID,
			&item.Title,
			&item.Subtitle,
			&item.DeepLink,
			&item.Score,
		); err != nil {
			return app.SearchPage{}, err
		}
		item.Domain = model.Domain(domain)
		page.Items = append(page.Items, item)
	}
	if err := rows.Err(); err != nil {
		return app.SearchPage{}, err
	}
	return page, nil
}

func finalizeSearchPage(page app.SearchPage, limit int, offset int) app.SearchPage {
	if len(page.Items) > limit {
		page.Items = page.Items[:limit]
		page.NextPageToken = app.EncodeSearchPageToken(offset + limit)
	}
	return page
}

func searchTokenQuery(query string) string {
	tokens := strings.Fields(strings.ToLower(strings.TrimSpace(query)))
	return strings.Join(tokens, " OR ")
}

func (r *PGSearchRepository) hasActiveDocuments(ctx context.Context, domains []string) (bool, error) {
	var exists bool
	err := r.pool.QueryRow(ctx, `
SELECT EXISTS (
    SELECT 1
    FROM search_documents
    WHERE deleted_at IS NULL
      AND visibility = 'public'
      AND moderation_status = 'approved'
      AND domain = ANY($1)
    LIMIT 1
)
`, domains).Scan(&exists)
	return exists, err
}

func (r *PGSearchRepository) UpsertDocument(ctx context.Context, document model.SearchDocument) error {
	title, err := json.Marshal(emptyMap(document.Title))
	if err != nil {
		return err
	}
	subtitle, err := json.Marshal(emptyMap(document.Subtitle))
	if err != nil {
		return err
	}
	description, err := json.Marshal(emptyMap(document.Description))
	if err != nil {
		return err
	}

	_, err = r.pool.Exec(ctx, `
INSERT INTO search_documents (
    domain,
    entity_id,
    entity_version,
    locale,
    title,
    subtitle,
    description,
    tags,
    category_codes,
    city_id,
    country_code,
    latitude,
    longitude,
    price_min,
    price_max,
    currency,
    rating,
    review_count,
    popularity_score,
    freshness_score,
    trust_score,
    availability_status,
    available_from,
    available_to,
    visibility,
    moderation_status,
    owner_user_id,
    preview_image_file_id,
    deep_link,
    search_text,
    search_text_normalized,
    search_variants,
    updated_at,
    indexed_at,
    deleted_at
) VALUES (
    $1, $2, $3, $4, $5::jsonb, $6::jsonb, $7::jsonb, $8, $9, $10, $11,
    $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, $23, $24,
    $25, $26, NULLIF($27, '')::uuid, NULLIF($28, '')::uuid, $29, $30,
    $31, $32, now(), now(), NULL
)
ON CONFLICT (domain, entity_id, locale) DO UPDATE SET
    entity_version = EXCLUDED.entity_version,
    title = EXCLUDED.title,
    subtitle = EXCLUDED.subtitle,
    description = EXCLUDED.description,
    tags = EXCLUDED.tags,
    category_codes = EXCLUDED.category_codes,
    city_id = EXCLUDED.city_id,
    country_code = EXCLUDED.country_code,
    latitude = EXCLUDED.latitude,
    longitude = EXCLUDED.longitude,
    price_min = EXCLUDED.price_min,
    price_max = EXCLUDED.price_max,
    currency = EXCLUDED.currency,
    rating = EXCLUDED.rating,
    review_count = EXCLUDED.review_count,
    popularity_score = EXCLUDED.popularity_score,
    freshness_score = EXCLUDED.freshness_score,
    trust_score = EXCLUDED.trust_score,
    availability_status = EXCLUDED.availability_status,
    available_from = EXCLUDED.available_from,
    available_to = EXCLUDED.available_to,
    visibility = EXCLUDED.visibility,
    moderation_status = EXCLUDED.moderation_status,
    owner_user_id = EXCLUDED.owner_user_id,
    preview_image_file_id = EXCLUDED.preview_image_file_id,
    deep_link = EXCLUDED.deep_link,
    search_text = EXCLUDED.search_text,
    search_text_normalized = EXCLUDED.search_text_normalized,
    search_variants = EXCLUDED.search_variants,
    updated_at = now(),
    indexed_at = now(),
    deleted_at = NULL
WHERE search_documents.entity_version <= EXCLUDED.entity_version
`, string(document.Domain),
		document.EntityID,
		document.EntityVersion,
		normalizeLocale(document.Locale),
		string(title),
		string(subtitle),
		string(description),
		document.Tags,
		document.CategoryCodes,
		nullIfBlank(document.CityID),
		nullIfBlank(document.CountryCode),
		document.Latitude,
		document.Longitude,
		document.PriceMin,
		document.PriceMax,
		nullIfBlank(document.Currency),
		document.Rating,
		document.ReviewCount,
		document.PopularityScore,
		document.FreshnessScore,
		document.TrustScore,
		nullIfBlank(document.AvailabilityStatus),
		document.AvailableFrom,
		document.AvailableTo,
		document.Visibility,
		document.ModerationStatus,
		document.OwnerUserID,
		document.PreviewImageFileID,
		document.DeepLink,
		document.SearchText,
		document.SearchTextNormalized,
		document.SearchVariants,
	)
	return err
}

func (r *PGSearchRepository) DeleteDocument(ctx context.Context, domain model.Domain, entityID string, locale string) error {
	_, err := r.pool.Exec(ctx, `
UPDATE search_documents
SET
    visibility = 'hidden',
    updated_at = now(),
    indexed_at = now(),
    deleted_at = now()
WHERE domain = $1
  AND entity_id = $2
  AND locale = $3
`, string(domain), strings.TrimSpace(entityID), normalizeLocale(locale))
	return err
}

func (r *PGSearchRepository) RecordSearchEvent(ctx context.Context, event model.SearchEvent) error {
	metadata, err := json.Marshal(emptyAnyMap(event.Metadata))
	if err != nil {
		return err
	}

	var domain any
	if event.Domain != nil {
		domain = string(*event.Domain)
	}

	_, err = r.pool.Exec(ctx, `
INSERT INTO search_query_events (
    event_type,
    search_session_id,
    query_hash,
    query_length,
    user_id_hash,
    anonymous_id_hash,
    scope,
    domain,
    entity_id,
    result_position,
    locale,
    request_id,
    metadata,
    created_at
) VALUES (
    $1, NULLIF($2, ''), NULLIF($3, ''), $4, NULLIF($5, ''), NULLIF($6, ''),
    $7, $8, NULLIF($9, ''), NULLIF($10, 0), $11, NULLIF($12, ''),
    $13::jsonb, $14
)
`,
		event.EventType,
		event.SearchSessionID,
		event.QueryHash,
		event.QueryLength,
		event.UserIDHash,
		event.AnonymousIDHash,
		string(event.Scope),
		domain,
		event.EntityID,
		event.ResultPosition,
		normalizeLocale(event.Locale),
		event.RequestID,
		string(metadata),
		event.CreatedAt,
	)
	return err
}

func (r *PGSearchRepository) EnqueueDocumentEvent(ctx context.Context, event model.SearchDocumentEvent) error {
	payload := event.Payload
	if len(payload) == 0 {
		payload = json.RawMessage(`{}`)
	}
	_, err := r.pool.Exec(ctx, `
INSERT INTO search_document_events (
    source_service,
    source_event_id,
    aggregate_type,
    aggregate_id,
    event_type,
    payload,
    status,
    attempt_count,
    next_attempt_at,
    created_at
) VALUES (
    $1, $2, $3, $4, $5, $6::jsonb, 'pending', 0, now(), now()
)
ON CONFLICT (source_service, source_event_id) DO NOTHING
`,
		strings.TrimSpace(event.SourceService),
		strings.TrimSpace(event.SourceEventID),
		strings.TrimSpace(event.AggregateType),
		strings.TrimSpace(event.AggregateID),
		strings.TrimSpace(event.EventType),
		string(payload),
	)
	return err
}

func (r *PGSearchRepository) ListDueDocumentEvents(
	ctx context.Context,
	limit int,
	now time.Time,
) ([]model.SearchDocumentEvent, error) {
	if limit <= 0 {
		limit = 50
	}
	if now.IsZero() {
		now = time.Now().UTC()
	}

	rows, err := r.pool.Query(ctx, `
WITH due AS (
    SELECT id
    FROM search_document_events
    WHERE status IN ('pending', 'retry')
      AND next_attempt_at <= $2
    ORDER BY next_attempt_at ASC, created_at ASC
    LIMIT $1
    FOR UPDATE SKIP LOCKED
)
UPDATE search_document_events e
SET status = 'processing'
FROM due
WHERE e.id = due.id
RETURNING
    e.id::text,
    e.source_service,
    e.source_event_id,
    e.aggregate_type,
    e.aggregate_id,
    e.event_type,
    e.payload,
    e.status,
    e.attempt_count,
    e.next_attempt_at,
    e.created_at
`, limit, now)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	events := make([]model.SearchDocumentEvent, 0)
	for rows.Next() {
		var event model.SearchDocumentEvent
		if err := rows.Scan(
			&event.ID,
			&event.SourceService,
			&event.SourceEventID,
			&event.AggregateType,
			&event.AggregateID,
			&event.EventType,
			&event.Payload,
			&event.Status,
			&event.AttemptCount,
			&event.NextAttemptAt,
			&event.CreatedAt,
		); err != nil {
			return nil, err
		}
		events = append(events, event)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	return events, nil
}

func (r *PGSearchRepository) MarkDocumentEventDelivered(ctx context.Context, eventID string, deliveredAt time.Time) error {
	if deliveredAt.IsZero() {
		deliveredAt = time.Now().UTC()
	}
	_, err := r.pool.Exec(ctx, `
UPDATE search_document_events
SET
    status = 'delivered',
    delivered_at = $2,
    last_error = NULL
WHERE id = $1::uuid
`, strings.TrimSpace(eventID), deliveredAt)
	return err
}

func (r *PGSearchRepository) MarkDocumentEventRetry(
	ctx context.Context,
	eventID string,
	reason string,
	nextAttemptAt time.Time,
) error {
	if nextAttemptAt.IsZero() {
		nextAttemptAt = time.Now().UTC()
	}
	_, err := r.pool.Exec(ctx, `
UPDATE search_document_events
SET
    status = 'retry',
    attempt_count = attempt_count + 1,
    next_attempt_at = $2,
    last_error = NULLIF($3, '')
WHERE id = $1::uuid
`, strings.TrimSpace(eventID), nextAttemptAt, strings.TrimSpace(reason))
	return err
}

func (r *PGSearchRepository) MarkDocumentEventDead(
	ctx context.Context,
	eventID string,
	reason string,
	deadAt time.Time,
) error {
	if deadAt.IsZero() {
		deadAt = time.Now().UTC()
	}
	_, err := r.pool.Exec(ctx, `
WITH updated AS (
    UPDATE search_document_events
    SET
        status = 'dead',
        attempt_count = attempt_count + 1,
        dead_at = $2,
        last_error = NULLIF($3, '')
    WHERE id = $1::uuid
    RETURNING
        id,
        source_service,
        source_event_id,
        aggregate_type,
        aggregate_id,
        event_type,
        payload,
        attempt_count,
        last_error,
        dead_at
)
INSERT INTO search_failed_events (
    document_event_id,
    source_service,
    source_event_id,
    aggregate_type,
    aggregate_id,
    event_type,
    payload,
    attempt_count,
    last_error,
    failed_at
)
SELECT
    id,
    source_service,
    source_event_id,
    aggregate_type,
    aggregate_id,
    event_type,
    payload,
    attempt_count,
    last_error,
    dead_at
FROM updated
ON CONFLICT (document_event_id) DO UPDATE SET
    attempt_count = EXCLUDED.attempt_count,
    last_error = EXCLUDED.last_error,
    failed_at = EXCLUDED.failed_at
`, strings.TrimSpace(eventID), deadAt, strings.TrimSpace(reason))
	return err
}

func domainStrings(domains []model.Domain) []string {
	result := make([]string, 0, len(domains))
	for _, domain := range domains {
		result = append(result, string(domain))
	}
	return result
}

func normalizeLocale(locale string) string {
	switch strings.ToLower(strings.TrimSpace(locale)) {
	case "ru", "kk", "en":
		return strings.ToLower(strings.TrimSpace(locale))
	default:
		return "en"
	}
}

func emptyMap(values map[string]string) map[string]string {
	if values == nil {
		return map[string]string{}
	}
	return values
}

func emptyAnyMap(values map[string]any) map[string]any {
	if values == nil {
		return map[string]any{}
	}
	return values
}

func nullIfBlank(value string) any {
	value = strings.TrimSpace(value)
	if value == "" {
		return nil
	}
	return value
}
