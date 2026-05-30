package main

import (
	"context"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"

	"kz/inflap/backend/services/sticker-service/internal/adapter/filemanager"
	httpadapter "kz/inflap/backend/services/sticker-service/internal/adapter/http"
	"kz/inflap/backend/services/sticker-service/internal/adapter/repository"
	"kz/inflap/backend/services/sticker-service/internal/app"
	"kz/inflap/backend/services/sticker-service/internal/config"
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

	stickerRepo := repository.NewPGStickerRepository(pool)
	fileManagerClient := filemanager.NewClient(
		cfg.FileManager.BaseURL,
		cfg.FileManager.EffectiveInternalServiceToken(cfg.Security.InternalServiceToken),
		&http.Client{Timeout: cfg.FileManager.Timeout},
	)
	stickerUseCase := app.NewStickerUseCase(
		stickerRepo,
		fileManagerClient,
		app.WithPostModeration(cfg.Sticker.PostModerationEnabled),
		app.WithUploadSessionTTL(cfg.Sticker.UploadSessionTTL),
	)

	mux := http.NewServeMux()
	handler := httpadapter.NewHandler(stickerUseCase, cfg.Security.InternalServiceToken)
	handler.Register(mux)

	server := &http.Server{
		Addr: cfg.HTTP.Address(),
		Handler: httpadapter.Chain(httpadapter.MiddlewareConfig{
			RequestIDHeader:            cfg.Security.RequestIDHeader,
			TrustedGatewayHeaderUserID: cfg.Security.TrustedGatewayHeaderUserID,
			TrustedGatewayHeaderRoles:  cfg.Security.TrustedGatewayHeaderRoles,
			TrustedGatewayHeaderSub:    cfg.Security.TrustedGatewayHeaderSub,
		}, mux),
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
			log.Fatal().Err(err).Msg("HTTP server failed")
		}
	}

	shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	if err := server.Shutdown(shutdownCtx); err != nil {
		log.Error().Err(err).Msg("HTTP shutdown failed")
	}
	log.Info().Str("service", cfg.App.Name).Msg("service stopped")
}

func configureLogger(cfg *config.Config) {
	level, err := zerolog.ParseLevel(cfg.Log.Level)
	if err != nil {
		level = zerolog.InfoLevel
	}
	zerolog.SetGlobalLevel(level)

	if cfg.Log.Pretty || !cfg.App.IsProduction() {
		log.Logger = zerolog.New(zerolog.ConsoleWriter{
			Out:        os.Stdout,
			TimeFormat: time.RFC3339,
		}).With().Timestamp().Logger()
		return
	}

	log.Logger = zerolog.New(os.Stdout).With().Timestamp().Logger()
}

func newPostgresPool(ctx context.Context, cfg *config.Config) (*pgxpool.Pool, error) {
	poolConfig, err := pgxpool.ParseConfig(cfg.DB.DSN())
	if err != nil {
		return nil, err
	}

	poolConfig.MaxConns = cfg.DB.MaxConns
	poolConfig.MinConns = cfg.DB.MinConns
	poolConfig.MaxConnLifetime = cfg.DB.ParsedMaxConnLifetime()
	poolConfig.MaxConnIdleTime = cfg.DB.ParsedMaxConnIdleTime()

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
