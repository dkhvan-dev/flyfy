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
	applicationHandler := httpadapter.RecoverPanic(mux)

	httpServer := &http.Server{
		Addr:         cfg.HTTP.Address(),
		Handler:      applicationHandler,
		ReadTimeout:  cfg.HTTP.ReadTimeout,
		WriteTimeout: cfg.HTTP.WriteTimeout,
		IdleTimeout:  cfg.HTTP.IdleTimeout,
	}
	transportTLSConfig := cfg.MTLS.ServerConfig()
	tlsConfig, err := transportTLSConfig.ServerTLSConfig()
	if err != nil {
		log.Fatal().Err(err).Msg("configure reference-service mTLS")
	}
	if err := validateReferenceServiceMTLSPort(*cfg, tlsConfig); err != nil {
		log.Fatal().Err(err).Msg("invalid reference-service mTLS listener configuration")
	}
	internalMTLSServer := newInternalReferenceMTLSServer(*cfg, applicationHandler, tlsConfig)

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
	if internalMTLSServer != nil {
		if err := internalMTLSServer.Shutdown(shutdownCtx); err != nil {
			log.Error().Err(err).Msg("internal mTLS http shutdown failed")
		}
	}

	log.Info().Str("service", cfg.App.Name).Msg("service stopped")
}

func validateReferenceServiceMTLSPort(cfg config.Config, tlsConfig *tls.Config) error {
	if tlsConfig == nil {
		return nil
	}
	if cfg.HTTP.InternalTLSPort == 0 {
		return fmt.Errorf("INTERNAL_HTTP_TLS_PORT is required when reference-service mTLS is enabled")
	}
	if cfg.HTTP.InternalTLSPort == cfg.HTTP.Port {
		return fmt.Errorf("INTERNAL_HTTP_TLS_PORT must be different from HTTP_PORT")
	}
	return nil
}

func newInternalReferenceMTLSServer(cfg config.Config, handler http.Handler, tlsConfig *tls.Config) *http.Server {
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
