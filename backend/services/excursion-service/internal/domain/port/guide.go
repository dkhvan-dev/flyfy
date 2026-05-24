package port

import (
	"context"

	"github.com/google/uuid"
)

type GuideExcursionPermission struct {
	GuideProfileID  uuid.UUID
	GuideUserID     uuid.UUID
	Allowed         bool
	RatingAvg       float64
	ReviewsCount    int
	ExperienceYears int
	DisplayName     string
	Nickname        string
	FirstName       string
	LastName        string
	GuideSearchText string
}

type GuideVerifier interface {
	VerifyExcursionGuide(ctx context.Context, userID uuid.UUID) (GuideExcursionPermission, error)
}
