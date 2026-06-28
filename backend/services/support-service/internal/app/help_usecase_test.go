package app

import (
	"context"
	"errors"
	"sort"
	"strings"
	"testing"
	"time"
)

func TestListContextualArticlesReturnsPublishedLocalizedActionableAnswers(t *testing.T) {
	repo := newFakeHelpRepository([]HelpArticle{
		{
			ID:       "activity-cancel-paid",
			Slug:     "activity-cancel-paid",
			Status:   ArticleStatusPublished,
			Tags:     []string{"activities", "payments", "refunds"},
			Surfaces: []HelpSurface{HelpSurfaceActivityDetails, HelpSurfaceHelpCenter},
			Visibility: ArticleVisibility{
				UserStates: []string{"paid"},
			},
			Translations: map[string]ArticleTranslation{
				"ru": {
					Title:       "Как отменить оплаченную активность?",
					ShortAnswer: "Откройте участие, проверьте срок бесплатной отмены и подтвердите отмену.",
					Body:        "Если отмена доступна, возврат запускается автоматически.",
				},
				"en": {
					Title:       "How do I cancel a paid activity?",
					ShortAnswer: "Open your booking, check the free-cancellation window, and confirm cancellation.",
					Body:        "If cancellation is available, the refund starts automatically.",
				},
			},
			Actions: []ArticleAction{
				{Type: ArticleActionOpenChat, Target: "activity_organizer"},
				{Type: ArticleActionContactSupport, Target: "support"},
			},
			RelatedArticleIDs: []string{"refund-timing"},
			UpdatedAt:         time.Date(2026, 6, 1, 10, 0, 0, 0, time.UTC),
		},
		{
			ID:       "activity-draft",
			Slug:     "activity-draft",
			Status:   ArticleStatusDraft,
			Tags:     []string{"activities"},
			Surfaces: []HelpSurface{HelpSurfaceActivityDetails},
			Translations: map[string]ArticleTranslation{
				"ru": {Title: "Черновик", ShortAnswer: "Не должен отображаться", Body: "Не опубликовано"},
			},
		},
		{
			ID:       "currency-rate-source",
			Slug:     "currency-rate-source",
			Status:   ArticleStatusPublished,
			Tags:     []string{"currency"},
			Surfaces: []HelpSurface{HelpSurfaceCurrencyConverter},
			Translations: map[string]ArticleTranslation{
				"ru": {Title: "Почему курс отличается?", ShortAnswer: "Курс справочный.", Body: "Банк может применять свой курс."},
			},
		},
	})
	uc := NewHelpUseCase(repo, fixedClock(time.Date(2026, 6, 20, 12, 0, 0, 0, time.UTC)))

	result, err := uc.ListContextualArticles(context.Background(), ListContextualArticlesInput{
		Locale:    "ru-KZ",
		Surface:   HelpSurfaceActivityDetails,
		Tags:      []string{"activities", "refunds"},
		UserState: "paid",
		Limit:     5,
	})
	if err != nil {
		t.Fatalf("ListContextualArticles returned error: %v", err)
	}

	if len(result.Items) != 1 {
		t.Fatalf("items len = %d, want 1: %#v", len(result.Items), result.Items)
	}
	item := result.Items[0]
	if item.ID != "activity-cancel-paid" {
		t.Fatalf("item ID = %q, want activity-cancel-paid", item.ID)
	}
	if item.Title != "Как отменить оплаченную активность?" {
		t.Fatalf("title = %q", item.Title)
	}
	if item.ShortAnswer == "" || item.Body == "" {
		t.Fatalf("expected actionable localized content, got %#v", item)
	}
	if len(item.Actions) != 2 {
		t.Fatalf("actions len = %d, want 2", len(item.Actions))
	}
	if item.Actions[0].Type != ArticleActionOpenChat || item.Actions[0].Target != "activity_organizer" {
		t.Fatalf("first action = %#v, want organizer chat", item.Actions[0])
	}
	if len(item.RelatedArticleIDs) != 1 || item.RelatedArticleIDs[0] != "refund-timing" {
		t.Fatalf("related articles = %#v", item.RelatedArticleIDs)
	}
}

func TestListContextualArticlesPrioritizesPopularHelpCenterAnswers(t *testing.T) {
	repo := newFakeHelpRepository([]HelpArticle{
		{
			ID:       "regular-newer-answer",
			Slug:     "regular-newer-answer",
			Status:   ArticleStatusPublished,
			Tags:     []string{"account"},
			Surfaces: []HelpSurface{HelpSurfaceHelpCenter},
			Translations: map[string]ArticleTranslation{
				"en": {
					Title:       "Regular account answer",
					ShortAnswer: "A regular help center answer.",
					Body:        "Regular content.",
				},
			},
			UpdatedAt: time.Date(2026, 6, 20, 12, 0, 0, 0, time.UTC),
		},
		{
			ID:       "popular-older-answer",
			Slug:     "popular-older-answer",
			Status:   ArticleStatusPublished,
			Tags:     []string{"popular", "account"},
			Surfaces: []HelpSurface{HelpSurfaceHelpCenter},
			Translations: map[string]ArticleTranslation{
				"en": {
					Title:       "Popular account answer",
					ShortAnswer: "A popular help center answer.",
					Body:        "Popular content.",
				},
			},
			UpdatedAt: time.Date(2026, 6, 1, 12, 0, 0, 0, time.UTC),
		},
	})
	uc := NewHelpUseCase(repo, fixedClock(time.Date(2026, 6, 20, 12, 0, 0, 0, time.UTC)))

	result, err := uc.ListContextualArticles(context.Background(), ListContextualArticlesInput{
		Locale:  "en",
		Surface: HelpSurfaceHelpCenter,
		Limit:   2,
	})
	if err != nil {
		t.Fatalf("ListContextualArticles returned error: %v", err)
	}
	if len(result.Items) != 2 {
		t.Fatalf("items len = %d, want 2: %#v", len(result.Items), result.Items)
	}
	if result.Items[0].ID != "popular-older-answer" {
		t.Fatalf("first item = %q, want popular-older-answer", result.Items[0].ID)
	}
}

func TestListContextualArticlesPaginatesAllAndFiltersByCategoryID(t *testing.T) {
	repo := newFakeHelpRepository([]HelpArticle{
		{
			ID:         "documents-1",
			CategoryID: "documents_visas_entry",
			Slug:       "documents-1",
			Status:     ArticleStatusPublished,
			Tags:       []string{"documents", "popular"},
			Surfaces:   []HelpSurface{HelpSurfaceHelpCenter},
			Translations: map[string]ArticleTranslation{
				"ru": {Title: "Документы 1", ShortAnswer: "Ответ 1", Body: "Тело 1"},
			},
			UpdatedAt: time.Date(2026, 6, 21, 10, 0, 0, 0, time.UTC),
		},
		{
			ID:         "documents-2",
			CategoryID: "documents_visas_entry",
			Slug:       "documents-2",
			Status:     ArticleStatusPublished,
			Tags:       []string{"documents", "popular"},
			Surfaces:   []HelpSurface{HelpSurfaceHelpCenter},
			Translations: map[string]ArticleTranslation{
				"ru": {Title: "Документы 2", ShortAnswer: "Ответ 2", Body: "Тело 2"},
			},
			UpdatedAt: time.Date(2026, 6, 20, 10, 0, 0, 0, time.UTC),
		},
		{
			ID:         "stay-1",
			CategoryID: "booking_accommodation",
			Slug:       "stay-1",
			Status:     ArticleStatusPublished,
			Tags:       []string{"accommodation", "popular"},
			Surfaces:   []HelpSurface{HelpSurfaceHelpCenter},
			Translations: map[string]ArticleTranslation{
				"ru": {Title: "Проживание 1", ShortAnswer: "Ответ 3", Body: "Тело 3"},
			},
			UpdatedAt: time.Date(2026, 6, 19, 10, 0, 0, 0, time.UTC),
		},
	})
	uc := NewHelpUseCase(repo, fixedClock(time.Date(2026, 6, 20, 12, 0, 0, 0, time.UTC)))

	all, err := uc.ListContextualArticles(context.Background(), ListContextualArticlesInput{
		Locale:  "ru",
		Surface: HelpSurfaceHelpCenter,
		Limit:   2,
		Offset:  0,
	})
	if err != nil {
		t.Fatalf("ListContextualArticles all returned error: %v", err)
	}
	if len(all.Items) != 2 || all.Total != 3 || !all.HasMore || all.NextOffset != 2 {
		t.Fatalf("all page = %#v, want 2/3 with next offset 2", all)
	}

	documents, err := uc.ListContextualArticles(context.Background(), ListContextualArticlesInput{
		Locale:     "ru",
		Surface:    HelpSurfaceHelpCenter,
		CategoryID: "documents_visas_entry",
		Limit:      10,
	})
	if err != nil {
		t.Fatalf("ListContextualArticles category returned error: %v", err)
	}
	if len(documents.Items) != 2 || documents.Total != 2 || documents.HasMore {
		t.Fatalf("documents page = %#v, want 2 documents and no next page", documents)
	}
	for _, item := range documents.Items {
		if item.ID == "stay-1" {
			t.Fatalf("category page leaked accommodation article: %#v", documents.Items)
		}
	}
}

func TestListHelpCategoriesReturnsPublishedCategoriesWithArticleCounts(t *testing.T) {
	repo := newFakeHelpRepository([]HelpArticle{
		{
			ID:         "documents-1",
			CategoryID: "documents_visas_entry",
			Slug:       "documents-1",
			Status:     ArticleStatusPublished,
			Surfaces:   []HelpSurface{HelpSurfaceHelpCenter},
			Translations: map[string]ArticleTranslation{
				"ru": {Title: "Документы", ShortAnswer: "Ответ", Body: "Тело"},
			},
		},
		{
			ID:         "draft-documents",
			CategoryID: "documents_visas_entry",
			Slug:       "draft-documents",
			Status:     ArticleStatusDraft,
			Surfaces:   []HelpSurface{HelpSurfaceHelpCenter},
			Translations: map[string]ArticleTranslation{
				"ru": {Title: "Черновик", ShortAnswer: "Ответ", Body: "Тело"},
			},
		},
		{
			ID:         "stay-1",
			CategoryID: "booking_accommodation",
			Slug:       "stay-1",
			Status:     ArticleStatusPublished,
			Surfaces:   []HelpSurface{HelpSurfaceActivityDetails},
			Translations: map[string]ArticleTranslation{
				"ru": {Title: "Активность", ShortAnswer: "Ответ", Body: "Тело"},
			},
		},
	})
	repo.categories = []HelpCategory{
		{ID: "documents_visas_entry", Slug: "documents-visas-entry", Status: ArticleStatusPublished, SortOrder: 10},
		{ID: "booking_accommodation", Slug: "booking-accommodation", Status: ArticleStatusPublished, SortOrder: 20},
		{ID: "empty_category", Slug: "empty-category", Status: ArticleStatusPublished, SortOrder: 30},
		{ID: "draft_category", Slug: "draft-category", Status: ArticleStatusDraft, SortOrder: 40},
	}
	repo.categories[0].Translations = map[string]HelpCategoryTranslation{
		"ru": {Title: "Документы и въезд"},
		"en": {Title: "Documents and entry"},
	}
	uc := NewHelpUseCase(repo, fixedClock(time.Date(2026, 6, 20, 12, 0, 0, 0, time.UTC)))

	result, err := uc.ListHelpCategories(context.Background(), ListHelpCategoriesInput{
		Locale:  "ru",
		Surface: HelpSurfaceHelpCenter,
	})
	if err != nil {
		t.Fatalf("ListHelpCategories returned error: %v", err)
	}

	if len(result.Items) != 1 {
		t.Fatalf("categories = %#v, want only categories with published localized help_center articles", result.Items)
	}
	if result.Items[0].ID != "documents_visas_entry" || result.Items[0].ArticleCount != 1 {
		t.Fatalf("category = %#v, want documents with count 1", result.Items[0])
	}
	if result.Items[0].Title != "Документы и въезд" {
		t.Fatalf("category title = %q, want localized database title", result.Items[0].Title)
	}
}

func TestSearchArticlesFindsLocalizedPublishedContent(t *testing.T) {
	repo := newFakeHelpRepository([]HelpArticle{
		{
			ID:       "refund-timing",
			Slug:     "refund-timing",
			Status:   ArticleStatusPublished,
			Tags:     []string{"payments", "refunds"},
			Surfaces: []HelpSurface{HelpSurfaceHelpCenter, HelpSurfaceActivityDetails},
			Translations: map[string]ArticleTranslation{
				"ru": {
					Title:       "Когда вернутся деньги?",
					ShortAnswer: "Возврат обычно занимает несколько банковских дней.",
					Body:        "Статус возврата можно проверить в деталях платежа.",
				},
			},
			Actions: []ArticleAction{{Type: ArticleActionContactSupport, Target: "support"}},
		},
		{
			ID:       "currency-rate-source",
			Slug:     "currency-rate-source",
			Status:   ArticleStatusPublished,
			Tags:     []string{"currency"},
			Surfaces: []HelpSurface{HelpSurfaceCurrencyConverter},
			Translations: map[string]ArticleTranslation{
				"ru": {
					Title:       "Почему курс отличается от банка?",
					ShortAnswer: "Курс в Inflap справочный.",
					Body:        "Банк или обменник может применять свой курс и комиссии.",
				},
			},
		},
	})
	uc := NewHelpUseCase(repo, fixedClock(time.Now()))

	result, err := uc.SearchArticles(context.Background(), SearchArticlesInput{
		Locale:  "ru",
		Query:   "возврат деньги",
		Surface: HelpSurfaceHelpCenter,
		Limit:   10,
	})
	if err != nil {
		t.Fatalf("SearchArticles returned error: %v", err)
	}

	if len(result.Items) != 1 {
		t.Fatalf("items len = %d, want 1: %#v", len(result.Items), result.Items)
	}
	if result.Items[0].ID != "refund-timing" {
		t.Fatalf("first item ID = %q, want refund-timing", result.Items[0].ID)
	}
}

func TestSearchArticlesDelegatesSearchToRepositoryInsteadOfScanningAllArticles(t *testing.T) {
	repo := newFakeHelpRepository([]HelpArticle{
		{
			ID:       "refund-timing",
			Slug:     "refund-timing",
			Status:   ArticleStatusPublished,
			Tags:     []string{"payments", "refunds"},
			Surfaces: []HelpSurface{HelpSurfaceHelpCenter},
			Translations: map[string]ArticleTranslation{
				"en": {
					Title:       "Refund timing",
					ShortAnswer: "Refunds usually take a few banking days.",
					Body:        "Open payment details to check the refund status.",
				},
			},
		},
	})
	uc := NewHelpUseCase(repo, fixedClock(time.Date(2026, 6, 21, 12, 0, 0, 0, time.UTC)))

	result, err := uc.SearchArticles(context.Background(), SearchArticlesInput{
		Locale:  "en",
		Query:   " Refund timing ",
		Surface: HelpSurfaceHelpCenter,
		Limit:   3,
	})
	if err != nil {
		t.Fatalf("SearchArticles returned error: %v", err)
	}

	if len(result.Items) != 1 || result.Items[0].ID != "refund-timing" {
		t.Fatalf("items = %#v, want refund-timing", result.Items)
	}
	if repo.listArticlesCalls != 0 {
		t.Fatalf("ListArticles calls = %d, want 0; search must use repository search/FTS path", repo.listArticlesCalls)
	}
	if repo.searchArticlesCalls != 1 {
		t.Fatalf("SearchArticles repository calls = %d, want 1", repo.searchArticlesCalls)
	}
	if repo.lastSearchArticleFilter.Query != "refund timing" ||
		repo.lastSearchArticleFilter.Locale != "en" ||
		repo.lastSearchArticleFilter.Surface != HelpSurfaceHelpCenter ||
		repo.lastSearchArticleFilter.Limit != 3 {
		t.Fatalf("repository search filter = %#v, want normalized locale/query/surface/limit", repo.lastSearchArticleFilter)
	}
	if len(repo.searchEvents) != 1 || repo.searchEvents[0].Query != "refund timing" || repo.searchEvents[0].ResultCount != 1 {
		t.Fatalf("search events = %#v, want normalized query analytics with one result", repo.searchEvents)
	}
}

func TestHelpAnalyticsTracksSearchFeedbackEscalationsAndTicketTiming(t *testing.T) {
	now := time.Date(2026, 6, 20, 12, 0, 0, 0, time.UTC)
	repo := newFakeHelpRepository([]HelpArticle{
		{
			ID:       "refund-timing",
			Slug:     "refund-timing",
			Status:   ArticleStatusPublished,
			Tags:     []string{"payments", "refunds"},
			Surfaces: []HelpSurface{HelpSurfaceHelpCenter},
			Translations: map[string]ArticleTranslation{
				"en": {
					Title:       "Refund money timing",
					ShortAnswer: "Refunds usually take a few banking days.",
					Body:        "Open payment details to check the current refund state.",
				},
			},
		},
	})
	uc := NewHelpUseCase(repo, fixedClock(now))

	if _, err := uc.SearchArticles(context.Background(), SearchArticlesInput{
		Locale:  "en",
		Query:   "refund money",
		Surface: HelpSurfaceHelpCenter,
		Limit:   10,
	}); err != nil {
		t.Fatalf("SearchArticles returned error: %v", err)
	}
	if _, err := uc.SearchArticles(context.Background(), SearchArticlesInput{
		Locale:  "en",
		Query:   "visa chargeback",
		Surface: HelpSurfaceHelpCenter,
		Limit:   10,
	}); err != nil {
		t.Fatalf("SearchArticles no-result returned error: %v", err)
	}
	if len(repo.searchEvents) != 2 {
		t.Fatalf("search events len = %d, want 2", len(repo.searchEvents))
	}
	if repo.searchEvents[1].Query != "visa chargeback" || repo.searchEvents[1].ResultCount != 0 {
		t.Fatalf("no-result search event = %#v", repo.searchEvents[1])
	}

	if err := uc.SubmitArticleFeedback(context.Background(), SubmitArticleFeedbackInput{
		ArticleID:          "refund-timing",
		UserID:             "user-123",
		Locale:             "en",
		Helpful:            false,
		Reason:             "Still need a person",
		EscalatedToSupport: true,
	}); err != nil {
		t.Fatalf("SubmitArticleFeedback returned error: %v", err)
	}

	createdAt := now.Add(-2 * time.Hour)
	firstResponseAt := createdAt.Add(15 * time.Minute)
	resolvedAt := createdAt.Add(90 * time.Minute)
	repo.tickets = []SupportTicket{
		{
			ID:              "ticket-resolved",
			UserID:          "user-123",
			Category:        SupportTicketCategoryPayments,
			Status:          SupportTicketStatusResolved,
			Priority:        SupportTicketPriorityNormal,
			Source:          "help_center",
			Locale:          "en",
			FirstResponseAt: &firstResponseAt,
			ResolvedAt:      &resolvedAt,
			CreatedAt:       createdAt,
			UpdatedAt:       resolvedAt,
			LastMessageAt:   resolvedAt,
		},
		{
			ID:            "ticket-waiting-support",
			UserID:        "user-456",
			Category:      SupportTicketCategoryTechnical,
			Status:        SupportTicketStatusWaitingSupport,
			Priority:      SupportTicketPriorityUrgent,
			Source:        "currency_converter",
			Locale:        "ru",
			CreatedAt:     now.Add(-30 * time.Minute),
			UpdatedAt:     now.Add(-25 * time.Minute),
			LastMessageAt: now.Add(-25 * time.Minute),
		},
	}
	repo.csat = []SupportTicketCSAT{
		{TicketID: "ticket-resolved", UserID: "user-123", Rating: 5, CreatedAt: now.Add(-5 * time.Minute)},
		{TicketID: "ticket-resolved-2", UserID: "user-456", Rating: 3, CreatedAt: now.Add(-3 * time.Minute)},
	}

	summary, err := uc.GetHelpAnalytics(context.Background(), GetHelpAnalyticsInput{Limit: 5})
	if err != nil {
		t.Fatalf("GetHelpAnalytics returned error: %v", err)
	}

	if !summary.GeneratedAt.Equal(now) {
		t.Fatalf("GeneratedAt = %v, want %v", summary.GeneratedAt, now)
	}
	if summary.Searches.Total != 2 || summary.Searches.WithoutResults != 1 || summary.Searches.SuccessRate != 0.5 {
		t.Fatalf("search analytics = %#v", summary.Searches)
	}
	if len(summary.Searches.TopNoResultQueries) != 1 || summary.Searches.TopNoResultQueries[0].Query != "visa chargeback" {
		t.Fatalf("top no-result queries = %#v", summary.Searches.TopNoResultQueries)
	}
	if summary.Feedback.Total != 1 || summary.Feedback.NotHelpful != 1 || summary.Feedback.Escalations != 1 {
		t.Fatalf("feedback analytics = %#v", summary.Feedback)
	}
	if len(summary.Feedback.TopNotHelpfulArticles) != 1 || summary.Feedback.TopNotHelpfulArticles[0].ArticleID != "refund-timing" {
		t.Fatalf("top not-helpful articles = %#v", summary.Feedback.TopNotHelpfulArticles)
	}
	if summary.Tickets.Total != 2 || summary.Tickets.Open != 1 || summary.Tickets.WaitingSupport != 1 ||
		summary.Tickets.Resolved != 1 || summary.Tickets.Urgent != 1 {
		t.Fatalf("ticket analytics = %#v", summary.Tickets)
	}
	if summary.Tickets.AverageFirstResponseSeconds != 900 || summary.Tickets.AverageResolutionSeconds != 5400 {
		t.Fatalf("ticket timing analytics = %#v", summary.Tickets)
	}
	if summary.Tickets.CSATResponses != 2 || summary.Tickets.AverageCSAT != 4 {
		t.Fatalf("ticket csat analytics = %#v", summary.Tickets)
	}
}

func TestAdminHelpCategoryWorkflowListsAndUpsertsCategories(t *testing.T) {
	now := time.Date(2026, 6, 20, 12, 0, 0, 0, time.UTC)
	repo := newFakeHelpRepository(nil)
	repo.categories = []HelpCategory{
		{
			ID:     "payments",
			Slug:   "payments",
			Status: ArticleStatusPublished,
			Translations: map[string]HelpCategoryTranslation{
				"en": {Title: "Payments"},
				"ru": {Title: "Деньги и карты"},
			},
			SortOrder: 20,
			CreatedAt: now.Add(-time.Hour),
			UpdatedAt: now.Add(-time.Hour),
		},
		{
			ID:        "draft-category",
			Slug:      "draft-category",
			Status:    ArticleStatusDraft,
			SortOrder: 90,
			CreatedAt: now.Add(-time.Hour),
			UpdatedAt: now.Add(-time.Hour),
		},
	}
	uc := NewHelpUseCase(repo, fixedClock(now))

	categories, err := uc.ListAdminHelpCategories(context.Background(), HelpCategoryFilter{
		Status: ArticleStatusPublished,
		Locale: "ru",
		Limit:  10,
	})
	if err != nil {
		t.Fatalf("ListAdminHelpCategories returned error: %v", err)
	}
	if len(categories) != 1 || categories[0].ID != "payments" {
		t.Fatalf("categories = %#v, want only published payments", categories)
	}
	if categories[0].Title != "Деньги и карты" {
		t.Fatalf("category title = %q, want localized Russian title", categories[0].Title)
	}

	category, err := uc.UpsertAdminHelpCategory(context.Background(), UpsertHelpCategoryInput{
		CategoryID: "safety",
		Slug:       "safety",
		Status:     ArticleStatusPublished,
		SortOrder:  10,
		ActorID:    "editor-1",
	})
	if err != nil {
		t.Fatalf("UpsertAdminHelpCategory returned error: %v", err)
	}
	if category.ID != "safety" ||
		category.Slug != "safety" ||
		category.Status != ArticleStatusPublished ||
		category.SortOrder != 10 ||
		!category.CreatedAt.Equal(now) ||
		!category.UpdatedAt.Equal(now) {
		t.Fatalf("category = %#v", category)
	}
	if len(repo.categories) != 3 {
		t.Fatalf("categories len = %d, want 3", len(repo.categories))
	}
}

func TestAdminSupportSavedReplyWorkflowListsAndUpsertsReplies(t *testing.T) {
	now := time.Date(2026, 6, 20, 12, 0, 0, 0, time.UTC)
	repo := newFakeHelpRepository(nil)
	repo.savedReplies = []SupportSavedReply{
		{
			ID:        "refund-status",
			Category:  "payments",
			Status:    ArticleStatusPublished,
			SortOrder: 20,
			Translations: map[string]SupportSavedReplyTranslation{
				"en": {Title: "Refund status", Body: "I checked your refund status."},
			},
			CreatedAt: now.Add(-time.Hour),
			UpdatedAt: now.Add(-time.Hour),
		},
		{
			ID:        "draft-reply",
			Category:  "payments",
			Status:    ArticleStatusDraft,
			SortOrder: 10,
			Translations: map[string]SupportSavedReplyTranslation{
				"en": {Title: "Draft", Body: "Draft body"},
			},
			CreatedAt: now.Add(-time.Hour),
			UpdatedAt: now.Add(-time.Hour),
		},
	}
	uc := NewHelpUseCase(repo, fixedClock(now))

	replies, err := uc.ListSupportSavedReplies(context.Background(), SupportSavedReplyFilter{
		Category: "payments",
		Status:   ArticleStatusPublished,
		Limit:    10,
	})
	if err != nil {
		t.Fatalf("ListSupportSavedReplies returned error: %v", err)
	}
	if len(replies) != 1 || replies[0].ID != "refund-status" {
		t.Fatalf("replies = %#v, want published refund-status", replies)
	}

	reply, err := uc.UpsertSupportSavedReply(context.Background(), UpsertSupportSavedReplyInput{
		ReplyID:   "meeting-point",
		ActorID:   "lead-1",
		Category:  "activities",
		Status:    ArticleStatusPublished,
		Tags:      []string{"meeting", "activity"},
		SortOrder: 5,
		Translations: map[string]SupportSavedReplyTranslation{
			"en": {Title: "Meeting point", Body: "Please open the activity details and check the meeting point block."},
			"ru": {Title: "Место встречи", Body: "Откройте детали активности и проверьте блок места встречи."},
		},
	})
	if err != nil {
		t.Fatalf("UpsertSupportSavedReply returned error: %v", err)
	}
	if reply.ID != "meeting-point" || reply.Category != "activities" || reply.Status != ArticleStatusPublished {
		t.Fatalf("reply = %#v", reply)
	}
	if reply.Translations["ru"].Body == "" || !reply.UpdatedAt.Equal(now) {
		t.Fatalf("reply translations/time = %#v", reply)
	}
}

func TestHelpContentWorkflowCreatesReviewsPublishesAndArchivesArticleWithAuditEvents(t *testing.T) {
	now := time.Date(2026, 6, 20, 12, 0, 0, 0, time.UTC)
	repo := newFakeHelpRepository(nil)
	uc := NewHelpUseCase(repo, fixedClock(now))

	draft, err := uc.UpsertHelpArticle(context.Background(), UpsertHelpArticleInput{
		ActorID: "editor-1",
		Article: HelpArticle{
			ID:         "refund-policy",
			Slug:       "refund-policy",
			CategoryID: "payments",
			Status:     ArticleStatusDraft,
			Tags:       []string{"payments", "refunds"},
			Surfaces:   []HelpSurface{HelpSurfaceHelpCenter, HelpSurfaceActivityDetails},
			Visibility: ArticleVisibility{PaymentStatuses: []string{"captured"}},
			Translations: map[string]ArticleTranslation{
				"en": {Title: "Refund policy", ShortAnswer: "Refund timing depends on the provider.", Body: "Open the booking to check the current refund state."},
				"ru": {Title: "Правила возврата", ShortAnswer: "Срок возврата зависит от провайдера.", Body: "Откройте бронирование, чтобы проверить актуальный статус возврата."},
				"kk": {Title: "Қайтарым ережелері", ShortAnswer: "Қайтарым мерзімі провайдерге байланысты.", Body: "Ағымдағы қайтарым мәртебесін тексеру үшін брондауды ашыңыз."},
			},
			Actions: []ArticleAction{{Type: ArticleActionContactSupport, Target: "support"}},
		},
	})
	if err != nil {
		t.Fatalf("UpsertHelpArticle returned error: %v", err)
	}
	if draft.Status != ArticleStatusDraft || draft.OwnerID != "editor-1" || draft.Version != 1 {
		t.Fatalf("draft = %#v, want draft v1 owned by editor-1", draft)
	}

	review, err := uc.SubmitHelpArticleForReview(context.Background(), "refund-policy", "editor-1")
	if err != nil {
		t.Fatalf("SubmitHelpArticleForReview returned error: %v", err)
	}
	if review.Status != ArticleStatusReview {
		t.Fatalf("review status = %q, want review", review.Status)
	}

	published, err := uc.PublishHelpArticle(context.Background(), "refund-policy", "publisher-1")
	if err != nil {
		t.Fatalf("PublishHelpArticle returned error: %v", err)
	}
	if published.Status != ArticleStatusPublished ||
		published.ReviewerID != "publisher-1" ||
		published.PublishedAt == nil ||
		published.LastReviewedAt == nil {
		t.Fatalf("published article = %#v", published)
	}

	archived, err := uc.ArchiveHelpArticle(context.Background(), "refund-policy", "publisher-1")
	if err != nil {
		t.Fatalf("ArchiveHelpArticle returned error: %v", err)
	}
	if archived.Status != ArticleStatusArchived {
		t.Fatalf("archived status = %q, want archived", archived.Status)
	}

	eventTypes := make([]string, 0, len(repo.articleEvents))
	for _, event := range repo.articleEvents {
		eventTypes = append(eventTypes, event.EventType)
		if event.ActorID == "" {
			t.Fatalf("article event missing actor: %#v", event)
		}
	}
	want := []string{"article_upserted", "article_submitted_for_review", "article_published", "article_archived"}
	if len(eventTypes) != len(want) {
		t.Fatalf("event types = %#v, want %#v", eventTypes, want)
	}
	for i := range want {
		if eventTypes[i] != want[i] {
			t.Fatalf("event types = %#v, want %#v", eventTypes, want)
		}
	}
}

func TestPublishHelpArticleRequiresAllSupportedLocales(t *testing.T) {
	now := time.Date(2026, 6, 20, 12, 0, 0, 0, time.UTC)
	repo := newFakeHelpRepository([]HelpArticle{
		{
			ID:       "partial-article",
			Slug:     "partial-article",
			Status:   ArticleStatusReview,
			Surfaces: []HelpSurface{HelpSurfaceHelpCenter},
			Translations: map[string]ArticleTranslation{
				"en": {Title: "Partial article", ShortAnswer: "Only English exists.", Body: "This is not enough for publication."},
			},
		},
	})
	uc := NewHelpUseCase(repo, fixedClock(now))

	_, err := uc.PublishHelpArticle(context.Background(), "partial-article", "publisher-1")
	if !errors.Is(err, ErrInvalidHelpArticle) {
		t.Fatalf("err = %v, want ErrInvalidHelpArticle", err)
	}
	if repo.articles[0].Status != ArticleStatusReview {
		t.Fatalf("article status = %q, want unchanged review", repo.articles[0].Status)
	}
	if len(repo.articleEvents) != 0 {
		t.Fatalf("article events len = %d, want 0", len(repo.articleEvents))
	}
}

func TestFeedbackAndSupportTicketPreserveHelpfulContextWithoutSensitiveData(t *testing.T) {
	repo := newFakeHelpRepository([]HelpArticle{
		{
			ID:       "activity-cancel-paid",
			Slug:     "activity-cancel-paid",
			Status:   ArticleStatusPublished,
			Tags:     []string{"activities"},
			Surfaces: []HelpSurface{HelpSurfaceActivityDetails},
			Translations: map[string]ArticleTranslation{
				"en": {Title: "Cancel activity", ShortAnswer: "Cancel from details.", Body: "Refunds depend on timing."},
			},
		},
	})
	uc := NewHelpUseCase(repo, fixedClock(time.Date(2026, 6, 20, 12, 0, 0, 0, time.UTC)))

	if err := uc.SubmitArticleFeedback(context.Background(), SubmitArticleFeedbackInput{
		ArticleID:          "activity-cancel-paid",
		UserID:             "user-123",
		Locale:             "en",
		Helpful:            false,
		Reason:             "Still unclear",
		EscalatedToSupport: true,
	}); err != nil {
		t.Fatalf("SubmitArticleFeedback returned error: %v", err)
	}

	ticket, err := uc.CreateSupportTicket(context.Background(), CreateSupportTicketInput{
		UserID:   "user-123",
		Category: SupportTicketCategoryActivities,
		Source:   "activity_details",
		Locale:   "en",
		Context: map[string]string{
			"activity_id":        "activity-456",
			"article_id":         "activity-cancel-paid",
			"amount":             "15000",
			"city_id":            "almaty",
			"country_code":       "KZ",
			"failed_search":      "refund organizer",
			"from_currency":      "KZT",
			"locale":             "ru",
			"payment_id":         "payment-789",
			"screen":             "activity_details",
			"search_query":       "refund organizer",
			"to_currency":        "USD",
			"authorization":      "Bearer secret",
			"access_token":       "secret-token",
			"raw_request_header": "do-not-store",
		},
	})
	if err != nil {
		t.Fatalf("CreateSupportTicket returned error: %v", err)
	}

	if len(repo.feedback) != 1 {
		t.Fatalf("feedback len = %d, want 1", len(repo.feedback))
	}
	if !repo.feedback[0].EscalatedToSupport {
		t.Fatal("expected feedback to preserve escalation signal")
	}
	if ticket.UserID != "user-123" || ticket.Status != SupportTicketStatusNew {
		t.Fatalf("ticket = %#v, want new ticket for user-123", ticket)
	}
	if ticket.Context["activity_id"] != "activity-456" {
		t.Fatalf("activity context missing: %#v", ticket.Context)
	}
	if ticket.Context["payment_id"] != "payment-789" {
		t.Fatalf("payment context missing: %#v", ticket.Context)
	}
	if ticket.Context["locale"] != "ru" ||
		ticket.Context["search_query"] != "refund organizer" ||
		ticket.Context["city_id"] != "almaty" ||
		ticket.Context["country_code"] != "KZ" ||
		ticket.Context["from_currency"] != "KZT" ||
		ticket.Context["to_currency"] != "USD" ||
		ticket.Context["amount"] != "15000" ||
		ticket.Context["screen"] != "activity_details" {
		t.Fatalf("rich support context missing: %#v", ticket.Context)
	}
	if _, ok := ticket.Context["authorization"]; ok {
		t.Fatalf("sensitive authorization context was stored: %#v", ticket.Context)
	}
	if _, ok := ticket.Context["access_token"]; ok {
		t.Fatalf("sensitive access token context was stored: %#v", ticket.Context)
	}
	if len(repo.tickets) != 1 {
		t.Fatalf("tickets len = %d, want 1", len(repo.tickets))
	}
}

func TestCreateSupportTicketEnsuresSupportConversationWhenContextHasNoChat(t *testing.T) {
	now := time.Date(2026, 6, 20, 12, 0, 0, 0, time.UTC)
	repo := newFakeHelpRepository(nil)
	chat := &fakeSupportChatGateway{conversationID: "conversation-created"}
	uc := NewHelpUseCase(repo, fixedClock(now))
	uc.SetSupportChatGateway(chat)

	ticket, err := uc.CreateSupportTicket(context.Background(), CreateSupportTicketInput{
		UserID:   "user-123",
		Category: SupportTicketCategoryTechnical,
		Source:   "help_center",
		Locale:   "ru",
		Context: map[string]string{
			"article_id": "refund-timing",
		},
	})
	if err != nil {
		t.Fatalf("CreateSupportTicket returned error: %v", err)
	}

	if len(chat.conversationRequests) != 1 || chat.conversationRequests[0] != "user-123" {
		t.Fatalf("conversation requests = %#v, want user-123", chat.conversationRequests)
	}
	if ticket.ConversationID != "conversation-created" {
		t.Fatalf("conversation id = %q, want conversation-created", ticket.ConversationID)
	}
	if ticket.Context["conversation_id"] != "conversation-created" {
		t.Fatalf("ticket context = %#v, want conversation_id", ticket.Context)
	}
}

func TestCreateSupportTicketContinuesWhenSupportConversationUnavailable(t *testing.T) {
	now := time.Date(2026, 6, 20, 12, 0, 0, 0, time.UTC)
	repo := newFakeHelpRepository(nil)
	chat := &fakeSupportChatGateway{err: errors.New("chat unavailable")}
	uc := NewHelpUseCase(repo, fixedClock(now))
	uc.SetSupportChatGateway(chat)

	ticket, err := uc.CreateSupportTicket(context.Background(), CreateSupportTicketInput{
		UserID:   "user-123",
		Category: SupportTicketCategoryTechnical,
		Source:   "help_center",
		Locale:   "ru",
		Context: map[string]string{
			"article_id": "refund-timing",
		},
	})
	if err != nil {
		t.Fatalf("CreateSupportTicket returned error: %v", err)
	}

	if ticket.UserID != "user-123" || ticket.Status != SupportTicketStatusNew {
		t.Fatalf("ticket = %#v, want created ticket", ticket)
	}
	if ticket.ConversationID != "" {
		t.Fatalf("conversation id = %q, want empty when chat is unavailable", ticket.ConversationID)
	}
	if _, ok := ticket.Context["conversation_id"]; ok {
		t.Fatalf("ticket context = %#v, want no conversation_id", ticket.Context)
	}
	if len(repo.tickets) != 1 {
		t.Fatalf("tickets len = %d, want 1", len(repo.tickets))
	}
}

func TestCreateSupportTicketNotifiesSupportOperators(t *testing.T) {
	now := time.Date(2026, 6, 20, 12, 0, 0, 0, time.UTC)
	repo := newFakeHelpRepository(nil)
	notifier := &fakeSupportOperatorNotifier{}
	uc := NewHelpUseCase(repo, fixedClock(now))
	uc.SetSupportOperatorNotifier(notifier)

	ticket, err := uc.CreateSupportTicket(context.Background(), CreateSupportTicketInput{
		UserID:   "user-123",
		Category: SupportTicketCategoryActivities,
		Source:   "activity_details",
		Locale:   "en",
		Context:  map[string]string{"activity_id": "activity-456"},
	})
	if err != nil {
		t.Fatalf("CreateSupportTicket returned error: %v", err)
	}

	if len(notifier.inputs) != 1 {
		t.Fatalf("operator notifications = %#v, want one", notifier.inputs)
	}
	input := notifier.inputs[0]
	if input.IdempotencyKey != "support:ticket:"+ticket.ID+":created" {
		t.Fatalf("idempotency key = %q", input.IdempotencyKey)
	}
	if input.Priority != "normal" || input.Category != "support" {
		t.Fatalf("category/priority = %q/%q", input.Category, input.Priority)
	}
	if input.Data["event"] != "support_ticket_created" || input.Data["ticketId"] != ticket.ID || input.Data["activity_id"] != "activity-456" {
		t.Fatalf("notification data = %#v", input.Data)
	}
	if input.DeepLink != "/admin/support/tickets/"+ticket.ID {
		t.Fatalf("deep link = %q", input.DeepLink)
	}
}

func TestNotifySLABreachedTicketsNotifiesOnlyBreachedActiveTickets(t *testing.T) {
	now := time.Date(2026, 6, 20, 12, 0, 0, 0, time.UTC)
	repo := newFakeHelpRepository(nil)
	notifier := &fakeSupportOperatorNotifier{}
	repo.tickets = []SupportTicket{
		{
			ID:            "ticket-breached",
			UserID:        "user-123",
			Category:      SupportTicketCategoryPayments,
			Status:        SupportTicketStatusNew,
			Priority:      SupportTicketPriorityHigh,
			Source:        "payment_details",
			Locale:        "en",
			Context:       map[string]string{"payment_id": "payment-123"},
			CreatedAt:     now.Add(-21 * time.Minute),
			UpdatedAt:     now.Add(-21 * time.Minute),
			LastMessageAt: now.Add(-21 * time.Minute),
		},
		{
			ID:            "ticket-on-track",
			UserID:        "user-456",
			Category:      SupportTicketCategoryActivities,
			Status:        SupportTicketStatusNew,
			Priority:      SupportTicketPriorityNormal,
			Source:        "activity_details",
			CreatedAt:     now.Add(-10 * time.Minute),
			UpdatedAt:     now.Add(-10 * time.Minute),
			LastMessageAt: now.Add(-10 * time.Minute),
		},
	}
	uc := NewHelpUseCase(repo, fixedClock(now))
	uc.SetSupportOperatorNotifier(notifier)

	count, err := uc.NotifySLABreachedTickets(context.Background(), NotifySLABreachedTicketsInput{Limit: 10})
	if err != nil {
		t.Fatalf("NotifySLABreachedTickets returned error: %v", err)
	}
	if count != 1 {
		t.Fatalf("notified count = %d, want 1", count)
	}
	if len(notifier.inputs) != 1 {
		t.Fatalf("operator notifications = %#v, want one", notifier.inputs)
	}
	input := notifier.inputs[0]
	if input.IdempotencyKey != "support:ticket:ticket-breached:sla_breached" {
		t.Fatalf("idempotency key = %q", input.IdempotencyKey)
	}
	if input.Priority != "high" || input.Data["event"] != "support_ticket_sla_breached" || input.Data["sla"] != "breached" {
		t.Fatalf("notification input = %#v", input)
	}
	if input.Data["payment_id"] != "payment-123" {
		t.Fatalf("notification data = %#v", input.Data)
	}
}

func TestCreateSupportTicketUsesIdempotencyKeyToReturnExistingTicket(t *testing.T) {
	now := time.Date(2026, 6, 20, 12, 0, 0, 0, time.UTC)
	repo := newFakeHelpRepository(nil)
	chat := &fakeSupportChatGateway{conversationID: "conversation-created"}
	uc := NewHelpUseCase(repo, fixedClock(now))
	uc.SetSupportChatGateway(chat)

	first, err := uc.CreateSupportTicket(context.Background(), CreateSupportTicketInput{
		UserID:         "user-123",
		Category:       SupportTicketCategoryActivities,
		Source:         "activity_details",
		Locale:         "ru",
		IdempotencyKey: "create-ticket-request-123",
		Context:        map[string]string{"activity_id": "activity-456"},
	})
	if err != nil {
		t.Fatalf("first CreateSupportTicket returned error: %v", err)
	}

	second, err := uc.CreateSupportTicket(context.Background(), CreateSupportTicketInput{
		UserID:         "user-123",
		Category:       SupportTicketCategoryPayments,
		Source:         "payment_details",
		Locale:         "en",
		IdempotencyKey: " create-ticket-request-123 ",
		Context:        map[string]string{"payment_id": "payment-789"},
	})
	if err != nil {
		t.Fatalf("second CreateSupportTicket returned error: %v", err)
	}

	if second.ID != first.ID {
		t.Fatalf("second ticket id = %q, want existing %q", second.ID, first.ID)
	}
	if second.Category != SupportTicketCategoryActivities || second.Context["activity_id"] != "activity-456" {
		t.Fatalf("second ticket = %#v, want original ticket data", second)
	}
	if first.IdempotencyKey != "create-ticket-request-123" {
		t.Fatalf("idempotency key = %q", first.IdempotencyKey)
	}
	if len(repo.tickets) != 1 {
		t.Fatalf("tickets len = %d, want one idempotent ticket", len(repo.tickets))
	}
	if len(chat.conversationRequests) != 1 {
		t.Fatalf("conversation requests = %#v, want one chat conversation", chat.conversationRequests)
	}
}

func TestUserCanListGetAndCloseOnlyOwnSupportTickets(t *testing.T) {
	now := time.Date(2026, 6, 20, 12, 0, 0, 0, time.UTC)
	repo := newFakeHelpRepository(nil)
	repo.tickets = []SupportTicket{
		{
			ID:            "ticket-user-123",
			UserID:        "user-123",
			Category:      SupportTicketCategoryActivities,
			Status:        SupportTicketStatusWaitingUser,
			Priority:      SupportTicketPriorityNormal,
			Source:        "activity_details",
			Locale:        "ru",
			Context:       map[string]string{"activity_id": "activity-456"},
			CreatedAt:     now.Add(-time.Hour),
			UpdatedAt:     now.Add(-time.Hour),
			LastMessageAt: now.Add(-time.Hour),
		},
		{
			ID:            "ticket-user-456",
			UserID:        "user-456",
			Category:      SupportTicketCategoryPayments,
			Status:        SupportTicketStatusNew,
			Priority:      SupportTicketPriorityNormal,
			Source:        "payment_details",
			Locale:        "en",
			CreatedAt:     now.Add(-2 * time.Hour),
			UpdatedAt:     now.Add(-2 * time.Hour),
			LastMessageAt: now.Add(-2 * time.Hour),
		},
	}
	uc := NewHelpUseCase(repo, fixedClock(now))

	items, err := uc.ListUserSupportTickets(context.Background(), ListUserSupportTicketsInput{
		UserID: "user-123",
		Limit:  10,
	})
	if err != nil {
		t.Fatalf("ListUserSupportTickets returned error: %v", err)
	}
	if len(items) != 1 || items[0].ID != "ticket-user-123" {
		t.Fatalf("items = %#v, want only user-123 ticket", items)
	}

	detail, err := uc.GetUserSupportTicket(context.Background(), "user-123", "ticket-user-123")
	if err != nil {
		t.Fatalf("GetUserSupportTicket returned error: %v", err)
	}
	if detail.Ticket.ID != "ticket-user-123" || detail.Ticket.UserID != "user-123" {
		t.Fatalf("detail = %#v", detail)
	}

	_, err = uc.GetUserSupportTicket(context.Background(), "user-123", "ticket-user-456")
	if !errors.Is(err, ErrSupportTicketNotFound) {
		t.Fatalf("other user detail err = %v, want ErrSupportTicketNotFound", err)
	}

	closed, err := uc.CloseUserSupportTicket(context.Background(), CloseUserSupportTicketInput{
		UserID:   "user-123",
		TicketID: "ticket-user-123",
		Reason:   "Thanks, this helped.",
	})
	if err != nil {
		t.Fatalf("CloseUserSupportTicket returned error: %v", err)
	}
	if closed.Status != SupportTicketStatusClosed {
		t.Fatalf("closed status = %q, want closed", closed.Status)
	}
	if len(repo.events) != 1 {
		t.Fatalf("events len = %d, want 1", len(repo.events))
	}
	if repo.events[0].ActorType != SupportActorTypeUser || repo.events[0].ActorID != "user-123" || repo.events[0].EventType != "ticket_closed_by_user" {
		t.Fatalf("event = %#v, want user close event", repo.events[0])
	}
}

func TestGetOrCreateUserSupportConversationReturnsLatestUserContext(t *testing.T) {
	now := time.Date(2026, 6, 20, 12, 0, 0, 0, time.UTC)
	repo := newFakeHelpRepository(nil)
	repo.tickets = []SupportTicket{
		{
			ID:             "ticket-older",
			UserID:         "user-123",
			ConversationID: "conversation-older",
			Category:       SupportTicketCategoryTechnical,
			Status:         SupportTicketStatusResolved,
			Priority:       SupportTicketPriorityNormal,
			Source:         "help_center",
			Locale:         "en",
			CreatedAt:      now.Add(-48 * time.Hour),
			UpdatedAt:      now.Add(-47 * time.Hour),
			LastMessageAt:  now.Add(-47 * time.Hour),
		},
		{
			ID:             "ticket-latest",
			UserID:         "user-123",
			ConversationID: "conversation-latest",
			Category:       SupportTicketCategoryTechnical,
			Status:         SupportTicketStatusWaitingSupport,
			Priority:       SupportTicketPriorityHigh,
			Source:         "support_chat",
			Locale:         "ru",
			CreatedAt:      now.Add(-3 * time.Hour),
			UpdatedAt:      now.Add(-2 * time.Hour),
			LastMessageAt:  now.Add(-2 * time.Hour),
		},
		{
			ID:            "ticket-other-user",
			UserID:        "user-456",
			Category:      SupportTicketCategoryTechnical,
			Status:        SupportTicketStatusNew,
			CreatedAt:     now.Add(-time.Hour),
			UpdatedAt:     now.Add(-time.Hour),
			LastMessageAt: now.Add(-time.Hour),
		},
	}
	repo.events = []SupportTicketEvent{
		{
			TicketID:  "ticket-older",
			ActorID:   "user-123",
			ActorType: SupportActorTypeUser,
			EventType: "ticket_created",
			Payload:   map[string]string{"source": "help_center"},
			CreatedAt: now.Add(-48 * time.Hour),
		},
		{
			TicketID:  "ticket-older",
			ActorID:   "agent-1",
			ActorType: SupportActorTypeAgent,
			EventType: "ticket_resolved",
			Payload:   map[string]string{"resolution": "Готово."},
			CreatedAt: now.Add(-47 * time.Hour),
		},
		{
			TicketID:  "ticket-latest",
			ActorID:   "user-123",
			ActorType: SupportActorTypeUser,
			EventType: "ticket_created",
			Payload:   map[string]string{"source": "support_chat"},
			CreatedAt: now.Add(-3 * time.Hour),
		},
		{
			TicketID:  "ticket-latest",
			ActorID:   "user-123",
			ActorType: SupportActorTypeUser,
			EventType: "user_replied",
			Payload:   map[string]string{"message_preview": "Нужна помощь с оплатой."},
			CreatedAt: now.Add(-2 * time.Hour),
		},
	}
	uc := NewHelpUseCase(repo, fixedClock(now))

	detail, err := uc.GetOrCreateUserSupportConversation(context.Background(), GetOrCreateUserSupportConversationInput{
		UserID: "user-123",
		Locale: "ru",
	})
	if err != nil {
		t.Fatalf("GetOrCreateUserSupportConversation returned error: %v", err)
	}

	if detail.Ticket.ID != "ticket-latest" || detail.Ticket.ConversationID != "conversation-latest" {
		t.Fatalf("detail ticket = %#v, want latest user conversation", detail.Ticket)
	}
	if len(repo.tickets) != 3 {
		t.Fatalf("tickets len = %d, want no new ticket", len(repo.tickets))
	}
	if len(detail.Events) != 4 {
		t.Fatalf("events len = %d, want full user support conversation history", len(detail.Events))
	}
	if detail.Events[0].TicketID != "ticket-older" ||
		detail.Events[2].TicketID != "ticket-latest" {
		t.Fatalf("events = %#v, want chronological events across support episodes", detail.Events)
	}
}

func TestGetOrCreateUserSupportConversationCreatesInitialContext(t *testing.T) {
	now := time.Date(2026, 6, 20, 12, 0, 0, 0, time.UTC)
	repo := newFakeHelpRepository(nil)
	chat := &fakeSupportChatGateway{conversationID: "conversation-created"}
	uc := NewHelpUseCase(repo, fixedClock(now))
	uc.SetSupportChatGateway(chat)

	detail, err := uc.GetOrCreateUserSupportConversation(context.Background(), GetOrCreateUserSupportConversationInput{
		UserID: "user-123",
		Locale: "ru",
	})
	if err != nil {
		t.Fatalf("GetOrCreateUserSupportConversation returned error: %v", err)
	}

	if detail.Ticket.UserID != "user-123" ||
		detail.Ticket.Source != "support_chat" ||
		detail.Ticket.Category != SupportTicketCategoryTechnical ||
		detail.Ticket.ConversationID != "conversation-created" {
		t.Fatalf("detail ticket = %#v, want created support chat context", detail.Ticket)
	}
	if len(repo.tickets) != 1 {
		t.Fatalf("tickets len = %d, want one backing conversation ticket", len(repo.tickets))
	}
	if len(chat.conversationRequests) != 1 || chat.conversationRequests[0] != "user-123" {
		t.Fatalf("conversation requests = %#v, want user-123", chat.conversationRequests)
	}
}

func TestUserReplyToSupportTicketSendsMessageToChatAndWaitsSupport(t *testing.T) {
	now := time.Date(2026, 6, 20, 12, 0, 0, 0, time.UTC)
	repo := newFakeHelpRepository(nil)
	repo.tickets = []SupportTicket{
		{
			ID:             "ticket-user-123",
			UserID:         "user-123",
			ConversationID: "conversation-123",
			Category:       SupportTicketCategoryActivities,
			Status:         SupportTicketStatusWaitingUser,
			Priority:       SupportTicketPriorityNormal,
			Source:         "activity_details",
			Locale:         "ru",
			Context:        map[string]string{"activity_id": "activity-456"},
			CreatedAt:      now.Add(-time.Hour),
			UpdatedAt:      now.Add(-30 * time.Minute),
			LastMessageAt:  now.Add(-30 * time.Minute),
		},
	}
	chat := &fakeSupportChatGateway{messageID: "chat-message-user-1"}
	uc := NewHelpUseCase(repo, fixedClock(now))
	uc.SetSupportChatGateway(chat)

	replied, err := uc.ReplyToUserSupportTicket(context.Background(), ReplyToUserSupportTicketInput{
		UserID:         "user-123",
		TicketID:       "ticket-user-123",
		Message:        "Я загрузил чек, проверьте, пожалуйста.",
		FileIDs:        []string{"receipt-1", " ", "receipt-2", "receipt-1"},
		IdempotencyKey: "user-reply-request-123",
	})
	if err != nil {
		t.Fatalf("ReplyToUserSupportTicket returned error: %v", err)
	}

	if replied.Status != SupportTicketStatusWaitingSupport {
		t.Fatalf("status = %q, want waiting_support", replied.Status)
	}
	if len(chat.messages) != 1 {
		t.Fatalf("chat messages len = %d, want 1", len(chat.messages))
	}
	if chat.messages[0].ConversationID != "conversation-123" ||
		chat.messages[0].ActorID != "user-123" ||
		chat.messages[0].Message != "Я загрузил чек, проверьте, пожалуйста." {
		t.Fatalf("chat message = %#v", chat.messages[0])
	}
	if got := strings.Join(chat.messages[0].FileIDs, ","); got != "receipt-1,receipt-2" {
		t.Fatalf("chat file ids = %#v", chat.messages[0].FileIDs)
	}
	if chat.messages[0].ClientMessageID == "" {
		t.Fatal("client message id must be derived for idempotent user chat sends")
	}
	if len(repo.events) != 1 {
		t.Fatalf("events len = %d, want 1", len(repo.events))
	}
	event := repo.events[0]
	if event.ActorType != SupportActorTypeUser || event.ActorID != "user-123" || event.EventType != "user_replied" {
		t.Fatalf("event = %#v, want user reply event", event)
	}
	if event.Payload["message_id"] != "chat-message-user-1" ||
		event.Payload["conversation_id"] != "conversation-123" ||
		event.Payload["client_message_id"] != chat.messages[0].ClientMessageID ||
		event.Payload["file_ids"] != "receipt-1,receipt-2" ||
		event.Payload["attachment_count"] != "2" {
		t.Fatalf("event payload = %#v", event.Payload)
	}
}

func TestUserReplyToSupportTicketEscalatesPriorityFromPaymentMessage(t *testing.T) {
	now := time.Date(2026, 6, 20, 12, 0, 0, 0, time.UTC)
	repo := newFakeHelpRepository(nil)
	repo.tickets = []SupportTicket{
		{
			ID:            "ticket-user-123",
			UserID:        "user-123",
			Status:        SupportTicketStatusWaitingUser,
			Priority:      SupportTicketPriorityNormal,
			CreatedAt:     now.Add(-time.Hour),
			UpdatedAt:     now.Add(-30 * time.Minute),
			LastMessageAt: now.Add(-30 * time.Minute),
		},
	}
	uc := NewHelpUseCase(repo, fixedClock(now))

	replied, err := uc.ReplyToUserSupportTicket(context.Background(), ReplyToUserSupportTicketInput{
		UserID:   "user-123",
		TicketID: "ticket-user-123",
		Message:  "Оплата списалась дважды, помогите проверить платеж.",
	})
	if err != nil {
		t.Fatalf("ReplyToUserSupportTicket returned error: %v", err)
	}

	if replied.Priority != SupportTicketPriorityHigh {
		t.Fatalf("priority = %q, want high", replied.Priority)
	}
}

func TestCreateSupportTicketIgnoresUntrustedMobileContextForPriorityAndSegment(t *testing.T) {
	now := time.Date(2026, 6, 20, 12, 0, 0, 0, time.UTC)
	repo := newFakeHelpRepository(nil)
	uc := NewHelpUseCase(repo, fixedClock(now))

	ticket, err := uc.CreateSupportTicket(context.Background(), CreateSupportTicketInput{
		UserID:   "user-123",
		Category: SupportTicketCategoryTechnical,
		Source:   "support_requests",
		Locale:   "ru",
		Context: map[string]string{
			"followers_count":    "25000",
			"is_vip":             "true",
			"is_guide":           "true",
			"guide_status":       "verified",
			"subscription_tier":  "pro",
			"user_nickname":      "@nomad",
			"source_route":       "/help/support",
			"previous_ticket_id": "support-user-123-20260620110000.000000000",
		},
	})
	if err != nil {
		t.Fatalf("CreateSupportTicket returned error: %v", err)
	}

	if ticket.Priority != SupportTicketPriorityNormal {
		t.Fatalf("priority = %q, want normal", ticket.Priority)
	}
	if ticket.CustomerSegment != SupportCustomerSegmentStandard {
		t.Fatalf("customer segment = %q, want standard", ticket.CustomerSegment)
	}
	if ticket.SegmentRefreshStatus != SupportSegmentRefreshStatusStale {
		t.Fatalf("segment refresh status = %q, want stale", ticket.SegmentRefreshStatus)
	}
	for _, untrustedKey := range []string{"followers_count", "is_vip", "is_guide", "guide_status", "subscription_tier"} {
		if _, ok := ticket.Context[untrustedKey]; ok {
			t.Fatalf("ticket context kept untrusted key %q: %#v", untrustedKey, ticket.Context)
		}
	}
	if ticket.Context["user_nickname"] != "@nomad" ||
		ticket.Context["source_route"] != "/help/support" ||
		ticket.Context["previous_ticket_id"] != "support-user-123-20260620110000.000000000" {
		t.Fatalf("ticket context = %#v, want safe hints preserved", ticket.Context)
	}
}

func TestCreateSupportTicketUsesTrustedGuideSegmentWithoutMakingItUrgent(t *testing.T) {
	now := time.Date(2026, 6, 20, 12, 0, 0, 0, time.UTC)
	repo := newFakeHelpRepository(nil)
	repo.userSegments = map[string]SupportUserSegment{
		"user-123": {
			UserID:          "user-123",
			Nickname:        "@guide_nomad",
			CustomerSegment: SupportCustomerSegmentGuide,
			FollowersCount:  25000,
			IsGuide:         true,
			GuideStatus:     "verified",
			ReasonCodes:     []string{"verified_guide", "followers_10k"},
			RefreshStatus:   SupportSegmentRefreshStatusFresh,
			UpdatedAt:       now.Add(-5 * time.Minute),
			SourceVersion:   "test-segment-v1",
		},
	}
	uc := NewHelpUseCase(repo, fixedClock(now))

	ticket, err := uc.CreateSupportTicket(context.Background(), CreateSupportTicketInput{
		UserID:   "user-123",
		Category: SupportTicketCategoryTechnical,
		Source:   "support_requests",
		Locale:   "ru",
		Context:  map[string]string{"source_route": "/help/support"},
	})
	if err != nil {
		t.Fatalf("CreateSupportTicket returned error: %v", err)
	}

	if ticket.Priority != SupportTicketPriorityHigh {
		t.Fatalf("priority = %q, want high for trusted guide", ticket.Priority)
	}
	if !containsString(ticket.PriorityReasonCodes, "segment_guide") {
		t.Fatalf("priority reasons = %#v, want segment_guide", ticket.PriorityReasonCodes)
	}
	if ticket.CustomerSegment != SupportCustomerSegmentGuide {
		t.Fatalf("customer segment = %q, want guide", ticket.CustomerSegment)
	}
	if ticket.SegmentRefreshStatus != SupportSegmentRefreshStatusFresh {
		t.Fatalf("segment refresh status = %q, want fresh", ticket.SegmentRefreshStatus)
	}
	if ticket.UserNicknameSnapshot != "@guide_nomad" ||
		ticket.FollowersCountSnapshot != 25000 ||
		ticket.GuideStatusSnapshot != "verified" ||
		ticket.SubscriptionTierSnapshot != "" {
		t.Fatalf("ticket trusted snapshots = %#v", ticket)
	}
	if !containsString(ticket.CustomerSegmentReasonCodes, "verified_guide") ||
		!containsString(ticket.CustomerSegmentReasonCodes, "followers_10k") {
		t.Fatalf("customer segment reasons = %#v", ticket.CustomerSegmentReasonCodes)
	}
}

func TestCreateSupportTicketAutoAssignsPaymentTicketBySkillLanguageAndLoad(t *testing.T) {
	now := time.Date(2026, 6, 20, 12, 0, 0, 0, time.UTC)
	repo := newFakeHelpRepository(nil)
	repo.supportAgents = []SupportAgent{
		{
			StaffID:       "general-agent",
			DisplayName:   "General Agent",
			Status:        SupportAgentStatusActive,
			Languages:     []string{"ru"},
			Skills:        []SupportAgentSkill{SupportAgentSkillAccount},
			Level:         SupportAgentLevelAgent,
			MaxActiveLoad: 8,
			UpdatedAt:     now.Add(-time.Hour),
		},
		{
			StaffID:       "payment-agent",
			DisplayName:   "Payment Agent",
			Status:        SupportAgentStatusActive,
			Languages:     []string{"ru", "en"},
			Skills:        []SupportAgentSkill{SupportAgentSkillPayments},
			Level:         SupportAgentLevelSenior,
			MaxActiveLoad: 8,
			UpdatedAt:     now.Add(-time.Hour),
		},
	}
	repo.tickets = []SupportTicket{
		{ID: "existing-1", UserID: "u1", AssigneeID: "general-agent", Status: SupportTicketStatusWaitingSupport, Priority: SupportTicketPriorityNormal, CreatedAt: now.Add(-time.Hour), UpdatedAt: now.Add(-time.Hour)},
	}
	uc := NewHelpUseCase(repo, fixedClock(now))

	ticket, err := uc.CreateSupportTicket(context.Background(), CreateSupportTicketInput{
		UserID:   "user-123",
		Category: SupportTicketCategoryPayments,
		Source:   "support_requests",
		Locale:   "ru",
		Context:  map[string]string{"payment_id": "payment-456"},
	})
	if err != nil {
		t.Fatalf("CreateSupportTicket returned error: %v", err)
	}

	if ticket.Priority != SupportTicketPriorityHigh {
		t.Fatalf("priority = %q, want high for payment ticket", ticket.Priority)
	}
	if !containsString(ticket.PriorityReasonCodes, "payment_category") {
		t.Fatalf("priority reasons = %#v, want payment_category", ticket.PriorityReasonCodes)
	}
	if ticket.AssigneeID != "payment-agent" ||
		ticket.AssignmentStatus != SupportAssignmentStatusAssigned ||
		ticket.AssignedAt == nil ||
		!containsString(ticket.AssignmentReasonCodes, "skill_payments") ||
		!containsString(ticket.AssignmentReasonCodes, "language_ru") {
		t.Fatalf("assignment result = %#v", ticket)
	}
	if !repo.hasTicketEvent(ticket.ID, "ticket_auto_assigned") {
		t.Fatalf("events = %#v, want ticket_auto_assigned", repo.events)
	}
}

func TestCreateSupportTicketLeavesTicketUnassignedWhenNoAgentMatches(t *testing.T) {
	now := time.Date(2026, 6, 20, 12, 0, 0, 0, time.UTC)
	repo := newFakeHelpRepository(nil)
	repo.supportAgents = []SupportAgent{
		{
			StaffID:       "offline-payment-agent",
			DisplayName:   "Offline Agent",
			Status:        SupportAgentStatusOffline,
			Languages:     []string{"ru"},
			Skills:        []SupportAgentSkill{SupportAgentSkillPayments},
			Level:         SupportAgentLevelSenior,
			MaxActiveLoad: 8,
			UpdatedAt:     now.Add(-time.Hour),
		},
	}
	uc := NewHelpUseCase(repo, fixedClock(now))

	ticket, err := uc.CreateSupportTicket(context.Background(), CreateSupportTicketInput{
		UserID:   "user-123",
		Category: SupportTicketCategoryPayments,
		Source:   "support_requests",
		Locale:   "ru",
	})
	if err != nil {
		t.Fatalf("CreateSupportTicket returned error: %v", err)
	}

	if ticket.AssigneeID != "" || ticket.AssignmentStatus != SupportAssignmentStatusNeedsAssignment {
		t.Fatalf("assignment result = %#v, want needs_assignment without assignee", ticket)
	}
	if !containsString(ticket.AssignmentReasonCodes, "no_available_agent") {
		t.Fatalf("assignment reasons = %#v, want no_available_agent", ticket.AssignmentReasonCodes)
	}
	if !repo.hasTicketEvent(ticket.ID, "ticket_assignment_failed") {
		t.Fatalf("events = %#v, want ticket_assignment_failed", repo.events)
	}
}

func TestSupportAgentConfigurationNormalizesAndPersistsRoutingProfile(t *testing.T) {
	now := time.Date(2026, 6, 20, 12, 0, 0, 0, time.UTC)
	repo := newFakeHelpRepository(nil)
	uc := NewHelpUseCase(repo, fixedClock(now))

	agent, err := uc.UpsertSupportAgent(context.Background(), UpsertSupportAgentInput{
		ActorID:       "support-lead",
		StaffID:       " agent-1 ",
		FirstName:     " Айгерим ",
		LastName:      " Нурланова ",
		MiddleName:    " Сапаровна ",
		Status:        SupportAgentStatusActive,
		Languages:     []string{"RU", " en ", "ru"},
		Skills:        []SupportAgentSkill{SupportAgentSkillPayments, SupportAgentSkillPayments, SupportAgentSkillTechnical},
		Level:         SupportAgentLevelSenior,
		MaxActiveLoad: 6,
		Timezone:      "Asia/Almaty",
	})
	if err != nil {
		t.Fatalf("UpsertSupportAgent returned error: %v", err)
	}

	if agent.StaffID != "agent-1" ||
		agent.DisplayName != "Нурланова Айгерим Сапаровна" ||
		agent.FirstName != "Айгерим" ||
		agent.LastName != "Нурланова" ||
		agent.MiddleName != "Сапаровна" ||
		agent.Level != SupportAgentLevelSenior ||
		len(agent.Languages) != 2 ||
		len(agent.Skills) != 2 ||
		agent.UpdatedAt != now {
		t.Fatalf("agent = %#v", agent)
	}

	agents, err := uc.ListSupportAgents(context.Background(), ListSupportAgentsInput{Status: SupportAgentStatusActive})
	if err != nil {
		t.Fatalf("ListSupportAgents returned error: %v", err)
	}
	if len(agents) != 1 || agents[0].StaffID != "agent-1" {
		t.Fatalf("agents = %#v", agents)
	}
}

func TestCreateSupportTicketDoesNotTreatPendingGuideApplicationAsGuideSegment(t *testing.T) {
	now := time.Date(2026, 6, 20, 12, 0, 0, 0, time.UTC)
	repo := newFakeHelpRepository(nil)
	uc := NewHelpUseCase(repo, fixedClock(now))
	uc.SetSupportUserSegmentResolver(fakeSupportUserSegmentResolver{
		segment: SupportUserSegment{
			UserID:        "user-123",
			Nickname:      "@pending_guide",
			IsGuide:       true,
			GuideStatus:   "PENDING_REVIEW",
			RefreshStatus: SupportSegmentRefreshStatusFresh,
			SourceVersion: "trusted-user-guide-v1",
			UpdatedAt:     now.Add(-time.Minute),
		},
	})

	ticket, err := uc.CreateSupportTicket(context.Background(), CreateSupportTicketInput{
		UserID:   "user-123",
		Category: SupportTicketCategoryTechnical,
		Source:   "support_requests",
		Locale:   "ru",
	})
	if err != nil {
		t.Fatalf("CreateSupportTicket returned error: %v", err)
	}

	if ticket.CustomerSegment != SupportCustomerSegmentStandard {
		t.Fatalf("customer segment = %q, want standard for pending guide application", ticket.CustomerSegment)
	}
	if ticket.Priority != SupportTicketPriorityNormal {
		t.Fatalf("priority = %q, want normal for pending guide application", ticket.Priority)
	}
	if containsString(ticket.PriorityReasonCodes, "segment_guide") {
		t.Fatalf("priority reasons = %#v, must not include segment_guide", ticket.PriorityReasonCodes)
	}
	if containsString(ticket.CustomerSegmentReasonCodes, "verified_guide") ||
		containsString(ticket.CustomerSegmentReasonCodes, "guide_profile") {
		t.Fatalf("segment reasons = %#v, must not mark pending applicant as guide", ticket.CustomerSegmentReasonCodes)
	}
	if ticket.GuideStatusSnapshot != "pending_review" {
		t.Fatalf("guide status snapshot = %q, want pending_review", ticket.GuideStatusSnapshot)
	}
}

func TestSupportUserSegmentManualOverrideDoesNotRequireSubscriptionSystem(t *testing.T) {
	now := time.Date(2026, 6, 20, 12, 0, 0, 0, time.UTC)
	repo := newFakeHelpRepository(nil)
	uc := NewHelpUseCase(repo, fixedClock(now))

	segment, err := uc.UpsertSupportUserSegment(context.Background(), UpsertSupportUserSegmentInput{
		ActorID:        "support-lead",
		UserID:         "user-123",
		Nickname:       " @nomad ",
		FollowersCount: 42000,
		IsGuide:        true,
		GuideStatus:    "verified",
		ManualSegment:  SupportCustomerSegmentVIP,
		ManualReason:   "Public launch partner",
		SourceVersion:  "admin-manual",
	})
	if err != nil {
		t.Fatalf("UpsertSupportUserSegment returned error: %v", err)
	}

	if segment.CustomerSegment != SupportCustomerSegmentVIP ||
		segment.SubscriptionTier != "" ||
		segment.RefreshStatus != SupportSegmentRefreshStatusFresh ||
		!containsString(segment.ReasonCodes, "manual_vip") ||
		!containsString(segment.ReasonCodes, "verified_guide") ||
		!containsString(segment.ReasonCodes, "followers_10k") {
		t.Fatalf("segment = %#v", segment)
	}

	loaded, err := uc.GetSupportUserSegment(context.Background(), "user-123")
	if err != nil {
		t.Fatalf("GetSupportUserSegment returned error: %v", err)
	}
	if loaded.CustomerSegment != SupportCustomerSegmentVIP || loaded.SourceVersion != "admin-manual" {
		t.Fatalf("loaded segment = %#v", loaded)
	}
}

func TestCreateSupportTicketUsesTrustedSegmentResolverAndManualOverrideWithoutSubscriptionSystem(t *testing.T) {
	now := time.Date(2026, 6, 20, 12, 0, 0, 0, time.UTC)
	repo := newFakeHelpRepository(nil)
	repo.userSegments = map[string]SupportUserSegment{
		"user-123": {
			UserID:        "user-123",
			ManualSegment: SupportCustomerSegmentVIP,
			ManualReason:  "Public launch partner",
			RefreshStatus: SupportSegmentRefreshStatusFresh,
			SourceVersion: "admin-manual",
			UpdatedAt:     now.Add(-time.Hour),
		},
	}
	uc := NewHelpUseCase(repo, fixedClock(now))
	uc.SetSupportUserSegmentResolver(fakeSupportUserSegmentResolver{
		segment: SupportUserSegment{
			UserID:         "user-123",
			Nickname:       "@creator_guide",
			FollowersCount: 150000,
			IsGuide:        true,
			GuideStatus:    "verified",
			RefreshStatus:  SupportSegmentRefreshStatusFresh,
			SourceVersion:  "trusted-user-guide-v1",
			UpdatedAt:      now.Add(-time.Minute),
		},
	})

	ticket, err := uc.CreateSupportTicket(context.Background(), CreateSupportTicketInput{
		UserID:   "user-123",
		Category: SupportTicketCategoryTechnical,
		Source:   "support_requests",
		Locale:   "ru",
	})
	if err != nil {
		t.Fatalf("CreateSupportTicket returned error: %v", err)
	}

	if ticket.CustomerSegment != SupportCustomerSegmentVIP ||
		ticket.Priority != SupportTicketPriorityHigh ||
		ticket.SubscriptionTierSnapshot != "" {
		t.Fatalf("ticket segment/priority = %#v", ticket)
	}
	if ticket.UserNicknameSnapshot != "@creator_guide" ||
		ticket.FollowersCountSnapshot != 150000 ||
		ticket.GuideStatusSnapshot != "verified" {
		t.Fatalf("ticket trusted snapshots = %#v", ticket)
	}
	for _, reason := range []string{"manual_vip", "followers_100k", "verified_guide"} {
		if !containsString(ticket.CustomerSegmentReasonCodes, reason) {
			t.Fatalf("customer segment reasons = %#v, want %q", ticket.CustomerSegmentReasonCodes, reason)
		}
	}
	if !containsString(ticket.PriorityReasonCodes, "segment_vip") {
		t.Fatalf("priority reasons = %#v, want segment_vip", ticket.PriorityReasonCodes)
	}
	stored := repo.userSegments["user-123"]
	if stored.CustomerSegment != SupportCustomerSegmentVIP ||
		stored.SourceVersion != "trusted-user-guide-v1" ||
		stored.ManualReason != "Public launch partner" ||
		stored.SubscriptionTier != "" {
		t.Fatalf("stored merged segment = %#v", stored)
	}
}

func TestCreateSupportTicketFallsBackWhenTrustedSegmentResolverUnavailable(t *testing.T) {
	now := time.Date(2026, 6, 20, 12, 0, 0, 0, time.UTC)
	repo := newFakeHelpRepository(nil)
	uc := NewHelpUseCase(repo, fixedClock(now))
	uc.SetSupportUserSegmentResolver(fakeSupportUserSegmentResolver{err: errors.New("user-service unavailable")})

	ticket, err := uc.CreateSupportTicket(context.Background(), CreateSupportTicketInput{
		UserID:   "user-123",
		Category: SupportTicketCategoryTechnical,
		Source:   "support_requests",
		Locale:   "ru",
	})
	if err != nil {
		t.Fatalf("CreateSupportTicket returned error: %v", err)
	}

	if ticket.CustomerSegment != SupportCustomerSegmentStandard ||
		ticket.Priority != SupportTicketPriorityNormal ||
		ticket.SegmentRefreshStatus != SupportSegmentRefreshStatusStale {
		t.Fatalf("ticket fallback segment = %#v", ticket)
	}
	if ticket.SubscriptionTierSnapshot != "" {
		t.Fatalf("subscription tier snapshot = %q, want empty without subscription system", ticket.SubscriptionTierSnapshot)
	}
}

func TestRefreshStaleSupportTicketSegmentsRecalculatesAndAutoAssigns(t *testing.T) {
	now := time.Date(2026, 6, 20, 12, 0, 0, 0, time.UTC)
	repo := newFakeHelpRepository(nil)
	repo.tickets = []SupportTicket{
		{
			ID:                   "ticket-stale",
			UserID:               "user-123",
			Category:             SupportTicketCategoryTechnical,
			Status:               SupportTicketStatusNew,
			Priority:             SupportTicketPriorityNormal,
			CustomerSegment:      SupportCustomerSegmentStandard,
			SegmentRefreshStatus: SupportSegmentRefreshStatusStale,
			AssignmentStatus:     SupportAssignmentStatusNeedsAssignment,
			Locale:               "ru",
			CreatedAt:            now.Add(-time.Hour),
			UpdatedAt:            now.Add(-time.Hour),
			LastMessageAt:        now.Add(-time.Hour),
		},
	}
	repo.supportAgents = []SupportAgent{
		{
			StaffID:       "technical-senior",
			DisplayName:   "Technical Senior",
			Status:        SupportAgentStatusActive,
			Languages:     []string{"ru"},
			Skills:        []SupportAgentSkill{SupportAgentSkillTechnical},
			Level:         SupportAgentLevelSenior,
			MaxActiveLoad: 8,
			UpdatedAt:     now.Add(-time.Hour),
		},
	}
	uc := NewHelpUseCase(repo, fixedClock(now))
	uc.SetSupportUserSegmentResolver(fakeSupportUserSegmentResolver{
		segment: SupportUserSegment{
			UserID:         "user-123",
			Nickname:       "@creator_guide",
			FollowersCount: 150000,
			IsGuide:        true,
			GuideStatus:    "active",
			RefreshStatus:  SupportSegmentRefreshStatusFresh,
			SourceVersion:  "trusted-user-guide-v1",
			UpdatedAt:      now,
		},
	})

	updated, err := uc.RefreshStaleSupportTicketSegments(context.Background(), RefreshStaleSupportTicketSegmentsInput{Limit: 10})
	if err != nil {
		t.Fatalf("RefreshStaleSupportTicketSegments returned error: %v", err)
	}

	if updated != 1 {
		t.Fatalf("updated = %d, want 1", updated)
	}
	ticket := repo.tickets[0]
	if ticket.CustomerSegment != SupportCustomerSegmentVIP ||
		ticket.Priority != SupportTicketPriorityHigh ||
		ticket.SegmentRefreshStatus != SupportSegmentRefreshStatusFresh ||
		ticket.AssigneeID != "technical-senior" ||
		ticket.AssignmentStatus != SupportAssignmentStatusAssigned {
		t.Fatalf("ticket after refresh = %#v", ticket)
	}
	if !containsString(ticket.CustomerSegmentReasonCodes, "followers_100k") ||
		!containsString(ticket.CustomerSegmentReasonCodes, "verified_guide") ||
		!containsString(ticket.PriorityReasonCodes, "segment_vip") {
		t.Fatalf("reason codes after refresh = priority %#v segment %#v", ticket.PriorityReasonCodes, ticket.CustomerSegmentReasonCodes)
	}
	if !repo.hasTicketEvent("ticket-stale", "ticket_segment_calculated") ||
		!repo.hasTicketEvent("ticket-stale", "ticket_auto_assigned") {
		t.Fatalf("events = %#v, want segment calculation and auto assignment", repo.events)
	}
}

func TestUserReplyToSupportTicketIsIdempotentForSameRequest(t *testing.T) {
	now := time.Date(2026, 6, 20, 12, 0, 0, 0, time.UTC)
	repo := newFakeHelpRepository(nil)
	repo.tickets = []SupportTicket{
		{
			ID:             "ticket-user-123",
			UserID:         "user-123",
			ConversationID: "conversation-123",
			Status:         SupportTicketStatusWaitingUser,
			CreatedAt:      now.Add(-time.Hour),
			UpdatedAt:      now.Add(-30 * time.Minute),
			LastMessageAt:  now.Add(-30 * time.Minute),
		},
	}
	chat := &fakeSupportChatGateway{messageID: "chat-message-user-1"}
	uc := NewHelpUseCase(repo, fixedClock(now))
	uc.SetSupportChatGateway(chat)

	input := ReplyToUserSupportTicketInput{
		UserID:         "user-123",
		TicketID:       "ticket-user-123",
		Message:        "Я загрузил чек, проверьте, пожалуйста.",
		IdempotencyKey: "user-reply-request-123",
	}
	first, err := uc.ReplyToUserSupportTicket(context.Background(), input)
	if err != nil {
		t.Fatalf("first ReplyToUserSupportTicket returned error: %v", err)
	}
	second, err := uc.ReplyToUserSupportTicket(context.Background(), input)
	if err != nil {
		t.Fatalf("second ReplyToUserSupportTicket returned error: %v", err)
	}

	if second.ID != first.ID || second.Status != first.Status {
		t.Fatalf("second reply = %#v, want existing ticket %#v", second, first)
	}
	if len(chat.messages) != 1 {
		t.Fatalf("chat messages len = %d, want one idempotent send", len(chat.messages))
	}
	if len(repo.events) != 1 {
		t.Fatalf("events len = %d, want one idempotent user reply event", len(repo.events))
	}
}

func TestUserReplyToSupportTicketRejectsOtherUserTicket(t *testing.T) {
	now := time.Date(2026, 6, 20, 12, 0, 0, 0, time.UTC)
	repo := newFakeHelpRepository(nil)
	repo.tickets = []SupportTicket{
		{
			ID:             "ticket-user-456",
			UserID:         "user-456",
			ConversationID: "conversation-456",
			Status:         SupportTicketStatusWaitingUser,
			CreatedAt:      now.Add(-time.Hour),
			UpdatedAt:      now.Add(-time.Hour),
			LastMessageAt:  now.Add(-time.Hour),
		},
	}
	chat := &fakeSupportChatGateway{messageID: "chat-message-user-1"}
	uc := NewHelpUseCase(repo, fixedClock(now))
	uc.SetSupportChatGateway(chat)

	_, err := uc.ReplyToUserSupportTicket(context.Background(), ReplyToUserSupportTicketInput{
		UserID:   "user-123",
		TicketID: "ticket-user-456",
		Message:  "Это чужой тикет.",
	})
	if !errors.Is(err, ErrSupportTicketNotFound) {
		t.Fatalf("err = %v, want ErrSupportTicketNotFound", err)
	}
	if len(chat.messages) != 0 {
		t.Fatalf("chat messages = %#v, want none", chat.messages)
	}
	if len(repo.events) != 0 {
		t.Fatalf("events = %#v, want none", repo.events)
	}
}

func TestUserReplyToSupportTicketStoresEventWhenChatSendFails(t *testing.T) {
	now := time.Date(2026, 6, 20, 12, 0, 0, 0, time.UTC)
	repo := newFakeHelpRepository(nil)
	repo.tickets = []SupportTicket{
		{
			ID:             "ticket-user-123",
			UserID:         "user-123",
			ConversationID: "conversation-123",
			Status:         SupportTicketStatusWaitingUser,
			CreatedAt:      now.Add(-time.Hour),
			UpdatedAt:      now.Add(-time.Hour),
			LastMessageAt:  now.Add(-time.Hour),
		},
	}
	uc := NewHelpUseCase(repo, fixedClock(now))
	uc.SetSupportChatGateway(&fakeSupportChatGateway{err: errors.New("chat unavailable")})

	ticket, err := uc.ReplyToUserSupportTicket(context.Background(), ReplyToUserSupportTicketInput{
		UserID:         "user-123",
		TicketID:       "ticket-user-123",
		Message:        "Проверьте, пожалуйста.",
		IdempotencyKey: "user-reply-request-123",
	})
	if err != nil {
		t.Fatalf("ReplyToUserSupportTicket returned error: %v", err)
	}
	if ticket.Status != SupportTicketStatusWaitingSupport {
		t.Fatalf("ticket status = %q, want waiting_support", ticket.Status)
	}
	if len(repo.events) != 1 {
		t.Fatalf("events len = %d, want 1", len(repo.events))
	}
	if repo.events[0].EventType != "user_replied" ||
		repo.events[0].Payload["message_preview"] != "Проверьте, пожалуйста." {
		t.Fatalf("event = %#v, want stored user reply", repo.events[0])
	}
}

func TestUserCanSubmitCSATOnlyForOwnResolvedOrClosedTicket(t *testing.T) {
	now := time.Date(2026, 6, 20, 12, 0, 0, 0, time.UTC)
	repo := newFakeHelpRepository(nil)
	resolvedAt := now.Add(-10 * time.Minute)
	repo.tickets = []SupportTicket{
		{
			ID:            "ticket-resolved",
			UserID:        "user-123",
			Category:      SupportTicketCategoryPayments,
			Status:        SupportTicketStatusResolved,
			Priority:      SupportTicketPriorityNormal,
			Source:        "help_center",
			Locale:        "en",
			ResolvedAt:    &resolvedAt,
			CreatedAt:     now.Add(-time.Hour),
			UpdatedAt:     resolvedAt,
			LastMessageAt: resolvedAt,
		},
		{
			ID:            "ticket-open",
			UserID:        "user-123",
			Category:      SupportTicketCategoryActivities,
			Status:        SupportTicketStatusWaitingSupport,
			Priority:      SupportTicketPriorityNormal,
			Source:        "activity_details",
			Locale:        "ru",
			CreatedAt:     now.Add(-30 * time.Minute),
			UpdatedAt:     now.Add(-25 * time.Minute),
			LastMessageAt: now.Add(-25 * time.Minute),
		},
		{
			ID:            "ticket-other-user",
			UserID:        "user-456",
			Category:      SupportTicketCategoryTechnical,
			Status:        SupportTicketStatusClosed,
			Priority:      SupportTicketPriorityNormal,
			Source:        "help_center",
			Locale:        "en",
			CreatedAt:     now.Add(-2 * time.Hour),
			UpdatedAt:     now.Add(-time.Hour),
			LastMessageAt: now.Add(-time.Hour),
		},
	}
	uc := NewHelpUseCase(repo, fixedClock(now))

	if err := uc.SubmitSupportTicketCSAT(context.Background(), SubmitSupportTicketCSATInput{
		UserID:   "user-123",
		TicketID: "ticket-resolved",
		Rating:   5,
		Comment:  "Clear and fast answer.",
	}); err != nil {
		t.Fatalf("SubmitSupportTicketCSAT returned error: %v", err)
	}

	if len(repo.csat) != 1 {
		t.Fatalf("csat len = %d, want 1", len(repo.csat))
	}
	if repo.csat[0].TicketID != "ticket-resolved" ||
		repo.csat[0].UserID != "user-123" ||
		repo.csat[0].Rating != 5 ||
		repo.csat[0].Comment != "Clear and fast answer." ||
		!repo.csat[0].CreatedAt.Equal(now) {
		t.Fatalf("csat = %#v", repo.csat[0])
	}
	if len(repo.events) != 1 ||
		repo.events[0].ActorType != SupportActorTypeUser ||
		repo.events[0].ActorID != "user-123" ||
		repo.events[0].EventType != "ticket_csat_submitted" ||
		repo.events[0].Payload["rating"] != "5" {
		t.Fatalf("events = %#v, want user csat audit event", repo.events)
	}

	if err := uc.SubmitSupportTicketCSAT(context.Background(), SubmitSupportTicketCSATInput{
		UserID:   "user-123",
		TicketID: "ticket-open",
		Rating:   4,
	}); !errors.Is(err, ErrInvalidFeedback) {
		t.Fatalf("open ticket err = %v, want ErrInvalidFeedback", err)
	}

	if err := uc.SubmitSupportTicketCSAT(context.Background(), SubmitSupportTicketCSATInput{
		UserID:   "user-123",
		TicketID: "ticket-other-user",
		Rating:   4,
	}); !errors.Is(err, ErrSupportTicketNotFound) {
		t.Fatalf("other user ticket err = %v, want ErrSupportTicketNotFound", err)
	}

	for _, rating := range []int{0, 6} {
		if err := uc.SubmitSupportTicketCSAT(context.Background(), SubmitSupportTicketCSATInput{
			UserID:   "user-123",
			TicketID: "ticket-resolved",
			Rating:   rating,
		}); !errors.Is(err, ErrInvalidFeedback) {
			t.Fatalf("rating %d err = %v, want ErrInvalidFeedback", rating, err)
		}
	}
}

func TestSupportAgentCanAssignReplyResolveAndReopenTicketWithAuditEvents(t *testing.T) {
	now := time.Date(2026, 6, 20, 12, 0, 0, 0, time.UTC)
	repo := newFakeHelpRepository(nil)
	repo.tickets = []SupportTicket{
		{
			ID:            "support-user-123-20260620120000",
			UserID:        "user-123",
			Category:      SupportTicketCategoryActivities,
			Status:        SupportTicketStatusNew,
			Priority:      SupportTicketPriorityNormal,
			Source:        "activity_details",
			Locale:        "ru",
			Context:       map[string]string{"activity_id": "activity-456"},
			CreatedAt:     now.Add(-time.Hour),
			LastMessageAt: now.Add(-time.Hour),
		},
	}
	clock := fixedClock(now)
	uc := NewHelpUseCase(repo, clock)

	_, err := uc.AssignSupportTicket(context.Background(), AssignSupportTicketInput{
		TicketID:   "support-user-123-20260620120000",
		ActorID:    "agent-1",
		AssigneeID: "agent-2",
	})
	if !errors.Is(err, ErrInvalidSupportAdminAction) {
		t.Fatalf("assign without reason err = %v, want ErrInvalidSupportAdminAction", err)
	}

	assigned, err := uc.AssignSupportTicket(context.Background(), AssignSupportTicketInput{
		TicketID:   "support-user-123-20260620120000",
		ActorID:    "agent-1",
		AssigneeID: "agent-2",
		Reason:     "Escalating guide activity case to a senior agent",
	})
	if err != nil {
		t.Fatalf("AssignSupportTicket returned error: %v", err)
	}
	if assigned.Status != SupportTicketStatusAssigned || assigned.AssigneeID != "agent-2" {
		t.Fatalf("assigned ticket = %#v", assigned)
	}
	if assigned.AssignmentStatus != SupportAssignmentStatusManual ||
		assigned.AssignmentReason != "Escalating guide activity case to a senior agent" ||
		!containsString(assigned.AssignmentReasonCodes, "manual_assignment") {
		t.Fatalf("assignment metadata = %#v, want manual assignment", assigned)
	}
	if got := repo.events[len(repo.events)-1].Payload["reason"]; got != "Escalating guide activity case to a senior agent" {
		t.Fatalf("manual assignment reason payload = %q", got)
	}

	replied, err := uc.ReplyToSupportTicket(context.Background(), ReplyToSupportTicketInput{
		TicketID:       assigned.ID,
		ActorID:        "agent-2",
		Message:        "Здравствуйте! Проверили вашу активность, возврат доступен.",
		ConversationID: "conversation-123",
		MessageID:      "message-456",
	})
	if err != nil {
		t.Fatalf("ReplyToSupportTicket returned error: %v", err)
	}
	if replied.Status != SupportTicketStatusWaitingUser {
		t.Fatalf("reply status = %q, want waiting_user", replied.Status)
	}
	if replied.FirstResponseAt == nil || !replied.FirstResponseAt.Equal(now) {
		t.Fatalf("first response at = %#v, want %s", replied.FirstResponseAt, now)
	}
	if replied.ConversationID != "conversation-123" {
		t.Fatalf("conversation id = %q", replied.ConversationID)
	}

	resolved, err := uc.ResolveSupportTicket(context.Background(), ResolveSupportTicketInput{
		TicketID:   assigned.ID,
		ActorID:    "agent-2",
		Resolution: "Refund window explained",
	})
	if err != nil {
		t.Fatalf("ResolveSupportTicket returned error: %v", err)
	}
	if resolved.Status != SupportTicketStatusResolved || resolved.ResolvedAt == nil {
		t.Fatalf("resolved ticket = %#v", resolved)
	}

	reopened, err := uc.ReopenSupportTicket(context.Background(), ReopenSupportTicketInput{
		TicketID: assigned.ID,
		ActorID:  "agent-2",
		Reason:   "User replied with a follow-up question",
	})
	if err != nil {
		t.Fatalf("ReopenSupportTicket returned error: %v", err)
	}
	if reopened.Status != SupportTicketStatusReopened || reopened.ResolvedAt != nil {
		t.Fatalf("reopened ticket = %#v", reopened)
	}

	eventTypes := make([]string, 0, len(repo.events))
	for _, event := range repo.events {
		eventTypes = append(eventTypes, event.EventType)
		if event.ActorType != SupportActorTypeAgent {
			t.Fatalf("event actor type = %q, want support_agent: %#v", event.ActorType, event)
		}
	}
	want := []string{"ticket_manually_reassigned", "agent_replied", "ticket_resolved", "ticket_reopened"}
	if len(eventTypes) != len(want) {
		t.Fatalf("event types = %#v, want %#v", eventTypes, want)
	}
	for i := range want {
		if eventTypes[i] != want[i] {
			t.Fatalf("event types = %#v, want %#v", eventTypes, want)
		}
	}
}

func TestReopenSupportTicketAutoAssignsWhenTicketHasNoResponsibleAgent(t *testing.T) {
	now := time.Date(2026, 6, 20, 12, 0, 0, 0, time.UTC)
	resolvedAt := now.Add(-time.Hour)
	repo := newFakeHelpRepository(nil)
	repo.supportAgents = []SupportAgent{
		{
			StaffID:       "activity-senior",
			DisplayName:   "Activity Senior",
			Status:        SupportAgentStatusActive,
			Languages:     []string{"ru"},
			Skills:        []SupportAgentSkill{SupportAgentSkillActivities},
			Level:         SupportAgentLevelSenior,
			MaxActiveLoad: 8,
			UpdatedAt:     now.Add(-time.Hour),
		},
	}
	repo.tickets = []SupportTicket{
		{
			ID:               "ticket-reopen",
			UserID:           "user-123",
			Category:         SupportTicketCategoryActivities,
			Status:           SupportTicketStatusResolved,
			Priority:         SupportTicketPriorityNormal,
			CustomerSegment:  SupportCustomerSegmentGuide,
			AssignmentStatus: SupportAssignmentStatusNeedsAssignment,
			Source:           "activity_details",
			Locale:           "ru",
			CreatedAt:        now.Add(-2 * time.Hour),
			LastMessageAt:    now.Add(-2 * time.Hour),
			ResolvedAt:       &resolvedAt,
		},
	}
	uc := NewHelpUseCase(repo, fixedClock(now))

	reopened, err := uc.ReopenSupportTicket(context.Background(), ReopenSupportTicketInput{
		TicketID: "ticket-reopen",
		ActorID:  "support-lead",
		Reason:   "User has a follow-up question",
	})
	if err != nil {
		t.Fatalf("ReopenSupportTicket returned error: %v", err)
	}

	if reopened.Status != SupportTicketStatusAssigned ||
		reopened.AssigneeID != "activity-senior" ||
		reopened.AssignmentStatus != SupportAssignmentStatusAssigned ||
		reopened.AssignedAt == nil {
		t.Fatalf("reopened ticket = %#v, want auto assigned ticket", reopened)
	}
	if !repo.hasTicketEvent("ticket-reopen", "ticket_reopened") ||
		!repo.hasTicketEvent("ticket-reopen", "ticket_auto_assigned") {
		t.Fatalf("events = %#v, want ticket_reopened and ticket_auto_assigned", repo.events)
	}
}

func TestSupportAgentReplySendsMessageToChatBeforeUpdatingTicket(t *testing.T) {
	now := time.Date(2026, 6, 20, 12, 0, 0, 0, time.UTC)
	repo := newFakeHelpRepository(nil)
	repo.tickets = []SupportTicket{
		{
			ID:             "ticket-1",
			UserID:         "user-123",
			ConversationID: "conversation-123",
			Category:       SupportTicketCategoryTechnical,
			Status:         SupportTicketStatusAssigned,
			Priority:       SupportTicketPriorityNormal,
			CreatedAt:      now.Add(-time.Hour),
			LastMessageAt:  now.Add(-time.Hour),
			UpdatedAt:      now.Add(-time.Hour),
		},
	}
	chat := &fakeSupportChatGateway{messageID: "chat-message-456"}
	uc := NewHelpUseCase(repo, fixedClock(now))
	uc.SetSupportChatGateway(chat)

	replied, err := uc.ReplyToSupportTicket(context.Background(), ReplyToSupportTicketInput{
		TicketID:       "ticket-1",
		ActorID:        "agent-1",
		Message:        "Здравствуйте! Поддержка уже проверяет ваш вопрос.",
		IdempotencyKey: "request-123",
	})
	if err != nil {
		t.Fatalf("ReplyToSupportTicket returned error: %v", err)
	}

	if len(chat.messages) != 1 {
		t.Fatalf("chat messages len = %d, want 1", len(chat.messages))
	}
	if chat.messages[0].ConversationID != "conversation-123" ||
		chat.messages[0].ActorID != "agent-1" ||
		chat.messages[0].Message != "Здравствуйте! Поддержка уже проверяет ваш вопрос." {
		t.Fatalf("chat message = %#v", chat.messages[0])
	}
	if chat.messages[0].ClientMessageID == "" {
		t.Fatalf("client message id must be derived for idempotent chat sends")
	}
	if replied.Status != SupportTicketStatusWaitingUser {
		t.Fatalf("reply status = %q, want waiting_user", replied.Status)
	}
	if len(repo.events) != 1 {
		t.Fatalf("events len = %d, want 1", len(repo.events))
	}
	if repo.events[0].Payload["message_id"] != "chat-message-456" {
		t.Fatalf("event payload = %#v, want chat message id", repo.events[0].Payload)
	}
	if repo.events[0].Payload["client_message_id"] != chat.messages[0].ClientMessageID {
		t.Fatalf("event payload = %#v, want client message id %s", repo.events[0].Payload, chat.messages[0].ClientMessageID)
	}
}

func TestSupportAgentReplyIsIdempotentForSameRequest(t *testing.T) {
	now := time.Date(2026, 6, 20, 12, 0, 0, 0, time.UTC)
	repo := newFakeHelpRepository(nil)
	repo.tickets = []SupportTicket{
		{
			ID:             "ticket-1",
			UserID:         "user-123",
			ConversationID: "conversation-123",
			Status:         SupportTicketStatusAssigned,
			CreatedAt:      now.Add(-time.Hour),
			LastMessageAt:  now.Add(-time.Hour),
			UpdatedAt:      now.Add(-time.Hour),
		},
	}
	chat := &fakeSupportChatGateway{messageID: "chat-message-456"}
	uc := NewHelpUseCase(repo, fixedClock(now))
	uc.SetSupportChatGateway(chat)

	input := ReplyToSupportTicketInput{
		TicketID:       "ticket-1",
		ActorID:        "agent-1",
		Message:        "Здравствуйте! Поддержка уже проверяет ваш вопрос.",
		IdempotencyKey: "request-123",
	}
	first, err := uc.ReplyToSupportTicket(context.Background(), input)
	if err != nil {
		t.Fatalf("first ReplyToSupportTicket returned error: %v", err)
	}
	second, err := uc.ReplyToSupportTicket(context.Background(), input)
	if err != nil {
		t.Fatalf("second ReplyToSupportTicket returned error: %v", err)
	}

	if second.ID != first.ID || second.Status != first.Status {
		t.Fatalf("second reply = %#v, want existing ticket %#v", second, first)
	}
	if len(chat.messages) != 1 {
		t.Fatalf("chat messages len = %d, want one idempotent send", len(chat.messages))
	}
	if len(repo.events) != 1 {
		t.Fatalf("events len = %d, want one idempotent agent reply event", len(repo.events))
	}
}

func TestSupportAgentReplyNotifiesUserWithoutLeakingContext(t *testing.T) {
	now := time.Date(2026, 6, 20, 12, 0, 0, 0, time.UTC)
	repo := newFakeHelpRepository(nil)
	repo.tickets = []SupportTicket{
		{
			ID:             "ticket-1",
			UserID:         "user-123",
			ConversationID: "conversation-123",
			Category:       SupportTicketCategoryPayments,
			Status:         SupportTicketStatusAssigned,
			Priority:       SupportTicketPriorityHigh,
			Source:         "payment_details",
			Locale:         "ru",
			Context:        map[string]string{"payment_id": "payment-456"},
			CreatedAt:      now.Add(-time.Hour),
			LastMessageAt:  now.Add(-time.Hour),
			UpdatedAt:      now.Add(-time.Hour),
		},
	}
	chat := &fakeSupportChatGateway{messageID: "chat-message-456"}
	notifier := &fakeSupportUserNotifier{}
	uc := NewHelpUseCase(repo, fixedClock(now))
	uc.SetSupportChatGateway(chat)
	uc.SetSupportUserNotifier(notifier)

	_, err := uc.ReplyToSupportTicket(context.Background(), ReplyToSupportTicketInput{
		TicketID:       "ticket-1",
		ActorID:        "agent-1",
		Message:        "Здравствуйте! Мы проверили ваш платеж.",
		IdempotencyKey: "request-123",
	})
	if err != nil {
		t.Fatalf("ReplyToSupportTicket returned error: %v", err)
	}

	if len(notifier.calls) != 1 {
		t.Fatalf("user notifications = %#v, want one", notifier.calls)
	}
	call := notifier.calls[0]
	if call.userID != "user-123" {
		t.Fatalf("notification user id = %q", call.userID)
	}
	if call.input.IdempotencyKey != "support:ticket:ticket-1:reply:chat-message-456" {
		t.Fatalf("idempotency key = %q", call.input.IdempotencyKey)
	}
	if call.input.Category != "support" || call.input.Priority != "normal" {
		t.Fatalf("category/priority = %q/%q", call.input.Category, call.input.Priority)
	}
	if call.input.Title != "Поддержка ответила" ||
		call.input.Body != "Поддержка ответила в вашем обращении." {
		t.Fatalf("notification text = %q/%q", call.input.Title, call.input.Body)
	}
	if call.input.DeepLink != "/help/support" {
		t.Fatalf("deep link = %q", call.input.DeepLink)
	}
	if call.input.Data["event"] != "support_ticket_replied" ||
		call.input.Data["ticketId"] != "ticket-1" ||
		call.input.Data["conversationId"] != "conversation-123" ||
		call.input.Data["messageId"] != "chat-message-456" {
		t.Fatalf("notification data = %#v", call.input.Data)
	}
	if call.input.Data["title.ru"] != "Поддержка ответила" ||
		call.input.Data["body.ru"] != "Поддержка ответила в вашем обращении." ||
		call.input.Data["title.kk"] != "Қолдау жауап берді" ||
		call.input.Data["body.en"] != "Support replied to your ticket." {
		t.Fatalf("localized notification data = %#v", call.input.Data)
	}
	if _, ok := call.input.Data["payment_id"]; ok {
		t.Fatalf("notification data leaked support context: %#v", call.input.Data)
	}
	if _, ok := call.input.Data["message_preview"]; ok {
		t.Fatalf("notification data leaked message preview: %#v", call.input.Data)
	}
}

func TestSupportAgentReplySucceedsWhenUserNotificationFails(t *testing.T) {
	now := time.Date(2026, 6, 20, 12, 0, 0, 0, time.UTC)
	repo := newFakeHelpRepository(nil)
	repo.tickets = []SupportTicket{
		{
			ID:             "ticket-1",
			UserID:         "user-123",
			ConversationID: "conversation-123",
			Status:         SupportTicketStatusAssigned,
			CreatedAt:      now.Add(-time.Hour),
			LastMessageAt:  now.Add(-time.Hour),
			UpdatedAt:      now.Add(-time.Hour),
		},
	}
	uc := NewHelpUseCase(repo, fixedClock(now))
	uc.SetSupportChatGateway(&fakeSupportChatGateway{messageID: "chat-message-456"})
	uc.SetSupportUserNotifier(&fakeSupportUserNotifier{err: errors.New("notification unavailable")})

	replied, err := uc.ReplyToSupportTicket(context.Background(), ReplyToSupportTicketInput{
		TicketID:       "ticket-1",
		ActorID:        "agent-1",
		Message:        "Здравствуйте!",
		IdempotencyKey: "request-123",
	})
	if err != nil {
		t.Fatalf("ReplyToSupportTicket returned error: %v", err)
	}
	if replied.Status != SupportTicketStatusWaitingUser {
		t.Fatalf("status = %q, want waiting_user", replied.Status)
	}
	if len(repo.events) != 1 || repo.events[0].EventType != "agent_replied" {
		t.Fatalf("events = %#v, want persisted reply event", repo.events)
	}
}

func TestSupportAgentReplyDoesNotUpdateTicketWhenChatSendFails(t *testing.T) {
	now := time.Date(2026, 6, 20, 12, 0, 0, 0, time.UTC)
	repo := newFakeHelpRepository(nil)
	repo.tickets = []SupportTicket{
		{
			ID:             "ticket-1",
			UserID:         "user-123",
			ConversationID: "conversation-123",
			Status:         SupportTicketStatusAssigned,
			CreatedAt:      now.Add(-time.Hour),
			LastMessageAt:  now.Add(-time.Hour),
			UpdatedAt:      now.Add(-time.Hour),
		},
	}
	uc := NewHelpUseCase(repo, fixedClock(now))
	uc.SetSupportChatGateway(&fakeSupportChatGateway{err: errors.New("chat unavailable")})

	ticket, err := uc.ReplyToSupportTicket(context.Background(), ReplyToSupportTicketInput{
		TicketID:       "ticket-1",
		ActorID:        "agent-1",
		Message:        "Здравствуйте!",
		IdempotencyKey: "request-123",
	})
	if err != nil {
		t.Fatalf("ReplyToSupportTicket returned error: %v", err)
	}
	if ticket.Status != SupportTicketStatusWaitingUser {
		t.Fatalf("ticket status = %q, want waiting_user", ticket.Status)
	}
	if len(repo.events) != 1 {
		t.Fatalf("events len = %d, want 1", len(repo.events))
	}
	if repo.events[0].EventType != "agent_replied" ||
		repo.events[0].Payload["message_preview"] != "Здравствуйте!" {
		t.Fatalf("event = %#v, want stored agent reply", repo.events[0])
	}
}

func TestSupportTicketAdminActionsRequireActor(t *testing.T) {
	repo := newFakeHelpRepository(nil)
	repo.tickets = []SupportTicket{{ID: "ticket-1", Status: SupportTicketStatusNew}}
	uc := NewHelpUseCase(repo, fixedClock(time.Now()))

	_, err := uc.AssignSupportTicket(context.Background(), AssignSupportTicketInput{
		TicketID:   "ticket-1",
		AssigneeID: "agent-1",
	})
	if err != ErrInvalidSupportAdminAction {
		t.Fatalf("err = %v, want ErrInvalidSupportAdminAction", err)
	}
}

type fakeHelpRepository struct {
	categories              []HelpCategory
	savedReplies            []SupportSavedReply
	articles                []HelpArticle
	articleEvents           []HelpArticleEvent
	searchEvents            []HelpSearchEvent
	feedback                []ArticleFeedback
	csat                    []SupportTicketCSAT
	tickets                 []SupportTicket
	events                  []SupportTicketEvent
	userSegments            map[string]SupportUserSegment
	supportAgents           []SupportAgent
	listArticlesCalls       int
	searchArticlesCalls     int
	lastSearchArticleFilter SearchArticleFilter
}

type fakeSupportUserSegmentResolver struct {
	segment SupportUserSegment
	err     error
}

func (r fakeSupportUserSegmentResolver) ResolveSupportUserSegment(context.Context, string) (SupportUserSegment, error) {
	if r.err != nil {
		return SupportUserSegment{}, r.err
	}
	return r.segment, nil
}

func newFakeHelpRepository(articles []HelpArticle) *fakeHelpRepository {
	return &fakeHelpRepository{articles: articles}
}

func (r *fakeHelpRepository) ListArticles(context.Context) ([]HelpArticle, error) {
	r.listArticlesCalls++
	return append([]HelpArticle(nil), r.articles...), nil
}

func (r *fakeHelpRepository) SearchArticles(_ context.Context, filter SearchArticleFilter) ([]HelpArticle, error) {
	r.searchArticlesCalls++
	r.lastSearchArticleFilter = filter
	matches := make([]rankedArticle, 0, len(r.articles))
	query := normalizeSearchText(filter.Query)
	for _, article := range r.articles {
		translation, ok := localizedArticle(article, filter.Locale)
		if !ok || article.Status != ArticleStatusPublished {
			continue
		}
		if filter.Surface != "" && !containsSurface(article.Surfaces, filter.Surface) {
			continue
		}
		score := articleSearchScore(article, translation, query)
		if score == 0 {
			continue
		}
		matches = append(matches, rankedArticle{
			article:     article,
			translation: translation,
			score:       score,
		})
	}
	sortRankedArticles(matches)
	limit := normalizeLimit(filter.Limit, defaultSearchLimit)
	if len(matches) < limit {
		limit = len(matches)
	}
	result := make([]HelpArticle, 0, limit)
	for i := 0; i < limit; i++ {
		result = append(result, matches[i].article)
	}
	return result, nil
}

func (r *fakeHelpRepository) ListCategories(_ context.Context, filter HelpCategoryFilter) ([]HelpCategory, error) {
	items := make([]HelpCategory, 0, len(r.categories))
	for _, category := range r.categories {
		if filter.Status != "" && category.Status != filter.Status {
			continue
		}
		items = append(items, category)
	}
	return items, nil
}

func (r *fakeHelpRepository) UpsertCategory(_ context.Context, category HelpCategory) error {
	for index := range r.categories {
		if r.categories[index].ID == category.ID {
			category.CreatedAt = r.categories[index].CreatedAt
			r.categories[index] = category
			return nil
		}
	}
	r.categories = append(r.categories, category)
	return nil
}

func (r *fakeHelpRepository) ListSavedReplies(_ context.Context, filter SupportSavedReplyFilter) ([]SupportSavedReply, error) {
	items := make([]SupportSavedReply, 0, len(r.savedReplies))
	for _, reply := range r.savedReplies {
		if filter.Status != "" && reply.Status != filter.Status {
			continue
		}
		if filter.Category != "" && reply.Category != filter.Category {
			continue
		}
		items = append(items, reply)
	}
	sort.Slice(items, func(i, j int) bool {
		if items[i].SortOrder != items[j].SortOrder {
			return items[i].SortOrder < items[j].SortOrder
		}
		return items[i].ID < items[j].ID
	})
	if filter.Offset >= len(items) {
		return []SupportSavedReply{}, nil
	}
	items = items[filter.Offset:]
	if filter.Limit > 0 && len(items) > filter.Limit {
		items = items[:filter.Limit]
	}
	return items, nil
}

func (r *fakeHelpRepository) UpsertSavedReply(_ context.Context, reply SupportSavedReply) error {
	for index := range r.savedReplies {
		if r.savedReplies[index].ID == reply.ID {
			reply.CreatedAt = r.savedReplies[index].CreatedAt
			r.savedReplies[index] = reply
			return nil
		}
	}
	r.savedReplies = append(r.savedReplies, reply)
	return nil
}

func (r *fakeHelpRepository) ListAdminArticles(_ context.Context, filter HelpArticleFilter) ([]HelpArticle, error) {
	items := make([]HelpArticle, 0, len(r.articles))
	for _, article := range r.articles {
		if filter.Status != "" && article.Status != filter.Status {
			continue
		}
		items = append(items, article)
	}
	return items, nil
}

func (r *fakeHelpRepository) GetArticle(_ context.Context, articleID string) (HelpArticle, []HelpArticleEvent, error) {
	for _, article := range r.articles {
		if article.ID == articleID {
			events := make([]HelpArticleEvent, 0)
			for _, event := range r.articleEvents {
				if event.ArticleID == articleID {
					events = append(events, event)
				}
			}
			return article, events, nil
		}
	}
	return HelpArticle{}, nil, ErrArticleNotFound
}

func (r *fakeHelpRepository) UpsertArticle(_ context.Context, article HelpArticle, event HelpArticleEvent) error {
	for index := range r.articles {
		if r.articles[index].ID == article.ID {
			r.articles[index] = article
			r.articleEvents = append(r.articleEvents, event)
			return nil
		}
	}
	r.articles = append(r.articles, article)
	r.articleEvents = append(r.articleEvents, event)
	return nil
}

func (r *fakeHelpRepository) SaveHelpSearchEvent(_ context.Context, event HelpSearchEvent) error {
	r.searchEvents = append(r.searchEvents, event)
	return nil
}

func (r *fakeHelpRepository) SaveArticleFeedback(_ context.Context, feedback ArticleFeedback) error {
	for index := range r.feedback {
		if r.feedback[index].ArticleID == feedback.ArticleID &&
			r.feedback[index].UserID == feedback.UserID {
			r.feedback[index] = feedback
			return nil
		}
	}
	r.feedback = append(r.feedback, feedback)
	return nil
}

func (r *fakeHelpRepository) CreateSupportTicket(_ context.Context, ticket SupportTicket) error {
	r.tickets = append(r.tickets, ticket)
	return nil
}

func (r *fakeHelpRepository) FindSupportTicketByIdempotencyKey(_ context.Context, userID string, idempotencyKey string) (SupportTicket, error) {
	for _, ticket := range r.tickets {
		if ticket.UserID == userID && ticket.IdempotencyKey == idempotencyKey {
			return ticket, nil
		}
	}
	return SupportTicket{}, ErrSupportTicketNotFound
}

func (r *fakeHelpRepository) ListSupportTickets(_ context.Context, filter SupportTicketFilter) ([]SupportTicket, error) {
	items := make([]SupportTicket, 0, len(r.tickets))
	for _, ticket := range r.tickets {
		if filter.UserID != "" && ticket.UserID != filter.UserID {
			continue
		}
		if filter.Status != "" && ticket.Status != filter.Status {
			continue
		}
		if filter.AssigneeID != "" && ticket.AssigneeID != filter.AssigneeID {
			continue
		}
		items = append(items, ticket)
	}
	return items, nil
}

func (r *fakeHelpRepository) GetSupportTicket(_ context.Context, ticketID string) (SupportTicket, []SupportTicketEvent, error) {
	for _, ticket := range r.tickets {
		if ticket.ID == ticketID {
			events := make([]SupportTicketEvent, 0, len(r.events))
			for _, event := range r.events {
				if event.TicketID == ticketID {
					events = append(events, event)
				}
			}
			return ticket, events, nil
		}
	}
	return SupportTicket{}, nil, ErrSupportTicketNotFound
}

func (r *fakeHelpRepository) UpdateSupportTicket(_ context.Context, ticket SupportTicket, event SupportTicketEvent) error {
	for index := range r.tickets {
		if r.tickets[index].ID == ticket.ID {
			r.tickets[index] = ticket
			r.events = append(r.events, event)
			return nil
		}
	}
	return ErrSupportTicketNotFound
}

func (r *fakeHelpRepository) AppendSupportTicketEvent(_ context.Context, event SupportTicketEvent) error {
	r.events = append(r.events, event)
	return nil
}

func (r *fakeHelpRepository) SaveSupportTicketCSAT(_ context.Context, csat SupportTicketCSAT, event SupportTicketEvent) error {
	r.csat = append(r.csat, csat)
	r.events = append(r.events, event)
	return nil
}

func (r *fakeHelpRepository) GetSupportUserSegment(_ context.Context, userID string) (SupportUserSegment, error) {
	if r.userSegments == nil {
		return SupportUserSegment{}, ErrSupportUserSegmentNotFound
	}
	segment, ok := r.userSegments[userID]
	if !ok {
		return SupportUserSegment{}, ErrSupportUserSegmentNotFound
	}
	return segment, nil
}

func (r *fakeHelpRepository) UpsertSupportUserSegment(_ context.Context, segment SupportUserSegment) error {
	if r.userSegments == nil {
		r.userSegments = map[string]SupportUserSegment{}
	}
	r.userSegments[segment.UserID] = segment
	return nil
}

func (r *fakeHelpRepository) ListSupportAgents(_ context.Context, filter SupportAgentFilter) ([]SupportAgent, error) {
	items := make([]SupportAgent, 0, len(r.supportAgents))
	for _, agent := range r.supportAgents {
		if filter.Status != "" && agent.Status != filter.Status {
			continue
		}
		items = append(items, agent)
	}
	if filter.Offset >= len(items) {
		return []SupportAgent{}, nil
	}
	items = items[filter.Offset:]
	if filter.Limit > 0 && len(items) > filter.Limit {
		items = items[:filter.Limit]
	}
	return items, nil
}

func (r *fakeHelpRepository) UpsertSupportAgent(_ context.Context, agent SupportAgent) error {
	for index := range r.supportAgents {
		if r.supportAgents[index].StaffID == agent.StaffID {
			r.supportAgents[index] = agent
			return nil
		}
	}
	r.supportAgents = append(r.supportAgents, agent)
	return nil
}

func (r *fakeHelpRepository) hasTicketEvent(ticketID string, eventType string) bool {
	for _, event := range r.events {
		if event.TicketID == ticketID && event.EventType == eventType {
			return true
		}
	}
	return false
}

func (r *fakeHelpRepository) GetHelpAnalytics(_ context.Context, filter HelpAnalyticsFilter) (HelpAnalyticsSummary, error) {
	limit := normalizeLimit(filter.Limit, 10)
	summary := HelpAnalyticsSummary{}
	summary.Searches = fakeSearchAnalytics(r.searchEvents, limit)
	summary.Feedback = fakeFeedbackAnalytics(r.feedback, limit)
	summary.Tickets = fakeTicketAnalytics(r.tickets, r.csat)
	return summary, nil
}

func fakeSearchAnalytics(events []HelpSearchEvent, limit int) HelpSearchAnalytics {
	result := HelpSearchAnalytics{Total: len(events)}
	noResultByQuery := make(map[string]int)
	repeatedByQuery := make(map[string]int)
	for _, event := range events {
		repeatedByQuery[event.Query]++
		if event.ResultCount == 0 {
			result.WithoutResults++
			noResultByQuery[event.Query]++
		}
	}
	if result.Total > 0 {
		result.SuccessRate = float64(result.Total-result.WithoutResults) / float64(result.Total)
	}
	result.TopNoResultQueries = fakeQueryStats(noResultByQuery, limit, false)
	result.RepeatedQueries = fakeQueryStats(repeatedByQuery, limit, true)
	return result
}

func fakeQueryStats(counts map[string]int, limit int, onlyRepeated bool) []HelpSearchQueryStat {
	stats := make([]HelpSearchQueryStat, 0, len(counts))
	for query, count := range counts {
		if onlyRepeated && count < 2 {
			continue
		}
		stats = append(stats, HelpSearchQueryStat{Query: query, Count: count})
	}
	sort.Slice(stats, func(i, j int) bool {
		if stats[i].Count != stats[j].Count {
			return stats[i].Count > stats[j].Count
		}
		return stats[i].Query < stats[j].Query
	})
	if len(stats) > limit {
		stats = stats[:limit]
	}
	return stats
}

func fakeFeedbackAnalytics(feedback []ArticleFeedback, limit int) HelpFeedbackAnalytics {
	result := HelpFeedbackAnalytics{Total: len(feedback)}
	statsByArticleID := make(map[string]HelpArticleFeedbackStat)
	for _, item := range feedback {
		if item.Helpful {
			result.Helpful++
			continue
		}
		result.NotHelpful++
		if item.EscalatedToSupport {
			result.Escalations++
		}
		stat := statsByArticleID[item.ArticleID]
		stat.ArticleID = item.ArticleID
		stat.Count++
		if item.EscalatedToSupport {
			stat.Escalations++
		}
		statsByArticleID[item.ArticleID] = stat
	}
	if result.Total > 0 {
		result.NotHelpfulRate = float64(result.NotHelpful) / float64(result.Total)
	}
	result.TopNotHelpfulArticles = make([]HelpArticleFeedbackStat, 0, len(statsByArticleID))
	for _, stat := range statsByArticleID {
		result.TopNotHelpfulArticles = append(result.TopNotHelpfulArticles, stat)
	}
	sort.Slice(result.TopNotHelpfulArticles, func(i, j int) bool {
		if result.TopNotHelpfulArticles[i].Count != result.TopNotHelpfulArticles[j].Count {
			return result.TopNotHelpfulArticles[i].Count > result.TopNotHelpfulArticles[j].Count
		}
		return result.TopNotHelpfulArticles[i].ArticleID < result.TopNotHelpfulArticles[j].ArticleID
	})
	if len(result.TopNotHelpfulArticles) > limit {
		result.TopNotHelpfulArticles = result.TopNotHelpfulArticles[:limit]
	}
	return result
}

func fakeTicketAnalytics(tickets []SupportTicket, csat []SupportTicketCSAT) SupportTicketAnalytics {
	result := SupportTicketAnalytics{Total: len(tickets)}
	var firstResponseTotalSeconds int64
	var firstResponseCount int64
	var resolutionTotalSeconds int64
	var resolutionCount int64
	for _, ticket := range tickets {
		switch ticket.Status {
		case SupportTicketStatusResolved:
			result.Resolved++
		case SupportTicketStatusClosed:
			result.Closed++
		default:
			result.Open++
		}
		if ticket.Status == SupportTicketStatusWaitingSupport {
			result.WaitingSupport++
		}
		if ticket.Priority == SupportTicketPriorityUrgent {
			result.Urgent++
		}
		if ticket.FirstResponseAt != nil {
			firstResponseTotalSeconds += int64(ticket.FirstResponseAt.Sub(ticket.CreatedAt).Seconds())
			firstResponseCount++
		}
		if ticket.ResolvedAt != nil {
			resolutionTotalSeconds += int64(ticket.ResolvedAt.Sub(ticket.CreatedAt).Seconds())
			resolutionCount++
		}
	}
	if firstResponseCount > 0 {
		result.AverageFirstResponseSeconds = firstResponseTotalSeconds / firstResponseCount
	}
	if resolutionCount > 0 {
		result.AverageResolutionSeconds = resolutionTotalSeconds / resolutionCount
	}
	result.CSATResponses = len(csat)
	if len(csat) > 0 {
		var ratingTotal int
		for _, item := range csat {
			ratingTotal += item.Rating
		}
		result.AverageCSAT = float64(ratingTotal) / float64(len(csat))
	}
	return result
}

type fakeSupportChatGateway struct {
	conversationID       string
	conversationRequests []string
	messages             []SupportChatMessageInput
	messageID            string
	err                  error
}

func (g *fakeSupportChatGateway) EnsureSupportConversation(_ context.Context, userID string) (SupportChatConversationResult, error) {
	if g.err != nil {
		return SupportChatConversationResult{}, g.err
	}
	g.conversationRequests = append(g.conversationRequests, userID)
	return SupportChatConversationResult{ConversationID: g.conversationID}, nil
}

func (g *fakeSupportChatGateway) SendSupportMessage(_ context.Context, input SupportChatMessageInput) (SupportChatMessageResult, error) {
	if g.err != nil {
		return SupportChatMessageResult{}, g.err
	}
	g.messages = append(g.messages, input)
	return SupportChatMessageResult{MessageID: g.messageID}, nil
}

type fakeSupportOperatorNotifier struct {
	inputs []SupportOperatorNotificationInput
	err    error
}

func (n *fakeSupportOperatorNotifier) NotifySupportOperators(_ context.Context, input SupportOperatorNotificationInput) error {
	n.inputs = append(n.inputs, input)
	return n.err
}

type fakeSupportUserNotifier struct {
	calls []fakeSupportUserNotificationCall
	err   error
}

type fakeSupportUserNotificationCall struct {
	userID string
	input  SupportUserNotificationInput
}

func (n *fakeSupportUserNotifier) NotifySupportUser(_ context.Context, userID string, input SupportUserNotificationInput) error {
	n.calls = append(n.calls, fakeSupportUserNotificationCall{userID: userID, input: input})
	return n.err
}

func fixedClock(now time.Time) func() time.Time {
	return func() time.Time {
		return now
	}
}

func containsString(items []string, value string) bool {
	for _, item := range items {
		if item == value {
			return true
		}
	}
	return false
}
