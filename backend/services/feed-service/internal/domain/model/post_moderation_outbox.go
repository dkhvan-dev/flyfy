package model

import (
	"encoding/json"
	"time"

	"github.com/google/uuid"
)

type PostModerationOutboxStatus string

const (
	PostModerationOutboxPending   PostModerationOutboxStatus = "PENDING"
	PostModerationOutboxDelivered PostModerationOutboxStatus = "DELIVERED"
	PostModerationOutboxDead      PostModerationOutboxStatus = "DEAD"
)

const (
	PostModerationOutboxEventPostReviewed     = "post_moderation.reviewed"
	PostModerationOutboxEventReportCreated    = "post_report.created"
	PostModerationOutboxEventReportAutoHidden = "post_report.auto_hidden"
	PostModerationOutboxEventReportResolved   = "post_report.resolved"
)

type PostModerationOutboxEvent struct {
	ID            uuid.UUID
	EventType     string
	AggregateType string
	AggregateID   uuid.UUID
	CommunityID   *uuid.UUID
	PostID        *uuid.UUID
	ActorUserID   uuid.UUID
	Payload       json.RawMessage
	Status        PostModerationOutboxStatus
	AttemptCount  int
	NextAttemptAt time.Time
	LastError     string
	CreatedAt     time.Time
	DeliveredAt   *time.Time
}
