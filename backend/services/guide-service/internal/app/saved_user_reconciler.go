package app

import (
	"context"
	"crypto/sha256"
	"encoding/binary"
	"errors"
	"strings"
	"sync"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"kz/inflap/backend/services/guide-service/internal/domain/model"
	"kz/inflap/backend/services/guide-service/internal/domain/port"
)

// User account/profile writes are owned by user-service and cannot share the
// guide-service transaction. This reconciler reads only known guide IDs over
// the authenticated internal client, then atomically updates the local
// revision/media state and lifecycle outbox. No user PII is persisted: only
// source timestamps, an opaque projection fingerprint, and the avatar file ID.
type SavedGuideUserReconcilerConfig struct {
	BatchSize        int
	Concurrency      int
	PollInterval     time.Duration
	LeaseDuration    time.Duration
	SourceTimeout    time.Duration
	SuccessInterval  time.Duration
	FailureBaseDelay time.Duration
	FailureMaxDelay  time.Duration
}

func DefaultSavedGuideUserReconcilerConfig() SavedGuideUserReconcilerConfig {
	return SavedGuideUserReconcilerConfig{
		BatchSize:        25,
		Concurrency:      4,
		PollInterval:     500 * time.Millisecond,
		LeaseDuration:    15 * time.Second,
		SourceTimeout:    3 * time.Second,
		SuccessInterval:  time.Minute,
		FailureBaseDelay: 5 * time.Second,
		FailureMaxDelay:  5 * time.Minute,
	}
}

func (c SavedGuideUserReconcilerConfig) Validate() error {
	if c.BatchSize < 1 || c.BatchSize > 200 || c.Concurrency < 1 || c.Concurrency > 16 ||
		c.PollInterval < 50*time.Millisecond || c.SourceTimeout <= 0 ||
		c.LeaseDuration <= c.SourceTimeout || c.SuccessInterval <= 0 ||
		c.FailureBaseDelay <= 0 || c.FailureMaxDelay < c.FailureBaseDelay {
		return model.ErrInvalidSavedLifecycleState
	}
	return nil
}

type SavedGuideUserReconciler struct {
	repo       port.SavedGuideUserReconciliationRepository
	userSource SavedGuideUserSource
	config     SavedGuideUserReconcilerConfig
	now        func() time.Time
}

func NewSavedGuideUserReconciler(
	repo port.SavedGuideUserReconciliationRepository,
	userSource SavedGuideUserSource,
	config SavedGuideUserReconcilerConfig,
) (*SavedGuideUserReconciler, error) {
	if repo == nil || userSource == nil {
		return nil, model.ErrInvalidSavedLifecycleState
	}
	if err := config.Validate(); err != nil {
		return nil, err
	}
	return &SavedGuideUserReconciler{
		repo:       repo,
		userSource: userSource,
		config:     config,
		now:        time.Now,
	}, nil
}

func (r *SavedGuideUserReconciler) Run(ctx context.Context) error {
	if r == nil || r.repo == nil || r.userSource == nil || r.now == nil {
		return model.ErrInvalidSavedLifecycleState
	}
	timer := time.NewTimer(0)
	defer timer.Stop()
	for {
		select {
		case <-ctx.Done():
			return nil
		case <-timer.C:
			processed, err := r.ReconcileBatch(ctx)
			if err != nil && !errors.Is(err, context.Canceled) {
				log.Error().Err(err).Msg("Saved guide user reconciliation batch failed")
			}
			delay := r.config.PollInterval
			if processed == r.config.BatchSize {
				delay = 0
			}
			timer.Reset(delay)
		}
	}
}

func (r *SavedGuideUserReconciler) ReconcileBatch(ctx context.Context) (int, error) {
	if r == nil || r.repo == nil || r.userSource == nil || r.now == nil {
		return 0, model.ErrInvalidSavedLifecycleState
	}
	items, err := r.repo.ClaimSavedGuideUserReconciliations(
		ctx,
		r.now().UTC(),
		r.config.BatchSize,
		r.config.LeaseDuration,
	)
	if err != nil {
		return 0, err
	}
	if len(items) == 0 {
		return 0, nil
	}

	jobs := make(chan *model.SavedGuideUserReconcileLease)
	var workers sync.WaitGroup
	workerCount := min(r.config.Concurrency, len(items))
	workers.Add(workerCount)
	for range workerCount {
		go func() {
			defer workers.Done()
			for item := range jobs {
				r.reconcileOne(ctx, item)
			}
		}()
	}
	for _, item := range items {
		select {
		case jobs <- item:
		case <-ctx.Done():
			close(jobs)
			workers.Wait()
			return len(items), ctx.Err()
		}
	}
	close(jobs)
	workers.Wait()
	return len(items), nil
}

func (r *SavedGuideUserReconciler) reconcileOne(
	ctx context.Context,
	lease *model.SavedGuideUserReconcileLease,
) {
	if lease == nil || lease.Validate() != nil {
		return
	}
	callCtx, cancel := context.WithTimeout(ctx, r.config.SourceTimeout)
	snapshot, err := r.userSource.GetSavedGuideUserSnapshot(callCtx, lease.UserID)
	cancel()
	observedAt := r.now().UTC()
	if err != nil {
		if errors.Is(err, ErrUserNotFound) {
			state := model.SavedGuideExternalUserState{
				AccountStatus:    "DELETED",
				IsDeleted:        true,
				AccountUpdatedAt: observedAt,
				ObservedAt:       observedAt,
			}
			if applyErr := r.repo.ApplySavedGuideExternalUserState(
				ctx,
				*lease,
				state,
				observedAt.Add(r.config.SuccessInterval),
			); applyErr != nil && !errors.Is(applyErr, context.Canceled) {
				log.Error().Err(applyErr).Msg("failed to persist unavailable Saved guide user state")
			}
			return
		}
		r.scheduleFailure(ctx, *lease, observedAt)
		return
	}
	if snapshot == nil || snapshot.UserID != lease.UserID {
		r.scheduleFailure(ctx, *lease, observedAt)
		return
	}
	state, err := savedGuideExternalUserState(snapshot, observedAt)
	if err != nil {
		r.scheduleFailure(ctx, *lease, observedAt)
		return
	}
	if err = r.repo.ApplySavedGuideExternalUserState(
		ctx,
		*lease,
		state,
		observedAt.Add(r.config.SuccessInterval),
	); err != nil && !errors.Is(err, context.Canceled) {
		log.Error().Err(err).Msg("failed to apply Saved guide user reconciliation")
	}
}

func (r *SavedGuideUserReconciler) scheduleFailure(
	ctx context.Context,
	lease model.SavedGuideUserReconcileLease,
	failedAt time.Time,
) {
	delay := r.config.FailureBaseDelay
	for range min(lease.FailureCount, 8) {
		delay *= 2
		if delay >= r.config.FailureMaxDelay {
			delay = r.config.FailureMaxDelay
			break
		}
	}
	if delay > r.config.FailureMaxDelay {
		delay = r.config.FailureMaxDelay
	}
	if err := r.repo.MarkSavedGuideUserReconcileFailed(
		ctx,
		lease,
		failedAt.Add(delay),
	); err != nil && !errors.Is(err, context.Canceled) {
		log.Error().Err(err).Msg("failed to schedule Saved guide user reconciliation retry")
	}
}

func savedGuideExternalUserState(
	snapshot *SavedGuideUserSnapshot,
	observedAt time.Time,
) (model.SavedGuideExternalUserState, error) {
	if snapshot == nil || snapshot.UserID == uuid.Nil || observedAt.IsZero() {
		return model.SavedGuideExternalUserState{}, model.ErrInvalidSavedLifecycleState
	}
	status := strings.ToUpper(strings.TrimSpace(snapshot.AccountStatus))
	if snapshot.IsDeleted {
		status = "DELETED"
	}
	if status == "" {
		return model.SavedGuideExternalUserState{}, model.ErrInvalidSavedLifecycleState
	}
	if status != "ACTIVE" && status != "DELETED" {
		status = "BLOCKED"
	}
	profileUpdatedAt := snapshot.ProfileUpdatedAt.UTC()
	fingerprint := savedGuideProjectionFingerprint(snapshot)
	state := model.SavedGuideExternalUserState{
		AccountStatus:         status,
		IsDeleted:             snapshot.IsDeleted || status == "DELETED",
		AccountUpdatedAt:      snapshot.AccountUpdatedAt.UTC(),
		ProfileUpdatedAt:      &profileUpdatedAt,
		ProjectionFingerprint: fingerprint[:],
		AvatarFileID:          snapshot.AvatarFileID,
		ObservedAt:            observedAt.UTC(),
	}
	if err := state.Validate(); err != nil {
		return model.SavedGuideExternalUserState{}, err
	}
	return state, nil
}

func savedGuideProjectionFingerprint(snapshot *SavedGuideUserSnapshot) [sha256.Size]byte {
	hash := sha256.New()
	write := func(value string) {
		var length [4]byte
		binary.BigEndian.PutUint32(length[:], uint32(len(value)))
		_, _ = hash.Write(length[:])
		_, _ = hash.Write([]byte(value))
	}
	write(savedGuideOptionalString(snapshot.FirstName))
	write(savedGuideOptionalString(snapshot.LastName))
	write(savedGuideOptionalString(snapshot.Nickname))
	write(savedGuideOptionalString(snapshot.CountryCode))
	write(strings.ToLower(strings.TrimSpace(snapshot.Locale)))
	if snapshot.AvatarFileID != nil {
		write(snapshot.AvatarFileID.String())
	} else {
		write("")
	}
	var result [sha256.Size]byte
	copy(result[:], hash.Sum(nil))
	return result
}
