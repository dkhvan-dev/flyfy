package repository

import (
	"context"
	"encoding/json"
	"fmt"
	"strings"
	"time"
	"unicode"

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
	title, summary, description, translations, product_translations, category_slug,
	status, visibility,
	duration_minutes, max_group_size,
	country_code, city_name, meeting_point, latitude, longitude, map_url,
	price_amount, currency,
	published_at, deleted_at, revision, created_at, updated_at
`

const tourProductCardSelectColumns = `
	id, canonical_key,
	landmark_id, landmark_name,
	title, summary, description, translations, category_slug,
	status, visibility,
	duration_minutes,
	country_code, city_name, latitude, longitude, map_url, cover_file_id,
	min_price_amount, currency, offers_count, published_offers_count, next_available_at,
	created_at, updated_at
`

const tourOfferSelectColumns = `
	id, product_id, legacy_tour_id,
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

func tourSmartSearchTargets() []smartSearchTarget {
	return []smartSearchTarget{
		columnSmartSearchTarget("tours.title"),
		columnSmartSearchTarget("tours.summary"),
		columnSmartSearchTarget("tours.description"),
		columnSmartSearchTarget("tours.translations"),
		columnSmartSearchTarget("tours.product_translations"),
		columnSmartSearchTarget("tours.landmark_name"),
		columnSmartSearchTarget("tours.category_slug"),
		columnSmartSearchTarget("tours.country_code"),
		columnSmartSearchTarget("tours.city_name"),
		columnSmartSearchTarget("tours.meeting_point"),
		templatedSmartSearchTarget(`EXISTS (
			SELECT 1 FROM tour_tags st
			WHERE st.tour_id = tours.id
			  AND LOWER(COALESCE(st.tag_slug::text, '')) LIKE %s
		)`),
		templatedSmartSearchTarget(`EXISTS (
			SELECT 1 FROM tour_languages sl
			WHERE sl.tour_id = tours.id
			  AND LOWER(COALESCE(sl.language_code::text, '')) LIKE %s
		)`),
		templatedSmartSearchTarget(`EXISTS (
			SELECT 1 FROM tour_included_items si
			WHERE si.tour_id = tours.id
			  AND (
			    LOWER(COALESCE(si.item_text::text, '')) LIKE %[1]s
			    OR LOWER(COALESCE(si.translations::text, '')) LIKE %[1]s
			  )
		)`),
		templatedSmartSearchTarget(`EXISTS (
			SELECT 1 FROM tour_itinerary_items sit
			WHERE sit.tour_id = tours.id
			  AND (
			    LOWER(COALESCE(sit.title::text, '')) LIKE %[1]s
			    OR LOWER(COALESCE(sit.description::text, '')) LIKE %[1]s
			    OR LOWER(COALESCE(sit.translations::text, '')) LIKE %[1]s
			  )
		)`),
	}
}

func tourProductSmartSearchTargets() []smartSearchTarget {
	return []smartSearchTarget{
		columnSmartSearchTarget("tour_products.canonical_key"),
		columnSmartSearchTarget("tour_products.title"),
		columnSmartSearchTarget("tour_products.summary"),
		columnSmartSearchTarget("tour_products.description"),
		columnSmartSearchTarget("tour_products.translations"),
		columnSmartSearchTarget("tour_products.landmark_name"),
		columnSmartSearchTarget("tour_products.category_slug"),
		columnSmartSearchTarget("tour_products.country_code"),
		columnSmartSearchTarget("tour_products.city_name"),
		templatedSmartSearchTarget(`EXISTS (
			SELECT 1
			FROM tour_offers o_search
			WHERE o_search.product_id = tour_products.id
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
			FROM tour_offers o_lang
			JOIN tour_offer_languages l_search ON l_search.offer_id = o_lang.id
			WHERE o_lang.product_id = tour_products.id
			  AND o_lang.status = 'PUBLISHED'
			  AND o_lang.visibility = 'PUBLIC'
			  AND o_lang.deleted_at IS NULL
			  AND LOWER(COALESCE(l_search.language_code::text, '')) LIKE %s
		)`),
		templatedSmartSearchTarget(`EXISTS (
			SELECT 1
			FROM tour_offers o_inc
			JOIN tour_offer_included_items i_search ON i_search.offer_id = o_inc.id
			WHERE o_inc.product_id = tour_products.id
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

func tourOfferSmartSearchTargets() []smartSearchTarget {
	return []smartSearchTarget{
		columnSmartSearchTarget("tour_offers.title"),
		columnSmartSearchTarget("tour_offers.summary"),
		columnSmartSearchTarget("tour_offers.description"),
		columnSmartSearchTarget("tour_offers.translations"),
		columnSmartSearchTarget("tour_offers.meeting_point"),
		columnSmartSearchTarget("tour_offers.currency"),
		columnSmartSearchTarget("tour_offers.guide_user_id"),
		columnSmartSearchTarget("tour_offers.guide_profile_id"),
		columnSmartSearchTarget("tour_offers.guide_display_name"),
		columnSmartSearchTarget("tour_offers.guide_search_text"),
		templatedSmartSearchTarget(`EXISTS (
			SELECT 1
			FROM tour_offer_languages l_search
			WHERE l_search.offer_id = tour_offers.id
			  AND LOWER(COALESCE(l_search.language_code::text, '')) LIKE %s
		)`),
		templatedSmartSearchTarget(`EXISTS (
			SELECT 1
			FROM tour_offer_included_items i_search
			WHERE i_search.offer_id = tour_offers.id
			  AND (
			    LOWER(COALESCE(i_search.item_text::text, '')) LIKE %[1]s
			    OR LOWER(COALESCE(i_search.translations::text, '')) LIKE %[1]s
			  )
		)`),
	}
}

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
	if err = syncTourMarketplace(ctx, tx, item, relations); err != nil {
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
	if err = syncTourMarketplace(ctx, tx, item, relations); err != nil {
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
		argPos = appendSmartSearchCondition(&parts, &args, argPos, *filter.SearchQuery, tourSmartSearchTargets())
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
	includedItems, err := r.listIncludedItems(ctx, "tour_included_items", "tour_id", tourID)
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

func (r *PGTourRepository) ListTourProductCards(ctx context.Context, filter port.TourProductFilter) ([]*model.TourProductCard, error) {
	base := `
		SELECT ` + tourProductCardSelectColumns + `
		FROM tour_products
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
				FROM tour_offers o
				JOIN tour_offer_languages l ON l.offer_id = o.id
				WHERE o.product_id = tour_products.id
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
		argPos = appendSmartSearchCondition(&parts, &args, argPos, *filter.SearchQuery, tourProductSmartSearchTargets())
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
				FROM tour_offers o
				WHERE o.product_id = tour_products.id
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
		return nil, fmt.Errorf("list tour products: %w", err)
	}
	defer rows.Close()

	items := make([]*model.TourProductCard, 0)
	for rows.Next() {
		item, scanErr := scanTourProductCard(rows)
		if scanErr != nil {
			return nil, fmt.Errorf("scan tour product: %w", scanErr)
		}
		items = append(items, item)
	}
	return items, rows.Err()
}

func (r *PGTourRepository) GetTourProductCardByID(ctx context.Context, productID uuid.UUID) (*model.TourProductCard, error) {
	query := `
		SELECT ` + tourProductCardSelectColumns + `
		FROM tour_products
		WHERE id = $1 AND status = 'PUBLISHED' AND visibility <> 'PRIVATE'
		LIMIT 1
	`
	item, err := scanTourProductCard(r.pool.QueryRow(ctx, query, productID))
	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, nil
		}
		return nil, fmt.Errorf("get tour product: %w", err)
	}
	return item, nil
}

func (r *PGTourRepository) ListTourOffers(ctx context.Context, filter port.TourOfferFilter) ([]*model.TourOffer, error) {
	base := `
		SELECT ` + tourOfferSelectColumns + `
		FROM tour_offers
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
				FROM tour_offer_languages l
				WHERE l.offer_id = tour_offers.id AND l.language_code = $%d
			)
		`, argPos))
		args = append(args, strings.ToLower(strings.TrimSpace(*filter.LanguageCode)))
		argPos++
	}
	if filter.SearchQuery != nil && strings.TrimSpace(*filter.SearchQuery) != "" {
		argPos = appendSmartSearchCondition(&parts, &args, argPos, *filter.SearchQuery, tourOfferSmartSearchTargets())
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
	parts = append(parts, " ORDER BY "+orderPrefix+tourOfferOrderBy(filter.Sort, filter.SortDirection))
	parts = append(parts, fmt.Sprintf(" LIMIT $%d OFFSET $%d", argPos, argPos+1))
	args = append(args, filter.Limit, filter.Offset)

	rows, err := r.pool.Query(ctx, strings.Join(parts, ""), args...)
	if err != nil {
		return nil, fmt.Errorf("list tour offers: %w", err)
	}
	defer rows.Close()

	items := make([]*model.TourOffer, 0)
	for rows.Next() {
		item, scanErr := scanTourOffer(rows)
		if scanErr != nil {
			return nil, fmt.Errorf("scan tour offer: %w", scanErr)
		}
		items = append(items, item)
	}
	return items, rows.Err()
}

func tourOfferOrderBy(sort string, direction string) string {
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

func (r *PGTourRepository) GetTourOfferByID(ctx context.Context, offerID uuid.UUID) (*model.TourOffer, error) {
	query := `
		SELECT ` + tourOfferSelectColumns + `
		FROM tour_offers
		WHERE id = $1
		LIMIT 1
	`
	item, err := scanTourOffer(r.pool.QueryRow(ctx, query, offerID))
	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, nil
		}
		return nil, fmt.Errorf("get tour offer by id: %w", err)
	}
	return item, nil
}

func (r *PGTourRepository) LoadTourOfferRelations(ctx context.Context, offerID uuid.UUID) (port.TourOfferRelations, error) {
	languages, err := r.listOfferStrings(ctx, "tour_offer_languages", "language_code", offerID)
	if err != nil {
		return port.TourOfferRelations{}, err
	}
	includedItems, err := r.listIncludedItems(ctx, "tour_offer_included_items", "offer_id", offerID)
	if err != nil {
		return port.TourOfferRelations{}, err
	}
	legacyTourID, err := r.legacyTourIDForOffer(ctx, offerID)
	if err != nil {
		return port.TourOfferRelations{}, err
	}
	var itinerary []*model.TourItineraryItem
	if legacyTourID != nil && *legacyTourID != uuid.Nil {
		itinerary, err = r.listItinerary(ctx, *legacyTourID)
		if err != nil {
			return port.TourOfferRelations{}, err
		}
	}
	return port.TourOfferRelations{LanguageCodes: languages, IncludedItems: includedItems, Itinerary: itinerary}, nil
}

func (r *PGTourRepository) CreateTourBooking(ctx context.Context, item *model.TourBooking) error {
	const query = `
		INSERT INTO tour_bookings (
			id,
			product_id, offer_id, legacy_tour_id,
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
		item.LegacyTourID,
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
		return fmt.Errorf("insert tour booking: %w", err)
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
			updated_at = $25,
			translations = $26::jsonb,
			product_translations = $27::jsonb
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
		tourTranslationsJSON(item.Translations),
		tourTranslationsJSON(item.ProductTranslations),
	}
}

func updateTourArgs(item *model.Tour) []any {
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
		tourTranslationsJSON(item.Translations),
		tourTranslationsJSON(item.ProductTranslations),
	}
}

func replaceTourRelations(ctx context.Context, tx pgx.Tx, tourID uuid.UUID, relations port.TourRelations) error {
	if err := replaceStrings(ctx, tx, "tour_tags", "tag_slug", tourID, relations.Tags); err != nil {
		return err
	}
	if err := replaceStrings(ctx, tx, "tour_languages", "language_code", tourID, relations.LanguageCodes); err != nil {
		return err
	}
	if err := replaceIncludedItems(ctx, tx, "tour_included_items", "tour_id", tourID, relations.IncludedItems); err != nil {
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

func replaceIncludedItems(ctx context.Context, exec dbExecutor, table string, parentColumn string, parentID uuid.UUID, values []model.TourIncludedItem) error {
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
		if _, err := exec.Exec(ctx, query, uuid.New(), parentID, text, tourLocalizedTextJSON(value.Translations), index, time.Now().UTC()); err != nil {
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
				title, description, translations, created_at, updated_at
			) VALUES ($1, $2, $3, $4, $5, $6, $7, $8::jsonb, $9, $10)
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
			tourItineraryTranslationsJSON(item.Translations),
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

func syncTourMarketplace(ctx context.Context, exec dbExecutor, item *model.Tour, relations port.TourRelations) error {
	productCoverFileID := relations.ProductCoverFileID
	if productCoverFileID == nil && item.LandmarkID == nil {
		productCoverFileID = relations.CoverFileID
	}
	productID, err := upsertTourProduct(ctx, exec, item, productCoverFileID)
	if err != nil {
		return err
	}
	offerID, err := upsertTourOffer(ctx, exec, productID, item, relations.CoverFileID)
	if err != nil {
		return err
	}
	if err = replaceOfferStrings(ctx, exec, "tour_offer_languages", "language_code", offerID, relations.LanguageCodes); err != nil {
		return err
	}
	if err = replaceIncludedItems(ctx, exec, "tour_offer_included_items", "offer_id", offerID, relations.IncludedItems); err != nil {
		return err
	}
	return refreshTourProductStats(ctx, exec, productID)
}

func upsertTourProduct(ctx context.Context, exec dbExecutor, item *model.Tour, coverFileID *uuid.UUID) (uuid.UUID, error) {
	const query = `
		INSERT INTO tour_products (
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
			landmark_id = COALESCE(tour_products.landmark_id, EXCLUDED.landmark_id),
			landmark_name = COALESCE(tour_products.landmark_name, EXCLUDED.landmark_name),
			title = CASE WHEN tour_products.published_offers_count = 0 THEN EXCLUDED.title ELSE tour_products.title END,
			summary = CASE WHEN tour_products.published_offers_count = 0 THEN EXCLUDED.summary ELSE tour_products.summary END,
			description = CASE WHEN tour_products.published_offers_count = 0 THEN EXCLUDED.description ELSE tour_products.description END,
			translations = CASE WHEN tour_products.published_offers_count = 0 THEN EXCLUDED.translations ELSE tour_products.translations END,
			category_slug = CASE WHEN tour_products.published_offers_count = 0 THEN EXCLUDED.category_slug ELSE tour_products.category_slug END,
			status = CASE
				WHEN tour_products.status = 'PUBLISHED' OR EXCLUDED.status = 'PUBLISHED' THEN 'PUBLISHED'
				ELSE EXCLUDED.status
			END,
			visibility = CASE
				WHEN tour_products.visibility = 'PUBLIC' OR EXCLUDED.visibility = 'PUBLIC' THEN 'PUBLIC'
				ELSE EXCLUDED.visibility
			END,
			duration_minutes = CASE WHEN tour_products.published_offers_count = 0 THEN EXCLUDED.duration_minutes ELSE tour_products.duration_minutes END,
			country_code = COALESCE(tour_products.country_code, EXCLUDED.country_code),
			city_name = COALESCE(tour_products.city_name, EXCLUDED.city_name),
			latitude = COALESCE(tour_products.latitude, EXCLUDED.latitude),
			longitude = COALESCE(tour_products.longitude, EXCLUDED.longitude),
			map_url = COALESCE(tour_products.map_url, EXCLUDED.map_url),
			cover_file_id = COALESCE(tour_products.cover_file_id, EXCLUDED.cover_file_id),
			updated_at = NOW()
		RETURNING id
	`
	productID := uuid.New()
	var persistedID uuid.UUID
	if err := exec.QueryRow(
		ctx,
		query,
		productID,
		tourMarketplaceCanonicalKey(item),
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
		tourTranslationsJSON(item.ProductTranslations),
	).Scan(&persistedID); err != nil {
		return uuid.Nil, fmt.Errorf("upsert tour product: %w", err)
	}
	return persistedID, nil
}

func upsertTourOffer(ctx context.Context, exec dbExecutor, productID uuid.UUID, item *model.Tour, coverFileID *uuid.UUID) (uuid.UUID, error) {
	const query = `
		INSERT INTO tour_offers (
			id, product_id, legacy_tour_id,
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
		ON CONFLICT (legacy_tour_id) DO UPDATE
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
		tourTranslationsJSON(nil),
	).Scan(&persistedID); err != nil {
		return uuid.Nil, fmt.Errorf("upsert tour offer: %w", err)
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

func refreshTourProductStats(ctx context.Context, exec dbExecutor, productID uuid.UUID) error {
	const query = `
		WITH stats AS (
			SELECT
				COUNT(id) FILTER (WHERE deleted_at IS NULL AND status <> 'ARCHIVED') AS offers_count,
				COUNT(id) FILTER (WHERE deleted_at IS NULL AND status = 'PUBLISHED' AND visibility = 'PUBLIC') AS published_offers_count,
				MIN(price_amount) FILTER (WHERE deleted_at IS NULL AND status = 'PUBLISHED' AND visibility = 'PUBLIC') AS min_price_amount
			FROM tour_offers
			WHERE product_id = $1
		),
		cheapest AS (
			SELECT currency
			FROM tour_offers
			WHERE product_id = $1 AND deleted_at IS NULL AND status = 'PUBLISHED' AND visibility = 'PUBLIC'
			ORDER BY price_amount ASC, updated_at DESC
			LIMIT 1
		)
		UPDATE tour_products
		SET
			offers_count = stats.offers_count,
			published_offers_count = stats.published_offers_count,
			min_price_amount = stats.min_price_amount,
			currency = (SELECT currency FROM cheapest),
			status = CASE WHEN stats.published_offers_count > 0 THEN 'PUBLISHED' ELSE 'DRAFT' END,
			updated_at = NOW()
		FROM stats
		WHERE tour_products.id = $1
	`
	if _, err := exec.Exec(ctx, query, productID); err != nil {
		return fmt.Errorf("refresh tour product stats: %w", err)
	}
	return nil
}

func marketplaceProductStatus(item *model.Tour) string {
	if item.IsPublished() && item.Visibility == enum.TourVisibilityPublic {
		return string(enum.TourStatusPublished)
	}
	return string(enum.TourStatusDraft)
}

func tourMarketplaceCanonicalKey(item *model.Tour) string {
	if item != nil && item.LandmarkID != nil && *item.LandmarkID != uuid.Nil {
		return "landmark:" + item.LandmarkID.String()
	}
	if item == nil {
		return "custom:unknown-country:unknown-city:uncategorized:unknown-tour"
	}
	country := marketplaceSlug(optionalStringValue(item.CountryCode), "unknown-country")
	city := marketplaceSlug(optionalStringValue(item.CityName), "unknown-city")
	category := marketplaceSlug(item.CategorySlug, "uncategorized")
	title := marketplaceSlug(item.Title, item.ID.String())
	return "custom:" + country + ":" + city + ":" + category + ":" + title
}

func marketplaceProductTitle(item *model.Tour) string {
	if item == nil {
		return "FlyFy tours"
	}
	if landmark := strings.TrimSpace(optionalStringValue(item.LandmarkName)); landmark != "" {
		return landmark
	}
	if title := strings.TrimSpace(item.Title); title != "" {
		return title
	}
	return "FlyFy tours"
}

func marketplaceProductSummary(item *model.Tour) string {
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

func marketplaceProductDescription(item *model.Tour) string {
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

func tourTranslationsJSON(input model.TourTranslations) string {
	normalized := model.NormalizeTourTranslations(input)
	if len(normalized) == 0 {
		return "{}"
	}
	raw, err := json.Marshal(normalized)
	if err != nil {
		return "{}"
	}
	return string(raw)
}

func scanTourTranslations(raw []byte) model.TourTranslations {
	if len(raw) == 0 {
		return nil
	}
	var translations model.TourTranslations
	if err := json.Unmarshal(raw, &translations); err != nil {
		return nil
	}
	return model.NormalizeTourTranslations(translations)
}

func tourLocalizedTextJSON(input model.TourLocalizedText) string {
	normalized := model.NormalizeTourLocalizedText(input)
	if len(normalized) == 0 {
		return "{}"
	}
	raw, err := json.Marshal(normalized)
	if err != nil {
		return "{}"
	}
	return string(raw)
}

func scanTourLocalizedText(raw []byte) model.TourLocalizedText {
	if len(raw) == 0 {
		return nil
	}
	var translations model.TourLocalizedText
	if err := json.Unmarshal(raw, &translations); err != nil {
		return nil
	}
	return model.NormalizeTourLocalizedText(translations)
}

func tourItineraryTranslationsJSON(input model.TourItineraryTranslations) string {
	normalized := model.NormalizeTourItineraryTranslations(input)
	if len(normalized) == 0 {
		return "{}"
	}
	raw, err := json.Marshal(normalized)
	if err != nil {
		return "{}"
	}
	return string(raw)
}

func scanTourItineraryTranslations(raw []byte) model.TourItineraryTranslations {
	if len(raw) == 0 {
		return nil
	}
	var translations model.TourItineraryTranslations
	if err := json.Unmarshal(raw, &translations); err != nil {
		return nil
	}
	return model.NormalizeTourItineraryTranslations(translations)
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

func (r *PGTourRepository) listOfferStrings(ctx context.Context, table string, column string, offerID uuid.UUID) ([]string, error) {
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

func (r *PGTourRepository) listIncludedItems(ctx context.Context, table string, parentColumn string, parentID uuid.UUID) ([]model.TourIncludedItem, error) {
	query := fmt.Sprintf("SELECT item_text, translations FROM %s WHERE %s = $1 ORDER BY sort_order ASC, created_at ASC", table, parentColumn)
	rows, err := r.pool.Query(ctx, query, parentID)
	if err != nil {
		return nil, fmt.Errorf("list %s: %w", table, err)
	}
	defer rows.Close()

	result := make([]model.TourIncludedItem, 0)
	for rows.Next() {
		var (
			text            string
			translationsRaw []byte
		)
		if err = rows.Scan(&text, &translationsRaw); err != nil {
			return nil, fmt.Errorf("scan %s: %w", table, err)
		}
		result = append(result, model.NewTourIncludedItem(text, scanTourLocalizedText(translationsRaw)))
	}
	return result, rows.Err()
}

func (r *PGTourRepository) listItinerary(ctx context.Context, tourID uuid.UUID) ([]*model.TourItineraryItem, error) {
	const query = `
		SELECT id, tour_id, sort_order, start_offset_minutes, duration_minutes,
		       title, description, translations, created_at, updated_at
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

func (r *PGTourRepository) legacyTourIDForOffer(ctx context.Context, offerID uuid.UUID) (*uuid.UUID, error) {
	const query = `SELECT legacy_tour_id FROM tour_offers WHERE id = $1`
	var legacyTourID *uuid.UUID
	if err := r.pool.QueryRow(ctx, query, offerID).Scan(&legacyTourID); err != nil {
		if err == pgx.ErrNoRows {
			return nil, nil
		}
		return nil, fmt.Errorf("get offer legacy tour id: %w", err)
	}
	return legacyTourID, nil
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
		item                   model.Tour
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
	item.Status = enum.TourStatus(statusRaw)
	item.Visibility = enum.TourVisibility(visibilityRaw)
	item.Translations = scanTourTranslations(translationsRaw)
	item.ProductTranslations = scanTourTranslations(productTranslationsRaw)
	return &item, nil
}

func scanTourProductCard(row tourScanner) (*model.TourProductCard, error) {
	var (
		item            model.TourProductCard
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
	item.Status = enum.TourStatus(statusRaw)
	item.Visibility = enum.TourVisibility(visibilityRaw)
	item.Translations = scanTourTranslations(translationsRaw)
	return &item, nil
}

func scanTourOffer(row tourScanner) (*model.TourOffer, error) {
	var (
		item            model.TourOffer
		statusRaw       string
		visibilityRaw   string
		translationsRaw []byte
	)
	if err := row.Scan(
		&item.ID,
		&item.ProductID,
		&item.LegacyTourID,
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
	item.Status = enum.TourStatus(statusRaw)
	item.Visibility = enum.TourVisibility(visibilityRaw)
	item.Translations = scanTourTranslations(translationsRaw)
	return &item, nil
}

func scanItineraryItem(row tourScanner) (*model.TourItineraryItem, error) {
	var (
		item            model.TourItineraryItem
		translationsRaw []byte
	)
	if err := row.Scan(
		&item.ID,
		&item.TourID,
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
	item.Translations = scanTourItineraryTranslations(translationsRaw)
	return &item, nil
}
