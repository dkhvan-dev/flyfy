package model

import (
	"errors"
	"time"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/activity-service/internal/domain/enum"
)

var (
	ErrInvalidActivityEventID   = errors.New("invalid activity event id")
	ErrInvalidActivityEventType = errors.New("invalid activity event type")
)

type ActivityEvent struct {
	ID          uuid.UUID
	ActivityID  uuid.UUID
	EventType   enum.ActivityEventType
	ActorUserID *uuid.UUID
	PayloadJSON []byte
	CreatedAt   time.Time
}

type NewActivityEventParams struct {
	ActivityID  uuid.UUID
	EventType   enum.ActivityEventType
	ActorUserID *uuid.UUID
	PayloadJSON []byte
}

func NewActivityEvent(params NewActivityEventParams) (*ActivityEvent, error) {
	item := &ActivityEvent{
		ID:          uuid.New(),
		ActivityID:  params.ActivityID,
		EventType:   params.EventType,
		ActorUserID: params.ActorUserID,
		PayloadJSON: params.PayloadJSON,
		CreatedAt:   time.Now().UTC(),
	}

	if err := item.Validate(); err != nil {
		return nil, err
	}

	return item, nil
}

func (e *ActivityEvent) Validate() error {
	if e.ID == uuid.Nil || e.ActivityID == uuid.Nil {
		return ErrInvalidActivityEventID
	}
	if !e.EventType.IsValid() {
		return ErrInvalidActivityEventType
	}
	if e.PayloadJSON == nil {
		e.PayloadJSON = []byte(`{}`)
	}
	return nil
}
