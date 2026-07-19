package repository

import (
	"context"
	"errors"
	"fmt"
	"strings"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"

	savedmaintenance "kz/inflap/backend/services/saved-service/internal/app/savedmaintenance"
)

var ErrInvalidSavedMaintenanceDependencies = errors.New("invalid PostgreSQL saved maintenance dependencies")

type PGSavedMaintenanceRepository struct {
	pool *pgxpool.Pool
}

var _ savedmaintenance.Repository = (*PGSavedMaintenanceRepository)(nil)

func NewPGSavedMaintenanceRepository(pool *pgxpool.Pool) (*PGSavedMaintenanceRepository, error) {
	if pool == nil {
		return nil, ErrInvalidSavedMaintenanceDependencies
	}
	return &PGSavedMaintenanceRepository{pool: pool}, nil
}

func (r *PGSavedMaintenanceRepository) ExpirePendingOperations(
	ctx context.Context,
	request savedmaintenance.BatchRequest,
) (savedmaintenance.BatchResult, error) {
	return r.runMaintenanceBatch(
		ctx,
		"expire pending operations",
		request,
		expirePendingSavedOperationsSQL,
		request.Now.UTC(),
		request.Now.Add(request.OperationRetention).UTC(),
		request.Limit,
	)
}

func (r *PGSavedMaintenanceRepository) PurgeTerminalOperations(
	ctx context.Context,
	request savedmaintenance.BatchRequest,
) (savedmaintenance.BatchResult, error) {
	return r.runMaintenanceBatch(
		ctx,
		"purge terminal operations",
		request,
		purgeTerminalSavedOperationsSQL,
		request.Now.UTC(),
		request.Now.Add(-request.OperationRetention).UTC(),
		request.Limit,
	)
}

func (r *PGSavedMaintenanceRepository) PurgeTerminalOutbox(
	ctx context.Context,
	request savedmaintenance.BatchRequest,
) (savedmaintenance.BatchResult, error) {
	return r.runMaintenanceBatch(
		ctx,
		"purge terminal outbox",
		request,
		purgeTerminalSavedOutboxSQL,
		request.Now.UTC(),
		request.Limit,
	)
}

func (r *PGSavedMaintenanceRepository) PurgeInboxDedup(
	ctx context.Context,
	request savedmaintenance.BatchRequest,
) (savedmaintenance.BatchResult, error) {
	return r.runMaintenanceBatch(
		ctx,
		"purge inbox dedup",
		request,
		purgeSavedInboxDedupSQL,
		request.Now.UTC(),
		request.Limit,
	)
}

func (r *PGSavedMaintenanceRepository) CleanupDeletedCollectionChildren(
	ctx context.Context,
	request savedmaintenance.BatchRequest,
) (savedmaintenance.BatchResult, error) {
	return r.runMaintenanceBatch(
		ctx,
		"cleanup deleted collection children",
		request,
		cleanupDeletedCollectionChildrenSQL,
		request.Limit,
	)
}

func (r *PGSavedMaintenanceRepository) PurgeRemovedCollectionItems(
	ctx context.Context,
	request savedmaintenance.BatchRequest,
) (savedmaintenance.BatchResult, error) {
	return r.runMaintenanceBatch(
		ctx,
		"purge removed collection items",
		request,
		purgeRemovedCollectionItemsSQL,
		request.Now.UTC(),
		request.Limit,
	)
}

func (r *PGSavedMaintenanceRepository) PurgeDeletedCollections(
	ctx context.Context,
	request savedmaintenance.BatchRequest,
) (savedmaintenance.BatchResult, error) {
	return r.runMaintenanceBatch(
		ctx,
		"purge deleted collections",
		request,
		purgeDeletedSavedCollectionsSQL,
		request.Now.UTC(),
		request.Limit,
	)
}

func (r *PGSavedMaintenanceRepository) PurgeRemovedSavedItems(
	ctx context.Context,
	request savedmaintenance.BatchRequest,
) (savedmaintenance.BatchResult, error) {
	return r.runMaintenanceBatch(
		ctx,
		"purge removed saved items",
		request,
		purgeRemovedSavedItemsSQL,
		request.Now.UTC(),
		request.Limit,
	)
}

func (r *PGSavedMaintenanceRepository) MarkProjectionGCCandidates(
	ctx context.Context,
	request savedmaintenance.BatchRequest,
) (savedmaintenance.BatchResult, error) {
	return r.runMaintenanceBatch(
		ctx,
		"mark projection GC candidates",
		request,
		markSavedProjectionGCCandidatesSQL,
		request.Now.UTC(),
		request.Limit,
	)
}

func (r *PGSavedMaintenanceRepository) PurgeEphemeralProjections(
	ctx context.Context,
	request savedmaintenance.BatchRequest,
) (savedmaintenance.BatchResult, error) {
	return r.runMaintenanceBatch(
		ctx,
		"purge ephemeral projections",
		request,
		purgeEphemeralSavedProjectionsSQL,
		request.Now.UTC(),
		request.Limit,
	)
}

func (r *PGSavedMaintenanceRepository) PurgeStandardProjections(
	ctx context.Context,
	request savedmaintenance.BatchRequest,
) (savedmaintenance.BatchResult, error) {
	return r.runMaintenanceBatch(
		ctx,
		"purge standard projections",
		request,
		purgeStandardSavedProjectionsSQL,
		request.Now.Add(-request.ProjectionRetention).UTC(),
		request.Limit,
	)
}

func (r *PGSavedMaintenanceRepository) PurgeCompletedSubjectPurges(
	ctx context.Context,
	request savedmaintenance.BatchRequest,
) (savedmaintenance.BatchResult, error) {
	return r.runMaintenanceBatch(
		ctx,
		"purge completed subject purges",
		request,
		purgeCompletedSubjectPurgesSQL,
		request.Now.UTC(),
		request.Limit,
	)
}

func (r *PGSavedMaintenanceRepository) runMaintenanceBatch(
	ctx context.Context,
	operation string,
	request savedmaintenance.BatchRequest,
	query string,
	arguments ...any,
) (savedmaintenance.BatchResult, error) {
	if err := ctx.Err(); err != nil {
		return savedmaintenance.BatchResult{}, err
	}
	if r == nil || r.pool == nil {
		return savedmaintenance.BatchResult{}, ErrInvalidSavedMaintenanceDependencies
	}
	if err := request.Validate(); err != nil {
		return savedmaintenance.BatchResult{}, err
	}

	tx, err := r.pool.BeginTx(ctx, pgx.TxOptions{
		IsoLevel:   pgx.ReadCommitted,
		AccessMode: pgx.ReadWrite,
	})
	if err != nil {
		return savedmaintenance.BatchResult{}, mapSavedMaintenanceError(operation, err)
	}
	defer func() { _ = tx.Rollback(context.Background()) }()

	var affected int64
	if err := tx.QueryRow(ctx, query, arguments...).Scan(&affected); err != nil {
		return savedmaintenance.BatchResult{}, mapSavedMaintenanceError(operation, err)
	}
	result := savedmaintenance.BatchResult{
		Affected: affected,
		HasMore:  affected == int64(request.Limit),
	}
	if err := result.Validate(request.Limit); err != nil {
		return savedmaintenance.BatchResult{}, savedmaintenance.NewError(
			operation,
			savedmaintenance.ErrorKindInvariant,
			false,
			err,
		)
	}
	if err := tx.Commit(ctx); err != nil {
		return savedmaintenance.BatchResult{}, mapSavedMaintenanceError(operation, err)
	}
	return result, nil
}

func mapSavedMaintenanceError(operation string, err error) error {
	if err == nil {
		return nil
	}
	if errors.Is(err, context.Canceled) || errors.Is(err, context.DeadlineExceeded) {
		return err
	}

	var postgresError *pgconn.PgError
	if !errors.As(err, &postgresError) {
		return savedmaintenance.NewError(
			operation,
			savedmaintenance.ErrorKindUnavailable,
			true,
			err,
		)
	}

	switch postgresError.Code {
	case "40001", "40P01", "55P03", "57014":
		return savedmaintenance.NewError(
			operation,
			savedmaintenance.ErrorKindContention,
			true,
			postgresError,
		)
	}
	if strings.HasPrefix(postgresError.Code, "08") || strings.HasPrefix(postgresError.Code, "53") ||
		postgresError.Code == "57P01" || postgresError.Code == "57P02" || postgresError.Code == "57P03" {
		return savedmaintenance.NewError(
			operation,
			savedmaintenance.ErrorKindUnavailable,
			true,
			postgresError,
		)
	}
	if strings.HasPrefix(postgresError.Code, "22") || strings.HasPrefix(postgresError.Code, "23") ||
		strings.HasPrefix(postgresError.Code, "42") {
		return savedmaintenance.NewError(
			operation,
			savedmaintenance.ErrorKindInvariant,
			false,
			postgresError,
		)
	}
	return savedmaintenance.NewError(
		operation,
		savedmaintenance.ErrorKindUnavailable,
		true,
		fmt.Errorf("postgres SQLSTATE %s: %w", postgresError.Code, postgresError),
	)
}
