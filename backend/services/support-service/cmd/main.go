package main

import (
	"context"
	"crypto/tls"
	"errors"
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"kz/inflap/backend/pkg/transportauth"
	chatadapter "kz/inflap/backend/services/support-service/internal/adapter/chat"
	httpadapter "kz/inflap/backend/services/support-service/internal/adapter/http"
	notificationadapter "kz/inflap/backend/services/support-service/internal/adapter/notification"
	usercontextadapter "kz/inflap/backend/services/support-service/internal/adapter/usercontext"
	"kz/inflap/backend/services/support-service/internal/app"
	"kz/inflap/backend/services/support-service/internal/config"
)

func main() {
	cfg, err := config.Load()
	if err != nil {
		slog.Error("load config", "error", err)
		os.Exit(1)
	}

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	repo, cleanupRepo, err := newHelpRepository(ctx, cfg)
	if err != nil {
		slog.Error("initialize repository", "error", err)
		os.Exit(1)
	}
	defer cleanupRepo()

	uc := app.NewHelpUseCase(repo, func() time.Time { return time.Now().UTC() })
	if cfg.UserContext.Enabled() {
		userContextHTTPClient, err := newUserContextHTTPClient(cfg.UserContext, cfg.MTLS)
		if err != nil {
			slog.Error("initialize support user-context mTLS transport", "error", err)
			os.Exit(1)
		}
		uc.SetSupportUserSegmentResolver(usercontextadapter.NewResolver(
			cfg.UserContext.UserServiceURL,
			cfg.UserContext.GuideServiceURL,
			cfg.Security.InternalServiceToken,
			cfg.UserContext.Timeout,
			usercontextadapter.WithHTTPClient(userContextHTTPClient),
		))
		go runSegmentRefreshLoop(ctx, cfg.UserContext.SegmentRefreshInterval, func(refreshCtx context.Context) (int, error) {
			return uc.RefreshStaleSupportTicketSegments(refreshCtx, app.RefreshStaleSupportTicketSegmentsInput{Limit: 50})
		})
	}
	if cfg.Chat.Enabled() {
		chatHTTPClient, err := newChatServiceHTTPClient(cfg.Chat, cfg.MTLS)
		if err != nil {
			slog.Error("initialize chat-service mTLS transport", "error", err)
			os.Exit(1)
		}
		uc.SetSupportChatGateway(chatadapter.NewClient(
			cfg.Chat.ServiceURL,
			cfg.Chat.Timeout,
			cfg.Security.InternalServiceToken,
			cfg.Chat.SupportSubject,
			chatadapter.WithHTTPClient(chatHTTPClient),
		))
	}
	if cfg.Notification.Enabled() {
		notificationHTTPClient, err := transportauth.NewHTTPClient(
			cfg.MTLS.ClientConfig(transportauth.ServerNameFromTarget(cfg.Notification.ServiceURL)),
			cfg.Notification.Timeout,
		)
		if err != nil {
			slog.Error("initialize notification-service mTLS transport", "error", err)
			os.Exit(1)
		}
		notificationClient := notificationadapter.New(
			cfg.Notification.ServiceURL,
			cfg.Security.InternalServiceToken,
			cfg.App.Name,
			cfg.Notification.OperatorUserIDs,
			cfg.Notification.Timeout,
			notificationadapter.WithHTTPClient(notificationHTTPClient),
		)
		uc.SetSupportUserNotifier(notificationClient)
		if cfg.Notification.OperatorAlertsEnabled() {
			uc.SetSupportOperatorNotifier(notificationClient)
			go runSLAAlertLoop(ctx, cfg.Notification.SLAAlertInterval, func(alertCtx context.Context) (int, error) {
				return uc.NotifySLABreachedTickets(alertCtx, app.NotifySLABreachedTicketsInput{Limit: 20})
			})
		}
	}
	handler := httpadapter.NewHandler(uc)

	mux := http.NewServeMux()
	handler.Register(mux)

	server := &http.Server{
		Addr:         cfg.HTTP.Address(),
		Handler:      mux,
		ReadTimeout:  cfg.HTTP.ReadTimeout,
		WriteTimeout: cfg.HTTP.WriteTimeout,
		IdleTimeout:  cfg.HTTP.IdleTimeout,
	}

	transportTLSConfig := cfg.MTLS.ServerConfig()
	tlsConfig, err := transportTLSConfig.ServerTLSConfig()
	if err != nil {
		slog.Error("configure support-service mTLS", "error", err)
		os.Exit(1)
	}
	if err := validateSupportServiceMTLSPort(cfg, tlsConfig); err != nil {
		slog.Error("invalid support-service mTLS listener configuration", "error", err)
		os.Exit(1)
	}
	internalMTLSServer := newInternalSupportMTLSServer(cfg, mux, tlsConfig)

	errCh := make(chan error, 2)
	go func() {
		slog.Info("HTTP server started", "service", cfg.App.Name, "port", cfg.HTTP.Port)
		if err := server.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			errCh <- err
			return
		}
		errCh <- nil
	}()
	if internalMTLSServer != nil {
		go func() {
			slog.Info("internal mTLS HTTP server started", "service", cfg.App.Name, "port", cfg.HTTP.InternalTLSPort)
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
		slog.Info("received shutdown signal", "signal", sig.String())
	case err := <-errCh:
		if err != nil {
			slog.Error("http server failed", "error", err)
			os.Exit(1)
		}
	}

	cancel()
	shutdownCtx, shutdownCancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer shutdownCancel()

	slog.Info("shutting down", "service", cfg.App.Name)
	if err := server.Shutdown(shutdownCtx); err != nil {
		slog.Error("http shutdown failed", "error", err)
	}
	if internalMTLSServer != nil {
		if err := internalMTLSServer.Shutdown(shutdownCtx); err != nil {
			slog.Error("internal mTLS HTTP shutdown failed", "error", err)
		}
	}
	slog.Info("service stopped", "service", cfg.App.Name)
}

func newChatServiceHTTPClient(chatCfg config.ChatConfig, mtls transportauth.EnvConfig) (*http.Client, error) {
	client, err := transportauth.NewHTTPClient(
		mtls.ClientConfig(transportauth.ServerNameFromTarget(chatCfg.ServiceURL)),
		chatCfg.Timeout,
	)
	if err != nil {
		return nil, fmt.Errorf("initialize chat-service mTLS transport: %w", err)
	}
	return client, nil
}

func newUserContextHTTPClient(userContextCfg config.UserContextConfig, mtls transportauth.EnvConfig) (*http.Client, error) {
	client, err := transportauth.NewHTTPClient(
		mtls.ClientConfig(""),
		userContextCfg.Timeout,
	)
	if err != nil {
		return nil, fmt.Errorf("initialize support user-context mTLS transport: %w", err)
	}
	return client, nil
}

func validateSupportServiceMTLSPort(cfg config.Config, tlsConfig *tls.Config) error {
	if tlsConfig == nil {
		return nil
	}
	if cfg.HTTP.InternalTLSPort == 0 {
		return fmt.Errorf("INTERNAL_HTTP_TLS_PORT is required when support-service mTLS is enabled")
	}
	if cfg.HTTP.InternalTLSPort == cfg.HTTP.Port {
		return fmt.Errorf("INTERNAL_HTTP_TLS_PORT must be different from SUPPORT_SERVICE_HTTP_PORT")
	}
	return nil
}

func newInternalSupportMTLSServer(cfg config.Config, handler http.Handler, tlsConfig *tls.Config) *http.Server {
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
