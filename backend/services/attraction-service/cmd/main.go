package main

import (
	"context"
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
	cacheadapter "kz/inflap/backend/services/attraction-service/internal/adapter/cache"
	httpadapter "kz/inflap/backend/services/attraction-service/internal/adapter/http"
	"kz/inflap/backend/services/attraction-service/internal/adapter/repository"
	userserviceadapter "kz/inflap/backend/services/attraction-service/internal/adapter/userservice"
	"kz/inflap/backend/services/attraction-service/internal/app"
	"kz/inflap/backend/services/attraction-service/internal/config"
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

	useCaseOptions := []app.AttractionUseCaseOption{app.WithAdminAuthorUserID(adminAuthorUserID)}
	redisClient := newRedisClient(ctx, cfg)
	if redisClient != nil {
		defer redisClient.Close()
		attractionCache := cacheadapter.NewRedisAttractionCache(redisClient, cfg.Redis.KeyPrefix)
		useCaseOptions = append(
			useCaseOptions,
			app.WithAttractionCache(attractionCache, cfg.Redis.DetailTTL, cfg.Redis.ListTTL),
		)
	}

	useCase := app.NewAttractionUseCase(repo, userClient, useCaseOptions...)

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

func newRedisClient(ctx context.Context, cfg *config.Config) *redis.Client {
	if !cfg.Redis.Enabled || cfg.Redis.Addr == "" {
		log.Info().Msg("attraction cache disabled")
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
		log.Warn().Err(err).Str("addr", cfg.Redis.Addr).Int("db", cfg.Redis.DB).Msg("Redis unavailable, attraction cache disabled")
		return nil
	}

	log.Info().
		Str("addr", cfg.Redis.Addr).
		Int("db", cfg.Redis.DB).
		Dur("detail_ttl", cfg.Redis.DetailTTL).
		Dur("list_ttl", cfg.Redis.ListTTL).
		Msg("attraction Redis cache enabled")
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
