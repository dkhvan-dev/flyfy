package dto

import "encoding/json"

type PaymentResponse struct {
	ID             string `json:"id"`
	IdempotencyKey string `json:"idempotencyKey"`

	SubjectType string `json:"subjectType"`
	SubjectID   string `json:"subjectId"`
	Purpose     string `json:"purpose"`

	PayerUserID       string  `json:"payerUserId"`
	RequestedByUserID *string `json:"requestedByUserId,omitempty"`

	OperationType string `json:"operationType"`
	Status        string `json:"status"`
	Provider      string `json:"provider"`

	ProviderTransactionID *string `json:"providerTransactionId,omitempty"`
	ParentTransactionID   *string `json:"parentTransactionId,omitempty"`

	AmountMinor int64           `json:"amountMinor"`
	Currency    string          `json:"currency"`
	Description *string         `json:"description,omitempty"`
	Metadata    json.RawMessage `json:"metadata"`

	FailureCode    *string `json:"failureCode,omitempty"`
	FailureMessage *string `json:"failureMessage,omitempty"`
	CompletedAt    *string `json:"completedAt,omitempty"`

	CreatedAt string `json:"createdAt"`
	UpdatedAt string `json:"updatedAt"`
}

type PaymentListResponse struct {
	Items   []PaymentResponse `json:"items"`
	HasMore bool              `json:"hasMore"`
}
