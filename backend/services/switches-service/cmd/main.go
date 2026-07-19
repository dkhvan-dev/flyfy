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

	"kz/inflap/backend/services/switches-service/internal/config"
	featurehttp "kz/inflap/backend/services/switches-service/internal/featureflag/adapter/http"
	featurerepo "kz/inflap/backend/services/switches-service/internal/featureflag/adapter/repository"
	featureapp "kz/inflap/backend/services/switches-service/internal/featureflag/app"
	policyhttp "kz/inflap/backend/services/switches-service/internal/platformpolicy/adapter/http"
	policyrepo "kz/inflap/backend/services/switches-service/internal/platformpolicy/adapter/repository"
	policyapp "kz/inflap/backend/services/switches-service/internal/platformpolicy/app"
	techhttp "kz/inflap/backend/services/switches-service/internal/techbreak/adapter/http"
	techrepo "kz/inflap/backend/services/switches-service/internal/techbreak/adapter/repository"
	techapp "kz/inflap/backend/services/switches-service/internal/techbreak/app"
)

const cacheInvalidationChannel = "switches_cache_invalidate"

type cacheInvalidator interface {
	ClearCache()
}

func main() {
	rootCtx, rootCancel := context.WithCancel(context.Background())
	defer rootCancel()
	ctx := rootCtx
	cfg, err := config.Load(ctx)
	if err != nil {
		log.Fatal().Err(err).Msg("load config")
	}
	configureLogger(cfg)

	pool, err := newPostgresPool(ctx, cfg)
	if err != nil {
		log.Fatal().Err(err).Msg("initialize postgres")
	}
	defer pool.Close()

	featureRepo := featurerepo.NewPGRepository(pool)
	featureClock := featureapp.NewSystemClock()
	featureService := featureapp.NewFeatureFlagService(
		featureRepo,
		featureRepo,
		featureapp.NewMemoryCacheWithClock[featureapp.FeatureFlagDetailResponse](cfg.Cache.TTL, cfg.Cache.MissTTL, featureClock),
		featureClock,
	)
	featureDomainService := featureapp.NewDomainService(featureRepo)

	techRepo := techrepo.NewPGRepository(pool)
	techClock := techapp.NewSystemClock()
	techBreakService := techapp.NewTechBreakService(
		techRepo,
		techRepo,
		techapp.NewMemoryCacheWithClock[techapp.TechBreakResponse](cfg.Cache.TTL, cfg.Cache.MissTTL, techClock),
		techClock,
	)
	techScopeService := techapp.NewTechBreakScopeService(techRepo, techRepo)
	techDomainService := techapp.NewDomainService(techRepo)
	policyRepo := policyrepo.NewPGRepository(pool)
	policyService := policyapp.NewService(policyRepo, nil)

	mux := http.NewServeMux()
	featurehttp.NewHandler(featureService, featureDomainService, cfg.Security.InternalServiceToken, pool.Ping).Register(mux)
	techhttp.NewHandler(techBreakService, techScopeService, techDomainService, cfg.Security.InternalServiceToken).Register(mux)
	policyhttp.NewHandler(policyService, policyhttp.AuthConfig{
		InternalServiceToken:      cfg.Security.InternalServiceToken,
		TrustedGatewayHeaderRoles: cfg.Security.TrustedGatewayHeaderRoles,
		TrustedGatewayHeaderSub:   cfg.Security.TrustedGatewayHeaderSub,
	}).Register(mux)

	if cfg.Scheduler.Enabled {
		go featureapp.NewScheduler(cfg.Scheduler.Interval, featureService.SwitchDue).Start(rootCtx)
		go techapp.NewScheduler(cfg.Scheduler.Interval, techBreakService.SwitchDue).Start(rootCtx)
	}
	if cfg.Runtime.CacheInvalidationListenerEnabled {
		go runCacheInvalidationListener(rootCtx, pool, featureService, techBreakService)
	}

	middleware := featurehttp.MiddlewareConfig{
		RequestIDHeader:            cfg.Security.RequestIDHeader,
		TrustedGatewayHeaderUserID: cfg.Security.TrustedGatewayHeaderUserID,
		TrustedGatewayHeaderRoles:  cfg.Security.TrustedGatewayHeaderRoles,
		TrustedGatewayHeaderSub:    cfg.Security.TrustedGatewayHeaderSub,
	}
	techMiddleware := techhttp.MiddlewareConfig(middleware)
	handler := featurehttp.Chain(middleware, techhttp.Chain(techMiddleware, mux))
	server := &http.Server{
		Addr:         cfg.HTTP.Address(),
		Handler:      handler,
		ReadTimeout:  cfg.HTTP.ReadTimeout,
		WriteTimeout: cfg.HTTP.WriteTimeout,
		IdleTimeout:  cfg.HTTP.IdleTimeout,
	}

	transportTLSConfig := cfg.MTLS.ServerConfig()
	tlsConfig, err := transportTLSConfig.ServerTLSConfig()
	if err != nil {
		log.Fatal().Err(err).Msg("failed to configure switches-service mTLS")
	}
	if err := validateSwitchesServiceMTLSPort(cfg, tlsConfig); err != nil {
		log.Fatal().Err(err).Msg("invalid switches-service mTLS listener configuration")
	}
	internalMTLSServer := newInternalSwitchesMTLSServer(cfg, handler, tlsConfig)

	errCh := make(chan error, 2)
	go func() {
		log.Info().Str("service", cfg.App.Name).Int("port", cfg.HTTP.Port).Msg("HTTP server started")
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			errCh <- err
			return
		}
		errCh <- nil
	}()
	if internalMTLSServer != nil {
		go func() {
			log.Info().Str("service", cfg.App.Name).Int("port", cfg.HTTP.InternalTLSPort).Msg("internal mTLS HTTP server started")
			if err := internalMTLSServer.ListenAndServeTLS("", ""); err != nil && err != http.ErrServerClosed {
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
		rootCancel()
	case err := <-errCh:
		if err != nil {
			log.Fatal().Err(err).Msg("HTTP server failed")
		}
		rootCancel()
	}

	shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if err := server.Shutdown(shutdownCtx); err != nil {
		log.Error().Err(err).Msg("HTTP shutdown failed")
	}
	if internalMTLSServer != nil {
		if err := internalMTLSServer.Shutdown(shutdownCtx); err != nil {
			log.Error().Err(err).Msg("internal mTLS HTTP shutdown failed")
		}
	}
	log.Info().Str("service", cfg.App.Name).Msg("service stopped")
}

func newInternalSwitchesMTLSServer(cfg *config.Config, handler http.Handler, tlsConfig *tls.Config) *http.Server {
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

func validateSwitchesServiceMTLSPort(cfg *config.Config, tlsConfig *tls.Config) error {
	if tlsConfig == nil {
		return nil
	}
	if cfg.HTTP.InternalTLSPort == 0 {
		return fmt.Errorf("INTERNAL_HTTP_TLS_PORT is required when switches-service mTLS is enabled")
	}
	if cfg.HTTP.InternalTLSPort == cfg.HTTP.Port {
		return fmt.Errorf("INTERNAL_HTTP_TLS_PORT must be different from HTTP_PORT")
	}
	return nil
}

func configureLogger(cfg *config.Config) {
	level, err := zerolog.ParseLevel(cfg.Log.Level)
	if err != nil {
		level = zerolog.InfoLevel
	}
	zerolog.SetGlobalLevel(level)
	if cfg.Log.Pretty || !cfg.App.IsProduction() {
		log.Logger = zerolog.New(zerolog.ConsoleWriter{
			Out:        os.Stdout,
			TimeFormat: time.RFC3339,
		}).With().Timestamp().Logger()
		return
	}
	log.Logger = zerolog.New(os.Stdout).With().Timestamp().Logger()
}

func runCacheInvalidationListener(
	ctx context.Context,
	pool *pgxpool.Pool,
	featureCache cacheInvalidator,
	techBreakCache cacheInvalidator,
) {
	for {
		if err := listenCacheInvalidations(ctx, pool, featureCache, techBreakCache); err != nil {
			if errors.Is(err, context.Canceled) || errors.Is(ctx.Err(), context.Canceled) {
				return
			}
			log.Warn().Err(err).Msg("cache invalidation listener stopped; retrying")
		}
		select {
		case <-ctx.Done():
			return
		case <-time.After(time.Second):
		}
	}
}

func listenCacheInvalidations(
	ctx context.Context,
	pool *pgxpool.Pool,
	featureCache cacheInvalidator,
	techBreakCache cacheInvalidator,
) error {
	conn, err := pool.Acquire(ctx)
	if err != nil {
		return err
	}
	defer conn.Release()
	if _, err = conn.Exec(ctx, "LISTEN "+cacheInvalidationChannel); err != nil {
		return err
	}
	for {
		notification, waitErr := conn.Conn().WaitForNotification(ctx)
		if waitErr != nil {
			return waitErr
		}
		handleCacheInvalidation(notification.Payload, featureCache, techBreakCache)
	}
}

func handleCacheInvalidation(payload string, featureCache cacheInvalidator, techBreakCache cacheInvalidator) {
	switch strings.ToLower(strings.TrimSpace(payload)) {
	case "all":
		featureCache.ClearCache()
		techBreakCache.ClearCache()
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
