package main

import (
	"context"
	"crypto/tls"
	"fmt"
	"net"
	"net/http"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"
	"google.golang.org/grpc"
	"kz/inflap/backend/pkg/switches"
	"kz/inflap/backend/pkg/transportauth"
	"kz/inflap/backend/pkg/trustpolicy/grpcclient"
	fraudadapter "kz/inflap/backend/services/file-manager-service/internal/adapter/fraud"
	grpcadapter "kz/inflap/backend/services/file-manager-service/internal/adapter/grpc"
	httpadapter "kz/inflap/backend/services/file-manager-service/internal/adapter/http"
	"kz/inflap/backend/services/file-manager-service/internal/adapter/repository"
	noopstorage "kz/inflap/backend/services/file-manager-service/internal/adapter/storage/noop"
	s3storage "kz/inflap/backend/services/file-manager-service/internal/adapter/storage/s3"
	"kz/inflap/backend/services/file-manager-service/internal/app"
	"kz/inflap/backend/services/file-manager-service/internal/config"
	"kz/inflap/backend/services/file-manager-service/internal/domain/enum"
	"kz/inflap/backend/services/file-manager-service/internal/domain/port"
	filev1 "kz/inflap/proto/gen/go/file/v1"
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
		Msg("starting file-manager-service")

	pool, err := newPostgresPool(ctx, cfg)
	if err != nil {
		log.Fatal().Err(err).Msg("failed to initialize postgres pool")
	}
	defer pool.Close()

	storageClient, err := newStorageProvider(ctx, cfg)
	if err != nil {
		log.Fatal().Err(err).Msg("failed to initialize storage provider")
	}

	fileRepo := repository.NewPGFileRepository(pool)
	bindingRepo := repository.NewPGFileBindingRepository(pool)
	idempotencyRepo := repository.NewPGIdempotencyRepository(pool)
	cleanupRepo := repository.NewIdempotencyCleanupRepository(pool)

	fraudClient, err := newFraudEvaluator(cfg)
	if err != nil {
		log.Fatal().Err(err).Msg("failed to initialize anti-fraud client")
	}

	fileUseCase := app.NewFileUseCaseWithFraud(fileRepo, storageClient, cfg, idempotencyRepo, fraudClient)
	bindingUseCase := app.NewFileBindingUseCaseWithFraud(fileRepo, bindingRepo, fraudClient)
	var trustClient *grpcclient.Client
	if cfg.Trust.Enabled {
		trustClient, err = newTrustPolicyClient(cfg)
		if err != nil {
			log.Fatal().Err(err).Msg("failed to initialize trust-service client")
		}
		defer trustClient.Close()
		fileUseCase.SetTrustPolicyClient(trustClient)
		bindingUseCase.SetTrustPolicyClient(trustClient)
	}

	httpHandler := httpadapter.NewHandler(fileUseCase, bindingUseCase)
	httpMux := http.NewServeMux()
	httpHandler.Register(httpMux)
	httpApplicationHandler := httpadapter.Chain(cfg, withTechBreakMaintenance(httpMux, cfg.Switches, cfg.MTLS, cfg.Security.InternalServiceToken, "FILE_MANAGER"))

	httpServer := &http.Server{
		Addr:         cfg.HTTP.Address(),
		Handler:      httpApplicationHandler,
		ReadTimeout:  cfg.HTTP.ReadTimeout,
		WriteTimeout: cfg.HTTP.WriteTimeout,
		IdleTimeout:  cfg.HTTP.IdleTimeout,
	}

	transportTLSConfig := cfg.MTLS.ServerConfig()
	mtlsConfig, err := transportTLSConfig.ServerTLSConfig()
	if err != nil {
		log.Fatal().Err(err).Msg("failed to configure file-manager-service mTLS")
	}
	if err := validateFileManagerServiceMTLSPort(cfg, mtlsConfig); err != nil {
		log.Fatal().Err(err).Msg("invalid file-manager-service mTLS listener configuration")
	}
	internalHTTPServer := newInternalFileManagerHTTPMTLSServer(cfg, httpApplicationHandler, mtlsConfig)

	grpcOptions := []grpc.ServerOption{
		grpc.UnaryInterceptor(grpcadapter.UnaryServerInterceptor(cfg)),
	}

	fileGRPCServer := grpcadapter.NewServer(fileUseCase, bindingUseCase)
	grpcServer := newFileManagerGRPCServer(fileGRPCServer, grpcOptions...)
	var internalGRPCServer *grpc.Server
	if mtlsConfig != nil {
		mtlsGRPCOptions, err := transportauth.GRPCServerOptions(transportTLSConfig)
		if err != nil {
			log.Fatal().Err(err).Msg("failed to configure file-manager-service internal mTLS gRPC")
		}
		internalGRPCServer = newFileManagerGRPCServer(fileGRPCServer, append(mtlsGRPCOptions, grpcOptions...)...)
	}

	cleanupWorker := app.NewIdempotencyCleanupWorker(cleanupRepo, time.Hour, 1000)
	go cleanupWorker.Start(ctx)

	expiredStoryMediaWorker := app.NewExpiredUploadCleanupWorker(
		fileUseCase,
		enum.FilePurposeStoryMedia,
		time.Hour,
		100,
	)
	go expiredStoryMediaWorker.Start(ctx)

	go func() {
		log.Info().
			Str("address", cfg.HTTP.Address()).
			Msg("http server started")

		if err = httpServer.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatal().Err(err).Msg("http server failed")
		}
	}()

	go func() {
		log.Info().
			Str("address", cfg.GRPC.Address()).
			Msg("grpc server started")

		if err = serveFileManagerGRPCServer(cfg.GRPC.Address(), grpcServer); err != nil {
			log.Fatal().Err(err).Msg("grpc server failed")
		}
	}()

	if internalGRPCServer != nil {
		go func() {
			log.Info().
				Str("address", cfg.GRPC.InternalTLSAddress()).
				Msg("internal mTLS grpc server started")

			if err = serveFileManagerGRPCServer(cfg.GRPC.InternalTLSAddress(), internalGRPCServer); err != nil {
				log.Fatal().Err(err).Msg("internal mTLS grpc server failed")
			}
		}()
	}
	if internalHTTPServer != nil {
		go func() {
			log.Info().
				Str("address", cfg.HTTP.InternalTLSAddress()).
				Msg("internal mTLS http server started")

			if serveErr := internalHTTPServer.ListenAndServeTLS("", ""); serveErr != nil && serveErr != http.ErrServerClosed {
				log.Fatal().Err(serveErr).Msg("internal mTLS http server failed")
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
		} else {
			log.Info().Msg("internal mTLS http server stopped")
		}
	}
}

func newFileManagerGRPCServer(fileServer filev1.FileServiceServer, options ...grpc.ServerOption) *grpc.Server {
	grpcServer := grpc.NewServer(options...)
	filev1.RegisterFileServiceServer(grpcServer, fileServer)
	return grpcServer
}

func serveFileManagerGRPCServer(address string, server *grpc.Server) error {
	listener, err := net.Listen("tcp", address)
	if err != nil {
		return fmt.Errorf("listen: %w", err)
	}
	if err := server.Serve(listener); err != nil {
		return fmt.Errorf("serve: %w", err)
	}
	return nil
}

func validateFileManagerServiceMTLSPort(cfg *config.Config, tlsConfig *tls.Config) error {
	if tlsConfig == nil {
		return nil
	}
	if cfg.GRPC.InternalTLSPort == 0 {
		return fmt.Errorf("INTERNAL_GRPC_TLS_PORT is required when file-manager-service mTLS is enabled")
	}
	if cfg.GRPC.InternalTLSPort == cfg.GRPC.Port {
		return fmt.Errorf("INTERNAL_GRPC_TLS_PORT must be different from GRPC_PORT")
	}
	if cfg.HTTP.InternalTLSPort == 0 {
		return fmt.Errorf("INTERNAL_HTTP_TLS_PORT is required when file-manager-service mTLS is enabled")
	}
	if cfg.HTTP.InternalTLSPort == cfg.HTTP.Port {
		return fmt.Errorf("INTERNAL_HTTP_TLS_PORT must be different from HTTP_PORT")
	}
	return nil
}

func newInternalFileManagerHTTPMTLSServer(cfg *config.Config, handler http.Handler, tlsConfig *tls.Config) *http.Server {
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

func newStorageProvider(ctx context.Context, cfg *config.Config) (port.StorageProvider, error) {
	switch strings.ToLower(strings.TrimSpace(cfg.Storage.Provider)) {
	case "s3", "r2", "minio", "seaweedfs":
		return s3storage.New(ctx, cfg.Storage)
	case "noop":
		return noopstorage.New(), nil
	default:
		return nil, fmt.Errorf("unsupported storage provider: %s", cfg.Storage.Provider)
	}
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

func newTrustPolicyClient(cfg *config.Config) (*grpcclient.Client, error) {
	return grpcclient.NewWithTransportAuth(
		cfg.Trust.Target,
		cfg.Security.InternalServiceToken,
		"file-manager-service",
		cfg.Trust.Timeout,
		cfg.MTLS.ClientConfig(transportauth.ServerNameFromTarget(cfg.Trust.Target)),
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
