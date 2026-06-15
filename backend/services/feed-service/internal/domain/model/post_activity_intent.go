package model

import (
	"encoding/json"
	"time"

	"github.com/google/uuid"
)

type PostActivityIntentStatus string

const (
	PostActivityIntentPending   PostActivityIntentStatus = "PENDING"
	PostActivityIntentDelivered PostActivityIntentStatus = "DELIVERED"
	PostActivityIntentDead      PostActivityIntentStatus = "DEAD"
)

const PostActivityIntentEventRequested = "activity_creation_requested"

type PostActivityIntentEvent struct {
	ID                  uuid.UUID
	EventType           string
	IdempotencyKey      string
	PostID              uuid.UUID
	AuthorUserID        uuid.UUID
	CommunityID         *uuid.UUID
	CommunityInstanceID *uuid.UUID
	PostProfileKey      string
	PostProfileVersion  int
	StructuredData      json.RawMessage
	Payload             json.RawMessage
	Status              PostActivityIntentStatus
	AttemptCount        int
	NextAttemptAt       time.Time
	LastError           string
	CreatedAt           time.Time
	DeliveredAt         *time.Time
}
