package repository

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"

	"kz/inflap/backend/services/support-service/internal/app"
)

type PGRepository struct {
	pool *pgxpool.Pool
}

func NewPGRepository(pool *pgxpool.Pool) *PGRepository {
	return &PGRepository{pool: pool}
}

func (r *PGRepository) ListArticles(ctx context.Context) ([]app.HelpArticle, error) {
	return r.ListAdminArticles(ctx, app.HelpArticleFilter{})
}

func (r *PGRepository) ListAdminArticles(ctx context.Context, filter app.HelpArticleFilter) ([]app.HelpArticle, error) {
	const query = `
		SELECT id, COALESCE(category_id, ''), slug, status, version, owner_id, reviewer_id,
			COALESCE(visibility_rules, '{}'::jsonb), published_at, last_reviewed_at,
			created_at, updated_at
		FROM help_articles
		WHERE ($1 = '' OR status = $1)
		ORDER BY updated_at DESC, id ASC
		LIMIT $2 OFFSET $3
	`
	limit := filter.Limit
	if limit <= 0 {
		limit = 1000
	}
	rows, err := r.pool.Query(ctx, query, string(filter.Status), limit, filter.Offset)
	if err != nil {
		return nil, fmt.Errorf("select help articles: %w", err)
	}
	defer rows.Close()

	articles := make([]app.HelpArticle, 0)
	for rows.Next() {
		article, err := scanHelpArticle(rows)
		if err != nil {
			return nil, err
		}
		articles = append(articles, article)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("iterate help articles: %w", err)
	}
	if len(articles) == 0 {
		return articles, nil
	}

	ids, articleIndexByID := indexArticles(articles)

	if err := r.loadTranslations(ctx, ids, articles, articleIndexByID); err != nil {
		return nil, err
	}
	if err := r.loadSurfaces(ctx, ids, articles, articleIndexByID); err != nil {
		return nil, err
	}
	if err := r.loadTags(ctx, ids, articles, articleIndexByID); err != nil {
		return nil, err
	}
	if err := r.loadActions(ctx, ids, articles, articleIndexByID); err != nil {
		return nil, err
	}
	if err := r.loadRelatedArticles(ctx, ids, articles, articleIndexByID); err != nil {
		return nil, err
	}

	return articles, nil
}

func (r *PGRepository) SearchArticles(ctx context.Context, filter app.SearchArticleFilter) ([]app.HelpArticle, error) {
	if filter.Query == "" {
		return []app.HelpArticle{}, nil
	}
	const query = `
		WITH search_query AS (
			SELECT websearch_to_tsquery('simple', $2) AS ts_query,
				lower($2) AS needle
		),
		ranked_articles AS (
			SELECT a.id, COALESCE(a.category_id, '') AS category_id, a.slug, a.status, a.version, a.owner_id, a.reviewer_id,
				COALESCE(a.visibility_rules, '{}'::jsonb) AS visibility_rules,
				a.published_at AS published_at, a.last_reviewed_at AS last_reviewed_at,
				a.created_at AS created_at, a.updated_at AS updated_at,
				(
					ts_rank_cd(t.search_vector, search_query.ts_query) +
					CASE WHEN lower(t.title) LIKE '%' || search_query.needle || '%' THEN 2.0 ELSE 0 END +
					CASE WHEN lower(t.short_answer) LIKE '%' || search_query.needle || '%' THEN 1.0 ELSE 0 END +
					CASE WHEN lower(t.body) LIKE '%' || search_query.needle || '%' THEN 0.5 ELSE 0 END +
					GREATEST(
						similarity(lower(t.title), search_query.needle),
						similarity(lower(t.short_answer), search_query.needle),
						similarity(lower(t.body), search_query.needle)
					)
				) AS search_rank
			FROM help_articles a
			JOIN help_article_translations t ON t.article_id = a.id
			CROSS JOIN search_query
			WHERE a.status = 'published'
				AND ($1 = '' OR t.locale = $1)
				AND ($3 = '' OR EXISTS (
					SELECT 1
					FROM help_article_surfaces s
					WHERE s.article_id = a.id AND s.surface = $3
				))
				AND (
					t.search_vector @@ search_query.ts_query
					OR lower(t.title) LIKE '%' || search_query.needle || '%'
					OR lower(t.short_answer) LIKE '%' || search_query.needle || '%'
					OR lower(t.body) LIKE '%' || search_query.needle || '%'
					OR lower(t.title) % search_query.needle
					OR lower(t.short_answer) % search_query.needle
					OR lower(t.body) % search_query.needle
				)
		)
		SELECT id, category_id, slug, status, version, owner_id, reviewer_id,
			visibility_rules, published_at, last_reviewed_at, created_at, updated_at
		FROM ranked_articles
		ORDER BY search_rank DESC, updated_at DESC, id ASC
		LIMIT $4
	`
	limit := filter.Limit
	if limit <= 0 {
		limit = 10
	}
	rows, err := r.pool.Query(ctx, query, filter.Locale, filter.Query, string(filter.Surface), limit)
	if err != nil {
		return nil, fmt.Errorf("search help articles: %w", err)
	}
	defer rows.Close()

	articles := make([]app.HelpArticle, 0)
	for rows.Next() {
		article, err := scanHelpArticle(rows)
		if err != nil {
			return nil, err
		}
		articles = append(articles, article)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("iterate help article search results: %w", err)
	}
	if len(articles) == 0 {
		return articles, nil
	}

	ids, articleIndexByID := indexArticles(articles)
	if err := r.loadTranslations(ctx, ids, articles, articleIndexByID); err != nil {
		return nil, err
	}
	if err := r.loadSurfaces(ctx, ids, articles, articleIndexByID); err != nil {
		return nil, err
	}
	if err := r.loadTags(ctx, ids, articles, articleIndexByID); err != nil {
		return nil, err
	}
	if err := r.loadActions(ctx, ids, articles, articleIndexByID); err != nil {
		return nil, err
	}
	if err := r.loadRelatedArticles(ctx, ids, articles, articleIndexByID); err != nil {
		return nil, err
	}

	return articles, nil
}

func (r *PGRepository) ListCategories(ctx context.Context, filter app.HelpCategoryFilter) ([]app.HelpCategory, error) {
	const query = `
		SELECT id, slug, status, sort_order, created_at, updated_at
		FROM help_categories
		WHERE ($1 = '' OR status = $1)
		ORDER BY sort_order ASC, slug ASC, id ASC
		LIMIT $2 OFFSET $3
	`
	limit := filter.Limit
	if limit <= 0 {
		limit = 1000
	}
	rows, err := r.pool.Query(ctx, query, string(filter.Status), limit, filter.Offset)
	if err != nil {
		return nil, fmt.Errorf("select help categories: %w", err)
	}
	defer rows.Close()

	categories := make([]app.HelpCategory, 0)
	for rows.Next() {
		category, err := scanHelpCategory(rows)
		if err != nil {
			return nil, err
		}
		categories = append(categories, category)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("iterate help categories: %w", err)
	}
	if len(categories) == 0 {
		return categories, nil
	}
	if err := r.loadCategoryTranslations(ctx, categories); err != nil {
		return nil, err
	}
	return categories, nil
}

func (r *PGRepository) UpsertCategory(ctx context.Context, category app.HelpCategory) error {
	const query = `
		INSERT INTO help_categories (id, slug, status, sort_order, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6)
		ON CONFLICT (id) DO UPDATE SET
			slug = EXCLUDED.slug,
			status = EXCLUDED.status,
			sort_order = EXCLUDED.sort_order,
			updated_at = EXCLUDED.updated_at
	`
	if _, err := r.pool.Exec(ctx, query,
		category.ID,
		category.Slug,
		string(category.Status),
		category.SortOrder,
		category.CreatedAt,
		category.UpdatedAt,
	); err != nil {
		return fmt.Errorf("upsert help category: %w", err)
	}
	return nil
}

func (r *PGRepository) loadCategoryTranslations(ctx context.Context, categories []app.HelpCategory) error {
	ids := make([]string, 0, len(categories))
	categoryIndexByID := make(map[string]int, len(categories))
	for index, category := range categories {
		ids = append(ids, category.ID)
		categoryIndexByID[category.ID] = index
		if categories[index].Translations == nil {
			categories[index].Translations = make(map[string]app.HelpCategoryTranslation)
		}
	}
	const query = `
		SELECT category_id, locale, title
		FROM help_category_translations
		WHERE category_id = ANY($1::text[])
		ORDER BY category_id, locale
	`
	rows, err := r.pool.Query(ctx, query, ids)
	if err != nil {
		return fmt.Errorf("select help category translations: %w", err)
	}
	defer rows.Close()
	for rows.Next() {
		var categoryID string
		var locale string
		var translation app.HelpCategoryTranslation
		if err := rows.Scan(&categoryID, &locale, &translation.Title); err != nil {
			return fmt.Errorf("scan help category translation: %w", err)
		}
		if index, ok := categoryIndexByID[categoryID]; ok {
			categories[index].Translations[locale] = translation
		}
	}
	if err := rows.Err(); err != nil {
		return fmt.Errorf("iterate help category translations: %w", err)
	}
	return nil
}

func (r *PGRepository) ListSavedReplies(ctx context.Context, filter app.SupportSavedReplyFilter) ([]app.SupportSavedReply, error) {
	const query = `
		SELECT id, category, status, tags, translations, sort_order, created_at, updated_at
		FROM support_saved_replies
		WHERE ($1 = '' OR status = $1)
			AND ($2 = '' OR category = $2)
		ORDER BY sort_order ASC, id ASC
		LIMIT $3 OFFSET $4
	`
	limit := filter.Limit
	if limit <= 0 {
		limit = 1000
	}
	rows, err := r.pool.Query(ctx, query, string(filter.Status), filter.Category, limit, filter.Offset)
	if err != nil {
		return nil, fmt.Errorf("select support saved replies: %w", err)
	}
	defer rows.Close()

	replies := make([]app.SupportSavedReply, 0)
	for rows.Next() {
		reply, err := scanSupportSavedReply(rows)
		if err != nil {
			return nil, err
		}
		replies = append(replies, reply)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("iterate support saved replies: %w", err)
	}
	return replies, nil
}

func (r *PGRepository) UpsertSavedReply(ctx context.Context, reply app.SupportSavedReply) error {
	translationsRaw, err := json.Marshal(reply.Translations)
	if err != nil {
		return fmt.Errorf("encode support saved reply translations: %w", err)
	}
	const query = `
		INSERT INTO support_saved_replies (
			id, category, status, tags, translations, sort_order, created_at, updated_at
		)
		VALUES ($1, $2, $3, $4, $5::jsonb, $6, $7, $8)
		ON CONFLICT (id) DO UPDATE SET
			category = EXCLUDED.category,
			status = EXCLUDED.status,
			tags = EXCLUDED.tags,
			translations = EXCLUDED.translations,
			sort_order = EXCLUDED.sort_order,
			updated_at = EXCLUDED.updated_at
	`
	if _, err := r.pool.Exec(ctx, query,
		reply.ID,
		reply.Category,
		string(reply.Status),
		reply.Tags,
		string(translationsRaw),
		reply.SortOrder,
		reply.CreatedAt,
		reply.UpdatedAt,
	); err != nil {
		return fmt.Errorf("upsert support saved reply: %w", err)
	}
	return nil
}

func (r *PGRepository) GetArticle(ctx context.Context, articleID string) (app.HelpArticle, []app.HelpArticleEvent, error) {
	const query = `
		SELECT id, COALESCE(category_id, ''), slug, status, version, owner_id, reviewer_id,
			COALESCE(visibility_rules, '{}'::jsonb), published_at, last_reviewed_at,
			created_at, updated_at
		FROM help_articles
		WHERE id = $1
	`
	article, err := scanHelpArticle(r.pool.QueryRow(ctx, query, articleID))
	if err != nil {
		if err == pgx.ErrNoRows {
			return app.HelpArticle{}, nil, app.ErrArticleNotFound
		}
		return app.HelpArticle{}, nil, err
	}

	articles := []app.HelpArticle{article}
	ids, articleIndexByID := indexArticles(articles)
	if err := r.loadTranslations(ctx, ids, articles, articleIndexByID); err != nil {
		return app.HelpArticle{}, nil, err
	}
	if err := r.loadSurfaces(ctx, ids, articles, articleIndexByID); err != nil {
		return app.HelpArticle{}, nil, err
	}
	if err := r.loadTags(ctx, ids, articles, articleIndexByID); err != nil {
		return app.HelpArticle{}, nil, err
	}
	if err := r.loadActions(ctx, ids, articles, articleIndexByID); err != nil {
		return app.HelpArticle{}, nil, err
	}
	if err := r.loadRelatedArticles(ctx, ids, articles, articleIndexByID); err != nil {
		return app.HelpArticle{}, nil, err
	}

	events, err := r.listArticleEvents(ctx, articleID)
	if err != nil {
		return app.HelpArticle{}, nil, err
	}
	return articles[0], events, nil
}

func (r *PGRepository) UpsertArticle(ctx context.Context, article app.HelpArticle, event app.HelpArticleEvent) error {
	visibilityRaw, err := json.Marshal(article.Visibility)
	if err != nil {
		return fmt.Errorf("encode help article visibility: %w", err)
	}
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return fmt.Errorf("begin help article upsert: %w", err)
	}
	defer func() {
		_ = tx.Rollback(ctx)
	}()

	if article.CategoryID != "" {
		if _, err = tx.Exec(ctx, `
			INSERT INTO help_categories (id, slug, status, updated_at)
			VALUES ($1, $1, 'published', $2)
			ON CONFLICT (id) DO UPDATE SET updated_at = EXCLUDED.updated_at
		`, article.CategoryID, article.UpdatedAt); err != nil {
			return fmt.Errorf("upsert help category: %w", err)
		}
	}

	var categoryID any
	if article.CategoryID != "" {
		categoryID = article.CategoryID
	}
	const upsertArticle = `
		INSERT INTO help_articles (
			id, category_id, slug, status, version, owner_id, reviewer_id, visibility_rules,
			published_at, last_reviewed_at, created_at, updated_at
		)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8::jsonb, $9, $10, $11, $12)
		ON CONFLICT (id) DO UPDATE SET
			category_id = EXCLUDED.category_id,
			slug = EXCLUDED.slug,
			status = EXCLUDED.status,
			version = EXCLUDED.version,
			owner_id = EXCLUDED.owner_id,
			reviewer_id = EXCLUDED.reviewer_id,
			visibility_rules = EXCLUDED.visibility_rules,
			published_at = EXCLUDED.published_at,
			last_reviewed_at = EXCLUDED.last_reviewed_at,
			updated_at = EXCLUDED.updated_at
	`
	if _, err = tx.Exec(ctx, upsertArticle,
		article.ID,
		categoryID,
		article.Slug,
		string(article.Status),
		article.Version,
		article.OwnerID,
		article.ReviewerID,
		string(visibilityRaw),
		article.PublishedAt,
		article.LastReviewedAt,
		article.CreatedAt,
		article.UpdatedAt,
	); err != nil {
		return fmt.Errorf("upsert help article: %w", err)
	}

	if err = replaceArticleTranslations(ctx, tx, article); err != nil {
		return err
	}
	if err = replaceArticleSurfaces(ctx, tx, article); err != nil {
		return err
	}
	if err = replaceArticleTags(ctx, tx, article); err != nil {
		return err
	}
	if err = replaceArticleActions(ctx, tx, article); err != nil {
		return err
	}
	if err = replaceArticleRelated(ctx, tx, article); err != nil {
		return err
	}
	if err = insertHelpArticleEvent(ctx, tx, event); err != nil {
		return err
	}
	if err = tx.Commit(ctx); err != nil {
		return fmt.Errorf("commit help article upsert: %w", err)
	}
	return nil
}

func (r *PGRepository) SaveHelpSearchEvent(ctx context.Context, event app.HelpSearchEvent) error {
	const query = `
		INSERT INTO help_search_events (query, locale, surface, result_count, created_at)
		VALUES ($1, $2, $3, $4, $5)
	`
	if _, err := r.pool.Exec(
		ctx,
		query,
		event.Query,
		event.Locale,
		string(event.Surface),
		event.ResultCount,
		event.CreatedAt,
	); err != nil {
		return fmt.Errorf("insert help search event: %w", err)
	}
	return nil
}

func (r *PGRepository) SaveArticleFeedback(ctx context.Context, feedback app.ArticleFeedback) error {
	const query = `
		INSERT INTO help_article_feedback (
			article_id, user_id, locale, helpful, reason, escalated_to_support, created_at, updated_at
		)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $7)
		ON CONFLICT (article_id, user_id) DO UPDATE SET
			locale = EXCLUDED.locale,
			helpful = EXCLUDED.helpful,
			reason = EXCLUDED.reason,
			escalated_to_support = EXCLUDED.escalated_to_support,
			updated_at = EXCLUDED.updated_at
	`
	_, err := r.pool.Exec(
		ctx,
		query,
		feedback.ArticleID,
		feedback.UserID,
		feedback.Locale,
		feedback.Helpful,
		feedback.Reason,
		feedback.EscalatedToSupport,
		feedback.CreatedAt,
	)
	if err != nil {
		return fmt.Errorf("insert help article feedback: %w", err)
	}
	return nil
}

func (r *PGRepository) CreateSupportTicket(ctx context.Context, ticket app.SupportTicket) error {
	normalizeSupportTicketPersistenceDefaults(&ticket)
	if ticket.Context == nil {
		ticket.Context = map[string]string{}
	}
	contextRaw, err := json.Marshal(ticket.Context)
	if err != nil {
		return fmt.Errorf("encode support ticket context: %w", err)
	}

	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return fmt.Errorf("begin support ticket transaction: %w", err)
	}
	defer func() {
		_ = tx.Rollback(ctx)
	}()

	const insertTicket = `
		INSERT INTO support_tickets (
			id, user_id, conversation_id, idempotency_key, category, status, priority, source, locale,
			priority_reason_codes, customer_segment, customer_segment_reason_codes, segment_refresh_status,
			user_nickname_snapshot, followers_count_snapshot, guide_status_snapshot, subscription_tier_snapshot,
			assignee_id, assignment_status, assignment_reason, assignment_reason_codes, assigned_at,
			context, last_message_at, created_at, updated_at
		)
		VALUES (
			$1, $2, $3, $4, $5, $6, $7, $8, $9,
			$10, $11, $12, $13,
			$14, $15, $16, $17,
			$18, $19, $20, $21, $22,
			$23::jsonb, $24, $25, $25
		)
	`
	if _, err = tx.Exec(
		ctx,
		insertTicket,
		ticket.ID,
		ticket.UserID,
		ticket.ConversationID,
		ticket.IdempotencyKey,
		string(ticket.Category),
		string(ticket.Status),
		string(ticket.Priority),
		ticket.Source,
		ticket.Locale,
		ticket.PriorityReasonCodes,
		string(ticket.CustomerSegment),
		ticket.CustomerSegmentReasonCodes,
		string(ticket.SegmentRefreshStatus),
		ticket.UserNicknameSnapshot,
		ticket.FollowersCountSnapshot,
		ticket.GuideStatusSnapshot,
		ticket.SubscriptionTierSnapshot,
		ticket.AssigneeID,
		string(ticket.AssignmentStatus),
		ticket.AssignmentReason,
		ticket.AssignmentReasonCodes,
		ticket.AssignedAt,
		string(contextRaw),
		ticket.LastMessageAt,
		ticket.CreatedAt,
	); err != nil {
		if isSupportTicketIdempotencyConflict(err) {
			return app.ErrSupportTicketAlreadyExists
		}
		return fmt.Errorf("insert support ticket: %w", err)
	}

	const insertEvent = `
		INSERT INTO support_ticket_events (
			ticket_id, actor_id, actor_type, event_type, payload, created_at
		)
		VALUES ($1, $2, 'user', 'ticket_created', $3::jsonb, $4)
	`
	eventPayload, err := json.Marshal(map[string]string{
		"category": string(ticket.Category),
		"source":   ticket.Source,
	})
	if err != nil {
		return fmt.Errorf("encode support ticket event: %w", err)
	}
	if _, err = tx.Exec(
		ctx,
		insertEvent,
		ticket.ID,
		ticket.UserID,
		string(eventPayload),
		ticket.CreatedAt,
	); err != nil {
		return fmt.Errorf("insert support ticket event: %w", err)
	}

	if err = tx.Commit(ctx); err != nil {
		return fmt.Errorf("commit support ticket transaction: %w", err)
	}
	return nil
}

func (r *PGRepository) FindSupportTicketByIdempotencyKey(ctx context.Context, userID string, idempotencyKey string) (app.SupportTicket, error) {
	const query = `
		SELECT id, user_id, conversation_id, idempotency_key, category, status, priority, source, locale,
			priority_reason_codes, customer_segment, customer_segment_reason_codes, segment_refresh_status,
			user_nickname_snapshot, followers_count_snapshot, guide_status_snapshot, COALESCE(subscription_tier_snapshot, ''),
			assignee_id, assignment_status, assignment_reason, assignment_reason_codes, assigned_at,
			context, first_response_at, resolved_at, last_message_at,
			COALESCE((
				SELECT COALESCE(
					NULLIF(event.payload->>'message_preview', ''),
					NULLIF(event.payload->>'message', ''),
					NULLIF(event.payload->>'resolution', ''),
					''
				)
				FROM support_ticket_events event
				WHERE event.ticket_id = support_tickets.id
					AND event.event_type IN ('user_replied', 'agent_replied', 'ticket_resolved')
				ORDER BY event.created_at DESC
				LIMIT 1
			), '') AS last_message_preview,
			created_at, updated_at
		FROM support_tickets
		WHERE user_id = $1 AND idempotency_key = $2 AND idempotency_key <> ''
	`
	ticket, err := scanSupportTicket(r.pool.QueryRow(ctx, query, userID, idempotencyKey))
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return app.SupportTicket{}, app.ErrSupportTicketNotFound
		}
		return app.SupportTicket{}, err
	}
	return ticket, nil
}

func (r *PGRepository) ListSupportTickets(ctx context.Context, filter app.SupportTicketFilter) ([]app.SupportTicket, error) {
	const query = `
		SELECT id, user_id, conversation_id, idempotency_key, category, status, priority, source, locale,
			priority_reason_codes, customer_segment, customer_segment_reason_codes, segment_refresh_status,
			user_nickname_snapshot, followers_count_snapshot, guide_status_snapshot, COALESCE(subscription_tier_snapshot, ''),
			assignee_id, assignment_status, assignment_reason, assignment_reason_codes, assigned_at,
			context, first_response_at, resolved_at, last_message_at,
			COALESCE((
				SELECT COALESCE(
					NULLIF(event.payload->>'message_preview', ''),
					NULLIF(event.payload->>'message', ''),
					NULLIF(event.payload->>'resolution', ''),
					''
				)
				FROM support_ticket_events event
				WHERE event.ticket_id = support_tickets.id
					AND event.event_type IN ('user_replied', 'agent_replied', 'ticket_resolved')
				ORDER BY event.created_at DESC
				LIMIT 1
			), '') AS last_message_preview,
			created_at, updated_at
		FROM support_tickets
		WHERE ($1 = '' OR status = $1)
			AND ($2 = '' OR category = $2)
			AND ($3 = '' OR priority = $3)
			AND ($4 = '' OR assignee_id = $4)
			AND ($5 = '' OR user_id = $5)
			AND (
				NOT $6::boolean
				OR (
					status NOT IN ('resolved', 'closed')
					AND (
						(
							first_response_at IS NULL
							AND now() > created_at + CASE priority
								WHEN 'urgent' THEN interval '10 minutes'
								WHEN 'high' THEN interval '20 minutes'
								ELSE interval '30 minutes'
							END
						)
						OR (
							first_response_at IS NOT NULL
							AND now() > created_at + CASE priority
								WHEN 'urgent' THEN interval '4 hours'
								WHEN 'high' THEN interval '12 hours'
								ELSE interval '24 hours'
							END
						)
					)
				)
			)
		ORDER BY
			CASE priority
				WHEN 'urgent' THEN 1
				WHEN 'high' THEN 2
				WHEN 'normal' THEN 3
				ELSE 4
			END,
			updated_at DESC,
			id ASC
		LIMIT $7 OFFSET $8
	`
	rows, err := r.pool.Query(
		ctx,
		query,
		string(filter.Status),
		string(filter.Category),
		string(filter.Priority),
		filter.AssigneeID,
		filter.UserID,
		filter.SLABreached,
		filter.Limit,
		filter.Offset,
	)
	if err != nil {
		return nil, fmt.Errorf("select support tickets: %w", err)
	}
	defer rows.Close()

	tickets := make([]app.SupportTicket, 0)
	for rows.Next() {
		ticket, err := scanSupportTicket(rows)
		if err != nil {
			return nil, err
		}
		tickets = append(tickets, ticket)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("iterate support tickets: %w", err)
	}
	return tickets, nil
}

func (r *PGRepository) GetSupportTicket(ctx context.Context, ticketID string) (app.SupportTicket, []app.SupportTicketEvent, error) {
	const ticketQuery = `
		SELECT id, user_id, conversation_id, idempotency_key, category, status, priority, source, locale,
			priority_reason_codes, customer_segment, customer_segment_reason_codes, segment_refresh_status,
			user_nickname_snapshot, followers_count_snapshot, guide_status_snapshot, COALESCE(subscription_tier_snapshot, ''),
			assignee_id, assignment_status, assignment_reason, assignment_reason_codes, assigned_at,
			context, first_response_at, resolved_at, last_message_at,
			COALESCE((
				SELECT COALESCE(
					NULLIF(event.payload->>'message_preview', ''),
					NULLIF(event.payload->>'message', ''),
					NULLIF(event.payload->>'resolution', ''),
					''
				)
				FROM support_ticket_events event
				WHERE event.ticket_id = support_tickets.id
					AND event.event_type IN ('user_replied', 'agent_replied', 'ticket_resolved')
				ORDER BY event.created_at DESC
				LIMIT 1
			), '') AS last_message_preview,
			created_at, updated_at
		FROM support_tickets
		WHERE id = $1
	`
	ticket, err := scanSupportTicket(r.pool.QueryRow(ctx, ticketQuery, ticketID))
	if err != nil {
		if err == pgx.ErrNoRows {
			return app.SupportTicket{}, nil, app.ErrSupportTicketNotFound
		}
		return app.SupportTicket{}, nil, err
	}

	const eventsQuery = `
		SELECT ticket_id, actor_id, actor_type, event_type, payload, created_at
		FROM support_ticket_events
		WHERE ticket_id = $1
		ORDER BY created_at ASC, id ASC
	`
	rows, err := r.pool.Query(ctx, eventsQuery, ticketID)
	if err != nil {
		return app.SupportTicket{}, nil, fmt.Errorf("select support ticket events: %w", err)
	}
	defer rows.Close()

	events := make([]app.SupportTicketEvent, 0)
	for rows.Next() {
		event, err := scanSupportTicketEvent(rows)
		if err != nil {
			return app.SupportTicket{}, nil, err
		}
		events = append(events, event)
	}
	if err := rows.Err(); err != nil {
		return app.SupportTicket{}, nil, fmt.Errorf("iterate support ticket events: %w", err)
	}
	return ticket, events, nil
}

func (r *PGRepository) UpdateSupportTicket(ctx context.Context, ticket app.SupportTicket, event app.SupportTicketEvent) error {
	normalizeSupportTicketPersistenceDefaults(&ticket)
	if ticket.Context == nil {
		ticket.Context = map[string]string{}
	}
	contextRaw, err := json.Marshal(ticket.Context)
	if err != nil {
		return fmt.Errorf("encode support ticket context: %w", err)
	}

	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return fmt.Errorf("begin support ticket update: %w", err)
	}
	defer func() {
		_ = tx.Rollback(ctx)
	}()

	const updateTicket = `
		UPDATE support_tickets
		SET conversation_id = $2,
			idempotency_key = $3,
			status = $4,
			priority = $5,
			priority_reason_codes = $6,
			customer_segment = $7,
			customer_segment_reason_codes = $8,
			segment_refresh_status = $9,
			user_nickname_snapshot = $10,
			followers_count_snapshot = $11,
			guide_status_snapshot = $12,
			subscription_tier_snapshot = $13,
			assignee_id = $14,
			assignment_status = $15,
			assignment_reason = $16,
			assignment_reason_codes = $17,
			assigned_at = $18,
			context = $19::jsonb,
			first_response_at = $20,
			resolved_at = $21,
			last_message_at = $22,
			updated_at = $23
		WHERE id = $1
	`
	tag, err := tx.Exec(
		ctx,
		updateTicket,
		ticket.ID,
		ticket.ConversationID,
		ticket.IdempotencyKey,
		string(ticket.Status),
		string(ticket.Priority),
		ticket.PriorityReasonCodes,
		string(ticket.CustomerSegment),
		ticket.CustomerSegmentReasonCodes,
		string(ticket.SegmentRefreshStatus),
		ticket.UserNicknameSnapshot,
		ticket.FollowersCountSnapshot,
		ticket.GuideStatusSnapshot,
		ticket.SubscriptionTierSnapshot,
		ticket.AssigneeID,
		string(ticket.AssignmentStatus),
		ticket.AssignmentReason,
		ticket.AssignmentReasonCodes,
		ticket.AssignedAt,
		string(contextRaw),
		ticket.FirstResponseAt,
		ticket.ResolvedAt,
		ticket.LastMessageAt,
		ticket.UpdatedAt,
	)
	if err != nil {
		return fmt.Errorf("update support ticket: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return app.ErrSupportTicketNotFound
	}
	if err = insertSupportTicketEvent(ctx, tx, event); err != nil {
		return err
	}
	if err = tx.Commit(ctx); err != nil {
		return fmt.Errorf("commit support ticket update: %w", err)
	}
	return nil
}

func (r *PGRepository) AppendSupportTicketEvent(ctx context.Context, event app.SupportTicketEvent) error {
	if err := insertSupportTicketEvent(ctx, r.pool, event); err != nil {
		return err
	}
	return nil
}

func (r *PGRepository) SaveSupportTicketCSAT(ctx context.Context, csat app.SupportTicketCSAT, event app.SupportTicketEvent) error {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return fmt.Errorf("begin support ticket csat transaction: %w", err)
	}
	defer func() {
		_ = tx.Rollback(ctx)
	}()

	const upsertCSAT = `
		INSERT INTO support_ticket_csat (ticket_id, user_id, rating, comment, created_at)
		VALUES ($1, $2, $3, $4, $5)
		ON CONFLICT (ticket_id) DO UPDATE SET
			user_id = EXCLUDED.user_id,
			rating = EXCLUDED.rating,
			comment = EXCLUDED.comment,
			created_at = EXCLUDED.created_at
	`
	if _, err = tx.Exec(ctx, upsertCSAT, csat.TicketID, csat.UserID, csat.Rating, csat.Comment, csat.CreatedAt); err != nil {
		return fmt.Errorf("upsert support ticket csat: %w", err)
	}
	if err = insertSupportTicketEvent(ctx, tx, event); err != nil {
		return err
	}
	if err = tx.Commit(ctx); err != nil {
		return fmt.Errorf("commit support ticket csat transaction: %w", err)
	}
	return nil
}

func (r *PGRepository) GetSupportUserSegment(ctx context.Context, userID string) (app.SupportUserSegment, error) {
	const query = `
		SELECT user_id, nickname, customer_segment, followers_count, is_guide, guide_status,
			is_public_figure, is_partner, manual_segment, manual_reason, COALESCE(subscription_tier, ''),
			reason_codes, refresh_status, updated_at, source_version
		FROM support_user_segments
		WHERE user_id = $1
	`
	segment, err := scanSupportUserSegment(r.pool.QueryRow(ctx, query, userID))
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return app.SupportUserSegment{}, app.ErrSupportUserSegmentNotFound
		}
		return app.SupportUserSegment{}, err
	}
	return segment, nil
}

func (r *PGRepository) UpsertSupportUserSegment(ctx context.Context, segment app.SupportUserSegment) error {
	const query = `
		INSERT INTO support_user_segments (
			user_id, nickname, customer_segment, followers_count, is_guide, guide_status,
			is_public_figure, is_partner, manual_segment, manual_reason, subscription_tier,
			reason_codes, refresh_status, updated_at, source_version
		)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15)
		ON CONFLICT (user_id) DO UPDATE SET
			nickname = EXCLUDED.nickname,
			customer_segment = EXCLUDED.customer_segment,
			followers_count = EXCLUDED.followers_count,
			is_guide = EXCLUDED.is_guide,
			guide_status = EXCLUDED.guide_status,
			is_public_figure = EXCLUDED.is_public_figure,
			is_partner = EXCLUDED.is_partner,
			manual_segment = EXCLUDED.manual_segment,
			manual_reason = EXCLUDED.manual_reason,
			subscription_tier = EXCLUDED.subscription_tier,
			reason_codes = EXCLUDED.reason_codes,
			refresh_status = EXCLUDED.refresh_status,
			updated_at = EXCLUDED.updated_at,
			source_version = EXCLUDED.source_version
	`
	_, err := r.pool.Exec(ctx, query,
		segment.UserID,
		segment.Nickname,
		string(segment.CustomerSegment),
		segment.FollowersCount,
		segment.IsGuide,
		segment.GuideStatus,
		segment.IsPublicFigure,
		segment.IsPartner,
		string(segment.ManualSegment),
		segment.ManualReason,
		segment.SubscriptionTier,
		segment.ReasonCodes,
		string(segment.RefreshStatus),
		segment.UpdatedAt,
		segment.SourceVersion,
	)
	if err != nil {
		return fmt.Errorf("upsert support user segment: %w", err)
	}
	return nil
}

func (r *PGRepository) ListSupportAgents(ctx context.Context, filter app.SupportAgentFilter) ([]app.SupportAgent, error) {
	const query = `
		SELECT staff_id, display_name, first_name, last_name, middle_name, status, languages, skills, level, max_active_load::float8, timezone, updated_at
		FROM support_agents
		WHERE ($1 = '' OR status = $1)
		ORDER BY status ASC, level DESC, staff_id ASC
		LIMIT $2 OFFSET $3
	`
	limit := filter.Limit
	if limit <= 0 {
		limit = 1000
	}
	rows, err := r.pool.Query(ctx, query, string(filter.Status), limit, filter.Offset)
	if err != nil {
		return nil, fmt.Errorf("select support agents: %w", err)
	}
	defer rows.Close()
	agents := make([]app.SupportAgent, 0)
	for rows.Next() {
		agent, err := scanSupportAgent(rows)
		if err != nil {
			return nil, err
		}
		agents = append(agents, agent)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("iterate support agents: %w", err)
	}
	return agents, nil
}

func (r *PGRepository) UpsertSupportAgent(ctx context.Context, agent app.SupportAgent) error {
	const query = `
		INSERT INTO support_agents (
			staff_id, display_name, first_name, last_name, middle_name, status, languages, skills, level, max_active_load, timezone, updated_at
		)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
		ON CONFLICT (staff_id) DO UPDATE SET
			display_name = EXCLUDED.display_name,
			first_name = EXCLUDED.first_name,
			last_name = EXCLUDED.last_name,
			middle_name = EXCLUDED.middle_name,
			status = EXCLUDED.status,
			languages = EXCLUDED.languages,
			skills = EXCLUDED.skills,
			level = EXCLUDED.level,
			max_active_load = EXCLUDED.max_active_load,
			timezone = EXCLUDED.timezone,
			updated_at = EXCLUDED.updated_at
	`
	skills := make([]string, 0, len(agent.Skills))
	for _, skill := range agent.Skills {
		skills = append(skills, string(skill))
	}
	_, err := r.pool.Exec(ctx, query,
		agent.StaffID,
		agent.DisplayName,
		agent.FirstName,
		agent.LastName,
		agent.MiddleName,
		string(agent.Status),
		agent.Languages,
		skills,
		string(agent.Level),
		agent.MaxActiveLoad,
		agent.Timezone,
		agent.UpdatedAt,
	)
	if err != nil {
		return fmt.Errorf("upsert support agent: %w", err)
	}
	return nil
}

func (r *PGRepository) GetHelpAnalytics(ctx context.Context, filter app.HelpAnalyticsFilter) (app.HelpAnalyticsSummary, error) {
	limit := filter.Limit
	if limit <= 0 {
		limit = 10
	}
	summary := app.HelpAnalyticsSummary{}
	if err := r.loadSearchAnalytics(ctx, limit, &summary.Searches); err != nil {
		return app.HelpAnalyticsSummary{}, err
	}
	if err := r.loadFeedbackAnalytics(ctx, limit, &summary.Feedback); err != nil {
		return app.HelpAnalyticsSummary{}, err
	}
	if err := r.loadTicketAnalytics(ctx, &summary.Tickets); err != nil {
		return app.HelpAnalyticsSummary{}, err
	}
	return summary, nil
}

func (r *PGRepository) loadSearchAnalytics(ctx context.Context, limit int, out *app.HelpSearchAnalytics) error {
	const totalsQuery = `
		SELECT count(*)::int, count(*) FILTER (WHERE result_count = 0)::int
		FROM help_search_events
	`
	if err := r.pool.QueryRow(ctx, totalsQuery).Scan(&out.Total, &out.WithoutResults); err != nil {
		return fmt.Errorf("select help search totals: %w", err)
	}
	if out.Total > 0 {
		out.SuccessRate = float64(out.Total-out.WithoutResults) / float64(out.Total)
	}

	const noResultQuery = `
		SELECT query, count(*)::int
		FROM help_search_events
		WHERE result_count = 0
		GROUP BY query
		ORDER BY count(*) DESC, query ASC
		LIMIT $1
	`
	noResultRows, err := r.pool.Query(ctx, noResultQuery, limit)
	if err != nil {
		return fmt.Errorf("select no-result help searches: %w", err)
	}
	out.TopNoResultQueries, err = scanHelpSearchQueryStats(noResultRows)
	if err != nil {
		return err
	}

	const repeatedQuery = `
		SELECT query, count(*)::int
		FROM help_search_events
		GROUP BY query
		HAVING count(*) > 1
		ORDER BY count(*) DESC, query ASC
		LIMIT $1
	`
	repeatedRows, err := r.pool.Query(ctx, repeatedQuery, limit)
	if err != nil {
		return fmt.Errorf("select repeated help searches: %w", err)
	}
	out.RepeatedQueries, err = scanHelpSearchQueryStats(repeatedRows)
	if err != nil {
		return err
	}
	return nil
}

func (r *PGRepository) loadFeedbackAnalytics(ctx context.Context, limit int, out *app.HelpFeedbackAnalytics) error {
	const totalsQuery = `
		SELECT
			count(*)::int,
			count(*) FILTER (WHERE helpful)::int,
			count(*) FILTER (WHERE NOT helpful)::int,
			count(*) FILTER (WHERE escalated_to_support)::int
		FROM help_article_feedback
	`
	if err := r.pool.QueryRow(ctx, totalsQuery).Scan(&out.Total, &out.Helpful, &out.NotHelpful, &out.Escalations); err != nil {
		return fmt.Errorf("select help feedback totals: %w", err)
	}
	if out.Total > 0 {
		out.NotHelpfulRate = float64(out.NotHelpful) / float64(out.Total)
	}

	const topNotHelpfulQuery = `
		SELECT article_id, count(*)::int, count(*) FILTER (WHERE escalated_to_support)::int
		FROM help_article_feedback
		WHERE NOT helpful
		GROUP BY article_id
		ORDER BY count(*) DESC, article_id ASC
		LIMIT $1
	`
	rows, err := r.pool.Query(ctx, topNotHelpfulQuery, limit)
	if err != nil {
		return fmt.Errorf("select not-helpful help articles: %w", err)
	}
	defer rows.Close()
	out.TopNotHelpfulArticles = make([]app.HelpArticleFeedbackStat, 0)
	for rows.Next() {
		var stat app.HelpArticleFeedbackStat
		if err := rows.Scan(&stat.ArticleID, &stat.Count, &stat.Escalations); err != nil {
			return fmt.Errorf("scan not-helpful help article: %w", err)
		}
		out.TopNotHelpfulArticles = append(out.TopNotHelpfulArticles, stat)
	}
	if err := rows.Err(); err != nil {
		return fmt.Errorf("iterate not-helpful help articles: %w", err)
	}
	return nil
}

func (r *PGRepository) loadTicketAnalytics(ctx context.Context, out *app.SupportTicketAnalytics) error {
	const query = `
		SELECT
			count(*)::int,
			count(*) FILTER (WHERE status NOT IN ('resolved', 'closed'))::int,
			count(*) FILTER (WHERE status = 'waiting_support')::int,
			count(*) FILTER (WHERE status = 'resolved')::int,
			count(*) FILTER (WHERE status = 'closed')::int,
			count(*) FILTER (WHERE priority = 'urgent')::int,
			COALESCE(avg(EXTRACT(EPOCH FROM (first_response_at - created_at))) FILTER (WHERE first_response_at IS NOT NULL), 0)::bigint,
			COALESCE(avg(EXTRACT(EPOCH FROM (resolved_at - created_at))) FILTER (WHERE resolved_at IS NOT NULL), 0)::bigint
		FROM support_tickets
	`
	if err := r.pool.QueryRow(ctx, query).Scan(
		&out.Total,
		&out.Open,
		&out.WaitingSupport,
		&out.Resolved,
		&out.Closed,
		&out.Urgent,
		&out.AverageFirstResponseSeconds,
		&out.AverageResolutionSeconds,
	); err != nil {
		return fmt.Errorf("select support ticket analytics: %w", err)
	}
	const csatQuery = `
		SELECT count(*)::int, COALESCE(avg(rating), 0)::float8
		FROM support_ticket_csat
	`
	if err := r.pool.QueryRow(ctx, csatQuery).Scan(&out.CSATResponses, &out.AverageCSAT); err != nil {
		return fmt.Errorf("select support ticket csat analytics: %w", err)
	}
	return nil
}

func scanHelpSearchQueryStats(rows pgx.Rows) ([]app.HelpSearchQueryStat, error) {
	defer rows.Close()
	stats := make([]app.HelpSearchQueryStat, 0)
	for rows.Next() {
		var stat app.HelpSearchQueryStat
		if err := rows.Scan(&stat.Query, &stat.Count); err != nil {
			return nil, fmt.Errorf("scan help search query stat: %w", err)
		}
		stats = append(stats, stat)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("iterate help search query stats: %w", err)
	}
	return stats, nil
}

func (r *PGRepository) listArticleEvents(ctx context.Context, articleID string) ([]app.HelpArticleEvent, error) {
	const query = `
		SELECT article_id, actor_id, actor_type, event_type, payload, created_at
		FROM help_article_events
		WHERE article_id = $1
		ORDER BY created_at ASC, id ASC
	`
	rows, err := r.pool.Query(ctx, query, articleID)
	if err != nil {
		return nil, fmt.Errorf("select help article events: %w", err)
	}
	defer rows.Close()

	events := make([]app.HelpArticleEvent, 0)
	for rows.Next() {
		event, err := scanHelpArticleEvent(rows)
		if err != nil {
			return nil, err
		}
		events = append(events, event)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("iterate help article events: %w", err)
	}
	return events, nil
}

func indexArticles(articles []app.HelpArticle) ([]string, map[string]int) {
	ids := make([]string, 0, len(articles))
	articleIndexByID := make(map[string]int, len(articles))
	for index, article := range articles {
		ids = append(ids, article.ID)
		articleIndexByID[article.ID] = index
	}
	return ids, articleIndexByID
}

func scanHelpCategory(scanner rowScanner) (app.HelpCategory, error) {
	var category app.HelpCategory
	var status string
	if err := scanner.Scan(
		&category.ID,
		&category.Slug,
		&status,
		&category.SortOrder,
		&category.CreatedAt,
		&category.UpdatedAt,
	); err != nil {
		return app.HelpCategory{}, fmt.Errorf("scan help category: %w", err)
	}
	category.Status = app.ArticleStatus(status)
	return category, nil
}

func scanSupportSavedReply(scanner rowScanner) (app.SupportSavedReply, error) {
	var reply app.SupportSavedReply
	var status string
	var translationsRaw []byte
	if err := scanner.Scan(
		&reply.ID,
		&reply.Category,
		&status,
		&reply.Tags,
		&translationsRaw,
		&reply.SortOrder,
		&reply.CreatedAt,
		&reply.UpdatedAt,
	); err != nil {
		return app.SupportSavedReply{}, fmt.Errorf("scan support saved reply: %w", err)
	}
	reply.Status = app.ArticleStatus(status)
	translations, err := decodeSupportSavedReplyTranslations(translationsRaw)
	if err != nil {
		return app.SupportSavedReply{}, fmt.Errorf("decode support saved reply translations %s: %w", reply.ID, err)
	}
	reply.Translations = translations
	return reply, nil
}

func decodeSupportSavedReplyTranslations(raw []byte) (map[string]app.SupportSavedReplyTranslation, error) {
	if len(raw) == 0 {
		return map[string]app.SupportSavedReplyTranslation{}, nil
	}
	translations := make(map[string]app.SupportSavedReplyTranslation)
	if err := json.Unmarshal(raw, &translations); err != nil {
		return nil, err
	}
	return translations, nil
}

func scanHelpArticle(scanner rowScanner) (app.HelpArticle, error) {
	var article app.HelpArticle
	var status string
	var visibilityRaw []byte
	var publishedAt pgtype.Timestamptz
	var lastReviewedAt pgtype.Timestamptz
	if err := scanner.Scan(
		&article.ID,
		&article.CategoryID,
		&article.Slug,
		&status,
		&article.Version,
		&article.OwnerID,
		&article.ReviewerID,
		&visibilityRaw,
		&publishedAt,
		&lastReviewedAt,
		&article.CreatedAt,
		&article.UpdatedAt,
	); err != nil {
		return app.HelpArticle{}, fmt.Errorf("scan help article: %w", err)
	}
	article.Status = app.ArticleStatus(status)
	article.Translations = make(map[string]app.ArticleTranslation)
	if err := decodeArticleVisibility(visibilityRaw, &article.Visibility); err != nil {
		return app.HelpArticle{}, fmt.Errorf("decode help article visibility %s: %w", article.ID, err)
	}
	if publishedAt.Valid {
		value := publishedAt.Time
		article.PublishedAt = &value
	}
	if lastReviewedAt.Valid {
		value := lastReviewedAt.Time
		article.LastReviewedAt = &value
	}
	return article, nil
}

func replaceArticleTranslations(ctx context.Context, tx pgx.Tx, article app.HelpArticle) error {
	if _, err := tx.Exec(ctx, `DELETE FROM help_article_translations WHERE article_id = $1`, article.ID); err != nil {
		return fmt.Errorf("delete help article translations: %w", err)
	}
	for locale, translation := range article.Translations {
		if _, err := tx.Exec(ctx, `
			INSERT INTO help_article_translations (article_id, locale, title, short_answer, body, updated_at)
			VALUES ($1, $2, $3, $4, $5, $6)
		`, article.ID, locale, translation.Title, translation.ShortAnswer, translation.Body, article.UpdatedAt); err != nil {
			return fmt.Errorf("insert help article translation: %w", err)
		}
	}
	return nil
}

func replaceArticleSurfaces(ctx context.Context, tx pgx.Tx, article app.HelpArticle) error {
	if _, err := tx.Exec(ctx, `DELETE FROM help_article_surfaces WHERE article_id = $1`, article.ID); err != nil {
		return fmt.Errorf("delete help article surfaces: %w", err)
	}
	for _, surface := range article.Surfaces {
		if _, err := tx.Exec(ctx, `
			INSERT INTO help_article_surfaces (article_id, surface)
			VALUES ($1, $2)
		`, article.ID, string(surface)); err != nil {
			return fmt.Errorf("insert help article surface: %w", err)
		}
	}
	return nil
}

func replaceArticleTags(ctx context.Context, tx pgx.Tx, article app.HelpArticle) error {
	if _, err := tx.Exec(ctx, `DELETE FROM help_article_tags WHERE article_id = $1`, article.ID); err != nil {
		return fmt.Errorf("delete help article tags: %w", err)
	}
	for _, tag := range article.Tags {
		if _, err := tx.Exec(ctx, `
			INSERT INTO help_article_tags (article_id, tag)
			VALUES ($1, $2)
		`, article.ID, tag); err != nil {
			return fmt.Errorf("insert help article tag: %w", err)
		}
	}
	return nil
}

func replaceArticleActions(ctx context.Context, tx pgx.Tx, article app.HelpArticle) error {
	if _, err := tx.Exec(ctx, `DELETE FROM help_article_actions WHERE article_id = $1`, article.ID); err != nil {
		return fmt.Errorf("delete help article actions: %w", err)
	}
	for index, action := range article.Actions {
		labelRaw := "{}"
		if action.Label != "" {
			raw, err := json.Marshal(map[string]string{"en": action.Label})
			if err != nil {
				return fmt.Errorf("encode help article action label: %w", err)
			}
			labelRaw = string(raw)
		}
		if _, err := tx.Exec(ctx, `
			INSERT INTO help_article_actions (article_id, action_type, target, label_translations, sort_order)
			VALUES ($1, $2, $3, $4::jsonb, $5)
		`, article.ID, string(action.Type), action.Target, labelRaw, index+1); err != nil {
			return fmt.Errorf("insert help article action: %w", err)
		}
	}
	return nil
}

func replaceArticleRelated(ctx context.Context, tx pgx.Tx, article app.HelpArticle) error {
	if _, err := tx.Exec(ctx, `DELETE FROM help_article_related_articles WHERE article_id = $1`, article.ID); err != nil {
		return fmt.Errorf("delete help article related articles: %w", err)
	}
	for index, relatedID := range article.RelatedArticleIDs {
		if _, err := tx.Exec(ctx, `
			INSERT INTO help_article_related_articles (article_id, related_article_id, sort_order)
			VALUES ($1, $2, $3)
		`, article.ID, relatedID, index+1); err != nil {
			return fmt.Errorf("insert help article related article: %w", err)
		}
	}
	return nil
}

func (r *PGRepository) loadTranslations(ctx context.Context, ids []string, articles []app.HelpArticle, articleIndexByID map[string]int) error {
	const query = `
		SELECT article_id, locale, title, short_answer, body
		FROM help_article_translations
		WHERE article_id = ANY($1::text[])
		ORDER BY article_id, locale
	`
	return r.eachRow(ctx, query, ids, func(rows pgx.Rows) error {
		var articleID string
		var locale string
		var translation app.ArticleTranslation
		if err := rows.Scan(
			&articleID,
			&locale,
			&translation.Title,
			&translation.ShortAnswer,
			&translation.Body,
		); err != nil {
			return fmt.Errorf("scan help article translation: %w", err)
		}
		if index, ok := articleIndexByID[articleID]; ok {
			articles[index].Translations[locale] = translation
		}
		return nil
	})
}

func (r *PGRepository) loadSurfaces(ctx context.Context, ids []string, articles []app.HelpArticle, articleIndexByID map[string]int) error {
	const query = `
		SELECT article_id, surface
		FROM help_article_surfaces
		WHERE article_id = ANY($1::text[])
		ORDER BY article_id, surface
	`
	return r.eachRow(ctx, query, ids, func(rows pgx.Rows) error {
		var articleID string
		var surface string
		if err := rows.Scan(&articleID, &surface); err != nil {
			return fmt.Errorf("scan help article surface: %w", err)
		}
		if index, ok := articleIndexByID[articleID]; ok {
			articles[index].Surfaces = append(articles[index].Surfaces, app.HelpSurface(surface))
		}
		return nil
	})
}

func (r *PGRepository) loadTags(ctx context.Context, ids []string, articles []app.HelpArticle, articleIndexByID map[string]int) error {
	const query = `
		SELECT article_id, tag
		FROM help_article_tags
		WHERE article_id = ANY($1::text[])
		ORDER BY article_id, tag
	`
	return r.eachRow(ctx, query, ids, func(rows pgx.Rows) error {
		var articleID string
		var tag string
		if err := rows.Scan(&articleID, &tag); err != nil {
			return fmt.Errorf("scan help article tag: %w", err)
		}
		if index, ok := articleIndexByID[articleID]; ok {
			articles[index].Tags = append(articles[index].Tags, tag)
		}
		return nil
	})
}

func (r *PGRepository) loadActions(ctx context.Context, ids []string, articles []app.HelpArticle, articleIndexByID map[string]int) error {
	const query = `
		SELECT article_id, action_type, target
		FROM help_article_actions
		WHERE article_id = ANY($1::text[])
		ORDER BY article_id, sort_order, id
	`
	return r.eachRow(ctx, query, ids, func(rows pgx.Rows) error {
		var articleID string
		var action app.ArticleAction
		var actionType string
		if err := rows.Scan(&articleID, &actionType, &action.Target); err != nil {
			return fmt.Errorf("scan help article action: %w", err)
		}
		action.Type = app.ArticleActionType(actionType)
		if index, ok := articleIndexByID[articleID]; ok {
			articles[index].Actions = append(articles[index].Actions, action)
		}
		return nil
	})
}

func (r *PGRepository) loadRelatedArticles(ctx context.Context, ids []string, articles []app.HelpArticle, articleIndexByID map[string]int) error {
	const query = `
		SELECT article_id, related_article_id
		FROM help_article_related_articles
		WHERE article_id = ANY($1::text[])
		ORDER BY article_id, sort_order, related_article_id
	`
	return r.eachRow(ctx, query, ids, func(rows pgx.Rows) error {
		var articleID string
		var relatedArticleID string
		if err := rows.Scan(&articleID, &relatedArticleID); err != nil {
			return fmt.Errorf("scan help article related item: %w", err)
		}
		if index, ok := articleIndexByID[articleID]; ok {
			articles[index].RelatedArticleIDs = append(articles[index].RelatedArticleIDs, relatedArticleID)
		}
		return nil
	})
}

func (r *PGRepository) eachRow(
	ctx context.Context,
	query string,
	ids []string,
	scan func(rows pgx.Rows) error,
) error {
	rows, err := r.pool.Query(ctx, query, ids)
	if err != nil {
		return fmt.Errorf("query help article relationship: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		if err := scan(rows); err != nil {
			return err
		}
	}
	if err := rows.Err(); err != nil {
		return fmt.Errorf("iterate help article relationship: %w", err)
	}
	return nil
}

func decodeArticleVisibility(raw []byte, out *app.ArticleVisibility) error {
	if len(raw) == 0 {
		return nil
	}
	var payload struct {
		UserStates      []string `json:"userStates"`
		PaymentStatuses []string `json:"paymentStatuses"`
	}
	if err := json.Unmarshal(raw, &payload); err != nil {
		return err
	}
	out.UserStates = append([]string(nil), payload.UserStates...)
	out.PaymentStatuses = append([]string(nil), payload.PaymentStatuses...)
	return nil
}

type rowScanner interface {
	Scan(dest ...any) error
}

func scanSupportTicket(scanner rowScanner) (app.SupportTicket, error) {
	var ticket app.SupportTicket
	var category string
	var status string
	var priority string
	var customerSegment string
	var segmentRefreshStatus string
	var assignmentStatus string
	var contextRaw []byte
	var firstResponseAt pgtype.Timestamptz
	var resolvedAt pgtype.Timestamptz
	var assignedAt pgtype.Timestamptz
	if err := scanner.Scan(
		&ticket.ID,
		&ticket.UserID,
		&ticket.ConversationID,
		&ticket.IdempotencyKey,
		&category,
		&status,
		&priority,
		&ticket.Source,
		&ticket.Locale,
		&ticket.PriorityReasonCodes,
		&customerSegment,
		&ticket.CustomerSegmentReasonCodes,
		&segmentRefreshStatus,
		&ticket.UserNicknameSnapshot,
		&ticket.FollowersCountSnapshot,
		&ticket.GuideStatusSnapshot,
		&ticket.SubscriptionTierSnapshot,
		&ticket.AssigneeID,
		&assignmentStatus,
		&ticket.AssignmentReason,
		&ticket.AssignmentReasonCodes,
		&assignedAt,
		&contextRaw,
		&firstResponseAt,
		&resolvedAt,
		&ticket.LastMessageAt,
		&ticket.LastMessagePreview,
		&ticket.CreatedAt,
		&ticket.UpdatedAt,
	); err != nil {
		return app.SupportTicket{}, fmt.Errorf("scan support ticket: %w", err)
	}
	ticket.Category = app.SupportTicketCategory(category)
	ticket.Status = app.SupportTicketStatus(status)
	ticket.Priority = app.SupportTicketPriority(priority)
	ticket.CustomerSegment = app.SupportCustomerSegment(customerSegment)
	ticket.SegmentRefreshStatus = app.SupportSegmentRefreshStatus(segmentRefreshStatus)
	ticket.AssignmentStatus = app.SupportAssignmentStatus(assignmentStatus)
	context, err := decodeStringMap(contextRaw)
	if err != nil {
		return app.SupportTicket{}, fmt.Errorf("decode support ticket context %s: %w", ticket.ID, err)
	}
	ticket.Context = context
	if assignedAt.Valid {
		value := assignedAt.Time
		ticket.AssignedAt = &value
	}
	if firstResponseAt.Valid {
		value := firstResponseAt.Time
		ticket.FirstResponseAt = &value
	}
	if resolvedAt.Valid {
		value := resolvedAt.Time
		ticket.ResolvedAt = &value
	}
	return ticket, nil
}

func normalizeSupportTicketPersistenceDefaults(ticket *app.SupportTicket) {
	if ticket.Priority == "" {
		ticket.Priority = app.SupportTicketPriorityNormal
	}
	if ticket.PriorityReasonCodes == nil {
		ticket.PriorityReasonCodes = []string{}
	}
	if ticket.CustomerSegment == "" {
		ticket.CustomerSegment = app.SupportCustomerSegmentStandard
	}
	if ticket.CustomerSegmentReasonCodes == nil {
		ticket.CustomerSegmentReasonCodes = []string{}
	}
	if ticket.SegmentRefreshStatus == "" {
		ticket.SegmentRefreshStatus = app.SupportSegmentRefreshStatusStale
	}
	if ticket.AssignmentReasonCodes == nil {
		ticket.AssignmentReasonCodes = []string{}
	}
	if ticket.AssignmentStatus == "" {
		if ticket.AssigneeID != "" {
			ticket.AssignmentStatus = app.SupportAssignmentStatusAssigned
		} else {
			ticket.AssignmentStatus = app.SupportAssignmentStatusNeedsAssignment
		}
	}
}

func scanSupportTicketEvent(scanner rowScanner) (app.SupportTicketEvent, error) {
	var event app.SupportTicketEvent
	var actorType string
	var payloadRaw []byte
	if err := scanner.Scan(
		&event.TicketID,
		&event.ActorID,
		&actorType,
		&event.EventType,
		&payloadRaw,
		&event.CreatedAt,
	); err != nil {
		return app.SupportTicketEvent{}, fmt.Errorf("scan support ticket event: %w", err)
	}
	event.ActorType = app.SupportActorType(actorType)
	payload, err := decodeStringMap(payloadRaw)
	if err != nil {
		return app.SupportTicketEvent{}, fmt.Errorf("decode support ticket event payload: %w", err)
	}
	event.Payload = payload
	return event, nil
}

func scanSupportUserSegment(scanner rowScanner) (app.SupportUserSegment, error) {
	var segment app.SupportUserSegment
	var customerSegment string
	var manualSegment string
	var refreshStatus string
	if err := scanner.Scan(
		&segment.UserID,
		&segment.Nickname,
		&customerSegment,
		&segment.FollowersCount,
		&segment.IsGuide,
		&segment.GuideStatus,
		&segment.IsPublicFigure,
		&segment.IsPartner,
		&manualSegment,
		&segment.ManualReason,
		&segment.SubscriptionTier,
		&segment.ReasonCodes,
		&refreshStatus,
		&segment.UpdatedAt,
		&segment.SourceVersion,
	); err != nil {
		return app.SupportUserSegment{}, fmt.Errorf("scan support user segment: %w", err)
	}
	segment.CustomerSegment = app.SupportCustomerSegment(customerSegment)
	segment.ManualSegment = app.SupportCustomerSegment(manualSegment)
	segment.RefreshStatus = app.SupportSegmentRefreshStatus(refreshStatus)
	return segment, nil
}

func scanSupportAgent(scanner rowScanner) (app.SupportAgent, error) {
	var agent app.SupportAgent
	var status string
	var skills []string
	var level string
	if err := scanner.Scan(
		&agent.StaffID,
		&agent.DisplayName,
		&agent.FirstName,
		&agent.LastName,
		&agent.MiddleName,
		&status,
		&agent.Languages,
		&skills,
		&level,
		&agent.MaxActiveLoad,
		&agent.Timezone,
		&agent.UpdatedAt,
	); err != nil {
		return app.SupportAgent{}, fmt.Errorf("scan support agent: %w", err)
	}
	agent.Status = app.SupportAgentStatus(status)
	agent.Skills = make([]app.SupportAgentSkill, 0, len(skills))
	for _, skill := range skills {
		agent.Skills = append(agent.Skills, app.SupportAgentSkill(skill))
	}
	agent.Level = app.SupportAgentLevel(level)
	return agent, nil
}

func scanHelpArticleEvent(scanner rowScanner) (app.HelpArticleEvent, error) {
	var event app.HelpArticleEvent
	var actorType string
	var payloadRaw []byte
	if err := scanner.Scan(
		&event.ArticleID,
		&event.ActorID,
		&actorType,
		&event.EventType,
		&payloadRaw,
		&event.CreatedAt,
	); err != nil {
		return app.HelpArticleEvent{}, fmt.Errorf("scan help article event: %w", err)
	}
	event.ActorType = app.SupportActorType(actorType)
	payload, err := decodeStringMap(payloadRaw)
	if err != nil {
		return app.HelpArticleEvent{}, fmt.Errorf("decode help article event payload: %w", err)
	}
	event.Payload = payload
	return event, nil
}

type eventInserter interface {
	Exec(ctx context.Context, sql string, arguments ...any) (pgconn.CommandTag, error)
}

func insertHelpArticleEvent(ctx context.Context, db eventInserter, event app.HelpArticleEvent) error {
	if event.Payload == nil {
		event.Payload = map[string]string{}
	}
	payloadRaw, err := json.Marshal(event.Payload)
	if err != nil {
		return fmt.Errorf("encode help article event payload: %w", err)
	}
	const query = `
		INSERT INTO help_article_events (
			article_id, actor_id, actor_type, event_type, payload, created_at
		)
		VALUES ($1, $2, $3, $4, $5::jsonb, $6)
	`
	if _, err = db.Exec(
		ctx,
		query,
		event.ArticleID,
		event.ActorID,
		string(event.ActorType),
		event.EventType,
		string(payloadRaw),
		event.CreatedAt,
	); err != nil {
		return fmt.Errorf("insert help article event: %w", err)
	}
	return nil
}

func insertSupportTicketEvent(ctx context.Context, db eventInserter, event app.SupportTicketEvent) error {
	if event.Payload == nil {
		event.Payload = map[string]string{}
	}
	payloadRaw, err := json.Marshal(event.Payload)
	if err != nil {
		return fmt.Errorf("encode support ticket event payload: %w", err)
	}
	const query = `
		INSERT INTO support_ticket_events (
			ticket_id, actor_id, actor_type, event_type, payload, created_at
		)
		VALUES ($1, $2, $3, $4, $5::jsonb, $6)
	`
	if _, err = db.Exec(
		ctx,
		query,
		event.TicketID,
		event.ActorID,
		string(event.ActorType),
		event.EventType,
		string(payloadRaw),
		event.CreatedAt,
	); err != nil {
		return fmt.Errorf("insert support ticket event: %w", err)
	}
	return nil
}

func isSupportTicketIdempotencyConflict(err error) bool {
	var pgErr *pgconn.PgError
	return errors.As(err, &pgErr) &&
		pgErr.Code == "23505" &&
		pgErr.ConstraintName == "idx_support_tickets_user_idempotency_key"
}

func decodeStringMap(raw []byte) (map[string]string, error) {
	if len(raw) == 0 {
		return map[string]string{}, nil
	}
	var payload map[string]string
	if err := json.Unmarshal(raw, &payload); err != nil {
		return nil, err
	}
	if payload == nil {
		return map[string]string{}, nil
	}
	return payload, nil
}
