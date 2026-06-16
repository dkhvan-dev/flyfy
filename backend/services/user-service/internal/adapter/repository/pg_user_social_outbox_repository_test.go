package repository

import (
	"context"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
)

func TestUserSocialOutboxMigrationDefinesTransactionalReadModelEvents(t *testing.T) {
	up, err := os.ReadFile("../../../migrations/013_user_social_outbox.up.sql")
	if err != nil {
		t.Fatalf("read user social outbox migration: %v", err)
	}
	migration := string(up)
	for _, needle := range []string{
		"CREATE TABLE IF NOT EXISTS user_social_outbox",
		"viewer_user_id uuid NOT NULL",
		"target_user_id uuid NOT NULL",
		"edge_type text NOT NULL",
		"active boolean NOT NULL",
		"source_key text NOT NULL",
		"source_updated_at timestamp with time zone DEFAULT now() NOT NULL",
		"user_social_outbox_source_key_key",
		"user_social_outbox_edge_type_check",
		"user_social_outbox_event_type_check",
		"user.follow.created",
		"user.follow.deleted",
		"user.friendship.created",
		"user.friendship.deleted",
		"idx_user_social_outbox_due",
	} {
		if !strings.Contains(migration, needle) {
			t.Fatalf("user social outbox migration must contain %q", needle)
		}
	}

	down, err := os.ReadFile("../../../migrations/013_user_social_outbox.down.sql")
	if err != nil {
		t.Fatalf("read user social outbox rollback migration: %v", err)
	}
	if !strings.Contains(string(down), "DROP TABLE IF EXISTS user_social_outbox") {
		t.Fatalf("rollback migration must drop user_social_outbox")
	}
}

func TestUserSocialMutationsEnqueueOutboxEventsAtomically(t *testing.T) {
	source, err := os.ReadFile("pg_user_repository.go")
	if err != nil {
		t.Fatalf("read pg user repository source: %v", err)
	}
	sql := string(source)
	for _, needle := range []string{
		"WITH inserted AS (",
		"INSERT INTO user_follows",
		"INSERT INTO user_social_outbox",
		"source_key",
		"ON CONFLICT (source_key) DO NOTHING",
		"user.follow.created",
		"user.follow.deleted",
		"user.friendship.created",
		"user.friendship.deleted",
		"UNION ALL",
		"WHERE status = 'ACCEPTED'",
	} {
		if !strings.Contains(sql, needle) {
			t.Fatalf("user social mutation SQL must contain %q", needle)
		}
	}
}

func TestRepositoryBackfillsExistingSocialEdgesIdempotently(t *testing.T) {
	source, err := os.ReadFile("pg_user_social_outbox_repository.go")
	if err != nil {
		t.Fatalf("read pg user social outbox repository source: %v", err)
	}
	sql := string(source)
	for _, needle := range []string{
		"func (r *PGUserRepository) BackfillFeedSocialOutbox",
		"INSERT INTO user_social_outbox",
		"FROM user_follows",
		"FROM user_friendships",
		"status = 'ACCEPTED'",
		"concat('backfill:following:'",
		"concat('backfill:friend:'",
		"ON CONFLICT (source_key) DO NOTHING",
		"user.follow.created",
		"user.friendship.created",
		"UNION ALL",
	} {
		if !strings.Contains(sql, needle) {
			t.Fatalf("feed social backfill SQL must contain %q", needle)
		}
	}
}

func TestPGUserRepositoryBackfillsExistingSocialEdgesIntoOutbox(t *testing.T) {
	dsn := os.Getenv("USER_SERVICE_REPOSITORY_TEST_DSN")
	if dsn == "" {
		t.Skip("set USER_SERVICE_REPOSITORY_TEST_DSN to run repository integration tests")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, dsn)
	if err != nil {
		t.Fatalf("connect test database: %v", err)
	}
	defer pool.Close()

	repo := NewPGUserRepository(pool)
	now := time.Now().UTC().Truncate(time.Second)
	followerID := uuid.New()
	followedID := uuid.New()
	friendRequesterID := uuid.New()
	friendAddresseeID := uuid.New()
	userIDs := []uuid.UUID{followerID, followedID, friendRequesterID, friendAddresseeID}

	cleanup := func() {
		_, _ = pool.Exec(context.Background(), `
			DELETE FROM user_social_outbox
			WHERE viewer_user_id = ANY($1::uuid[])
			   OR target_user_id = ANY($1::uuid[])
		`, userIDs)
		_, _ = pool.Exec(context.Background(), `
			DELETE FROM user_friendships
			WHERE requester_user_id = ANY($1::uuid[])
			   OR addressee_user_id = ANY($1::uuid[])
		`, userIDs)
		_, _ = pool.Exec(context.Background(), `
			DELETE FROM user_follows
			WHERE follower_user_id = ANY($1::uuid[])
			   OR followed_user_id = ANY($1::uuid[])
		`, userIDs)
		_, _ = pool.Exec(context.Background(), `DELETE FROM users WHERE id = ANY($1::uuid[])`, userIDs)
	}
	cleanup()
	t.Cleanup(cleanup)

	for _, userID := range userIDs {
		if _, err := pool.Exec(ctx, `
			INSERT INTO users (id, auth_subject_id, status, created_at, updated_at)
			VALUES ($1, $2, 'ACTIVE', $3, $3)
		`, userID, "feed-social-backfill-"+userID.String(), now); err != nil {
			t.Fatalf("insert test user %s: %v", userID, err)
		}
	}
	if _, err := pool.Exec(ctx, `
		INSERT INTO user_follows (follower_user_id, followed_user_id, created_at)
		VALUES ($1, $2, $3)
	`, followerID, followedID, now.Add(-3*time.Minute)); err != nil {
		t.Fatalf("insert test follow edge: %v", err)
	}
	if _, err := pool.Exec(ctx, `
		INSERT INTO user_friendships (
			id, requester_user_id, addressee_user_id, status, requested_at, responded_at, updated_at
		) VALUES ($1, $2, $3, 'ACCEPTED', $4, $5, $5)
	`, uuid.New(), friendRequesterID, friendAddresseeID, now.Add(-2*time.Minute), now.Add(-time.Minute)); err != nil {
		t.Fatalf("insert test friendship edge: %v", err)
	}

	if _, err := repo.BackfillFeedSocialOutbox(ctx, now); err != nil {
		t.Fatalf("BackfillFeedSocialOutbox returned error: %v", err)
	}
	if _, err := repo.BackfillFeedSocialOutbox(ctx, now.Add(time.Second)); err != nil {
		t.Fatalf("second BackfillFeedSocialOutbox returned error: %v", err)
	}

	expected := map[string]struct {
		eventType    string
		viewerUserID uuid.UUID
		targetUserID uuid.UUID
		edgeType     string
	}{
		"backfill:following:" + followerID.String() + ":" + followedID.String(): {
			eventType:    "user.follow.created",
			viewerUserID: followerID,
			targetUserID: followedID,
			edgeType:     "following",
		},
		"backfill:friend:" + friendRequesterID.String() + ":" + friendAddresseeID.String(): {
			eventType:    "user.friendship.created",
			viewerUserID: friendRequesterID,
			targetUserID: friendAddresseeID,
			edgeType:     "friend",
		},
		"backfill:friend:" + friendAddresseeID.String() + ":" + friendRequesterID.String(): {
			eventType:    "user.friendship.created",
			viewerUserID: friendAddresseeID,
			targetUserID: friendRequesterID,
			edgeType:     "friend",
		},
	}

	rows, err := pool.Query(ctx, `
		SELECT source_key, event_type, viewer_user_id, target_user_id, edge_type, active, COUNT(*) OVER (PARTITION BY source_key)
		FROM user_social_outbox
		WHERE source_key = ANY($1::text[])
		ORDER BY source_key ASC
	`, mapKeys(expected))
	if err != nil {
		t.Fatalf("query backfilled outbox events: %v", err)
	}
	defer rows.Close()

	seen := make(map[string]bool, len(expected))
	for rows.Next() {
		var sourceKey string
		var eventType string
		var viewerUserID uuid.UUID
		var targetUserID uuid.UUID
		var edgeType string
		var active bool
		var duplicateCount int
		if err := rows.Scan(&sourceKey, &eventType, &viewerUserID, &targetUserID, &edgeType, &active, &duplicateCount); err != nil {
			t.Fatalf("scan backfilled outbox event: %v", err)
		}
		want, ok := expected[sourceKey]
		if !ok {
			t.Fatalf("unexpected source key %q", sourceKey)
		}
		if duplicateCount != 1 {
			t.Fatalf("source key %q duplicate count = %d, want 1", sourceKey, duplicateCount)
		}
		if eventType != want.eventType ||
			viewerUserID != want.viewerUserID ||
			targetUserID != want.targetUserID ||
			edgeType != want.edgeType ||
			!active {
			t.Fatalf("event %q = %s/%s/%s/%s active=%v, want %+v active=true", sourceKey, eventType, viewerUserID, targetUserID, edgeType, active, want)
		}
		seen[sourceKey] = true
	}
	if err := rows.Err(); err != nil {
		t.Fatalf("iterate backfilled outbox events: %v", err)
	}
	if len(seen) != len(expected) {
		t.Fatalf("backfilled source keys = %v, want %d keys", seen, len(expected))
	}
}

func mapKeys[T any](items map[string]T) []string {
	keys := make([]string, 0, len(items))
	for key := range items {
		keys = append(keys, key)
	}
	return keys
}
