package repository

import (
	"context"
	"errors"
	"os"
	"testing"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"

	"kz/inflap/backend/services/support-service/internal/app"
)

func TestPGRepositoryImplementsHelpRepository(t *testing.T) {
	var _ app.HelpRepository = (*PGRepository)(nil)
}

func TestNormalizeSupportTicketPersistenceDefaultsKeepsArrayColumnsNonNull(t *testing.T) {
	ticket := app.SupportTicket{}

	normalizeSupportTicketPersistenceDefaults(&ticket)

	if ticket.PriorityReasonCodes == nil {
		t.Fatal("PriorityReasonCodes is nil, want empty slice for non-null PostgreSQL text[] column")
	}
	if ticket.CustomerSegmentReasonCodes == nil {
		t.Fatal("CustomerSegmentReasonCodes is nil, want empty slice for non-null PostgreSQL text[] column")
	}
	if ticket.AssignmentReasonCodes == nil {
		t.Fatal("AssignmentReasonCodes is nil, want empty slice for non-null PostgreSQL text[] column")
	}
}

func TestPGRepositoryPersistsHelpCenterDataAgainstLiveDatabase(t *testing.T) {
	dsn := os.Getenv("SUPPORT_SERVICE_REPOSITORY_TEST_DSN")
	if dsn == "" {
		t.Skip("set SUPPORT_SERVICE_REPOSITORY_TEST_DSN to run live repository test")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, dsn)
	if err != nil {
		t.Fatalf("connect postgres: %v", err)
	}
	defer pool.Close()

	if err := ensureSupportTestSchema(ctx, pool); err != nil {
		t.Fatalf("ensure schema: %v", err)
	}
	if err := truncateSupportTestData(ctx, pool); err != nil {
		t.Fatalf("truncate test data: %v", err)
	}
	if err := seedSupportTestArticle(ctx, pool); err != nil {
		t.Fatalf("seed article: %v", err)
	}

	repo := NewPGRepository(pool)
	articles, err := repo.ListArticles(ctx)
	if err != nil {
		t.Fatalf("ListArticles returned error: %v", err)
	}
	if len(articles) != 1 {
		t.Fatalf("articles len = %d, want 1: %#v", len(articles), articles)
	}
	article := articles[0]
	if article.ID != "activity-cancel-paid" {
		t.Fatalf("article ID = %q", article.ID)
	}
	if article.Translations["ru"].Title != "Как отменить активность?" {
		t.Fatalf("ru translation = %#v", article.Translations["ru"])
	}
	if len(article.Surfaces) != 2 || len(article.Tags) != 2 || len(article.Actions) != 2 {
		t.Fatalf("article relationships not loaded: %#v", article)
	}
	if article.Visibility.UserStates[0] != "paid" || article.Visibility.PaymentStatuses[0] != "captured" {
		t.Fatalf("visibility = %#v", article.Visibility)
	}

	feedback := app.ArticleFeedback{
		ArticleID:          "activity-cancel-paid",
		UserID:             "user-123",
		Locale:             "ru",
		Helpful:            false,
		Reason:             "Need support",
		EscalatedToSupport: true,
		CreatedAt:          time.Date(2026, 6, 20, 12, 0, 0, 0, time.UTC),
	}
	if err := repo.SaveArticleFeedback(ctx, feedback); err != nil {
		t.Fatalf("SaveArticleFeedback returned error: %v", err)
	}
	updatedFeedback := feedback
	updatedFeedback.Helpful = true
	updatedFeedback.Reason = "This helped"
	updatedFeedback.EscalatedToSupport = false
	updatedFeedback.CreatedAt = time.Date(2026, 6, 20, 12, 2, 0, 0, time.UTC)
	if err := repo.SaveArticleFeedback(ctx, updatedFeedback); err != nil {
		t.Fatalf("SaveArticleFeedback update returned error: %v", err)
	}
	if err := repo.SaveHelpSearchEvent(ctx, app.HelpSearchEvent{
		Query:       "refund money",
		Locale:      "en",
		Surface:     app.HelpSurfaceHelpCenter,
		ResultCount: 1,
		CreatedAt:   time.Date(2026, 6, 20, 12, 5, 0, 0, time.UTC),
	}); err != nil {
		t.Fatalf("SaveHelpSearchEvent returned error: %v", err)
	}
	if err := repo.SaveHelpSearchEvent(ctx, app.HelpSearchEvent{
		Query:       "visa chargeback",
		Locale:      "en",
		Surface:     app.HelpSurfaceHelpCenter,
		ResultCount: 0,
		CreatedAt:   time.Date(2026, 6, 20, 12, 6, 0, 0, time.UTC),
	}); err != nil {
		t.Fatalf("SaveHelpSearchEvent no-result returned error: %v", err)
	}

	ticket := app.SupportTicket{
		ID:             "support-user-123-20260620120000",
		UserID:         "user-123",
		IdempotencyKey: "create-ticket-request-123",
		Category:       app.SupportTicketCategoryActivities,
		Status:         app.SupportTicketStatusNew,
		Priority:       app.SupportTicketPriorityNormal,
		Source:         "activity_details",
		Locale:         "ru",
		Context:        map[string]string{"activity_id": "activity-456"},
		CreatedAt:      time.Date(2026, 6, 20, 12, 0, 0, 0, time.UTC),
		LastMessageAt:  time.Date(2026, 6, 20, 12, 0, 0, 0, time.UTC),
	}
	if err := repo.CreateSupportTicket(ctx, ticket); err != nil {
		t.Fatalf("CreateSupportTicket returned error: %v", err)
	}
	existing, err := repo.FindSupportTicketByIdempotencyKey(ctx, "user-123", "create-ticket-request-123")
	if err != nil {
		t.Fatalf("FindSupportTicketByIdempotencyKey returned error: %v", err)
	}
	if existing.ID != ticket.ID || existing.IdempotencyKey != "create-ticket-request-123" {
		t.Fatalf("existing ticket = %#v", existing)
	}
	duplicate := ticket
	duplicate.ID = "support-user-123-duplicate"
	if err := repo.CreateSupportTicket(ctx, duplicate); !errors.Is(err, app.ErrSupportTicketAlreadyExists) {
		t.Fatalf("duplicate CreateSupportTicket err = %v, want ErrSupportTicketAlreadyExists", err)
	}
	if _, err := repo.FindSupportTicketByIdempotencyKey(ctx, "user-123", "missing-request"); !errors.Is(err, app.ErrSupportTicketNotFound) {
		t.Fatalf("missing FindSupportTicketByIdempotencyKey err = %v, want ErrSupportTicketNotFound", err)
	}
	if err := repo.SaveSupportTicketCSAT(ctx, app.SupportTicketCSAT{
		TicketID:  ticket.ID,
		UserID:    "user-123",
		Rating:    5,
		Comment:   "Clear answer",
		CreatedAt: time.Date(2026, 6, 20, 12, 30, 0, 0, time.UTC),
	}, app.SupportTicketEvent{
		TicketID:  ticket.ID,
		ActorID:   "user-123",
		ActorType: app.SupportActorTypeUser,
		EventType: "ticket_csat_submitted",
		Payload:   map[string]string{"rating": "5"},
		CreatedAt: time.Date(2026, 6, 20, 12, 30, 0, 0, time.UTC),
	}); err != nil {
		t.Fatalf("SaveSupportTicketCSAT returned error: %v", err)
	}

	var feedbackCount int
	if err := pool.QueryRow(ctx, `SELECT count(*) FROM help_article_feedback`).Scan(&feedbackCount); err != nil {
		t.Fatalf("count feedback: %v", err)
	}
	if feedbackCount != 1 {
		t.Fatalf("feedback count = %d, want 1", feedbackCount)
	}
	var feedbackHelpful bool
	var feedbackReason string
	var feedbackEscalated bool
	if err := pool.QueryRow(ctx, `
		SELECT helpful, reason, escalated_to_support
		FROM help_article_feedback
		WHERE article_id = $1 AND user_id = $2
	`, feedback.ArticleID, feedback.UserID).Scan(&feedbackHelpful, &feedbackReason, &feedbackEscalated); err != nil {
		t.Fatalf("select feedback: %v", err)
	}
	if !feedbackHelpful || feedbackReason != "This helped" || feedbackEscalated {
		t.Fatalf("feedback row = helpful:%v reason:%q escalated:%v, want latest vote", feedbackHelpful, feedbackReason, feedbackEscalated)
	}

	var ticketContext map[string]string
	if err := pool.QueryRow(ctx, `SELECT context FROM support_tickets WHERE id = $1`, ticket.ID).Scan(&ticketContext); err != nil {
		t.Fatalf("select ticket context: %v", err)
	}
	if ticketContext["activity_id"] != "activity-456" {
		t.Fatalf("ticket context = %#v", ticketContext)
	}
	var csatRating int
	if err := pool.QueryRow(ctx, `SELECT rating FROM support_ticket_csat WHERE ticket_id = $1`, ticket.ID).Scan(&csatRating); err != nil {
		t.Fatalf("select csat rating: %v", err)
	}
	if csatRating != 5 {
		t.Fatalf("csat rating = %d, want 5", csatRating)
	}

	analytics, err := repo.GetHelpAnalytics(ctx, app.HelpAnalyticsFilter{Limit: 5})
	if err != nil {
		t.Fatalf("GetHelpAnalytics returned error: %v", err)
	}
	if analytics.Searches.Total != 2 || analytics.Searches.WithoutResults != 1 || analytics.Feedback.Escalations != 1 {
		t.Fatalf("analytics = %#v", analytics)
	}
	if analytics.Tickets.CSATResponses != 1 || analytics.Tickets.AverageCSAT != 5 {
		t.Fatalf("csat analytics = %#v", analytics.Tickets)
	}
}

func TestPGRepositorySearchArticlesAgainstLiveDatabase(t *testing.T) {
	dsn := os.Getenv("SUPPORT_SERVICE_REPOSITORY_READONLY_TEST_DSN")
	if dsn == "" {
		t.Skip("set SUPPORT_SERVICE_REPOSITORY_READONLY_TEST_DSN to run live readonly repository search test")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, dsn)
	if err != nil {
		t.Fatalf("connect postgres: %v", err)
	}
	defer pool.Close()

	repo := NewPGRepository(pool)
	articles, err := repo.SearchArticles(ctx, app.SearchArticleFilter{
		Locale:  "ru",
		Query:   "паспорт",
		Surface: app.HelpSurfaceHelpCenter,
		Limit:   20,
	})
	if err != nil {
		t.Fatalf("SearchArticles returned error: %v", err)
	}
	if len(articles) == 0 {
		t.Fatal("SearchArticles returned no articles for seeded tourist FAQ query")
	}
}

func ensureSupportTestSchema(ctx context.Context, pool *pgxpool.Pool) error {
	for _, migration := range []string{
		"../../../migrations/001_help_center_support.up.sql",
		"../../../migrations/002_help_article_events.up.sql",
		"../../../migrations/003_help_search_events.up.sql",
		"../../../migrations/004_support_ticket_csat.up.sql",
		"../../../migrations/005_support_ticket_idempotency.up.sql",
		"../../../migrations/006_support_saved_replies.up.sql",
		"../../../migrations/007_support_assignment_segments.up.sql",
		"../../../migrations/011_help_category_taxonomy.up.sql",
		"../../../migrations/012_seed_support_saved_replies.up.sql",
	} {
		up, err := os.ReadFile(migration)
		if err != nil {
			return err
		}
		if _, err = pool.Exec(ctx, string(up)); err != nil {
			return err
		}
	}
	return nil
}

func truncateSupportTestData(ctx context.Context, pool *pgxpool.Pool) error {
	_, err := pool.Exec(ctx, `
		TRUNCATE support_agents, support_user_segments, support_saved_replies, support_ticket_csat, support_ticket_events, support_tickets, help_article_events, help_search_events, help_article_feedback,
			help_category_translations,
			help_article_related_articles, help_article_actions, help_article_tags,
			help_article_surfaces, help_article_translations, help_articles,
			help_categories RESTART IDENTITY CASCADE
	`)
	return err
}

func seedSupportTestArticle(ctx context.Context, pool *pgxpool.Pool) error {
	_, err := pool.Exec(ctx, `
		INSERT INTO help_categories (id, slug, status)
		VALUES ('activities', 'activities', 'published');

		INSERT INTO help_articles (id, category_id, slug, status, visibility_rules, updated_at)
		VALUES (
			'activity-cancel-paid',
			'activities',
			'activity-cancel-paid',
			'published',
			'{"userStates":["paid"],"paymentStatuses":["captured"]}'::jsonb,
			'2026-06-20T09:00:00Z'
		);

		INSERT INTO help_article_translations (article_id, locale, title, short_answer, body)
		VALUES
			('activity-cancel-paid', 'ru', 'Как отменить активность?', 'Проверьте срок отмены.', 'Если отмена доступна, возврат начнется автоматически.'),
			('activity-cancel-paid', 'en', 'How do I cancel?', 'Check the cancellation window.', 'If cancellation is available, the refund starts automatically.');

		INSERT INTO help_article_surfaces (article_id, surface)
		VALUES
			('activity-cancel-paid', 'help_center'),
			('activity-cancel-paid', 'activity_details');

		INSERT INTO help_article_tags (article_id, tag)
		VALUES
			('activity-cancel-paid', 'activities'),
			('activity-cancel-paid', 'refunds');

		INSERT INTO help_article_actions (article_id, action_type, target, label_translations, sort_order)
		VALUES
			('activity-cancel-paid', 'open_chat', 'activity_organizer', '{"ru":"Открыть чат"}'::jsonb, 1),
			('activity-cancel-paid', 'contact_support', 'support', '{"ru":"Связаться с поддержкой"}'::jsonb, 2);
	`)
	return err
}
