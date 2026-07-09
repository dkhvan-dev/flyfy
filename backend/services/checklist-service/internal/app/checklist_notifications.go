package app

import (
	"context"
	"fmt"
)

const (
	defaultChecklistNotificationScanLimit = 100
	maxChecklistNotificationScanLimit     = 500
)

func (uc *ChecklistUseCase) DispatchDueChecklistNotifications(
	ctx context.Context,
	input DispatchChecklistNotificationsInput,
) (DispatchChecklistNotificationsResult, error) {
	var result DispatchChecklistNotificationsResult
	if uc == nil || uc.repo == nil {
		return result, ErrChecklistPersistenceMissing
	}

	checklists, err := uc.repo.ListTripChecklistInstances(ctx, clampChecklistNotificationLimit(input.Limit))
	if err != nil {
		return result, fmt.Errorf("%w: %v", ErrChecklistPersistenceFailed, err)
	}

	result.Scanned = len(checklists)
	result.Skipped = len(checklists)
	return result, nil
}

func clampChecklistNotificationLimit(limit int) int {
	if limit <= 0 {
		return defaultChecklistNotificationScanLimit
	}
	if limit > maxChecklistNotificationScanLimit {
		return maxChecklistNotificationScanLimit
	}
	return limit
}
