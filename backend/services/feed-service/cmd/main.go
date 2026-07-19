package main

import (
	"context"
	"crypto/tls"
	"errors"
	"fmt"
	"net"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/redis/go-redis/v9"
	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"
	"google.golang.org/grpc"
	"kz/inflap/backend/pkg/serviceauth"
	"kz/inflap/backend/pkg/switches"
	"kz/inflap/backend/pkg/transportauth"
	activityadapter "kz/inflap/backend/services/feed-service/internal/adapter/activity"
	cacheadapter "kz/inflap/backend/services/feed-service/internal/adapter/cache"
	filemanageradapter "kz/inflap/backend/services/feed-service/internal/adapter/filemanager"
	grpcadapter "kz/inflap/backend/services/feed-service/internal/adapter/grpc"
	httpadapter "kz/inflap/backend/services/feed-service/internal/adapter/http"
	notificationadapter "kz/inflap/backend/services/feed-service/internal/adapter/notification"
	"kz/inflap/backend/services/feed-service/internal/adapter/repository"
	searchindexadapter "kz/inflap/backend/services/feed-service/internal/adapter/searchindex"
	userrouteadapter "kz/inflap/backend/services/feed-service/internal/adapter/userroute"
	uservicadapter "kz/inflap/backend/services/feed-service/internal/adapter/userservice"
	"kz/inflap/backend/services/feed-service/internal/app"
	"kz/inflap/backend/services/feed-service/internal/config"
	"kz/inflap/backend/services/feed-service/internal/domain/port"
	contentv1 "kz/inflap/proto/gen/go/content/v1"
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

	userClient, err := newUserServiceClient(cfg)
	if err != nil {
		log.Fatal().Err(err).Msg("failed to initialize user-service grpc client")
	}
	defer userClient.Close()

	fileManagerClient, err := newFileManagerClient(cfg)
	if err != nil {
		log.Fatal().Err(err).Msg("failed to initialize file-manager grpc client")
	}
	defer fileManagerClient.Close()

	feedRankingPolicy := feedRankingPolicyFromConfig(cfg.Feed).Normalized()
	feedCuratedBlockPolicy := feedCuratedBlockPolicyFromConfig(cfg.Feed).Normalized()
	feedDiversityPolicy := feedDiversityPolicyFromConfig(cfg.Feed).Normalized()
	repo := repository.NewPGPostRepository(pool).
		WithFeedRankingPolicy(feedRankingPolicy).
		WithPostPublishCooldown(cfg.Post.CreateCooldown)
	notificationHTTPClient, err := newNotificationServiceHTTPClient(cfg)
	if err != nil {
		log.Fatal().Err(err).Msg("failed to configure notification-service mTLS client")
	}
	notificationClient := notificationadapter.New(
		cfg.Notification.HTTPURL,
		cfg.Security.InternalServiceToken,
		"feed-service",
		cfg.Notification.RequestTimeout,
		notificationadapter.WithHTTPClient(notificationHTTPClient),
	)
	activityHTTPClient, err := newActivityServiceHTTPClient(cfg)
	if err != nil {
		log.Fatal().Err(err).Msg("failed to configure activity-service mTLS client")
	}
	activityClient := activityadapter.New(
		cfg.Activity.HTTPURL,
		cfg.Security.InternalServiceToken,
		"feed-service",
		cfg.Activity.RequestTimeout,
		activityadapter.WithHTTPClient(activityHTTPClient),
	)
	userRouteHTTPClient, err := newUserRouteServiceHTTPClient(cfg)
	if err != nil {
		log.Fatal().Err(err).Msg("failed to configure user-route-service mTLS client")
	}
	userRouteClient := userrouteadapter.New(
		cfg.UserRoute.HTTPURL,
		cfg.UserRoute.RequestTimeout,
		userrouteadapter.WithHTTPClient(userRouteHTTPClient),
	)
	postFeedCache, closePostFeedCache := newPostFeedCache(ctx, cfg)
	defer closePostFeedCache()
	useCase := app.NewPostUseCase(repo, userClient, cfg.Public.PostShareBaseURL).
		WithPostCreateCooldown(cfg.Post.CreateCooldown).
		WithPostMediaBinder(fileManagerClient).
		WithRouteReferenceValidator(userRouteClient).
		WithPostNotificationGateway(notificationClient).
		WithFeedCuratedBlockPolicy(feedCuratedBlockPolicy).
		WithFeedDiversityPolicy(feedDiversityPolicy).
		WithFeedExperimentAssignment(feedRankingPolicy.ExperimentKey).
		WithFeedExperimentVariants(cfg.Feed.RankingExperimentVariants).
		WithFeedExperimentPolicyOverrides(cfg.Feed.RankingExperimentPolicies)
	savedPostSourceAuthorizer, err := newSavedPostSourceAuthorizer(cfg)
	if err != nil {
		log.Fatal().Err(err).Msg("failed to configure Saved post source authentication")
	}
	savedPostSourceServer := grpcadapter.NewSavedPostSourceServer(
		app.NewSavedPostSourceUseCase(repo),
		savedPostSourceAuthorizer,
	)
	if cfg.SearchService.Enabled {
		searchIndexOptions, closeSearchIndexAuth := newSearchIndexOptions(cfg)
		defer closeSearchIndexAuth()
		searchIndexer := searchindexadapter.New(
			cfg.SearchService.HTTPURL,
			cfg.Security.InternalServiceToken,
			cfg.SearchService.Timeout,
			searchIndexOptions...,
		)
		useCase.WithCommunitySearchIndexer(searchIndexer)
	}
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
	httpHandler := httpadapter.Chain(cfg, withTechBreakMaintenance(withRequestLogging(mux), cfg.Switches, cfg.MTLS, cfg.Security.InternalServiceToken, "FEED"))

	server := &http.Server{
		Addr:         cfg.HTTP.Address(),
		Handler:      httpHandler,
		ReadTimeout:  cfg.HTTP.ReadTimeout,
		WriteTimeout: cfg.HTTP.WriteTimeout,
		IdleTimeout:  cfg.HTTP.IdleTimeout,
	}

	transportTLSConfig := cfg.MTLS.ServerConfig()
	tlsConfig, err := transportTLSConfig.ServerTLSConfig()
	if err != nil {
		log.Fatal().Err(err).Msg("configure feed-service mTLS")
	}
	if err := validateFeedServiceMTLSPort(cfg, tlsConfig); err != nil {
		log.Fatal().Err(err).Msg("invalid feed-service mTLS listener configuration")
	}
	internalMTLSServer := newInternalFeedMTLSServer(cfg, httpHandler, tlsConfig)
	savedGRPCServer := newFeedSavedSourceGRPCServer(savedPostSourceServer)
	var internalSavedGRPCServer *grpc.Server
	if tlsConfig != nil {
		serverOptions, optionsErr := transportauth.GRPCServerOptions(transportTLSConfig)
		if optionsErr != nil {
			log.Fatal().Err(optionsErr).Msg("configure feed-service internal mTLS gRPC")
		}
		internalSavedGRPCServer = newFeedSavedSourceGRPCServer(
			savedPostSourceServer,
			serverOptions...,
		)
	}

	go func() {
		log.Info().Str("address", cfg.HTTP.Address()).Msg("http server started")
		if err = server.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			log.Fatal().Err(err).Msg("http server failed")
		}
	}()
	if internalMTLSServer != nil {
		go func() {
			log.Info().Str("address", cfg.HTTP.InternalTLSAddress()).Msg("internal mTLS http server started")
			if err := internalMTLSServer.ListenAndServeTLS("", ""); err != nil && !errors.Is(err, http.ErrServerClosed) {
				log.Fatal().Err(err).Msg("internal mTLS http server failed")
			}
		}()
	}
	go func() {
		log.Info().Str("address", cfg.GRPC.Address()).Msg("Saved source gRPC server started")
		if serveErr := serveFeedSavedSourceGRPCServer(cfg.GRPC.Address(), savedGRPCServer); serveErr != nil {
			log.Fatal().Err(serveErr).Msg("Saved source gRPC server failed")
		}
	}()
	if internalSavedGRPCServer != nil {
		go func() {
			log.Info().Str("address", cfg.GRPC.InternalTLSAddress()).Msg("internal mTLS Saved source gRPC server started")
			if serveErr := serveFeedSavedSourceGRPCServer(cfg.GRPC.InternalTLSAddress(), internalSavedGRPCServer); serveErr != nil {
				log.Fatal().Err(serveErr).Msg("internal mTLS Saved source gRPC server failed")
			}
		}()
	}

	<-ctx.Done()
	log.Info().Msg("shutdown signal received")

	shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	if err = server.Shutdown(shutdownCtx); err != nil {
		log.Error().Err(err).Msg("http server shutdown failed")
	} else {
		log.Info().Msg("http server stopped")
	}
	if internalMTLSServer != nil {
		if err = internalMTLSServer.Shutdown(shutdownCtx); err != nil {
			log.Error().Err(err).Msg("internal mTLS http server shutdown failed")
		} else {
			log.Info().Msg("internal mTLS http server stopped")
		}
	}
	stopFeedSavedSourceGRPCServers(savedGRPCServer, internalSavedGRPCServer, 10*time.Second)
}

func withTechBreakMaintenance(next http.Handler, cfg config.SwitchesServiceConfig, mtls transportauth.EnvConfig, fallbackToken string, domainCode string) http.Handler {
	token := switches.EffectiveInternalServiceToken(cfg.InternalServiceToken, fallbackToken)
	middleware, err := switches.NewMaintenanceMiddleware(
		switches.HTTPClientConfig{
			BaseURL:              cfg.HTTPURL,
			InternalServiceToken: token,
			Timeout:              cfg.RequestTimeout,
			TransportAuth:        mtls.ClientConfig(transportauth.ServerNameFromTarget(cfg.HTTPURL)),
		},
		switches.MaintenanceMiddlewareConfig{
			DomainCode: domainCode,
			OnCheckError: func(ctx context.Context, err error, check switches.TechBreakCheck) {
				log.Warn().Err(err).Str("domain_code", check.DomainCode).Msg("tech break check failed; allowing request")
			},
		},
	)
	if err != nil {
		log.Warn().Err(err).Str("domain_code", domainCode).Msg("tech break middleware disabled")
		return next
	}
	return middleware(next)
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

func feedDiversityPolicyFromConfig(cfg config.FeedConfig) app.FeedDiversityPolicy {
	return app.FeedDiversityPolicy{
		MaxPostsPerCommunityPerPage: cfg.RankingMaxPostsPerCommunityPerPage,
		MaxPostsPerCategoryPerPage:  cfg.RankingMaxPostsPerCategoryPerPage,
		MaxPostsPerAuthorPerPage:    cfg.RankingMaxPostsPerAuthorPerPage,
		MaxPostsPerProfilePerPage:   cfg.RankingMaxPostsPerProfilePerPage,
	}
}

func feedRankingPolicyFromConfig(cfg config.FeedConfig) repository.FeedRankingPolicy {
	return repository.FeedRankingPolicy{
		ExperimentKey:                     cfg.RankingExperimentKey,
		PostInterestWeight:                cfg.RankingPostInterestWeight,
		CommunityInterestWeight:           cfg.RankingCommunityInterestWeight,
		CommunityInterestMinScore:         cfg.RankingCommunityInterestMinScore,
		FrequentCommunityMinVisits:        cfg.RankingFrequentCommunityMinVisits,
		FrequentCommunityMinVisitDays:     cfg.RankingFrequentCommunityMinVisitDays,
		FrequentCommunityFreshnessWindow:  cfg.RankingFrequentCommunityFreshnessWindow,
		FrequentCommunityHalfLife:         cfg.RankingFrequentCommunityHalfLife,
		FrequentCommunityBoostHours:       cfg.RankingFrequentCommunityBoostHours,
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

func newSearchIndexOptions(cfg *config.Config) ([]searchindexadapter.Option, func()) {
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
	log.Info().Str("service_id", cfg.TokenService.ServiceID).Msg("search indexing service JWT auth enabled")
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

func newNotificationServiceHTTPClient(cfg *config.Config) (*http.Client, error) {
	return transportauth.NewHTTPClient(
		cfg.MTLS.ClientConfig(transportauth.ServerNameFromTarget(cfg.Notification.HTTPURL)),
		cfg.Notification.RequestTimeout,
	)
}

func newActivityServiceHTTPClient(cfg *config.Config) (*http.Client, error) {
	return transportauth.NewHTTPClient(
		cfg.MTLS.ClientConfig(transportauth.ServerNameFromTarget(cfg.Activity.HTTPURL)),
		cfg.Activity.RequestTimeout,
	)
}

func newUserRouteServiceHTTPClient(cfg *config.Config) (*http.Client, error) {
	return transportauth.NewHTTPClient(
		cfg.MTLS.ClientConfig(transportauth.ServerNameFromTarget(cfg.UserRoute.HTTPURL)),
		cfg.UserRoute.RequestTimeout,
	)
}

func validateFeedServiceMTLSPort(cfg *config.Config, tlsConfig *tls.Config) error {
	if tlsConfig == nil {
		return nil
	}
	if cfg.HTTP.InternalTLSPort == 0 {
		return fmt.Errorf("INTERNAL_HTTP_TLS_PORT is required when feed-service mTLS is enabled")
	}
	if cfg.HTTP.InternalTLSPort == cfg.HTTP.Port {
		return fmt.Errorf("INTERNAL_HTTP_TLS_PORT must be different from HTTP_PORT")
	}
	if cfg.GRPC.InternalTLSPort == 0 {
		return fmt.Errorf("INTERNAL_GRPC_TLS_PORT is required when feed-service mTLS is enabled")
	}
	if cfg.GRPC.InternalTLSPort == cfg.GRPC.Port {
		return fmt.Errorf("INTERNAL_GRPC_TLS_PORT must be different from GRPC_PORT")
	}
	if cfg.GRPC.InternalTLSPort == cfg.HTTP.InternalTLSPort {
		return fmt.Errorf("INTERNAL_GRPC_TLS_PORT must be different from INTERNAL_HTTP_TLS_PORT")
	}
	return nil
}

func newFeedSavedSourceGRPCServer(
	server *grpcadapter.SavedPostSourceServer,
	options ...grpc.ServerOption,
) *grpc.Server {
	grpcServer := grpc.NewServer(options...)
	contentv1.RegisterSavedSourceServiceServer(grpcServer, server)
	return grpcServer
}

func serveFeedSavedSourceGRPCServer(address string, server *grpc.Server) error {
	listener, err := net.Listen("tcp", address)
	if err != nil {
		return fmt.Errorf("listen for Saved source gRPC: %w", err)
	}
	if err = server.Serve(listener); err != nil && !errors.Is(err, grpc.ErrServerStopped) {
		return fmt.Errorf("serve Saved source gRPC: %w", err)
	}
	return nil
}

func stopFeedSavedSourceGRPCServers(
	publicServer *grpc.Server,
	internalServer *grpc.Server,
	timeout time.Duration,
) {
	if timeout <= 0 {
		timeout = 10 * time.Second
	}
	done := make(chan struct{})
	go func() {
		publicServer.GracefulStop()
		if internalServer != nil {
			internalServer.GracefulStop()
		}
		close(done)
	}()
	select {
	case <-done:
		log.Info().Msg("Saved source gRPC servers stopped")
	case <-time.After(timeout):
		publicServer.Stop()
		if internalServer != nil {
			internalServer.Stop()
		}
		log.Warn().Msg("Saved source gRPC shutdown timed out")
	}
}

func newSavedPostSourceAuthorizer(cfg *config.Config) (*serviceauth.JWTVerifier, error) {
	if cfg == nil {
		return nil, fmt.Errorf("feed service config is required")
	}
	if !cfg.Security.ServiceAuthEnabled() {
		if cfg.App.IsProduction() {
			return nil, fmt.Errorf("SERVICE_AUTH_ISSUER and SERVICE_AUTH_JWKS_URL are required in production")
		}
		return nil, nil
	}
	jwksClient, err := transportauth.NewHTTPClient(
		cfg.MTLS.ClientConfig(
			transportauth.ServerNameFromTarget(cfg.Security.ServiceAuthJWKSURL),
		),
		3*time.Second,
	)
	if err != nil {
		return nil, fmt.Errorf("configure service auth JWKS client: %w", err)
	}
	verifier, err := serviceauth.NewJWTVerifier(serviceauth.VerifierConfig{
		Issuer:   cfg.Security.ServiceAuthIssuer,
		JWKSURL:  cfg.Security.ServiceAuthJWKSURL,
		CacheTTL: cfg.Security.ServiceAuthCacheTTL,
		Client:   jwksClient,
	})
	if err != nil {
		return nil, fmt.Errorf("configure service auth verifier: %w", err)
	}
	return verifier, nil
}

func newInternalFeedMTLSServer(cfg *config.Config, handler http.Handler, tlsConfig *tls.Config) *http.Server {
	if tlsConfig == nil {
		return nil
	}
	return &http.Server{
		Addr:         cfg.HTTP.InternalTLSAddress(),
		Handler:      handler,
		TLSConfig:    tlsConfig,
		ReadTimeout:  cfg.HTTP.ReadTimeout,
		WriteTimeout: cfg.HTTP.WriteTimeout,
		IdleTimeout:  cfg.HTTP.IdleTimeout,
	}
}

func newUserServiceClient(cfg *config.Config) (*uservicadapter.Client, error) {
	grpcOptions, err := transportauth.GRPCDialOptions(
		cfg.MTLS.ClientConfig(transportauth.ServerNameFromTarget(cfg.UserService.Target)),
	)
	if err != nil {
		return nil, fmt.Errorf("initialize user-service mTLS transport: %w", err)
	}
	return uservicadapter.New(
		cfg.UserService.Target,
		cfg.Security.InternalServiceToken,
		"feed-service",
		grpcOptions...,
	)
}

func newFileManagerClient(cfg *config.Config) (*filemanageradapter.Client, error) {
	grpcOptions, err := transportauth.GRPCDialOptions(
		cfg.MTLS.ClientConfig(transportauth.ServerNameFromTarget(cfg.FileManager.Target)),
	)
	if err != nil {
		return nil, fmt.Errorf("initialize file-manager mTLS transport: %w", err)
	}
	return filemanageradapter.New(
		cfg.FileManager.Target,
		cfg.Security.InternalServiceToken,
		"feed-service",
		grpcOptions...,
	)
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
