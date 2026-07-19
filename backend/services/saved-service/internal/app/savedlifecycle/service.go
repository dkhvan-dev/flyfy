package savedlifecycle

import (
	"context"
	"time"
)

const (
	InboxRetention       = 14 * 24 * time.Hour
	MaxInboxCleanupBatch = 1_000
)

type Repository interface {
	Apply(ctx context.Context, event Event, processedAt time.Time) (Outcome, error)
	DeleteExpired(ctx context.Context, now time.Time, limit int) (int64, error)
}

type Service struct {
	repository Repository
	now        func() time.Time
}

func NewService(repository Repository) (*Service, error) {
	if repository == nil {
		return nil, NewPermanentError(ErrorCodePersistenceInvariant)
	}
	return &Service{repository: repository, now: time.Now}, nil
}

func (s *Service) Ingest(ctx context.Context, event Event) (Outcome, error) {
	if ctx == nil {
		return Outcome{}, NewPermanentError(ErrorCodePersistenceInvariant)
	}
	if err := ctx.Err(); err != nil {
		return Outcome{}, err
	}
	if s == nil || s.repository == nil || s.now == nil {
		return Outcome{}, ErrRepositoryUnavailable
	}
	processedAt := s.now().UTC()
	if err := event.Validate(processedAt); err != nil {
		return Outcome{}, err
	}
	outcome, err := s.repository.Apply(ctx, event, processedAt)
	if err != nil {
		return Outcome{}, err
	}
	if !outcome.IsValid() {
		return Outcome{}, NewPermanentError(ErrorCodePersistenceInvariant)
	}
	return outcome, nil
}

func (s *Service) DeleteExpiredInbox(ctx context.Context, limit int) (int64, error) {
	if ctx == nil {
		return 0, NewPermanentError(ErrorCodePersistenceInvariant)
	}
	if err := ctx.Err(); err != nil {
		return 0, err
	}
	if s == nil || s.repository == nil || s.now == nil {
		return 0, ErrRepositoryUnavailable
	}
	if limit < 1 || limit > MaxInboxCleanupBatch {
		return 0, NewPermanentError(ErrorCodePersistenceInvariant)
	}
	return s.repository.DeleteExpired(ctx, s.now().UTC(), limit)
}
