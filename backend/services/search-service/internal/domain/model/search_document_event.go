package model

import (
	"encoding/json"
	"time"
)

type SearchDocumentEvent struct {
	ID            string
	SourceService string
	SourceEventID string
	AggregateType string
	AggregateID   string
	EventType     string
	Payload       json.RawMessage
	Status        string
	AttemptCount  int
	NextAttemptAt time.Time
	CreatedAt     time.Time
}
