package main

import (
	"context"
	"flag"
	"fmt"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/sethvargo/go-envconfig"

	"kz/inflap/backend/services/activity-service/internal/adapter/repository"
	"kz/inflap/backend/services/activity-service/internal/app"
	"kz/inflap/backend/services/activity-service/internal/config"
)

type backfillConfig struct {
	DB          config.DBConfig
	MaxAttempts int `env:"ACTIVITY_TRANSLATION_MAX_ATTEMPTS, default=5"`
}

func main() {
	apply := flag.Bool("apply", false, "create missing activity translation jobs")
	batchSize := flag.Int("batch-size", 100, "number of activities scanned per batch")
	flag.Parse()

	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	var cfg backfillConfig
	if err := envconfig.Process(ctx, &cfg); err != nil {
		fatalf("load backfill config: %v", err)
	}
	poolConfig, err := pgxpool.ParseConfig(cfg.DB.DSN())
	if err != nil {
		fatalf("parse database config: %v", err)
	}
	poolConfig.MaxConns = cfg.DB.MaxConns
	poolConfig.MinConns = cfg.DB.MinConns
	poolConfig.MaxConnIdleTime = cfg.DB.ParsedMaxConnIdleTime()
	poolConfig.MaxConnLifetime = cfg.DB.ParsedMaxConnLifetime()
	pool, err := pgxpool.NewWithConfig(ctx, poolConfig)
	if err != nil {
		fatalf("connect database: %v", err)
	}
	defer pool.Close()
	if err = pool.Ping(ctx); err != nil {
		fatalf("ping database: %v", err)
	}

	repo := repository.NewPGActivityRepository(pool)
	scheduler := app.NewActivityTranslationScheduler(cfg.MaxAttempts)
	afterID := uuid.Nil
	totalActivities := 0
	totalJobs := 0
	for {
		candidates, listErr := repo.ListActivityTranslationBackfillCandidates(ctx, afterID, *batchSize)
		if listErr != nil {
			fatalf("list backfill candidates: %v", listErr)
		}
		if len(candidates) == 0 {
			break
		}
		for _, candidate := range candidates {
			jobs, scheduleErr := scheduler.BuildJobs(
				candidate.ActivityID,
				candidate.SourceLanguage,
				candidate.Title,
				candidate.Description,
				candidate.Translations,
				time.Now().UTC(),
			)
			if scheduleErr != nil {
				fatalf("schedule activity %s: %v", candidate.ActivityID, scheduleErr)
			}
			totalActivities++
			totalJobs += len(jobs)
			if *apply && len(jobs) > 0 {
				if enqueueErr := repo.EnqueueActivityTranslationJobs(ctx, jobs); enqueueErr != nil {
					fatalf("enqueue activity %s translations: %v", candidate.ActivityID, enqueueErr)
				}
			}
			afterID = candidate.ActivityID
		}
	}

	mode := "dry-run"
	if *apply {
		mode = "apply"
	}
	fmt.Printf("mode=%s activities_scanned=%d jobs=%d\n", mode, totalActivities, totalJobs)
}

func fatalf(format string, args ...any) {
	_, _ = fmt.Fprintf(os.Stderr, format+"\n", args...)
	os.Exit(1)
}
