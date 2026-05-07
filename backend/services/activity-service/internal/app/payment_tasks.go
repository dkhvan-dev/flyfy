package app

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/activity-service/internal/domain/model"
	"github.com/dkhvan-dev/flyfy/backend/services/activity-service/internal/domain/port"
)

type participantPaymentAction string

const (
	participantPaymentActionCapture participantPaymentAction = "capture"
	participantPaymentActionRefund  participantPaymentAction = "refund"
	participantPaymentActionVoid    participantPaymentAction = "void"
)

type participantPaymentTask struct {
	Action                     participantPaymentAction
	ActivityID                 uuid.UUID
	ParticipantID              uuid.UUID
	UserID                     uuid.UUID
	ParentPaymentTransactionID uuid.UUID
	ActorUserID                *uuid.UUID
	IdempotencyKey             string
	EventType                  string
	Policy                     string
	Reason                     string
	Trigger                    string
	AmountMinor                *int64
	MarkPaid                   bool
	ErrorOnFailure             error
}

func executeParticipantPaymentTask(
	ctx context.Context,
	repo port.ActivityRepository,
	gateway port.ActivityPaymentGateway,
	task participantPaymentTask,
) error {
	if err := ensurePaymentGateway(gateway); err != nil {
		return err
	}
	if task.ActivityID == uuid.Nil || task.ParticipantID == uuid.Nil || task.UserID == uuid.Nil ||
		task.ParentPaymentTransactionID == uuid.Nil {
		return ErrPaymentGatewayUnavailable
	}

	input := port.PaymentChildInput{
		ParentTransactionID: task.ParentPaymentTransactionID,
		IdempotencyKey:      task.IdempotencyKey,
		AmountMinor:         task.AmountMinor,
		Metadata: map[string]any{
			"activityId":                 task.ActivityID.String(),
			"participantId":              task.ParticipantID.String(),
			"participantUserId":          task.UserID.String(),
			"parentPaymentTransactionId": task.ParentPaymentTransactionID.String(),
			"policy":                     task.Policy,
			"reason":                     task.Reason,
			"trigger":                    task.Trigger,
		},
	}

	var tx *port.PaymentTransaction
	var err error
	switch task.Action {
	case participantPaymentActionCapture:
		tx, err = gateway.Capture(ctx, input)
	case participantPaymentActionRefund:
		tx, err = gateway.Refund(ctx, input)
	case participantPaymentActionVoid:
		tx, err = gateway.Void(ctx, input)
	default:
		return ErrPaymentGatewayUnavailable
	}
	if err != nil {
		return fmt.Errorf("%w: %v", task.ErrorOnFailure, err)
	}
	if !paymentSucceeded(tx) {
		return wrapPaymentStatusError(task.ErrorOnFailure, tx)
	}

	return repo.WithTx(ctx, func(txRepo port.ActivityTxRepository) error {
		participant, err := txRepo.GetParticipantByActivityAndUserForUpdate(ctx, task.ActivityID, task.UserID)
		if err != nil {
			return fmt.Errorf("get participant for payment event: %w", err)
		}
		if participant == nil || participant.ID != task.ParticipantID {
			return ErrParticipantNotFound
		}

		now := time.Now().UTC()
		if task.MarkPaid {
			participant.PaymentTransactionID = &tx.ID
			participant.PaidAt = &now
			participant.UpdatedAt = now
			if err = txRepo.UpdateParticipant(ctx, participant); err != nil {
				return fmt.Errorf("mark participant paid: %w", err)
			}
		}

		event, eventErr := model.NewParticipantEvent(model.NewParticipantEventParams{
			ActivityID:    task.ActivityID,
			ParticipantID: task.ParticipantID,
			UserID:        task.UserID,
			EventType:     task.EventType,
			ActorUserID:   task.ActorUserID,
			PayloadJSON: mustJSON(map[string]any{
				"paymentTransactionId":       tx.ID.String(),
				"parentPaymentTransactionId": task.ParentPaymentTransactionID.String(),
				"paymentStatus":              tx.Status,
				"policy":                     task.Policy,
				"reason":                     task.Reason,
				"trigger":                    task.Trigger,
				"idempotencyKey":             task.IdempotencyKey,
			}),
		})
		if eventErr == nil {
			if err = txRepo.CreateParticipantEvent(ctx, event); err != nil {
				return fmt.Errorf("create participant payment event: %w", err)
			}
		}

		return nil
	})
}
