package app

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/guide-service/internal/domain/model"
)

func TestSavedGuideUserReconcilerPersistsActivePublicFingerprint(t *testing.T) {
	t.Parallel()
	now := time.Date(2026, 7, 16, 12, 0, 0, 0, time.UTC)
	userID := uuid.New()
	avatarID := uuid.New()
	nickname := "Aruzhan"
	repo := &savedUserReconcileRepoStub{claimed: []*model.SavedGuideUserReconcileLease{{
		GuideProfileID: uuid.New(), UserID: userID, LeaseToken: uuid.New(),
	}}}
	userSource := &savedGuideUserSourceStub{snapshot: &SavedGuideUserSnapshot{
		UserID: userID, AccountStatus: "ACTIVE", Nickname: &nickname,
		AvatarFileID: &avatarID, Locale: "en",
		AccountUpdatedAt: now.Add(-2 * time.Second), ProfileUpdatedAt: now.Add(-time.Second),
	}}
	config := DefaultSavedGuideUserReconcilerConfig()
	config.BatchSize = 1
	config.Concurrency = 1
	reconciler, err := NewSavedGuideUserReconciler(repo, userSource, config)
	if err != nil {
		t.Fatalf("NewSavedGuideUserReconciler() error = %v", err)
	}
	reconciler.now = func() time.Time { return now }

	if _, err = reconciler.ReconcileBatch(context.Background()); err != nil {
		t.Fatalf("ReconcileBatch() error = %v", err)
	}
	if repo.applied == nil || repo.applied.AccountStatus != "ACTIVE" ||
		len(repo.applied.ProjectionFingerprint) != 32 || repo.applied.AvatarFileID == nil ||
		*repo.applied.AvatarFileID != avatarID {
		t.Fatalf("applied state = %+v", repo.applied)
	}
}

func TestSavedGuideUserReconcilerTreatsAuthoritativeNotFoundAsDeleted(t *testing.T) {
	t.Parallel()
	now := time.Date(2026, 7, 16, 12, 0, 0, 0, time.UTC)
	repo := &savedUserReconcileRepoStub{claimed: []*model.SavedGuideUserReconcileLease{{
		GuideProfileID: uuid.New(), UserID: uuid.New(), LeaseToken: uuid.New(),
	}}}
	config := DefaultSavedGuideUserReconcilerConfig()
	config.BatchSize = 1
	config.Concurrency = 1
	reconciler, err := NewSavedGuideUserReconciler(
		repo,
		&savedGuideUserSourceStub{err: ErrUserNotFound},
		config,
	)
	if err != nil {
		t.Fatalf("NewSavedGuideUserReconciler() error = %v", err)
	}
	reconciler.now = func() time.Time { return now }

	if _, err = reconciler.ReconcileBatch(context.Background()); err != nil {
		t.Fatalf("ReconcileBatch() error = %v", err)
	}
	if repo.applied == nil || repo.applied.AccountStatus != "DELETED" || !repo.applied.IsDeleted ||
		repo.applied.ProfileUpdatedAt != nil || len(repo.applied.ProjectionFingerprint) != 0 {
		t.Fatalf("deleted state = %+v", repo.applied)
	}
}

func TestSavedGuideUserReconcilerSchedulesBoundedDependencyRetry(t *testing.T) {
	t.Parallel()
	now := time.Date(2026, 7, 16, 12, 0, 0, 0, time.UTC)
	repo := &savedUserReconcileRepoStub{claimed: []*model.SavedGuideUserReconcileLease{{
		GuideProfileID: uuid.New(), UserID: uuid.New(), LeaseToken: uuid.New(), FailureCount: 3,
	}}}
	config := DefaultSavedGuideUserReconcilerConfig()
	config.BatchSize = 1
	config.Concurrency = 1
	reconciler, err := NewSavedGuideUserReconciler(
		repo,
		&savedGuideUserSourceStub{err: errors.New("dependency unavailable")},
		config,
	)
	if err != nil {
		t.Fatalf("NewSavedGuideUserReconciler() error = %v", err)
	}
	reconciler.now = func() time.Time { return now }

	if _, err = reconciler.ReconcileBatch(context.Background()); err != nil {
		t.Fatalf("ReconcileBatch() error = %v", err)
	}
	want := now.Add(40 * time.Second)
	if repo.failedAt != want {
		t.Fatalf("retry at = %s, want %s", repo.failedAt, want)
	}
}

func TestSavedGuideUserReconcilerRejectsMismatchedUserIdentity(t *testing.T) {
	t.Parallel()
	now := time.Date(2026, 7, 16, 12, 0, 0, 0, time.UTC)
	claimedUserID := uuid.New()
	repo := &savedUserReconcileRepoStub{claimed: []*model.SavedGuideUserReconcileLease{{
		GuideProfileID: uuid.New(), UserID: claimedUserID, LeaseToken: uuid.New(),
	}}}
	config := DefaultSavedGuideUserReconcilerConfig()
	config.BatchSize = 1
	config.Concurrency = 1
	reconciler, err := NewSavedGuideUserReconciler(
		repo,
		&savedGuideUserSourceStub{snapshot: &SavedGuideUserSnapshot{
			UserID: uuid.New(), AccountStatus: "ACTIVE", Locale: "en",
			AccountUpdatedAt: now, ProfileUpdatedAt: now,
		}},
		config,
	)
	if err != nil {
		t.Fatalf("NewSavedGuideUserReconciler() error = %v", err)
	}
	reconciler.now = func() time.Time { return now }

	if _, err = reconciler.ReconcileBatch(context.Background()); err != nil {
		t.Fatalf("ReconcileBatch() error = %v", err)
	}
	if repo.applied != nil || repo.failedAt != now.Add(config.FailureBaseDelay) {
		t.Fatalf("mismatched identity applied=%+v retry=%s", repo.applied, repo.failedAt)
	}
}

func TestSavedGuideExternalUserStateMapsUnknownNonActiveStatusToDeny(t *testing.T) {
	t.Parallel()
	now := time.Date(2026, 7, 16, 12, 0, 0, 0, time.UTC)
	state, err := savedGuideExternalUserState(&SavedGuideUserSnapshot{
		UserID: uuid.New(), AccountStatus: "SUSPENDED", Locale: "en",
		AccountUpdatedAt: now, ProfileUpdatedAt: now,
	}, now)
	if err != nil {
		t.Fatalf("savedGuideExternalUserState() error = %v", err)
	}
	if state.AccountStatus != "BLOCKED" || state.IsDeleted {
		t.Fatalf("future deny status mapped to %+v", state)
	}
}

type savedUserReconcileRepoStub struct {
	claimed  []*model.SavedGuideUserReconcileLease
	applied  *model.SavedGuideExternalUserState
	failedAt time.Time
}

func (r *savedUserReconcileRepoStub) ClaimSavedGuideUserReconciliations(
	context.Context, time.Time, int, time.Duration,
) ([]*model.SavedGuideUserReconcileLease, error) {
	items := r.claimed
	r.claimed = nil
	return items, nil
}

func (r *savedUserReconcileRepoStub) ApplySavedGuideExternalUserState(
	_ context.Context,
	_ model.SavedGuideUserReconcileLease,
	state model.SavedGuideExternalUserState,
	_ time.Time,
) error {
	r.applied = &state
	return nil
}

func (r *savedUserReconcileRepoStub) MarkSavedGuideUserReconcileFailed(
	_ context.Context,
	_ model.SavedGuideUserReconcileLease,
	nextAttemptAt time.Time,
) error {
	r.failedAt = nextAttemptAt
	return nil
}
