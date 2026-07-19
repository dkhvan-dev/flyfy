package repository

import (
	"context"
	"errors"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"

	savedcapabilityapp "kz/inflap/backend/services/saved-service/internal/app/savedcapability"
)

const getSavedCapabilityUsageSQL = `
SELECT
    COALESCE((
        SELECT active_saved_items_count
        FROM saved_user_usage
        WHERE owner_user_id = $1
    ), 0),
    COALESCE((
        SELECT active_collections_count
        FROM saved_collection_usage
        WHERE owner_user_id = $1
    ), 0),
    GREATEST(
        COALESCE((
            SELECT usage_version
            FROM saved_user_usage
            WHERE owner_user_id = $1
        ), 0),
        COALESCE((
            SELECT usage_version
            FROM saved_collection_usage
            WHERE owner_user_id = $1
        ), 0)
    )`

type PGSavedCapabilityRepository struct {
	pool *pgxpool.Pool
}

var _ savedcapabilityapp.Repository = (*PGSavedCapabilityRepository)(nil)

func NewPGSavedCapabilityRepository(pool *pgxpool.Pool) (*PGSavedCapabilityRepository, error) {
	if pool == nil {
		return nil, savedcapabilityapp.ErrInvalidConfiguration
	}
	return &PGSavedCapabilityRepository{pool: pool}, nil
}

func (repository *PGSavedCapabilityRepository) GetUsage(
	ctx context.Context,
	ownerUserID uuid.UUID,
) (savedcapabilityapp.Usage, error) {
	if repository == nil || repository.pool == nil || ctx == nil || ownerUserID == uuid.Nil {
		return savedcapabilityapp.Usage{}, savedcapabilityapp.ErrInvalidRequest
	}
	var activeSavedItems int64
	var activeCollections int64
	var usageVersion int64
	if err := repository.pool.QueryRow(ctx, getSavedCapabilityUsageSQL, ownerUserID).Scan(
		&activeSavedItems,
		&activeCollections,
		&usageVersion,
	); err != nil {
		return savedcapabilityapp.Usage{}, mapSavedCapabilityPGError(err)
	}
	if activeSavedItems < 0 || activeCollections < 0 || usageVersion < 0 {
		return savedcapabilityapp.Usage{}, savedcapabilityapp.ErrDataInvariant
	}
	return savedcapabilityapp.Usage{
		ActiveSavedItems:  uint64(activeSavedItems),
		ActiveCollections: uint64(activeCollections),
		UsageVersion:      uint64(usageVersion),
	}, nil
}

func mapSavedCapabilityPGError(err error) error {
	if errors.Is(err, context.Canceled) || errors.Is(err, context.DeadlineExceeded) {
		return err
	}
	var postgresError *pgconn.PgError
	if errors.As(err, &postgresError) &&
		(postgresError.Code == "22003" || postgresError.Code == "23514") {
		return savedcapabilityapp.ErrDataInvariant
	}
	return savedcapabilityapp.ErrRepositoryUnavailable
}
