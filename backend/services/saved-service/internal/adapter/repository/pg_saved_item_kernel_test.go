package repository

import (
	"errors"
	"strings"
	"testing"

	"github.com/jackc/pgx/v5/pgconn"

	saveditemapp "kz/inflap/backend/services/saved-service/internal/app/saveditem"
	"kz/inflap/backend/services/saved-service/internal/domain"
)

func TestSavedItemSQLContracts(t *testing.T) {
	assertSQLContains(t, lockSavedItemOperationSQL,
		"FROM saved_operations", "subject = $1", "session_generation = $2",
		"operation_id = $3", "FOR UPDATE")
	assertSQLContains(t, updateSavedItemOperationTerminalSQL,
		"status = 'PENDING'", "semantic_request_hmac = $21",
		"request_hmac_key_version = $22", "commit_deadline <= $19",
		"commit_deadline > $19")
	assertSQLContains(t, lockSavedRelationshipSQL,
		"owner_user_id = $1", "entity_type = $2", "entity_id = $3", "FOR UPDATE")
	assertSQLContains(t, lockEffectiveCollectionsSQL,
		"owner_user_id = $1", "ORDER BY id", "FOR UPDATE")
	assertSQLContains(t, lockEffectiveMembershipsSQL,
		"owner_user_id = $1", "saved_item_id = $2", "ORDER BY collection_id, id", "FOR UPDATE")
	assertSQLContains(t, removeEffectiveMembershipsSQL,
		"removal_reason = 'GLOBAL_UNSAVE'", "INTERVAL '14 days'")
	assertSQLContains(t, removeSavedRelationshipSQL,
		"relationship_state = 'REMOVED'", "INTERVAL '14 days'")
	assertSQLContains(t, insertSavedProjectionSQL,
		"media_reference_revision", "media_valid_until", "rating_scale_max",
		"$34::jsonb", "$35::jsonb")

	for _, forbidden := range []string{"confirmation", "expected_count", "removal:commit", "request_payload"} {
		if strings.Contains(strings.ToLower(removeSavedRelationshipSQL+removeEffectiveMembershipsSQL), forbidden) {
			t.Fatalf("global unsave SQL contains forbidden choreography %q", forbidden)
		}
	}
}

func TestEncodeLocalizedSummary(t *testing.T) {
	en := "from 20 USD"
	ru := "от 10 000 KZT"
	encoded, err := encodeLocalizedSummary(saveditemapp.LocalizedText{EN: &en, RU: &ru})
	if err != nil {
		t.Fatalf("encodeLocalizedSummary() error = %v", err)
	}
	if encoded != `{"en":"from 20 USD","ru":"от 10 000 KZT"}` {
		t.Fatalf("encoded summary = %v", encoded)
	}
	empty, err := encodeLocalizedSummary(saveditemapp.LocalizedText{})
	if err != nil || empty != nil {
		t.Fatalf("empty summary = (%v, %v), want (nil, nil)", empty, err)
	}
}

func TestSavedItemPGErrorMappingIsBounded(t *testing.T) {
	err := mapSavedItemPGError(&pgconn.PgError{
		Code:           "23505",
		Message:        "duplicate secret target",
		Detail:         "owner=private-id",
		ConstraintName: "private_constraint",
	})
	if !errors.Is(err, domain.ErrMutationStale) {
		t.Fatalf("mapped error = %v", err)
	}
	if strings.Contains(err.Error(), "private") || strings.Contains(err.Error(), "duplicate") {
		t.Fatalf("mapped error leaks PostgreSQL details: %q", err.Error())
	}
}

func assertSQLContains(t testing.TB, query string, fragments ...string) {
	t.Helper()
	for _, fragment := range fragments {
		if !strings.Contains(query, fragment) {
			t.Fatalf("SQL does not contain %q", fragment)
		}
	}
}
