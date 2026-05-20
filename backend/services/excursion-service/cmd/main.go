package main

import (
	"context"
	"net/http"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"

	attractionadapter "github.com/dkhvan-dev/flyfy/backend/services/excursion-service/internal/adapter/attraction"
	chatadapter "github.com/dkhvan-dev/flyfy/backend/services/excursion-service/internal/adapter/chat"
	filemanageradapter "github.com/dkhvan-dev/flyfy/backend/services/excursion-service/internal/adapter/filemanager"
	grpcadapter "github.com/dkhvan-dev/flyfy/backend/services/excursion-service/internal/adapter/grpc"
	guideadapter "github.com/dkhvan-dev/flyfy/backend/services/excursion-service/internal/adapter/guide"
	httpadapter "github.com/dkhvan-dev/flyfy/backend/services/excursion-service/internal/adapter/http"
	"github.com/dkhvan-dev/flyfy/backend/services/excursion-service/internal/adapter/repository"
	translationadapter "github.com/dkhvan-dev/flyfy/backend/services/excursion-service/internal/adapter/translation"
	userserviceadapter "github.com/dkhvan-dev/flyfy/backend/services/excursion-service/internal/adapter/userservice"
	"github.com/dkhvan-dev/flyfy/backend/services/excursion-service/internal/app"
	"github.com/dkhvan-dev/flyfy/backend/services/excursion-service/internal/config"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
)

func main() {
	ctx := context.Background()
	cfg, err := config.Load(ctx)
	if err != nil {
		log.Fatal().Err(err).Msg("load config")
	}
	configureLogger(cfg)
	validateSecurityConfig(cfg)

	pool, err := newPostgresPool(ctx, cfg)
	if err != nil {
		log.Fatal().Err(err).Msg("initialize postgres")
	}
	defer pool.Close()
	if err = pool.Ping(ctx); err != nil {
		log.Fatal().Err(err).Msg("ping postgres")
	}

	repo := repository.NewPGExcursionRepository(pool)
	guideClient, err := guideadapter.New(
		cfg.GuideService.Target,
		grpc.WithTransportCredentials(insecure.NewCredentials()),
		grpc.WithUnaryInterceptor(grpcadapter.InternalTokenInterceptor(
			cfg.Security.InternalServiceToken,
			cfg.App.Name,
		)),
	)
	if err != nil {
		log.Fatal().Err(err).Msg("dial guide-service")
	}
	defer guideClient.Close()

	userClient, err := userserviceadapter.New(
		cfg.UserService.Target,
		cfg.Security.InternalServiceToken,
		cfg.App.Name,
		grpc.WithTransportCredentials(insecure.NewCredentials()),
	)
	if err != nil {
		log.Fatal().Err(err).Msg("dial user-service")
	}
	defer userClient.Close()

	fileManagerClient, err := filemanageradapter.New(
		cfg.FileManager.Target,
		grpc.WithTransportCredentials(insecure.NewCredentials()),
		grpc.WithUnaryInterceptor(grpcadapter.InternalTokenInterceptor(
			cfg.Security.InternalServiceToken,
			cfg.App.Name,
		)),
	)
	if err != nil {
		log.Fatal().Err(err).Msg("dial file-manager-service")
	}
	defer fileManagerClient.Close()

	translator := translationadapter.NewClient(
		cfg.Translation.BaseURL,
		cfg.Translation.Timeout,
		cfg.Security.InternalServiceToken,
	)
	attractionRatingClient := attractionadapter.NewClient(
		cfg.Attraction.BaseURL,
		cfg.Security.InternalServiceToken,
	)
	chatClient := chatadapter.New(
		cfg.ChatService.HTTPURL,
		cfg.Security.InternalServiceToken,
		cfg.ChatService.RequestTimeout,
	)
	excursionUC := app.NewExcursionUseCase(repo, guideClient, fileManagerClient, translator).
		WithUserProfileResolver(userClient).
		WithAttractionRatingUpdater(attractionRatingClient).
		WithExcursionChatGateway(chatClient).
		WithAttendanceQRConfig(
			cfg.Attendance.QRSigningSecret,
			cfg.Attendance.QRTTL,
			cfg.Attendance.OfflineWindow,
		)
	handler := httpadapter.NewHandler(excursionUC, fileManagerClient)

	mux := http.NewServeMux()
	handler.Register(mux)

	server := &http.Server{
		Addr:         cfg.HTTP.Address(),
		Handler:      httpadapter.Chain(cfg, mux),
		ReadTimeout:  cfg.HTTP.ReadTimeout,
		WriteTimeout: cfg.HTTP.WriteTimeout,
		IdleTimeout:  cfg.HTTP.IdleTimeout,
	}

	backgroundCtx, stopBackground := context.WithCancel(ctx)
	defer stopBackground()
	go runExcursionLifecycleTicker(backgroundCtx, excursionUC, cfg.Attendance)

	errCh := make(chan error, 1)
	go func() {
		log.Info().Str("service", cfg.App.Name).Int("port", cfg.HTTP.Port).Msg("HTTP server started")
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			errCh <- err
			return
		}
		errCh <- nil
	}()

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
	if err := server.Shutdown(shutdownCtx); err != nil {
		log.Error().Err(err).Msg("http shutdown failed")
	}
	log.Info().Str("service", cfg.App.Name).Msg("service stopped")
}

func runExcursionLifecycleTicker(
	ctx context.Context,
	uc *app.ExcursionUseCase,
	attendanceCfg config.AttendanceConfig,
) {
	interval := attendanceCfg.CompletionTickerInterval
	if interval <= 0 {
		interval = time.Minute
	}
	batchSize := attendanceCfg.CompletionBatchSize
	if batchSize <= 0 {
		batchSize = 100
	}

	ticker := time.NewTicker(interval)
	defer ticker.Stop()

	run := func() {
		closedCount, err := uc.AutoCloseBookedExcursionScheduleSlots(ctx, batchSize)
		if err != nil {
			log.Error().Err(err).Msg("auto-close booked excursion schedule slots failed")
			return
		}
		if closedCount > 0 {
			log.Info().Int("closed_slots", closedCount).Msg("auto-closed booked excursion schedule slots")
		}

		count, err := uc.AutoCompleteDueExcursionScheduleSlots(ctx, batchSize)
		if err != nil {
			log.Error().Err(err).Msg("auto-complete due excursion schedule slots failed")
			return
		}
		if count > 0 {
			log.Info().Int("completed_slots", count).Msg("auto-completed due excursion schedule slots")
		}
	}

	run()
	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			run()
		}
	}
}

func configureLogger(cfg *config.Config) {
	level, err := zerolog.ParseLevel(cfg.Log.Level)
	if err != nil {
		level = zerolog.InfoLevel
	}
	zerolog.SetGlobalLevel(level)
	log.Logger = log.Output(zerolog.ConsoleWriter{Out: os.Stderr, TimeFormat: time.RFC3339})
}

func validateSecurityConfig(cfg *config.Config) {
	if strings.EqualFold(cfg.App.Env, "production") &&
		strings.TrimSpace(cfg.Attendance.QRSigningSecret) == "" {
		log.Fatal().
			Str("env", "EXCURSION_ATTENDANCE_QR_SIGNING_SECRET").
			Msg("missing production excursion attendance QR signing secret")
	}
}

func newPostgresPool(ctx context.Context, cfg *config.Config) (*pgxpool.Pool, error) {
	poolCfg, err := pgxpool.ParseConfig(cfg.DB.DSN())
	if err != nil {
		return nil, err
	}
	poolCfg.MaxConns = cfg.DB.MaxConns
	poolCfg.MinConns = cfg.DB.MinConns
	poolCfg.MaxConnLifetime = cfg.DB.ParsedMaxConnLifetime()
	poolCfg.MaxConnIdleTime = cfg.DB.ParsedMaxConnIdleTime()
	return pgxpool.NewWithConfig(ctx, poolCfg)
}
