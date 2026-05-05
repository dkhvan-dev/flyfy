package model

import (
	"errors"
	"strings"
	"time"

	"github.com/google/uuid"
)

var (
	ErrInvalidPaymentEventID   = errors.New("invalid payment event id")
	ErrInvalidPaymentEventType = errors.New("invalid payment event type")
)

type PaymentEvent struct {
	ID            uuid.UUID
	TransactionID uuid.UUID
	EventType     string
	Payload       []byte
	CreatedAt     time.Time
}

type NewPaymentEventParams struct {
	TransactionID uuid.UUID
	EventType     string
	Payload       []byte
}

func NewPaymentEvent(params NewPaymentEventParams) (*PaymentEvent, error) {
	item := &PaymentEvent{
		ID:            uuid.New(),
		TransactionID: params.TransactionID,
		EventType:     strings.TrimSpace(params.EventType),
		Payload:       normalizeMetadata(params.Payload),
		CreatedAt:     time.Now().UTC(),
	}

	if err := item.Validate(); err != nil {
		return nil, err
	}

	return item, nil
}

func (e *PaymentEvent) Validate() error {
	if e.ID == uuid.Nil || e.TransactionID == uuid.Nil {
		return ErrInvalidPaymentEventID
	}
	if e.EventType == "" {
		return ErrInvalidPaymentEventType
	}
	return nil
}
