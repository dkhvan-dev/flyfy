package dto

type SendMessageRequest struct {
	Content          string   `json:"content"`
	Type             string   `json:"type"`
	FileIDs          []string `json:"fileIds"`
	StickerID        *string  `json:"stickerId,omitempty"`
	ReplyToMessageID *string  `json:"replyToMessageId"`
}

type ForwardMessageRequest struct {
	TargetConversationID string `json:"targetConversationId"`
}

type EditMessageRequest struct {
	Content string `json:"content"`
}

type MarkReadRequest struct {
	LastReadMessageID string `json:"lastReadMessageId"`
}

type ReactMessageRequest struct {
	Emoji string `json:"emoji"`
}

type MessageResponse struct {
	ID                        string                   `json:"id"`
	SenderUserID              string                   `json:"senderUserId"`
	SenderDisplayName         string                   `json:"senderDisplayName"`
	SenderAvatarFileID        *string                  `json:"senderAvatarFileId,omitempty"`
	Type                      string                   `json:"type"`
	Content                   string                   `json:"content"`
	FileIDs                   []string                 `json:"fileIds,omitempty"`
	StickerID                 *string                  `json:"stickerId,omitempty"`
	StickerFileID             *string                  `json:"stickerFileId,omitempty"`
	ReplyToMessageID          *string                  `json:"replyToMessageId,omitempty"`
	ForwardedFromMessageID    *string                  `json:"forwardedFromMessageId,omitempty"`
	ForwardedFromSenderUserID *string                  `json:"forwardedFromSenderUserId,omitempty"`
	ForwardedFromSenderName   *string                  `json:"forwardedFromSenderName,omitempty"`
	ForwardCount              int                      `json:"forwardCount"`
	EditedAt                  *string                  `json:"editedAt,omitempty"`
	DeletedAt                 *string                  `json:"deletedAt,omitempty"`
	Reactions                 []MessageReactionInfo    `json:"reactions,omitempty"`
	ReadReceipts              []MessageReadReceiptInfo `json:"readReceipts,omitempty"`
	SentAt                    string                   `json:"sentAt"`
}

type MessageReactionInfo struct {
	Emoji       string                    `json:"emoji"`
	Count       int                       `json:"count"`
	ReactedByMe bool                      `json:"reactedByMe"`
	UserIDs     []string                  `json:"userIds,omitempty"`
	Users       []MessageReactionUserInfo `json:"users,omitempty"`
}

type MessageReactionUserInfo struct {
	UserID    string `json:"userId"`
	ReactedAt string `json:"reactedAt"`
}

type MessageReadReceiptInfo struct {
	UserID string `json:"userId"`
	ReadAt string `json:"readAt"`
}

type MessageReactionResponse struct {
	MessageID string                `json:"messageId"`
	Reactions []MessageReactionInfo `json:"reactions"`
}

type MessageListResponse struct {
	Items      []MessageResponse `json:"items"`
	NextCursor *string           `json:"nextCursor"`
}

type DeleteMessageResponse struct {
	HardDeleted bool    `json:"hardDeleted"`
	DeletedAt   *string `json:"deletedAt,omitempty"`
}
