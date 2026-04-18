package nats

import (
	"context"
	"encoding/json"
	"fmt"

	"github.com/nats-io/nats.go"
	"github.com/nats-io/nats.go/jetstream"
	"github.com/rs/zerolog/log"

	"github.com/dkhvan-dev/flyfy/backend/services/chat-service/internal/event"
)

type Publisher struct {
	js jetstream.JetStream
}

func NewPublisher(nc *nats.Conn) (*Publisher, error) {
	js, err := jetstream.New(nc)
	if err != nil {
		return nil, fmt.Errorf("create jetstream context: %w", err)
	}

	_, err = js.CreateOrUpdateStream(context.Background(), jetstream.StreamConfig{
		Name:       "CHAT",
		Subjects:   []string{"chat.>"},
		Storage:    jetstream.FileStorage,
		Retention:  jetstream.LimitsPolicy,
		MaxAge:     7 * 24 * 60 * 60 * 1e9,
		MaxBytes:   10 * 1024 * 1024 * 1024,
		Discard:    jetstream.DiscardOld,
		Duplicates: 2 * 60 * 1e9,
	})
	if err != nil {
		return nil, fmt.Errorf("create/update CHAT stream: %w", err)
	}

	log.Info().Msg("NATS JetStream CHAT stream ready")
	return &Publisher{js: js}, nil
}

func (p *Publisher) Publish(ctx context.Context, subject string, evt event.Event) error {
	data, err := json.Marshal(evt)
	if err != nil {
		return fmt.Errorf("marshal event: %w", err)
	}

	opts := []jetstream.PublishOpt{
		jetstream.WithMsgID(evt.EventID.String()),
	}

	_, err = p.js.Publish(ctx, subject, data, opts...)
	if err != nil {
		return fmt.Errorf("publish to %s: %w", subject, err)
	}
	return nil
}

func (p *Publisher) Close() error {
	return nil
}
