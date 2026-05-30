package port

import (
	"context"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/anti-fraud-service/internal/domain/model"
)

type RiskRepository interface {
	CreateEvent(ctx context.Context, event *model.RiskEvent) error
	CountEvents(ctx context.Context, filter RiskEventFilter) (int, error)
	CreateAssessment(ctx context.Context, assessment *model.RiskAssessment) error
	ListAssessments(ctx context.Context, filter RiskAssessmentFilter) ([]*model.RiskAssessment, error)
	UpdateAssessmentReview(ctx context.Context, input RiskAssessmentReviewInput) (*model.RiskAssessment, error)
}

type RiskEventFilter struct {
	Since       time.Time
	Action      string
	ActorUserID *uuid.UUID
	SignalKey   string
	SignalHash  string
}

type RiskAssessmentFilter struct {
	SubjectTypes   []string
	Decisions      []model.RiskDecision
	ReviewStatuses []model.RiskReviewStatus
	EnforcedOnly   bool
	Limit          int
	Offset         int
}

type RiskAssessmentReviewInput struct {
	AssessmentID      uuid.UUID
	Status            model.RiskReviewStatus
	ReviewedByStaffID uuid.UUID
	ReasonCodes       []string
	Comment           string
	ReviewedAt        time.Time
}
