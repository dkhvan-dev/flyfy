package trustpolicy

import (
	"context"

	"github.com/google/uuid"
)

type Action string

const (
	ActionActivityCreate         Action = "ACTIVITY_CREATE"
	ActionTourPublish            Action = "TOUR_PUBLISH"
	ActionChatSend               Action = "CHAT_SEND"
	ActionFileUpload             Action = "FILE_UPLOAD"
	ActionFileBind               Action = "FILE_BIND"
	ActionPayoutRequest          Action = "PAYOUT_REQUEST"
	ActionGuideApplicationSubmit Action = "GUIDE_APPLICATION_SUBMIT"
)

type Decision string

const (
	DecisionAllow      Decision = "ALLOW"
	DecisionDeny       Decision = "DENY"
	DecisionReview     Decision = "REVIEW"
	DecisionQuarantine Decision = "QUARANTINE"
	DecisionPending    Decision = "PENDING"
)

type Check struct {
	UserID         uuid.UUID
	Action         Action
	ResourceType   string
	ResourceID     string
	IdempotencyKey string
	Metadata       map[string]any
}

type Result struct {
	Decision         Decision
	ReasonCode       string
	PublicMessageKey string
	DecisionID       string
}

type PolicyClient interface {
	CheckActionPolicy(ctx context.Context, check Check) (Result, error)
}
