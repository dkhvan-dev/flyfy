package app

import (
	"context"
	"encoding/json"
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/admin-panel/internal/domain/enum"
	"kz/inflap/backend/services/admin-panel/internal/domain/model"
	"kz/inflap/backend/services/admin-panel/internal/domain/port"
)

func TestDecideExcursionSupersedesPreviousAppliedDecision(t *testing.T) {
	t.Parallel()

	actor := &model.StaffUser{
		ID:          uuid.New(),
		Email:       "moderator@inflap.local",
		DisplayName: "Moderator",
		Status:      enum.StaffStatusActive,
		Permissions: []enum.Permission{
			enum.PermissionModerationRead,
			enum.PermissionExcursionModerate,
		},
	}
	caseID := uuid.New()
	excursionID := uuid.New()
	repo := &moderationRepoStub{
		item: &model.ModerationCase{
			ID:             caseID,
			TargetType:     model.ModerationTargetExcursion,
			TargetID:       excursionID,
			SourceRevision: 2,
			Status:         enum.ModerationCaseStatusRejected,
			CreatedAt:      time.Now().UTC(),
			UpdatedAt:      time.Now().UTC(),
		},
	}
	excursion := &moderationExcursionClientStub{
		item: &model.ExcursionModerationItem{
			ID:       excursionID,
			Revision: 2,
			Status:   "PUBLISHED",
		},
	}
	uc := NewModerationUseCase(repo, excursion, &moderationActivityClientStub{}, &moderationGuideClientStub{}, &moderationChatClientStub{}, &moderationAuditRepoStub{})

	_, err := uc.DecideExcursion(context.Background(), ModerationDecisionInput{
		Actor:           actor,
		CaseID:          caseID,
		Decision:        enum.ModerationDecisionApprove,
		InternalComment: "Повторная проверка пройдена.",
		IdempotencyKey:  "approve-again",
	})

	if err != nil {
		t.Fatalf("DecideExcursion() error = %v", err)
	}
	if repo.supersededCaseID != caseID {
		t.Fatalf("supersededCaseID = %s, want %s", repo.supersededCaseID, caseID)
	}
	if repo.supersededRevision != 2 {
		t.Fatalf("supersededRevision = %d, want 2", repo.supersededRevision)
	}
	if repo.supersededExceptDecisionID == uuid.Nil {
		t.Fatal("new decision id was not excluded from superseding")
	}
}

func TestSyncActivityQueueUpsertsActiveFlaggedActivityCases(t *testing.T) {
	t.Parallel()

	actor := &model.StaffUser{
		ID:          uuid.New(),
		Email:       "activity-moderator@inflap.local",
		DisplayName: "Activity Moderator",
		Status:      enum.StaffStatusActive,
		Permissions: []enum.Permission{
			enum.PermissionModerationRead,
		},
	}
	activityID := uuid.New()
	repo := &moderationRepoStub{}
	activity := &moderationActivityClientStub{
		items: []model.ActivityModerationItem{
			{
				ID:                    activityID,
				Title:                 "VIP hiking trip",
				Status:                "ENROLLMENT_OPEN",
				ModerationStatus:      "FLAGGED",
				ModerationRiskScore:   70,
				ModerationReasonCodes: []string{"external_contact"},
				Revision:              3,
			},
		},
	}
	uc := NewModerationUseCase(repo, &moderationExcursionClientStub{}, activity, &moderationGuideClientStub{}, &moderationChatClientStub{}, &moderationAuditRepoStub{})

	if err := uc.SyncActivityQueue(context.Background(), actor); err != nil {
		t.Fatalf("SyncActivityQueue() error = %v", err)
	}
	if len(repo.upsertedActivities) != 1 {
		t.Fatalf("upserted activities = %d, want 1", len(repo.upsertedActivities))
	}
	if repo.upsertedActivities[0].ID != activityID {
		t.Fatalf("upserted activity id = %s, want %s", repo.upsertedActivities[0].ID, activityID)
	}
	if len(repo.cancelledActivityIDs) != 1 || repo.cancelledActivityIDs[0] != activityID {
		t.Fatalf("cancelled stale active ids = %#v, want [%s]", repo.cancelledActivityIDs, activityID)
	}
}

func TestFeedQualityDashboardRequiresModerationReadAndUsesStoryClient(t *testing.T) {
	t.Parallel()

	actor := &model.StaffUser{
		ID:          uuid.New(),
		Email:       "quality@inflap.local",
		DisplayName: "Quality Lead",
		Status:      enum.StaffStatusActive,
		Permissions: []enum.Permission{
			enum.PermissionModerationRead,
		},
	}
	since := time.Date(2026, 5, 1, 0, 0, 0, 0, time.UTC)
	until := since.Add(7 * 24 * time.Hour)
	posts := &moderationPostReportClientStub{
		feedQualityMetrics: []model.FeedQualityMetric{
			{
				Surface:            "home",
				BlockType:          "post_card",
				Action:             "conversion",
				EventCount:         10,
				UniqueViewers:      8,
				ConversionCount:    3,
				HideCount:          1,
				NotInterestedCount: 2,
			},
		},
	}
	uc := NewModerationUseCase(&moderationRepoStub{}, &moderationExcursionClientStub{}, &moderationActivityClientStub{}, &moderationGuideClientStub{}, &moderationChatClientStub{}, &moderationAuditRepoStub{})
	uc.SetPostReportClient(posts)

	page, err := uc.FeedQualityDashboard(context.Background(), actor, FeedQualityDashboardInput{
		Since:   since,
		Until:   until,
		Surface: "home",
		Limit:   500,
	})

	if err != nil {
		t.Fatalf("FeedQualityDashboard() error = %v", err)
	}
	if len(page.Metrics) != 1 {
		t.Fatalf("metrics length = %d, want 1", len(page.Metrics))
	}
	if page.Metrics[0].ConversionCount != 3 || page.Totals.NotInterestedCount != 2 {
		t.Fatalf("dashboard page = %+v, want converted and negative feedback totals", page)
	}
	if posts.lastFeedQualityFilter.Surface != "home" {
		t.Fatalf("surface = %q, want home", posts.lastFeedQualityFilter.Surface)
	}
	if posts.lastFeedQualityFilter.Limit != 200 {
		t.Fatalf("limit = %d, want clamp to 200", posts.lastFeedQualityFilter.Limit)
	}

	_, err = uc.FeedQualityDashboard(context.Background(), &model.StaffUser{ID: uuid.New()}, FeedQualityDashboardInput{})
	if !errors.Is(err, ErrPermissionDenied) {
		t.Fatalf("unauthorized error = %v, want ErrPermissionDenied", err)
	}
}

func TestSyncGuideApplicationQueueUpsertsPendingApplicationCases(t *testing.T) {
	t.Parallel()

	actor := &model.StaffUser{
		ID:          uuid.New(),
		Email:       "guide-moderator@inflap.local",
		DisplayName: "Guide Moderator",
		Status:      enum.StaffStatusActive,
		Permissions: []enum.Permission{
			enum.PermissionModerationRead,
		},
	}
	applicationID := uuid.New()
	repo := &moderationRepoStub{}
	guide := &moderationGuideClientStub{
		items: []model.GuideApplicationModerationItem{
			{
				ID:               applicationID,
				GuideDisplayName: "Aruzhan Nomad",
				FirstName:        "Aruzhan",
				LastName:         "Khan",
				Status:           "SUBMITTED",
				GuideStatus:      "PENDING_REVIEW",
				Revision:         5,
				SubmittedAt:      timePtr(time.Now().UTC()),
			},
		},
	}
	uc := NewModerationUseCase(repo, &moderationExcursionClientStub{}, &moderationActivityClientStub{}, guide, &moderationChatClientStub{}, &moderationAuditRepoStub{})

	if err := uc.SyncGuideApplicationQueue(context.Background(), actor); err != nil {
		t.Fatalf("SyncGuideApplicationQueue() error = %v", err)
	}
	if len(repo.upsertedGuideApplications) != 1 {
		t.Fatalf("upserted guide applications = %d, want 1", len(repo.upsertedGuideApplications))
	}
	if repo.upsertedGuideApplications[0].ID != applicationID {
		t.Fatalf("upserted guide application id = %s, want %s", repo.upsertedGuideApplications[0].ID, applicationID)
	}
	if len(repo.cancelledGuideApplicationIDs) != 1 || repo.cancelledGuideApplicationIDs[0] != applicationID {
		t.Fatalf("cancelled stale guide application ids = %#v, want [%s]", repo.cancelledGuideApplicationIDs, applicationID)
	}
}

func TestSyncChatMessageQueueUpsertsFlaggedMessageCases(t *testing.T) {
	t.Parallel()

	actor := &model.StaffUser{
		ID:          uuid.New(),
		Email:       "chat-moderator@inflap.local",
		DisplayName: "Chat Moderator",
		Status:      enum.StaffStatusActive,
		Permissions: []enum.Permission{
			enum.PermissionModerationRead,
		},
	}
	messageID := uuid.New()
	conversationID := uuid.New()
	repo := &moderationRepoStub{}
	chat := &moderationChatClientStub{
		items: []model.ChatMessageModerationItem{
			{
				ID:                    messageID,
				ConversationID:        conversationID,
				ConversationTitle:     "Medeu private tour",
				SenderDisplayName:     "Risky Sender",
				Content:               "Напишите мне в WhatsApp +77011234567",
				ModerationStatus:      "FLAGGED",
				ModerationRiskScore:   80,
				ModerationReasonCodes: []string{"off_platform_contact"},
				Revision:              2,
				SentAt:                time.Now().UTC(),
			},
		},
	}
	uc := NewModerationUseCase(repo, &moderationExcursionClientStub{}, &moderationActivityClientStub{}, &moderationGuideClientStub{}, chat, &moderationAuditRepoStub{})

	if err := uc.SyncChatMessageQueue(context.Background(), actor); err != nil {
		t.Fatalf("SyncChatMessageQueue() error = %v", err)
	}
	if len(repo.upsertedChatMessages) != 1 {
		t.Fatalf("upserted chat messages = %d, want 1", len(repo.upsertedChatMessages))
	}
	if repo.upsertedChatMessages[0].ID != messageID {
		t.Fatalf("upserted chat message id = %s, want %s", repo.upsertedChatMessages[0].ID, messageID)
	}
	if len(repo.cancelledChatMessageIDs) != 1 || repo.cancelledChatMessageIDs[0] != messageID {
		t.Fatalf("cancelled stale chat message ids = %#v, want [%s]", repo.cancelledChatMessageIDs, messageID)
	}
}

func TestSyncPostReportQueueUpsertsOpenReportCases(t *testing.T) {
	t.Parallel()

	actor := &model.StaffUser{
		ID:          uuid.New(),
		Email:       "moderation-lead@inflap.local",
		DisplayName: "Moderation Lead",
		Status:      enum.StaffStatusActive,
		Permissions: []enum.Permission{
			enum.PermissionModerationRead,
		},
	}
	reportID := uuid.New()
	postID := uuid.New()
	pendingPostID := uuid.New()
	communityID := uuid.New()
	repo := &moderationRepoStub{}
	postReports := &moderationPostReportClientStub{
		items: []model.PostReportModerationItem{
			{
				ID:                  reportID,
				PostID:              postID,
				CommunityID:         &communityID,
				ReporterUserID:      uuid.New(),
				AuthorUserID:        uuid.New(),
				Reason:              "HARASSMENT",
				Details:             "Threatening replies in a public travel post.",
				Status:              "OPEN",
				ModerationRiskScore: 80,
				Revision:            1,
				CreatedAt:           time.Now().UTC(),
				UpdatedAt:           time.Now().UTC(),
			},
		},
		postItems: []model.PostModerationItem{
			{
				ID:               pendingPostID,
				CommunityID:      &communityID,
				AuthorUserID:     uuid.New(),
				Title:            "Community post waiting for moderation",
				Excerpt:          "A fresh post from the mobile editor.",
				Status:           "PUBLISHED",
				ModerationStatus: "PENDING",
				Revision:         3,
				CreatedAt:        time.Now().UTC(),
				UpdatedAt:        time.Now().UTC(),
			},
		},
	}
	uc := NewModerationUseCase(repo, &moderationExcursionClientStub{}, &moderationActivityClientStub{}, &moderationGuideClientStub{}, &moderationChatClientStub{}, &moderationAuditRepoStub{})
	uc.SetPostReportClient(postReports)

	if err := uc.SyncPostReportQueue(context.Background(), actor); err != nil {
		t.Fatalf("SyncPostReportQueue() error = %v", err)
	}
	if len(repo.upsertedPostReports) != 1 {
		t.Fatalf("upserted post reports = %d, want 1", len(repo.upsertedPostReports))
	}
	if repo.upsertedPostReports[0].ID != reportID {
		t.Fatalf("upserted post report id = %s, want %s", repo.upsertedPostReports[0].ID, reportID)
	}
	if len(repo.cancelledPostReportIDs) != 1 || repo.cancelledPostReportIDs[0] != reportID {
		t.Fatalf("cancelled stale post report ids = %#v, want [%s]", repo.cancelledPostReportIDs, reportID)
	}
	if len(repo.upsertedPosts) != 1 {
		t.Fatalf("upserted community posts = %d, want 1", len(repo.upsertedPosts))
	}
	if repo.upsertedPosts[0].ID != pendingPostID {
		t.Fatalf("upserted community post id = %s, want %s", repo.upsertedPosts[0].ID, pendingPostID)
	}
	if len(repo.cancelledPostIDs) != 1 || repo.cancelledPostIDs[0] != pendingPostID {
		t.Fatalf("cancelled stale community post ids = %#v, want [%s]", repo.cancelledPostIDs, pendingPostID)
	}
}

func TestDecidePostReportReviewMarksReportReviewedAndCaseApproved(t *testing.T) {
	t.Parallel()

	actor := &model.StaffUser{
		ID:          uuid.New(),
		Email:       "moderation-lead@inflap.local",
		DisplayName: "Moderation Lead",
		Status:      enum.StaffStatusActive,
		Permissions: []enum.Permission{
			enum.PermissionModerationRead,
			enum.PermissionModerationAssign,
		},
	}
	caseID := uuid.New()
	reportID := uuid.New()
	communityID := uuid.New()
	repo := &moderationRepoStub{
		item: &model.ModerationCase{
			ID:             caseID,
			TargetType:     model.ModerationTargetPost,
			TargetID:       reportID,
			SourceRevision: 1,
			Status:         enum.ModerationCaseStatusOpen,
			CreatedAt:      time.Now().UTC(),
			UpdatedAt:      time.Now().UTC(),
		},
	}
	postReports := &moderationPostReportClientStub{
		item: &model.PostReportModerationItem{
			ID:          reportID,
			PostID:      uuid.New(),
			CommunityID: &communityID,
			Status:      "REVIEWED",
			Revision:    1,
			CreatedAt:   time.Now().UTC(),
			UpdatedAt:   time.Now().UTC(),
		},
	}
	uc := NewModerationUseCase(repo, &moderationExcursionClientStub{}, &moderationActivityClientStub{}, &moderationGuideClientStub{}, &moderationChatClientStub{}, &moderationAuditRepoStub{})
	uc.SetPostReportClient(postReports)

	_, err := uc.DecidePostReport(context.Background(), ModerationDecisionInput{
		Actor:           actor,
		CaseID:          caseID,
		Decision:        enum.ModerationDecisionApprove,
		InternalComment: "Confirmed policy violation and reviewed the report.",
		IdempotencyKey:  "post-report-review",
		RequestMetadata: RequestMetadata{RequestID: "request-1"},
	})

	if err != nil {
		t.Fatalf("DecidePostReport() error = %v", err)
	}
	if postReports.lastReviewInput.ReportID != reportID {
		t.Fatalf("reviewed report id = %s, want %s", postReports.lastReviewInput.ReportID, reportID)
	}
	if postReports.lastReviewInput.InternalComment != "Confirmed policy violation and reviewed the report." {
		t.Fatalf("internal comment sent to feed-service = %q", postReports.lastReviewInput.InternalComment)
	}
	if postReports.lastReviewInput.RequestID != "request-1" {
		t.Fatalf("request id = %q, want request-1", postReports.lastReviewInput.RequestID)
	}
	if repo.item.Status != enum.ModerationCaseStatusApproved {
		t.Fatalf("case status = %s, want %s", repo.item.Status, enum.ModerationCaseStatusApproved)
	}
}

func TestDecidePostReportApproveRoutesCommunityPostToStoryReview(t *testing.T) {
	t.Parallel()

	actor := &model.StaffUser{
		ID:          uuid.New(),
		Email:       "moderation-lead@inflap.local",
		DisplayName: "Moderation Lead",
		Status:      enum.StaffStatusActive,
		Permissions: []enum.Permission{
			enum.PermissionModerationRead,
			enum.PermissionModerationAssign,
		},
	}
	caseID := uuid.New()
	postID := uuid.New()
	communityID := uuid.New()
	metadata, _ := json.Marshal(map[string]string{"moderationKind": "community_post"})
	repo := &moderationRepoStub{
		item: &model.ModerationCase{
			ID:             caseID,
			TargetType:     model.ModerationTargetPost,
			TargetID:       postID,
			SourceRevision: 4,
			Status:         enum.ModerationCaseStatusOpen,
			Metadata:       metadata,
			CreatedAt:      time.Now().UTC(),
			UpdatedAt:      time.Now().UTC(),
		},
	}
	posts := &moderationPostReportClientStub{
		storyItem: &model.PostModerationItem{
			ID:               postID,
			CommunityID:      &communityID,
			AuthorUserID:     uuid.New(),
			Title:            "Community post",
			Status:           "PUBLISHED",
			ModerationStatus: "APPROVED",
			Revision:         5,
			CreatedAt:        time.Now().UTC(),
			UpdatedAt:        time.Now().UTC(),
		},
	}
	uc := NewModerationUseCase(repo, &moderationExcursionClientStub{}, &moderationActivityClientStub{}, &moderationGuideClientStub{}, &moderationChatClientStub{}, &moderationAuditRepoStub{})
	uc.SetPostReportClient(posts)

	detail, err := uc.DecidePostReport(context.Background(), ModerationDecisionInput{
		Actor:           actor,
		CaseID:          caseID,
		Decision:        enum.ModerationDecisionApprove,
		InternalComment: "Post follows the community rules.",
		IdempotencyKey:  "community-post-approve",
		RequestMetadata: RequestMetadata{RequestID: "request-2"},
	})

	if err != nil {
		t.Fatalf("DecidePostReport() error = %v", err)
	}
	if posts.lastApproveStoryInput.PostID != postID ||
		posts.lastApproveStoryInput.ActorStaffID != actor.ID ||
		posts.lastApproveStoryInput.InternalComment != "Post follows the community rules." ||
		posts.lastApproveStoryInput.RequestID != "request-2" {
		t.Fatalf("community post approve input = %+v", posts.lastApproveStoryInput)
	}
	if repo.createdDecision == nil || repo.createdDecision.SourceRevision != 4 {
		t.Fatalf("created decision = %+v, want source revision 4", repo.createdDecision)
	}
	if detail == nil || detail.Post == nil || detail.Post.ID != postID {
		t.Fatalf("detail post = %+v, want post %s", detail, postID)
	}
}

func TestDecidePostReportDismissRequiresInternalComment(t *testing.T) {
	t.Parallel()

	actor := &model.StaffUser{
		ID:          uuid.New(),
		Email:       "moderation-lead@inflap.local",
		DisplayName: "Moderation Lead",
		Status:      enum.StaffStatusActive,
		Permissions: []enum.Permission{
			enum.PermissionModerationRead,
			enum.PermissionModerationAssign,
		},
	}
	caseID := uuid.New()
	reportID := uuid.New()
	repo := &moderationRepoStub{
		item: &model.ModerationCase{
			ID:             caseID,
			TargetType:     model.ModerationTargetPost,
			TargetID:       reportID,
			SourceRevision: 1,
			Status:         enum.ModerationCaseStatusOpen,
			CreatedAt:      time.Now().UTC(),
			UpdatedAt:      time.Now().UTC(),
		},
	}
	postReports := &moderationPostReportClientStub{}
	uc := NewModerationUseCase(repo, &moderationExcursionClientStub{}, &moderationActivityClientStub{}, &moderationGuideClientStub{}, &moderationChatClientStub{}, &moderationAuditRepoStub{})
	uc.SetPostReportClient(postReports)

	_, err := uc.DecidePostReport(context.Background(), ModerationDecisionInput{
		Actor:          actor,
		CaseID:         caseID,
		Decision:       enum.ModerationDecisionReject,
		IdempotencyKey: "post-report-dismiss",
	})

	if !errors.Is(err, ErrInvalidInput) {
		t.Fatalf("DecidePostReport() error = %v, want %v", err, ErrInvalidInput)
	}
	if repo.createdDecision != nil {
		t.Fatal("DecidePostReport() created decision without mandatory internal comment")
	}
	if postReports.lastDismissInput.ReportID != uuid.Nil {
		t.Fatal("DecidePostReport() called feed-service without mandatory internal comment")
	}
}

func TestDecideChatMessageRejectRequiresPublicAndInternalComments(t *testing.T) {
	t.Parallel()

	actor := &model.StaffUser{
		ID:          uuid.New(),
		Email:       "chat-moderator@inflap.local",
		DisplayName: "Chat Moderator",
		Status:      enum.StaffStatusActive,
		Permissions: []enum.Permission{
			enum.PermissionModerationRead,
			enum.PermissionChatModerate,
		},
	}
	caseID := uuid.New()
	messageID := uuid.New()

	for _, tc := range []struct {
		name            string
		publicComment   string
		internalComment string
	}{
		{name: "missing public comment", internalComment: "Off-platform contact confirmed."},
		{name: "missing internal comment", publicComment: "Сообщение скрыто из-за попытки увести общение из Inflap."},
	} {
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()

			repo := &moderationRepoStub{
				item: &model.ModerationCase{
					ID:             caseID,
					TargetType:     model.ModerationTargetChatMessage,
					TargetID:       messageID,
					SourceRevision: 2,
					Status:         enum.ModerationCaseStatusOpen,
					CreatedAt:      time.Now().UTC(),
					UpdatedAt:      time.Now().UTC(),
				},
			}
			chat := &moderationChatClientStub{
				item: &model.ChatMessageModerationItem{
					ID:               messageID,
					Revision:         2,
					ModerationStatus: "FLAGGED",
				},
			}
			uc := NewModerationUseCase(repo, &moderationExcursionClientStub{}, &moderationActivityClientStub{}, &moderationGuideClientStub{}, chat, &moderationAuditRepoStub{})

			_, err := uc.DecideChatMessage(context.Background(), ModerationDecisionInput{
				Actor:           actor,
				CaseID:          caseID,
				Decision:        enum.ModerationDecisionReject,
				ReasonCodes:     []string{"off_platform_contact"},
				PublicComment:   tc.publicComment,
				InternalComment: tc.internalComment,
				IdempotencyKey:  "chat-hide",
			})

			if !errors.Is(err, ErrInvalidInput) {
				t.Fatalf("DecideChatMessage() error = %v, want %v", err, ErrInvalidInput)
			}
			if repo.createdDecision != nil {
				t.Fatal("DecideChatMessage() created decision without mandatory comments")
			}
			if chat.lastHideInput.MessageID != uuid.Nil {
				t.Fatal("DecideChatMessage() called chat service without mandatory comments")
			}
		})
	}
}

func TestDecideChatMessageRejectHidesMessageAndMarksCaseRejected(t *testing.T) {
	t.Parallel()

	actor := &model.StaffUser{
		ID:          uuid.New(),
		Email:       "chat-moderator@inflap.local",
		DisplayName: "Chat Moderator",
		Status:      enum.StaffStatusActive,
		Permissions: []enum.Permission{
			enum.PermissionModerationRead,
			enum.PermissionChatModerate,
		},
	}
	caseID := uuid.New()
	messageID := uuid.New()
	repo := &moderationRepoStub{
		item: &model.ModerationCase{
			ID:             caseID,
			TargetType:     model.ModerationTargetChatMessage,
			TargetID:       messageID,
			SourceRevision: 2,
			Status:         enum.ModerationCaseStatusOpen,
			CreatedAt:      time.Now().UTC(),
			UpdatedAt:      time.Now().UTC(),
		},
	}
	chat := &moderationChatClientStub{
		item: &model.ChatMessageModerationItem{
			ID:               messageID,
			Revision:         3,
			ModerationStatus: "HIDDEN_BY_MODERATION",
		},
	}
	uc := NewModerationUseCase(repo, &moderationExcursionClientStub{}, &moderationActivityClientStub{}, &moderationGuideClientStub{}, chat, &moderationAuditRepoStub{})

	_, err := uc.DecideChatMessage(context.Background(), ModerationDecisionInput{
		Actor:           actor,
		CaseID:          caseID,
		Decision:        enum.ModerationDecisionReject,
		ReasonCodes:     []string{"off_platform_contact"},
		PublicComment:   "Сообщение скрыто из-за попытки увести общение из Inflap.",
		InternalComment: "Phone number and WhatsApp mention confirmed.",
		IdempotencyKey:  "chat-hide",
	})

	if err != nil {
		t.Fatalf("DecideChatMessage() error = %v", err)
	}
	if chat.lastHideInput.MessageID != messageID {
		t.Fatalf("hidden message id = %s, want %s", chat.lastHideInput.MessageID, messageID)
	}
	if chat.lastHideInput.PublicComment == "" {
		t.Fatal("public comment must be sent to chat service")
	}
	if repo.item.Status != enum.ModerationCaseStatusRejected {
		t.Fatalf("case status = %s, want %s", repo.item.Status, enum.ModerationCaseStatusRejected)
	}
}

func TestDecideChatMessageApproveMarksMessageSafe(t *testing.T) {
	t.Parallel()

	actor := &model.StaffUser{
		ID:          uuid.New(),
		Email:       "chat-moderator@inflap.local",
		DisplayName: "Chat Moderator",
		Status:      enum.StaffStatusActive,
		Permissions: []enum.Permission{
			enum.PermissionModerationRead,
			enum.PermissionChatModerate,
		},
	}
	caseID := uuid.New()
	messageID := uuid.New()
	repo := &moderationRepoStub{
		item: &model.ModerationCase{
			ID:             caseID,
			TargetType:     model.ModerationTargetChatMessage,
			TargetID:       messageID,
			SourceRevision: 2,
			Status:         enum.ModerationCaseStatusOpen,
			CreatedAt:      time.Now().UTC(),
			UpdatedAt:      time.Now().UTC(),
		},
	}
	chat := &moderationChatClientStub{
		item: &model.ChatMessageModerationItem{
			ID:               messageID,
			Revision:         3,
			ModerationStatus: "CLEARED",
		},
	}
	uc := NewModerationUseCase(repo, &moderationExcursionClientStub{}, &moderationActivityClientStub{}, &moderationGuideClientStub{}, chat, &moderationAuditRepoStub{})

	_, err := uc.DecideChatMessage(context.Background(), ModerationDecisionInput{
		Actor:           actor,
		CaseID:          caseID,
		Decision:        enum.ModerationDecisionApprove,
		InternalComment: "Context reviewed, no violation.",
		IdempotencyKey:  "chat-safe",
	})

	if err != nil {
		t.Fatalf("DecideChatMessage() error = %v", err)
	}
	if chat.lastApproveInput.MessageID != messageID {
		t.Fatalf("approved message id = %s, want %s", chat.lastApproveInput.MessageID, messageID)
	}
	if repo.item.Status != enum.ModerationCaseStatusApproved {
		t.Fatalf("case status = %s, want %s", repo.item.Status, enum.ModerationCaseStatusApproved)
	}
}

func TestDecideActivityApproveKeepsCaseAuditedAndApplied(t *testing.T) {
	t.Parallel()

	actor := &model.StaffUser{
		ID:          uuid.New(),
		Email:       "activity-moderator@inflap.local",
		DisplayName: "Activity Moderator",
		Status:      enum.StaffStatusActive,
		Permissions: []enum.Permission{
			enum.PermissionModerationRead,
			enum.PermissionActivityModerate,
		},
	}
	caseID := uuid.New()
	activityID := uuid.New()
	repo := &moderationRepoStub{
		item: &model.ModerationCase{
			ID:             caseID,
			TargetType:     model.ModerationTargetActivity,
			TargetID:       activityID,
			SourceRevision: 3,
			Status:         enum.ModerationCaseStatusOpen,
			CreatedAt:      time.Now().UTC(),
			UpdatedAt:      time.Now().UTC(),
		},
	}
	activity := &moderationActivityClientStub{
		item: &model.ActivityModerationItem{
			ID:               activityID,
			Revision:         3,
			Status:           "ENROLLMENT_OPEN",
			ModerationStatus: "APPROVED",
		},
	}
	uc := NewModerationUseCase(repo, &moderationExcursionClientStub{}, activity, &moderationGuideClientStub{}, &moderationChatClientStub{}, &moderationAuditRepoStub{})

	_, err := uc.DecideActivity(context.Background(), ModerationDecisionInput{
		Actor:           actor,
		CaseID:          caseID,
		Decision:        enum.ModerationDecisionApprove,
		InternalComment: "Signals reviewed.",
		IdempotencyKey:  "activity-approve",
	})

	if err != nil {
		t.Fatalf("DecideActivity() error = %v", err)
	}
	if repo.createdDecision == nil {
		t.Fatal("DecideActivity() did not create moderation decision")
	}
	if repo.createdDecision.DecisionType != enum.ModerationDecisionApprove {
		t.Fatalf("decision type = %s, want %s", repo.createdDecision.DecisionType, enum.ModerationDecisionApprove)
	}
	if repo.item.Status != enum.ModerationCaseStatusApproved {
		t.Fatalf("case status = %s, want %s", repo.item.Status, enum.ModerationCaseStatusApproved)
	}
}

func TestDecideActivityApproveNotifiesHost(t *testing.T) {
	t.Parallel()

	actor := &model.StaffUser{
		ID:          uuid.New(),
		Email:       "activity-moderator@inflap.local",
		DisplayName: "Activity Moderator",
		Status:      enum.StaffStatusActive,
		Permissions: []enum.Permission{
			enum.PermissionModerationRead,
			enum.PermissionActivityModerate,
		},
	}
	caseID := uuid.New()
	activityID := uuid.New()
	hostUserID := uuid.New()
	repo := &moderationRepoStub{
		item: &model.ModerationCase{
			ID:             caseID,
			TargetType:     model.ModerationTargetActivity,
			TargetID:       activityID,
			SourceRevision: 3,
			Status:         enum.ModerationCaseStatusOpen,
			CreatedAt:      time.Now().UTC(),
			UpdatedAt:      time.Now().UTC(),
		},
	}
	activity := &moderationActivityClientStub{
		item: &model.ActivityModerationItem{
			ID:               activityID,
			HostUserID:       hostUserID,
			Title:            "Medeu sunset walk",
			Revision:         3,
			Status:           "ENROLLMENT_OPEN",
			ModerationStatus: "APPROVED",
		},
	}
	notifications := make(chan port.UserNotificationInput, 1)
	uc := NewModerationUseCase(repo, &moderationExcursionClientStub{}, activity, &moderationGuideClientStub{}, &moderationChatClientStub{}, &moderationAuditRepoStub{})
	uc.SetNotificationGateway(adminNotificationGatewayStub{
		send: func(ctx context.Context, input port.UserNotificationInput) error {
			notifications <- input
			return nil
		},
	})

	_, err := uc.DecideActivity(context.Background(), ModerationDecisionInput{
		Actor:           actor,
		CaseID:          caseID,
		Decision:        enum.ModerationDecisionApprove,
		InternalComment: "Signals reviewed.",
		IdempotencyKey:  "activity-approve",
	})

	if err != nil {
		t.Fatalf("DecideActivity() error = %v", err)
	}
	got := waitAdminNotification(t, notifications)
	if len(got.RecipientUserIDs) != 1 || got.RecipientUserIDs[0] != hostUserID {
		t.Fatalf("recipient user ids = %v, want host %s", got.RecipientUserIDs, hostUserID)
	}
	if got.IdempotencyKey != "admin:moderation:activity-approve:activity_approved" {
		t.Fatalf("idempotency key = %q", got.IdempotencyKey)
	}
	if got.Category != "activity" || got.Priority != "normal" {
		t.Fatalf("category/priority = %q/%q, want activity/normal", got.Category, got.Priority)
	}
	if got.DeepLink != "/activities/"+activityID.String() {
		t.Fatalf("deep link = %q", got.DeepLink)
	}
	if got.CollapseKey != "admin:moderation:activity:"+activityID.String() {
		t.Fatalf("collapse key = %q", got.CollapseKey)
	}
	if got.Data["adminEvent"] != "activity_approved" ||
		got.Data["caseId"] != caseID.String() ||
		got.Data["targetType"] != string(model.ModerationTargetActivity) ||
		got.Data["targetId"] != activityID.String() ||
		got.Data["decision"] != string(enum.ModerationDecisionApprove) {
		t.Fatalf("notification data = %#v", got.Data)
	}
}

func TestDecideActivityRejectRequiresPublicAndInternalComments(t *testing.T) {
	t.Parallel()

	actor := &model.StaffUser{
		ID:          uuid.New(),
		Email:       "activity-moderator@inflap.local",
		DisplayName: "Activity Moderator",
		Status:      enum.StaffStatusActive,
		Permissions: []enum.Permission{
			enum.PermissionModerationRead,
			enum.PermissionActivityModerate,
		},
	}
	caseID := uuid.New()
	activityID := uuid.New()

	for _, tc := range []struct {
		name            string
		publicComment   string
		internalComment string
	}{
		{name: "missing public comment", internalComment: "External contact confirmed."},
		{name: "missing internal comment", publicComment: "Уберите контактные данные из описания."},
	} {
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()

			repo := &moderationRepoStub{
				item: &model.ModerationCase{
					ID:             caseID,
					TargetType:     model.ModerationTargetActivity,
					TargetID:       activityID,
					SourceRevision: 3,
					Status:         enum.ModerationCaseStatusOpen,
					CreatedAt:      time.Now().UTC(),
					UpdatedAt:      time.Now().UTC(),
				},
			}
			activity := &moderationActivityClientStub{
				item: &model.ActivityModerationItem{
					ID:               activityID,
					Revision:         3,
					Status:           "ENROLLMENT_OPEN",
					ModerationStatus: "FLAGGED",
				},
			}
			uc := NewModerationUseCase(repo, &moderationExcursionClientStub{}, activity, &moderationGuideClientStub{}, &moderationChatClientStub{}, &moderationAuditRepoStub{})

			_, err := uc.DecideActivity(context.Background(), ModerationDecisionInput{
				Actor:           actor,
				CaseID:          caseID,
				Decision:        enum.ModerationDecisionReject,
				ReasonCodes:     []string{"external_contact"},
				PublicComment:   tc.publicComment,
				InternalComment: tc.internalComment,
				IdempotencyKey:  "activity-reject",
			})

			if !errors.Is(err, ErrInvalidInput) {
				t.Fatalf("DecideActivity() error = %v, want %v", err, ErrInvalidInput)
			}
			if repo.createdDecision != nil {
				t.Fatal("DecideActivity() created decision without mandatory comments")
			}
			if activity.lastRejectInput.ActivityID != uuid.Nil {
				t.Fatal("DecideActivity() called activity service without mandatory comments")
			}
		})
	}
}

func TestDecideActivityRejectSendsPublicCommentToActivityService(t *testing.T) {
	t.Parallel()

	actor := &model.StaffUser{
		ID:          uuid.New(),
		Email:       "activity-moderator@inflap.local",
		DisplayName: "Activity Moderator",
		Status:      enum.StaffStatusActive,
		Permissions: []enum.Permission{
			enum.PermissionModerationRead,
			enum.PermissionActivityModerate,
		},
	}
	caseID := uuid.New()
	activityID := uuid.New()
	repo := &moderationRepoStub{
		item: &model.ModerationCase{
			ID:             caseID,
			TargetType:     model.ModerationTargetActivity,
			TargetID:       activityID,
			SourceRevision: 3,
			Status:         enum.ModerationCaseStatusOpen,
			CreatedAt:      time.Now().UTC(),
			UpdatedAt:      time.Now().UTC(),
		},
	}
	activity := &moderationActivityClientStub{
		item: &model.ActivityModerationItem{
			ID:               activityID,
			Revision:         3,
			Status:           "CANCELLED",
			ModerationStatus: "REJECTED",
		},
	}
	uc := NewModerationUseCase(repo, &moderationExcursionClientStub{}, activity, &moderationGuideClientStub{}, &moderationChatClientStub{}, &moderationAuditRepoStub{})

	_, err := uc.DecideActivity(context.Background(), ModerationDecisionInput{
		Actor:           actor,
		CaseID:          caseID,
		Decision:        enum.ModerationDecisionReject,
		ReasonCodes:     []string{"external_contact"},
		PublicComment:   "Уберите контактный номер из описания активности.",
		InternalComment: "Контактный номер подтвержден вручную.",
		IdempotencyKey:  "activity-reject",
	})

	if err != nil {
		t.Fatalf("DecideActivity() error = %v", err)
	}
	if activity.lastRejectInput.PublicComment != "Уберите контактный номер из описания активности." {
		t.Fatalf("public comment sent to activity service = %q", activity.lastRejectInput.PublicComment)
	}
}

func TestDecideGuideApplicationRejectRequiresPublicAndInternalComments(t *testing.T) {
	t.Parallel()

	actor := &model.StaffUser{
		ID:          uuid.New(),
		Email:       "guide-moderator@inflap.local",
		DisplayName: "Guide Moderator",
		Status:      enum.StaffStatusActive,
		Permissions: []enum.Permission{
			enum.PermissionModerationRead,
			enum.PermissionGuideModerate,
		},
	}
	caseID := uuid.New()
	applicationID := uuid.New()

	for _, tc := range []struct {
		name            string
		publicComment   string
		internalComment string
	}{
		{name: "missing public comment", internalComment: "Insufficient document quality."},
		{name: "missing internal comment", publicComment: "Пожалуйста, загрузите читаемое удостоверение личности."},
	} {
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()

			repo := &moderationRepoStub{
				item: &model.ModerationCase{
					ID:             caseID,
					TargetType:     model.ModerationTargetGuideApplication,
					TargetID:       applicationID,
					SourceRevision: 5,
					Status:         enum.ModerationCaseStatusOpen,
					CreatedAt:      time.Now().UTC(),
					UpdatedAt:      time.Now().UTC(),
				},
			}
			guide := &moderationGuideClientStub{
				item: &model.GuideApplicationModerationItem{
					ID:          applicationID,
					Revision:    5,
					Status:      "SUBMITTED",
					GuideStatus: "PENDING_REVIEW",
				},
			}
			uc := NewModerationUseCase(repo, &moderationExcursionClientStub{}, &moderationActivityClientStub{}, guide, &moderationChatClientStub{}, &moderationAuditRepoStub{})

			_, err := uc.DecideGuideApplication(context.Background(), ModerationDecisionInput{
				Actor:           actor,
				CaseID:          caseID,
				Decision:        enum.ModerationDecisionReject,
				ReasonCodes:     []string{"documents_unreadable"},
				PublicComment:   tc.publicComment,
				InternalComment: tc.internalComment,
				IdempotencyKey:  "guide-reject",
			})

			if !errors.Is(err, ErrInvalidInput) {
				t.Fatalf("DecideGuideApplication() error = %v, want %v", err, ErrInvalidInput)
			}
			if repo.createdDecision != nil {
				t.Fatal("DecideGuideApplication() created decision without mandatory comments")
			}
			if guide.lastRejectInput.GuideApplicationID != uuid.Nil {
				t.Fatal("DecideGuideApplication() called guide service without mandatory comments")
			}
		})
	}
}

func TestDecideGuideApplicationRejectSendsPublicCommentToGuideService(t *testing.T) {
	t.Parallel()

	actor := &model.StaffUser{
		ID:          uuid.New(),
		Email:       "guide-moderator@inflap.local",
		DisplayName: "Guide Moderator",
		Status:      enum.StaffStatusActive,
		Permissions: []enum.Permission{
			enum.PermissionModerationRead,
			enum.PermissionGuideModerate,
		},
	}
	caseID := uuid.New()
	applicationID := uuid.New()
	repo := &moderationRepoStub{
		item: &model.ModerationCase{
			ID:             caseID,
			TargetType:     model.ModerationTargetGuideApplication,
			TargetID:       applicationID,
			SourceRevision: 5,
			Status:         enum.ModerationCaseStatusOpen,
			CreatedAt:      time.Now().UTC(),
			UpdatedAt:      time.Now().UTC(),
		},
	}
	guide := &moderationGuideClientStub{
		item: &model.GuideApplicationModerationItem{
			ID:          applicationID,
			Revision:    5,
			Status:      "REJECTED",
			GuideStatus: "REJECTED",
		},
	}
	uc := NewModerationUseCase(repo, &moderationExcursionClientStub{}, &moderationActivityClientStub{}, guide, &moderationChatClientStub{}, &moderationAuditRepoStub{})

	_, err := uc.DecideGuideApplication(context.Background(), ModerationDecisionInput{
		Actor:           actor,
		CaseID:          caseID,
		Decision:        enum.ModerationDecisionReject,
		ReasonCodes:     []string{"documents_unreadable"},
		PublicComment:   "Пожалуйста, загрузите читаемое удостоверение личности.",
		InternalComment: "Identity document is unreadable.",
		IdempotencyKey:  "guide-reject",
	})

	if err != nil {
		t.Fatalf("DecideGuideApplication() error = %v", err)
	}
	if guide.lastRejectInput.PublicComment != "Пожалуйста, загрузите читаемое удостоверение личности." {
		t.Fatalf("public comment sent to guide service = %q", guide.lastRejectInput.PublicComment)
	}
}

func TestDecideGuideApplicationRevokeSendsPublicCommentAndMarksCaseRevoked(t *testing.T) {
	t.Parallel()

	actor := &model.StaffUser{
		ID:          uuid.New(),
		Email:       "guide-moderator@inflap.local",
		DisplayName: "Guide Moderator",
		Status:      enum.StaffStatusActive,
		Permissions: []enum.Permission{
			enum.PermissionModerationRead,
			enum.PermissionGuideModerate,
		},
	}
	caseID := uuid.New()
	applicationID := uuid.New()
	repo := &moderationRepoStub{
		item: &model.ModerationCase{
			ID:             caseID,
			TargetType:     model.ModerationTargetGuideApplication,
			TargetID:       applicationID,
			SourceRevision: 6,
			Status:         enum.ModerationCaseStatusApproved,
			CreatedAt:      time.Now().UTC(),
			UpdatedAt:      time.Now().UTC(),
		},
	}
	guide := &moderationGuideClientStub{
		item: &model.GuideApplicationModerationItem{
			ID:          applicationID,
			Revision:    6,
			Status:      "APPROVED",
			GuideStatus: "REVOKED",
		},
	}
	uc := NewModerationUseCase(repo, &moderationExcursionClientStub{}, &moderationActivityClientStub{}, guide, &moderationChatClientStub{}, &moderationAuditRepoStub{})

	_, err := uc.DecideGuideApplication(context.Background(), ModerationDecisionInput{
		Actor:           actor,
		CaseID:          caseID,
		Decision:        enum.ModerationDecisionRevoke,
		ReasonCodes:     []string{"unsafe_behavior"},
		PublicComment:   "Статус гида отозван из-за нарушений правил безопасности.",
		InternalComment: "Safety policy violation confirmed by moderation lead.",
		IdempotencyKey:  "guide-revoke",
	})

	if err != nil {
		t.Fatalf("DecideGuideApplication() error = %v", err)
	}
	if guide.lastRevokeInput.PublicComment != "Статус гида отозван из-за нарушений правил безопасности." {
		t.Fatalf("public comment sent to guide service = %q", guide.lastRevokeInput.PublicComment)
	}
	if repo.item.Status != enum.ModerationCaseStatusRevoked {
		t.Fatalf("case status = %s, want %s", repo.item.Status, enum.ModerationCaseStatusRevoked)
	}
}

func TestDecideGuideApplicationRevokeRejectedCaseIsDenied(t *testing.T) {
	t.Parallel()

	actor := &model.StaffUser{
		ID:          uuid.New(),
		Email:       "guide-moderator@inflap.local",
		DisplayName: "Guide Moderator",
		Status:      enum.StaffStatusActive,
		Permissions: []enum.Permission{
			enum.PermissionModerationRead,
			enum.PermissionGuideModerate,
		},
	}
	caseID := uuid.New()
	applicationID := uuid.New()
	repo := &moderationRepoStub{
		item: &model.ModerationCase{
			ID:             caseID,
			TargetType:     model.ModerationTargetGuideApplication,
			TargetID:       applicationID,
			SourceRevision: 6,
			Status:         enum.ModerationCaseStatusRejected,
			CreatedAt:      time.Now().UTC(),
			UpdatedAt:      time.Now().UTC(),
		},
	}
	guide := &moderationGuideClientStub{}
	uc := NewModerationUseCase(repo, &moderationExcursionClientStub{}, &moderationActivityClientStub{}, guide, &moderationChatClientStub{}, &moderationAuditRepoStub{})

	_, err := uc.DecideGuideApplication(context.Background(), ModerationDecisionInput{
		Actor:           actor,
		CaseID:          caseID,
		Decision:        enum.ModerationDecisionRevoke,
		ReasonCodes:     []string{"unsafe_behavior"},
		PublicComment:   "Статус гида отозван из-за нарушений правил безопасности.",
		InternalComment: "Trying to revoke from rejected decision.",
		IdempotencyKey:  "guide-revoke-rejected",
	})

	if !errors.Is(err, ErrInvalidInput) {
		t.Fatalf("DecideGuideApplication() error = %v, want %v", err, ErrInvalidInput)
	}
	if guide.lastRevokeInput.GuideApplicationID != uuid.Nil {
		t.Fatal("DecideGuideApplication() must not call guide service for rejected cases")
	}
}

func TestListActiveGuidesUsesGuideClient(t *testing.T) {
	t.Parallel()

	actor := &model.StaffUser{
		ID:          uuid.New(),
		Email:       "guide-moderator@inflap.local",
		DisplayName: "Guide Moderator",
		Status:      enum.StaffStatusActive,
		Permissions: []enum.Permission{
			enum.PermissionModerationRead,
			enum.PermissionGuideModerate,
		},
	}
	guideProfileID := uuid.New()
	guide := &moderationGuideClientStub{
		activeGuides: []model.GuideApplicationModerationItem{
			{
				GuideProfileID: guideProfileID,
				GuideStatus:    "ACTIVE",
				GuideUserID:    uuid.New(),
			},
		},
	}
	uc := NewModerationUseCase(&moderationRepoStub{}, &moderationExcursionClientStub{}, &moderationActivityClientStub{}, guide, &moderationChatClientStub{}, &moderationAuditRepoStub{})

	items, err := uc.ListActiveGuides(context.Background(), actor, 100, 0)

	if err != nil {
		t.Fatalf("ListActiveGuides() error = %v", err)
	}
	if len(items) != 1 || items[0].GuideProfileID != guideProfileID {
		t.Fatalf("ListActiveGuides() items = %#v, want profile %s", items, guideProfileID)
	}
	if guide.lastListActiveLimit != 100 || guide.lastListActiveOffset != 0 {
		t.Fatalf("guide list args = %d/%d, want 100/0", guide.lastListActiveLimit, guide.lastListActiveOffset)
	}
}

func TestRevokeActiveGuideUsesGuideProfileIDAndAudit(t *testing.T) {
	t.Parallel()

	actor := &model.StaffUser{
		ID:          uuid.New(),
		Email:       "guide-moderator@inflap.local",
		DisplayName: "Guide Moderator",
		Status:      enum.StaffStatusActive,
		Permissions: []enum.Permission{
			enum.PermissionModerationRead,
			enum.PermissionGuideModerate,
		},
	}
	guideProfileID := uuid.New()
	audit := &moderationAuditRepoStub{}
	guide := &moderationGuideClientStub{
		item: &model.GuideApplicationModerationItem{
			GuideProfileID: guideProfileID,
			GuideStatus:    "REVOKED",
		},
	}
	uc := NewModerationUseCase(&moderationRepoStub{}, &moderationExcursionClientStub{}, &moderationActivityClientStub{}, guide, &moderationChatClientStub{}, audit)

	item, err := uc.RevokeActiveGuide(context.Background(), RevokeActiveGuideInput{
		Actor:           actor,
		GuideProfileID:  guideProfileID,
		ReasonCodes:     []string{"unsafe_behavior"},
		PublicComment:   "Статус гида отозван из-за нарушений правил безопасности.",
		InternalComment: "Safety policy violation confirmed.",
		IdempotencyKey:  "active-guide-revoke",
	})

	if err != nil {
		t.Fatalf("RevokeActiveGuide() error = %v", err)
	}
	if item == nil || item.GuideProfileID != guideProfileID {
		t.Fatalf("RevokeActiveGuide() item = %#v, want profile %s", item, guideProfileID)
	}
	if guide.lastRevokeProfileInput.GuideProfileID != guideProfileID {
		t.Fatalf("guide profile id sent to guide service = %s, want %s", guide.lastRevokeProfileInput.GuideProfileID, guideProfileID)
	}
	if guide.lastRevokeProfileInput.PublicComment == "" {
		t.Fatal("public comment must be sent to guide service")
	}
	if audit.lastAction != "guide.status.revoked" {
		t.Fatalf("audit action = %q, want guide.status.revoked", audit.lastAction)
	}
}

type adminNotificationGatewayStub struct {
	send func(ctx context.Context, input port.UserNotificationInput) error
}

func (s adminNotificationGatewayStub) SendUserNotification(
	ctx context.Context,
	input port.UserNotificationInput,
) error {
	if s.send != nil {
		return s.send(ctx, input)
	}
	return nil
}

func waitAdminNotification(
	t *testing.T,
	ch <-chan port.UserNotificationInput,
) port.UserNotificationInput {
	t.Helper()

	select {
	case got := <-ch:
		return got
	case <-time.After(time.Second):
		t.Fatal("timed out waiting for admin notification")
	}
	return port.UserNotificationInput{}
}

type moderationRepoStub struct {
	item                         *model.ModerationCase
	decisions                    []*model.ModerationDecision
	createdDecision              *model.ModerationDecision
	supersededCaseID             uuid.UUID
	supersededRevision           int
	supersededExceptDecisionID   uuid.UUID
	upsertedActivities           []model.ActivityModerationItem
	cancelledActivityIDs         []uuid.UUID
	upsertedGuideApplications    []model.GuideApplicationModerationItem
	cancelledGuideApplicationIDs []uuid.UUID
	upsertedChatMessages         []model.ChatMessageModerationItem
	cancelledChatMessageIDs      []uuid.UUID
	upsertedPostReports          []model.PostReportModerationItem
	cancelledPostReportIDs       []uuid.UUID
	upsertedPosts                []model.PostModerationItem
	cancelledPostIDs             []uuid.UUID
}

func (r *moderationRepoStub) UpsertExcursionCase(context.Context, model.ExcursionModerationItem) (*model.ModerationCase, error) {
	return nil, nil
}

func (r *moderationRepoStub) CancelStaleExcursionCases(context.Context, []uuid.UUID, time.Time) error {
	return nil
}

func (r *moderationRepoStub) UpsertActivityCase(_ context.Context, item model.ActivityModerationItem) (*model.ModerationCase, error) {
	r.upsertedActivities = append(r.upsertedActivities, item)
	return nil, nil
}

func (r *moderationRepoStub) CancelStaleActivityCases(_ context.Context, activeTargetIDs []uuid.UUID, _ time.Time) error {
	r.cancelledActivityIDs = append([]uuid.UUID(nil), activeTargetIDs...)
	return nil
}

func (r *moderationRepoStub) UpsertGuideApplicationCase(_ context.Context, item model.GuideApplicationModerationItem) (*model.ModerationCase, error) {
	r.upsertedGuideApplications = append(r.upsertedGuideApplications, item)
	return nil, nil
}

func (r *moderationRepoStub) CancelStaleGuideApplicationCases(_ context.Context, activeTargetIDs []uuid.UUID, _ time.Time) error {
	r.cancelledGuideApplicationIDs = append([]uuid.UUID(nil), activeTargetIDs...)
	return nil
}

func (r *moderationRepoStub) UpsertChatMessageCase(_ context.Context, item model.ChatMessageModerationItem) (*model.ModerationCase, error) {
	r.upsertedChatMessages = append(r.upsertedChatMessages, item)
	return nil, nil
}

func (r *moderationRepoStub) CancelStaleChatMessageCases(_ context.Context, activeTargetIDs []uuid.UUID, _ time.Time) error {
	r.cancelledChatMessageIDs = append([]uuid.UUID(nil), activeTargetIDs...)
	return nil
}

func (r *moderationRepoStub) UpsertPostReportCase(_ context.Context, item model.PostReportModerationItem) (*model.ModerationCase, error) {
	r.upsertedPostReports = append(r.upsertedPostReports, item)
	return nil, nil
}

func (r *moderationRepoStub) CancelStalePostReportCases(_ context.Context, activeTargetIDs []uuid.UUID, _ time.Time) error {
	r.cancelledPostReportIDs = append([]uuid.UUID(nil), activeTargetIDs...)
	return nil
}

func (r *moderationRepoStub) UpsertStoryCase(_ context.Context, item model.PostModerationItem) (*model.ModerationCase, error) {
	r.upsertedPosts = append(r.upsertedPosts, item)
	return nil, nil
}

func (r *moderationRepoStub) CancelStaleStoryCases(_ context.Context, activeTargetIDs []uuid.UUID, _ time.Time) error {
	r.cancelledPostIDs = append([]uuid.UUID(nil), activeTargetIDs...)
	return nil
}

func (r *moderationRepoStub) ListCases(context.Context, model.ModerationQueueFilter) ([]*model.ModerationCase, error) {
	return []*model.ModerationCase{r.item}, nil
}

func (r *moderationRepoStub) GetCase(context.Context, uuid.UUID) (*model.ModerationCase, error) {
	return r.item, nil
}

func (r *moderationRepoStub) ListDecisions(context.Context, uuid.UUID) ([]*model.ModerationDecision, error) {
	return r.decisions, nil
}

func (r *moderationRepoStub) CreateDecision(_ context.Context, decision *model.ModerationDecision) error {
	r.createdDecision = decision
	r.decisions = append([]*model.ModerationDecision{decision}, r.decisions...)
	return nil
}

func (r *moderationRepoStub) MarkDecisionApplied(context.Context, uuid.UUID, []byte, time.Time) error {
	return nil
}

func (r *moderationRepoStub) MarkDecisionFailed(context.Context, uuid.UUID, []byte, time.Time) error {
	return nil
}

func (r *moderationRepoStub) SupersedeAppliedDecisions(_ context.Context, caseID uuid.UUID, sourceRevision int, exceptDecisionID uuid.UUID, _ time.Time) error {
	r.supersededCaseID = caseID
	r.supersededRevision = sourceRevision
	r.supersededExceptDecisionID = exceptDecisionID
	return nil
}

func (r *moderationRepoStub) UpdateCaseStatus(_ context.Context, _ uuid.UUID, status enum.ModerationCaseStatus, _ *time.Time, _ time.Time) error {
	r.item.Status = status
	return nil
}

type moderationExcursionClientStub struct {
	item             *model.ExcursionModerationItem
	lastApproveInput port.ExcursionDecisionInput
	lastRejectInput  port.ExcursionDecisionInput
}

func (c *moderationExcursionClientStub) ListPendingReview(context.Context, int, int) ([]model.ExcursionModerationItem, error) {
	return nil, nil
}

func (c *moderationExcursionClientStub) GetExcursion(context.Context, uuid.UUID) (*model.ExcursionModerationItem, error) {
	return c.item, nil
}

func (c *moderationExcursionClientStub) Approve(_ context.Context, input port.ExcursionDecisionInput) (*model.ExcursionModerationItem, []byte, error) {
	c.lastApproveInput = input
	raw, _ := json.Marshal(c.item)
	return c.item, raw, nil
}

func (c *moderationExcursionClientStub) Reject(_ context.Context, input port.ExcursionDecisionInput) (*model.ExcursionModerationItem, []byte, error) {
	c.lastRejectInput = input
	raw, _ := json.Marshal(c.item)
	return c.item, raw, nil
}

type moderationActivityClientStub struct {
	item             *model.ActivityModerationItem
	items            []model.ActivityModerationItem
	lastApproveInput port.ActivityDecisionInput
	lastRejectInput  port.ActivityDecisionInput
}

func (c *moderationActivityClientStub) ListFlagged(context.Context, int, int) ([]model.ActivityModerationItem, error) {
	return c.items, nil
}

func (c *moderationActivityClientStub) GetActivity(context.Context, uuid.UUID) (*model.ActivityModerationItem, error) {
	return c.item, nil
}

func (c *moderationActivityClientStub) Approve(_ context.Context, input port.ActivityDecisionInput) (*model.ActivityModerationItem, []byte, error) {
	c.lastApproveInput = input
	raw, _ := json.Marshal(c.item)
	return c.item, raw, nil
}

func (c *moderationActivityClientStub) Reject(_ context.Context, input port.ActivityDecisionInput) (*model.ActivityModerationItem, []byte, error) {
	c.lastRejectInput = input
	raw, _ := json.Marshal(c.item)
	return c.item, raw, nil
}

type moderationChatClientStub struct {
	item             *model.ChatMessageModerationItem
	items            []model.ChatMessageModerationItem
	lastApproveInput port.ChatMessageDecisionInput
	lastHideInput    port.ChatMessageDecisionInput
}

func (c *moderationChatClientStub) ListFlaggedMessages(context.Context, int, int) ([]model.ChatMessageModerationItem, error) {
	return c.items, nil
}

func (c *moderationChatClientStub) GetMessage(context.Context, uuid.UUID) (*model.ChatMessageModerationItem, error) {
	return c.item, nil
}

func (c *moderationChatClientStub) ApproveMessage(_ context.Context, input port.ChatMessageDecisionInput) (*model.ChatMessageModerationItem, []byte, error) {
	c.lastApproveInput = input
	raw, _ := json.Marshal(c.item)
	return c.item, raw, nil
}

func (c *moderationChatClientStub) HideMessage(_ context.Context, input port.ChatMessageDecisionInput) (*model.ChatMessageModerationItem, []byte, error) {
	c.lastHideInput = input
	raw, _ := json.Marshal(c.item)
	return c.item, raw, nil
}

type moderationPostReportClientStub struct {
	item                  *model.PostReportModerationItem
	items                 []model.PostReportModerationItem
	storyItem             *model.PostModerationItem
	postItems             []model.PostModerationItem
	feedQualityMetrics    []model.FeedQualityMetric
	lastFeedQualityFilter model.FeedQualityMetricFilter
	lastReviewInput       port.PostReportDecisionInput
	lastDismissInput      port.PostReportDecisionInput
	lastApproveStoryInput port.CommunityPostDecisionInput
	lastRejectStoryInput  port.CommunityPostDecisionInput
}

func (c *moderationPostReportClientStub) ListOpenReports(context.Context, int, int) ([]model.PostReportModerationItem, error) {
	return c.items, nil
}

func (c *moderationPostReportClientStub) ListPendingCommunityPosts(context.Context, int, int) ([]model.PostModerationItem, error) {
	return c.postItems, nil
}

func (c *moderationPostReportClientStub) GetReport(context.Context, uuid.UUID) (*model.PostReportModerationItem, error) {
	return c.item, nil
}

func (c *moderationPostReportClientStub) GetCommunityPost(context.Context, uuid.UUID) (*model.PostModerationItem, error) {
	return c.storyItem, nil
}

func (c *moderationPostReportClientStub) ListFeedQualityMetrics(_ context.Context, filter model.FeedQualityMetricFilter) ([]model.FeedQualityMetric, error) {
	c.lastFeedQualityFilter = filter
	return c.feedQualityMetrics, nil
}

func (c *moderationPostReportClientStub) ReviewReport(_ context.Context, input port.PostReportDecisionInput) (*model.PostReportModerationItem, []byte, error) {
	c.lastReviewInput = input
	raw, _ := json.Marshal(c.item)
	return c.item, raw, nil
}

func (c *moderationPostReportClientStub) DismissReport(_ context.Context, input port.PostReportDecisionInput) (*model.PostReportModerationItem, []byte, error) {
	c.lastDismissInput = input
	raw, _ := json.Marshal(c.item)
	return c.item, raw, nil
}

func (c *moderationPostReportClientStub) ApproveCommunityPost(_ context.Context, input port.CommunityPostDecisionInput) (*model.PostModerationItem, []byte, error) {
	c.lastApproveStoryInput = input
	raw, _ := json.Marshal(c.storyItem)
	return c.storyItem, raw, nil
}

func (c *moderationPostReportClientStub) RejectCommunityPost(_ context.Context, input port.CommunityPostDecisionInput) (*model.PostModerationItem, []byte, error) {
	c.lastRejectStoryInput = input
	raw, _ := json.Marshal(c.storyItem)
	return c.storyItem, raw, nil
}

type moderationGuideClientStub struct {
	item                   *model.GuideApplicationModerationItem
	items                  []model.GuideApplicationModerationItem
	activeGuides           []model.GuideApplicationModerationItem
	lastApproveInput       port.GuideApplicationDecisionInput
	lastRejectInput        port.GuideApplicationDecisionInput
	lastRevokeInput        port.GuideApplicationDecisionInput
	lastRevokeProfileInput port.GuideProfileDecisionInput
	lastListActiveLimit    int
	lastListActiveOffset   int
}

func (c *moderationGuideClientStub) ListPendingApplications(context.Context, int, int) ([]model.GuideApplicationModerationItem, error) {
	return c.items, nil
}

func (c *moderationGuideClientStub) ListActiveGuides(_ context.Context, limit int, offset int) ([]model.GuideApplicationModerationItem, error) {
	c.lastListActiveLimit = limit
	c.lastListActiveOffset = offset
	return c.activeGuides, nil
}

func (c *moderationGuideClientStub) GetApplication(context.Context, uuid.UUID) (*model.GuideApplicationModerationItem, error) {
	return c.item, nil
}

func (c *moderationGuideClientStub) Approve(_ context.Context, input port.GuideApplicationDecisionInput) (*model.GuideApplicationModerationItem, []byte, error) {
	c.lastApproveInput = input
	raw, _ := json.Marshal(c.item)
	return c.item, raw, nil
}

func (c *moderationGuideClientStub) Reject(_ context.Context, input port.GuideApplicationDecisionInput) (*model.GuideApplicationModerationItem, []byte, error) {
	c.lastRejectInput = input
	raw, _ := json.Marshal(c.item)
	return c.item, raw, nil
}

func (c *moderationGuideClientStub) Revoke(_ context.Context, input port.GuideApplicationDecisionInput) (*model.GuideApplicationModerationItem, []byte, error) {
	c.lastRevokeInput = input
	raw, _ := json.Marshal(c.item)
	return c.item, raw, nil
}

func (c *moderationGuideClientStub) RevokeProfile(_ context.Context, input port.GuideProfileDecisionInput) (*model.GuideApplicationModerationItem, []byte, error) {
	c.lastRevokeProfileInput = input
	raw, _ := json.Marshal(c.item)
	return c.item, raw, nil
}

type moderationAuditRepoStub struct {
	lastAction string
}

func (r *moderationAuditRepoStub) Append(_ context.Context, event *model.AuditEvent) error {
	if event != nil {
		r.lastAction = event.Action
	}
	return nil
}

func (r *moderationAuditRepoStub) List(context.Context, model.AuditFilter) ([]*model.AuditEvent, error) {
	return nil, nil
}

func timePtr(value time.Time) *time.Time {
	return &value
}
