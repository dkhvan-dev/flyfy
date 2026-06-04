package app

import (
	"github.com/google/uuid"

	"kz/inflap/backend/services/chat-service/internal/domain/model"
)

func directConversationPeerID(participants []*model.Participant, actorUserID uuid.UUID) uuid.UUID {
	for _, participant := range participants {
		if participant == nil || participant.LeftAt != nil {
			continue
		}
		if participant.UserID != uuid.Nil && participant.UserID != actorUserID {
			return participant.UserID
		}
	}
	return uuid.Nil
}
