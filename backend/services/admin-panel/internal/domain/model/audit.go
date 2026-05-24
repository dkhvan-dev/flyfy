package model

import (
	"encoding/json"
	"time"

	"github.com/google/uuid"
)

type AuditEvent struct {
	ID               uuid.UUID
	ActorStaffID     *uuid.UUID
	ActorDisplayName string
	ActorEmail       string
	Action           string
	EntityType       string
	EntityID         *uuid.UUID
	RequestID        string
	IPAddressHash    string
	UserAgentHash    string
	BeforeJSON       json.RawMessage
	AfterJSON        json.RawMessage
	Metadata         json.RawMessage
	CreatedAt        time.Time
}

type AuditFilter struct {
	ActorStaffID *uuid.UUID
	EntityType   *string
	EntityID     *uuid.UUID
	Action       *string
	Limit        int
	Offset       int
}
