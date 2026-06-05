package app

import (
	"context"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/chat-service/internal/domain/model"
	"kz/inflap/backend/services/chat-service/internal/domain/port"
)

func TestNewSystemMessageDefaultsModerationFields(t *testing.T) {
	t.Parallel()

	msg := newSystemMessage(uuid.New(), "User joined", time.Now().UTC())

	if msg.ModerationStatus != model.MessageModerationStatusVisible {
		t.Fatalf(
			"ModerationStatus = %q, want %q",
			msg.ModerationStatus,
			model.MessageModerationStatusVisible,
		)
	}
	if msg.ModerationReasonCodes == nil {
		t.Fatal("ModerationReasonCodes is nil, want empty slice")
	}
	if len(msg.ModerationReasonCodes) != 0 {
		t.Fatalf("ModerationReasonCodes = %v, want empty", msg.ModerationReasonCodes)
	}
	if msg.ModerationRevision != 1 {
		t.Fatalf("ModerationRevision = %d, want 1", msg.ModerationRevision)
	}
}

func TestSyncExcursionScheduleSlotConversationCreatesConversationWithGuideAndBookingAuthors(t *testing.T) {
	slotID := uuid.New()
	guideUserID := uuid.New()
	touristOneID := uuid.New()
	touristTwoID := uuid.New()
	until := time.Now().UTC().Add(3 * time.Hour)
	repo := newFakeMessageRepo(uuid.New(), guideUserID)
	repo.conversationsByID = map[uuid.UUID]*model.Conversation{}
	repo.conversationsByExcursionSlotID = map[uuid.UUID]*model.Conversation{}
	repo.participantsByConversationUser = map[[2]uuid.UUID]*model.Participant{}
	uc := NewConversationUseCase(repo, fakeEventPublisher{}, nil)

	conv, err := uc.SyncExcursionScheduleSlotConversation(context.Background(), SyncExcursionScheduleSlotConversationInput{
		ScheduleSlotID:          slotID,
		ExcursionTitle:          "Almaty mountain walk",
		MessagingAvailableUntil: &until,
		GuideUserID:             guideUserID,
		ParticipantUserIDs:      []uuid.UUID{touristOneID, touristTwoID, touristOneID, guideUserID},
	})
	if err != nil {
		t.Fatalf("SyncExcursionScheduleSlotConversation() error = %v", err)
	}
	if conv == nil || conv.ExcursionScheduleSlotID == nil || *conv.ExcursionScheduleSlotID != slotID {
		t.Fatalf("conversation excursion slot id = %v, want %s", conv, slotID)
	}
	if conv.Title == nil || *conv.Title != "Almaty mountain walk" {
		t.Fatalf("conversation title = %v, want excursion title", conv.Title)
	}
	if conv.MessagingAvailableUntil == nil || !conv.MessagingAvailableUntil.Equal(until) {
		t.Fatalf("messaging deadline = %v, want %v", conv.MessagingAvailableUntil, until)
	}

	assertParticipantRole(t, repo, conv.ID, guideUserID, "admin")
	assertParticipantRole(t, repo, conv.ID, touristOneID, "member")
	assertParticipantRole(t, repo, conv.ID, touristTwoID, "member")
	if len(repo.createdParticipants) != 3 {
		t.Fatalf("created participants = %d, want guide + 2 unique booking authors", len(repo.createdParticipants))
	}
}

func TestPinMessageEnqueuesNotificationOutbox(t *testing.T) {
	t.Parallel()

	conversationID := uuid.New()
	messageID := uuid.New()
	actorUserID := uuid.New()
	recipientUserID := uuid.New()
	mutedUserID := uuid.New()
	now := time.Now().UTC()
	mutedUntil := now.Add(time.Hour)

	repo := newFakeMessageRepo(conversationID, actorUserID)
	repo.conversation.Type = "group"
	repo.participantsByConversationUser = map[[2]uuid.UUID]*model.Participant{
		{conversationID, actorUserID}: {
			ID:             uuid.New(),
			ConversationID: conversationID,
			UserID:         actorUserID,
			Role:           "admin",
			JoinedAt:       now,
		},
		{conversationID, recipientUserID}: {
			ID:             uuid.New(),
			ConversationID: conversationID,
			UserID:         recipientUserID,
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
			SenderUserID:   recipientUserID,
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
	uc := NewConversationUseCase(repo, fakeEventPublisher{}, profiles)
	uc.SetNotificationSender(notifications)

	_, err := uc.PinMessage(context.Background(), conversationID, messageID, actorUserID)
	if err != nil {
		t.Fatalf("PinMessage error: %v", err)
	}

	notifications.expectNone(t)
	if len(repo.createdNotificationOutbox) != 1 {
		t.Fatalf("outbox entries = %d, want one", len(repo.createdNotificationOutbox))
	}
	item := repo.createdNotificationOutbox[0]
	if item.EventType != chatNotificationEventPin {
		t.Fatalf("EventType = %q, want %q", item.EventType, chatNotificationEventPin)
	}
	if item.ConversationID != conversationID || item.MessageID != messageID || item.ActorUserID != actorUserID {
		t.Fatalf("outbox target = conversation %s message %s actor %s", item.ConversationID, item.MessageID, item.ActorUserID)
	}
}

func TestListConversationsUsesBatchedReadModelEnrichment(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	actorUserID := uuid.New()
	peerUserID := uuid.New()
	groupUserID := uuid.New()
	now := time.Now().UTC()
	mutedUntil := now.Add(2 * time.Hour)
	directConversationID := uuid.New()
	groupConversationID := uuid.New()
	directMessageID := uuid.New()
	groupMessageID := uuid.New()
	directFileID := "direct-file"
	groupFileID := "group-file"

	repo := newFakeMessageRepo(directConversationID, actorUserID)
	repo.listConversations = []*model.Conversation{
		{
			ID:             directConversationID,
			Type:           "direct",
			CreatedAt:      now.Add(-time.Hour),
			LastActivityAt: now,
		},
		{
			ID:             groupConversationID,
			Type:           "group",
			CreatedAt:      now.Add(-2 * time.Hour),
			LastActivityAt: now.Add(-time.Minute),
		},
	}
	repo.participantsByConversation = map[uuid.UUID][]*model.Participant{
		directConversationID: {
			{
				ID:             uuid.New(),
				ConversationID: directConversationID,
				UserID:         actorUserID,
				Role:           "member",
				MutedUntil:     &mutedUntil,
				JoinedAt:       now.Add(-time.Hour),
			},
			{
				ID:             uuid.New(),
				ConversationID: directConversationID,
				UserID:         peerUserID,
				Role:           "member",
				JoinedAt:       now.Add(-time.Hour),
			},
		},
		groupConversationID: {
			{
				ID:             uuid.New(),
				ConversationID: groupConversationID,
				UserID:         actorUserID,
				Role:           "member",
				JoinedAt:       now.Add(-2 * time.Hour),
			},
			{
				ID:             uuid.New(),
				ConversationID: groupConversationID,
				UserID:         groupUserID,
				Role:           "admin",
				JoinedAt:       now.Add(-2 * time.Hour),
			},
		},
	}
	repo.lastMessagesByConversation = map[uuid.UUID]*model.Message{
		directConversationID: {
			ID:             directMessageID,
			ConversationID: directConversationID,
			SenderUserID:   peerUserID,
			Type:           "text",
			Content:        "hello",
			SentAt:         now,
		},
		groupConversationID: {
			ID:             groupMessageID,
			ConversationID: groupConversationID,
			SenderUserID:   groupUserID,
			Type:           "image",
			Content:        "view",
			SentAt:         now.Add(-time.Minute),
		},
	}
	repo.messageFileIDs = map[uuid.UUID][]string{
		directMessageID: {directFileID},
		groupMessageID:  {groupFileID},
	}
	repo.unreadCountsByConversation = map[uuid.UUID]int{
		directConversationID: 3,
		groupConversationID:  5,
	}
	repo.activeParticipantCountsByConversation = map[uuid.UUID]int{
		directConversationID: 2,
		groupConversationID:  7,
	}
	profiles := &fakeUserProfileResolver{
		profiles: map[uuid.UUID]port.PublicUserProfile{
			actorUserID: {UserID: actorUserID, DisplayName: "Me"},
			peerUserID:  {UserID: peerUserID, DisplayName: "Peer"},
			groupUserID: {UserID: groupUserID, DisplayName: "Guide"},
		},
	}
	uc := NewConversationUseCase(repo, fakeEventPublisher{}, profiles)

	convs, err := uc.ListConversations(ctx, actorUserID, nil, 20, nil)
	if err != nil {
		t.Fatalf("ListConversations error: %v", err)
	}

	if len(convs) != 2 {
		t.Fatalf("conversations = %d, want 2", len(convs))
	}
	if repo.listParticipantsCalls != 0 ||
		repo.getLastMessageCalls != 0 ||
		repo.getMessageFileIDsCalls != 0 ||
		repo.getUnreadCountCalls != 0 ||
		repo.countActiveParticipantsCalls != 0 ||
		repo.getParticipantCalls != 0 {
		t.Fatalf(
			"used per-conversation calls: participants=%d last=%d files=%d unread=%d count=%d participant=%d",
			repo.listParticipantsCalls,
			repo.getLastMessageCalls,
			repo.getMessageFileIDsCalls,
			repo.getUnreadCountCalls,
			repo.countActiveParticipantsCalls,
			repo.getParticipantCalls,
		)
	}
	if repo.listParticipantsByConversationIDsCalls != 1 ||
		repo.listLastMessagesByConversationIDsCalls != 1 ||
		repo.listMessageFileIDsCalls != 1 ||
		repo.listUnreadCountsByConversationIDsCalls != 1 ||
		repo.countActiveParticipantsByConversationIDsCalls != 1 ||
		repo.listParticipantsByConversationUserIDsCalls != 1 {
		t.Fatalf(
			"batch call counts mismatch: participants=%d last=%d files=%d unread=%d counts=%d actor=%d",
			repo.listParticipantsByConversationIDsCalls,
			repo.listLastMessagesByConversationIDsCalls,
			repo.listMessageFileIDsCalls,
			repo.listUnreadCountsByConversationIDsCalls,
			repo.countActiveParticipantsByConversationIDsCalls,
			repo.listParticipantsByConversationUserIDsCalls,
		)
	}
	if profiles.calls != 1 {
		t.Fatalf("profile resolver calls = %d, want 1", profiles.calls)
	}

	direct := convs[0]
	if len(direct.Participants) != 2 || direct.Participants[1].DisplayName != "Peer" {
		t.Fatalf("direct participants were not enriched: %+v", direct.Participants)
	}
	if direct.LastMessage == nil || direct.LastMessage.SenderDisplayName != "Peer" {
		t.Fatalf("direct last message was not enriched: %+v", direct.LastMessage)
	}
	if len(direct.LastMessage.FileIDs) != 1 || direct.LastMessage.FileIDs[0] != directFileID {
		t.Fatalf("direct last message file ids = %+v, want %s", direct.LastMessage.FileIDs, directFileID)
	}
	if direct.UnreadCount != 3 || direct.ParticipantCount != 2 {
		t.Fatalf("direct counters unread=%d participants=%d", direct.UnreadCount, direct.ParticipantCount)
	}
	if direct.MutedUntil == nil || !direct.MutedUntil.Equal(mutedUntil) {
		t.Fatalf("direct mutedUntil = %v, want %v", direct.MutedUntil, mutedUntil)
	}

	group := convs[1]
	if len(group.Participants) != 2 || group.Participants[1].DisplayName != "Guide" {
		t.Fatalf("group participants were not enriched: %+v", group.Participants)
	}
	if group.LastMessage == nil || group.LastMessage.SenderDisplayName != "Guide" {
		t.Fatalf("group last message was not enriched: %+v", group.LastMessage)
	}
	if len(group.LastMessage.FileIDs) != 1 || group.LastMessage.FileIDs[0] != groupFileID {
		t.Fatalf("group last message file ids = %+v, want %s", group.LastMessage.FileIDs, groupFileID)
	}
	if group.UnreadCount != 5 || group.ParticipantCount != 7 {
		t.Fatalf("group counters unread=%d participants=%d", group.UnreadCount, group.ParticipantCount)
	}
}

func assertParticipantRole(
	t *testing.T,
	repo *fakeMessageRepo,
	conversationID uuid.UUID,
	userID uuid.UUID,
	wantRole string,
) {
	t.Helper()
	participant := repo.participantsByConversationUser[[2]uuid.UUID{conversationID, userID}]
	if participant == nil {
		t.Fatalf("participant %s was not created", userID)
	}
	if participant.Role != wantRole {
		t.Fatalf("participant %s role = %q, want %q", userID, participant.Role, wantRole)
	}
}
