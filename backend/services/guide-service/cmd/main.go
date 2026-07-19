package main

import (
	"context"
	"crypto/tls"
	"fmt"
	"net"
	"net/http"
	"os"
	"os/signal"
	"sync"
	"syscall"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/nats-io/nats.go"
	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"
	"google.golang.org/grpc"
	"kz/inflap/backend/pkg/natstransport"
	"kz/inflap/backend/pkg/serviceauth"
	"kz/inflap/backend/pkg/transportauth"
	excursionserviceadapter "kz/inflap/backend/services/guide-service/internal/adapter/excursionservice"
	filemanageradapter "kz/inflap/backend/services/guide-service/internal/adapter/filemanager"
	fraudadapter "kz/inflap/backend/services/guide-service/internal/adapter/fraud"
	grpcadapter "kz/inflap/backend/services/guide-service/internal/adapter/grpc"
	httpadapter "kz/inflap/backend/services/guide-service/internal/adapter/http"
	natsadapter "kz/inflap/backend/services/guide-service/internal/adapter/nats"
	"kz/inflap/backend/services/guide-service/internal/adapter/repository"
	searchindexadapter "kz/inflap/backend/services/guide-service/internal/adapter/searchindex"
	userserviceadapter "kz/inflap/backend/services/guide-service/internal/adapter/userservice"
	"kz/inflap/backend/services/guide-service/internal/app"
	"kz/inflap/backend/services/guide-service/internal/config"
	"kz/inflap/backend/services/guide-service/internal/domain/port"
	contentv1 "kz/inflap/proto/gen/go/content/v1"
	guidev1 "kz/inflap/proto/gen/go/guide/v1"
)

func main() {
	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	cfg, err := config.Load(ctx)
	if err != nil {
		panic(err)
	}

	setupLogger(cfg)

	log.Info().
		Str("env", cfg.App.Env).
		Msg("starting guide-service")

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

	fileClient, err := newFileManagerClient(cfg)
	if err != nil {
		log.Fatal().Err(err).Msg("failed to initialize file-manager grpc client")
	}
	defer fileClient.Close()

	guideRepo := repository.NewPGGuideRepository(pool)
	savedLifecycleRuntime, err := startSavedLifecycleRuntime(ctx, cfg, guideRepo, userClient)
	if err != nil {
		log.Fatal().Err(err).Msg("failed to initialize Saved guide lifecycle runtime")
	}
	excursionHTTPClient, err := newExcursionServiceHTTPClient(cfg)
	if err != nil {
		log.Fatal().Err(err).Msg("failed to initialize excursion-service client")
	}
	excursionClient := excursionserviceadapter.New(cfg.Excursion.BaseURL, cfg.Security.InternalServiceToken, excursionHTTPClient)
	fraudClient, err := newFraudEvaluator(cfg)
	if err != nil {
		log.Fatal().Err(err).Msg("failed to initialize anti-fraud client")
	}
	guideUseCase := app.NewGuideUseCaseWithFraud(guideRepo, userClient, fileClient, fraudClient, excursionClient)
	savedSourceUseCase := app.NewSavedGuideSourceUseCase(guideRepo, userClient)
	savedAvatarDeliveryUseCase := app.NewSavedGuideAvatarDeliveryUseCase(savedSourceUseCase, fileClient)
	savedSourceAuthorizer, err := newSavedGuideSourceAuthorizer(cfg)
	if err != nil {
		log.Fatal().Err(err).Msg("failed to configure Saved source service authentication")
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
		guideUseCase.SetSearchIndexer(searchIndexer)
	}

	httpHandler := httpadapter.NewHandler(guideUseCase, savedAvatarDeliveryUseCase)
	httpMux := http.NewServeMux()
	httpHandler.Register(httpMux)

	httpServer := &http.Server{
		Addr:         cfg.HTTP.Address(),
		Handler:      httpadapter.Chain(cfg, withRequestLogging(httpMux)),
		ReadTimeout:  cfg.HTTP.ReadTimeout,
		WriteTimeout: cfg.HTTP.WriteTimeout,
		IdleTimeout:  cfg.HTTP.IdleTimeout,
	}

	transportTLSConfig := cfg.MTLS.ServerConfig()
	mtlsConfig, err := transportTLSConfig.ServerTLSConfig()
	if err != nil {
		log.Fatal().Err(err).Msg("failed to configure guide-service mTLS")
	}
	if err := validateGuideServiceMTLSPort(cfg, mtlsConfig); err != nil {
		log.Fatal().Err(err).Msg("invalid guide-service mTLS listener configuration")
	}
	internalHTTPServer := newInternalGuideHTTPMTLSServer(cfg, httpServer.Handler, mtlsConfig)
	grpcOptions := []grpc.ServerOption{
		grpc.UnaryInterceptor(grpcadapter.UnaryServerInterceptor(cfg, savedSourceAuthorizer)),
	}

	guideGRPCServer := grpcadapter.NewServer(
		guideUseCase,
		grpcadapter.WithSavedSource(savedSourceUseCase),
	)
	grpcServer := newGuideGRPCServer(guideGRPCServer, grpcOptions...)
	var internalGRPCServer *grpc.Server
	if mtlsConfig != nil {
		mtlsGRPCOptions, err := transportauth.GRPCServerOptions(transportTLSConfig)
		if err != nil {
			log.Fatal().Err(err).Msg("failed to configure guide-service internal mTLS gRPC")
		}
		internalGRPCServer = newGuideGRPCServer(guideGRPCServer, append(mtlsGRPCOptions, grpcOptions...)...)
	}

	go func() {
		log.Info().
			Str("address", cfg.HTTP.Address()).
			Msg("http server started")

		if err = httpServer.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatal().Err(err).Msg("http server failed")
		}
	}()

	if internalHTTPServer != nil {
		go func() {
			log.Info().
				Str("address", cfg.HTTP.InternalTLSAddress()).
				Msg("internal mTLS http server started")

			if err = internalHTTPServer.ListenAndServeTLS("", ""); err != nil && err != http.ErrServerClosed {
				log.Fatal().Err(err).Msg("internal mTLS http server failed")
			}
		}()
	}

	go func() {
		log.Info().
			Str("address", cfg.GRPC.Address()).
			Msg("grpc server started")

		if err = serveGuideGRPCServer(cfg.GRPC.Address(), grpcServer); err != nil {
			log.Fatal().Err(err).Msg("grpc server failed")
		}
	}()

	if internalGRPCServer != nil {
		go func() {
			log.Info().
				Str("address", cfg.GRPC.InternalTLSAddress()).
				Msg("internal mTLS grpc server started")

			if err = serveGuideGRPCServer(cfg.GRPC.InternalTLSAddress(), internalGRPCServer); err != nil {
				log.Fatal().Err(err).Msg("internal mTLS grpc server failed")
			}
		}()
	}

	<-ctx.Done()
	log.Info().Msg("shutdown signal received")

	shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	grpcServer.GracefulStop()
	if internalGRPCServer != nil {
		internalGRPCServer.GracefulStop()
	}

	if err = httpServer.Shutdown(shutdownCtx); err != nil {
		log.Error().Err(err).Msg("http server shutdown failed")
	} else {
		log.Info().Msg("http server stopped")
	}
	if internalHTTPServer != nil {
		if err = internalHTTPServer.Shutdown(shutdownCtx); err != nil {
			log.Error().Err(err).Msg("internal mTLS http server shutdown failed")
		}
	}
	if savedLifecycleRuntime != nil {
		if err = savedLifecycleRuntime.Shutdown(shutdownCtx); err != nil {
			log.Error().Err(err).Msg("Saved guide lifecycle runtime shutdown failed")
		}
	}
}

type savedLifecycleRuntime struct {
	connection *nats.Conn
	cancel     context.CancelFunc
	wait       sync.WaitGroup
}

func startSavedLifecycleRuntime(
	ctx context.Context,
	cfg *config.Config,
	repo *repository.PGGuideRepository,
	userSource app.SavedGuideUserSource,
) (*savedLifecycleRuntime, error) {
	if cfg == nil || repo == nil || userSource == nil {
		return nil, fmt.Errorf("Saved lifecycle runtime dependencies are required")
	}
	if !cfg.SavedLifecycle.Enabled {
		log.Info().Msg("Saved guide lifecycle delivery is disabled")
		return nil, nil
	}
	if err := cfg.SavedLifecycle.Validate(cfg.App.Env); err != nil {
		return nil, err
	}
	natsConfig, err := cfg.SavedLifecycle.NATSConfig(cfg.App.Env)
	if err != nil {
		return nil, err
	}
	connection, err := natstransport.Connect(
		natsConfig,
		"guide-service-saved-lifecycle",
		natstransport.Hooks{
			Disconnected: func(disconnectErr error) {
				log.Warn().Err(disconnectErr).Msg("Saved lifecycle NATS connection interrupted")
			},
			Reconnected: func() {
				log.Info().Msg("Saved lifecycle NATS connection restored")
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
		return nil, fmt.Errorf("connect Saved lifecycle NATS: %w", err)
	}
	publisher, err := natsadapter.NewSavedLifecyclePublisher(
		ctx,
		connection,
		cfg.SavedLifecycle.Subject,
	)
	if err != nil {
		connection.Close()
		return nil, err
	}
	dispatcher, err := app.NewSavedLifecycleDispatcher(
		repo,
		publisher,
		app.SavedLifecycleDispatcherConfig{
			BatchSize:          cfg.SavedLifecycle.BatchSize,
			Concurrency:        cfg.SavedLifecycle.Concurrency,
			PollInterval:       cfg.SavedLifecycle.PollInterval,
			LeaseDuration:      cfg.SavedLifecycle.LeaseDuration,
			PublishTimeout:     cfg.SavedLifecycle.PublishTimeout,
			DeliveredRetention: cfg.SavedLifecycle.DeliveredRetention,
			DeadRetention:      cfg.SavedLifecycle.DeadRetention,
			CleanupInterval:    cfg.SavedLifecycle.CleanupInterval,
			CleanupBatchSize:   200,
		},
	)
	if err != nil {
		connection.Close()
		return nil, err
	}
	reconciler, err := app.NewSavedGuideUserReconciler(
		repo,
		userSource,
		app.SavedGuideUserReconcilerConfig{
			BatchSize:        cfg.SavedLifecycle.ReconcileBatchSize,
			Concurrency:      cfg.SavedLifecycle.ReconcileConcurrency,
			PollInterval:     cfg.SavedLifecycle.ReconcilePollInterval,
			LeaseDuration:    cfg.SavedLifecycle.ReconcileLeaseDuration,
			SourceTimeout:    cfg.SavedLifecycle.ReconcileSourceTimeout,
			SuccessInterval:  cfg.SavedLifecycle.ReconcileInterval,
			FailureBaseDelay: cfg.SavedLifecycle.ReconcileFailureBase,
			FailureMaxDelay:  cfg.SavedLifecycle.ReconcileFailureMax,
		},
	)
	if err != nil {
		connection.Close()
		return nil, err
	}

	workerCtx, cancelWorkers := context.WithCancel(ctx)
	runtime := &savedLifecycleRuntime{connection: connection, cancel: cancelWorkers}
	runtime.wait.Add(2)
	go func() {
		defer runtime.wait.Done()
		if runErr := dispatcher.Run(workerCtx); runErr != nil {
			log.Error().Err(runErr).Msg("Saved lifecycle dispatcher stopped")
			runtime.cancel()
		}
	}()
	go func() {
		defer runtime.wait.Done()
		if runErr := reconciler.Run(workerCtx); runErr != nil {
			log.Error().Err(runErr).Msg("Saved guide user reconciler stopped")
			runtime.cancel()
		}
	}()
	log.Info().Msg("Saved guide lifecycle runtime started")
	return runtime, nil
}

func (r *savedLifecycleRuntime) Shutdown(ctx context.Context) error {
	if r == nil {
		return nil
	}
	if r.cancel != nil {
		r.cancel()
	}
	done := make(chan struct{})
	go func() {
		r.wait.Wait()
		close(done)
	}()
	select {
	case <-done:
	case <-ctx.Done():
		if r.connection != nil {
			r.connection.Close()
		}
		return ctx.Err()
	}
	if r.connection == nil {
		return nil
	}
	if err := natstransport.Drain(r.connection); err != nil {
		r.connection.Close()
		return fmt.Errorf("drain Saved lifecycle NATS connection: %w", err)
	}
	return nil
}

func newGuideGRPCServer(guideServer *grpcadapter.Server, options ...grpc.ServerOption) *grpc.Server {
	grpcServer := grpc.NewServer(options...)
	guidev1.RegisterGuideServiceServer(grpcServer, guideServer)
	contentv1.RegisterSavedSourceServiceServer(grpcServer, guideServer)
	return grpcServer
}

func newSavedGuideSourceAuthorizer(cfg *config.Config) (*serviceauth.JWTVerifier, error) {
	if cfg == nil {
		return nil, fmt.Errorf("guide service config is required")
	}
	if !cfg.Security.SavedSourceAuthEnabled() {
		if cfg.App.IsProduction() {
			return nil, fmt.Errorf(
				"SERVICE_AUTH_ISSUER, SERVICE_AUTH_JWKS_URL, and SAVED_SOURCE_ALLOWED_CALLER are required in production",
			)
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
		return nil, fmt.Errorf("configure Saved source JWKS client: %w", err)
	}
	verifier, err := serviceauth.NewJWTVerifier(serviceauth.VerifierConfig{
		Issuer:   cfg.Security.ServiceAuthIssuer,
		JWKSURL:  cfg.Security.ServiceAuthJWKSURL,
		CacheTTL: cfg.Security.ServiceAuthCacheTTL,
		Client:   jwksClient,
	})
	if err != nil {
		return nil, fmt.Errorf("configure Saved source verifier: %w", err)
	}
	return verifier, nil
}

func serveGuideGRPCServer(address string, server *grpc.Server) error {
	listener, err := net.Listen("tcp", address)
	if err != nil {
		return fmt.Errorf("listen: %w", err)
	}
	if err := server.Serve(listener); err != nil {
		return fmt.Errorf("serve: %w", err)
	}
	return nil
}

func validateGuideServiceMTLSPort(cfg *config.Config, tlsConfig *tls.Config) error {
	if tlsConfig == nil {
		return nil
	}
	if cfg.GRPC.InternalTLSPort == 0 {
		return fmt.Errorf("INTERNAL_GRPC_TLS_PORT is required when guide-service mTLS is enabled")
	}
	if cfg.GRPC.InternalTLSPort == cfg.GRPC.Port {
		return fmt.Errorf("INTERNAL_GRPC_TLS_PORT must be different from GRPC_PORT")
	}
	if cfg.HTTP.InternalTLSPort == 0 {
		return fmt.Errorf("INTERNAL_HTTP_TLS_PORT is required when guide-service mTLS is enabled")
	}
	if cfg.HTTP.InternalTLSPort == cfg.HTTP.Port {
		return fmt.Errorf("INTERNAL_HTTP_TLS_PORT must be different from HTTP_PORT")
	}
	return nil
}

func newInternalGuideHTTPMTLSServer(cfg *config.Config, handler http.Handler, tlsConfig *tls.Config) *http.Server {
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

func newExcursionServiceHTTPClient(cfg *config.Config) (*http.Client, error) {
	client, err := transportauth.NewHTTPClient(
		cfg.MTLS.ClientConfig(transportauth.ServerNameFromTarget(cfg.Excursion.BaseURL)),
		cfg.Excursion.Timeout,
	)
	if err != nil {
		return nil, fmt.Errorf("initialize excursion-service mTLS transport: %w", err)
	}
	return client, nil
}

func newUserServiceClient(cfg *config.Config) (*userserviceadapter.Client, error) {
	grpcOptions, err := transportauth.GRPCDialOptions(
		cfg.MTLS.ClientConfig(transportauth.ServerNameFromTarget(cfg.UserService.Target)),
	)
	if err != nil {
		return nil, fmt.Errorf("initialize user-service mTLS transport: %w", err)
	}
	return userserviceadapter.New(
		cfg.UserService.Target,
		cfg.Security.InternalServiceToken,
		"guide-service",
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
		"guide-service",
		grpcOptions...,
	)
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

func newFraudEvaluator(cfg *config.Config) (port.FraudEvaluator, error) {
	if cfg == nil || !cfg.AntiFraud.Enabled {
		return nil, nil
	}
	fraudHTTPClient, err := transportauth.NewHTTPClient(
		cfg.MTLS.ClientConfig(transportauth.ServerNameFromTarget(cfg.AntiFraud.BaseURL)),
		cfg.AntiFraud.Timeout,
	)
	if err != nil {
		return nil, fmt.Errorf("initialize anti-fraud mTLS transport: %w", err)
	}
	return fraudadapter.NewHTTPClient(
		cfg.AntiFraud.BaseURL,
		cfg.AntiFraud.InternalServiceToken,
		cfg.AntiFraud.SignalHashKey,
		cfg.AntiFraud.Timeout,
		fraudadapter.WithHTTPClient(fraudHTTPClient),
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
