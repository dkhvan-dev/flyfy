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
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/dkhvan-dev/flyfy/backend/services/excursion-service/internal/domain/enum"
	"github.com/dkhvan-dev/flyfy/backend/services/excursion-service/internal/domain/model"
	"github.com/dkhvan-dev/flyfy/backend/services/excursion-service/internal/domain/port"
)

type PGExcursionRepository struct {
	pool *pgxpool.Pool
}

func NewPGExcursionRepository(pool *pgxpool.Pool) *PGExcursionRepository {
	return &PGExcursionRepository{pool: pool}
}

const (
	pgUniqueViolation             = "23505"
	activeGuideLandmarkConstraint = "uq_excursions_active_guide_landmark"
)

const excursionSelectColumns = `
	id, guide_profile_id, guide_user_id,
	landmark_id, landmark_name,
	title, summary, description, translations, product_translations, category_slug,
	status, visibility,
	duration_minutes, max_group_size,
	country_code, city_name, meeting_point, latitude, longitude, map_url,
	price_amount, currency,
	published_at, deleted_at, revision, created_at, updated_at
`

const excursionProductCardSelectColumns = `
	id, canonical_key,
	landmark_id, landmark_name,
	title, summary, description, translations, category_slug,
	status, visibility,
	duration_minutes,
	country_code, city_name, latitude, longitude, map_url, cover_file_id,
	min_price_amount, currency, offers_count, published_offers_count, next_available_at,
	created_at, updated_at
`

const excursionOfferSelectColumns = `
	id, product_id, legacy_excursion_id,
	guide_profile_id, guide_user_id,
	guide_rating_avg, guide_reviews_count, guide_experience_years,
	guide_display_name, guide_search_text,
	title, summary, description, translations,
	status, visibility,
	duration_minutes, max_group_size, meeting_point, latitude, longitude, map_url,
	price_amount, currency, cover_file_id,
	published_at, deleted_at, revision, created_at, updated_at
`

type smartSearchTarget func(placeholder string) string

func columnSmartSearchTarget(expression string) smartSearchTarget {
	return func(placeholder string) string {
		return "LOWER(COALESCE(" + expression + "::text, '')) LIKE " + placeholder
	}
}

func templatedSmartSearchTarget(template string) smartSearchTarget {
	return func(placeholder string) string {
		return fmt.Sprintf(template, placeholder)
	}
}

func appendSmartSearchCondition(parts *[]string, args *[]any, argPos int, rawQuery string, targets []smartSearchTarget) int {
	if len(targets) == 0 {
		return argPos
	}
	for _, group := range smartSearchNeedleGroups(rawQuery) {
		conditions := make([]string, 0, len(group)*len(targets))
		for _, needle := range group {
			if needle == "" {
				continue
			}
			for _, target := range targets {
				placeholder := fmt.Sprintf("$%d", argPos)
				conditions = append(conditions, target(placeholder))
				*args = append(*args, "%"+needle+"%")
				argPos++
			}
		}
		if len(conditions) > 0 {
			*parts = append(*parts, " AND ("+strings.Join(conditions, " OR ")+")")
		}
	}
	return argPos
}

func smartSearchNeedleGroups(rawQuery string) [][]string {
	tokens := normalizedSearchTokens(rawQuery)
	groups := make([][]string, 0, len(tokens))
	for _, token := range tokens {
		variants := smartSearchNeedleVariants(token)
		if len(variants) == 0 {
			continue
		}
		groups = append(groups, variants)
	}
	return groups
}

func normalizedSearchTokens(value string) []string {
	value = strings.TrimSpace(strings.ToLower(value))
	if value == "" {
		return nil
	}
	var builder strings.Builder
	lastSpace := false
	for _, r := range value {
		if unicode.IsLetter(r) || unicode.IsDigit(r) {
			builder.WriteRune(r)
			lastSpace = false
			continue
		}
		if !lastSpace && builder.Len() > 0 {
			builder.WriteByte(' ')
			lastSpace = true
		}
	}
	normalized := strings.TrimSpace(builder.String())
	if normalized == "" {
		return nil
	}
	rawTokens := strings.Fields(normalized)
	const maxSearchTokens = 6
	if len(rawTokens) > maxSearchTokens {
		rawTokens = rawTokens[:maxSearchTokens]
	}
	return rawTokens
}

func smartSearchNeedleVariants(token string) []string {
	seen := make(map[string]struct{}, 8)
	var variants []string
	add := func(value string) {
		value = strings.TrimSpace(strings.ToLower(value))
		if value == "" {
			return
		}
		if _, ok := seen[value]; ok {
			return
		}
		seen[value] = struct{}{}
		variants = append(variants, value)
	}

	add(token)
	if hasASCII(token) {
		add(latinToCyrillicSearch(token))
	}
	if hasCyrillic(token) {
		add(cyrillicToLatinSearch(token))
	}
	appendLanguageSearchVariants(add, token)
	return variants
}

func hasASCII(value string) bool {
	for _, r := range value {
		if r >= 'a' && r <= 'z' {
			return true
		}
	}
	return false
}

func hasCyrillic(value string) bool {
	for _, r := range value {
		if unicode.In(r, unicode.Cyrillic) {
			return true
		}
	}
	return false
}

func latinToCyrillicSearch(value string) string {
	value = strings.ToLower(strings.TrimSpace(value))
	if value == "" {
		return ""
	}
	var builder strings.Builder
	for i := 0; i < len(value); {
		remaining := value[i:]
		switch {
		case strings.HasPrefix(remaining, "shch"):
			builder.WriteString("щ")
			i += 4
		case strings.HasPrefix(remaining, "sch"):
			builder.WriteString("щ")
			i += 3
		case strings.HasPrefix(remaining, "nyo"), strings.HasPrefix(remaining, "nio"):
			builder.WriteString("ньо")
			i += 3
		case strings.HasPrefix(remaining, "ch"):
			builder.WriteString("ч")
			i += 2
		case strings.HasPrefix(remaining, "sh"):
			builder.WriteString("ш")
			i += 2
		case strings.HasPrefix(remaining, "zh"):
			builder.WriteString("ж")
			i += 2
		case strings.HasPrefix(remaining, "kh"):
			builder.WriteString("х")
			i += 2
		case strings.HasPrefix(remaining, "gh"):
			builder.WriteString("ғ")
			i += 2
		case strings.HasPrefix(remaining, "ng"):
			builder.WriteString("ң")
			i += 2
		case strings.HasPrefix(remaining, "ya"), strings.HasPrefix(remaining, "ia"):
			builder.WriteString("я")
			i += 2
		case strings.HasPrefix(remaining, "yu"), strings.HasPrefix(remaining, "iu"):
			builder.WriteString("ю")
			i += 2
		case strings.HasPrefix(remaining, "yo"), strings.HasPrefix(remaining, "io"):
			builder.WriteString("ё")
			i += 2
		case strings.HasPrefix(remaining, "ye"):
			builder.WriteString("е")
			i += 2
		default:
			builder.WriteString(latinRuneToCyrillic(value[i]))
			i++
		}
	}
	return builder.String()
}

func latinRuneToCyrillic(ch byte) string {
	switch ch {
	case 'a':
		return "а"
	case 'b':
		return "б"
	case 'c', 'k':
		return "к"
	case 'd':
		return "д"
	case 'e':
		return "е"
	case 'f':
		return "ф"
	case 'g':
		return "г"
	case 'h':
		return "х"
	case 'i':
		return "и"
	case 'j':
		return "ж"
	case 'l':
		return "л"
	case 'm':
		return "м"
	case 'n':
		return "н"
	case 'o':
		return "о"
	case 'p':
		return "п"
	case 'q':
		return "қ"
	case 'r':
		return "р"
	case 's':
		return "с"
	case 't':
		return "т"
	case 'u', 'w':
		return "у"
	case 'v':
		return "в"
	case 'x':
		return "кс"
	case 'y':
		return "ы"
	case 'z':
		return "з"
	default:
		return string(ch)
	}
}

func cyrillicToLatinSearch(value string) string {
	var builder strings.Builder
	for _, r := range strings.ToLower(strings.TrimSpace(value)) {
		switch r {
		case 'а', 'ә':
			builder.WriteString("a")
		case 'б':
			builder.WriteString("b")
		case 'в':
			builder.WriteString("v")
		case 'г', 'ғ':
			builder.WriteString("g")
		case 'д':
			builder.WriteString("d")
		case 'е', 'э':
			builder.WriteString("e")
		case 'ё':
			builder.WriteString("yo")
		case 'ж':
			builder.WriteString("zh")
		case 'з':
			builder.WriteString("z")
		case 'и', 'і':
			builder.WriteString("i")
		case 'й':
			builder.WriteString("y")
		case 'к', 'қ':
			builder.WriteString("k")
		case 'л':
			builder.WriteString("l")
		case 'м':
			builder.WriteString("m")
		case 'н', 'ң':
			builder.WriteString("n")
		case 'о', 'ө':
			builder.WriteString("o")
		case 'п':
			builder.WriteString("p")
		case 'р':
			builder.WriteString("r")
		case 'с':
			builder.WriteString("s")
		case 'т':
			builder.WriteString("t")
		case 'у', 'ұ', 'ү':
			builder.WriteString("u")
		case 'ф':
			builder.WriteString("f")
		case 'х', 'һ':
			builder.WriteString("h")
		case 'ц':
			builder.WriteString("ts")
		case 'ч':
			builder.WriteString("ch")
		case 'ш':
			builder.WriteString("sh")
		case 'щ':
			builder.WriteString("shch")
		case 'ы', 'ь':
			builder.WriteString("y")
		case 'ъ':
		case 'ю':
			builder.WriteString("yu")
		case 'я':
			builder.WriteString("ya")
		default:
			builder.WriteRune(r)
		}
	}
	return builder.String()
}

func appendLanguageSearchVariants(add func(string), token string) {
	switch strings.TrimSpace(strings.ToLower(token)) {
	case "en", "eng", "english", "анг", "английский", "ағылшын":
		add("en")
		add("english")
		add("английский")
		add("ағылшын")
	case "ru", "rus", "russian", "рус", "русский", "орыс":
		add("ru")
		add("russian")
		add("русский")
		add("орыс")
	case "kk", "kz", "kaz", "kazakh", "қазақ", "казахский":
		add("kk")
		add("kz")
		add("kazakh")
		add("қазақ")
		add("казахский")
	case "fr", "fre", "french", "француз", "французский":
		add("fr")
		add("french")
		add("французский")
	case "ja", "jp", "japanese", "япон", "японский", "жапон":
		add("ja")
		add("jp")
		add("japanese")
		add("японский")
		add("жапон")
	case "de", "ger", "german", "немецкий", "неміс":
		add("de")
		add("german")
		add("немецкий")
		add("неміс")
	case "es", "spa", "spanish", "испанский", "испан":
		add("es")
		add("spanish")
		add("испанский")
	case "tr", "tur", "turkish", "турецкий", "түрік":
		add("tr")
		add("turkish")
		add("турецкий")
		add("түрік")
	}
}

func excursionSmartSearchTargets() []smartSearchTarget {
	return []smartSearchTarget{
		columnSmartSearchTarget("excursions.title"),
		columnSmartSearchTarget("excursions.summary"),
		columnSmartSearchTarget("excursions.description"),
		columnSmartSearchTarget("excursions.translations"),
		columnSmartSearchTarget("excursions.product_translations"),
		columnSmartSearchTarget("excursions.landmark_name"),
		columnSmartSearchTarget("excursions.category_slug"),
		columnSmartSearchTarget("excursions.country_code"),
		columnSmartSearchTarget("excursions.city_name"),
		columnSmartSearchTarget("excursions.meeting_point"),
		templatedSmartSearchTarget(`EXISTS (
			SELECT 1 FROM excursion_tags st
			WHERE st.excursion_id = excursions.id
			  AND LOWER(COALESCE(st.tag_slug::text, '')) LIKE %s
		)`),
		templatedSmartSearchTarget(`EXISTS (
			SELECT 1 FROM excursion_languages sl
			WHERE sl.excursion_id = excursions.id
			  AND LOWER(COALESCE(sl.language_code::text, '')) LIKE %s
		)`),
		templatedSmartSearchTarget(`EXISTS (
			SELECT 1 FROM excursion_included_items si
			WHERE si.excursion_id = excursions.id
			  AND (
			    LOWER(COALESCE(si.item_text::text, '')) LIKE %[1]s
			    OR LOWER(COALESCE(si.translations::text, '')) LIKE %[1]s
			  )
		)`),
		templatedSmartSearchTarget(`EXISTS (
			SELECT 1 FROM excursion_itinerary_items sit
			WHERE sit.excursion_id = excursions.id
			  AND (
			    LOWER(COALESCE(sit.title::text, '')) LIKE %[1]s
			    OR LOWER(COALESCE(sit.description::text, '')) LIKE %[1]s
			    OR LOWER(COALESCE(sit.translations::text, '')) LIKE %[1]s
			  )
		)`),
	}
}

func excursionProductSmartSearchTargets() []smartSearchTarget {
	return []smartSearchTarget{
		columnSmartSearchTarget("excursion_products.canonical_key"),
		columnSmartSearchTarget("excursion_products.title"),
		columnSmartSearchTarget("excursion_products.summary"),
		columnSmartSearchTarget("excursion_products.description"),
		columnSmartSearchTarget("excursion_products.translations"),
		columnSmartSearchTarget("excursion_products.landmark_name"),
		columnSmartSearchTarget("excursion_products.category_slug"),
		columnSmartSearchTarget("excursion_products.country_code"),
		columnSmartSearchTarget("excursion_products.city_name"),
		templatedSmartSearchTarget(`EXISTS (
			SELECT 1
			FROM excursion_offers o_search
			WHERE o_search.product_id = excursion_products.id
			  AND o_search.status = 'PUBLISHED'
			  AND o_search.visibility = 'PUBLIC'
			  AND o_search.deleted_at IS NULL
			  AND (
			    LOWER(COALESCE(o_search.title::text, '')) LIKE %[1]s
			    OR LOWER(COALESCE(o_search.summary::text, '')) LIKE %[1]s
			    OR LOWER(COALESCE(o_search.description::text, '')) LIKE %[1]s
			    OR LOWER(COALESCE(o_search.meeting_point::text, '')) LIKE %[1]s
			  )
		)`),
		templatedSmartSearchTarget(`EXISTS (
			SELECT 1
			FROM excursion_offers o_lang
			JOIN excursion_offer_languages l_search ON l_search.offer_id = o_lang.id
			WHERE o_lang.product_id = excursion_products.id
			  AND o_lang.status = 'PUBLISHED'
			  AND o_lang.visibility = 'PUBLIC'
			  AND o_lang.deleted_at IS NULL
			  AND LOWER(COALESCE(l_search.language_code::text, '')) LIKE %s
		)`),
		templatedSmartSearchTarget(`EXISTS (
			SELECT 1
			FROM excursion_offers o_inc
			JOIN excursion_offer_included_items i_search ON i_search.offer_id = o_inc.id
			WHERE o_inc.product_id = excursion_products.id
			  AND o_inc.status = 'PUBLISHED'
			  AND o_inc.visibility = 'PUBLIC'
			  AND o_inc.deleted_at IS NULL
			  AND (
			    LOWER(COALESCE(i_search.item_text::text, '')) LIKE %[1]s
			    OR LOWER(COALESCE(i_search.translations::text, '')) LIKE %[1]s
			  )
		)`),
	}
}

func excursionOfferSmartSearchTargets() []smartSearchTarget {
	return []smartSearchTarget{
		columnSmartSearchTarget("excursion_offers.title"),
		columnSmartSearchTarget("excursion_offers.summary"),
		columnSmartSearchTarget("excursion_offers.description"),
		columnSmartSearchTarget("excursion_offers.translations"),
		columnSmartSearchTarget("excursion_offers.meeting_point"),
		columnSmartSearchTarget("excursion_offers.currency"),
		columnSmartSearchTarget("excursion_offers.guide_user_id"),
		columnSmartSearchTarget("excursion_offers.guide_profile_id"),
		columnSmartSearchTarget("excursion_offers.guide_display_name"),
		columnSmartSearchTarget("excursion_offers.guide_search_text"),
		templatedSmartSearchTarget(`EXISTS (
			SELECT 1
			FROM excursion_offer_languages l_search
			WHERE l_search.offer_id = excursion_offers.id
			  AND LOWER(COALESCE(l_search.language_code::text, '')) LIKE %s
		)`),
		templatedSmartSearchTarget(`EXISTS (
			SELECT 1
			FROM excursion_offer_included_items i_search
			WHERE i_search.offer_id = excursion_offers.id
			  AND (
			    LOWER(COALESCE(i_search.item_text::text, '')) LIKE %[1]s
			    OR LOWER(COALESCE(i_search.translations::text, '')) LIKE %[1]s
			  )
		)`),
	}
}

func (r *PGExcursionRepository) CreateExcursionAggregate(ctx context.Context, item *model.Excursion, relations port.ExcursionRelations) error {
	tx, err := r.pool.BeginTx(ctx, pgx.TxOptions{})
	if err != nil {
		return fmt.Errorf("begin create excursion tx: %w", err)
	}
	defer func() {
		_ = tx.Rollback(ctx)
	}()

	if err = insertExcursion(ctx, tx, item); err != nil {
		return err
	}
	if err = replaceExcursionRelations(ctx, tx, item.ID, relations); err != nil {
		return err
	}
	if err = syncExcursionMarketplace(ctx, tx, item, relations); err != nil {
		return err
	}
	if err = tx.Commit(ctx); err != nil {
		return fmt.Errorf("commit create excursion tx: %w", err)
	}
	return nil
}

func (r *PGExcursionRepository) UpdateExcursionAggregate(ctx context.Context, item *model.Excursion, relations port.ExcursionRelations) error {
	tx, err := r.pool.BeginTx(ctx, pgx.TxOptions{})
	if err != nil {
		return fmt.Errorf("begin update excursion tx: %w", err)
	}
	defer func() {
		_ = tx.Rollback(ctx)
	}()

	if err = updateExcursion(ctx, tx, item); err != nil {
		return err
	}
	if err = replaceExcursionRelations(ctx, tx, item.ID, relations); err != nil {
		return err
	}
	if err = syncExcursionMarketplace(ctx, tx, item, relations); err != nil {
		return err
	}
	if err = tx.Commit(ctx); err != nil {
		return fmt.Errorf("commit update excursion tx: %w", err)
	}
	return nil
}

func (r *PGExcursionRepository) UpdateExcursion(ctx context.Context, item *model.Excursion) error {
	return updateExcursion(ctx, r.pool, item)
}

func (r *PGExcursionRepository) GetExcursionByID(ctx context.Context, excursionID uuid.UUID) (*model.Excursion, error) {
	query := `
		SELECT ` + excursionSelectColumns + `
		FROM excursions
		WHERE id = $1
		LIMIT 1
	`
	item, err := scanExcursion(r.pool.QueryRow(ctx, query, excursionID))
	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, nil
		}
		return nil, fmt.Errorf("get excursion by id: %w", err)
	}
	return item, nil
}

func (r *PGExcursionRepository) HasActiveExcursionForGuideLandmark(ctx context.Context, guideUserID uuid.UUID, landmarkID uuid.UUID) (bool, error) {
	if guideUserID == uuid.Nil || landmarkID == uuid.Nil {
		return false, nil
	}
	const query = `
		SELECT EXISTS (
			SELECT 1
			FROM excursions
			WHERE guide_user_id = $1
				AND landmark_id = $2
				AND deleted_at IS NULL
				AND status <> 'ARCHIVED'
		)
	`
	var exists bool
	if err := r.pool.QueryRow(ctx, query, guideUserID, landmarkID).Scan(&exists); err != nil {
		return false, fmt.Errorf("check guide landmark excursion: %w", err)
	}
	return exists, nil
}

func (r *PGExcursionRepository) ListExcursions(ctx context.Context, filter port.ExcursionFilter) ([]*model.Excursion, error) {
	base := `
		SELECT ` + excursionSelectColumns + `
		FROM excursions
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
				SELECT 1 FROM excursion_languages tl
				WHERE tl.excursion_id = excursions.id AND tl.language_code = $%d
			)
		`, argPos))
		args = append(args, strings.ToLower(strings.TrimSpace(*filter.LanguageCode)))
		argPos++
	}
	if filter.SearchQuery != nil && strings.TrimSpace(*filter.SearchQuery) != "" {
		argPos = appendSmartSearchCondition(&parts, &args, argPos, *filter.SearchQuery, excursionSmartSearchTargets())
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
		return nil, fmt.Errorf("list excursions: %w", err)
	}
	defer rows.Close()

	items := make([]*model.Excursion, 0)
	for rows.Next() {
		item, scanErr := scanExcursion(rows)
		if scanErr != nil {
			return nil, fmt.Errorf("scan listed excursion: %w", scanErr)
		}
		items = append(items, item)
	}
	return items, rows.Err()
}

func (r *PGExcursionRepository) LoadExcursionRelations(ctx context.Context, excursionID uuid.UUID) (port.ExcursionRelations, error) {
	tags, err := r.listStrings(ctx, "excursion_tags", "tag_slug", excursionID)
	if err != nil {
		return port.ExcursionRelations{}, err
	}
	languages, err := r.listStrings(ctx, "excursion_languages", "language_code", excursionID)
	if err != nil {
		return port.ExcursionRelations{}, err
	}
	includedItems, err := r.listIncludedItems(ctx, "excursion_included_items", "excursion_id", excursionID)
	if err != nil {
		return port.ExcursionRelations{}, err
	}
	itinerary, err := r.listItinerary(ctx, excursionID)
	if err != nil {
		return port.ExcursionRelations{}, err
	}
	coverFileID, err := r.getCoverFileID(ctx, excursionID)
	if err != nil {
		return port.ExcursionRelations{}, err
	}
	return port.ExcursionRelations{
		Tags:          tags,
		LanguageCodes: languages,
		IncludedItems: includedItems,
		Itinerary:     itinerary,
		CoverFileID:   coverFileID,
	}, nil
}

func (r *PGExcursionRepository) CreateExcursionEvent(ctx context.Context, item *model.ExcursionEvent) error {
	const query = `
		INSERT INTO excursion_events (id, excursion_id, event_type, actor_user_id, payload, created_at)
		VALUES ($1, $2, $3, $4, $5::jsonb, $6)
	`
	_, err := r.pool.Exec(
		ctx,
		query,
		item.ID,
		item.ExcursionID,
		string(item.EventType),
		item.ActorUserID,
		string(item.PayloadJSON),
		item.CreatedAt,
	)
	if err != nil {
		return fmt.Errorf("insert excursion event: %w", err)
	}
	return nil
}

func (r *PGExcursionRepository) ListExcursionProductCards(ctx context.Context, filter port.ExcursionProductFilter) ([]*model.ExcursionProductCard, error) {
	base := `
		SELECT ` + excursionProductCardSelectColumns + `
		FROM excursion_products
		WHERE status = 'PUBLISHED' AND visibility = 'PUBLIC'
	`
	parts := []string{base}
	args := make([]any, 0, 10)
	argPos := 1

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
				SELECT 1
				FROM excursion_offers o
				JOIN excursion_offer_languages l ON l.offer_id = o.id
				WHERE o.product_id = excursion_products.id
				  AND o.status = 'PUBLISHED'
				  AND o.visibility = 'PUBLIC'
				  AND o.deleted_at IS NULL
				  AND l.language_code = $%d
			)
		`, argPos))
		args = append(args, strings.ToLower(strings.TrimSpace(*filter.LanguageCode)))
		argPos++
	}
	if filter.SearchQuery != nil && strings.TrimSpace(*filter.SearchQuery) != "" {
		argPos = appendSmartSearchCondition(&parts, &args, argPos, *filter.SearchQuery, excursionProductSmartSearchTargets())
	}
	if filter.PriceMin != nil {
		parts = append(parts, fmt.Sprintf(" AND min_price_amount >= $%d", argPos))
		args = append(args, *filter.PriceMin)
		argPos++
	}
	if filter.PriceMax != nil {
		parts = append(parts, fmt.Sprintf(" AND min_price_amount <= $%d", argPos))
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
		parts = append(parts, fmt.Sprintf(`
			AND EXISTS (
				SELECT 1
				FROM excursion_offers o
				WHERE o.product_id = excursion_products.id
				  AND o.status = 'PUBLISHED'
				  AND o.visibility = 'PUBLIC'
				  AND o.deleted_at IS NULL
				  AND o.max_group_size >= $%d
			)
		`, argPos))
		args = append(args, *filter.MaxGroupSizeMin)
		argPos++
	}

	if filter.Limit <= 0 {
		filter.Limit = 20
	}
	if filter.Offset < 0 {
		filter.Offset = 0
	}

	parts = append(parts, " ORDER BY published_offers_count DESC, updated_at DESC")
	parts = append(parts, fmt.Sprintf(" LIMIT $%d OFFSET $%d", argPos, argPos+1))
	args = append(args, filter.Limit, filter.Offset)

	rows, err := r.pool.Query(ctx, strings.Join(parts, ""), args...)
	if err != nil {
		return nil, fmt.Errorf("list excursion products: %w", err)
	}
	defer rows.Close()

	items := make([]*model.ExcursionProductCard, 0)
	for rows.Next() {
		item, scanErr := scanExcursionProductCard(rows)
		if scanErr != nil {
			return nil, fmt.Errorf("scan excursion product: %w", scanErr)
		}
		items = append(items, item)
	}
	return items, rows.Err()
}

func (r *PGExcursionRepository) GetExcursionProductCardByID(ctx context.Context, productID uuid.UUID) (*model.ExcursionProductCard, error) {
	query := `
		SELECT ` + excursionProductCardSelectColumns + `
		FROM excursion_products
		WHERE id = $1 AND status = 'PUBLISHED' AND visibility <> 'PRIVATE'
		LIMIT 1
	`
	item, err := scanExcursionProductCard(r.pool.QueryRow(ctx, query, productID))
	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, nil
		}
		return nil, fmt.Errorf("get excursion product: %w", err)
	}
	return item, nil
}

func (r *PGExcursionRepository) ListExcursionOffers(ctx context.Context, filter port.ExcursionOfferFilter) ([]*model.ExcursionOffer, error) {
	base := `
		SELECT ` + excursionOfferSelectColumns + `
		FROM excursion_offers
		WHERE product_id = $1
		  AND status = 'PUBLISHED'
		  AND visibility = 'PUBLIC'
		  AND deleted_at IS NULL
	`
	parts := []string{base}
	args := []any{filter.ProductID}
	argPos := 2

	if filter.LanguageCode != nil && strings.TrimSpace(*filter.LanguageCode) != "" {
		parts = append(parts, fmt.Sprintf(`
			AND EXISTS (
				SELECT 1
				FROM excursion_offer_languages l
				WHERE l.offer_id = excursion_offers.id AND l.language_code = $%d
			)
		`, argPos))
		args = append(args, strings.ToLower(strings.TrimSpace(*filter.LanguageCode)))
		argPos++
	}
	if filter.SearchQuery != nil && strings.TrimSpace(*filter.SearchQuery) != "" {
		argPos = appendSmartSearchCondition(&parts, &args, argPos, *filter.SearchQuery, excursionOfferSmartSearchTargets())
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

	orderPrefix := ""
	if filter.PreferredGuideUserID != nil {
		orderPrefix = fmt.Sprintf("(guide_user_id = $%d) DESC, ", argPos)
		args = append(args, *filter.PreferredGuideUserID)
		argPos++
	}
	parts = append(parts, " ORDER BY "+orderPrefix+excursionOfferOrderBy(filter.Sort, filter.SortDirection))
	parts = append(parts, fmt.Sprintf(" LIMIT $%d OFFSET $%d", argPos, argPos+1))
	args = append(args, filter.Limit, filter.Offset)

	rows, err := r.pool.Query(ctx, strings.Join(parts, ""), args...)
	if err != nil {
		return nil, fmt.Errorf("list excursion offers: %w", err)
	}
	defer rows.Close()

	items := make([]*model.ExcursionOffer, 0)
	for rows.Next() {
		item, scanErr := scanExcursionOffer(rows)
		if scanErr != nil {
			return nil, fmt.Errorf("scan excursion offer: %w", scanErr)
		}
		items = append(items, item)
	}
	return items, rows.Err()
}

func (r *PGExcursionRepository) ListExcursionLanguageCodesByGuideUserIDs(ctx context.Context, guideUserIDs []uuid.UUID) (map[uuid.UUID][]string, error) {
	if len(guideUserIDs) == 0 {
		return map[uuid.UUID][]string{}, nil
	}

	placeholders := make([]string, 0, len(guideUserIDs))
	args := make([]any, 0, len(guideUserIDs))
	for _, guideUserID := range guideUserIDs {
		if guideUserID == uuid.Nil {
			continue
		}
		placeholders = append(placeholders, fmt.Sprintf("$%d", len(args)+1))
		args = append(args, guideUserID)
	}
	if len(args) == 0 {
		return map[uuid.UUID][]string{}, nil
	}

	query := `
		SELECT source.guide_user_id, source.language_code
		FROM (
			SELECT o.guide_user_id, l.language_code, l.sort_order
			FROM excursions o
			JOIN excursion_languages l ON l.excursion_id = o.id
			WHERE o.guide_user_id IN (` + strings.Join(placeholders, ",") + `)
			  AND o.deleted_at IS NULL

			UNION ALL

			SELECT o.guide_user_id, l.language_code, l.sort_order
			FROM excursion_offers o
			JOIN excursion_offer_languages l ON l.offer_id = o.id
			WHERE o.guide_user_id IN (` + strings.Join(placeholders, ",") + `)
			  AND o.deleted_at IS NULL
		) source
		GROUP BY source.guide_user_id, source.language_code
		ORDER BY source.guide_user_id, MIN(source.sort_order), source.language_code
	`
	rows, err := r.pool.Query(ctx, query, args...)
	if err != nil {
		return nil, fmt.Errorf("list guide excursion languages: %w", err)
	}
	defer rows.Close()

	result := make(map[uuid.UUID][]string, len(guideUserIDs))
	for rows.Next() {
		var guideUserID uuid.UUID
		var languageCode string
		if err = rows.Scan(&guideUserID, &languageCode); err != nil {
			return nil, fmt.Errorf("scan guide excursion language: %w", err)
		}
		languageCode = strings.ToLower(strings.TrimSpace(languageCode))
		if languageCode == "" {
			continue
		}
		result[guideUserID] = append(result[guideUserID], languageCode)
	}
	if err = rows.Err(); err != nil {
		return nil, err
	}
	return result, nil
}

func excursionOfferOrderBy(sort string, direction string) string {
	dir := "DESC"
	if strings.EqualFold(strings.TrimSpace(direction), "asc") {
		dir = "ASC"
	}
	switch strings.ToLower(strings.TrimSpace(sort)) {
	case "price", "price_asc", "price_desc":
		if strings.EqualFold(strings.TrimSpace(sort), "price_asc") {
			dir = "ASC"
		}
		if strings.EqualFold(strings.TrimSpace(sort), "price_desc") {
			dir = "DESC"
		}
		return "price_amount " + dir + ", guide_rating_avg DESC, guide_reviews_count DESC, updated_at DESC"
	case "experience", "experience_asc", "experience_desc", "group_size_desc":
		if strings.EqualFold(strings.TrimSpace(sort), "experience_asc") {
			dir = "ASC"
		}
		if strings.EqualFold(strings.TrimSpace(sort), "experience_desc") ||
			strings.EqualFold(strings.TrimSpace(sort), "group_size_desc") {
			dir = "DESC"
		}
		return "guide_experience_years " + dir + ", guide_rating_avg DESC, guide_reviews_count DESC, price_amount ASC, updated_at DESC"
	default:
		return "guide_rating_avg " + dir + ", guide_reviews_count DESC, price_amount ASC, updated_at DESC"
	}
}

func (r *PGExcursionRepository) GetExcursionOfferByID(ctx context.Context, offerID uuid.UUID) (*model.ExcursionOffer, error) {
	query := `
		SELECT ` + excursionOfferSelectColumns + `
		FROM excursion_offers
		WHERE id = $1
		LIMIT 1
	`
	item, err := scanExcursionOffer(r.pool.QueryRow(ctx, query, offerID))
	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, nil
		}
		return nil, fmt.Errorf("get excursion offer by id: %w", err)
	}
	return item, nil
}

func (r *PGExcursionRepository) LoadExcursionOfferRelations(ctx context.Context, offerID uuid.UUID) (port.ExcursionOfferRelations, error) {
	languages, err := r.listOfferStrings(ctx, "excursion_offer_languages", "language_code", offerID)
	if err != nil {
		return port.ExcursionOfferRelations{}, err
	}
	includedItems, err := r.listIncludedItems(ctx, "excursion_offer_included_items", "offer_id", offerID)
	if err != nil {
		return port.ExcursionOfferRelations{}, err
	}
	legacyExcursionID, err := r.legacyExcursionIDForOffer(ctx, offerID)
	if err != nil {
		return port.ExcursionOfferRelations{}, err
	}
	var itinerary []*model.ExcursionItineraryItem
	if legacyExcursionID != nil && *legacyExcursionID != uuid.Nil {
		itinerary, err = r.listItinerary(ctx, *legacyExcursionID)
		if err != nil {
			return port.ExcursionOfferRelations{}, err
		}
	}
	return port.ExcursionOfferRelations{LanguageCodes: languages, IncludedItems: includedItems, Itinerary: itinerary}, nil
}

func (r *PGExcursionRepository) CreateExcursionBooking(ctx context.Context, item *model.ExcursionBooking) error {
	const query = `
		INSERT INTO excursion_bookings (
			id,
			product_id, offer_id, legacy_excursion_id,
			guide_profile_id, guide_user_id, tourist_user_id,
			scheduled_for, adults, children, total_seats,
			unit_price_amount, service_fee_amount, total_price_amount, currency,
			status, idempotency_key, cancelled_at, cancel_reason,
			created_at, updated_at
		) VALUES (
			$1,
			$2, $3, $4,
			$5, $6, $7,
			$8, $9, $10, $11,
			$12, $13, $14, $15,
			$16, $17, $18, $19,
			$20, $21
		)
	`
	_, err := r.pool.Exec(
		ctx,
		query,
		item.ID,
		item.ProductID,
		item.OfferID,
		item.LegacyExcursionID,
		item.GuideProfileID,
		item.GuideUserID,
		item.TouristUserID,
		item.ScheduledFor,
		item.Adults,
		item.Children,
		item.TotalSeats,
		item.UnitPriceAmount,
		item.ServiceFeeAmount,
		item.TotalPriceAmount,
		item.Currency,
		string(item.Status),
		item.IdempotencyKey,
		item.CancelledAt,
		item.CancelReason,
		item.CreatedAt,
		item.UpdatedAt,
	)
	if err != nil {
		return fmt.Errorf("insert excursion booking: %w", err)
	}
	return nil
}

func (r *PGExcursionRepository) ListExcursionBookings(ctx context.Context, filter port.ExcursionBookingFilter) ([]*model.ExcursionBookingListItem, error) {
	const query = `
		SELECT
			b.id,
			b.product_id, b.offer_id, b.legacy_excursion_id,
			b.guide_profile_id, b.guide_user_id, b.tourist_user_id,
			b.scheduled_for, b.adults, b.children, b.total_seats,
			b.unit_price_amount, b.service_fee_amount, b.total_price_amount, b.currency,
			b.status, b.idempotency_key, b.cancelled_at, b.cancel_reason,
			b.created_at, b.updated_at,
			COALESCE(NULLIF(o.title, ''), p.title),
			COALESCE(NULLIF(o.summary, ''), p.summary),
			p.landmark_id, p.landmark_name, p.category_slug, p.country_code, p.city_name,
			COALESCE(o.cover_file_id, p.cover_file_id),
			o.guide_display_name,
			r.id, r.booking_id, r.product_id, r.offer_id, r.legacy_excursion_id,
			r.landmark_id, r.landmark_name,
			r.guide_profile_id, r.guide_user_id, r.guide_display_name, r.tourist_user_id,
			r.rating, r.comment, r.created_at, r.updated_at
		FROM excursion_bookings b
		JOIN excursion_products p ON p.id = b.product_id
		JOIN excursion_offers o ON o.id = b.offer_id
		LEFT JOIN excursion_reviews r ON r.booking_id = b.id
		WHERE b.tourist_user_id = $1
		ORDER BY
			CASE WHEN r.id IS NULL THEN 0 ELSE 1 END ASC,
			b.scheduled_for DESC,
			b.created_at DESC,
			b.id ASC
		LIMIT $2 OFFSET $3
	`
	rows, err := r.pool.Query(ctx, query, filter.TouristUserID, filter.Limit, filter.Offset)
	if err != nil {
		return nil, fmt.Errorf("query excursion bookings: %w", err)
	}
	defer rows.Close()

	items := make([]*model.ExcursionBookingListItem, 0)
	for rows.Next() {
		item, scanErr := scanExcursionBookingListItem(rows)
		if scanErr != nil {
			return nil, scanErr
		}
		items = append(items, item)
	}
	if err = rows.Err(); err != nil {
		return nil, fmt.Errorf("iterate excursion bookings: %w", err)
	}
	return items, nil
}

func (r *PGExcursionRepository) GetExcursionBookingByID(ctx context.Context, bookingID uuid.UUID) (*model.ExcursionBooking, error) {
	const query = `
		SELECT
			id,
			product_id, offer_id, legacy_excursion_id,
			guide_profile_id, guide_user_id, tourist_user_id,
			scheduled_for, adults, children, total_seats,
			unit_price_amount, service_fee_amount, total_price_amount, currency,
			status, idempotency_key, cancelled_at, cancel_reason,
			created_at, updated_at
		FROM excursion_bookings
		WHERE id = $1
	`
	item, err := scanExcursionBooking(r.pool.QueryRow(ctx, query, bookingID))
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, fmt.Errorf("get excursion booking: %w", err)
	}
	return item, nil
}

func (r *PGExcursionRepository) CreateExcursionReview(ctx context.Context, item *model.ExcursionReview) error {
	const query = `
		INSERT INTO excursion_reviews (
			id,
			booking_id, product_id, offer_id, legacy_excursion_id,
			landmark_id, landmark_name,
			guide_profile_id, guide_user_id, guide_display_name, tourist_user_id,
			rating, comment, created_at, updated_at
		)
		SELECT
			$1,
			$2, $3, $4, $5,
			p.landmark_id, p.landmark_name,
			$6, $7, o.guide_display_name, $8,
			$9, $10, $11, $12
		FROM excursion_products p
		JOIN excursion_offers o ON o.id = $4 AND o.product_id = p.id
		WHERE p.id = $3
		RETURNING landmark_id, landmark_name, guide_display_name
	`
	err := r.pool.QueryRow(
		ctx,
		query,
		item.ID,
		item.BookingID,
		item.ProductID,
		item.OfferID,
		item.LegacyExcursionID,
		item.GuideProfileID,
		item.GuideUserID,
		item.TouristUserID,
		item.Rating,
		item.Comment,
		item.CreatedAt,
		item.UpdatedAt,
	).Scan(&item.LandmarkID, &item.LandmarkName, &item.GuideDisplayName)
	if err != nil {
		if isExcursionReviewUniqueViolation(err) {
			return model.ErrExcursionReviewAlreadyExists
		}
		return fmt.Errorf("insert excursion review: %w", err)
	}
	return nil
}

func (r *PGExcursionRepository) GetExcursionReviewByBookingID(ctx context.Context, bookingID uuid.UUID) (*model.ExcursionReview, error) {
	const query = `
		SELECT
			id, booking_id, product_id, offer_id, legacy_excursion_id,
			landmark_id, landmark_name,
			guide_profile_id, guide_user_id, guide_display_name, tourist_user_id,
			rating, comment, created_at, updated_at
		FROM excursion_reviews
		WHERE booking_id = $1
	`
	item, err := scanExcursionReview(r.pool.QueryRow(ctx, query, bookingID))
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, fmt.Errorf("get excursion review: %w", err)
	}
	return item, nil
}

func (r *PGExcursionRepository) ListExcursionReviews(ctx context.Context, filter port.ExcursionReviewFilter) ([]*model.ExcursionReview, error) {
	const query = `
		SELECT
			id, booking_id, product_id, offer_id, legacy_excursion_id,
			landmark_id, landmark_name,
			guide_profile_id, guide_user_id, guide_display_name, tourist_user_id,
			rating, comment, created_at, updated_at
		FROM excursion_reviews
		WHERE ($1::uuid IS NULL OR product_id = $1)
		  AND ($2::uuid IS NULL OR landmark_id = $2)
		ORDER BY created_at DESC, id ASC
		LIMIT $3 OFFSET $4
	`
	rows, err := r.pool.Query(ctx, query, filter.ProductID, filter.LandmarkID, filter.Limit, filter.Offset)
	if err != nil {
		return nil, fmt.Errorf("query excursion reviews: %w", err)
	}
	defer rows.Close()

	items := make([]*model.ExcursionReview, 0)
	for rows.Next() {
		item, scanErr := scanExcursionReview(rows)
		if scanErr != nil {
			return nil, scanErr
		}
		items = append(items, item)
	}
	if err = rows.Err(); err != nil {
		return nil, fmt.Errorf("iterate excursion reviews: %w", err)
	}
	return items, nil
}

type dbExecutor interface {
	Exec(ctx context.Context, sql string, arguments ...any) (pgconn.CommandTag, error)
	QueryRow(ctx context.Context, sql string, args ...any) pgx.Row
}

func insertExcursion(ctx context.Context, exec dbExecutor, item *model.Excursion) error {
	const query = `
		INSERT INTO excursions (
			id, guide_profile_id, guide_user_id,
			landmark_id, landmark_name,
			title, summary, description, category_slug,
			status, visibility,
			duration_minutes, max_group_size,
			country_code, city_name, meeting_point, latitude, longitude, map_url,
			price_amount, currency,
			published_at, deleted_at, revision, created_at, updated_at,
			translations, product_translations
		) VALUES (
			$1, $2, $3,
			$4, $5,
			$6, $7, $8, $9,
			$10, $11,
			$12, $13,
			$14, $15, $16, $17, $18, $19,
			$20, $21,
			$22, $23, $24, $25, $26,
			$27::jsonb, $28::jsonb
		)
	`
	_, err := exec.Exec(ctx, query, excursionArgs(item)...)
	if err != nil {
		if isGuideLandmarkUniqueViolation(err) {
			return model.ErrExcursionGuideLandmarkAlreadyExists
		}
		return fmt.Errorf("insert excursion: %w", err)
	}
	return nil
}

func isGuideLandmarkUniqueViolation(err error) bool {
	var pgErr *pgconn.PgError
	return errors.As(err, &pgErr) &&
		pgErr.Code == pgUniqueViolation &&
		pgErr.ConstraintName == activeGuideLandmarkConstraint
}

func isExcursionReviewUniqueViolation(err error) bool {
	var pgErr *pgconn.PgError
	return errors.As(err, &pgErr) &&
		pgErr.Code == pgUniqueViolation &&
		pgErr.ConstraintName == "idx_excursion_reviews_booking"
}

func updateExcursion(ctx context.Context, exec dbExecutor, item *model.Excursion) error {
	const query = `
		UPDATE excursions
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
			updated_at = $25,
			translations = $26::jsonb,
			product_translations = $27::jsonb
		WHERE id = $1
	`
	tag, err := exec.Exec(ctx, query, updateExcursionArgs(item)...)
	if err != nil {
		if isGuideLandmarkUniqueViolation(err) {
			return model.ErrExcursionGuideLandmarkAlreadyExists
		}
		return fmt.Errorf("update excursion: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return nil
	}
	return nil
}

func excursionArgs(item *model.Excursion) []any {
	return []any{
		item.ID,
		item.GuideProfileID,
		item.GuideUserID,
		item.LandmarkID,
		item.LandmarkName,
		marketplaceProductTitle(item),
		marketplaceProductSummary(item),
		marketplaceProductDescription(item),
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
		excursionTranslationsJSON(item.Translations),
		excursionTranslationsJSON(item.ProductTranslations),
	}
}

func updateExcursionArgs(item *model.Excursion) []any {
	return []any{
		item.ID,
		item.GuideProfileID,
		item.GuideUserID,
		item.LandmarkID,
		item.LandmarkName,
		marketplaceProductTitle(item),
		marketplaceProductSummary(item),
		marketplaceProductDescription(item),
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
		excursionTranslationsJSON(item.Translations),
		excursionTranslationsJSON(item.ProductTranslations),
	}
}

func replaceExcursionRelations(ctx context.Context, tx pgx.Tx, excursionID uuid.UUID, relations port.ExcursionRelations) error {
	if err := replaceStrings(ctx, tx, "excursion_tags", "tag_slug", excursionID, relations.Tags); err != nil {
		return err
	}
	if err := replaceStrings(ctx, tx, "excursion_languages", "language_code", excursionID, relations.LanguageCodes); err != nil {
		return err
	}
	if err := replaceIncludedItems(ctx, tx, "excursion_included_items", "excursion_id", excursionID, relations.IncludedItems); err != nil {
		return err
	}
	if err := replaceItinerary(ctx, tx, excursionID, relations.Itinerary); err != nil {
		return err
	}
	return replaceCover(ctx, tx, excursionID, relations.CoverFileID)
}

func replaceStrings(ctx context.Context, tx pgx.Tx, table string, column string, excursionID uuid.UUID, values []string) error {
	if _, err := tx.Exec(ctx, fmt.Sprintf("DELETE FROM %s WHERE excursion_id = $1", table), excursionID); err != nil {
		return fmt.Errorf("delete %s: %w", table, err)
	}
	for index, value := range values {
		value = strings.TrimSpace(value)
		if value == "" {
			continue
		}
		query := fmt.Sprintf(
			"INSERT INTO %s (id, excursion_id, %s, sort_order, created_at) VALUES ($1, $2, $3, $4, $5)",
			table,
			column,
		)
		if _, err := tx.Exec(ctx, query, uuid.New(), excursionID, value, index, time.Now().UTC()); err != nil {
			return fmt.Errorf("insert %s: %w", table, err)
		}
	}
	return nil
}

func replaceIncludedItems(ctx context.Context, exec dbExecutor, table string, parentColumn string, parentID uuid.UUID, values []model.ExcursionIncludedItem) error {
	if _, err := exec.Exec(ctx, fmt.Sprintf("DELETE FROM %s WHERE %s = $1", table, parentColumn), parentID); err != nil {
		return fmt.Errorf("delete %s: %w", table, err)
	}
	for index, value := range values {
		text := strings.TrimSpace(value.Text)
		if text == "" {
			continue
		}
		query := fmt.Sprintf(
			"INSERT INTO %s (id, %s, item_text, translations, sort_order, created_at) VALUES ($1, $2, $3, $4::jsonb, $5, $6)",
			table,
			parentColumn,
		)
		if _, err := exec.Exec(ctx, query, uuid.New(), parentID, text, excursionLocalizedTextJSON(value.Translations), index, time.Now().UTC()); err != nil {
			return fmt.Errorf("insert %s: %w", table, err)
		}
	}
	return nil
}

func replaceItinerary(ctx context.Context, tx pgx.Tx, excursionID uuid.UUID, items []*model.ExcursionItineraryItem) error {
	if _, err := tx.Exec(ctx, "DELETE FROM excursion_itinerary_items WHERE excursion_id = $1", excursionID); err != nil {
		return fmt.Errorf("delete excursion itinerary: %w", err)
	}
	for _, item := range items {
		const query = `
			INSERT INTO excursion_itinerary_items (
				id, excursion_id, sort_order, start_offset_minutes, duration_minutes,
				title, description, translations, created_at, updated_at
			) VALUES ($1, $2, $3, $4, $5, $6, $7, $8::jsonb, $9, $10)
		`
		if _, err := tx.Exec(
			ctx,
			query,
			item.ID,
			excursionID,
			item.SortOrder,
			item.StartOffsetMinutes,
			item.DurationMinutes,
			item.Title,
			item.Description,
			excursionItineraryTranslationsJSON(item.Translations),
			item.CreatedAt,
			item.UpdatedAt,
		); err != nil {
			return fmt.Errorf("insert excursion itinerary: %w", err)
		}
	}
	return nil
}

func replaceCover(ctx context.Context, tx pgx.Tx, excursionID uuid.UUID, coverFileID *uuid.UUID) error {
	if _, err := tx.Exec(ctx, "DELETE FROM excursion_covers WHERE excursion_id = $1", excursionID); err != nil {
		return fmt.Errorf("delete excursion cover: %w", err)
	}
	if coverFileID == nil || *coverFileID == uuid.Nil {
		return nil
	}
	const query = `
		INSERT INTO excursion_covers (id, excursion_id, file_id, created_at)
		VALUES ($1, $2, $3, $4)
	`
	if _, err := tx.Exec(ctx, query, uuid.New(), excursionID, *coverFileID, time.Now().UTC()); err != nil {
		return fmt.Errorf("insert excursion cover: %w", err)
	}
	return nil
}

func syncExcursionMarketplace(ctx context.Context, exec dbExecutor, item *model.Excursion, relations port.ExcursionRelations) error {
	productCoverFileID := relations.ProductCoverFileID
	if productCoverFileID == nil && item.LandmarkID == nil {
		productCoverFileID = relations.CoverFileID
	}
	productID, err := upsertExcursionProduct(ctx, exec, item, productCoverFileID)
	if err != nil {
		return err
	}
	offerID, err := upsertExcursionOffer(ctx, exec, productID, item, relations.CoverFileID)
	if err != nil {
		return err
	}
	if err = replaceOfferStrings(ctx, exec, "excursion_offer_languages", "language_code", offerID, relations.LanguageCodes); err != nil {
		return err
	}
	if err = replaceIncludedItems(ctx, exec, "excursion_offer_included_items", "offer_id", offerID, relations.IncludedItems); err != nil {
		return err
	}
	return refreshExcursionProductStats(ctx, exec, productID)
}

func upsertExcursionProduct(ctx context.Context, exec dbExecutor, item *model.Excursion, coverFileID *uuid.UUID) (uuid.UUID, error) {
	const query = `
		INSERT INTO excursion_products (
			id, canonical_key,
			landmark_id, landmark_name,
			title, summary, description, category_slug,
			status, visibility,
			duration_minutes,
			country_code, city_name, latitude, longitude, map_url, cover_file_id,
			created_at, updated_at, translations
		) VALUES (
			$1, $2,
			$3, $4,
			$5, $6, $7, $8,
			$9, $10,
			$11,
			$12, $13, $14, $15, $16, $17,
			$18, $19, $20::jsonb
		)
		ON CONFLICT (canonical_key) DO UPDATE
		SET
			landmark_id = COALESCE(excursion_products.landmark_id, EXCLUDED.landmark_id),
			landmark_name = COALESCE(excursion_products.landmark_name, EXCLUDED.landmark_name),
			title = CASE WHEN excursion_products.published_offers_count = 0 THEN EXCLUDED.title ELSE excursion_products.title END,
			summary = CASE WHEN excursion_products.published_offers_count = 0 THEN EXCLUDED.summary ELSE excursion_products.summary END,
			description = CASE WHEN excursion_products.published_offers_count = 0 THEN EXCLUDED.description ELSE excursion_products.description END,
			translations = CASE WHEN excursion_products.published_offers_count = 0 THEN EXCLUDED.translations ELSE excursion_products.translations END,
			category_slug = CASE WHEN excursion_products.published_offers_count = 0 THEN EXCLUDED.category_slug ELSE excursion_products.category_slug END,
			status = CASE
				WHEN excursion_products.status = 'PUBLISHED' OR EXCLUDED.status = 'PUBLISHED' THEN 'PUBLISHED'
				ELSE EXCLUDED.status
			END,
			visibility = CASE
				WHEN excursion_products.visibility = 'PUBLIC' OR EXCLUDED.visibility = 'PUBLIC' THEN 'PUBLIC'
				ELSE EXCLUDED.visibility
			END,
			duration_minutes = CASE WHEN excursion_products.published_offers_count = 0 THEN EXCLUDED.duration_minutes ELSE excursion_products.duration_minutes END,
			country_code = COALESCE(excursion_products.country_code, EXCLUDED.country_code),
			city_name = COALESCE(excursion_products.city_name, EXCLUDED.city_name),
			latitude = COALESCE(excursion_products.latitude, EXCLUDED.latitude),
			longitude = COALESCE(excursion_products.longitude, EXCLUDED.longitude),
			map_url = COALESCE(excursion_products.map_url, EXCLUDED.map_url),
			cover_file_id = COALESCE(excursion_products.cover_file_id, EXCLUDED.cover_file_id),
			updated_at = NOW()
		RETURNING id
	`
	productID := uuid.New()
	var persistedID uuid.UUID
	if err := exec.QueryRow(
		ctx,
		query,
		productID,
		excursionMarketplaceCanonicalKey(item),
		item.LandmarkID,
		item.LandmarkName,
		marketplaceProductTitle(item),
		marketplaceProductSummary(item),
		marketplaceProductDescription(item),
		item.CategorySlug,
		marketplaceProductStatus(item),
		string(item.Visibility),
		item.DurationMinutes,
		item.CountryCode,
		item.CityName,
		item.Latitude,
		item.Longitude,
		item.MapURL,
		coverFileID,
		item.CreatedAt,
		item.UpdatedAt,
		excursionTranslationsJSON(item.ProductTranslations),
	).Scan(&persistedID); err != nil {
		return uuid.Nil, fmt.Errorf("upsert excursion product: %w", err)
	}
	return persistedID, nil
}

func upsertExcursionOffer(ctx context.Context, exec dbExecutor, productID uuid.UUID, item *model.Excursion, coverFileID *uuid.UUID) (uuid.UUID, error) {
	const query = `
		INSERT INTO excursion_offers (
			id, product_id, legacy_excursion_id,
			guide_profile_id, guide_user_id,
			guide_rating_avg, guide_reviews_count, guide_experience_years,
			guide_display_name, guide_search_text,
			title, summary, description,
			status, visibility,
			duration_minutes, max_group_size, meeting_point, latitude, longitude, map_url,
			price_amount, currency, cover_file_id,
			published_at, deleted_at, revision, created_at, updated_at, translations
		) VALUES (
			$1, $2, $3,
			$4, $5,
			$6, $7, $8,
			$9, $10,
			$11, $12, $13,
			$14, $15,
			$16, $17, $18, $19, $20, $21,
			$22, $23, $24,
			$25, $26, $27, $28, $29, $30::jsonb
		)
		ON CONFLICT (legacy_excursion_id) DO UPDATE
		SET
			product_id = EXCLUDED.product_id,
			guide_profile_id = EXCLUDED.guide_profile_id,
			guide_user_id = EXCLUDED.guide_user_id,
			guide_rating_avg = EXCLUDED.guide_rating_avg,
			guide_reviews_count = EXCLUDED.guide_reviews_count,
			guide_experience_years = EXCLUDED.guide_experience_years,
			guide_display_name = EXCLUDED.guide_display_name,
			guide_search_text = EXCLUDED.guide_search_text,
			title = EXCLUDED.title,
			summary = EXCLUDED.summary,
			description = EXCLUDED.description,
			translations = EXCLUDED.translations,
			status = EXCLUDED.status,
			visibility = EXCLUDED.visibility,
			duration_minutes = EXCLUDED.duration_minutes,
			max_group_size = EXCLUDED.max_group_size,
			meeting_point = EXCLUDED.meeting_point,
			latitude = EXCLUDED.latitude,
			longitude = EXCLUDED.longitude,
			map_url = EXCLUDED.map_url,
			price_amount = EXCLUDED.price_amount,
			currency = EXCLUDED.currency,
			cover_file_id = EXCLUDED.cover_file_id,
			published_at = EXCLUDED.published_at,
			deleted_at = EXCLUDED.deleted_at,
			revision = EXCLUDED.revision,
			updated_at = EXCLUDED.updated_at
		RETURNING id
	`
	offerID := uuid.New()
	var persistedID uuid.UUID
	if err := exec.QueryRow(
		ctx,
		query,
		offerID,
		productID,
		item.ID,
		item.GuideProfileID,
		item.GuideUserID,
		item.GuideRatingAvg,
		item.GuideReviewsCount,
		item.GuideExperienceYears,
		item.GuideDisplayName,
		item.GuideSearchText,
		marketplaceProductTitle(item),
		marketplaceProductSummary(item),
		marketplaceProductDescription(item),
		string(item.Status),
		string(item.Visibility),
		item.DurationMinutes,
		item.MaxGroupSize,
		item.MeetingPoint,
		item.Latitude,
		item.Longitude,
		item.MapURL,
		item.PriceAmount,
		item.Currency,
		coverFileID,
		item.PublishedAt,
		item.DeletedAt,
		item.Revision,
		item.CreatedAt,
		item.UpdatedAt,
		excursionTranslationsJSON(nil),
	).Scan(&persistedID); err != nil {
		return uuid.Nil, fmt.Errorf("upsert excursion offer: %w", err)
	}
	return persistedID, nil
}

func replaceOfferStrings(ctx context.Context, exec dbExecutor, table string, column string, offerID uuid.UUID, values []string) error {
	if _, err := exec.Exec(ctx, fmt.Sprintf("DELETE FROM %s WHERE offer_id = $1", table), offerID); err != nil {
		return fmt.Errorf("delete %s: %w", table, err)
	}
	for index, value := range values {
		value = strings.TrimSpace(value)
		if value == "" {
			continue
		}
		query := fmt.Sprintf(
			"INSERT INTO %s (id, offer_id, %s, sort_order, created_at) VALUES ($1, $2, $3, $4, $5)",
			table,
			column,
		)
		if _, err := exec.Exec(ctx, query, uuid.New(), offerID, value, index, time.Now().UTC()); err != nil {
			return fmt.Errorf("insert %s: %w", table, err)
		}
	}
	return nil
}

func refreshExcursionProductStats(ctx context.Context, exec dbExecutor, productID uuid.UUID) error {
	const query = `
		WITH stats AS (
			SELECT
				COUNT(id) FILTER (WHERE deleted_at IS NULL AND status <> 'ARCHIVED') AS offers_count,
				COUNT(id) FILTER (WHERE deleted_at IS NULL AND status = 'PUBLISHED' AND visibility = 'PUBLIC') AS published_offers_count,
				MIN(price_amount) FILTER (WHERE deleted_at IS NULL AND status = 'PUBLISHED' AND visibility = 'PUBLIC') AS min_price_amount
			FROM excursion_offers
			WHERE product_id = $1
		),
		cheapest AS (
			SELECT currency
			FROM excursion_offers
			WHERE product_id = $1 AND deleted_at IS NULL AND status = 'PUBLISHED' AND visibility = 'PUBLIC'
			ORDER BY price_amount ASC, updated_at DESC
			LIMIT 1
		)
		UPDATE excursion_products
		SET
			offers_count = stats.offers_count,
			published_offers_count = stats.published_offers_count,
			min_price_amount = stats.min_price_amount,
			currency = (SELECT currency FROM cheapest),
			status = CASE WHEN stats.published_offers_count > 0 THEN 'PUBLISHED' ELSE 'DRAFT' END,
			updated_at = NOW()
		FROM stats
		WHERE excursion_products.id = $1
	`
	if _, err := exec.Exec(ctx, query, productID); err != nil {
		return fmt.Errorf("refresh excursion product stats: %w", err)
	}
	return nil
}

func marketplaceProductStatus(item *model.Excursion) string {
	if item.IsPublished() && item.Visibility == enum.ExcursionVisibilityPublic {
		return string(enum.ExcursionStatusPublished)
	}
	return string(enum.ExcursionStatusDraft)
}

func excursionMarketplaceCanonicalKey(item *model.Excursion) string {
	if item != nil && item.LandmarkID != nil && *item.LandmarkID != uuid.Nil {
		return "landmark:" + item.LandmarkID.String()
	}
	if item == nil {
		return "custom:unknown-country:unknown-city:uncategorized:unknown-excursion"
	}
	country := marketplaceSlug(optionalStringValue(item.CountryCode), "unknown-country")
	city := marketplaceSlug(optionalStringValue(item.CityName), "unknown-city")
	category := marketplaceSlug(item.CategorySlug, "uncategorized")
	title := marketplaceSlug(item.Title, item.ID.String())
	return "custom:" + country + ":" + city + ":" + category + ":" + title
}

func marketplaceProductTitle(item *model.Excursion) string {
	if item == nil {
		return "FlyFy excursions"
	}
	if landmark := strings.TrimSpace(optionalStringValue(item.LandmarkName)); landmark != "" {
		return landmark
	}
	if title := strings.TrimSpace(item.Title); title != "" {
		return title
	}
	return "FlyFy excursions"
}

func marketplaceProductSummary(item *model.Excursion) string {
	if item == nil {
		return "Compare guide offers from local FlyFy guides."
	}
	if landmark := strings.TrimSpace(optionalStringValue(item.LandmarkName)); landmark != "" {
		return "Compare guide offers for " + landmark + "."
	}
	if summary := strings.TrimSpace(item.Summary); summary != "" {
		return summary
	}
	return "Compare guide offers from local FlyFy guides."
}

func marketplaceProductDescription(item *model.Excursion) string {
	if item == nil {
		return "Choose a guide, language, price, meeting point, and included options before booking."
	}
	if strings.TrimSpace(optionalStringValue(item.LandmarkName)) != "" {
		return "Choose a guide, language, price, meeting point, and included options before booking."
	}
	if description := strings.TrimSpace(item.Description); description != "" {
		return description
	}
	return "Choose a guide, language, price, meeting point, and included options before booking."
}

func optionalStringValue(value *string) string {
	if value == nil {
		return ""
	}
	return *value
}

func excursionTranslationsJSON(input model.ExcursionTranslations) string {
	normalized := model.NormalizeExcursionTranslations(input)
	if len(normalized) == 0 {
		return "{}"
	}
	raw, err := json.Marshal(normalized)
	if err != nil {
		return "{}"
	}
	return string(raw)
}

func scanExcursionTranslations(raw []byte) model.ExcursionTranslations {
	if len(raw) == 0 {
		return nil
	}
	var translations model.ExcursionTranslations
	if err := json.Unmarshal(raw, &translations); err != nil {
		return nil
	}
	return model.NormalizeExcursionTranslations(translations)
}

func excursionLocalizedTextJSON(input model.ExcursionLocalizedText) string {
	normalized := model.NormalizeExcursionLocalizedText(input)
	if len(normalized) == 0 {
		return "{}"
	}
	raw, err := json.Marshal(normalized)
	if err != nil {
		return "{}"
	}
	return string(raw)
}

func scanExcursionLocalizedText(raw []byte) model.ExcursionLocalizedText {
	if len(raw) == 0 {
		return nil
	}
	var translations model.ExcursionLocalizedText
	if err := json.Unmarshal(raw, &translations); err != nil {
		return nil
	}
	return model.NormalizeExcursionLocalizedText(translations)
}

func excursionItineraryTranslationsJSON(input model.ExcursionItineraryTranslations) string {
	normalized := model.NormalizeExcursionItineraryTranslations(input)
	if len(normalized) == 0 {
		return "{}"
	}
	raw, err := json.Marshal(normalized)
	if err != nil {
		return "{}"
	}
	return string(raw)
}

func scanExcursionItineraryTranslations(raw []byte) model.ExcursionItineraryTranslations {
	if len(raw) == 0 {
		return nil
	}
	var translations model.ExcursionItineraryTranslations
	if err := json.Unmarshal(raw, &translations); err != nil {
		return nil
	}
	return model.NormalizeExcursionItineraryTranslations(translations)
}

func marketplaceSlug(value string, fallback string) string {
	value = strings.TrimSpace(strings.ToLower(value))
	var builder strings.Builder
	lastDash := false
	for _, r := range value {
		if unicode.IsLetter(r) || unicode.IsDigit(r) {
			builder.WriteRune(r)
			lastDash = false
			continue
		}
		if !lastDash && builder.Len() > 0 {
			builder.WriteByte('-')
			lastDash = true
		}
	}
	result := strings.Trim(builder.String(), "-")
	if result == "" {
		return fallback
	}
	return result
}

func (r *PGExcursionRepository) listStrings(ctx context.Context, table string, column string, excursionID uuid.UUID) ([]string, error) {
	query := fmt.Sprintf("SELECT %s FROM %s WHERE excursion_id = $1 ORDER BY sort_order ASC, created_at ASC", column, table)
	rows, err := r.pool.Query(ctx, query, excursionID)
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

func (r *PGExcursionRepository) listOfferStrings(ctx context.Context, table string, column string, offerID uuid.UUID) ([]string, error) {
	query := fmt.Sprintf("SELECT %s FROM %s WHERE offer_id = $1 ORDER BY sort_order ASC, created_at ASC", column, table)
	rows, err := r.pool.Query(ctx, query, offerID)
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

func (r *PGExcursionRepository) listIncludedItems(ctx context.Context, table string, parentColumn string, parentID uuid.UUID) ([]model.ExcursionIncludedItem, error) {
	query := fmt.Sprintf("SELECT item_text, translations FROM %s WHERE %s = $1 ORDER BY sort_order ASC, created_at ASC", table, parentColumn)
	rows, err := r.pool.Query(ctx, query, parentID)
	if err != nil {
		return nil, fmt.Errorf("list %s: %w", table, err)
	}
	defer rows.Close()

	result := make([]model.ExcursionIncludedItem, 0)
	for rows.Next() {
		var (
			text            string
			translationsRaw []byte
		)
		if err = rows.Scan(&text, &translationsRaw); err != nil {
			return nil, fmt.Errorf("scan %s: %w", table, err)
		}
		result = append(result, model.NewExcursionIncludedItem(text, scanExcursionLocalizedText(translationsRaw)))
	}
	return result, rows.Err()
}

func (r *PGExcursionRepository) listItinerary(ctx context.Context, excursionID uuid.UUID) ([]*model.ExcursionItineraryItem, error) {
	const query = `
		SELECT id, excursion_id, sort_order, start_offset_minutes, duration_minutes,
		       title, description, translations, created_at, updated_at
		FROM excursion_itinerary_items
		WHERE excursion_id = $1
		ORDER BY sort_order ASC, start_offset_minutes ASC
	`
	rows, err := r.pool.Query(ctx, query, excursionID)
	if err != nil {
		return nil, fmt.Errorf("list excursion itinerary: %w", err)
	}
	defer rows.Close()

	result := make([]*model.ExcursionItineraryItem, 0)
	for rows.Next() {
		item, scanErr := scanItineraryItem(rows)
		if scanErr != nil {
			return nil, fmt.Errorf("scan excursion itinerary: %w", scanErr)
		}
		result = append(result, item)
	}
	return result, rows.Err()
}

func (r *PGExcursionRepository) legacyExcursionIDForOffer(ctx context.Context, offerID uuid.UUID) (*uuid.UUID, error) {
	const query = `SELECT legacy_excursion_id FROM excursion_offers WHERE id = $1`
	var legacyExcursionID *uuid.UUID
	if err := r.pool.QueryRow(ctx, query, offerID).Scan(&legacyExcursionID); err != nil {
		if err == pgx.ErrNoRows {
			return nil, nil
		}
		return nil, fmt.Errorf("get offer legacy excursion id: %w", err)
	}
	return legacyExcursionID, nil
}

func (r *PGExcursionRepository) getCoverFileID(ctx context.Context, excursionID uuid.UUID) (*uuid.UUID, error) {
	const query = `
		SELECT file_id
		FROM excursion_covers
		WHERE excursion_id = $1
		LIMIT 1
	`
	var fileID uuid.UUID
	if err := r.pool.QueryRow(ctx, query, excursionID).Scan(&fileID); err != nil {
		if err == pgx.ErrNoRows {
			return nil, nil
		}
		return nil, fmt.Errorf("get excursion cover: %w", err)
	}
	return &fileID, nil
}

type excursionScanner interface {
	Scan(dest ...any) error
}

func scanExcursion(row excursionScanner) (*model.Excursion, error) {
	var (
		item                   model.Excursion
		statusRaw              string
		visibilityRaw          string
		translationsRaw        []byte
		productTranslationsRaw []byte
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
		&translationsRaw,
		&productTranslationsRaw,
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
	item.Status = enum.ExcursionStatus(statusRaw)
	item.Visibility = enum.ExcursionVisibility(visibilityRaw)
	item.Translations = scanExcursionTranslations(translationsRaw)
	item.ProductTranslations = scanExcursionTranslations(productTranslationsRaw)
	return &item, nil
}

func scanExcursionProductCard(row excursionScanner) (*model.ExcursionProductCard, error) {
	var (
		item            model.ExcursionProductCard
		statusRaw       string
		visibilityRaw   string
		translationsRaw []byte
	)
	if err := row.Scan(
		&item.ID,
		&item.CanonicalKey,
		&item.LandmarkID,
		&item.LandmarkName,
		&item.Title,
		&item.Summary,
		&item.Description,
		&translationsRaw,
		&item.CategorySlug,
		&statusRaw,
		&visibilityRaw,
		&item.DurationMinutes,
		&item.CountryCode,
		&item.CityName,
		&item.Latitude,
		&item.Longitude,
		&item.MapURL,
		&item.CoverFileID,
		&item.MinPriceAmount,
		&item.Currency,
		&item.OffersCount,
		&item.PublishedOffersCount,
		&item.NextAvailableAt,
		&item.CreatedAt,
		&item.UpdatedAt,
	); err != nil {
		return nil, err
	}
	item.Status = enum.ExcursionStatus(statusRaw)
	item.Visibility = enum.ExcursionVisibility(visibilityRaw)
	item.Translations = scanExcursionTranslations(translationsRaw)
	return &item, nil
}

func scanExcursionOffer(row excursionScanner) (*model.ExcursionOffer, error) {
	var (
		item            model.ExcursionOffer
		statusRaw       string
		visibilityRaw   string
		translationsRaw []byte
	)
	if err := row.Scan(
		&item.ID,
		&item.ProductID,
		&item.LegacyExcursionID,
		&item.GuideProfileID,
		&item.GuideUserID,
		&item.GuideRatingAvg,
		&item.GuideReviewsCount,
		&item.GuideExperienceYears,
		&item.GuideDisplayName,
		&item.GuideSearchText,
		&item.Title,
		&item.Summary,
		&item.Description,
		&translationsRaw,
		&statusRaw,
		&visibilityRaw,
		&item.DurationMinutes,
		&item.MaxGroupSize,
		&item.MeetingPoint,
		&item.Latitude,
		&item.Longitude,
		&item.MapURL,
		&item.PriceAmount,
		&item.Currency,
		&item.CoverFileID,
		&item.PublishedAt,
		&item.DeletedAt,
		&item.Revision,
		&item.CreatedAt,
		&item.UpdatedAt,
	); err != nil {
		return nil, err
	}
	item.Status = enum.ExcursionStatus(statusRaw)
	item.Visibility = enum.ExcursionVisibility(visibilityRaw)
	item.Translations = scanExcursionTranslations(translationsRaw)
	return &item, nil
}

func scanExcursionBooking(row excursionScanner) (*model.ExcursionBooking, error) {
	var (
		item      model.ExcursionBooking
		statusRaw string
	)
	if err := row.Scan(
		&item.ID,
		&item.ProductID,
		&item.OfferID,
		&item.LegacyExcursionID,
		&item.GuideProfileID,
		&item.GuideUserID,
		&item.TouristUserID,
		&item.ScheduledFor,
		&item.Adults,
		&item.Children,
		&item.TotalSeats,
		&item.UnitPriceAmount,
		&item.ServiceFeeAmount,
		&item.TotalPriceAmount,
		&item.Currency,
		&statusRaw,
		&item.IdempotencyKey,
		&item.CancelledAt,
		&item.CancelReason,
		&item.CreatedAt,
		&item.UpdatedAt,
	); err != nil {
		return nil, err
	}
	item.Status = enum.ExcursionBookingStatus(statusRaw)
	return &item, nil
}

func scanExcursionBookingListItem(row excursionScanner) (*model.ExcursionBookingListItem, error) {
	var (
		booking                model.ExcursionBooking
		statusRaw              string
		reviewID               *uuid.UUID
		reviewBookingID        *uuid.UUID
		reviewProductID        *uuid.UUID
		reviewOfferID          *uuid.UUID
		reviewGuideProfileID   *uuid.UUID
		reviewGuideUserID      *uuid.UUID
		reviewGuideDisplayName *string
		reviewTouristUserID    *uuid.UUID
		review                 model.ExcursionReview
		reviewRating           *float64
		reviewComment          *string
		reviewCreatedAt        *time.Time
		reviewUpdatedAt        *time.Time
		item                   model.ExcursionBookingListItem
	)
	if err := row.Scan(
		&booking.ID,
		&booking.ProductID,
		&booking.OfferID,
		&booking.LegacyExcursionID,
		&booking.GuideProfileID,
		&booking.GuideUserID,
		&booking.TouristUserID,
		&booking.ScheduledFor,
		&booking.Adults,
		&booking.Children,
		&booking.TotalSeats,
		&booking.UnitPriceAmount,
		&booking.ServiceFeeAmount,
		&booking.TotalPriceAmount,
		&booking.Currency,
		&statusRaw,
		&booking.IdempotencyKey,
		&booking.CancelledAt,
		&booking.CancelReason,
		&booking.CreatedAt,
		&booking.UpdatedAt,
		&item.Title,
		&item.Summary,
		&item.LandmarkID,
		&item.LandmarkName,
		&item.CategorySlug,
		&item.CountryCode,
		&item.CityName,
		&item.CoverFileID,
		&item.GuideDisplayName,
		&reviewID,
		&reviewBookingID,
		&reviewProductID,
		&reviewOfferID,
		&review.LegacyExcursionID,
		&review.LandmarkID,
		&review.LandmarkName,
		&reviewGuideProfileID,
		&reviewGuideUserID,
		&reviewGuideDisplayName,
		&reviewTouristUserID,
		&reviewRating,
		&reviewComment,
		&reviewCreatedAt,
		&reviewUpdatedAt,
	); err != nil {
		return nil, err
	}
	booking.Status = enum.ExcursionBookingStatus(statusRaw)
	item.Booking = &booking
	if reviewID != nil {
		review.ID = *reviewID
		if reviewBookingID != nil {
			review.BookingID = *reviewBookingID
		}
		if reviewProductID != nil {
			review.ProductID = *reviewProductID
		}
		if reviewOfferID != nil {
			review.OfferID = *reviewOfferID
		}
		if reviewGuideProfileID != nil {
			review.GuideProfileID = *reviewGuideProfileID
		}
		if reviewGuideUserID != nil {
			review.GuideUserID = *reviewGuideUserID
		}
		if reviewGuideDisplayName != nil {
			review.GuideDisplayName = *reviewGuideDisplayName
		}
		if reviewTouristUserID != nil {
			review.TouristUserID = *reviewTouristUserID
		}
		if reviewRating != nil {
			review.Rating = *reviewRating
		}
		if reviewComment != nil {
			review.Comment = *reviewComment
		}
		if reviewCreatedAt != nil {
			review.CreatedAt = *reviewCreatedAt
		}
		if reviewUpdatedAt != nil {
			review.UpdatedAt = *reviewUpdatedAt
		}
		item.Review = &review
	}
	return &item, nil
}

func scanExcursionReview(row excursionScanner) (*model.ExcursionReview, error) {
	var item model.ExcursionReview
	if err := row.Scan(
		&item.ID,
		&item.BookingID,
		&item.ProductID,
		&item.OfferID,
		&item.LegacyExcursionID,
		&item.LandmarkID,
		&item.LandmarkName,
		&item.GuideProfileID,
		&item.GuideUserID,
		&item.GuideDisplayName,
		&item.TouristUserID,
		&item.Rating,
		&item.Comment,
		&item.CreatedAt,
		&item.UpdatedAt,
	); err != nil {
		return nil, err
	}
	return &item, nil
}

func scanItineraryItem(row excursionScanner) (*model.ExcursionItineraryItem, error) {
	var (
		item            model.ExcursionItineraryItem
		translationsRaw []byte
	)
	if err := row.Scan(
		&item.ID,
		&item.ExcursionID,
		&item.SortOrder,
		&item.StartOffsetMinutes,
		&item.DurationMinutes,
		&item.Title,
		&item.Description,
		&translationsRaw,
		&item.CreatedAt,
		&item.UpdatedAt,
	); err != nil {
		return nil, err
	}
	item.Translations = scanExcursionItineraryTranslations(translationsRaw)
	return &item, nil
}
