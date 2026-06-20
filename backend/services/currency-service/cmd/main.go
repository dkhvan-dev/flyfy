package main

import (
	"context"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/rs/zerolog/log"
	"kz/inflap/backend/pkg/switches"
	httpadapter "kz/inflap/backend/services/currency-service/internal/adapter/http"
	"kz/inflap/backend/services/currency-service/internal/adapter/provider"
	"kz/inflap/backend/services/currency-service/internal/app"
	"kz/inflap/backend/services/currency-service/internal/config"
)

func main() {
	ctx := context.Background()
	cfg, err := config.Load(ctx)
	if err != nil {
		log.Fatal().Err(err).Msg("load config")
	}

	httpClient := &http.Client{Timeout: cfg.Provider.Timeout}
	primaryProvider := provider.NewExchangeRateAPIProvider(
		cfg.Provider.BaseURL,
		httpClient,
		cfg.Provider.CacheTTL,
	)
	fallbackProvider := app.NewSeedRateProvider(time.Date(2026, 5, 31, 0, 0, 0, 0, time.UTC))
	uc := app.NewConverterUseCase(primaryProvider, fallbackProvider)

	handler := httpadapter.NewHandler(uc)
	mux := http.NewServeMux()
	handler.Register(mux)

	server := &http.Server{
		Addr:         cfg.HTTP.Address(),
		Handler:      withTechBreakMaintenance(mux, cfg.Switches, "", "CURRENCY"),
		ReadTimeout:  cfg.HTTP.ReadTimeout,
		WriteTimeout: cfg.HTTP.WriteTimeout,
		IdleTimeout:  cfg.HTTP.IdleTimeout,
	}

	errCh := make(chan error, 1)
	go func() {
		log.Info().Str("service", cfg.App.Name).Int("port", cfg.HTTP.Port).Msg("HTTP server started")
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
		log.Info().Str("signal", sig.String()).Msg("received shutdown signal")
	case err := <-errCh:
		if err != nil {
			log.Fatal().Err(err).Msg("http server failed")
		}
	}

	shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	log.Info().Str("service", cfg.App.Name).Msg("shutting down")
	if err := server.Shutdown(shutdownCtx); err != nil {
		log.Error().Err(err).Msg("http shutdown failed")
	}
	log.Info().Str("service", cfg.App.Name).Msg("service stopped")
}

func withTechBreakMaintenance(next http.Handler, cfg config.SwitchesServiceConfig, fallbackToken string, domainCode string) http.Handler {
	token := switches.EffectiveInternalServiceToken(cfg.InternalServiceToken, fallbackToken)
	middleware, err := switches.NewMaintenanceMiddleware(
		switches.HTTPClientConfig{
			BaseURL:              cfg.HTTPURL,
			InternalServiceToken: token,
			Timeout:              cfg.RequestTimeout,
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
