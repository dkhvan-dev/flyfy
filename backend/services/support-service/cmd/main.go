package main

import (
	"context"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

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
		uc.SetSupportUserSegmentResolver(usercontextadapter.NewResolver(
			cfg.UserContext.UserServiceURL,
			cfg.UserContext.GuideServiceURL,
			cfg.Security.InternalServiceToken,
			cfg.UserContext.Timeout,
		))
		go runSegmentRefreshLoop(ctx, cfg.UserContext.SegmentRefreshInterval, func(refreshCtx context.Context) (int, error) {
			return uc.RefreshStaleSupportTicketSegments(refreshCtx, app.RefreshStaleSupportTicketSegmentsInput{Limit: 50})
		})
	}
	if cfg.Chat.Enabled() {
		uc.SetSupportChatGateway(chatadapter.NewClient(
			cfg.Chat.ServiceURL,
			cfg.Chat.Timeout,
			cfg.Security.InternalServiceToken,
			cfg.Chat.SupportSubject,
		))
	}
	if cfg.Notification.Enabled() {
		notificationClient := notificationadapter.New(
			cfg.Notification.ServiceURL,
			cfg.Security.InternalServiceToken,
			cfg.App.Name,
			cfg.Notification.OperatorUserIDs,
			cfg.Notification.Timeout,
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

	errCh := make(chan error, 1)
	go func() {
		slog.Info("HTTP server started", "service", cfg.App.Name, "port", cfg.HTTP.Port)
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			errCh <- err
			return
		}
		errCh <- nil
	}()

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
	slog.Info("service stopped", "service", cfg.App.Name)
}
