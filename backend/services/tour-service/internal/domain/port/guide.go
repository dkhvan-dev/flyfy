package port

import (
	"context"

	"github.com/google/uuid"
)

type GuideTourPermission struct {
	GuideProfileID uuid.UUID
	GuideUserID    uuid.UUID
	Allowed        bool
}

type GuideVerifier interface {
	VerifyTourGuide(ctx context.Context, userID uuid.UUID) (GuideTourPermission, error)
}
