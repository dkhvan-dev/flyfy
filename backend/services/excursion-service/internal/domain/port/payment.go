package port

import (
	"context"

	"github.com/google/uuid"
)

const (
	PaymentOperationTypeCharge = "CHARGE"
	PaymentOperationTypeRefund = "REFUND"

	PaymentStatusPending   = "PENDING"
	PaymentStatusSucceeded = "SUCCEEDED"
)

type PaymentTransaction struct {
	ID            uuid.UUID
	OperationType string
	Status        string
	AmountMinor   int64
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

type PaymentTransactionFilter struct {
	SubjectType   string
	SubjectID     *uuid.UUID
	OperationType *string
	Status        *string
	Limit         int
	Offset        int
}

type ExcursionPaymentGateway interface {
	Charge(ctx context.Context, input PaymentCreateInput) (*PaymentTransaction, error)
	Refund(ctx context.Context, input PaymentChildInput) (*PaymentTransaction, error)
	ListTransactions(ctx context.Context, filter PaymentTransactionFilter) ([]*PaymentTransaction, error)
}
