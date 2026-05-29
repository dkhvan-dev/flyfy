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

	activityadapter "github.com/dkhvan-dev/flyfy/backend/services/admin-panel/internal/adapter/activity"
	antifraudadapter "github.com/dkhvan-dev/flyfy/backend/services/admin-panel/internal/adapter/antifraud"
	attractionadapter "github.com/dkhvan-dev/flyfy/backend/services/admin-panel/internal/adapter/attraction"
	chatadapter "github.com/dkhvan-dev/flyfy/backend/services/admin-panel/internal/adapter/chat"
	"github.com/dkhvan-dev/flyfy/backend/services/admin-panel/internal/adapter/excursion"
	filemanageradapter "github.com/dkhvan-dev/flyfy/backend/services/admin-panel/internal/adapter/filemanager"
	guideadapter "github.com/dkhvan-dev/flyfy/backend/services/admin-panel/internal/adapter/guide"
	httpadapter "github.com/dkhvan-dev/flyfy/backend/services/admin-panel/internal/adapter/http"
	"github.com/dkhvan-dev/flyfy/backend/services/admin-panel/internal/adapter/repository"
	"github.com/dkhvan-dev/flyfy/backend/services/admin-panel/internal/app"
	"github.com/dkhvan-dev/flyfy/backend/services/admin-panel/internal/config"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"
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
	antiFraudClient := antifraudadapter.NewClient(
		cfg.AntiFraud.BaseURL,
		cfg.AntiFraud.Timeout,
		cfg.Security.TrustedInternalToken,
	)
	attractionClient := attractionadapter.NewClient(
		cfg.Attraction.BaseURL,
		cfg.Attraction.Timeout,
		cfg.Security.TrustedInternalToken,
	)
	fileManagerClient := filemanageradapter.NewClient(
		cfg.FileManager.BaseURL,
		cfg.FileManager.Timeout,
		cfg.Security.TrustedInternalToken,
	)

	authUC := app.NewAuthUseCase(staffRepo, sessionRepo, loginAttemptRepo, auditRepo, app.AuthConfig{
		IdleTimeout:      cfg.Security.SessionIdleTimeout,
		AbsoluteTimeout:  cfg.Security.SessionAbsoluteTimeout,
		LoginWindow:      cfg.Security.LoginRateLimitWindow,
		MaxLoginFailures: cfg.Security.LoginRateLimitMaxFailures,
	})
	staffUC := app.NewStaffUseCase(staffRepo, auditRepo, sessionRepo)
	moderationUC := app.NewModerationUseCase(moderationRepo, excursionClient, activityClient, guideClient, chatClient, auditRepo)
	fraudUC := app.NewFraudUseCase(antiFraudClient, auditRepo)
	attractionUC := app.NewAttractionContentUseCase(attractionClient, fileManagerClient, auditRepo, app.AttractionContentConfig{
		MaxImageBytes: cfg.FileManager.MaxAttractionImageBytes,
	})
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
	adminServer := httpadapter.NewServer(cfg, renderer, authUC, staffUC, moderationUC, auditUC, attractionUC, fraudUC)
	adminServer.SetReadinessCheck(pool.Ping)

	server := &http.Server{
		Addr:              cfg.HTTP.Address(),
		Handler:           adminServer.Handler(),
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
