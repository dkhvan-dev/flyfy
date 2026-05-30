package port

import (
	"context"

	"github.com/google/uuid"

	"kz/inflap/backend/services/payment-service/internal/domain/enum"
	"kz/inflap/backend/services/payment-service/internal/domain/model"
)

type PaymentFilter struct {
	SubjectType   *string
	SubjectID     *uuid.UUID
	PayerUserID   *uuid.UUID
	OperationType *enum.PaymentOperationType
	Status        *enum.PaymentStatus
	Limit         int
	Offset        int
}

type PaymentTxRepository interface {
	GetTransactionByIDForUpdate(ctx context.Context, transactionID uuid.UUID) (*model.PaymentTransaction, error)
	GetTransactionByIdempotencyKey(ctx context.Context, idempotencyKey string) (*model.PaymentTransaction, error)
	SumReservedChildAmount(ctx context.Context, parentTransactionID uuid.UUID, operationType enum.PaymentOperationType) (int64, error)
	CreateTransaction(ctx context.Context, item *model.PaymentTransaction) error
	UpdateTransactionResult(ctx context.Context, item *model.PaymentTransaction) error
	CreateEvent(ctx context.Context, item *model.PaymentEvent) error
}

type PaymentRepository interface {
	GetTransactionByID(ctx context.Context, transactionID uuid.UUID) (*model.PaymentTransaction, error)
	GetTransactionByIdempotencyKey(ctx context.Context, idempotencyKey string) (*model.PaymentTransaction, error)
	ListTransactions(ctx context.Context, filter PaymentFilter) ([]*model.PaymentTransaction, error)
	WithTx(ctx context.Context, fn func(repo PaymentTxRepository) error) error
}
