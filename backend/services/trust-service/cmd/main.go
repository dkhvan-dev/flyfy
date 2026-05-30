package main

import (
	"context"
	"net"
	"os"
	"os/signal"
	"syscall"
	"time"

	grpcadapter "github.com/dkhvan-dev/flyfy/backend/services/trust-service/internal/adapter/grpc"
	"github.com/dkhvan-dev/flyfy/backend/services/trust-service/internal/adapter/repository"
	"github.com/dkhvan-dev/flyfy/backend/services/trust-service/internal/app"
	"github.com/dkhvan-dev/flyfy/backend/services/trust-service/internal/config"
	trustv1 "github.com/dkhvan-dev/flyfy/proto/gen/go/trust/v1"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"
	"google.golang.org/grpc"
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
		Msg("starting trust-service")

	pool, err := newPostgresPool(ctx, cfg)
	if err != nil {
		log.Fatal().Err(err).Msg("failed to initialize postgres pool")
	}
	defer pool.Close()

	trustRepo := repository.NewPGTrustRepository(pool)
	policyUseCase := app.NewPolicyUseCase(trustRepo)
	trustServer := grpcadapter.NewServer(policyUseCase)

	listener, err := net.Listen("tcp", cfg.GRPC.Address())
	if err != nil {
		log.Fatal().Err(err).Str("address", cfg.GRPC.Address()).Msg("failed to listen grpc")
	}

	grpcServer := grpc.NewServer(
		grpc.UnaryInterceptor(grpcadapter.UnaryServerInterceptor(cfg)),
	)
	trustv1.RegisterTrustServiceServer(grpcServer, trustServer)

	go func() {
		log.Info().
			Str("address", cfg.GRPC.Address()).
			Msg("grpc server started")

		if err := grpcServer.Serve(listener); err != nil {
			log.Fatal().Err(err).Msg("grpc server failed")
		}
	}()

	<-ctx.Done()
	log.Info().Msg("shutdown signal received")
	grpcServer.GracefulStop()
	log.Info().Msg("grpc server stopped")
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

	if err := pool.Ping(pingCtx); err != nil {
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
