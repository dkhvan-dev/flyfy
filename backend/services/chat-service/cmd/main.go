package main

import (
	"context"
	"net"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/dkhvan-dev/flyfy/backend/pkg/trustpolicy/grpcclient"
	grpcadapter "github.com/dkhvan-dev/flyfy/backend/services/chat-service/internal/adapter/grpc"
	httpadapter "github.com/dkhvan-dev/flyfy/backend/services/chat-service/internal/adapter/http"
	natsadapter "github.com/dkhvan-dev/flyfy/backend/services/chat-service/internal/adapter/nats"
	"github.com/dkhvan-dev/flyfy/backend/services/chat-service/internal/adapter/repository"
	stickeradapter "github.com/dkhvan-dev/flyfy/backend/services/chat-service/internal/adapter/sticker"
	"github.com/dkhvan-dev/flyfy/backend/services/chat-service/internal/adapter/ws"
	"github.com/dkhvan-dev/flyfy/backend/services/chat-service/internal/app"
	"github.com/dkhvan-dev/flyfy/backend/services/chat-service/internal/config"
	activityv1 "github.com/dkhvan-dev/flyfy/proto/gen/go/activity/v1"
	userv1 "github.com/dkhvan-dev/flyfy/proto/gen/go/user/v1"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/nats-io/nats.go"
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

	// PostgreSQL
	pool, err := newPostgresPool(ctx, cfg)
	if err != nil {
		log.Fatal().Err(err).Msg("failed to initialize postgres pool")
	}
	defer pool.Close()

	// NATS
	nc, err := nats.Connect(cfg.NATS.URL)
	if err != nil {
		log.Fatal().Err(err).Msg("failed to connect to NATS")
	}
	defer nc.Close()

	publisher, err := natsadapter.NewPublisher(nc)
	if err != nil {
		log.Fatal().Err(err).Msg("failed to create NATS publisher")
	}
	defer publisher.Close()

	// User service gRPC client
	userConn, err := grpc.NewClient(
		cfg.UserService.GRPCAddress,
		grpc.WithTransportCredentials(insecure.NewCredentials()),
		grpc.WithUnaryInterceptor(grpcadapter.InternalTokenInterceptor(
			cfg.Security.InternalServiceToken,
			cfg.App.Name,
		)),
	)
	if err != nil {
		log.Fatal().Err(err).Msg("failed to dial user-service grpc")
	}
	defer userConn.Close()

	userClient := userv1.NewUserServiceClient(userConn)
	actorResolver := grpcadapter.NewUserResolver(userClient)

	// Activity service gRPC client
	activityConn, err := grpc.NewClient(
		cfg.ActivityService.GRPCAddress,
		grpc.WithTransportCredentials(insecure.NewCredentials()),
		grpc.WithUnaryInterceptor(grpcadapter.InternalTokenInterceptor(
			cfg.Security.InternalServiceToken,
			cfg.App.Name,
		)),
	)
	if err != nil {
		log.Fatal().Err(err).Msg("failed to dial activity-service grpc")
	}
	defer activityConn.Close()

	activityClient := activityv1.NewActivityServiceClient(activityConn)
	activityResolver := grpcadapter.NewActivityLifecycleResolver(activityClient)

	// Repository & use cases
	repo := repository.NewPGChatRepository(pool)
	stickerResolver := stickeradapter.NewClient(
		cfg.StickerService.HTTPURL,
		cfg.StickerService.EffectiveInternalServiceToken(cfg.Security.InternalServiceToken),
		&http.Client{Timeout: cfg.StickerService.Timeout},
	)
	conversationUC := app.NewConversationUseCase(repo, publisher, actorResolver, activityResolver)
	messageUC := app.NewMessageUseCaseWithStickerResolver(
		repo,
		publisher,
		actorResolver,
		stickerResolver,
		activityResolver,
	)
	var trustClient *grpcclient.Client
	if cfg.Trust.Enabled {
		trustClient, err = grpcclient.New(
			cfg.Trust.Target,
			cfg.Security.InternalServiceToken,
			cfg.App.Name,
			cfg.Trust.Timeout,
		)
		if err != nil {
			log.Fatal().Err(err).Msg("failed to initialize trust-service client")
		}
		defer trustClient.Close()
		messageUC.SetTrustPolicyClient(trustClient)
	}

	// WebSocket hub
	hub := ws.NewHub()
	wsHandler := ws.NewWSHandler(hub, repo, messageUC)

	// NATS consumer -> Hub
	instanceID := uuid.NewString()[:8]
	consumer, err := natsadapter.NewConsumer(nc, instanceID, hub.HandleEvent)
	if err != nil {
		log.Fatal().Err(err).Msg("failed to create NATS consumer")
	}
	defer consumer.Stop()

	// HTTP handler
	httpHandler := httpadapter.NewHandler(conversationUC, messageUC, wsHandler, actorResolver)
	httpMux := http.NewServeMux()
	httpHandler.Register(httpMux)

	httpServer := &http.Server{
		Addr:         cfg.HTTP.Address(),
		Handler:      httpadapter.Chain(cfg, httpMux),
		ReadTimeout:  cfg.HTTP.ReadTimeout,
		WriteTimeout: cfg.HTTP.WriteTimeout,
		IdleTimeout:  cfg.HTTP.IdleTimeout,
	}

	// gRPC server (internal service API)
	grpcServer := grpc.NewServer()
	chatGRPCServer := grpcadapter.NewServer(conversationUC)
	_ = chatGRPCServer // will register with proto-generated service later

	grpcLis, err := net.Listen("tcp", cfg.GRPC.Address())
	if err != nil {
		log.Fatal().Err(err).Msg("failed to listen grpc")
	}

	// Start servers
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

	// Graceful shutdown
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
