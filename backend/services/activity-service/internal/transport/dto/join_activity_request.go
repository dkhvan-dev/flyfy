package dto

type JoinActivityRequest struct {
	IdempotencyKey *string `json:"idempotencyKey,omitempty"`
}
