package main

import (
	"context"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	filemanageradapter "github.com/dkhvan-dev/flyfy/backend/services/tour-service/internal/adapter/filemanager"
	grpcadapter "github.com/dkhvan-dev/flyfy/backend/services/tour-service/internal/adapter/grpc"
	guideadapter "github.com/dkhvan-dev/flyfy/backend/services/tour-service/internal/adapter/guide"
	httpadapter "github.com/dkhvan-dev/flyfy/backend/services/tour-service/internal/adapter/http"
	"github.com/dkhvan-dev/flyfy/backend/services/tour-service/internal/adapter/repository"
	"github.com/dkhvan-dev/flyfy/backend/services/tour-service/internal/app"
	"github.com/dkhvan-dev/flyfy/backend/services/tour-service/internal/config"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
)

func main() {
	ctx := context.Background()
	cfg, err := config.Load(ctx)
	if err != nil {
		log.Fatal().Err(err).Msg("load config")
	}
	configureLogger(cfg)

	pool, err := newPostgresPool(ctx, cfg)
	if err != nil {
		log.Fatal().Err(err).Msg("initialize postgres")
	}
	defer pool.Close()
	if err = pool.Ping(ctx); err != nil {
		log.Fatal().Err(err).Msg("ping postgres")
	}

	repo := repository.NewPGTourRepository(pool)
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

	fileManagerClient, err := filemanageradapter.New(
		cfg.FileManager.Target,
		grpc.WithTransportCredentials(insecure.NewCredentials()),
		grpc.WithUnaryInterceptor(grpcadapter.InternalTokenInterceptor(
			cfg.Security.InternalServiceToken,
			cfg.App.Name,
		)),
	)
	if err != nil {
		log.Fatal().Err(err).Msg("dial file-manager-service")
	}
	defer fileManagerClient.Close()

	tourUC := app.NewTourUseCase(repo, guideClient, fileManagerClient)
	handler := httpadapter.NewHandler(tourUC, fileManagerClient)

	mux := http.NewServeMux()
	handler.Register(mux)

	server := &http.Server{
		Addr:         cfg.HTTP.Address(),
		Handler:      httpadapter.Chain(cfg, mux),
		ReadTimeout:  cfg.HTTP.ReadTimeout,
		WriteTimeout: cfg.HTTP.WriteTimeout,
		IdleTimeout:  cfg.HTTP.IdleTimeout,
	}

	errCh := make(chan error, 1)
	go func() {
		log.Info().Str("service", cfg.App.Name).Int("port", cfg.HTTP.Port).Msg("HTTP server started")
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			errCh <- err
			return
		}
		errCh <- nil
	}()

	stop := make(chan os.Signal, 1)
	signal.Notify(stop, syscall.SIGINT, syscall.SIGTERM)

	select {
	case sig := <-stop:
		log.Info().Str("signal", sig.String()).Msg("received shutdown signal")
	case err := <-errCh:
		if err != nil {
			log.Fatal().Err(err).Msg("http server failed")
		}
	}

	shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if err := server.Shutdown(shutdownCtx); err != nil {
		log.Error().Err(err).Msg("http shutdown failed")
	}
	log.Info().Str("service", cfg.App.Name).Msg("service stopped")
}

func configureLogger(cfg *config.Config) {
	level, err := zerolog.ParseLevel(cfg.Log.Level)
	if err != nil {
		level = zerolog.InfoLevel
	}
	zerolog.SetGlobalLevel(level)
	log.Logger = log.Output(zerolog.ConsoleWriter{Out: os.Stderr, TimeFormat: time.RFC3339})
}

func newPostgresPool(ctx context.Context, cfg *config.Config) (*pgxpool.Pool, error) {
	poolCfg, err := pgxpool.ParseConfig(cfg.DB.DSN())
	if err != nil {
		return nil, err
	}
	poolCfg.MaxConns = cfg.DB.MaxConns
	poolCfg.MinConns = cfg.DB.MinConns
	poolCfg.MaxConnLifetime = cfg.DB.ParsedMaxConnLifetime()
	poolCfg.MaxConnIdleTime = cfg.DB.ParsedMaxConnIdleTime()
	return pgxpool.NewWithConfig(ctx, poolCfg)
}
