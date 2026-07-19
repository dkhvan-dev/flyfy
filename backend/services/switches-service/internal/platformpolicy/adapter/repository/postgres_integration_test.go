package repository

import (
	"context"
	"errors"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"kz/inflap/backend/services/switches-service/internal/platformpolicy/app"
)

func TestPGRepositoryAgainstPostgres(t *testing.T) {
	dsn := os.Getenv("SWITCHES_PLATFORM_POLICY_TEST_DSN")
	if dsn == "" {
		t.Skip("SWITCHES_PLATFORM_POLICY_TEST_DSN is not set")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	adminPool, err := pgxpool.New(ctx, dsn)
	if err != nil {
		t.Fatalf("create admin pool: %v", err)
	}
	defer adminPool.Close()

	schema := "platform_policy_test_" + strings.ReplaceAll(uuid.NewString(), "-", "")
	schemaSQL := pgx.Identifier{schema}.Sanitize()
	if _, err = adminPool.Exec(ctx, "create schema "+schemaSQL); err != nil {
		t.Fatalf("create test schema: %v", err)
	}
	defer func() {
		cleanupCtx, cleanupCancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cleanupCancel()
		_, _ = adminPool.Exec(cleanupCtx, "drop schema if exists "+schemaSQL+" cascade")
	}()

	config, err := pgxpool.ParseConfig(dsn)
	if err != nil {
		t.Fatalf("parse test DSN: %v", err)
	}
	config.ConnConfig.RuntimeParams["search_path"] = schema
	config.ConnConfig.DefaultQueryExecMode = pgx.QueryExecModeSimpleProtocol
	pool, err := pgxpool.NewWithConfig(ctx, config)
	if err != nil {
		t.Fatalf("create policy pool: %v", err)
	}
	defer pool.Close()

	migrationPath := filepath.Join("..", "..", "..", "..", "migrations", "000011_platform_personal_data_policy.up.sql")
	migration, err := os.ReadFile(migrationPath)
	if err != nil {
		t.Fatalf("read migration: %v", err)
	}
	if _, err = pool.Exec(ctx, string(migration)); err != nil {
		t.Fatalf("apply migration: %v", err)
	}

	repository := NewPGRepository(pool)
	initial, err := repository.ReadDecision(ctx)
	if err != nil {
		t.Fatalf("read initial decision: %v", err)
	}
	if initial.State != app.StateAvailable || initial.Revision == 0 {
		t.Fatalf("initial decision = %#v", initial)
	}

	var expiredRevision int64
	if err = pool.QueryRow(ctx, `
		update platform_personal_data_policy_state
		set revision = revision + 1,
		    issued_at = transaction_timestamp() - interval '30 seconds',
		    valid_until = transaction_timestamp() - interval '10 seconds'
		where singleton_id = 1
		returning revision
	`).Scan(&expiredRevision); err != nil {
		t.Fatalf("expire decision lease: %v", err)
	}

	renewed, err := repository.ReadDecision(ctx)
	if err != nil {
		t.Fatalf("renew decision: %v", err)
	}
	if renewed.Revision != uint64(expiredRevision+1) || renewed.State != app.StateAvailable {
		t.Fatalf("renewed decision = %#v, expired revision = %d", renewed, expiredRevision)
	}

	changed, err := repository.ChangeState(ctx, app.ChangeCommand{
		ExpectedRevision: renewed.Revision,
		State:            app.StateLocked,
		Actor:            "integration-admin",
		Reason:           "repository integration test",
		ChangeTicket:     "TEST-000011",
	})
	if err != nil {
		t.Fatalf("change policy state: %v", err)
	}
	if changed.Revision != renewed.Revision+1 || changed.State != app.StateLocked {
		t.Fatalf("changed decision = %#v", changed)
	}

	_, err = repository.ChangeState(ctx, app.ChangeCommand{
		ExpectedRevision: changed.Revision,
		State:            app.StateLocked,
		Actor:            "integration-admin",
		Reason:           "same state",
		ChangeTicket:     "TEST-000011",
	})
	if !errors.Is(err, app.ErrStateUnchanged) {
		t.Fatalf("same-state error = %v, want ErrStateUnchanged", err)
	}

	_, err = repository.ChangeState(ctx, app.ChangeCommand{
		ExpectedRevision: changed.Revision - 1,
		State:            app.StateAvailable,
		Actor:            "integration-admin",
		Reason:           "stale revision",
		ChangeTicket:     "TEST-000011",
	})
	if !errors.Is(err, app.ErrRevisionConflict) {
		t.Fatalf("stale-revision error = %v, want ErrRevisionConflict", err)
	}

	start := make(chan struct{})
	results := make(chan error, 2)
	for _, ticket := range []string{"TEST-CONCURRENT-A", "TEST-CONCURRENT-B"} {
		go func(changeTicket string) {
			<-start
			_, changeErr := repository.ChangeState(ctx, app.ChangeCommand{
				ExpectedRevision: changed.Revision,
				State:            app.StateAvailable,
				Actor:            "integration-admin",
				Reason:           "concurrent optimistic update",
				ChangeTicket:     changeTicket,
			})
			results <- changeErr
		}(ticket)
	}
	close(start)
	succeeded := 0
	conflicted := 0
	for range 2 {
		switch changeErr := <-results; {
		case changeErr == nil:
			succeeded++
		case errors.Is(changeErr, app.ErrRevisionConflict):
			conflicted++
		default:
			t.Fatalf("concurrent change error = %v", changeErr)
		}
	}
	if succeeded != 1 || conflicted != 1 {
		t.Fatalf("concurrent outcomes: succeeded = %d, conflicted = %d", succeeded, conflicted)
	}

	var historyCount int
	if err = pool.QueryRow(ctx, "select count(*) from platform_personal_data_policy_history").Scan(&historyCount); err != nil {
		t.Fatalf("count policy history: %v", err)
	}
	if historyCount != 3 {
		t.Fatalf("history count = %d, want seed plus two state transitions", historyCount)
	}

	var audit string
	if err = pool.QueryRow(ctx, `
		select actor || ':' || reason || ':' || change_ticket
		from platform_personal_data_policy_history
		where revision = $1
	`, int64(changed.Revision)).Scan(&audit); err != nil {
		t.Fatalf("read policy audit: %v", err)
	}
	if audit != "integration-admin:repository integration test:TEST-000011" {
		t.Fatalf("audit = %q", audit)
	}

	t.Logf("verified platform policy repository in isolated schema %q at revision %d", schema, changed.Revision)
}
