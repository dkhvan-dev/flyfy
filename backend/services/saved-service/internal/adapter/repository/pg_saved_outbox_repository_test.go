package repository

import (
	"errors"
	"strings"
	"testing"

	"github.com/jackc/pgx/v5/pgconn"

	savedoutbox "kz/inflap/backend/services/saved-service/internal/app/savedoutbox"
)

func TestSavedOutboxSQLContracts(t *testing.T) {
	assertSavedOutboxSQLContains(t, claimDueSavedOutboxSQL,
		"FOR UPDATE SKIP LOCKED",
		"status = 'PENDING'",
		"locked_at IS NULL",
		"attempt_count < $2",
		"attempt_count = outbox.attempt_count + 1",
		"ORDER BY next_attempt_at, created_at, id",
	)
	for _, sensitiveColumn := range []string{
		"owner_user_id",
		"saved_item_id",
		"entity_id",
		"state_generation",
		"relationship_attribution_id",
		"relationship_version",
	} {
		if strings.Contains(claimDueSavedOutboxSQL, sensitiveColumn) {
			t.Fatalf("claim query selects privacy-sensitive column %q", sensitiveColumn)
		}
	}

	assertSavedOutboxSQLContains(t, recoverStaleSavedOutboxLeasesSQL,
		"next_attempt_at <= $1",
		"locked_at IS NOT NULL AND locked_at <= $2",
		"attempt_count >= $3",
		"THEN 'DEAD'",
		"ORDER BY next_attempt_at, created_at, id",
		"FOR UPDATE SKIP LOCKED",
	)
	for name, query := range map[string]string{
		"delivered": markSavedOutboxDeliveredSQL,
		"failed":    markSavedOutboxFailedSQL,
	} {
		assertSavedOutboxSQLContains(t, query,
			"status = 'PENDING'",
			"locked_at = $2",
			"attempt_count = $3",
		)
		if strings.Contains(strings.ToLower(query), "last_error_message") {
			t.Fatalf("%s query persists raw error text", name)
		}
	}
	assertSavedOutboxSQLContains(t, deleteExpiredSavedOutboxSQL,
		"status IN ('DELIVERED', 'DEAD')",
		"retention_expires_at <= $1",
		"LIMIT $2",
		"FOR UPDATE SKIP LOCKED",
	)
}

func TestSavedOutboxPGErrorMappingIsBounded(t *testing.T) {
	err := mapSavedOutboxPGError(&pgconn.PgError{
		Code:    "23514",
		Message: "owner private-owner target private-target",
		Detail:  "raw row contained account identifiers",
	})
	if !errors.Is(err, savedoutbox.ErrPersistenceInvariant) {
		t.Fatalf("mapped error = %v", err)
	}
	if strings.Contains(err.Error(), "private") || strings.Contains(err.Error(), "owner") {
		t.Fatalf("mapped error leaks PostgreSQL details: %q", err.Error())
	}
	scanErr := mapSavedOutboxScanError(errors.New("private row decoding failed"))
	if !errors.Is(scanErr, savedoutbox.ErrPersistenceInvariant) ||
		strings.Contains(scanErr.Error(), "private") {
		t.Fatalf("mapped scan error = %q", scanErr)
	}
}

func TestNewPGSavedOutboxRepositoryRejectsNilPool(t *testing.T) {
	if _, err := NewPGSavedOutboxRepository(nil); !errors.Is(err, savedoutbox.ErrInvalidDependencies) {
		t.Fatalf("NewPGSavedOutboxRepository(nil) error = %v", err)
	}
}

func assertSavedOutboxSQLContains(t testing.TB, query string, fragments ...string) {
	t.Helper()
	for _, fragment := range fragments {
		if !strings.Contains(query, fragment) {
			t.Fatalf("SQL does not contain %q", fragment)
		}
	}
}
