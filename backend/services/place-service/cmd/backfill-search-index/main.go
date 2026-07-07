package main

import (
	"context"
	"flag"
	"net/http"
	"os"
	"os/signal"
	"syscall"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"

	"kz/inflap/backend/pkg/serviceauth"
	"kz/inflap/backend/pkg/transportauth"
	"kz/inflap/backend/services/place-service/internal/adapter/repository"
	searchindexadapter "kz/inflap/backend/services/place-service/internal/adapter/searchindex"
	"kz/inflap/backend/services/place-service/internal/app"
	"kz/inflap/backend/services/place-service/internal/config"
)

func main() {
	dryRun := flag.Bool("dry-run", false, "scan and report search index backfill changes without publishing index events")
	batchSize := flag.Int("batch-size", 100, "number of places to scan per database page")
	limit := flag.Int("limit", 0, "maximum number of places to scan; 0 means no limit")
	deleteStale := flag.Bool("delete-stale", true, "publish delete events for places that are no longer indexable")
	flag.Parse()

	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	cfg, err := config.Load(ctx)
	if err != nil {
		log.Fatal().Err(err).Msg("failed to load config")
	}
	setupLogger(cfg)

	if !*dryRun && !cfg.SearchService.Enabled {
		log.Fatal().Msg("SEARCH_INDEXING_ENABLED must be true unless -dry-run is used")
	}

	pool, err := newPostgresPool(ctx, cfg)
	if err != nil {
		log.Fatal().Err(err).Msg("failed to initialize postgres pool")
	}
	defer pool.Close()

	repo := repository.NewPGPlaceRepository(pool)
	searchIndexOptions, closeSearchIndexAuth := newSearchIndexOptions(cfg, *dryRun)
	defer closeSearchIndexAuth()
	indexer := searchindexadapter.New(
		cfg.SearchService.HTTPURL,
		cfg.Security.InternalServiceToken,
		cfg.SearchService.Timeout,
		searchIndexOptions...,
	)

	stats, err := app.BackfillPlaceSearchIndex(ctx, repo, indexer, app.SearchIndexBackfillOptions{
		BatchSize:   *batchSize,
		Limit:       *limit,
		DryRun:      *dryRun,
		DeleteStale: *deleteStale,
	})
	if err != nil {
		log.Fatal().Err(err).Msg("failed to backfill place search index")
	}

	log.Info().
		Bool("dry_run", *dryRun).
		Bool("delete_stale", *deleteStale).
		Int("scanned", stats.Scanned).
		Int("upserted", stats.Upserted).
		Int("deleted", stats.Deleted).
		Int("skipped", stats.Skipped).
		Int("failed", stats.Failed).
		Msg("place search index backfill completed")
}

func newSearchIndexOptions(cfg *config.Config, dryRun bool) ([]searchindexadapter.Option, func()) {
	if dryRun {
		return nil, func() {}
	}
	searchHTTPClient, err := newSearchIndexHTTPClient(cfg)
	if err != nil {
		log.Fatal().Err(err).Msg("failed to configure search indexing mTLS client")
	}
	options := []searchindexadapter.Option{searchindexadapter.WithHTTPClient(searchHTTPClient)}

	if !cfg.TokenService.Enabled() {
		if cfg.App.IsProduction() {
			log.Fatal().Msg("TOKEN_SERVICE_SECRET is required when search indexing is enabled in production")
		}
		log.Warn().Msg("search indexing service JWT auth disabled; falling back to legacy internal token")
		return options, func() {}
	}
	source, err := serviceauth.NewGRPCServiceTokenSource(serviceauth.TokenSourceConfig{
		Target:        cfg.TokenService.Target,
		ServiceID:     cfg.TokenService.ServiceID,
		ServiceSecret: cfg.TokenService.ServiceSecret,
		CallTimeout:   cfg.TokenService.CallTimeout,
		TransportAuth: cfg.MTLS.ClientConfig(transportauth.ServerNameFromTarget(cfg.TokenService.Target)),
	})
	if err != nil {
		log.Fatal().Err(err).Msg("failed to initialize search indexing service token source")
	}
	options = append(options, searchindexadapter.WithServiceTokenSource(source))
	return options, func() {
		if err := source.Close(); err != nil {
			log.Warn().Err(err).Msg("failed to close search indexing service token source")
		}
	}
}

func newSearchIndexHTTPClient(cfg *config.Config) (*http.Client, error) {
	return transportauth.NewHTTPClient(
		cfg.MTLS.ClientConfig(transportauth.ServerNameFromTarget(cfg.SearchService.HTTPURL)),
		cfg.SearchService.Timeout,
	)
}

func newPostgresPool(ctx context.Context, cfg *config.Config) (*pgxpool.Pool, error) {
	poolConfig, err := pgxpool.ParseConfig(cfg.Postgres.DSN())
	if err != nil {
		return nil, err
	}

	poolConfig.MaxConns = cfg.Postgres.MaxConns
	poolConfig.MinConns = cfg.Postgres.MinConns

	pool, err := pgxpool.NewWithConfig(ctx, poolConfig)
	if err != nil {
		return nil, err
	}
	if err = pool.Ping(ctx); err != nil {
		pool.Close()
		return nil, err
	}
	return pool, nil
}

func setupLogger(cfg *config.Config) {
	level, err := zerolog.ParseLevel(cfg.Log.Level)
	if err != nil {
		level = zerolog.InfoLevel
	}
	zerolog.SetGlobalLevel(level)
	log.Logger = log.Output(zerolog.ConsoleWriter{Out: os.Stderr})
}
