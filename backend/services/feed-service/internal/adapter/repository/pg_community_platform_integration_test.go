package repository

import (
	"context"
	"errors"
	"os"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"kz/inflap/backend/services/feed-service/internal/domain/model"
	"kz/inflap/backend/services/feed-service/internal/domain/port"
)

func TestPGPostRepositoryMaterializesCommunityInstancesAgainstLiveDB(t *testing.T) {
	dsn := os.Getenv("FEED_SERVICE_REPOSITORY_TEST_DSN")
	if dsn == "" {
		t.Skip("set FEED_SERVICE_REPOSITORY_TEST_DSN to run live repository materialization test")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, dsn)
	if err != nil {
		t.Fatalf("connect test database: %v", err)
	}
	defer pool.Close()

	repo := NewPGPostRepository(pool)
	result, err := repo.MaterializeCommunityInstances(ctx, model.CommunityInstanceMaterializationFilter{
		CountryCode: "VN",
		CityID:      "da-nang",
		ScopeType:   "CITY",
		Limit:       50,
	})
	if err != nil {
		t.Fatalf("materialize community instances: %v", err)
	}
	if result == nil || result.MaterializedCount == 0 {
		t.Fatalf("expected materialized community instances, got %#v", result)
	}

	var instanceCount int
	if err = pool.QueryRow(
		ctx,
		`SELECT COUNT(*)
		 FROM community_instances
		 WHERE country_code = 'VN'
		   AND city_id = 'da-nang'
		   AND scope_type = 'CITY'
		   AND community_id IS NOT NULL`,
	).Scan(&instanceCount); err != nil {
		t.Fatalf("count materialized instances: %v", err)
	}
	if instanceCount == 0 {
		t.Fatalf("expected persisted community instances for VN/da-nang")
	}
}

func TestFeedCandidatePageCompletenessAgainstLiveDB(t *testing.T) {
	dsn := os.Getenv("FEED_SERVICE_REPOSITORY_TEST_DSN")
	if dsn == "" {
		t.Skip("set FEED_SERVICE_REPOSITORY_TEST_DSN to run live feed completeness test")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	pool, err := pgxpool.New(ctx, dsn)
	if err != nil {
		t.Fatalf("connect test database: %v", err)
	}
	defer pool.Close()

	const limit = 20
	var eligibleCount int
	if err = pool.QueryRow(ctx, `
		SELECT COUNT(*)
		FROM post_feed_items fi
		JOIN posts s ON s.id = fi.post_id
		WHERE fi.is_visible = TRUE
		  AND (s.expires_at IS NULL OR s.expires_at > NOW())
	`).Scan(&eligibleCount); err != nil {
		t.Fatalf("count eligible feed candidates: %v", err)
	}
	if eligibleCount == 0 {
		t.Skip("feed fixture is required for live completeness test")
	}

	wantCount := eligibleCount
	if wantCount > limit {
		wantCount = limit
	}
	posts, err := NewPGPostRepository(pool).ListFeedPosts(ctx, model.PostListFilter{
		CandidateSource: model.PostCandidateSourcePopular,
		Limit:           limit,
	})
	if err != nil {
		t.Fatalf("list popular feed candidates: %v", err)
	}
	if len(posts) != wantCount {
		t.Fatalf("popular candidate page size = %d, want %d from %d eligible posts", len(posts), wantCount, eligibleCount)
	}
}

func TestPostPublishCooldownReservationAgainstLiveDB(t *testing.T) {
	dsn := os.Getenv("FEED_SERVICE_REPOSITORY_TEST_DSN")
	if dsn == "" {
		t.Skip("set FEED_SERVICE_REPOSITORY_TEST_DSN to run live cooldown reservation test")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	pool, err := pgxpool.New(ctx, dsn)
	if err != nil {
		t.Fatalf("connect test database: %v", err)
	}
	defer pool.Close()

	authorID := uuid.New()
	firstPostID := uuid.New()
	secondPostID := uuid.New()
	thirdPostID := uuid.New()
	defer func() {
		cleanupCtx, cleanupCancel := context.WithTimeout(context.Background(), 3*time.Second)
		defer cleanupCancel()
		_, _ = pool.Exec(cleanupCtx, `DELETE FROM post_publish_cooldowns WHERE author_user_id = $1`, authorID)
	}()

	firstTx, err := pool.Begin(ctx)
	if err != nil {
		t.Fatalf("begin first cooldown tx: %v", err)
	}
	defer firstTx.Rollback(ctx)
	if err = reservePostPublishCooldownTx(ctx, firstTx, authorID, firstPostID, 5*time.Minute); err != nil {
		t.Fatalf("reserve first cooldown: %v", err)
	}

	secondResult := make(chan error, 1)
	secondStarted := make(chan struct{})
	go func() {
		tx, beginErr := pool.Begin(ctx)
		if beginErr != nil {
			secondResult <- beginErr
			return
		}
		defer tx.Rollback(ctx)
		close(secondStarted)
		reserveErr := reservePostPublishCooldownTx(ctx, tx, authorID, secondPostID, 5*time.Minute)
		if reserveErr != nil {
			secondResult <- reserveErr
			return
		}
		secondResult <- tx.Commit(ctx)
	}()
	<-secondStarted
	time.Sleep(50 * time.Millisecond)
	if err = firstTx.Commit(ctx); err != nil {
		t.Fatalf("commit first cooldown: %v", err)
	}

	err = <-secondResult
	var cooldownErr *port.PostPublishCooldownError
	if !errors.As(err, &cooldownErr) {
		t.Fatalf("second reservation error = %v, want PostPublishCooldownError", err)
	}
	if cooldownErr.NextAvailableAt.Before(time.Now().UTC().Add(4 * time.Minute)) {
		t.Fatalf("second reservation deadline = %s, want active five-minute cooldown", cooldownErr.NextAvailableAt)
	}

	if _, err = pool.Exec(ctx, `
		UPDATE post_publish_cooldowns
		SET last_published_at = clock_timestamp() - INTERVAL '2 seconds',
			next_available_at = clock_timestamp() - INTERVAL '1 second'
		WHERE author_user_id = $1
	`, authorID); err != nil {
		t.Fatalf("expire cooldown: %v", err)
	}
	if err = reserveCooldownInOwnTx(ctx, pool, authorID, thirdPostID, 5*time.Minute); err != nil {
		t.Fatalf("reserve expired cooldown: %v", err)
	}

	var storedPostID uuid.UUID
	if err = pool.QueryRow(ctx, `
		SELECT last_post_id
		FROM post_publish_cooldowns
		WHERE author_user_id = $1
	`, authorID).Scan(&storedPostID); err != nil {
		t.Fatalf("read refreshed cooldown: %v", err)
	}
	if storedPostID != thirdPostID {
		t.Fatalf("last_post_id = %s, want %s", storedPostID, thirdPostID)
	}
}

func TestCommunityVisitAffinityAggregationAgainstLiveDB(t *testing.T) {
	dsn := os.Getenv("FEED_SERVICE_REPOSITORY_TEST_DSN")
	if dsn == "" {
		t.Skip("set FEED_SERVICE_REPOSITORY_TEST_DSN to run live community affinity test")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	pool, err := pgxpool.New(ctx, dsn)
	if err != nil {
		t.Fatalf("connect test database: %v", err)
	}
	defer pool.Close()

	var communityID uuid.UUID
	if err = pool.QueryRow(ctx, `SELECT id FROM communities ORDER BY created_at LIMIT 1`).Scan(&communityID); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			t.Skip("community fixture is required for live affinity test")
		}
		t.Fatalf("read community fixture: %v", err)
	}

	viewerUserID := uuid.New()
	defer func() {
		cleanupCtx, cleanupCancel := context.WithTimeout(context.Background(), 3*time.Second)
		defer cleanupCancel()
		_, _ = pool.Exec(cleanupCtx, `DELETE FROM post_feed_user_interests WHERE viewer_user_id = $1`, viewerUserID)
		_, _ = pool.Exec(cleanupCtx, `DELETE FROM post_feed_user_community_affinities WHERE viewer_user_id = $1`, viewerUserID)
		_, _ = pool.Exec(cleanupCtx, `DELETE FROM post_feed_events WHERE viewer_user_id = $1`, viewerUserID)
	}()

	repo := NewPGPostRepository(pool)
	firstVisitAt := time.Now().UTC().Add(-48 * time.Hour).Truncate(time.Minute)
	visitTimes := []time.Time{
		firstVisitAt,
		firstVisitAt.Add(6 * time.Minute),
		firstVisitAt.Add(24 * time.Hour),
	}
	events := make([]model.FeedEvent, 0, len(visitTimes))
	for _, visitedAt := range visitTimes {
		events = append(events, meaningfulCommunityVisitEvent(viewerUserID, communityID, visitedAt))
	}
	if err = repo.CreateFeedEvents(ctx, events); err != nil {
		t.Fatalf("create meaningful community visit events: %v", err)
	}

	assertCommunityAffinity := func(wantVisits int, wantDays int, wantScoreMin float64, wantScoreMax float64) {
		t.Helper()
		var visits int
		var days int
		if scanErr := pool.QueryRow(ctx, `
			SELECT meaningful_visit_count, distinct_visit_day_count
			FROM post_feed_user_community_affinities
			WHERE viewer_user_id = $1 AND community_id = $2
		`, viewerUserID, communityID).Scan(&visits, &days); scanErr != nil {
			t.Fatalf("read community affinity: %v", scanErr)
		}
		if visits != wantVisits || days != wantDays {
			t.Fatalf("community affinity visits/days = %d/%d, want %d/%d", visits, days, wantVisits, wantDays)
		}

		var score float64
		if scanErr := pool.QueryRow(ctx, `
			SELECT score
			FROM post_feed_user_interests
			WHERE viewer_user_id = $1 AND entity_type = 'community' AND entity_id = $2
		`, viewerUserID, communityID.String()).Scan(&score); scanErr != nil {
			t.Fatalf("read community interest score: %v", scanErr)
		}
		if score < wantScoreMin || score > wantScoreMax {
			t.Fatalf("community interest score = %.4f, want %.4f..%.4f", score, wantScoreMin, wantScoreMax)
		}
	}

	assertCommunityAffinity(3, 2, 2.09, 2.11)
	if _, err = repo.ListFeedPosts(ctx, model.PostListFilter{
		ViewerUserID:    &viewerUserID,
		CandidateSource: model.PostCandidateSourceInterest,
		Limit:           5,
	}); err != nil {
		t.Fatalf("list interest candidates with frequent community affinity: %v", err)
	}

	tooSoon := meaningfulCommunityVisitEvent(
		viewerUserID,
		communityID,
		visitTimes[len(visitTimes)-1].Add(2*time.Minute),
	)
	if err = repo.CreateFeedEvents(ctx, []model.FeedEvent{tooSoon}); err != nil {
		t.Fatalf("create deduplicated community visit event: %v", err)
	}
	assertCommunityAffinity(3, 2, 2.09, 2.11)
}

func meaningfulCommunityVisitEvent(viewerUserID uuid.UUID, communityID uuid.UUID, visitedAt time.Time) model.FeedEvent {
	return model.FeedEvent{
		ID:           uuid.New(),
		EventID:      uuid.New(),
		ViewerUserID: &viewerUserID,
		EventType:    model.FeedEventTypeDwell,
		Surface:      "content",
		Tab:          "for_you",
		BlockID:      "community:" + communityID.String() + ":profile",
		BlockType:    model.FeedBlockTypeCommunityCard,
		CommunityID:  &communityID,
		OccurredAt:   visitedAt,
		ReceivedAt:   time.Now().UTC(),
		Metadata: map[string]any{
			"source":     "community_profile_visit",
			"action":     "meaningful_visit",
			"entityType": "community",
			"entityId":   communityID.String(),
			"dwellMs":    meaningfulCommunityVisitDwellMS,
		},
	}
}

func reserveCooldownInOwnTx(
	ctx context.Context,
	pool *pgxpool.Pool,
	authorID uuid.UUID,
	postID uuid.UUID,
	cooldown time.Duration,
) error {
	tx, err := pool.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)
	if err = reservePostPublishCooldownTx(ctx, tx, authorID, postID, cooldown); err != nil {
		return err
	}
	return tx.Commit(ctx)
}
