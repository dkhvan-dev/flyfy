package main

import (
	"context"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	httpadapter "github.com/dkhvan-dev/flyfy/backend/services/attraction-service/internal/adapter/http"
	"github.com/dkhvan-dev/flyfy/backend/services/attraction-service/internal/adapter/repository"
	userserviceadapter "github.com/dkhvan-dev/flyfy/backend/services/attraction-service/internal/adapter/userservice"
	"github.com/dkhvan-dev/flyfy/backend/services/attraction-service/internal/app"
	"github.com/dkhvan-dev/flyfy/backend/services/attraction-service/internal/config"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"
)

func main() {
	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	cfg, err := config.Load(ctx)
	if err != nil {
		panic(err)
	}

	setupLogger(cfg)
	log.Info().Str("env", cfg.App.Env).Msg("starting attraction-service")

	pool, err := newPostgresPool(ctx, cfg)
	if err != nil {
		log.Fatal().Err(err).Msg("failed to initialize postgres pool")
	}
	defer pool.Close()

	userClient, err := userserviceadapter.New(
		cfg.UserService.GRPCTarget,
		cfg.Security.InternalServiceToken,
		"attraction-service",
	)
	if err != nil {
		log.Fatal().Err(err).Msg("failed to initialize user-service grpc client")
	}
	defer userClient.Close()

	repo := repository.NewPGAttractionRepository(pool)
	adminAuthorUserID, err := uuid.Parse(cfg.Admin.AttractionAuthorUserID)
	if err != nil || adminAuthorUserID == uuid.Nil {
		log.Fatal().Err(err).Str("admin_author_user_id", cfg.Admin.AttractionAuthorUserID).Msg("invalid admin attraction author user id")
	}
	useCase := app.NewAttractionUseCase(repo, userClient, app.WithAdminAuthorUserID(adminAuthorUserID))

	handler := httpadapter.NewHandler(useCase)
	mux := http.NewServeMux()
	handler.Register(mux)

	readTimeout, _ := time.ParseDuration(cfg.HTTP.ReadTimeout)
	writeTimeout, _ := time.ParseDuration(cfg.HTTP.WriteTimeout)
	idleTimeout, _ := time.ParseDuration(cfg.HTTP.IdleTimeout)

	server := &http.Server{
		Addr:         cfg.HTTP.Address(),
		Handler:      httpadapter.Chain(cfg, mux),
		ReadTimeout:  readTimeout,
		WriteTimeout: writeTimeout,
		IdleTimeout:  idleTimeout,
	}

	go func() {
		log.Info().Str("address", cfg.HTTP.Address()).Msg("http server started")
		if err = server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatal().Err(err).Msg("http server failed")
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
