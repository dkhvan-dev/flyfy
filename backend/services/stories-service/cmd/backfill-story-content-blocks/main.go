package main

import (
	"context"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"os"
	"os/signal"
	"strconv"
	"strings"
	"syscall"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"

	"kz/inflap/backend/services/stories-service/internal/app"
	"kz/inflap/backend/services/stories-service/internal/domain/model"
)

const (
	defaultBatchSize         = 100
	maxBatchSize             = 1000
	defaultQueryTimeout      = 10 * time.Second
	defaultUpdateTimeout     = 10 * time.Second
	postgresLockTimeout      = 3 * time.Second
	postgresStatementTimeout = 9 * time.Second
)

type legacyStoryRow struct {
	ID      uuid.UUID
	Content string
}

type storyBackfillStore interface {
	LoadLegacyStoryRows(ctx context.Context, after uuid.UUID, limit int) ([]legacyStoryRow, error)
	UpdateStoryDocument(ctx context.Context, storyID uuid.UUID, document model.StoryDocument) (bool, error)
}

type pgStoryBackfillStore struct {
	pool          *pgxpool.Pool
	queryTimeout  time.Duration
	updateTimeout time.Duration
}

func main() {
	var (
		databaseURL = flag.String("database-url", envFirst("STORIES_DATABASE_URL", "DATABASE_URL", "POSTGRES_DSN"), "stories-service PostgreSQL URL")
		dryRun      = flag.Bool("dry-run", envBool("BACKFILL_DRY_RUN", true), "convert and log without updating stories")
		limit       = flag.Int("limit", envInt("BACKFILL_LIMIT", 0), "maximum stories to process; 0 means all")
		batchSize   = flag.Int("batch-size", envInt("BACKFILL_BATCH_SIZE", defaultBatchSize), "number of stories to process per batch")
		logLevel    = flag.String("log-level", envString("LOG_LEVEL", "info"), "log level")
	)
	flag.Parse()

	setupLogger(*logLevel)

	options, err := validateBackfillOptions(backfillOptions{
		DryRun:    *dryRun,
		Limit:     *limit,
		BatchSize: *batchSize,
	})
	if err != nil {
		log.Fatal().Err(err).Msg("invalid backfill options")
	}

	dsn := strings.TrimSpace(*databaseURL)
	if dsn == "" {
		dsn, err = postgresDSNFromEnv()
		if err != nil {
			log.Fatal().Err(err).Msg("postgres config is required; set -database-url, STORIES_DATABASE_URL, DATABASE_URL, POSTGRES_DSN, or POSTGRES_HOST/USER/PASSWORD/DB")
		}
	}

	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	poolCfg, err := pgxpool.ParseConfig(dsn)
	if err != nil {
		log.Fatal().Err(err).Msg("parse postgres config")
	}
	applyPostgresRuntimeTimeouts(poolCfg)

	pool, err := pgxpool.NewWithConfig(ctx, poolCfg)
	if err != nil {
		log.Fatal().Err(err).Msg("initialize postgres")
	}
	defer pool.Close()

	pingCtx, cancel := context.WithTimeout(ctx, 5*time.Second)
	defer cancel()
	if err = pool.Ping(pingCtx); err != nil {
		log.Fatal().Err(err).Msg("ping postgres")
	}

	stats, err := backfill(ctx, newPGStoryBackfillStore(pool), options)
	if err != nil {
		log.Fatal().Err(err).Msg("backfill story content blocks")
	}

	log.Info().
		Int("scanned", stats.Scanned).
		Int("converted", stats.Converted).
		Int("updated", stats.Updated).
		Int("skipped", stats.Skipped).
		Int("failed", stats.Failed).
		Bool("dryRun", *dryRun).
		Msg("story content blocks backfill finished")
}

type backfillOptions struct {
	DryRun    bool
	Limit     int
	BatchSize int
}

type backfillStats struct {
	Scanned   int
	Converted int
	Updated   int
	Skipped   int
	Failed    int
}

func backfill(ctx context.Context, store storyBackfillStore, options backfillOptions) (backfillStats, error) {
	options, err := validateBackfillOptions(options)
	if err != nil {
		return backfillStats{}, err
	}

	batchSize := options.BatchSize
	remaining := options.Limit
	var (
		stats  backfillStats
		lastID uuid.UUID
	)

	for {
		currentBatchSize := batchSize
		if remaining > 0 && remaining < currentBatchSize {
			currentBatchSize = remaining
		}

		rows, err := store.LoadLegacyStoryRows(ctx, lastID, currentBatchSize)
		if err != nil {
			return stats, fmt.Errorf("load legacy story rows: %w", err)
		}
		if len(rows) == 0 {
			return stats, nil
		}

		for _, row := range rows {
			lastID = row.ID
			stats.Scanned++

			document, err := app.LegacyStoryContentToDocument(row.ID, row.Content)
			if err != nil {
				stats.Failed++
				log.Warn().Err(err).Stringer("storyID", row.ID).Msg("skip story with invalid legacy content")
				continue
			}
			stats.Converted++

			if options.DryRun {
				log.Info().
					Stringer("storyID", row.ID).
					Int("blockCount", len(document.Blocks)).
					Int("plainTextLength", len([]rune(document.PlainText()))).
					Msg("would backfill story content blocks")
				continue
			}

			updated, err := store.UpdateStoryDocument(ctx, row.ID, document)
			if err != nil {
				stats.Failed++
				log.Warn().Err(err).Stringer("storyID", row.ID).Msg("update story content blocks")
				continue
			}
			if updated {
				stats.Updated++
				log.Info().Stringer("storyID", row.ID).Int("blockCount", len(document.Blocks)).Msg("backfilled story content blocks")
			} else {
				stats.Skipped++
				log.Info().Stringer("storyID", row.ID).Msg("story already backfilled by another process")
			}
		}

		if remaining > 0 {
			remaining -= len(rows)
			if remaining <= 0 {
				return stats, nil
			}
		}
	}
}

func newPGStoryBackfillStore(pool *pgxpool.Pool) *pgStoryBackfillStore {
	return &pgStoryBackfillStore{
		pool:          pool,
		queryTimeout:  defaultQueryTimeout,
		updateTimeout: defaultUpdateTimeout,
	}
}

func (s *pgStoryBackfillStore) LoadLegacyStoryRows(ctx context.Context, after uuid.UUID, limit int) ([]legacyStoryRow, error) {
	const query = `
		SELECT id, content
		FROM stories
		WHERE content_blocks IS NULL
		  AND id > $1
		ORDER BY id ASC
		LIMIT $2
	`

	queryCtx, cancel := context.WithTimeout(ctx, s.queryTimeout)
	defer cancel()

	rows, err := s.pool.Query(queryCtx, query, after, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	result := make([]legacyStoryRow, 0, limit)
	for rows.Next() {
		var row legacyStoryRow
		if err = rows.Scan(&row.ID, &row.Content); err != nil {
			return nil, err
		}
		result = append(result, row)
	}
	return result, rows.Err()
}

func (s *pgStoryBackfillStore) UpdateStoryDocument(ctx context.Context, storyID uuid.UUID, document model.StoryDocument) (bool, error) {
	blocks, err := json.Marshal(document)
	if err != nil {
		return false, fmt.Errorf("marshal story document: %w", err)
	}

	const query = `
		UPDATE stories
		SET content_blocks = $2,
		    content_plain_text = $3,
		    content_schema_version = $4,
		    revision = revision + 1,
		    updated_at = NOW()
		WHERE id = $1
		  AND content_blocks IS NULL
	`
	updateCtx, cancel := context.WithTimeout(ctx, s.updateTimeout)
	defer cancel()

	tag, err := s.pool.Exec(updateCtx, query, storyID, blocks, document.PlainText(), model.StoryDocumentVersion)
	if err != nil {
		return false, err
	}
	return tag.RowsAffected() > 0, nil
}

func validateBackfillOptions(options backfillOptions) (backfillOptions, error) {
	if options.Limit < 0 {
		return options, fmt.Errorf("limit must be >= 0")
	}
	if options.BatchSize <= 0 {
		return options, fmt.Errorf("batch-size must be > 0")
	}
	if options.BatchSize > maxBatchSize {
		return options, fmt.Errorf("batch-size must be <= %d", maxBatchSize)
	}
	return options, nil
}

func applyPostgresRuntimeTimeouts(poolCfg *pgxpool.Config) {
	if poolCfg.ConnConfig.RuntimeParams == nil {
		poolCfg.ConnConfig.RuntimeParams = make(map[string]string, 2)
	}
	poolCfg.ConnConfig.RuntimeParams["lock_timeout"] = postgresLockTimeout.String()
	poolCfg.ConnConfig.RuntimeParams["statement_timeout"] = postgresStatementTimeout.String()
}

func postgresDSNFromEnv() (string, error) {
	host := strings.TrimSpace(os.Getenv("POSTGRES_HOST"))
	user := strings.TrimSpace(os.Getenv("POSTGRES_USER"))
	password := strings.TrimSpace(os.Getenv("POSTGRES_PASSWORD"))
	dbName := strings.TrimSpace(os.Getenv("POSTGRES_DB"))
	if host == "" || user == "" || password == "" || dbName == "" {
		return "", errors.New("missing postgres connection settings")
	}

	port := envInt("POSTGRES_PORT", 5432)
	sslMode := envString("POSTGRES_SSLMODE", "disable")
	return fmt.Sprintf("postgres://%s:%s@%s:%d/%s?sslmode=%s", user, password, host, port, dbName, sslMode), nil
}

func setupLogger(levelRaw string) {
	level, err := zerolog.ParseLevel(strings.TrimSpace(levelRaw))
	if err != nil {
		level = zerolog.InfoLevel
	}
	zerolog.SetGlobalLevel(level)
	log.Logger = zerolog.New(zerolog.ConsoleWriter{
		Out:        os.Stdout,
		TimeFormat: time.RFC3339,
	}).With().Timestamp().Logger()
}

func envFirst(keys ...string) string {
	for _, key := range keys {
		if value := strings.TrimSpace(os.Getenv(key)); value != "" {
			return value
		}
	}
	return ""
}

func envString(key string, fallback string) string {
	if value := strings.TrimSpace(os.Getenv(key)); value != "" {
		return value
	}
	return fallback
}

func envBool(key string, fallback bool) bool {
	value := strings.TrimSpace(os.Getenv(key))
	if value == "" {
		return fallback
	}
	parsed, err := strconv.ParseBool(value)
	if err != nil {
		return fallback
	}
	return parsed
}

func envInt(key string, fallback int) int {
	value := strings.TrimSpace(os.Getenv(key))
	if value == "" {
		return fallback
	}
	parsed, err := strconv.Atoi(value)
	if err != nil {
		return fallback
	}
	return parsed
}
