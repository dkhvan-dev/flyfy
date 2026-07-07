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
	"github.com/redis/go-redis/v9"
	"github.com/rs/zerolog"
	"google.golang.org/grpc"

	"google.golang.org/grpc/reflection"
	"kz/inflap/backend/pkg/transportauth"
	"kz/inflap/backend/services/token-service/internal/adapter/crypto"
	tokengrpc "kz/inflap/backend/services/token-service/internal/adapter/grpc"
	"kz/inflap/backend/services/token-service/internal/adapter/grpc/handler"
	"kz/inflap/backend/services/token-service/internal/adapter/grpc/interceptor"
	httpAdapter "kz/inflap/backend/services/token-service/internal/adapter/http"
	notificationAdapter "kz/inflap/backend/services/token-service/internal/adapter/notification"
	"kz/inflap/backend/services/token-service/internal/adapter/repository"
	"kz/inflap/backend/services/token-service/internal/app"
	"kz/inflap/backend/services/token-service/internal/config"
	"kz/inflap/backend/services/token-service/internal/domain/port"
	pb "kz/inflap/proto/gen/go/token"
)

func main() {
	// --- Logger ---
	logger := zerolog.New(os.Stdout).
		With().
		Timestamp().
		Str("service", "token-service").
		Logger()

	if os.Getenv("APP_ENV") == "development" {
		logger = logger.Output(zerolog.ConsoleWriter{Out: os.Stderr})
	}

	// --- Config ---
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	cfg, err := config.Load(ctx)
	if err != nil {
		logger.Fatal().Err(err).Msg("failed to load config")
	}

	logger.Info().
		Int("grpc_port", cfg.GRPCPort).
		Int("http_port", cfg.HTTPPort).
		Str("env", cfg.Env).
		Msg("starting token-service")

	// --- Infrastructure ---

	// PostgreSQL
	pgPool, err := pgxpool.New(ctx, cfg.Postgres.DSN())
	if err != nil {
		logger.Fatal().Err(err).Msg("failed to connect to PostgreSQL")
	}
	defer pgPool.Close()

	if err := pgPool.Ping(ctx); err != nil {
		logger.Fatal().Err(err).Msg("PostgreSQL ping failed")
	}
	logger.Info().Msg("PostgreSQL connected")

	// Redis
	rdb := redis.NewClient(&redis.Options{
		Addr:     cfg.Redis.Addr,
		Password: cfg.Redis.Password,
		DB:       cfg.Redis.DB,
	})
	defer rdb.Close()

	if err := rdb.Ping(ctx).Err(); err != nil {
		logger.Fatal().Err(err).Msg("Redis ping failed")
	}
	logger.Info().Msg("Redis connected")

	// --- Adapters (secondary ports) ---
	var keyStore port.KeyStore
	if cfg.JWT.PrivateKeyPath != "" {
		keyStore = repository.NewFileKeyStore(cfg.JWT.PrivateKeyPath)
		logger.Info().Str("path", cfg.JWT.PrivateKeyPath).Msg("using persistent file key store")
	} else {
		keyStore = repository.NewInMemoryKeyStore()
		logger.Warn().Msg("using in-memory key store; JWT sessions will be invalidated on service restart")
	}
	revStore := repository.NewRedisRevocationStore(rdb)
	revSessionCache := repository.NewRedisRevokedSessionCache(rdb)
	sessionStore := repository.NewPgSessionStore(pgPool)
	sessionAudit := repository.NewPgSessionAuditLogger(pgPool, logger)
	svcStore := repository.NewPgServiceAccountStore(pgPool)
	passwordVerifier := crypto.NewBcryptVerifier(0) // 0 = use DefaultCost (12)
	audit := repository.NewZerologAuditLogger(logger)
	var tokenOptions []app.Option
	if cfg.Notification.HTTPURL != "" && cfg.Notification.InternalServiceToken != "" {
		notificationHTTPClient, err := newNotificationServiceHTTPClient(cfg)
		if err != nil {
			logger.Fatal().Err(err).Msg("failed to initialize notification-service mTLS transport")
		}
		tokenOptions = append(tokenOptions, app.WithSessionRevocationNotifier(
			notificationAdapter.NewClient(
				cfg.Notification.HTTPURL,
				cfg.Notification.InternalServiceToken,
				cfg.Notification.Timeout,
				notificationAdapter.WithHTTPClient(notificationHTTPClient),
			),
		))
		logger.Info().Str("url", cfg.Notification.HTTPURL).Msg("notification session revocation notifier enabled")
	}

	// --- Application (use cases) ---
	tokenUC := app.NewTokenUseCase(
		cfg.JWT, cfg.Session,
		keyStore, revStore, sessionStore, revSessionCache, sessionAudit,
		svcStore, passwordVerifier, audit, logger,
		tokenOptions...,
	)

	// --- Ensure initial key ---
	scheduler := app.NewKeyRotationScheduler(tokenUC, cfg.JWT, logger)
	if err := scheduler.EnsureActiveKey(ctx, keyStore); err != nil {
		logger.Fatal().Err(err).Msg("failed to ensure active signing key")
	}

	// Start background key rotation
	go scheduler.Start(ctx)

	// --- gRPC Server ---
	grpcHandler := handler.NewTokenGRPCHandler(tokenUC, tokenUC, tokenUC, tokenUC, tokenUC, tokenUC, logger)
	transportTLSConfig := cfg.MTLS.ServerConfig()
	mtlsConfig, err := transportTLSConfig.ServerTLSConfig()
	if err != nil {
		logger.Fatal().Err(err).Msg("failed to configure token-service mTLS")
	}
	if err := validateTokenServiceMTLSPorts(cfg, mtlsConfig); err != nil {
		logger.Fatal().Err(err).Msg("invalid token-service mTLS listener configuration")
	}

	// Define method permissions for S2S auth interceptor
	// Methods listed here require service token + specified roles.
	// AuthenticateService is intentionally NOT protected (it's the login endpoint for services).
	methodPerms := interceptor.MethodPermissions{
		// These methods require service auth + specific roles
		"/token.v1.TokenService/GenerateUserTokens":    {"token:generate"},
		"/token.v1.TokenService/ValidateAccessToken":   {"token:validate"},
		"/token.v1.TokenService/ValidateRefreshToken":  {"token:validate"},
		"/token.v1.TokenService/RefreshTokens":         {"token:generate", "token:validate"},
		"/token.v1.TokenService/RevokeToken":           {"token:revoke"},
		"/token.v1.TokenService/ListUserSessions":      {"token:revoke"},
		"/token.v1.TokenService/RevokeSession":         {"token:revoke"},
		"/token.v1.TokenService/RevokeAllUserSessions": {"token:revoke"},
		"/token.v1.TokenService/ValidateServiceToken":  {"token:validate"},
		"/token.v1.TokenService/GenerateServiceToken":  {"token:generate"},
		// AuthenticateService is NOT in this map → public (no service token required)
	}

	grpcOptions := []grpc.ServerOption{
		grpc.ChainUnaryInterceptor(
			interceptor.RecoveryInterceptor(logger),
			interceptor.LoggingInterceptor(logger),
			interceptor.ServiceAuthInterceptor(tokenUC, audit, methodPerms, logger),
		),
	}
	grpcServer := grpc.NewServer(grpcOptions...)

	// Register the gRPC service
	tokenSrv := tokengrpc.NewTokenServiceServer(grpcHandler)
	pb.RegisterTokenServiceServer(grpcServer, tokenSrv)

	// Enable reflection (so Apidog can discover endpoints)
	reflection.Register(grpcServer)

	var internalGRPCServer *grpc.Server
	if mtlsConfig != nil {
		mtlsGRPCOptions, err := transportauth.GRPCServerOptions(transportTLSConfig)
		if err != nil {
			logger.Fatal().Err(err).Msg("failed to configure token-service internal mTLS gRPC")
		}
		internalGRPCServer = grpc.NewServer(append(mtlsGRPCOptions, grpcOptions...)...)
		pb.RegisterTokenServiceServer(internalGRPCServer, tokenSrv)
		reflection.Register(internalGRPCServer)
	}

	// --- HTTP Server (JWKS + Health) ---
	jwksHandler := httpAdapter.NewJWKSHandler(tokenUC, logger)
	httpServer := &http.Server{
		Addr:         fmt.Sprintf(":%d", cfg.HTTPPort),
		Handler:      jwksHandler.Router(),
		ReadTimeout:  5 * time.Second,
		WriteTimeout: 10 * time.Second,
		IdleTimeout:  30 * time.Second,
	}
	internalHTTPServer := newInternalMTLSHTTPServer(cfg, jwksHandler.Router(), mtlsConfig)

	// --- Start servers ---
	errCh := make(chan error, 4)

	// gRPC
	go func() {
		lis, err := net.Listen("tcp", fmt.Sprintf(":%d", cfg.GRPCPort))
		if err != nil {
			errCh <- fmt.Errorf("gRPC listen: %w", err)
			return
		}
		logger.Info().Int("port", cfg.GRPCPort).Msg("gRPC server listening")
		if err := grpcServer.Serve(lis); err != nil {
			errCh <- fmt.Errorf("gRPC serve: %w", err)
		}
	}()

	if internalGRPCServer != nil {
		go func() {
			lis, err := net.Listen("tcp", fmt.Sprintf(":%d", cfg.InternalGRPCTLSPort))
			if err != nil {
				errCh <- fmt.Errorf("internal mTLS gRPC listen: %w", err)
				return
			}
			logger.Info().Int("port", cfg.InternalGRPCTLSPort).Msg("internal mTLS gRPC server listening")
			if err := internalGRPCServer.Serve(lis); err != nil {
				errCh <- fmt.Errorf("internal mTLS gRPC serve: %w", err)
			}
		}()
	}

	// HTTP
	go func() {
		logger.Info().Int("port", cfg.HTTPPort).Msg("HTTP server listening (JWKS + Health)")
		if err := httpServer.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			errCh <- fmt.Errorf("HTTP serve: %w", err)
		}
	}()

	if internalHTTPServer != nil {
		go func() {
			logger.Info().Int("port", cfg.InternalHTTPTLSPort).Msg("internal mTLS HTTP server listening (JWKS + Health)")
			if err := internalHTTPServer.ListenAndServeTLS("", ""); err != nil && err != http.ErrServerClosed {
				errCh <- fmt.Errorf("internal mTLS HTTP serve: %w", err)
			}
		}()
	}

	// --- Graceful shutdown ---
	sigCh := make(chan os.Signal, 1)
	signal.Notify(sigCh, syscall.SIGINT, syscall.SIGTERM)

	select {
	case sig := <-sigCh:
		logger.Info().Str("signal", sig.String()).Msg("shutdown signal received")
	case err := <-errCh:
		logger.Error().Err(err).Msg("server error")
	}

	// Initiate graceful shutdown
	logger.Info().Msg("shutting down...")
	cancel()

	shutdownCtx, shutdownCancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer shutdownCancel()

	grpcServer.GracefulStop()
	if internalGRPCServer != nil {
		internalGRPCServer.GracefulStop()
	}
	if err := httpServer.Shutdown(shutdownCtx); err != nil {
		logger.Error().Err(err).Msg("HTTP shutdown error")
	}
	if internalHTTPServer != nil {
		if err := internalHTTPServer.Shutdown(shutdownCtx); err != nil {
			logger.Error().Err(err).Msg("internal mTLS HTTP shutdown error")
		}
	}

	logger.Info().Msg("token-service stopped")
}

func validateTokenServiceMTLSPorts(cfg *config.Config, tlsConfig *tls.Config) error {
	if tlsConfig == nil {
		return nil
	}
	if cfg.InternalGRPCTLSPort == 0 {
		return fmt.Errorf("INTERNAL_GRPC_TLS_PORT is required when token-service mTLS is enabled")
	}
	if cfg.InternalHTTPTLSPort == 0 {
		return fmt.Errorf("INTERNAL_HTTP_TLS_PORT is required when token-service mTLS is enabled")
	}
	return nil
}

func newInternalMTLSHTTPServer(cfg *config.Config, handler http.Handler, tlsConfig *tls.Config) *http.Server {
	if tlsConfig == nil || cfg.InternalHTTPTLSPort == 0 {
		return nil
	}
	return &http.Server{
		Addr:         fmt.Sprintf(":%d", cfg.InternalHTTPTLSPort),
		Handler:      handler,
		ReadTimeout:  5 * time.Second,
		WriteTimeout: 10 * time.Second,
		IdleTimeout:  30 * time.Second,
		TLSConfig:    tlsConfig,
	}
}

func newNotificationServiceHTTPClient(cfg *config.Config) (*http.Client, error) {
	return transportauth.NewHTTPClient(
		cfg.MTLS.ClientConfig(transportauth.ServerNameFromTarget(cfg.Notification.HTTPURL)),
		cfg.Notification.Timeout,
	)
}
