package app

import (
	"context"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/dkhvan-dev/flyfy/backend/services/chat-service/internal/domain/model"
	"github.com/dkhvan-dev/flyfy/backend/services/chat-service/internal/domain/port"
	"github.com/dkhvan-dev/flyfy/backend/services/chat-service/internal/event"
)

type ConversationUseCase struct {
	repo             port.ChatRepository
	publisher        port.EventPublisher
	profileResolver  port.UserProfileResolver
	activityResolver port.ActivityLifecycleResolver
}

func NewConversationUseCase(
	repo port.ChatRepository,
	publisher port.EventPublisher,
	profileResolver port.UserProfileResolver,
	activityResolver ...port.ActivityLifecycleResolver,
) *ConversationUseCase {
	var resolver port.ActivityLifecycleResolver
	if len(activityResolver) > 0 {
		resolver = activityResolver[0]
	}

	return &ConversationUseCase{
		repo:             repo,
		publisher:        publisher,
		profileResolver:  profileResolver,
		activityResolver: resolver,
	}
}

type CreateDirectConversationInput struct {
	ActorUserID       uuid.UUID
	ParticipantUserID uuid.UUID
}

func (u *ConversationUseCase) CreateDirectConversation(ctx context.Context, input CreateDirectConversationInput) (*model.Conversation, error) {
	if input.ActorUserID == uuid.Nil {
		return nil, ErrInvalidUserID
	}
	if input.ParticipantUserID == uuid.Nil {
		return nil, ErrInvalidUserID
	}

	existing, err := u.repo.FindDirectConversation(ctx, input.ActorUserID, input.ParticipantUserID)
	if err != nil {
		return nil, err
	}
	if existing != nil {
		return existing, nil
	}

	convType := "direct"
	now := time.Now().UTC()

	var conv *model.Conversation
	err = u.repo.WithTx(ctx, func(txRepo port.ChatTxRepository) error {
		conv = &model.Conversation{
			ID:             uuid.New(),
			Type:           convType,
			CreatedAt:      now,
			LastActivityAt: now,
		}
		if err := txRepo.CreateConversation(ctx, conv); err != nil {
			return err
		}

		for _, uid := range []uuid.UUID{input.ActorUserID, input.ParticipantUserID} {
			if err := txRepo.CreateParticipant(ctx, &model.Participant{
				ID:             uuid.New(),
				ConversationID: conv.ID,
				UserID:         uid,
				Role:           "member",
				JoinedAt:       now,
			}); err != nil {
				return err
			}
		}
		return nil
	})
	if err != nil {
		return nil, err
	}

	go func() {
		evt := event.New("conversation.created", conv.ID, nil)
		if pubErr := u.publisher.Publish(context.Background(), "chat.conversation.created", evt); pubErr != nil {
			log.Error().Err(pubErr).Str("conversation_id", conv.ID.String()).Msg("failed to publish conversation.created event")
		}
	}()

	return conv, nil
}

type CreateActivityConversationInput struct {
	ActivityID              uuid.UUID
	Title                   string
	HostUserID              uuid.UUID
	MessagingAvailableUntil *time.Time
}

func (u *ConversationUseCase) CreateActivityConversation(ctx context.Context, input CreateActivityConversationInput) (*model.Conversation, error) {
	if input.ActivityID == uuid.Nil {
		return nil, ErrInvalidActivityID
	}
	if input.HostUserID == uuid.Nil {
		return nil, ErrInvalidUserID
	}

	existing, err := u.repo.GetConversationByActivityID(ctx, input.ActivityID)
	if err != nil {
		return nil, err
	}
	if existing != nil {
		return existing, nil
	}

	convType := "group"
	title := strings.TrimSpace(input.Title)
	now := time.Now().UTC()

	var conv *model.Conversation
	err = u.repo.WithTx(ctx, func(txRepo port.ChatTxRepository) error {
		conv = &model.Conversation{
			ID:                      uuid.New(),
			Type:                    convType,
			Title:                   &title,
			ActivityID:              &input.ActivityID,
			MessagingAvailableUntil: normalizeTimePtr(input.MessagingAvailableUntil),
			CreatedAt:               now,
			LastActivityAt:          now,
		}
		if err := txRepo.CreateConversation(ctx, conv); err != nil {
			return err
		}

		if err := txRepo.CreateParticipant(ctx, &model.Participant{
			ID:             uuid.New(),
			ConversationID: conv.ID,
			UserID:         input.HostUserID,
			Role:           "admin",
			JoinedAt:       now,
		}); err != nil {
			return err
		}
		return nil
	})
	if err != nil {
		return nil, err
	}

	return conv, nil
}

type EnsureActivityParticipantInput struct {
	ActivityID              uuid.UUID
	ActivityTitle           string
	ActivityAvatarFileID    string
	MessagingAvailableUntil *time.Time
	HostUserID              uuid.UUID
	UserID                  uuid.UUID
	DisplayName             string
}

type SyncActivityConversationInput struct {
	ActivityID              uuid.UUID
	ActivityTitle           string
	ActivityAvatarFileID    string
	MessagingAvailableUntil *time.Time
}

func (u *ConversationUseCase) EnsureActivityParticipant(ctx context.Context, input EnsureActivityParticipantInput) (*model.Conversation, error) {
	if input.ActivityID == uuid.Nil {
		return nil, ErrInvalidActivityID
	}
	if input.UserID == uuid.Nil {
		return nil, ErrInvalidUserID
	}
	if input.HostUserID == uuid.Nil {
		return nil, ErrInvalidUserID
	}

	title := strings.TrimSpace(input.ActivityTitle)
	if title == "" {
		title = "Activity chat"
	}
	displayName := strings.TrimSpace(input.DisplayName)
	if displayName == "" {
		displayName = displayNameForUser(ctx, u.profileResolver, input.UserID, "User")
	}
	activityAvatarFileID := strings.TrimSpace(input.ActivityAvatarFileID)
	var avatarFileID *string
	if activityAvatarFileID != "" {
		avatarFileID = &activityAvatarFileID
	}

	now := time.Now().UTC()
	var conv *model.Conversation
	var participantAdded bool
	var conversationChanged bool

	err := u.repo.WithTx(ctx, func(txRepo port.ChatTxRepository) error {
		var err error
		conv, err = txRepo.GetConversationByActivityIDForUpdate(ctx, input.ActivityID)
		if err != nil {
			return err
		}
		if conv == nil {
			conv = &model.Conversation{
				ID:                      uuid.New(),
				Type:                    "group",
				Title:                   &title,
				AvatarFileID:            avatarFileID,
				ActivityID:              &input.ActivityID,
				MessagingAvailableUntil: normalizeTimePtr(input.MessagingAvailableUntil),
				CreatedAt:               now,
				LastActivityAt:          now,
			}
			if err := txRepo.CreateConversation(ctx, conv); err != nil {
				return err
			}
			if err := txRepo.CreateParticipant(ctx, &model.Participant{
				ID:             uuid.New(),
				ConversationID: conv.ID,
				UserID:         input.HostUserID,
				Role:           "admin",
				JoinedAt:       now,
			}); err != nil {
				return err
			}
		} else {
			if strings.TrimSpace(title) != "" && (conv.Title == nil || strings.TrimSpace(*conv.Title) != title) {
				conv.Title = &title
				conversationChanged = true
			}
			if avatarFileID != nil && (conv.AvatarFileID == nil || strings.TrimSpace(*conv.AvatarFileID) != *avatarFileID) {
				conv.AvatarFileID = avatarFileID
				conversationChanged = true
			}
			if !sameOptionalTime(conv.MessagingAvailableUntil, input.MessagingAvailableUntil) {
				conv.MessagingAvailableUntil = normalizeTimePtr(input.MessagingAvailableUntil)
				conversationChanged = true
			}
		}

		participant, err := txRepo.GetParticipantForUpdate(ctx, conv.ID, input.UserID)
		if err != nil {
			return err
		}
		if participant != nil && participant.LeftAt == nil {
			if conversationChanged {
				return txRepo.UpdateConversation(ctx, conv)
			}
			return nil
		}

		count, err := txRepo.CountActiveParticipants(ctx, conv.ID)
		if err != nil {
			return err
		}
		if count >= 200 {
			return ErrConversationFull
		}

		if err := txRepo.CreateParticipant(ctx, &model.Participant{
			ID:             uuid.New(),
			ConversationID: conv.ID,
			UserID:         input.UserID,
			Role:           "member",
			JoinedAt:       now,
		}); err != nil {
			return err
		}

		systemMsg := newSystemMessage(conv.ID, displayName+" joined", now)
		if err := txRepo.CreateMessage(ctx, systemMsg); err != nil {
			return err
		}

		conv.LastActivityAt = now
		if err := txRepo.UpdateConversation(ctx, conv); err != nil {
			return err
		}

		participantAdded = true
		return nil
	})
	if err != nil {
		return nil, err
	}

	if participantAdded {
		go func() {
			evt := event.New("participant.joined", conv.ID, event.ParticipantJoinedPayload{
				UserID:      input.UserID,
				DisplayName: displayName,
			})
			_ = u.publisher.Publish(context.Background(), "chat.participant.joined", evt)
		}()
	}

	return conv, nil
}

func (u *ConversationUseCase) SyncActivityConversation(ctx context.Context, input SyncActivityConversationInput) (*model.Conversation, error) {
	if input.ActivityID == uuid.Nil {
		return nil, ErrInvalidActivityID
	}

	title := strings.TrimSpace(input.ActivityTitle)
	activityAvatarFileID := strings.TrimSpace(input.ActivityAvatarFileID)
	var avatarFileID *string
	if activityAvatarFileID != "" {
		avatarFileID = &activityAvatarFileID
	}

	var conv *model.Conversation
	err := u.repo.WithTx(ctx, func(txRepo port.ChatTxRepository) error {
		var err error
		conv, err = txRepo.GetConversationByActivityIDForUpdate(ctx, input.ActivityID)
		if err != nil {
			return err
		}
		if conv == nil {
			return nil
		}

		if title != "" {
			conv.Title = &title
		}
		if avatarFileID != nil {
			conv.AvatarFileID = avatarFileID
		}
		conv.MessagingAvailableUntil = normalizeTimePtr(input.MessagingAvailableUntil)

		return txRepo.UpdateConversation(ctx, conv)
	})
	if err != nil {
		return nil, err
	}

	return conv, nil
}

func (u *ConversationUseCase) GetConversationByID(ctx context.Context, conversationID, actorUserID uuid.UUID) (*model.Conversation, error) {
	conv, err := u.repo.GetConversationByID(ctx, conversationID)
	if err != nil {
		return nil, err
	}
	if conv == nil {
		return nil, ErrConversationNotFound
	}

	participant, err := u.repo.GetParticipant(ctx, conversationID, actorUserID)
	if err != nil {
		return nil, err
	}
	if participant == nil || participant.LeftAt != nil {
		return nil, ErrNotParticipant
	}

	conv.Participants, err = u.repo.ListParticipantsByConversationID(ctx, conversationID)
	if err != nil {
		return nil, err
	}
	enrichParticipants(ctx, u.profileResolver, conv.Participants)

	conv.UnreadCount, err = u.repo.GetUnreadCount(ctx, conversationID, actorUserID)
	if err != nil {
		return nil, err
	}

	conv.PinnedMessages, err = loadPinnedMessages(
		ctx,
		u.repo,
		u.profileResolver,
		conversationID,
	)
	if err != nil {
		return nil, err
	}

	return conv, nil
}

func (u *ConversationUseCase) GetConversationByActivityID(ctx context.Context, activityID, actorUserID uuid.UUID) (*model.Conversation, error) {
	conv, err := u.repo.GetConversationByActivityID(ctx, activityID)
	if err != nil {
		return nil, err
	}
	if conv == nil {
		return nil, ErrConversationNotFound
	}
	conv, err = refreshActivityMessagingWindow(ctx, u.repo, u.activityResolver, conv, true)
	if err != nil {
		return nil, err
	}

	participant, err := u.repo.GetParticipant(ctx, conv.ID, actorUserID)
	if err != nil {
		return nil, err
	}
	if participant == nil || participant.LeftAt != nil {
		return nil, ErrNotParticipant
	}

	conv.Participants, err = u.repo.ListParticipantsByConversationID(ctx, conv.ID)
	if err != nil {
		return nil, err
	}
	enrichParticipants(ctx, u.profileResolver, conv.Participants)

	conv.UnreadCount, err = u.repo.GetUnreadCount(ctx, conv.ID, actorUserID)
	if err != nil {
		return nil, err
	}

	conv.PinnedMessages, err = loadPinnedMessages(
		ctx,
		u.repo,
		u.profileResolver,
		conv.ID,
	)
	if err != nil {
		return nil, err
	}

	return conv, nil
}

func (u *ConversationUseCase) ListConversations(ctx context.Context, actorUserID uuid.UUID, convType *string, limit int, cursor *time.Time) ([]*model.Conversation, error) {
	if limit <= 0 || limit > 50 {
		limit = 20
	}

	convs, err := u.repo.ListConversationsByUserID(ctx, port.ConversationFilter{
		UserID: &actorUserID,
		Type:   convType,
		Limit:  limit,
		Cursor: cursor,
	})
	if err != nil {
		return nil, err
	}

	for _, conv := range convs {
		conv.Participants, _ = u.repo.ListParticipantsByConversationID(ctx, conv.ID)
		enrichParticipants(ctx, u.profileResolver, conv.Participants)

		conv.LastMessage, _ = u.repo.GetLastMessage(ctx, conv.ID)
		if conv.LastMessage != nil {
			conv.LastMessage.FileIDs, _ = u.repo.GetMessageFileIDs(ctx, conv.LastMessage.ID)
			enrichMessages(ctx, u.profileResolver, []*model.Message{conv.LastMessage})
		}
		conv.UnreadCount, _ = u.repo.GetUnreadCount(ctx, conv.ID, actorUserID)
		count, _ := u.repo.CountActiveParticipants(ctx, conv.ID)
		conv.ParticipantCount = count

		participant, _ := u.repo.GetParticipant(ctx, conv.ID, actorUserID)
		if participant != nil {
			conv.MutedUntil = participant.MutedUntil
		}
	}

	return convs, nil
}

func (u *ConversationUseCase) AddParticipant(ctx context.Context, conversationID, userID uuid.UUID, displayName string) error {
	conv, err := u.repo.GetConversationByID(ctx, conversationID)
	if err != nil {
		return err
	}
	if conv == nil {
		return ErrConversationNotFound
	}

	count, err := u.repo.CountActiveParticipants(ctx, conversationID)
	if err != nil {
		return err
	}
	if count >= 200 {
		return ErrConversationFull
	}

	displayName = displayNameForUser(ctx, u.profileResolver, userID, displayName)
	now := time.Now().UTC()
	err = u.repo.WithTx(ctx, func(txRepo port.ChatTxRepository) error {
		if err := txRepo.CreateParticipant(ctx, &model.Participant{
			ID:             uuid.New(),
			ConversationID: conversationID,
			UserID:         userID,
			Role:           "member",
			JoinedAt:       now,
		}); err != nil {
			return err
		}

		systemMsg := newSystemMessage(conversationID, displayName+" joined", now)
		if err := txRepo.CreateMessage(ctx, systemMsg); err != nil {
			return err
		}

		conv.LastActivityAt = now
		return txRepo.UpdateConversation(ctx, conv)
	})
	if err != nil {
		return err
	}

	go func() {
		evt := event.New("participant.joined", conversationID, event.ParticipantJoinedPayload{
			UserID:      userID,
			DisplayName: displayName,
		})
		_ = u.publisher.Publish(context.Background(), "chat.participant.joined", evt)
	}()

	return nil
}

func (u *ConversationUseCase) RemoveParticipant(ctx context.Context, conversationID, userID uuid.UUID) error {
	participant, err := u.repo.GetParticipant(ctx, conversationID, userID)
	if err != nil {
		return err
	}
	if participant == nil || participant.LeftAt != nil {
		return ErrParticipantNotFound
	}

	now := time.Now().UTC()
	participant.LeftAt = &now
	displayName := displayNameForUser(ctx, u.profileResolver, userID, "User")

	err = u.repo.WithTx(ctx, func(txRepo port.ChatTxRepository) error {
		if err := txRepo.UpdateParticipant(ctx, participant); err != nil {
			return err
		}

		systemMsg := newSystemMessage(conversationID, displayName+" left", now)
		return txRepo.CreateMessage(ctx, systemMsg)
	})
	if err != nil {
		return err
	}

	go func() {
		evt := event.New("participant.left", conversationID, event.ParticipantLeftPayload{UserID: userID})
		_ = u.publisher.Publish(context.Background(), "chat.participant.left", evt)
	}()

	return nil
}

func newSystemMessage(conversationID uuid.UUID, content string, sentAt time.Time) *model.Message {
	return &model.Message{
		ID:             uuid.New(),
		ConversationID: conversationID,
		SenderUserID:   uuid.Nil,
		Type:           "system",
		Content:        content,
		SentAt:         sentAt,
	}
}

func normalizeTimePtr(value *time.Time) *time.Time {
	if value == nil || value.IsZero() {
		return nil
	}
	normalized := value.UTC()
	return &normalized
}

func sameOptionalTime(a *time.Time, b *time.Time) bool {
	a = normalizeTimePtr(a)
	b = normalizeTimePtr(b)
	if a == nil || b == nil {
		return a == nil && b == nil
	}
	return a.Equal(*b)
}

func (u *ConversationUseCase) LeaveConversation(ctx context.Context, conversationID, actorUserID uuid.UUID) error {
	conv, err := u.repo.GetConversationByID(ctx, conversationID)
	if err != nil {
		return err
	}
	if conv == nil {
		return ErrConversationNotFound
	}
	if conv.Type == "direct" {
		return ErrDirectChatCannotLeave
	}

	return u.RemoveParticipant(ctx, conversationID, actorUserID)
}

type MuteInput struct {
	ConversationID uuid.UUID
	ActorUserID    uuid.UUID
	Until          *time.Time
}

func (u *ConversationUseCase) MuteConversation(ctx context.Context, input MuteInput) error {
	participant, err := u.repo.GetParticipant(ctx, input.ConversationID, input.ActorUserID)
	if err != nil {
		return err
	}
	if participant == nil || participant.LeftAt != nil {
		return ErrNotParticipant
	}

	participant.MutedUntil = input.Until

	return u.repo.WithTx(ctx, func(txRepo port.ChatTxRepository) error {
		return txRepo.UpdateParticipant(ctx, participant)
	})
}

func (u *ConversationUseCase) PinMessage(
	ctx context.Context,
	conversationID, messageID, actorUserID uuid.UUID,
) ([]*model.ConversationPin, error) {
	conv, err := u.repo.GetConversationByID(ctx, conversationID)
	if err != nil {
		return nil, err
	}
	if conv == nil {
		return nil, ErrConversationNotFound
	}

	participant, err := u.repo.GetParticipant(ctx, conversationID, actorUserID)
	if err != nil {
		return nil, err
	}
	if participant == nil || participant.LeftAt != nil {
		return nil, ErrNotParticipant
	}
	if conv.Type != "direct" && participant.Role != "admin" {
		return nil, ErrNotAdmin
	}

	msg, err := u.repo.GetMessageByID(ctx, messageID)
	if err != nil {
		return nil, err
	}
	if msg == nil || msg.ConversationID != conversationID {
		return nil, ErrMessageNotFound
	}
	if msg.DeletedAt != nil {
		return nil, ErrMessageAlreadyDeleted
	}

	now := time.Now().UTC()
	err = u.repo.WithTx(ctx, func(txRepo port.ChatTxRepository) error {
		return txRepo.CreateConversationPin(ctx, &model.ConversationPin{
			ID:             uuid.New(),
			ConversationID: conversationID,
			MessageID:      messageID,
			PinnedByUserID: actorUserID,
			PinnedAt:       now,
		})
	})
	if err != nil {
		return nil, err
	}

	pins, err := loadPinnedMessages(ctx, u.repo, u.profileResolver, conversationID)
	if err != nil {
		return nil, err
	}

	publishedPins := pins
	go func() {
		_ = publishPinnedMessages(
			context.Background(),
			u.publisher,
			conversationID,
			publishedPins,
		)
	}()

	return pins, nil
}

func (u *ConversationUseCase) UnpinMessage(
	ctx context.Context,
	conversationID, messageID, actorUserID uuid.UUID,
) ([]*model.ConversationPin, error) {
	conv, err := u.repo.GetConversationByID(ctx, conversationID)
	if err != nil {
		return nil, err
	}
	if conv == nil {
		return nil, ErrConversationNotFound
	}

	participant, err := u.repo.GetParticipant(ctx, conversationID, actorUserID)
	if err != nil {
		return nil, err
	}
	if participant == nil || participant.LeftAt != nil {
		return nil, ErrNotParticipant
	}
	if conv.Type != "direct" && participant.Role != "admin" {
		return nil, ErrNotAdmin
	}

	err = u.repo.WithTx(ctx, func(txRepo port.ChatTxRepository) error {
		_, err := txRepo.DeleteConversationPin(ctx, conversationID, messageID)
		return err
	})
	if err != nil {
		return nil, err
	}

	pins, err := loadPinnedMessages(ctx, u.repo, u.profileResolver, conversationID)
	if err != nil {
		return nil, err
	}

	publishedPins := pins
	go func() {
		_ = publishPinnedMessages(
			context.Background(),
			u.publisher,
			conversationID,
			publishedPins,
		)
	}()

	return pins, nil
}
