package main

import (
	"context"
	"crypto/tls"
	"errors"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/redis/go-redis/v9"
	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"
	"kz/inflap/backend/pkg/serviceauth"
	"kz/inflap/backend/pkg/switches"
	"kz/inflap/backend/pkg/transportauth"
	cacheadapter "kz/inflap/backend/services/place-service/internal/adapter/cache"
	httpadapter "kz/inflap/backend/services/place-service/internal/adapter/http"
	"kz/inflap/backend/services/place-service/internal/adapter/repository"
	searchindexadapter "kz/inflap/backend/services/place-service/internal/adapter/searchindex"
	userserviceadapter "kz/inflap/backend/services/place-service/internal/adapter/userservice"
	"kz/inflap/backend/services/place-service/internal/app"
	"kz/inflap/backend/services/place-service/internal/config"
	"kz/inflap/backend/services/place-service/internal/mediabackfill"
)

func main() {
	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	cfg, err := config.Load(ctx)
	if err != nil {
		panic(err)
	}

	setupLogger(cfg)
	log.Info().Str("env", cfg.App.Env).Msg("starting place-service")

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

	repo := repository.NewPGPlaceRepository(pool)
	adminAuthorUserID, err := uuid.Parse(cfg.Admin.PlaceAuthorUserID)
	if err != nil || adminAuthorUserID == uuid.Nil {
		log.Fatal().Err(err).Str("admin_author_user_id", cfg.Admin.PlaceAuthorUserID).Msg("invalid admin place author user id")
	}

	useCaseOptions := []app.PlaceUseCaseOption{app.WithAdminAuthorUserID(adminAuthorUserID)}
	redisClient := newRedisClient(ctx, cfg)
	if redisClient != nil {
		defer redisClient.Close()
		placeCache := cacheadapter.NewRedisPlaceCache(redisClient, cfg.Redis.KeyPrefix)
		useCaseOptions = append(
			useCaseOptions,
			app.WithPlaceCache(placeCache, cfg.Redis.DetailTTL, cfg.Redis.ListTTL),
		)
	}
	if cfg.SearchService.Enabled {
		searchIndexOptions, closeSearchIndexAuth := newSearchIndexOptions(cfg)
		defer closeSearchIndexAuth()
		searchIndexer := searchindexadapter.New(
			cfg.SearchService.HTTPURL,
			cfg.Security.InternalServiceToken,
			cfg.SearchService.Timeout,
			searchIndexOptions...,
		)
		useCaseOptions = append(useCaseOptions, app.WithPlaceSearchIndexer(searchIndexer))
	}

	useCase := app.NewPlaceUseCase(repo, userClient, useCaseOptions...)

	mediaBackfillFileManagerClient, err := newMediaBackfillFileManagerHTTPClient(cfg)
	if err != nil {
		log.Fatal().Err(err).Msg("failed to initialize media backfill file-manager client")
	}
	mediaBackfillRunner := mediabackfill.NewRunner(pool, mediabackfill.Config{
		FileManagerURL:          cfg.MediaBackfill.FileManagerURL,
		HTTPTimeout:             cfg.MediaBackfill.HTTPTimeout,
		FileManagerHTTPClient:   mediaBackfillFileManagerClient,
		RowDelay:                cfg.MediaBackfill.RowDelay,
		RunTimeout:              cfg.MediaBackfill.RunTimeout,
		CommonsMinMediaPerPlace: cfg.MediaBackfill.CommonsMinMediaPerPlace,
	})
	handler := httpadapter.NewHandler(useCase)
	handler.SetMediaBackfillStarter(mediaBackfillRunner)
	mux := http.NewServeMux()
	handler.Register(mux)

	readTimeout, _ := time.ParseDuration(cfg.HTTP.ReadTimeout)
	writeTimeout, _ := time.ParseDuration(cfg.HTTP.WriteTimeout)
	idleTimeout, _ := time.ParseDuration(cfg.HTTP.IdleTimeout)
	httpHandler := httpadapter.Chain(cfg, withTechBreakMaintenance(mux, cfg.Switches, cfg.MTLS, cfg.Security.InternalServiceToken, "PLACE"))

	server := &http.Server{
		Addr:         cfg.HTTP.Address(),
		Handler:      httpHandler,
		ReadTimeout:  readTimeout,
		WriteTimeout: writeTimeout,
		IdleTimeout:  idleTimeout,
	}

	transportTLSConfig := cfg.MTLS.ServerConfig()
	tlsConfig, err := transportTLSConfig.ServerTLSConfig()
	if err != nil {
		log.Fatal().Err(err).Msg("configure place-service mTLS")
	}
	if err := validatePlaceServiceMTLSPort(cfg, tlsConfig); err != nil {
		log.Fatal().Err(err).Msg("invalid place-service mTLS listener configuration")
	}
	internalMTLSServer := newInternalPlaceMTLSServer(cfg, httpHandler, tlsConfig, readTimeout, writeTimeout, idleTimeout)

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

func newMediaBackfillFileManagerHTTPClient(cfg *config.Config) (*http.Client, error) {
	client, err := transportauth.NewHTTPClient(
		cfg.MTLS.ClientConfig(transportauth.ServerNameFromTarget(cfg.MediaBackfill.FileManagerURL)),
		cfg.MediaBackfill.HTTPTimeout,
	)
	if err != nil {
		return nil, fmt.Errorf("initialize file-manager mTLS transport: %w", err)
	}
	return client, nil
}

func newUserServiceClient(cfg *config.Config) (*userserviceadapter.Client, error) {
	grpcOptions, err := transportauth.GRPCDialOptions(
		cfg.MTLS.ClientConfig(transportauth.ServerNameFromTarget(cfg.UserService.GRPCTarget)),
	)
	if err != nil {
		return nil, fmt.Errorf("initialize user-service mTLS transport: %w", err)
	}
	return userserviceadapter.New(
		cfg.UserService.GRPCTarget,
		cfg.Security.InternalServiceToken,
		cfg.App.Name,
		grpcOptions...,
	)
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

func validatePlaceServiceMTLSPort(cfg *config.Config, tlsConfig *tls.Config) error {
	if tlsConfig == nil {
		return nil
	}
	if cfg.HTTP.InternalTLSPort == 0 {
		return fmt.Errorf("INTERNAL_HTTP_TLS_PORT is required when place-service mTLS is enabled")
	}
	if cfg.HTTP.InternalTLSPort == cfg.HTTP.Port {
		return fmt.Errorf("INTERNAL_HTTP_TLS_PORT must be different from HTTP_PORT")
	}
	return nil
}

func newInternalPlaceMTLSServer(
	cfg *config.Config,
	handler http.Handler,
	tlsConfig *tls.Config,
	readTimeout time.Duration,
	writeTimeout time.Duration,
	idleTimeout time.Duration,
) *http.Server {
	if tlsConfig == nil {
		return nil
	}
	return &http.Server{
		Addr:         cfg.HTTP.InternalTLSAddress(),
		Handler:      handler,
		TLSConfig:    tlsConfig,
		ReadTimeout:  readTimeout,
		WriteTimeout: writeTimeout,
		IdleTimeout:  idleTimeout,
	}
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

	pingCtx, cancel := context.WithTimeout(ctx, 5*time.Second)
	defer cancel()
	if err = pool.Ping(pingCtx); err != nil {
		pool.Close()
		return nil, err
	}

	return pool, nil
}

func newRedisClient(ctx context.Context, cfg *config.Config) *redis.Client {
	if !cfg.Redis.Enabled || cfg.Redis.Addr == "" {
		log.Info().Msg("place cache disabled")
		return nil
	}

	client := redis.NewClient(&redis.Options{
		Addr:     cfg.Redis.Addr,
		Password: cfg.Redis.Password,
		DB:       cfg.Redis.DB,
	})

	pingCtx, cancel := context.WithTimeout(ctx, 2*time.Second)
	defer cancel()
	if err := client.Ping(pingCtx).Err(); err != nil {
		_ = client.Close()
		log.Warn().Err(err).Str("addr", cfg.Redis.Addr).Int("db", cfg.Redis.DB).Msg("Redis unavailable, place cache disabled")
		return nil
	}

	log.Info().
		Str("addr", cfg.Redis.Addr).
		Int("db", cfg.Redis.DB).
		Dur("detail_ttl", cfg.Redis.DetailTTL).
		Dur("list_ttl", cfg.Redis.ListTTL).
		Msg("place Redis cache enabled")
	return client
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
