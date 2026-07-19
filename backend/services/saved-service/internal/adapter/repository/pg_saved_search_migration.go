package repository

import (
	"context"
	"errors"
	"fmt"
	"strconv"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	savedsearchmigration "kz/inflap/backend/services/saved-service/internal/app/savedsearchmigration"
)

const savedSearchParityPredicateSQL = `
       projections.search_title_en_v1 IS DISTINCT FROM saved_search_normalize_v1(projections.title_en)
    OR projections.search_title_ru_v1 IS DISTINCT FROM saved_search_normalize_v1(projections.title_ru)
    OR projections.search_title_kk_v1 IS DISTINCT FROM saved_search_normalize_v1(projections.title_kk)
    OR projections.search_city_en_v1 IS DISTINCT FROM saved_search_normalize_v1(projections.city_en)
    OR projections.search_city_ru_v1 IS DISTINCT FROM saved_search_normalize_v1(projections.city_ru)
    OR projections.search_city_kk_v1 IS DISTINCT FROM saved_search_normalize_v1(projections.city_kk)
    OR projections.search_country_en_v1 IS DISTINCT FROM saved_search_normalize_v1(projections.country_en)
    OR projections.search_country_ru_v1 IS DISTINCT FROM saved_search_normalize_v1(projections.country_ru)
    OR projections.search_country_kk_v1 IS DISTINCT FROM saved_search_normalize_v1(projections.country_kk)`

const savedSearchBackfillBatchSQL = `
WITH candidates AS MATERIALIZED (
    SELECT projections.entity_type, projections.entity_id
    FROM saved_content_projections AS projections
    WHERE (` + savedSearchParityPredicateSQL + `)
    ORDER BY projections.entity_type, projections.entity_id
    LIMIT $1
    FOR UPDATE SKIP LOCKED
), updated AS (
    UPDATE saved_content_projections AS projections
    SET search_title_en_v1 = saved_search_normalize_v1(projections.title_en),
        search_title_ru_v1 = saved_search_normalize_v1(projections.title_ru),
        search_title_kk_v1 = saved_search_normalize_v1(projections.title_kk),
        search_city_en_v1 = saved_search_normalize_v1(projections.city_en),
        search_city_ru_v1 = saved_search_normalize_v1(projections.city_ru),
        search_city_kk_v1 = saved_search_normalize_v1(projections.city_kk),
        search_country_en_v1 = saved_search_normalize_v1(projections.country_en),
        search_country_ru_v1 = saved_search_normalize_v1(projections.country_ru),
        search_country_kk_v1 = saved_search_normalize_v1(projections.country_kk)
    FROM candidates
    WHERE projections.entity_type = candidates.entity_type
      AND projections.entity_id = candidates.entity_id
    RETURNING 1
)
SELECT count(*)::bigint FROM updated`

const savedSearchPendingSQL = `
SELECT EXISTS (
    SELECT 1
    FROM saved_content_projections AS projections
    WHERE (` + savedSearchParityPredicateSQL + `)
)`

const savedSearchSchemaStatusSQL = `
SELECT
    COALESCE((
        SELECT count(*) = 9
           AND bool_and(attributes.attgenerated = '')
           AND bool_and(attributes.atttypid = 'text'::regtype)
        FROM pg_attribute AS attributes
        WHERE attributes.attrelid = 'saved_content_projections'::regclass
          AND attributes.attname = ANY($1::text[])
          AND attributes.attnum > 0
          AND NOT attributes.attisdropped
    ), FALSE),
    EXISTS (
        SELECT 1
        FROM pg_trigger AS triggers
        JOIN pg_proc AS functions ON functions.oid = triggers.tgfoid
        WHERE triggers.tgrelid = 'saved_content_projections'::regclass
          AND triggers.tgname = 'trg_saved_search_sync_projection_v1'
          AND NOT triggers.tgisinternal
          AND triggers.tgenabled IN ('O', 'A')
          AND functions.proname = 'saved_search_sync_projection_v1'
    ),
    EXISTS (
        SELECT 1
        FROM pg_constraint AS constraints
        WHERE constraints.conrelid = 'saved_content_projections'::regclass
          AND constraints.conname = 'saved_content_projections_search_parity_v1_check'
          AND constraints.contype = 'c'
    ),
    COALESCE((
        SELECT constraints.convalidated
        FROM pg_constraint AS constraints
        WHERE constraints.conrelid = 'saved_content_projections'::regclass
          AND constraints.conname = 'saved_content_projections_search_parity_v1_check'
          AND constraints.contype = 'c'
    ), FALSE),
    EXISTS (
        SELECT 1
        FROM pg_index AS indexes
        JOIN pg_class AS index_relations ON index_relations.oid = indexes.indexrelid
        WHERE indexes.indrelid = 'saved_items'::regclass
          AND index_relations.relname = 'idx_saved_items_active_owner_search_v1'
          AND indexes.indisready
          AND indexes.indisvalid
    ),
    EXISTS (
        SELECT 1
        FROM pg_index AS indexes
        JOIN pg_class AS index_relations ON index_relations.oid = indexes.indexrelid
        WHERE indexes.indrelid = 'saved_content_projections'::regclass
          AND index_relations.relname = 'idx_saved_content_projections_public_search_target_v1'
          AND indexes.indisready
          AND indexes.indisvalid
    ),
    EXISTS (
        SELECT 1
        FROM pg_index AS indexes
        JOIN pg_class AS index_relations ON index_relations.oid = indexes.indexrelid
        WHERE indexes.indrelid = 'saved_content_projections'::regclass
          AND index_relations.relname = 'idx_saved_content_projections_search_backfill_v1'
    ),
    EXISTS (
        SELECT 1
        FROM pg_index AS indexes
        JOIN pg_class AS index_relations ON index_relations.oid = indexes.indexrelid
        WHERE indexes.indrelid = 'saved_content_projections'::regclass
          AND index_relations.relname = 'idx_saved_content_projections_search_backfill_v1'
          AND indexes.indisready
          AND indexes.indisvalid
    )`

const savedSearchValidateContractSQL = `
ALTER TABLE saved_content_projections
VALIDATE CONSTRAINT saved_content_projections_search_parity_v1_check`

const savedSearchDropBackfillIndexSQL = `
DROP INDEX CONCURRENTLY IF EXISTS idx_saved_content_projections_search_backfill_v1`

const setSavedSearchMigrationTimeoutsSQL = `
SELECT set_config('lock_timeout', $1, TRUE),
       set_config('statement_timeout', $2, TRUE)`

const setSavedSearchMigrationSessionTimeoutsSQL = `
SELECT set_config('lock_timeout', $1, FALSE),
       set_config('statement_timeout', $2, FALSE)`

const resetSavedSearchMigrationSessionTimeoutsSQL = `
RESET lock_timeout;
RESET statement_timeout`

var savedSearchProjectionColumns = []string{
	"search_title_en_v1",
	"search_title_ru_v1",
	"search_title_kk_v1",
	"search_city_en_v1",
	"search_city_ru_v1",
	"search_city_kk_v1",
	"search_country_en_v1",
	"search_country_ru_v1",
	"search_country_kk_v1",
}

type SavedSearchMigrationOptions struct {
	LockTimeout      time.Duration
	StatementTimeout time.Duration
	ContractTimeout  time.Duration
}

func (o SavedSearchMigrationOptions) Validate() error {
	if o.LockTimeout < time.Millisecond || o.LockTimeout > 30*time.Second {
		return errors.New("saved search migration lock timeout must be between 1ms and 30s")
	}
	if o.StatementTimeout < time.Second || o.StatementTimeout > 5*time.Minute {
		return errors.New("saved search migration statement timeout must be between 1s and 5m")
	}
	if o.ContractTimeout < time.Second || o.ContractTimeout > 24*time.Hour {
		return errors.New("saved search migration contract timeout must be between 1s and 24h")
	}
	return nil
}

type PGSavedSearchMigrationRepository struct {
	pool    *pgxpool.Pool
	options SavedSearchMigrationOptions
}

func NewPGSavedSearchMigrationRepository(
	pool *pgxpool.Pool,
	options SavedSearchMigrationOptions,
) (*PGSavedSearchMigrationRepository, error) {
	if pool == nil {
		return nil, errors.New("saved search migration pool is required")
	}
	if err := options.Validate(); err != nil {
		return nil, err
	}
	return &PGSavedSearchMigrationRepository{pool: pool, options: options}, nil
}

func (r *PGSavedSearchMigrationRepository) BackfillBatch(
	ctx context.Context,
	batchSize int,
) (int64, error) {
	if ctx == nil || r == nil || r.pool == nil {
		return 0, errors.New("saved search migration repository is unavailable")
	}
	if batchSize < 1 || batchSize > savedsearchmigration.MaxBatchSize {
		return 0, fmt.Errorf("saved search backfill batch size must be between 1 and %d", savedsearchmigration.MaxBatchSize)
	}

	batchCtx, cancel := context.WithTimeout(ctx, r.options.StatementTimeout+r.options.LockTimeout+time.Second)
	defer cancel()
	tx, err := r.pool.BeginTx(batchCtx, pgx.TxOptions{})
	if err != nil {
		return 0, fmt.Errorf("begin saved search backfill batch: %w", err)
	}
	defer func() { _ = tx.Rollback(context.Background()) }()
	if err := setSavedSearchMigrationTimeouts(batchCtx, tx, r.options.LockTimeout, r.options.StatementTimeout); err != nil {
		return 0, err
	}

	var rows int64
	if err := tx.QueryRow(batchCtx, savedSearchBackfillBatchSQL, batchSize).Scan(&rows); err != nil {
		return 0, fmt.Errorf("execute saved search backfill batch: %w", err)
	}
	if rows < 0 || rows > int64(batchSize) {
		return 0, errors.New("saved search backfill returned an invalid row count")
	}
	if err := tx.Commit(batchCtx); err != nil {
		return 0, fmt.Errorf("commit saved search backfill batch: %w", err)
	}
	return rows, nil
}

func (r *PGSavedSearchMigrationRepository) Status(
	ctx context.Context,
) (savedsearchmigration.Status, error) {
	if ctx == nil || r == nil || r.pool == nil {
		return savedsearchmigration.Status{}, errors.New("saved search migration repository is unavailable")
	}
	statusCtx, cancel := context.WithTimeout(ctx, r.options.StatementTimeout+r.options.LockTimeout+time.Second)
	defer cancel()
	tx, err := r.pool.BeginTx(statusCtx, pgx.TxOptions{
		IsoLevel:   pgx.RepeatableRead,
		AccessMode: pgx.ReadOnly,
	})
	if err != nil {
		return savedsearchmigration.Status{}, fmt.Errorf("begin saved search status inspection: %w", err)
	}
	defer func() { _ = tx.Rollback(context.Background()) }()
	if err := setSavedSearchMigrationTimeouts(
		statusCtx,
		tx,
		r.options.LockTimeout,
		r.options.StatementTimeout,
	); err != nil {
		return savedsearchmigration.Status{}, err
	}

	status := savedsearchmigration.Status{}
	if err := tx.QueryRow(statusCtx, savedSearchSchemaStatusSQL, savedSearchProjectionColumns).Scan(
		&status.ColumnsReady,
		&status.TriggerReady,
		&status.ParityConstraintPresent,
		&status.ParityConstraintValidated,
		&status.OwnerIndexReady,
		&status.ProjectionIndexReady,
		&status.BackfillIndexPresent,
		&status.BackfillIndexReady,
	); err != nil {
		return savedsearchmigration.Status{}, fmt.Errorf("inspect saved search schema: %w", err)
	}
	if !status.ColumnsReady {
		status.Pending = true
		if err := tx.Commit(statusCtx); err != nil {
			return savedsearchmigration.Status{}, fmt.Errorf("commit saved search status inspection: %w", err)
		}
		return status, nil
	}
	if status.ParityConstraintValidated {
		status.Pending = false
		if err := tx.Commit(statusCtx); err != nil {
			return savedsearchmigration.Status{}, fmt.Errorf("commit saved search status inspection: %w", err)
		}
		return status, nil
	}
	if err := tx.QueryRow(statusCtx, savedSearchPendingSQL).Scan(&status.Pending); err != nil {
		return savedsearchmigration.Status{}, fmt.Errorf("inspect saved search parity: %w", err)
	}
	if err := tx.Commit(statusCtx); err != nil {
		return savedsearchmigration.Status{}, fmt.Errorf("commit saved search status inspection: %w", err)
	}
	return status, nil
}

func (r *PGSavedSearchMigrationRepository) ValidateContract(ctx context.Context) error {
	if ctx == nil || r == nil || r.pool == nil {
		return errors.New("saved search migration repository is unavailable")
	}
	contractCtx, cancel := context.WithTimeout(ctx, r.options.ContractTimeout+r.options.LockTimeout+time.Second)
	defer cancel()
	tx, err := r.pool.BeginTx(contractCtx, pgx.TxOptions{})
	if err != nil {
		return fmt.Errorf("begin saved search contract validation: %w", err)
	}
	defer func() { _ = tx.Rollback(context.Background()) }()
	if err := setSavedSearchMigrationTimeouts(contractCtx, tx, r.options.LockTimeout, r.options.ContractTimeout); err != nil {
		return err
	}
	if _, err := tx.Exec(contractCtx, savedSearchValidateContractSQL); err != nil {
		return fmt.Errorf("validate saved search parity constraint: %w", err)
	}
	if err := tx.Commit(contractCtx); err != nil {
		return fmt.Errorf("commit saved search contract validation: %w", err)
	}
	if err := r.dropBackfillIndex(ctx); err != nil {
		return err
	}
	return nil
}

func (r *PGSavedSearchMigrationRepository) dropBackfillIndex(ctx context.Context) error {
	dropCtx, cancel := context.WithTimeout(ctx, r.options.ContractTimeout+r.options.LockTimeout+time.Second)
	defer cancel()
	connection, err := r.pool.Acquire(dropCtx)
	if err != nil {
		return fmt.Errorf("acquire connection for saved search contract cleanup: %w", err)
	}
	defer connection.Release()
	if _, err := connection.Exec(
		dropCtx,
		setSavedSearchMigrationSessionTimeoutsSQL,
		postgresMilliseconds(r.options.LockTimeout),
		postgresMilliseconds(r.options.ContractTimeout),
	); err != nil {
		return fmt.Errorf("configure saved search contract cleanup timeouts: %w", err)
	}
	defer func() {
		cleanupCtx, cancel := context.WithTimeout(context.Background(), time.Second)
		defer cancel()
		_, _ = connection.Exec(cleanupCtx, resetSavedSearchMigrationSessionTimeoutsSQL)
	}()
	if _, err := connection.Exec(dropCtx, savedSearchDropBackfillIndexSQL); err != nil {
		return fmt.Errorf("drop saved search backfill index: %w", err)
	}
	return nil
}

func setSavedSearchMigrationTimeouts(
	ctx context.Context,
	tx pgx.Tx,
	lockTimeout time.Duration,
	statementTimeout time.Duration,
) error {
	if _, err := tx.Exec(
		ctx,
		setSavedSearchMigrationTimeoutsSQL,
		postgresMilliseconds(lockTimeout),
		postgresMilliseconds(statementTimeout),
	); err != nil {
		return fmt.Errorf("configure saved search migration timeouts: %w", err)
	}
	return nil
}

func postgresMilliseconds(duration time.Duration) string {
	milliseconds := duration.Milliseconds()
	if milliseconds < 1 {
		milliseconds = 1
	}
	return strconv.FormatInt(milliseconds, 10) + "ms"
}
