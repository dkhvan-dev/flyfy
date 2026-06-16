package main

import (
	"context"
	"net"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"
	"google.golang.org/grpc"
	feedserviceadapter "kz/inflap/backend/services/user-service/internal/adapter/feedservice"
	grpcadapter "kz/inflap/backend/services/user-service/internal/adapter/grpc"
	httpadapter "kz/inflap/backend/services/user-service/internal/adapter/http"
	phoneadapter "kz/inflap/backend/services/user-service/internal/adapter/phone"
	"kz/inflap/backend/services/user-service/internal/adapter/repository"
	"kz/inflap/backend/services/user-service/internal/app"
	"kz/inflap/backend/services/user-service/internal/config"

	filemanageradapter "kz/inflap/backend/services/user-service/internal/adapter/filemanager"
	userv1 "kz/inflap/proto/gen/go/user/v1"
)

func main() {
	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	cfg, err := config.Load(ctx)
	if err != nil {
		panic(err)
	}

	setupLogger(cfg)

	log.Info().
		Str("env", cfg.App.Env).
		Msg("starting user-service")

	pool, err := newPostgresPool(ctx, cfg)
	if err != nil {
		log.Fatal().Err(err).Msg("failed to initialize postgres pool")
	}
	defer pool.Close()

	fileManagerClient, err := filemanageradapter.New(
		cfg.FileManager.Target,
		cfg.Security.InternalServiceToken,
		"user-service",
	)
	if err != nil {
		log.Fatal().Err(err).Msg("failed to initialize file-manager grpc client")
	}
	defer fileManagerClient.Close()

	userRepo := repository.NewPGUserRepository(pool)
	userUseCase := app.NewUserUseCase(userRepo, fileManagerClient)
	var feedServiceClient *feedserviceadapter.Client
	if cfg.Social.WorkerEnabled || cfg.Social.StartupDrainEnabled {
		feedServiceClient = feedserviceadapter.New(
			cfg.FeedService.HTTPURL,
			cfg.Security.InternalServiceToken,
			"user-service",
			cfg.FeedService.RequestTimeout,
		)
	}
	if cfg.Social.StartupBackfillEnabled {
		stats, reconcileErr := app.ReconcileUserSocialOutbox(
			ctx,
			userRepo,
			feedServiceClient,
			app.UserSocialOutboxReconcilerConfig{
				BackfillEnabled: true,
				DrainEnabled:    cfg.Social.StartupDrainEnabled,
				MaxDrainBatches: cfg.Social.StartupMaxDrainBatches,
				WorkerConfig: app.UserSocialOutboxWorkerConfig{
					PollInterval: cfg.Social.WorkerPollInterval,
					BatchSize:    cfg.Social.WorkerBatchSize,
					MaxAttempts:  cfg.Social.WorkerMaxAttempts,
					BaseBackoff:  cfg.Social.WorkerBaseBackoff,
				},
			},
			time.Now().UTC(),
		)
		if reconcileErr != nil {
			log.Fatal().Err(reconcileErr).Msg("failed to reconcile feed social outbox")
		}
		log.Info().
			Int64("backfilled_events", stats.Backfilled).
			Int("drained_events", stats.Drained).
			Int("drain_batches", stats.DrainBatches).
			Msg("feed social outbox startup reconciliation completed")
	}
	if cfg.Social.WorkerEnabled {
		socialOutboxWorker := app.NewUserSocialOutboxWorker(
			userRepo,
			feedServiceClient,
			app.UserSocialOutboxWorkerConfig{
				PollInterval: cfg.Social.WorkerPollInterval,
				BatchSize:    cfg.Social.WorkerBatchSize,
				MaxAttempts:  cfg.Social.WorkerMaxAttempts,
				BaseBackoff:  cfg.Social.WorkerBaseBackoff,
			},
		)
		go socialOutboxWorker.Start(ctx)
		log.Info().Msg("user social outbox worker started")
	}
	if cfg.Phone.Provider != "log" {
		log.Fatal().
			Str("provider", cfg.Phone.Provider).
			Msg("unsupported PHONE_VERIFICATION_PROVIDER")
	}
	if cfg.App.IsProduction() && cfg.Phone.Provider == "log" {
		log.Fatal().Msg("PHONE_VERIFICATION_PROVIDER=log is not allowed in production")
	}
	if cfg.App.IsProduction() && cfg.Phone.CodeHashSecret == "" {
		log.Fatal().Msg("PHONE_VERIFICATION_CODE_HASH_SECRET is required in production")
	}
	if cfg.App.IsProduction() && cfg.Phone.DevelopmentStaticCode != "" {
		log.Fatal().Msg("PHONE_VERIFICATION_DEV_STATIC_CODE is not allowed in production")
	}
	phoneVerificationUseCase := app.NewPhoneVerificationUseCase(
		userRepo,
		phoneadapter.NewLogSender(cfg.App.Env),
		app.PhoneVerificationConfig{
			CodeLength:            cfg.Phone.CodeLength,
			CodeTTL:               cfg.Phone.CodeTTL,
			ResendCooldown:        cfg.Phone.ResendCooldown,
			MaxVerifyAttempts:     cfg.Phone.MaxVerifyAttempts,
			CodeHashSecret:        cfg.Phone.CodeHashSecret,
			DevelopmentStaticCode: cfg.Phone.DevelopmentStaticCode,
		},
	)

	httpHandler := httpadapter.NewHandler(userUseCase, phoneVerificationUseCase)
	httpMux := http.NewServeMux()
	httpHandler.Register(httpMux)

	httpServer := &http.Server{
		Addr:         cfg.HTTP.Address(),
		Handler:      httpadapter.Chain(cfg, withRequestLogging(httpMux)),
		ReadTimeout:  cfg.HTTP.ReadTimeout,
		WriteTimeout: cfg.HTTP.WriteTimeout,
		IdleTimeout:  cfg.HTTP.IdleTimeout,
	}

	grpcLis, err := net.Listen("tcp", cfg.GRPC.Address())
	if err != nil {
		log.Fatal().Err(err).Msg("failed to listen grpc")
	}

	grpcServer := grpc.NewServer(
		grpc.UnaryInterceptor(grpcadapter.UnaryServerInterceptor(cfg)),
	)

	userGRPCServer := grpcadapter.NewServer(userUseCase)
	userv1.RegisterUserServiceServer(grpcServer, userGRPCServer)

	go func() {
		log.Info().
			Str("address", cfg.HTTP.Address()).
			Msg("http server started")

		if err = httpServer.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatal().Err(err).Msg("http server failed")
		}
	}()

	go func() {
		log.Info().
			Str("address", cfg.GRPC.Address()).
			Msg("grpc server started")

		if err = grpcServer.Serve(grpcLis); err != nil {
			log.Fatal().Err(err).Msg("grpc server failed")
		}
	}()

	<-ctx.Done()
	log.Info().Msg("shutdown signal received")

	shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	grpcServer.GracefulStop()

	if err = httpServer.Shutdown(shutdownCtx); err != nil {
		log.Error().Err(err).Msg("http server shutdown failed")
	} else {
		log.Info().Msg("http server stopped")
	}
}

func newPostgresPool(ctx context.Context, cfg *config.Config) (*pgxpool.Pool, error) {
	poolConfig, err := pgxpool.ParseConfig(cfg.Postgres.DSN())
	if err != nil {
		return nil, err
	}

	poolConfig.MaxConns = cfg.Postgres.MaxOpenConns
	poolConfig.MinConns = cfg.Postgres.MinOpenConns
	poolConfig.MaxConnLifetime = cfg.Postgres.ParsedMaxConnLifetime()
	poolConfig.MaxConnIdleTime = cfg.Postgres.ParsedMaxConnIdleTime()

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

func setupLogger(cfg *config.Config) {
	level, err := zerolog.ParseLevel(cfg.Log.Level)
	if err != nil {
		level = zerolog.InfoLevel
	}

	zerolog.SetGlobalLevel(level)

	if cfg.App.IsProduction() {
		log.Logger = zerolog.New(os.Stdout).With().Timestamp().Logger()
		return
	}

	log.Logger = zerolog.New(zerolog.ConsoleWriter{
		Out:        os.Stdout,
		TimeFormat: time.RFC3339,
	}).With().Timestamp().Logger()
}

func withRequestLogging(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		startedAt := time.Now()

		rw := &responseWriter{
			ResponseWriter: w,
			statusCode:     http.StatusOK,
		}

		next.ServeHTTP(rw, r)

		log.Info().
			Str("method", r.Method).
			Str("path", r.URL.Path).
			Int("status", rw.statusCode).
			Dur("duration", time.Since(startedAt)).
			Msg("http request handled")
	})
}

type responseWriter struct {
	http.ResponseWriter
	statusCode int
}

func (rw *responseWriter) WriteHeader(statusCode int) {
	rw.statusCode = statusCode
	rw.ResponseWriter.WriteHeader(statusCode)
}
