package repository

import (
	"bytes"
	"context"
	"encoding/base64"
	"errors"
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	operationapp "kz/inflap/backend/services/saved-service/internal/app/operation"
	"kz/inflap/backend/services/saved-service/internal/domain"
)

const operationStoreIntegrationDSNEnv = "SAVED_SERVICE_REPOSITORY_TEST_DSN"

func TestPGOperationStoreIdentityConvergence(t *testing.T) {
	pool, store := openOperationStoreIntegration(t)
	subject := uuid.New()

	t.Run("same identity", func(t *testing.T) {
		truncateSavedOperations(t, pool)

		sessionGeneration := uuid.New()
		operationID := uuid.New()
		idempotencyKey := integrationIdempotencyKey(1)
		const workers = 24

		pending := make([]*domain.SavedOperation, workers)
		for index := range pending {
			pending[index] = newIntegrationPendingOperation(
				t,
				subject,
				sessionGeneration,
				operationID,
				idempotencyKey,
			)
		}

		results := createConcurrently(t, store, pending)
		created := 0
		for _, result := range results {
			if result.err != nil {
				t.Fatalf("CreateOrFind() error = %v", result.err)
			}
			if result.result.Created {
				created++
			}
			assertReceiptIdentity(t, result.result.Receipt, subject, sessionGeneration, operationID, idempotencyKey)
		}
		if created != 1 {
			t.Fatalf("created receipts = %d, want 1", created)
		}
		assertSavedOperationCount(t, pool, 1)
	})

	t.Run("operation ID collision", func(t *testing.T) {
		truncateSavedOperations(t, pool)

		sessionGeneration := uuid.New()
		operationID := uuid.New()
		canonicalKey := integrationIdempotencyKey(2)
		createOneIntegrationReceipt(t, store, newIntegrationPendingOperation(
			t, subject, sessionGeneration, operationID, canonicalKey,
		))

		result := createOneIntegrationReceipt(t, store, newIntegrationPendingOperation(
			t, subject, sessionGeneration, operationID, integrationIdempotencyKey(3),
		))
		if result.Created {
			t.Fatal("operation ID collision created a second receipt")
		}
		assertReceiptIdentity(t, result.Receipt, subject, sessionGeneration, operationID, canonicalKey)
		assertSavedOperationCount(t, pool, 1)
	})

	t.Run("idempotency collision", func(t *testing.T) {
		truncateSavedOperations(t, pool)

		sessionGeneration := uuid.New()
		canonicalOperationID := uuid.New()
		idempotencyKey := integrationIdempotencyKey(4)
		createOneIntegrationReceipt(t, store, newIntegrationPendingOperation(
			t, subject, sessionGeneration, canonicalOperationID, idempotencyKey,
		))

		result := createOneIntegrationReceipt(t, store, newIntegrationPendingOperation(
			t, subject, sessionGeneration, uuid.New(), idempotencyKey,
		))
		if result.Created {
			t.Fatal("idempotency collision created a second receipt")
		}
		assertReceiptIdentity(t, result.Receipt, subject, sessionGeneration, canonicalOperationID, idempotencyKey)
		assertSavedOperationCount(t, pool, 1)
	})

	t.Run("crossed existing identities", func(t *testing.T) {
		truncateSavedOperations(t, pool)

		sessionGeneration := uuid.New()
		operationIDA := uuid.New()
		operationIDB := uuid.New()
		idempotencyKeyA := integrationIdempotencyKey(5)
		idempotencyKeyB := integrationIdempotencyKey(6)
		createOneIntegrationReceipt(t, store, newIntegrationPendingOperation(
			t, subject, sessionGeneration, operationIDA, idempotencyKeyA,
		))
		createOneIntegrationReceipt(t, store, newIntegrationPendingOperation(
			t, subject, sessionGeneration, operationIDB, idempotencyKeyB,
		))

		results := createConcurrently(t, store, []*domain.SavedOperation{
			newIntegrationPendingOperation(t, subject, sessionGeneration, operationIDA, idempotencyKeyB),
			newIntegrationPendingOperation(t, subject, sessionGeneration, operationIDB, idempotencyKeyA),
		})
		for _, result := range results {
			if result.err != nil {
				t.Fatalf("CreateOrFind() error = %v", result.err)
			}
			if result.result.Created {
				t.Fatal("crossed identities created a third binding")
			}
		}
		assertReceiptIdentity(t, results[0].result.Receipt, subject, sessionGeneration, operationIDA, idempotencyKeyA)
		assertReceiptIdentity(t, results[1].result.Receipt, subject, sessionGeneration, operationIDB, idempotencyKeyB)
		assertSavedOperationCount(t, pool, 2)
	})

	t.Run("session isolation", func(t *testing.T) {
		truncateSavedOperations(t, pool)

		operationID := uuid.New()
		idempotencyKey := integrationIdempotencyKey(7)
		sessionA := uuid.New()
		sessionB := uuid.New()
		results := createConcurrently(t, store, []*domain.SavedOperation{
			newIntegrationPendingOperation(t, subject, sessionA, operationID, idempotencyKey),
			newIntegrationPendingOperation(t, subject, sessionB, operationID, idempotencyKey),
		})
		for _, result := range results {
			if result.err != nil {
				t.Fatalf("CreateOrFind() error = %v", result.err)
			}
			if !result.result.Created {
				t.Fatal("identity in a distinct session did not create its own receipt")
			}
		}
		assertReceiptIdentity(t, results[0].result.Receipt, subject, sessionA, operationID, idempotencyKey)
		assertReceiptIdentity(t, results[1].result.Receipt, subject, sessionB, operationID, idempotencyKey)
		assertSavedOperationCount(t, pool, 2)
	})

	t.Run("subject pending limit is atomic and replay remains available", func(t *testing.T) {
		truncateSavedOperations(t, pool)

		limitedStore, err := NewPGOperationStore(pool, 2)
		if err != nil {
			t.Fatalf("NewPGOperationStore(limit) error = %v", err)
		}
		session := uuid.New()
		pending := make([]*domain.SavedOperation, 8)
		for index := range pending {
			pending[index] = newIntegrationPendingOperation(
				t,
				subject,
				session,
				uuid.New(),
				integrationIdempotencyKey(byte(10+index)),
			)
		}
		results := createConcurrently(t, limitedStore, pending)
		created := 0
		rateLimited := 0
		var createdRequest *domain.SavedOperation
		for index, result := range results {
			switch {
			case result.err == nil && result.result.Created:
				created++
				createdRequest = pending[index]
			case errors.Is(result.err, domain.ErrRateLimited):
				rateLimited++
			default:
				t.Fatalf("concurrent result %d = (%+v, %v)", index, result.result, result.err)
			}
		}
		if created != 2 || rateLimited != 6 || createdRequest == nil {
			t.Fatalf("created=%d rate_limited=%d", created, rateLimited)
		}

		replay, err := limitedStore.CreateOrFind(context.Background(), createdRequest)
		if err != nil || replay.Created || replay.Receipt == nil {
			t.Fatalf("replay at limit = (%+v, %v)", replay, err)
		}
		otherSubject := newIntegrationPendingOperation(
			t, uuid.New(), session, uuid.New(), integrationIdempotencyKey(20),
		)
		createOneIntegrationReceipt(t, limitedStore, otherSubject)
		assertSavedOperationCount(t, pool, 3)
	})

	t.Run("cancelled context", func(t *testing.T) {
		truncateSavedOperations(t, pool)

		ctx, cancel := context.WithCancel(context.Background())
		cancel()
		_, err := store.CreateOrFind(ctx, newIntegrationPendingOperation(
			t, subject, uuid.New(), uuid.New(), integrationIdempotencyKey(8),
		))
		if !errors.Is(err, context.Canceled) {
			t.Fatalf("CreateOrFind() error = %v, want context.Canceled", err)
		}
		assertSavedOperationCount(t, pool, 0)
	})
}

type concurrentCreateResult struct {
	index  int
	result operationapp.CreateOrFindResult
	err    error
}

func createConcurrently(
	t *testing.T,
	store *PGOperationStore,
	pending []*domain.SavedOperation,
) []concurrentCreateResult {
	t.Helper()

	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()
	start := make(chan struct{})
	resultChannel := make(chan concurrentCreateResult, len(pending))
	var ready sync.WaitGroup
	ready.Add(len(pending))

	for index, receipt := range pending {
		go func(index int, receipt *domain.SavedOperation) {
			ready.Done()
			<-start
			result, err := store.CreateOrFind(ctx, receipt)
			resultChannel <- concurrentCreateResult{index: index, result: result, err: err}
		}(index, receipt)
	}
	ready.Wait()
	close(start)

	results := make([]concurrentCreateResult, len(pending))
	for range pending {
		result := <-resultChannel
		results[result.index] = result
	}
	return results
}

func createOneIntegrationReceipt(
	t *testing.T,
	store *PGOperationStore,
	pending *domain.SavedOperation,
) operationapp.CreateOrFindResult {
	t.Helper()

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	result, err := store.CreateOrFind(ctx, pending)
	if err != nil {
		t.Fatalf("CreateOrFind() error = %v", err)
	}
	return result
}

func newIntegrationPendingOperation(
	t testing.TB,
	subject uuid.UUID,
	sessionGeneration uuid.UUID,
	operationID uuid.UUID,
	idempotencyKey string,
) *domain.SavedOperation {
	t.Helper()

	now := time.Now().UTC().Truncate(time.Microsecond)
	receipt, err := domain.NewPendingOperation(
		operationID,
		subject,
		sessionGeneration,
		domain.OperationKindSave,
		idempotencyKey,
		bytes.Repeat([]byte{0x73}, 32),
		1,
		domain.SourceSurfaceCard,
		9,
		now,
		now.Add(10*time.Second),
	)
	if err != nil {
		t.Fatalf("NewPendingOperation() error = %v", err)
	}
	return receipt
}

func integrationIdempotencyKey(seed byte) string {
	return base64.RawURLEncoding.EncodeToString(bytes.Repeat([]byte{seed}, 16))
}

func assertReceiptIdentity(
	t testing.TB,
	receipt *domain.SavedOperation,
	subject uuid.UUID,
	sessionGeneration uuid.UUID,
	operationID uuid.UUID,
	idempotencyKey string,
) {
	t.Helper()
	if receipt == nil {
		t.Fatal("receipt is nil")
	}
	if receipt.SubjectID() != subject || receipt.SessionGeneration() != sessionGeneration ||
		receipt.OperationID() != operationID || receipt.IdempotencyKey() != idempotencyKey {
		t.Fatalf("receipt identity = (%s, %s, %s, %q), want (%s, %s, %s, %q)",
			receipt.SubjectID(), receipt.SessionGeneration(), receipt.OperationID(), receipt.IdempotencyKey(),
			subject, sessionGeneration, operationID, idempotencyKey)
	}
}

func assertSavedOperationCount(t testing.TB, pool *pgxpool.Pool, want int) {
	t.Helper()

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	var count int
	if err := pool.QueryRow(ctx, "SELECT count(*) FROM saved_operations").Scan(&count); err != nil {
		t.Fatalf("count saved_operations: %v", err)
	}
	if count != want {
		t.Fatalf("saved_operations count = %d, want %d", count, want)
	}
}

func truncateSavedOperations(t testing.TB, pool *pgxpool.Pool) {
	t.Helper()

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	if _, err := pool.Exec(ctx, "TRUNCATE TABLE saved_operations"); err != nil {
		t.Fatalf("truncate saved_operations: %v", err)
	}
}

func openOperationStoreIntegration(t *testing.T) (*pgxpool.Pool, *PGOperationStore) {
	t.Helper()

	dsn := strings.TrimSpace(os.Getenv(operationStoreIntegrationDSNEnv))
	if dsn == "" {
		t.Skipf("%s is not set", operationStoreIntegrationDSNEnv)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	adminPool, err := pgxpool.New(ctx, dsn)
	if err != nil {
		t.Fatalf("connect integration database: %v", err)
	}
	if err := adminPool.Ping(ctx); err != nil {
		adminPool.Close()
		t.Fatalf("ping integration database: %v", err)
	}

	schema := "saved_operation_store_" + strings.ReplaceAll(uuid.NewString(), "-", "")
	quotedSchema := pgx.Identifier{schema}.Sanitize()
	if _, err := adminPool.Exec(ctx, "CREATE SCHEMA "+quotedSchema); err != nil {
		adminPool.Close()
		t.Fatalf("create isolated schema: %v", err)
	}

	coreUpSQL := readSavedMigration(t, "001_saved_core.up.sql")
	collectionsUpSQL := readSavedMigration(t, "002_saved_collections.up.sql")
	searchUpSQL := readSavedMigration(t, "003_saved_search.up.sql")
	reconciliationUpSQL := readSavedMigration(t, "006_saved_reconciliation_scheduler.up.sql")
	reconciliationDownSQL := readSavedMigration(t, "006_saved_reconciliation_scheduler.down.sql")
	searchDownSQL := readSavedMigration(t, "003_saved_search.down.sql")
	collectionsDownSQL := readSavedMigration(t, "002_saved_collections.down.sql")
	coreDownSQL := readSavedMigration(t, "001_saved_core.down.sql")
	poolConfig, err := pgxpool.ParseConfig(dsn)
	if err != nil {
		_, _ = adminPool.Exec(context.Background(), "DROP SCHEMA "+quotedSchema+" CASCADE")
		adminPool.Close()
		t.Fatalf("parse integration DSN: %v", err)
	}
	poolConfig.ConnConfig.RuntimeParams["search_path"] = quotedSchema
	poolConfig.ConnConfig.DefaultQueryExecMode = pgx.QueryExecModeSimpleProtocol
	pool, err := pgxpool.NewWithConfig(ctx, poolConfig)
	if err != nil {
		_, _ = adminPool.Exec(context.Background(), "DROP SCHEMA "+quotedSchema+" CASCADE")
		adminPool.Close()
		t.Fatalf("connect isolated schema: %v", err)
	}

	t.Cleanup(func() {
		cleanupCtx, cleanupCancel := context.WithTimeout(context.Background(), 30*time.Second)
		defer cleanupCancel()
		if _, err := pool.Exec(cleanupCtx, reconciliationDownSQL); err != nil {
			t.Errorf("apply Saved reconciliation migration down in isolated schema: %v", err)
		}
		if _, err := pool.Exec(cleanupCtx, searchDownSQL); err != nil {
			t.Errorf("apply Saved search migration down in isolated schema: %v", err)
		}
		if _, err := pool.Exec(cleanupCtx, collectionsDownSQL); err != nil {
			t.Errorf("apply Saved collections migration down in isolated schema: %v", err)
		}
		if _, err := pool.Exec(cleanupCtx, coreDownSQL); err != nil {
			t.Errorf("apply Saved core migration down in isolated schema: %v", err)
		}
		pool.Close()
		if _, err := adminPool.Exec(cleanupCtx, "DROP SCHEMA "+quotedSchema+" CASCADE"); err != nil {
			t.Errorf("drop isolated schema: %v", err)
		}
		adminPool.Close()
	})

	var currentSchema string
	if err := pool.QueryRow(ctx, "SELECT current_schema()").Scan(&currentSchema); err != nil {
		t.Fatalf("read isolated current_schema: %v", err)
	}
	if currentSchema != schema {
		t.Fatalf("current_schema() = %q, want %q", currentSchema, schema)
	}
	if _, err := pool.Exec(ctx, coreUpSQL); err != nil {
		t.Fatalf("apply Saved core migration up in isolated schema: %v", err)
	}
	if _, err := pool.Exec(ctx, collectionsUpSQL); err != nil {
		t.Fatalf("apply Saved collections migration up in isolated schema: %v", err)
	}
	if _, err := pool.Exec(ctx, searchUpSQL); err != nil {
		t.Fatalf("apply Saved search migration up in isolated schema: %v", err)
	}
	if _, err := pool.Exec(ctx, reconciliationUpSQL); err != nil {
		t.Fatalf("apply Saved reconciliation migration up in isolated schema: %v", err)
	}

	store, err := NewPGOperationStore(pool, maxPendingOperationsPerSubject)
	if err != nil {
		t.Fatalf("NewPGOperationStore() error = %v", err)
	}
	return pool, store
}

func readSavedMigration(t testing.TB, name string) string {
	t.Helper()

	_, currentFile, _, ok := runtime.Caller(0)
	if !ok {
		t.Fatal("resolve integration test path")
	}
	path := filepath.Join(filepath.Dir(currentFile), "..", "..", "..", "migrations", name)
	contents, err := os.ReadFile(path)
	if err != nil {
		t.Fatalf("read migration %s: %v", name, err)
	}
	if len(contents) == 0 {
		t.Fatalf("migration %s is empty", name)
	}
	return string(contents)
}
