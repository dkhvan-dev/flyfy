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

type MessageHandler func(evt event.Event)

type Consumer struct {
	js       jetstream.JetStream
	nc       *nats.Conn
	consumer jetstream.Consumer
	cancel   context.CancelFunc
}

func NewConsumer(nc *nats.Conn, instanceID string, handler MessageHandler) (*Consumer, error) {
	js, err := jetstream.New(nc)
	if err != nil {
		return nil, fmt.Errorf("create jetstream context: %w", err)
	}

	stream, err := js.Stream(context.Background(), "CHAT")
	if err != nil {
		return nil, fmt.Errorf("get CHAT stream: %w", err)
	}

	consumerName := fmt.Sprintf("chat-ws-%s", instanceID)
	cons, err := stream.CreateOrUpdateConsumer(context.Background(), jetstream.ConsumerConfig{
		Name:          consumerName,
		Durable:       consumerName,
		FilterSubject: "chat.>",
		AckPolicy:     jetstream.AckExplicitPolicy,
	})
	if err != nil {
		return nil, fmt.Errorf("create consumer %s: %w", consumerName, err)
	}

	ctx, cancel := context.WithCancel(context.Background())

	c := &Consumer{
		js:       js,
		nc:       nc,
		consumer: cons,
		cancel:   cancel,
	}

	go c.consume(ctx, handler)
	log.Info().Str("consumer", consumerName).Msg("NATS consumer started")
	return c, nil
}

func (c *Consumer) consume(ctx context.Context, handler MessageHandler) {
	for {
		select {
		case <-ctx.Done():
			return
		default:
		}

		msgs, err := c.consumer.Fetch(10, jetstream.FetchMaxWait(5e9))
		if err != nil {
			if ctx.Err() != nil {
				return
			}
			continue
		}

		for msg := range msgs.Messages() {
			var evt event.Event
			if err := json.Unmarshal(msg.Data(), &evt); err != nil {
				log.Error().Err(err).Msg("unmarshal NATS event")
				_ = msg.Nak()
				continue
			}

			handler(evt)
			_ = msg.Ack()
		}
	}
}

func (c *Consumer) Stop() {
	c.cancel()
}
