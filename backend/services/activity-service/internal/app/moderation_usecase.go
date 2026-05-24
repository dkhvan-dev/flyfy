package app

import (
	"context"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/activity-service/internal/domain/model"
)

type ModerationUseCase struct {
	activityUseCase *ActivityUseCase
}

func NewModerationUseCase(activityUseCase *ActivityUseCase) *ModerationUseCase {
	return &ModerationUseCase{
		activityUseCase: activityUseCase,
	}
}

func (u *ModerationUseCase) ApproveActivity(
	ctx context.Context,
	activityID uuid.UUID,
	moderatorUserID uuid.UUID,
) (*model.Activity, error) {
	return u.activityUseCase.ApproveModeration(ctx, activityID, moderatorUserID)
}

func (u *ModerationUseCase) RejectActivity(
	ctx context.Context,
	activityID uuid.UUID,
	moderatorUserID uuid.UUID,
	publicComment string,
) (*model.Activity, error) {
	return u.activityUseCase.RejectModeration(ctx, activityID, moderatorUserID, publicComment)
}
