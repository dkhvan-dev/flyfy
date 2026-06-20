package main

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/redis/go-redis/v9"
	"github.com/rs/zerolog"

	fraudadapter "kz/inflap/backend/services/auth-service/internal/adapter/fraud"
	httpAdapter "kz/inflap/backend/services/auth-service/internal/adapter/http"
	"kz/inflap/backend/services/auth-service/internal/adapter/oauth"
	"kz/inflap/backend/services/auth-service/internal/adapter/otp"
	"kz/inflap/backend/services/auth-service/internal/adapter/repository"
	switchesadapter "kz/inflap/backend/services/auth-service/internal/adapter/switches"
	"kz/inflap/backend/services/auth-service/internal/adapter/tokenclient"
	"kz/inflap/backend/services/auth-service/internal/adapter/userservice"
	"kz/inflap/backend/services/auth-service/internal/app"
	"kz/inflap/backend/services/auth-service/internal/config"
	"kz/inflap/backend/services/auth-service/internal/domain/port"
)

func main() {
	// --- Logger ---
	logger := zerolog.New(os.Stdout).
		With().
		Timestamp().
		Str("service", "auth-service").
		Logger()

	if os.Getenv("APP_ENV") == "development" {
		logger = logger.Output(zerolog.ConsoleWriter{Out: os.Stderr})
	}

	// --- Config ---
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	cfg, err := config.Load(ctx)
	if err != nil {
		logger.Fatal().Err(err).Msg("failed to load config")
	}

	logger.Info().
		Int("http_port", cfg.HTTPPort).
		Int("grpc_port", cfg.GRPCPort).
		Str("env", cfg.Env).
		Msg("starting auth-service")

	// --- Infrastructure ---

	// PostgreSQL
	pgPool, err := pgxpool.New(ctx, cfg.Postgres.DSN())
	if err != nil {
		logger.Fatal().Err(err).Msg("failed to connect to PostgreSQL")
	}
	defer pgPool.Close()

	if err := pgPool.Ping(ctx); err != nil {
		logger.Fatal().Err(err).Msg("PostgreSQL ping failed")
	}
	logger.Info().Msg("PostgreSQL connected")

	// Redis
	rdb := redis.NewClient(&redis.Options{
		Addr:     cfg.Redis.Addr,
		Password: cfg.Redis.Password,
		DB:       cfg.Redis.DB,
	})
	defer rdb.Close()

	if err := rdb.Ping(ctx).Err(); err != nil {
		logger.Fatal().Err(err).Msg("Redis ping failed")
	}
	logger.Info().Msg("Redis connected")

	// --- Adapters (secondary ports) ---

	// Repositories
	userRepo := repository.NewPgUserRepository(pgPool)
	otpStore := repository.NewRedisOTPStore(rdb, cfg.OTP.TTL)

	// OTP sender (log-based for dev)
	otpSender := otp.NewLogOTPSender(logger)

	// OAuth verifiers (stubs for dev)
	googleVerifier := oauth.NewGoogleVerifier(cfg.Google.ClientID, logger)
	appleVerifier := oauth.NewAppleVerifier(cfg.Apple.TeamID, cfg.Apple.BundleID, logger)

	// Token service client (S2S gRPC)
	tokenClient, err := tokenclient.NewTokenServiceClient(cfg.TokenService, logger)
	if err != nil {
		logger.Fatal().Err(err).Msg("failed to create token service client")
	}
	defer tokenClient.Close()
	logger.Info().
		Str("addr", cfg.TokenService.Addr).
		Str("service_id", cfg.TokenService.ServiceID).
		Msg("token-service client initialized")

	var nicknameResolver port.NicknameResolver
	if cfg.UserService.InternalServiceToken == "" {
		logger.Warn().Msg("user-service internal token is not configured; nickname password login is disabled")
	} else {
		userClient, err := userservice.New(cfg.UserService)
		if err != nil {
			logger.Fatal().Err(err).Msg("failed to create user-service client")
		}
		defer userClient.Close()
		nicknameResolver = userClient
		logger.Info().
			Str("target", cfg.UserService.GRPCTarget).
			Msg("user-service client initialized")
	}

	// --- Application (use cases) ---
	fraudClient, err := newFraudEvaluator(cfg)
	if err != nil {
		logger.Fatal().Err(err).Msg("failed to create anti-fraud client")
	}

	authUC := app.NewAuthUseCaseWithFraud(
		userRepo,
		otpStore,
		otpSender,
		googleVerifier,
		appleVerifier,
		tokenClient,
		fraudClient,
		cfg.OTP,
		cfg.Security,
		cfg.Env,
		logger,
	)
	authUC.SetEmailOTPSender(otp.NewEmailOTPSender(otp.EmailSenderConfig{
		FromAddress:  cfg.Email.OTPFromAddress,
		SMTPHost:     cfg.Email.SMTPHost,
		SMTPPort:     cfg.Email.SMTPPort,
		SMTPUsername: cfg.Email.SMTPUsername,
		SMTPPassword: cfg.Email.SMTPPassword,
		SMTPTimeout:  cfg.Email.SMTPTimeout,
	}, logger))
	authUC.SetNicknameResolver(nicknameResolver)
	if switchesClient := newSwitchesClient(cfg, logger); switchesClient != nil {
		authUC.SetFeatureFlagReader(switchesClient)
		authUC.SetTechBreakChecker(switchesClient)
	}

	// --- HTTP Server ---
	authHandler := httpAdapter.NewAuthHandler(authUC, logger)
	httpServer := &http.Server{
		Addr:         fmt.Sprintf(":%d", cfg.HTTPPort),
		Handler:      authHandler.Router(),
		ReadTimeout:  5 * time.Second,
		WriteTimeout: 10 * time.Second,
		IdleTimeout:  30 * time.Second,
	}

	// --- Start server ---
	errCh := make(chan error, 1)

	go func() {
		logger.Info().Int("port", cfg.HTTPPort).Msg("HTTP server listening")
		if err := httpServer.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			errCh <- fmt.Errorf("HTTP serve: %w", err)
		}
	}()

	// --- Graceful shutdown ---
	sigCh := make(chan os.Signal, 1)
	signal.Notify(sigCh, syscall.SIGINT, syscall.SIGTERM)

	select {
	case sig := <-sigCh:
		logger.Info().Str("signal", sig.String()).Msg("shutdown signal received")
	case err := <-errCh:
		logger.Error().Err(err).Msg("server error")
	}

	// Initiate graceful shutdown
	logger.Info().Msg("shutting down...")
	cancel()

	shutdownCtx, shutdownCancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer shutdownCancel()

	if err := httpServer.Shutdown(shutdownCtx); err != nil {
		logger.Error().Err(err).Msg("HTTP shutdown error")
	}

	logger.Info().Msg("auth-service stopped")
}

func newFraudEvaluator(cfg *config.Config) (port.FraudEvaluator, error) {
	if cfg == nil || !cfg.AntiFraud.Enabled {
		return nil, nil
	}
	return fraudadapter.NewHTTPClient(
		cfg.AntiFraud.BaseURL,
		cfg.AntiFraud.InternalServiceToken,
		cfg.AntiFraud.SignalHashKey,
		cfg.AntiFraud.Timeout,
	)
}

func newSwitchesClient(cfg *config.Config, logger zerolog.Logger) *switchesadapter.Client {
	if cfg == nil || !cfg.Switches.Enabled() {
		logger.Warn().Msg("switches-service client is disabled; feature flags and tech breaks are not enforced")
		return nil
	}
	client, err := switchesadapter.NewHTTPClient(cfg.Switches, logger)
	if err != nil {
		logger.Error().Err(err).Msg("failed to create switches-service client")
		return nil
	}
	logger.Info().
		Str("base_url", cfg.Switches.BaseURL).
		Dur("timeout", cfg.Switches.Timeout).
		Msg("switches-service client initialized")
	return client
}
