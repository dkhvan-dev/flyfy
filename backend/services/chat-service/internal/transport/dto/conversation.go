package dto

type CreateConversationRequest struct {
	Type               string   `json:"type"`
	ParticipantUserIDs []string `json:"participantUserIds"`
	ActivityID         string   `json:"activityId,omitempty"`
	Title              string   `json:"title,omitempty"`
}

type EnsureActivityParticipantRequest struct {
	ActivityID              string `json:"activityId"`
	ActivityTitle           string `json:"activityTitle,omitempty"`
	ActivityAvatarFileID    string `json:"activityAvatarFileId,omitempty"`
	MessagingAvailableUntil string `json:"messagingAvailableUntil,omitempty"`
	HostUserID              string `json:"hostUserId,omitempty"`
	UserID                  string `json:"userId"`
	DisplayName             string `json:"displayName,omitempty"`
}

type SyncActivityConversationRequest struct {
	ActivityID              string `json:"activityId"`
	ActivityTitle           string `json:"activityTitle,omitempty"`
	ActivityAvatarFileID    string `json:"activityAvatarFileId,omitempty"`
	MessagingAvailableUntil string `json:"messagingAvailableUntil,omitempty"`
}

type SyncExcursionScheduleSlotConversationRequest struct {
	ScheduleSlotID          string   `json:"scheduleSlotId"`
	ExcursionTitle          string   `json:"excursionTitle,omitempty"`
	ExcursionAvatarFileID   string   `json:"excursionAvatarFileId,omitempty"`
	MessagingAvailableUntil string   `json:"messagingAvailableUntil,omitempty"`
	GuideUserID             string   `json:"guideUserId"`
	ParticipantUserIDs      []string `json:"participantUserIds,omitempty"`
}

type ConversationListItem struct {
	ID                      string              `json:"id"`
	Type                    string              `json:"type"`
	Title                   *string             `json:"title"`
	AvatarFileID            *string             `json:"avatarFileId"`
	ActivityID              *string             `json:"activityId,omitempty"`
	ExcursionScheduleSlotID *string             `json:"excursionScheduleSlotId,omitempty"`
	Participants            []ParticipantInfo   `json:"participants,omitempty"`
	LastMessage             *LastMessagePreview `json:"lastMessage"`
	UnreadCount             int                 `json:"unreadCount"`
	ParticipantCount        int                 `json:"participantCount"`
	MutedUntil              *string             `json:"mutedUntil"`
	MessagingAvailableUntil *string             `json:"messagingAvailableUntil,omitempty"`
	CanSendMessages         bool                `json:"canSendMessages"`
	LastActivityAt          string              `json:"lastActivityAt"`
}

type LastMessagePreview struct {
	ID                      string   `json:"id"`
	SenderUserID            string   `json:"senderUserId"`
	SenderDisplayName       string   `json:"senderDisplayName"`
	Type                    string   `json:"type"`
	ContentPreview          string   `json:"contentPreview"`
	FileIDs                 []string `json:"fileIds,omitempty"`
	StickerID               *string  `json:"stickerId,omitempty"`
	StickerFileID           *string  `json:"stickerFileId,omitempty"`
	DeletedAt               *string  `json:"deletedAt,omitempty"`
	ModerationStatus        string   `json:"moderationStatus,omitempty"`
	ModerationPublicComment *string  `json:"moderationPublicComment,omitempty"`
	SentAt                  string   `json:"sentAt"`
}

type ConversationDetail struct {
	ID                      string              `json:"id"`
	Type                    string              `json:"type"`
	Title                   *string             `json:"title"`
	AvatarFileID            *string             `json:"avatarFileId"`
	CreatedAt               string              `json:"createdAt"`
	ActivityID              *string             `json:"activityId"`
	ExcursionScheduleSlotID *string             `json:"excursionScheduleSlotId,omitempty"`
	Participants            []ParticipantInfo   `json:"participants"`
	PinnedMessages          []PinnedMessageInfo `json:"pinnedMessages"`
	UnreadCount             int                 `json:"unreadCount"`
	MutedUntil              *string             `json:"mutedUntil"`
	MessagingAvailableUntil *string             `json:"messagingAvailableUntil,omitempty"`
	CanSendMessages         bool                `json:"canSendMessages"`
	LastActivityAt          string              `json:"lastActivityAt"`
}

type ParticipantInfo struct {
	UserID            string  `json:"userId"`
	DisplayName       string  `json:"displayName"`
	AvatarFileID      *string `json:"avatarFileId"`
	Role              string  `json:"role"`
	JoinedAt          string  `json:"joinedAt"`
	LastReadMessageID *string `json:"lastReadMessageId,omitempty"`
	IsOnline          bool    `json:"isOnline"`
	LastSeenAt        *string `json:"lastSeenAt,omitempty"`
}

type PinnedMessageInfo struct {
	ID                 string   `json:"id"`
	SenderUserID       string   `json:"senderUserId"`
	SenderDisplayName  string   `json:"senderDisplayName"`
	SenderAvatarFileID *string  `json:"senderAvatarFileId,omitempty"`
	Type               string   `json:"type"`
	Content            string   `json:"content"`
	FileIDs            []string `json:"fileIds,omitempty"`
	StickerID          *string  `json:"stickerId,omitempty"`
	StickerFileID      *string  `json:"stickerFileId,omitempty"`
	SentAt             string   `json:"sentAt"`
	PinnedAt           string   `json:"pinnedAt"`
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

type PinnedMessagesResponse struct {
	Items []PinnedMessageInfo `json:"items"`
}
