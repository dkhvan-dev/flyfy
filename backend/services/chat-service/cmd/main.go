package main

import (
	"context"
	"crypto/tls"
	"fmt"
	"net"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/nats-io/nats.go"
	"github.com/rs/zerolog/log"
	"google.golang.org/grpc"
	"kz/inflap/backend/pkg/switches"
	"kz/inflap/backend/pkg/transportauth"
	"kz/inflap/backend/pkg/trustpolicy/grpcclient"
	grpcadapter "kz/inflap/backend/services/chat-service/internal/adapter/grpc"
	httpadapter "kz/inflap/backend/services/chat-service/internal/adapter/http"
	natsadapter "kz/inflap/backend/services/chat-service/internal/adapter/nats"
	notificationadapter "kz/inflap/backend/services/chat-service/internal/adapter/notification"
	"kz/inflap/backend/services/chat-service/internal/adapter/repository"
	stickeradapter "kz/inflap/backend/services/chat-service/internal/adapter/sticker"
	"kz/inflap/backend/services/chat-service/internal/adapter/ws"
	"kz/inflap/backend/services/chat-service/internal/app"
	"kz/inflap/backend/services/chat-service/internal/config"
	activityv1 "kz/inflap/proto/gen/go/activity/v1"
	userv1 "kz/inflap/proto/gen/go/user/v1"
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
	userConn, err := newUserServiceConn(cfg)
	if err != nil {
		log.Fatal().Err(err).Msg("failed to dial user-service grpc")
	}
	defer userConn.Close()

	userClient := userv1.NewUserServiceClient(userConn)
	actorResolver := grpcadapter.NewUserResolver(userClient)

	// Activity service gRPC client
	activityConn, err := newActivityServiceConn(cfg)
	if err != nil {
		log.Fatal().Err(err).Msg("failed to dial activity-service grpc")
	}
	defer activityConn.Close()

	activityClient := activityv1.NewActivityServiceClient(activityConn)
	activityResolver := grpcadapter.NewActivityLifecycleResolver(activityClient)

	// Repository & use cases
	repo := repository.NewPGChatRepository(pool)
	stickerHTTPClient, err := newStickerServiceHTTPClient(cfg)
	if err != nil {
		log.Fatal().Err(err).Msg("initialize sticker-service mTLS transport")
	}
	stickerResolver := stickeradapter.NewClient(
		cfg.StickerService.HTTPURL,
		cfg.StickerService.EffectiveInternalServiceToken(cfg.Security.InternalServiceToken),
		stickerHTTPClient,
	)
	conversationUC := app.NewConversationUseCase(repo, publisher, actorResolver, activityResolver)
	messageUC := app.NewMessageUseCaseWithStickerResolver(
		repo,
		publisher,
		actorResolver,
		stickerResolver,
		activityResolver,
	)
	notificationHTTPClient, err := transportauth.NewHTTPClient(
		cfg.MTLS.ClientConfig(transportauth.ServerNameFromTarget(cfg.Notification.HTTPURL)),
		cfg.Notification.RequestTimeout,
	)
	if err != nil {
		log.Fatal().Err(err).Msg("initialize notification-service mTLS transport")
	}
	notificationClient := notificationadapter.NewClient(
		cfg.Notification.HTTPURL,
		cfg.Security.InternalServiceToken,
		cfg.App.Name,
		notificationHTTPClient,
	)
	conversationUC.SetNotificationSender(notificationClient)
	messageUC.SetNotificationSender(notificationClient)
	notificationDispatcher := app.NewChatNotificationDispatcher(
		repo,
		notificationClient,
		actorResolver,
		app.ChatNotificationDispatcherConfig{
			BatchSize:      cfg.NotificationOutbox.BatchSize,
			MaxAttempts:    cfg.NotificationOutbox.MaxAttempts,
			BaseRetryDelay: cfg.NotificationOutbox.BaseRetryDelay,
			MaxRetryDelay:  cfg.NotificationOutbox.MaxRetryDelay,
		},
	)
	notificationWorkerCtx, stopNotificationWorker := context.WithCancel(context.Background())
	defer stopNotificationWorker()
	if cfg.NotificationOutbox.Enabled {
		go runChatNotificationOutboxWorker(
			notificationWorkerCtx,
			notificationDispatcher,
			cfg.NotificationOutbox.PollInterval,
			cfg.NotificationOutbox.BatchSize,
		)
	}
	var trustClient *grpcclient.Client
	if cfg.Trust.Enabled {
		trustClient, err = newTrustPolicyClient(cfg)
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
		Handler:      httpadapter.Chain(cfg, withTechBreakMaintenance(httpMux, cfg.Switches, cfg.MTLS, cfg.Security.InternalServiceToken, "CHAT")),
		ReadTimeout:  cfg.HTTP.ReadTimeout,
		WriteTimeout: cfg.HTTP.WriteTimeout,
		IdleTimeout:  cfg.HTTP.IdleTimeout,
	}

	transportTLSConfig := cfg.MTLS.ServerConfig()
	mtlsConfig, err := transportTLSConfig.ServerTLSConfig()
	if err != nil {
		log.Fatal().Err(err).Msg("failed to configure chat-service mTLS")
	}
	if err := validateChatServiceMTLSPort(cfg, mtlsConfig); err != nil {
		log.Fatal().Err(err).Msg("invalid chat-service mTLS listener configuration")
	}
	internalHTTPServer := newInternalChatHTTPMTLSServer(cfg, httpServer.Handler, mtlsConfig)

	// gRPC server (internal service API)
	chatGRPCServer := grpcadapter.NewServer(conversationUC)
	_ = chatGRPCServer // will register with proto-generated service later
	grpcServer := newChatGRPCServer()
	var internalGRPCServer *grpc.Server
	if mtlsConfig != nil {
		mtlsGRPCOptions, err := transportauth.GRPCServerOptions(transportTLSConfig)
		if err != nil {
			log.Fatal().Err(err).Msg("failed to configure chat-service internal mTLS gRPC")
		}
		internalGRPCServer = newChatGRPCServer(mtlsGRPCOptions...)
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

	if internalHTTPServer != nil {
		go func() {
			log.Info().
				Str("service", cfg.App.Name).
				Str("address", cfg.HTTP.InternalTLSAddress()).
				Msg("internal mTLS HTTP server started")
			if err := internalHTTPServer.ListenAndServeTLS("", ""); err != nil && err != http.ErrServerClosed {
				httpErrCh <- err
				return
			}
			httpErrCh <- nil
		}()
	}

	go func() {
		log.Info().Str("service", cfg.App.Name).Int("port", cfg.GRPC.Port).Msg("gRPC server started")
		if err := serveChatGRPCServer(cfg.GRPC.Address(), grpcServer); err != nil {
			grpcErrCh <- err
			return
		}
		grpcErrCh <- nil
	}()

	if internalGRPCServer != nil {
		go func() {
			log.Info().
				Str("service", cfg.App.Name).
				Str("address", cfg.GRPC.InternalTLSAddress()).
				Msg("internal mTLS gRPC server started")
			if err := serveChatGRPCServer(cfg.GRPC.InternalTLSAddress(), internalGRPCServer); err != nil {
				grpcErrCh <- err
				return
			}
			grpcErrCh <- nil
		}()
	}

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
	stopNotificationWorker()

	if err := httpServer.Shutdown(shutdownCtx); err != nil {
		log.Error().Err(err).Msg("http shutdown failed")
	}
	if internalHTTPServer != nil {
		if err := internalHTTPServer.Shutdown(shutdownCtx); err != nil {
			log.Error().Err(err).Msg("internal mTLS http shutdown failed")
		}
	}

	done := make(chan struct{})
	go func() {
		grpcServer.GracefulStop()
		if internalGRPCServer != nil {
			internalGRPCServer.GracefulStop()
		}
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

func newChatGRPCServer(options ...grpc.ServerOption) *grpc.Server {
	return grpc.NewServer(options...)
}

func serveChatGRPCServer(address string, server *grpc.Server) error {
	listener, err := net.Listen("tcp", address)
	if err != nil {
		return fmt.Errorf("listen: %w", err)
	}
	if err := server.Serve(listener); err != nil {
		return fmt.Errorf("serve: %w", err)
	}
	return nil
}

func validateChatServiceMTLSPort(cfg *config.Config, tlsConfig *tls.Config) error {
	if tlsConfig == nil {
		return nil
	}
	if cfg.GRPC.InternalTLSPort == 0 {
		return fmt.Errorf("INTERNAL_GRPC_TLS_PORT is required when chat-service mTLS is enabled")
	}
	if cfg.GRPC.InternalTLSPort == cfg.GRPC.Port {
		return fmt.Errorf("INTERNAL_GRPC_TLS_PORT must be different from GRPC_PORT")
	}
	if cfg.HTTP.InternalTLSPort == 0 {
		return fmt.Errorf("INTERNAL_HTTP_TLS_PORT is required when chat-service mTLS is enabled")
	}
	if cfg.HTTP.InternalTLSPort == cfg.HTTP.Port {
		return fmt.Errorf("INTERNAL_HTTP_TLS_PORT must be different from HTTP_PORT")
	}
	return nil
}

func newInternalChatHTTPMTLSServer(cfg *config.Config, handler http.Handler, tlsConfig *tls.Config) *http.Server {
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

func newStickerServiceHTTPClient(cfg *config.Config) (*http.Client, error) {
	client, err := transportauth.NewHTTPClient(
		cfg.MTLS.ClientConfig(transportauth.ServerNameFromTarget(cfg.StickerService.HTTPURL)),
		cfg.StickerService.Timeout,
	)
	if err != nil {
		return nil, fmt.Errorf("initialize sticker-service mTLS transport: %w", err)
	}
	return client, nil
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

func newTrustPolicyClient(cfg *config.Config) (*grpcclient.Client, error) {
	return grpcclient.NewWithTransportAuth(
		cfg.Trust.Target,
		cfg.Security.InternalServiceToken,
		cfg.App.Name,
		cfg.Trust.Timeout,
		cfg.MTLS.ClientConfig(transportauth.ServerNameFromTarget(cfg.Trust.Target)),
	)
}

func newUserServiceConn(cfg *config.Config) (*grpc.ClientConn, error) {
	grpcOptions, err := transportauth.GRPCDialOptions(
		cfg.MTLS.ClientConfig(transportauth.ServerNameFromTarget(cfg.UserService.GRPCAddress)),
	)
	if err != nil {
		return nil, fmt.Errorf("initialize user-service mTLS transport: %w", err)
	}
	grpcOptions = append(
		grpcOptions,
		grpc.WithUnaryInterceptor(grpcadapter.InternalTokenInterceptor(
			cfg.Security.InternalServiceToken,
			cfg.App.Name,
		)),
	)
	return grpc.NewClient(cfg.UserService.GRPCAddress, grpcOptions...)
}

func newActivityServiceConn(cfg *config.Config) (*grpc.ClientConn, error) {
	grpcOptions, err := transportauth.GRPCDialOptions(
		cfg.MTLS.ClientConfig(transportauth.ServerNameFromTarget(cfg.ActivityService.GRPCAddress)),
	)
	if err != nil {
		return nil, fmt.Errorf("initialize activity-service mTLS transport: %w", err)
	}
	grpcOptions = append(
		grpcOptions,
		grpc.WithUnaryInterceptor(grpcadapter.InternalTokenInterceptor(
			cfg.Security.InternalServiceToken,
			cfg.App.Name,
		)),
	)
	return grpc.NewClient(cfg.ActivityService.GRPCAddress, grpcOptions...)
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

func runChatNotificationOutboxWorker(
	ctx context.Context,
	dispatcher *app.ChatNotificationDispatcher,
	pollInterval time.Duration,
	batchSize int,
) {
	if dispatcher == nil {
		return
	}
	if pollInterval <= 0 {
		pollInterval = 500 * time.Millisecond
	}
	if batchSize <= 0 {
		batchSize = 100
	}

	ticker := time.NewTicker(pollInterval)
	defer ticker.Stop()

	for {
		processed, err := dispatcher.DispatchDue(ctx, time.Now().UTC(), batchSize)
		if err != nil && ctx.Err() == nil {
			log.Error().Err(err).Msg("chat notification outbox dispatch failed")
		}
		if processed == batchSize {
			continue
		}

		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
		}
	}
}
