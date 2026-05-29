package model

import (
	"time"

	"github.com/google/uuid"
)

type FraudBlockTarget string

const (
	FraudBlockTargetActivity         FraudBlockTarget = "ACTIVITY"
	FraudBlockTargetExcursion        FraudBlockTarget = "EXCURSION"
	FraudBlockTargetGuideApplication FraudBlockTarget = "GUIDE_APPLICATION"
)

type FraudBlockReviewStatus string

const (
	FraudBlockReviewStatusOpen           FraudBlockReviewStatus = "OPEN"
	FraudBlockReviewStatusConfirmedFraud FraudBlockReviewStatus = "CONFIRMED_FRAUD"
	FraudBlockReviewStatusFalsePositive  FraudBlockReviewStatus = "FALSE_POSITIVE"
	FraudBlockReviewStatusEscalated      FraudBlockReviewStatus = "ESCALATED"
)

type FraudBlock struct {
	ID                uuid.UUID
	EventID           uuid.UUID
	Action            string
	ActorUserID       *uuid.UUID
	SubjectType       string
	SubjectID         *uuid.UUID
	Decision          string
	RiskScore         int
	Reasons           []string
	PolicyVersion     string
	ShadowMode        bool
	ReviewStatus      FraudBlockReviewStatus
	ReviewedByStaffID *uuid.UUID
	ReviewReasonCodes []string
	ReviewComment     string
	ReviewedAt        *time.Time
	UpdatedAt         time.Time
	Metadata          map[string]any
	CreatedAt         time.Time
}

type FraudBlockReviewInput struct {
	AssessmentID      uuid.UUID
	Status            FraudBlockReviewStatus
	ReviewedByStaffID uuid.UUID
	ReasonCodes       []string
	Comment           string
}
