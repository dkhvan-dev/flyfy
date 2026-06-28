package repository

import (
	"context"
	"testing"
	"time"

	"kz/inflap/backend/services/support-service/internal/app"
)

func TestMemoryRepositorySeedsUsefulContextualArticlesForEveryTargetSurface(t *testing.T) {
	repo := NewMemoryRepository(memoryRepositoryTestArticles())
	uc := app.NewHelpUseCase(repo, nil)

	cases := []struct {
		name    string
		surface app.HelpSurface
		tags    []string
	}{
		{name: "activity", surface: app.HelpSurfaceActivityDetails, tags: []string{"activities", "refunds"}},
		{name: "excursion", surface: app.HelpSurfaceExcursionDetails, tags: []string{"excursions", "guides"}},
		{name: "place", surface: app.HelpSurfacePlaceDetails, tags: []string{"places", "tickets"}},
		{name: "currency", surface: app.HelpSurfaceCurrencyConverter, tags: []string{"currency", "rates"}},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			result, err := uc.ListContextualArticles(context.Background(), app.ListContextualArticlesInput{
				Locale:  "ru",
				Surface: tc.surface,
				Tags:    tc.tags,
				Limit:   5,
			})
			if err != nil {
				t.Fatalf("ListContextualArticles returned error: %v", err)
			}
			if len(result.Items) == 0 {
				t.Fatalf("expected seeded contextual help for %s", tc.surface)
			}
			for _, item := range result.Items {
				if item.Title == "" || item.ShortAnswer == "" || item.Body == "" {
					t.Fatalf("article %s is not useful enough: %#v", item.ID, item)
				}
				if len(item.Actions) == 0 {
					t.Fatalf("article %s has no next-step action", item.ID)
				}
			}
		})
	}
}

func TestMemoryRepositorySearchArticlesFiltersPublishedLocaleSurfaceAndQuery(t *testing.T) {
	now := time.Date(2026, 6, 21, 12, 0, 0, 0, time.UTC)
	repo := NewMemoryRepository([]app.HelpArticle{
		{
			ID:        "refund-timing",
			Slug:      "refund-timing",
			Status:    app.ArticleStatusPublished,
			Tags:      []string{"payments", "refunds"},
			Surfaces:  []app.HelpSurface{app.HelpSurfaceHelpCenter},
			UpdatedAt: now,
			Translations: map[string]app.ArticleTranslation{
				"ru": {
					Title:       "Когда вернутся деньги?",
					ShortAnswer: "Возврат обычно занимает несколько банковских дней.",
					Body:        "Откройте детали платежа, чтобы проверить статус возврата.",
				},
			},
		},
		{
			ID:        "draft-refund",
			Slug:      "draft-refund",
			Status:    app.ArticleStatusDraft,
			Tags:      []string{"payments", "refunds"},
			Surfaces:  []app.HelpSurface{app.HelpSurfaceHelpCenter},
			UpdatedAt: now.Add(time.Hour),
			Translations: map[string]app.ArticleTranslation{
				"ru": {
					Title:       "Возврат черновик",
					ShortAnswer: "Не показывать.",
					Body:        "Эта статья еще не опубликована.",
				},
			},
		},
		{
			ID:        "currency-rate-source",
			Slug:      "currency-rate-source",
			Status:    app.ArticleStatusPublished,
			Tags:      []string{"currency"},
			Surfaces:  []app.HelpSurface{app.HelpSurfaceCurrencyConverter},
			UpdatedAt: now.Add(2 * time.Hour),
			Translations: map[string]app.ArticleTranslation{
				"ru": {
					Title:       "Почему курс отличается?",
					ShortAnswer: "Курс справочный.",
					Body:        "Банк может применять свои комиссии.",
				},
			},
		},
	})

	items, err := repo.SearchArticles(context.Background(), app.SearchArticleFilter{
		Locale:  "ru",
		Query:   "возврат деньги",
		Surface: app.HelpSurfaceHelpCenter,
		Limit:   1,
	})
	if err != nil {
		t.Fatalf("SearchArticles returned error: %v", err)
	}

	if len(items) != 1 {
		t.Fatalf("items len = %d, want 1: %#v", len(items), items)
	}
	if items[0].ID != "refund-timing" {
		t.Fatalf("first item ID = %q, want refund-timing", items[0].ID)
	}
}

func TestMemoryRepositoryTestArticlesHaveRequiredLocales(t *testing.T) {
	for _, article := range memoryRepositoryTestArticles() {
		if article.Status != app.ArticleStatusPublished {
			t.Fatalf("seed article %s must be published", article.ID)
		}
		for _, locale := range []string{"en", "ru", "kk"} {
			translation := article.Translations[locale]
			if translation.Title == "" || translation.ShortAnswer == "" || translation.Body == "" {
				t.Fatalf("article %s missing useful %s translation: %#v", article.ID, locale, translation)
			}
		}
	}
}

func memoryRepositoryTestArticles() []app.HelpArticle {
	updatedAt := time.Date(2026, 6, 20, 9, 0, 0, 0, time.UTC)
	return []app.HelpArticle{
		memoryRepositoryTestArticle(
			"activity-help",
			"activity-help",
			[]string{"activities", "refunds"},
			[]app.HelpSurface{app.HelpSurfaceHelpCenter, app.HelpSurfaceActivityDetails},
			app.ArticleActionOpenChat,
			"activity_organizer",
			updatedAt,
		),
		memoryRepositoryTestArticle(
			"excursion-help",
			"excursion-help",
			[]string{"excursions", "guides"},
			[]app.HelpSurface{app.HelpSurfaceHelpCenter, app.HelpSurfaceExcursionDetails},
			app.ArticleActionOpenChat,
			"guide",
			updatedAt,
		),
		memoryRepositoryTestArticle(
			"place-help",
			"place-help",
			[]string{"places", "tickets"},
			[]app.HelpSurface{app.HelpSurfaceHelpCenter, app.HelpSurfacePlaces, app.HelpSurfacePlaceDetails},
			app.ArticleActionContactSupport,
			"support",
			updatedAt,
		),
		memoryRepositoryTestArticle(
			"currency-rate-source",
			"currency-rate-source",
			[]string{"currency", "rates"},
			[]app.HelpSurface{app.HelpSurfaceHelpCenter, app.HelpSurfaceCurrencyConverter},
			app.ArticleActionContactSupport,
			"support",
			updatedAt,
		),
	}
}

func memoryRepositoryTestArticle(
	id string,
	slug string,
	tags []string,
	surfaces []app.HelpSurface,
	actionType app.ArticleActionType,
	actionTarget string,
	updatedAt time.Time,
) app.HelpArticle {
	return app.HelpArticle{
		ID:       id,
		Slug:     slug,
		Status:   app.ArticleStatusPublished,
		Tags:     tags,
		Surfaces: surfaces,
		Translations: map[string]app.ArticleTranslation{
			"en": {
				Title:       "Useful help answer",
				ShortAnswer: "A short practical answer for tests.",
				Body:        "A detailed answer with safe next steps for tests.",
			},
			"ru": {
				Title:       "Полезный ответ",
				ShortAnswer: "Короткий практичный ответ для тестов.",
				Body:        "Подробный ответ с безопасными следующими шагами для тестов.",
			},
			"kk": {
				Title:       "Пайдалы жауап",
				ShortAnswer: "Тесттерге арналған қысқа практикалық жауап.",
				Body:        "Тесттерге арналған қауіпсіз келесі қадамдары бар толық жауап.",
			},
		},
		Actions: []app.ArticleAction{
			{Type: actionType, Target: actionTarget},
		},
		UpdatedAt: updatedAt,
	}
}

func TestMemoryRepositoryPersistsFeedbackAndTicketsInMemory(t *testing.T) {
	repo := NewMemoryRepository(memoryRepositoryTestArticles())

	if err := repo.SaveArticleFeedback(context.Background(), app.ArticleFeedback{
		ArticleID:          "currency-rate-source",
		UserID:             "user-123",
		Helpful:            false,
		EscalatedToSupport: true,
	}); err != nil {
		t.Fatalf("SaveArticleFeedback returned error: %v", err)
	}
	if err := repo.CreateSupportTicket(context.Background(), app.SupportTicket{
		ID:       "ticket-1",
		UserID:   "user-123",
		Category: app.SupportTicketCategoryCurrency,
		Status:   app.SupportTicketStatusNew,
	}); err != nil {
		t.Fatalf("CreateSupportTicket returned error: %v", err)
	}

	if len(repo.Feedback()) != 1 {
		t.Fatalf("feedback len = %d, want 1", len(repo.Feedback()))
	}
	if len(repo.Tickets()) != 1 {
		t.Fatalf("tickets len = %d, want 1", len(repo.Tickets()))
	}

	_, events, err := repo.GetSupportTicket(context.Background(), "ticket-1")
	if err != nil {
		t.Fatalf("GetSupportTicket returned error: %v", err)
	}
	if len(events) != 1 {
		t.Fatalf("events len = %d, want 1", len(events))
	}
	if events[0].EventType != "ticket_created" ||
		events[0].ActorType != app.SupportActorTypeUser ||
		events[0].ActorID != "user-123" {
		t.Fatalf("created event = %#v", events[0])
	}
	if events[0].Payload["category"] != string(app.SupportTicketCategoryCurrency) {
		t.Fatalf("created event payload = %#v", events[0].Payload)
	}
}

func TestMemoryRepositoryUpsertsHelpArticleFeedbackPerArticleAndUser(t *testing.T) {
	repo := NewMemoryRepository(memoryRepositoryTestArticles())
	ctx := context.Background()

	if err := repo.SaveArticleFeedback(ctx, app.ArticleFeedback{
		ArticleID:          "currency-rate-source",
		UserID:             "user-123",
		Locale:             "ru",
		Helpful:            false,
		Reason:             "Нужен сотрудник",
		EscalatedToSupport: true,
		CreatedAt:          time.Date(2026, 6, 28, 10, 0, 0, 0, time.UTC),
	}); err != nil {
		t.Fatalf("SaveArticleFeedback first returned error: %v", err)
	}
	if err := repo.SaveArticleFeedback(ctx, app.ArticleFeedback{
		ArticleID:          "currency-rate-source",
		UserID:             "user-123",
		Locale:             "ru",
		Helpful:            true,
		Reason:             "Разобрался",
		EscalatedToSupport: false,
		CreatedAt:          time.Date(2026, 6, 28, 10, 5, 0, 0, time.UTC),
	}); err != nil {
		t.Fatalf("SaveArticleFeedback second returned error: %v", err)
	}

	feedback := repo.Feedback()
	if len(feedback) != 1 {
		t.Fatalf("feedback len = %d, want 1: %#v", len(feedback), feedback)
	}
	if !feedback[0].Helpful ||
		feedback[0].Reason != "Разобрался" ||
		feedback[0].EscalatedToSupport {
		t.Fatalf("feedback = %#v, want latest vote", feedback[0])
	}
}

func TestMemoryRepositoryListsAndUpsertsHelpCategories(t *testing.T) {
	repo := NewMemoryRepository(memoryRepositoryTestArticles())
	now := time.Date(2026, 6, 20, 12, 0, 0, 0, time.UTC)

	if err := repo.UpsertCategory(context.Background(), app.HelpCategory{
		ID:        "payments",
		Slug:      "payments",
		Status:    app.ArticleStatusPublished,
		SortOrder: 20,
		CreatedAt: now,
		UpdatedAt: now,
	}); err != nil {
		t.Fatalf("UpsertCategory(payments) returned error: %v", err)
	}
	if err := repo.UpsertCategory(context.Background(), app.HelpCategory{
		ID:        "activities",
		Slug:      "activities",
		Status:    app.ArticleStatusPublished,
		SortOrder: 10,
		CreatedAt: now,
		UpdatedAt: now,
	}); err != nil {
		t.Fatalf("UpsertCategory(activities) returned error: %v", err)
	}
	if err := repo.UpsertCategory(context.Background(), app.HelpCategory{
		ID:        "draft",
		Slug:      "draft",
		Status:    app.ArticleStatusDraft,
		SortOrder: 5,
		CreatedAt: now,
		UpdatedAt: now,
	}); err != nil {
		t.Fatalf("UpsertCategory(draft) returned error: %v", err)
	}

	categories, err := repo.ListCategories(context.Background(), app.HelpCategoryFilter{
		Status: app.ArticleStatusPublished,
		Limit:  10,
	})
	if err != nil {
		t.Fatalf("ListCategories returned error: %v", err)
	}
	if len(categories) != 2 {
		t.Fatalf("categories len = %d, want 2: %#v", len(categories), categories)
	}
	if categories[0].ID != "activities" || categories[1].ID != "payments" {
		t.Fatalf("categories order = %#v, want sort_order asc", categories)
	}

	updatedAt := now.Add(time.Hour)
	if err := repo.UpsertCategory(context.Background(), app.HelpCategory{
		ID:        "payments",
		Slug:      "payments-v2",
		Status:    app.ArticleStatusArchived,
		SortOrder: 30,
		CreatedAt: updatedAt,
		UpdatedAt: updatedAt,
	}); err != nil {
		t.Fatalf("UpsertCategory(update payments) returned error: %v", err)
	}
	archived, err := repo.ListCategories(context.Background(), app.HelpCategoryFilter{
		Status: app.ArticleStatusArchived,
		Limit:  10,
	})
	if err != nil {
		t.Fatalf("ListCategories(archived) returned error: %v", err)
	}
	if len(archived) != 1 || archived[0].Slug != "payments-v2" {
		t.Fatalf("archived categories = %#v", archived)
	}
	if !archived[0].CreatedAt.Equal(now) {
		t.Fatalf("updated category CreatedAt = %s, want original %s", archived[0].CreatedAt, now)
	}
}

func TestMemoryRepositoryListSupportTicketsFiltersSLABreachedTickets(t *testing.T) {
	repo := NewMemoryRepository(memoryRepositoryTestArticles())
	now := time.Now().UTC()
	firstResponseAt := now.Add(-23 * time.Hour)
	resolvedAt := now.Add(-time.Hour)
	tickets := []app.SupportTicket{
		{
			ID:            "breached-first-response",
			UserID:        "user-1",
			Status:        app.SupportTicketStatusNew,
			Priority:      app.SupportTicketPriorityNormal,
			CreatedAt:     now.Add(-31 * time.Minute),
			LastMessageAt: now.Add(-31 * time.Minute),
		},
		{
			ID:            "on-track-first-response",
			UserID:        "user-1",
			Status:        app.SupportTicketStatusNew,
			Priority:      app.SupportTicketPriorityNormal,
			CreatedAt:     now.Add(-10 * time.Minute),
			LastMessageAt: now.Add(-10 * time.Minute),
		},
		{
			ID:              "closed-old-ticket",
			UserID:          "user-1",
			Status:          app.SupportTicketStatusClosed,
			Priority:        app.SupportTicketPriorityUrgent,
			FirstResponseAt: &firstResponseAt,
			ResolvedAt:      &resolvedAt,
			CreatedAt:       now.Add(-48 * time.Hour),
			LastMessageAt:   resolvedAt,
		},
	}
	for _, ticket := range tickets {
		if err := repo.CreateSupportTicket(context.Background(), ticket); err != nil {
			t.Fatalf("CreateSupportTicket(%s) returned error: %v", ticket.ID, err)
		}
	}

	items, err := repo.ListSupportTickets(context.Background(), app.SupportTicketFilter{
		SLABreached: true,
		Limit:       10,
	})
	if err != nil {
		t.Fatalf("ListSupportTickets returned error: %v", err)
	}
	if len(items) != 1 || items[0].ID != "breached-first-response" {
		t.Fatalf("items = %#v, want only breached active ticket", items)
	}
}
