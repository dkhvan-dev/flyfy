package main

import (
	"context"
	"flag"
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"

	"kz/inflap/backend/pkg/serviceauth"
	"kz/inflap/backend/pkg/transportauth"
	"kz/inflap/backend/services/support-service/internal/adapter/repository"
	searchindexadapter "kz/inflap/backend/services/support-service/internal/adapter/searchindex"
	"kz/inflap/backend/services/support-service/internal/app"
	"kz/inflap/backend/services/support-service/internal/config"
)

func main() {
	dryRun := flag.Bool("dry-run", false, "scan and report search index backfill changes without publishing index events")
	batchSize := flag.Int("batch-size", 100, "number of help articles to scan per database page")
	limit := flag.Int("limit", 0, "maximum number of help articles to scan; 0 means no limit")
	deleteStale := flag.Bool("delete-stale", true, "publish delete events for help articles that are no longer indexable")
	flag.Parse()

	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	cfg, err := config.Load()
	if err != nil {
		slog.Error("load config", "error", err)
		os.Exit(1)
	}
	if !cfg.DB.Enabled() {
		slog.Error("SUPPORT_SERVICE_DATABASE_URL is required for search backfill")
		os.Exit(1)
	}
	if !*dryRun && !cfg.SearchService.Enabled {
		slog.Error("SUPPORT_SERVICE_SEARCH_INDEXING_ENABLED must be true unless -dry-run is used")
		os.Exit(1)
	}

	pool, err := newPostgresPool(ctx, cfg)
	if err != nil {
		slog.Error("initialize postgres", "error", err)
		os.Exit(1)
	}
	defer pool.Close()

	searchIndexOptions, closeSearchIndexAuth, err := newSearchIndexOptions(cfg, *dryRun)
	if err != nil {
		slog.Error("initialize search indexing", "error", err)
		os.Exit(1)
	}
	defer closeSearchIndexAuth()
	indexer := searchindexadapter.New(
		cfg.SearchService.HTTPURL,
		cfg.Security.InternalServiceToken,
		cfg.SearchService.Timeout,
		searchIndexOptions...,
	)

	stats, err := app.BackfillHelpArticleSearchIndex(ctx, repository.NewPGRepository(pool), indexer, app.SearchIndexBackfillOptions{
		BatchSize:   *batchSize,
		Limit:       *limit,
		DryRun:      *dryRun,
		DeleteStale: *deleteStale,
	})
	if err != nil {
		slog.Error("backfill help article search index", "error", err)
		os.Exit(1)
	}

	slog.Info(
		"help article search index backfill completed",
		"dry_run", *dryRun,
		"delete_stale", *deleteStale,
		"scanned", stats.Scanned,
		"upserted", stats.Upserted,
		"deleted", stats.Deleted,
		"skipped", stats.Skipped,
		"failed", stats.Failed,
	)
}

func newSearchIndexOptions(cfg config.Config, dryRun bool) ([]searchindexadapter.Option, func(), error) {
	if dryRun {
		return nil, func() {}, nil
	}
	searchHTTPClient, err := newSearchIndexHTTPClient(cfg)
	if err != nil {
		return nil, func() {}, err
	}
	options := []searchindexadapter.Option{searchindexadapter.WithHTTPClient(searchHTTPClient)}

	if !cfg.TokenService.Enabled() {
		if cfg.App.IsProduction() {
			return nil, func() {}, fmt.Errorf("TOKEN_SERVICE_SECRET is required when support search indexing is enabled in production")
		}
		slog.Warn("support search indexing service JWT auth disabled; falling back to legacy internal token")
		return options, func() {}, nil
	}
	source, err := serviceauth.NewGRPCServiceTokenSource(serviceauth.TokenSourceConfig{
		Target:        cfg.TokenService.Target,
		ServiceID:     cfg.TokenService.ServiceID,
		ServiceSecret: cfg.TokenService.ServiceSecret,
		CallTimeout:   cfg.TokenService.CallTimeout,
		TransportAuth: cfg.MTLS.ClientConfig(transportauth.ServerNameFromTarget(cfg.TokenService.Target)),
	})
	if err != nil {
		return nil, func() {}, err
	}
	options = append(options, searchindexadapter.WithServiceTokenSource(source))
	return options, func() {
		if err := source.Close(); err != nil {
			slog.Warn("close support search indexing token source", "error", err)
		}
	}, nil
}

func newSearchIndexHTTPClient(cfg config.Config) (*http.Client, error) {
	return transportauth.NewHTTPClient(
		cfg.MTLS.ClientConfig(transportauth.ServerNameFromTarget(cfg.SearchService.HTTPURL)),
		cfg.SearchService.Timeout,
	)
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
