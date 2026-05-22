package port

import (
	"context"

	"github.com/google/uuid"
)

type UserProfileResolver interface {
	DisplayNameForUserID(ctx context.Context, userID uuid.UUID) (string, error)
	FilterFriendUserIDs(ctx context.Context, userID uuid.UUID, candidateUserIDs []uuid.UUID) ([]uuid.UUID, error)
}
