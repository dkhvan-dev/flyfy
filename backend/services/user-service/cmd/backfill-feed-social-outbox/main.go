package main

import (
	"context"
	"flag"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"

	"kz/inflap/backend/pkg/transportauth"
	feedserviceadapter "kz/inflap/backend/services/user-service/internal/adapter/feedservice"
	"kz/inflap/backend/services/user-service/internal/adapter/repository"
	"kz/inflap/backend/services/user-service/internal/app"
	"kz/inflap/backend/services/user-service/internal/config"
)

func main() {
	drain := flag.Bool("drain", false, "publish due social outbox events to feed-service after enqueueing backfill events")
	maxDrainBatches := flag.Int("max-drain-batches", 0, "maximum social outbox batches to process when -drain is enabled; 0 means drain until the outbox is empty")
	flag.Parse()

	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	cfg, err := config.Load(ctx)
	if err != nil {
		log.Fatal().Err(err).Msg("failed to load config")
	}
	setupLogger(cfg)

	pool, err := newPostgresPool(ctx, cfg)
	if err != nil {
		log.Fatal().Err(err).Msg("failed to initialize postgres pool")
	}
	defer pool.Close()

	inserted, err := backfillFeedSocialOutbox(ctx, pool)
	if err != nil {
		log.Fatal().Err(err).Msg("failed to backfill feed social outbox")
	}
	log.Info().Int64("inserted_events", inserted).Msg("feed social outbox backfill completed")

	if *drain {
		drained, batches, err := drainFeedSocialOutbox(ctx, pool, cfg, *maxDrainBatches)
		if err != nil {
			log.Fatal().Err(err).Msg("failed to drain feed social outbox")
		}
		log.Info().
			Int("drained_events", drained).
			Int("drain_batches", batches).
			Msg("feed social outbox drain completed")
	}
}

func backfillFeedSocialOutbox(ctx context.Context, pool *pgxpool.Pool) (int64, error) {
	userRepo := repository.NewPGUserRepository(pool)
	inserted, err := userRepo.BackfillFeedSocialOutbox(ctx, time.Now().UTC())
	if err != nil {
		return 0, fmt.Errorf("insert feed social outbox backfill events: %w", err)
	}
	return inserted, nil
}

func drainFeedSocialOutbox(ctx context.Context, pool *pgxpool.Pool, cfg *config.Config, maxBatches int) (int, int, error) {
	maxDrainBatches := maxBatches
	if maxDrainBatches < 0 {
		maxDrainBatches = 0
	}
	maxBatches = maxDrainBatches
	userRepo := repository.NewPGUserRepository(pool)
	feedHTTPClient, err := newFeedServiceHTTPClient(cfg)
	if err != nil {
		return 0, 0, err
	}
	publisher := feedserviceadapter.New(
		cfg.FeedService.HTTPURL,
		cfg.Security.InternalServiceToken,
		"user-service-backfill",
		cfg.FeedService.RequestTimeout,
		feedserviceadapter.WithHTTPClient(feedHTTPClient),
	)
	worker := app.NewUserSocialOutboxWorker(
		userRepo,
		publisher,
		app.UserSocialOutboxWorkerConfig{
			BatchSize:    cfg.Social.WorkerBatchSize,
			MaxAttempts:  cfg.Social.WorkerMaxAttempts,
			BaseBackoff:  cfg.Social.WorkerBaseBackoff,
			PollInterval: cfg.Social.WorkerPollInterval,
		},
	)

	var drained int
	var batches int
	for {
		if maxBatches > 0 && batches >= maxBatches {
			return drained, batches, nil
		}
		stats, err := worker.ProcessOnce(ctx, time.Now().UTC())
		if err != nil {
			return drained, batches, err
		}
		if stats.Fetched == 0 {
			return drained, batches, nil
		}
		batches++
		drained += stats.Delivered
		log.Info().
			Int("fetched", stats.Fetched).
			Int("published", stats.Published).
			Int("delivered", stats.Delivered).
			Int("failed", stats.Failed).
			Int("invalid", stats.Invalid).
			Msg("feed social outbox drain batch completed")
	}
	return drained, batches, nil
}

func newFeedServiceHTTPClient(cfg *config.Config) (*http.Client, error) {
	client, err := transportauth.NewHTTPClient(
		cfg.MTLS.ClientConfig(transportauth.ServerNameFromTarget(cfg.FeedService.HTTPURL)),
		cfg.FeedService.RequestTimeout,
	)
	if err != nil {
		return nil, fmt.Errorf("initialize feed-service mTLS transport: %w", err)
	}
	return client, nil
}

func newPostgresPool(ctx context.Context, cfg *config.Config) (*pgxpool.Pool, error) {
	poolConfig, err := pgxpool.ParseConfig(cfg.Postgres.DSN())
	if err != nil {
		return nil, err
	}

	poolConfig.MaxConns = cfg.Postgres.MaxOpenConns
	poolConfig.MinConns = cfg.Postgres.MinOpenConns
	poolConfig.MaxConnLifetime = cfg.Postgres.ParsedMaxConnLifetime()
	poolConfig.MaxConnIdleTime = cfg.Postgres.ParsedMaxConnIdleTime()

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
