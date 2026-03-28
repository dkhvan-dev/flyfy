package app

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/activity-service/internal/domain/enum"
	"github.com/dkhvan-dev/flyfy/backend/services/activity-service/internal/domain/model"
	"github.com/dkhvan-dev/flyfy/backend/services/activity-service/internal/domain/port"
)

type JoinUseCase struct {
	repo port.ActivityRepository
}

func NewJoinUseCase(repo port.ActivityRepository) *JoinUseCase {
	return &JoinUseCase{repo: repo}
}

type JoinActivityInput struct {
	ActivityID         uuid.UUID
	UserID             uuid.UUID
	VisibilityPassword *string
}

type LeaveActivityInput struct {
	ActivityID uuid.UUID
	UserID     uuid.UUID
	Reason     *string
}

func (u *JoinUseCase) JoinActivity(ctx context.Context, input JoinActivityInput) (*model.ActivityParticipant, error) {
	if input.ActivityID == uuid.Nil {
		return nil, ErrInvalidActivityID
	}
	if input.UserID == uuid.Nil {
		return nil, ErrInvalidParticipantUserID
	}

	var created *model.ActivityParticipant

	err := u.repo.WithTx(ctx, func(txRepo port.ActivityTxRepository) error {
		activity, err := txRepo.GetActivityByIDForUpdate(ctx, input.ActivityID)
		if err != nil {
			return fmt.Errorf("get activity by id for update: %w", err)
		}
		if activity == nil {
			return ErrActivityNotFound
		}

		if activity.Status != enum.ActivityStatusEnrollmentOpen &&
			activity.Status != enum.ActivityStatusPublished &&
			activity.Status != enum.ActivityStatusFull {
			return ErrActivityJoinClosed
		}

		now := time.Now().UTC()
		if !activity.RegistrationDeadline.IsZero() && now.After(activity.RegistrationDeadline) {
			return ErrActivityJoinClosed
		}

		existing, err := txRepo.GetParticipantByActivityAndUserForUpdate(ctx, input.ActivityID, input.UserID)
		if err != nil {
			return fmt.Errorf("get participant by activity and user for update: %w", err)
		}
		if existing != nil && existing.Status.IsActive() {
			return ErrAlreadyJoined
		}

		hasScheduleConflict, err := txRepo.HasActiveOverlappingJoinedActivity(
			ctx,
			input.UserID,
			input.ActivityID,
			activity.StartAt,
			activity.EndAt,
		)
		if err != nil {
			return fmt.Errorf("check overlapping joined activities: %w", err)
		}
		if hasScheduleConflict {
			return ErrParticipantScheduleConflict
		}

		if activity.Visibility == enum.ActivityVisibilityPrivate {
			if err = verifyVisibilityPassword(
				activity.VisibilityPasswordHash,
				input.VisibilityPassword,
			); err != nil {
				return err
			}
		}

		occupied, err := txRepo.CountOccupiedSlotsForUpdate(ctx, input.ActivityID)
		if err != nil {
			return fmt.Errorf("count occupied slots for update: %w", err)
		}

		status := enum.ParticipantStatusRequested
		if activity.JoinMode == enum.ActivityJoinModeAutoApprove {
			status = enum.ParticipantStatusApproved
		}

		if activity.CapacityType == enum.ActivityCapacityTypeLimited && activity.MaxParticipants != nil {
			if occupied >= *activity.MaxParticipants {
				status = enum.ParticipantStatusWaitlisted
			}
		}

		participant, err := model.NewActivityParticipant(model.NewActivityParticipantParams{
			ActivityID: input.ActivityID,
			UserID:     input.UserID,
			Status:     status,
		})
		if err != nil {
			return err
		}

		if status == enum.ParticipantStatusApproved {
			nowCopy := now
			participant.ApprovedAt = &nowCopy
		}
		if status == enum.ParticipantStatusWaitlisted {
			nowCopy := now
			participant.WaitlistedAt = &nowCopy
			activity.Status = enum.ActivityStatusFull
			activity.Revision++
			activity.UpdatedAt = now
		}

		if err = txRepo.CreateParticipant(ctx, participant); err != nil {
			return fmt.Errorf("create participant: %w", err)
		}

		participantEvent, participantEventErr := model.NewParticipantEvent(model.NewParticipantEventParams{
			ActivityID:    activity.ID,
			ParticipantID: participant.ID,
			UserID:        participant.UserID,
			EventType:     string(status),
			ActorUserID:   &input.UserID,
			PayloadJSON:   mustJSON(map[string]any{"status": string(status)}),
		})
		if participantEventErr == nil {
			if err = txRepo.CreateParticipantEvent(ctx, participantEvent); err != nil {
				return fmt.Errorf("create participant event: %w", err)
			}
		}

		if status == enum.ParticipantStatusWaitlisted {
			if err = txRepo.UpdateActivity(ctx, activity); err != nil {
				return fmt.Errorf("update activity full status: %w", err)
			}

			activityEvent, activityEventErr := model.NewActivityEvent(model.NewActivityEventParams{
				ActivityID:  activity.ID,
				EventType:   enum.ActivityEventTypeCapacityChanged,
				ActorUserID: &input.UserID,
				PayloadJSON: mustJSON(map[string]any{
					"status": "FULL",
				}),
			})
			if activityEventErr == nil {
				if err = txRepo.CreateActivityEvent(ctx, activityEvent); err != nil {
					return fmt.Errorf("create activity event: %w", err)
				}
			}
		}

		created = participant
		return nil
	})
	if err != nil {
		return nil, err
	}

	return created, nil
}

func (u *JoinUseCase) LeaveActivity(ctx context.Context, input LeaveActivityInput) (*model.ActivityParticipant, error) {
	if input.ActivityID == uuid.Nil {
		return nil, ErrInvalidActivityID
	}
	if input.UserID == uuid.Nil {
		return nil, ErrInvalidParticipantUserID
	}

	var updated *model.ActivityParticipant

	err := u.repo.WithTx(ctx, func(txRepo port.ActivityTxRepository) error {
		activity, err := txRepo.GetActivityByIDForUpdate(ctx, input.ActivityID)
		if err != nil {
			return fmt.Errorf("get activity by id for update: %w", err)
		}
		if activity == nil {
			return ErrActivityNotFound
		}

		participant, err := txRepo.GetParticipantByActivityAndUserForUpdate(ctx, input.ActivityID, input.UserID)
		if err != nil {
			return fmt.Errorf("get participant by activity and user for update: %w", err)
		}
		if participant == nil {
			return ErrParticipantNotFound
		}
		if participant.Status == enum.ParticipantStatusCancelled {
			return ErrParticipantAlreadyCancelled
		}
		if !participant.Status.IsActive() &&
			participant.Status != enum.ParticipantStatusApproved &&
			participant.Status != enum.ParticipantStatusConfirmed {
			return ErrParticipantStateInvalid
		}

		now := time.Now().UTC()
		if err = participant.SetStatus(enum.ParticipantStatusCancelled, now); err != nil {
			return err
		}
		participant.CancelReason = model.NormalizeOptionalString(input.Reason)
		cancelledBy := input.UserID
		participant.CancelledByUserID = &cancelledBy

		if err = txRepo.UpdateParticipant(ctx, participant); err != nil {
			return fmt.Errorf("update participant: %w", err)
		}

		participantEvent, participantEventErr := model.NewParticipantEvent(model.NewParticipantEventParams{
			ActivityID:    activity.ID,
			ParticipantID: participant.ID,
			UserID:        participant.UserID,
			EventType:     string(enum.ParticipantStatusCancelled),
			ActorUserID:   &input.UserID,
			PayloadJSON: mustJSON(map[string]any{
				"reason": input.Reason,
			}),
		})
		if participantEventErr == nil {
			if err = txRepo.CreateParticipantEvent(ctx, participantEvent); err != nil {
				return fmt.Errorf("create participant cancel event: %w", err)
			}
		}

		if activity.CapacityType == enum.ActivityCapacityTypeLimited && activity.MaxParticipants != nil {
			occupied, countErr := txRepo.CountOccupiedSlotsForUpdate(ctx, activity.ID)
			if countErr == nil && occupied < *activity.MaxParticipants && activity.Status == enum.ActivityStatusFull {
				activity.Status = enum.ActivityStatusEnrollmentOpen
				activity.Revision++
				activity.UpdatedAt = now

				if err = txRepo.UpdateActivity(ctx, activity); err != nil {
					return fmt.Errorf("reopen activity after leave: %w", err)
				}

				actEvent, actEventErr := model.NewActivityEvent(model.NewActivityEventParams{
					ActivityID:  activity.ID,
					EventType:   enum.ActivityEventTypeRegistrationReopened,
					ActorUserID: &input.UserID,
					PayloadJSON: mustJSON(map[string]any{}),
				})
				if actEventErr == nil {
					if err = txRepo.CreateActivityEvent(ctx, actEvent); err != nil {
						return fmt.Errorf("create reopen activity event: %w", err)
					}
				}
			}
		}

		updated = participant
		return nil
	})
	if err != nil {
		return nil, err
	}

	return updated, nil
}
