package repository

import (
	"context"
	"errors"
	"strings"
	"testing"
	"time"

	"kz/inflap/backend/services/switches-service/internal/platformpolicy/app"
)

func TestReadDecisionUsesFreshDatabaseLeaseWithoutTransaction(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, 7, 16, 10, 0, 0, 0, time.UTC)
	database := &fakeDatabase{
		rows: []row{currentRow(7, app.StateAvailable, now.Add(-time.Second), now.Add(19*time.Second), now)},
	}
	repository := newPGRepository(database)

	decision, err := repository.ReadDecision(context.Background())
	if err != nil {
		t.Fatalf("ReadDecision() error = %v", err)
	}
	if decision.Revision != 7 || decision.State != app.StateAvailable {
		t.Fatalf("decision = %#v", decision)
	}
	if database.beginCalls != 0 {
		t.Fatalf("begin calls = %d, want 0", database.beginCalls)
	}
	if len(database.queries) != 1 || strings.Contains(strings.ToLower(database.queries[0]), "for update") {
		t.Fatalf("initial queries = %#v", database.queries)
	}
}

func TestReadDecisionRenewsExpiringLeaseUnderLock(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, 7, 16, 10, 0, 0, 0, time.UTC)
	tx := &fakeTransaction{rows: []row{
		decisionRow(7, app.StateAvailable, now.Add(-15*time.Second), now.Add(4*time.Second)),
		timeRow(now),
		decisionRow(8, app.StateAvailable, now, now.Add(app.DecisionValidity)),
	}}
	database := &fakeDatabase{
		rows: []row{currentRow(7, app.StateAvailable, now.Add(-15*time.Second), now.Add(4*time.Second), now)},
		tx:   tx,
	}
	repository := newPGRepository(database)

	decision, err := repository.ReadDecision(context.Background())
	if err != nil {
		t.Fatalf("ReadDecision() error = %v", err)
	}
	if decision.Revision != 8 || !tx.committed {
		t.Fatalf("decision = %#v, committed = %t", decision, tx.committed)
	}
	if len(tx.queries) != 3 || !strings.Contains(strings.ToLower(tx.queries[0]), "for update") ||
		!strings.Contains(strings.ToLower(tx.queries[1]), "clock_timestamp") ||
		!strings.Contains(strings.ToLower(tx.queries[2]), "set revision = revision + 1") {
		t.Fatalf("transaction queries = %#v", tx.queries)
	}
}

func TestChangeStateRejectsRevisionConflictBeforeWriting(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, 7, 16, 10, 0, 0, 0, time.UTC)
	tx := &fakeTransaction{rows: []row{
		decisionRow(9, app.StateAvailable, now, now.Add(app.DecisionValidity)),
	}}
	repository := newPGRepository(&fakeDatabase{tx: tx})

	_, err := repository.ChangeState(context.Background(), app.ChangeCommand{
		ExpectedRevision: 8,
		State:            app.StateLocked,
		Actor:            "admin",
		Reason:           "incident",
		ChangeTicket:     "INC-1",
	})
	if !errors.Is(err, app.ErrRevisionConflict) {
		t.Fatalf("ChangeState() error = %v, want revision conflict", err)
	}
	if len(tx.queries) != 1 || len(tx.execs) != 0 || tx.committed || !tx.rolledBack {
		t.Fatalf("transaction state = %+v", tx)
	}
}

func TestChangeStateRejectsSameStateDeterministically(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, 7, 16, 10, 0, 0, 0, time.UTC)
	tx := &fakeTransaction{rows: []row{
		decisionRow(9, app.StateLocked, now, now.Add(app.DecisionValidity)),
	}}
	repository := newPGRepository(&fakeDatabase{tx: tx})

	_, err := repository.ChangeState(context.Background(), app.ChangeCommand{
		ExpectedRevision: 9,
		State:            app.StateLocked,
		Actor:            "admin",
		Reason:           "incident",
		ChangeTicket:     "INC-1",
	})
	if !errors.Is(err, app.ErrStateUnchanged) {
		t.Fatalf("ChangeState() error = %v, want state unchanged", err)
	}
	if len(tx.queries) != 1 || len(tx.execs) != 0 || tx.committed || !tx.rolledBack {
		t.Fatalf("transaction state = %+v", tx)
	}
}

func TestChangeStateUpdatesAndAppendsHistoryInOneTransaction(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, 7, 16, 10, 0, 0, 0, time.UTC)
	tx := &fakeTransaction{rows: []row{
		decisionRow(9, app.StateAvailable, now.Add(-time.Second), now.Add(19*time.Second)),
		decisionRow(10, app.StateLocked, now, now.Add(app.DecisionValidity)),
	}}
	repository := newPGRepository(&fakeDatabase{tx: tx})

	decision, err := repository.ChangeState(context.Background(), app.ChangeCommand{
		ExpectedRevision: 9,
		State:            app.StateLocked,
		Actor:            "admin-subject",
		Reason:           "incident response",
		ChangeTicket:     "INC-123",
	})
	if err != nil {
		t.Fatalf("ChangeState() error = %v", err)
	}
	if decision.Revision != 10 || decision.State != app.StateLocked || !tx.committed {
		t.Fatalf("decision = %#v, committed = %t", decision, tx.committed)
	}
	if len(tx.queries) != 2 || len(tx.execs) != 1 {
		t.Fatalf("queries = %d, execs = %d", len(tx.queries), len(tx.execs))
	}
	if !strings.Contains(strings.ToLower(tx.execs[0]), "platform_personal_data_policy_history") {
		t.Fatalf("history statement = %q", tx.execs[0])
	}
	if got := tx.execArgs[0]; len(got) != 9 || got[0] != int64(10) || got[1] != int64(9) {
		t.Fatalf("history args = %#v", got)
	}
}

type fakeDatabase struct {
	rows       []row
	tx         *fakeTransaction
	queries    []string
	beginCalls int
}

func (database *fakeDatabase) QueryRow(_ context.Context, query string, _ ...any) row {
	database.queries = append(database.queries, query)
	if len(database.rows) == 0 {
		return errorRow{err: errors.New("unexpected database query")}
	}
	result := database.rows[0]
	database.rows = database.rows[1:]
	return result
}

func (database *fakeDatabase) Begin(context.Context) (transaction, error) {
	database.beginCalls++
	if database.tx == nil {
		return nil, errors.New("unexpected transaction")
	}
	return database.tx, nil
}

type fakeTransaction struct {
	rows       []row
	queries    []string
	execs      []string
	execArgs   [][]any
	committed  bool
	rolledBack bool
}

func (tx *fakeTransaction) QueryRow(_ context.Context, query string, _ ...any) row {
	tx.queries = append(tx.queries, query)
	if len(tx.rows) == 0 {
		return errorRow{err: errors.New("unexpected transaction query")}
	}
	result := tx.rows[0]
	tx.rows = tx.rows[1:]
	return result
}

func (tx *fakeTransaction) Exec(_ context.Context, query string, args ...any) error {
	tx.execs = append(tx.execs, query)
	tx.execArgs = append(tx.execArgs, args)
	return nil
}

func (tx *fakeTransaction) Commit(context.Context) error {
	tx.committed = true
	return nil
}

func (tx *fakeTransaction) Rollback(context.Context) error {
	tx.rolledBack = true
	return nil
}

type scanRow struct {
	values []any
}

func (result scanRow) Scan(dest ...any) error {
	if len(dest) != len(result.values) {
		return errors.New("unexpected scan destination count")
	}
	for index, value := range result.values {
		switch target := dest[index].(type) {
		case *int64:
			*target = value.(int64)
		case *string:
			*target = value.(string)
		case *time.Time:
			*target = value.(time.Time)
		default:
			return errors.New("unexpected scan destination type")
		}
	}
	return nil
}

type errorRow struct {
	err error
}

func (result errorRow) Scan(...any) error { return result.err }

func currentRow(revision int64, state app.State, issuedAt time.Time, validUntil time.Time, databaseNow time.Time) row {
	return scanRow{values: []any{revision, string(state), issuedAt, validUntil, databaseNow}}
}

func decisionRow(revision int64, state app.State, issuedAt time.Time, validUntil time.Time) row {
	return scanRow{values: []any{revision, string(state), issuedAt, validUntil}}
}

func timeRow(value time.Time) row {
	return scanRow{values: []any{value}}
}
