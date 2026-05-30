package repository

import (
	"context"
	"os"
	"testing"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/dkhvan-dev/flyfy/backend/services/user-service/internal/domain/model"
)

func TestPGUserRepositoryListAdminUsersScansLiveDatabase(t *testing.T) {
	dsn := os.Getenv("USER_SERVICE_REPOSITORY_TEST_DSN")
	if dsn == "" {
		t.Skip("set USER_SERVICE_REPOSITORY_TEST_DSN to run repository integration tests")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, dsn)
	if err != nil {
		t.Fatalf("connect test database: %v", err)
	}
	defer pool.Close()

	repo := NewPGUserRepository(pool)
	if _, _, err := repo.ListAdminUsers(ctx, model.AdminUserListFilter{PageSize: 10}); err != nil {
		t.Fatalf("ListAdminUsers returned error: %v", err)
	}
}
