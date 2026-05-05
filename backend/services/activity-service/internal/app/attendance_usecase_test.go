package app

import (
	"context"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/activity-service/internal/domain/enum"
	"github.com/dkhvan-dev/flyfy/backend/services/activity-service/internal/domain/model"
	"github.com/dkhvan-dev/flyfy/backend/services/activity-service/internal/domain/port"
)

type attendanceRepoStub struct {
	withTx func(ctx context.Context, fn func(repo port.ActivityTxRepository) error) error
}

func (s *attendanceRepoStub) CreateActivity(ctx context.Context, item *model.Activity) error {
	return nil
}

func (s *attendanceRepoStub) UpdateActivity(ctx context.Context, item *model.Activity) error {
	return nil
}

func (s *attendanceRepoStub) GetActivityByID(ctx context.Context, activityID uuid.UUID) (*model.Activity, error) {
	return nil, nil
}

func (s *attendanceRepoStub) ListActivities(ctx context.Context, filter port.ActivityFilter) ([]*model.Activity, error) {
	return nil, nil
}

func (s *attendanceRepoStub) ListActivitiesDueForRegistrationFinalization(ctx context.Context, before time.Time, limit int) ([]*model.Activity, error) {
	return nil, nil
}

func (s *attendanceRepoStub) ListActivitiesDueForStart(ctx context.Context, before time.Time, limit int) ([]*model.Activity, error) {
	return nil, nil
}

func (s *attendanceRepoStub) ListActivitiesDueForCompletion(ctx context.Context, before time.Time, limit int) ([]*model.Activity, error) {
	return nil, nil
}

func (s *attendanceRepoStub) CreateActivityEvent(ctx context.Context, item *model.ActivityEvent) error {
	return nil
}

func (s *attendanceRepoStub) ListTagsByActivityID(ctx context.Context, activityID uuid.UUID) ([]string, error) {
	return nil, nil
}

func (s *attendanceRepoStub) ReplaceTags(ctx context.Context, activityID uuid.UUID, tags []string) error {
	return nil
}

func (s *attendanceRepoStub) ListMediaByActivityID(ctx context.Context, activityID uuid.UUID) ([]*model.ActivityMedia, error) {
	return nil, nil
}

func (s *attendanceRepoStub) ReplaceMedia(ctx context.Context, activityID uuid.UUID, items []*model.ActivityMedia) error {
	return nil
}

func (s *attendanceRepoStub) CreateAttendanceQRIssue(ctx context.Context, item *model.AttendanceQRIssue) error {
	return nil
}

func (s *attendanceRepoStub) GetParticipantByActivityAndUser(ctx context.Context, activityID uuid.UUID, userID uuid.UUID) (*model.ActivityParticipant, error) {
	return nil, nil
}

func (s *attendanceRepoStub) ListParticipantsByActivityID(ctx context.Context, activityID uuid.UUID, limit int, offset int) ([]*model.ActivityParticipant, error) {
	return nil, nil
}

func (s *attendanceRepoStub) ListHostedActivitiesByUserID(ctx context.Context, userID uuid.UUID, limit int, offset int) ([]*model.Activity, error) {
	return nil, nil
}

func (s *attendanceRepoStub) ListJoinedActivitiesByUserID(ctx context.Context, userID uuid.UUID, limit int, offset int) ([]*model.Activity, error) {
	return nil, nil
}

func (s *attendanceRepoStub) CreateParticipant(ctx context.Context, item *model.ActivityParticipant) error {
	return nil
}

func (s *attendanceRepoStub) UpdateParticipant(ctx context.Context, item *model.ActivityParticipant) error {
	return nil
}

func (s *attendanceRepoStub) CreateParticipantEvent(ctx context.Context, item *model.ParticipantEvent) error {
	return nil
}

func (s *attendanceRepoStub) WithTx(ctx context.Context, fn func(repo port.ActivityTxRepository) error) error {
	if s.withTx != nil {
		return s.withTx(ctx, fn)
	}
	return nil
}

func (s *attendanceRepoStub) ListActiveBlockedURLPatterns(ctx context.Context) ([]*model.BlockedURLPattern, error) {
	return nil, nil
}

func (s *attendanceRepoStub) CountActivitiesCreatedSince(ctx context.Context, hostUserID uuid.UUID, since time.Time) (int, error) {
	return 0, nil
}

type attendanceTxRepoStub struct {
	getAttendanceSyncAttemptByScanIDForUpdate func(ctx context.Context, scanID uuid.UUID) (*model.AttendanceSyncAttempt, error)
	getAttendanceQRIssueByJTIForUpdate        func(ctx context.Context, jti uuid.UUID) (*model.AttendanceQRIssue, error)
	getActivityByIDForUpdate                  func(ctx context.Context, activityID uuid.UUID) (*model.Activity, error)
	getParticipantByActivityAndUserForUpdate  func(ctx context.Context, activityID uuid.UUID, userID uuid.UUID) (*model.ActivityParticipant, error)
	createAttendanceSyncAttempt               func(ctx context.Context, item *model.AttendanceSyncAttempt) error
}

func (s *attendanceTxRepoStub) GetActivityByIDForUpdate(ctx context.Context, activityID uuid.UUID) (*model.Activity, error) {
	if s.getActivityByIDForUpdate != nil {
		return s.getActivityByIDForUpdate(ctx, activityID)
	}
	return nil, nil
}

func (s *attendanceTxRepoStub) GetParticipantByActivityAndUserForUpdate(ctx context.Context, activityID uuid.UUID, userID uuid.UUID) (*model.ActivityParticipant, error) {
	if s.getParticipantByActivityAndUserForUpdate != nil {
		return s.getParticipantByActivityAndUserForUpdate(ctx, activityID, userID)
	}
	return nil, nil
}

func (s *attendanceTxRepoStub) GetAttendanceQRIssueByJTIForUpdate(ctx context.Context, jti uuid.UUID) (*model.AttendanceQRIssue, error) {
	if s.getAttendanceQRIssueByJTIForUpdate != nil {
		return s.getAttendanceQRIssueByJTIForUpdate(ctx, jti)
	}
	return nil, nil
}

func (s *attendanceTxRepoStub) GetAttendanceSyncAttemptByScanIDForUpdate(ctx context.Context, scanID uuid.UUID) (*model.AttendanceSyncAttempt, error) {
	if s.getAttendanceSyncAttemptByScanIDForUpdate != nil {
		return s.getAttendanceSyncAttemptByScanIDForUpdate(ctx, scanID)
	}
	return nil, nil
}

func (s *attendanceTxRepoStub) HasActiveOverlappingJoinedActivity(ctx context.Context, userID uuid.UUID, excludeActivityID uuid.UUID, startAt time.Time, endAt time.Time) (bool, error) {
	return false, nil
}

func (s *attendanceTxRepoStub) CountOccupiedSlotsForUpdate(ctx context.Context, activityID uuid.UUID) (int, error) {
	return 0, nil
}

func (s *attendanceTxRepoStub) ListParticipantsByActivityIDForUpdate(ctx context.Context, activityID uuid.UUID) ([]*model.ActivityParticipant, error) {
	return nil, nil
}

func (s *attendanceTxRepoStub) CreateParticipant(ctx context.Context, item *model.ActivityParticipant) error {
	return nil
}

func (s *attendanceTxRepoStub) UpdateParticipant(ctx context.Context, item *model.ActivityParticipant) error {
	return nil
}

func (s *attendanceTxRepoStub) CreateAttendanceSyncAttempt(ctx context.Context, item *model.AttendanceSyncAttempt) error {
	if s.createAttendanceSyncAttempt != nil {
		return s.createAttendanceSyncAttempt(ctx, item)
	}
	return nil
}

func (s *attendanceTxRepoStub) UpdateAttendanceSyncAttempt(ctx context.Context, item *model.AttendanceSyncAttempt) error {
	return nil
}

func (s *attendanceTxRepoStub) CreateParticipantEvent(ctx context.Context, item *model.ParticipantEvent) error {
	return nil
}

func (s *attendanceTxRepoStub) CreateActivityEvent(ctx context.Context, item *model.ActivityEvent) error {
	return nil
}

func (s *attendanceTxRepoStub) UpdateActivity(ctx context.Context, item *model.Activity) error {
	return nil
}

func TestSyncAttendanceProofCancelledParticipantReturnsNotEligible(t *testing.T) {
	t.Parallel()

	activityID := uuid.New()
	hostUserID := uuid.New()
	participantUserID := uuid.New()
	scanID := uuid.New()
	now := time.Now().UTC()

	activity := validActivity(t, activityID, hostUserID)
	activity.Status = enum.ActivityStatusStarted

	participant := validParticipant(t, activityID, participantUserID, enum.ParticipantStatusApproved)
	if err := participant.SetStatus(enum.ParticipantStatusCancelled, now.Add(-5*time.Minute)); err != nil {
		t.Fatalf("participant.SetStatus() error = %v", err)
	}
	checkedInAt := now.Add(-10 * time.Minute)
	participant.CheckedInAt = &checkedInAt

	issue, err := model.NewAttendanceQRIssue(model.NewAttendanceQRIssueParams{
		ActivityID:    activityID,
		HostUserID:    hostUserID,
		IssuedAt:      now.Add(-10 * time.Second),
		TTL:           45 * time.Second,
		OfflineWindow: 6 * time.Hour,
	})
	if err != nil {
		t.Fatalf("model.NewAttendanceQRIssue() error = %v", err)
	}

	token, err := signAttendanceQRToken(
		[]byte("test-secret"),
		issue.ActivityID,
		issue.HostUserID,
		issue.JTI,
		issue.IssuedAt,
		issue.ExpiresAt,
	)
	if err != nil {
		t.Fatalf("signAttendanceQRToken() error = %v", err)
	}

	var createdAttempt *model.AttendanceSyncAttempt
	txRepo := &attendanceTxRepoStub{
		getAttendanceQRIssueByJTIForUpdate: func(ctx context.Context, jti uuid.UUID) (*model.AttendanceQRIssue, error) {
			return issue, nil
		},
		getActivityByIDForUpdate: func(ctx context.Context, requestedActivityID uuid.UUID) (*model.Activity, error) {
			return activity, nil
		},
		getParticipantByActivityAndUserForUpdate: func(ctx context.Context, requestedActivityID uuid.UUID, requestedUserID uuid.UUID) (*model.ActivityParticipant, error) {
			return participant, nil
		},
		createAttendanceSyncAttempt: func(ctx context.Context, item *model.AttendanceSyncAttempt) error {
			createdAttempt = item
			return nil
		},
	}
	repo := &attendanceRepoStub{
		withTx: func(ctx context.Context, fn func(repo port.ActivityTxRepository) error) error {
			return fn(txRepo)
		},
	}

	uc := NewAttendanceUseCase(repo, "test-secret", 45*time.Second, 6*time.Hour)
	result := uc.syncAttendanceProof(context.Background(), participantUserID, AttendanceProofInput{
		ScanID:         scanID,
		QRToken:        token,
		InstallationID: "installation-1",
	})

	if result.Status != AttendanceSyncStatusRejected {
		t.Fatalf("syncAttendanceProof() status = %s, want %s", result.Status, AttendanceSyncStatusRejected)
	}
	if result.Code != "participant_not_eligible" {
		t.Fatalf("syncAttendanceProof() code = %s, want participant_not_eligible", result.Code)
	}
	if createdAttempt == nil {
		t.Fatal("syncAttendanceProof() did not persist rejection attempt")
	}
	if createdAttempt.ResultStatus != model.AttendanceSyncAttemptStatusRejected {
		t.Fatalf("syncAttendanceProof() attempt status = %s, want %s", createdAttempt.ResultStatus, model.AttendanceSyncAttemptStatusRejected)
	}
	if createdAttempt.FailureCode == nil || *createdAttempt.FailureCode != "participant_not_eligible" {
		t.Fatalf("syncAttendanceProof() attempt failure code = %v, want participant_not_eligible", createdAttempt.FailureCode)
	}
}
