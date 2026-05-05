package dto

import "encoding/json"

type CreatePaymentRequest struct {
	IdempotencyKey string          `json:"idempotencyKey"`
	SubjectType    string          `json:"subjectType"`
	SubjectID      string          `json:"subjectId"`
	Purpose        string          `json:"purpose"`
	PayerUserID    *string         `json:"payerUserId,omitempty"`
	AmountMinor    int64           `json:"amountMinor"`
	Currency       string          `json:"currency"`
	Description    *string         `json:"description,omitempty"`
	Metadata       json.RawMessage `json:"metadata,omitempty"`
}

type ChildPaymentRequest struct {
	IdempotencyKey string          `json:"idempotencyKey"`
	AmountMinor    *int64          `json:"amountMinor,omitempty"`
	Description    *string         `json:"description,omitempty"`
	Metadata       json.RawMessage `json:"metadata,omitempty"`
}
