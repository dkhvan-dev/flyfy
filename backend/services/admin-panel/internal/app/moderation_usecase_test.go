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
