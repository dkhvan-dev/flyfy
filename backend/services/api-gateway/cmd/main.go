package main

import (
	"context"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"
	httpadapter "kz/inflap/backend/services/api-gateway/internal/adapter/http"
	tokenserviceadapter "kz/inflap/backend/services/api-gateway/internal/adapter/tokenservice"
	"kz/inflap/backend/services/api-gateway/internal/app"
	"kz/inflap/backend/services/api-gateway/internal/config"
)

func main() {
	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	cfg, err := config.Load(ctx)
	if err != nil {
		panic(err)
	}

	setupLogger(cfg)

	tokenVerifier, err := tokenserviceadapter.New(cfg.TokenService)
	if err != nil {
		log.Fatal().Err(err).Msg("failed to initialize token-service grpc client")
	}
	defer tokenVerifier.Close()

	readiness := httpadapter.NewReadinessHandler(
		map[string]app.ReadinessChecker{
			"token-service":        tokenVerifier,
			"auth-service":         httpadapter.NewHTTPReadinessChecker(cfg.Downstreams.AuthService+"/health", 2*time.Second),
			"user-service":         httpadapter.NewHTTPReadinessChecker(cfg.Downstreams.UserService+"/health", 2*time.Second),
			"guide-service":        httpadapter.NewHTTPReadinessChecker(cfg.Downstreams.GuideService+"/health", 2*time.Second),
			"file-manager-service": httpadapter.NewHTTPReadinessChecker(cfg.Downstreams.FileManagerService+"/health", 2*time.Second),
			"payment-service":      httpadapter.NewHTTPReadinessChecker(cfg.Downstreams.PaymentService+"/health", 2*time.Second),
			"sticker-service":      httpadapter.NewHTTPReadinessChecker(cfg.Downstreams.StickerService+"/health", 2*time.Second),
			"notification-service": httpadapter.NewHTTPReadinessChecker(cfg.Downstreams.NotificationService+"/health", 2*time.Second),
			"admin-panel":          httpadapter.NewHTTPReadinessChecker(cfg.Downstreams.AdminPanelService+"/health", 2*time.Second),
		},
		2*time.Second,
	)

	// Redis response cache for reference data.
	responseCache := httpadapter.NewResponseCache(cfg.Redis)
	defer responseCache.Close()

	if err := responseCache.Ping(ctx); err != nil {
		log.Warn().Err(err).Msg("redis response cache not available, caching disabled")
		responseCache = nil
	} else {
		log.Info().Msg("redis response cache connected")
	}

	proxyHandler, err := httpadapter.NewProxyHandler(cfg, readiness)
	if err != nil {
		log.Fatal().Err(err).Msg("failed to initialize proxy handler")
	}
	defer proxyHandler.Close()

	mux := http.NewServeMux()
	proxyHandler.Register(mux)

	server := &http.Server{
		Addr:         cfg.HTTP.Address(),
		Handler:      httpadapter.Chain(cfg, tokenVerifier, responseCache, mux),
		ReadTimeout:  cfg.HTTP.ReadTimeout,
		WriteTimeout: cfg.HTTP.WriteTimeout,
		IdleTimeout:  cfg.HTTP.IdleTimeout,
	}

	go func() {
		log.Info().
			Str("address", cfg.HTTP.Address()).
			Msg("api-gateway started")

		if err = server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatal().Err(err).Msg("api-gateway failed")
		}
	}()

	<-ctx.Done()
	log.Info().Msg("shutdown signal received")

	shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	if err = server.Shutdown(shutdownCtx); err != nil {
		log.Error().Err(err).Msg("gateway shutdown failed")
	} else {
		log.Info().Msg("gateway stopped")
	}
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
