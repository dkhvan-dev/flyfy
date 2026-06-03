package app

import (
	"context"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/chat-service/internal/domain/model"
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
