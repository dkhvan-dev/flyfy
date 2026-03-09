package model

import (
	"errors"
	"strings"
	"time"

	"github.com/google/uuid"
)

var (
	ErrInvalidParticipantEventID = errors.New("invalid participant event id")
	ErrInvalidParticipantRef     = errors.New("invalid participant event reference")
	ErrInvalidParticipantEvent   = errors.New("invalid participant event type")
)

type ParticipantEvent struct {
	ID            uuid.UUID
	ActivityID    uuid.UUID
	ParticipantID uuid.UUID
	UserID        uuid.UUID
	EventType     string
	ActorUserID   *uuid.UUID
	PayloadJSON   []byte
	CreatedAt     time.Time
}

type NewParticipantEventParams struct {
	ActivityID    uuid.UUID
	ParticipantID uuid.UUID
	UserID        uuid.UUID
	EventType     string
	ActorUserID   *uuid.UUID
	PayloadJSON   []byte
}

func NewParticipantEvent(params NewParticipantEventParams) (*ParticipantEvent, error) {
	item := &ParticipantEvent{
		ID:            uuid.New(),
		ActivityID:    params.ActivityID,
		ParticipantID: params.ParticipantID,
		UserID:        params.UserID,
		EventType:     params.EventType,
		ActorUserID:   params.ActorUserID,
		PayloadJSON:   params.PayloadJSON,
		CreatedAt:     time.Now().UTC(),
	}

	if err := item.Validate(); err != nil {
		return nil, err
	}

	return item, nil
}

func (e *ParticipantEvent) Validate() error {
	if e.ID == uuid.Nil {
		return ErrInvalidParticipantEventID
	}
	if e.ActivityID == uuid.Nil || e.ParticipantID == uuid.Nil || e.UserID == uuid.Nil {
		return ErrInvalidParticipantRef
	}
	if strings.TrimSpace(e.EventType) == "" {
		return ErrInvalidParticipantEvent
	}
	if e.PayloadJSON == nil {
		e.PayloadJSON = []byte(`{}`)
	}
	return nil
}
