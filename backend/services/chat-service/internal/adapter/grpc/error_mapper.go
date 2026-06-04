package grpc

import (
	"errors"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"kz/inflap/backend/services/chat-service/internal/app"
)

type appGRPCErrorDefinition struct {
	err     error
	code    codes.Code
	message string
}

var appGRPCErrorDefinitions = []appGRPCErrorDefinition{
	{err: app.ErrInvalidConversationID, code: codes.InvalidArgument, message: "invalid conversation id"},
	{err: app.ErrInvalidActivityID, code: codes.InvalidArgument, message: "invalid activity id"},
	{err: app.ErrInvalidMessageID, code: codes.InvalidArgument, message: "invalid message id"},
	{err: app.ErrInvalidUserID, code: codes.InvalidArgument, message: "invalid user id"},
	{err: app.ErrMessageTooLong, code: codes.InvalidArgument, message: "message content exceeds 4KB limit"},
	{err: app.ErrInvalidMessageType, code: codes.InvalidArgument, message: "invalid message type"},
	{err: app.ErrInvalidStickerID, code: codes.InvalidArgument, message: "invalid sticker id"},
	{err: app.ErrInvalidReaction, code: codes.InvalidArgument, message: "invalid message reaction"},
	{err: app.ErrInvalidModerationDecision, code: codes.InvalidArgument, message: "invalid moderation decision"},
	{err: app.ErrCannotBlockSelf, code: codes.InvalidArgument, message: "cannot block yourself"},

	{err: app.ErrConversationNotFound, code: codes.NotFound, message: "conversation not found"},
	{err: app.ErrMessageNotFound, code: codes.NotFound, message: "message not found"},
	{err: app.ErrParticipantNotFound, code: codes.NotFound, message: "participant not found"},

	{err: app.ErrAccessDenied, code: codes.PermissionDenied, message: "access denied"},
	{err: app.ErrNotParticipant, code: codes.PermissionDenied, message: "user is not a participant of this conversation"},
	{err: app.ErrNotAdmin, code: codes.PermissionDenied, message: "user is not an admin of this conversation"},
	{err: app.ErrNotMessageAuthor, code: codes.PermissionDenied, message: "user is not the author of this message"},
	{err: app.ErrCannotMessageBlockedUser, code: codes.PermissionDenied, message: "recipient has blocked this user"},

	{err: app.ErrTooManyFiles, code: codes.ResourceExhausted, message: "maximum 10 files per message"},
	{err: app.ErrConversationFull, code: codes.ResourceExhausted, message: "conversation has reached maximum participants"},

	{err: app.ErrDirectChatCannotLeave, code: codes.FailedPrecondition, message: "cannot leave a direct chat"},
	{err: app.ErrCannotPinInDirectChat, code: codes.FailedPrecondition, message: "cannot pin messages in direct chats"},
	{err: app.ErrMessageEditExpired, code: codes.FailedPrecondition, message: "message can only be edited within 24 hours"},
	{err: app.ErrMessageAlreadyDeleted, code: codes.FailedPrecondition, message: "message is already deleted"},
	{err: app.ErrStickerNotAvailable, code: codes.FailedPrecondition, message: "sticker is not available"},
	{err: app.ErrConversationMessagingClosed, code: codes.FailedPrecondition, message: "conversation messaging is closed"},
}

func grpcStatusFromAppError(err error) error {
	if definition, ok := grpcAppErrorDefinition(err); ok {
		return status.Error(definition.code, definition.message)
	}
	return status.Error(codes.Internal, "technical error")
}

func isGRPCBusinessError(err error) bool {
	_, ok := grpcAppErrorDefinition(err)
	return ok
}

func grpcAppErrorDefinition(err error) (appGRPCErrorDefinition, bool) {
	for _, definition := range appGRPCErrorDefinitions {
		if errors.Is(err, definition.err) {
			return definition, true
		}
	}
	return appGRPCErrorDefinition{}, false
}
