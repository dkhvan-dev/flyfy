package port

import (
	"context"

	"github.com/google/uuid"
)

const (
	PaymentStatusPending   = "PENDING"
	PaymentStatusSucceeded = "SUCCEEDED"
)

type PaymentTransaction struct {
	ID            uuid.UUID
	OperationType string
	Status        string
}

type PaymentCreateInput struct {
	IdempotencyKey string
	SubjectType    string
	SubjectID      uuid.UUID
	Purpose        string
	PayerUserID    uuid.UUID
	AmountMinor    int64
	Currency       string
	Description    *string
	Metadata       map[string]any
}

type PaymentChildInput struct {
	ParentTransactionID uuid.UUID
	IdempotencyKey      string
	AmountMinor         *int64
	Description         *string
	Metadata            map[string]any
}

type ActivityPaymentGateway interface {
	Authorize(ctx context.Context, input PaymentCreateInput) (*PaymentTransaction, error)
	Capture(ctx context.Context, input PaymentChildInput) (*PaymentTransaction, error)
	Refund(ctx context.Context, input PaymentChildInput) (*PaymentTransaction, error)
	Void(ctx context.Context, input PaymentChildInput) (*PaymentTransaction, error)
}
