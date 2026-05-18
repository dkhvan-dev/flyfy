package main

import (
	"context"
	"flag"
	"os"
	"time"

	guideratingadapter "github.com/dkhvan-dev/flyfy/backend/services/excursion-service/internal/adapter/guiderating"
	"github.com/dkhvan-dev/flyfy/backend/services/excursion-service/internal/adapter/repository"
	"github.com/dkhvan-dev/flyfy/backend/services/excursion-service/internal/config"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"
)

func main() {
	windowMonths := flag.Int("window-months", 3, "number of past months included in guide rating recalculation")
	flag.Parse()

	ctx := context.Background()
	cfg, err := config.Load(ctx)
	if err != nil {
		log.Fatal().Err(err).Msg("load config")
	}
	configureLogger(cfg)

	pool, err := newPostgresPool(ctx, cfg)
	if err != nil {
		log.Fatal().Err(err).Msg("initialize postgres")
	}
	defer pool.Close()

	now := time.Now().UTC()
	from := now.AddDate(0, -*windowMonths, 0)
	repo := repository.NewPGExcursionRepository(pool)
	stats, err := repo.CalculateGuideReviewStats(ctx, from, now)
	if err != nil {
		log.Fatal().Err(err).Msg("calculate guide review stats")
	}

	snapshots := make([]guideratingadapter.Snapshot, 0, len(stats))
	for _, item := range stats {
		snapshots = append(snapshots, guideratingadapter.Snapshot{
			GuideProfileID: item.GuideProfileID,
			RatingAvg:      item.RatingAvg,
			ReviewsCount:   item.ReviewsCount,
		})
	}

	client := guideratingadapter.NewClient(cfg.GuideService.BaseURL, cfg.Security.InternalServiceToken)
	if err = client.ApplySnapshots(ctx, snapshots); err != nil {
		log.Fatal().Err(err).Msg("apply guide rating snapshots")
	}
	log.Info().
		Int("guides", len(snapshots)).
		Time("window_from", from).
		Time("window_to", now).
		Msg("guide ratings recalculated")
}

func configureLogger(cfg *config.Config) {
	level, err := zerolog.ParseLevel(cfg.Log.Level)
	if err != nil {
		level = zerolog.InfoLevel
	}
	zerolog.SetGlobalLevel(level)
	log.Logger = log.Output(zerolog.ConsoleWriter{Out: os.Stderr, TimeFormat: time.RFC3339})
}

func newPostgresPool(ctx context.Context, cfg *config.Config) (*pgxpool.Pool, error) {
	poolCfg, err := pgxpool.ParseConfig(cfg.DB.DSN())
	if err != nil {
		return nil, err
	}
	poolCfg.MaxConns = cfg.DB.MaxConns
	poolCfg.MinConns = cfg.DB.MinConns
	poolCfg.MaxConnLifetime = cfg.DB.ParsedMaxConnLifetime()
	poolCfg.MaxConnIdleTime = cfg.DB.ParsedMaxConnIdleTime()
	return pgxpool.NewWithConfig(ctx, poolCfg)
}
