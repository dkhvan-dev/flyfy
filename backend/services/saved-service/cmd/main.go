package main

import (
	"context"
	"crypto/hmac"
	"crypto/sha256"
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

	httpadapter "kz/inflap/backend/services/saved-service/internal/adapter/http"
	mediaadapter "kz/inflap/backend/services/saved-service/internal/adapter/media"
	metricsadapter "kz/inflap/backend/services/saved-service/internal/adapter/metrics"
	repositoryadapter "kz/inflap/backend/services/saved-service/internal/adapter/repository"
	"kz/inflap/backend/services/saved-service/internal/app/cursor"
	"kz/inflap/backend/services/saved-service/internal/app/operation"
	"kz/inflap/backend/services/saved-service/internal/app/productrollout"
	"kz/inflap/backend/services/saved-service/internal/app/savedcapability"
	"kz/inflap/backend/services/saved-service/internal/app/savedcollection"
	"kz/inflap/backend/services/saved-service/internal/app/saveditem"
	"kz/inflap/backend/services/saved-service/internal/app/savedquery"
	"kz/inflap/backend/services/saved-service/internal/app/savedsearch"
	"kz/inflap/backend/services/saved-service/internal/app/savedsearchmigration"
	"kz/inflap/backend/services/saved-service/internal/bootstrap"
	"kz/inflap/backend/services/saved-service/internal/config"
	"kz/inflap/backend/services/saved-service/internal/domain"
)

func main() {
	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	cfg, err := config.Load(ctx)
	if err != nil {
		log.Fatal().Err(err).Msg("load configuration")
	}
	setupLogger(cfg)

	pool, err := newPostgresPool(ctx, cfg)
	if err != nil {
		log.Fatal().Err(err).Msg("initialize PostgreSQL pool")
	}
	defer pool.Close()

	dependencies, err := bootstrap.New(cfg, pool)
	if err != nil {
		log.Fatal().Err(err).Msg("initialize production dependencies")
	}
	defer func() {
		if closeErr := dependencies.Close(); closeErr != nil {
			log.Error().Err(closeErr).Msg("close production dependencies")
		}
	}()

	telemetry := metricsadapter.New()
	background, err := newSavedBackgroundRuntime(
		ctx,
		cfg,
		pool,
		dependencies.Sources,
		productionRuntimeObserver{metrics: telemetry},
		productionLifecycleObserver{metrics: telemetry},
	)
	if err != nil {
		log.Fatal().Err(err).Msg("initialize Saved background runtime")
	}
	if err = background.Start(ctx); err != nil {
		shutdownBackgroundAfterStartupFailure(background, cfg.HTTP.ShutdownTimeout)
		log.Fatal().Err(err).Msg("start Saved background runtime")
	}

	applicationHandler, err := newApplicationHandler(cfg, pool, dependencies, background, telemetry)
	if err != nil {
		shutdownBackgroundAfterStartupFailure(background, cfg.HTTP.ShutdownTimeout)
		log.Fatal().Err(err).Msg("initialize application handler")
	}
	internalApplicationHandler, err := newInternalApplicationHandler(
		cfg,
		applicationHandler,
		background.maintenance,
	)
	if err != nil {
		shutdownBackgroundAfterStartupFailure(background, cfg.HTTP.ShutdownTimeout)
		log.Fatal().Err(err).Msg("initialize internal application handler")
	}
	httpObserver := productionHTTPObserver{}
	handler := telemetry.WrapObserved(applicationHandler, httpObserver)
	internalHandler := telemetry.WrapObserved(internalApplicationHandler, httpObserver)

	server := newHTTPServer(cfg.HTTP.Address(), handler, cfg.HTTP, nil)
	internalMTLSServer, err := newInternalSavedMTLSServer(*cfg, internalHandler)
	if err != nil {
		log.Fatal().Err(err).Msg("configure internal mTLS listener")
	}

	errCh := make(chan error, 2)
	go serveHTTP(errCh, server, cfg.App.Name, cfg.HTTP.Port, false)
	if internalMTLSServer != nil {
		go serveHTTP(errCh, internalMTLSServer, cfg.App.Name, cfg.HTTP.InternalTLSPort, true)
	}

	select {
	case <-ctx.Done():
		log.Info().Msg("shutdown signal received")
	case <-background.Done():
		if backgroundErr := background.Err(); backgroundErr != nil {
			log.Error().Err(backgroundErr).Msg("Saved background runtime failed")
			stop()
		}
	case err := <-errCh:
		if err != nil {
			log.Error().Err(err).Msg("HTTP server failed")
			stop()
		}
	}

	shutdownCtx, cancel := context.WithTimeout(context.Background(), cfg.HTTP.ShutdownTimeout)
	defer cancel()
	shutdownServer(shutdownCtx, "HTTP", server)
	if internalMTLSServer != nil {
		shutdownServer(shutdownCtx, "internal mTLS HTTP", internalMTLSServer)
	}
	if err := background.Shutdown(shutdownCtx); err != nil {
		log.Error().Err(err).Msg("shutdown Saved background runtime")
	}
	log.Info().Str("service", cfg.App.Name).Msg("service stopped")
}

func newApplicationHandler(
	cfg *config.Config,
	pool *pgxpool.Pool,
	dependencies *bootstrap.Dependencies,
	background readinessChecker,
	telemetry *metricsadapter.Metrics,
) (http.Handler, error) {
	if cfg == nil || pool == nil || dependencies == nil || dependencies.Readiness == nil ||
		dependencies.Sources == nil || dependencies.SessionValidator == nil ||
		dependencies.PolicyGate == nil || dependencies.OperationHMAC == nil ||
		dependencies.CursorCodec == nil || dependencies.GatewayAuthorizer == nil ||
		dependencies.UserAccess == nil || background == nil ||
		telemetry == nil {
		return nil, errors.New("saved-service application dependencies are incomplete")
	}
	searchStatusCtx, cancelSearchStatus := context.WithTimeout(
		context.Background(),
		cfg.HTTP.ReadinessTimeout,
	)
	err := requireSavedSearchRollout(
		searchStatusCtx,
		pool,
		cfg.Features.SearchEnabled,
	)
	cancelSearchStatus()
	if err != nil {
		return nil, err
	}

	operationStore, err := repositoryadapter.NewPGOperationStore(pool, cfg.Limits.MaxConcurrentOperations)
	if err != nil {
		return nil, fmt.Errorf("initialize operation store: %w", err)
	}
	itemRepository, err := repositoryadapter.NewPGSavedItemRepository(pool)
	if err != nil {
		return nil, fmt.Errorf("initialize saved item repository: %w", err)
	}
	queryRepository, err := repositoryadapter.NewPGSavedQueryRepository(pool)
	if err != nil {
		return nil, fmt.Errorf("initialize saved query repository: %w", err)
	}
	searchRepository, err := repositoryadapter.NewPGSavedSearchRepository(pool)
	if err != nil {
		return nil, fmt.Errorf("initialize saved search repository: %w", err)
	}
	collectionLimits := savedCollectionLimits(cfg.Limits)
	collectionRepository, err := repositoryadapter.NewPGSavedCollectionRepository(
		pool,
		collectionLimits,
		nil,
	)
	if err != nil {
		return nil, fmt.Errorf("initialize saved collection repository: %w", err)
	}
	capabilityRepository, err := repositoryadapter.NewPGSavedCapabilityRepository(pool)
	if err != nil {
		return nil, fmt.Errorf("initialize Saved capability repository: %w", err)
	}
	rolloutGate, err := productrollout.NewEvaluator(savedProductRolloutConfig(*cfg))
	if err != nil {
		return nil, fmt.Errorf("initialize Saved product rollout: %w", err)
	}
	mediaResolver, err := mediaadapter.NewRouteResolver(cfg.PublicAPI.Origin)
	if err != nil {
		return nil, fmt.Errorf("initialize Saved media resolver: %w", err)
	}
	queryService, err := savedquery.NewService(queryRepository, mediaResolver, dependencies.UserAccess)
	if err != nil {
		return nil, fmt.Errorf("initialize saved query service: %w", err)
	}
	searchService, err := savedsearch.NewService(searchRepository, mediaResolver, dependencies.UserAccess)
	if err != nil {
		return nil, fmt.Errorf("initialize saved search service: %w", err)
	}
	collectionReadService, err := savedcollection.NewReadService(
		collectionRepository,
		mediaResolver,
		dependencies.UserAccess,
	)
	if err != nil {
		return nil, fmt.Errorf("initialize saved collection read service: %w", err)
	}
	capabilityService, err := savedcapability.NewService(capabilityRepository, savedcapability.Config{
		CapabilityRevision: cfg.Features.CapabilityRevision,
		ProductFlags: savedcapability.ProductFlags{
			SavedItemsEnabled:  cfg.Features.SavedItemsEnabled,
			SearchEnabled:      cfg.Features.SearchEnabled,
			CollectionsEnabled: cfg.Features.CollectionsEnabled,
		},
		SupportedEntityTypes: []domain.EntityType{
			domain.EntityTypeAttraction,
			domain.EntityTypeActivity,
			domain.EntityTypeUser,
			domain.EntityTypePost,
		},
		MaxActiveSavedItems:   uint64(cfg.Limits.MaxActiveSaves),
		QuotaWarningRemaining: uint64(cfg.Features.QuotaWarningRemaining),
	})
	if err != nil {
		return nil, fmt.Errorf("initialize Saved capability service: %w", err)
	}
	scopeFingerprinter, err := newCursorScopeFingerprinter(cfg.Crypto)
	if err != nil {
		return nil, fmt.Errorf("initialize cursor scope fingerprinter: %w", err)
	}
	clock := operation.SystemClock{}
	operationService, err := operation.NewService(operationStore, dependencies.OperationHMAC, clock)
	if err != nil {
		return nil, fmt.Errorf("initialize operation service: %w", err)
	}
	itemService, err := saveditem.NewService(saveditem.ServiceConfig{
		OperationBeginner: operationService,
		Repository:        itemRepository,
		SourceResolver:    dependencies.Sources,
		SessionValidator:  dependencies.SessionValidator,
		PolicyGate:        dependencies.PolicyGate,
		UserAccessPolicy:  dependencies.UserAccess,
		Clock:             clock,
		MaxActiveSaves:    uint64(cfg.Limits.MaxActiveSaves),
		DisableExpansion:  !cfg.Features.SavedItemsEnabled,
	})
	if err != nil {
		return nil, fmt.Errorf("initialize saved item service: %w", err)
	}
	collectionMutationService, err := savedcollection.NewMutationService(savedcollection.MutationServiceConfig{
		OperationBeginner: operationService,
		Repository:        collectionRepository,
		SourceResolver:    dependencies.Sources,
		SessionValidator:  dependencies.SessionValidator,
		PolicyGate:        dependencies.PolicyGate,
		UserAccessPolicy:  dependencies.UserAccess,
		Clock:             clock,
		Limits:            collectionLimits,
		DisableExpansion:  !cfg.Features.CollectionsEnabled,
	})
	if err != nil {
		return nil, fmt.Errorf("initialize saved collection mutation service: %w", err)
	}
	mutationHandler, err := httpadapter.NewSavedItemMutationHandler(itemService, clock)
	if err != nil {
		return nil, fmt.Errorf("initialize saved mutation handler: %w", err)
	}
	operationHandler, err := httpadapter.NewOperationHandler(itemRepository, clock)
	if err != nil {
		return nil, fmt.Errorf("initialize saved operation handler: %w", err)
	}
	queryHandler, err := httpadapter.NewSavedQueryHandler(
		queryService,
		dependencies.CursorCodec,
		scopeFingerprinter,
	)
	if err != nil {
		return nil, fmt.Errorf("initialize saved query handler: %w", err)
	}
	searchHandler, err := httpadapter.NewSavedSearchHandler(
		searchService,
		dependencies.CursorCodec,
		scopeFingerprinter,
		telemetry,
	)
	if err != nil {
		return nil, fmt.Errorf("initialize saved search handler: %w", err)
	}
	collectionHandler, err := httpadapter.NewSavedCollectionHandler(
		collectionReadService,
		collectionMutationService,
		clock,
	)
	if err != nil {
		return nil, fmt.Errorf("initialize saved collection handler: %w", err)
	}
	capabilityHandler, err := httpadapter.NewSavedCapabilitiesHandler(capabilityService)
	if err != nil {
		return nil, fmt.Errorf("initialize Saved capability handler: %w", err)
	}
	registrars := []httpadapter.PersonalRouteRegistrar{
		mutationHandler,
		operationHandler,
		queryHandler,
		collectionHandler,
		capabilityHandler,
	}
	if cfg.Features.SearchEnabled {
		registrars = append(registrars, searchHandler)
	}
	personalHandler, err := httpadapter.NewPersonalRouterWithRollout(
		dependencies.GatewayAuthorizer,
		dependencies.PolicyGate,
		rolloutGate,
		registrars...,
	)
	if err != nil {
		return nil, fmt.Errorf("initialize personal Saved routes: %w", err)
	}

	mux := http.NewServeMux()
	httpadapter.NewHealthHandler(
		readinessPinger{checker: compositeReadiness{checkers: []readinessChecker{
			dependencies.Readiness,
			background,
		}}},
		cfg.HTTP.ReadinessTimeout,
	).Register(mux)
	mux.Handle("GET /metrics", telemetry)
	mux.Handle("/v1/users/me/", personalHandler)
	return mux, nil
}

func savedProductRolloutConfig(cfg config.Config) productrollout.Config {
	rule := func(enabled bool, basisPoints int) productrollout.Rule {
		return productrollout.Rule{
			Enabled:          enabled,
			BasisPoints:      basisPoints,
			AllowedPlatforms: []productrollout.Platform{productrollout.PlatformAndroid, productrollout.PlatformIOS},
			MinimumBuildByPlatform: map[productrollout.Platform]uint64{
				productrollout.PlatformAndroid: cfg.Rollout.AndroidMinimumBuild,
				productrollout.PlatformIOS:     cfg.Rollout.IOSMinimumBuild,
			},
		}
	}

	return productrollout.Config{
		SavedCore:        rule(cfg.Features.SavedItemsEnabled, cfg.Rollout.CoreBasisPoints),
		SavedSearch:      rule(cfg.Features.SearchEnabled, cfg.Rollout.SearchBasisPoints),
		SavedCollections: rule(cfg.Features.CollectionsEnabled, cfg.Rollout.CollectionsBasisPoints),
		Entities: productrollout.EntityRules{
			Attraction: rule(cfg.Features.SavedItemsEnabled, cfg.Rollout.AttractionBasisPoints),
			Activity:   rule(cfg.Features.SavedItemsEnabled, cfg.Rollout.ActivityBasisPoints),
			User:       rule(cfg.Features.SavedItemsEnabled, cfg.Rollout.UserBasisPoints),
			Post:       rule(cfg.Features.SavedItemsEnabled, cfg.Rollout.PostBasisPoints),
		},
	}
}

type savedSearchStatusReader interface {
	Status(context.Context) (savedsearchmigration.Status, error)
}

func requireSavedSearchRollout(
	ctx context.Context,
	pool *pgxpool.Pool,
	enabled bool,
) error {
	if !enabled {
		return nil
	}
	if ctx == nil || pool == nil {
		return errors.New("Saved search rollout verification is unavailable")
	}
	repository, err := repositoryadapter.NewPGSavedSearchMigrationRepository(
		pool,
		repositoryadapter.SavedSearchMigrationOptions{
			LockTimeout:      time.Second,
			StatementTimeout: 10 * time.Second,
			ContractTimeout:  30 * time.Minute,
		},
	)
	if err != nil {
		return fmt.Errorf("initialize Saved search rollout verifier: %w", err)
	}
	return requireSavedSearchReady(ctx, repository)
}

func requireSavedSearchReady(ctx context.Context, reader savedSearchStatusReader) error {
	if ctx == nil || reader == nil {
		return errors.New("Saved search rollout verification is unavailable")
	}
	status, err := reader.Status(ctx)
	if err != nil {
		return fmt.Errorf("verify Saved search rollout: %w", err)
	}
	if !status.Ready() {
		return errors.New(
			"SAVED_SEARCH_PRODUCT_ENABLED requires a completed Saved search contract rollout",
		)
	}
	return nil
}

func newInternalApplicationHandler(
	cfg *config.Config,
	publicHandler http.Handler,
	purgeUseCase httpadapter.SubjectPurgeUseCase,
) (http.Handler, error) {
	if cfg == nil || publicHandler == nil || purgeUseCase == nil {
		return nil, errors.New("internal Saved application dependencies are incomplete")
	}
	purgeHandler, err := httpadapter.NewSubjectPurgeHandler(
		purgeUseCase,
		cfg.Compliance.AllowedCallerSPIFFEID,
	)
	if err != nil {
		return nil, err
	}
	mux := http.NewServeMux()
	if err := purgeHandler.Register(mux); err != nil {
		return nil, err
	}
	mux.Handle("/", publicHandler)
	return mux, nil
}

func savedCollectionLimits(limits config.OwnerLimitsConfig) savedcollection.Limits {
	return savedcollection.Limits{
		MaxActiveCollections:        uint64(limits.MaxActiveCollections),
		MaxMembershipsPerCollection: uint64(limits.MaxMembershipsPerCollection),
		MaxMembershipsPerOwner:      uint64(limits.MaxMembershipsPerOwner),
		MaxDesiredCollectionIDs:     limits.MaxDesiredCollectionIDs,
		MaxActiveSaves:              uint64(limits.MaxActiveSaves),
	}
}

func newCursorScopeFingerprinter(cryptoConfig config.CryptoConfig) (*cursor.Fingerprinter, error) {
	cursorKey := cryptoConfig.CursorCurrentKey().Secret.Bytes()
	defer clear(cursorKey)
	if len(cursorKey) != sha256.Size {
		return nil, cursor.ErrInvalidScope
	}
	mac := hmac.New(sha256.New, cursorKey)
	_, _ = mac.Write([]byte("saved-cursor-scope-fingerprint-key-v1"))
	scopeKey := mac.Sum(nil)
	defer clear(scopeKey)
	return cursor.NewFingerprinter(scopeKey)
}

type readinessChecker interface {
	Check(context.Context) error
}

type readinessPinger struct {
	checker readinessChecker
}

func (p readinessPinger) Ping(ctx context.Context) error {
	if p.checker == nil {
		return errors.New("saved-service readiness is unavailable")
	}
	err := p.checker.Check(ctx)
	if err != nil {
		log.Warn().Err(err).Msg("Saved readiness check failed")
	}
	return err
}

func newPostgresPool(ctx context.Context, cfg *config.Config) (*pgxpool.Pool, error) {
	poolConfig, err := pgxpool.ParseConfig(cfg.DB.DSN())
	if err != nil {
		return nil, fmt.Errorf("parse PostgreSQL pool configuration: %w", err)
	}
	poolConfig.MaxConns = cfg.DB.MaxConns
	poolConfig.MinConns = cfg.DB.MinConns
	poolConfig.MaxConnLifetime = cfg.DB.MaxConnLifetime
	poolConfig.MaxConnIdleTime = cfg.DB.MaxConnIdleTime

	pool, err := pgxpool.NewWithConfig(ctx, poolConfig)
	if err != nil {
		return nil, fmt.Errorf("create PostgreSQL pool: %w", err)
	}

	pingCtx, cancel := context.WithTimeout(ctx, cfg.HTTP.ReadinessTimeout)
	defer cancel()
	if err := pool.Ping(pingCtx); err != nil {
		pool.Close()
		return nil, fmt.Errorf("ping PostgreSQL: %w", err)
	}
	return pool, nil
}

func newInternalSavedMTLSServer(cfg config.Config, handler http.Handler) (*http.Server, error) {
	tlsConfig, err := cfg.MTLS.ServerConfig().ServerTLSConfig()
	if err != nil {
		return nil, err
	}
	if tlsConfig == nil {
		return nil, nil
	}
	if err := validateSavedMTLSListener(cfg, tlsConfig); err != nil {
		return nil, err
	}
	return newHTTPServer(cfg.HTTP.InternalTLSAddress(), handler, cfg.HTTP, tlsConfig), nil
}

func validateSavedMTLSListener(cfg config.Config, tlsConfig *tls.Config) error {
	if tlsConfig == nil {
		return nil
	}
	if cfg.HTTP.InternalTLSPort == 0 {
		return fmt.Errorf("INTERNAL_HTTP_TLS_PORT is required when mTLS is enabled")
	}
	if cfg.HTTP.InternalTLSPort == cfg.HTTP.Port {
		return fmt.Errorf("INTERNAL_HTTP_TLS_PORT must be different from HTTP_PORT")
	}
	return nil
}

func newHTTPServer(address string, handler http.Handler, cfg config.HTTPConfig, tlsConfig *tls.Config) *http.Server {
	return &http.Server{
		Addr:              address,
		Handler:           handler,
		TLSConfig:         tlsConfig,
		ReadHeaderTimeout: cfg.ReadHeaderTimeout,
		ReadTimeout:       cfg.ReadTimeout,
		WriteTimeout:      cfg.WriteTimeout,
		IdleTimeout:       cfg.IdleTimeout,
	}
}

func serveHTTP(errCh chan<- error, server *http.Server, service string, port int, tlsEnabled bool) {
	mode := "HTTP"
	serve := server.ListenAndServe
	if tlsEnabled {
		mode = "internal mTLS HTTP"
		serve = func() error { return server.ListenAndServeTLS("", "") }
	}
	log.Info().Str("service", service).Int("port", port).Str("listener", mode).Msg("server started")
	if err := serve(); err != nil && !errors.Is(err, http.ErrServerClosed) {
		errCh <- fmt.Errorf("serve %s: %w", mode, err)
	}
}

func shutdownServer(ctx context.Context, name string, server *http.Server) {
	if err := server.Shutdown(ctx); err != nil {
		log.Error().Err(err).Str("server", name).Msg("shutdown failed")
	}
}

func shutdownBackgroundAfterStartupFailure(
	background *savedBackgroundRuntime,
	timeout time.Duration,
) {
	if background == nil {
		return
	}
	shutdownCtx, cancel := context.WithTimeout(context.Background(), timeout)
	defer cancel()
	if err := background.Shutdown(shutdownCtx); err != nil {
		log.Error().Err(err).Msg("shutdown Saved background runtime after startup failure")
	}
}

func setupLogger(cfg *config.Config) {
	level, _ := zerolog.ParseLevel(strings.TrimSpace(cfg.Log.Level))
	zerolog.SetGlobalLevel(level)
	if strings.EqualFold(cfg.App.Env, "production") {
		log.Logger = zerolog.New(os.Stdout).With().Timestamp().Logger()
		return
	}
	log.Logger = zerolog.New(zerolog.ConsoleWriter{
		Out:        os.Stdout,
		TimeFormat: time.RFC3339,
	}).With().Timestamp().Logger()
}
