package natsadapter

import (
	"context"
	"errors"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"
	gonats "github.com/nats-io/nats.go"
	"github.com/nats-io/nats.go/jetstream"

	savedlifecycle "kz/inflap/backend/services/saved-service/internal/app/savedlifecycle"
)

const savedLifecycleNATSIntegrationURLEnv = "SAVED_SERVICE_LIFECYCLE_NATS_TEST_URL"

type integrationLifecycleIngestor struct {
	ingested chan savedlifecycle.Event
}

func (i *integrationLifecycleIngestor) Ingest(
	ctx context.Context,
	event savedlifecycle.Event,
) (savedlifecycle.Outcome, error) {
	select {
	case i.ingested <- event:
		return savedlifecycle.Outcome{
			Code:              savedlifecycle.OutcomeApplied,
			ProjectionApplied: true,
		}, nil
	case <-ctx.Done():
		return savedlifecycle.Outcome{}, ctx.Err()
	}
}

func (*integrationLifecycleIngestor) DeleteExpiredInbox(context.Context, int) (int64, error) {
	return 0, nil
}

func TestSavedLifecycleConsumerLiveJetStreamAckAndShutdown(t *testing.T) {
	url := strings.TrimSpace(os.Getenv(savedLifecycleNATSIntegrationURLEnv))
	if url == "" {
		t.Skip(savedLifecycleNATSIntegrationURLEnv + " is not set")
	}
	connection, err := gonats.Connect(url, gonats.Timeout(3*time.Second))
	if err != nil {
		t.Fatalf("connect NATS: %v", err)
	}
	defer connection.Close()
	js, err := jetstream.New(connection)
	if err != nil {
		t.Fatalf("create JetStream context: %v", err)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()
	binding := DefaultConsumerConfig().Bindings[0]
	suffix := strings.ReplaceAll(uuid.NewString(), "-", "")
	binding.Durable = "SAVED_LIFECYCLE_TEST_" + suffix
	streamName, streamErr := js.StreamNameBySubject(ctx, binding.Subject)
	if errors.Is(streamErr, jetstream.ErrStreamNotFound) {
		t.Skipf("canonical stream %s is not available", SavedSourceStreamName)
	}
	if streamErr != nil {
		t.Fatalf("resolve integration stream: %v", streamErr)
	}
	if streamName != SavedSourceStreamName {
		t.Fatalf("subject %s is owned by non-canonical stream %s", binding.Subject, streamName)
	}
	t.Cleanup(func() {
		cleanupCtx, cleanupCancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cleanupCancel()
		_ = js.DeleteConsumer(cleanupCtx, streamName, binding.Durable)
	})

	config := DefaultConsumerConfig()
	config.Bindings = []ConsumerBinding{binding}
	config.WorkersPerBinding = 1
	config.AckWait = 8 * time.Second
	config.ProcessTimeout = 2 * time.Second
	config.AckTimeout = time.Second
	config.ProvisionTimeout = 3 * time.Second
	config.CleanupInterval = time.Hour
	config.CleanupTimeout = time.Second
	ingestor := &integrationLifecycleIngestor{ingested: make(chan savedlifecycle.Event, 1)}
	observed := make(chan Observation, 8)
	consumer, err := NewSavedLifecycleConsumer(
		connection,
		ingestor,
		config,
		ObserverFunc(func(observation Observation) { observed <- observation }),
	)
	if err != nil {
		t.Fatalf("NewSavedLifecycleConsumer() error = %v", err)
	}
	runCtx, stop := context.WithCancel(context.Background())
	runDone := make(chan error, 1)
	go func() { runDone <- consumer.Run(runCtx) }()

	contract, _ := savedlifecycle.ContractForSubject(binding.Subject)
	payload := validLifecycleProtoPayload(t, contract, time.Now().UTC(), true)
	if _, err = js.Publish(ctx, binding.Subject, payload, jetstream.WithMsgID(uuid.NewString())); err != nil {
		stop()
		t.Fatalf("publish lifecycle event: %v", err)
	}
	select {
	case event := <-ingestor.ingested:
		if event.Subject != binding.Subject {
			t.Fatalf("ingested subject = %q", event.Subject)
		}
	case <-ctx.Done():
		stop()
		t.Fatal("timed out waiting for lifecycle ingestion")
	}

	acked := false
	for !acked {
		select {
		case observation := <-observed:
			acked = observation.Action == ObservationAck
		case <-ctx.Done():
			stop()
			t.Fatal("timed out waiting for durable ACK")
		}
	}
	stop()
	select {
	case runErr := <-runDone:
		if runErr != nil {
			t.Fatalf("Run() error = %v", runErr)
		}
	case <-time.After(3 * time.Second):
		t.Fatal("consumer did not stop after cancellation")
	}
}
