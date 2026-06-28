package http

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"sort"
	"strings"
	"testing"
	"time"

	"kz/inflap/backend/services/support-service/internal/app"
)

func TestContextualArticlesEndpointReturnsLocalizedActionableHelp(t *testing.T) {
	handler := NewHandler(app.NewHelpUseCase(newHTTPFakeRepository(), fixedClock()))
	mux := http.NewServeMux()
	handler.Register(mux)

	req := httptest.NewRequest(
		http.MethodGet,
		"/v1/help/articles/contextual?locale=ru-KZ&surface=activity_details&tags=activities,refunds&userState=paid",
		nil,
	)
	rec := httptest.NewRecorder()

	mux.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want 200; body=%s", rec.Code, rec.Body.String())
	}
	var payload map[string]any
	if err := json.Unmarshal(rec.Body.Bytes(), &payload); err != nil {
		t.Fatalf("decode response: %v", err)
	}
	items, ok := payload["items"].([]any)
	if !ok {
		t.Fatalf("items = %#v, want array", payload["items"])
	}
	if len(items) != 1 {
		t.Fatalf("items len = %d, want 1: %#v", len(items), items)
	}
	item, ok := items[0].(map[string]any)
	if !ok {
		t.Fatalf("item = %#v, want object", items[0])
	}
	if item["id"] != "activity-cancel-paid" {
		t.Fatalf("id = %v, want activity-cancel-paid", item["id"])
	}
	if item["title"] != "Как отменить оплаченную активность?" {
		t.Fatalf("title = %v", item["title"])
	}
	actions, ok := item["actions"].([]any)
	if !ok || len(actions) == 0 {
		t.Fatalf("actions = %#v, want non-empty array", item["actions"])
	}
	firstAction, ok := actions[0].(map[string]any)
	if !ok {
		t.Fatalf("first action = %#v, want object", actions[0])
	}
	if firstAction["type"] != "open_chat" || firstAction["target"] != "activity_organizer" {
		t.Fatalf("first action = %#v, want lower-camel actionable payload", firstAction)
	}
	if _, ok := firstAction["Type"]; ok {
		t.Fatalf("first action leaked Go field names: %#v", firstAction)
	}
}

func TestHelpCategoriesEndpointReturnsPublishedDatabaseCategories(t *testing.T) {
	repo := newHTTPFakeRepository()
	repo.categories = []app.HelpCategory{
		{
			ID:     "documents_visas_entry",
			Slug:   "documents-visas-entry",
			Status: app.ArticleStatusPublished,
			Translations: map[string]app.HelpCategoryTranslation{
				"ru": {Title: "Документы и въезд"},
				"en": {Title: "Documents and entry"},
			},
			SortOrder: 10,
		},
		{ID: "booking_accommodation", Slug: "booking-accommodation", Status: app.ArticleStatusPublished, SortOrder: 20},
		{ID: "empty_category", Slug: "empty-category", Status: app.ArticleStatusPublished, SortOrder: 30},
	}
	repo.articles = append(repo.articles, app.HelpArticle{
		ID:         "documents-seed",
		CategoryID: "documents_visas_entry",
		Slug:       "documents-seed",
		Status:     app.ArticleStatusPublished,
		Surfaces:   []app.HelpSurface{app.HelpSurfaceHelpCenter},
		Translations: map[string]app.ArticleTranslation{
			"ru": {Title: "Документы", ShortAnswer: "Ответ", Body: "Тело"},
		},
	})
	handler := NewHandler(app.NewHelpUseCase(repo, fixedClock()))
	mux := http.NewServeMux()
	handler.Register(mux)

	req := httptest.NewRequest(http.MethodGet, "/v1/help/categories?locale=ru&surface=help_center", nil)
	rec := httptest.NewRecorder()

	mux.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want 200; body=%s", rec.Code, rec.Body.String())
	}
	var payload map[string][]map[string]any
	if err := json.Unmarshal(rec.Body.Bytes(), &payload); err != nil {
		t.Fatalf("decode response: %v", err)
	}
	items := payload["items"]
	if len(items) != 1 {
		t.Fatalf("items = %#v, want only categories with published help articles", items)
	}
	if items[0]["id"] != "documents_visas_entry" ||
		items[0]["slug"] != "documents-visas-entry" ||
		items[0]["title"] != "Документы и въезд" ||
		items[0]["articleCount"] != float64(1) {
		t.Fatalf("category payload = %#v", items[0])
	}
}

func TestContextualArticlesEndpointSupportsCategoryPagination(t *testing.T) {
	repo := newHTTPFakeRepository()
	repo.articles = append(repo.articles,
		app.HelpArticle{
			ID:         "documents-a",
			CategoryID: "documents_visas_entry",
			Slug:       "documents-a",
			Status:     app.ArticleStatusPublished,
			Surfaces:   []app.HelpSurface{app.HelpSurfaceHelpCenter},
			Translations: map[string]app.ArticleTranslation{
				"ru": {Title: "Документы A", ShortAnswer: "Ответ", Body: "Тело"},
			},
			UpdatedAt: time.Date(2026, 6, 22, 10, 0, 0, 0, time.UTC),
		},
		app.HelpArticle{
			ID:         "documents-b",
			CategoryID: "documents_visas_entry",
			Slug:       "documents-b",
			Status:     app.ArticleStatusPublished,
			Surfaces:   []app.HelpSurface{app.HelpSurfaceHelpCenter},
			Translations: map[string]app.ArticleTranslation{
				"ru": {Title: "Документы B", ShortAnswer: "Ответ", Body: "Тело"},
			},
			UpdatedAt: time.Date(2026, 6, 21, 10, 0, 0, 0, time.UTC),
		},
		app.HelpArticle{
			ID:         "stay-a",
			CategoryID: "booking_accommodation",
			Slug:       "stay-a",
			Status:     app.ArticleStatusPublished,
			Surfaces:   []app.HelpSurface{app.HelpSurfaceHelpCenter},
			Translations: map[string]app.ArticleTranslation{
				"ru": {Title: "Проживание", ShortAnswer: "Ответ", Body: "Тело"},
			},
			UpdatedAt: time.Date(2026, 6, 20, 10, 0, 0, 0, time.UTC),
		},
	)
	handler := NewHandler(app.NewHelpUseCase(repo, fixedClock()))
	mux := http.NewServeMux()
	handler.Register(mux)

	req := httptest.NewRequest(
		http.MethodGet,
		"/v1/help/articles/contextual?locale=ru&surface=help_center&categoryId=documents_visas_entry&limit=1&offset=1",
		nil,
	)
	rec := httptest.NewRecorder()

	mux.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want 200; body=%s", rec.Code, rec.Body.String())
	}
	var payload map[string]any
	if err := json.Unmarshal(rec.Body.Bytes(), &payload); err != nil {
		t.Fatalf("decode response: %v", err)
	}
	items := payload["items"].([]any)
	if len(items) != 1 {
		t.Fatalf("items = %#v, want one second page item", items)
	}
	item := items[0].(map[string]any)
	if item["id"] != "documents-b" || payload["total"] != float64(2) || payload["hasMore"] != false {
		t.Fatalf("payload = %#v", payload)
	}
}

func TestSearchArticlesEndpointUsesQueryAndSurface(t *testing.T) {
	handler := NewHandler(app.NewHelpUseCase(newHTTPFakeRepository(), fixedClock()))
	mux := http.NewServeMux()
	handler.Register(mux)

	req := httptest.NewRequest(
		http.MethodGet,
		"/v1/help/articles/search?locale=ru&surface=help_center&q=%D0%B2%D0%BE%D0%B7%D0%B2%D1%80%D0%B0%D1%82",
		nil,
	)
	rec := httptest.NewRecorder()

	mux.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want 200; body=%s", rec.Code, rec.Body.String())
	}
	var payload map[string]any
	if err := json.Unmarshal(rec.Body.Bytes(), &payload); err != nil {
		t.Fatalf("decode response: %v", err)
	}
	items, ok := payload["items"].([]any)
	if !ok || len(items) == 0 {
		t.Fatalf("items = %#v, want non-empty array", payload["items"])
	}
	item, ok := items[0].(map[string]any)
	if !ok || item["id"] != "refund-timing" {
		t.Fatalf("items = %#v, want refund-timing", payload["items"])
	}
}

func TestFeedbackEndpointPersistsEscalationSignal(t *testing.T) {
	repo := newHTTPFakeRepository()
	handler := NewHandler(app.NewHelpUseCase(repo, fixedClock()))
	mux := http.NewServeMux()
	handler.Register(mux)

	body := bytes.NewBufferString(`{
		"locale": "ru",
		"helpful": false,
		"reason": "Still need a person",
		"escalatedToSupport": true
	}`)
	req := httptest.NewRequest(http.MethodPut, "/v1/help/articles/activity-cancel-paid/feedback", body)
	req.Header.Set("X-User-Id", "user-123")
	rec := httptest.NewRecorder()

	mux.ServeHTTP(rec, req)

	if rec.Code != http.StatusAccepted {
		t.Fatalf("status = %d, want 202; body=%s", rec.Code, rec.Body.String())
	}
	if len(repo.feedback) != 1 {
		t.Fatalf("feedback len = %d, want 1", len(repo.feedback))
	}
	if repo.feedback[0].ArticleID != "activity-cancel-paid" || !repo.feedback[0].EscalatedToSupport {
		t.Fatalf("feedback = %#v", repo.feedback[0])
	}
}

func TestCreateSupportTicketEndpointSanitizesContext(t *testing.T) {
	repo := newHTTPFakeRepository()
	handler := NewHandler(app.NewHelpUseCase(repo, fixedClock()))
	mux := http.NewServeMux()
	handler.Register(mux)

	body := bytes.NewBufferString(`{
		"category": "activities",
		"source": "activity_details",
		"locale": "ru",
		"context": {
			"activity_id": "activity-456",
			"article_id": "activity-cancel-paid",
			"followers_count": "25000",
			"is_vip": "true",
			"is_guide": "true",
			"subscription_tier": "pro",
			"authorization": "Bearer secret"
		}
	}`)
	req := httptest.NewRequest(http.MethodPost, "/v1/support/tickets", body)
	req.Header.Set("X-User-Id", "user-123")
	rec := httptest.NewRecorder()

	mux.ServeHTTP(rec, req)

	if rec.Code != http.StatusCreated {
		t.Fatalf("status = %d, want 201; body=%s", rec.Code, rec.Body.String())
	}
	var payload map[string]any
	if err := json.Unmarshal(rec.Body.Bytes(), &payload); err != nil {
		t.Fatalf("decode response: %v", err)
	}
	if payload["id"] == "" || payload["status"] != "new" {
		t.Fatalf("payload = %#v", payload)
	}
	if payload["customerSegment"] != "standard" ||
		payload["segmentRefreshStatus"] != "stale" ||
		payload["assignmentStatus"] != "needs_assignment" {
		t.Fatalf("payload segment/assignment = %#v", payload)
	}
	if len(repo.tickets) != 1 {
		t.Fatalf("tickets len = %d, want 1", len(repo.tickets))
	}
	if _, ok := repo.tickets[0].Context["authorization"]; ok {
		t.Fatalf("authorization leaked into context: %#v", repo.tickets[0].Context)
	}
	for _, untrustedKey := range []string{"followers_count", "is_vip", "is_guide", "subscription_tier"} {
		if _, ok := repo.tickets[0].Context[untrustedKey]; ok {
			t.Fatalf("untrusted key %q leaked into context: %#v", untrustedKey, repo.tickets[0].Context)
		}
	}
}

func TestCreateSupportTicketEndpointPassesIdempotencyKey(t *testing.T) {
	repo := newHTTPFakeRepository()
	handler := NewHandler(app.NewHelpUseCase(repo, fixedClock()))
	mux := http.NewServeMux()
	handler.Register(mux)

	body := bytes.NewBufferString(`{
		"category": "technical",
		"source": "help_center",
		"locale": "en",
		"context": {"article_id": "refund-timing"}
	}`)
	req := httptest.NewRequest(http.MethodPost, "/v1/support/tickets", body)
	req.Header.Set("X-User-Id", "user-123")
	req.Header.Set("Idempotency-Key", "create-ticket-request-123")
	rec := httptest.NewRecorder()

	mux.ServeHTTP(rec, req)

	if rec.Code != http.StatusCreated {
		t.Fatalf("status = %d, want 201; body=%s", rec.Code, rec.Body.String())
	}
	if len(repo.tickets) != 1 {
		t.Fatalf("tickets len = %d, want 1", len(repo.tickets))
	}
	if repo.tickets[0].IdempotencyKey != "create-ticket-request-123" {
		t.Fatalf("idempotency key = %q", repo.tickets[0].IdempotencyKey)
	}
}

func TestAdminSupportRoutingEndpointsManageAgentsAndUserSegments(t *testing.T) {
	repo := newHTTPFakeRepository()
	handler := NewHandler(app.NewHelpUseCase(repo, fixedClock()))
	mux := http.NewServeMux()
	handler.Register(mux)

	agentBody := bytes.NewBufferString(`{
		"firstName": "Айгерим",
		"lastName": "Нурланова",
		"middleName": "Сапаровна",
		"status": "active",
		"languages": ["ru", "en"],
		"skills": ["payments", "technical"],
		"level": "senior",
		"maxActiveLoad": 6,
		"timezone": "Asia/Almaty"
	}`)
	agentReq := httptest.NewRequest(http.MethodPut, "/v1/admin/support/agents/staff-1", agentBody)
	agentReq.Header.Set("X-User-Id", "support-lead")
	agentReq.Header.Set("X-User-Roles", "SUPPORT_LEAD")
	agentRec := httptest.NewRecorder()

	mux.ServeHTTP(agentRec, agentReq)

	if agentRec.Code != http.StatusOK {
		t.Fatalf("agent status = %d, want 200; body=%s", agentRec.Code, agentRec.Body.String())
	}
	var agentPayload map[string]map[string]any
	if err := json.Unmarshal(agentRec.Body.Bytes(), &agentPayload); err != nil {
		t.Fatalf("decode agent response: %v", err)
	}
	if agentPayload["agent"]["staffId"] != "staff-1" ||
		agentPayload["agent"]["firstName"] != "Айгерим" ||
		agentPayload["agent"]["lastName"] != "Нурланова" ||
		agentPayload["agent"]["status"] != "active" ||
		agentPayload["agent"]["level"] != "senior" {
		t.Fatalf("agent payload = %#v", agentPayload)
	}

	listReq := httptest.NewRequest(http.MethodGet, "/v1/admin/support/agents?status=active", nil)
	listReq.Header.Set("X-User-Id", "support-lead")
	listReq.Header.Set("X-User-Roles", "SUPPORT_LEAD")
	listRec := httptest.NewRecorder()

	mux.ServeHTTP(listRec, listReq)

	if listRec.Code != http.StatusOK {
		t.Fatalf("list status = %d, want 200; body=%s", listRec.Code, listRec.Body.String())
	}
	var listPayload map[string][]map[string]any
	if err := json.Unmarshal(listRec.Body.Bytes(), &listPayload); err != nil {
		t.Fatalf("decode list response: %v", err)
	}
	if len(listPayload["items"]) != 1 || listPayload["items"][0]["staffId"] != "staff-1" {
		t.Fatalf("list payload = %#v", listPayload)
	}

	segmentBody := bytes.NewBufferString(`{
		"nickname": "@nomad",
		"followersCount": 42000,
		"isGuide": true,
		"guideStatus": "verified",
		"isPublicFigure": false,
		"isPartner": false,
		"manualSegment": "vip",
		"manualReason": "Launch partner",
		"sourceVersion": "admin-manual"
	}`)
	segmentReq := httptest.NewRequest(http.MethodPut, "/v1/admin/support/user-segments/user-123", segmentBody)
	segmentReq.Header.Set("X-User-Id", "support-lead")
	segmentReq.Header.Set("X-User-Roles", "SUPPORT_LEAD")
	segmentRec := httptest.NewRecorder()

	mux.ServeHTTP(segmentRec, segmentReq)

	if segmentRec.Code != http.StatusOK {
		t.Fatalf("segment status = %d, want 200; body=%s", segmentRec.Code, segmentRec.Body.String())
	}
	var segmentPayload map[string]map[string]any
	if err := json.Unmarshal(segmentRec.Body.Bytes(), &segmentPayload); err != nil {
		t.Fatalf("decode segment response: %v", err)
	}
	reasonCodes, _ := segmentPayload["segment"]["reasonCodes"].([]any)
	if segmentPayload["segment"]["customerSegment"] != "vip" ||
		segmentPayload["segment"]["subscriptionTier"] != nil ||
		len(reasonCodes) == 0 {
		t.Fatalf("segment payload = %#v", segmentPayload)
	}
}

func TestUserSupportTicketEndpointsEnforceOwnership(t *testing.T) {
	repo := newHTTPFakeRepository()
	repo.tickets = []app.SupportTicket{
		{
			ID:            "ticket-user-123",
			UserID:        "user-123",
			Category:      app.SupportTicketCategoryActivities,
			Status:        app.SupportTicketStatusWaitingUser,
			Priority:      app.SupportTicketPriorityNormal,
			Source:        "activity_details",
			Locale:        "ru",
			Context:       map[string]string{"activity_id": "activity-456"},
			CreatedAt:     time.Date(2026, 6, 20, 11, 0, 0, 0, time.UTC),
			UpdatedAt:     time.Date(2026, 6, 20, 11, 0, 0, 0, time.UTC),
			LastMessageAt: time.Date(2026, 6, 20, 11, 0, 0, 0, time.UTC),
		},
		{
			ID:            "ticket-user-456",
			UserID:        "user-456",
			Category:      app.SupportTicketCategoryPayments,
			Status:        app.SupportTicketStatusNew,
			Priority:      app.SupportTicketPriorityNormal,
			Source:        "payment_details",
			Locale:        "en",
			CreatedAt:     time.Date(2026, 6, 20, 10, 0, 0, 0, time.UTC),
			UpdatedAt:     time.Date(2026, 6, 20, 10, 0, 0, 0, time.UTC),
			LastMessageAt: time.Date(2026, 6, 20, 10, 0, 0, 0, time.UTC),
		},
	}
	handler := NewHandler(app.NewHelpUseCase(repo, fixedClock()))
	mux := http.NewServeMux()
	handler.Register(mux)

	list := httptest.NewRequest(http.MethodGet, "/v1/support/tickets", nil)
	list.Header.Set("X-User-Id", "user-123")
	listRec := httptest.NewRecorder()
	mux.ServeHTTP(listRec, list)
	if listRec.Code != http.StatusOK {
		t.Fatalf("list status = %d, want 200; body=%s", listRec.Code, listRec.Body.String())
	}
	var listPayload map[string][]map[string]any
	if err := json.Unmarshal(listRec.Body.Bytes(), &listPayload); err != nil {
		t.Fatalf("decode list payload: %v", err)
	}
	if len(listPayload["items"]) != 1 || listPayload["items"][0]["id"] != "ticket-user-123" {
		t.Fatalf("list payload = %#v, want only current user ticket", listPayload)
	}

	otherDetail := httptest.NewRequest(http.MethodGet, "/v1/support/tickets/ticket-user-456", nil)
	otherDetail.Header.Set("X-User-Id", "user-123")
	otherDetailRec := httptest.NewRecorder()
	mux.ServeHTTP(otherDetailRec, otherDetail)
	if otherDetailRec.Code != http.StatusNotFound {
		t.Fatalf("other detail status = %d, want 404; body=%s", otherDetailRec.Code, otherDetailRec.Body.String())
	}

	closeBody := bytes.NewBufferString(`{"reason":"Thanks, this helped."}`)
	closeReq := httptest.NewRequest(http.MethodPost, "/v1/support/tickets/ticket-user-123/close", closeBody)
	closeReq.Header.Set("X-User-Id", "user-123")
	closeRec := httptest.NewRecorder()
	mux.ServeHTTP(closeRec, closeReq)
	if closeRec.Code != http.StatusOK {
		t.Fatalf("close status = %d, want 200; body=%s", closeRec.Code, closeRec.Body.String())
	}
	var closePayload map[string]map[string]any
	if err := json.Unmarshal(closeRec.Body.Bytes(), &closePayload); err != nil {
		t.Fatalf("decode close payload: %v", err)
	}
	if closePayload["ticket"]["status"] != "closed" {
		t.Fatalf("close payload = %#v", closePayload)
	}
	if len(repo.events) != 1 || repo.events[0].ActorType != app.SupportActorTypeUser {
		t.Fatalf("events = %#v, want user close event", repo.events)
	}
}

func TestUserSupportConversationEndpointReturnsSingleChatContext(t *testing.T) {
	repo := newHTTPFakeRepository()
	mux := http.NewServeMux()
	NewHandler(app.NewHelpUseCase(repo, fixedClock())).Register(mux)

	req := httptest.NewRequest(http.MethodGet, "/v1/support/conversation?locale=ru", nil)
	req.Header.Set("X-User-Id", "user-123")
	rec := httptest.NewRecorder()

	mux.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want 200; body=%s", rec.Code, rec.Body.String())
	}
	var payload map[string]any
	if err := json.Unmarshal(rec.Body.Bytes(), &payload); err != nil {
		t.Fatalf("decode response: %v", err)
	}
	ticket, _ := payload["ticket"].(map[string]any)
	if ticket["userId"] != "user-123" ||
		ticket["source"] != "support_chat" ||
		ticket["category"] != "technical" {
		t.Fatalf("ticket payload = %#v, want single support chat context", ticket)
	}
	if len(repo.tickets) != 1 {
		t.Fatalf("tickets len = %d, want one backing support conversation", len(repo.tickets))
	}
}

func TestUserSupportTicketReplyEndpointSendsMessageToOwnTicket(t *testing.T) {
	repo := newHTTPFakeRepository()
	repo.tickets = []app.SupportTicket{
		{
			ID:             "ticket-user-123",
			UserID:         "user-123",
			ConversationID: "conversation-123",
			Category:       app.SupportTicketCategoryTechnical,
			Status:         app.SupportTicketStatusWaitingUser,
			Priority:       app.SupportTicketPriorityNormal,
			Source:         "help_center",
			Locale:         "ru",
			CreatedAt:      time.Date(2026, 6, 20, 11, 0, 0, 0, time.UTC),
			UpdatedAt:      time.Date(2026, 6, 20, 11, 30, 0, 0, time.UTC),
			LastMessageAt:  time.Date(2026, 6, 20, 11, 30, 0, 0, time.UTC),
		},
		{
			ID:             "ticket-user-456",
			UserID:         "user-456",
			ConversationID: "conversation-456",
			Status:         app.SupportTicketStatusWaitingUser,
			CreatedAt:      time.Date(2026, 6, 20, 10, 0, 0, 0, time.UTC),
			UpdatedAt:      time.Date(2026, 6, 20, 10, 0, 0, 0, time.UTC),
			LastMessageAt:  time.Date(2026, 6, 20, 10, 0, 0, 0, time.UTC),
		},
	}
	chat := &httpFakeSupportChatGateway{messageID: "chat-message-user-1"}
	uc := app.NewHelpUseCase(repo, fixedClock())
	uc.SetSupportChatGateway(chat)
	handler := NewHandler(uc)
	mux := http.NewServeMux()
	handler.Register(mux)

	body := bytes.NewBufferString(`{
		"message": "Я отправил чек, проверьте, пожалуйста.",
		"actorNickname": "@nomad"
	}`)
	req := httptest.NewRequest(http.MethodPost, "/v1/support/tickets/ticket-user-123/reply", body)
	req.Header.Set("X-User-Id", "user-123")
	req.Header.Set("Idempotency-Key", "user-reply-request-123")
	rec := httptest.NewRecorder()
	mux.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("reply status = %d, want 200; body=%s", rec.Code, rec.Body.String())
	}
	var payload map[string]map[string]any
	if err := json.Unmarshal(rec.Body.Bytes(), &payload); err != nil {
		t.Fatalf("decode reply payload: %v", err)
	}
	if payload["ticket"]["status"] != "waiting_support" {
		t.Fatalf("reply payload = %#v", payload)
	}
	if len(chat.messages) != 1 {
		t.Fatalf("chat messages = %#v, want one", chat.messages)
	}
	if chat.messages[0].ActorID != "user-123" || chat.messages[0].ConversationID != "conversation-123" {
		t.Fatalf("chat message = %#v", chat.messages[0])
	}
	if len(repo.events) != 1 || repo.events[0].ActorType != app.SupportActorTypeUser || repo.events[0].EventType != "user_replied" {
		t.Fatalf("events = %#v, want user reply event", repo.events)
	}
	if repo.events[0].Payload["actor_nickname"] != "@nomad" {
		t.Fatalf("actor_nickname = %q, want @nomad", repo.events[0].Payload["actor_nickname"])
	}

	otherBody := bytes.NewBufferString(`{"message":"Нельзя отвечать в чужой тикет."}`)
	otherReq := httptest.NewRequest(http.MethodPost, "/v1/support/tickets/ticket-user-456/reply", otherBody)
	otherReq.Header.Set("X-User-Id", "user-123")
	otherRec := httptest.NewRecorder()
	mux.ServeHTTP(otherRec, otherReq)
	if otherRec.Code != http.StatusNotFound {
		t.Fatalf("other reply status = %d, want 404; body=%s", otherRec.Code, otherRec.Body.String())
	}
}

func TestUserSupportTicketCSATEndpointPersistsResolvedTicketRating(t *testing.T) {
	repo := newHTTPFakeRepository()
	resolvedAt := time.Date(2026, 6, 20, 11, 50, 0, 0, time.UTC)
	repo.tickets = []app.SupportTicket{
		{
			ID:            "ticket-resolved",
			UserID:        "user-123",
			Category:      app.SupportTicketCategoryTechnical,
			Status:        app.SupportTicketStatusResolved,
			Priority:      app.SupportTicketPriorityNormal,
			Source:        "help_center",
			Locale:        "en",
			ResolvedAt:    &resolvedAt,
			CreatedAt:     time.Date(2026, 6, 20, 11, 0, 0, 0, time.UTC),
			UpdatedAt:     resolvedAt,
			LastMessageAt: resolvedAt,
		},
		{
			ID:            "ticket-other-user",
			UserID:        "user-456",
			Category:      app.SupportTicketCategoryTechnical,
			Status:        app.SupportTicketStatusClosed,
			Priority:      app.SupportTicketPriorityNormal,
			Source:        "help_center",
			Locale:        "en",
			CreatedAt:     time.Date(2026, 6, 20, 10, 0, 0, 0, time.UTC),
			UpdatedAt:     time.Date(2026, 6, 20, 11, 0, 0, 0, time.UTC),
			LastMessageAt: time.Date(2026, 6, 20, 11, 0, 0, 0, time.UTC),
		},
	}
	handler := NewHandler(app.NewHelpUseCase(repo, fixedClock()))
	mux := http.NewServeMux()
	handler.Register(mux)

	body := bytes.NewBufferString(`{"rating":5,"comment":"Clear and fast answer."}`)
	req := httptest.NewRequest(http.MethodPost, "/v1/support/tickets/ticket-resolved/csat", body)
	req.Header.Set("X-User-Id", "user-123")
	rec := httptest.NewRecorder()
	mux.ServeHTTP(rec, req)

	if rec.Code != http.StatusAccepted {
		t.Fatalf("status = %d, want 202; body=%s", rec.Code, rec.Body.String())
	}
	if len(repo.csat) != 1 {
		t.Fatalf("csat len = %d, want 1", len(repo.csat))
	}
	if repo.csat[0].TicketID != "ticket-resolved" ||
		repo.csat[0].UserID != "user-123" ||
		repo.csat[0].Rating != 5 ||
		repo.csat[0].Comment != "Clear and fast answer." {
		t.Fatalf("csat = %#v", repo.csat[0])
	}

	otherBody := bytes.NewBufferString(`{"rating":4}`)
	otherReq := httptest.NewRequest(http.MethodPost, "/v1/support/tickets/ticket-other-user/csat", otherBody)
	otherReq.Header.Set("X-User-Id", "user-123")
	otherRec := httptest.NewRecorder()
	mux.ServeHTTP(otherRec, otherReq)
	if otherRec.Code != http.StatusNotFound {
		t.Fatalf("other user status = %d, want 404; body=%s", otherRec.Code, otherRec.Body.String())
	}
}

func TestAdminSupportTicketEndpointsRequireSupportRoleAndReturnTicketDetail(t *testing.T) {
	repo := newHTTPFakeRepository()
	repo.tickets = []app.SupportTicket{
		{
			ID:                 "ticket-1",
			UserID:             "user-123",
			Category:           app.SupportTicketCategoryActivities,
			Status:             app.SupportTicketStatusNew,
			Priority:           app.SupportTicketPriorityNormal,
			Source:             "activity_details",
			Locale:             "ru",
			Context:            map[string]string{"activity_id": "activity-456"},
			LastMessagePreview: "Не проходит оплата тура.",
			CreatedAt:          time.Date(2026, 6, 20, 11, 0, 0, 0, time.UTC),
			LastMessageAt:      time.Date(2026, 6, 20, 11, 0, 0, 0, time.UTC),
		},
	}
	handler := NewHandler(app.NewHelpUseCase(repo, fixedClock()))
	mux := http.NewServeMux()
	handler.Register(mux)

	forbidden := httptest.NewRequest(http.MethodGet, "/v1/admin/support/tickets", nil)
	forbidden.Header.Set("X-User-Id", "staff-1")
	forbidden.Header.Set("X-User-Roles", "READ_ONLY_AUDITOR")
	forbiddenRec := httptest.NewRecorder()
	mux.ServeHTTP(forbiddenRec, forbidden)
	if forbiddenRec.Code != http.StatusForbidden {
		t.Fatalf("forbidden status = %d, want 403; body=%s", forbiddenRec.Code, forbiddenRec.Body.String())
	}

	req := httptest.NewRequest(http.MethodGet, "/v1/admin/support/tickets?status=new", nil)
	req.Header.Set("X-User-Id", "staff-1")
	req.Header.Set("X-User-Roles", "SUPPORT_VIEWER")
	rec := httptest.NewRecorder()
	mux.ServeHTTP(rec, req)
	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want 200; body=%s", rec.Code, rec.Body.String())
	}
	var listPayload map[string][]map[string]any
	if err := json.Unmarshal(rec.Body.Bytes(), &listPayload); err != nil {
		t.Fatalf("decode list response: %v", err)
	}
	if len(listPayload["items"]) != 1 || listPayload["items"][0]["id"] != "ticket-1" {
		t.Fatalf("list payload = %#v", listPayload)
	}
	if listPayload["items"][0]["lastMessagePreview"] != "Не проходит оплата тура." {
		t.Fatalf("last message preview = %#v", listPayload["items"][0]["lastMessagePreview"])
	}

	detail := httptest.NewRequest(http.MethodGet, "/v1/admin/support/tickets/ticket-1", nil)
	detail.Header.Set("X-User-Id", "staff-1")
	detail.Header.Set("X-User-Roles", "SUPPORT_AGENT")
	detailRec := httptest.NewRecorder()
	mux.ServeHTTP(detailRec, detail)
	if detailRec.Code != http.StatusOK {
		t.Fatalf("detail status = %d, want 200; body=%s", detailRec.Code, detailRec.Body.String())
	}
	var detailPayload map[string]any
	if err := json.Unmarshal(detailRec.Body.Bytes(), &detailPayload); err != nil {
		t.Fatalf("decode detail response: %v", err)
	}
	if detailPayload["ticket"].(map[string]any)["id"] != "ticket-1" {
		t.Fatalf("detail payload = %#v", detailPayload)
	}
}

func TestAdminSupportTicketsAcceptsSLABreachedFilter(t *testing.T) {
	repo := newHTTPFakeRepository()
	handler := NewHandler(app.NewHelpUseCase(repo, fixedClock()))
	mux := http.NewServeMux()
	handler.Register(mux)

	req := httptest.NewRequest(http.MethodGet, "/v1/admin/support/tickets?sla=breached", nil)
	req.Header.Set("X-User-Id", "staff-1")
	req.Header.Set("X-User-Roles", "SUPPORT_VIEWER")
	rec := httptest.NewRecorder()
	mux.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want 200; body=%s", rec.Code, rec.Body.String())
	}
	if !repo.lastTicketFilter.SLABreached {
		t.Fatalf("SLABreached filter = false, want true")
	}
}

func TestAdminSupportSavedReplyEndpointsRequireManageRoleAndUpsertReply(t *testing.T) {
	repo := newHTTPFakeRepository()
	repo.savedReplies = []app.SupportSavedReply{
		{
			ID:        "refund-status",
			Category:  "payments",
			Status:    app.ArticleStatusPublished,
			SortOrder: 20,
			Translations: map[string]app.SupportSavedReplyTranslation{
				"en": {Title: "Refund status", Body: "I checked your refund status."},
			},
			UpdatedAt: time.Date(2026, 6, 20, 12, 0, 0, 0, time.UTC),
		},
	}
	handler := NewHandler(app.NewHelpUseCase(repo, fixedClock()))
	mux := http.NewServeMux()
	handler.Register(mux)

	list := httptest.NewRequest(http.MethodGet, "/v1/admin/support/saved-replies?category=payments&status=published", nil)
	list.Header.Set("X-User-Id", "agent-1")
	list.Header.Set("X-User-Roles", "SUPPORT_AGENT")
	listRec := httptest.NewRecorder()
	mux.ServeHTTP(listRec, list)
	if listRec.Code != http.StatusOK {
		t.Fatalf("list status = %d, want 200; body=%s", listRec.Code, listRec.Body.String())
	}
	var listPayload struct {
		Items []map[string]any `json:"items"`
	}
	if err := json.Unmarshal(listRec.Body.Bytes(), &listPayload); err != nil {
		t.Fatalf("decode list payload: %v", err)
	}
	if len(listPayload.Items) != 1 || listPayload.Items[0]["id"] != "refund-status" {
		t.Fatalf("list payload = %#v", listPayload)
	}

	body := bytes.NewBufferString(`{
		"category": "activities",
		"status": "published",
		"tags": ["meeting", "activity"],
		"sortOrder": 5,
		"translations": {
			"en": {"title": "Meeting point", "body": "Please check the meeting point block."},
			"ru": {"title": "Место встречи", "body": "Проверьте блок места встречи."}
		}
	}`)
	forbidden := httptest.NewRequest(http.MethodPut, "/v1/admin/support/saved-replies/meeting-point", bytes.NewBuffer(body.Bytes()))
	forbidden.Header.Set("X-User-Id", "agent-1")
	forbidden.Header.Set("X-User-Roles", "SUPPORT_AGENT")
	forbiddenRec := httptest.NewRecorder()
	mux.ServeHTTP(forbiddenRec, forbidden)
	if forbiddenRec.Code != http.StatusForbidden {
		t.Fatalf("forbidden status = %d, want 403; body=%s", forbiddenRec.Code, forbiddenRec.Body.String())
	}

	edit := httptest.NewRequest(http.MethodPut, "/v1/admin/support/saved-replies/meeting-point", bytes.NewBuffer(body.Bytes()))
	edit.Header.Set("X-User-Id", "lead-1")
	edit.Header.Set("X-User-Roles", "SUPPORT_LEAD")
	editRec := httptest.NewRecorder()
	mux.ServeHTTP(editRec, edit)
	if editRec.Code != http.StatusOK {
		t.Fatalf("edit status = %d, want 200; body=%s", editRec.Code, editRec.Body.String())
	}
	var editPayload map[string]map[string]any
	if err := json.Unmarshal(editRec.Body.Bytes(), &editPayload); err != nil {
		t.Fatalf("decode edit payload: %v", err)
	}
	if editPayload["reply"]["id"] != "meeting-point" ||
		editPayload["reply"]["category"] != "activities" ||
		editPayload["reply"]["status"] != "published" {
		t.Fatalf("edit payload = %#v", editPayload)
	}
}

func TestAdminSupportTicketReplyUpdatesTicketAndAuditEvents(t *testing.T) {
	repo := newHTTPFakeRepository()
	repo.tickets = []app.SupportTicket{
		{
			ID:            "ticket-1",
			UserID:        "user-123",
			Category:      app.SupportTicketCategoryActivities,
			Status:        app.SupportTicketStatusAssigned,
			Priority:      app.SupportTicketPriorityNormal,
			Source:        "activity_details",
			Locale:        "ru",
			AssigneeID:    "staff-1",
			Context:       map[string]string{"activity_id": "activity-456"},
			CreatedAt:     time.Date(2026, 6, 20, 11, 0, 0, 0, time.UTC),
			LastMessageAt: time.Date(2026, 6, 20, 11, 0, 0, 0, time.UTC),
		},
	}
	handler := NewHandler(app.NewHelpUseCase(repo, fixedClock()))
	mux := http.NewServeMux()
	handler.Register(mux)

	body := bytes.NewBufferString(`{
		"message": "Здравствуйте! Проверили ваш вопрос.",
		"conversationId": "conversation-123",
		"messageId": "message-456"
	}`)
	req := httptest.NewRequest(http.MethodPost, "/v1/admin/support/tickets/ticket-1/reply", body)
	req.Header.Set("X-User-Id", "staff-1")
	req.Header.Set("X-User-Roles", "SUPPORT_AGENT")
	req.Header.Set("X-Actor-Display-Name", "Aruzhan Ops")
	rec := httptest.NewRecorder()

	mux.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want 200; body=%s", rec.Code, rec.Body.String())
	}
	if repo.tickets[0].Status != app.SupportTicketStatusWaitingUser {
		t.Fatalf("ticket status = %q, want waiting_user", repo.tickets[0].Status)
	}
	if len(repo.events) != 1 || repo.events[0].EventType != "agent_replied" {
		t.Fatalf("events = %#v", repo.events)
	}
	if repo.events[0].Payload["actor_display_name"] != "Aruzhan Ops" {
		t.Fatalf("actor_display_name = %q, want Aruzhan Ops", repo.events[0].Payload["actor_display_name"])
	}
}

func TestAdminHelpArticleEndpointsRequireContentRolesAndPublishArticle(t *testing.T) {
	repo := newHTTPFakeRepository()
	handler := NewHandler(app.NewHelpUseCase(repo, fixedClock()))
	mux := http.NewServeMux()
	handler.Register(mux)

	body := bytes.NewBufferString(`{
		"slug": "refund-policy",
		"categoryId": "payments",
		"tags": ["payments", "refunds"],
		"surfaces": ["help_center", "activity_details"],
		"visibility": {"paymentStatuses": ["captured"]},
		"translations": {
			"en": {"title": "Refund policy", "shortAnswer": "Refund timing depends on the provider.", "body": "Open the booking to check the current refund state."},
			"ru": {"title": "Правила возврата", "shortAnswer": "Срок возврата зависит от провайдера.", "body": "Откройте бронирование, чтобы проверить актуальный статус возврата."},
			"kk": {"title": "Қайтарым ережелері", "shortAnswer": "Қайтарым мерзімі провайдерге байланысты.", "body": "Ағымдағы қайтарым мәртебесін тексеру үшін брондауды ашыңыз."}
		},
		"actions": [{"type": "contact_support", "target": "support"}],
		"relatedArticleIds": ["refund-timing"]
	}`)
	forbidden := httptest.NewRequest(http.MethodPut, "/v1/admin/help/articles/refund-policy", bytes.NewBuffer(body.Bytes()))
	forbidden.Header.Set("X-User-Id", "staff-1")
	forbidden.Header.Set("X-User-Roles", "SUPPORT_AGENT")
	forbiddenRec := httptest.NewRecorder()
	mux.ServeHTTP(forbiddenRec, forbidden)
	if forbiddenRec.Code != http.StatusForbidden {
		t.Fatalf("forbidden status = %d, want 403; body=%s", forbiddenRec.Code, forbiddenRec.Body.String())
	}

	edit := httptest.NewRequest(http.MethodPut, "/v1/admin/help/articles/refund-policy", bytes.NewBuffer(body.Bytes()))
	edit.Header.Set("X-User-Id", "editor-1")
	edit.Header.Set("X-User-Roles", "HELP_CONTENT_EDITOR")
	editRec := httptest.NewRecorder()
	mux.ServeHTTP(editRec, edit)
	if editRec.Code != http.StatusOK {
		t.Fatalf("edit status = %d, want 200; body=%s", editRec.Code, editRec.Body.String())
	}
	var editPayload map[string]map[string]any
	if err := json.Unmarshal(editRec.Body.Bytes(), &editPayload); err != nil {
		t.Fatalf("decode edit payload: %v", err)
	}
	if editPayload["article"]["status"] != "draft" || editPayload["article"]["ownerId"] != "editor-1" {
		t.Fatalf("edit payload = %#v", editPayload)
	}

	submit := httptest.NewRequest(http.MethodPost, "/v1/admin/help/articles/refund-policy/submit-review", nil)
	submit.Header.Set("X-User-Id", "editor-1")
	submit.Header.Set("X-User-Roles", "HELP_CONTENT_EDITOR")
	submitRec := httptest.NewRecorder()
	mux.ServeHTTP(submitRec, submit)
	if submitRec.Code != http.StatusOK {
		t.Fatalf("submit status = %d, want 200; body=%s", submitRec.Code, submitRec.Body.String())
	}

	publishForbidden := httptest.NewRequest(http.MethodPost, "/v1/admin/help/articles/refund-policy/publish", nil)
	publishForbidden.Header.Set("X-User-Id", "editor-1")
	publishForbidden.Header.Set("X-User-Roles", "HELP_CONTENT_EDITOR")
	publishForbiddenRec := httptest.NewRecorder()
	mux.ServeHTTP(publishForbiddenRec, publishForbidden)
	if publishForbiddenRec.Code != http.StatusForbidden {
		t.Fatalf("publish forbidden status = %d, want 403; body=%s", publishForbiddenRec.Code, publishForbiddenRec.Body.String())
	}

	publish := httptest.NewRequest(http.MethodPost, "/v1/admin/help/articles/refund-policy/publish", nil)
	publish.Header.Set("X-User-Id", "publisher-1")
	publish.Header.Set("X-User-Roles", "HELP_CONTENT_PUBLISHER")
	publishRec := httptest.NewRecorder()
	mux.ServeHTTP(publishRec, publish)
	if publishRec.Code != http.StatusOK {
		t.Fatalf("publish status = %d, want 200; body=%s", publishRec.Code, publishRec.Body.String())
	}
	var publishPayload map[string]map[string]any
	if err := json.Unmarshal(publishRec.Body.Bytes(), &publishPayload); err != nil {
		t.Fatalf("decode publish payload: %v", err)
	}
	if publishPayload["article"]["status"] != "published" ||
		publishPayload["article"]["reviewerId"] != "publisher-1" ||
		publishPayload["article"]["publishedAt"] == "" {
		t.Fatalf("publish payload = %#v", publishPayload)
	}

	detail := httptest.NewRequest(http.MethodGet, "/v1/admin/help/articles/refund-policy", nil)
	detail.Header.Set("X-User-Id", "editor-1")
	detail.Header.Set("X-User-Roles", "HELP_CONTENT_EDITOR")
	detailRec := httptest.NewRecorder()
	mux.ServeHTTP(detailRec, detail)
	if detailRec.Code != http.StatusOK {
		t.Fatalf("detail status = %d, want 200; body=%s", detailRec.Code, detailRec.Body.String())
	}
	var detailPayload map[string]any
	if err := json.Unmarshal(detailRec.Body.Bytes(), &detailPayload); err != nil {
		t.Fatalf("decode detail payload: %v", err)
	}
	if len(detailPayload["events"].([]any)) < 3 {
		t.Fatalf("detail payload = %#v, want article events", detailPayload)
	}
}

func TestAdminHelpCategoryEndpointsRequireContentRolesAndUpsertCategory(t *testing.T) {
	repo := newHTTPFakeRepository()
	repo.categories = []app.HelpCategory{
		{
			ID:     "payments",
			Slug:   "payments",
			Status: app.ArticleStatusPublished,
			Translations: map[string]app.HelpCategoryTranslation{
				"en": {Title: "Payments"},
				"ru": {Title: "Деньги и карты"},
			},
			SortOrder: 20,
			CreatedAt: time.Date(2026, 6, 1, 9, 0, 0, 0, time.UTC),
			UpdatedAt: time.Date(2026, 6, 1, 9, 0, 0, 0, time.UTC),
		},
		{
			ID:        "draft",
			Slug:      "draft",
			Status:    app.ArticleStatusDraft,
			SortOrder: 10,
			CreatedAt: time.Date(2026, 6, 1, 9, 0, 0, 0, time.UTC),
			UpdatedAt: time.Date(2026, 6, 1, 9, 0, 0, 0, time.UTC),
		},
	}
	handler := NewHandler(app.NewHelpUseCase(repo, fixedClock()))
	mux := http.NewServeMux()
	handler.Register(mux)

	forbiddenList := httptest.NewRequest(http.MethodGet, "/v1/admin/help/categories", nil)
	forbiddenList.Header.Set("X-User-Id", "staff-1")
	forbiddenList.Header.Set("X-User-Roles", "SUPPORT_AGENT")
	forbiddenListRec := httptest.NewRecorder()
	mux.ServeHTTP(forbiddenListRec, forbiddenList)
	if forbiddenListRec.Code != http.StatusForbidden {
		t.Fatalf("forbidden list status = %d, want 403; body=%s", forbiddenListRec.Code, forbiddenListRec.Body.String())
	}

	list := httptest.NewRequest(http.MethodGet, "/v1/admin/help/categories?status=published&locale=ru", nil)
	list.Header.Set("X-User-Id", "editor-1")
	list.Header.Set("X-User-Roles", "HELP_CONTENT_EDITOR")
	listRec := httptest.NewRecorder()
	mux.ServeHTTP(listRec, list)
	if listRec.Code != http.StatusOK {
		t.Fatalf("list status = %d, want 200; body=%s", listRec.Code, listRec.Body.String())
	}
	var listPayload struct {
		Items []map[string]any `json:"items"`
	}
	if err := json.Unmarshal(listRec.Body.Bytes(), &listPayload); err != nil {
		t.Fatalf("decode list payload: %v", err)
	}
	if len(listPayload.Items) != 1 ||
		listPayload.Items[0]["id"] != "payments" ||
		listPayload.Items[0]["title"] != "Деньги и карты" {
		t.Fatalf("list payload = %#v", listPayload)
	}

	body := bytes.NewBufferString(`{"slug":"safety","status":"published","sortOrder":5}`)
	forbiddenEdit := httptest.NewRequest(http.MethodPut, "/v1/admin/help/categories/safety", bytes.NewBuffer(body.Bytes()))
	forbiddenEdit.Header.Set("X-User-Id", "staff-1")
	forbiddenEdit.Header.Set("X-User-Roles", "SUPPORT_AGENT")
	forbiddenEditRec := httptest.NewRecorder()
	mux.ServeHTTP(forbiddenEditRec, forbiddenEdit)
	if forbiddenEditRec.Code != http.StatusForbidden {
		t.Fatalf("forbidden edit status = %d, want 403; body=%s", forbiddenEditRec.Code, forbiddenEditRec.Body.String())
	}

	edit := httptest.NewRequest(http.MethodPut, "/v1/admin/help/categories/safety", bytes.NewBuffer(body.Bytes()))
	edit.Header.Set("X-User-Id", "editor-1")
	edit.Header.Set("X-User-Roles", "HELP_CONTENT_EDITOR")
	editRec := httptest.NewRecorder()
	mux.ServeHTTP(editRec, edit)
	if editRec.Code != http.StatusOK {
		t.Fatalf("edit status = %d, want 200; body=%s", editRec.Code, editRec.Body.String())
	}
	var editPayload map[string]map[string]any
	if err := json.Unmarshal(editRec.Body.Bytes(), &editPayload); err != nil {
		t.Fatalf("decode edit payload: %v", err)
	}
	if editPayload["category"]["id"] != "safety" ||
		editPayload["category"]["status"] != "published" ||
		editPayload["category"]["slug"] != "safety" {
		t.Fatalf("edit payload = %#v", editPayload)
	}
}

func TestAdminHelpAnalyticsEndpointRequiresRoleAndReturnsOperationalMetrics(t *testing.T) {
	repo := newHTTPFakeRepository()
	repo.analytics = app.HelpAnalyticsSummary{
		GeneratedAt: time.Date(2026, 6, 20, 12, 0, 0, 0, time.UTC),
		Searches: app.HelpSearchAnalytics{
			Total:          2,
			WithoutResults: 1,
			SuccessRate:    0.5,
			TopNoResultQueries: []app.HelpSearchQueryStat{
				{Query: "visa chargeback", Count: 1},
			},
			RepeatedQueries: []app.HelpSearchQueryStat{
				{Query: "refund money", Count: 3},
			},
		},
		Feedback: app.HelpFeedbackAnalytics{
			Total:          1,
			NotHelpful:     1,
			Escalations:    1,
			NotHelpfulRate: 1,
			TopNotHelpfulArticles: []app.HelpArticleFeedbackStat{
				{ArticleID: "refund-timing", Count: 1, Escalations: 1},
			},
		},
		Tickets: app.SupportTicketAnalytics{
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
	}
	handler := NewHandler(app.NewHelpUseCase(repo, fixedClock()))
	mux := http.NewServeMux()
	handler.Register(mux)

	forbidden := httptest.NewRequest(http.MethodGet, "/v1/admin/help/analytics", nil)
	forbidden.Header.Set("X-User-Id", "staff-1")
	forbidden.Header.Set("X-User-Roles", "READ_ONLY_AUDITOR")
	forbiddenRec := httptest.NewRecorder()
	mux.ServeHTTP(forbiddenRec, forbidden)
	if forbiddenRec.Code != http.StatusForbidden {
		t.Fatalf("forbidden status = %d, want 403; body=%s", forbiddenRec.Code, forbiddenRec.Body.String())
	}

	req := httptest.NewRequest(http.MethodGet, "/v1/admin/help/analytics?limit=5", nil)
	req.Header.Set("X-User-Id", "lead-1")
	req.Header.Set("X-User-Roles", "SUPPORT_LEAD")
	rec := httptest.NewRecorder()
	mux.ServeHTTP(rec, req)
	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want 200; body=%s", rec.Code, rec.Body.String())
	}
	var payload map[string]any
	if err := json.Unmarshal(rec.Body.Bytes(), &payload); err != nil {
		t.Fatalf("decode analytics response: %v", err)
	}
	searches := payload["searches"].(map[string]any)
	if searches["withoutResults"] != float64(1) || searches["successRate"] != 0.5 {
		t.Fatalf("searches = %#v", searches)
	}
	feedback := payload["feedback"].(map[string]any)
	if feedback["notHelpful"] != float64(1) || feedback["escalations"] != float64(1) {
		t.Fatalf("feedback = %#v", feedback)
	}
	tickets := payload["tickets"].(map[string]any)
	if tickets["averageFirstResponseSeconds"] != float64(900) ||
		tickets["averageResolutionSeconds"] != float64(5400) ||
		tickets["waitingSupport"] != float64(1) ||
		tickets["csatResponses"] != float64(2) ||
		tickets["averageCSAT"] != float64(4) {
		t.Fatalf("tickets = %#v", tickets)
	}
}

type httpFakeRepository struct {
	categories       []app.HelpCategory
	savedReplies     []app.SupportSavedReply
	articles         []app.HelpArticle
	articleEvents    []app.HelpArticleEvent
	searchEvents     []app.HelpSearchEvent
	feedback         []app.ArticleFeedback
	csat             []app.SupportTicketCSAT
	tickets          []app.SupportTicket
	events           []app.SupportTicketEvent
	userSegments     map[string]app.SupportUserSegment
	supportAgents    []app.SupportAgent
	analytics        app.HelpAnalyticsSummary
	lastTicketFilter app.SupportTicketFilter
}

func newHTTPFakeRepository() *httpFakeRepository {
	return &httpFakeRepository{
		articles: []app.HelpArticle{
			{
				ID:       "activity-cancel-paid",
				Slug:     "activity-cancel-paid",
				Status:   app.ArticleStatusPublished,
				Tags:     []string{"activities", "refunds"},
				Surfaces: []app.HelpSurface{app.HelpSurfaceActivityDetails, app.HelpSurfaceHelpCenter},
				Visibility: app.ArticleVisibility{
					UserStates: []string{"paid"},
				},
				Translations: map[string]app.ArticleTranslation{
					"ru": {
						Title:       "Как отменить оплаченную активность?",
						ShortAnswer: "Проверьте срок бесплатной отмены и подтвердите действие.",
						Body:        "Если отмена доступна, возврат запускается автоматически.",
					},
					"en": {
						Title:       "How do I cancel a paid activity?",
						ShortAnswer: "Check the cancellation window and confirm cancellation.",
						Body:        "If cancellation is available, the refund starts automatically.",
					},
				},
				Actions: []app.ArticleAction{
					{Type: app.ArticleActionOpenChat, Target: "activity_organizer"},
					{Type: app.ArticleActionContactSupport, Target: "support"},
				},
				UpdatedAt: time.Date(2026, 6, 1, 10, 0, 0, 0, time.UTC),
			},
			{
				ID:       "refund-timing",
				Slug:     "refund-timing",
				Status:   app.ArticleStatusPublished,
				Tags:     []string{"payments", "refunds"},
				Surfaces: []app.HelpSurface{app.HelpSurfaceHelpCenter},
				Translations: map[string]app.ArticleTranslation{
					"ru": {
						Title:       "Когда вернутся деньги?",
						ShortAnswer: "Возврат обычно занимает несколько банковских дней.",
						Body:        "Статус возврата можно проверить в деталях платежа.",
					},
				},
			},
		},
	}
}

func (r *httpFakeRepository) ListArticles(context.Context) ([]app.HelpArticle, error) {
	return append([]app.HelpArticle(nil), r.articles...), nil
}

func (r *httpFakeRepository) SearchArticles(_ context.Context, filter app.SearchArticleFilter) ([]app.HelpArticle, error) {
	terms := strings.Fields(strings.ToLower(strings.TrimSpace(filter.Query)))
	if len(terms) == 0 {
		return []app.HelpArticle{}, nil
	}
	matches := make([]httpArticleSearchMatch, 0, len(r.articles))
	for _, article := range r.articles {
		if article.Status != app.ArticleStatusPublished {
			continue
		}
		if filter.Surface != "" && !httpArticleHasSurface(article, filter.Surface) {
			continue
		}
		translation, ok := article.Translations[filter.Locale]
		if !ok {
			translation, ok = article.Translations["en"]
		}
		if !ok {
			continue
		}
		score := 0
		for _, term := range terms {
			termScore := httpWeightedFieldScore(translation.Title, term, 5) +
				httpWeightedFieldScore(translation.ShortAnswer, term, 4) +
				httpWeightedFieldScore(translation.Body, term, 2) +
				httpWeightedFieldScore(strings.Join(article.Tags, " "), term, 1)
			if termScore == 0 {
				score = 0
				break
			}
			score += termScore
		}
		if score > 0 {
			matches = append(matches, httpArticleSearchMatch{article: article, score: score})
		}
	}
	sort.SliceStable(matches, func(i, j int) bool {
		if matches[i].score != matches[j].score {
			return matches[i].score > matches[j].score
		}
		if !matches[i].article.UpdatedAt.Equal(matches[j].article.UpdatedAt) {
			return matches[i].article.UpdatedAt.After(matches[j].article.UpdatedAt)
		}
		return matches[i].article.ID < matches[j].article.ID
	})
	limit := filter.Limit
	if limit <= 0 {
		limit = len(matches)
	}
	if len(matches) < limit {
		limit = len(matches)
	}
	items := make([]app.HelpArticle, 0, limit)
	for i := 0; i < limit; i++ {
		items = append(items, matches[i].article)
	}
	return items, nil
}

type httpArticleSearchMatch struct {
	article app.HelpArticle
	score   int
}

func httpWeightedFieldScore(value string, term string, weight int) int {
	text := strings.Join(strings.Fields(strings.ToLower(strings.TrimSpace(value))), " ")
	switch {
	case text == "":
		return 0
	case strings.HasPrefix(text, term):
		return weight * 3
	case strings.Contains(text, " "+term):
		return weight * 2
	case strings.Contains(text, term):
		return weight
	default:
		return 0
	}
}

func httpArticleHasSurface(article app.HelpArticle, surface app.HelpSurface) bool {
	for _, item := range article.Surfaces {
		if item == surface {
			return true
		}
	}
	return false
}

func (r *httpFakeRepository) ListCategories(_ context.Context, filter app.HelpCategoryFilter) ([]app.HelpCategory, error) {
	items := make([]app.HelpCategory, 0, len(r.categories))
	for _, category := range r.categories {
		if filter.Status != "" && category.Status != filter.Status {
			continue
		}
		items = append(items, category)
	}
	if filter.Offset >= len(items) {
		return []app.HelpCategory{}, nil
	}
	items = items[filter.Offset:]
	if filter.Limit > 0 && len(items) > filter.Limit {
		items = items[:filter.Limit]
	}
	return append([]app.HelpCategory(nil), items...), nil
}

func (r *httpFakeRepository) UpsertCategory(_ context.Context, category app.HelpCategory) error {
	for index := range r.categories {
		if r.categories[index].ID != category.ID {
			continue
		}
		if !r.categories[index].CreatedAt.IsZero() {
			category.CreatedAt = r.categories[index].CreatedAt
		}
		r.categories[index] = category
		return nil
	}
	r.categories = append(r.categories, category)
	return nil
}

func (r *httpFakeRepository) ListSavedReplies(_ context.Context, filter app.SupportSavedReplyFilter) ([]app.SupportSavedReply, error) {
	items := make([]app.SupportSavedReply, 0, len(r.savedReplies))
	for _, reply := range r.savedReplies {
		if filter.Status != "" && reply.Status != filter.Status {
			continue
		}
		if filter.Category != "" && reply.Category != filter.Category {
			continue
		}
		items = append(items, reply)
	}
	return items, nil
}

func (r *httpFakeRepository) UpsertSavedReply(_ context.Context, reply app.SupportSavedReply) error {
	for index := range r.savedReplies {
		if r.savedReplies[index].ID != reply.ID {
			continue
		}
		if !r.savedReplies[index].CreatedAt.IsZero() {
			reply.CreatedAt = r.savedReplies[index].CreatedAt
		}
		r.savedReplies[index] = reply
		return nil
	}
	r.savedReplies = append(r.savedReplies, reply)
	return nil
}

func (r *httpFakeRepository) ListAdminArticles(_ context.Context, filter app.HelpArticleFilter) ([]app.HelpArticle, error) {
	items := make([]app.HelpArticle, 0, len(r.articles))
	for _, article := range r.articles {
		if filter.Status != "" && article.Status != filter.Status {
			continue
		}
		items = append(items, article)
	}
	return items, nil
}

func (r *httpFakeRepository) GetArticle(_ context.Context, articleID string) (app.HelpArticle, []app.HelpArticleEvent, error) {
	for _, article := range r.articles {
		if article.ID == articleID {
			events := make([]app.HelpArticleEvent, 0)
			for _, event := range r.articleEvents {
				if event.ArticleID == articleID {
					events = append(events, event)
				}
			}
			return article, events, nil
		}
	}
	return app.HelpArticle{}, nil, app.ErrArticleNotFound
}

func (r *httpFakeRepository) UpsertArticle(_ context.Context, article app.HelpArticle, event app.HelpArticleEvent) error {
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

func (r *httpFakeRepository) SaveHelpSearchEvent(_ context.Context, event app.HelpSearchEvent) error {
	r.searchEvents = append(r.searchEvents, event)
	return nil
}

func (r *httpFakeRepository) SaveArticleFeedback(_ context.Context, feedback app.ArticleFeedback) error {
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

func (r *httpFakeRepository) CreateSupportTicket(_ context.Context, ticket app.SupportTicket) error {
	r.tickets = append(r.tickets, ticket)
	return nil
}

func (r *httpFakeRepository) FindSupportTicketByIdempotencyKey(_ context.Context, userID string, idempotencyKey string) (app.SupportTicket, error) {
	for _, ticket := range r.tickets {
		if ticket.UserID == userID && ticket.IdempotencyKey == idempotencyKey {
			return ticket, nil
		}
	}
	return app.SupportTicket{}, app.ErrSupportTicketNotFound
}

func (r *httpFakeRepository) ListSupportTickets(_ context.Context, filter app.SupportTicketFilter) ([]app.SupportTicket, error) {
	r.lastTicketFilter = filter
	items := make([]app.SupportTicket, 0, len(r.tickets))
	for _, ticket := range r.tickets {
		if filter.UserID != "" && ticket.UserID != filter.UserID {
			continue
		}
		if filter.Status != "" && ticket.Status != filter.Status {
			continue
		}
		items = append(items, ticket)
	}
	return items, nil
}

func (r *httpFakeRepository) GetSupportTicket(_ context.Context, ticketID string) (app.SupportTicket, []app.SupportTicketEvent, error) {
	for _, ticket := range r.tickets {
		if ticket.ID == ticketID {
			return ticket, append([]app.SupportTicketEvent(nil), r.events...), nil
		}
	}
	return app.SupportTicket{}, nil, app.ErrSupportTicketNotFound
}

func (r *httpFakeRepository) UpdateSupportTicket(_ context.Context, ticket app.SupportTicket, event app.SupportTicketEvent) error {
	for index := range r.tickets {
		if r.tickets[index].ID == ticket.ID {
			r.tickets[index] = ticket
			r.events = append(r.events, event)
			return nil
		}
	}
	return app.ErrSupportTicketNotFound
}

func (r *httpFakeRepository) AppendSupportTicketEvent(_ context.Context, event app.SupportTicketEvent) error {
	r.events = append(r.events, event)
	return nil
}

func (r *httpFakeRepository) SaveSupportTicketCSAT(_ context.Context, csat app.SupportTicketCSAT, event app.SupportTicketEvent) error {
	r.csat = append(r.csat, csat)
	r.events = append(r.events, event)
	return nil
}

func (r *httpFakeRepository) GetSupportUserSegment(_ context.Context, userID string) (app.SupportUserSegment, error) {
	if r.userSegments == nil {
		return app.SupportUserSegment{}, app.ErrSupportUserSegmentNotFound
	}
	segment, ok := r.userSegments[userID]
	if !ok {
		return app.SupportUserSegment{}, app.ErrSupportUserSegmentNotFound
	}
	return segment, nil
}

func (r *httpFakeRepository) UpsertSupportUserSegment(_ context.Context, segment app.SupportUserSegment) error {
	if r.userSegments == nil {
		r.userSegments = map[string]app.SupportUserSegment{}
	}
	r.userSegments[segment.UserID] = segment
	return nil
}

func (r *httpFakeRepository) ListSupportAgents(_ context.Context, filter app.SupportAgentFilter) ([]app.SupportAgent, error) {
	items := make([]app.SupportAgent, 0, len(r.supportAgents))
	for _, agent := range r.supportAgents {
		if filter.Status != "" && agent.Status != filter.Status {
			continue
		}
		items = append(items, agent)
	}
	return items, nil
}

func (r *httpFakeRepository) UpsertSupportAgent(_ context.Context, agent app.SupportAgent) error {
	for index := range r.supportAgents {
		if r.supportAgents[index].StaffID == agent.StaffID {
			r.supportAgents[index] = agent
			return nil
		}
	}
	r.supportAgents = append(r.supportAgents, agent)
	return nil
}

func (r *httpFakeRepository) GetHelpAnalytics(context.Context, app.HelpAnalyticsFilter) (app.HelpAnalyticsSummary, error) {
	return r.analytics, nil
}

func fixedClock() func() time.Time {
	return func() time.Time {
		return time.Date(2026, 6, 20, 12, 0, 0, 0, time.UTC)
	}
}

type httpFakeSupportChatGateway struct {
	conversationID       string
	conversationRequests []string
	messages             []app.SupportChatMessageInput
	messageID            string
	err                  error
}

func (g *httpFakeSupportChatGateway) EnsureSupportConversation(_ context.Context, userID string) (app.SupportChatConversationResult, error) {
	if g.err != nil {
		return app.SupportChatConversationResult{}, g.err
	}
	g.conversationRequests = append(g.conversationRequests, userID)
	return app.SupportChatConversationResult{ConversationID: g.conversationID}, nil
}

func (g *httpFakeSupportChatGateway) SendSupportMessage(_ context.Context, input app.SupportChatMessageInput) (app.SupportChatMessageResult, error) {
	if g.err != nil {
		return app.SupportChatMessageResult{}, g.err
	}
	g.messages = append(g.messages, input)
	return app.SupportChatMessageResult{MessageID: g.messageID}, nil
}
