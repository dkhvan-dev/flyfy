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

	"github.com/redis/go-redis/v9"
	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"

	cacheadapter "kz/inflap/backend/services/routing-service/internal/adapter/cache"
	httpadapter "kz/inflap/backend/services/routing-service/internal/adapter/http"
	"kz/inflap/backend/services/routing-service/internal/adapter/osrm"
	"kz/inflap/backend/services/routing-service/internal/adapter/otp"
	"kz/inflap/backend/services/routing-service/internal/adapter/valhalla"
	"kz/inflap/backend/services/routing-service/internal/app"
	"kz/inflap/backend/services/routing-service/internal/config"
	"kz/inflap/backend/services/routing-service/internal/domain/model"
)

func main() {
	ctx := context.Background()
	cfg, err := config.Load(ctx)
	if err != nil {
		log.Fatal().Err(err).Msg("load config")
	}
	setupLogger(cfg.Log.Level)

	deps := app.Dependencies{
		DataStatus: model.RoutingDataStatus{
			Region:              cfg.Data.Region,
			OSMSource:           cfg.Data.OSMSource,
			OSMDataVersion:      cfg.Data.OSMDataVersion,
			TransitEnabled:      cfg.Data.TransitEnabled,
			TransitCityCode:     cfg.Data.TransitCityCode,
			GTFSVersion:         cfg.Data.GTFSVersion,
			GeneratedAt:         cfg.Data.GeneratedAt,
			AttributionRequired: cfg.Data.AttributionRequired,
		},
	}
	if strings.TrimSpace(cfg.Engines.ValhallaURL) != "" {
		client, err := valhalla.New(cfg.Engines.ValhallaURL, cfg.Engines.Timeout)
		if err != nil {
			log.Fatal().Err(err).Msg("configure valhalla adapter")
		}
		deps.Valhalla = client
	}
	if cfg.Engines.EnableOSRM && strings.TrimSpace(cfg.Engines.OSRMURL) != "" {
		client, err := osrm.New(cfg.Engines.OSRMURL, cfg.Engines.Timeout)
		if err != nil {
			log.Fatal().Err(err).Msg("configure osrm adapter")
		}
		deps.OSRM = client
	}
	if cfg.TransitRuntimeEnabled() {
		deps.OTP = otp.New(cfg.Engines.OTPURL)
	} else if cfg.Data.TransitEnabled {
		log.Warn().
			Str("city_code", cfg.Data.TransitCityCode).
			Str("gtfs_version", cfg.Data.GTFSVersion).
			Bool("otp_enabled", cfg.Engines.EnableOTP).
			Bool("otp_url_configured", strings.TrimSpace(cfg.Engines.OTPURL) != "").
			Msg("transit routing disabled until city GTFS and OTP are fully configured")
	}
	redisClient := newRedisClient(ctx, cfg)
	if redisClient != nil {
		defer redisClient.Close()
		deps.RouteCache = cacheadapter.NewRedisRouteCache(redisClient, cfg.Cache.KeyPrefix, cfg.Cache.TTL)
		deps.RouteCacheTTL = cfg.Cache.TTL
	}

	uc := app.NewRoutingUseCase(deps)
	handler := httpadapter.NewHandler(uc)
	mux := http.NewServeMux()
	handler.Register(mux)
	applicationHandler := httpadapter.RequestObservability(httpadapter.RecoverPanic(mux))

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
		log.Fatal().Err(err).Msg("configure routing-service mTLS")
	}
	if err := validateRoutingServiceMTLSPort(*cfg, tlsConfig); err != nil {
		log.Fatal().Err(err).Msg("invalid routing-service mTLS listener configuration")
	}
	internalMTLSServer := newInternalRoutingMTLSServer(*cfg, applicationHandler, tlsConfig)

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

func validateRoutingServiceMTLSPort(cfg config.Config, tlsConfig *tls.Config) error {
	if tlsConfig == nil {
		return nil
	}
	if cfg.HTTP.InternalTLSPort == 0 {
		return fmt.Errorf("INTERNAL_HTTP_TLS_PORT is required when routing-service mTLS is enabled")
	}
	if cfg.HTTP.InternalTLSPort == cfg.HTTP.Port {
		return fmt.Errorf("INTERNAL_HTTP_TLS_PORT must be different from HTTP_PORT")
	}
	return nil
}

func newInternalRoutingMTLSServer(cfg config.Config, handler http.Handler, tlsConfig *tls.Config) *http.Server {
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

func setupLogger(level string) {
	parsed, err := zerolog.ParseLevel(strings.TrimSpace(level))
	if err != nil {
		parsed = zerolog.InfoLevel
	}
	zerolog.SetGlobalLevel(parsed)
}

func newRedisClient(ctx context.Context, cfg *config.Config) *redis.Client {
	redisURL := strings.TrimSpace(cfg.Cache.RedisURL)
	if redisURL == "" || cfg.Cache.TTL <= 0 {
		log.Info().Msg("routing cache disabled")
		return nil
	}

	options, err := redis.ParseURL(redisURL)
	if err != nil {
		log.Warn().Err(err).Msg("invalid REDIS_URL, routing cache disabled")
		return nil
	}
	client := redis.NewClient(options)

	pingCtx, cancel := context.WithTimeout(ctx, 2*time.Second)
	defer cancel()
	if err := client.Ping(pingCtx).Err(); err != nil {
		_ = client.Close()
		log.Warn().Err(err).Msg("Redis unavailable, routing cache disabled")
		return nil
	}

	log.Info().
		Str("addr", options.Addr).
		Dur("ttl", cfg.Cache.TTL).
		Msg("routing Redis cache enabled")
	return client
}
