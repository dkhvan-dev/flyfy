package model

import (
	"time"

	"github.com/google/uuid"
)

type IdempotencyRecord struct {
	ID                 uuid.UUID
	Operation          string
	IdempotencyKey     string
	RequestFingerprint string

	ResponseStatusCode *int
	ResponseBody       []byte

	ResourceType *string
	ResourceID   *uuid.UUID

	CreatedByUserID *uuid.UUID
	ExpiresAt       time.Time
	CreatedAt       time.Time
	UpdatedAt       time.Time
}
