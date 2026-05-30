package port

import (
	"context"

	"github.com/google/uuid"

	"kz/inflap/backend/services/file-manager-service/internal/domain/enum"
)

type FraudDecision string

const (
	FraudDecisionAllow     FraudDecision = "ALLOW"
	FraudDecisionChallenge FraudDecision = "CHALLENGE"
	FraudDecisionReview    FraudDecision = "REVIEW"
	FraudDecisionBlock     FraudDecision = "BLOCK"
)

type FraudAssessmentInput struct {
	Action      string
	ActorUserID *uuid.UUID
	FileID      *uuid.UUID
	OwnerType   *enum.OwnerType
	OwnerID     *uuid.UUID
	Purpose     enum.FilePurpose
	ContentType string
	SizeBytes   int64
	ClientIP    string
	DeviceID    string
	UserAgent   string
	Metadata    map[string]any
}

type FraudAssessmentResult struct {
	Decision   FraudDecision
	RiskScore  int
	Reasons    []string
	ShadowMode bool
}

type FraudEvaluator interface {
	AssessFile(ctx context.Context, input FraudAssessmentInput) (*FraudAssessmentResult, error)
}
