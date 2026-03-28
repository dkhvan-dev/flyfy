package main

import (
	"context"
	"net"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	filemanageradapter "github.com/dkhvan-dev/flyfy/backend/services/activity-service/internal/adapter/filemanager"
	grpcadapter "github.com/dkhvan-dev/flyfy/backend/services/activity-service/internal/adapter/grpc"
	httpadapter "github.com/dkhvan-dev/flyfy/backend/services/activity-service/internal/adapter/http"
	"github.com/dkhvan-dev/flyfy/backend/services/activity-service/internal/adapter/repository"
	"github.com/dkhvan-dev/flyfy/backend/services/activity-service/internal/app"
	"github.com/dkhvan-dev/flyfy/backend/services/activity-service/internal/config"
	activityv1 "github.com/dkhvan-dev/flyfy/proto/gen/go/activity/v1"
	userv1 "github.com/dkhvan-dev/flyfy/proto/gen/go/user/v1"
	"github.com/jackc/pgx/v5/pgxpool"
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

	pool, err := newPostgresPool(ctx, cfg)
	if err != nil {
		log.Fatal().Err(err).Msg("failed to initialize postgres pool")
	}
	defer pool.Close()

	if err = pool.Ping(ctx); err != nil {
		log.Fatal().Err(err).Msg("Failed ping db")
	}

	repo := repository.NewPGActivityRepository(pool)

	userConn, err := grpc.NewClient(
		cfg.UserService.GRPCAddress,
		grpc.WithTransportCredentials(insecure.NewCredentials()),
		grpc.WithUnaryInterceptor(grpcadapter.InternalTokenInterceptor(
			cfg.Security.InternalServiceToken,
			cfg.App.Name,
		)),
	)
	if err != nil {
		log.Fatal().Err(err).Msg("Failed dial user-service grpc")
	}
	defer userConn.Close()

	userClient := userv1.NewUserServiceClient(userConn)
	actorResolver := grpcadapter.NewUserResolver(userClient)

	fileManagerClient, err := filemanageradapter.New(
		cfg.FileManager.Target,
		grpc.WithTransportCredentials(insecure.NewCredentials()),
		grpc.WithUnaryInterceptor(grpcadapter.InternalTokenInterceptor(
			cfg.Security.InternalServiceToken,
			cfg.App.Name,
		)),
	)
	if err != nil {
		log.Fatal().Err(err).Msg("Failed dial file-manager grpc")
	}
	defer fileManagerClient.Close()

	activityUC := app.NewActivityUseCase(repo, fileManagerClient)
	joinUC := app.NewJoinUseCase(repo)
	searchUC := app.NewSearchUseCase(repo)
	moderationUC := app.NewModerationUseCase(activityUC)

	httpHandler := httpadapter.NewHandler(activityUC, joinUC, repo, fileManagerClient, actorResolver)

	httpMux := http.NewServeMux()
	httpHandler.Register(httpMux)

	httpServer := &http.Server{
		Addr:         cfg.HTTP.Address(),
		Handler:      httpadapter.Chain(cfg, withRequestLogging(httpMux)),
		ReadTimeout:  cfg.HTTP.ReadTimeout,
		WriteTimeout: cfg.HTTP.WriteTimeout,
		IdleTimeout:  cfg.HTTP.IdleTimeout,
	}

	grpcServer := grpc.NewServer()
	activityGRPCServer := grpcadapter.NewServer(
		activityUC,
		joinUC,
		searchUC,
		moderationUC,
	)
	activityv1.RegisterActivityServiceServer(grpcServer, activityGRPCServer)

	grpcLis, err := net.Listen("tcp", cfg.GRPC.Address())
	if err != nil {
		log.Fatal().Err(err).Msg("Failed listen grpc")
	}

	httpErrCh := make(chan error, 1)
	grpcErrCh := make(chan error, 1)

	go func() {
		log.Info().Str("service", cfg.App.Name).Int("port", cfg.HTTP.Port).Msg("HTTP server started")
		if err := httpServer.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			httpErrCh <- err
			return
		}
		httpErrCh <- nil
	}()

	go func() {
		log.Info().Str("service", cfg.App.Name).Int("port", cfg.GRPC.Port).Msg("gRPC server started")
		if err := grpcServer.Serve(grpcLis); err != nil {
			grpcErrCh <- err
			return
		}
		grpcErrCh <- nil
	}()

	stop := make(chan os.Signal, 1)
	signal.Notify(stop, syscall.SIGINT, syscall.SIGTERM)

	select {
	case sig := <-stop:
		log.Info().Str("signal", sig.String()).Msg("received shutdown signal")
	case err := <-httpErrCh:
		if err != nil {
			log.Fatal().Err(err).Msg("http server failed")
		}
	case err := <-grpcErrCh:
		if err != nil {
			log.Fatal().Err(err).Msg("grpc server failed")
		}
	}

	shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	log.Info().Str("service", cfg.App.Name).Msg("shutting down")

	if err := httpServer.Shutdown(shutdownCtx); err != nil {
		log.Error().Err(err).Msg("http shutdown failed")
	}

	done := make(chan struct{})
	go func() {
		grpcServer.GracefulStop()
		close(done)
	}()

	select {
	case <-done:
		log.Info().Msg("grpc server stopped gracefully")
	case <-time.After(10 * time.Second):
		log.Warn().Msg("grpc graceful stop timeout reached, forcing stop")
		grpcServer.Stop()
	}

	log.Info().Str("service", cfg.App.Name).Msg("service stopped")
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
