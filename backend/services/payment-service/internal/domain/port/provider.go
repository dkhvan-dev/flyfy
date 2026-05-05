package port

import (
	"context"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/payment-service/internal/domain/enum"
)

type ProviderOperationInput struct {
	IdempotencyKey string
	TransactionID  uuid.UUID
	SubjectType    string
	SubjectID      uuid.UUID
	Purpose        string
	AmountMinor    int64
	Currency       string
}

type ProviderOperationResult struct {
	Provider              enum.PaymentProvider
	ProviderTransactionID string
	Status                enum.PaymentStatus
	FailureCode           *string
	FailureMessage        *string
}

type PaymentProvider interface {
	Authorize(ctx context.Context, input ProviderOperationInput) (*ProviderOperationResult, error)
	Charge(ctx context.Context, input ProviderOperationInput) (*ProviderOperationResult, error)
	Capture(ctx context.Context, input ProviderOperationInput) (*ProviderOperationResult, error)
	Refund(ctx context.Context, input ProviderOperationInput) (*ProviderOperationResult, error)
	Void(ctx context.Context, input ProviderOperationInput) (*ProviderOperationResult, error)
}
