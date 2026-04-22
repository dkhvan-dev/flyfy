package app

import "errors"

var (
	ErrInvalidConversationID = errors.New("invalid conversation id")
	ErrInvalidActivityID     = errors.New("invalid activity id")
	ErrInvalidMessageID      = errors.New("invalid message id")
	ErrInvalidUserID         = errors.New("invalid user id")

	ErrConversationNotFound = errors.New("conversation not found")
	ErrMessageNotFound      = errors.New("message not found")
	ErrParticipantNotFound  = errors.New("participant not found")

	ErrAccessDenied     = errors.New("access denied")
	ErrNotParticipant   = errors.New("user is not a participant of this conversation")
	ErrNotAdmin         = errors.New("user is not an admin of this conversation")
	ErrNotMessageAuthor = errors.New("user is not the author of this message")

	ErrDirectChatCannotLeave = errors.New("cannot leave a direct chat")
	ErrMessageTooLong        = errors.New("message content exceeds 4KB limit")
	ErrInvalidMessageType    = errors.New("invalid message type")
	ErrMessageEditExpired    = errors.New("message can only be edited within 24 hours")
	ErrMessageAlreadyDeleted = errors.New("message is already deleted")
	ErrCannotPinInDirectChat = errors.New("cannot pin messages in direct chats")

	ErrTooManyFiles                = errors.New("maximum 10 files per message")
	ErrConversationFull            = errors.New("conversation has reached maximum participants")
	ErrConversationMessagingClosed = errors.New("conversation messaging is closed")
)
