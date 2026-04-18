package dto

type CreateConversationRequest struct {
	Type               string   `json:"type"`
	ParticipantUserIDs []string `json:"participantUserIds"`
}

type ConversationListItem struct {
	ID               string              `json:"id"`
	Type             string              `json:"type"`
	Title            *string             `json:"title"`
	AvatarFileID     *string             `json:"avatarFileId"`
	LastMessage      *LastMessagePreview  `json:"lastMessage"`
	UnreadCount      int                 `json:"unreadCount"`
	ParticipantCount int                 `json:"participantCount"`
	MutedUntil       *string             `json:"mutedUntil"`
	LastActivityAt   string              `json:"lastActivityAt"`
}

type LastMessagePreview struct {
	ID                string `json:"id"`
	SenderUserID      string `json:"senderUserId"`
	SenderDisplayName string `json:"senderDisplayName"`
	ContentPreview    string `json:"contentPreview"`
	SentAt            string `json:"sentAt"`
}

type ConversationDetail struct {
	ID             string            `json:"id"`
	Type           string            `json:"type"`
	Title          *string           `json:"title"`
	AvatarFileID   *string           `json:"avatarFileId"`
	CreatedAt      string            `json:"createdAt"`
	ActivityID     *string           `json:"activityId"`
	Participants   []ParticipantInfo `json:"participants"`
	PinnedMessage  *PinnedMessageInfo `json:"pinnedMessage"`
	UnreadCount    int               `json:"unreadCount"`
	MutedUntil     *string           `json:"mutedUntil"`
	LastActivityAt string            `json:"lastActivityAt"`
}

type ParticipantInfo struct {
	UserID       string  `json:"userId"`
	DisplayName  string  `json:"displayName"`
	AvatarFileID *string `json:"avatarFileId"`
	Role         string  `json:"role"`
	JoinedAt     string  `json:"joinedAt"`
}

type PinnedMessageInfo struct {
	ID                string `json:"id"`
	SenderUserID      string `json:"senderUserId"`
	SenderDisplayName string `json:"senderDisplayName"`
	Content           string `json:"content"`
	SentAt            string `json:"sentAt"`
}

type ConversationListResponse struct {
	Items      []ConversationListItem `json:"items"`
	NextCursor *string                `json:"nextCursor"`
}

type MuteRequest struct {
	Until *string `json:"until"`
}

type PinRequest struct {
	MessageID string `json:"messageId"`
}
