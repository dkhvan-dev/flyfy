package app

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/activity-service/internal/domain/enum"
	"kz/inflap/backend/services/activity-service/internal/domain/model"
	"kz/inflap/backend/services/activity-service/internal/domain/port"
)

func (u *JoinUseCase) authorizeParticipantPayment(
	ctx context.Context,
	activity *model.Activity,
	participant *model.ActivityParticipant,
	actorUserID uuid.UUID,
) (*model.ActivityParticipant, error) {
	if err := ensurePaymentGateway(u.payment); err != nil {
		return nil, err
	}
	if activity == nil || participant == nil {
		return nil, ErrParticipantNotFound
	}

	amountMinor, err := activityPaymentAmountMinor(activity)
	if err != nil {
		return nil, err
	}

	idempotencyKey := fmt.Sprintf(
		"activity_join_authorize:%s:participant:%s",
		activity.ID,
		participant.ID,
	)
	tx, err := u.payment.Authorize(ctx, port.PaymentCreateInput{
		IdempotencyKey: idempotencyKey,
		SubjectType:    activityPaymentSubjectType,
		SubjectID:      participant.ID,
		Purpose:        activityPaymentPurposeJoin,
		PayerUserID:    participant.UserID,
		AmountMinor:    amountMinor,
		Currency:       activityCurrency(activity),
		Description:    paymentDescription(activity, participant, "Authorization"),
		Metadata:       paymentMetadata(activity, participant, "authorize_on_join"),
	})
	if err != nil {
		return nil, fmt.Errorf("%w: %v", ErrPaymentAuthorizationFailed, err)
	}
	if !paymentSucceeded(tx) && !paymentPending(tx) {
		return nil, wrapPaymentStatusError(ErrPaymentAuthorizationFailed, tx)
	}

	var updated *model.ActivityParticipant
	err = u.repo.WithTx(ctx, func(txRepo port.ActivityTxRepository) error {
		current, err := txRepo.GetParticipantByActivityAndUserForUpdate(ctx, participant.ActivityID, participant.UserID)
		if err != nil {
			return fmt.Errorf("get participant after payment authorization: %w", err)
		}
		if current == nil {
			return ErrParticipantNotFound
		}
		if current.Status != enum.ParticipantStatusPendingPayment {
			updated = current
			return nil
		}

		now := time.Now().UTC()
		current.PaymentTransactionID = &tx.ID
		if paymentSucceeded(tx) {
			if err = current.SetStatus(enum.ParticipantStatusConfirmed, now); err != nil {
				return err
			}
			current.PaidAt = nil
			current.PaymentDueAt = nil
		}

		if err = txRepo.UpdateParticipant(ctx, current); err != nil {
			return fmt.Errorf("update participant payment authorization: %w", err)
		}

		eventType := ParticipantEventTypePaymentAuthorizationSucceeded
		payloadStatus := tx.Status
		participantEvent, participantEventErr := model.NewParticipantEvent(model.NewParticipantEventParams{
			ActivityID:    current.ActivityID,
			ParticipantID: current.ID,
			UserID:        current.UserID,
			EventType:     eventType,
			ActorUserID:   &actorUserID,
			PayloadJSON: mustJSON(map[string]any{
				"activityId":           activity.ID.String(),
				"participantId":        current.ID.String(),
				"paymentTransactionId": tx.ID.String(),
				"paymentStatus":        payloadStatus,
				"priceType":            string(activity.PriceType),
				"amountMinor":          amountMinor,
				"currency":             activityCurrency(activity),
				"policy":               "authorize_on_join",
				"idempotencyKey":       idempotencyKey,
			}),
		})
		if participantEventErr == nil {
			if err = txRepo.CreateParticipantEvent(ctx, participantEvent); err != nil {
				return fmt.Errorf("create payment authorization event: %w", err)
			}
		}

		if paymentSucceeded(tx) {
			if err = markActivityFullIfCapacityReachedAfterPayment(
				ctx,
				txRepo,
				current.ActivityID,
				actorUserID,
				now,
			); err != nil {
				return err
			}
		}

		updated = current
		return nil
	})
	if err != nil {
		return nil, err
	}

	return updated, nil
}

func markActivityFullIfCapacityReachedAfterPayment(
	ctx context.Context,
	txRepo port.ActivityTxRepository,
	activityID uuid.UUID,
	actorUserID uuid.UUID,
	now time.Time,
) error {
	activity, err := txRepo.GetActivityByIDForUpdate(ctx, activityID)
	if err != nil {
		return fmt.Errorf("get activity after payment authorization: %w", err)
	}
	if activity == nil {
		return ErrActivityNotFound
	}
	if activity.CapacityType != enum.ActivityCapacityTypeLimited ||
		activity.MaxParticipants == nil ||
		activity.Status == enum.ActivityStatusFull {
		return nil
	}
	switch activity.Status {
	case enum.ActivityStatusEnrollmentOpen, enum.ActivityStatusPublished:
	default:
		return nil
	}

	occupied, err := txRepo.CountOccupiedSlotsForUpdate(ctx, activityID)
	if err != nil {
		return fmt.Errorf("count occupied slots after payment authorization: %w", err)
	}
	if occupied < *activity.MaxParticipants {
		return nil
	}

	activity.Status = enum.ActivityStatusFull
	activity.Revision++
	activity.UpdatedAt = now
	if err = txRepo.UpdateActivity(ctx, activity); err != nil {
		return fmt.Errorf("update activity full status after payment authorization: %w", err)
	}

	activityEvent, activityEventErr := model.NewActivityEvent(model.NewActivityEventParams{
		ActivityID:  activity.ID,
		EventType:   enum.ActivityEventTypeCapacityChanged,
		ActorUserID: &actorUserID,
		PayloadJSON: mustJSON(map[string]any{
			"status": "FULL",
		}),
	})
	if activityEventErr == nil {
		if err = txRepo.CreateActivityEvent(ctx, activityEvent); err != nil {
			return fmt.Errorf("create payment capacity changed event: %w", err)
		}
	}

	return nil
}
