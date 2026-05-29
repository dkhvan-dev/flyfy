package port

import (
	"context"
	"time"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/anti-fraud-service/internal/domain/model"
)

type RiskRepository interface {
	CreateEvent(ctx context.Context, event *model.RiskEvent) error
	CountEvents(ctx context.Context, filter RiskEventFilter) (int, error)
	CreateAssessment(ctx context.Context, assessment *model.RiskAssessment) error
}

type RiskEventFilter struct {
	Since       time.Time
	Action      string
	ActorUserID *uuid.UUID
	SignalKey   string
	SignalHash  string
}
