package dto

type SendMessageRequest struct {
	Content          string   `json:"content"`
	Type             string   `json:"type"`
	FileIDs          []string `json:"fileIds"`
	ReplyToMessageID *string  `json:"replyToMessageId"`
}

type EditMessageRequest struct {
	Content string `json:"content"`
}

type MarkReadRequest struct {
	LastReadMessageID string `json:"lastReadMessageId"`
}

type MessageResponse struct {
	ID                 string   `json:"id"`
	SenderUserID       string   `json:"senderUserId"`
	SenderDisplayName  string   `json:"senderDisplayName"`
	SenderAvatarFileID *string  `json:"senderAvatarFileId,omitempty"`
	Type               string   `json:"type"`
	Content            string   `json:"content"`
	FileIDs            []string `json:"fileIds,omitempty"`
	ReplyToMessageID   *string  `json:"replyToMessageId,omitempty"`
	EditedAt           *string  `json:"editedAt,omitempty"`
	DeletedAt          *string  `json:"deletedAt,omitempty"`
	SentAt             string   `json:"sentAt"`
}

type MessageListResponse struct {
	Items      []MessageResponse `json:"items"`
	NextCursor *string           `json:"nextCursor"`
}
