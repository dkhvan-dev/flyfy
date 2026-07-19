package repository

import (
	"context"
	"errors"
	"fmt"
	"math"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"kz/inflap/backend/services/switches-service/internal/platformpolicy/app"
)

const (
	readCurrentPolicySQL = `
		select revision, state, issued_at, valid_until, clock_timestamp()
		from platform_personal_data_policy_state
		where singleton_id = 1
	`
	lockCurrentPolicySQL = `
		select revision, state, issued_at, valid_until
		from platform_personal_data_policy_state
		where singleton_id = 1
		for update
	`
	readDatabaseTimeSQL = `select clock_timestamp()`
	leaseRenewalSQL     = `
		with lease as (
		    select clock_timestamp() as issued_at
		)
		update platform_personal_data_policy_state
		set revision = revision + 1,
		    issued_at = lease.issued_at,
		    valid_until = lease.issued_at + interval '20 seconds'
		from lease
		where singleton_id = 1
		  and revision < 9223372036854775807
		returning platform_personal_data_policy_state.revision,
		          platform_personal_data_policy_state.state,
		          platform_personal_data_policy_state.issued_at,
		          platform_personal_data_policy_state.valid_until
	`
	changePolicySQL = `
		with lease as (
		    select clock_timestamp() as issued_at
		)
		update platform_personal_data_policy_state
		set revision = revision + 1,
		    state = $1,
		    issued_at = lease.issued_at,
		    valid_until = lease.issued_at + interval '20 seconds',
		    changed_at = lease.issued_at,
		    actor = $2,
		    reason = $3,
		    change_ticket = $4
		from lease
		where singleton_id = 1
		  and revision = $5
		  and revision < 9223372036854775807
		returning platform_personal_data_policy_state.revision,
		          platform_personal_data_policy_state.state,
		          platform_personal_data_policy_state.issued_at,
		          platform_personal_data_policy_state.valid_until
	`
	appendHistorySQL = `
		insert into platform_personal_data_policy_history (
		    revision,
		    previous_revision,
		    previous_state,
		    state,
		    issued_at,
		    valid_until,
		    changed_at,
		    actor,
		    reason,
		    change_ticket
		)
		values ($1, $2, $3, $4, $5, $6, $5, $7, $8, $9)
	`
)

type row interface {
	Scan(dest ...any) error
}

type transaction interface {
	QueryRow(ctx context.Context, sql string, args ...any) row
	Exec(ctx context.Context, sql string, args ...any) error
	Commit(ctx context.Context) error
	Rollback(ctx context.Context) error
}

type database interface {
	QueryRow(ctx context.Context, sql string, args ...any) row
	Begin(ctx context.Context) (transaction, error)
}

type poolDatabase struct {
	pool *pgxpool.Pool
}

func (database poolDatabase) QueryRow(ctx context.Context, sql string, args ...any) row {
	return database.pool.QueryRow(ctx, sql, args...)
}

func (database poolDatabase) Begin(ctx context.Context) (transaction, error) {
	tx, err := database.pool.BeginTx(ctx, pgx.TxOptions{IsoLevel: pgx.ReadCommitted})
	if err != nil {
		return nil, err
	}
	return pgTransaction{tx: tx}, nil
}

type pgTransaction struct {
	tx pgx.Tx
}

func (transaction pgTransaction) QueryRow(ctx context.Context, sql string, args ...any) row {
	return transaction.tx.QueryRow(ctx, sql, args...)
}

func (transaction pgTransaction) Exec(ctx context.Context, sql string, args ...any) error {
	_, err := transaction.tx.Exec(ctx, sql, args...)
	return err
}

func (transaction pgTransaction) Commit(ctx context.Context) error {
	return transaction.tx.Commit(ctx)
}

func (transaction pgTransaction) Rollback(ctx context.Context) error {
	return transaction.tx.Rollback(ctx)
}

type PGRepository struct {
	database database
}

func NewPGRepository(pool *pgxpool.Pool) *PGRepository {
	if pool == nil {
		return &PGRepository{}
	}
	return &PGRepository{database: poolDatabase{pool: pool}}
}

func newPGRepository(database database) *PGRepository {
	return &PGRepository{database: database}
}

// ReadDecision performs an authoritative database read on every call. A lease
// is renewed under a row lock only when it approaches expiry, which keeps one
// revision bound to one exact issued_at/valid_until pair.
func (repository *PGRepository) ReadDecision(ctx context.Context) (app.Decision, error) {
	if repository == nil || repository.database == nil {
		return app.Decision{}, errors.New("platform policy database is unavailable")
	}

	decision, databaseNow, err := scanCurrentPolicy(repository.database.QueryRow(ctx, readCurrentPolicySQL))
	if err != nil {
		return app.Decision{}, fmt.Errorf("read platform policy: %w", err)
	}
	if leaseIsFresh(decision, databaseNow) {
		return decision, nil
	}

	return repository.renewDecision(ctx)
}

func (repository *PGRepository) renewDecision(ctx context.Context) (app.Decision, error) {
	tx, err := repository.database.Begin(ctx)
	if err != nil {
		return app.Decision{}, fmt.Errorf("begin platform policy lease renewal: %w", err)
	}
	committed := false
	defer rollbackUnlessCommitted(tx, &committed)

	decision, err := scanDecision(tx.QueryRow(ctx, lockCurrentPolicySQL))
	if err != nil {
		return app.Decision{}, fmt.Errorf("lock platform policy for lease renewal: %w", err)
	}
	databaseNow, err := scanTime(tx.QueryRow(ctx, readDatabaseTimeSQL))
	if err != nil {
		return app.Decision{}, fmt.Errorf("read database time for lease renewal: %w", err)
	}
	if !leaseIsFresh(decision, databaseNow) {
		decision, err = scanDecision(tx.QueryRow(ctx, leaseRenewalSQL))
		if err != nil {
			return app.Decision{}, fmt.Errorf("renew platform policy lease: %w", err)
		}
	}
	if err = tx.Commit(ctx); err != nil {
		return app.Decision{}, fmt.Errorf("commit platform policy lease renewal: %w", err)
	}
	committed = true
	return decision, nil
}

func (repository *PGRepository) ChangeState(ctx context.Context, command app.ChangeCommand) (app.Decision, error) {
	if repository == nil || repository.database == nil {
		return app.Decision{}, errors.New("platform policy database is unavailable")
	}
	if command.ExpectedRevision == 0 || command.ExpectedRevision > math.MaxInt64 || !command.State.Valid() {
		return app.Decision{}, app.ErrInvalidCommand
	}

	tx, err := repository.database.Begin(ctx)
	if err != nil {
		return app.Decision{}, fmt.Errorf("begin platform policy change: %w", err)
	}
	committed := false
	defer rollbackUnlessCommitted(tx, &committed)

	current, err := scanDecision(tx.QueryRow(ctx, lockCurrentPolicySQL))
	if err != nil {
		return app.Decision{}, fmt.Errorf("lock platform policy for change: %w", err)
	}
	if current.Revision != command.ExpectedRevision {
		return app.Decision{}, app.ErrRevisionConflict
	}
	if current.State == command.State {
		return app.Decision{}, app.ErrStateUnchanged
	}

	updated, err := scanDecision(tx.QueryRow(
		ctx,
		changePolicySQL,
		command.State,
		command.Actor,
		command.Reason,
		command.ChangeTicket,
		int64(command.ExpectedRevision),
	))
	if errors.Is(err, pgx.ErrNoRows) {
		return app.Decision{}, app.ErrRevisionConflict
	}
	if err != nil {
		return app.Decision{}, fmt.Errorf("update platform policy: %w", err)
	}

	if err = tx.Exec(
		ctx,
		appendHistorySQL,
		int64(updated.Revision),
		int64(current.Revision),
		current.State,
		updated.State,
		updated.IssuedAt,
		updated.ValidUntil,
		command.Actor,
		command.Reason,
		command.ChangeTicket,
	); err != nil {
		return app.Decision{}, fmt.Errorf("append platform policy history: %w", err)
	}
	if err = tx.Commit(ctx); err != nil {
		return app.Decision{}, fmt.Errorf("commit platform policy change: %w", err)
	}
	committed = true
	return updated, nil
}

func scanCurrentPolicy(result row) (app.Decision, time.Time, error) {
	var (
		revision    int64
		state       string
		issuedAt    time.Time
		validUntil  time.Time
		databaseNow time.Time
	)
	if err := result.Scan(&revision, &state, &issuedAt, &validUntil, &databaseNow); err != nil {
		return app.Decision{}, time.Time{}, err
	}
	decision, err := decisionFromDatabase(revision, state, issuedAt, validUntil)
	if err != nil {
		return app.Decision{}, time.Time{}, err
	}
	if databaseNow.IsZero() {
		return app.Decision{}, time.Time{}, errors.New("database timestamp is missing")
	}
	return decision, databaseNow, nil
}

func scanDecision(result row) (app.Decision, error) {
	var (
		revision   int64
		state      string
		issuedAt   time.Time
		validUntil time.Time
	)
	if err := result.Scan(&revision, &state, &issuedAt, &validUntil); err != nil {
		return app.Decision{}, err
	}
	return decisionFromDatabase(revision, state, issuedAt, validUntil)
}

func scanTime(result row) (time.Time, error) {
	var value time.Time
	if err := result.Scan(&value); err != nil {
		return time.Time{}, err
	}
	if value.IsZero() {
		return time.Time{}, errors.New("database timestamp is missing")
	}
	return value, nil
}

func decisionFromDatabase(revision int64, state string, issuedAt time.Time, validUntil time.Time) (app.Decision, error) {
	decision := app.Decision{
		Revision:   uint64(revision),
		State:      app.State(state),
		IssuedAt:   issuedAt.UTC(),
		ValidUntil: validUntil.UTC(),
	}
	window := decision.ValidUntil.Sub(decision.IssuedAt)
	if revision <= 0 || !decision.State.Valid() || decision.IssuedAt.IsZero() ||
		window <= 0 || window > app.MaxValidityWindow {
		return app.Decision{}, errors.New("database contains an invalid platform policy decision")
	}
	return decision, nil
}

func leaseIsFresh(decision app.Decision, databaseNow time.Time) bool {
	return databaseNow.Before(decision.ValidUntil.Add(-app.RenewalLeadTime))
}

func rollbackUnlessCommitted(tx transaction, committed *bool) {
	if tx == nil || committed == nil || *committed {
		return
	}
	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()
	_ = tx.Rollback(ctx)
}

var _ app.Repository = (*PGRepository)(nil)
var _ transaction = pgTransaction{}
