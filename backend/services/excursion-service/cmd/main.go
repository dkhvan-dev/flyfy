package main

import (
	"context"
	"crypto/tls"
	"errors"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"
	"google.golang.org/grpc"
	"kz/inflap/backend/pkg/serviceauth"
	"kz/inflap/backend/pkg/switches"
	"kz/inflap/backend/pkg/transportauth"
	"kz/inflap/backend/pkg/trustpolicy/grpcclient"
	chatadapter "kz/inflap/backend/services/excursion-service/internal/adapter/chat"
	filemanageradapter "kz/inflap/backend/services/excursion-service/internal/adapter/filemanager"
	fraudadapter "kz/inflap/backend/services/excursion-service/internal/adapter/fraud"
	grpcadapter "kz/inflap/backend/services/excursion-service/internal/adapter/grpc"
	guideadapter "kz/inflap/backend/services/excursion-service/internal/adapter/guide"
	httpadapter "kz/inflap/backend/services/excursion-service/internal/adapter/http"
	notificationadapter "kz/inflap/backend/services/excursion-service/internal/adapter/notification"
	paymentadapter "kz/inflap/backend/services/excursion-service/internal/adapter/payment"
	placeadapter "kz/inflap/backend/services/excursion-service/internal/adapter/place"
	"kz/inflap/backend/services/excursion-service/internal/adapter/repository"
	searchindexadapter "kz/inflap/backend/services/excursion-service/internal/adapter/searchindex"
	translationadapter "kz/inflap/backend/services/excursion-service/internal/adapter/translation"
	userserviceadapter "kz/inflap/backend/services/excursion-service/internal/adapter/userservice"
	"kz/inflap/backend/services/excursion-service/internal/app"
	"kz/inflap/backend/services/excursion-service/internal/config"
	"kz/inflap/backend/services/excursion-service/internal/domain/port"
)

func main() {
	ctx := context.Background()
	cfg, err := config.Load(ctx)
	if err != nil {
		log.Fatal().Err(err).Msg("load config")
	}
	configureLogger(cfg)
	validateSecurityConfig(cfg)

	pool, err := newPostgresPool(ctx, cfg)
	if err != nil {
		log.Fatal().Err(err).Msg("initialize postgres")
	}
	defer pool.Close()
	if err = pool.Ping(ctx); err != nil {
		log.Fatal().Err(err).Msg("ping postgres")
	}

	repo := repository.NewPGExcursionRepository(pool)
	guideClient, err := newGuideServiceClient(cfg)
	if err != nil {
		log.Fatal().Err(err).Msg("dial guide-service")
	}
	defer guideClient.Close()

	userClient, err := newUserServiceClient(cfg)
	if err != nil {
		log.Fatal().Err(err).Msg("dial user-service")
	}
	defer userClient.Close()

	fileManagerClient, err := newFileManagerClient(cfg)
	if err != nil {
		log.Fatal().Err(err).Msg("dial file-manager-service")
	}
	defer fileManagerClient.Close()

	translator, err := newTranslationClient(cfg)
	if err != nil {
		log.Fatal().Err(err).Msg("initialize translation-service client")
	}
	placeHTTPClient, err := newPlaceServiceHTTPClient(cfg)
	if err != nil {
		log.Fatal().Err(err).Msg("initialize place-service client")
	}
	placeRatingClient := placeadapter.NewClient(
		cfg.Place.BaseURL,
		cfg.Security.InternalServiceToken,
		placeadapter.WithHTTPClient(placeHTTPClient),
	)
	chatHTTPClient, err := newChatServiceHTTPClient(cfg)
	if err != nil {
		log.Fatal().Err(err).Msg("initialize chat-service client")
	}
	chatClient := chatadapter.New(
		cfg.ChatService.HTTPURL,
		cfg.Security.InternalServiceToken,
		cfg.ChatService.RequestTimeout,
		chatadapter.WithHTTPClient(chatHTTPClient),
	)
	notificationHTTPClient, err := transportauth.NewHTTPClient(
		cfg.MTLS.ClientConfig(transportauth.ServerNameFromTarget(cfg.Notification.HTTPURL)),
		cfg.Notification.RequestTimeout,
	)
	if err != nil {
		log.Fatal().Err(err).Msg("initialize notification-service mTLS transport")
	}
	notificationClient := notificationadapter.New(
		cfg.Notification.HTTPURL,
		cfg.Security.InternalServiceToken,
		cfg.App.Name,
		cfg.Notification.RequestTimeout,
		notificationadapter.WithHTTPClient(notificationHTTPClient),
	)
	paymentClient, err := newPaymentServiceClient(cfg)
	if err != nil {
		log.Fatal().Err(err).Msg("initialize payment-service client")
	}
	fraudClient, err := newFraudEvaluator(cfg)
	if err != nil {
		log.Fatal().Err(err).Msg("initialize anti-fraud client")
	}
	var trustClient *grpcclient.Client
	if cfg.Trust.Enabled {
		trustClient, err = newTrustPolicyClient(cfg)
		if err != nil {
			log.Fatal().Err(err).Msg("initialize trust-service client")
		}
		defer trustClient.Close()
	}
	excursionUC := app.NewExcursionUseCase(repo, guideClient, fileManagerClient, translator).
		WithUserProfileResolver(userClient).
		WithPlaceRatingUpdater(placeRatingClient).
		WithExcursionChatGateway(chatClient).
		WithNotificationGateway(notificationClient).
		WithPaymentGateway(paymentClient).
		WithFraudEvaluator(fraudClient).
		WithTrustPolicyClient(trustClient).
		WithAttendanceQRConfig(
			cfg.Attendance.QRSigningSecret,
			cfg.Attendance.QRTTL,
			cfg.Attendance.OfflineWindow,
		)
	if cfg.SearchService.Enabled {
		searchIndexOptions, closeSearchIndexAuth := newSearchIndexOptions(cfg)
		defer closeSearchIndexAuth()
		searchIndexer := searchindexadapter.New(
			cfg.SearchService.HTTPURL,
			cfg.Security.InternalServiceToken,
			cfg.SearchService.Timeout,
			searchIndexOptions...,
		)
		excursionUC.SetSearchIndexer(searchIndexer)
	}
	handler := httpadapter.NewHandler(excursionUC, fileManagerClient)

	mux := http.NewServeMux()
	handler.Register(mux)
	httpHandler := httpadapter.Chain(cfg, withTechBreakMaintenance(mux, cfg.Switches, cfg.MTLS, cfg.Security.InternalServiceToken, "EXCURSION"))

	server := &http.Server{
		Addr:         cfg.HTTP.Address(),
		Handler:      httpHandler,
		ReadTimeout:  cfg.HTTP.ReadTimeout,
		WriteTimeout: cfg.HTTP.WriteTimeout,
		IdleTimeout:  cfg.HTTP.IdleTimeout,
	}

	transportTLSConfig := cfg.MTLS.ServerConfig()
	tlsConfig, err := transportTLSConfig.ServerTLSConfig()
	if err != nil {
		log.Fatal().Err(err).Msg("configure excursion-service mTLS")
	}
	if err := validateExcursionServiceMTLSPort(cfg, tlsConfig); err != nil {
		log.Fatal().Err(err).Msg("invalid excursion-service mTLS listener configuration")
	}
	internalMTLSServer := newInternalExcursionMTLSServer(cfg, httpHandler, tlsConfig)

	backgroundCtx, stopBackground := context.WithCancel(ctx)
	defer stopBackground()
	go runExcursionLifecycleTicker(backgroundCtx, excursionUC, cfg.Attendance)

	errCh := make(chan error, 2)
	go func() {
		log.Info().Str("service", cfg.App.Name).Int("port", cfg.HTTP.Port).Msg("HTTP server started")
		if err := server.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			errCh <- err
			return
		}
		errCh <- nil
	}()
	if internalMTLSServer != nil {
		go func() {
			log.Info().Str("service", cfg.App.Name).Int("port", cfg.HTTP.InternalTLSPort).Msg("internal mTLS HTTP server started")
			if err := internalMTLSServer.ListenAndServeTLS("", ""); err != nil && !errors.Is(err, http.ErrServerClosed) {
				errCh <- fmt.Errorf("internal mTLS HTTP serve: %w", err)
				return
			}
			errCh <- nil
		}()
	}

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
	if internalMTLSServer != nil {
		if err := internalMTLSServer.Shutdown(shutdownCtx); err != nil {
			log.Error().Err(err).Msg("internal mTLS HTTP shutdown failed")
		}
	}
	log.Info().Str("service", cfg.App.Name).Msg("service stopped")
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

func validateExcursionServiceMTLSPort(cfg *config.Config, tlsConfig *tls.Config) error {
	if tlsConfig == nil {
		return nil
	}
	if cfg.HTTP.InternalTLSPort == 0 {
		return fmt.Errorf("INTERNAL_HTTP_TLS_PORT is required when excursion-service mTLS is enabled")
	}
	if cfg.HTTP.InternalTLSPort == cfg.HTTP.Port {
		return fmt.Errorf("INTERNAL_HTTP_TLS_PORT must be different from HTTP_PORT")
	}
	return nil
}

func newInternalExcursionMTLSServer(cfg *config.Config, handler http.Handler, tlsConfig *tls.Config) *http.Server {
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

func newTranslationClient(cfg *config.Config) (*translationadapter.Client, error) {
	translationHTTPClient, err := transportauth.NewHTTPClient(
		cfg.MTLS.ClientConfig(transportauth.ServerNameFromTarget(cfg.Translation.BaseURL)),
		cfg.Translation.Timeout,
	)
	if err != nil {
		return nil, fmt.Errorf("initialize translation-service mTLS transport: %w", err)
	}
	return translationadapter.NewClient(
		cfg.Translation.BaseURL,
		cfg.Translation.Timeout,
		cfg.Security.InternalServiceToken,
		translationadapter.WithHTTPClient(translationHTTPClient),
	), nil
}

func runExcursionLifecycleTicker(
	ctx context.Context,
	uc *app.ExcursionUseCase,
	attendanceCfg config.AttendanceConfig,
) {
	interval := attendanceCfg.CompletionTickerInterval
	if interval <= 0 {
		interval = time.Minute
	}
	batchSize := attendanceCfg.CompletionBatchSize
	if batchSize <= 0 {
		batchSize = 100
	}

	ticker := time.NewTicker(interval)
	defer ticker.Stop()

	run := func() {
		closedCount, err := uc.AutoCloseBookedExcursionScheduleSlots(ctx, batchSize)
		if err != nil {
			log.Error().Err(err).Msg("auto-close booked excursion schedule slots failed")
			return
		}
		if closedCount > 0 {
			log.Info().Int("closed_slots", closedCount).Msg("auto-closed booked excursion schedule slots")
		}

		count, err := uc.AutoCompleteDueExcursionScheduleSlots(ctx, batchSize)
		if err != nil {
			log.Error().Err(err).Msg("auto-complete due excursion schedule slots failed")
			return
		}
		if count > 0 {
			log.Info().Int("completed_slots", count).Msg("auto-completed due excursion schedule slots")
		}
	}

	run()
	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			run()
		}
	}
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

func newUserServiceClient(cfg *config.Config) (*userserviceadapter.Client, error) {
	grpcOptions, err := transportauth.GRPCDialOptions(
		cfg.MTLS.ClientConfig(transportauth.ServerNameFromTarget(cfg.UserService.Target)),
	)
	if err != nil {
		return nil, fmt.Errorf("initialize user-service mTLS transport: %w", err)
	}
	return userserviceadapter.New(
		cfg.UserService.Target,
		cfg.Security.InternalServiceToken,
		cfg.App.Name,
		grpcOptions...,
	)
}

func newGuideServiceClient(cfg *config.Config) (*guideadapter.Client, error) {
	grpcOptions, err := transportauth.GRPCDialOptions(
		cfg.MTLS.ClientConfig(transportauth.ServerNameFromTarget(cfg.GuideService.Target)),
	)
	if err != nil {
		return nil, fmt.Errorf("initialize guide-service mTLS transport: %w", err)
	}
	grpcOptions = append(
		grpcOptions,
		grpc.WithUnaryInterceptor(grpcadapter.InternalTokenInterceptor(
			cfg.Security.InternalServiceToken,
			cfg.App.Name,
		)),
	)
	return guideadapter.New(cfg.GuideService.Target, grpcOptions...)
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

func newPlaceServiceHTTPClient(cfg *config.Config) (*http.Client, error) {
	client, err := transportauth.NewHTTPClient(
		cfg.MTLS.ClientConfig(transportauth.ServerNameFromTarget(cfg.Place.BaseURL)),
		cfg.Place.Timeout,
	)
	if err != nil {
		return nil, fmt.Errorf("initialize place-service mTLS transport: %w", err)
	}
	return client, nil
}

func configureLogger(cfg *config.Config) {
	level, err := zerolog.ParseLevel(cfg.Log.Level)
	if err != nil {
		level = zerolog.InfoLevel
	}
	zerolog.SetGlobalLevel(level)
	log.Logger = log.Output(zerolog.ConsoleWriter{Out: os.Stderr, TimeFormat: time.RFC3339})
}

func validateSecurityConfig(cfg *config.Config) {
	if strings.EqualFold(cfg.App.Env, "production") &&
		strings.TrimSpace(cfg.Attendance.QRSigningSecret) == "" {
		log.Fatal().
			Str("env", "EXCURSION_ATTENDANCE_QR_SIGNING_SECRET").
			Msg("missing production excursion attendance QR signing secret")
	}
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
