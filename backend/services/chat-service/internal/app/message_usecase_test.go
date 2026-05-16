package app

import (
	"context"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/chat-service/internal/domain/model"
	"github.com/dkhvan-dev/flyfy/backend/services/chat-service/internal/domain/port"
	"github.com/dkhvan-dev/flyfy/backend/services/chat-service/internal/event"
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
			PackSlug:       "flyfy-travel-basics",
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
		msg.StickerPayload.PackSlug != "flyfy-travel-basics" ||
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

type fakeMessageRepo struct {
	conversationID                 uuid.UUID
	senderID                       uuid.UUID
	conversation                   *model.Conversation
	participant                    *model.Participant
	createdMessage                 *model.Message
	conversationsByID              map[uuid.UUID]*model.Conversation
	participantsByConversationUser map[[2]uuid.UUID]*model.Participant
	messagesByID                   map[uuid.UUID]*model.Message
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
	if r.participantsByConversationUser != nil {
		return r.participantsByConversationUser[[2]uuid.UUID{conversationID, userID}], nil
	}
	return r.participant, nil
}

func (r *fakeMessageRepo) WithTx(ctx context.Context, fn func(repo port.ChatTxRepository) error) error {
	return fn(r)
}

func (r *fakeMessageRepo) CreateMessage(_ context.Context, msg *model.Message) error {
	copyValue := *msg
	r.createdMessage = &copyValue
	if r.messagesByID != nil {
		r.messagesByID[msg.ID] = &copyValue
	}
	return nil
}

func (r *fakeMessageRepo) CreateConversation(context.Context, *model.Conversation) error {
	return nil
}

func (r *fakeMessageRepo) CreateMessageFiles(context.Context, uuid.UUID, []string) error {
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
	return nil, nil
}

func (r *fakeMessageRepo) FindDirectConversation(context.Context, uuid.UUID, uuid.UUID) (*model.Conversation, error) {
	return nil, nil
}

func (r *fakeMessageRepo) GetConversationByActivityID(context.Context, uuid.UUID) (*model.Conversation, error) {
	return nil, nil
}

func (r *fakeMessageRepo) GetMessageByID(_ context.Context, messageID uuid.UUID) (*model.Message, error) {
	if r.messagesByID != nil {
		return r.messagesByID[messageID], nil
	}
	return nil, nil
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

func (r *fakeMessageRepo) ListParticipantsByConversationID(context.Context, uuid.UUID) ([]*model.Participant, error) {
	return nil, nil
}

func (r *fakeMessageRepo) CountActiveParticipants(context.Context, uuid.UUID) (int, error) {
	return 1, nil
}

func (r *fakeMessageRepo) GetUnreadCount(context.Context, uuid.UUID, uuid.UUID) (int, error) {
	return 0, nil
}

func (r *fakeMessageRepo) GetLastMessage(context.Context, uuid.UUID) (*model.Message, error) {
	return nil, nil
}

func (r *fakeMessageRepo) GetMessageFileIDs(_ context.Context, messageID uuid.UUID) ([]string, error) {
	if r.messagesByID != nil && r.messagesByID[messageID] != nil {
		return r.messagesByID[messageID].FileIDs, nil
	}
	return nil, nil
}

func (r *fakeMessageRepo) ListPinnedMessagesByConversationID(context.Context, uuid.UUID) ([]*model.ConversationPin, error) {
	return nil, nil
}

func (r *fakeMessageRepo) GetConversationByActivityIDForUpdate(context.Context, uuid.UUID) (*model.Conversation, error) {
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

func (r *fakeMessageRepo) CreateParticipant(context.Context, *model.Participant) error {
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

type fakeEventPublisher struct{}

func (fakeEventPublisher) Publish(context.Context, string, event.Event) error { return nil }
func (fakeEventPublisher) Close() error                                       { return nil }
