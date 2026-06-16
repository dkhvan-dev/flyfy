package main

import (
	"context"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/redis/go-redis/v9"
	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"
	activityadapter "kz/inflap/backend/services/feed-service/internal/adapter/activity"
	cacheadapter "kz/inflap/backend/services/feed-service/internal/adapter/cache"
	filemanageradapter "kz/inflap/backend/services/feed-service/internal/adapter/filemanager"
	httpadapter "kz/inflap/backend/services/feed-service/internal/adapter/http"
	notificationadapter "kz/inflap/backend/services/feed-service/internal/adapter/notification"
	"kz/inflap/backend/services/feed-service/internal/adapter/repository"
	uservicadapter "kz/inflap/backend/services/feed-service/internal/adapter/userservice"
	"kz/inflap/backend/services/feed-service/internal/app"
	"kz/inflap/backend/services/feed-service/internal/config"
	"kz/inflap/backend/services/feed-service/internal/domain/port"
)

func main() {
	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	cfg, err := config.Load(ctx)
	if err != nil {
		panic(err)
	}

	setupLogger(cfg)
	log.Info().Str("env", cfg.App.Env).Msg("starting feed-service")

	pool, err := newPostgresPool(ctx, cfg)
	if err != nil {
		log.Fatal().Err(err).Msg("failed to initialize postgres pool")
	}
	defer pool.Close()

	userClient, err := uservicadapter.New(
		cfg.UserService.Target,
		cfg.Security.InternalServiceToken,
		"feed-service",
	)
	if err != nil {
		log.Fatal().Err(err).Msg("failed to initialize user-service grpc client")
	}
	defer userClient.Close()

	fileManagerClient, err := filemanageradapter.New(
		cfg.FileManager.Target,
		cfg.Security.InternalServiceToken,
		"feed-service",
	)
	if err != nil {
		log.Fatal().Err(err).Msg("failed to initialize file-manager grpc client")
	}
	defer fileManagerClient.Close()

	feedRankingPolicy := feedRankingPolicyFromConfig(cfg.Feed).Normalized()
	feedCuratedBlockPolicy := feedCuratedBlockPolicyFromConfig(cfg.Feed).Normalized()
	repo := repository.NewPGPostRepository(pool).
		WithFeedRankingPolicy(feedRankingPolicy)
	notificationClient := notificationadapter.New(
		cfg.Notification.HTTPURL,
		cfg.Security.InternalServiceToken,
		"feed-service",
		cfg.Notification.RequestTimeout,
	)
	activityClient := activityadapter.New(
		cfg.Activity.HTTPURL,
		cfg.Security.InternalServiceToken,
		"feed-service",
		cfg.Activity.RequestTimeout,
	)
	postFeedCache, closePostFeedCache := newPostFeedCache(ctx, cfg)
	defer closePostFeedCache()
	useCase := app.NewPostUseCase(repo, userClient, cfg.Public.PostShareBaseURL).
		WithPostMediaBinder(fileManagerClient).
		WithPostNotificationGateway(notificationClient).
		WithFeedCuratedBlockPolicy(feedCuratedBlockPolicy).
		WithFeedExperimentAssignment(feedRankingPolicy.ExperimentKey).
		WithFeedExperimentVariants(cfg.Feed.RankingExperimentVariants).
		WithFeedExperimentPolicyOverrides(cfg.Feed.RankingExperimentPolicies)
	if postFeedCache != nil {
		useCase.WithPostFeedCache(postFeedCache, cfg.Redis.FeedTTL, cfg.Redis.TrayTTL)
	}
	if cfg.Feed.ProjectionWorkerEnabled {
		feedProjectionWorker := app.NewPostFeedProjectionWorker(repo, app.PostFeedProjectionWorkerConfig{
			PollInterval: cfg.Feed.ProjectionWorkerPollInterval,
			BatchSize:    cfg.Feed.ProjectionWorkerBatchSize,
			MaxAttempts:  cfg.Feed.ProjectionWorkerMaxAttempts,
			BaseBackoff:  cfg.Feed.ProjectionWorkerBaseBackoff,
		})
		if postFeedCache != nil {
			feedProjectionWorker.WithPostFeedCache(postFeedCache)
		}
		go feedProjectionWorker.Start(ctx)
		log.Info().Msg("post feed projection worker started")
	}
	if cfg.Feed.ActivityIntentWorkerEnabled {
		activityIntentWorker := app.NewPostActivityIntentWorker(repo, activityClient, app.PostActivityIntentWorkerConfig{
			PollInterval: cfg.Feed.ActivityIntentWorkerPollInterval,
			BatchSize:    cfg.Feed.ActivityIntentWorkerBatchSize,
			MaxAttempts:  cfg.Feed.ActivityIntentWorkerMaxAttempts,
			BaseBackoff:  cfg.Feed.ActivityIntentWorkerBaseBackoff,
		})
		go activityIntentWorker.Start(ctx)
		log.Info().Msg("post activity intent worker started")
	}

	handler := httpadapter.NewHandler(useCase)
	mux := http.NewServeMux()
	handler.Register(mux)

	server := &http.Server{
		Addr:         cfg.HTTP.Address(),
		Handler:      httpadapter.Chain(cfg, withRequestLogging(mux)),
		ReadTimeout:  cfg.HTTP.ReadTimeout,
		WriteTimeout: cfg.HTTP.WriteTimeout,
		IdleTimeout:  cfg.HTTP.IdleTimeout,
	}

	go func() {
		log.Info().Str("address", cfg.HTTP.Address()).Msg("http server started")
		if err = server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatal().Err(err).Msg("http server failed")
		}
	}()

	<-ctx.Done()
	log.Info().Msg("shutdown signal received")

	shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	if err = server.Shutdown(shutdownCtx); err != nil {
		log.Error().Err(err).Msg("http server shutdown failed")
	} else {
		log.Info().Msg("http server stopped")
	}
}

func newPostFeedCache(ctx context.Context, cfg *config.Config) (port.PostFeedCache, func()) {
	if !cfg.Redis.FeedCacheEnabled {
		return nil, func() {}
	}
	client := redis.NewClient(&redis.Options{
		Addr:     cfg.Redis.Addr,
		Password: cfg.Redis.Password,
		DB:       cfg.Redis.DB,
	})
	cache := cacheadapter.NewRedisPostFeedCache(client, cfg.Redis.KeyPrefix)

	pingCtx, cancel := context.WithTimeout(ctx, 2*time.Second)
	defer cancel()
	if err := cache.Ping(pingCtx); err != nil {
		_ = client.Close()
		log.Warn().Err(err).Msg("post feed redis cache disabled")
		return nil, func() {}
	}
	log.Info().Str("addr", cfg.Redis.Addr).Msg("post feed redis cache enabled")
	return cache, func() { _ = client.Close() }
}

func feedCuratedBlockPolicyFromConfig(cfg config.FeedConfig) app.FeedCuratedBlockPolicy {
	return app.FeedCuratedBlockPolicy{
		MaxConversionBlocksPerPage:  cfg.CuratedMaxConversionBlocksPerPage,
		MaxOfficialNewsCardsPerPage: cfg.CuratedMaxOfficialNewsCardsPerPage,
		MaxProfileCardsPerPage:      cfg.CuratedMaxProfileCardsPerPage,
	}
}

func feedRankingPolicyFromConfig(cfg config.FeedConfig) repository.FeedRankingPolicy {
	return repository.FeedRankingPolicy{
		ExperimentKey:                     cfg.RankingExperimentKey,
		PostInterestWeight:                cfg.RankingPostInterestWeight,
		CommunityInterestWeight:           cfg.RankingCommunityInterestWeight,
		PostProfileAffinityWeight:         cfg.RankingPostProfileAffinityWeight,
		CityAffinityWeight:                cfg.RankingCityAffinityWeight,
		CountryAffinityWeight:             cfg.RankingCountryAffinityWeight,
		CategoryAffinityWeight:            cfg.RankingCategoryAffinityWeight,
		TagAffinityWeight:                 cfg.RankingTagAffinityWeight,
		AuthorAffinityWeight:              cfg.RankingAuthorAffinityWeight,
		MaxBoostHours:                     cfg.RankingMaxBoostHours,
		MaxPenaltyHours:                   cfg.RankingMaxPenaltyHours,
		InterestFreshnessDelay:            cfg.RankingInterestFreshnessDelay,
		NotInterestedPenalty:              cfg.RankingNotInterestedPenalty,
		RecentPostImpressionWindow:        cfg.RankingRecentPostImpressionWindow,
		RecentPostImpressionPenaltyHours:  cfg.RankingRecentPostImpressionPenaltyHours,
		RecentCommunityEventWindow:        cfg.RankingRecentCommunityEventWindow,
		RecentCommunityPenaltyHours:       cfg.RankingRecentCommunityPenaltyHours,
		CommunityMembershipBoostHours:     cfg.RankingCommunityMembershipBoostHours,
		SocialFriendBoostHours:            cfg.RankingSocialFriendBoostHours,
		SocialFollowingBoostHours:         cfg.RankingSocialFollowingBoostHours,
		CurrentCityBoostHours:             cfg.RankingCurrentCityBoostHours,
		CurrentCountryBoostHours:          cfg.RankingCurrentCountryBoostHours,
		ExplorationFreshnessWindow:        cfg.RankingExplorationFreshnessWindow,
		ExplorationLowViewThreshold:       cfg.RankingExplorationLowViewThreshold,
		ExplorationMaxBoostHours:          cfg.RankingExplorationMaxBoostHours,
		QualityPenaltyWindow:              cfg.RankingQualityPenaltyWindow,
		QualityMinNegativeEvents:          cfg.RankingQualityMinNegativeEvents,
		QualityNegativePenaltyHours:       cfg.RankingQualityNegativePenaltyHours,
		QualityMaxPenaltyHours:            cfg.RankingQualityMaxPenaltyHours,
		MaxPostsPerCommunityPerPage:       cfg.RankingMaxPostsPerCommunityPerPage,
		MaxPostsPerCategoryPerPage:        cfg.RankingMaxPostsPerCategoryPerPage,
		MaxPostsPerAuthorPerPage:          cfg.RankingMaxPostsPerAuthorPerPage,
		MaxPostsPerProfilePerPage:         cfg.RankingMaxPostsPerProfilePerPage,
		ColdStartMaxBoostHours:            cfg.RankingColdStartMaxBoostHours,
		ColdStartEngagementWeight:         cfg.RankingColdStartEngagementWeight,
		EngagementMaxBoostHours:           cfg.RankingEngagementMaxBoostHours,
		EngagementWeight:                  cfg.RankingEngagementWeight,
		EngagementFreshnessWindow:         cfg.RankingEngagementFreshnessWindow,
		NegativeInterestDecayWindow:       cfg.RankingNegativeInterestDecayWindow,
		NegativeInterestMinWeight:         cfg.RankingNegativeInterestMinWeight,
		DirectNegativeFeedbackDecayWindow: cfg.RankingDirectNegativeFeedbackDecayWindow,
	}
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

	pingCtx, cancel := context.WithTimeout(ctx, 5*time.Second)
	defer cancel()
	if err = pool.Ping(pingCtx); err != nil {
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

	if cfg.App.IsProduction() {
		log.Logger = zerolog.New(os.Stdout).With().Timestamp().Logger()
		return
	}

	log.Logger = zerolog.New(zerolog.ConsoleWriter{
		Out:        os.Stdout,
		TimeFormat: time.RFC3339,
	}).With().Timestamp().Logger()
}

func withRequestLogging(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		startedAt := time.Now()

		rw := &responseWriter{
			ResponseWriter: w,
			statusCode:     http.StatusOK,
		}

		next.ServeHTTP(rw, r)

		log.Info().
			Str("method", r.Method).
			Str("path", r.URL.Path).
			Int("status", rw.statusCode).
			Dur("duration", time.Since(startedAt)).
			Msg("http request handled")
	})
}

type responseWriter struct {
	http.ResponseWriter
	statusCode int
}

func (rw *responseWriter) WriteHeader(statusCode int) {
	rw.statusCode = statusCode
	rw.ResponseWriter.WriteHeader(statusCode)
}
