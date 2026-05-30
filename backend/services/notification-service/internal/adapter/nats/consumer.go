package nats

import (
	"context"
	"encoding/json"
	"fmt"
	"sync"
	"time"

	"github.com/google/uuid"
	"github.com/nats-io/nats.go"
	"github.com/nats-io/nats.go/jetstream"
	"github.com/rs/zerolog/log"

	"kz/inflap/backend/services/notification-service/internal/domain/model"
)

type FanoutHandler func(ctx context.Context, requestID uuid.UUID) error
type DeliveryHandler func(ctx context.Context, deliveryID uuid.UUID) error

type ConsumerConfig struct {
	BatchSize           int
	FanoutConcurrency   int
	DeliveryConcurrency int
	MaxDeliver          int
	MaxAckPending       int
	AckWait             time.Duration
	NakDelay            time.Duration
	FetchMaxWait        time.Duration
}

type ConsumerGroup struct {
	cancel context.CancelFunc
}

func NewConsumerGroup(
	nc *nats.Conn,
	instanceID string,
	fanoutHandler FanoutHandler,
	deliveryHandler DeliveryHandler,
	cfg ConsumerConfig,
) (*ConsumerGroup, error) {
	cfg = normalizeConsumerConfig(cfg)
	js, err := jetstream.New(nc)
	if err != nil {
		return nil, fmt.Errorf("create jetstream context: %w", err)
	}
	stream, err := js.Stream(context.Background(), "NOTIFICATIONS")
	if err != nil {
		return nil, fmt.Errorf("get NOTIFICATIONS stream: %w", err)
	}

	ctx, cancel := context.WithCancel(context.Background())
	group := &ConsumerGroup{cancel: cancel}

	fanoutConsumer, err := stream.CreateOrUpdateConsumer(context.Background(), jetstream.ConsumerConfig{
		Name:          "notification-fanout",
		Durable:       "notification-fanout",
		FilterSubject: "notifications.requested",
		AckPolicy:     jetstream.AckExplicitPolicy,
		AckWait:       cfg.AckWait,
		MaxDeliver:    cfg.MaxDeliver,
		MaxAckPending: cfg.MaxAckPending,
	})
	if err != nil {
		cancel()
		return nil, fmt.Errorf("create fanout consumer: %w", err)
	}
	go consumeFanout(ctx, nc, fanoutConsumer, fanoutHandler, cfg)

	deliveryConsumer, err := stream.CreateOrUpdateConsumer(context.Background(), jetstream.ConsumerConfig{
		Name:          "notification-delivery",
		Durable:       "notification-delivery",
		FilterSubject: "notifications.delivery.>",
		AckPolicy:     jetstream.AckExplicitPolicy,
		AckWait:       cfg.AckWait,
		MaxDeliver:    cfg.MaxDeliver,
		MaxAckPending: cfg.MaxAckPending,
	})
	if err != nil {
		cancel()
		return nil, fmt.Errorf("create delivery consumer: %w", err)
	}
	go consumeDelivery(ctx, nc, deliveryConsumer, deliveryHandler, cfg)

	log.Info().Str("instance_id", instanceID).Msg("NATS notification consumers started")
	return group, nil
}

func (c *ConsumerGroup) Stop() {
	if c != nil && c.cancel != nil {
		c.cancel()
	}
}

func consumeFanout(
	ctx context.Context,
	nc *nats.Conn,
	consumer jetstream.Consumer,
	handler FanoutHandler,
	cfg ConsumerConfig,
) {
	consumeMessages(ctx, consumer, cfg.BatchSize, cfg.FetchMaxWait, cfg.FanoutConcurrency, func(msg jetstream.Msg) {
		handleFanoutMessage(ctx, nc, msg, handler, cfg)
	})
}

func consumeDelivery(
	ctx context.Context,
	nc *nats.Conn,
	consumer jetstream.Consumer,
	handler DeliveryHandler,
	cfg ConsumerConfig,
) {
	consumeMessages(ctx, consumer, cfg.BatchSize, cfg.FetchMaxWait, cfg.DeliveryConcurrency, func(msg jetstream.Msg) {
		handleDeliveryMessage(ctx, nc, msg, handler, cfg)
	})
}

func consumeMessages(
	ctx context.Context,
	consumer jetstream.Consumer,
	batchSize int,
	fetchMaxWait time.Duration,
	concurrency int,
	handle func(jetstream.Msg),
) {
	sem := make(chan struct{}, concurrency)
	var wg sync.WaitGroup
	defer wg.Wait()

	for {
		if ctx.Err() != nil {
			return
		}
		msgs, err := consumer.Fetch(batchSize, jetstream.FetchMaxWait(fetchMaxWait))
		if err != nil {
			if ctx.Err() != nil {
				return
			}
			continue
		}
		for msg := range msgs.Messages() {
			select {
			case <-ctx.Done():
				return
			case sem <- struct{}{}:
			}
			wg.Add(1)
			go func() {
				defer wg.Done()
				defer func() { <-sem }()
				handle(msg)
			}()
		}
	}
}

func handleFanoutMessage(
	ctx context.Context,
	nc *nats.Conn,
	msg jetstream.Msg,
	handler FanoutHandler,
	cfg ConsumerConfig,
) {
	var request model.NotificationRequest
	if err := json.Unmarshal(msg.Data(), &request); err != nil {
		log.Error().Err(err).Msg("unmarshal notification request")
		_ = publishToDLQ(nc, "notifications.dlq.fanout.invalid", msg.Data())
		_ = msg.Term()
		return
	}
	if err := handler(ctx, request.ID); err != nil {
		log.Error().Err(err).Str("request_id", request.ID.String()).Msg("fanout notification request")
		nakOrDLQ(nc, msg, "notifications.dlq.fanout.failed", cfg, err)
		return
	}
	_ = msg.Ack()
}

func handleDeliveryMessage(
	ctx context.Context,
	nc *nats.Conn,
	msg jetstream.Msg,
	handler DeliveryHandler,
	cfg ConsumerConfig,
) {
	var delivery model.Delivery
	if err := json.Unmarshal(msg.Data(), &delivery); err != nil {
		log.Error().Err(err).Msg("unmarshal notification delivery")
		_ = publishToDLQ(nc, "notifications.dlq.delivery.invalid", msg.Data())
		_ = msg.Term()
		return
	}
	if err := handler(ctx, delivery.ID); err != nil {
		log.Error().Err(err).Str("delivery_id", delivery.ID.String()).Msg("deliver notification")
		nakOrDLQ(nc, msg, "notifications.dlq.delivery.failed", cfg, err)
		return
	}
	_ = msg.Ack()
}

func nakOrDLQ(nc *nats.Conn, msg jetstream.Msg, dlqSubject string, cfg ConsumerConfig, cause error) {
	if shouldTerminate(msg, cfg.MaxDeliver) {
		log.Error().Err(cause).Str("subject", msg.Subject()).Msg("notification message exhausted retries")
		_ = publishToDLQ(nc, dlqSubject, msg.Data())
		_ = msg.Term()
		return
	}
	_ = msg.NakWithDelay(cfg.NakDelay)
}

func shouldTerminate(msg jetstream.Msg, maxDeliver int) bool {
	metadata, err := msg.Metadata()
	if err != nil {
		return false
	}
	return maxDeliver > 0 && metadata.NumDelivered >= uint64(maxDeliver)
}

func publishToDLQ(nc *nats.Conn, subject string, data []byte) error {
	if nc == nil {
		return nil
	}
	return nc.Publish(subject, data)
}

func normalizeConsumerConfig(cfg ConsumerConfig) ConsumerConfig {
	if cfg.BatchSize <= 0 {
		cfg.BatchSize = 500
	}
	if cfg.FanoutConcurrency <= 0 {
		cfg.FanoutConcurrency = 8
	}
	if cfg.DeliveryConcurrency <= 0 {
		cfg.DeliveryConcurrency = 64
	}
	if cfg.MaxDeliver <= 0 {
		cfg.MaxDeliver = 10
	}
	if cfg.MaxAckPending <= 0 {
		cfg.MaxAckPending = 8192
	}
	if cfg.AckWait <= 0 {
		cfg.AckWait = 30 * time.Second
	}
	if cfg.NakDelay <= 0 {
		cfg.NakDelay = time.Second
	}
	if cfg.FetchMaxWait <= 0 {
		cfg.FetchMaxWait = 500 * time.Millisecond
	}
	return cfg
}
