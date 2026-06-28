package http

import (
	"context"
	"net/http"
	"net/http/httptest"
	"net/url"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/admin-panel/internal/app"
	"kz/inflap/backend/services/admin-panel/internal/config"
	"kz/inflap/backend/services/admin-panel/internal/domain/enum"
	"kz/inflap/backend/services/admin-panel/internal/domain/model"
)

func TestHelpArticleListRendersArticlesAndCreateLink(t *testing.T) {
	client := &supportHTTPClientStub{
		categories: []model.HelpCategory{
			{
				ID:     "money_cards",
				Slug:   "money-cards",
				Title:  "Деньги и карты",
				Status: model.HelpArticleStatusPublished,
			},
		},
		articles: []model.HelpArticle{
			{
				ID:         "refund-policy",
				CategoryID: "money_cards",
				Slug:       "refund-policy",
				Status:     model.HelpArticleStatusPublished,
				Version:    3,
				Tags:       []string{"payments", "refunds"},
				Surfaces:   []string{"help_center", "activity_details"},
				UpdatedAt:  time.Date(2026, 6, 20, 12, 0, 0, 0, time.UTC),
				Translations: map[string]model.HelpArticleTranslation{
					"en": {Title: "Refund policy", ShortAnswer: "Refund timing depends on the provider."},
					"ru": {Title: "Правила возврата", ShortAnswer: "Срок возврата зависит от поставщика."},
				},
			},
		},
	}
	server := newSupportHTTPTestServer(t, app.NewSupportUseCase(client, nil))
	staff := &model.StaffUser{
		ID:          uuid.New(),
		Email:       "editor@inflap.local",
		DisplayName: "Editor",
		Permissions: []enum.Permission{enum.PermissionHelpContentEdit},
	}

	request := httptest.NewRequest(http.MethodGet, "/admin/help/articles?status=published", nil)
	request = request.WithContext(withLocale(adminTestContext(request.Context(), staff), localeRU))
	recorder := httptest.NewRecorder()

	server.HelpArticleList(recorder, request)

	if recorder.Code != http.StatusOK {
		t.Fatalf("status = %d, body = %s", recorder.Code, recorder.Body.String())
	}
	body := recorder.Body.String()
	for _, expected := range []string{
		"Правила возврата",
		"Срок возврата зависит от поставщика.",
		"Деньги и карты",
		"/admin/help/articles/new",
		"/admin/help/articles/refund-policy/edit",
	} {
		if !strings.Contains(body, expected) {
			t.Fatalf("body missing %q:\n%s", expected, body)
		}
	}
	for _, unexpected := range []string{
		"Refund policy",
		"activity_details",
		"Поверхности",
	} {
		if strings.Contains(body, unexpected) {
			t.Fatalf("body unexpectedly contains %q:\n%s", unexpected, body)
		}
	}
	if client.lastHelpFilter.Status != model.HelpArticleStatusPublished {
		t.Fatalf("status filter = %q", client.lastHelpFilter.Status)
	}
	if client.lastHelpCategoryFilter.Status != "" {
		t.Fatalf("category status filter = %q, want all categories", client.lastHelpCategoryFilter.Status)
	}
	if client.lastHelpCategoryFilter.Locale != localeRU {
		t.Fatalf("category locale filter = %q, want %q", client.lastHelpCategoryFilter.Locale, localeRU)
	}
}

func TestHelpArticleListDefaultsToAllStatuses(t *testing.T) {
	client := &supportHTTPClientStub{}
	server := newSupportHTTPTestServer(t, app.NewSupportUseCase(client, nil))
	staff := &model.StaffUser{
		ID:          uuid.New(),
		Email:       "editor@inflap.local",
		DisplayName: "Editor",
		Permissions: []enum.Permission{enum.PermissionHelpContentEdit},
	}

	request := httptest.NewRequest(http.MethodGet, "/admin/help/articles", nil)
	request = request.WithContext(adminTestContext(request.Context(), staff))
	recorder := httptest.NewRecorder()

	server.HelpArticleList(recorder, request)

	if recorder.Code != http.StatusOK {
		t.Fatalf("status = %d, body = %s", recorder.Code, recorder.Body.String())
	}
	if client.lastHelpFilter.Status != "" {
		t.Fatalf("status filter = %q, want all statuses", client.lastHelpFilter.Status)
	}
	if !strings.Contains(recorder.Body.String(), `value="all" selected`) {
		t.Fatalf("all statuses option was not selected:\n%s", recorder.Body.String())
	}
}

func TestHelpCategoryManagementRendersCategoriesAndSavesForm(t *testing.T) {
	client := &supportHTTPClientStub{
		categories: []model.HelpCategory{
			{
				ID:        "payments",
				Slug:      "payments",
				Status:    model.HelpArticleStatusPublished,
				SortOrder: 20,
				UpdatedAt: time.Date(2026, 6, 20, 12, 0, 0, 0, time.UTC),
			},
		},
		upsertedCategory: model.HelpCategory{
			ID:        "safety",
			Slug:      "safety",
			Status:    model.HelpArticleStatusPublished,
			SortOrder: 5,
			UpdatedAt: time.Date(2026, 6, 20, 12, 30, 0, 0, time.UTC),
		},
	}
	server := newSupportHTTPTestServer(t, app.NewSupportUseCase(client, nil))
	staff := &model.StaffUser{
		ID:          uuid.New(),
		Email:       "editor@inflap.local",
		DisplayName: "Editor",
		Permissions: []enum.Permission{enum.PermissionHelpContentEdit},
	}

	list := httptest.NewRequest(http.MethodGet, "/admin/help/categories?status=published", nil)
	list = list.WithContext(adminTestContext(list.Context(), staff))
	listRec := httptest.NewRecorder()
	server.HelpCategoryList(listRec, list)
	if listRec.Code != http.StatusOK {
		t.Fatalf("list status = %d, body = %s", listRec.Code, listRec.Body.String())
	}
	listBody := listRec.Body.String()
	for _, expected := range []string{
		"payments",
		"/admin/help/categories",
		`name="category_id"`,
		`name="sort_order"`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("list body missing %q:\n%s", expected, listBody)
		}
	}
	if client.lastHelpCategoryFilter.Status != model.HelpArticleStatusPublished {
		t.Fatalf("status filter = %q", client.lastHelpCategoryFilter.Status)
	}

	form := url.Values{}
	form.Set("category_id", "safety")
	form.Set("slug", "safety")
	form.Set("status", "published")
	form.Set("sort_order", "5")
	save := httptest.NewRequest(http.MethodPost, "/admin/help/categories", strings.NewReader(form.Encode()))
	save.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	save = save.WithContext(adminTestContext(save.Context(), staff))
	saveRec := httptest.NewRecorder()
	server.SaveHelpCategory(saveRec, save)
	if saveRec.Code != http.StatusSeeOther {
		t.Fatalf("save status = %d, body = %s", saveRec.Code, saveRec.Body.String())
	}
	location := saveRec.Header().Get("Location")
	if !strings.Contains(location, "/admin/help/categories") || !strings.Contains(location, "flash=help.categorySaved") {
		t.Fatalf("redirect location = %q", location)
	}
	if client.lastHelpCategoryUpsert.ActorStaffID != staff.ID.String() ||
		client.lastHelpCategoryUpsert.CategoryID != "safety" ||
		client.lastHelpCategoryUpsert.SortOrder != 5 {
		t.Fatalf("category input = %#v", client.lastHelpCategoryUpsert)
	}
}

func TestSupportSavedReplyManagementRendersRepliesAndSavesForm(t *testing.T) {
	client := &supportHTTPClientStub{
		savedReplies: []model.SupportSavedReply{
			{
				ID:        "refund-status",
				Category:  "payments",
				Status:    model.HelpArticleStatusPublished,
				Tags:      []string{"refunds"},
				SortOrder: 20,
				Translations: map[string]model.SupportSavedReplyTranslation{
					"en": {Title: "Refund status", Body: "I checked your refund status."},
					"ru": {Title: "Статус возврата", Body: "Я проверила статус возврата. Обычно деньги возвращаются тем же способом оплаты после обработки провайдером."},
				},
				UpdatedAt: time.Date(2026, 6, 20, 12, 0, 0, 0, time.UTC),
			},
		},
		upsertedSavedReply: model.SupportSavedReply{
			ID:        "meeting-point",
			Category:  "activities",
			Status:    model.HelpArticleStatusPublished,
			SortOrder: 5,
			Translations: map[string]model.SupportSavedReplyTranslation{
				"en": {Title: "Meeting point", Body: "Please check the meeting point block."},
			},
			UpdatedAt: time.Date(2026, 6, 20, 12, 30, 0, 0, time.UTC),
		},
	}
	server := newSupportHTTPTestServer(t, app.NewSupportUseCase(client, nil))
	staff := &model.StaffUser{
		ID:          uuid.New(),
		Email:       "lead@inflap.local",
		DisplayName: "Lead",
		Roles:       []enum.StaffRole{enum.StaffRoleSupportLead},
	}

	list := httptest.NewRequest(http.MethodGet, "/admin/support/saved-replies?category=payments&status=published", nil)
	list = list.WithContext(withLocale(adminTestContext(list.Context(), staff), localeRU))
	listRec := httptest.NewRecorder()
	server.SupportSavedReplyList(listRec, list)
	if listRec.Code != http.StatusOK {
		t.Fatalf("list status = %d, body = %s", listRec.Code, listRec.Body.String())
	}
	listBody := listRec.Body.String()
	for _, expected := range []string{
		"Статус возврата",
		"Я проверила статус возврата. Обычно деньги возвращаются тем же способом оплаты",
		`name="reply_id"`,
		"Лучше писать на английском, без пробелов, в snake_case или kebab-case.",
		`name="title_en"`,
		`name="body_en"`,
	} {
		if !strings.Contains(listBody, expected) {
			t.Fatalf("list body missing %q:\n%s", expected, listBody)
		}
	}
	if strings.Contains(listBody, "после обработки провайдером.") {
		t.Fatalf("list body contains full saved reply instead of preview:\n%s", listBody)
	}
	if client.lastSavedReplyFilter.Category != "payments" || client.lastSavedReplyFilter.Status != model.HelpArticleStatusPublished {
		t.Fatalf("saved reply filter = %#v", client.lastSavedReplyFilter)
	}

	form := url.Values{}
	form.Set("reply_id", "meeting-point")
	form.Set("category", "activities")
	form.Set("status", "published")
	form.Set("tags", "meeting, activity")
	form.Set("sort_order", "5")
	form.Set("title_en", "Meeting point")
	form.Set("body_en", "Please check the meeting point block.")
	form.Set("title_ru", "Место встречи")
	form.Set("body_ru", "Проверьте блок с местом встречи.")
	save := httptest.NewRequest(http.MethodPost, "/admin/support/saved-replies", strings.NewReader(form.Encode()))
	save.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	save = save.WithContext(adminTestContext(save.Context(), staff))
	saveRec := httptest.NewRecorder()
	server.SaveSupportSavedReply(saveRec, save)
	if saveRec.Code != http.StatusSeeOther {
		t.Fatalf("save status = %d, body = %s", saveRec.Code, saveRec.Body.String())
	}
	location := saveRec.Header().Get("Location")
	if !strings.Contains(location, "/admin/support/saved-replies") || !strings.Contains(location, "flash=support.savedReplySaved") {
		t.Fatalf("redirect location = %q", location)
	}
	input := client.lastSavedReplyUpsert
	if input.ActorStaffID != staff.ID.String() || input.ReplyID != "meeting-point" || input.SortOrder != 5 {
		t.Fatalf("saved reply input = %#v", input)
	}
	if input.Translations["ru"].Body != "Проверьте блок с местом встречи." {
		t.Fatalf("translations = %#v", input.Translations)
	}
}

func TestSaveHelpArticleParsesLocalizedFormAndRedirects(t *testing.T) {
	client := &supportHTTPClientStub{
		upsertedArticle: model.HelpArticle{
			ID:      "refund-policy",
			Slug:    "refund-policy",
			Status:  model.HelpArticleStatusDraft,
			Version: 1,
		},
	}
	server := newSupportHTTPTestServer(t, app.NewSupportUseCase(client, nil))
	staff := &model.StaffUser{
		ID:          uuid.New(),
		Email:       "editor@inflap.local",
		DisplayName: "Editor",
		Permissions: []enum.Permission{enum.PermissionHelpContentEdit},
	}
	form := url.Values{}
	form.Set("slug", "refund-policy")
	form.Set("category_id", "payments")
	form.Set("status", "draft")
	form.Set("tags", "payments, refunds")
	form.Add("surfaces", "help_center")
	form.Add("surfaces", "activity_details")
	form.Set("visibility_user_states", "booked, paid")
	form.Set("visibility_payment_statuses", "paid, refunded")
	form.Set("title_en", "Refund policy")
	form.Set("short_answer_en", "Refund timing depends on the provider.")
	form.Set("body_en", "Open booking details and check provider rules.")
	form.Set("title_ru", "Правила возврата")
	form.Set("short_answer_ru", "Срок зависит от провайдера.")
	form.Set("body_ru", "Откройте детали бронирования.")
	form.Set("title_kk", "Қайтарым ережелері")
	form.Set("short_answer_kk", "Мерзім провайдерге байланысты.")
	form.Set("body_kk", "Брондау деталін ашыңыз.")
	form.Set("related_article_ids", "payment-failed")
	form.Set("action_type", "contact_support")
	form.Set("action_target", "support")
	form.Set("action_label", "Contact support")

	request := httptest.NewRequest(http.MethodPost, "/admin/help/articles/refund-policy", strings.NewReader(form.Encode()))
	request.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	request = request.WithContext(adminTestContext(request.Context(), staff))
	recorder := httptest.NewRecorder()

	server.SaveHelpArticle(recorder, request)

	if recorder.Code != http.StatusSeeOther {
		t.Fatalf("status = %d, body = %s", recorder.Code, recorder.Body.String())
	}
	location := recorder.Header().Get("Location")
	if !strings.Contains(location, "/admin/help/articles/refund-policy/edit") || !strings.Contains(location, "flash=help.articleSaved") {
		t.Fatalf("redirect location = %q", location)
	}
	input := client.lastHelpUpsert
	if input.ActorStaffID != staff.ID.String() {
		t.Fatalf("actor = %q", input.ActorStaffID)
	}
	if input.CategoryID != "payments" || input.Status != model.HelpArticleStatusDraft {
		t.Fatalf("input = %#v", input)
	}
	if len(input.Surfaces) != 2 || input.Surfaces[0] != "help_center" || input.Surfaces[1] != "activity_details" {
		t.Fatalf("surfaces = %#v", input.Surfaces)
	}
	if got := input.Translations["ru"].Title; got != "Правила возврата" {
		t.Fatalf("ru title = %q", got)
	}
	if len(input.Actions) != 1 || input.Actions[0].Type != "contact_support" {
		t.Fatalf("actions = %#v", input.Actions)
	}
}

func TestSaveHelpArticleCanCreatePopularQAWithoutTechnicalFields(t *testing.T) {
	client := &supportHTTPClientStub{
		upsertedArticle: model.HelpArticle{
			ID:      "how-to-contact-support",
			Slug:    "how-to-contact-support",
			Status:  model.HelpArticleStatusDraft,
			Version: 1,
		},
	}
	server := newSupportHTTPTestServer(t, app.NewSupportUseCase(client, nil))
	staff := &model.StaffUser{
		ID:          uuid.New(),
		Email:       "editor@inflap.local",
		DisplayName: "Editor",
		Permissions: []enum.Permission{enum.PermissionHelpContentEdit},
	}

	page := httptest.NewRequest(http.MethodGet, "/admin/help/articles/new", nil)
	page = page.WithContext(adminTestContext(page.Context(), staff))
	pageRec := httptest.NewRecorder()
	server.NewHelpArticlePage(pageRec, page)
	if pageRec.Code != http.StatusOK {
		t.Fatalf("page status = %d, body = %s", pageRec.Code, pageRec.Body.String())
	}
	pageBody := pageRec.Body.String()
	for _, expected := range []string{
		`name="is_popular"`,
		`name="question_template"`,
		"Popular Q&amp;A",
	} {
		if !strings.Contains(pageBody, expected) {
			t.Fatalf("new article body missing %q:\n%s", expected, pageBody)
		}
	}

	form := url.Values{}
	form.Set("question_template", "support_request")
	form.Set("is_popular", "on")
	form.Set("title_en", "How do I contact support?")
	form.Set("short_answer_en", "Open Support requests and start a chat.")
	form.Set("body_en", "If Help Center does not answer your question, open Support requests.")
	form.Set("title_ru", "Как связаться с поддержкой?")
	form.Set("short_answer_ru", "Откройте обращения в поддержку и начните чат.")
	form.Set("body_ru", "Если в Центре помощи нет ответа, откройте обращения в поддержку.")
	form.Set("title_kk", "Қолдауға қалай жазамын?")
	form.Set("short_answer_kk", "Қолдау сұрауларын ашып, чат бастаңыз.")
	form.Set("body_kk", "Көмек орталығында жауап жоқ болса, қолдау сұрауын ашыңыз.")

	request := httptest.NewRequest(http.MethodPost, "/admin/help/articles", strings.NewReader(form.Encode()))
	request.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	request = request.WithContext(adminTestContext(request.Context(), staff))
	recorder := httptest.NewRecorder()

	server.CreateHelpArticle(recorder, request)

	if recorder.Code != http.StatusSeeOther {
		t.Fatalf("status = %d, body = %s", recorder.Code, recorder.Body.String())
	}
	input := client.lastHelpUpsert
	if input.ArticleID != "how-do-i-contact-support" || input.Slug != "how-do-i-contact-support" {
		t.Fatalf("generated IDs = articleID %q slug %q", input.ArticleID, input.Slug)
	}
	if input.CategoryID != "account" || len(input.Actions) != 0 {
		t.Fatalf("unexpected input = %#v", input)
	}
	if !stringSliceContains(input.Tags, "popular") || !stringSliceContains(input.Tags, "account") {
		t.Fatalf("tags = %#v", input.Tags)
	}
	if !stringSliceContains(input.Surfaces, "help_center") {
		t.Fatalf("surfaces = %#v", input.Surfaces)
	}
	if got := input.Translations["ru"].Title; got != "Как связаться с поддержкой?" {
		t.Fatalf("ru title = %q", got)
	}
}

func TestHelpAnalyticsDashboardRendersOperationalMetrics(t *testing.T) {
	client := &supportHTTPClientStub{
		analytics: model.HelpAnalyticsSummary{
			GeneratedAt: time.Date(2026, 6, 20, 12, 0, 0, 0, time.UTC),
			Searches: model.HelpSearchAnalytics{
				Total:          2,
				WithoutResults: 1,
				SuccessRate:    0.5,
				TopNoResultQueries: []model.HelpSearchQueryStat{
					{Query: "visa chargeback", Count: 1},
				},
				RepeatedQueries: []model.HelpSearchQueryStat{
					{Query: "refund money", Count: 3},
				},
			},
			Feedback: model.HelpFeedbackAnalytics{
				Total:          1,
				NotHelpful:     1,
				Escalations:    1,
				NotHelpfulRate: 1,
				TopNotHelpfulArticles: []model.HelpArticleFeedbackStat{
					{ArticleID: "refund-timing", Count: 1, Escalations: 1},
				},
			},
			Tickets: model.SupportTicketAnalytics{
				Total:                       2,
				Open:                        1,
				WaitingSupport:              1,
				Resolved:                    1,
				Urgent:                      1,
				AverageFirstResponseSeconds: 900,
				AverageResolutionSeconds:    5400,
				CSATResponses:               2,
				AverageCSAT:                 4,
			},
		},
	}
	server := newSupportHTTPTestServer(t, app.NewSupportUseCase(client, nil))
	staff := &model.StaffUser{
		ID:          uuid.New(),
		Email:       "lead@inflap.local",
		DisplayName: "Lead",
		Permissions: []enum.Permission{enum.PermissionSupportRead},
	}

	request := httptest.NewRequest(http.MethodGet, "/admin/help/analytics", nil)
	request = request.WithContext(adminTestContext(request.Context(), staff))
	recorder := httptest.NewRecorder()

	server.HelpAnalyticsDashboard(recorder, request)

	if recorder.Code != http.StatusOK {
		t.Fatalf("status = %d, body = %s", recorder.Code, recorder.Body.String())
	}
	body := recorder.Body.String()
	for _, expected := range []string{
		"visa chargeback",
		"refund money",
		"refund-timing",
		"50%",
		"CSAT",
		"4.0",
		"15m",
		"1h 30m",
	} {
		if !strings.Contains(body, expected) {
			t.Fatalf("body missing %q:\n%s", expected, body)
		}
	}
}

func TestSupportTicketQueueRendersFirstResponseSLAIndicator(t *testing.T) {
	now := time.Now().UTC()
	client := &supportHTTPClientStub{
		tickets: []model.SupportTicket{
			{
				ID:                   "ticket-first-response-breach",
				UserID:               "user-1",
				UserNicknameSnapshot: "@nomad",
				AssigneeID:           "agent-2",
				Category:             model.SupportTicketCategoryPayments,
				Status:               model.SupportTicketStatusNew,
				Priority:             model.SupportTicketPriorityNormal,
				PriorityReasonCodes:  []string{"payment_keyword"},
				CustomerSegment:      model.SupportCustomerSegmentGuide,
				CustomerSegmentReasonCodes: []string{
					"verified_guide",
					"followers_10k",
				},
				AssignmentStatus:      model.SupportAssignmentStatusAssigned,
				AssignmentReasonCodes: []string{"skill_payments", "language_ru"},
				Source:                "help_center",
				Locale:                "en",
				LastMessagePreview:    "Не проходит оплата тура.",
				Context:               map[string]string{"screen": "payment_failed"},
				CreatedAt:             now.Add(-31 * time.Minute),
				LastMessageAt:         now.Add(-30 * time.Minute),
			},
		},
	}
	server := newSupportHTTPTestServer(t, app.NewSupportUseCase(client, nil))
	staff := &model.StaffUser{
		ID:          uuid.New(),
		Email:       "support@inflap.local",
		DisplayName: "Support",
		Permissions: []enum.Permission{enum.PermissionSupportRead},
	}

	request := httptest.NewRequest(http.MethodGet, "/admin/support/tickets", nil)
	request = request.WithContext(adminTestContext(request.Context(), staff))
	recorder := httptest.NewRecorder()

	server.SupportTicketQueue(recorder, request)

	if recorder.Code != http.StatusOK {
		t.Fatalf("status = %d, body = %s", recorder.Code, recorder.Body.String())
	}
	body := recorder.Body.String()
	for _, expected := range []string{
		"SLA breached",
		"@nomad",
		"Не проходит оплата тура.",
		"Payment-related message",
		"Assigned by system",
	} {
		if !strings.Contains(body, expected) {
			t.Fatalf("body missing %q:\n%s", expected, body)
		}
	}
	for _, unexpected := range []string{
		`<code>user-1</code>`,
		"agent-2",
		"First response overdue",
		"payment_keyword",
		"Guide",
		"Verified guide profile",
		"10k&#43; followers",
		"verified_guide",
		"followers_10k",
		"Payments specialist",
		"Russian-language support",
		"skill_payments",
		"language_ru",
	} {
		if strings.Contains(body, unexpected) {
			t.Fatalf("support queue rendered raw value %q:\n%s", unexpected, body)
		}
	}
}

func TestSupportTicketQueueRendersAssigneeDisplayName(t *testing.T) {
	now := time.Now().UTC()
	assigneeID := uuid.New()
	client := &supportHTTPClientStub{
		tickets: []model.SupportTicket{
			{
				ID:                         "ticket-assignee-name",
				UserID:                     "user-1",
				UserNicknameSnapshot:       "@nomad",
				AssigneeID:                 assigneeID.String(),
				Category:                   model.SupportTicketCategoryPayments,
				Status:                     model.SupportTicketStatusAssigned,
				Priority:                   model.SupportTicketPriorityHigh,
				CustomerSegment:            model.SupportCustomerSegmentStandard,
				AssignmentStatus:           model.SupportAssignmentStatusAssigned,
				AssignmentReasonCodes:      []string{"skill_payments"},
				LastMessagePreview:         "Need help with payment.",
				Context:                    map[string]string{"screen": "payment_failed"},
				CreatedAt:                  now.Add(-time.Hour),
				LastMessageAt:              now.Add(-30 * time.Minute),
				CustomerSegmentReasonCodes: []string{"default"},
			},
		},
	}
	assignee := &model.StaffUser{
		ID:          assigneeID,
		Email:       "agent.payments@inflap.local",
		DisplayName: "Aruzhan Payments",
		Status:      enum.StaffStatusActive,
	}
	server := newSupportHTTPTestServerWithStaff(
		t,
		app.NewSupportUseCase(client, nil),
		app.NewStaffUseCase(&supportStaffRepoStub{target: assignee}, nil),
	)
	staff := &model.StaffUser{
		ID:          uuid.New(),
		Email:       "support@inflap.local",
		DisplayName: "Support",
		Permissions: []enum.Permission{enum.PermissionSupportRead},
	}

	request := httptest.NewRequest(http.MethodGet, "/admin/support/tickets", nil)
	request = request.WithContext(adminTestContext(request.Context(), staff))
	recorder := httptest.NewRecorder()

	server.SupportTicketQueue(recorder, request)

	if recorder.Code != http.StatusOK {
		t.Fatalf("status = %d, body = %s", recorder.Code, recorder.Body.String())
	}
	body := recorder.Body.String()
	for _, expected := range []string{
		"Responsible",
		"Aruzhan Payments",
	} {
		if !strings.Contains(body, expected) {
			t.Fatalf("body missing %q:\n%s", expected, body)
		}
	}
	if strings.Contains(body, assigneeID.String()) {
		t.Fatalf("support queue rendered raw assignee id:\n%s", body)
	}
	for _, unexpected := range []string{
		"Assigned by system",
		"Payments specialist",
	} {
		if strings.Contains(body, unexpected) {
			t.Fatalf("support queue rendered assignment detail %q:\n%s", unexpected, body)
		}
	}
}

func TestSupportTicketQueueRendersCompactSLAAndResponsibleColumns(t *testing.T) {
	now := time.Now().UTC()
	assigneeID := uuid.New()
	client := &supportHTTPClientStub{
		tickets: []model.SupportTicket{
			{
				ID:                    "ticket-compact-columns",
				UserID:                "user-1",
				UserNicknameSnapshot:  "@nomad",
				AssigneeID:            assigneeID.String(),
				Status:                model.SupportTicketStatusWaitingSupport,
				Priority:              model.SupportTicketPriorityNormal,
				CustomerSegment:       model.SupportCustomerSegmentStandard,
				AssignmentStatus:      model.SupportAssignmentStatusAssigned,
				AssignmentReasonCodes: []string{"skill_payments"},
				LastMessagePreview:    "Need help with payment.",
				Context:               map[string]string{"screen": "payment_failed"},
				CreatedAt:             now.Add(-31 * time.Minute),
				LastMessageAt:         now.Add(-30 * time.Minute),
			},
		},
	}
	assignee := &model.StaffUser{
		ID:          assigneeID,
		Email:       "agent.payments@inflap.local",
		DisplayName: "Aruzhan Payments",
		Status:      enum.StaffStatusActive,
	}
	server := newSupportHTTPTestServerWithStaff(
		t,
		app.NewSupportUseCase(client, nil),
		app.NewStaffUseCase(&supportStaffRepoStub{target: assignee}, nil),
	)
	staff := &model.StaffUser{
		ID:          uuid.New(),
		Email:       "support@inflap.local",
		DisplayName: "Support",
		Permissions: []enum.Permission{enum.PermissionSupportRead},
	}

	request := httptest.NewRequest(http.MethodGet, "/admin/support/tickets", nil)
	request = request.WithContext(adminTestContext(request.Context(), staff))
	recorder := httptest.NewRecorder()

	server.SupportTicketQueue(recorder, request)

	if recorder.Code != http.StatusOK {
		t.Fatalf("status = %d, body = %s", recorder.Code, recorder.Body.String())
	}
	body := recorder.Body.String()
	for _, expected := range []string{
		"SLA breached",
		"Aruzhan Payments",
	} {
		if !strings.Contains(body, expected) {
			t.Fatalf("body missing %q:\n%s", expected, body)
		}
	}
	for _, unexpected := range []string{
		"First response overdue",
		"Assigned by system",
		"Payments specialist",
	} {
		if strings.Contains(body, unexpected) {
			t.Fatalf("support queue rendered detailed value %q:\n%s", unexpected, body)
		}
	}
}

func TestSupportTicketQueueShowsFirstResponseTargetDuration(t *testing.T) {
	now := time.Now().UTC()
	client := &supportHTTPClientStub{
		tickets: []model.SupportTicket{
			{
				ID:                   "ticket-first-response-target",
				UserID:               "user-1",
				UserNicknameSnapshot: "@nomad",
				Status:               model.SupportTicketStatusWaitingSupport,
				Priority:             model.SupportTicketPriorityNormal,
				CustomerSegment:      model.SupportCustomerSegmentStandard,
				LastMessagePreview:   "Need help.",
				Context:              map[string]string{"screen": "support_chat"},
				CreatedAt:            now.Add(-5 * time.Minute),
				LastMessageAt:        now.Add(-5 * time.Minute),
			},
		},
	}
	server := newSupportHTTPTestServer(t, app.NewSupportUseCase(client, nil))
	staff := &model.StaffUser{
		ID:          uuid.New(),
		Email:       "support@inflap.local",
		DisplayName: "Support",
		Permissions: []enum.Permission{enum.PermissionSupportRead},
	}

	request := httptest.NewRequest(http.MethodGet, "/admin/support/tickets", nil)
	request = request.WithContext(adminTestContext(request.Context(), staff))
	recorder := httptest.NewRecorder()

	server.SupportTicketQueue(recorder, request)

	if recorder.Code != http.StatusOK {
		t.Fatalf("status = %d, body = %s", recorder.Code, recorder.Body.String())
	}
	body := recorder.Body.String()
	if !strings.Contains(body, "Answer within 30 min") {
		t.Fatalf("body missing first response target duration:\n%s", body)
	}
	if strings.Contains(body, "On track") {
		t.Fatalf("support queue rendered generic SLA state instead of response target:\n%s", body)
	}
}

func TestSupportTicketQueueMovesEntityIDFromContextToTicketColumn(t *testing.T) {
	now := time.Now().UTC()
	client := &supportHTTPClientStub{
		tickets: []model.SupportTicket{
			{
				ID:                   "ticket-context-entity",
				UserID:               "user-1",
				UserNicknameSnapshot: "@nomad",
				Status:               model.SupportTicketStatusWaitingSupport,
				Priority:             model.SupportTicketPriorityNormal,
				CustomerSegment:      model.SupportCustomerSegmentStandard,
				LastMessagePreview:   "Question about the activity.",
				Context: map[string]string{
					"entity_id": "activity-123",
					"screen":    "activity_details",
				},
				CreatedAt:     now.Add(-time.Hour),
				LastMessageAt: now.Add(-30 * time.Minute),
			},
		},
	}
	server := newSupportHTTPTestServer(t, app.NewSupportUseCase(client, nil))
	staff := &model.StaffUser{
		ID:          uuid.New(),
		Email:       "support@inflap.local",
		DisplayName: "Support",
		Permissions: []enum.Permission{enum.PermissionSupportRead},
	}

	request := httptest.NewRequest(http.MethodGet, "/admin/support/tickets", nil)
	request = request.WithContext(adminTestContext(request.Context(), staff))
	recorder := httptest.NewRecorder()

	server.SupportTicketQueue(recorder, request)

	if recorder.Code != http.StatusOK {
		t.Fatalf("status = %d, body = %s", recorder.Code, recorder.Body.String())
	}
	body := recorder.Body.String()
	for _, expected := range []string{
		"activity-123",
		"screen: activity_details",
	} {
		if !strings.Contains(body, expected) {
			t.Fatalf("body missing %q:\n%s", expected, body)
		}
	}
	for _, unexpected := range []string{
		"entity_id",
		"entity_id: activity-123",
	} {
		if strings.Contains(body, unexpected) {
			t.Fatalf("support queue rendered entity id in context %q:\n%s", unexpected, body)
		}
	}
}

func TestSupportTicketQueueRendersCleanTicketIDAndKeepsUserColumnFocused(t *testing.T) {
	now := time.Now().UTC()
	client := &supportHTTPClientStub{
		tickets: []model.SupportTicket{
			{
				ID:                         "support-6c91f13b-20260620120000.000000000",
				UserID:                     "user-1",
				UserNicknameSnapshot:       "akashimo",
				Status:                     model.SupportTicketStatusWaitingSupport,
				Priority:                   model.SupportTicketPriorityNormal,
				CustomerSegment:            model.SupportCustomerSegmentStandard,
				CustomerSegmentReasonCodes: []string{"standard"},
				LastMessagePreview:         "Нужна помощь.",
				Context: map[string]string{
					"entity_id": "activity-123",
					"screen":    "activity_details",
				},
				CreatedAt:     now.Add(-time.Hour),
				LastMessageAt: now.Add(-30 * time.Minute),
			},
		},
	}
	server := newSupportHTTPTestServer(t, app.NewSupportUseCase(client, nil))
	staff := &model.StaffUser{
		ID:          uuid.New(),
		Email:       "support@inflap.local",
		DisplayName: "Support",
		Permissions: []enum.Permission{enum.PermissionSupportRead},
	}

	request := httptest.NewRequest(http.MethodGet, "/admin/support/tickets", nil)
	request = request.WithContext(withLocale(adminTestContext(request.Context(), staff), localeRU))
	recorder := httptest.NewRecorder()

	server.SupportTicketQueue(recorder, request)

	if recorder.Code != http.StatusOK {
		t.Fatalf("status = %d, body = %s", recorder.Code, recorder.Body.String())
	}
	body := recorder.Body.String()
	for _, expected := range []string{
		"6c91f13b-20260620120000.000000000",
		"activity-123",
		"akashimo",
		"screen: activity_details",
	} {
		if !strings.Contains(body, expected) {
			t.Fatalf("body missing %q:\n%s", expected, body)
		}
	}
	for _, unexpected := range []string{
		">support-<",
		"ID: activity-123",
		`<span class="muted block">Обычный</span>`,
		"Обычный аккаунт",
	} {
		if strings.Contains(body, unexpected) {
			t.Fatalf("support queue rendered noisy value %q:\n%s", unexpected, body)
		}
	}
}

func TestSupportTicketQueueHidesSupportEntityIDFromTicketColumn(t *testing.T) {
	now := time.Now().UTC()
	relatedSupportID := "support-6c91f13b-5d4c-42c4-884c-58899917741b-20260626135925.024664842"
	client := &supportHTTPClientStub{
		tickets: []model.SupportTicket{
			{
				ID:                   "support-6c91f13b-5d4c-42c4-884c-58899917741b-20260627060611.406723382",
				UserID:               "user-1",
				UserNicknameSnapshot: "akashimo",
				Status:               model.SupportTicketStatusWaitingSupport,
				Priority:             model.SupportTicketPriorityNormal,
				CustomerSegment:      model.SupportCustomerSegmentStandard,
				LastMessagePreview:   "Нужна помощь.",
				Context: map[string]string{
					"entity_id": relatedSupportID,
					"screen":    "support_chat",
				},
				CreatedAt:     now.Add(-time.Hour),
				LastMessageAt: now.Add(-30 * time.Minute),
			},
		},
	}
	server := newSupportHTTPTestServer(t, app.NewSupportUseCase(client, nil))
	staff := &model.StaffUser{
		ID:          uuid.New(),
		Email:       "support@inflap.local",
		DisplayName: "Support",
		Permissions: []enum.Permission{enum.PermissionSupportRead},
	}

	request := httptest.NewRequest(http.MethodGet, "/admin/support/tickets", nil)
	request = request.WithContext(adminTestContext(request.Context(), staff))
	recorder := httptest.NewRecorder()

	server.SupportTicketQueue(recorder, request)

	if recorder.Code != http.StatusOK {
		t.Fatalf("status = %d, body = %s", recorder.Code, recorder.Body.String())
	}
	body := recorder.Body.String()
	if !strings.Contains(body, "6c91f13b-5d4c-42c4-884c-58899917741b-20260627060611.406723382") {
		t.Fatalf("body missing clean ticket id:\n%s", body)
	}
	if strings.Contains(body, relatedSupportID) {
		t.Fatalf("support queue rendered related support id in ticket column:\n%s", body)
	}
	if strings.Contains(body, "entity_id") {
		t.Fatalf("support queue rendered support entity_id in context:\n%s", body)
	}
}

func TestSupportTicketQueueTemplateDoesNotExposeCategoryFilterOrColumn(t *testing.T) {
	template, err := os.ReadFile("templates/support/index.html")
	if err != nil {
		t.Fatalf("read support index template: %v", err)
	}
	source := string(template)
	for _, unexpected := range []string{
		`name="category"`,
		"CategoryOptions",
		"support.category",
		".Item.Category",
	} {
		if strings.Contains(source, unexpected) {
			t.Fatalf("support queue template exposes %q:\n%s", unexpected, source)
		}
	}
}

func TestSupportTicketQueueDefaultsToAllStatusesAndHidesLegacyOpenStatus(t *testing.T) {
	client := &supportHTTPClientStub{}
	server := newSupportHTTPTestServer(t, app.NewSupportUseCase(client, nil))
	staff := &model.StaffUser{
		ID:          uuid.New(),
		Email:       "support@inflap.local",
		DisplayName: "Support",
		Permissions: []enum.Permission{enum.PermissionSupportRead},
	}

	request := httptest.NewRequest(http.MethodGet, "/admin/support/tickets", nil)
	request = request.WithContext(adminTestContext(request.Context(), staff))
	recorder := httptest.NewRecorder()

	server.SupportTicketQueue(recorder, request)

	if recorder.Code != http.StatusOK {
		t.Fatalf("status = %d, body = %s", recorder.Code, recorder.Body.String())
	}
	if client.lastTicketFilter.Status != "" {
		t.Fatalf("status filter = %q, want all statuses", client.lastTicketFilter.Status)
	}
	body := recorder.Body.String()
	if !strings.Contains(body, `value="all" selected`) {
		t.Fatalf("all statuses option was not selected:\n%s", body)
	}
	if strings.Contains(body, `value="open"`) {
		t.Fatalf("legacy open status should not be shown in support queue filter:\n%s", body)
	}
}

func TestSupportTicketQueuePassesSLABreachedFilter(t *testing.T) {
	client := &supportHTTPClientStub{}
	server := newSupportHTTPTestServer(t, app.NewSupportUseCase(client, nil))
	staff := &model.StaffUser{
		ID:          uuid.New(),
		Email:       "support@inflap.local",
		DisplayName: "Support",
		Permissions: []enum.Permission{enum.PermissionSupportRead},
	}

	request := httptest.NewRequest(http.MethodGet, "/admin/support/tickets?sla=breached", nil)
	request = request.WithContext(adminTestContext(request.Context(), staff))
	recorder := httptest.NewRecorder()

	server.SupportTicketQueue(recorder, request)

	if recorder.Code != http.StatusOK {
		t.Fatalf("status = %d, body = %s", recorder.Code, recorder.Body.String())
	}
	if !client.lastTicketFilter.SLABreached {
		t.Fatalf("SLABreached filter = false, want true")
	}
	if !strings.Contains(recorder.Body.String(), `value="breached" selected`) {
		t.Fatalf("SLA breached option was not selected:\n%s", recorder.Body.String())
	}
}

func TestSupportTicketDetailRendersSavedRepliesForReplyAgents(t *testing.T) {
	now := time.Now().UTC()
	client := &supportHTTPClientStub{
		detail: model.SupportTicketDetail{
			Ticket: model.SupportTicket{
				ID:             "ticket-payment",
				UserID:         "user-2",
				ConversationID: "conversation-1",
				Category:       model.SupportTicketCategoryPayments,
				Status:         model.SupportTicketStatusWaitingSupport,
				Priority:       model.SupportTicketPriorityNormal,
				Source:         "help_center",
				Locale:         "en",
				CreatedAt:      now.Add(-time.Hour),
				LastMessageAt:  now.Add(-30 * time.Minute),
			},
		},
		savedReplies: []model.SupportSavedReply{
			{
				ID:        "refund-status",
				Category:  "payments",
				Status:    model.HelpArticleStatusPublished,
				Tags:      []string{"refunds"},
				SortOrder: 20,
				Translations: map[string]model.SupportSavedReplyTranslation{
					"en": {Title: "Refund status", Body: "I checked your refund status."},
					"ru": {Title: "Статус возврата", Body: "Я проверила статус возврата. Обычно деньги возвращаются тем же способом оплаты после обработки провайдером."},
				},
			},
		},
	}
	server := newSupportHTTPTestServer(t, app.NewSupportUseCase(client, nil))
	staff := &model.StaffUser{
		ID:          uuid.New(),
		Email:       "support@inflap.local",
		DisplayName: "Support",
		Permissions: []enum.Permission{enum.PermissionSupportReply},
	}

	request := httptest.NewRequest(http.MethodGet, "/admin/support/tickets/ticket-payment", nil)
	request.SetPathValue("ticketID", "ticket-payment")
	request = request.WithContext(withLocale(adminTestContext(request.Context(), staff), localeRU))
	recorder := httptest.NewRecorder()

	server.SupportTicketDetail(recorder, request)

	if recorder.Code != http.StatusOK {
		t.Fatalf("status = %d, body = %s", recorder.Code, recorder.Body.String())
	}
	body := recorder.Body.String()
	for _, expected := range []string{
		"Статус возврата",
		"Я проверила статус возврата",
		`data-support-saved-reply`,
		`data-support-reply-composer`,
	} {
		if !strings.Contains(body, expected) {
			t.Fatalf("body missing %q:\n%s", expected, body)
		}
	}
	for _, unexpected := range []string{
		`<code>refund-status</code>`,
		"refunds",
		"Refund status",
		"I checked your refund status.",
	} {
		if strings.Contains(body, unexpected) {
			t.Fatalf("body contains %q:\n%s", unexpected, body)
		}
	}
	if client.lastSavedReplyFilter.Category != "payments" || client.lastSavedReplyFilter.Status != model.HelpArticleStatusPublished {
		t.Fatalf("saved reply filter = %#v", client.lastSavedReplyFilter)
	}
}

func TestReplySupportTicketRedirectsBackToChatComposer(t *testing.T) {
	client := &supportHTTPClientStub{}
	server := newSupportHTTPTestServer(t, app.NewSupportUseCase(client, nil))
	staff := &model.StaffUser{
		ID:          uuid.New(),
		Email:       "support@inflap.local",
		DisplayName: "Support",
		Permissions: []enum.Permission{enum.PermissionSupportReply},
	}

	form := url.Values{}
	form.Set("message", "Проверяю платеж, скоро вернусь с ответом.")
	request := httptest.NewRequest(http.MethodPost, "/admin/support/tickets/ticket-payment/reply?status=waiting_support", strings.NewReader(form.Encode()))
	request.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	request.SetPathValue("ticketID", "ticket-payment")
	request = request.WithContext(adminTestContext(request.Context(), staff))
	recorder := httptest.NewRecorder()

	server.ReplySupportTicket(recorder, request)

	if recorder.Code != http.StatusSeeOther {
		t.Fatalf("status = %d, body = %s", recorder.Code, recorder.Body.String())
	}
	location := recorder.Header().Get("Location")
	if !strings.HasPrefix(location, "/admin/support/tickets/ticket-payment?") ||
		!strings.Contains(location, "flash=support.ticketUpdated") ||
		!strings.Contains(location, "status=waiting_support") ||
		!strings.HasSuffix(location, "#support-chat-composer") {
		t.Fatalf("redirect location = %q, want detail URL preserving query and scrolling to chat composer", location)
	}
}

func TestSupportTicketDetailRendersCleanSupportTicketID(t *testing.T) {
	now := time.Now().UTC()
	client := &supportHTTPClientStub{
		detail: model.SupportTicketDetail{
			Ticket: model.SupportTicket{
				ID:                   "support-6c91f13b-20260620120000.000000000",
				UserID:               "user-2",
				UserNicknameSnapshot: "akashimo",
				Status:               model.SupportTicketStatusWaitingSupport,
				Priority:             model.SupportTicketPriorityNormal,
				CustomerSegment:      model.SupportCustomerSegmentStandard,
				Locale:               "ru",
				CreatedAt:            now.Add(-time.Hour),
				LastMessageAt:        now.Add(-30 * time.Minute),
			},
		},
	}
	server := newSupportHTTPTestServer(t, app.NewSupportUseCase(client, nil))
	staff := &model.StaffUser{
		ID:          uuid.New(),
		Email:       "support@inflap.local",
		DisplayName: "Support",
		Permissions: []enum.Permission{enum.PermissionSupportRead},
	}

	request := httptest.NewRequest(http.MethodGet, "/admin/support/tickets/support-6c91f13b-20260620120000.000000000", nil)
	request.SetPathValue("ticketID", "support-6c91f13b-20260620120000.000000000")
	request = request.WithContext(adminTestContext(request.Context(), staff))
	recorder := httptest.NewRecorder()

	server.SupportTicketDetail(recorder, request)

	if recorder.Code != http.StatusOK {
		t.Fatalf("status = %d, body = %s", recorder.Code, recorder.Body.String())
	}
	body := recorder.Body.String()
	if !strings.Contains(body, "6c91f13b-20260620120000.000000000") {
		t.Fatalf("body missing clean support ticket id:\n%s", body)
	}
	for _, unexpected := range []string{
		">support-<",
		"<code>support-6c91f13b-20260620120000.000000000</code>",
	} {
		if strings.Contains(body, unexpected) {
			t.Fatalf("support detail rendered noisy id %q:\n%s", unexpected, body)
		}
	}
}

func TestSupportTicketDetailHidesEntityIDFromContext(t *testing.T) {
	now := time.Now().UTC()
	previousSupportID := "support-6c91f13b-5d4c-42c4-884c-58899917741b-20260626135925.024664842"
	currentTicketID := "support-6c91f13b-5d4c-42c4-884c-58899917741b-20260627060611.406723382"
	client := &supportHTTPClientStub{
		detail: model.SupportTicketDetail{
			Ticket: model.SupportTicket{
				ID:                   currentTicketID,
				UserID:               "user-2",
				UserNicknameSnapshot: "akashimo",
				Status:               model.SupportTicketStatusWaitingSupport,
				Priority:             model.SupportTicketPriorityNormal,
				CustomerSegment:      model.SupportCustomerSegmentStandard,
				Locale:               "ru",
				Context: map[string]string{
					"entity_id":          previousSupportID,
					"previous_ticket_id": previousSupportID,
					"screen":             "support_chat",
				},
				CreatedAt:     now.Add(-time.Hour),
				LastMessageAt: now.Add(-30 * time.Minute),
			},
		},
	}
	server := newSupportHTTPTestServer(t, app.NewSupportUseCase(client, nil))
	staff := &model.StaffUser{
		ID:          uuid.New(),
		Email:       "support@inflap.local",
		DisplayName: "Support",
		Permissions: []enum.Permission{enum.PermissionSupportRead},
	}

	request := httptest.NewRequest(http.MethodGet, "/admin/support/tickets/"+currentTicketID, nil)
	request.SetPathValue("ticketID", currentTicketID)
	request = request.WithContext(adminTestContext(request.Context(), staff))
	recorder := httptest.NewRecorder()

	server.SupportTicketDetail(recorder, request)

	if recorder.Code != http.StatusOK {
		t.Fatalf("status = %d, body = %s", recorder.Code, recorder.Body.String())
	}
	body := recorder.Body.String()
	if !strings.Contains(body, "6c91f13b-5d4c-42c4-884c-58899917741b-20260627060611.406723382") {
		t.Fatalf("body missing clean current ticket id:\n%s", body)
	}
	for _, expected := range []string{
		"screen",
		"support_chat",
	} {
		if !strings.Contains(body, expected) {
			t.Fatalf("body missing context value %q:\n%s", expected, body)
		}
	}
	for _, unexpected := range []string{
		"entity_id",
		"previous_ticket_id",
		previousSupportID,
	} {
		if strings.Contains(body, unexpected) {
			t.Fatalf("support detail rendered entity id context %q:\n%s", unexpected, body)
		}
	}
}

func TestSupportTicketDetailRendersConversationChatAndHumanMetadata(t *testing.T) {
	now := time.Date(2026, 6, 20, 12, 0, 0, 0, time.UTC)
	client := &supportHTTPClientStub{
		detail: model.SupportTicketDetail{
			Ticket: model.SupportTicket{
				ID:                         "ticket-payment",
				UserID:                     "user-2",
				AssigneeID:                 "agent-2",
				ConversationID:             "conversation-1",
				Category:                   model.SupportTicketCategoryTechnical,
				Status:                     model.SupportTicketStatusWaitingSupport,
				Priority:                   model.SupportTicketPriorityHigh,
				PriorityReasonCodes:        []string{"payment_keyword"},
				CustomerSegment:            model.SupportCustomerSegmentGuide,
				CustomerSegmentReasonCodes: []string{"verified_guide", "followers_10k"},
				SegmentRefreshStatus:       "fresh",
				AssignmentStatus:           model.SupportAssignmentStatusAssigned,
				AssignmentReasonCodes:      []string{"skill_payments", "language_ru"},
				Source:                     "help_center",
				Locale:                     "ru",
				CreatedAt:                  now.Add(-time.Hour),
				LastMessageAt:              now.Add(-30 * time.Minute),
			},
			Events: []model.SupportTicketEvent{
				{
					TicketID:  "ticket-payment",
					ActorID:   "user-2",
					ActorType: "user",
					EventType: "user_replied",
					Payload: map[string]string{
						"actor_nickname":   "@nomad",
						"message_preview":  "Не проходит оплата тура.",
						"attachment_count": "2",
						"file_ids":         "11111111-1111-1111-1111-111111111111,22222222-2222-2222-2222-222222222222",
					},
					CreatedAt: now.Add(-45 * time.Minute),
				},
				{
					TicketID:  "ticket-payment",
					ActorID:   "agent-2",
					ActorType: "support_agent",
					EventType: "agent_replied",
					Payload: map[string]string{
						"actor_display_name": "Aruzhan Ops",
						"message_preview":    "Проверяю платеж, скоро вернусь с ответом.",
					},
					CreatedAt: now.Add(-30 * time.Minute),
				},
				{
					TicketID:  "ticket-payment",
					ActorID:   "system",
					ActorType: "system",
					EventType: "ticket_segment_calculated",
					Payload: map[string]string{
						"customer_segment": "guide",
						"reason_codes":     "verified_guide,followers_10k",
						"refresh_status":   "fresh",
					},
					CreatedAt: now.Add(-25 * time.Minute),
				},
				{
					TicketID:  "ticket-payment",
					ActorID:   "user-2",
					ActorType: "user",
					EventType: "ticket_closed_by_user",
					Payload: map[string]string{
						"actor_nickname": "@nomad",
						"reason":         "closed_from_mobile",
					},
					CreatedAt: now.Add(-20 * time.Minute),
				},
				{
					TicketID:  "ticket-payment",
					ActorID:   "user-2",
					ActorType: "user",
					EventType: "ticket_csat_submitted",
					Payload: map[string]string{
						"actor_nickname": "@nomad",
						"rating":         "5",
						"comment":        "Fast and helpful.",
					},
					CreatedAt: now.Add(-15 * time.Minute),
				},
			},
		},
	}
	server := newSupportHTTPTestServer(t, app.NewSupportUseCase(client, nil))
	staff := &model.StaffUser{
		ID:          uuid.New(),
		Email:       "support@inflap.local",
		DisplayName: "Support",
		Permissions: []enum.Permission{enum.PermissionSupportReply},
	}

	request := httptest.NewRequest(http.MethodGet, "/admin/support/tickets/ticket-payment", nil)
	request.SetPathValue("ticketID", "ticket-payment")
	request = request.WithContext(adminTestContext(request.Context(), staff))
	recorder := httptest.NewRecorder()

	server.SupportTicketDetail(recorder, request)

	if recorder.Code != http.StatusOK {
		t.Fatalf("status = %d, body = %s", recorder.Code, recorder.Body.String())
	}
	body := recorder.Body.String()
	for _, expected := range []string{
		"@nomad",
		"Aruzhan Ops",
		"Russian",
		"Payment-related message",
		"Guide",
		"Verified guide profile",
		"10k&#43; followers",
		"Up to date",
		"Assigned by system",
		"Payments specialist",
		"Russian-language support",
		"Не проходит оплата тура.",
		"Attachments: 2",
		"Attachment 1",
		"Attachment 2",
		`href="/admin/support/tickets/ticket-payment/attachments/0/0"`,
		`href="/admin/support/tickets/ticket-payment/attachments/0/1"`,
		"Проверяю платеж, скоро вернусь с ответом.",
		"Customer segment recalculated",
		"Request closed by user",
		"Support rating submitted",
		"User rating",
		"5/5",
		"Fast and helpful.",
		`class="support-chat"`,
		`class="support-chat-composer`,
		`id="support-chat-composer"`,
	} {
		if !strings.Contains(body, expected) {
			t.Fatalf("body missing %q:\n%s", expected, body)
		}
	}
	for _, unexpected := range []string{
		">Category<",
		">Source<",
		">Reply</span>",
		"help_center",
		"technical",
		"payment_keyword",
		"verified_guide",
		"followers_10k",
		"skill_payments",
		"language_ru",
		"closed_from_mobile",
		"11111111-1111-1111-1111-111111111111",
		"22222222-2222-2222-2222-222222222222",
		"ticket_csat_submitted",
		"ticket_segment_calculated",
		">system<",
		"conversation-1",
		">Conversation</dt>",
		"user-2</code>",
		"agent-2</code>",
		"Ticket events",
	} {
		if strings.Contains(body, unexpected) {
			t.Fatalf("body contains %q:\n%s", unexpected, body)
		}
	}
}

func TestSupportTicketAttachmentRedirectsToPresignedDownloadURL(t *testing.T) {
	attachmentID := uuid.MustParse("33333333-3333-3333-3333-333333333333")
	client := &supportHTTPClientStub{
		detail: model.SupportTicketDetail{
			Ticket: model.SupportTicket{ID: "ticket-payment"},
			Events: []model.SupportTicketEvent{
				{
					TicketID:  "ticket-payment",
					ActorType: "user",
					EventType: "user_replied",
					Payload: map[string]string{
						"file_ids":         attachmentID.String(),
						"attachment_count": "1",
					},
				},
			},
		},
	}
	files := &supportAttachmentDownloadClientStub{
		downloadURL: "https://files.inflap.test/support/receipt.jpg?signature=temporary",
		expiresAt:   time.Date(2026, 6, 20, 12, 10, 0, 0, time.UTC),
	}
	support := app.NewSupportUseCase(client, nil)
	support.SetFileDownloadClient(files)
	server := newSupportHTTPTestServer(t, support)
	staff := &model.StaffUser{
		ID:          uuid.New(),
		Email:       "support@inflap.local",
		DisplayName: "Support",
		Permissions: []enum.Permission{enum.PermissionSupportRead},
	}

	request := httptest.NewRequest(http.MethodGet, "/admin/support/tickets/ticket-payment/attachments/0/0", nil)
	request.SetPathValue("ticketID", "ticket-payment")
	request.SetPathValue("eventIndex", "0")
	request.SetPathValue("attachmentIndex", "0")
	request = request.WithContext(adminTestContext(request.Context(), staff))
	recorder := httptest.NewRecorder()

	server.SupportTicketAttachment(recorder, request)

	if recorder.Code != http.StatusFound {
		t.Fatalf("status = %d, body = %s", recorder.Code, recorder.Body.String())
	}
	if location := recorder.Header().Get("Location"); location != files.downloadURL {
		t.Fatalf("Location = %q, want %q", location, files.downloadURL)
	}
	if files.calls != 1 || files.fileID != attachmentID {
		t.Fatalf("file client calls = %d fileID = %s", files.calls, files.fileID)
	}
}

func TestSupportTicketDetailRendersAssigneeAutocompleteFromActiveSupportAgents(t *testing.T) {
	now := time.Date(2026, 6, 20, 12, 0, 0, 0, time.UTC)
	activeStaffID := uuid.New()
	client := &supportHTTPClientStub{
		detail: model.SupportTicketDetail{
			Ticket: model.SupportTicket{
				ID:            "ticket-payment",
				UserID:        "user-2",
				Status:        model.SupportTicketStatusWaitingSupport,
				Priority:      model.SupportTicketPriorityHigh,
				Locale:        "en",
				CreatedAt:     now.Add(-time.Hour),
				LastMessageAt: now.Add(-30 * time.Minute),
			},
		},
		agents: []model.SupportAgent{
			{
				StaffID:     activeStaffID.String(),
				DisplayName: "Aigerim Support",
				Status:      model.SupportAgentStatusActive,
				Languages:   []string{"ru", "en"},
				Skills:      []model.SupportAgentSkill{model.SupportAgentSkillPayments},
				Level:       model.SupportAgentLevelSenior,
			},
			{
				StaffID:     "staff-paused",
				DisplayName: "Paused Agent",
				Status:      model.SupportAgentStatusPaused,
				Languages:   []string{"en"},
				Skills:      []model.SupportAgentSkill{model.SupportAgentSkillTechnical},
				Level:       model.SupportAgentLevelAgent,
			},
		},
	}
	agentStaff := &model.StaffUser{
		ID:          activeStaffID,
		Email:       "aigerim@inflap.local",
		DisplayName: "Aigerim Support",
	}
	server := newSupportHTTPTestServerWithStaff(t, app.NewSupportUseCase(client, nil), app.NewStaffUseCase(&supportStaffRepoStub{target: agentStaff}, nil))
	staff := &model.StaffUser{
		ID:          uuid.New(),
		Email:       "lead@inflap.local",
		DisplayName: "Lead",
		Permissions: []enum.Permission{enum.PermissionSupportManage},
	}

	request := httptest.NewRequest(http.MethodGet, "/admin/support/tickets/ticket-payment", nil)
	request.SetPathValue("ticketID", "ticket-payment")
	request = request.WithContext(adminTestContext(request.Context(), staff))
	recorder := httptest.NewRecorder()

	server.SupportTicketDetail(recorder, request)

	if recorder.Code != http.StatusOK {
		t.Fatalf("status = %d, body = %s", recorder.Code, recorder.Body.String())
	}
	if client.lastAgentFilter.Status != model.SupportAgentStatusActive {
		t.Fatalf("agent filter status = %q, want active", client.lastAgentFilter.Status)
	}
	body := recorder.Body.String()
	for _, expected := range []string{
		`name="assignee_query"`,
		`list="support-assignee-options"`,
		`value="Aigerim Support"`,
		"Aigerim Support",
		"aigerim@inflap.local",
	} {
		if !strings.Contains(body, expected) {
			t.Fatalf("body missing %q:\n%s", expected, body)
		}
	}
	if strings.Contains(body, `value="Aigerim Support · `+activeStaffID.String()+`"`) ||
		strings.Contains(body, `value="Aigerim Support &lt;aigerim@inflap.local&gt; · `+activeStaffID.String()+`"`) {
		t.Fatalf("assignee visible value contains staff id:\n%s", body)
	}
	if strings.Contains(body, "Paused Agent") || strings.Contains(body, "staff-paused") {
		t.Fatalf("body contains inactive support agent:\n%s", body)
	}
}

func TestAssignSupportTicketResolvesAutocompleteValueToSupportAgentID(t *testing.T) {
	activeStaffID := uuid.New()
	client := &supportHTTPClientStub{
		agents: []model.SupportAgent{
			{
				StaffID:     activeStaffID.String(),
				DisplayName: "Aigerim Support",
				Status:      model.SupportAgentStatusActive,
				Languages:   []string{"ru", "en"},
				Skills:      []model.SupportAgentSkill{model.SupportAgentSkillPayments},
				Level:       model.SupportAgentLevelSenior,
			},
			{
				StaffID:     "staff-paused",
				DisplayName: "Paused Agent",
				Status:      model.SupportAgentStatusPaused,
			},
		},
	}
	agentStaff := &model.StaffUser{
		ID:          activeStaffID,
		Email:       "aigerim@inflap.local",
		DisplayName: "Aigerim Support",
	}
	server := newSupportHTTPTestServerWithStaff(t, app.NewSupportUseCase(client, nil), app.NewStaffUseCase(&supportStaffRepoStub{target: agentStaff}, nil))
	staff := &model.StaffUser{
		ID:          uuid.New(),
		Email:       "lead@inflap.local",
		DisplayName: "Lead",
		Permissions: []enum.Permission{enum.PermissionSupportManage},
	}
	form := url.Values{}
	form.Set("assignee_query", "aigerim@inflap.local")
	form.Set("assignment_reason", "Payment queue ownership")
	request := httptest.NewRequest(http.MethodPost, "/admin/support/tickets/ticket-payment/assign", strings.NewReader(form.Encode()))
	request.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	request.SetPathValue("ticketID", "ticket-payment")
	request = request.WithContext(adminTestContext(request.Context(), staff))
	recorder := httptest.NewRecorder()

	server.AssignSupportTicket(recorder, request)

	if recorder.Code != http.StatusSeeOther {
		t.Fatalf("status = %d, body = %s", recorder.Code, recorder.Body.String())
	}
	if client.lastAgentFilter.Status != model.SupportAgentStatusActive {
		t.Fatalf("agent filter status = %q, want active", client.lastAgentFilter.Status)
	}
	if client.lastTicketAssign.AssigneeID != activeStaffID.String() || client.lastTicketAssign.Reason != "Payment queue ownership" {
		t.Fatalf("assign input = %#v", client.lastTicketAssign)
	}
}

func TestSupportTicketDetailResolvesAssigneeDisplayNameFromStaffDirectory(t *testing.T) {
	now := time.Date(2026, 6, 20, 12, 0, 0, 0, time.UTC)
	assigneeID := uuid.New()
	client := &supportHTTPClientStub{
		detail: model.SupportTicketDetail{
			Ticket: model.SupportTicket{
				ID:             "ticket-payment",
				UserID:         "user-2",
				AssigneeID:     assigneeID.String(),
				ConversationID: "conversation-1",
				Status:         model.SupportTicketStatusAssigned,
				Priority:       model.SupportTicketPriorityHigh,
				Locale:         "en",
				CreatedAt:      now.Add(-time.Hour),
				LastMessageAt:  now.Add(-30 * time.Minute),
			},
			Events: []model.SupportTicketEvent{
				{
					TicketID:  "ticket-payment",
					ActorID:   "user-2",
					ActorType: "user",
					EventType: "user_replied",
					Payload: map[string]string{
						"actor_nickname":  "@nomad",
						"message_preview": "Payment was charged twice.",
					},
					CreatedAt: now.Add(-45 * time.Minute),
				},
			},
		},
	}
	assignee := &model.StaffUser{
		ID:          assigneeID,
		Email:       "agent@inflap.local",
		DisplayName: "Aruzhan Support Lead",
	}
	server := newSupportHTTPTestServerWithStaff(t, app.NewSupportUseCase(client, nil), app.NewStaffUseCase(&supportStaffRepoStub{target: assignee}, nil))
	staff := &model.StaffUser{
		ID:          uuid.New(),
		Email:       "viewer@inflap.local",
		DisplayName: "Viewer",
		Permissions: []enum.Permission{enum.PermissionSupportRead},
	}

	request := httptest.NewRequest(http.MethodGet, "/admin/support/tickets/ticket-payment", nil)
	request.SetPathValue("ticketID", "ticket-payment")
	request = request.WithContext(adminTestContext(request.Context(), staff))
	recorder := httptest.NewRecorder()

	server.SupportTicketDetail(recorder, request)

	if recorder.Code != http.StatusOK {
		t.Fatalf("status = %d, body = %s", recorder.Code, recorder.Body.String())
	}
	body := recorder.Body.String()
	if !strings.Contains(body, "Aruzhan Support Lead") {
		t.Fatalf("body missing assignee display name:\n%s", body)
	}
	if strings.Contains(body, assigneeID.String()) {
		t.Fatalf("body contains raw assignee id %q:\n%s", assigneeID.String(), body)
	}
}

func TestSupportTicketDetailRendersResolutionSLAIndicator(t *testing.T) {
	now := time.Now().UTC()
	firstResponseAt := now.Add(-23 * time.Hour)
	client := &supportHTTPClientStub{
		detail: model.SupportTicketDetail{
			Ticket: model.SupportTicket{
				ID:              "ticket-resolution-breach",
				UserID:          "user-2",
				ConversationID:  "conversation-1",
				Category:        model.SupportTicketCategoryTechnical,
				Status:          model.SupportTicketStatusWaitingSupport,
				Priority:        model.SupportTicketPriorityNormal,
				Source:          "support_chat",
				Locale:          "en",
				Context:         map[string]string{"screen": "activity_details"},
				FirstResponseAt: &firstResponseAt,
				CreatedAt:       now.Add(-25 * time.Hour),
				LastMessageAt:   now.Add(-2 * time.Hour),
			},
		},
	}
	server := newSupportHTTPTestServer(t, app.NewSupportUseCase(client, nil))
	staff := &model.StaffUser{
		ID:          uuid.New(),
		Email:       "support@inflap.local",
		DisplayName: "Support",
		Permissions: []enum.Permission{enum.PermissionSupportRead},
	}

	request := httptest.NewRequest(http.MethodGet, "/admin/support/tickets/ticket-resolution-breach", nil)
	request.SetPathValue("ticketID", "ticket-resolution-breach")
	request = request.WithContext(adminTestContext(request.Context(), staff))
	recorder := httptest.NewRecorder()

	server.SupportTicketDetail(recorder, request)

	if recorder.Code != http.StatusOK {
		t.Fatalf("status = %d, body = %s", recorder.Code, recorder.Body.String())
	}
	body := recorder.Body.String()
	if !strings.Contains(body, "Resolution overdue") {
		t.Fatalf("body missing resolution SLA label:\n%s", body)
	}
	if strings.Contains(body, "SLA breached") {
		t.Fatalf("body shows generic SLA state instead of actionable label:\n%s", body)
	}
}

func TestSupportAgentRoutingPageRendersAndSavesForms(t *testing.T) {
	supportProfileStaffID := uuid.New()
	client := &supportHTTPClientStub{
		agents: []model.SupportAgent{
			{
				StaffID:       supportProfileStaffID.String(),
				DisplayName:   "Нурланова Айгерим Сапаровна",
				FirstName:     "Айгерим",
				LastName:      "Нурланова",
				MiddleName:    "Сапаровна",
				Status:        model.SupportAgentStatusActive,
				Languages:     []string{"ru", "en"},
				Skills:        []model.SupportAgentSkill{model.SupportAgentSkillPayments, model.SupportAgentSkillTechnical},
				Level:         model.SupportAgentLevelSenior,
				MaxActiveLoad: 6,
				Timezone:      "Asia/Almaty",
				UpdatedAt:     time.Date(2026, 6, 20, 12, 0, 0, 0, time.UTC),
			},
		},
		userSegment: model.SupportUserSegment{
			UserID:          "user-123",
			Nickname:        "@nomad",
			CustomerSegment: model.SupportCustomerSegmentVIP,
			ManualSegment:   model.SupportCustomerSegmentVIP,
			ReasonCodes:     []string{"manual_vip"},
		},
	}
	supportProfileStaff := &model.StaffUser{
		ID:          supportProfileStaffID,
		Email:       "aigerim.routing@inflap.local",
		DisplayName: "Aigerim Routing",
		Status:      enum.StaffStatusActive,
		Roles:       []enum.StaffRole{enum.StaffRoleSupportAgent},
	}
	readOnlyStaff := &model.StaffUser{
		ID:          uuid.New(),
		Email:       "viewer@inflap.local",
		DisplayName: "Support Viewer",
		Status:      enum.StaffStatusActive,
		Roles:       []enum.StaffRole{enum.StaffRoleSupportViewer},
		Permissions: []enum.Permission{enum.PermissionSupportRead},
	}
	server := newSupportHTTPTestServerWithStaff(
		t,
		app.NewSupportUseCase(client, nil),
		app.NewStaffUseCase(&supportStaffRepoStub{targets: []*model.StaffUser{supportProfileStaff, readOnlyStaff}}, nil),
	)
	staff := &model.StaffUser{ID: uuid.New(), Permissions: []enum.Permission{enum.PermissionSupportManage}, Timezone: "UTC"}

	list := httptest.NewRequest(http.MethodGet, "/admin/support/agents?status=active&userId=user-123", nil)
	list = list.WithContext(adminTestContext(list.Context(), staff))
	listRec := httptest.NewRecorder()

	server.SupportAgentList(listRec, list)

	if listRec.Code != http.StatusOK {
		t.Fatalf("status = %d, body = %s", listRec.Code, listRec.Body.String())
	}
	body := listRec.Body.String()
	for _, expected := range []string{
		"Support routing",
		"Нурланова Айгерим Сапаровна",
		"payments, technical",
		`name="staff_lookup"`,
		`name="last_name"`,
		`name="first_name"`,
		`name="middle_name"`,
		`data-support-agent-staff-suggestions`,
		`data-support-agent-staff-option`,
		"Aigerim Routing · aigerim.routing@inflap.local",
		"Start typing full name or email",
		`data-support-agent-language-dropdown`,
		`<details class="filter-combobox support-language-dropdown" data-support-agent-language-dropdown>`,
		`<summary class="button support-language-button"`,
		`data-support-agent-language-button`,
		`data-support-agent-language-options`,
		`type="checkbox" name="languages" value="ru"`,
		`type="checkbox" name="languages" value="en"`,
		`type="checkbox" name="languages" value="kk"`,
		`value="ru"`,
		`value="en"`,
		`value="kk"`,
		`data-support-agent-timezone-combobox`,
		`data-support-agent-timezone-input`,
		`data-support-agent-timezone-value`,
		`data-support-agent-timezone-suggestions`,
		`data-support-agent-timezone-option`,
		`data-value="Asia/Almaty"`,
		`data-search="`,
		`Алматы`,
		`Казахстан`,
		`UTC&#43;05:00`,
		`&#43;5`,
		`value="Asia/Almaty"`,
		`Europe/London`,
	} {
		if !strings.Contains(body, expected) {
			t.Fatalf("body missing %q:\n%s", expected, body)
		}
	}
	for _, unexpected := range []string{
		`name="display_name"`,
		"staff-uuid-or-id",
		`<datalist id="support-agent-staff-options"`,
		`list="support-agent-timezone-options"`,
		`<datalist id="support-agent-timezone-options"`,
		`<select name="languages" multiple`,
		`<script>`,
		`data-support-agent-language-options hidden`,
		"Support Viewer",
		"viewer@inflap.local",
		"Trusted user segment",
		`name="segment_user_id"`,
		`name="manual_segment"`,
		`name="manual_reason"`,
		`/admin/support/user-segments`,
		"@nomad",
	} {
		if strings.Contains(body, unexpected) {
			t.Fatalf("body contains %q:\n%s", unexpected, body)
		}
	}

	saveAgentForm := url.Values{}
	saveAgentForm.Set("staff_lookup", "Aigerim Routing · aigerim.routing@inflap.local")
	saveAgentForm.Set("last_name", "Ибраева")
	saveAgentForm.Set("first_name", "Аружан")
	saveAgentForm.Set("middle_name", "Ермековна")
	saveAgentForm.Set("status", string(model.SupportAgentStatusActive))
	saveAgentForm.Add("languages", "ru")
	saveAgentForm.Add("languages", "en")
	saveAgentForm.Add("skills", string(model.SupportAgentSkillPayments))
	saveAgentForm.Add("skills", string(model.SupportAgentSkillSafety))
	saveAgentForm.Set("level", string(model.SupportAgentLevelLead))
	saveAgentForm.Set("max_active_load", "5.5")
	saveAgentForm.Set("timezone", "Asia/Almaty")
	saveAgent := httptest.NewRequest(http.MethodPost, "/admin/support/agents", strings.NewReader(saveAgentForm.Encode()))
	saveAgent.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	saveAgent = saveAgent.WithContext(adminTestContext(saveAgent.Context(), staff))
	saveAgentRec := httptest.NewRecorder()

	server.SaveSupportAgent(saveAgentRec, saveAgent)

	if saveAgentRec.Code != http.StatusSeeOther ||
		client.lastAgentUpsert.StaffID != supportProfileStaffID.String() ||
		client.lastAgentUpsert.LastName != "Ибраева" ||
		client.lastAgentUpsert.FirstName != "Аружан" ||
		client.lastAgentUpsert.MiddleName != "Ермековна" ||
		strings.Join(client.lastAgentUpsert.Languages, ",") != "ru,en" ||
		len(client.lastAgentUpsert.Skills) != 2 {
		t.Fatalf("save agent status = %d input = %#v", saveAgentRec.Code, client.lastAgentUpsert)
	}
}

func TestSupportAgentLanguageDropdownCheckboxesKeepIntrinsicWidth(t *testing.T) {
	css, err := os.ReadFile("static/css/admin.css")
	if err != nil {
		t.Fatalf("read admin css: %v", err)
	}
	source := string(css)
	ruleStart := strings.Index(source, ".support-language-option input {")
	if ruleStart == -1 {
		t.Fatalf("admin css missing support language checkbox rule")
	}
	ruleEnd := strings.Index(source[ruleStart:], "}")
	if ruleEnd == -1 {
		t.Fatalf("admin css support language checkbox rule is not closed")
	}
	rule := source[ruleStart : ruleStart+ruleEnd]
	for _, expected := range []string{
		"width: auto;",
		"margin: 0;",
	} {
		if !strings.Contains(rule, expected) {
			t.Fatalf("support language checkbox rule missing %q:\n%s", expected, rule)
		}
	}
}

func newSupportHTTPTestServer(t *testing.T, support *app.SupportUseCase) *Server {
	return newSupportHTTPTestServerWithStaff(t, support, nil)
}

func newSupportHTTPTestServerWithStaff(t *testing.T, support *app.SupportUseCase, staff *app.StaffUseCase) *Server {
	t.Helper()
	renderer, err := NewRenderer()
	if err != nil {
		t.Fatalf("NewRenderer() error = %v", err)
	}
	server := NewServer(&config.Config{}, renderer, nil, staff, nil, nil, nil, nil, nil)
	server.SetSupportUseCase(support)
	return server
}

type supportStaffRepoStub struct {
	target  *model.StaffUser
	targets []*model.StaffUser
}

func (r *supportStaffRepoStub) GetByID(_ context.Context, id uuid.UUID) (*model.StaffUser, error) {
	for _, target := range r.targets {
		if target != nil && target.ID == id {
			return target, nil
		}
	}
	if r.target != nil && r.target.ID == id {
		return r.target, nil
	}
	return nil, nil
}

func (r *supportStaffRepoStub) GetByEmail(context.Context, string) (*model.StaffUser, error) {
	return nil, nil
}

func (r *supportStaffRepoStub) List(context.Context, int, int) ([]*model.StaffUser, error) {
	if r.targets != nil {
		return r.targets, nil
	}
	if r.target == nil {
		return nil, nil
	}
	return []*model.StaffUser{r.target}, nil
}

func (r *supportStaffRepoStub) Create(context.Context, *model.StaffUser, string, []enum.StaffRole) error {
	return nil
}

func (r *supportStaffRepoStub) UpdateProfileAndRoles(context.Context, uuid.UUID, string, []enum.StaffRole, uuid.UUID, time.Time) error {
	return nil
}

func (r *supportStaffRepoStub) UpdateTimezone(context.Context, uuid.UUID, string, time.Time) error {
	return nil
}

func (r *supportStaffRepoStub) UpdateLoginSuccess(context.Context, uuid.UUID, time.Time) error {
	return nil
}

func (r *supportStaffRepoStub) UpdateLoginFailure(context.Context, uuid.UUID, int, *time.Time) error {
	return nil
}

func (r *supportStaffRepoStub) UpdatePassword(context.Context, uuid.UUID, string, enum.StaffStatus, time.Time) error {
	return nil
}

func (r *supportStaffRepoStub) SetStatus(context.Context, uuid.UUID, enum.StaffStatus, time.Time) error {
	return nil
}

func (r *supportStaffRepoStub) GetPermissions(context.Context, uuid.UUID) ([]enum.Permission, []enum.StaffRole, error) {
	return nil, nil, nil
}

type supportHTTPClientStub struct {
	tickets                []model.SupportTicket
	detail                 model.SupportTicketDetail
	categories             []model.HelpCategory
	savedReplies           []model.SupportSavedReply
	articles               []model.HelpArticle
	analytics              model.HelpAnalyticsSummary
	agents                 []model.SupportAgent
	userSegment            model.SupportUserSegment
	upsertedCategory       model.HelpCategory
	upsertedSavedReply     model.SupportSavedReply
	upsertedArticle        model.HelpArticle
	upsertedAgent          model.SupportAgent
	upsertedUserSegment    model.SupportUserSegment
	lastHelpCategoryFilter model.HelpCategoryFilter
	lastHelpCategoryUpsert model.HelpCategoryUpsertInput
	lastSavedReplyFilter   model.SupportSavedReplyFilter
	lastSavedReplyUpsert   model.SupportSavedReplyUpsertInput
	lastAgentFilter        model.SupportAgentFilter
	lastAgentUpsert        model.SupportAgentUpsertInput
	lastTicketAssign       model.SupportTicketAssignInput
	lastUserSegmentUpsert  model.SupportUserSegmentUpsertInput
	lastHelpFilter         model.HelpArticleFilter
	lastHelpUpsert         model.HelpArticleUpsertInput
	lastTicketFilter       model.SupportTicketFilter
}

func (c *supportHTTPClientStub) ListTickets(_ context.Context, filter model.SupportTicketFilter) ([]model.SupportTicket, error) {
	c.lastTicketFilter = filter
	return c.tickets, nil
}

func (c *supportHTTPClientStub) GetTicket(context.Context, string) (model.SupportTicketDetail, error) {
	return c.detail, nil
}

func (c *supportHTTPClientStub) AssignTicket(_ context.Context, input model.SupportTicketAssignInput) (model.SupportTicket, error) {
	c.lastTicketAssign = input
	return model.SupportTicket{ID: input.TicketID, AssigneeID: input.AssigneeID}, nil
}

func (c *supportHTTPClientStub) ReplyTicket(context.Context, model.SupportTicketReplyInput) (model.SupportTicket, error) {
	return model.SupportTicket{}, nil
}

func (c *supportHTTPClientStub) AddTicketNote(context.Context, model.SupportTicketNoteInput) error {
	return nil
}

func (c *supportHTTPClientStub) ResolveTicket(context.Context, model.SupportTicketResolveInput) (model.SupportTicket, error) {
	return model.SupportTicket{}, nil
}

func (c *supportHTTPClientStub) ReopenTicket(context.Context, model.SupportTicketReopenInput) (model.SupportTicket, error) {
	return model.SupportTicket{}, nil
}

func (c *supportHTTPClientStub) ListSupportAgents(_ context.Context, filter model.SupportAgentFilter) ([]model.SupportAgent, error) {
	c.lastAgentFilter = filter
	return c.agents, nil
}

func (c *supportHTTPClientStub) UpsertSupportAgent(_ context.Context, input model.SupportAgentUpsertInput) (model.SupportAgent, error) {
	c.lastAgentUpsert = input
	if c.upsertedAgent.StaffID != "" {
		return c.upsertedAgent, nil
	}
	return model.SupportAgent{
		StaffID:       input.StaffID,
		DisplayName:   input.DisplayName,
		FirstName:     input.FirstName,
		LastName:      input.LastName,
		MiddleName:    input.MiddleName,
		Status:        input.Status,
		Languages:     input.Languages,
		Skills:        input.Skills,
		Level:         input.Level,
		MaxActiveLoad: input.MaxActiveLoad,
		Timezone:      input.Timezone,
	}, nil
}

func (c *supportHTTPClientStub) GetSupportUserSegment(context.Context, string) (model.SupportUserSegment, error) {
	return c.userSegment, nil
}

func (c *supportHTTPClientStub) UpsertSupportUserSegment(_ context.Context, input model.SupportUserSegmentUpsertInput) (model.SupportUserSegment, error) {
	c.lastUserSegmentUpsert = input
	if c.upsertedUserSegment.UserID != "" {
		return c.upsertedUserSegment, nil
	}
	return model.SupportUserSegment{
		UserID:          input.UserID,
		Nickname:        input.Nickname,
		CustomerSegment: input.ManualSegment,
		FollowersCount:  input.FollowersCount,
		IsGuide:         input.IsGuide,
		ManualSegment:   input.ManualSegment,
		ManualReason:    input.ManualReason,
		ReasonCodes:     []string{"manual_" + string(input.ManualSegment)},
	}, nil
}

func (c *supportHTTPClientStub) ListSupportSavedReplies(_ context.Context, filter model.SupportSavedReplyFilter) ([]model.SupportSavedReply, error) {
	c.lastSavedReplyFilter = filter
	return c.savedReplies, nil
}

func (c *supportHTTPClientStub) UpsertSupportSavedReply(_ context.Context, input model.SupportSavedReplyUpsertInput) (model.SupportSavedReply, error) {
	c.lastSavedReplyUpsert = input
	if c.upsertedSavedReply.ID != "" {
		return c.upsertedSavedReply, nil
	}
	return model.SupportSavedReply{
		ID:           input.ReplyID,
		Category:     input.Category,
		Status:       input.Status,
		Tags:         input.Tags,
		Translations: input.Translations,
		SortOrder:    input.SortOrder,
	}, nil
}

func (c *supportHTTPClientStub) ListHelpCategories(_ context.Context, filter model.HelpCategoryFilter) ([]model.HelpCategory, error) {
	c.lastHelpCategoryFilter = filter
	return c.categories, nil
}

func (c *supportHTTPClientStub) UpsertHelpCategory(_ context.Context, input model.HelpCategoryUpsertInput) (model.HelpCategory, error) {
	c.lastHelpCategoryUpsert = input
	if c.upsertedCategory.ID != "" {
		return c.upsertedCategory, nil
	}
	return model.HelpCategory{
		ID:        input.CategoryID,
		Slug:      input.Slug,
		Status:    input.Status,
		SortOrder: input.SortOrder,
	}, nil
}

func (c *supportHTTPClientStub) ListHelpArticles(_ context.Context, filter model.HelpArticleFilter) ([]model.HelpArticle, error) {
	c.lastHelpFilter = filter
	return c.articles, nil
}

func (c *supportHTTPClientStub) GetHelpArticle(context.Context, string) (model.HelpArticleDetail, error) {
	if len(c.articles) == 0 {
		return model.HelpArticleDetail{}, nil
	}
	return model.HelpArticleDetail{Article: c.articles[0]}, nil
}

func (c *supportHTTPClientStub) GetHelpAnalytics(context.Context, int) (model.HelpAnalyticsSummary, error) {
	return c.analytics, nil
}

func (c *supportHTTPClientStub) UpsertHelpArticle(_ context.Context, input model.HelpArticleUpsertInput) (model.HelpArticle, error) {
	c.lastHelpUpsert = input
	if c.upsertedArticle.ID != "" {
		return c.upsertedArticle, nil
	}
	return model.HelpArticle{ID: input.ArticleID, Slug: input.Slug, Status: model.HelpArticleStatusDraft}, nil
}

func (c *supportHTTPClientStub) SubmitHelpArticleForReview(_ context.Context, articleID string, _ model.HelpArticleActionInput) (model.HelpArticle, error) {
	return model.HelpArticle{ID: articleID, Status: model.HelpArticleStatusReview}, nil
}

func (c *supportHTTPClientStub) PublishHelpArticle(_ context.Context, articleID string, _ model.HelpArticleActionInput) (model.HelpArticle, error) {
	return model.HelpArticle{ID: articleID, Status: model.HelpArticleStatusPublished}, nil
}

func (c *supportHTTPClientStub) ArchiveHelpArticle(_ context.Context, articleID string, _ model.HelpArticleActionInput) (model.HelpArticle, error) {
	return model.HelpArticle{ID: articleID, Status: model.HelpArticleStatusArchived}, nil
}

type supportAttachmentDownloadClientStub struct {
	calls       int
	fileID      uuid.UUID
	downloadURL string
	expiresAt   time.Time
}

func (c *supportAttachmentDownloadClientStub) CreateDownloadURL(_ context.Context, fileID uuid.UUID) (model.FileDownloadURL, error) {
	c.calls++
	c.fileID = fileID
	return model.FileDownloadURL{URL: c.downloadURL, ExpiresAt: c.expiresAt}, nil
}

func stringSliceContains(values []string, target string) bool {
	for _, value := range values {
		if value == target {
			return true
		}
	}
	return false
}
