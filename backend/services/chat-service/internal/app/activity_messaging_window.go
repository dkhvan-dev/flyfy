package app

import (
	"context"
	"fmt"
	"time"

	"github.com/rs/zerolog/log"

	"github.com/dkhvan-dev/flyfy/backend/services/chat-service/internal/domain/model"
	"github.com/dkhvan-dev/flyfy/backend/services/chat-service/internal/domain/port"
)

func refreshActivityMessagingWindow(
	ctx context.Context,
	repo port.ChatRepository,
	resolver port.ActivityLifecycleResolver,
	conv *model.Conversation,
	force bool,
) (*model.Conversation, error) {
	if conv == nil || conv.ActivityID == nil || resolver == nil {
		return conv, nil
	}
	if !force && conv.MessagingAvailableUntil != nil {
		return conv, nil
	}

	lifecycle, err := resolver.GetActivityLifecycle(ctx, *conv.ActivityID)
	if err != nil {
		if conv.MessagingAvailableUntil != nil {
			log.Warn().
				Err(err).
				Str("conversation_id", conv.ID.String()).
				Str("activity_id", conv.ActivityID.String()).
				Msg("failed to refresh activity chat messaging window, using stored value")
			return conv, nil
		}
		return conv, err
	}

	until, ok := activityLifecycleMessagingAvailableUntil(lifecycle)
	if !ok {
		if conv.MessagingAvailableUntil != nil {
			return conv, nil
		}
		return conv, fmt.Errorf("activity %s has no messaging deadline", conv.ActivityID.String())
	}

	if sameOptionalTime(conv.MessagingAvailableUntil, &until) {
		return conv, nil
	}

	var updated *model.Conversation
	err = repo.WithTx(ctx, func(txRepo port.ChatTxRepository) error {
		locked, err := txRepo.GetConversationByIDForUpdate(ctx, conv.ID)
		if err != nil {
			return err
		}
		if locked == nil {
			return ErrConversationNotFound
		}

		locked.MessagingAvailableUntil = normalizeTimePtr(&until)
		if err = txRepo.UpdateConversation(ctx, locked); err != nil {
			return err
		}
		updated = locked
		return nil
	})
	if err != nil {
		return conv, err
	}
	if updated == nil {
		return conv, nil
	}
	return updated, nil
}

func activityLifecycleMessagingAvailableUntil(
	lifecycle *port.ActivityLifecycle,
) (time.Time, bool) {
	if lifecycle == nil || lifecycle.EndAt.IsZero() {
		return time.Time{}, false
	}

	closedAt := lifecycle.EndAt
	if lifecycle.CancelledAt != nil && !lifecycle.CancelledAt.IsZero() {
		closedAt = lifecycle.CancelledAt.UTC()
	} else if lifecycle.CompletedAt != nil && !lifecycle.CompletedAt.IsZero() {
		closedAt = lifecycle.CompletedAt.UTC()
	}

	return closedAt.UTC().Add(time.Hour), true
}
