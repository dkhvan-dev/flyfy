package app

import (
	"context"
	"fmt"

	"github.com/google/uuid"

	"kz/inflap/backend/services/activity-service/internal/domain/enum"
	"kz/inflap/backend/services/activity-service/internal/domain/model"
)

func (u *ActivityUseCase) GetActivityForViewer(
	ctx context.Context,
	activityID uuid.UUID,
	actorUserID uuid.UUID,
) (*model.Activity, error) {
	item, err := u.GetActivityByID(ctx, activityID)
	if err != nil {
		return nil, err
	}
	if isActivityPubliclyAccessible(item) {
		return item, nil
	}
	if actorUserID == uuid.Nil {
		return nil, ErrActivityNotFound
	}
	if item.HostUserID == actorUserID {
		return item, nil
	}

	participant, err := u.repo.GetParticipantByActivityAndUser(ctx, item.ID, actorUserID)
	if err != nil {
		return nil, fmt.Errorf("get activity viewer participant: %w", err)
	}
	if participant != nil && participant.Status.IsActive() {
		return item, nil
	}

	return nil, ErrActivityNotFound
}

func isActivityPubliclyAccessible(item *model.Activity) bool {
	if item == nil || item.Visibility != enum.ActivityVisibilityPublic {
		return false
	}
	if !item.Status.IsValid() || item.PublishedAt == nil || item.CancelledAt != nil {
		return false
	}
	switch item.Status {
	case enum.ActivityStatusCancelled, enum.ActivityStatusArchived:
		return false
	}
	return isActivityModerationPubliclyVisible(item.ModerationStatus)
}

func isActivityModerationPubliclyVisible(status enum.ActivityModerationStatus) bool {
	switch status {
	case enum.ActivityModerationStatusNotRequired,
		enum.ActivityModerationStatusFlagged,
		enum.ActivityModerationStatusInReview,
		enum.ActivityModerationStatusApproved:
		return true
	default:
		return false
	}
}
