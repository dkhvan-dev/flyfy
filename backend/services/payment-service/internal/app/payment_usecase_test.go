package app

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"sync"
	"testing"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/payment-service/internal/domain/enum"
	"github.com/dkhvan-dev/flyfy/backend/services/payment-service/internal/domain/model"
	"github.com/dkhvan-dev/flyfy/backend/services/payment-service/internal/domain/port"
)

func TestPaymentUseCaseChargeIsGenericAndIdempotent(t *testing.T) {
	ctx := context.Background()
	repo := newMemoryPaymentRepo()
	useCase := NewPaymentUseCase(repo, staticProvider{})

	payerID := uuid.New()
	activityID := uuid.New()

	first, err := useCase.Charge(ctx, CreatePaymentInput{
		IdempotencyKey: "charge-activity-1",
		SubjectType:    "ACTIVITY",
		SubjectID:      activityID,
		Purpose:        "JOIN_ACTIVITY",
		PayerUserID:    payerID,
		AmountMinor:    12_500,
		Currency:       "KZT",
	})
	if err != nil {
		t.Fatalf("charge activity: %v", err)
	}
	if first.Status != enum.PaymentStatusSucceeded {
		t.Fatalf("expected succeeded status, got %s", first.Status)
	}

	again, err := useCase.Charge(ctx, CreatePaymentInput{
		IdempotencyKey: "charge-activity-1",
		SubjectType:    "EXCURSION",
		SubjectID:      uuid.New(),
		Purpose:        "BOOK_EXCURSION",
		PayerUserID:    payerID,
		AmountMinor:    99_999,
		Currency:       "USD",
	})
	if err != nil {
		t.Fatalf("repeat charge with same idempotency key: %v", err)
	}
	if again.ID != first.ID {
		t.Fatalf("expected idempotent transaction id %s, got %s", first.ID, again.ID)
	}
	if again.SubjectType != "ACTIVITY" || again.Purpose != "JOIN_ACTIVITY" || again.AmountMinor != 12_500 {
		t.Fatalf("idempotent response was mutated: %#v", again)
	}

	excursion, err := useCase.Charge(ctx, CreatePaymentInput{
		IdempotencyKey: "charge-excursion-1",
		SubjectType:    "EXCURSION",
		SubjectID:      uuid.New(),
		Purpose:        "BOOK_EXCURSION",
		PayerUserID:    payerID,
		AmountMinor:    45_000,
		Currency:       "KZT",
	})
	if err != nil {
		t.Fatalf("charge excursion: %v", err)
	}
	if excursion.SubjectType != "EXCURSION" || excursion.Purpose != "BOOK_EXCURSION" {
		t.Fatalf("expected generic excursion payment, got %#v", excursion)
	}
}

func TestPaymentUseCaseRefundCannotExceedReservedAmount(t *testing.T) {
	ctx := context.Background()
	repo := newMemoryPaymentRepo()
	useCase := NewPaymentUseCase(repo, staticProvider{})

	charge, err := useCase.Charge(ctx, CreatePaymentInput{
		IdempotencyKey: "charge-refund-1",
		SubjectType:    "ACTIVITY",
		SubjectID:      uuid.New(),
		Purpose:        "JOIN_ACTIVITY",
		PayerUserID:    uuid.New(),
		AmountMinor:    1_000,
		Currency:       "KZT",
	})
	if err != nil {
		t.Fatalf("charge: %v", err)
	}

	firstRefund := int64(700)
	if _, err = useCase.Refund(ctx, ChildPaymentInput{
		ParentTransactionID: charge.ID,
		IdempotencyKey:      "refund-charge-1",
		AmountMinor:         &firstRefund,
	}); err != nil {
		t.Fatalf("refund: %v", err)
	}

	secondRefund := int64(400)
	_, err = useCase.Refund(ctx, ChildPaymentInput{
		ParentTransactionID: charge.ID,
		IdempotencyKey:      "refund-charge-2",
		AmountMinor:         &secondRefund,
	})
	if !errors.Is(err, ErrPaymentAmountExceeded) {
		t.Fatalf("expected ErrPaymentAmountExceeded, got %v", err)
	}
}

func TestPaymentUseCaseCaptureReservesPendingAmount(t *testing.T) {
	ctx := context.Background()
	repo := newMemoryPaymentRepo()
	useCase := NewPaymentUseCase(repo, staticProvider{
		captureStatus: enum.PaymentStatusPending,
	})

	authorization, err := useCase.Authorize(ctx, CreatePaymentInput{
		IdempotencyKey: "authorize-capture-1",
		SubjectType:    "ACTIVITY",
		SubjectID:      uuid.New(),
		Purpose:        "JOIN_ACTIVITY",
		PayerUserID:    uuid.New(),
		AmountMinor:    1_000,
		Currency:       "KZT",
	})
	if err != nil {
		t.Fatalf("authorize: %v", err)
	}

	firstCapture := int64(700)
	capture, err := useCase.Capture(ctx, ChildPaymentInput{
		ParentTransactionID: authorization.ID,
		IdempotencyKey:      "capture-auth-1",
		AmountMinor:         &firstCapture,
	})
	if err != nil {
		t.Fatalf("capture: %v", err)
	}
	if capture.Status != enum.PaymentStatusPending {
		t.Fatalf("expected pending capture, got %s", capture.Status)
	}

	secondCapture := int64(400)
	_, err = useCase.Capture(ctx, ChildPaymentInput{
		ParentTransactionID: authorization.ID,
		IdempotencyKey:      "capture-auth-2",
		AmountMinor:         &secondCapture,
	})
	if !errors.Is(err, ErrPaymentAmountExceeded) {
		t.Fatalf("expected ErrPaymentAmountExceeded, got %v", err)
	}
}

func TestPaymentUseCaseDoesNotCallProviderWhenFraudBlocksCharge(t *testing.T) {
	ctx := context.Background()
	repo := newMemoryPaymentRepo()
	provider := &trackingProvider{}
	useCase := NewPaymentUseCaseWithFraud(repo, provider, staticFraudDecision{
		decision: port.FraudDecisionBlock,
		reasons:  []string{"HIGH_PAYMENT_AMOUNT"},
	})

	transaction, err := useCase.Charge(ctx, CreatePaymentInput{
		IdempotencyKey: "charge-fraud-block-1",
		SubjectType:    "ACTIVITY",
		SubjectID:      uuid.New(),
		Purpose:        "JOIN_ACTIVITY",
		PayerUserID:    uuid.New(),
		AmountMinor:    2_000_000,
		Currency:       "KZT",
	})
	if err != nil {
		t.Fatalf("charge with fraud block: %v", err)
	}

	if provider.calls != 0 {
		t.Fatalf("expected provider not to be called, got %d calls", provider.calls)
	}
	if transaction.Status != enum.PaymentStatusFailed {
		t.Fatalf("expected failed transaction, got %s", transaction.Status)
	}
	if transaction.FailureCode == nil || *transaction.FailureCode != "FRAUD_BLOCKED" {
		t.Fatalf("expected FRAUD_BLOCKED failure code, got %#v", transaction.FailureCode)
	}
}

type staticProvider struct {
	captureStatus enum.PaymentStatus
}

func (p staticProvider) Authorize(ctx context.Context, input port.ProviderOperationInput) (*port.ProviderOperationResult, error) {
	return p.result(enum.PaymentOperationTypeAuthorize, input, enum.PaymentStatusSucceeded), nil
}

func (p staticProvider) Charge(ctx context.Context, input port.ProviderOperationInput) (*port.ProviderOperationResult, error) {
	return p.result(enum.PaymentOperationTypeCharge, input, enum.PaymentStatusSucceeded), nil
}

func (p staticProvider) Capture(ctx context.Context, input port.ProviderOperationInput) (*port.ProviderOperationResult, error) {
	status := p.captureStatus
	if status == "" {
		status = enum.PaymentStatusSucceeded
	}
	return p.result(enum.PaymentOperationTypeCapture, input, status), nil
}

func (p staticProvider) Refund(ctx context.Context, input port.ProviderOperationInput) (*port.ProviderOperationResult, error) {
	return p.result(enum.PaymentOperationTypeRefund, input, enum.PaymentStatusSucceeded), nil
}

func (p staticProvider) Void(ctx context.Context, input port.ProviderOperationInput) (*port.ProviderOperationResult, error) {
	return p.result(enum.PaymentOperationTypeVoid, input, enum.PaymentStatusSucceeded), nil
}

func (p staticProvider) result(
	operationType enum.PaymentOperationType,
	input port.ProviderOperationInput,
	status enum.PaymentStatus,
) *port.ProviderOperationResult {
	return &port.ProviderOperationResult{
		Provider:              enum.PaymentProviderMock,
		ProviderTransactionID: fmt.Sprintf("mock_%s_%s", strings.ToLower(string(operationType)), input.TransactionID),
		Status:                status,
	}
}

type trackingProvider struct {
	calls int
}

func (p *trackingProvider) Authorize(ctx context.Context, input port.ProviderOperationInput) (*port.ProviderOperationResult, error) {
	p.calls++
	return staticProvider{}.Authorize(ctx, input)
}

func (p *trackingProvider) Charge(ctx context.Context, input port.ProviderOperationInput) (*port.ProviderOperationResult, error) {
	p.calls++
	return staticProvider{}.Charge(ctx, input)
}

func (p *trackingProvider) Capture(ctx context.Context, input port.ProviderOperationInput) (*port.ProviderOperationResult, error) {
	p.calls++
	return staticProvider{}.Capture(ctx, input)
}

func (p *trackingProvider) Refund(ctx context.Context, input port.ProviderOperationInput) (*port.ProviderOperationResult, error) {
	p.calls++
	return staticProvider{}.Refund(ctx, input)
}

func (p *trackingProvider) Void(ctx context.Context, input port.ProviderOperationInput) (*port.ProviderOperationResult, error) {
	p.calls++
	return staticProvider{}.Void(ctx, input)
}

type staticFraudDecision struct {
	decision port.FraudDecision
	reasons  []string
	shadow   bool
}

func (f staticFraudDecision) AssessPayment(ctx context.Context, input port.FraudAssessmentInput) (*port.FraudAssessmentResult, error) {
	return &port.FraudAssessmentResult{
		Decision:   f.decision,
		RiskScore:  95,
		Reasons:    f.reasons,
		ShadowMode: f.shadow,
	}, nil
}

type memoryPaymentRepo struct {
	mu           sync.Mutex
	transactions map[uuid.UUID]*model.PaymentTransaction
	byKey        map[string]uuid.UUID
	events       []*model.PaymentEvent
}

func newMemoryPaymentRepo() *memoryPaymentRepo {
	return &memoryPaymentRepo{
		transactions: make(map[uuid.UUID]*model.PaymentTransaction),
		byKey:        make(map[string]uuid.UUID),
		events:       make([]*model.PaymentEvent, 0),
	}
}

func (r *memoryPaymentRepo) GetTransactionByID(ctx context.Context, transactionID uuid.UUID) (*model.PaymentTransaction, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	return clonePaymentTransaction(r.transactions[transactionID]), nil
}

func (r *memoryPaymentRepo) GetTransactionByIdempotencyKey(ctx context.Context, idempotencyKey string) (*model.PaymentTransaction, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	id, ok := r.byKey[strings.TrimSpace(idempotencyKey)]
	if !ok {
		return nil, nil
	}
	return clonePaymentTransaction(r.transactions[id]), nil
}

func (r *memoryPaymentRepo) ListTransactions(ctx context.Context, filter port.PaymentFilter) ([]*model.PaymentTransaction, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	result := make([]*model.PaymentTransaction, 0, len(r.transactions))
	for _, item := range r.transactions {
		result = append(result, clonePaymentTransaction(item))
	}
	return result, nil
}

func (r *memoryPaymentRepo) WithTx(ctx context.Context, fn func(repo port.PaymentTxRepository) error) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	return fn(&memoryPaymentTxRepo{repo: r})
}

type memoryPaymentTxRepo struct {
	repo *memoryPaymentRepo
}

func (r *memoryPaymentTxRepo) GetTransactionByIDForUpdate(ctx context.Context, transactionID uuid.UUID) (*model.PaymentTransaction, error) {
	return clonePaymentTransaction(r.repo.transactions[transactionID]), nil
}

func (r *memoryPaymentTxRepo) GetTransactionByIdempotencyKey(ctx context.Context, idempotencyKey string) (*model.PaymentTransaction, error) {
	id, ok := r.repo.byKey[strings.TrimSpace(idempotencyKey)]
	if !ok {
		return nil, nil
	}
	return clonePaymentTransaction(r.repo.transactions[id]), nil
}

func (r *memoryPaymentTxRepo) SumReservedChildAmount(
	ctx context.Context,
	parentTransactionID uuid.UUID,
	operationType enum.PaymentOperationType,
) (int64, error) {
	var amount int64
	for _, item := range r.repo.transactions {
		if item.ParentTransactionID == nil || *item.ParentTransactionID != parentTransactionID {
			continue
		}
		if item.OperationType != operationType {
			continue
		}
		if item.Status != enum.PaymentStatusPending && item.Status != enum.PaymentStatusSucceeded {
			continue
		}
		amount += item.AmountMinor
	}
	return amount, nil
}

func (r *memoryPaymentTxRepo) CreateTransaction(ctx context.Context, item *model.PaymentTransaction) error {
	if _, exists := r.repo.byKey[item.IdempotencyKey]; exists {
		return fmt.Errorf("duplicate idempotency key: %s", item.IdempotencyKey)
	}
	r.repo.transactions[item.ID] = clonePaymentTransaction(item)
	r.repo.byKey[item.IdempotencyKey] = item.ID
	return nil
}

func (r *memoryPaymentTxRepo) UpdateTransactionResult(ctx context.Context, item *model.PaymentTransaction) error {
	if _, exists := r.repo.transactions[item.ID]; !exists {
		return ErrPaymentNotFound
	}
	r.repo.transactions[item.ID] = clonePaymentTransaction(item)
	return nil
}

func (r *memoryPaymentTxRepo) CreateEvent(ctx context.Context, item *model.PaymentEvent) error {
	r.repo.events = append(r.repo.events, item)
	return nil
}

func clonePaymentTransaction(item *model.PaymentTransaction) *model.PaymentTransaction {
	if item == nil {
		return nil
	}

	clone := *item
	if item.RequestedByUserID != nil {
		v := *item.RequestedByUserID
		clone.RequestedByUserID = &v
	}
	if item.ProviderTransactionID != nil {
		v := *item.ProviderTransactionID
		clone.ProviderTransactionID = &v
	}
	if item.ParentTransactionID != nil {
		v := *item.ParentTransactionID
		clone.ParentTransactionID = &v
	}
	if item.Description != nil {
		v := *item.Description
		clone.Description = &v
	}
	if item.Metadata != nil {
		clone.Metadata = append([]byte(nil), item.Metadata...)
	}
	if item.FailureCode != nil {
		v := *item.FailureCode
		clone.FailureCode = &v
	}
	if item.FailureMessage != nil {
		v := *item.FailureMessage
		clone.FailureMessage = &v
	}
	if item.CompletedAt != nil {
		v := *item.CompletedAt
		clone.CompletedAt = &v
	}

	return &clone
}
