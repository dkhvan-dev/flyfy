package repository

import (
	"context"
	"os"
	"testing"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"

	"kz/inflap/backend/services/feed-service/internal/domain/model"
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
