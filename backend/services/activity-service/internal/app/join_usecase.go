package app

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/dkhvan-dev/flyfy/backend/services/activity-service/internal/domain/enum"
	"github.com/dkhvan-dev/flyfy/backend/services/activity-service/internal/domain/model"
	"github.com/dkhvan-dev/flyfy/backend/services/activity-service/internal/domain/port"
)

type JoinUseCase struct {
	repo                port.ActivityRepository
	chatGateway         port.ActivityChatGateway
	userProfileResolver port.UserProfileResolver
	payment             port.ActivityPaymentGateway
	fraud               port.FraudEvaluator
}

func NewJoinUseCase(
	repo port.ActivityRepository,
	chatGateway port.ActivityChatGateway,
	userProfileResolver ...port.UserProfileResolver,
) *JoinUseCase {
	var resolver port.UserProfileResolver
	if len(userProfileResolver) > 0 {
		resolver = userProfileResolver[0]
	}
	return &JoinUseCase{
		repo:                repo,
		chatGateway:         chatGateway,
		userProfileResolver: resolver,
	}
}

func (u *JoinUseCase) SetPaymentGateway(paymentGateway port.ActivityPaymentGateway) {
	u.payment = paymentGateway
}

type JoinActivityInput struct {
	ActivityID         uuid.UUID
	UserID             uuid.UUID
	VisibilityPassword *string
	IdempotencyKey     *string
}

type InviteFriendsInput struct {
	ActivityID     uuid.UUID
	ActorUserID    uuid.UUID
	InviteeUserIDs []uuid.UUID
}

type InviteFriendsResult struct {
	Invited        []*model.ActivityParticipant
	SkippedUserIDs []uuid.UUID
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

	var err error
	var fraudAssessment *port.FraudAssessmentResult
	fraudAssessmentUnavailable := false
	if u.fraud != nil {
		activityForFraud, err := u.repo.GetActivityByID(ctx, input.ActivityID)
		if err != nil {
			return nil, fmt.Errorf("get activity for fraud assessment: %w", err)
		}
		if activityForFraud == nil {
			return nil, ErrActivityNotFound
		}
		idempotencyKey := ""
		if input.IdempotencyKey != nil {
			idempotencyKey = *input.IdempotencyKey
		}
		fraudAssessment, err = u.assessActivityFraud(ctx, activityParticipantFraudInput(
			fraudActionActivityJoin,
			input.UserID,
			input.ActivityID,
			activityForFraud,
			idempotencyKey,
			map[string]any{
				"visibility": string(activityForFraud.Visibility),
				"status":     string(activityForFraud.Status),
			},
		))
		if err != nil {
			fraudAssessmentUnavailable = true
			log.Warn().
				Err(err).
				Str("activity_id", input.ActivityID.String()).
				Str("user_id", input.UserID.String()).
				Msg("activity join fraud assessment unavailable; allowing join")
		} else if err = rejectBlockedActivityFraudDecision(fraudAssessment); err != nil {
			return nil, err
		}
	}

	var created *model.ActivityParticipant
	var activityForPostCommit *model.Activity
	requiresPaymentAuthorization := false
	var chatInput *port.EnsureActivityParticipantInput

	err = u.repo.WithTx(ctx, func(txRepo port.ActivityTxRepository) error {
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

		status := enum.ParticipantStatusApproved
		if status == enum.ParticipantStatusApproved && isPaidActivity(activity) {
			if err = ensurePaymentGateway(u.payment); err != nil {
				return err
			}
			status = enum.ParticipantStatusPendingPayment
			requiresPaymentAuthorization = true
		}

		if activity.CapacityType == enum.ActivityCapacityTypeLimited && activity.MaxParticipants != nil {
			if occupied >= *activity.MaxParticipants {
				status = enum.ParticipantStatusWaitlisted
			}
		}

		participant := existing
		acceptedInvitation := participant != nil && participant.Status == enum.ParticipantStatusInvited
		if acceptedInvitation {
			if err = participant.SetStatus(status, now); err != nil {
				return err
			}
			if err = txRepo.UpdateParticipant(ctx, participant); err != nil {
				return fmt.Errorf("update invited participant: %w", err)
			}
		} else {
			participant, err = model.NewActivityParticipant(model.NewActivityParticipantParams{
				ActivityID: input.ActivityID,
				UserID:     input.UserID,
				Status:     status,
			})
			if err != nil {
				return err
			}

			if status == enum.ParticipantStatusApproved || status == enum.ParticipantStatusConfirmed {
				nowCopy := now
				participant.ApprovedAt = &nowCopy
			}
			if status == enum.ParticipantStatusWaitlisted {
				nowCopy := now
				participant.WaitlistedAt = &nowCopy
			}

			if err = txRepo.CreateParticipant(ctx, participant); err != nil {
				return fmt.Errorf("create participant: %w", err)
			}
		}

		if status == enum.ParticipantStatusWaitlisted {
			activity.Status = enum.ActivityStatusFull
			activity.Revision++
			activity.UpdatedAt = now
		}

		participantEventPayload := addFraudAssessmentPayload(
			map[string]any{
				"status":             string(status),
				"paymentMode":        paymentModeForParticipant(activity, status),
				"acceptedInvitation": acceptedInvitation,
			},
			fraudAssessment,
			fraudAssessmentUnavailable,
		)
		participantEvent, participantEventErr := model.NewParticipantEvent(model.NewParticipantEventParams{
			ActivityID:    activity.ID,
			ParticipantID: participant.ID,
			UserID:        participant.UserID,
			EventType:     string(status),
			ActorUserID:   &input.UserID,
			PayloadJSON:   mustJSON(participantEventPayload),
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
		activityForPostCommit = activity
		return nil
	})
	if err != nil {
		return nil, err
	}

	if requiresPaymentAuthorization {
		authorized, authErr := u.authorizeParticipantPayment(ctx, activityForPostCommit, created, input.UserID)
		if authErr != nil {
			return nil, authErr
		}
		created = authorized
	}

	if created != nil &&
		created.Status.IsActive() &&
		created.Status != enum.ParticipantStatusPendingPayment &&
		activityForPostCommit != nil {
		messagingAvailableUntil := activityChatMessagingAvailableUntil(activityForPostCommit)
		chatInput = &port.EnsureActivityParticipantInput{
			ActivityID:              activityForPostCommit.ID,
			ActivityTitle:           activityForPostCommit.Title,
			MessagingAvailableUntil: &messagingAvailableUntil,
			HostUserID:              activityForPostCommit.HostUserID,
			UserID:                  created.UserID,
		}
	}

	if u.chatGateway != nil && chatInput != nil {
		chatCtx, cancel := context.WithTimeout(context.WithoutCancel(ctx), 5*time.Second)
		defer cancel()

		if strings.TrimSpace(chatInput.ActivityAvatarFileID) == "" {
			media, mediaErr := u.repo.ListMediaByActivityID(chatCtx, chatInput.ActivityID)
			if mediaErr != nil {
				log.Warn().
					Err(mediaErr).
					Str("activity_id", chatInput.ActivityID.String()).
					Msg("failed to resolve activity cover for chat")
			} else {
				chatInput.ActivityAvatarFileID = activityCoverFileID(media)
			}
		}

		if strings.TrimSpace(chatInput.DisplayName) == "" && u.userProfileResolver != nil {
			displayName, displayNameErr := u.userProfileResolver.DisplayNameForUserID(chatCtx, chatInput.UserID)
			if displayNameErr != nil {
				log.Warn().
					Err(displayNameErr).
					Str("user_id", chatInput.UserID.String()).
					Msg("failed to resolve activity participant display name for chat")
			} else {
				chatInput.DisplayName = strings.TrimSpace(displayName)
			}
		}

		if chatErr := u.chatGateway.EnsureActivityParticipant(chatCtx, *chatInput); chatErr != nil {
			log.Error().
				Err(chatErr).
				Str("activity_id", chatInput.ActivityID.String()).
				Str("user_id", chatInput.UserID.String()).
				Msg("failed to add activity participant to chat")
		}
	}

	return created, nil
}

func (u *JoinUseCase) InviteFriends(ctx context.Context, input InviteFriendsInput) (*InviteFriendsResult, error) {
	if input.ActivityID == uuid.Nil {
		return nil, ErrInvalidActivityID
	}
	if input.ActorUserID == uuid.Nil {
		return nil, ErrInvalidActorUserID
	}

	inviteeUserIDs := uniqueInviteeUserIDs(input.InviteeUserIDs, input.ActorUserID)
	if len(inviteeUserIDs) == 0 {
		return nil, ErrInvalidParticipantUserID
	}

	result := &InviteFriendsResult{
		Invited:        make([]*model.ActivityParticipant, 0, len(inviteeUserIDs)),
		SkippedUserIDs: make([]uuid.UUID, 0),
	}

	activity, err := u.repo.GetActivityByID(ctx, input.ActivityID)
	if err != nil {
		return nil, fmt.Errorf("get activity by id for invitation: %w", err)
	}
	if err = validateInvitationActivity(activity, input.ActorUserID, time.Now().UTC()); err != nil {
		return nil, err
	}

	if err = u.enforceActivityFraud(ctx, activityParticipantFraudInput(
		fraudActionActivityInvite,
		input.ActorUserID,
		input.ActivityID,
		activity,
		"",
		map[string]any{
			"inviteeCount": len(inviteeUserIDs),
		},
	)); err != nil {
		return nil, err
	}

	friendInviteeUserIDs, skippedNonFriendUserIDs, err := u.filterFriendInviteeUserIDs(
		ctx,
		input.ActorUserID,
		inviteeUserIDs,
	)
	if err != nil {
		return nil, err
	}
	result.SkippedUserIDs = append(result.SkippedUserIDs, skippedNonFriendUserIDs...)
	if len(friendInviteeUserIDs) == 0 {
		return result, nil
	}
	inviteeUserIDs = friendInviteeUserIDs

	err = u.repo.WithTx(ctx, func(txRepo port.ActivityTxRepository) error {
		activity, err := txRepo.GetActivityByIDForUpdate(ctx, input.ActivityID)
		if err != nil {
			return fmt.Errorf("get activity by id for invitation: %w", err)
		}
		now := time.Now().UTC()
		if err = validateInvitationActivity(activity, input.ActorUserID, now); err != nil {
			return err
		}

		if activity.Visibility == enum.ActivityVisibilityPrivate && activity.HostUserID != input.ActorUserID {
			actorParticipant, actorErr := txRepo.GetParticipantByActivityAndUserForUpdate(ctx, input.ActivityID, input.ActorUserID)
			if actorErr != nil {
				return fmt.Errorf("get invitation actor participant: %w", actorErr)
			}
			if actorParticipant == nil || !actorParticipant.Status.IsActive() {
				return ErrActivityJoinClosed
			}
		}

		for _, inviteeUserID := range inviteeUserIDs {
			existing, participantErr := txRepo.GetParticipantByActivityAndUserForUpdate(
				ctx,
				input.ActivityID,
				inviteeUserID,
			)
			if participantErr != nil {
				return fmt.Errorf("get invited participant by activity and user: %w", participantErr)
			}
			if existing != nil && (existing.Status.IsActive() || existing.Status == enum.ParticipantStatusInvited) {
				result.SkippedUserIDs = append(result.SkippedUserIDs, inviteeUserID)
				continue
			}

			participant, createErr := model.NewActivityParticipant(model.NewActivityParticipantParams{
				ActivityID: input.ActivityID,
				UserID:     inviteeUserID,
				Status:     enum.ParticipantStatusInvited,
			})
			if createErr != nil {
				return createErr
			}
			if err = txRepo.CreateParticipant(ctx, participant); err != nil {
				return fmt.Errorf("create invited participant: %w", err)
			}

			participantEvent, participantEventErr := model.NewParticipantEvent(model.NewParticipantEventParams{
				ActivityID:    activity.ID,
				ParticipantID: participant.ID,
				UserID:        participant.UserID,
				EventType:     string(enum.ParticipantStatusInvited),
				ActorUserID:   &input.ActorUserID,
				PayloadJSON: mustJSON(map[string]any{
					"status":    string(enum.ParticipantStatusInvited),
					"invitedBy": input.ActorUserID.String(),
				}),
			})
			if participantEventErr == nil {
				if err = txRepo.CreateParticipantEvent(ctx, participantEvent); err != nil {
					return fmt.Errorf("create participant invitation event: %w", err)
				}
			}

			result.Invited = append(result.Invited, participant)
		}

		return nil
	})
	if err != nil {
		return nil, err
	}

	return result, nil
}

func (u *JoinUseCase) filterFriendInviteeUserIDs(
	ctx context.Context,
	actorUserID uuid.UUID,
	inviteeUserIDs []uuid.UUID,
) ([]uuid.UUID, []uuid.UUID, error) {
	if u.userProfileResolver == nil {
		return nil, nil, ErrFriendshipVerificationUnavailable
	}

	friendUserIDs, err := u.userProfileResolver.FilterFriendUserIDs(ctx, actorUserID, inviteeUserIDs)
	if err != nil {
		return nil, nil, fmt.Errorf("%w: %v", ErrFriendshipVerificationUnavailable, err)
	}

	friendSet := make(map[uuid.UUID]struct{}, len(friendUserIDs))
	for _, userID := range friendUserIDs {
		if userID == uuid.Nil || userID == actorUserID {
			continue
		}
		friendSet[userID] = struct{}{}
	}

	allowed := make([]uuid.UUID, 0, len(inviteeUserIDs))
	skipped := make([]uuid.UUID, 0)
	for _, userID := range inviteeUserIDs {
		if _, ok := friendSet[userID]; ok {
			allowed = append(allowed, userID)
			continue
		}
		skipped = append(skipped, userID)
	}

	return allowed, skipped, nil
}

func uniqueInviteeUserIDs(items []uuid.UUID, actorUserID uuid.UUID) []uuid.UUID {
	seen := make(map[uuid.UUID]struct{}, len(items))
	result := make([]uuid.UUID, 0, len(items))
	for _, item := range items {
		if item == uuid.Nil || item == actorUserID {
			continue
		}
		if _, ok := seen[item]; ok {
			continue
		}
		seen[item] = struct{}{}
		result = append(result, item)
	}
	return result
}

func validateInvitationActivity(activity *model.Activity, actorUserID uuid.UUID, now time.Time) error {
	if activity == nil {
		return ErrActivityNotFound
	}
	if !canInviteToActivity(activity) {
		return ErrActivityJoinClosed
	}
	if activity.HostUserID != actorUserID && !activity.AllowsParticipantInvites {
		return ErrActivityInvitationForbidden
	}
	if !activity.RegistrationDeadline.IsZero() && now.After(activity.RegistrationDeadline) {
		return ErrActivityJoinClosed
	}
	return nil
}

func canInviteToActivity(activity *model.Activity) bool {
	if activity == nil {
		return false
	}
	switch activity.Status {
	case enum.ActivityStatusPublished,
		enum.ActivityStatusEnrollmentOpen,
		enum.ActivityStatusFull:
		return true
	default:
		return false
	}
}

func activityCoverFileID(media []*model.ActivityMedia) string {
	if len(media) == 0 {
		return ""
	}

	fallback := media[0]
	for _, item := range media {
		if item == nil {
			continue
		}
		if item.IsCover {
			return item.FileID.String()
		}
		if fallback == nil {
			fallback = item
		}
	}
	if fallback == nil {
		return ""
	}
	return fallback.FileID.String()
}

func (u *JoinUseCase) LeaveActivity(ctx context.Context, input LeaveActivityInput) (*model.ActivityParticipant, error) {
	if input.ActivityID == uuid.Nil {
		return nil, ErrInvalidActivityID
	}
	if input.UserID == uuid.Nil {
		return nil, ErrInvalidParticipantUserID
	}

	var err error
	if u.fraud != nil {
		activityForFraud, err := u.repo.GetActivityByID(ctx, input.ActivityID)
		if err != nil {
			return nil, fmt.Errorf("get activity for leave fraud assessment: %w", err)
		}
		if activityForFraud == nil {
			return nil, ErrActivityNotFound
		}
		if err = u.enforceActivityFraud(ctx, activityParticipantFraudInput(
			fraudActionActivityLeave,
			input.UserID,
			input.ActivityID,
			activityForFraud,
			"",
			map[string]any{
				"reason": input.Reason,
			},
		)); err != nil {
			return nil, err
		}
	}

	var updated *model.ActivityParticipant
	var paymentTask *participantPaymentTask

	err = u.repo.WithTx(ctx, func(txRepo port.ActivityTxRepository) error {
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
		if isParticipantCancellationTerminal(participant.Status) {
			return ErrParticipantAlreadyCancelled
		}
		if !participant.Status.IsActive() &&
			participant.Status != enum.ParticipantStatusApproved &&
			participant.Status != enum.ParticipantStatusConfirmed {
			return ErrParticipantStateInvalid
		}

		now := time.Now().UTC()
		if !now.Before(activity.StartAt) || activity.Status == enum.ActivityStatusStarted {
			return ErrActivityLeaveClosed
		}

		lateCancellation := isLateParticipantCancellation(activity, now)
		nextStatus := enum.ParticipantStatusCancelled
		cancelPolicy := "free_cancellation_before_registration_deadline"
		if lateCancellation {
			nextStatus = enum.ParticipantStatusLateCancelled
			cancelPolicy = "late_cancellation_after_registration_deadline"
		}

		if err = participant.SetStatus(nextStatus, now); err != nil {
			return err
		}
		participant.CancelReason = model.NormalizeOptionalString(input.Reason)
		if participant.CancelReason == nil && lateCancellation {
			defaultReason := ParticipantCancelReasonLateCancellation
			participant.CancelReason = model.NormalizeOptionalString(&defaultReason)
		}
		cancelledBy := input.UserID
		participant.CancelledByUserID = &cancelledBy

		if err = txRepo.UpdateParticipant(ctx, participant); err != nil {
			return fmt.Errorf("update participant: %w", err)
		}

		participantEvent, participantEventErr := model.NewParticipantEvent(model.NewParticipantEventParams{
			ActivityID:    activity.ID,
			ParticipantID: participant.ID,
			UserID:        participant.UserID,
			EventType:     string(nextStatus),
			ActorUserID:   &input.UserID,
			PayloadJSON: mustJSON(map[string]any{
				"reason":               participant.CancelReason,
				"policy":               cancelPolicy,
				"registrationDeadline": activity.RegistrationDeadline.Format(time.RFC3339),
				"lateCancellation":     lateCancellation,
			}),
		})
		if participantEventErr == nil {
			if err = txRepo.CreateParticipantEvent(ctx, participantEvent); err != nil {
				return fmt.Errorf("create participant cancel event: %w", err)
			}
		}

		if isPaidActivity(activity) && participant.PaymentTransactionID != nil {
			if participant.PaidAt != nil {
				if lateCancellation {
					paymentEvent, paymentEventErr := model.NewParticipantEvent(model.NewParticipantEventParams{
						ActivityID:    activity.ID,
						ParticipantID: participant.ID,
						UserID:        participant.UserID,
						EventType:     ParticipantEventTypePaymentRefundDenied,
						ActorUserID:   &input.UserID,
						PayloadJSON: mustJSON(map[string]any{
							"activityId":                 activity.ID.String(),
							"participantId":              participant.ID.String(),
							"parentPaymentTransactionId": participant.PaymentTransactionID.String(),
							"policy":                     "no_refund_after_registration_deadline",
							"idempotencyKey": fmt.Sprintf(
								"activity_late_leave_no_refund:%s:participant:%s",
								activity.ID,
								participant.ID,
							),
						}),
					})
					if paymentEventErr == nil {
						if err = txRepo.CreateParticipantEvent(ctx, paymentEvent); err != nil {
							return fmt.Errorf("create refund denied event: %w", err)
						}
					}
				} else {
					paymentTask = &participantPaymentTask{
						Action:                     participantPaymentActionRefund,
						ActivityID:                 activity.ID,
						ParticipantID:              participant.ID,
						UserID:                     participant.UserID,
						ParentPaymentTransactionID: *participant.PaymentTransactionID,
						ActorUserID:                &input.UserID,
						IdempotencyKey: fmt.Sprintf(
							"activity_leave_refund:%s:participant:%s",
							activity.ID,
							participant.ID,
						),
						EventType:      ParticipantEventTypePaymentRefundSucceeded,
						Policy:         "full_refund_before_registration_deadline",
						Reason:         cancelPolicy,
						ErrorOnFailure: ErrPaymentRefundFailed,
					}
				}
			} else {
				paymentTask = &participantPaymentTask{
					Action:                     participantPaymentActionVoid,
					ActivityID:                 activity.ID,
					ParticipantID:              participant.ID,
					UserID:                     participant.UserID,
					ParentPaymentTransactionID: *participant.PaymentTransactionID,
					ActorUserID:                &input.UserID,
					IdempotencyKey: fmt.Sprintf(
						"activity_leave_auth_void:%s:participant:%s",
						activity.ID,
						participant.ID,
					),
					EventType:      ParticipantEventTypePaymentAuthorizationVoided,
					Policy:         "authorization_voided_before_capture",
					Reason:         cancelPolicy,
					ErrorOnFailure: ErrPaymentVoidFailed,
				}
			}
		}

		if !lateCancellation && activity.CapacityType == enum.ActivityCapacityTypeLimited && activity.MaxParticipants != nil {
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
	if paymentTask != nil {
		if err = executeParticipantPaymentTask(ctx, u.repo, u.payment, *paymentTask); err != nil {
			return nil, err
		}
	}

	return updated, nil
}
