package app

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/activity-service/internal/domain/enum"
	"github.com/dkhvan-dev/flyfy/backend/services/activity-service/internal/domain/model"
	"github.com/dkhvan-dev/flyfy/backend/services/activity-service/internal/domain/port"
)

const (
	AttendanceSyncStatusSynced        = "SYNCED"
	AttendanceSyncStatusAlreadySynced = "ALREADY_SYNCED"
	AttendanceSyncStatusRejected      = "REJECTED"
	AttendanceSyncStatusRetryable     = "RETRYABLE"
)

type AttendanceUseCase struct {
	repo          port.ActivityRepository
	qrSigningKey  []byte
	qrTTL         time.Duration
	offlineWindow time.Duration
	fraud         port.FraudEvaluator
}

func NewAttendanceUseCase(
	repo port.ActivityRepository,
	qrSigningSecret string,
	qrTTL time.Duration,
	offlineWindow time.Duration,
) *AttendanceUseCase {
	if qrTTL <= 0 {
		qrTTL = 45 * time.Second
	}
	if offlineWindow <= qrTTL {
		offlineWindow = 6 * time.Hour
	}

	return &AttendanceUseCase{
		repo:          repo,
		qrSigningKey:  []byte(strings.TrimSpace(qrSigningSecret)),
		qrTTL:         qrTTL,
		offlineWindow: offlineWindow,
	}
}

type AttendanceQRData struct {
	ActivityID string
	Token      string
	ExpiresAt  time.Time
	RefreshAt  time.Time
}

type AttendanceProofInput struct {
	ScanID          uuid.UUID
	QRToken         string
	InstallationID  string
	ScannedAtDevice *time.Time
}

type AttendanceSyncItemResult struct {
	ScanID      uuid.UUID
	ActivityID  *uuid.UUID
	Status      string
	Code        string
	Message     string
	CheckedInAt *time.Time
	SyncedAt    time.Time
}

func (u *AttendanceUseCase) GenerateAttendanceQR(
	ctx context.Context,
	activityID uuid.UUID,
	actorUserID uuid.UUID,
) (*AttendanceQRData, error) {
	if activityID == uuid.Nil {
		return nil, ErrInvalidActivityID
	}
	if actorUserID == uuid.Nil {
		return nil, ErrInvalidActorUserID
	}

	activity, err := u.repo.GetActivityByID(ctx, activityID)
	if err != nil {
		return nil, fmt.Errorf("get activity by id: %w", err)
	}
	if activity == nil {
		return nil, ErrActivityNotFound
	}
	if activity.HostUserID != actorUserID {
		return nil, ErrAttendanceAccessDenied
	}
	if !isAttendanceQRAvailable(activity.Status) {
		return nil, ErrAttendanceQRUnavailable
	}

	now := time.Now().UTC()
	issue, err := model.NewAttendanceQRIssue(model.NewAttendanceQRIssueParams{
		ActivityID:    activity.ID,
		HostUserID:    actorUserID,
		IssuedAt:      now,
		TTL:           u.qrTTL,
		OfflineWindow: u.resolveOfflineWindow(activity, now),
	})
	if err != nil {
		return nil, err
	}

	if err = u.repo.CreateAttendanceQRIssue(ctx, issue); err != nil {
		return nil, fmt.Errorf("create attendance qr issue: %w", err)
	}

	token, err := signAttendanceQRToken(
		u.qrSigningKey,
		issue.ActivityID,
		issue.HostUserID,
		issue.JTI,
		issue.IssuedAt,
		issue.ExpiresAt,
	)
	if err != nil {
		return nil, fmt.Errorf("sign attendance qr: %w", err)
	}

	refreshAt := issue.ExpiresAt.Add(-10 * time.Second)
	if !refreshAt.After(now) {
		refreshAt = now.Add(u.qrTTL / 2)
	}

	return &AttendanceQRData{
		ActivityID: issue.ActivityID.String(),
		Token:      token,
		ExpiresAt:  issue.ExpiresAt,
		RefreshAt:  refreshAt,
	}, nil
}

func (u *AttendanceUseCase) SyncAttendanceProofs(
	ctx context.Context,
	actorUserID uuid.UUID,
	inputs []AttendanceProofInput,
) ([]AttendanceSyncItemResult, error) {
	if actorUserID == uuid.Nil {
		return nil, ErrInvalidParticipantUserID
	}

	results := make([]AttendanceSyncItemResult, 0, len(inputs))
	for _, input := range inputs {
		results = append(results, u.syncAttendanceProof(ctx, actorUserID, input))
	}

	return results, nil
}

func (u *AttendanceUseCase) syncAttendanceProof(
	ctx context.Context,
	actorUserID uuid.UUID,
	input AttendanceProofInput,
) AttendanceSyncItemResult {
	now := time.Now().UTC()

	if input.ScanID == uuid.Nil {
		return AttendanceSyncItemResult{
			ScanID:   input.ScanID,
			Status:   AttendanceSyncStatusRejected,
			Code:     "invalid_scan_id",
			Message:  "invalid attendance scan id",
			SyncedAt: now,
		}
	}
	if strings.TrimSpace(input.QRToken) == "" {
		return AttendanceSyncItemResult{
			ScanID:   input.ScanID,
			Status:   AttendanceSyncStatusRejected,
			Code:     "invalid_qr",
			Message:  ErrAttendanceQRInvalid.Error(),
			SyncedAt: now,
		}
	}
	if strings.TrimSpace(input.InstallationID) == "" {
		return AttendanceSyncItemResult{
			ScanID:   input.ScanID,
			Status:   AttendanceSyncStatusRejected,
			Code:     "invalid_installation",
			Message:  "invalid installation id",
			SyncedAt: now,
		}
	}

	decoded, err := decodeAndVerifyAttendanceQR(u.qrSigningKey, input.QRToken)
	if err != nil {
		return AttendanceSyncItemResult{
			ScanID:   input.ScanID,
			Status:   AttendanceSyncStatusRejected,
			Code:     attendanceSyncCodeForError(err),
			Message:  err.Error(),
			SyncedAt: now,
		}
	}

	result := AttendanceSyncItemResult{
		ScanID:     input.ScanID,
		ActivityID: &decoded.ActivityID,
		SyncedAt:   now,
	}

	err = u.repo.WithTx(ctx, func(txRepo port.ActivityTxRepository) error {
		existingAttempt, err := txRepo.GetAttendanceSyncAttemptByScanIDForUpdate(
			ctx,
			input.ScanID,
		)
		if err != nil {
			return fmt.Errorf("get attendance sync attempt: %w", err)
		}
		if existingAttempt != nil {
			result = attendanceResultFromAttempt(existingAttempt)
			return nil
		}

		issue, err := txRepo.GetAttendanceQRIssueByJTIForUpdate(ctx, decoded.JTI)
		if err != nil {
			return fmt.Errorf("get attendance qr issue: %w", err)
		}
		if issue == nil ||
			issue.ActivityID != decoded.ActivityID ||
			issue.HostUserID != decoded.HostUserID {
			attempt, attemptErr := buildRejectedAttendanceAttempt(
				input,
				actorUserID,
				decoded,
				"invalid_qr",
				ErrAttendanceQRInvalid.Error(),
			)
			if attemptErr == nil {
				if err = txRepo.CreateAttendanceSyncAttempt(ctx, attempt); err != nil {
					return fmt.Errorf("create invalid attendance attempt: %w", err)
				}
			}
			result = rejectedAttendanceResult(
				input.ScanID,
				decoded.ActivityID,
				"invalid_qr",
				ErrAttendanceQRInvalid.Error(),
			)
			return nil
		}
		if now.After(issue.UsableUntil) {
			attempt, attemptErr := buildRejectedAttendanceAttempt(
				input,
				actorUserID,
				decoded,
				"qr_expired",
				ErrAttendanceQRExpired.Error(),
			)
			if attemptErr == nil {
				if err = txRepo.CreateAttendanceSyncAttempt(ctx, attempt); err != nil {
					return fmt.Errorf("create expired attendance attempt: %w", err)
				}
			}
			result = rejectedAttendanceResult(
				input.ScanID,
				decoded.ActivityID,
				"qr_expired",
				ErrAttendanceQRExpired.Error(),
			)
			return nil
		}

		activity, err := txRepo.GetActivityByIDForUpdate(ctx, decoded.ActivityID)
		if err != nil {
			return fmt.Errorf("get activity for attendance sync: %w", err)
		}
		if activity == nil {
			attempt, attemptErr := buildRejectedAttendanceAttempt(
				input,
				actorUserID,
				decoded,
				"activity_not_found",
				ErrActivityNotFound.Error(),
			)
			if attemptErr == nil {
				if err = txRepo.CreateAttendanceSyncAttempt(ctx, attempt); err != nil {
					return fmt.Errorf("create missing activity attendance attempt: %w", err)
				}
			}
			result = rejectedAttendanceResult(
				input.ScanID,
				decoded.ActivityID,
				"activity_not_found",
				ErrActivityNotFound.Error(),
			)
			return nil
		}
		if !isAttendanceScanAllowed(activity.Status) {
			attempt, attemptErr := buildRejectedAttendanceAttempt(
				input,
				actorUserID,
				decoded,
				"activity_unavailable",
				ErrAttendanceQRUnavailable.Error(),
			)
			if attemptErr == nil {
				if err = txRepo.CreateAttendanceSyncAttempt(ctx, attempt); err != nil {
					return fmt.Errorf("create unavailable activity attendance attempt: %w", err)
				}
			}
			result = rejectedAttendanceResult(
				input.ScanID,
				decoded.ActivityID,
				"activity_unavailable",
				ErrAttendanceQRUnavailable.Error(),
			)
			return nil
		}
		if activity.HostUserID == actorUserID {
			attempt, attemptErr := buildRejectedAttendanceAttempt(
				input,
				actorUserID,
				decoded,
				"host_scan_not_allowed",
				ErrAttendanceAccessDenied.Error(),
			)
			if attemptErr == nil {
				if err = txRepo.CreateAttendanceSyncAttempt(ctx, attempt); err != nil {
					return fmt.Errorf("create host attendance attempt: %w", err)
				}
			}
			result = rejectedAttendanceResult(
				input.ScanID,
				decoded.ActivityID,
				"host_scan_not_allowed",
				ErrAttendanceAccessDenied.Error(),
			)
			return nil
		}

		participant, err := txRepo.GetParticipantByActivityAndUserForUpdate(
			ctx,
			decoded.ActivityID,
			actorUserID,
		)
		if err != nil {
			return fmt.Errorf("get participant for attendance sync: %w", err)
		}
		if participant == nil {
			attempt, attemptErr := buildRejectedAttendanceAttempt(
				input,
				actorUserID,
				decoded,
				"not_registered",
				ErrParticipantNotFound.Error(),
			)
			if attemptErr == nil {
				if err = txRepo.CreateAttendanceSyncAttempt(ctx, attempt); err != nil {
					return fmt.Errorf("create missing participant attendance attempt: %w", err)
				}
			}
			result = rejectedAttendanceResult(
				input.ScanID,
				decoded.ActivityID,
				"not_registered",
				ErrParticipantNotFound.Error(),
			)
			return nil
		}

		if !canParticipantCheckIn(participant.Status) &&
			participant.Status != enum.ParticipantStatusCheckedIn &&
			participant.Status != enum.ParticipantStatusAttended {
			attempt, attemptErr := buildRejectedAttendanceAttempt(
				input,
				actorUserID,
				decoded,
				"participant_not_eligible",
				ErrAttendanceParticipantInvalid.Error(),
			)
			if attemptErr == nil {
				if err = txRepo.CreateAttendanceSyncAttempt(ctx, attempt); err != nil {
					return fmt.Errorf("create invalid participant attendance attempt: %w", err)
				}
			}
			result = rejectedAttendanceResult(
				input.ScanID,
				decoded.ActivityID,
				"participant_not_eligible",
				ErrAttendanceParticipantInvalid.Error(),
			)
			return nil
		}

		if participant.Status == enum.ParticipantStatusCheckedIn ||
			participant.Status == enum.ParticipantStatusAttended ||
			participant.CheckedInAt != nil {
			checkedInAt := participant.CheckedInAt
			if checkedInAt == nil {
				checkedInAt = participant.AttendedAt
			}

			attempt, attemptErr := model.NewAttendanceSyncAttempt(
				model.NewAttendanceSyncAttemptParams{
					ScanID:            input.ScanID,
					ActivityID:        decoded.ActivityID,
					ParticipantUserID: actorUserID,
					QRJTI:             decoded.JTI,
					InstallationID:    input.InstallationID,
					ScannedAtDevice:   input.ScannedAtDevice,
					ResultStatus:      model.AttendanceSyncAttemptStatusAlreadyCheckedIn,
					CheckedInAt:       checkedInAt,
				},
			)
			if attemptErr == nil {
				if err = txRepo.CreateAttendanceSyncAttempt(ctx, attempt); err != nil {
					return fmt.Errorf("create already checked-in attendance attempt: %w", err)
				}
			}

			result = AttendanceSyncItemResult{
				ScanID:      input.ScanID,
				ActivityID:  &decoded.ActivityID,
				Status:      AttendanceSyncStatusAlreadySynced,
				Code:        "already_checked_in",
				Message:     ErrAttendanceAlreadyCheckedIn.Error(),
				CheckedInAt: checkedInAt,
				SyncedAt:    time.Now().UTC(),
			}
			return nil
		}

		if err = u.enforceActivityFraud(ctx, activityParticipantFraudInput(
			fraudActionActivityAttendanceCheckIn,
			actorUserID,
			activity.ID,
			activity,
			input.ScanID.String(),
			map[string]any{
				"scanId":          input.ScanID.String(),
				"qrJti":           decoded.JTI.String(),
				"installationId":  strings.TrimSpace(input.InstallationID),
				"scannedAtDevice": input.ScannedAtDevice,
			},
		)); err != nil {
			attempt, attemptErr := buildRejectedAttendanceAttempt(
				input,
				actorUserID,
				decoded,
				"fraud_rejected",
				ErrFraudRejected.Error(),
			)
			if attemptErr == nil {
				if createErr := txRepo.CreateAttendanceSyncAttempt(ctx, attempt); createErr != nil {
					return fmt.Errorf("create fraud rejected attendance attempt: %w", createErr)
				}
			}
			result = rejectedAttendanceResult(
				input.ScanID,
				decoded.ActivityID,
				"fraud_rejected",
				ErrFraudRejected.Error(),
			)
			return nil
		}

		checkInTime := time.Now().UTC()
		if err = participant.SetStatus(enum.ParticipantStatusCheckedIn, checkInTime); err != nil {
			return err
		}
		if err = txRepo.UpdateParticipant(ctx, participant); err != nil {
			return fmt.Errorf("update checked-in participant: %w", err)
		}

		attempt, attemptErr := model.NewAttendanceSyncAttempt(
			model.NewAttendanceSyncAttemptParams{
				ScanID:            input.ScanID,
				ActivityID:        decoded.ActivityID,
				ParticipantUserID: actorUserID,
				QRJTI:             decoded.JTI,
				InstallationID:    input.InstallationID,
				ScannedAtDevice:   input.ScannedAtDevice,
				ResultStatus:      model.AttendanceSyncAttemptStatusAccepted,
				CheckedInAt:       &checkInTime,
			},
		)
		if attemptErr != nil {
			return attemptErr
		}
		if err = txRepo.CreateAttendanceSyncAttempt(ctx, attempt); err != nil {
			return fmt.Errorf("create accepted attendance attempt: %w", err)
		}

		participantEvent, participantEventErr := model.NewParticipantEvent(
			model.NewParticipantEventParams{
				ActivityID:    activity.ID,
				ParticipantID: participant.ID,
				UserID:        participant.UserID,
				EventType:     string(enum.ParticipantStatusCheckedIn),
				ActorUserID:   &actorUserID,
				PayloadJSON: mustJSON(map[string]any{
					"scanId":          input.ScanID.String(),
					"qrJti":           decoded.JTI.String(),
					"installationId":  strings.TrimSpace(input.InstallationID),
					"scannedAtDevice": input.ScannedAtDevice,
				}),
			},
		)
		if participantEventErr == nil {
			if err = txRepo.CreateParticipantEvent(ctx, participantEvent); err != nil {
				return fmt.Errorf("create participant checked-in event: %w", err)
			}
		}

		result = AttendanceSyncItemResult{
			ScanID:      input.ScanID,
			ActivityID:  &decoded.ActivityID,
			Status:      AttendanceSyncStatusSynced,
			Code:        "checked_in",
			Message:     "attendance synced",
			CheckedInAt: &checkInTime,
			SyncedAt:    time.Now().UTC(),
		}
		return nil
	})
	if err != nil {
		return AttendanceSyncItemResult{
			ScanID:     input.ScanID,
			ActivityID: result.ActivityID,
			Status:     AttendanceSyncStatusRetryable,
			Code:       "server_error",
			Message:    "attendance sync failed",
			SyncedAt:   time.Now().UTC(),
		}
	}

	return result
}

func (u *AttendanceUseCase) resolveOfflineWindow(activity *model.Activity, now time.Time) time.Duration {
	offlineDeadline := now.Add(u.offlineWindow)
	if activity != nil && !activity.EndAt.IsZero() {
		eventDeadline := activity.EndAt.UTC().Add(6 * time.Hour)
		if eventDeadline.Before(offlineDeadline) {
			offlineDeadline = eventDeadline
		}
	}
	if !offlineDeadline.After(now.Add(u.qrTTL)) {
		offlineDeadline = now.Add(u.qrTTL).Add(30 * time.Minute)
	}
	return time.Until(offlineDeadline)
}

func attendanceSyncCodeForError(err error) string {
	switch err {
	case nil:
		return ""
	case ErrAttendanceQRVersionInvalid:
		return "unsupported_qr"
	case ErrAttendanceQRInvalid:
		return "invalid_qr"
	default:
		if err.Error() == ErrAttendanceQRVersionInvalid.Error() {
			return "unsupported_qr"
		}
		return "invalid_qr"
	}
}

func attendanceResultFromAttempt(
	attempt *model.AttendanceSyncAttempt,
) AttendanceSyncItemResult {
	status := AttendanceSyncStatusRejected
	code := valueOr(attempt.FailureCode, "rejected")
	message := valueOr(attempt.FailureMessage, "attendance rejected")

	switch attempt.ResultStatus {
	case model.AttendanceSyncAttemptStatusAccepted:
		status = AttendanceSyncStatusSynced
		code = "checked_in"
		message = "attendance synced"
	case model.AttendanceSyncAttemptStatusAlreadyCheckedIn:
		status = AttendanceSyncStatusAlreadySynced
		code = "already_checked_in"
		message = ErrAttendanceAlreadyCheckedIn.Error()
	}

	return AttendanceSyncItemResult{
		ScanID:      attempt.ScanID,
		ActivityID:  &attempt.ActivityID,
		Status:      status,
		Code:        code,
		Message:     message,
		CheckedInAt: attempt.CheckedInAt,
		SyncedAt:    attempt.UpdatedAt,
	}
}

func buildRejectedAttendanceAttempt(
	input AttendanceProofInput,
	actorUserID uuid.UUID,
	decoded *decodedAttendanceQR,
	code string,
	message string,
) (*model.AttendanceSyncAttempt, error) {
	return model.NewAttendanceSyncAttempt(model.NewAttendanceSyncAttemptParams{
		ScanID:            input.ScanID,
		ActivityID:        decoded.ActivityID,
		ParticipantUserID: actorUserID,
		QRJTI:             decoded.JTI,
		InstallationID:    input.InstallationID,
		ScannedAtDevice:   input.ScannedAtDevice,
		ResultStatus:      model.AttendanceSyncAttemptStatusRejected,
		FailureCode:       &code,
		FailureMessage:    &message,
	})
}

func rejectedAttendanceResult(
	scanID uuid.UUID,
	activityID uuid.UUID,
	code string,
	message string,
) AttendanceSyncItemResult {
	return AttendanceSyncItemResult{
		ScanID:     scanID,
		ActivityID: &activityID,
		Status:     AttendanceSyncStatusRejected,
		Code:       code,
		Message:    message,
		SyncedAt:   time.Now().UTC(),
	}
}

func canParticipantCheckIn(status enum.ParticipantStatus) bool {
	switch status {
	case enum.ParticipantStatusApproved,
		enum.ParticipantStatusPendingPayment,
		enum.ParticipantStatusConfirmed:
		return true
	default:
		return false
	}
}

func isAttendanceQRAvailable(status enum.ActivityStatus) bool {
	switch status {
	case enum.ActivityStatusCancelled,
		enum.ActivityStatusCompleted,
		enum.ActivityStatusArchived:
		return false
	default:
		return true
	}
}

func isAttendanceScanAllowed(status enum.ActivityStatus) bool {
	switch status {
	case enum.ActivityStatusPublished,
		enum.ActivityStatusEnrollmentOpen,
		enum.ActivityStatusFull,
		enum.ActivityStatusStarted:
		return true
	default:
		return false
	}
}

func valueOr(ptr *string, fallback string) string {
	if ptr == nil || strings.TrimSpace(*ptr) == "" {
		return fallback
	}
	return strings.TrimSpace(*ptr)
}
