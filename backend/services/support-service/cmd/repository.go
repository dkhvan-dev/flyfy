package main

import (
	"context"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"

	"kz/inflap/backend/services/support-service/internal/adapter/repository"
	"kz/inflap/backend/services/support-service/internal/app"
	"kz/inflap/backend/services/support-service/internal/config"
)

func newHelpRepository(ctx context.Context, cfg config.Config) (app.HelpRepository, func(), error) {
	if !cfg.DB.Enabled() {
		return repository.NewMemoryRepository(nil), func() {}, nil
	}

	pool, err := newPostgresPool(ctx, cfg)
	if err != nil {
		return nil, func() {}, err
	}

	return repository.NewPGRepository(pool), pool.Close, nil
}

func newPostgresPool(ctx context.Context, cfg config.Config) (*pgxpool.Pool, error) {
	poolConfig, err := pgxpool.ParseConfig(cfg.DB.URL)
	if err != nil {
		return nil, fmt.Errorf("parse support database url: %w", err)
	}

	poolConfig.MinConns = 0
	poolConfig.MaxConns = 10

	pool, err := pgxpool.NewWithConfig(ctx, poolConfig)
	if err != nil {
		return nil, fmt.Errorf("create support database pool: %w", err)
	}

	pingCtx, cancel := context.WithTimeout(ctx, 5*time.Second)
	defer cancel()
	if err := pool.Ping(pingCtx); err != nil {
		pool.Close()
		return nil, fmt.Errorf("ping support database: %w", err)
	}

	return pool, nil
}
