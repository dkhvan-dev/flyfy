package model

import (
	"encoding/json"
	"errors"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/excursion-service/internal/domain/enum"
)

var (
	ErrInvalidExcursionEventID      = errors.New("invalid excursion event id")
	ErrInvalidExcursionEventType    = errors.New("invalid excursion event type")
	ErrInvalidExcursionEventPayload = errors.New("invalid excursion event payload")
)

type ExcursionEvent struct {
	ID          uuid.UUID
	ExcursionID uuid.UUID
	EventType   enum.ExcursionEventType
	ActorUserID *uuid.UUID
	PayloadJSON []byte
	CreatedAt   time.Time
}

type NewExcursionEventParams struct {
	ExcursionID uuid.UUID
	EventType   enum.ExcursionEventType
	ActorUserID *uuid.UUID
	Payload     any
}

func NewExcursionEvent(params NewExcursionEventParams) (*ExcursionEvent, error) {
	payload := []byte("{}")
	if params.Payload != nil {
		raw, err := json.Marshal(params.Payload)
		if err != nil {
			return nil, ErrInvalidExcursionEventPayload
		}
		payload = raw
	}

	item := &ExcursionEvent{
		ID:          uuid.New(),
		ExcursionID: params.ExcursionID,
		EventType:   params.EventType,
		ActorUserID: params.ActorUserID,
		PayloadJSON: payload,
		CreatedAt:   time.Now().UTC(),
	}
	if err := item.Validate(); err != nil {
		return nil, err
	}
	return item, nil
}

func (e *ExcursionEvent) Validate() error {
	if e.ID == uuid.Nil || e.ExcursionID == uuid.Nil {
		return ErrInvalidExcursionEventID
	}
	if !e.EventType.IsValid() {
		return ErrInvalidExcursionEventType
	}
	if !json.Valid(e.PayloadJSON) {
		return ErrInvalidExcursionEventPayload
	}
	return nil
}
