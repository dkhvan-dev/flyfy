package repository

import (
	"context"
	"errors"
	"strings"
	"testing"
	"time"

	"github.com/jackc/pgx/v5/pgconn"

	savedmaintenance "kz/inflap/backend/services/saved-service/internal/app/savedmaintenance"
)

func TestSavedMaintenanceSQLIsBoundedAndLockFriendly(t *testing.T) {
	t.Parallel()

	queries := map[string]string{
		"expire operations":           expirePendingSavedOperationsSQL,
		"purge operations":            purgeTerminalSavedOperationsSQL,
		"purge outbox":                purgeTerminalSavedOutboxSQL,
		"purge inbox":                 purgeSavedInboxDedupSQL,
		"cleanup collection children": cleanupDeletedCollectionChildrenSQL,
		"purge collection items":      purgeRemovedCollectionItemsSQL,
		"purge collections":           purgeDeletedSavedCollectionsSQL,
		"purge saved items":           purgeRemovedSavedItemsSQL,
		"mark projections":            markSavedProjectionGCCandidatesSQL,
		"purge ephemeral projections": purgeEphemeralSavedProjectionsSQL,
		"purge standard projections":  purgeStandardSavedProjectionsSQL,
		"purge subject jobs":          purgeCompletedSubjectPurgesSQL,
		"subject outbox":              purgeSubjectOutboxSQL,
		"subject collection items":    purgeSubjectCollectionItemsSQL,
		"subject collections":         purgeSubjectCollectionsSQL,
		"subject saved items":         purgeSubjectSavedItemsSQL,
		"subject operations":          purgeSubjectOperationsSQL,
		"subject collection usage":    purgeSubjectCollectionUsageSQL,
		"subject user usage":          purgeSubjectUserUsageSQL,
	}
	for name, query := range queries {
		query := strings.ToUpper(query)
		for _, required := range []string{"ORDER BY", "LIMIT", "FOR UPDATE", "SKIP LOCKED"} {
			if !strings.Contains(query, required) {
				t.Errorf("%s does not contain %q", name, required)
			}
		}
		for _, forbidden := range []string{"LOCK TABLE", "TRUNCATE TABLE", "DELETE FROM SAVED_CONTENT_PROJECTIONS;"} {
			if strings.Contains(query, forbidden) {
				t.Errorf("%s contains forbidden SQL %q", name, forbidden)
			}
		}
	}
}

func TestExpirePendingOperationsSQLHasCASAndCoarseRefreshScopes(t *testing.T) {
	t.Parallel()

	for _, required := range []string{
		"operation.status = 'PENDING'",
		"operation.commit_deadline <= $1",
		"WHEN 'SAVE_TARGET' THEN 'SAVED_ITEMS'",
		"WHEN 'UNSAVE_TARGET' THEN 'BOTH'",
		"WHEN 'SET_TARGET_COLLECTIONS' THEN 'BOTH'",
		"WHEN 'CREATE_COLLECTION' THEN 'COLLECTIONS'",
		"WHEN 'RENAME_COLLECTION' THEN 'COLLECTIONS'",
		"WHEN 'DELETE_COLLECTION' THEN 'BOTH'",
	} {
		if !strings.Contains(expirePendingSavedOperationsSQL, required) {
			t.Errorf("expiry SQL does not contain %q", required)
		}
	}
}

func TestSavedMaintenanceDeletionQueriesAreOwnerSafe(t *testing.T) {
	t.Parallel()

	for name, query := range map[string]string{
		"collection child": cleanupDeletedCollectionChildrenSQL,
		"collection":       purgeDeletedSavedCollectionsSQL,
		"saved item":       purgeRemovedSavedItemsSQL,
		"subject outbox":   purgeSubjectOutboxSQL,
		"subject item":     purgeSubjectSavedItemsSQL,
	} {
		if !strings.Contains(query, "owner_user_id") {
			t.Errorf("%s query lacks owner_user_id binding", name)
		}
	}
	if !strings.Contains(purgeSubjectOperationsSQL, "operation.subject = $2") {
		t.Fatal("subject operation purge lacks subject binding")
	}
}

func TestSavedMaintenanceMigrationAddsOnlyProvenIndexes(t *testing.T) {
	t.Parallel()

	up := readSavedMigration(t, "005_saved_maintenance_indexes.up.sql")
	down := readSavedMigration(t, "005_saved_maintenance_indexes.down.sql")
	for _, index := range []string{
		"idx_saved_collection_items_deleted_parent_cleanup",
		"idx_saved_operations_collection_dependency",
		"idx_saved_outbox_owner_purge",
		"idx_saved_content_projections_gc_discovery",
	} {
		if !strings.Contains(up, "CREATE INDEX "+index) {
			t.Errorf("up migration does not create %s", index)
		}
		if !strings.Contains(down, "DROP INDEX IF EXISTS "+index) {
			t.Errorf("down migration does not drop %s", index)
		}
	}
	if strings.Contains(strings.ToUpper(up), "CREATE TABLE") || strings.Contains(strings.ToUpper(up), "ALTER TABLE") {
		t.Fatal("maintenance index migration changes table shape")
	}
}

func TestMapSavedMaintenanceErrorClassifiesRetryability(t *testing.T) {
	t.Parallel()

	contention := mapSavedMaintenanceError("test", &pgconn.PgError{Code: "40001", Message: "serialization"})
	if !savedmaintenance.IsRetryable(contention) {
		t.Fatalf("serialization error = %v, want retryable", contention)
	}
	var typed *savedmaintenance.Error
	if !errors.As(contention, &typed) || typed.Kind != savedmaintenance.ErrorKindContention {
		t.Fatalf("serialization typed error = %#v", typed)
	}

	invariant := mapSavedMaintenanceError("test", &pgconn.PgError{Code: "23514", Message: "check"})
	if savedmaintenance.IsRetryable(invariant) || !errors.As(invariant, &typed) ||
		typed.Kind != savedmaintenance.ErrorKindInvariant {
		t.Fatalf("constraint typed error = %#v", typed)
	}

	if got := mapSavedMaintenanceError("test", context.Canceled); !errors.Is(got, context.Canceled) {
		t.Fatalf("context error = %v", got)
	}
}

func TestSavedMaintenanceBatchRejectsInvalidRequest(t *testing.T) {
	t.Parallel()

	repository := &PGSavedMaintenanceRepository{}
	request := savedmaintenance.BatchRequest{
		Now:                 time.Now().UTC(),
		Limit:               0,
		OperationRetention:  savedmaintenance.DefaultOperationRetention,
		ProjectionRetention: savedmaintenance.DefaultProjectionRetention,
	}
	_, err := repository.PurgeTerminalOperations(context.Background(), request)
	if !errors.Is(err, ErrInvalidSavedMaintenanceDependencies) {
		t.Fatalf("nil repository error = %v", err)
	}
}
