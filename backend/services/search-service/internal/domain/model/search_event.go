package model

import "time"

type SearchEvent struct {
	EventType       string
	SearchSessionID string
	QueryHash       string
	QueryLength     int
	UserIDHash      string
	AnonymousIDHash string
	Scope           Scope
	Domain          *Domain
	EntityID        string
	ResultPosition  int
	Locale          string
	RequestID       string
	Metadata        map[string]any
	CreatedAt       time.Time
}
