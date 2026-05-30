package nats

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/nats-io/nats.go"
	"github.com/nats-io/nats.go/jetstream"
	"github.com/rs/zerolog/log"
)

type Publisher struct {
	js jetstream.JetStream
}

func NewPublisher(nc *nats.Conn, streamMaxBytes int64) (*Publisher, error) {
	if streamMaxBytes <= 0 {
		streamMaxBytes = 512 * 1024 * 1024
	}
	js, err := jetstream.New(nc)
	if err != nil {
		return nil, fmt.Errorf("create jetstream context: %w", err)
	}

	_, err = js.CreateOrUpdateStream(context.Background(), jetstream.StreamConfig{
		Name:       "NOTIFICATIONS",
		Subjects:   []string{"notifications.>"},
		Storage:    jetstream.FileStorage,
		Retention:  jetstream.LimitsPolicy,
		MaxAge:     14 * 24 * time.Hour,
		MaxBytes:   streamMaxBytes,
		Discard:    jetstream.DiscardOld,
		Duplicates: 10 * time.Minute,
	})
	if err != nil {
		return nil, fmt.Errorf("create/update NOTIFICATIONS stream: %w", err)
	}

	log.Info().Msg("NATS JetStream NOTIFICATIONS stream ready")
	return &Publisher{js: js}, nil
}

func (p *Publisher) Publish(ctx context.Context, subject string, payload any, messageID string) error {
	data, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("marshal notification event: %w", err)
	}
	opts := []jetstream.PublishOpt{}
	if messageID != "" {
		opts = append(opts, jetstream.WithMsgID(messageID))
	}
	if _, err = p.js.Publish(ctx, subject, data, opts...); err != nil {
		return fmt.Errorf("publish notification event to %s: %w", subject, err)
	}
	return nil
}

func (p *Publisher) Close() error {
	return nil
}
