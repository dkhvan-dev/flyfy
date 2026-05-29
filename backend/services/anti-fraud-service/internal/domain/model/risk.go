package model

import (
	"strings"
	"time"

	"github.com/google/uuid"
)

type RiskDecision string

const (
	RiskDecisionAllow     RiskDecision = "ALLOW"
	RiskDecisionChallenge RiskDecision = "CHALLENGE"
	RiskDecisionReview    RiskDecision = "REVIEW"
	RiskDecisionBlock     RiskDecision = "BLOCK"
)

type RiskReviewStatus string

const (
	RiskReviewStatusOpen           RiskReviewStatus = "OPEN"
	RiskReviewStatusConfirmedFraud RiskReviewStatus = "CONFIRMED_FRAUD"
	RiskReviewStatusFalsePositive  RiskReviewStatus = "FALSE_POSITIVE"
	RiskReviewStatusEscalated      RiskReviewStatus = "ESCALATED"
)

type RiskEvent struct {
	ID          uuid.UUID  `json:"id"`
	Action      string     `json:"action"`
	ActorUserID *uuid.UUID `json:"actorUserId,omitempty"`
	SubjectType string     `json:"subjectType"`
	SubjectID   *uuid.UUID `json:"subjectId,omitempty"`

	SourceService  string            `json:"sourceService"`
	IdempotencyKey string            `json:"idempotencyKey"`
	AmountMinor    *int64            `json:"amountMinor,omitempty"`
	Currency       string            `json:"currency"`
	SignalHashes   map[string]string `json:"signalHashes"`
	Metadata       map[string]any    `json:"metadata"`
	CreatedAt      time.Time         `json:"createdAt"`
}

type RiskAssessment struct {
	ID          uuid.UUID  `json:"id"`
	EventID     uuid.UUID  `json:"eventId"`
	Action      string     `json:"action"`
	ActorUserID *uuid.UUID `json:"actorUserId,omitempty"`
	SubjectType string     `json:"subjectType"`
	SubjectID   *uuid.UUID `json:"subjectId,omitempty"`

	Decision          RiskDecision     `json:"decision"`
	RiskScore         int              `json:"riskScore"`
	Reasons           []string         `json:"reasons"`
	PolicyVersion     string           `json:"policyVersion"`
	ShadowMode        bool             `json:"shadowMode"`
	ReviewStatus      RiskReviewStatus `json:"reviewStatus"`
	ReviewedByStaffID *uuid.UUID       `json:"reviewedByStaffId,omitempty"`
	ReviewReasonCodes []string         `json:"reviewReasonCodes,omitempty"`
	ReviewComment     string           `json:"reviewComment,omitempty"`
	ReviewedAt        *time.Time       `json:"reviewedAt,omitempty"`
	UpdatedAt         time.Time        `json:"updatedAt"`
	Metadata          map[string]any   `json:"metadata"`
	CreatedAt         time.Time        `json:"createdAt"`
}

func NormalizeCode(value string) string {
	return strings.ToUpper(strings.TrimSpace(value))
}

func NormalizeReviewStatus(value RiskReviewStatus) RiskReviewStatus {
	switch RiskReviewStatus(NormalizeCode(string(value))) {
	case RiskReviewStatusConfirmedFraud:
		return RiskReviewStatusConfirmedFraud
	case RiskReviewStatusFalsePositive:
		return RiskReviewStatusFalsePositive
	case RiskReviewStatusEscalated:
		return RiskReviewStatusEscalated
	default:
		return RiskReviewStatusOpen
	}
}
