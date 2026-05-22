package dto

type InviteFriendsRequest struct {
	UserIDs []string `json:"userIds"`
}

type InviteFriendsResponse struct {
	Invited        []ParticipantResponse `json:"invited"`
	SkippedUserIDs []string              `json:"skippedUserIds"`
}
