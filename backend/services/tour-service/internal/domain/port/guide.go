package port

import (
	"context"

	"github.com/google/uuid"
)

type GuideTourPermission struct {
	GuideProfileID  uuid.UUID
	GuideUserID     uuid.UUID
	Allowed         bool
	RatingAvg       float64
	ReviewsCount    int
	ExperienceYears int
	DisplayName     string
	GuideSearchText string
}

type GuideVerifier interface {
	VerifyTourGuide(ctx context.Context, userID uuid.UUID) (GuideTourPermission, error)
}
