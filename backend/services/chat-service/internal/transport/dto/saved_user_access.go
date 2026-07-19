package dto

type SavedUserAccessCheckRequest struct {
	OwnerUserID   string   `json:"ownerUserId"`
	TargetUserIDs []string `json:"targetUserIds"`
}

type SavedUserAccessCheckResponse struct {
	DeniedTargetUserIDs []string `json:"deniedTargetUserIds"`
}
