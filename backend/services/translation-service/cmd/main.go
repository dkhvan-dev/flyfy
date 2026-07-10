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

	"kz/inflap/backend/pkg/serviceauth"
	"kz/inflap/backend/pkg/transportauth"
	httpadapter "kz/inflap/backend/services/translation-service/internal/adapter/http"
	"kz/inflap/backend/services/translation-service/internal/adapter/provider"
	"kz/inflap/backend/services/translation-service/internal/adapter/repository"
	"kz/inflap/backend/services/translation-service/internal/app"
	"kz/inflap/backend/services/translation-service/internal/config"
	"kz/inflap/backend/services/translation-service/internal/domain/port"
)

func main() {
	ctx := context.Background()
	cfg, err := config.Load(ctx)
	if err != nil {
		log.Fatal().Err(err).Msg("load config")
	}
	setupLogger(cfg.Log.Level)

	pool, err := newPostgresPool(ctx, cfg.Database.URL)
	if err != nil {
		log.Fatal().Err(err).Msg("connect postgres")
	}
	defer pool.Close()

	repo := repository.NewPGTranslationRepository(pool)
	translationProvider, err := newTranslationProvider(*cfg)
	if err != nil {
		log.Fatal().Err(err).Msg("configure translation provider")
	}
	uc := app.NewTranslationUseCase(repo, translationProvider, app.Config{
		Environment:            cfg.App.Env,
		BillingMode:            cfg.Translation.BillingMode,
		MonthlyCharacterLimit:  cfg.Translation.MonthlyCharacterLimit,
		QuotaWarningThreshold:  cfg.Translation.QuotaWarningThreshold,
		QuotaCriticalThreshold: cfg.Translation.QuotaCriticalThreshold,
		GlossaryVersion:        cfg.Translation.GlossaryVersion,
	})

	serviceAuthorizer, err := newServiceAuthorizer(*cfg)
	if err != nil {
		log.Fatal().Err(err).Msg("configure service auth")
	}
	handler := httpadapter.NewHandler(uc, httpadapter.SecurityConfig{
		InternalServiceToken: cfg.Security.InternalServiceToken,
		ServiceAuthorizer:    serviceAuthorizer,
	})
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
		log.Fatal().Err(err).Msg("configure translation-service mTLS")
	}
	if err := validateTranslationServiceMTLSPort(*cfg, tlsConfig); err != nil {
		log.Fatal().Err(err).Msg("invalid translation-service mTLS listener configuration")
	}
	internalMTLSServer := newInternalTranslationMTLSServer(*cfg, mux, tlsConfig)

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
			log.Error().Err(err).Msg("internal mTLS http shutdown failed")
		}
	}
	log.Info().Str("service", cfg.App.Name).Msg("service stopped")
}

func setupLogger(level string) {
	parsed, err := zerolog.ParseLevel(level)
	if err != nil {
		parsed = zerolog.InfoLevel
	}
	zerolog.SetGlobalLevel(parsed)
	log.Logger = log.Output(zerolog.ConsoleWriter{Out: os.Stderr, TimeFormat: time.RFC3339})
}

func newPostgresPool(ctx context.Context, dsn string) (*pgxpool.Pool, error) {
	if dsn == "" {
		return nil, fmt.Errorf("DATABASE_URL is required")
	}
	cfg, err := pgxpool.ParseConfig(dsn)
	if err != nil {
		return nil, fmt.Errorf("parse DATABASE_URL: %w", err)
	}
	pool, err := pgxpool.NewWithConfig(ctx, cfg)
	if err != nil {
		return nil, fmt.Errorf("open postgres pool: %w", err)
	}
	if err := pool.Ping(ctx); err != nil {
		pool.Close()
		return nil, fmt.Errorf("ping postgres: %w", err)
	}
	return pool, nil
}

func newTranslationProvider(cfg config.Config) (port.Provider, error) {
	switch cfg.Provider.Name {
	case "", "azure", "azure_translator":
		if strings.TrimSpace(cfg.Provider.Azure.Key) == "" {
			log.Warn().Msg("azure translator provider disabled because AZURE_TRANSLATOR_KEY is empty")
			return nil, nil
		}
		return provider.NewAzureTranslator(provider.AzureConfig{
			BaseURL: cfg.Provider.Azure.Endpoint,
			Key:     cfg.Provider.Azure.Key,
			Region:  cfg.Provider.Azure.Region,
			Timeout: cfg.Provider.Azure.Timeout,
		}), nil
	default:
		return nil, fmt.Errorf("unsupported TRANSLATION_PROVIDER %q", cfg.Provider.Name)
	}
}

func newServiceAuthorizer(cfg config.Config) (httpadapter.ServiceAuthorizer, error) {
	if !cfg.Security.ServiceAuthEnabled() {
		return nil, nil
	}
	jwksClient, err := newServiceAuthJWKSHTTPClient(cfg)
	if err != nil {
		return nil, fmt.Errorf("configure service auth JWKS HTTP client: %w", err)
	}
	return serviceauth.NewJWTVerifier(serviceauth.VerifierConfig{
		Issuer:   cfg.Security.ServiceAuthIssuer,
		JWKSURL:  cfg.Security.ServiceAuthJWKSURL,
		CacheTTL: cfg.Security.ServiceAuthCacheTTL,
		Client:   jwksClient,
	})
}

func newServiceAuthJWKSHTTPClient(cfg config.Config) (*http.Client, error) {
	if strings.EqualFold(strings.TrimSpace(cfg.MTLS.Mode), string(transportauth.ModeEnforce)) &&
		(strings.TrimSpace(cfg.MTLS.ClientCertPath) == "" || strings.TrimSpace(cfg.MTLS.ClientKeyPath) == "") {
		return nil, fmt.Errorf("MTLS_CLIENT_CERT_PATH and MTLS_CLIENT_KEY_PATH are required for service auth JWKS when mTLS is enforced")
	}
	return transportauth.NewHTTPClient(
		cfg.MTLS.ClientConfig(transportauth.ServerNameFromTarget(cfg.Security.ServiceAuthJWKSURL)),
		3*time.Second,
	)
}

func validateTranslationServiceMTLSPort(cfg config.Config, tlsConfig *tls.Config) error {
	if tlsConfig == nil {
		return nil
	}
	if cfg.HTTP.InternalTLSPort == 0 {
		return fmt.Errorf("INTERNAL_HTTP_TLS_PORT is required when translation-service mTLS is enabled")
	}
	if cfg.HTTP.InternalTLSPort == cfg.HTTP.Port {
		return fmt.Errorf("INTERNAL_HTTP_TLS_PORT must be different from HTTP_PORT")
	}
	return nil
}

func newInternalTranslationMTLSServer(cfg config.Config, handler http.Handler, tlsConfig *tls.Config) *http.Server {
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
