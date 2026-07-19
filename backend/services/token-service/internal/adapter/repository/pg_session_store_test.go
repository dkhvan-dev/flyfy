package repository

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
)

type sessionGenerationQueryerStub struct {
	query string
	args  []any
	row   pgx.Row
}

func (s *sessionGenerationQueryerStub) QueryRow(_ context.Context, query string, args ...any) pgx.Row {
	s.query = query
	s.args = args
	return s.row
}

type sessionGenerationRowStub struct {
	valid bool
	err   error
}

func (s sessionGenerationRowStub) Scan(dest ...any) error {
	if s.err != nil {
		return s.err
	}
	if len(dest) != 1 {
		return fmt.Errorf("Scan() destinations = %d, want 1", len(dest))
	}
	valid, ok := dest[0].(*bool)
	if !ok {
		return fmt.Errorf("Scan() destination type = %T, want *bool", dest[0])
	}
	*valid = s.valid
	return nil
}

func TestQueryCurrentSessionGenerationUsesAuthoritativeLifecyclePredicates(t *testing.T) {
	t.Parallel()

	userID := uuid.New()
	generation := uuid.New()
	now := time.Date(2026, time.July, 16, 10, 30, 0, 0, time.UTC)
	ttl := 24 * time.Hour
	queryer := &sessionGenerationQueryerStub{row: sessionGenerationRowStub{valid: true}}

	valid, err := queryCurrentSessionGeneration(t.Context(), queryer, userID, generation, now, ttl)
	if err != nil {
		t.Fatalf("queryCurrentSessionGeneration() error = %v", err)
	}
	if !valid {
		t.Fatal("queryCurrentSessionGeneration() = false, want true")
	}

	for _, predicate := range []string{
		"candidate.user_id = $1",
		"candidate.id = $2",
		"candidate.revoked_at IS NULL",
		"candidate.refresh_expires_at > $3",
		"candidate.last_used_at >= $5",
		"NOT EXISTS",
		"other.revoked_at IS NULL",
	} {
		if !strings.Contains(queryer.query, predicate) {
			t.Errorf("validation query missing predicate %q", predicate)
		}
	}
	if len(queryer.args) != 5 {
		t.Fatalf("QueryRow() args = %d, want 5", len(queryer.args))
	}
	if queryer.args[0] != userID || queryer.args[1] != generation {
		t.Fatalf("QueryRow() identity args = %v, want subject/generation", queryer.args[:2])
	}
	if queryer.args[2] != now {
		t.Fatalf("QueryRow() now = %v, want %v", queryer.args[2], now)
	}
	if queryer.args[3] != true {
		t.Fatalf("QueryRow() inactivity enabled = %v, want true", queryer.args[3])
	}
	if queryer.args[4] != now.Add(-ttl) {
		t.Fatalf("QueryRow() inactivity cutoff = %v, want %v", queryer.args[4], now.Add(-ttl))
	}
}

func TestQueryCurrentSessionGenerationDisablesInactivityWithoutTTL(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, time.July, 16, 10, 30, 0, 0, time.FixedZone("test", 6*60*60))
	queryer := &sessionGenerationQueryerStub{row: sessionGenerationRowStub{valid: false}}

	valid, err := queryCurrentSessionGeneration(t.Context(), queryer, uuid.New(), uuid.New(), now, 0)
	if err != nil {
		t.Fatalf("queryCurrentSessionGeneration() error = %v", err)
	}
	if valid {
		t.Fatal("queryCurrentSessionGeneration() = true, want false")
	}
	if queryer.args[3] != false {
		t.Fatalf("QueryRow() inactivity enabled = %v, want false", queryer.args[3])
	}
	if queryer.args[2] != now.UTC() || queryer.args[4] != now.UTC() {
		t.Fatalf("QueryRow() timestamps were not normalized to UTC: %v", queryer.args)
	}
}

func TestQueryCurrentSessionGenerationFailsClosedOnQueryError(t *testing.T) {
	t.Parallel()

	dependencyErr := errors.New("database unavailable")
	queryer := &sessionGenerationQueryerStub{row: sessionGenerationRowStub{err: dependencyErr}}

	valid, err := queryCurrentSessionGeneration(
		t.Context(),
		queryer,
		uuid.New(),
		uuid.New(),
		time.Now(),
		time.Hour,
	)
	if !errors.Is(err, dependencyErr) {
		t.Fatalf("queryCurrentSessionGeneration() error = %v, want dependency error", err)
	}
	if valid {
		t.Fatal("queryCurrentSessionGeneration() = true on query error")
	}
}
