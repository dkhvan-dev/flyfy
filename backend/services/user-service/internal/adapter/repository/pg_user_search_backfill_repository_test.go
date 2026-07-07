package repository

import (
	"os"
	"strings"
	"testing"
)

func TestUserSearchBackfillRepositoryBuildsFullAggregate(t *testing.T) {
	source, err := os.ReadFile("pg_user_repository.go")
	if err != nil {
		t.Fatalf("read pg user repository source: %v", err)
	}
	sql := string(source)
	for _, needle := range []string{
		"func (r *PGUserRepository) ListUserSearchIndexBackfillAggregates",
		"FROM users u",
		"LEFT JOIN user_profiles p ON p.user_id = u.id",
		"LEFT JOIN user_reputation rep ON rep.user_id = u.id",
		"LEFT JOIN (",
		"COUNT(*)::int AS followers_count",
		"ORDER BY u.created_at ASC, u.id ASC",
		"LIMIT $1 OFFSET $2",
	} {
		if !strings.Contains(sql, needle) {
			t.Fatalf("user search backfill repository must contain %q", needle)
		}
	}
}
