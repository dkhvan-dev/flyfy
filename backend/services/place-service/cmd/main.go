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

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/nats-io/nats.go"
	"github.com/redis/go-redis/v9"
	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"
	"google.golang.org/grpc"
	"kz/inflap/backend/pkg/natstransport"
	"kz/inflap/backend/pkg/serviceauth"
	"kz/inflap/backend/pkg/switches"
	"kz/inflap/backend/pkg/transportauth"
	cacheadapter "kz/inflap/backend/services/place-service/internal/adapter/cache"
	filemanageradapter "kz/inflap/backend/services/place-service/internal/adapter/filemanager"
	grpcadapter "kz/inflap/backend/services/place-service/internal/adapter/grpc"
	httpadapter "kz/inflap/backend/services/place-service/internal/adapter/http"
	natsadapter "kz/inflap/backend/services/place-service/internal/adapter/nats"
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
	var (
		savedLifecycleConnection *nats.Conn
		savedLifecycleDone       chan error
	)
	if cfg.SavedLifecycle.Enabled {
		savedLifecycleConnection, savedLifecycleDone, err = startSavedLifecycleDispatcher(ctx, pool, cfg)
		if err != nil {
			log.Fatal().Err(err).Msg("failed to initialize Saved lifecycle dispatcher")
		}
	}
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
	savedSourceUseCase := app.NewSavedSourceUseCase(repo)
	savedSourceAuthorizer, err := newSavedSourceAuthorizer(cfg)
	if err != nil {
		log.Fatal().Err(err).Msg("failed to configure Saved source service authentication")
	}
	savedSourceServer := grpcadapter.NewSavedSourceServer(savedSourceUseCase, savedSourceAuthorizer)
	savedCoverFileManagerClient, err := newSavedCoverFileManagerClient(cfg)
	if err != nil {
		log.Fatal().Err(err).Msg("failed to initialize Saved cover file-manager client")
	}
	defer savedCoverFileManagerClient.Close()
	savedCoverDeliveryUseCase := app.NewSavedAttractionCoverDeliveryUseCase(
		repo,
		savedCoverFileManagerClient,
	)

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
	handler := httpadapter.NewHandler(useCase, savedCoverDeliveryUseCase)
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
	if err := validatePlaceServiceGRPCPort(cfg); err != nil {
		log.Fatal().Err(err).Msg("invalid place-service gRPC listener configuration")
	}
	internalMTLSServer := newInternalPlaceMTLSServer(cfg, httpHandler, tlsConfig, readTimeout, writeTimeout, idleTimeout)
	grpcOptions, err := transportauth.GRPCServerOptions(transportTLSConfig)
	if err != nil {
		log.Fatal().Err(err).Msg("configure place-service gRPC mTLS")
	}
	grpcServer := grpc.NewServer(grpcOptions...)
	grpcadapter.RegisterSavedSourceServer(grpcServer, savedSourceServer)

	go func() {
		log.Info().Str("address", cfg.HTTP.Address()).Msg("http server started")
		if serveErr := server.ListenAndServe(); serveErr != nil && !errors.Is(serveErr, http.ErrServerClosed) {
			log.Fatal().Err(serveErr).Msg("http server failed")
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
		log.Info().Str("address", cfg.GRPC.Address()).Msg("internal Saved gRPC server started")
		if serveErr := servePlaceGRPCServer(cfg.GRPC.Address(), grpcServer); serveErr != nil &&
			!errors.Is(serveErr, grpc.ErrServerStopped) {
			log.Fatal().Err(serveErr).Msg("gRPC server failed")
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
	if internalMTLSServer != nil {
		if err = internalMTLSServer.Shutdown(shutdownCtx); err != nil {
			log.Error().Err(err).Msg("internal mTLS http server shutdown failed")
		} else {
			log.Info().Msg("internal mTLS http server stopped")
		}
	}

	grpcStopped := make(chan struct{})
	go func() {
		grpcServer.GracefulStop()
		close(grpcStopped)
	}()
	select {
	case <-grpcStopped:
		log.Info().Msg("gRPC server stopped")
	case <-time.After(10 * time.Second):
		log.Warn().Msg("gRPC graceful stop timed out; forcing stop")
		grpcServer.Stop()
	}

	if savedLifecycleDone != nil {
		select {
		case dispatcherErr := <-savedLifecycleDone:
			if dispatcherErr != nil {
				log.Error().Err(dispatcherErr).Msg("Saved lifecycle dispatcher stopped with error")
			} else {
				log.Info().Msg("Saved lifecycle dispatcher stopped")
			}
		case <-shutdownCtx.Done():
			log.Warn().Msg("Saved lifecycle dispatcher shutdown timed out")
		}
	}
	if savedLifecycleConnection != nil {
		if err = natstransport.Drain(savedLifecycleConnection); err != nil {
			log.Warn().Err(err).Msg("Saved lifecycle NATS drain failed")
		}
		savedLifecycleConnection.Close()
	}
}

func startSavedLifecycleDispatcher(
	ctx context.Context,
	pool *pgxpool.Pool,
	cfg *config.Config,
) (*nats.Conn, chan error, error) {
	if pool == nil || cfg == nil {
		return nil, nil, errors.New("Saved lifecycle dispatcher dependencies are required")
	}
	if err := cfg.SavedLifecycle.Validate(cfg.App.Env); err != nil {
		return nil, nil, err
	}
	natsConfig, err := cfg.SavedLifecycle.NATSConfig(cfg.App.Env)
	if err != nil {
		return nil, nil, err
	}
	connection, err := natstransport.Connect(
		natsConfig,
		"place-service-saved-lifecycle",
		natstransport.Hooks{
			Disconnected: func(disconnectErr error) {
				log.Warn().Err(disconnectErr).Msg("Saved lifecycle NATS disconnected")
			},
			Reconnected: func() {
				log.Info().Msg("Saved lifecycle NATS reconnected")
			},
			Closed: func(closeErr error) {
				if closeErr == nil {
					log.Info().Msg("Saved lifecycle NATS connection closed")
					return
				}
				log.Warn().Err(closeErr).Msg("Saved lifecycle NATS connection closed unexpectedly")
			},
			AsyncError: func(asyncErr error) {
				log.Warn().Err(asyncErr).Msg("Saved lifecycle NATS asynchronous error")
			},
		},
	)
	if err != nil {
		return nil, nil, fmt.Errorf("connect Saved lifecycle NATS: %w", err)
	}

	streamCtx, cancel := context.WithTimeout(ctx, natsConfig.ConnectTimeout)
	defer cancel()
	publisher, err := natsadapter.NewSavedLifecyclePublisher(
		streamCtx,
		connection,
	)
	if err != nil {
		connection.Close()
		return nil, nil, err
	}
	dispatcher, err := app.NewSavedLifecycleDispatcher(
		repository.NewPGSavedLifecycleOutboxRepository(pool),
		publisher,
		app.SavedLifecycleDispatcherConfig{
			BatchSize:       cfg.SavedLifecycle.BatchSize,
			Concurrency:     cfg.SavedLifecycle.Concurrency,
			PollInterval:    cfg.SavedLifecycle.PollInterval,
			LeaseDuration:   cfg.SavedLifecycle.LeaseDuration,
			PublishTimeout:  cfg.SavedLifecycle.PublishTimeout,
			MaxAttempts:     cfg.SavedLifecycle.MaxAttempts,
			RetryBase:       cfg.SavedLifecycle.RetryBase,
			RetryMax:        cfg.SavedLifecycle.RetryMax,
			CleanupInterval: cfg.SavedLifecycle.CleanupInterval,
			CleanupBatch:    cfg.SavedLifecycle.CleanupBatch,
		},
	)
	if err != nil {
		connection.Close()
		return nil, nil, err
	}

	done := make(chan error, 1)
	go func() {
		done <- dispatcher.Run(ctx)
		close(done)
	}()
	log.Info().Msg("Saved lifecycle dispatcher started")
	return connection, done, nil
}

func newSavedSourceAuthorizer(cfg *config.Config) (*serviceauth.JWTVerifier, error) {
	if cfg == nil {
		return nil, fmt.Errorf("place service config is required")
	}
	if !cfg.Security.ServiceAuthEnabled() {
		if cfg.App.IsProduction() {
			return nil, fmt.Errorf("SERVICE_AUTH_ISSUER and SERVICE_AUTH_JWKS_URL are required in production")
		}
		return nil, nil
	}

	jwksClient, err := transportauth.NewHTTPClient(
		cfg.MTLS.ClientConfig(transportauth.ServerNameFromTarget(cfg.Security.ServiceAuthJWKSURL)),
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

func servePlaceGRPCServer(address string, server *grpc.Server) error {
	listener, err := net.Listen("tcp", address)
	if err != nil {
		return fmt.Errorf("listen on %s: %w", address, err)
	}
	if err = server.Serve(listener); err != nil {
		return fmt.Errorf("serve on %s: %w", address, err)
	}
	return nil
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

func newSavedCoverFileManagerClient(cfg *config.Config) (*filemanageradapter.Client, error) {
	grpcOptions, err := transportauth.GRPCDialOptions(
		cfg.MTLS.ClientConfig(transportauth.ServerNameFromTarget(cfg.FileManager.GRPCTarget)),
	)
	if err != nil {
		return nil, fmt.Errorf("initialize Saved cover file-manager mTLS transport: %w", err)
	}
	return filemanageradapter.New(
		cfg.FileManager.GRPCTarget,
		cfg.Security.InternalServiceToken,
		cfg.App.Name,
		cfg.FileManager.RequestTimeout,
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

func validatePlaceServiceGRPCPort(cfg *config.Config) error {
	if cfg == nil {
		return fmt.Errorf("place service config is required")
	}
	if cfg.GRPC.Port <= 0 || cfg.GRPC.Port > 65535 {
		return fmt.Errorf("GRPC_PORT must be between 1 and 65535")
	}
	if cfg.GRPC.Port == cfg.HTTP.Port {
		return fmt.Errorf("GRPC_PORT must be different from HTTP_PORT")
	}
	if cfg.HTTP.InternalTLSPort > 0 && cfg.GRPC.Port == cfg.HTTP.InternalTLSPort {
		return fmt.Errorf("GRPC_PORT must be different from INTERNAL_HTTP_TLS_PORT")
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
