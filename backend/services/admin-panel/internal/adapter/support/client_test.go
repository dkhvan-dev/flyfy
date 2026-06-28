package support

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"kz/inflap/backend/services/admin-panel/internal/domain/model"
)

func TestClientListTicketsSendsInternalSupportHeaders(t *testing.T) {
	var gotUserID string
	var gotRoles string
	var gotSLA string
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/v1/admin/support/tickets" {
			t.Fatalf("path = %q, want /v1/admin/support/tickets", r.URL.Path)
		}
		gotUserID = r.Header.Get("X-User-Id")
		gotRoles = r.Header.Get("X-User-Roles")
		gotSLA = r.URL.Query().Get("sla")
		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(map[string]any{
			"items": []map[string]any{
				{
					"id":                         "ticket-1",
					"userId":                     "user-1",
					"status":                     "new",
					"category":                   "activities",
					"priority":                   "normal",
					"priorityReasonCodes":        []string{"payment_keyword"},
					"customerSegment":            "guide",
					"customerSegmentReasonCodes": []string{"verified_guide"},
					"segmentRefreshStatus":       "fresh",
					"userNicknameSnapshot":       "@nomad",
					"followersCountSnapshot":     25000,
					"guideStatusSnapshot":        "verified",
					"source":                     "activity_details",
					"locale":                     "ru",
					"assignmentStatus":           "assigned",
					"assignmentReason":           "auto_assignment",
					"assignmentReasonCodes":      []string{"skill_activities", "language_ru"},
					"assignedAt":                 "2026-06-20T12:01:00Z",
					"context":                    map[string]string{"activity_id": "activity-1"},
					"lastMessagePreview":         "Не проходит оплата тура.",
					"lastMessageAt":              "2026-06-20T12:00:00Z",
					"createdAt":                  "2026-06-20T12:00:00Z",
					"updatedAt":                  "2026-06-20T12:00:00Z",
				},
			},
		})
	}))
	defer server.Close()

	client := NewClient(server.URL, time.Second, "internal-token")
	items, err := client.ListTickets(
		t.Context(),
		model.SupportTicketFilter{Status: model.SupportTicketStatusNew, SLABreached: true, Limit: 10},
	)
	if err != nil {
		t.Fatalf("ListTickets returned error: %v", err)
	}
	if len(items) != 1 || items[0].ID != "ticket-1" {
		t.Fatalf("items = %#v", items)
	}
	if items[0].CustomerSegment != model.SupportCustomerSegmentGuide ||
		items[0].SegmentRefreshStatus != "fresh" ||
		items[0].UserNicknameSnapshot != "@nomad" ||
		items[0].FollowersCountSnapshot != 25000 ||
		items[0].LastMessagePreview != "Не проходит оплата тура." ||
		items[0].AssignmentStatus != model.SupportAssignmentStatusAssigned ||
		items[0].AssignedAt == nil {
		t.Fatalf("mapped ticket metadata = %#v", items[0])
	}
	if len(items[0].PriorityReasonCodes) != 1 || items[0].PriorityReasonCodes[0] != "payment_keyword" {
		t.Fatalf("priority reason codes = %#v", items[0].PriorityReasonCodes)
	}
	if len(items[0].AssignmentReasonCodes) != 2 || items[0].AssignmentReasonCodes[0] != "skill_activities" {
		t.Fatalf("assignment reason codes = %#v", items[0].AssignmentReasonCodes)
	}
	if gotUserID != "admin-panel" {
		t.Fatalf("X-User-Id = %q, want admin-panel", gotUserID)
	}
	if gotRoles == "" {
		t.Fatal("X-User-Roles was not sent")
	}
	if gotSLA != "breached" {
		t.Fatalf("sla query = %q, want breached", gotSLA)
	}
}

func TestClientManagesSupportAgentsAndUserSegments(t *testing.T) {
	var agentBody map[string]any
	var segmentBody map[string]any
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		switch {
		case r.Method == http.MethodGet && r.URL.Path == "/v1/admin/support/agents":
			_ = json.NewEncoder(w).Encode(map[string]any{
				"items": []map[string]any{
					{
						"staffId":       "staff-1",
						"displayName":   "Нурланова Айгерим Сапаровна",
						"firstName":     "Айгерим",
						"lastName":      "Нурланова",
						"middleName":    "Сапаровна",
						"status":        "active",
						"languages":     []string{"ru", "en"},
						"skills":        []string{"payments", "technical"},
						"level":         "senior",
						"maxActiveLoad": 6,
						"timezone":      "Asia/Almaty",
						"updatedAt":     "2026-06-20T12:00:00Z",
					},
				},
			})
		case r.Method == http.MethodPut && r.URL.Path == "/v1/admin/support/agents/staff-2":
			if err := json.NewDecoder(r.Body).Decode(&agentBody); err != nil {
				t.Fatalf("decode agent body: %v", err)
			}
			_ = json.NewEncoder(w).Encode(map[string]any{
				"agent": map[string]any{
					"staffId":       "staff-2",
					"displayName":   "Ибраева Аружан Ермековна",
					"firstName":     "Аружан",
					"lastName":      "Ибраева",
					"middleName":    "Ермековна",
					"status":        "active",
					"languages":     []string{"ru"},
					"skills":        []string{"payments"},
					"level":         "lead",
					"maxActiveLoad": 5.5,
					"timezone":      "Asia/Almaty",
					"updatedAt":     "2026-06-20T12:01:00Z",
				},
			})
		case r.Method == http.MethodGet && r.URL.Path == "/v1/admin/support/user-segments/user-123":
			_ = json.NewEncoder(w).Encode(map[string]any{
				"segment": map[string]any{
					"userId":          "user-123",
					"nickname":        "@nomad",
					"customerSegment": "vip",
					"followersCount":  42000,
					"isGuide":         true,
					"manualSegment":   "vip",
					"reasonCodes":     []string{"manual_vip"},
					"refreshStatus":   "fresh",
					"updatedAt":       "2026-06-20T12:02:00Z",
					"sourceVersion":   "admin-manual",
				},
			})
		case r.Method == http.MethodPut && r.URL.Path == "/v1/admin/support/user-segments/user-123":
			if err := json.NewDecoder(r.Body).Decode(&segmentBody); err != nil {
				t.Fatalf("decode segment body: %v", err)
			}
			_ = json.NewEncoder(w).Encode(map[string]any{
				"segment": map[string]any{
					"userId":          "user-123",
					"nickname":        "@nomad",
					"customerSegment": "vip",
					"followersCount":  42000,
					"isGuide":         true,
					"manualSegment":   "vip",
					"reasonCodes":     []string{"manual_vip"},
					"refreshStatus":   "fresh",
					"updatedAt":       "2026-06-20T12:03:00Z",
				},
			})
		default:
			t.Fatalf("unexpected request %s %s", r.Method, r.URL.RequestURI())
		}
	}))
	defer server.Close()

	client := NewClient(server.URL, time.Second, "internal-token")
	agents, err := client.ListSupportAgents(t.Context(), model.SupportAgentFilter{Status: model.SupportAgentStatusActive, Limit: 10})
	if err != nil {
		t.Fatalf("ListSupportAgents returned error: %v", err)
	}
	if len(agents) != 1 || agents[0].Skills[0] != model.SupportAgentSkillPayments {
		t.Fatalf("agents = %#v", agents)
	}
	if agents[0].FirstName != "Айгерим" || agents[0].LastName != "Нурланова" {
		t.Fatalf("agent name fields = %#v", agents[0])
	}

	agent, err := client.UpsertSupportAgent(t.Context(), model.SupportAgentUpsertInput{
		ActorStaffID:   "lead-1",
		StaffID:        "staff-2",
		FirstName:      "Аружан",
		LastName:       "Ибраева",
		MiddleName:     "Ермековна",
		Status:         model.SupportAgentStatusActive,
		Languages:      []string{"ru"},
		Skills:         []model.SupportAgentSkill{model.SupportAgentSkillPayments},
		Level:          model.SupportAgentLevelLead,
		MaxActiveLoad:  5.5,
		Timezone:       "Asia/Almaty",
		IdempotencyKey: "idem-agent",
	})
	if err != nil {
		t.Fatalf("UpsertSupportAgent returned error: %v", err)
	}
	if agent.StaffID != "staff-2" ||
		agent.FirstName != "Аружан" ||
		agent.LastName != "Ибраева" ||
		agentBody["firstName"] != "Аружан" ||
		agentBody["lastName"] != "Ибраева" ||
		agentBody["middleName"] != "Ермековна" ||
		agentBody["level"] != "lead" {
		t.Fatalf("agent = %#v body = %#v", agent, agentBody)
	}

	segment, err := client.GetSupportUserSegment(t.Context(), "user-123")
	if err != nil {
		t.Fatalf("GetSupportUserSegment returned error: %v", err)
	}
	if segment.CustomerSegment != model.SupportCustomerSegmentVIP {
		t.Fatalf("segment = %#v", segment)
	}

	updated, err := client.UpsertSupportUserSegment(t.Context(), model.SupportUserSegmentUpsertInput{
		ActorStaffID:   "lead-1",
		UserID:         "user-123",
		Nickname:       "@nomad",
		FollowersCount: 42000,
		IsGuide:        true,
		ManualSegment:  model.SupportCustomerSegmentVIP,
		ManualReason:   "Launch partner",
	})
	if err != nil {
		t.Fatalf("UpsertSupportUserSegment returned error: %v", err)
	}
	if updated.CustomerSegment != model.SupportCustomerSegmentVIP ||
		segmentBody["subscriptionTier"] != "" {
		t.Fatalf("updated = %#v body = %#v", updated, segmentBody)
	}
}

func TestClientAssignTicketSendsManualReason(t *testing.T) {
	var gotBody map[string]string
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodPost || r.URL.Path != "/v1/admin/support/tickets/ticket-1/assign" {
			t.Fatalf("unexpected request %s %s", r.Method, r.URL.RequestURI())
		}
		if err := json.NewDecoder(r.Body).Decode(&gotBody); err != nil {
			t.Fatalf("decode body: %v", err)
		}
		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(map[string]any{
			"ticket": map[string]any{
				"id":               "ticket-1",
				"userId":           "user-1",
				"status":           "assigned",
				"category":         "technical",
				"priority":         "normal",
				"source":           "support_requests",
				"locale":           "ru",
				"assigneeId":       "agent-2",
				"assignmentStatus": "manual",
				"assignmentReason": "Escalating to senior support",
				"context":          map[string]string{},
				"lastMessageAt":    "2026-06-20T12:00:00Z",
				"createdAt":        "2026-06-20T12:00:00Z",
				"updatedAt":        "2026-06-20T12:00:00Z",
			},
		})
	}))
	defer server.Close()

	client := NewClient(server.URL, time.Second, "internal-token")
	ticket, err := client.AssignTicket(t.Context(), model.SupportTicketAssignInput{
		TicketID:       "ticket-1",
		ActorStaffID:   "lead-1",
		AssigneeID:     "agent-2",
		Reason:         "Escalating to senior support",
		IdempotencyKey: "idem-assign",
	})
	if err != nil {
		t.Fatalf("AssignTicket returned error: %v", err)
	}
	if ticket.AssignmentStatus != model.SupportAssignmentStatusManual ||
		gotBody["assigneeId"] != "agent-2" ||
		gotBody["reason"] != "Escalating to senior support" {
		t.Fatalf("ticket = %#v body = %#v", ticket, gotBody)
	}
}

func TestClientReplyTicketSendsActorDisplayName(t *testing.T) {
	var gotDisplayName string
	var gotBody map[string]any
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodPost || r.URL.Path != "/v1/admin/support/tickets/ticket-1/reply" {
			t.Fatalf("unexpected request %s %s", r.Method, r.URL.RequestURI())
		}
		gotDisplayName = r.Header.Get("X-Actor-Display-Name")
		if err := json.NewDecoder(r.Body).Decode(&gotBody); err != nil {
			t.Fatalf("decode body: %v", err)
		}
		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(map[string]any{
			"ticket": map[string]any{
				"id":              "ticket-1",
				"userId":          "user-1",
				"status":          "waiting_user",
				"category":        "technical",
				"priority":        "normal",
				"source":          "support_requests",
				"locale":          "ru",
				"context":         map[string]string{},
				"lastMessageAt":   "2026-06-20T12:00:00Z",
				"firstResponseAt": "2026-06-20T12:00:00Z",
				"createdAt":       "2026-06-20T12:00:00Z",
				"updatedAt":       "2026-06-20T12:00:00Z",
			},
		})
	}))
	defer server.Close()

	client := NewClient(server.URL, time.Second, "internal-token")
	ticket, err := client.ReplyTicket(t.Context(), model.SupportTicketReplyInput{
		TicketID:         "ticket-1",
		ActorStaffID:     "staff-1",
		ActorDisplayName: "Aruzhan Ops",
		Message:          "Hello from support",
		FileIDs:          []string{"file-1", " ", "file-2", "file-1"},
		IdempotencyKey:   "idem-1",
		RequestID:        "req-1",
	})
	if err != nil {
		t.Fatalf("ReplyTicket returned error: %v", err)
	}
	if ticket.ID != "ticket-1" || ticket.Status != model.SupportTicketStatusWaitingUser {
		t.Fatalf("ticket = %#v", ticket)
	}
	if gotDisplayName != "Aruzhan Ops" {
		t.Fatalf("X-Actor-Display-Name = %q, want Aruzhan Ops", gotDisplayName)
	}
	if gotBody["message"] != "Hello from support" {
		t.Fatalf("body = %#v", gotBody)
	}
	fileIDs, ok := gotBody["fileIds"].([]any)
	if !ok || len(fileIDs) != 2 || fileIDs[0] != "file-1" || fileIDs[1] != "file-2" {
		t.Fatalf("fileIds body = %#v", gotBody)
	}
}

func TestClientListAndUpsertSupportSavedRepliesUsesSupportEndpoints(t *testing.T) {
	var gotListPath string
	var gotEditPath string
	var gotUserID string
	var gotRoles string
	var gotBody map[string]any
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		switch r.Method + " " + r.URL.Path {
		case http.MethodGet + " /v1/admin/support/saved-replies":
			gotListPath = r.URL.RequestURI()
			_ = json.NewEncoder(w).Encode(map[string]any{
				"items": []map[string]any{
					{
						"id":        "refund-status",
						"category":  "payments",
						"status":    "published",
						"tags":      []string{"refunds"},
						"sortOrder": 20,
						"translations": map[string]any{
							"en": map[string]string{"title": "Refund status", "body": "I checked your refund status."},
						},
						"createdAt": "2026-06-20T12:00:00Z",
						"updatedAt": "2026-06-20T12:00:00Z",
					},
				},
			})
		case http.MethodPut + " /v1/admin/support/saved-replies/meeting-point":
			gotEditPath = r.URL.Path
			gotUserID = r.Header.Get("X-User-Id")
			gotRoles = r.Header.Get("X-User-Roles")
			if err := json.NewDecoder(r.Body).Decode(&gotBody); err != nil {
				t.Fatalf("decode body: %v", err)
			}
			_ = json.NewEncoder(w).Encode(map[string]any{
				"reply": map[string]any{
					"id":        "meeting-point",
					"category":  "activities",
					"status":    "published",
					"sortOrder": 5,
					"translations": map[string]any{
						"en": map[string]string{"title": "Meeting point", "body": "Please check the meeting point block."},
					},
					"createdAt": "2026-06-20T12:00:00Z",
					"updatedAt": "2026-06-20T12:00:00Z",
				},
			})
		default:
			t.Fatalf("unexpected request %s %s", r.Method, r.URL.RequestURI())
		}
	}))
	defer server.Close()

	client := NewClient(server.URL, time.Second, "internal-token")
	replies, err := client.ListSupportSavedReplies(t.Context(), model.SupportSavedReplyFilter{
		Category: "payments",
		Status:   model.HelpArticleStatusPublished,
		Limit:    10,
	})
	if err != nil {
		t.Fatalf("ListSupportSavedReplies returned error: %v", err)
	}
	if len(replies) != 1 || replies[0].ID != "refund-status" || replies[0].Translations["en"].Body == "" {
		t.Fatalf("replies = %#v", replies)
	}
	if gotListPath != "/v1/admin/support/saved-replies?category=payments&limit=10&offset=0&status=published" {
		t.Fatalf("list path = %q", gotListPath)
	}

	reply, err := client.UpsertSupportSavedReply(t.Context(), model.SupportSavedReplyUpsertInput{
		ReplyID:      "meeting-point",
		ActorStaffID: "lead-1",
		Category:     "activities",
		Status:       model.HelpArticleStatusPublished,
		Tags:         []string{"meeting"},
		SortOrder:    5,
		Translations: map[string]model.SupportSavedReplyTranslation{
			"en": {Title: "Meeting point", Body: "Please check the meeting point block."},
		},
		IdempotencyKey: "idem-1",
		RequestID:      "req-1",
	})
	if err != nil {
		t.Fatalf("UpsertSupportSavedReply returned error: %v", err)
	}
	if reply.ID != "meeting-point" || reply.Category != "activities" {
		t.Fatalf("reply = %#v", reply)
	}
	if gotEditPath != "/v1/admin/support/saved-replies/meeting-point" {
		t.Fatalf("edit path = %q", gotEditPath)
	}
	if gotUserID != "lead-1" {
		t.Fatalf("X-User-Id = %q", gotUserID)
	}
	if gotRoles == "" || !strings.Contains(gotRoles, "SUPPORT_ADMIN") {
		t.Fatalf("X-User-Roles = %q", gotRoles)
	}
	if gotBody["category"] != "activities" || gotBody["status"] != "published" || gotBody["sortOrder"] != float64(5) {
		t.Fatalf("body = %#v", gotBody)
	}
}

func TestClientUpsertHelpArticleSendsEditorHeadersAndPayload(t *testing.T) {
	var gotPath string
	var gotUserID string
	var gotRoles string
	var gotBody map[string]any
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		gotPath = r.URL.Path
		gotUserID = r.Header.Get("X-User-Id")
		gotRoles = r.Header.Get("X-User-Roles")
		if err := json.NewDecoder(r.Body).Decode(&gotBody); err != nil {
			t.Fatalf("decode body: %v", err)
		}
		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(map[string]any{
			"article": map[string]any{
				"id":       "refund-policy",
				"slug":     "refund-policy",
				"status":   "draft",
				"version":  1,
				"ownerId":  "editor-1",
				"tags":     []string{"payments", "refunds"},
				"surfaces": []string{"help_center"},
				"translations": map[string]any{
					"en": map[string]string{"title": "Refund policy", "shortAnswer": "Refund timing depends on the provider.", "body": "Open booking details."},
					"ru": map[string]string{"title": "Правила возврата", "shortAnswer": "Срок зависит от провайдера.", "body": "Откройте детали бронирования."},
					"kk": map[string]string{"title": "Қайтарым ережелері", "shortAnswer": "Мерзім провайдерге байланысты.", "body": "Брондау деталін ашыңыз."},
				},
				"updatedAt": "2026-06-20T12:00:00Z",
			},
		})
	}))
	defer server.Close()

	client := NewClient(server.URL, time.Second, "internal-token")
	article, err := client.UpsertHelpArticle(t.Context(), model.HelpArticleUpsertInput{
		ArticleID:    "refund-policy",
		ActorStaffID: "editor-1",
		Slug:         "refund-policy",
		Tags:         []string{"payments", "refunds"},
		Surfaces:     []string{"help_center"},
		Translations: map[string]model.HelpArticleTranslation{
			"en": {Title: "Refund policy", ShortAnswer: "Refund timing depends on the provider.", Body: "Open booking details."},
			"ru": {Title: "Правила возврата", ShortAnswer: "Срок зависит от провайдера.", Body: "Откройте детали бронирования."},
			"kk": {Title: "Қайтарым ережелері", ShortAnswer: "Мерзім провайдерге байланысты.", Body: "Брондау деталін ашыңыз."},
		},
		IdempotencyKey: "idem-1",
		RequestID:      "req-1",
	})
	if err != nil {
		t.Fatalf("UpsertHelpArticle returned error: %v", err)
	}
	if article.ID != "refund-policy" || article.Status != model.HelpArticleStatusDraft {
		t.Fatalf("article = %#v", article)
	}
	if gotPath != "/v1/admin/help/articles/refund-policy" {
		t.Fatalf("path = %q", gotPath)
	}
	if gotUserID != "editor-1" {
		t.Fatalf("X-User-Id = %q", gotUserID)
	}
	if gotRoles == "" {
		t.Fatal("X-User-Roles was not sent")
	}
	if gotBody["slug"] != "refund-policy" {
		t.Fatalf("body = %#v", gotBody)
	}
}

func TestClientListAndUpsertHelpCategoriesUsesCategoryEndpoints(t *testing.T) {
	var gotListPath string
	var gotEditPath string
	var gotUserID string
	var gotRoles string
	var gotBody map[string]any
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		switch r.Method + " " + r.URL.Path {
		case http.MethodGet + " /v1/admin/help/categories":
			gotListPath = r.URL.RequestURI()
			_ = json.NewEncoder(w).Encode(map[string]any{
				"items": []map[string]any{
					{
						"id":        "payments",
						"slug":      "payments",
						"title":     "Payments",
						"status":    "published",
						"sortOrder": 20,
						"createdAt": "2026-06-20T12:00:00Z",
						"updatedAt": "2026-06-20T12:00:00Z",
					},
				},
			})
		case http.MethodPut + " /v1/admin/help/categories/safety":
			gotEditPath = r.URL.Path
			gotUserID = r.Header.Get("X-User-Id")
			gotRoles = r.Header.Get("X-User-Roles")
			if err := json.NewDecoder(r.Body).Decode(&gotBody); err != nil {
				t.Fatalf("decode body: %v", err)
			}
			_ = json.NewEncoder(w).Encode(map[string]any{
				"category": map[string]any{
					"id":        "safety",
					"slug":      "safety",
					"status":    "published",
					"sortOrder": 5,
					"createdAt": "2026-06-20T12:00:00Z",
					"updatedAt": "2026-06-20T12:00:00Z",
				},
			})
		default:
			t.Fatalf("unexpected request %s %s", r.Method, r.URL.RequestURI())
		}
	}))
	defer server.Close()

	client := NewClient(server.URL, time.Second, "internal-token")
	categories, err := client.ListHelpCategories(t.Context(), model.HelpCategoryFilter{
		Status: model.HelpArticleStatusPublished,
		Locale: "ru",
		Limit:  10,
	})
	if err != nil {
		t.Fatalf("ListHelpCategories returned error: %v", err)
	}
	if len(categories) != 1 || categories[0].ID != "payments" || categories[0].Title != "Payments" || categories[0].SortOrder != 20 {
		t.Fatalf("categories = %#v", categories)
	}
	if gotListPath != "/v1/admin/help/categories?limit=10&locale=ru&offset=0&status=published" {
		t.Fatalf("list path = %q", gotListPath)
	}

	category, err := client.UpsertHelpCategory(t.Context(), model.HelpCategoryUpsertInput{
		CategoryID:     "safety",
		ActorStaffID:   "editor-1",
		Slug:           "safety",
		Status:         model.HelpArticleStatusPublished,
		SortOrder:      5,
		IdempotencyKey: "idem-1",
		RequestID:      "req-1",
	})
	if err != nil {
		t.Fatalf("UpsertHelpCategory returned error: %v", err)
	}
	if category.ID != "safety" || category.Status != model.HelpArticleStatusPublished {
		t.Fatalf("category = %#v", category)
	}
	if gotEditPath != "/v1/admin/help/categories/safety" {
		t.Fatalf("edit path = %q", gotEditPath)
	}
	if gotUserID != "editor-1" {
		t.Fatalf("X-User-Id = %q", gotUserID)
	}
	if gotRoles == "" || !strings.Contains(gotRoles, "HELP_CONTENT_EDITOR") {
		t.Fatalf("X-User-Roles = %q", gotRoles)
	}
	if gotBody["slug"] != "safety" || gotBody["status"] != "published" || gotBody["sortOrder"] != float64(5) {
		t.Fatalf("body = %#v", gotBody)
	}
}

func TestClientGetHelpAnalyticsUsesAnalyticsEndpointAndMapsSummary(t *testing.T) {
	var gotPath string
	var gotRoles string
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		gotPath = r.URL.RequestURI()
		gotRoles = r.Header.Get("X-User-Roles")
		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(map[string]any{
			"generatedAt": "2026-06-20T12:00:00Z",
			"searches": map[string]any{
				"total":          2,
				"withoutResults": 1,
				"successRate":    0.5,
				"topNoResultQueries": []map[string]any{
					{"query": "visa chargeback", "count": 1},
				},
				"repeatedQueries": []map[string]any{
					{"query": "refund money", "count": 3},
				},
			},
			"feedback": map[string]any{
				"total":          1,
				"notHelpful":     1,
				"escalations":    1,
				"notHelpfulRate": 1,
				"topNotHelpfulArticles": []map[string]any{
					{"articleId": "refund-timing", "count": 1, "escalations": 1},
				},
			},
			"tickets": map[string]any{
				"total":                       2,
				"open":                        1,
				"waitingSupport":              1,
				"resolved":                    1,
				"urgent":                      1,
				"averageFirstResponseSeconds": 900,
				"averageResolutionSeconds":    5400,
				"csatResponses":               2,
				"averageCSAT":                 4,
			},
		})
	}))
	defer server.Close()

	client := NewClient(server.URL, time.Second, "internal-token")
	summary, err := client.GetHelpAnalytics(t.Context(), 5)
	if err != nil {
		t.Fatalf("GetHelpAnalytics returned error: %v", err)
	}
	if gotPath != "/v1/admin/help/analytics?limit=5" {
		t.Fatalf("path = %q", gotPath)
	}
	if gotRoles == "" || !strings.Contains(gotRoles, "SUPPORT_LEAD") || !strings.Contains(gotRoles, "HELP_CONTENT_EDITOR") {
		t.Fatalf("X-User-Roles = %q", gotRoles)
	}
	if summary.Searches.WithoutResults != 1 || summary.Searches.SuccessRate != 0.5 {
		t.Fatalf("search summary = %#v", summary.Searches)
	}
	if len(summary.Searches.TopNoResultQueries) != 1 || summary.Searches.TopNoResultQueries[0].Query != "visa chargeback" {
		t.Fatalf("top no-result queries = %#v", summary.Searches.TopNoResultQueries)
	}
	if summary.Feedback.Escalations != 1 || len(summary.Feedback.TopNotHelpfulArticles) != 1 {
		t.Fatalf("feedback summary = %#v", summary.Feedback)
	}
	if summary.Tickets.AverageFirstResponseSeconds != 900 || summary.Tickets.AverageResolutionSeconds != 5400 {
		t.Fatalf("ticket summary = %#v", summary.Tickets)
	}
	if summary.Tickets.CSATResponses != 2 || summary.Tickets.AverageCSAT != 4 {
		t.Fatalf("ticket csat summary = %#v", summary.Tickets)
	}
}
