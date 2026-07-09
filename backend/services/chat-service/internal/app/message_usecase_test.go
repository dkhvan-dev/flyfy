package app

import (
	"context"
	"errors"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/chat-service/internal/domain/model"
	"kz/inflap/backend/services/chat-service/internal/domain/port"
	"kz/inflap/backend/services/chat-service/internal/event"
)

func TestSendStickerMessageValidatesStickerAndStoresStickerPayload(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	conversationID := uuid.New()
	senderID := uuid.New()
	stickerID := uuid.New()
	packID := uuid.New()
	fileID := uuid.New()
	fallbackID := uuid.New()
	previewID := uuid.New()

	repo := newFakeMessageRepo(conversationID, senderID)
	stickers := &fakeStickerResolver{
		result: &port.StickerMetadata{
			StickerID:      stickerID,
			PackID:         packID,
			PackSlug:       "inflap-travel-basics",
			Slug:           "boarding-pass",
			FileID:         fileID,
			FallbackFileID: fallbackID,
			PreviewFileID:  &previewID,
			ContentType:    "application/json",
			Width:          512,
			Height:         512,
			DurationMS:     1800,
			Status:         "ACTIVE",
		},
	}
	useCase := NewMessageUseCaseWithStickerResolver(repo, &fakeEventPublisher{}, nil, stickers)

	msg, err := useCase.SendMessage(ctx, SendMessageInput{
		ConversationID: conversationID,
		SenderUserID:   senderID,
		Type:           "sticker",
		StickerID:      &stickerID,
		FileIDs:        []string{uuid.NewString()},
	})
	if err != nil {
		t.Fatalf("SendMessage error: %v", err)
	}

	if stickers.senderUserID != senderID || stickers.stickerID != stickerID {
		t.Fatalf("sticker validation input mismatch: sender=%s sticker=%s", stickers.senderUserID, stickers.stickerID)
	}
	if msg.Type != messageTypeSticker {
		t.Fatalf("message type = %q, want sticker", msg.Type)
	}
	if msg.StickerID == nil || *msg.StickerID != stickerID {
		t.Fatalf("StickerID = %v, want %s", msg.StickerID, stickerID)
	}
	if msg.StickerFileID == nil || *msg.StickerFileID != fallbackID.String() {
		t.Fatalf("StickerFileID = %v, want %s", msg.StickerFileID, fallbackID)
	}
	if msg.StickerPayload == nil {
		t.Fatal("expected sticker payload")
	}
	if msg.StickerPayload.PackID != packID ||
		msg.StickerPayload.PackSlug != "inflap-travel-basics" ||
		msg.StickerPayload.Slug != "boarding-pass" ||
		msg.StickerPayload.FallbackFileID != fallbackID.String() ||
		msg.StickerPayload.PreviewFileID == nil ||
		*msg.StickerPayload.PreviewFileID != previewID.String() ||
		msg.StickerPayload.ContentType != "application/json" ||
		msg.StickerPayload.Width != 512 ||
		msg.StickerPayload.Height != 512 ||
		msg.StickerPayload.DurationMS != 1800 {
		t.Fatalf("unexpected sticker payload: %+v", msg.StickerPayload)
	}
	if len(msg.FileIDs) != 0 {
		t.Fatalf("sticker messages must not persist attachment fileIds: %+v", msg.FileIDs)
	}
	if repo.createdMessage == nil ||
		repo.createdMessage.StickerID == nil ||
		*repo.createdMessage.StickerID != stickerID ||
		repo.createdMessage.StickerPayload == nil {
		t.Fatalf("repository did not receive sticker metadata: %+v", repo.createdMessage)
	}
}

func TestSendStickerMessageCanValidateWithStickerServiceIdentity(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	conversationID := uuid.New()
	senderID := uuid.New()
	stickerAccessUserID := uuid.New()
	stickerID := uuid.New()
	fileID := uuid.New()

	repo := newFakeMessageRepo(conversationID, senderID)
	stickers := &fakeStickerResolver{
		result: &port.StickerMetadata{
			StickerID: stickerID,
			PackID:    uuid.New(),
			FileID:    fileID,
			Status:    "ACTIVE",
		},
	}
	useCase := NewMessageUseCaseWithStickerResolver(repo, &fakeEventPublisher{}, nil, stickers)

	msg, err := useCase.SendMessage(ctx, SendMessageInput{
		ConversationID:      conversationID,
		SenderUserID:        senderID,
		StickerAccessUserID: &stickerAccessUserID,
		Type:                "sticker",
		StickerID:           &stickerID,
	})
	if err != nil {
		t.Fatalf("SendMessage error: %v", err)
	}

	if stickers.senderUserID != stickerAccessUserID {
		t.Fatalf("expected sticker validation user %s, got %s", stickerAccessUserID, stickers.senderUserID)
	}
	if msg.SenderUserID != senderID {
		t.Fatalf("message sender must remain canonical user id %s, got %s", senderID, msg.SenderUserID)
	}
}

func TestSendStickerMessageFlagsWhenTrustPolicyUnavailable(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	conversationID := uuid.New()
	senderID := uuid.New()
	stickerID := uuid.New()
	fileID := uuid.New()

	repo := newFakeMessageRepo(conversationID, senderID)
	stickers := &fakeStickerResolver{
		result: &port.StickerMetadata{
			StickerID:   stickerID,
			PackID:      uuid.New(),
			PackSlug:    "inflap-travel-basics",
			Slug:        "boarding-pass",
			FileID:      fileID,
			ContentType: "application/x-tgsticker",
			Width:       512,
			Height:      512,
			DurationMS:  1800,
			Status:      "ACTIVE",
		},
	}
	trustPolicy := &fakeTrustPolicyClient{err: errors.New("trust policy timeout")}
	useCase := NewMessageUseCaseWithStickerResolver(repo, &fakeEventPublisher{}, nil, stickers)
	useCase.SetTrustPolicyClient(trustPolicy)

	msg, err := useCase.SendMessage(ctx, SendMessageInput{
		ConversationID: conversationID,
		SenderUserID:   senderID,
		Type:           "sticker",
		StickerID:      &stickerID,
	})
	if err != nil {
		t.Fatalf("SendMessage error: %v", err)
	}

	if trustPolicy.check.Action != trustActionChatSend {
		t.Fatalf("trust action = %q, want %q", trustPolicy.check.Action, trustActionChatSend)
	}
	if hasSticker, ok := trustPolicy.check.Metadata["hasSticker"].(bool); !ok || !hasSticker {
		t.Fatalf("trust metadata hasSticker = %#v, want true", trustPolicy.check.Metadata["hasSticker"])
	}
	if msg.ModerationStatus != model.MessageModerationStatusFlagged {
		t.Fatalf("ModerationStatus = %q, want %q", msg.ModerationStatus, model.MessageModerationStatusFlagged)
	}
	if !containsString(msg.ModerationReasonCodes, "TRUST_POLICY_UNAVAILABLE") {
		t.Fatalf("ModerationReasonCodes = %#v, want TRUST_POLICY_UNAVAILABLE", msg.ModerationReasonCodes)
	}
	if msg.ModerationTriggeredAt == nil {
		t.Fatal("ModerationTriggeredAt must be set when trust policy is unavailable")
	}
	if msg.StickerPayload == nil || msg.StickerPayload.ContentType != "application/x-tgsticker" {
		t.Fatalf("sticker payload was not preserved: %+v", msg.StickerPayload)
	}
}

func TestSendStickerMessageRejectsMissingStickerResolver(t *testing.T) {
	t.Parallel()

	conversationID := uuid.New()
	senderID := uuid.New()
	stickerID := uuid.New()
	repo := newFakeMessageRepo(conversationID, senderID)
	useCase := NewMessageUseCase(repo, &fakeEventPublisher{}, nil)

	_, err := useCase.SendMessage(context.Background(), SendMessageInput{
		ConversationID: conversationID,
		SenderUserID:   senderID,
		Type:           "sticker",
		StickerID:      &stickerID,
	})
	if err != ErrStickerNotAvailable {
		t.Fatalf("expected ErrStickerNotAvailable, got %v", err)
	}
}

func TestSendMessageStoresTextContent(t *testing.T) {
	t.Parallel()

	conversationID := uuid.New()
	senderID := uuid.New()
	repo := newFakeMessageRepo(conversationID, senderID)
	useCase := NewMessageUseCase(repo, &fakeEventPublisher{}, nil)

	msg, err := useCase.SendMessage(context.Background(), SendMessageInput{
		ConversationID: conversationID,
		SenderUserID:   senderID,
		Type:           "text",
		Content:        "hello",
	})
	if err != nil {
		t.Fatalf("SendMessage error: %v", err)
	}
	if msg.Content != "hello" {
		t.Fatalf("Content = %q, want hello", msg.Content)
	}
}

func TestPendingAttachmentMessageCompletesAfterUpload(t *testing.T) {
	t.Parallel()

	conversationID := uuid.New()
	senderID := uuid.New()
	repo := newFakeMessageRepo(conversationID, senderID)
	repo.messagesByID = map[uuid.UUID]*model.Message{}
	repo.messageFileIDs = map[uuid.UUID][]string{}
	useCase := NewMessageUseCase(repo, &fakeEventPublisher{}, nil)

	pending, err := useCase.SendMessage(context.Background(), SendMessageInput{
		ConversationID:  conversationID,
		SenderUserID:    senderID,
		Type:            messageTypeFile,
		Content:         "look at this",
		DeferFileUpload: true,
	})
	if err != nil {
		t.Fatalf("SendMessage pending error: %v", err)
	}
	if pending.SendStatus != model.MessageSendStatusPendingAttachments {
		t.Fatalf("pending SendStatus = %q, want %q", pending.SendStatus, model.MessageSendStatusPendingAttachments)
	}
	if len(pending.FileIDs) != 0 {
		t.Fatalf("pending FileIDs = %#v, want none before upload", pending.FileIDs)
	}
	if got := len(repo.createdNotificationOutbox); got != 0 {
		t.Fatalf("pending notification outbox len = %d, want 0 before upload completes", got)
	}

	completed, err := useCase.CompletePendingMessageAttachments(context.Background(), CompletePendingMessageAttachmentsInput{
		ConversationID: conversationID,
		MessageID:      pending.ID,
		SenderUserID:   senderID,
		FileIDs:        []string{"file-a", "file-b"},
	})
	if err != nil {
		t.Fatalf("CompletePendingMessageAttachments error: %v", err)
	}
	if completed.SendStatus != model.MessageSendStatusSent {
		t.Fatalf("completed SendStatus = %q, want %q", completed.SendStatus, model.MessageSendStatusSent)
	}
	if completed.Type != messageTypeFile {
		t.Fatalf("completed Type = %q, want file", completed.Type)
	}
	if got := strings.Join(completed.FileIDs, ","); got != "file-a,file-b" {
		t.Fatalf("completed FileIDs = %q, want file-a,file-b", got)
	}
	if got := strings.Join(repo.messageFileIDs[pending.ID], ","); got != "file-a,file-b" {
		t.Fatalf("repo message files = %q, want file-a,file-b", got)
	}
	if got := len(repo.createdNotificationOutbox); got != 1 {
		t.Fatalf("notification outbox len after complete = %d, want 1", got)
	}
}

func TestSendMessageStoresStoryReplyContext(t *testing.T) {
	t.Parallel()

	conversationID := uuid.New()
	senderID := uuid.New()
	storyID := uuid.New()
	storyAuthorID := uuid.New()
	expiresAt := time.Now().UTC().Add(24 * time.Hour)
	repo := newFakeMessageRepo(conversationID, senderID)
	useCase := NewMessageUseCase(repo, &fakeEventPublisher{}, nil)

	msg, err := useCase.SendMessage(context.Background(), SendMessageInput{
		ConversationID: conversationID,
		SenderUserID:   senderID,
		Type:           "text",
		Content:        "Looks great",
		StoryReply: &model.StoryReplyContext{
			StoryID:            storyID,
			StoryAuthorUserID:  storyAuthorID,
			StoryTitle:         "Morning route",
			StoryPreviewFileID: "cover-one",
			StoryPreviewURL:    "https://cdn.example.test/cover-one.jpg",
			StoryExpiresAt:     &expiresAt,
		},
	})
	if err != nil {
		t.Fatalf("SendMessage error: %v", err)
	}

	if msg.StoryReply == nil {
		t.Fatal("StoryReply must be returned")
	}
	if msg.StoryReply.StoryID != storyID ||
		msg.StoryReply.StoryAuthorUserID != storyAuthorID ||
		msg.StoryReply.StoryTitle != "Morning route" ||
		msg.StoryReply.StoryPreviewFileID != "cover-one" ||
		msg.StoryReply.StoryPreviewURL != "https://cdn.example.test/cover-one.jpg" {
		t.Fatalf("StoryReply = %+v, want normalized story context", msg.StoryReply)
	}
	if msg.StoryReply.StoryExpiresAt == nil || !msg.StoryReply.StoryExpiresAt.Equal(expiresAt) {
		t.Fatalf("StoryExpiresAt = %v, want %v", msg.StoryReply.StoryExpiresAt, expiresAt)
	}
	if repo.createdMessage == nil || repo.createdMessage.StoryReply == nil {
		t.Fatalf("repository did not receive story reply context: %+v", repo.createdMessage)
	}
	if repo.createdMessage.StoryReply.StoryID != storyID ||
		repo.createdMessage.StoryReply.StoryAuthorUserID != storyAuthorID {
		t.Fatalf("repository StoryReply = %+v, want story %s author %s", repo.createdMessage.StoryReply, storyID, storyAuthorID)
	}
}

func TestSendMessageReturnsExistingMessageForDuplicateClientMessageID(t *testing.T) {
	t.Parallel()

	conversationID := uuid.New()
	senderID := uuid.New()
	clientMessageID := uuid.New()
	existingMessageID := uuid.New()
	sentAt := time.Now().UTC().Add(-time.Minute)
	repo := newFakeMessageRepo(conversationID, senderID)
	repo.messagesByClientMessageID = map[[3]uuid.UUID]*model.Message{
		{conversationID, senderID, clientMessageID}: {
			ID:              existingMessageID,
			ConversationID:  conversationID,
			SenderUserID:    senderID,
			ClientMessageID: &clientMessageID,
			Type:            messageTypeText,
			Content:         "already stored",
			SentAt:          sentAt,
		},
	}
	notifications := &fakeChatNotificationSender{}
	useCase := NewMessageUseCase(repo, &fakeEventPublisher{}, nil)
	useCase.SetNotificationSender(notifications)

	msg, err := useCase.SendMessage(context.Background(), SendMessageInput{
		ConversationID:  conversationID,
		SenderUserID:    senderID,
		ClientMessageID: &clientMessageID,
		Type:            "text",
		Content:         "retried payload",
	})
	if err != nil {
		t.Fatalf("SendMessage error: %v", err)
	}

	if msg.ID != existingMessageID {
		t.Fatalf("message ID = %s, want existing %s", msg.ID, existingMessageID)
	}
	if msg.Content != "already stored" {
		t.Fatalf("Content = %q, want existing content", msg.Content)
	}
	if repo.createMessageCalls != 0 {
		t.Fatalf("CreateMessage calls = %d, want duplicate retry to skip insert", repo.createMessageCalls)
	}
	if len(notifications.sent) != 0 {
		t.Fatalf("duplicate retry must not send push notification, got %#v", notifications.sent)
	}
}

func TestSendMessageEnqueuesNotificationOutboxWithoutCallingNotificationService(t *testing.T) {
	t.Parallel()

	conversationID := uuid.New()
	senderID := uuid.New()
	recipientID := uuid.New()
	mutedRecipientID := uuid.New()
	blockedRecipientID := uuid.New()
	leftRecipientID := uuid.New()
	now := time.Now().UTC()
	mutedUntil := now.Add(time.Hour)
	leftAt := now.Add(-time.Minute)
	repo := newFakeMessageRepo(conversationID, senderID)
	repo.participantsByConversationUser = map[[2]uuid.UUID]*model.Participant{
		{conversationID, senderID}: {
			ID:             uuid.New(),
			ConversationID: conversationID,
			UserID:         senderID,
			Role:           "member",
			JoinedAt:       now,
		},
		{conversationID, recipientID}: {
			ID:             uuid.New(),
			ConversationID: conversationID,
			UserID:         recipientID,
			Role:           "member",
			JoinedAt:       now,
		},
		{conversationID, mutedRecipientID}: {
			ID:             uuid.New(),
			ConversationID: conversationID,
			UserID:         mutedRecipientID,
			Role:           "member",
			MutedUntil:     &mutedUntil,
			JoinedAt:       now,
		},
		{conversationID, blockedRecipientID}: {
			ID:             uuid.New(),
			ConversationID: conversationID,
			UserID:         blockedRecipientID,
			Role:           "member",
			JoinedAt:       now,
		},
		{conversationID, leftRecipientID}: {
			ID:             uuid.New(),
			ConversationID: conversationID,
			UserID:         leftRecipientID,
			Role:           "member",
			JoinedAt:       now.Add(-time.Hour),
			LeftAt:         &leftAt,
		},
	}
	repo.blockedPairs = map[[2]uuid.UUID]bool{
		{blockedRecipientID, senderID}: true,
	}
	notifications := newFakeChatNotificationSender()
	useCase := NewMessageUseCase(repo, &fakeEventPublisher{}, nil)
	useCase.SetNotificationSender(notifications)

	msg, err := useCase.SendMessage(context.Background(), SendMessageInput{
		ConversationID:    conversationID,
		SenderUserID:      senderID,
		SenderDisplayName: "Aigerim",
		Type:              "text",
		Content:           "Meet near the north gate",
	})
	if err != nil {
		t.Fatalf("SendMessage error: %v", err)
	}

	notifications.expectNone(t)
	if len(repo.createdNotificationOutbox) != 1 {
		t.Fatalf("outbox entries = %d, want one", len(repo.createdNotificationOutbox))
	}
	item := repo.createdNotificationOutbox[0]
	if item.EventType != chatNotificationEventMessage {
		t.Fatalf("EventType = %q, want %q", item.EventType, chatNotificationEventMessage)
	}
	if item.ConversationID != conversationID || item.MessageID != msg.ID || item.ActorUserID != senderID {
		t.Fatalf("outbox target = conversation %s message %s actor %s", item.ConversationID, item.MessageID, item.ActorUserID)
	}
	if repo.blockListLookupCount != 0 {
		t.Fatalf("send path block list lookups = %d, want async dispatcher to resolve recipients", repo.blockListLookupCount)
	}
	if repo.blockLookupCount != 0 {
		t.Fatalf("per-recipient block lookups = %d, want none for notification fanout", repo.blockLookupCount)
	}
}

func TestSendMessageSkipsNotificationWhenAllRecipientsMuted(t *testing.T) {
	t.Parallel()

	conversationID := uuid.New()
	senderID := uuid.New()
	mutedRecipientID := uuid.New()
	now := time.Now().UTC()
	mutedUntil := now.Add(time.Hour)
	repo := newFakeMessageRepo(conversationID, senderID)
	repo.participantsByConversationUser = map[[2]uuid.UUID]*model.Participant{
		{conversationID, senderID}: {
			ID:             uuid.New(),
			ConversationID: conversationID,
			UserID:         senderID,
			Role:           "member",
			JoinedAt:       now,
		},
		{conversationID, mutedRecipientID}: {
			ID:             uuid.New(),
			ConversationID: conversationID,
			UserID:         mutedRecipientID,
			Role:           "member",
			MutedUntil:     &mutedUntil,
			JoinedAt:       now,
		},
	}
	notifications := newFakeChatNotificationSender()
	useCase := NewMessageUseCase(repo, &fakeEventPublisher{}, nil)
	useCase.SetNotificationSender(notifications)

	_, err := useCase.SendMessage(context.Background(), SendMessageInput{
		ConversationID:    conversationID,
		SenderUserID:      senderID,
		SenderDisplayName: "Aigerim",
		Type:              "text",
		Content:           "Meet near the north gate",
	})
	if err != nil {
		t.Fatalf("SendMessage error: %v", err)
	}
	notifications.expectNone(t)
}

func TestSendMessageRejectsDirectMessageWhenRecipientBlockedSender(t *testing.T) {
	t.Parallel()

	conversationID := uuid.New()
	senderID := uuid.New()
	recipientID := uuid.New()
	now := time.Now().UTC()
	repo := newFakeMessageRepo(conversationID, senderID)
	repo.conversation.Type = "direct"
	repo.participantsByConversationUser = map[[2]uuid.UUID]*model.Participant{
		{conversationID, senderID}: {
			ID:             uuid.New(),
			ConversationID: conversationID,
			UserID:         senderID,
			Role:           "member",
			JoinedAt:       now,
		},
		{conversationID, recipientID}: {
			ID:             uuid.New(),
			ConversationID: conversationID,
			UserID:         recipientID,
			Role:           "member",
			JoinedAt:       now,
		},
	}
	repo.blockedPairs = map[[2]uuid.UUID]bool{
		{recipientID, senderID}: true,
	}

	useCase := NewMessageUseCase(repo, &fakeEventPublisher{}, nil)
	_, err := useCase.SendMessage(context.Background(), SendMessageInput{
		ConversationID: conversationID,
		SenderUserID:   senderID,
		Type:           "text",
		Content:        "hello",
	})
	if err != ErrCannotMessageBlockedUser {
		t.Fatalf("expected ErrCannotMessageBlockedUser, got %v", err)
	}
	if repo.createdMessage != nil {
		t.Fatalf("blocked direct message must not be stored: %+v", repo.createdMessage)
	}
}

func TestToggleReactionEnqueuesOriginalMessageSenderNotificationOutbox(t *testing.T) {
	t.Parallel()

	conversationID := uuid.New()
	messageID := uuid.New()
	actorUserID := uuid.New()
	messageSenderID := uuid.New()
	mutedUserID := uuid.New()
	now := time.Now().UTC()
	mutedUntil := now.Add(time.Hour)

	repo := newFakeMessageRepo(conversationID, actorUserID)
	repo.participantsByConversationUser = map[[2]uuid.UUID]*model.Participant{
		{conversationID, actorUserID}: {
			ID:             uuid.New(),
			ConversationID: conversationID,
			UserID:         actorUserID,
			Role:           "member",
			JoinedAt:       now,
		},
		{conversationID, messageSenderID}: {
			ID:             uuid.New(),
			ConversationID: conversationID,
			UserID:         messageSenderID,
			Role:           "member",
			JoinedAt:       now,
		},
		{conversationID, mutedUserID}: {
			ID:             uuid.New(),
			ConversationID: conversationID,
			UserID:         mutedUserID,
			Role:           "member",
			MutedUntil:     &mutedUntil,
			JoinedAt:       now,
		},
	}
	repo.messagesByID = map[uuid.UUID]*model.Message{
		messageID: {
			ID:             messageID,
			ConversationID: conversationID,
			SenderUserID:   messageSenderID,
			Type:           "text",
			Content:        "Meet near the north gate",
			SentAt:         now,
		},
	}
	notifications := newFakeChatNotificationSender()
	profiles := &fakeUserProfileResolver{
		profiles: map[uuid.UUID]port.PublicUserProfile{
			actorUserID: {UserID: actorUserID, DisplayName: "Aigerim"},
		},
	}
	useCase := NewMessageUseCase(repo, &fakeEventPublisher{}, profiles)
	useCase.SetNotificationSender(notifications)

	_, err := useCase.ToggleReaction(context.Background(), conversationID, messageID, actorUserID, "👍")
	if err != nil {
		t.Fatalf("ToggleReaction error: %v", err)
	}

	notifications.expectNone(t)
	if len(repo.createdNotificationOutbox) != 1 {
		t.Fatalf("outbox entries = %d, want one", len(repo.createdNotificationOutbox))
	}
	item := repo.createdNotificationOutbox[0]
	if item.EventType != chatNotificationEventReaction {
		t.Fatalf("EventType = %q, want %q", item.EventType, chatNotificationEventReaction)
	}
	if item.ConversationID != conversationID || item.MessageID != messageID || item.ActorUserID != actorUserID {
		t.Fatalf("outbox target = conversation %s message %s actor %s", item.ConversationID, item.MessageID, item.ActorUserID)
	}
	if item.ReactionEmoji != "👍" {
		t.Fatalf("ReactionEmoji = %q, want thumbs up", item.ReactionEmoji)
	}
}

func TestSendMessageFlagsOffPlatformContactForModeration(t *testing.T) {
	t.Parallel()

	conversationID := uuid.New()
	senderID := uuid.New()
	repo := newFakeMessageRepo(conversationID, senderID)
	useCase := NewMessageUseCase(repo, &fakeEventPublisher{}, nil)

	msg, err := useCase.SendMessage(context.Background(), SendMessageInput{
		ConversationID: conversationID,
		SenderUserID:   senderID,
		Type:           "text",
		Content:        "Напишите мне в WhatsApp +77011234567 перед участием",
	})
	if err != nil {
		t.Fatalf("SendMessage error: %v", err)
	}

	if msg.ModerationStatus != model.MessageModerationStatusFlagged {
		t.Fatalf("ModerationStatus = %q, want %q", msg.ModerationStatus, model.MessageModerationStatusFlagged)
	}
	if msg.ModerationRiskScore <= 0 {
		t.Fatalf("ModerationRiskScore = %d, want positive", msg.ModerationRiskScore)
	}
	if !containsString(msg.ModerationReasonCodes, "off_platform_contact") {
		t.Fatalf("ModerationReasonCodes = %#v, want off_platform_contact", msg.ModerationReasonCodes)
	}
	if !containsString(msg.ModerationReasonCodes, "phone_number") {
		t.Fatalf("ModerationReasonCodes = %#v, want phone_number", msg.ModerationReasonCodes)
	}
	if msg.ModerationTriggeredAt == nil {
		t.Fatal("ModerationTriggeredAt must be set for flagged messages")
	}
}

func TestForwardMessageCreatesTargetCopyAndTracksForwardMetadata(t *testing.T) {
	t.Parallel()

	sourceConversationID := uuid.New()
	targetConversationID := uuid.New()
	actorUserID := uuid.New()
	originalSenderID := uuid.New()
	sourceMessageID := uuid.New()
	now := time.Now().UTC()
	repo := newFakeMessageRepo(sourceConversationID, actorUserID)
	repo.conversationsByID = map[uuid.UUID]*model.Conversation{
		sourceConversationID: repo.conversation,
		targetConversationID: {
			ID:             targetConversationID,
			Type:           "group",
			CreatedAt:      now,
			LastActivityAt: now,
		},
	}
	repo.participantsByConversationUser = map[[2]uuid.UUID]*model.Participant{
		{sourceConversationID, actorUserID}: repo.participant,
		{targetConversationID, actorUserID}: {
			ID:             uuid.New(),
			ConversationID: targetConversationID,
			UserID:         actorUserID,
			Role:           "member",
			JoinedAt:       now,
		},
	}
	repo.messagesByID = map[uuid.UUID]*model.Message{
		sourceMessageID: {
			ID:                sourceMessageID,
			ConversationID:    sourceConversationID,
			SenderUserID:      originalSenderID,
			SenderDisplayName: "Aigerim",
			Type:              "text",
			Content:           "Meet near the north gate",
			SentAt:            now.Add(-time.Minute),
		},
	}

	useCase := NewMessageUseCase(repo, &fakeEventPublisher{}, nil)
	forwarded, err := useCase.ForwardMessage(context.Background(), ForwardMessageInput{
		SourceConversationID: sourceConversationID,
		TargetConversationID: targetConversationID,
		MessageID:            sourceMessageID,
		SenderUserID:         actorUserID,
	})
	if err != nil {
		t.Fatalf("forward message failed: %v", err)
	}

	if forwarded.ConversationID != targetConversationID {
		t.Fatalf("forwarded message must be created in target conversation")
	}
	if forwarded.Content != "Meet near the north gate" {
		t.Fatalf("forwarded content mismatch: %q", forwarded.Content)
	}
	if forwarded.ForwardedFromMessageID == nil || *forwarded.ForwardedFromMessageID != sourceMessageID {
		t.Fatalf("forwarded source message id was not preserved")
	}
	if forwarded.ForwardedFromSenderName != "Aigerim" {
		t.Fatalf("forwarded source sender name mismatch: %q", forwarded.ForwardedFromSenderName)
	}
	if repo.messagesByID[sourceMessageID].ForwardCount != 1 {
		t.Fatalf("source forward count = %d, want 1", repo.messagesByID[sourceMessageID].ForwardCount)
	}
}

func TestForwardMessageRejectsDirectTargetWhenRecipientBlockedSender(t *testing.T) {
	t.Parallel()

	sourceConversationID := uuid.New()
	targetConversationID := uuid.New()
	sourceMessageID := uuid.New()
	actorUserID := uuid.New()
	recipientID := uuid.New()
	sourceSenderID := uuid.New()
	now := time.Now().UTC()
	repo := newFakeMessageRepo(targetConversationID, actorUserID)
	repo.conversationsByID = map[uuid.UUID]*model.Conversation{
		sourceConversationID: {
			ID:             sourceConversationID,
			Type:           "group",
			CreatedAt:      now,
			LastActivityAt: now,
		},
		targetConversationID: {
			ID:             targetConversationID,
			Type:           "direct",
			CreatedAt:      now,
			LastActivityAt: now,
		},
	}
	repo.participantsByConversationUser = map[[2]uuid.UUID]*model.Participant{
		{sourceConversationID, actorUserID}: {
			ID:             uuid.New(),
			ConversationID: sourceConversationID,
			UserID:         actorUserID,
			Role:           "member",
			JoinedAt:       now,
		},
		{targetConversationID, actorUserID}: {
			ID:             uuid.New(),
			ConversationID: targetConversationID,
			UserID:         actorUserID,
			Role:           "member",
			JoinedAt:       now,
		},
		{targetConversationID, recipientID}: {
			ID:             uuid.New(),
			ConversationID: targetConversationID,
			UserID:         recipientID,
			Role:           "member",
			JoinedAt:       now,
		},
	}
	repo.messagesByID = map[uuid.UUID]*model.Message{
		sourceMessageID: {
			ID:             sourceMessageID,
			ConversationID: sourceConversationID,
			SenderUserID:   sourceSenderID,
			Type:           "text",
			Content:        "Meet near the north gate",
			SentAt:         now,
		},
	}
	repo.blockedPairs = map[[2]uuid.UUID]bool{
		{recipientID, actorUserID}: true,
	}

	useCase := NewMessageUseCase(repo, &fakeEventPublisher{}, nil)
	_, err := useCase.ForwardMessage(context.Background(), ForwardMessageInput{
		SourceConversationID: sourceConversationID,
		TargetConversationID: targetConversationID,
		MessageID:            sourceMessageID,
		SenderUserID:         actorUserID,
	})
	if err != ErrCannotMessageBlockedUser {
		t.Fatalf("expected ErrCannotMessageBlockedUser, got %v", err)
	}
	if repo.messagesByID[sourceMessageID].ForwardCount != 0 {
		t.Fatalf("blocked forward must not increment source forward count")
	}
}

type fakeMessageRepo struct {
	conversationID                                uuid.UUID
	senderID                                      uuid.UUID
	conversation                                  *model.Conversation
	participant                                   *model.Participant
	createdMessage                                *model.Message
	createMessageCalls                            int
	listConversations                             []*model.Conversation
	conversationsByID                             map[uuid.UUID]*model.Conversation
	conversationsByExcursionSlotID                map[uuid.UUID]*model.Conversation
	participantsByConversationUser                map[[2]uuid.UUID]*model.Participant
	participantsByConversation                    map[uuid.UUID][]*model.Participant
	createdParticipants                           []*model.Participant
	messagesByID                                  map[uuid.UUID]*model.Message
	messagesByClientMessageID                     map[[3]uuid.UUID]*model.Message
	lastMessagesByConversation                    map[uuid.UUID]*model.Message
	messageFileIDs                                map[uuid.UUID][]string
	unreadCountsByConversation                    map[uuid.UUID]int
	activeParticipantCountsByConversation         map[uuid.UUID]int
	createdNotificationOutbox                     []*model.ChatNotificationOutbox
	claimedNotificationOutbox                     []*model.ChatNotificationOutbox
	sentNotificationOutboxIDs                     []uuid.UUID
	retriedNotificationOutbox                     []notificationOutboxRetry
	failedNotificationOutbox                      []notificationOutboxFailure
	blockedPairs                                  map[[2]uuid.UUID]bool
	blockLookupCount                              int
	blockListLookupCount                          int
	listParticipantsCalls                         int
	listParticipantsByConversationIDsCalls        int
	getParticipantCalls                           int
	listParticipantsByConversationUserIDsCalls    int
	countActiveParticipantsCalls                  int
	countActiveParticipantsByConversationIDsCalls int
	getUnreadCountCalls                           int
	listUnreadCountsByConversationIDsCalls        int
	getLastMessageCalls                           int
	listLastMessagesByConversationIDsCalls        int
	getMessageFileIDsCalls                        int
	listMessageFileIDsCalls                       int
}

type notificationOutboxRetry struct {
	id            uuid.UUID
	nextAttemptAt time.Time
	lastError     string
}

type notificationOutboxFailure struct {
	id        uuid.UUID
	failedAt  time.Time
	lastError string
}

func newFakeMessageRepo(conversationID, senderID uuid.UUID) *fakeMessageRepo {
	now := time.Now().UTC()
	return &fakeMessageRepo{
		conversationID: conversationID,
		senderID:       senderID,
		conversation: &model.Conversation{
			ID:             conversationID,
			Type:           "group",
			CreatedAt:      now,
			LastActivityAt: now,
		},
		participant: &model.Participant{
			ID:             uuid.New(),
			ConversationID: conversationID,
			UserID:         senderID,
			Role:           "member",
			JoinedAt:       now,
		},
	}
}

func (r *fakeMessageRepo) GetConversationByID(_ context.Context, conversationID uuid.UUID) (*model.Conversation, error) {
	if r.conversationsByID != nil {
		if conv := r.conversationsByID[conversationID]; conv != nil {
			return conv, nil
		}
	}
	return r.conversation, nil
}

func (r *fakeMessageRepo) GetParticipant(_ context.Context, conversationID, userID uuid.UUID) (*model.Participant, error) {
	r.getParticipantCalls++
	if r.participantsByConversationUser != nil {
		return r.participantsByConversationUser[[2]uuid.UUID{conversationID, userID}], nil
	}
	return r.participant, nil
}

func (r *fakeMessageRepo) WithTx(ctx context.Context, fn func(repo port.ChatTxRepository) error) error {
	return fn(r)
}

func (r *fakeMessageRepo) CreateMessage(_ context.Context, msg *model.Message) error {
	r.createMessageCalls++
	copyValue := *msg
	r.createdMessage = &copyValue
	if r.messagesByID != nil {
		r.messagesByID[msg.ID] = &copyValue
	}
	if r.messagesByClientMessageID != nil && msg.ClientMessageID != nil {
		r.messagesByClientMessageID[[3]uuid.UUID{msg.ConversationID, msg.SenderUserID, *msg.ClientMessageID}] = &copyValue
	}
	return nil
}

func (r *fakeMessageRepo) CreateConversation(_ context.Context, conv *model.Conversation) error {
	if r.conversationsByID != nil {
		r.conversationsByID[conv.ID] = conv
	}
	if r.conversationsByExcursionSlotID != nil && conv.ExcursionScheduleSlotID != nil {
		r.conversationsByExcursionSlotID[*conv.ExcursionScheduleSlotID] = conv
	}
	return nil
}

func (r *fakeMessageRepo) CreateMessageFiles(_ context.Context, messageID uuid.UUID, fileIDs []string) error {
	copied := append([]string(nil), fileIDs...)
	if r.messageFileIDs != nil {
		r.messageFileIDs[messageID] = copied
	}
	if r.messagesByID != nil && r.messagesByID[messageID] != nil {
		r.messagesByID[messageID].FileIDs = copied
	}
	return nil
}

func (r *fakeMessageRepo) GetConversationByIDForUpdate(_ context.Context, conversationID uuid.UUID) (*model.Conversation, error) {
	if r.conversationsByID != nil {
		return r.conversationsByID[conversationID], nil
	}
	return r.conversation, nil
}

func (r *fakeMessageRepo) UpdateConversation(_ context.Context, conv *model.Conversation) error {
	r.conversation = conv
	if r.conversationsByID != nil {
		r.conversationsByID[conv.ID] = conv
	}
	return nil
}

func (r *fakeMessageRepo) ListConversationsByUserID(context.Context, port.ConversationFilter) ([]*model.Conversation, error) {
	return r.listConversations, nil
}

func (r *fakeMessageRepo) FindDirectConversation(context.Context, uuid.UUID, uuid.UUID) (*model.Conversation, error) {
	return nil, nil
}

func (r *fakeMessageRepo) GetConversationByActivityID(context.Context, uuid.UUID) (*model.Conversation, error) {
	return nil, nil
}

func (r *fakeMessageRepo) GetConversationByExcursionScheduleSlotID(
	_ context.Context,
	slotID uuid.UUID,
) (*model.Conversation, error) {
	if r.conversationsByExcursionSlotID != nil {
		return r.conversationsByExcursionSlotID[slotID], nil
	}
	return nil, nil
}

func (r *fakeMessageRepo) GetMessageByID(_ context.Context, messageID uuid.UUID) (*model.Message, error) {
	if r.messagesByID != nil {
		return r.messagesByID[messageID], nil
	}
	return nil, nil
}

func (r *fakeMessageRepo) GetMessageByIDForUpdate(_ context.Context, messageID uuid.UUID) (*model.Message, error) {
	if r.messagesByID != nil {
		return r.messagesByID[messageID], nil
	}
	return nil, nil
}

func (r *fakeMessageRepo) GetMessageByClientMessageID(
	_ context.Context,
	conversationID uuid.UUID,
	senderUserID uuid.UUID,
	clientMessageID uuid.UUID,
) (*model.Message, error) {
	if r.messagesByClientMessageID == nil {
		return nil, nil
	}
	return r.messagesByClientMessageID[[3]uuid.UUID{conversationID, senderUserID, clientMessageID}], nil
}

func (r *fakeMessageRepo) ListMessages(context.Context, port.MessageFilter) ([]*model.Message, error) {
	return nil, nil
}

func (r *fakeMessageRepo) ListMessageReactionSummaries(
	context.Context,
	[]uuid.UUID,
	uuid.UUID,
) (map[uuid.UUID][]model.MessageReactionSummary, error) {
	return nil, nil
}

func (r *fakeMessageRepo) ListMessageReadReceipts(
	context.Context,
	[]uuid.UUID,
) (map[uuid.UUID][]model.MessageReadReceipt, error) {
	return nil, nil
}

func (r *fakeMessageRepo) ListParticipantsByConversationID(_ context.Context, conversationID uuid.UUID) ([]*model.Participant, error) {
	r.listParticipantsCalls++
	if r.participantsByConversation != nil {
		return r.participantsByConversation[conversationID], nil
	}
	if r.participantsByConversationUser != nil {
		participants := make([]*model.Participant, 0, len(r.participantsByConversationUser))
		for key, participant := range r.participantsByConversationUser {
			if key[0] == conversationID {
				participants = append(participants, participant)
			}
		}
		return participants, nil
	}
	return nil, nil
}

func (r *fakeMessageRepo) ListParticipantsByConversationIDs(
	_ context.Context,
	conversationIDs []uuid.UUID,
) (map[uuid.UUID][]*model.Participant, error) {
	r.listParticipantsByConversationIDsCalls++
	result := make(map[uuid.UUID][]*model.Participant, len(conversationIDs))
	if r.participantsByConversation != nil {
		for _, conversationID := range conversationIDs {
			result[conversationID] = r.participantsByConversation[conversationID]
		}
		return result, nil
	}
	if r.participantsByConversationUser != nil {
		for key, participant := range r.participantsByConversationUser {
			result[key[0]] = append(result[key[0]], participant)
		}
	}
	return result, nil
}

func (r *fakeMessageRepo) ListParticipantsByConversationUserIDs(
	_ context.Context,
	conversationIDs []uuid.UUID,
	userID uuid.UUID,
) (map[uuid.UUID]*model.Participant, error) {
	r.listParticipantsByConversationUserIDsCalls++
	result := make(map[uuid.UUID]*model.Participant, len(conversationIDs))
	for _, conversationID := range conversationIDs {
		if r.participantsByConversationUser != nil {
			if participant := r.participantsByConversationUser[[2]uuid.UUID{conversationID, userID}]; participant != nil {
				result[conversationID] = participant
				continue
			}
		}
		if r.participantsByConversation != nil {
			for _, participant := range r.participantsByConversation[conversationID] {
				if participant != nil && participant.UserID == userID {
					result[conversationID] = participant
					break
				}
			}
		}
	}
	return result, nil
}

func (r *fakeMessageRepo) IsUserBlocked(_ context.Context, blockerUserID, blockedUserID uuid.UUID) (bool, error) {
	r.blockLookupCount++
	return r.blockedPairs[[2]uuid.UUID{blockerUserID, blockedUserID}], nil
}

func (r *fakeMessageRepo) ListUserIDsBlockingUser(
	_ context.Context,
	blockedUserID uuid.UUID,
	candidateBlockerUserIDs []uuid.UUID,
) (map[uuid.UUID]bool, error) {
	r.blockListLookupCount++
	result := make(map[uuid.UUID]bool)
	for _, blockerUserID := range candidateBlockerUserIDs {
		if r.blockedPairs[[2]uuid.UUID{blockerUserID, blockedUserID}] {
			result[blockerUserID] = true
		}
	}
	return result, nil
}

func (r *fakeMessageRepo) UpsertUserBlock(_ context.Context, block *model.UserBlock) error {
	if r.blockedPairs == nil {
		r.blockedPairs = map[[2]uuid.UUID]bool{}
	}
	r.blockedPairs[[2]uuid.UUID{block.BlockerUserID, block.BlockedUserID}] = true
	return nil
}

func (r *fakeMessageRepo) DeleteUserBlock(_ context.Context, blockerUserID, blockedUserID uuid.UUID) error {
	delete(r.blockedPairs, [2]uuid.UUID{blockerUserID, blockedUserID})
	return nil
}

func (r *fakeMessageRepo) CountActiveParticipants(_ context.Context, conversationID uuid.UUID) (int, error) {
	r.countActiveParticipantsCalls++
	if r.activeParticipantCountsByConversation != nil {
		return r.activeParticipantCountsByConversation[conversationID], nil
	}
	return 1, nil
}

func (r *fakeMessageRepo) CountActiveParticipantsByConversationIDs(
	_ context.Context,
	conversationIDs []uuid.UUID,
) (map[uuid.UUID]int, error) {
	r.countActiveParticipantsByConversationIDsCalls++
	result := make(map[uuid.UUID]int, len(conversationIDs))
	for _, conversationID := range conversationIDs {
		if r.activeParticipantCountsByConversation != nil {
			result[conversationID] = r.activeParticipantCountsByConversation[conversationID]
			continue
		}
		if r.participantsByConversation != nil {
			result[conversationID] = len(r.participantsByConversation[conversationID])
			continue
		}
		result[conversationID] = 1
	}
	return result, nil
}

func (r *fakeMessageRepo) GetUnreadCount(_ context.Context, conversationID, _ uuid.UUID) (int, error) {
	r.getUnreadCountCalls++
	if r.unreadCountsByConversation != nil {
		return r.unreadCountsByConversation[conversationID], nil
	}
	return 0, nil
}

func (r *fakeMessageRepo) ListUnreadCountsByConversationIDs(
	_ context.Context,
	conversationIDs []uuid.UUID,
	_ uuid.UUID,
) (map[uuid.UUID]int, error) {
	r.listUnreadCountsByConversationIDsCalls++
	result := make(map[uuid.UUID]int, len(conversationIDs))
	for _, conversationID := range conversationIDs {
		if r.unreadCountsByConversation != nil {
			result[conversationID] = r.unreadCountsByConversation[conversationID]
		}
	}
	return result, nil
}

func (r *fakeMessageRepo) GetLastMessage(_ context.Context, conversationID uuid.UUID) (*model.Message, error) {
	r.getLastMessageCalls++
	if r.lastMessagesByConversation != nil {
		return r.lastMessagesByConversation[conversationID], nil
	}
	return nil, nil
}

func (r *fakeMessageRepo) ListLastMessagesByConversationIDs(
	_ context.Context,
	conversationIDs []uuid.UUID,
) (map[uuid.UUID]*model.Message, error) {
	r.listLastMessagesByConversationIDsCalls++
	result := make(map[uuid.UUID]*model.Message, len(conversationIDs))
	for _, conversationID := range conversationIDs {
		if r.lastMessagesByConversation != nil {
			result[conversationID] = r.lastMessagesByConversation[conversationID]
		}
	}
	return result, nil
}

func (r *fakeMessageRepo) GetMessageFileIDs(_ context.Context, messageID uuid.UUID) ([]string, error) {
	r.getMessageFileIDsCalls++
	if r.messageFileIDs != nil {
		return r.messageFileIDs[messageID], nil
	}
	if r.messagesByID != nil && r.messagesByID[messageID] != nil {
		return r.messagesByID[messageID].FileIDs, nil
	}
	return nil, nil
}

func (r *fakeMessageRepo) ListMessageFileIDs(
	_ context.Context,
	messageIDs []uuid.UUID,
) (map[uuid.UUID][]string, error) {
	r.listMessageFileIDsCalls++
	result := make(map[uuid.UUID][]string, len(messageIDs))
	for _, messageID := range messageIDs {
		if r.messageFileIDs != nil {
			result[messageID] = r.messageFileIDs[messageID]
			continue
		}
		if r.messagesByID != nil && r.messagesByID[messageID] != nil {
			result[messageID] = r.messagesByID[messageID].FileIDs
		}
	}
	return result, nil
}

func (r *fakeMessageRepo) ListPinnedMessagesByConversationID(context.Context, uuid.UUID) ([]*model.ConversationPin, error) {
	return nil, nil
}

func (r *fakeMessageRepo) ClaimDueChatNotificationOutbox(
	context.Context,
	time.Time,
	int,
) ([]*model.ChatNotificationOutbox, error) {
	return r.claimedNotificationOutbox, nil
}

func (r *fakeMessageRepo) MarkChatNotificationOutboxSent(_ context.Context, outboxID uuid.UUID, _ time.Time) error {
	r.sentNotificationOutboxIDs = append(r.sentNotificationOutboxIDs, outboxID)
	return nil
}

func (r *fakeMessageRepo) RetryChatNotificationOutbox(
	_ context.Context,
	outboxID uuid.UUID,
	nextAttemptAt time.Time,
	lastError string,
) error {
	r.retriedNotificationOutbox = append(r.retriedNotificationOutbox, notificationOutboxRetry{
		id:            outboxID,
		nextAttemptAt: nextAttemptAt,
		lastError:     lastError,
	})
	return nil
}

func (r *fakeMessageRepo) FailChatNotificationOutbox(
	_ context.Context,
	outboxID uuid.UUID,
	failedAt time.Time,
	lastError string,
) error {
	r.failedNotificationOutbox = append(r.failedNotificationOutbox, notificationOutboxFailure{
		id:        outboxID,
		failedAt:  failedAt,
		lastError: lastError,
	})
	return nil
}

func (r *fakeMessageRepo) ListFlaggedMessagesForModeration(
	context.Context,
	port.ChatModerationFilter,
) ([]*model.ChatMessageModerationItem, error) {
	if r.createdMessage == nil || r.createdMessage.ModerationStatus != model.MessageModerationStatusFlagged {
		return nil, nil
	}
	return []*model.ChatMessageModerationItem{
		chatModerationItemFromMessage(r.createdMessage),
	}, nil
}

func (r *fakeMessageRepo) GetMessageForModeration(
	_ context.Context,
	messageID uuid.UUID,
	_ int,
	_ int,
) (*model.ChatMessageModerationItem, error) {
	if r.createdMessage != nil && r.createdMessage.ID == messageID {
		return chatModerationItemFromMessage(r.createdMessage), nil
	}
	if r.messagesByID != nil && r.messagesByID[messageID] != nil {
		return chatModerationItemFromMessage(r.messagesByID[messageID]), nil
	}
	return nil, nil
}

func (r *fakeMessageRepo) UpdateMessageModeration(
	_ context.Context,
	messageID uuid.UUID,
	status string,
	reasonCodes []string,
	publicComment string,
	internalComment string,
	moderatedBy uuid.UUID,
	now time.Time,
) (*model.Message, error) {
	msg := r.createdMessage
	if r.messagesByID != nil && r.messagesByID[messageID] != nil {
		msg = r.messagesByID[messageID]
	}
	if msg == nil || msg.ID != messageID {
		return nil, nil
	}
	msg.ModerationStatus = status
	msg.ModerationReasonCodes = append([]string(nil), reasonCodes...)
	msg.ModerationPublicComment = publicComment
	msg.ModerationInternalComment = internalComment
	msg.ModerationReviewedBy = &moderatedBy
	msg.ModerationReviewedAt = &now
	msg.ModerationRevision++
	return msg, nil
}

func (r *fakeMessageRepo) GetConversationByActivityIDForUpdate(context.Context, uuid.UUID) (*model.Conversation, error) {
	return nil, nil
}

func (r *fakeMessageRepo) GetConversationByExcursionScheduleSlotIDForUpdate(
	_ context.Context,
	slotID uuid.UUID,
) (*model.Conversation, error) {
	if r.conversationsByExcursionSlotID != nil {
		return r.conversationsByExcursionSlotID[slotID], nil
	}
	return nil, nil
}

func (r *fakeMessageRepo) GetParticipantForUpdate(_ context.Context, conversationID, userID uuid.UUID) (*model.Participant, error) {
	if r.participantsByConversationUser != nil {
		return r.participantsByConversationUser[[2]uuid.UUID{conversationID, userID}], nil
	}
	return r.participant, nil
}

func (r *fakeMessageRepo) CountActiveParticipantsTx(context.Context, uuid.UUID) (int, error) {
	return 1, nil
}

func (r *fakeMessageRepo) CreateParticipant(_ context.Context, p *model.Participant) error {
	copyValue := *p
	r.createdParticipants = append(r.createdParticipants, &copyValue)
	if r.participantsByConversationUser != nil {
		r.participantsByConversationUser[[2]uuid.UUID{p.ConversationID, p.UserID}] = &copyValue
	}
	return nil
}

func (r *fakeMessageRepo) UpdateParticipant(context.Context, *model.Participant) error {
	return nil
}

func (r *fakeMessageRepo) UpdateMessage(_ context.Context, msg *model.Message) error {
	if r.messagesByID != nil {
		copyValue := *msg
		r.messagesByID[msg.ID] = &copyValue
	}
	return nil
}

func (r *fakeMessageRepo) DeleteMessage(context.Context, uuid.UUID) error {
	return nil
}

func (r *fakeMessageRepo) GetMessageReactionForUpdate(context.Context, uuid.UUID, uuid.UUID) (*model.MessageReaction, error) {
	return nil, nil
}

func (r *fakeMessageRepo) SetMessageReaction(context.Context, *model.MessageReaction) error {
	return nil
}

func (r *fakeMessageRepo) DeleteMessageReaction(context.Context, uuid.UUID, uuid.UUID) error {
	return nil
}

func (r *fakeMessageRepo) CreateConversationPin(context.Context, *model.ConversationPin) error {
	return nil
}

func (r *fakeMessageRepo) DeleteConversationPin(context.Context, uuid.UUID, uuid.UUID) (bool, error) {
	return false, nil
}

func (r *fakeMessageRepo) DeleteConversationPinsByMessageID(context.Context, uuid.UUID) (int64, error) {
	return 0, nil
}

func (r *fakeMessageRepo) CreateChatNotificationOutbox(_ context.Context, item *model.ChatNotificationOutbox) error {
	if item == nil {
		return nil
	}
	copyValue := *item
	r.createdNotificationOutbox = append(r.createdNotificationOutbox, &copyValue)
	return nil
}

func (r *fakeMessageRepo) GetPreviousMessage(context.Context, uuid.UUID, time.Time, uuid.UUID) (*model.Message, error) {
	return nil, nil
}

func (r *fakeMessageRepo) HasReadByOtherParticipant(context.Context, uuid.UUID, uuid.UUID, uuid.UUID) (bool, error) {
	return false, nil
}

func (r *fakeMessageRepo) ReplaceLastReadMessageID(context.Context, uuid.UUID, uuid.UUID, *uuid.UUID) error {
	return nil
}

func (r *fakeMessageRepo) CreateReadReceiptsUpToMessage(context.Context, uuid.UUID, uuid.UUID, uuid.UUID, time.Time) error {
	return nil
}

type fakeStickerResolver struct {
	senderUserID uuid.UUID
	stickerID    uuid.UUID
	result       *port.StickerMetadata
	err          error
}

func (f *fakeStickerResolver) ValidateSend(
	_ context.Context,
	senderUserID uuid.UUID,
	stickerID uuid.UUID,
) (*port.StickerMetadata, error) {
	f.senderUserID = senderUserID
	f.stickerID = stickerID
	return f.result, f.err
}

type fakeTrustPolicyClient struct {
	check  port.TrustPolicyCheck
	result port.TrustPolicyResult
	err    error
}

func (f *fakeTrustPolicyClient) CheckActionPolicy(
	_ context.Context,
	check port.TrustPolicyCheck,
) (port.TrustPolicyResult, error) {
	f.check = check
	return f.result, f.err
}

type fakeEventPublisher struct{}

func (fakeEventPublisher) Publish(context.Context, string, event.Event) error { return nil }
func (fakeEventPublisher) Close() error                                       { return nil }

type fakeUserProfileResolver struct {
	profiles map[uuid.UUID]port.PublicUserProfile
	calls    int
}

func (f *fakeUserProfileResolver) GetPublicProfilesByUserIDs(
	_ context.Context,
	userIDs []uuid.UUID,
) (map[uuid.UUID]port.PublicUserProfile, error) {
	f.calls++
	result := make(map[uuid.UUID]port.PublicUserProfile)
	for _, userID := range userIDs {
		if profile, ok := f.profiles[userID]; ok {
			result[userID] = profile
		}
	}
	return result, nil
}

type fakeChatNotificationSender struct {
	sent chan port.ChatNotification
	err  error
}

func newFakeChatNotificationSender() *fakeChatNotificationSender {
	return &fakeChatNotificationSender{sent: make(chan port.ChatNotification, 1)}
}

func (f *fakeChatNotificationSender) SendChatMessageNotification(
	_ context.Context,
	notification port.ChatNotification,
) error {
	if f.err != nil {
		return f.err
	}
	f.sent <- notification
	return nil
}

func (f *fakeChatNotificationSender) take(t *testing.T) port.ChatNotification {
	t.Helper()
	select {
	case notification := <-f.sent:
		return notification
	case <-time.After(time.Second):
		t.Fatal("expected chat notification to be sent")
		return port.ChatNotification{}
	}
}

func (f *fakeChatNotificationSender) expectNone(t *testing.T) {
	t.Helper()
	select {
	case notification := <-f.sent:
		t.Fatalf("expected no chat notification, got %+v", notification)
	case <-time.After(50 * time.Millisecond):
		return
	}
}

func chatModerationItemFromMessage(msg *model.Message) *model.ChatMessageModerationItem {
	if msg == nil {
		return nil
	}
	return &model.ChatMessageModerationItem{
		ID:                    msg.ID,
		ConversationID:        msg.ConversationID,
		SenderUserID:          msg.SenderUserID,
		SenderDisplayName:     msg.SenderDisplayName,
		Type:                  msg.Type,
		Content:               msg.Content,
		FileIDs:               append([]string(nil), msg.FileIDs...),
		ModerationStatus:      msg.ModerationStatus,
		ModerationRiskScore:   msg.ModerationRiskScore,
		ModerationReasonCodes: append([]string(nil), msg.ModerationReasonCodes...),
		ModerationTriggeredAt: msg.ModerationTriggeredAt,
		ModerationReviewedAt:  msg.ModerationReviewedAt,
		Revision:              msg.ModerationRevision,
		SentAt:                msg.SentAt,
	}
}

func containsString(values []string, expected string) bool {
	for _, value := range values {
		if value == expected {
			return true
		}
	}
	return false
}
