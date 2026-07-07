package main

import (
	"context"
	"crypto/tls"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/redis/go-redis/v9"
	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"

	"kz/inflap/backend/pkg/serviceauth"
	"kz/inflap/backend/pkg/transportauth"
	cacheadapter "kz/inflap/backend/services/search-service/internal/adapter/cache"
	httpadapter "kz/inflap/backend/services/search-service/internal/adapter/http"
	"kz/inflap/backend/services/search-service/internal/adapter/repository"
	"kz/inflap/backend/services/search-service/internal/app"
	"kz/inflap/backend/services/search-service/internal/config"
)

func main() {
	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	cfg, err := config.Load(ctx)
	if err != nil {
		log.Fatal().Err(err).Msg("failed to load config")
	}
	setupLogger(cfg)

	if cfg.Database.DSN == "" {
		log.Fatal().Msg("DATABASE_DSN is required")
	}

	pool, err := pgxpool.New(ctx, cfg.Database.DSN)
	if err != nil {
		log.Fatal().Err(err).Msg("failed to connect database")
	}
	defer pool.Close()

	repo := repository.NewPGSearchRepository(pool)
	searchUseCaseOptions := []app.SearchUseCaseOption{}
	redisClient := newRedisClient(ctx, cfg)
	if redisClient != nil {
		defer redisClient.Close()
		searchCache := cacheadapter.NewRedisSearchCache(redisClient, cfg.Redis.KeyPrefix)
		searchUseCaseOptions = append(searchUseCaseOptions, app.WithSearchCache(searchCache, cfg.Redis.TTL))
	}

	searchUC := app.NewSearchUseCase(repo, searchUseCaseOptions...)
	indexUC := app.NewIndexingUseCase(repo)
	eventUC := app.NewSearchEventUseCase(repo)
	documentUC := app.NewDocumentEventUseCase(repo, indexUC)
	handlerOptions := []httpadapter.Option{
		httpadapter.WithIndexing(indexUC),
		httpadapter.WithEvents(eventUC),
		httpadapter.WithDocumentEvents(documentUC),
		httpadapter.WithInternalToken(cfg.Security.InternalServiceToken),
	}
	if cfg.Security.ServiceAuthEnabled() {
		jwksClient, err := newServiceAuthJWKSHTTPClient(cfg)
		if err != nil {
			log.Fatal().Err(err).Msg("failed to configure service auth JWKS mTLS client")
		}
		verifier, err := serviceauth.NewJWTVerifier(serviceauth.VerifierConfig{
			Issuer:   cfg.Security.ServiceAuthIssuer,
			JWKSURL:  cfg.Security.ServiceAuthJWKSURL,
			CacheTTL: cfg.Security.ServiceAuthCacheTTL,
			Client:   jwksClient,
		})
		if err != nil {
			log.Fatal().Err(err).Msg("failed to configure service auth verifier")
		}
		handlerOptions = append(handlerOptions, httpadapter.WithServiceAuthorizer(verifier))
		log.Info().
			Str("issuer", cfg.Security.ServiceAuthIssuer).
			Str("jwks_url", cfg.Security.ServiceAuthJWKSURL).
			Dur("cache_ttl", cfg.Security.ServiceAuthCacheTTL).
			Msg("service JWT auth enabled for internal endpoints")
	} else if cfg.App.IsProduction() {
		log.Fatal().Msg("SERVICE_AUTH_ISSUER and SERVICE_AUTH_JWKS_URL are required in production")
	}
	handler := httpadapter.NewHandler(searchUC, handlerOptions...)

	mux := http.NewServeMux()
	handler.Register(mux)

	transportTLSConfig := cfg.MTLS.ServerConfig()
	tlsConfig, err := transportTLSConfig.ServerTLSConfig()
	if err != nil {
		log.Fatal().Err(err).Msg("failed to configure search-service mTLS")
	}
	plainServer := &http.Server{
		Addr:         cfg.HTTP.Address(),
		Handler:      mux,
		ReadTimeout:  cfg.HTTP.ReadTimeout,
		WriteTimeout: cfg.HTTP.WriteTimeout,
		IdleTimeout:  cfg.HTTP.IdleTimeout,
	}
	if tlsConfig != nil && cfg.HTTP.InternalTLSPort == 0 {
		log.Fatal().Msg("INTERNAL_HTTP_TLS_PORT is required when search-service mTLS is enabled")
	}
	internalMTLSServer := newInternalMTLSServer(cfg, mux, tlsConfig)

	go func() {
		log.Info().Str("address", cfg.HTTP.Address()).Msg("search-service plaintext HTTP started")
		if err := plainServer.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatal().Err(err).Msg("search-service plaintext HTTP failed")
		}
	}()

	if internalMTLSServer != nil {
		go func() {
			log.Info().
				Str("address", cfg.HTTP.InternalTLSAddress()).
				Str("mode", cfg.MTLS.Mode).
				Msg("search-service internal mTLS HTTP started")
			if err := internalMTLSServer.ListenAndServeTLS("", ""); err != nil && err != http.ErrServerClosed {
				log.Fatal().Err(err).Msg("search-service internal mTLS HTTP failed")
			}
		}()
	}

	if cfg.DocumentEvents.WorkerEnabled {
		go runDocumentEventWorker(ctx, documentUC, cfg)
		log.Info().Msg("search document event worker started")
	}

	<-ctx.Done()
	shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	_ = plainServer.Shutdown(shutdownCtx)
	if internalMTLSServer != nil {
		if err := internalMTLSServer.Shutdown(shutdownCtx); err != nil {
			log.Warn().Err(err).Msg("search-service internal mTLS HTTP shutdown failed")
		}
	}
}

func newInternalMTLSServer(cfg *config.Config, handler http.Handler, tlsConfig *tls.Config) *http.Server {
	if cfg.HTTP.InternalTLSPort == 0 || tlsConfig == nil {
		return nil
	}
	return &http.Server{
		Addr:         cfg.HTTP.InternalTLSAddress(),
		Handler:      handler,
		ReadTimeout:  cfg.HTTP.ReadTimeout,
		WriteTimeout: cfg.HTTP.WriteTimeout,
		IdleTimeout:  cfg.HTTP.IdleTimeout,
		TLSConfig:    tlsConfig,
	}
}

func newServiceAuthJWKSHTTPClient(cfg *config.Config) (*http.Client, error) {
	return transportauth.NewHTTPClient(
		cfg.MTLS.ClientConfig(transportauth.ServerNameFromTarget(cfg.Security.ServiceAuthJWKSURL)),
		3*time.Second,
	)
}

func runDocumentEventWorker(ctx context.Context, documentUC *app.DocumentEventUseCase, cfg *config.Config) {
	ticker := time.NewTicker(cfg.DocumentEvents.WorkerPollInterval)
	defer ticker.Stop()

	process := func() {
		stats, err := documentUC.ProcessDueDocumentEvents(ctx, app.ProcessDocumentEventOptions{
			BatchSize:   cfg.DocumentEvents.WorkerBatchSize,
			MaxAttempts: cfg.DocumentEvents.WorkerMaxAttempts,
			BaseBackoff: cfg.DocumentEvents.WorkerBaseBackoff,
		})
		if err != nil {
			log.Warn().Err(err).Msg("failed to process search document events")
			return
		}
		if stats.Scanned > 0 {
			log.Info().
				Str("metric", "search_document_events_processed").
				Int("scanned", stats.Scanned).
				Int("delivered", stats.Delivered).
				Int("retry_scheduled", stats.RetryScheduled).
				Int("dead", stats.Dead).
				Int("search_index_failed_events_total", stats.FailedEventsTotal).
				Float64("search_index_lag_seconds", stats.MaxIndexLagSeconds).
				Msg("processed search document events")
		}
	}

	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			process()
		}
	}
}

func newRedisClient(ctx context.Context, cfg *config.Config) *redis.Client {
	if !cfg.Redis.Enabled || cfg.Redis.Addr == "" {
		log.Info().Msg("search cache disabled")
		return nil
	}

	client := redis.NewClient(&redis.Options{
		Addr:     cfg.Redis.Addr,
		Password: cfg.Redis.Password,
		DB:       cfg.Redis.DB,
	})

	pingCtx, cancel := context.WithTimeout(ctx, 2*time.Second)
	defer cancel()
	if err := client.Ping(pingCtx).Err(); err != nil {
		_ = client.Close()
		log.Warn().Err(err).Str("addr", cfg.Redis.Addr).Int("db", cfg.Redis.DB).Msg("Redis unavailable, search cache disabled")
		return nil
	}

	log.Info().
		Str("addr", cfg.Redis.Addr).
		Int("db", cfg.Redis.DB).
		Dur("ttl", cfg.Redis.TTL).
		Msg("search Redis cache enabled")
	return client
}

func setupLogger(cfg *config.Config) {
	level, err := zerolog.ParseLevel(cfg.Log.Level)
	if err != nil {
		level = zerolog.InfoLevel
	}
	zerolog.SetGlobalLevel(level)
	if !cfg.App.IsProduction() {
		log.Logger = log.Output(zerolog.ConsoleWriter{Out: os.Stderr})
	}
}
