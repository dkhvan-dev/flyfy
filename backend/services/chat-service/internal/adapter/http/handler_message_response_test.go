package http

import (
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/chat-service/internal/domain/model"
)

func TestMessageResponseFromModelExposesModeratorRemovalReason(t *testing.T) {
	reviewedAt := time.Date(2026, 5, 25, 12, 30, 0, 0, time.UTC)
	msg := &model.Message{
		ID:                      uuid.New(),
		ConversationID:          uuid.New(),
		SenderUserID:            uuid.New(),
		Type:                    "text",
		Content:                 "Напишите мне в WhatsApp +77011234567",
		FileIDs:                 []string{"file-1"},
		ModerationStatus:        model.MessageModerationStatusHiddenByModeration,
		ModerationReviewedAt:    &reviewedAt,
		ModerationPublicComment: "Нельзя переводить общение за пределы FlyFy.",
		SentAt:                  reviewedAt.Add(-time.Hour),
	}

	response := messageResponseFromModel(msg)

	if response.Content != "" {
		t.Fatalf("Content = %q, want redacted", response.Content)
	}
	if len(response.FileIDs) != 0 {
		t.Fatalf("FileIDs = %#v, want redacted", response.FileIDs)
	}
	if response.DeletedAt == nil {
		t.Fatal("DeletedAt must be set for a message hidden by moderation")
	}
	if response.ModerationStatus != model.MessageModerationStatusHiddenByModeration {
		t.Fatalf("ModerationStatus = %q, want %q", response.ModerationStatus, model.MessageModerationStatusHiddenByModeration)
	}
	if response.ModerationPublicComment == nil || *response.ModerationPublicComment != msg.ModerationPublicComment {
		t.Fatalf("ModerationPublicComment = %v, want %q", response.ModerationPublicComment, msg.ModerationPublicComment)
	}
}
