package main

import (
	"context"
	"crypto/tls"
	"fmt"
	"net"
	"net/http"
	"os"
	"os/signal"
	"strings"
	"sync"
	"syscall"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/nats-io/nats.go"
	"github.com/rs/zerolog/log"
	"google.golang.org/grpc"
	"kz/inflap/backend/pkg/natstransport"
	"kz/inflap/backend/pkg/serviceauth"
	"kz/inflap/backend/pkg/switches"
	"kz/inflap/backend/pkg/transportauth"
	"kz/inflap/backend/pkg/trustpolicy/grpcclient"
	chatadapter "kz/inflap/backend/services/activity-service/internal/adapter/chat"
	filemanageradapter "kz/inflap/backend/services/activity-service/internal/adapter/filemanager"
	fraudadapter "kz/inflap/backend/services/activity-service/internal/adapter/fraud"
	grpcadapter "kz/inflap/backend/services/activity-service/internal/adapter/grpc"
	httpadapter "kz/inflap/backend/services/activity-service/internal/adapter/http"
	metricsadapter "kz/inflap/backend/services/activity-service/internal/adapter/metrics"
	natsadapter "kz/inflap/backend/services/activity-service/internal/adapter/nats"
	notificationadapter "kz/inflap/backend/services/activity-service/internal/adapter/notification"
	paymentadapter "kz/inflap/backend/services/activity-service/internal/adapter/payment"
	"kz/inflap/backend/services/activity-service/internal/adapter/repository"
	searchindexadapter "kz/inflap/backend/services/activity-service/internal/adapter/searchindex"
	switchesadapter "kz/inflap/backend/services/activity-service/internal/adapter/switches"
	translationadapter "kz/inflap/backend/services/activity-service/internal/adapter/translation"
	"kz/inflap/backend/services/activity-service/internal/app"
	"kz/inflap/backend/services/activity-service/internal/config"
	"kz/inflap/backend/services/activity-service/internal/domain/port"
	activityv1 "kz/inflap/proto/gen/go/activity/v1"
	contentv1 "kz/inflap/proto/gen/go/content/v1"
	userv1 "kz/inflap/proto/gen/go/user/v1"
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

	userConn, err := newUserServiceConn(cfg)
	if err != nil {
		log.Fatal().Err(err).Msg("Failed dial user-service grpc")
	}
	defer userConn.Close()

	userClient := userv1.NewUserServiceClient(userConn)
	actorResolver := grpcadapter.NewUserResolver(userClient)

	fileManagerClient, err := newFileManagerClient(cfg)
	if err != nil {
		log.Fatal().Err(err).Msg("Failed dial file-manager grpc")
	}
	defer fileManagerClient.Close()
	translator, closeTranslationAuth, err := newActivityTranslationClient(cfg)
	if err != nil {
		log.Fatal().Err(err).Msg("Failed initialize translation-service client")
	}
	defer closeTranslationAuth()
	if cfg.Translation.WorkerEnabled && translator == nil {
		log.Fatal().Msg("TRANSLATION_SERVICE_URL is required when activity translation worker is enabled")
	}

	activityUC := app.NewActivityUseCase(repo, fileManagerClient).
		WithAsyncTranslationConfig(cfg.Translation.AsyncEnabled, cfg.Translation.MaxAttempts)
	activityUC.SetUserProfileResolver(actorResolver)
	if cfg.SearchService.Enabled {
		searchIndexOptions, closeSearchIndexAuth := newSearchIndexOptions(cfg)
		defer closeSearchIndexAuth()
		searchIndexer := searchindexadapter.New(
			cfg.SearchService.HTTPURL,
			cfg.Security.InternalServiceToken,
			cfg.SearchService.Timeout,
			searchIndexOptions...,
		)
		activityUC.SetSearchIndexer(searchIndexer)
	}
	var trustClient *grpcclient.Client
	if cfg.Trust.Enabled {
		trustClient, err = newTrustPolicyClient(cfg)
		if err != nil {
			log.Fatal().Err(err).Msg("Failed initialize trust-service client")
		}
		defer trustClient.Close()
		activityUC.SetTrustPolicyClient(trustClient)
	}
	fraudClient, err := newFraudEvaluator(cfg)
	if err != nil {
		log.Fatal().Err(err).Msg("Failed initialize anti-fraud client")
	}
	activityUC.SetFraudEvaluator(fraudClient)
	chatHTTPClient, err := newChatServiceHTTPClient(cfg)
	if err != nil {
		log.Fatal().Err(err).Msg("failed to initialize chat-service mTLS transport")
	}
	chatClient := chatadapter.New(
		cfg.ChatService.HTTPURL,
		cfg.Security.InternalServiceToken,
		cfg.ChatService.RequestTimeout,
		chatadapter.WithHTTPClient(chatHTTPClient),
	)
	activityUC.SetChatGateway(chatClient)
	notificationHTTPClient, err := transportauth.NewHTTPClient(
		cfg.MTLS.ClientConfig(transportauth.ServerNameFromTarget(cfg.Notification.HTTPURL)),
		cfg.Notification.RequestTimeout,
	)
	if err != nil {
		log.Fatal().Err(err).Msg("failed to initialize notification-service mTLS transport")
	}
	notificationClient := notificationadapter.New(
		cfg.Notification.HTTPURL,
		cfg.Security.InternalServiceToken,
		cfg.App.Name,
		cfg.Notification.RequestTimeout,
		notificationadapter.WithHTTPClient(notificationHTTPClient),
	)
	activityUC.SetNotificationGateway(notificationClient)
	paymentClient, err := newPaymentServiceClient(cfg)
	if err != nil {
		log.Fatal().Err(err).Msg("Failed initialize payment-service client")
	}
	activityUC.SetPaymentGateway(paymentClient)
	attendanceUC := app.NewAttendanceUseCase(
		repo,
		cfg.Attendance.QRSigningSecret,
		cfg.Attendance.QRTTL,
		cfg.Attendance.OfflineWindow,
	)
	attendanceUC.SetFraudEvaluator(fraudClient)
	joinUC := app.NewJoinUseCase(repo, chatClient, actorResolver)
	joinUC.SetPaymentGateway(paymentClient)
	joinUC.SetFraudEvaluator(fraudClient)
	joinUC.SetNotificationGateway(notificationClient)
	if switchesClient := newSwitchesClient(cfg); switchesClient != nil {
		joinUC.SetFeatureFlagReader(switchesClient)
		joinUC.SetTechBreakChecker(switchesClient)
	}
	searchUC := app.NewSearchUseCase(repo)
	moderationUC := app.NewModerationUseCase(activityUC)
	savedSourceUC := app.NewSavedSourceUseCase(repo)
	savedSourceAuthorizer, err := newSavedSourceAuthorizer(cfg)
	if err != nil {
		log.Fatal().Err(err).Msg("failed to configure Saved source service authentication")
	}

	httpHandler := httpadapter.NewHandler(
		activityUC,
		attendanceUC,
		joinUC,
		repo,
		fileManagerClient,
		actorResolver,
		cfg.Security.InternalServiceToken,
	)

	httpMux := http.NewServeMux()
	translationMetrics := metricsadapter.NewActivityTranslation()
	httpMux.Handle("GET /metrics", translationMetrics)
	httpHandler.Register(httpMux)

	httpServer := &http.Server{
		Addr:         cfg.HTTP.Address(),
		Handler:      httpadapter.Chain(cfg, withTechBreakMaintenance(withRequestLogging(httpMux), cfg.Switches, cfg.MTLS, cfg.Security.InternalServiceToken, "ACTIVITY")),
		ReadTimeout:  cfg.HTTP.ReadTimeout,
		WriteTimeout: cfg.HTTP.WriteTimeout,
		IdleTimeout:  cfg.HTTP.IdleTimeout,
	}

	activityGRPCServer := grpcadapter.NewServer(
		activityUC,
		joinUC,
		searchUC,
		moderationUC,
		grpcadapter.WithSavedSource(savedSourceUC, savedSourceAuthorizer),
	)
	transportTLSConfig := cfg.MTLS.ServerConfig()
	mtlsConfig, err := transportTLSConfig.ServerTLSConfig()
	if err != nil {
		log.Fatal().Err(err).Msg("failed to configure activity-service mTLS")
	}
	if err := validateActivityServiceMTLSPort(cfg, mtlsConfig); err != nil {
		log.Fatal().Err(err).Msg("invalid activity-service mTLS listener configuration")
	}
	internalHTTPServer := newInternalActivityHTTPMTLSServer(cfg, httpServer.Handler, mtlsConfig)

	grpcServer := newActivityGRPCServer(activityGRPCServer)
	var internalGRPCServer *grpc.Server
	if mtlsConfig != nil {
		mtlsGRPCOptions, err := transportauth.GRPCServerOptions(transportTLSConfig)
		if err != nil {
			log.Fatal().Err(err).Msg("failed to configure activity-service internal mTLS gRPC")
		}
		internalGRPCServer = newActivityGRPCServer(activityGRPCServer, mtlsGRPCOptions...)
	}

	httpErrCh := make(chan error, 2)
	grpcErrCh := make(chan error, 1)
	backgroundCtx, stopBackground := context.WithCancel(context.Background())
	defer stopBackground()
	var backgroundWG sync.WaitGroup

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
		if err := serveActivityGRPCServer(cfg.GRPC.Address(), grpcServer); err != nil {
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
			if err := serveActivityGRPCServer(cfg.GRPC.InternalTLSAddress(), internalGRPCServer); err != nil {
				grpcErrCh <- err
				return
			}
			grpcErrCh <- nil
		}()
	}

	backgroundWG.Add(1)
	go func() {
		defer backgroundWG.Done()
		runActivityLifecycleTicker(backgroundCtx, activityUC)
	}()
	translationWorker := app.NewActivityTranslationWorker(
		app.ActivityTranslationWorkerConfig{
			Enabled:        cfg.Translation.WorkerEnabled,
			WorkerID:       activityTranslationWorkerID(),
			BatchSize:      cfg.Translation.WorkerBatchSize,
			PollInterval:   cfg.Translation.WorkerInterval,
			RequestTimeout: cfg.Translation.RequestTimeout,
			RetryBaseDelay: cfg.Translation.RetryBaseDelay,
			LockTimeout:    cfg.Translation.WorkerLockTimeout,
		},
		repo,
		translator,
		translationMetrics,
	)
	translationWorker.SetAppliedHook(activityUC.SyncActivitySearchDocumentByID)
	if cfg.Translation.WorkerEnabled {
		backgroundWG.Add(1)
		go func() {
			defer backgroundWG.Done()
			if runErr := translationWorker.Run(backgroundCtx); runErr != nil {
				log.Error().Err(runErr).Msg("activity translation worker stopped")
			}
		}()
	}

	var savedLifecycleNATS *nats.Conn
	if cfg.SavedLifecycle.Enabled {
		natsConfig, configErr := cfg.SavedLifecycle.NATSConfig(cfg.App.Env)
		if configErr != nil {
			log.Fatal().Err(configErr).Msg("validate activity Saved lifecycle NATS transport")
		}
		savedLifecycleNATS, err = natstransport.Connect(
			natsConfig,
			cfg.App.Name+"-saved-lifecycle",
			natstransport.Hooks{
				Disconnected: func(disconnectErr error) {
					log.Warn().Err(disconnectErr).Msg("activity Saved lifecycle NATS disconnected")
				},
				Reconnected: func() {
					log.Info().Msg("activity Saved lifecycle NATS reconnected")
				},
				Closed: func(closeErr error) {
					if closeErr == nil {
						log.Info().Msg("activity Saved lifecycle NATS connection closed")
						return
					}
					log.Warn().Err(closeErr).Msg("activity Saved lifecycle NATS connection closed unexpectedly")
				},
				AsyncError: func(asyncErr error) {
					log.Warn().Err(asyncErr).Msg("activity Saved lifecycle NATS asynchronous error")
				},
			},
		)
		if err != nil {
			log.Fatal().Err(err).Msg("configure activity Saved lifecycle NATS connection")
		}
		defer savedLifecycleNATS.Close()
		savedLifecyclePublisher, publisherErr := natsadapter.NewActivitySavedLifecyclePublisher(
			savedLifecycleNATS,
		)
		if publisherErr != nil {
			log.Fatal().Err(publisherErr).Msg("initialize activity Saved lifecycle publisher")
		}
		savedLifecycleWorker := app.NewActivitySavedLifecycleWorker(
			repo,
			savedLifecyclePublisher,
			translationMetrics,
			app.ActivitySavedLifecycleWorkerConfig{
				WorkerID:         activitySavedLifecycleWorkerID(),
				BatchSize:        cfg.SavedLifecycle.WorkerBatchSize,
				PollInterval:     cfg.SavedLifecycle.PollInterval,
				LeaseDuration:    cfg.SavedLifecycle.LeaseDuration,
				PublishTimeout:   cfg.SavedLifecycle.PublishTimeout,
				RetryBaseDelay:   cfg.SavedLifecycle.RetryBaseDelay,
				RetryMaxDelay:    cfg.SavedLifecycle.RetryMaxDelay,
				CleanupInterval:  cfg.SavedLifecycle.CleanupInterval,
				CleanupBatchSize: cfg.SavedLifecycle.CleanupBatchSize,
			},
		)
		backgroundWG.Add(1)
		go func() {
			defer backgroundWG.Done()
			if runErr := savedLifecycleWorker.Run(backgroundCtx); runErr != nil {
				log.Error().Err(runErr).Msg("activity Saved lifecycle worker stopped")
			}
		}()
	}

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
	stopBackground()
	backgroundWG.Wait()
	if savedLifecycleNATS != nil {
		if err := natstransport.Drain(savedLifecycleNATS); err != nil {
			log.Warn().Err(err).Msg("drain activity Saved lifecycle NATS connection")
		}
	}

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

func newActivityGRPCServer(activityServer *grpcadapter.Server, options ...grpc.ServerOption) *grpc.Server {
	grpcServer := grpc.NewServer(options...)
	activityv1.RegisterActivityServiceServer(grpcServer, activityServer)
	contentv1.RegisterSavedSourceServiceServer(grpcServer, activityServer)
	return grpcServer
}

func newSavedSourceAuthorizer(cfg *config.Config) (*serviceauth.JWTVerifier, error) {
	if cfg == nil {
		return nil, fmt.Errorf("activity service config is required")
	}
	if !cfg.Security.ServiceAuthEnabled() {
		if cfg.App.IsProduction() {
			return nil, fmt.Errorf("SERVICE_AUTH_ISSUER and SERVICE_AUTH_JWKS_URL are required in production")
		}
		return nil, nil
	}

	jwksClient, err := transportauth.NewHTTPClient(
		cfg.MTLS.ClientConfig(
			transportauth.ServerNameFromTarget(cfg.Security.ServiceAuthJWKSURL),
		),
		3*time.Second,
	)
	if err != nil {
		return nil, fmt.Errorf("configure service auth JWKS client: %w", err)
	}
	verifier, err := serviceauth.NewJWTVerifier(serviceauth.VerifierConfig{
		Issuer:   cfg.Security.ServiceAuthIssuer,
		JWKSURL:  cfg.Security.ServiceAuthJWKSURL,
		CacheTTL: cfg.Security.ServiceAuthCacheTTL,
		Client:   jwksClient,
	})
	if err != nil {
		return nil, fmt.Errorf("configure service auth verifier: %w", err)
	}
	return verifier, nil
}

func serveActivityGRPCServer(address string, server *grpc.Server) error {
	listener, err := net.Listen("tcp", address)
	if err != nil {
		return fmt.Errorf("listen: %w", err)
	}
	if err := server.Serve(listener); err != nil {
		return fmt.Errorf("serve: %w", err)
	}
	return nil
}

func validateActivityServiceMTLSPort(cfg *config.Config, tlsConfig *tls.Config) error {
	if tlsConfig == nil {
		return nil
	}
	if cfg.GRPC.InternalTLSPort == 0 {
		return fmt.Errorf("INTERNAL_GRPC_TLS_PORT is required when activity-service mTLS is enabled")
	}
	if cfg.GRPC.InternalTLSPort == cfg.GRPC.Port {
		return fmt.Errorf("INTERNAL_GRPC_TLS_PORT must be different from GRPC_PORT")
	}
	if cfg.HTTP.InternalTLSPort == 0 {
		return fmt.Errorf("INTERNAL_HTTP_TLS_PORT is required when activity-service mTLS is enabled")
	}
	if cfg.HTTP.InternalTLSPort == cfg.HTTP.Port {
		return fmt.Errorf("INTERNAL_HTTP_TLS_PORT must be different from HTTP_PORT")
	}
	return nil
}

func newInternalActivityHTTPMTLSServer(cfg *config.Config, handler http.Handler, tlsConfig *tls.Config) *http.Server {
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

func newActivityTranslationClient(
	cfg *config.Config,
) (*translationadapter.Client, func(), error) {
	if strings.TrimSpace(cfg.Translation.BaseURL) == "" {
		return nil, func() {}, nil
	}
	translationHTTPClient, err := transportauth.NewHTTPClient(
		cfg.MTLS.ClientConfig(transportauth.ServerNameFromTarget(cfg.Translation.BaseURL)),
		cfg.Translation.RequestTimeout,
	)
	if err != nil {
		return nil, func() {}, fmt.Errorf("initialize translation-service mTLS transport: %w", err)
	}
	options := []translationadapter.Option{
		translationadapter.WithHTTPClient(translationHTTPClient),
	}
	closeAuth := func() {}
	if cfg.TokenService.Enabled() {
		source, sourceErr := serviceauth.NewGRPCServiceTokenSource(serviceauth.TokenSourceConfig{
			Target:        cfg.TokenService.Target,
			ServiceID:     cfg.TokenService.ServiceID,
			ServiceSecret: cfg.TokenService.ServiceSecret,
			CallTimeout:   cfg.TokenService.CallTimeout,
			TransportAuth: cfg.MTLS.ClientConfig(
				transportauth.ServerNameFromTarget(cfg.TokenService.Target),
			),
		})
		if sourceErr != nil {
			return nil, func() {}, fmt.Errorf("initialize translation service token source: %w", sourceErr)
		}
		options = append(options, translationadapter.WithServiceTokenSource(source))
		closeAuth = func() {
			if closeErr := source.Close(); closeErr != nil {
				log.Warn().Err(closeErr).Msg("close translation service token source")
			}
		}
		log.Info().Str("service_id", cfg.TokenService.ServiceID).Msg("translation service JWT auth enabled")
	} else if cfg.App.IsProduction() {
		return nil, func() {}, fmt.Errorf("TOKEN_SERVICE_SECRET is required for translation-service calls in production")
	} else {
		log.Warn().Msg("translation service JWT auth disabled; using legacy internal token")
	}
	return translationadapter.NewClient(
		cfg.Translation.BaseURL,
		cfg.Translation.RequestTimeout,
		cfg.Security.InternalServiceToken,
		options...,
	), closeAuth, nil
}

func activityTranslationWorkerID() string {
	hostname, err := os.Hostname()
	if err != nil || strings.TrimSpace(hostname) == "" {
		hostname = "unknown-host"
	}
	return fmt.Sprintf("%s:%d", hostname, os.Getpid())
}

func activitySavedLifecycleWorkerID() string {
	hostname, err := os.Hostname()
	if err != nil || strings.TrimSpace(hostname) == "" {
		hostname = "unknown-host"
	}
	return fmt.Sprintf("%s:saved-lifecycle:%d", hostname, os.Getpid())
}

func newSearchIndexOptions(cfg *config.Config) ([]searchindexadapter.Option, func()) {
	searchHTTPClient, err := newSearchIndexHTTPClient(cfg)
	if err != nil {
		log.Fatal().Err(err).Msg("failed to configure search indexing mTLS client")
	}
	options := []searchindexadapter.Option{searchindexadapter.WithHTTPClient(searchHTTPClient)}

	if !cfg.TokenService.Enabled() {
		if cfg.App.IsProduction() {
			log.Fatal().Msg("TOKEN_SERVICE_SECRET is required when search indexing is enabled in production")
		}
		log.Warn().Msg("search indexing service JWT auth disabled; falling back to legacy internal token")
		return options, func() {}
	}
	source, err := serviceauth.NewGRPCServiceTokenSource(serviceauth.TokenSourceConfig{
		Target:        cfg.TokenService.Target,
		ServiceID:     cfg.TokenService.ServiceID,
		ServiceSecret: cfg.TokenService.ServiceSecret,
		CallTimeout:   cfg.TokenService.CallTimeout,
		TransportAuth: cfg.MTLS.ClientConfig(transportauth.ServerNameFromTarget(cfg.TokenService.Target)),
	})
	if err != nil {
		log.Fatal().Err(err).Msg("failed to initialize search indexing service token source")
	}
	log.Info().Str("service_id", cfg.TokenService.ServiceID).Msg("search indexing service JWT auth enabled")
	options = append(options, searchindexadapter.WithServiceTokenSource(source))
	return options, func() {
		if err := source.Close(); err != nil {
			log.Warn().Err(err).Msg("failed to close search indexing service token source")
		}
	}
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

func newFileManagerClient(cfg *config.Config) (*filemanageradapter.Client, error) {
	grpcOptions, err := transportauth.GRPCDialOptions(
		cfg.MTLS.ClientConfig(transportauth.ServerNameFromTarget(cfg.FileManager.Target)),
	)
	if err != nil {
		return nil, fmt.Errorf("initialize file-manager mTLS transport: %w", err)
	}
	grpcOptions = append(
		grpcOptions,
		grpc.WithUnaryInterceptor(grpcadapter.InternalTokenInterceptor(
			cfg.Security.InternalServiceToken,
			cfg.App.Name,
		)),
	)
	return filemanageradapter.New(cfg.FileManager.Target, grpcOptions...)
}

func newSearchIndexHTTPClient(cfg *config.Config) (*http.Client, error) {
	return transportauth.NewHTTPClient(
		cfg.MTLS.ClientConfig(transportauth.ServerNameFromTarget(cfg.SearchService.HTTPURL)),
		cfg.SearchService.Timeout,
	)
}

func newChatServiceHTTPClient(cfg *config.Config) (*http.Client, error) {
	client, err := transportauth.NewHTTPClient(
		cfg.MTLS.ClientConfig(transportauth.ServerNameFromTarget(cfg.ChatService.HTTPURL)),
		cfg.ChatService.RequestTimeout,
	)
	if err != nil {
		return nil, fmt.Errorf("initialize chat-service mTLS transport: %w", err)
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

func newFraudEvaluator(cfg *config.Config) (port.FraudEvaluator, error) {
	if cfg == nil || !cfg.AntiFraud.Enabled {
		return nil, nil
	}
	fraudHTTPClient, err := transportauth.NewHTTPClient(
		cfg.MTLS.ClientConfig(transportauth.ServerNameFromTarget(cfg.AntiFraud.BaseURL)),
		cfg.AntiFraud.Timeout,
	)
	if err != nil {
		return nil, fmt.Errorf("initialize anti-fraud mTLS transport: %w", err)
	}
	return fraudadapter.NewHTTPClient(
		cfg.AntiFraud.BaseURL,
		cfg.AntiFraud.InternalServiceToken,
		cfg.AntiFraud.SignalHashKey,
		cfg.AntiFraud.Timeout,
		fraudadapter.WithHTTPClient(fraudHTTPClient),
	)
}

func newPaymentServiceClient(cfg *config.Config) (*paymentadapter.Client, error) {
	paymentHTTPClient, err := transportauth.NewHTTPClient(
		cfg.MTLS.ClientConfig(transportauth.ServerNameFromTarget(cfg.Payment.HTTPURL)),
		cfg.Payment.RequestTimeout,
	)
	if err != nil {
		return nil, fmt.Errorf("initialize payment-service mTLS transport: %w", err)
	}
	return paymentadapter.New(
		cfg.Payment.HTTPURL,
		cfg.Security.InternalServiceToken,
		cfg.Payment.RequestTimeout,
		paymentadapter.WithHTTPClient(paymentHTTPClient),
	)
}

func newSwitchesClient(cfg *config.Config) *switchesadapter.Client {
	if cfg == nil || !cfg.Switches.Enabled() {
		log.Warn().Msg("switches-service client is disabled; activity feature flags and tech breaks are not enforced")
		return nil
	}
	switchesHTTPClient, err := transportauth.NewHTTPClient(
		cfg.MTLS.ClientConfig(transportauth.ServerNameFromTarget(cfg.Switches.HTTPURL)),
		cfg.Switches.RequestTimeout,
	)
	if err != nil {
		log.Error().Err(err).Msg("failed to configure switches-service mTLS client")
		return nil
	}
	client, err := switchesadapter.New(
		cfg.Switches,
		switchesadapter.WithHTTPClient(switchesHTTPClient),
	)
	if err != nil {
		log.Error().Err(err).Msg("failed to create switches-service client")
		return nil
	}
	log.Info().
		Str("base_url", cfg.Switches.HTTPURL).
		Dur("timeout", cfg.Switches.RequestTimeout).
		Msg("switches-service client initialized")
	return client
}

func runActivityLifecycleTicker(ctx context.Context, activityUC *app.ActivityUseCase) {
	ticker := time.NewTicker(time.Minute)
	defer ticker.Stop()

	runTick := func() {
		tickCtx, cancel := context.WithTimeout(ctx, 20*time.Second)
		defer cancel()

		finalizationStats, err := activityUC.AutoFinalizeRegistrationDueActivities(tickCtx, 100)
		if err != nil {
			log.Error().Err(err).Msg("finalize activity registration deadlines")
			return
		}
		if finalizationStats.Finalized > 0 {
			log.Info().
				Int("finalized", finalizationStats.Finalized).
				Int("confirmed", finalizationStats.Confirmed).
				Int("cancelled", finalizationStats.Cancelled).
				Msg("activity registrations finalized by lifecycle ticker")
		}

		startedCount, err := activityUC.AutoStartDueActivities(tickCtx, 100)
		if err != nil {
			log.Error().Err(err).Msg("auto-start due activities")
			return
		}
		if startedCount > 0 {
			log.Info().
				Int("count", startedCount).
				Msg("activities auto-started by lifecycle ticker")
		}

		completedCount, err := activityUC.AutoCompleteDueActivities(tickCtx, 100)
		if err != nil {
			log.Error().Err(err).Msg("auto-complete due activities")
			return
		}
		if completedCount > 0 {
			log.Info().
				Int("count", completedCount).
				Msg("activities auto-completed by lifecycle ticker")
		}
	}

	runTick()

	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			runTick()
		}
	}
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
