package main

import (
	"context"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/rs/zerolog/log"
	"kz/inflap/backend/services/reference-service/data"
	httpadapter "kz/inflap/backend/services/reference-service/internal/adapter/http"
	"kz/inflap/backend/services/reference-service/internal/adapter/repository"
	"kz/inflap/backend/services/reference-service/internal/app"
	"kz/inflap/backend/services/reference-service/internal/config"
)

func main() {
	ctx := context.Background()
	cfg, err := config.Load(ctx)
	if err != nil {
		log.Fatal().Err(err).Msg("load config")
	}

	// Load reference data into memory.
	repo, err := repository.NewMemoryRepository(data.FS)
	if err != nil {
		log.Fatal().Err(err).Msg("failed to load reference data")
	}

	log.Info().Msg("reference data loaded into memory")

	uc := app.NewReferenceUseCase(repo)

	// HTTP server.
	handler := httpadapter.NewHandler(uc)
	mux := http.NewServeMux()
	handler.Register(mux)

	httpServer := &http.Server{
		Addr:         cfg.HTTP.Address(),
		Handler:      httpadapter.RecoverPanic(mux),
		ReadTimeout:  cfg.HTTP.ReadTimeout,
		WriteTimeout: cfg.HTTP.WriteTimeout,
		IdleTimeout:  cfg.HTTP.IdleTimeout,
	}

	errCh := make(chan error, 1)
	go func() {
		log.Info().Str("service", cfg.App.Name).Int("port", cfg.HTTP.Port).Msg("HTTP server started")
		if err := httpServer.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			errCh <- err
			return
		}
		errCh <- nil
	}()

	// Graceful shutdown.
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

	log.Info().Str("service", cfg.App.Name).Msg("service stopped")
}
