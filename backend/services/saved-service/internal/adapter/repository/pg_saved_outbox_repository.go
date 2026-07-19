package repository

import (
	"context"
	"errors"
	"fmt"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"

	savedoutbox "kz/inflap/backend/services/saved-service/internal/app/savedoutbox"
	"kz/inflap/backend/services/saved-service/internal/domain"
)

type PGSavedOutboxRepository struct {
	pool *pgxpool.Pool
}

var _ savedoutbox.Repository = (*PGSavedOutboxRepository)(nil)

func NewPGSavedOutboxRepository(pool *pgxpool.Pool) (*PGSavedOutboxRepository, error) {
	if pool == nil {
		return nil, savedoutbox.ErrInvalidDependencies
	}
	return &PGSavedOutboxRepository{pool: pool}, nil
}

func (repository *PGSavedOutboxRepository) RecoverStaleLeases(
	ctx context.Context,
	request savedoutbox.RecoveryRequest,
) (savedoutbox.RecoveryResult, error) {
	if err := validateSavedOutboxRepositoryCall(ctx, repository); err != nil {
		return savedoutbox.RecoveryResult{}, err
	}
	if err := request.Validate(); err != nil {
		return savedoutbox.RecoveryResult{}, err
	}

	var released, dead int64
	err := repository.pool.QueryRow(
		ctx,
		recoverStaleSavedOutboxLeasesSQL,
		request.Now.UTC(),
		request.LeaseExpiredBefore.UTC(),
		request.MaxAttempts,
		request.Limit,
		request.TerminalExpiresAt.UTC(),
		string(savedoutbox.FailureAttemptsExhausted),
		string(savedoutbox.FailureLeaseExpired),
	).Scan(&released, &dead)
	if err != nil {
		return savedoutbox.RecoveryResult{}, mapSavedOutboxPGError(err)
	}
	if released < 0 || dead < 0 || released+dead > int64(request.Limit) {
		return savedoutbox.RecoveryResult{}, savedoutbox.ErrPersistenceInvariant
	}
	return savedoutbox.RecoveryResult{Released: int(released), Dead: int(dead)}, nil
}

func (repository *PGSavedOutboxRepository) ClaimDue(
	ctx context.Context,
	request savedoutbox.ClaimRequest,
) ([]savedoutbox.ClaimedRecord, error) {
	if err := validateSavedOutboxRepositoryCall(ctx, repository); err != nil {
		return nil, err
	}
	if err := request.Validate(); err != nil {
		return nil, err
	}

	rows, err := repository.pool.Query(
		ctx,
		claimDueSavedOutboxSQL,
		request.Now.UTC(),
		request.MaxAttempts,
		request.Limit,
	)
	if err != nil {
		return nil, mapSavedOutboxPGError(err)
	}
	defer rows.Close()

	claimed := make([]savedoutbox.ClaimedRecord, 0, request.Limit)
	for rows.Next() {
		var record savedoutbox.ClaimedRecord
		var eventType, entityType string
		var attempt int32
		if err = rows.Scan(
			&record.Lease.EventID,
			&record.SchemaVersion,
			&eventType,
			&entityType,
			&record.OccurredAt,
			&attempt,
			&record.Lease.AcquiredAt,
		); err != nil {
			return nil, mapSavedOutboxScanError(err)
		}
		record.Kind = savedoutbox.EventKind(eventType)
		record.EntityType = domain.EntityType(entityType)
		record.OccurredAt = record.OccurredAt.UTC()
		record.Lease.AcquiredAt = record.Lease.AcquiredAt.UTC()
		record.Lease.Attempt = int(attempt)
		if err = record.Lease.Validate(); err != nil || record.Lease.Attempt > request.MaxAttempts {
			return nil, savedoutbox.ErrPersistenceInvariant
		}
		claimed = append(claimed, record)
	}
	if err = rows.Err(); err != nil {
		return nil, mapSavedOutboxPGError(err)
	}
	return claimed, nil
}

func (repository *PGSavedOutboxRepository) MarkDelivered(
	ctx context.Context,
	delivery savedoutbox.Delivery,
) error {
	if err := validateSavedOutboxRepositoryCall(ctx, repository); err != nil {
		return err
	}
	if err := delivery.Validate(); err != nil {
		return err
	}
	tag, err := repository.pool.Exec(
		ctx,
		markSavedOutboxDeliveredSQL,
		delivery.Lease.EventID,
		delivery.Lease.AcquiredAt.UTC(),
		delivery.Lease.Attempt,
		delivery.DeliveredAt.UTC(),
		delivery.RetainUntil.UTC(),
	)
	if err != nil {
		return mapSavedOutboxPGError(err)
	}
	if tag.RowsAffected() != 1 {
		return savedoutbox.ErrLeaseLost
	}
	return nil
}

func (repository *PGSavedOutboxRepository) MarkFailed(
	ctx context.Context,
	failure savedoutbox.Failure,
) (savedoutbox.FailureDisposition, error) {
	if err := validateSavedOutboxRepositoryCall(ctx, repository); err != nil {
		return "", err
	}
	if err := failure.Validate(); err != nil {
		return "", err
	}

	var status string
	err := repository.pool.QueryRow(
		ctx,
		markSavedOutboxFailedSQL,
		failure.Lease.EventID,
		failure.Lease.AcquiredAt.UTC(),
		failure.Lease.Attempt,
		failure.FailedAt.UTC(),
		failure.NextAttemptAt.UTC(),
		failure.RetainUntil.UTC(),
		failure.MaxAttempts,
		string(failure.Code),
		failure.Permanent,
	).Scan(&status)
	if errors.Is(err, pgx.ErrNoRows) {
		return "", savedoutbox.ErrLeaseLost
	}
	if err != nil {
		return "", mapSavedOutboxPGError(err)
	}

	disposition := savedoutbox.FailureRetryScheduled
	if status == "DEAD" {
		disposition = savedoutbox.FailureDead
	} else if status != "PENDING" {
		return "", savedoutbox.ErrPersistenceInvariant
	}
	if (disposition == savedoutbox.FailureDead) != failure.MustBecomeDead() {
		return "", savedoutbox.ErrPersistenceInvariant
	}
	return disposition, nil
}

func (repository *PGSavedOutboxRepository) DeleteExpired(
	ctx context.Context,
	request savedoutbox.CleanupRequest,
) (int64, error) {
	if err := validateSavedOutboxRepositoryCall(ctx, repository); err != nil {
		return 0, err
	}
	if err := request.Validate(); err != nil {
		return 0, err
	}

	var deleted int64
	if err := repository.pool.QueryRow(
		ctx,
		deleteExpiredSavedOutboxSQL,
		request.Now.UTC(),
		request.Limit,
	).Scan(&deleted); err != nil {
		return 0, mapSavedOutboxPGError(err)
	}
	if deleted < 0 || deleted > int64(request.Limit) {
		return 0, savedoutbox.ErrPersistenceInvariant
	}
	return deleted, nil
}

func validateSavedOutboxRepositoryCall(
	ctx context.Context,
	repository *PGSavedOutboxRepository,
) error {
	if ctx == nil {
		return savedoutbox.ErrInvalidRequest
	}
	if err := ctx.Err(); err != nil {
		return err
	}
	if repository == nil || repository.pool == nil {
		return savedoutbox.ErrRepositoryUnavailable
	}
	return nil
}

func mapSavedOutboxPGError(err error) error {
	if err == nil {
		return nil
	}
	if errors.Is(err, context.Canceled) || errors.Is(err, context.DeadlineExceeded) {
		return err
	}
	var postgresError *pgconn.PgError
	if errors.As(err, &postgresError) {
		switch postgresError.Code {
		case "22003", "22007", "22008", "22P02", "23502", "23503", "23505", "23514":
			return savedoutbox.ErrPersistenceInvariant
		}
		return fmt.Errorf("%w (postgres SQLSTATE %s)", savedoutbox.ErrRepositoryUnavailable, postgresError.Code)
	}
	return savedoutbox.ErrRepositoryUnavailable
}

func mapSavedOutboxScanError(err error) error {
	if errors.Is(err, context.Canceled) || errors.Is(err, context.DeadlineExceeded) {
		return err
	}
	return savedoutbox.ErrPersistenceInvariant
}
