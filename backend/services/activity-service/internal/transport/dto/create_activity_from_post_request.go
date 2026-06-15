package dto

type CreateActivityFromPostRequest struct {
	CreateActivityRequest

	HostUserID     string `json:"hostUserId"`
	SourcePostID   string `json:"sourcePostId,omitempty"`
	IdempotencyKey string `json:"idempotencyKey,omitempty"`
}
