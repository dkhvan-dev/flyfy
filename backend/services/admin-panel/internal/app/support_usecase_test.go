package app

import (
	"context"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/admin-panel/internal/domain/enum"
	"kz/inflap/backend/services/admin-panel/internal/domain/model"
)

func TestSupportUseCaseRequiresSupportPermission(t *testing.T) {
	uc := NewSupportUseCase(&supportClientStub{}, &supportAuditStub{})
	actor := &model.StaffUser{ID: uuid.New(), Permissions: []enum.Permission{enum.PermissionDashboardRead}}

	_, err := uc.ListTickets(context.Background(), actor, model.SupportTicketFilter{})

	if err != ErrPermissionDenied {
		t.Fatalf("err = %v, want ErrPermissionDenied", err)
	}
}

func TestSupportUseCaseAllowsViewerToListTickets(t *testing.T) {
	client := &supportClientStub{
		tickets: []model.SupportTicket{{ID: "ticket-1", Status: model.SupportTicketStatusNew}},
	}
	uc := NewSupportUseCase(client, nil)
	actor := &model.StaffUser{ID: uuid.New(), Permissions: []enum.Permission{enum.PermissionSupportRead}}

	items, err := uc.ListTickets(context.Background(), actor, model.SupportTicketFilter{})

	if err != nil {
		t.Fatalf("ListTickets returned error: %v", err)
	}
	if len(items) != 1 || items[0].ID != "ticket-1" {
		t.Fatalf("items = %#v", items)
	}
	if client.lastFilter.Limit != 50 {
		t.Fatalf("limit = %d, want default 50", client.lastFilter.Limit)
	}
}

func TestSupportUseCaseCreatesAttachmentDownloadURLFromTicketEvent(t *testing.T) {
	firstAttachmentID := uuid.MustParse("11111111-1111-1111-1111-111111111111")
	secondAttachmentID := uuid.MustParse("22222222-2222-2222-2222-222222222222")
	client := &supportClientStub{
		detail: model.SupportTicketDetail{
			Events: []model.SupportTicketEvent{
				{
					TicketID:  "ticket-1",
					ActorType: "user",
					EventType: "user_replied",
					Payload: map[string]string{
						"file_ids": firstAttachmentID.String() + "," + secondAttachmentID.String(),
					},
				},
			},
		},
	}
	files := &supportFileDownloadClientStub{
		downloadURL: "https://files.inflap.test/support/receipt.jpg?signature=temporary",
		expiresAt:   time.Date(2026, 6, 20, 12, 10, 0, 0, time.UTC),
	}
	uc := NewSupportUseCase(client, nil)
	uc.SetFileDownloadClient(files)
	actor := &model.StaffUser{ID: uuid.New(), Permissions: []enum.Permission{enum.PermissionSupportRead}}

	download, err := uc.CreateAttachmentDownloadURL(context.Background(), actor, " ticket-1 ", 0, 1)

	if err != nil {
		t.Fatalf("CreateAttachmentDownloadURL returned error: %v", err)
	}
	if download.URL != files.downloadURL || !download.ExpiresAt.Equal(files.expiresAt) {
		t.Fatalf("download = %#v", download)
	}
	if files.calls != 1 || files.fileID != secondAttachmentID {
		t.Fatalf("file client calls = %d fileID = %s", files.calls, files.fileID)
	}
}

func TestSupportUseCaseAttachmentDownloadRequiresSupportReadPermission(t *testing.T) {
	files := &supportFileDownloadClientStub{}
	uc := NewSupportUseCase(&supportClientStub{}, nil)
	uc.SetFileDownloadClient(files)
	actor := &model.StaffUser{ID: uuid.New(), Permissions: []enum.Permission{enum.PermissionDashboardRead}}

	_, err := uc.CreateAttachmentDownloadURL(context.Background(), actor, "ticket-1", 0, 0)

	if err != ErrPermissionDenied {
		t.Fatalf("err = %v, want ErrPermissionDenied", err)
	}
	if files.calls != 0 {
		t.Fatalf("file client was called %d times", files.calls)
	}
}

func TestSupportUseCaseReplyWritesAudit(t *testing.T) {
	actorID := uuid.New()
	client := &supportClientStub{
		replyTicket: model.SupportTicket{
			ID:             "ticket-1",
			Status:         model.SupportTicketStatusWaitingUser,
			ConversationID: "conversation-1",
			UpdatedAt:      time.Date(2026, 6, 20, 12, 0, 0, 0, time.UTC),
		},
		agents: []model.SupportAgent{
			{
				StaffID:     actorID.String(),
				DisplayName: "Нурланова Айгерим Сапаровна",
				FirstName:   "Айгерим",
				LastName:    "Нурланова",
				Status:      model.SupportAgentStatusActive,
			},
		},
	}
	audit := &supportAuditStub{}
	uc := NewSupportUseCase(client, audit)
	actor := &model.StaffUser{
		ID:          actorID,
		Email:       "agent@inflap.local",
		DisplayName: "Айгерим Нурланова",
		Permissions: []enum.Permission{enum.PermissionSupportReply},
	}

	ticket, err := uc.ReplyTicket(context.Background(), actor, model.SupportTicketReplyInput{
		TicketID: "ticket-1",
		Message:  "Hello from support",
	}, RequestMetadata{RequestID: "req-1", IPAddress: "127.0.0.1", UserAgent: "test"})

	if err != nil {
		t.Fatalf("ReplyTicket returned error: %v", err)
	}
	if ticket.Status != model.SupportTicketStatusWaitingUser {
		t.Fatalf("ticket status = %q", ticket.Status)
	}
	if client.lastReply.ActorStaffID != actor.ID.String() || client.lastReply.IdempotencyKey == "" {
		t.Fatalf("reply input = %#v", client.lastReply)
	}
	if client.lastReply.ActorDisplayName != "Айгерим" {
		t.Fatalf("actor display name = %q, want Айгерим", client.lastReply.ActorDisplayName)
	}
	if len(audit.events) != 1 || audit.events[0].Action != "support.ticket.reply" {
		t.Fatalf("audit events = %#v", audit.events)
	}
}

func TestSupportUseCaseReplyUsesGivenNameForLegacySwappedAgentProfile(t *testing.T) {
	actorID := uuid.New()
	client := &supportClientStub{
		replyTicket: model.SupportTicket{
			ID:             "ticket-legacy-agent",
			Status:         model.SupportTicketStatusWaitingUser,
			ConversationID: "conversation-legacy-agent",
		},
		agents: []model.SupportAgent{
			{
				StaffID:     actorID.String(),
				DisplayName: "Нурланова Айгерим Сапаровна",
				FirstName:   "Нурланова",
				LastName:    "Айгерим",
				Status:      model.SupportAgentStatusActive,
			},
		},
	}
	uc := NewSupportUseCase(client, nil)
	actor := &model.StaffUser{
		ID:          actorID,
		DisplayName: "Нурланова Айгерим Сапаровна",
		Permissions: []enum.Permission{enum.PermissionSupportReply},
	}

	_, err := uc.ReplyTicket(context.Background(), actor, model.SupportTicketReplyInput{
		TicketID: "ticket-legacy-agent",
		Message:  "Здравствуйте",
	}, RequestMetadata{RequestID: "req-legacy-agent"})

	if err != nil {
		t.Fatalf("ReplyTicket returned error: %v", err)
	}
	if client.lastReply.ActorDisplayName != "Айгерим" {
		t.Fatalf("actor display name = %q, want Айгерим", client.lastReply.ActorDisplayName)
	}
}

func TestSupportUseCaseSavedReplyWorkflowRequiresManagePermissionAndAudits(t *testing.T) {
	client := &supportClientStub{
		savedReplies: []model.SupportSavedReply{
			{
				ID:       "refund-status",
				Category: "payments",
				Status:   model.HelpArticleStatusPublished,
				Translations: map[string]model.SupportSavedReplyTranslation{
					"en": {Title: "Refund status", Body: "I checked your refund status."},
				},
			},
		},
	}
	audit := &supportAuditStub{}
	uc := NewSupportUseCase(client, audit)
	agent := &model.StaffUser{
		ID:          uuid.New(),
		Email:       "agent@inflap.local",
		DisplayName: "Agent",
		Permissions: []enum.Permission{enum.PermissionSupportReply},
	}
	manager := &model.StaffUser{
		ID:          uuid.New(),
		Email:       "lead@inflap.local",
		DisplayName: "Lead",
		Permissions: []enum.Permission{enum.PermissionSupportManage},
	}
	supportLead := &model.StaffUser{
		ID:          uuid.New(),
		Email:       "support-lead@inflap.local",
		DisplayName: "Support Lead",
		Roles:       []enum.StaffRole{enum.StaffRoleSupportLead},
	}

	replies, err := uc.ListSupportSavedReplies(context.Background(), agent, model.SupportSavedReplyFilter{})
	if err != nil {
		t.Fatalf("ListSupportSavedReplies returned error: %v", err)
	}
	if len(replies) != 1 || replies[0].ID != "refund-status" {
		t.Fatalf("replies = %#v", replies)
	}

	_, err = uc.UpsertSupportSavedReply(context.Background(), agent, model.SupportSavedReplyUpsertInput{
		ReplyID: "meeting-point",
	}, RequestMetadata{RequestID: "req-denied"})
	if err != ErrPermissionDenied {
		t.Fatalf("err = %v, want ErrPermissionDenied", err)
	}

	reply, err := uc.UpsertSupportSavedReply(context.Background(), supportLead, model.SupportSavedReplyUpsertInput{
		ReplyID:  "lead-template",
		Category: "technical",
		Status:   model.HelpArticleStatusPublished,
		Translations: map[string]model.SupportSavedReplyTranslation{
			"en": {Title: "Technical issue", Body: "I checked the technical details."},
		},
	}, RequestMetadata{RequestID: "req-lead-reply", IPAddress: "127.0.0.1", UserAgent: "test"})
	if err != nil {
		t.Fatalf("UpsertSupportSavedReply for support lead returned error: %v", err)
	}
	if reply.ID != "lead-template" || client.lastSavedReplyUpsert.ActorStaffID != supportLead.ID.String() {
		t.Fatalf("lead reply = %#v input = %#v", reply, client.lastSavedReplyUpsert)
	}

	reply, err = uc.UpsertSupportSavedReply(context.Background(), manager, model.SupportSavedReplyUpsertInput{
		ReplyID:   "meeting-point",
		Category:  "activities",
		Status:    model.HelpArticleStatusPublished,
		Tags:      []string{"meeting"},
		SortOrder: 5,
		Translations: map[string]model.SupportSavedReplyTranslation{
			"en": {Title: "Meeting point", Body: "Please check the meeting point block."},
		},
	}, RequestMetadata{RequestID: "req-reply", IPAddress: "127.0.0.1", UserAgent: "test"})
	if err != nil {
		t.Fatalf("UpsertSupportSavedReply returned error: %v", err)
	}
	if reply.ID != "meeting-point" || client.lastSavedReplyUpsert.ActorStaffID != manager.ID.String() {
		t.Fatalf("reply = %#v input = %#v", reply, client.lastSavedReplyUpsert)
	}
	if len(audit.events) != 2 ||
		audit.events[0].Action != "support.saved_reply.upsert" ||
		audit.events[0].EntityType != "support_saved_reply" ||
		audit.events[1].Action != "support.saved_reply.upsert" ||
		audit.events[1].EntityType != "support_saved_reply" {
		t.Fatalf("audit events = %#v", audit.events)
	}
}

func TestSupportUseCaseRoutingConfigurationRequiresManagePermissionAndAudits(t *testing.T) {
	client := &supportClientStub{
		agents: []model.SupportAgent{
			{StaffID: "agent-1", Status: model.SupportAgentStatusActive},
		},
		userSegment: model.SupportUserSegment{
			UserID:          "user-123",
			CustomerSegment: model.SupportCustomerSegmentStandard,
		},
	}
	audit := &supportAuditStub{}
	uc := NewSupportUseCase(client, audit)
	agent := &model.StaffUser{
		ID:          uuid.New(),
		Email:       "agent@inflap.local",
		DisplayName: "Agent",
		Permissions: []enum.Permission{enum.PermissionSupportReply},
	}
	manager := &model.StaffUser{
		ID:          uuid.New(),
		Email:       "lead@inflap.local",
		DisplayName: "Lead",
		Permissions: []enum.Permission{enum.PermissionSupportManage},
	}

	if _, err := uc.ListSupportAgents(context.Background(), agent, model.SupportAgentFilter{}); err != ErrPermissionDenied {
		t.Fatalf("ListSupportAgents err = %v, want ErrPermissionDenied", err)
	}

	agents, err := uc.ListSupportAgents(context.Background(), manager, model.SupportAgentFilter{Status: model.SupportAgentStatusActive})
	if err != nil {
		t.Fatalf("ListSupportAgents returned error: %v", err)
	}
	if len(agents) != 1 || client.lastAgentFilter.Limit != 50 {
		t.Fatalf("agents = %#v filter = %#v", agents, client.lastAgentFilter)
	}

	updatedAgent, err := uc.UpsertSupportAgent(context.Background(), manager, model.SupportAgentUpsertInput{
		StaffID:       " agent-2 ",
		FirstName:     "Аружан",
		LastName:      "Ибраева",
		MiddleName:    "Ермековна",
		Status:        model.SupportAgentStatusActive,
		Languages:     []string{"ru"},
		Skills:        []model.SupportAgentSkill{model.SupportAgentSkillPayments},
		Level:         model.SupportAgentLevelSenior,
		MaxActiveLoad: 6,
		Timezone:      "Asia/Almaty",
	}, RequestMetadata{RequestID: "req-1"})
	if err != nil {
		t.Fatalf("UpsertSupportAgent returned error: %v", err)
	}
	if updatedAgent.StaffID != "agent-2" ||
		updatedAgent.FirstName != "Аружан" ||
		updatedAgent.LastName != "Ибраева" ||
		client.lastAgentUpsert.ActorStaffID != manager.ID.String() ||
		client.lastAgentUpsert.IdempotencyKey == "" {
		t.Fatalf("agent = %#v input = %#v", updatedAgent, client.lastAgentUpsert)
	}

	segment, err := uc.UpsertSupportUserSegment(context.Background(), manager, model.SupportUserSegmentUpsertInput{
		UserID:         " user-123 ",
		Nickname:       "@nomad",
		FollowersCount: 42000,
		IsGuide:        true,
		ManualSegment:  model.SupportCustomerSegmentVIP,
		ManualReason:   "Launch partner",
	}, RequestMetadata{RequestID: "req-2"})
	if err != nil {
		t.Fatalf("UpsertSupportUserSegment returned error: %v", err)
	}
	if segment.CustomerSegment != model.SupportCustomerSegmentVIP ||
		client.lastSegmentUpsert.ActorStaffID != manager.ID.String() ||
		client.lastSegmentUpsert.SubscriptionTier != "" {
		t.Fatalf("segment = %#v input = %#v", segment, client.lastSegmentUpsert)
	}
	if len(audit.events) != 2 ||
		audit.events[0].Action != "support.agent.upsert" ||
		audit.events[1].Action != "support.user_segment.upsert" {
		t.Fatalf("audit events = %#v", audit.events)
	}
}

func TestSupportUseCaseHelpArticleWorkflowRequiresHelpContentPermissionAndAudits(t *testing.T) {
	client := &supportClientStub{
		helpArticle: model.HelpArticle{
			ID:      "refund-policy",
			Slug:    "refund-policy",
			Status:  model.HelpArticleStatusPublished,
			Version: 1,
		},
	}
	audit := &supportAuditStub{}
	uc := NewSupportUseCase(client, audit)
	editor := &model.StaffUser{
		ID:          uuid.New(),
		Email:       "editor@inflap.local",
		DisplayName: "Editor",
		Permissions: []enum.Permission{enum.PermissionHelpContentEdit},
	}
	publisher := &model.StaffUser{
		ID:          uuid.New(),
		Email:       "publisher@inflap.local",
		DisplayName: "Publisher",
		Permissions: []enum.Permission{enum.PermissionHelpContentPublish},
	}
	agent := &model.StaffUser{ID: uuid.New(), Permissions: []enum.Permission{enum.PermissionSupportReply}}

	_, err := uc.UpsertHelpArticle(context.Background(), agent, model.HelpArticleUpsertInput{
		ArticleID: "refund-policy",
		Slug:      "refund-policy",
	}, RequestMetadata{RequestID: "req-denied"})
	if err != ErrPermissionDenied {
		t.Fatalf("err = %v, want ErrPermissionDenied", err)
	}

	_, err = uc.UpsertHelpArticle(context.Background(), editor, model.HelpArticleUpsertInput{
		ArticleID: "refund-policy",
		Slug:      "refund-policy",
		Translations: map[string]model.HelpArticleTranslation{
			"en": {Title: "Refund policy", ShortAnswer: "Refund timing depends on the provider.", Body: "Open booking details."},
			"ru": {Title: "Правила возврата", ShortAnswer: "Срок зависит от провайдера.", Body: "Откройте детали бронирования."},
			"kk": {Title: "Қайтарым ережелері", ShortAnswer: "Мерзім провайдерге байланысты.", Body: "Брондау деталін ашыңыз."},
		},
	}, RequestMetadata{RequestID: "req-edit"})
	if err != nil {
		t.Fatalf("UpsertHelpArticle returned error: %v", err)
	}
	if client.lastHelpArticleUpsert.ActorStaffID != editor.ID.String() {
		t.Fatalf("upsert actor = %#v", client.lastHelpArticleUpsert)
	}

	article, err := uc.PublishHelpArticle(context.Background(), publisher, "refund-policy", RequestMetadata{RequestID: "req-publish"})
	if err != nil {
		t.Fatalf("PublishHelpArticle returned error: %v", err)
	}
	if article.Status != model.HelpArticleStatusPublished {
		t.Fatalf("article status = %q", article.Status)
	}
	if len(audit.events) != 2 ||
		audit.events[0].Action != "help.article.upsert" ||
		audit.events[1].Action != "help.article.publish" {
		t.Fatalf("audit events = %#v", audit.events)
	}
}

func TestSupportUseCaseHelpCategoryWorkflowRequiresHelpContentPermissionAndAudits(t *testing.T) {
	client := &supportClientStub{
		helpCategories: []model.HelpCategory{
			{ID: "payments", Slug: "payments", Status: model.HelpArticleStatusPublished, SortOrder: 20},
		},
	}
	audit := &supportAuditStub{}
	uc := NewSupportUseCase(client, audit)
	editor := &model.StaffUser{
		ID:          uuid.New(),
		Email:       "editor@inflap.local",
		DisplayName: "Editor",
		Permissions: []enum.Permission{enum.PermissionHelpContentEdit},
	}
	agent := &model.StaffUser{ID: uuid.New(), Permissions: []enum.Permission{enum.PermissionSupportReply}}

	_, err := uc.ListHelpCategories(context.Background(), agent, model.HelpCategoryFilter{})
	if err != ErrPermissionDenied {
		t.Fatalf("list err = %v, want ErrPermissionDenied", err)
	}
	_, err = uc.UpsertHelpCategory(context.Background(), agent, model.HelpCategoryUpsertInput{
		CategoryID: "safety",
		Slug:       "safety",
		Status:     model.HelpArticleStatusPublished,
	}, RequestMetadata{RequestID: "req-denied"})
	if err != ErrPermissionDenied {
		t.Fatalf("upsert err = %v, want ErrPermissionDenied", err)
	}

	categories, err := uc.ListHelpCategories(context.Background(), editor, model.HelpCategoryFilter{})
	if err != nil {
		t.Fatalf("ListHelpCategories returned error: %v", err)
	}
	if len(categories) != 1 || categories[0].ID != "payments" {
		t.Fatalf("categories = %#v", categories)
	}
	if client.lastHelpCategoryFilter.Limit != 50 {
		t.Fatalf("category limit = %d, want 50", client.lastHelpCategoryFilter.Limit)
	}

	category, err := uc.UpsertHelpCategory(context.Background(), editor, model.HelpCategoryUpsertInput{
		CategoryID: "safety",
		Slug:       "safety",
		Status:     model.HelpArticleStatusPublished,
		SortOrder:  5,
	}, RequestMetadata{RequestID: "req-category", IPAddress: "127.0.0.1", UserAgent: "test"})
	if err != nil {
		t.Fatalf("UpsertHelpCategory returned error: %v", err)
	}
	if category.ID != "safety" || client.lastHelpCategoryUpsert.ActorStaffID != editor.ID.String() {
		t.Fatalf("category = %#v input = %#v", category, client.lastHelpCategoryUpsert)
	}
	if len(audit.events) != 1 || audit.events[0].Action != "help.category.upsert" || audit.events[0].EntityType != "help_category" {
		t.Fatalf("audit events = %#v", audit.events)
	}
}

type supportClientStub struct {
	tickets                []model.SupportTicket
	detail                 model.SupportTicketDetail
	replyTicket            model.SupportTicket
	savedReplies           []model.SupportSavedReply
	helpArticle            model.HelpArticle
	helpCategories         []model.HelpCategory
	analytics              model.HelpAnalyticsSummary
	agents                 []model.SupportAgent
	userSegment            model.SupportUserSegment
	lastFilter             model.SupportTicketFilter
	lastReply              model.SupportTicketReplyInput
	lastAgentFilter        model.SupportAgentFilter
	lastAgentUpsert        model.SupportAgentUpsertInput
	lastSegmentUpsert      model.SupportUserSegmentUpsertInput
	lastSavedReplyFilter   model.SupportSavedReplyFilter
	lastSavedReplyUpsert   model.SupportSavedReplyUpsertInput
	lastHelpArticleUpsert  model.HelpArticleUpsertInput
	lastHelpCategoryFilter model.HelpCategoryFilter
	lastHelpCategoryUpsert model.HelpCategoryUpsertInput
}

func (s *supportClientStub) ListTickets(_ context.Context, filter model.SupportTicketFilter) ([]model.SupportTicket, error) {
	s.lastFilter = filter
	return s.tickets, nil
}

func (s *supportClientStub) GetTicket(context.Context, string) (model.SupportTicketDetail, error) {
	return s.detail, nil
}

func (s *supportClientStub) AssignTicket(_ context.Context, input model.SupportTicketAssignInput) (model.SupportTicket, error) {
	return model.SupportTicket{ID: input.TicketID, AssigneeID: input.AssigneeID}, nil
}

func (s *supportClientStub) ReplyTicket(_ context.Context, input model.SupportTicketReplyInput) (model.SupportTicket, error) {
	s.lastReply = input
	return s.replyTicket, nil
}

func (s *supportClientStub) AddTicketNote(context.Context, model.SupportTicketNoteInput) error {
	return nil
}

func (s *supportClientStub) ResolveTicket(_ context.Context, input model.SupportTicketResolveInput) (model.SupportTicket, error) {
	return model.SupportTicket{ID: input.TicketID, Status: model.SupportTicketStatusResolved}, nil
}

func (s *supportClientStub) ReopenTicket(_ context.Context, input model.SupportTicketReopenInput) (model.SupportTicket, error) {
	return model.SupportTicket{ID: input.TicketID, Status: model.SupportTicketStatusReopened}, nil
}

func (s *supportClientStub) ListSupportAgents(_ context.Context, filter model.SupportAgentFilter) ([]model.SupportAgent, error) {
	s.lastAgentFilter = filter
	return s.agents, nil
}

func (s *supportClientStub) UpsertSupportAgent(_ context.Context, input model.SupportAgentUpsertInput) (model.SupportAgent, error) {
	s.lastAgentUpsert = input
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

func (s *supportClientStub) GetSupportUserSegment(context.Context, string) (model.SupportUserSegment, error) {
	return s.userSegment, nil
}

func (s *supportClientStub) UpsertSupportUserSegment(_ context.Context, input model.SupportUserSegmentUpsertInput) (model.SupportUserSegment, error) {
	s.lastSegmentUpsert = input
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

func (s *supportClientStub) ListSupportSavedReplies(_ context.Context, filter model.SupportSavedReplyFilter) ([]model.SupportSavedReply, error) {
	s.lastSavedReplyFilter = filter
	return s.savedReplies, nil
}

func (s *supportClientStub) UpsertSupportSavedReply(_ context.Context, input model.SupportSavedReplyUpsertInput) (model.SupportSavedReply, error) {
	s.lastSavedReplyUpsert = input
	return model.SupportSavedReply{
		ID:           input.ReplyID,
		Category:     input.Category,
		Status:       input.Status,
		Tags:         input.Tags,
		Translations: input.Translations,
		SortOrder:    input.SortOrder,
	}, nil
}

func (s *supportClientStub) ListHelpCategories(_ context.Context, filter model.HelpCategoryFilter) ([]model.HelpCategory, error) {
	s.lastHelpCategoryFilter = filter
	return s.helpCategories, nil
}

func (s *supportClientStub) UpsertHelpCategory(_ context.Context, input model.HelpCategoryUpsertInput) (model.HelpCategory, error) {
	s.lastHelpCategoryUpsert = input
	return model.HelpCategory{
		ID:        input.CategoryID,
		Slug:      input.Slug,
		Status:    input.Status,
		SortOrder: input.SortOrder,
	}, nil
}

func (s *supportClientStub) ListHelpArticles(context.Context, model.HelpArticleFilter) ([]model.HelpArticle, error) {
	return []model.HelpArticle{s.helpArticle}, nil
}

func (s *supportClientStub) GetHelpArticle(context.Context, string) (model.HelpArticleDetail, error) {
	return model.HelpArticleDetail{Article: s.helpArticle}, nil
}

func (s *supportClientStub) GetHelpAnalytics(context.Context, int) (model.HelpAnalyticsSummary, error) {
	return s.analytics, nil
}

func (s *supportClientStub) UpsertHelpArticle(_ context.Context, input model.HelpArticleUpsertInput) (model.HelpArticle, error) {
	s.lastHelpArticleUpsert = input
	return model.HelpArticle{ID: input.ArticleID, Slug: input.Slug, Status: model.HelpArticleStatusDraft}, nil
}

func (s *supportClientStub) SubmitHelpArticleForReview(_ context.Context, articleID string, _ model.HelpArticleActionInput) (model.HelpArticle, error) {
	return model.HelpArticle{ID: articleID, Status: model.HelpArticleStatusReview}, nil
}

func (s *supportClientStub) PublishHelpArticle(_ context.Context, articleID string, _ model.HelpArticleActionInput) (model.HelpArticle, error) {
	return model.HelpArticle{ID: articleID, Status: model.HelpArticleStatusPublished}, nil
}

func (s *supportClientStub) ArchiveHelpArticle(_ context.Context, articleID string, _ model.HelpArticleActionInput) (model.HelpArticle, error) {
	return model.HelpArticle{ID: articleID, Status: model.HelpArticleStatusArchived}, nil
}

type supportAuditStub struct {
	events []*model.AuditEvent
}

type supportFileDownloadClientStub struct {
	calls       int
	fileID      uuid.UUID
	downloadURL string
	expiresAt   time.Time
}

func (s *supportFileDownloadClientStub) CreateDownloadURL(_ context.Context, fileID uuid.UUID) (model.FileDownloadURL, error) {
	s.calls++
	s.fileID = fileID
	return model.FileDownloadURL{URL: s.downloadURL, ExpiresAt: s.expiresAt}, nil
}

func (s *supportAuditStub) Append(_ context.Context, event *model.AuditEvent) error {
	s.events = append(s.events, event)
	return nil
}

func (s *supportAuditStub) List(context.Context, model.AuditFilter) ([]*model.AuditEvent, error) {
	return nil, nil
}
