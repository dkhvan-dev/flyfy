package port

import (
	"context"

	"github.com/google/uuid"
)

type FraudDecision string

const (
	FraudDecisionAllow     FraudDecision = "ALLOW"
	FraudDecisionChallenge FraudDecision = "CHALLENGE"
	FraudDecisionReview    FraudDecision = "REVIEW"
	FraudDecisionBlock     FraudDecision = "BLOCK"
)

type FraudAssessmentInput struct {
	Action         string
	ActorUserID    uuid.UUID
	SubjectType    string
	SubjectID      uuid.UUID
	IdempotencyKey string
	AmountMinor    *int64
	Currency       string
	ClientIP       string
	DeviceID       string
	UserAgent      string
	Metadata       map[string]any
}

type FraudAssessmentResult struct {
	Decision   FraudDecision
	RiskScore  int
	Reasons    []string
	ShadowMode bool
}

type FraudEvaluator interface {
	AssessExcursion(ctx context.Context, input FraudAssessmentInput) (*FraudAssessmentResult, error)
}
