package main

import (
	"context"
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
	"kz/inflap/backend/pkg/trustpolicy/grpcclient"
	fraudadapter "kz/inflap/backend/services/file-manager-service/internal/adapter/fraud"
	grpcadapter "kz/inflap/backend/services/file-manager-service/internal/adapter/grpc"
	httpadapter "kz/inflap/backend/services/file-manager-service/internal/adapter/http"
	"kz/inflap/backend/services/file-manager-service/internal/adapter/repository"
	noopstorage "kz/inflap/backend/services/file-manager-service/internal/adapter/storage/noop"
	s3storage "kz/inflap/backend/services/file-manager-service/internal/adapter/storage/s3"
	"kz/inflap/backend/services/file-manager-service/internal/app"
	"kz/inflap/backend/services/file-manager-service/internal/config"
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
		trustClient, err = grpcclient.New(
			cfg.Trust.Target,
			cfg.Security.InternalServiceToken,
			"file-manager-service",
			cfg.Trust.Timeout,
		)
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

	httpServer := &http.Server{
		Addr:         cfg.HTTP.Address(),
		Handler:      httpadapter.Chain(cfg, httpMux),
		ReadTimeout:  cfg.HTTP.ReadTimeout,
		WriteTimeout: cfg.HTTP.WriteTimeout,
		IdleTimeout:  cfg.HTTP.IdleTimeout,
	}

	grpcLis, err := net.Listen("tcp", cfg.GRPC.Address())
	if err != nil {
		log.Fatal().Err(err).Msg("failed to listen grpc")
	}

	grpcServer := grpc.NewServer(
		grpc.UnaryInterceptor(grpcadapter.UnaryServerInterceptor(cfg)),
	)

	fileGRPCServer := grpcadapter.NewServer(fileUseCase, bindingUseCase)
	filev1.RegisterFileServiceServer(grpcServer, fileGRPCServer)

	cleanupWorker := app.NewIdempotencyCleanupWorker(cleanupRepo, time.Hour, 1000)
	go cleanupWorker.Start(ctx)

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

		if err = grpcServer.Serve(grpcLis); err != nil {
			log.Fatal().Err(err).Msg("grpc server failed")
		}
	}()

	<-ctx.Done()
	log.Info().Msg("shutdown signal received")

	shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	grpcServer.GracefulStop()

	if err = httpServer.Shutdown(shutdownCtx); err != nil {
		log.Error().Err(err).Msg("http server shutdown failed")
	} else {
		log.Info().Msg("http server stopped")
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
	return fraudadapter.NewHTTPClient(
		cfg.AntiFraud.BaseURL,
		cfg.AntiFraud.InternalServiceToken,
		cfg.AntiFraud.SignalHashKey,
		cfg.AntiFraud.Timeout,
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
