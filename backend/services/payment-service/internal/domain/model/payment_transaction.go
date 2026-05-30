package model

import (
	"encoding/json"
	"errors"
	"regexp"
	"strings"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/payment-service/internal/domain/enum"
)

var (
	ErrInvalidPaymentID              = errors.New("invalid payment transaction id")
	ErrInvalidIdempotencyKey         = errors.New("invalid idempotency key")
	ErrInvalidPaymentSubject         = errors.New("invalid payment subject")
	ErrInvalidPaymentPurpose         = errors.New("invalid payment purpose")
	ErrInvalidPayerUserID            = errors.New("invalid payer user id")
	ErrInvalidPaymentOperationType   = errors.New("invalid payment operation type")
	ErrInvalidPaymentStatus          = errors.New("invalid payment status")
	ErrInvalidPaymentProvider        = errors.New("invalid payment provider")
	ErrInvalidPaymentAmount          = errors.New("invalid payment amount")
	ErrInvalidPaymentCurrency        = errors.New("invalid payment currency")
	ErrInvalidPaymentMetadata        = errors.New("invalid payment metadata")
	ErrInvalidParentPaymentReference = errors.New("invalid parent payment reference")
)

var (
	subjectTypePattern = regexp.MustCompile(`^[A-Z][A-Z0-9_]{1,39}$`)
	purposePattern     = regexp.MustCompile(`^[A-Z][A-Z0-9_]{1,49}$`)
	currencyPattern    = regexp.MustCompile(`^[A-Z]{3}$`)
)

type PaymentTransaction struct {
	ID             uuid.UUID
	IdempotencyKey string

	SubjectType string
	SubjectID   uuid.UUID
	Purpose     string

	PayerUserID       uuid.UUID
	RequestedByUserID *uuid.UUID

	OperationType enum.PaymentOperationType
	Status        enum.PaymentStatus
	Provider      enum.PaymentProvider

	ProviderTransactionID *string
	ParentTransactionID   *uuid.UUID

	AmountMinor int64
	Currency    string
	Description *string
	Metadata    []byte

	FailureCode    *string
	FailureMessage *string
	CompletedAt    *time.Time

	CreatedAt time.Time
	UpdatedAt time.Time
}

type NewPaymentTransactionParams struct {
	IdempotencyKey string
	SubjectType    string
	SubjectID      uuid.UUID
	Purpose        string

	PayerUserID       uuid.UUID
	RequestedByUserID *uuid.UUID

	OperationType enum.PaymentOperationType
	Status        enum.PaymentStatus
	Provider      enum.PaymentProvider

	ProviderTransactionID *string
	ParentTransactionID   *uuid.UUID

	AmountMinor int64
	Currency    string
	Description *string
	Metadata    []byte

	FailureCode    *string
	FailureMessage *string
	CompletedAt    *time.Time
}

func NewPaymentTransaction(params NewPaymentTransactionParams) (*PaymentTransaction, error) {
	now := time.Now().UTC()

	item := &PaymentTransaction{
		ID:             uuid.New(),
		IdempotencyKey: strings.TrimSpace(params.IdempotencyKey),
		SubjectType:    NormalizePaymentCode(params.SubjectType),
		SubjectID:      params.SubjectID,
		Purpose:        NormalizePaymentCode(params.Purpose),

		PayerUserID:       params.PayerUserID,
		RequestedByUserID: params.RequestedByUserID,

		OperationType: params.OperationType,
		Status:        params.Status,
		Provider:      params.Provider,

		ProviderTransactionID: NormalizeOptionalString(params.ProviderTransactionID),
		ParentTransactionID:   params.ParentTransactionID,

		AmountMinor: params.AmountMinor,
		Currency:    NormalizePaymentCode(params.Currency),
		Description: NormalizeOptionalString(params.Description),
		Metadata:    normalizeMetadata(params.Metadata),

		FailureCode:    NormalizeOptionalString(params.FailureCode),
		FailureMessage: NormalizeOptionalString(params.FailureMessage),
		CompletedAt:    params.CompletedAt,

		CreatedAt: now,
		UpdatedAt: now,
	}

	if err := item.Validate(); err != nil {
		return nil, err
	}

	return item, nil
}

func (p *PaymentTransaction) Validate() error {
	if p.ID == uuid.Nil {
		return ErrInvalidPaymentID
	}
	if len(strings.TrimSpace(p.IdempotencyKey)) < 8 || len(strings.TrimSpace(p.IdempotencyKey)) > 200 {
		return ErrInvalidIdempotencyKey
	}
	if !subjectTypePattern.MatchString(p.SubjectType) || p.SubjectID == uuid.Nil {
		return ErrInvalidPaymentSubject
	}
	if !purposePattern.MatchString(p.Purpose) {
		return ErrInvalidPaymentPurpose
	}
	if p.PayerUserID == uuid.Nil {
		return ErrInvalidPayerUserID
	}
	if p.RequestedByUserID != nil && *p.RequestedByUserID == uuid.Nil {
		return ErrInvalidPayerUserID
	}
	if !p.OperationType.IsValid() {
		return ErrInvalidPaymentOperationType
	}
	if !p.Status.IsValid() {
		return ErrInvalidPaymentStatus
	}
	if !p.Provider.IsValid() {
		return ErrInvalidPaymentProvider
	}
	if p.ParentTransactionID != nil && *p.ParentTransactionID == uuid.Nil {
		return ErrInvalidParentPaymentReference
	}
	if p.AmountMinor < 0 {
		return ErrInvalidPaymentAmount
	}
	if p.OperationType != enum.PaymentOperationTypeVoid && p.AmountMinor <= 0 {
		return ErrInvalidPaymentAmount
	}
	if !currencyPattern.MatchString(p.Currency) {
		return ErrInvalidPaymentCurrency
	}
	if !json.Valid(p.Metadata) {
		return ErrInvalidPaymentMetadata
	}

	return nil
}

func NormalizeOptionalString(v *string) *string {
	if v == nil {
		return nil
	}
	value := strings.TrimSpace(*v)
	if value == "" {
		return nil
	}
	return &value
}

func NormalizePaymentCode(v string) string {
	return strings.ToUpper(strings.TrimSpace(v))
}

func normalizeMetadata(v []byte) []byte {
	if len(v) == 0 || !json.Valid(v) {
		return []byte(`{}`)
	}
	return v
}
