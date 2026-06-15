package dto

type SendMessageRequest struct {
	Content          string                    `json:"content"`
	Type             string                    `json:"type"`
	ClientMessageID  *string                   `json:"clientMessageId,omitempty"`
	FileIDs          []string                  `json:"fileIds"`
	StickerID        *string                   `json:"stickerId,omitempty"`
	ReplyToMessageID *string                   `json:"replyToMessageId"`
	StoryReply       *StoryReplyContextRequest `json:"storyReply,omitempty"`
}

type StoryReplyContextRequest struct {
	StoryID            string  `json:"storyId"`
	StoryAuthorUserID  string  `json:"storyAuthorUserId"`
	StoryTitle         string  `json:"storyTitle,omitempty"`
	StoryPreviewFileID string  `json:"storyPreviewFileId,omitempty"`
	StoryPreviewURL    string  `json:"storyPreviewUrl,omitempty"`
	StoryExpiresAt     *string `json:"storyExpiresAt,omitempty"`
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
	ID                        string                     `json:"id"`
	ClientMessageID           *string                    `json:"clientMessageId,omitempty"`
	SenderUserID              string                     `json:"senderUserId"`
	SenderDisplayName         string                     `json:"senderDisplayName"`
	SenderAvatarFileID        *string                    `json:"senderAvatarFileId,omitempty"`
	Type                      string                     `json:"type"`
	Content                   string                     `json:"content"`
	FileIDs                   []string                   `json:"fileIds,omitempty"`
	StickerID                 *string                    `json:"stickerId,omitempty"`
	StickerFileID             *string                    `json:"stickerFileId,omitempty"`
	ReplyToMessageID          *string                    `json:"replyToMessageId,omitempty"`
	StoryReply                *StoryReplyContextResponse `json:"storyReply,omitempty"`
	ForwardedFromMessageID    *string                    `json:"forwardedFromMessageId,omitempty"`
	ForwardedFromSenderUserID *string                    `json:"forwardedFromSenderUserId,omitempty"`
	ForwardedFromSenderName   *string                    `json:"forwardedFromSenderName,omitempty"`
	ForwardCount              int                        `json:"forwardCount"`
	EditedAt                  *string                    `json:"editedAt,omitempty"`
	DeletedAt                 *string                    `json:"deletedAt,omitempty"`
	ModerationStatus          string                     `json:"moderationStatus,omitempty"`
	ModerationPublicComment   *string                    `json:"moderationPublicComment,omitempty"`
	Reactions                 []MessageReactionInfo      `json:"reactions,omitempty"`
	ReadReceipts              []MessageReadReceiptInfo   `json:"readReceipts,omitempty"`
	SentAt                    string                     `json:"sentAt"`
}

type StoryReplyContextResponse struct {
	StoryID            string  `json:"storyId"`
	StoryAuthorUserID  string  `json:"storyAuthorUserId"`
	StoryTitle         string  `json:"storyTitle,omitempty"`
	StoryPreviewFileID string  `json:"storyPreviewFileId,omitempty"`
	StoryPreviewURL    string  `json:"storyPreviewUrl,omitempty"`
	StoryExpiresAt     *string `json:"storyExpiresAt,omitempty"`
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

type ChatModerationDecisionRequest struct {
	ReasonCodes     []string `json:"reasonCodes"`
	PublicComment   string   `json:"publicComment"`
	InternalComment string   `json:"internalComment"`
}

type ChatMessageModerationListResponse struct {
	Items []ChatMessageModerationResponse `json:"items"`
}

type ChatParticipantModerationResponse struct {
	UserID      string `json:"userId"`
	DisplayName string `json:"displayName,omitempty"`
	Role        string `json:"role,omitempty"`
}

type ChatMessageContextResponse struct {
	ID                string   `json:"id"`
	SenderUserID      string   `json:"senderUserId"`
	SenderDisplayName string   `json:"senderDisplayName,omitempty"`
	Type              string   `json:"type"`
	Content           string   `json:"content"`
	FileIDs           []string `json:"fileIds,omitempty"`
	EditedAt          *string  `json:"editedAt,omitempty"`
	DeletedAt         *string  `json:"deletedAt,omitempty"`
	SentAt            string   `json:"sentAt"`
}

type ChatMessageModerationResponse struct {
	ID                      string                              `json:"id"`
	ConversationID          string                              `json:"conversationId"`
	ConversationType        string                              `json:"conversationType"`
	ConversationTitle       string                              `json:"conversationTitle,omitempty"`
	ActivityID              *string                             `json:"activityId,omitempty"`
	ExcursionScheduleSlotID *string                             `json:"excursionScheduleSlotId,omitempty"`
	SenderUserID            string                              `json:"senderUserId"`
	SenderDisplayName       string                              `json:"senderDisplayName,omitempty"`
	Type                    string                              `json:"type"`
	Content                 string                              `json:"content"`
	FileIDs                 []string                            `json:"fileIds,omitempty"`
	ModerationStatus        string                              `json:"moderationStatus"`
	ModerationRiskScore     int                                 `json:"moderationRiskScore"`
	ModerationReasonCodes   []string                            `json:"moderationReasonCodes,omitempty"`
	ModerationTriggeredAt   *string                             `json:"moderationTriggeredAt,omitempty"`
	ModerationReviewedAt    *string                             `json:"moderationReviewedAt,omitempty"`
	ContextBefore           []ChatMessageContextResponse        `json:"contextBefore,omitempty"`
	ContextAfter            []ChatMessageContextResponse        `json:"contextAfter,omitempty"`
	Participants            []ChatParticipantModerationResponse `json:"participants,omitempty"`
	Revision                int                                 `json:"revision"`
	EditedAt                *string                             `json:"editedAt,omitempty"`
	DeletedAt               *string                             `json:"deletedAt,omitempty"`
	SentAt                  string                              `json:"sentAt"`
	CreatedAt               string                              `json:"createdAt"`
	UpdatedAt               string                              `json:"updatedAt"`
}
