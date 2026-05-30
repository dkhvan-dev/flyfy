package main

import (
	"context"
	"errors"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/nats-io/nats.go"
	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"

	httpadapter "kz/inflap/backend/services/notification-service/internal/adapter/http"
	natsadapter "kz/inflap/backend/services/notification-service/internal/adapter/nats"
	"kz/inflap/backend/services/notification-service/internal/adapter/provider"
	"kz/inflap/backend/services/notification-service/internal/adapter/repository"
	"kz/inflap/backend/services/notification-service/internal/app"
	"kz/inflap/backend/services/notification-service/internal/config"
	"kz/inflap/backend/services/notification-service/internal/domain/model"
)

func main() {
	ctx := context.Background()

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

	tokenProtector, err := app.NewTokenProtectorFromBase64(
		cfg.Security.TokenEncryptionKeyBase64,
		cfg.Security.TokenHashKeyBase64,
	)
	if err != nil {
		log.Fatal().Err(err).Msg("initialize token protector")
	}

	nc, err := nats.Connect(cfg.NATS.URL)
	if err != nil {
		log.Fatal().Err(err).Msg("connect nats")
	}
	defer nc.Close()

	publisher, err := natsadapter.NewPublisher(nc, cfg.NATS.StreamMaxBytes)
	if err != nil {
		log.Fatal().Err(err).Msg("initialize notification publisher")
	}

	repo := repository.NewPGNotificationRepository(pool, tokenProtector)
	providers, err := buildProviders(cfg)
	if err != nil {
		log.Fatal().Err(err).Msg("initialize push providers")
	}
	notificationUseCase := app.NewNotificationUseCase(repo, publisher, providers)

	var consumerGroup *natsadapter.ConsumerGroup
	var stopRetryScheduler context.CancelFunc
	if cfg.Workers.Enabled {
		instanceID := uuid.NewString()[:8]
		consumerGroup, err = natsadapter.NewConsumerGroup(
			nc,
			instanceID,
			func(ctx context.Context, requestID uuid.UUID) error {
				_, err := notificationUseCase.FanoutRequest(ctx, requestID)
				return err
			},
			notificationUseCase.DeliverNotification,
			natsadapter.ConsumerConfig{
				BatchSize:           cfg.NATS.BatchSize,
				FanoutConcurrency:   cfg.NATS.FanoutConcurrency,
				DeliveryConcurrency: cfg.NATS.DeliveryConcurrency,
				MaxDeliver:          cfg.NATS.MaxDeliver,
				MaxAckPending:       cfg.NATS.MaxAckPending,
				AckWait:             cfg.NATS.AckWait,
				NakDelay:            cfg.NATS.NakDelay,
				FetchMaxWait:        cfg.NATS.FetchMaxWait,
			},
		)
		if err != nil {
			log.Fatal().Err(err).Msg("initialize notification consumers")
		}
		defer consumerGroup.Stop()

		retryCtx, cancel := context.WithCancel(context.Background())
		stopRetryScheduler = cancel
		defer stopRetryScheduler()
		go runRetryScheduler(retryCtx, notificationUseCase, cfg.Workers.RetryScanInterval, cfg.Workers.RetryScanBatchSize)
	}

	mux := http.NewServeMux()
	handler := httpadapter.NewHandler(notificationUseCase, cfg.Security.InternalServiceToken)
	handler.Register(mux)

	server := &http.Server{
		Addr: cfg.HTTP.Address(),
		Handler: httpadapter.Chain(httpadapter.MiddlewareConfig{
			RequestIDHeader:            cfg.Security.RequestIDHeader,
			TrustedGatewayHeaderUserID: cfg.Security.TrustedGatewayHeaderUserID,
			TrustedGatewayHeaderRoles:  cfg.Security.TrustedGatewayHeaderRoles,
			TrustedGatewayHeaderSub:    cfg.Security.TrustedGatewayHeaderSub,
		}, mux),
		ReadTimeout:  cfg.HTTP.ReadTimeout,
		WriteTimeout: cfg.HTTP.WriteTimeout,
		IdleTimeout:  cfg.HTTP.IdleTimeout,
	}

	errCh := make(chan error, 1)
	go func() {
		log.Info().Str("service", cfg.App.Name).Int("port", cfg.HTTP.Port).Msg("HTTP server started")
		if err := server.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
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
			log.Fatal().Err(err).Msg("HTTP server failed")
		}
	}

	shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if err := server.Shutdown(shutdownCtx); err != nil {
		log.Error().Err(err).Msg("HTTP shutdown failed")
	}
	log.Info().Str("service", cfg.App.Name).Msg("service stopped")
}

func buildProviders(cfg *config.Config) (map[model.Provider]app.PushProvider, error) {
	providers := map[model.Provider]app.PushProvider{
		model.ProviderFCM:  provider.DisabledProvider{Name: model.ProviderFCM},
		model.ProviderAPNS: provider.DisabledProvider{Name: model.ProviderAPNS},
		model.ProviderHMS:  provider.DisabledProvider{Name: model.ProviderHMS},
	}

	if cfg.Providers.FCM.Enabled {
		fcmProvider, err := provider.NewFCMProvider(provider.FCMConfig{
			Enabled:                cfg.Providers.FCM.Enabled,
			ProjectID:              cfg.Providers.FCM.ProjectID,
			ServiceAccountJSONPath: cfg.Providers.FCM.ServiceAccountJSONPath,
			TokenURL:               cfg.Providers.FCM.TokenURL,
			Timeout:                cfg.Providers.FCM.Timeout,
		})
		if err != nil {
			return nil, err
		}
		providers[model.ProviderFCM] = fcmProvider
	}

	if cfg.Providers.APNS.Enabled {
		apnsProvider, err := provider.NewAPNSProvider(provider.APNSConfig{
			Enabled:            cfg.Providers.APNS.Enabled,
			DefaultEnvironment: apnsEnvironment(cfg.Providers.APNS.Environment),
			TeamID:             cfg.Providers.APNS.TeamID,
			KeyID:              cfg.Providers.APNS.KeyID,
			BundleID:           cfg.Providers.APNS.BundleID,
			AuthKeyPath:        cfg.Providers.APNS.AuthKeyPath,
			Timeout:            cfg.Providers.APNS.Timeout,
		})
		if err != nil {
			return nil, err
		}
		providers[model.ProviderAPNS] = apnsProvider
	}

	if cfg.Providers.HMS.Enabled {
		hmsProvider, err := provider.NewHMSProvider(provider.HMSConfig{
			Enabled:      cfg.Providers.HMS.Enabled,
			AppID:        cfg.Providers.HMS.AppID,
			ClientID:     cfg.Providers.HMS.ClientID,
			ClientSecret: cfg.Providers.HMS.ClientSecret,
			TokenURL:     cfg.Providers.HMS.TokenURL,
			SendURL:      cfg.Providers.HMS.SendURL,
			Timeout:      cfg.Providers.HMS.Timeout,
		})
		if err != nil {
			return nil, err
		}
		providers[model.ProviderHMS] = hmsProvider
	}

	return providers, nil
}

func apnsEnvironment(value string) model.Environment {
	if value == string(model.EnvironmentProduction) {
		return model.EnvironmentProduction
	}
	return model.EnvironmentSandbox
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

func runRetryScheduler(
	ctx context.Context,
	notificationUseCase *app.NotificationUseCase,
	interval time.Duration,
	batchSize int,
) {
	ticker := time.NewTicker(interval)
	defer ticker.Stop()
	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			published, err := notificationUseCase.PublishDueDeliveries(ctx, batchSize)
			if err != nil {
				log.Error().Err(err).Msg("publish due notification deliveries")
				continue
			}
			if published > 0 {
				log.Info().Int("published", published).Msg("due notification deliveries requeued")
			}
		}
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
