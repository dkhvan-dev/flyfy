package main

import (
	"context"
	"testing"
	"time"

	"kz/inflap/backend/services/support-service/internal/adapter/repository"
	"kz/inflap/backend/services/support-service/internal/config"
)

func TestNewHelpRepositoryUsesMemoryFallbackWithoutDatabaseURL(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), time.Second)
	defer cancel()

	repo, cleanup, err := newHelpRepository(ctx, config.Config{})
	if err != nil {
		t.Fatalf("newHelpRepository returned error: %v", err)
	}
	defer cleanup()

	if _, ok := repo.(*repository.MemoryRepository); !ok {
		t.Fatalf("repo type = %T, want *repository.MemoryRepository", repo)
	}
	articles, err := repo.ListArticles(ctx)
	if err != nil {
		t.Fatalf("ListArticles returned error: %v", err)
	}
	if len(articles) != 0 {
		t.Fatalf("memory fallback articles len = %d, want 0 because Q&A must come from the database", len(articles))
	}
}

func TestNewHelpRepositoryRejectsInvalidDatabaseURL(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), time.Second)
	defer cancel()

	_, cleanup, err := newHelpRepository(ctx, config.Config{
		DB: config.DBConfig{URL: "://not-a-postgres-url"},
	})
	defer cleanup()

	if err == nil {
		t.Fatal("expected invalid database URL error")
	}
}
