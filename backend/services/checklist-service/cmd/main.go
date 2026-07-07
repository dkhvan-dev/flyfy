package main

import (
	"context"
	"crypto/tls"
	"errors"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/rs/zerolog/log"
	"kz/inflap/backend/pkg/transportauth"
	"kz/inflap/backend/services/checklist-service/data"
	httpadapter "kz/inflap/backend/services/checklist-service/internal/adapter/http"
	notificationadapter "kz/inflap/backend/services/checklist-service/internal/adapter/notification"
	"kz/inflap/backend/services/checklist-service/internal/adapter/repository"
	"kz/inflap/backend/services/checklist-service/internal/app"
	"kz/inflap/backend/services/checklist-service/internal/config"
)

func main() {
	ctx := context.Background()
	cfg, err := config.Load(ctx)
	if err != nil {
		log.Fatal().Err(err).Msg("load config")
	}

	pool, err := newPostgresPool(ctx, cfg)
	if err != nil {
		log.Fatal().Err(err).Msg("initialize postgres")
	}
	defer pool.Close()

	useCaseOptions := make([]app.ChecklistUseCaseOption, 0, 1)
	if cfg.Notifications.IsSenderConfigured() {
		notificationHTTPClient, err := newNotificationServiceHTTPClient(cfg)
		if err != nil {
			log.Fatal().Err(err).Msg("initialize notification-service mTLS transport")
		}
		sender, err := notificationadapter.NewHTTPSender(notificationadapter.HTTPSenderConfig{
			BaseURL:              cfg.Notifications.ServiceBaseURL,
			InternalServiceToken: cfg.Notifications.InternalServiceToken,
			SourceService:        cfg.App.Name,
			Timeout:              cfg.Notifications.HTTPTimeout,
			HTTPClient:           notificationHTTPClient,
		})
		if err != nil {
			log.Fatal().Err(err).Msg("initialize notification sender")
		}
		useCaseOptions = append(useCaseOptions, app.WithChecklistNotificationSender(sender))
	} else {
		log.Info().Msg("checklist notification sender disabled: notification service URL/token are not configured")
	}

	uc := app.NewChecklistUseCase(
		repository.NewPGChecklistRepository(pool, data.DefaultCatalogSeed()),
		useCaseOptions...,
	)
	dispatchCancel := startChecklistNotificationDispatcher(ctx, uc, cfg.Notifications)
	defer dispatchCancel()

	handler := httpadapter.NewHandler(
		uc,
		httpadapter.WithInternalServiceToken(cfg.Notifications.DispatchServiceToken),
	)
	mux := http.NewServeMux()
	handler.Register(mux)

	httpServer := &http.Server{
		Addr:         cfg.HTTP.Address(),
		Handler:      mux,
		ReadTimeout:  cfg.HTTP.ReadTimeout,
		WriteTimeout: cfg.HTTP.WriteTimeout,
		IdleTimeout:  cfg.HTTP.IdleTimeout,
	}

	transportTLSConfig := cfg.MTLS.ServerConfig()
	tlsConfig, err := transportTLSConfig.ServerTLSConfig()
	if err != nil {
		log.Fatal().Err(err).Msg("configure checklist-service mTLS")
	}
	if err := validateChecklistServiceMTLSPort(cfg, tlsConfig); err != nil {
		log.Fatal().Err(err).Msg("invalid checklist-service mTLS listener configuration")
	}
	internalMTLSServer := newInternalChecklistMTLSServer(cfg, mux, tlsConfig)

	errCh := make(chan error, 2)
	go func() {
		log.Info().Str("service", cfg.App.Name).Int("port", cfg.HTTP.Port).Msg("HTTP server started")
		if err := httpServer.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
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

	log.Info().Str("service", cfg.App.Name).Msg("shutting down")
	if err := httpServer.Shutdown(shutdownCtx); err != nil {
		log.Error().Err(err).Msg("http shutdown failed")
	}
	if internalMTLSServer != nil {
		if err := internalMTLSServer.Shutdown(shutdownCtx); err != nil {
			log.Error().Err(err).Msg("internal mTLS HTTP shutdown failed")
		}
	}
	log.Info().Str("service", cfg.App.Name).Msg("service stopped")
}

func startChecklistNotificationDispatcher(
	parent context.Context,
	uc *app.ChecklistUseCase,
	cfg config.NotificationConfig,
) context.CancelFunc {
	workerCtx, cancel := context.WithCancel(parent)
	if !cfg.DispatchEnabled {
		log.Info().Msg("checklist notification dispatcher disabled by config")
		return cancel
	}
	if !cfg.IsSenderConfigured() {
		return cancel
	}

	interval := cfg.DispatchInterval
	if interval <= 0 {
		interval = time.Hour
	}
	batchSize := cfg.DispatchBatchSize
	if batchSize <= 0 {
		batchSize = 100
	}

	run := func() {
		runCtx, runCancel := context.WithTimeout(workerCtx, 2*time.Minute)
		defer runCancel()

		result, err := uc.DispatchDueChecklistNotifications(runCtx, app.DispatchChecklistNotificationsInput{
			Limit:             batchSize,
			PreferredLanguage: cfg.DispatchDefaultLang,
		})
		if err != nil {
			log.Error().Err(err).Msg("dispatch checklist notifications")
			return
		}
		log.Info().
			Int("scanned", result.Scanned).
			Int("sent", result.Sent).
			Int("skipped", result.Skipped).
			Msg("dispatched checklist notifications")
	}

	go func() {
		run()
		ticker := time.NewTicker(interval)
		defer ticker.Stop()
		for {
			select {
			case <-workerCtx.Done():
				return
			case <-ticker.C:
				run()
			}
		}
	}()

	return cancel
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

func newNotificationServiceHTTPClient(cfg *config.Config) (*http.Client, error) {
	return transportauth.NewHTTPClient(
		cfg.MTLS.ClientConfig(transportauth.ServerNameFromTarget(cfg.Notifications.ServiceBaseURL)),
		cfg.Notifications.HTTPTimeout,
	)
}

func validateChecklistServiceMTLSPort(cfg *config.Config, tlsConfig *tls.Config) error {
	if tlsConfig == nil {
		return nil
	}
	if cfg.HTTP.InternalTLSPort == 0 {
		return fmt.Errorf("INTERNAL_HTTP_TLS_PORT is required when checklist-service mTLS is enabled")
	}
	if cfg.HTTP.InternalTLSPort == cfg.HTTP.Port {
		return fmt.Errorf("INTERNAL_HTTP_TLS_PORT must be different from HTTP_PORT")
	}
	return nil
}

func newInternalChecklistMTLSServer(cfg *config.Config, handler http.Handler, tlsConfig *tls.Config) *http.Server {
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
