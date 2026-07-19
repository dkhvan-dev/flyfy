package natsadapter

import (
	"context"
	"errors"
	"fmt"
	"time"

	gonats "github.com/nats-io/nats.go"
	"github.com/nats-io/nats.go/jetstream"
)

const (
	SavedSourceSubjectPattern  = "saved.source.>"
	savedSourceStreamMaxAge    = 14 * 24 * time.Hour
	savedSourceStreamMaxBytes  = int64(4 * 1024 * 1024 * 1024)
	savedSourceDuplicateWindow = 10 * time.Minute
)

type savedSourceStreamManager interface {
	CreateOrUpdateStream(context.Context, jetstream.StreamConfig) (jetstream.Stream, error)
}

// EnsureSavedSourceStream makes Saved startup independent from producer
// startup order. Every producer uses the same canonical stream contract.
func EnsureSavedSourceStream(
	ctx context.Context,
	connection *gonats.Conn,
	replicas int,
) error {
	if ctx == nil || connection == nil || connection.IsClosed() {
		return errors.New("Saved source stream dependencies are unavailable")
	}
	if replicas != 1 && replicas != 3 && replicas != 5 {
		return errors.New("Saved source stream replicas must be 1, 3, or 5")
	}
	js, err := jetstream.New(connection)
	if err != nil {
		return fmt.Errorf("create Saved source JetStream context: %w", err)
	}
	if err = ensureSavedSourceStream(ctx, js, savedSourceStreamConfig(replicas)); err != nil {
		return fmt.Errorf("create or update Saved source stream: %w", err)
	}
	return nil
}

func ensureSavedSourceStream(
	ctx context.Context,
	manager savedSourceStreamManager,
	config jetstream.StreamConfig,
) error {
	_, err := manager.CreateOrUpdateStream(ctx, config)
	if errors.Is(err, jetstream.ErrStreamNameAlreadyInUse) {
		// CreateOrUpdate performs update-then-create. A concurrent producer may
		// create the stream between those requests, so retry through update.
		_, err = manager.CreateOrUpdateStream(ctx, config)
	}
	return err
}

func savedSourceStreamConfig(replicas int) jetstream.StreamConfig {
	return jetstream.StreamConfig{
		Name:       SavedSourceStreamName,
		Subjects:   []string{SavedSourceSubjectPattern},
		Storage:    jetstream.FileStorage,
		Retention:  jetstream.LimitsPolicy,
		MaxAge:     savedSourceStreamMaxAge,
		MaxBytes:   savedSourceStreamMaxBytes,
		Discard:    jetstream.DiscardOld,
		Duplicates: savedSourceDuplicateWindow,
		Replicas:   replicas,
	}
}
