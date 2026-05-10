package model

import (
	"encoding/json"
	"errors"
	"time"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/tour-service/internal/domain/enum"
)

var (
	ErrInvalidTourEventID      = errors.New("invalid tour event id")
	ErrInvalidTourEventType    = errors.New("invalid tour event type")
	ErrInvalidTourEventPayload = errors.New("invalid tour event payload")
)

type TourEvent struct {
	ID          uuid.UUID
	TourID      uuid.UUID
	EventType   enum.TourEventType
	ActorUserID *uuid.UUID
	PayloadJSON []byte
	CreatedAt   time.Time
}

type NewTourEventParams struct {
	TourID      uuid.UUID
	EventType   enum.TourEventType
	ActorUserID *uuid.UUID
	Payload     any
}

func NewTourEvent(params NewTourEventParams) (*TourEvent, error) {
	payload := []byte("{}")
	if params.Payload != nil {
		raw, err := json.Marshal(params.Payload)
		if err != nil {
			return nil, ErrInvalidTourEventPayload
		}
		payload = raw
	}

	item := &TourEvent{
		ID:          uuid.New(),
		TourID:      params.TourID,
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

func (e *TourEvent) Validate() error {
	if e.ID == uuid.Nil || e.TourID == uuid.Nil {
		return ErrInvalidTourEventID
	}
	if !e.EventType.IsValid() {
		return ErrInvalidTourEventType
	}
	if !json.Valid(e.PayloadJSON) {
		return ErrInvalidTourEventPayload
	}
	return nil
}
