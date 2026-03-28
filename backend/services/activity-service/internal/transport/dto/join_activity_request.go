package dto

type JoinActivityRequest struct {
	IdempotencyKey *string `json:"idempotencyKey,omitempty"`
	Password       *string `json:"password,omitempty"`
}
