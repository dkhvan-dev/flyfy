package main

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"

	fraudadapter "github.com/dkhvan-dev/flyfy/backend/services/payment-service/internal/adapter/fraud"
	httpadapter "github.com/dkhvan-dev/flyfy/backend/services/payment-service/internal/adapter/http"
	mockprovider "github.com/dkhvan-dev/flyfy/backend/services/payment-service/internal/adapter/provider"
	"github.com/dkhvan-dev/flyfy/backend/services/payment-service/internal/adapter/repository"
	"github.com/dkhvan-dev/flyfy/backend/services/payment-service/internal/app"
	"github.com/dkhvan-dev/flyfy/backend/services/payment-service/internal/config"
	"github.com/dkhvan-dev/flyfy/backend/services/payment-service/internal/domain/port"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"
)

func main() {
	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	cfg, err := config.Load(ctx)
	if err != nil {
		panic(err)
	}

	setupLogger(cfg)
	log.Info().Str("service", cfg.App.Name).Str("env", cfg.App.Env).Msg("starting payment-service")

	pool, err := newPostgresPool(ctx, cfg)
	if err != nil {
		log.Fatal().Err(err).Msg("failed to initialize postgres pool")
	}
	defer pool.Close()

	repo := repository.NewPGPaymentRepository(pool)
	provider, err := newPaymentProvider(cfg)
	if err != nil {
		log.Fatal().Err(err).Msg("failed to initialize payment provider")
	}
	fraudClient, err := newFraudDecisionPort(cfg)
	if err != nil {
		log.Fatal().Err(err).Msg("failed to initialize anti-fraud client")
	}
	useCase := app.NewPaymentUseCaseWithFraud(repo, provider, fraudClient)

	handler := httpadapter.NewHandler(useCase)
	mux := http.NewServeMux()
	handler.Register(mux)

	server := &http.Server{
		Addr:         cfg.HTTP.Address(),
		Handler:      httpadapter.Chain(cfg, withRequestLogging(mux)),
		ReadTimeout:  cfg.HTTP.ReadTimeout,
		WriteTimeout: cfg.HTTP.WriteTimeout,
		IdleTimeout:  cfg.HTTP.IdleTimeout,
	}

	go func() {
		log.Info().Str("address", cfg.HTTP.Address()).Msg("http server started")
		if err = server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatal().Err(err).Msg("http server failed")
		}
	}()

	<-ctx.Done()
	log.Info().Msg("shutdown signal received")

	shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	if err = server.Shutdown(shutdownCtx); err != nil {
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

func newPaymentProvider(cfg *config.Config) (port.PaymentProvider, error) {
	switch strings.ToLower(strings.TrimSpace(cfg.Payment.Provider)) {
	case "", "mock":
		return mockprovider.NewMockProvider(), nil
	default:
		return nil, fmt.Errorf("unsupported payment provider %q", cfg.Payment.Provider)
	}
}

func newFraudDecisionPort(cfg *config.Config) (port.FraudDecisionPort, error) {
	if cfg == nil || !cfg.AntiFraud.Enabled {
		return nil, nil
	}
	return fraudadapter.NewHTTPClient(
		cfg.AntiFraud.BaseURL,
		cfg.AntiFraud.InternalServiceToken,
		cfg.AntiFraud.Timeout,
	)
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
