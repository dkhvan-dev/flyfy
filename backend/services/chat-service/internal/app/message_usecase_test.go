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

	repo := newFakeMessageRepo(conversationID, senderID)
	stickers := &fakeStickerResolver{
		result: &port.StickerMetadata{
			StickerID: stickerID,
			PackID:    packID,
			FileID:    fileID,
			Status:    "ACTIVE",
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
	if msg.StickerFileID == nil || *msg.StickerFileID != fileID.String() {
		t.Fatalf("StickerFileID = %v, want %s", msg.StickerFileID, fileID)
	}
	if len(msg.FileIDs) != 0 {
		t.Fatalf("sticker messages must not persist attachment fileIds: %+v", msg.FileIDs)
	}
	if repo.createdMessage == nil || repo.createdMessage.StickerID == nil || *repo.createdMessage.StickerID != stickerID {
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

type fakeMessageRepo struct {
	conversationID uuid.UUID
	senderID       uuid.UUID
	conversation   *model.Conversation
	participant    *model.Participant
	createdMessage *model.Message
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

func (r *fakeMessageRepo) GetConversationByID(context.Context, uuid.UUID) (*model.Conversation, error) {
	return r.conversation, nil
}

func (r *fakeMessageRepo) GetParticipant(context.Context, uuid.UUID, uuid.UUID) (*model.Participant, error) {
	return r.participant, nil
}

func (r *fakeMessageRepo) WithTx(ctx context.Context, fn func(repo port.ChatTxRepository) error) error {
	return fn(r)
}

func (r *fakeMessageRepo) CreateMessage(_ context.Context, msg *model.Message) error {
	copyValue := *msg
	r.createdMessage = &copyValue
	return nil
}

func (r *fakeMessageRepo) CreateConversation(context.Context, *model.Conversation) error {
	return nil
}

func (r *fakeMessageRepo) CreateMessageFiles(context.Context, uuid.UUID, []string) error {
	return nil
}

func (r *fakeMessageRepo) GetConversationByIDForUpdate(context.Context, uuid.UUID) (*model.Conversation, error) {
	return r.conversation, nil
}

func (r *fakeMessageRepo) UpdateConversation(_ context.Context, conv *model.Conversation) error {
	r.conversation = conv
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

func (r *fakeMessageRepo) GetMessageByID(context.Context, uuid.UUID) (*model.Message, error) {
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

func (r *fakeMessageRepo) GetMessageFileIDs(context.Context, uuid.UUID) ([]string, error) {
	return nil, nil
}

func (r *fakeMessageRepo) ListPinnedMessagesByConversationID(context.Context, uuid.UUID) ([]*model.ConversationPin, error) {
	return nil, nil
}

func (r *fakeMessageRepo) GetConversationByActivityIDForUpdate(context.Context, uuid.UUID) (*model.Conversation, error) {
	return nil, nil
}

func (r *fakeMessageRepo) GetParticipantForUpdate(context.Context, uuid.UUID, uuid.UUID) (*model.Participant, error) {
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

func (r *fakeMessageRepo) UpdateMessage(context.Context, *model.Message) error {
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
