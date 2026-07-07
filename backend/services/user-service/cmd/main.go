package main

import (
	"context"
	"crypto/tls"
	"fmt"
	"net"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"
	"google.golang.org/grpc"
	"kz/inflap/backend/pkg/serviceauth"
	"kz/inflap/backend/pkg/switches"
	"kz/inflap/backend/pkg/transportauth"
	feedserviceadapter "kz/inflap/backend/services/user-service/internal/adapter/feedservice"
	grpcadapter "kz/inflap/backend/services/user-service/internal/adapter/grpc"
	httpadapter "kz/inflap/backend/services/user-service/internal/adapter/http"
	phoneadapter "kz/inflap/backend/services/user-service/internal/adapter/phone"
	"kz/inflap/backend/services/user-service/internal/adapter/repository"
	searchindexadapter "kz/inflap/backend/services/user-service/internal/adapter/searchindex"
	"kz/inflap/backend/services/user-service/internal/app"
	"kz/inflap/backend/services/user-service/internal/config"

	filemanageradapter "kz/inflap/backend/services/user-service/internal/adapter/filemanager"
	userv1 "kz/inflap/proto/gen/go/user/v1"
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
		Msg("starting user-service")

	pool, err := newPostgresPool(ctx, cfg)
	if err != nil {
		log.Fatal().Err(err).Msg("failed to initialize postgres pool")
	}
	defer pool.Close()

	fileManagerClient, err := newFileManagerClient(cfg)
	if err != nil {
		log.Fatal().Err(err).Msg("failed to initialize file-manager grpc client")
	}
	defer fileManagerClient.Close()

	userRepo := repository.NewPGUserRepository(pool)
	userUseCase := app.NewUserUseCase(userRepo, fileManagerClient)
	if cfg.SearchService.Enabled {
		searchIndexOptions, closeSearchIndexAuth := newSearchIndexOptions(cfg)
		defer closeSearchIndexAuth()
		searchIndexer := searchindexadapter.New(
			cfg.SearchService.HTTPURL,
			cfg.Security.InternalServiceToken,
			cfg.SearchService.Timeout,
			searchIndexOptions...,
		)
		userUseCase.SetSearchIndexer(searchIndexer)
	}
	var feedServiceClient *feedserviceadapter.Client
	if cfg.Social.WorkerEnabled || cfg.Social.StartupDrainEnabled {
		feedHTTPClient, err := newFeedServiceHTTPClient(cfg)
		if err != nil {
			log.Fatal().Err(err).Msg("failed to initialize feed-service client")
		}
		feedServiceClient = feedserviceadapter.New(
			cfg.FeedService.HTTPURL,
			cfg.Security.InternalServiceToken,
			"user-service",
			cfg.FeedService.RequestTimeout,
			feedserviceadapter.WithHTTPClient(feedHTTPClient),
		)
	}
	if cfg.Social.StartupBackfillEnabled {
		stats, reconcileErr := app.ReconcileUserSocialOutbox(
			ctx,
			userRepo,
			feedServiceClient,
			app.UserSocialOutboxReconcilerConfig{
				BackfillEnabled: true,
				DrainEnabled:    cfg.Social.StartupDrainEnabled,
				MaxDrainBatches: cfg.Social.StartupMaxDrainBatches,
				WorkerConfig: app.UserSocialOutboxWorkerConfig{
					PollInterval: cfg.Social.WorkerPollInterval,
					BatchSize:    cfg.Social.WorkerBatchSize,
					MaxAttempts:  cfg.Social.WorkerMaxAttempts,
					BaseBackoff:  cfg.Social.WorkerBaseBackoff,
				},
			},
			time.Now().UTC(),
		)
		if reconcileErr != nil {
			log.Fatal().Err(reconcileErr).Msg("failed to reconcile feed social outbox")
		}
		log.Info().
			Int64("backfilled_events", stats.Backfilled).
			Int("drained_events", stats.Drained).
			Int("drain_batches", stats.DrainBatches).
			Msg("feed social outbox startup reconciliation completed")
	}
	if cfg.Social.WorkerEnabled {
		socialOutboxWorker := app.NewUserSocialOutboxWorker(
			userRepo,
			feedServiceClient,
			app.UserSocialOutboxWorkerConfig{
				PollInterval: cfg.Social.WorkerPollInterval,
				BatchSize:    cfg.Social.WorkerBatchSize,
				MaxAttempts:  cfg.Social.WorkerMaxAttempts,
				BaseBackoff:  cfg.Social.WorkerBaseBackoff,
			},
		)
		go socialOutboxWorker.Start(ctx)
		log.Info().Msg("user social outbox worker started")
	}
	if cfg.Phone.Provider != "log" {
		log.Fatal().
			Str("provider", cfg.Phone.Provider).
			Msg("unsupported PHONE_VERIFICATION_PROVIDER")
	}
	if cfg.App.IsProduction() && cfg.Phone.Provider == "log" {
		log.Fatal().Msg("PHONE_VERIFICATION_PROVIDER=log is not allowed in production")
	}
	if cfg.App.IsProduction() && cfg.Phone.CodeHashSecret == "" {
		log.Fatal().Msg("PHONE_VERIFICATION_CODE_HASH_SECRET is required in production")
	}
	if cfg.App.IsProduction() && cfg.Phone.DevelopmentStaticCode != "" {
		log.Fatal().Msg("PHONE_VERIFICATION_DEV_STATIC_CODE is not allowed in production")
	}
	phoneVerificationUseCase := app.NewPhoneVerificationUseCase(
		userRepo,
		phoneadapter.NewLogSender(cfg.App.Env),
		app.PhoneVerificationConfig{
			CodeLength:            cfg.Phone.CodeLength,
			CodeTTL:               cfg.Phone.CodeTTL,
			ResendCooldown:        cfg.Phone.ResendCooldown,
			MaxVerifyAttempts:     cfg.Phone.MaxVerifyAttempts,
			CodeHashSecret:        cfg.Phone.CodeHashSecret,
			DevelopmentStaticCode: cfg.Phone.DevelopmentStaticCode,
		},
	)

	httpHandler := httpadapter.NewHandler(userUseCase, phoneVerificationUseCase)
	httpMux := http.NewServeMux()
	httpHandler.Register(httpMux)

	httpServer := &http.Server{
		Addr:         cfg.HTTP.Address(),
		Handler:      httpadapter.Chain(cfg, withTechBreakMaintenance(withRequestLogging(httpMux), cfg.Switches, cfg.MTLS, cfg.Security.InternalServiceToken, "USER")),
		ReadTimeout:  cfg.HTTP.ReadTimeout,
		WriteTimeout: cfg.HTTP.WriteTimeout,
		IdleTimeout:  cfg.HTTP.IdleTimeout,
	}

	transportTLSConfig := cfg.MTLS.ServerConfig()
	mtlsConfig, err := transportTLSConfig.ServerTLSConfig()
	if err != nil {
		log.Fatal().Err(err).Msg("failed to configure user-service mTLS")
	}
	if err := validateUserServiceMTLSPort(cfg, mtlsConfig); err != nil {
		log.Fatal().Err(err).Msg("invalid user-service mTLS listener configuration")
	}
	internalHTTPServer := newInternalUserHTTPMTLSServer(cfg, httpServer.Handler, mtlsConfig)

	grpcOptions := []grpc.ServerOption{
		grpc.UnaryInterceptor(grpcadapter.UnaryServerInterceptor(cfg)),
	}

	userGRPCServer := grpcadapter.NewServer(userUseCase)
	grpcServer := newUserGRPCServer(userGRPCServer, grpcOptions...)
	var internalGRPCServer *grpc.Server
	if mtlsConfig != nil {
		mtlsGRPCOptions, err := transportauth.GRPCServerOptions(transportTLSConfig)
		if err != nil {
			log.Fatal().Err(err).Msg("failed to configure user-service internal mTLS gRPC")
		}
		internalGRPCServer = newUserGRPCServer(userGRPCServer, append(mtlsGRPCOptions, grpcOptions...)...)
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

		if serveErr := serveUserGRPCServer(cfg.GRPC.Address(), grpcServer); serveErr != nil {
			log.Fatal().Err(serveErr).Msg("grpc server failed")
		}
	}()

	if internalGRPCServer != nil {
		go func() {
			log.Info().
				Str("address", cfg.GRPC.InternalTLSAddress()).
				Msg("internal mTLS grpc server started")

			if serveErr := serveUserGRPCServer(cfg.GRPC.InternalTLSAddress(), internalGRPCServer); serveErr != nil {
				log.Fatal().Err(serveErr).Msg("internal mTLS grpc server failed")
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
}

func newUserGRPCServer(userServer userv1.UserServiceServer, options ...grpc.ServerOption) *grpc.Server {
	grpcServer := grpc.NewServer(options...)
	userv1.RegisterUserServiceServer(grpcServer, userServer)
	return grpcServer
}

func serveUserGRPCServer(address string, server *grpc.Server) error {
	listener, err := net.Listen("tcp", address)
	if err != nil {
		return fmt.Errorf("listen: %w", err)
	}
	if err := server.Serve(listener); err != nil {
		return fmt.Errorf("serve: %w", err)
	}
	return nil
}

func validateUserServiceMTLSPort(cfg *config.Config, tlsConfig *tls.Config) error {
	if tlsConfig == nil {
		return nil
	}
	if cfg.GRPC.InternalTLSPort == 0 {
		return fmt.Errorf("INTERNAL_GRPC_TLS_PORT is required when user-service mTLS is enabled")
	}
	if cfg.GRPC.InternalTLSPort == cfg.GRPC.Port {
		return fmt.Errorf("INTERNAL_GRPC_TLS_PORT must be different from GRPC_PORT")
	}
	if cfg.HTTP.InternalTLSPort == 0 {
		return fmt.Errorf("INTERNAL_HTTP_TLS_PORT is required when user-service mTLS is enabled")
	}
	if cfg.HTTP.InternalTLSPort == cfg.HTTP.Port {
		return fmt.Errorf("INTERNAL_HTTP_TLS_PORT must be different from HTTP_PORT")
	}
	return nil
}

func newInternalUserHTTPMTLSServer(cfg *config.Config, handler http.Handler, tlsConfig *tls.Config) *http.Server {
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
		"user-service",
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
