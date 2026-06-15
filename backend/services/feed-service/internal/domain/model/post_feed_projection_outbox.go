package model

import (
	"encoding/json"
	"time"

	"github.com/google/uuid"
)

type PostFeedProjectionOutboxStatus string

const (
	PostFeedProjectionOutboxPending   PostFeedProjectionOutboxStatus = "PENDING"
	PostFeedProjectionOutboxDelivered PostFeedProjectionOutboxStatus = "DELIVERED"
	PostFeedProjectionOutboxDead      PostFeedProjectionOutboxStatus = "DEAD"
)

const (
	PostFeedProjectionEventUpsert = "post_feed.upsert"
	PostFeedProjectionEventDelete = "post_feed.delete"
)

type PostFeedProjectionOutboxEvent struct {
	ID            uuid.UUID
	EventType     string
	PostID        uuid.UUID
	PostRevision  int64
	Payload       json.RawMessage
	Status        PostFeedProjectionOutboxStatus
	AttemptCount  int
	NextAttemptAt time.Time
	LastError     string
	CreatedAt     time.Time
	DeliveredAt   *time.Time
}
