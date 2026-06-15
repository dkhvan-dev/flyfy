package model

import (
	"errors"
	"strings"
	"time"

	"github.com/google/uuid"
)

var (
	ErrInvalidActivityIdempotencyKey = errors.New("invalid activity idempotency key")
	ErrInvalidActivityRequestHash    = errors.New("invalid activity idempotency request hash")
)

type ActivityIdempotencyStatus string

const (
	ActivityIdempotencyStatusInProgress ActivityIdempotencyStatus = "IN_PROGRESS"
	ActivityIdempotencyStatusCompleted  ActivityIdempotencyStatus = "COMPLETED"
	ActivityIdempotencyStatusFailed     ActivityIdempotencyStatus = "FAILED"
)

func (s ActivityIdempotencyStatus) IsValid() bool {
	switch s {
	case ActivityIdempotencyStatusInProgress,
		ActivityIdempotencyStatusCompleted,
		ActivityIdempotencyStatusFailed:
		return true
	default:
		return false
	}
}

type ActivityIdempotencyKey struct {
	Key                string
	SourceService      string
	SourceResourceType string
	SourceResourceID   string
	HostUserID         uuid.UUID
	RequestHash        string
	ActivityID         *uuid.UUID
	Status             ActivityIdempotencyStatus
	LastError          *string
	CreatedAt          time.Time
	UpdatedAt          time.Time
	CompletedAt        *time.Time
}

func NewActivityIdempotencyKey(params ActivityIdempotencyKeyParams) (*ActivityIdempotencyKey, error) {
	now := time.Now().UTC()
	item := &ActivityIdempotencyKey{
		Key:                strings.TrimSpace(params.Key),
		SourceService:      strings.TrimSpace(params.SourceService),
		SourceResourceType: strings.TrimSpace(params.SourceResourceType),
		SourceResourceID:   strings.TrimSpace(params.SourceResourceID),
		HostUserID:         params.HostUserID,
		RequestHash:        strings.TrimSpace(params.RequestHash),
		Status:             ActivityIdempotencyStatusInProgress,
		CreatedAt:          now,
		UpdatedAt:          now,
	}
	if item.SourceResourceType == "" {
		item.SourceResourceType = "post"
	}
	if err := item.Validate(); err != nil {
		return nil, err
	}
	return item, nil
}

type ActivityIdempotencyKeyParams struct {
	Key                string
	SourceService      string
	SourceResourceType string
	SourceResourceID   string
	HostUserID         uuid.UUID
	RequestHash        string
}

func (k *ActivityIdempotencyKey) Validate() error {
	if k == nil ||
		strings.TrimSpace(k.Key) == "" ||
		strings.TrimSpace(k.SourceService) == "" ||
		strings.TrimSpace(k.SourceResourceType) == "" ||
		strings.TrimSpace(k.SourceResourceID) == "" ||
		k.HostUserID == uuid.Nil {
		return ErrInvalidActivityIdempotencyKey
	}
	if strings.TrimSpace(k.RequestHash) == "" {
		return ErrInvalidActivityRequestHash
	}
	if !k.Status.IsValid() {
		return ErrInvalidActivityIdempotencyKey
	}
	return nil
}
