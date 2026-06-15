package app

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/chat-service/internal/domain/model"
	"kz/inflap/backend/services/chat-service/internal/domain/port"
)

func TestChatNotificationDispatcherSendsMessageOutboxAndMarksSent(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, 6, 5, 12, 0, 0, 0, time.UTC)
	conversationID := uuid.New()
	messageID := uuid.New()
	senderID := uuid.New()
	recipientID := uuid.New()
	mutedRecipientID := uuid.New()
	blockedRecipientID := uuid.New()
	outboxID := uuid.New()
	mutedUntil := time.Now().UTC().Add(time.Hour)
	repo := newFakeMessageRepo(conversationID, senderID)
	repo.claimedNotificationOutbox = []*model.ChatNotificationOutbox{
		{
			ID:             outboxID,
			EventType:      chatNotificationEventMessage,
			ConversationID: conversationID,
			MessageID:      messageID,
			ActorUserID:    senderID,
			Attempts:       1,
			CreatedAt:      now.Add(-time.Second),
		},
	}
	repo.messagesByID = map[uuid.UUID]*model.Message{
		messageID: {
			ID:             messageID,
			ConversationID: conversationID,
			SenderUserID:   senderID,
			Type:           "text",
			Content:        "Meet near the north gate",
			SentAt:         now,
		},
	}
	repo.participantsByConversationUser = map[[2]uuid.UUID]*model.Participant{
		{conversationID, senderID}: {
			ID:             uuid.New(),
			ConversationID: conversationID,
			UserID:         senderID,
			Role:           "member",
			JoinedAt:       now.Add(-time.Hour),
		},
		{conversationID, recipientID}: {
			ID:             uuid.New(),
			ConversationID: conversationID,
			UserID:         recipientID,
			Role:           "member",
			JoinedAt:       now.Add(-time.Hour),
		},
		{conversationID, mutedRecipientID}: {
			ID:             uuid.New(),
			ConversationID: conversationID,
			UserID:         mutedRecipientID,
			Role:           "member",
			MutedUntil:     &mutedUntil,
			JoinedAt:       now.Add(-time.Hour),
		},
		{conversationID, blockedRecipientID}: {
			ID:             uuid.New(),
			ConversationID: conversationID,
			UserID:         blockedRecipientID,
			Role:           "member",
			JoinedAt:       now.Add(-time.Hour),
		},
	}
	repo.blockedPairs = map[[2]uuid.UUID]bool{
		{blockedRecipientID, senderID}: true,
	}
	profiles := &fakeUserProfileResolver{
		profiles: map[uuid.UUID]port.PublicUserProfile{
			senderID: {UserID: senderID, DisplayName: "Aigerim"},
		},
	}
	sender := newFakeChatNotificationSender()
	dispatcher := NewChatNotificationDispatcher(repo, sender, profiles, ChatNotificationDispatcherConfig{})

	processed, err := dispatcher.DispatchDue(context.Background(), now, 10)
	if err != nil {
		t.Fatalf("DispatchDue error: %v", err)
	}

	if processed != 1 {
		t.Fatalf("processed = %d, want 1", processed)
	}
	notification := sender.take(t)
	if notification.EventType != chatNotificationEventMessage {
		t.Fatalf("EventType = %q, want %q", notification.EventType, chatNotificationEventMessage)
	}
	if notification.ConversationID != conversationID || notification.MessageID != messageID || notification.SenderUserID != senderID {
		t.Fatalf("notification target = conversation %s message %s sender %s", notification.ConversationID, notification.MessageID, notification.SenderUserID)
	}
	if notification.SenderDisplayName != "Aigerim" {
		t.Fatalf("SenderDisplayName = %q, want Aigerim", notification.SenderDisplayName)
	}
	if notification.Body != "Meet near the north gate" {
		t.Fatalf("Body = %q, want message body", notification.Body)
	}
	if len(notification.RecipientUserIDs) != 1 || notification.RecipientUserIDs[0] != recipientID {
		t.Fatalf("RecipientUserIDs = %v, want only %s", notification.RecipientUserIDs, recipientID)
	}
	if len(repo.sentNotificationOutboxIDs) != 1 || repo.sentNotificationOutboxIDs[0] != outboxID {
		t.Fatalf("sent outbox IDs = %v, want %s", repo.sentNotificationOutboxIDs, outboxID)
	}
	if len(repo.retriedNotificationOutbox) != 0 {
		t.Fatalf("retry entries = %+v, want none", repo.retriedNotificationOutbox)
	}
}

func TestChatNotificationDispatcherRetriesFailedSendWithBackoff(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, 6, 5, 12, 0, 0, 0, time.UTC)
	conversationID := uuid.New()
	messageID := uuid.New()
	senderID := uuid.New()
	recipientID := uuid.New()
	outboxID := uuid.New()
	repo := newFakeMessageRepo(conversationID, senderID)
	repo.claimedNotificationOutbox = []*model.ChatNotificationOutbox{
		{
			ID:             outboxID,
			EventType:      chatNotificationEventMessage,
			ConversationID: conversationID,
			MessageID:      messageID,
			ActorUserID:    senderID,
			Attempts:       2,
			CreatedAt:      now.Add(-time.Second),
		},
	}
	repo.messagesByID = map[uuid.UUID]*model.Message{
		messageID: {
			ID:             messageID,
			ConversationID: conversationID,
			SenderUserID:   senderID,
			Type:           "text",
			Content:        "Retry me",
			SentAt:         now,
		},
	}
	repo.participantsByConversationUser = map[[2]uuid.UUID]*model.Participant{
		{conversationID, senderID}: {
			ID:             uuid.New(),
			ConversationID: conversationID,
			UserID:         senderID,
			Role:           "member",
			JoinedAt:       now.Add(-time.Hour),
		},
		{conversationID, recipientID}: {
			ID:             uuid.New(),
			ConversationID: conversationID,
			UserID:         recipientID,
			Role:           "member",
			JoinedAt:       now.Add(-time.Hour),
		},
	}
	sender := newFakeChatNotificationSender()
	sender.err = errors.New("notification-service timeout")
	dispatcher := NewChatNotificationDispatcher(repo, sender, nil, ChatNotificationDispatcherConfig{
		BaseRetryDelay: time.Second,
		MaxRetryDelay:  30 * time.Second,
		MaxAttempts:    5,
	})

	processed, err := dispatcher.DispatchDue(context.Background(), now, 10)
	if err != nil {
		t.Fatalf("DispatchDue error: %v", err)
	}

	if processed != 0 {
		t.Fatalf("processed = %d, want failed item not counted as sent", processed)
	}
	if len(repo.sentNotificationOutboxIDs) != 0 {
		t.Fatalf("sent outbox IDs = %v, want none", repo.sentNotificationOutboxIDs)
	}
	if len(repo.retriedNotificationOutbox) != 1 {
		t.Fatalf("retry entries = %d, want one", len(repo.retriedNotificationOutbox))
	}
	retry := repo.retriedNotificationOutbox[0]
	if retry.id != outboxID {
		t.Fatalf("retry id = %s, want %s", retry.id, outboxID)
	}
	if !retry.nextAttemptAt.After(now) {
		t.Fatalf("nextAttemptAt = %s, want after %s", retry.nextAttemptAt, now)
	}
	if retry.lastError == "" {
		t.Fatal("lastError must be stored for observability")
	}
}
