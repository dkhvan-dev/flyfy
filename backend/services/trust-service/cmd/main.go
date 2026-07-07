package main

import (
	"context"
	"crypto/tls"
	"fmt"
	"net"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"
	"google.golang.org/grpc"
	"kz/inflap/backend/pkg/transportauth"
	grpcadapter "kz/inflap/backend/services/trust-service/internal/adapter/grpc"
	"kz/inflap/backend/services/trust-service/internal/adapter/repository"
	"kz/inflap/backend/services/trust-service/internal/app"
	"kz/inflap/backend/services/trust-service/internal/config"
	trustv1 "kz/inflap/proto/gen/go/trust/v1"
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

	transportTLSConfig := cfg.MTLS.ServerConfig()
	mtlsConfig, err := transportTLSConfig.ServerTLSConfig()
	if err != nil {
		log.Fatal().Err(err).Msg("failed to configure trust-service mTLS")
	}
	if err := validateTrustServiceMTLSPort(cfg, mtlsConfig); err != nil {
		log.Fatal().Err(err).Msg("invalid trust-service mTLS listener configuration")
	}

	grpcOptions := []grpc.ServerOption{
		grpc.UnaryInterceptor(grpcadapter.UnaryServerInterceptor(cfg)),
	}
	grpcServer := newTrustGRPCServer(trustServer, grpcOptions...)

	var internalGRPCServer *grpc.Server
	if mtlsConfig != nil {
		mtlsGRPCOptions, err := transportauth.GRPCServerOptions(transportTLSConfig)
		if err != nil {
			log.Fatal().Err(err).Msg("failed to configure trust-service internal mTLS gRPC")
		}
		internalGRPCServer = newTrustGRPCServer(trustServer, append(mtlsGRPCOptions, grpcOptions...)...)
	}

	errCh := make(chan error, 2)
	go func() {
		log.Info().
			Str("address", cfg.GRPC.Address()).
			Msg("grpc server started")

		if err := serveTrustGRPCServer(cfg.GRPC.Address(), grpcServer); err != nil {
			errCh <- fmt.Errorf("grpc server failed: %w", err)
		}
	}()

	if internalGRPCServer != nil {
		go func() {
			log.Info().
				Str("address", cfg.GRPC.InternalTLSAddress()).
				Msg("internal mTLS grpc server started")

			if err := serveTrustGRPCServer(cfg.GRPC.InternalTLSAddress(), internalGRPCServer); err != nil {
				errCh <- fmt.Errorf("internal mTLS grpc server failed: %w", err)
			}
		}()
	}

	var serverErr error
	select {
	case <-ctx.Done():
		log.Info().Msg("shutdown signal received")
	case err := <-errCh:
		serverErr = err
		log.Error().Err(err).Msg("server error")
	}

	grpcServer.GracefulStop()
	if internalGRPCServer != nil {
		internalGRPCServer.GracefulStop()
	}
	log.Info().Msg("grpc server stopped")
	if serverErr != nil {
		os.Exit(1)
	}
}

func newTrustGRPCServer(trustServer trustv1.TrustServiceServer, options ...grpc.ServerOption) *grpc.Server {
	grpcServer := grpc.NewServer(options...)
	trustv1.RegisterTrustServiceServer(grpcServer, trustServer)
	return grpcServer
}

func serveTrustGRPCServer(address string, server *grpc.Server) error {
	listener, err := net.Listen("tcp", address)
	if err != nil {
		return fmt.Errorf("listen: %w", err)
	}
	if err := server.Serve(listener); err != nil {
		return fmt.Errorf("serve: %w", err)
	}
	return nil
}

func validateTrustServiceMTLSPort(cfg *config.Config, tlsConfig *tls.Config) error {
	if tlsConfig == nil {
		return nil
	}
	if cfg.GRPC.InternalTLSPort == 0 {
		return fmt.Errorf("INTERNAL_GRPC_TLS_PORT is required when trust-service mTLS is enabled")
	}
	if cfg.GRPC.InternalTLSPort == cfg.GRPC.Port {
		return fmt.Errorf("INTERNAL_GRPC_TLS_PORT must be different from GRPC_PORT")
	}
	return nil
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
