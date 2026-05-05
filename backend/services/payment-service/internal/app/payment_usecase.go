package app

import (
	"context"
	"encoding/json"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/payment-service/internal/domain/enum"
	"github.com/dkhvan-dev/flyfy/backend/services/payment-service/internal/domain/model"
	"github.com/dkhvan-dev/flyfy/backend/services/payment-service/internal/domain/port"
)

type PaymentUseCase struct {
	repo     port.PaymentRepository
	provider port.PaymentProvider
}

func NewPaymentUseCase(repo port.PaymentRepository, provider port.PaymentProvider) *PaymentUseCase {
	return &PaymentUseCase{repo: repo, provider: provider}
}

type CreatePaymentInput struct {
	IdempotencyKey string
	SubjectType    string
	SubjectID      uuid.UUID
	Purpose        string

	PayerUserID       uuid.UUID
	RequestedByUserID *uuid.UUID

	AmountMinor int64
	Currency    string
	Description *string
	Metadata    []byte
}

type ChildPaymentInput struct {
	ParentTransactionID uuid.UUID
	IdempotencyKey      string
	RequestedByUserID   *uuid.UUID
	AmountMinor         *int64
	Description         *string
	Metadata            []byte
}

func (u *PaymentUseCase) Authorize(ctx context.Context, input CreatePaymentInput) (*model.PaymentTransaction, error) {
	return u.createRootOperation(ctx, input, enum.PaymentOperationTypeAuthorize)
}

func (u *PaymentUseCase) Charge(ctx context.Context, input CreatePaymentInput) (*model.PaymentTransaction, error) {
	return u.createRootOperation(ctx, input, enum.PaymentOperationTypeCharge)
}

func (u *PaymentUseCase) Capture(ctx context.Context, input ChildPaymentInput) (*model.PaymentTransaction, error) {
	return u.createChildOperation(ctx, input, enum.PaymentOperationTypeCapture)
}

func (u *PaymentUseCase) Refund(ctx context.Context, input ChildPaymentInput) (*model.PaymentTransaction, error) {
	return u.createChildOperation(ctx, input, enum.PaymentOperationTypeRefund)
}

func (u *PaymentUseCase) Void(ctx context.Context, input ChildPaymentInput) (*model.PaymentTransaction, error) {
	return u.createChildOperation(ctx, input, enum.PaymentOperationTypeVoid)
}

func (u *PaymentUseCase) GetTransaction(ctx context.Context, transactionID uuid.UUID) (*model.PaymentTransaction, error) {
	if transactionID == uuid.Nil {
		return nil, ErrInvalidPaymentID
	}

	item, err := u.repo.GetTransactionByID(ctx, transactionID)
	if err != nil {
		return nil, fmt.Errorf("get payment transaction: %w", err)
	}
	if item == nil {
		return nil, ErrPaymentNotFound
	}

	return item, nil
}

func (u *PaymentUseCase) ListTransactions(ctx context.Context, filter port.PaymentFilter) ([]*model.PaymentTransaction, error) {
	if filter.Limit <= 0 {
		filter.Limit = 20
	}
	if filter.Limit > 100 {
		filter.Limit = 100
	}
	if filter.Offset < 0 {
		filter.Offset = 0
	}

	return u.repo.ListTransactions(ctx, filter)
}

func (u *PaymentUseCase) createRootOperation(
	ctx context.Context,
	input CreatePaymentInput,
	operationType enum.PaymentOperationType,
) (*model.PaymentTransaction, error) {
	var result *model.PaymentTransaction
	var created *model.PaymentTransaction

	err := u.repo.WithTx(ctx, func(txRepo port.PaymentTxRepository) error {
		existing, err := txRepo.GetTransactionByIdempotencyKey(ctx, strings.TrimSpace(input.IdempotencyKey))
		if err != nil {
			return fmt.Errorf("get transaction by idempotency key: %w", err)
		}
		if existing != nil {
			result = existing
			return nil
		}

		item, err := model.NewPaymentTransaction(model.NewPaymentTransactionParams{
			IdempotencyKey:    input.IdempotencyKey,
			SubjectType:       input.SubjectType,
			SubjectID:         input.SubjectID,
			Purpose:           input.Purpose,
			PayerUserID:       input.PayerUserID,
			RequestedByUserID: input.RequestedByUserID,
			OperationType:     operationType,
			Status:            enum.PaymentStatusPending,
			Provider:          enum.PaymentProviderMock,
			AmountMinor:       input.AmountMinor,
			Currency:          input.Currency,
			Description:       input.Description,
			Metadata:          input.Metadata,
		})
		if err != nil {
			return err
		}

		if err = txRepo.CreateTransaction(ctx, item); err != nil {
			return fmt.Errorf("create payment transaction: %w", err)
		}
		if err = txRepo.CreateEvent(ctx, newEventOrPanic(item.ID, string(operationType)+"_"+string(item.Status), map[string]any{
			"operationType": string(operationType),
			"status":        string(item.Status),
			"provider":      string(item.Provider),
		})); err != nil {
			return fmt.Errorf("create payment event: %w", err)
		}

		created = item
		return nil
	})
	if err != nil {
		return nil, err
	}
	if result != nil {
		return result, nil
	}

	providerResult, err := u.runProviderOperation(ctx, operationType, created)
	if err != nil {
		return nil, err
	}

	return u.finalizeProviderResult(ctx, created.ID, providerResult)
}

func (u *PaymentUseCase) createChildOperation(
	ctx context.Context,
	input ChildPaymentInput,
	operationType enum.PaymentOperationType,
) (*model.PaymentTransaction, error) {
	if input.ParentTransactionID == uuid.Nil {
		return nil, ErrInvalidParentPayment
	}

	var result *model.PaymentTransaction
	var created *model.PaymentTransaction

	err := u.repo.WithTx(ctx, func(txRepo port.PaymentTxRepository) error {
		existing, err := txRepo.GetTransactionByIdempotencyKey(ctx, strings.TrimSpace(input.IdempotencyKey))
		if err != nil {
			return fmt.Errorf("get transaction by idempotency key: %w", err)
		}
		if existing != nil {
			result = existing
			return nil
		}

		parent, err := txRepo.GetTransactionByIDForUpdate(ctx, input.ParentTransactionID)
		if err != nil {
			return fmt.Errorf("get parent payment transaction: %w", err)
		}
		if parent == nil {
			return ErrPaymentNotFound
		}
		if parent.Status != enum.PaymentStatusSucceeded {
			return ErrPaymentAlreadyFinalized
		}

		amount, err := u.resolveChildAmount(ctx, txRepo, parent, input.AmountMinor, operationType)
		if err != nil {
			return err
		}

		item, err := model.NewPaymentTransaction(model.NewPaymentTransactionParams{
			IdempotencyKey:      input.IdempotencyKey,
			SubjectType:         parent.SubjectType,
			SubjectID:           parent.SubjectID,
			Purpose:             parent.Purpose,
			PayerUserID:         parent.PayerUserID,
			RequestedByUserID:   input.RequestedByUserID,
			OperationType:       operationType,
			Status:              enum.PaymentStatusPending,
			Provider:            parent.Provider,
			ParentTransactionID: &parent.ID,
			AmountMinor:         amount,
			Currency:            parent.Currency,
			Description:         input.Description,
			Metadata:            input.Metadata,
		})
		if err != nil {
			return err
		}

		if err = txRepo.CreateTransaction(ctx, item); err != nil {
			return fmt.Errorf("create child payment transaction: %w", err)
		}
		if err = txRepo.CreateEvent(ctx, newEventOrPanic(item.ID, string(operationType)+"_"+string(item.Status), map[string]any{
			"operationType": string(operationType),
			"status":        string(item.Status),
			"provider":      string(item.Provider),
			"parentId":      parent.ID.String(),
		})); err != nil {
			return fmt.Errorf("create child payment event: %w", err)
		}

		created = item
		return nil
	})
	if err != nil {
		return nil, err
	}
	if result != nil {
		return result, nil
	}

	providerResult, err := u.runProviderOperation(ctx, operationType, created)
	if err != nil {
		return nil, err
	}

	return u.finalizeProviderResult(ctx, created.ID, providerResult)
}

func (u *PaymentUseCase) resolveChildAmount(
	ctx context.Context,
	txRepo port.PaymentTxRepository,
	parent *model.PaymentTransaction,
	requestedAmount *int64,
	operationType enum.PaymentOperationType,
) (int64, error) {
	if parent == nil {
		return 0, ErrInvalidParentPayment
	}

	switch operationType {
	case enum.PaymentOperationTypeCapture:
		if parent.OperationType != enum.PaymentOperationTypeAuthorize {
			return 0, ErrPaymentOperationUnsupported
		}
		captured, err := txRepo.SumReservedChildAmount(ctx, parent.ID, enum.PaymentOperationTypeCapture)
		if err != nil {
			return 0, fmt.Errorf("sum captured amount: %w", err)
		}
		voided, err := txRepo.SumReservedChildAmount(ctx, parent.ID, enum.PaymentOperationTypeVoid)
		if err != nil {
			return 0, fmt.Errorf("sum voided amount: %w", err)
		}
		return chooseAvailableAmount(parent.AmountMinor-captured-voided, requestedAmount)

	case enum.PaymentOperationTypeVoid:
		if parent.OperationType != enum.PaymentOperationTypeAuthorize {
			return 0, ErrPaymentOperationUnsupported
		}
		captured, err := txRepo.SumReservedChildAmount(ctx, parent.ID, enum.PaymentOperationTypeCapture)
		if err != nil {
			return 0, fmt.Errorf("sum captured amount: %w", err)
		}
		voided, err := txRepo.SumReservedChildAmount(ctx, parent.ID, enum.PaymentOperationTypeVoid)
		if err != nil {
			return 0, fmt.Errorf("sum voided amount: %w", err)
		}
		return chooseAvailableAmount(parent.AmountMinor-captured-voided, requestedAmount)

	case enum.PaymentOperationTypeRefund:
		if parent.OperationType != enum.PaymentOperationTypeCharge &&
			parent.OperationType != enum.PaymentOperationTypeCapture {
			return 0, ErrPaymentOperationUnsupported
		}
		refunded, err := txRepo.SumReservedChildAmount(ctx, parent.ID, enum.PaymentOperationTypeRefund)
		if err != nil {
			return 0, fmt.Errorf("sum refunded amount: %w", err)
		}
		return chooseAvailableAmount(parent.AmountMinor-refunded, requestedAmount)

	default:
		return 0, ErrPaymentOperationUnsupported
	}
}

func chooseAvailableAmount(available int64, requested *int64) (int64, error) {
	if available <= 0 {
		return 0, ErrPaymentAmountExceeded
	}
	if requested == nil {
		return available, nil
	}
	if *requested <= 0 {
		return 0, ErrInvalidAmount
	}
	if *requested > available {
		return 0, ErrPaymentAmountExceeded
	}
	return *requested, nil
}

func (u *PaymentUseCase) runProviderOperation(
	ctx context.Context,
	operationType enum.PaymentOperationType,
	item *model.PaymentTransaction,
) (*port.ProviderOperationResult, error) {
	input := port.ProviderOperationInput{
		IdempotencyKey: item.IdempotencyKey,
		TransactionID:  item.ID,
		SubjectType:    item.SubjectType,
		SubjectID:      item.SubjectID,
		Purpose:        item.Purpose,
		AmountMinor:    item.AmountMinor,
		Currency:       item.Currency,
	}

	switch operationType {
	case enum.PaymentOperationTypeAuthorize:
		return u.provider.Authorize(ctx, input)
	case enum.PaymentOperationTypeCharge:
		return u.provider.Charge(ctx, input)
	case enum.PaymentOperationTypeCapture:
		return u.provider.Capture(ctx, input)
	case enum.PaymentOperationTypeRefund:
		return u.provider.Refund(ctx, input)
	case enum.PaymentOperationTypeVoid:
		return u.provider.Void(ctx, input)
	default:
		return nil, ErrPaymentOperationUnsupported
	}
}

func (u *PaymentUseCase) finalizeProviderResult(
	ctx context.Context,
	transactionID uuid.UUID,
	providerResult *port.ProviderOperationResult,
) (*model.PaymentTransaction, error) {
	var result *model.PaymentTransaction

	err := u.repo.WithTx(ctx, func(txRepo port.PaymentTxRepository) error {
		item, err := txRepo.GetTransactionByIDForUpdate(ctx, transactionID)
		if err != nil {
			return fmt.Errorf("get payment transaction for finalize: %w", err)
		}
		if item == nil {
			return ErrPaymentNotFound
		}
		if item.Status != enum.PaymentStatusPending {
			result = item
			return nil
		}

		applyProviderResult(item, providerResult)

		if err = txRepo.UpdateTransactionResult(ctx, item); err != nil {
			return fmt.Errorf("update payment transaction result: %w", err)
		}
		if err = txRepo.CreateEvent(ctx, newEventOrPanic(item.ID, string(item.OperationType)+"_"+string(item.Status), map[string]any{
			"operationType": string(item.OperationType),
			"status":        string(item.Status),
			"provider":      string(item.Provider),
			"providerId":    item.ProviderTransactionID,
		})); err != nil {
			return fmt.Errorf("create payment event: %w", err)
		}

		result = item
		return nil
	})
	if err != nil {
		return nil, err
	}

	return result, nil
}

func applyProviderResult(item *model.PaymentTransaction, result *port.ProviderOperationResult) {
	now := time.Now().UTC()
	if result == nil {
		item.Status = enum.PaymentStatusFailed
		item.UpdatedAt = now
		item.CompletedAt = &now
		return
	}

	item.Provider = result.Provider
	item.ProviderTransactionID = model.NormalizeOptionalString(&result.ProviderTransactionID)
	item.Status = result.Status
	item.FailureCode = result.FailureCode
	item.FailureMessage = result.FailureMessage
	item.UpdatedAt = now
	if item.Status == enum.PaymentStatusPending {
		item.CompletedAt = nil
	} else {
		item.CompletedAt = &now
	}
}

func newEventOrPanic(transactionID uuid.UUID, eventType string, payload any) *model.PaymentEvent {
	body, err := json.Marshal(payload)
	if err != nil {
		body = []byte(`{}`)
	}
	event, err := model.NewPaymentEvent(model.NewPaymentEventParams{
		TransactionID: transactionID,
		EventType:     eventType,
		Payload:       body,
	})
	if err != nil {
		panic(err)
	}
	return event
}
