package main

import (
	"context"
	"errors"
	"net/http"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"
	_ "time/tzdata"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"
	"kz/inflap/backend/pkg/switches"
	activityadapter "kz/inflap/backend/services/admin-panel/internal/adapter/activity"
	antifraudadapter "kz/inflap/backend/services/admin-panel/internal/adapter/antifraud"
	chatadapter "kz/inflap/backend/services/admin-panel/internal/adapter/chat"
	"kz/inflap/backend/services/admin-panel/internal/adapter/excursion"
	featureflagadapter "kz/inflap/backend/services/admin-panel/internal/adapter/featureflag"
	filemanageradapter "kz/inflap/backend/services/admin-panel/internal/adapter/filemanager"
	guideadapter "kz/inflap/backend/services/admin-panel/internal/adapter/guide"
	httpadapter "kz/inflap/backend/services/admin-panel/internal/adapter/http"
	notificationadapter "kz/inflap/backend/services/admin-panel/internal/adapter/notification"
	placeadapter "kz/inflap/backend/services/admin-panel/internal/adapter/place"
	postadapter "kz/inflap/backend/services/admin-panel/internal/adapter/post"
	"kz/inflap/backend/services/admin-panel/internal/adapter/repository"
	techbreakadapter "kz/inflap/backend/services/admin-panel/internal/adapter/techbreak"
	trustadapter "kz/inflap/backend/services/admin-panel/internal/adapter/trust"
	useradapter "kz/inflap/backend/services/admin-panel/internal/adapter/user"
	userrouteadapter "kz/inflap/backend/services/admin-panel/internal/adapter/userroute"
	"kz/inflap/backend/services/admin-panel/internal/app"
	"kz/inflap/backend/services/admin-panel/internal/config"
)

func main() {
	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	cfg, err := config.Load(ctx)
	if err != nil {
		log.Fatal().Err(err).Msg("failed to load admin-panel config")
	}
	configureLogger(cfg)
	if err = validateConfig(cfg); err != nil {
		log.Fatal().Err(err).Msg("invalid admin-panel config")
	}

	pool, err := connectPostgres(ctx, cfg)
	if err != nil {
		log.Fatal().Err(err).Msg("failed to connect admin-panel database")
	}
	defer pool.Close()

	staffRepo := repository.NewPGStaffRepository(pool)
	sessionRepo := repository.NewPGSessionRepository(pool)
	loginAttemptRepo := repository.NewPGLoginAttemptRepository(pool)
	auditRepo := repository.NewPGAuditRepository(pool)
	moderationRepo := repository.NewPGModerationRepository(pool)
	userModerationRepo := repository.NewPGUserModerationRepository(pool)
	restrictionOutboxRepo := repository.NewPGUserRestrictionOutboxRepository(pool)
	excursionClient := excursion.NewClient(
		cfg.Excursion.BaseURL,
		cfg.Excursion.Timeout,
		cfg.Security.TrustedInternalToken,
	)
	activityClient := activityadapter.NewClient(
		cfg.Activity.BaseURL,
		cfg.Activity.Timeout,
		cfg.Security.TrustedInternalToken,
	)
	guideClient := guideadapter.NewClient(
		cfg.Guide.BaseURL,
		cfg.Guide.Timeout,
		cfg.Security.TrustedInternalToken,
	)
	chatClient := chatadapter.NewClient(
		cfg.Chat.BaseURL,
		cfg.Chat.Timeout,
		cfg.Security.TrustedInternalToken,
	)
	postClient := postadapter.NewClient(
		cfg.FeedService.BaseURL,
		cfg.FeedService.Timeout,
		cfg.Security.TrustedInternalToken,
	)
	userRouteClient := userrouteadapter.NewClient(
		cfg.UserRoute.BaseURL,
		cfg.UserRoute.Timeout,
		cfg.Security.TrustedInternalToken,
	)
	userClient, err := useradapter.New(
		cfg.User.Target,
		cfg.Security.TrustedInternalToken,
		cfg.App.Name,
		cfg.User.Timeout,
	)
	if err != nil {
		log.Fatal().Err(err).Msg("failed to initialize user-service client")
	}
	defer userClient.Close()
	trustClient, err := trustadapter.New(
		cfg.Trust.Target,
		cfg.Security.TrustedInternalToken,
		cfg.App.Name,
		cfg.Trust.Timeout,
	)
	if err != nil {
		log.Fatal().Err(err).Msg("failed to initialize trust-service client")
	}
	defer trustClient.Close()
	antiFraudClient := antifraudadapter.NewClient(
		cfg.AntiFraud.BaseURL,
		cfg.AntiFraud.Timeout,
		cfg.Security.TrustedInternalToken,
	)
	placeClient := placeadapter.NewClient(
		cfg.Place.BaseURL,
		cfg.Place.Timeout,
		cfg.Security.TrustedInternalToken,
	)
	fileManagerClient := filemanageradapter.NewClient(
		cfg.FileManager.BaseURL,
		cfg.FileManager.Timeout,
		cfg.Security.TrustedInternalToken,
	)
	featureFlagClient := featureflagadapter.NewClient(
		cfg.FeatureFlag.BaseURL,
		cfg.FeatureFlag.Timeout,
		cfg.Security.TrustedInternalToken,
	)
	techBreakClient := techbreakadapter.NewClient(
		cfg.TechBreak.BaseURL,
		cfg.TechBreak.Timeout,
		cfg.Security.TrustedInternalToken,
	)
	var notificationClient *notificationadapter.Client
	if strings.TrimSpace(cfg.Notification.HTTPURL) != "" &&
		strings.TrimSpace(cfg.Security.TrustedInternalToken) != "" {
		notificationClient = notificationadapter.New(
			cfg.Notification.HTTPURL,
			cfg.Security.TrustedInternalToken,
			cfg.App.Name,
			cfg.Notification.RequestTimeout,
		)
		log.Info().
			Str("url", cfg.Notification.HTTPURL).
			Msg("admin-panel user notification client enabled")
	}

	authUC := app.NewAuthUseCase(staffRepo, sessionRepo, loginAttemptRepo, auditRepo, app.AuthConfig{
		IdleTimeout:      cfg.Security.SessionIdleTimeout,
		AbsoluteTimeout:  cfg.Security.SessionAbsoluteTimeout,
		LoginWindow:      cfg.Security.LoginRateLimitWindow,
		MaxLoginFailures: cfg.Security.LoginRateLimitMaxFailures,
	})
	staffUC := app.NewStaffUseCase(staffRepo, auditRepo, sessionRepo)
	moderationUC := app.NewModerationUseCase(moderationRepo, excursionClient, activityClient, guideClient, chatClient, auditRepo)
	moderationUC.SetPostReportClient(postClient)
	userRouteModerationUC := app.NewUserRouteModerationUseCase(userRouteClient, auditRepo)
	userModerationUC := app.NewUserModerationUseCase(userClient, userModerationRepo, auditRepo)
	trustAppealUC := app.NewTrustAppealUseCase(trustClient, auditRepo)
	if notificationClient != nil {
		moderationUC.SetNotificationGateway(notificationClient)
		userModerationUC.SetNotificationGateway(notificationClient)
	}
	restrictionOutboxWorker := app.NewRestrictionOutboxWorker(
		restrictionOutboxRepo,
		trustClient,
		app.RestrictionOutboxWorkerConfig{
			PollInterval: cfg.Trust.OutboxPollInterval,
			BatchSize:    cfg.Trust.OutboxBatchSize,
			MaxAttempts:  cfg.Trust.OutboxMaxAttempts,
			BaseBackoff:  cfg.Trust.OutboxBaseBackoff,
		},
	)
	fraudUC := app.NewFraudUseCase(antiFraudClient, auditRepo)
	placeUC := app.NewPlaceContentUseCase(placeClient, fileManagerClient, auditRepo, app.PlaceContentConfig{
		MaxImageBytes: cfg.FileManager.MaxPlaceImageBytes,
	})
	communityAdminUC := app.NewCommunityAdminUseCase(
		postClient,
		auditRepo,
		app.WithCommunityAdminFileUploads(
			fileManagerClient,
			cfg.FileManager.MaxPlaceImageBytes,
		),
	)
	operationsUC := app.NewOperationsUseCase(featureFlagClient, techBreakClient, auditRepo)
	auditUC := app.NewAuditUseCase(auditRepo)

	if created, err := bootstrapSuperAdmin(ctx, cfg, staffUC); err != nil {
		log.Fatal().Err(err).Msg("failed to bootstrap super admin")
	} else if created {
		log.Warn().
			Str("email", strings.ToLower(strings.TrimSpace(cfg.Bootstrap.SuperAdminEmail))).
			Msg("bootstrap super admin created; rotate the password after first login")
	}

	renderer, err := httpadapter.NewRenderer()
	if err != nil {
		log.Fatal().Err(err).Msg("failed to initialize renderer")
	}
	adminServer := httpadapter.NewServer(cfg, renderer, authUC, staffUC, moderationUC, userModerationUC, auditUC, placeUC, fraudUC)
	adminServer.SetReadinessCheck(pool.Ping)
	adminServer.SetTrustAppealUseCase(trustAppealUC)
	adminServer.SetCommunityAdminUseCase(communityAdminUC)
	adminServer.SetOperationsUseCase(operationsUC)
	adminServer.SetUserRouteModerationUseCase(userRouteModerationUC)

	go restrictionOutboxWorker.Start(ctx)

	server := &http.Server{
		Addr:              cfg.HTTP.Address(),
		Handler:           withTechBreakMaintenance(adminServer.Handler(), cfg.Switches, cfg.Security.TrustedInternalToken, "ADMIN", "/admin/static/"),
		ReadHeaderTimeout: 5 * time.Second,
		ReadTimeout:       cfg.HTTP.ReadTimeout,
		WriteTimeout:      cfg.HTTP.WriteTimeout,
		IdleTimeout:       cfg.HTTP.IdleTimeout,
	}

	go func() {
		<-ctx.Done()
		shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		defer cancel()
		if err := server.Shutdown(shutdownCtx); err != nil {
			log.Error().Err(err).Msg("admin-panel graceful shutdown failed")
		}
	}()

	log.Info().
		Str("addr", cfg.HTTP.Address()).
		Str("env", cfg.App.Env).
		Msg("admin-panel started")
	if err := server.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
		log.Fatal().Err(err).Msg("admin-panel failed")
	}
}

func withTechBreakMaintenance(
	next http.Handler,
	cfg config.SwitchesServiceConfig,
	fallbackToken string,
	domainCode string,
	skipPathPrefixes ...string,
) http.Handler {
	token := switches.EffectiveInternalServiceToken(cfg.InternalServiceToken, fallbackToken)
	middleware, err := switches.NewMaintenanceMiddleware(
		switches.HTTPClientConfig{
			BaseURL:              cfg.HTTPURL,
			InternalServiceToken: token,
			Timeout:              cfg.RequestTimeout,
		},
		switches.MaintenanceMiddlewareConfig{
			DomainCode:       domainCode,
			SkipPathPrefixes: skipPathPrefixes,
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

func configureLogger(cfg *config.Config) {
	level, err := zerolog.ParseLevel(strings.ToLower(strings.TrimSpace(cfg.Log.Level)))
	if err != nil {
		level = zerolog.InfoLevel
	}
	zerolog.SetGlobalLevel(level)
	if !cfg.App.IsProduction() {
		log.Logger = log.Output(zerolog.ConsoleWriter{Out: os.Stderr, TimeFormat: time.RFC3339})
	}
}

func validateConfig(cfg *config.Config) error {
	if cfg.App.IsProduction() {
		if !cfg.Security.CookieSecure {
			return errors.New("COOKIE_SECURE must be true in production")
		}
		if strings.TrimSpace(cfg.Security.TrustedInternalToken) == "" {
			return errors.New("INTERNAL_SERVICE_TOKEN is required in production")
		}
	}
	if strings.TrimSpace(cfg.Bootstrap.SuperAdminEmail) != "" &&
		strings.TrimSpace(cfg.Bootstrap.SuperAdminPassword) == "" {
		return errors.New("BOOTSTRAP_SUPERADMIN_PASSWORD is required when BOOTSTRAP_SUPERADMIN_EMAIL is set")
	}
	return nil
}

func connectPostgres(ctx context.Context, cfg *config.Config) (*pgxpool.Pool, error) {
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
	if err = pool.Ping(ctx); err != nil {
		pool.Close()
		return nil, err
	}
	return pool, nil
}

func bootstrapSuperAdmin(ctx context.Context, cfg *config.Config, staff *app.StaffUseCase) (bool, error) {
	return staff.BootstrapSuperAdmin(ctx, app.BootstrapSuperAdminInput{
		Email:       cfg.Bootstrap.SuperAdminEmail,
		DisplayName: cfg.Bootstrap.SuperAdminDisplayName,
		Password:    cfg.Bootstrap.SuperAdminPassword,
		Metadata: app.RequestMetadata{
			RequestID: "bootstrap",
			IPAddress: "127.0.0.1",
			UserAgent: "admin-panel/bootstrap",
		},
	})
}
