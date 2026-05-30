package main

import (
	"context"
	"flag"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"

	grpcadapter "kz/inflap/backend/services/excursion-service/internal/adapter/grpc"
	guideadapter "kz/inflap/backend/services/excursion-service/internal/adapter/guide"
	"kz/inflap/backend/services/excursion-service/internal/config"
	"kz/inflap/backend/services/excursion-service/internal/domain/port"
)

func main() {
	var (
		batchSize = flag.Int("batch-size", 200, "number of distinct guide users to process per batch")
		dryRun    = flag.Bool("dry-run", false, "load snapshots without updating excursion_offers")
	)
	flag.Parse()

	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	cfg, err := config.Load(ctx)
	if err != nil {
		log.Fatal().Err(err).Msg("load config")
	}
	configureLogger(cfg)

	poolCfg, err := pgxpool.ParseConfig(cfg.DB.DSN())
	if err != nil {
		log.Fatal().Err(err).Msg("parse postgres config")
	}
	poolCfg.MaxConns = cfg.DB.MaxConns
	poolCfg.MinConns = cfg.DB.MinConns
	poolCfg.MaxConnLifetime = cfg.DB.ParsedMaxConnLifetime()
	poolCfg.MaxConnIdleTime = cfg.DB.ParsedMaxConnIdleTime()

	pool, err := pgxpool.NewWithConfig(ctx, poolCfg)
	if err != nil {
		log.Fatal().Err(err).Msg("initialize postgres")
	}
	defer pool.Close()

	guideClient, err := guideadapter.New(
		cfg.GuideService.Target,
		grpc.WithTransportCredentials(insecure.NewCredentials()),
		grpc.WithUnaryInterceptor(grpcadapter.InternalTokenInterceptor(
			cfg.Security.InternalServiceToken,
			cfg.App.Name,
		)),
	)
	if err != nil {
		log.Fatal().Err(err).Msg("dial guide-service")
	}
	defer guideClient.Close()

	processed, updated, failed := backfill(ctx, pool, guideClient, *batchSize, *dryRun)
	log.Info().
		Int("processedGuideUsers", processed).
		Int64("updatedOffers", updated).
		Int("failedGuideUsers", failed).
		Bool("dryRun", *dryRun).
		Msg("guide search snapshot backfill finished")
}

func backfill(
	ctx context.Context,
	pool *pgxpool.Pool,
	guideClient *guideadapter.Client,
	batchSize int,
	dryRun bool,
) (int, int64, int) {
	if batchSize <= 0 {
		batchSize = 200
	}

	var (
		lastGuideUserID uuid.UUID
		processed       int
		updated         int64
		failed          int
	)

	for {
		guideUserIDs, err := loadGuideUserIDs(ctx, pool, lastGuideUserID, batchSize)
		if err != nil {
			log.Fatal().Err(err).Msg("load guide user ids")
		}
		if len(guideUserIDs) == 0 {
			return processed, updated, failed
		}

		for _, guideUserID := range guideUserIDs {
			lastGuideUserID = guideUserID
			processed++

			permission, err := guideClient.VerifyExcursionGuide(ctx, guideUserID)
			if err != nil {
				failed++
				log.Warn().Err(err).Stringer("guideUserID", guideUserID).Msg("skip guide snapshot")
				continue
			}

			displayName := strings.TrimSpace(permission.DisplayName)
			nickname := strings.TrimSpace(permission.Nickname)
			firstName := strings.TrimSpace(permission.FirstName)
			lastName := strings.TrimSpace(permission.LastName)
			searchText := strings.TrimSpace(permission.GuideSearchText)
			if searchText == "" {
				searchText = strings.TrimSpace(strings.Join([]string{
					displayName,
					nickname,
					firstName,
					lastName,
					guideUserID.String(),
				}, " "))
			}

			if dryRun {
				log.Info().
					Stringer("guideUserID", guideUserID).
					Str("displayName", displayName).
					Str("nickname", nickname).
					Str("firstName", firstName).
					Str("lastName", lastName).
					Str("searchText", searchText).
					Msg("would update guide search snapshot")
				continue
			}

			rowsUpdated, err := updateGuideSnapshot(ctx, pool, guideUserID, permission, searchText)
			if err != nil {
				failed++
				log.Warn().Err(err).Stringer("guideUserID", guideUserID).Msg("update guide snapshot")
				continue
			}
			updated += rowsUpdated
		}
	}
}

func loadGuideUserIDs(
	ctx context.Context,
	pool *pgxpool.Pool,
	after uuid.UUID,
	limit int,
) ([]uuid.UUID, error) {
	const query = `
		SELECT guide_user_id
		FROM (
			SELECT DISTINCT guide_user_id
			FROM excursion_offers
			WHERE deleted_at IS NULL
			  AND (guide_display_name = '' OR guide_search_text = '')
			UNION
			SELECT DISTINCT guide_user_id
			FROM excursions
			WHERE deleted_at IS NULL
			  AND (
				guide_display_name = ''
				OR guide_nickname = ''
				OR guide_first_name = ''
				OR guide_last_name = ''
				OR guide_search_text = ''
			  )
		) AS candidates
		WHERE guide_user_id > $1
		ORDER BY guide_user_id ASC
		LIMIT $2
	`
	rows, err := pool.Query(ctx, query, after, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	result := make([]uuid.UUID, 0, limit)
	for rows.Next() {
		var guideUserID uuid.UUID
		if err = rows.Scan(&guideUserID); err != nil {
			return nil, err
		}
		result = append(result, guideUserID)
	}
	return result, rows.Err()
}

func updateGuideSnapshot(
	ctx context.Context,
	pool *pgxpool.Pool,
	guideUserID uuid.UUID,
	permission port.GuideExcursionPermission,
	searchText string,
) (int64, error) {
	displayName := strings.TrimSpace(permission.DisplayName)
	nickname := strings.TrimSpace(permission.Nickname)
	firstName := strings.TrimSpace(permission.FirstName)
	lastName := strings.TrimSpace(permission.LastName)
	const offerQuery = `
		UPDATE excursion_offers
		SET guide_display_name = $2,
		    guide_search_text = $3
		WHERE guide_user_id = $1
		  AND deleted_at IS NULL
		  AND (guide_display_name IS DISTINCT FROM $2 OR guide_search_text IS DISTINCT FROM $3)
	`
	offerTag, err := pool.Exec(ctx, offerQuery, guideUserID, displayName, searchText)
	if err != nil {
		return 0, err
	}
	const excursionQuery = `
		UPDATE excursions
		SET guide_rating_avg = $2,
		    guide_reviews_count = $3,
		    guide_experience_years = $4,
		    guide_display_name = $5,
		    guide_nickname = $6,
		    guide_first_name = $7,
		    guide_last_name = $8,
		    guide_search_text = $9
		WHERE guide_user_id = $1
		  AND deleted_at IS NULL
		  AND (
			guide_rating_avg IS DISTINCT FROM $2
			OR guide_reviews_count IS DISTINCT FROM $3
			OR guide_experience_years IS DISTINCT FROM $4
			OR guide_display_name IS DISTINCT FROM $5
			OR guide_nickname IS DISTINCT FROM $6
			OR guide_first_name IS DISTINCT FROM $7
			OR guide_last_name IS DISTINCT FROM $8
			OR guide_search_text IS DISTINCT FROM $9
		  )
	`
	excursionTag, err := pool.Exec(
		ctx,
		excursionQuery,
		guideUserID,
		permission.RatingAvg,
		permission.ReviewsCount,
		permission.ExperienceYears,
		displayName,
		nickname,
		firstName,
		lastName,
		searchText,
	)
	if err != nil {
		return 0, err
	}
	return offerTag.RowsAffected() + excursionTag.RowsAffected(), nil
}

func configureLogger(cfg *config.Config) {
	level, err := zerolog.ParseLevel(cfg.Log.Level)
	if err != nil {
		level = zerolog.InfoLevel
	}
	zerolog.SetGlobalLevel(level)
	log.Logger = log.Output(zerolog.ConsoleWriter{Out: os.Stderr, TimeFormat: time.RFC3339})
}
