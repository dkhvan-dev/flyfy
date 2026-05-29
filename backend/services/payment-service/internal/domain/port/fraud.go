package port

import (
	"context"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/payment-service/internal/domain/enum"
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
	TransactionID  uuid.UUID
	IdempotencyKey string
	ActorUserID    uuid.UUID
	SubjectType    string
	SubjectID      uuid.UUID
	Purpose        string
	OperationType  enum.PaymentOperationType
	AmountMinor    int64
	Currency       string
	Metadata       []byte
}

type FraudAssessmentResult struct {
	Decision   FraudDecision
	RiskScore  int
	Reasons    []string
	ShadowMode bool
}

type FraudDecisionPort interface {
	AssessPayment(ctx context.Context, input FraudAssessmentInput) (*FraudAssessmentResult, error)
}
