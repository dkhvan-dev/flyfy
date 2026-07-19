package repository

import (
	"bytes"
	"context"
	"encoding/base64"
	"errors"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
)

const collectionMigrationIntegrationDSNEnv = "SAVED_SERVICE_REPOSITORY_TEST_DSN"

func TestSavedCollectionsMigrationPostgres(t *testing.T) {
	dsn := strings.TrimSpace(os.Getenv(collectionMigrationIntegrationDSNEnv))
	if dsn == "" {
		t.Skipf("%s is not set", collectionMigrationIntegrationDSNEnv)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 90*time.Second)
	defer cancel()

	pool := openCollectionMigrationSchema(t, ctx, dsn)
	up001 := readMigration(t, "001_saved_core.up.sql")
	down001 := readMigration(t, "001_saved_core.down.sql")
	up002 := readMigration(t, "002_saved_collections.up.sql")
	down002 := readMigration(t, "002_saved_collections.down.sql")

	requireMigrationExec(t, ctx, pool, up001)
	requireMigrationExec(t, ctx, pool, up002)

	now := time.Now().UTC().Truncate(time.Microsecond)
	ownerA := uuid.New()
	ownerB := uuid.New()
	savedItemA := seedSavedItem(t, ctx, pool, ownerA, "place-a", now)
	savedItemB := seedSavedItem(t, ctx, pool, ownerB, "place-b", now)
	collectionA := uuid.New()
	collectionB := uuid.New()
	deletedCollection := uuid.New()

	requireSQLExec(t, ctx, pool, `
		INSERT INTO saved_collections (
			id, owner_user_id, client_creation_id, title,
			normalized_title_key, created_at, organized_at, updated_at
		) VALUES ($1, $2, $3, 'Almaty', 'almaty', $4, $4, $4)`,
		collectionA, ownerA, uuid.New(), now,
	)
	requireSQLExec(t, ctx, pool, `
		INSERT INTO saved_collections (
			id, owner_user_id, client_creation_id, title,
			normalized_title_key, created_at, organized_at, updated_at
		) VALUES ($1, $2, $3, 'Almaty', 'almaty', $4, $4, $4)`,
		collectionB, ownerB, uuid.New(), now,
	)
	requireSQLExec(t, ctx, pool, `
		INSERT INTO saved_collections (
			id, owner_user_id, client_creation_id, lifecycle_state,
			lifecycle_version, metadata_version, items_version,
			active_item_count, created_at, organized_at, updated_at,
			deleted_at, purge_eligible_at
		) VALUES (
			$1, $2, $3, 'DELETED', 2, 1, 0, 0,
			$4, $4, $5, $5, $5::timestamptz + INTERVAL '14 days'
		)`,
		deletedCollection, ownerA, uuid.New(), now, now.Add(time.Second),
	)
	requireSQLExec(t, ctx, pool, `
		INSERT INTO saved_collection_usage (
			owner_user_id, active_collections_count,
			active_memberships_count, usage_version,
			created_at, updated_at
		) VALUES ($1, 1, 1, 1, $2, $2)`,
		ownerA, now,
	)

	membershipA := uuid.New()
	requireSQLExec(t, ctx, pool, `
		INSERT INTO saved_collection_items (
			id, owner_user_id, collection_id, saved_item_id,
			saved_at_snapshot, added_at, updated_at
		) VALUES ($1, $2, $3, $4, $5, $5, $5)`,
		membershipA, ownerA, collectionA, savedItemA, now,
	)

	// A DELETED parent may retain ACTIVE children only while bounded cleanup runs.
	requireSQLExec(t, ctx, pool, `
		INSERT INTO saved_collection_items (
			id, owner_user_id, collection_id, saved_item_id,
			saved_at_snapshot, added_at, updated_at
		) VALUES ($1, $2, $3, $4, $5, $5, $5)`,
		uuid.New(), ownerA, deletedCollection, savedItemA, now,
	)

	removedAt := now.Add(2 * time.Second)
	requireSQLExec(t, ctx, pool, `
		INSERT INTO saved_collection_items (
			id, owner_user_id, collection_id, saved_item_id,
			membership_state, membership_version, saved_at_snapshot,
			removal_reason, added_at, updated_at, removed_at, purge_eligible_at
		) VALUES (
			$1, $2, $3, $4, 'REMOVED', 2, $5,
			'USER_REMOVED', $5, $6, $6, $6::timestamptz + INTERVAL '14 days'
		)`,
		uuid.New(), ownerB, collectionB, savedItemB, now, removedAt,
	)

	expectConstraintFailure(t, ctx, pool, "idx_saved_collections_active_title", `
		INSERT INTO saved_collections (
			id, owner_user_id, client_creation_id, title,
			normalized_title_key, created_at, organized_at, updated_at
		) VALUES ($1, $2, $3, 'ALMATY', 'almaty', $4, $4, $4)`,
		uuid.New(), ownerA, uuid.New(), now,
	)
	expectConstraintFailure(t, ctx, pool, "saved_collections_lifecycle_check", `
		INSERT INTO saved_collections (
			id, owner_user_id, client_creation_id, lifecycle_state,
			created_at, organized_at, updated_at
		) VALUES ($1, $2, $3, 'ACTIVE', $4, $4, $4)`,
		uuid.New(), ownerA, uuid.New(), now,
	)
	expectConstraintFailure(t, ctx, pool, "saved_collections_lifecycle_check", `
		INSERT INTO saved_collections (
			id, owner_user_id, client_creation_id, lifecycle_state,
			lifecycle_version, metadata_version, active_item_count,
			created_at, organized_at, updated_at, deleted_at, purge_eligible_at
		) VALUES (
			$1, $2, $3, 'DELETED', 2, 1, 0,
			$4, $4, $5, $5, $5::timestamptz + INTERVAL '13 days'
		)`,
		uuid.New(), ownerA, uuid.New(), now, now.Add(time.Second),
	)
	expectConstraintFailure(t, ctx, pool, "saved_collection_items_saved_item_fkey", `
		INSERT INTO saved_collection_items (
			id, owner_user_id, collection_id, saved_item_id,
			saved_at_snapshot, added_at, updated_at
		) VALUES ($1, $2, $3, $4, $5, $5, $5)`,
		uuid.New(), ownerA, collectionA, savedItemB, now,
	)
	expectConstraintFailure(t, ctx, pool, "saved_collection_items_lifecycle_check", `
		INSERT INTO saved_collection_items (
			id, owner_user_id, collection_id, saved_item_id,
			membership_state, membership_version, saved_at_snapshot,
			removal_reason, added_at, updated_at, removed_at, purge_eligible_at
		) VALUES (
			$1, $2, $3, $4, 'REMOVED', 2, $5,
			'USER_REMOVED', $5, $6, $6, $6::timestamptz + INTERVAL '7 days'
		)`,
		uuid.New(), ownerB, collectionB, savedItemB, now, removedAt,
	)
	expectConstraintFailure(t, ctx, pool, "saved_collection_items_collection_fkey",
		"DELETE FROM saved_collections WHERE owner_user_id = $1 AND id = $2",
		ownerA, collectionA,
	)

	operationSubject := ownerA.String()
	sessionGeneration := uuid.New()
	operationCreatedAt := now.Add(3 * time.Second)
	operationCompletedAt := operationCreatedAt.Add(time.Second)
	requireSQLExec(t, ctx, pool, `
		INSERT INTO saved_operations (
			subject, session_generation, operation_id, operation_kind,
			idempotency_key, semantic_request_hmac, request_hmac_key_version,
			first_seen_source_surface, accepted_platform_access_policy_revision,
			status, commit_deadline, outcome_code, outcome_retryable,
			refresh_scope, applied_collection_id,
			applied_collection_metadata_version,
			applied_collection_lifecycle_version,
			created_at, completed_at, retention_expires_at
		) VALUES (
			$1, $2, $3, 'CREATE_COLLECTION', $4, $5, 1,
			'CARD', 1, 'SUCCEEDED', $6, 'APPLIED', FALSE,
			'COLLECTIONS', $7, 1, 1, $8, $9, $9::timestamptz + INTERVAL '14 days'
		)`,
		operationSubject,
		sessionGeneration,
		uuid.New(),
		collectionIdempotencyKey(1),
		bytes.Repeat([]byte{0x51}, 32),
		operationCreatedAt.Add(10*time.Second),
		collectionA,
		operationCreatedAt,
		operationCompletedAt,
	)
	expectConstraintFailure(t, ctx, pool, "saved_operations_versions_check", `
		INSERT INTO saved_operations (
			subject, session_generation, operation_id, operation_kind,
			idempotency_key, semantic_request_hmac, request_hmac_key_version,
			first_seen_source_surface, accepted_platform_access_policy_revision,
			status, commit_deadline, outcome_code, outcome_retryable,
			refresh_scope, applied_collection_id,
			created_at, completed_at, retention_expires_at
		) VALUES (
			$1, $2, $3, 'CREATE_COLLECTION', $4, $5, 1,
			'CARD', 1, 'SUCCEEDED', $6, 'APPLIED', FALSE,
			'COLLECTIONS', $7, $8, $9, $9::timestamptz + INTERVAL '14 days'
		)`,
		operationSubject,
		sessionGeneration,
		uuid.New(),
		collectionIdempotencyKey(2),
		bytes.Repeat([]byte{0x52}, 32),
		operationCreatedAt.Add(10*time.Second),
		collectionA,
		operationCreatedAt,
		operationCompletedAt,
	)
	expectConstraintFailure(t, ctx, pool, "saved_operations_collection_kind_check", `
		INSERT INTO saved_operations (
			subject, session_generation, operation_id, operation_kind,
			idempotency_key, semantic_request_hmac, request_hmac_key_version,
			first_seen_source_surface, accepted_platform_access_policy_revision,
			status, commit_deadline, outcome_code, outcome_retryable,
			refresh_scope, observed_dependent_membership_version,
			created_at, completed_at, retention_expires_at
		) VALUES (
			$1, $2, $3, 'CREATE_COLLECTION', $4, $5, 1,
			'CARD', 1, 'REJECTED', $6, 'SAVED_MUTATION_STALE', FALSE,
			'NONE', 0, $7, $8, $8::timestamptz + INTERVAL '14 days'
		)`,
		operationSubject,
		sessionGeneration,
		uuid.New(),
		collectionIdempotencyKey(3),
		bytes.Repeat([]byte{0x53}, 32),
		operationCreatedAt.Add(10*time.Second),
		operationCreatedAt,
		operationCompletedAt,
	)
	requireSQLExec(t, ctx, pool, `
		INSERT INTO saved_subject_purge_operations (
			operation_id, subject, owner_user_id, phase,
			next_attempt_at, created_at, updated_at
		) VALUES ($1, $2, $3, 'COLLECTION_ITEMS', $4, $4, $4)`,
		uuid.New(), "purge:"+ownerA.String(), ownerA, now,
	)

	if _, err := pool.Exec(ctx, down002); err == nil {
		t.Fatal("down migration succeeded while private collection data existed")
	} else {
		var pgErr *pgconn.PgError
		if !errors.As(err, &pgErr) || pgErr.Code != "55000" {
			t.Fatalf("guarded down migration error = %v, want SQLSTATE 55000", err)
		}
	}
	assertTableRowCount(t, ctx, pool, "saved_collections", 3)

	requireSQLExec(t, ctx, pool, "DELETE FROM saved_subject_purge_operations")
	requireSQLExec(t, ctx, pool, "DELETE FROM saved_operations")
	requireSQLExec(t, ctx, pool, "DELETE FROM saved_collection_items")
	requireSQLExec(t, ctx, pool, "DELETE FROM saved_collection_usage")
	requireSQLExec(t, ctx, pool, "DELETE FROM saved_collections")
	requireMigrationExec(t, ctx, pool, down002)

	assertRelationMissing(t, ctx, pool, "saved_collection_items")
	assertRelationMissing(t, ctx, pool, "saved_collection_usage")
	assertRelationMissing(t, ctx, pool, "saved_collections")
	assertColumnMissing(t, ctx, pool, "saved_operations", "applied_collection_id")

	insertLegacyPendingOperation(t, ctx, pool, "SAVE_TARGET", collectionIdempotencyKey(4), now)
	expectConstraintFailure(t, ctx, pool, "saved_operations_kind_check", `
		INSERT INTO saved_operations (
			subject, session_generation, operation_id, operation_kind,
			idempotency_key, semantic_request_hmac, request_hmac_key_version,
			first_seen_source_surface, accepted_platform_access_policy_revision,
			commit_deadline, created_at
		) VALUES ($1, $2, $3, 'CREATE_COLLECTION', $4, $5, 1, 'CARD', 1, $6, $7)`,
		uuid.NewString(), uuid.New(), uuid.New(), collectionIdempotencyKey(5),
		bytes.Repeat([]byte{0x55}, 32), now.Add(10*time.Second), now,
	)
	requireSQLExec(t, ctx, pool, "DELETE FROM saved_operations")
	requireMigrationExec(t, ctx, pool, down001)
	assertRelationMissing(t, ctx, pool, "saved_items")

}

func openCollectionMigrationSchema(
	t *testing.T,
	ctx context.Context,
	dsn string,
) *pgxpool.Pool {
	t.Helper()

	adminPool, err := pgxpool.New(ctx, dsn)
	if err != nil {
		t.Fatalf("connect integration database: %v", err)
	}
	if err := adminPool.Ping(ctx); err != nil {
		adminPool.Close()
		t.Fatalf("ping integration database: %v", err)
	}

	schema := "saved_collections_" + strings.ReplaceAll(uuid.NewString(), "-", "")
	quotedSchema := pgx.Identifier{schema}.Sanitize()
	if _, err := adminPool.Exec(ctx, "CREATE SCHEMA "+quotedSchema); err != nil {
		adminPool.Close()
		t.Fatalf("create isolated schema: %v", err)
	}

	config, err := pgxpool.ParseConfig(dsn)
	if err != nil {
		_, _ = adminPool.Exec(context.Background(), "DROP SCHEMA "+quotedSchema+" CASCADE")
		adminPool.Close()
		t.Fatalf("parse integration DSN: %v", err)
	}
	config.ConnConfig.RuntimeParams["search_path"] = quotedSchema
	config.ConnConfig.DefaultQueryExecMode = pgx.QueryExecModeSimpleProtocol
	pool, err := pgxpool.NewWithConfig(ctx, config)
	if err != nil {
		_, _ = adminPool.Exec(context.Background(), "DROP SCHEMA "+quotedSchema+" CASCADE")
		adminPool.Close()
		t.Fatalf("connect isolated schema: %v", err)
	}

	t.Cleanup(func() {
		pool.Close()
		cleanupCtx, cleanupCancel := context.WithTimeout(context.Background(), 30*time.Second)
		defer cleanupCancel()
		if _, err := adminPool.Exec(cleanupCtx, "DROP SCHEMA "+quotedSchema+" CASCADE"); err != nil {
			t.Errorf("drop isolated schema: %v", err)
		}
		adminPool.Close()
	})

	return pool
}

func seedSavedItem(
	t testing.TB,
	ctx context.Context,
	pool *pgxpool.Pool,
	owner uuid.UUID,
	entityID string,
	now time.Time,
) uuid.UUID {
	t.Helper()

	requireSQLExec(t, ctx, pool, `
		INSERT INTO saved_content_projections (
			entity_type, entity_id, source_service, visibility_status,
			visibility_validated_at, source_default_locale, title_en,
			ever_referenced, created_at, updated_at
		) VALUES (
			'ATTRACTION', $1, 'place-service', 'PUBLIC',
			$2, 'EN', 'Attraction', TRUE, $2, $2
		)`, entityID, now,
	)

	savedItemID := uuid.New()
	requireSQLExec(t, ctx, pool, `
		INSERT INTO saved_items (
			id, owner_user_id, entity_type, entity_id,
			state_generation, relationship_attribution_id,
			saved_at, created_at, updated_at
		) VALUES ($1, $2, 'ATTRACTION', $3, $4, $5, $6, $6, $6)`,
		savedItemID, owner, entityID, uuid.New(), uuid.New(), now,
	)
	return savedItemID
}

func insertLegacyPendingOperation(
	t testing.TB,
	ctx context.Context,
	pool *pgxpool.Pool,
	kind string,
	idempotencyKey string,
	now time.Time,
) {
	t.Helper()
	requireSQLExec(t, ctx, pool, `
		INSERT INTO saved_operations (
			subject, session_generation, operation_id, operation_kind,
			idempotency_key, semantic_request_hmac, request_hmac_key_version,
			first_seen_source_surface, accepted_platform_access_policy_revision,
			commit_deadline, created_at
		) VALUES ($1, $2, $3, $4, $5, $6, 1, 'CARD', 1, $7, $8)`,
		uuid.NewString(), uuid.New(), uuid.New(), kind, idempotencyKey,
		bytes.Repeat([]byte{0x54}, 32), now.Add(10*time.Second), now,
	)
}

func collectionIdempotencyKey(seed byte) string {
	return base64.RawURLEncoding.EncodeToString(bytes.Repeat([]byte{seed}, 16))
}

func requireMigrationExec(t testing.TB, ctx context.Context, pool *pgxpool.Pool, sql string) {
	t.Helper()
	if _, err := pool.Exec(ctx, sql); err != nil {
		t.Fatalf("execute migration: %v", err)
	}
}

func requireSQLExec(
	t testing.TB,
	ctx context.Context,
	pool *pgxpool.Pool,
	sql string,
	args ...any,
) {
	t.Helper()
	if _, err := pool.Exec(ctx, sql, args...); err != nil {
		t.Fatalf("execute SQL: %v", err)
	}
}

func expectConstraintFailure(
	t testing.TB,
	ctx context.Context,
	pool *pgxpool.Pool,
	constraint string,
	sql string,
	args ...any,
) {
	t.Helper()
	_, err := pool.Exec(ctx, sql, args...)
	if err == nil {
		t.Fatalf("SQL unexpectedly passed constraint %s", constraint)
	}
	var pgErr *pgconn.PgError
	if !errors.As(err, &pgErr) {
		t.Fatalf("SQL error = %v, want PostgreSQL constraint error", err)
	}
	if pgErr.ConstraintName != constraint {
		t.Fatalf("constraint = %q, want %q (error: %v)", pgErr.ConstraintName, constraint, err)
	}
}

func assertTableRowCount(
	t testing.TB,
	ctx context.Context,
	pool *pgxpool.Pool,
	table string,
	want int,
) {
	t.Helper()
	var count int
	if err := pool.QueryRow(ctx, "SELECT count(*) FROM "+pgx.Identifier{table}.Sanitize()).Scan(&count); err != nil {
		t.Fatalf("count %s: %v", table, err)
	}
	if count != want {
		t.Fatalf("%s row count = %d, want %d", table, count, want)
	}
}

func assertRelationMissing(
	t testing.TB,
	ctx context.Context,
	pool *pgxpool.Pool,
	relation string,
) {
	t.Helper()
	var name *string
	if err := pool.QueryRow(ctx, "SELECT to_regclass($1)::text", relation).Scan(&name); err != nil {
		t.Fatalf("resolve relation %s: %v", relation, err)
	}
	if name != nil {
		t.Fatalf("relation %s still exists as %s", relation, *name)
	}
}

func assertColumnMissing(
	t testing.TB,
	ctx context.Context,
	pool *pgxpool.Pool,
	table string,
	column string,
) {
	t.Helper()
	var exists bool
	if err := pool.QueryRow(ctx, `
		SELECT EXISTS (
			SELECT 1
			FROM information_schema.columns
			WHERE table_schema = current_schema()
			AND table_name = $1
			AND column_name = $2
		)`, table, column).Scan(&exists); err != nil {
		t.Fatalf("inspect %s.%s: %v", table, column, err)
	}
	if exists {
		t.Fatalf("column %s.%s still exists", table, column)
	}
}
