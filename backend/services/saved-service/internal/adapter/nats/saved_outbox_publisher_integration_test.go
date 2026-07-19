package natsadapter

import (
	"context"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"
	gonats "github.com/nats-io/nats.go"
	"github.com/nats-io/nats.go/jetstream"
)

const savedOutboxNATSTestURLEnv = "SAVED_SERVICE_OUTBOX_NATS_TEST_URL"

func TestSavedOutboxPublisherJetStreamContract(t *testing.T) {
	natsURL := strings.TrimSpace(os.Getenv(savedOutboxNATSTestURLEnv))
	if natsURL == "" {
		t.Skip(savedOutboxNATSTestURLEnv + " is not set")
	}

	connection, err := gonats.Connect(natsURL, gonats.Timeout(3*time.Second))
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

	publisher, err := NewSavedOutboxPublisher(connection, 1)
	if err != nil {
		t.Fatalf("NewSavedOutboxPublisher() error = %v", err)
	}
	expectedConfig := savedDomainStreamConfig(1)
	provisioned, err := js.CreateOrUpdateStream(ctx, expectedConfig)
	if err != nil {
		t.Fatalf("pre-provision SAVED_DOMAIN stream: %v", err)
	}
	provisionedInfo, err := provisioned.Info(ctx)
	if err != nil {
		t.Fatalf("read pre-provisioned SAVED_DOMAIN stream: %v", err)
	}
	if !savedDomainStreamConfigMatches(provisionedInfo.Config, expectedConfig) {
		t.Fatalf("normalized SAVED_DOMAIN stream config = %+v, expected %+v", provisionedInfo.Config, expectedConfig)
	}
	initialMessageCount := provisionedInfo.State.Msgs
	if err = publisher.EnsureStream(ctx); err != nil {
		t.Fatalf("EnsureStream() error = %v", err)
	}
	stream, err := js.Stream(ctx, SavedDomainStreamName)
	if err != nil {
		t.Fatalf("load SAVED_DOMAIN stream: %v", err)
	}
	info, err := stream.Info(ctx)
	if err != nil {
		t.Fatalf("load SAVED_DOMAIN stream info: %v", err)
	}
	if !savedDomainStreamConfigMatches(info.Config, savedDomainStreamConfig(1)) {
		t.Fatalf("SAVED_DOMAIN stream config = %+v", info.Config)
	}

	event := testSavedDomainEvent()
	event.EventID = uuid.New()
	if err = publisher.Publish(ctx, event); err != nil {
		t.Fatalf("first Publish() error = %v", err)
	}
	if err = publisher.Publish(ctx, event); err != nil {
		t.Fatalf("duplicate Publish() error = %v", err)
	}
	info, err = stream.Info(ctx)
	if err != nil {
		t.Fatalf("reload SAVED_DOMAIN stream info: %v", err)
	}
	if info.State.Msgs != initialMessageCount+1 {
		t.Fatalf("stream message count = %d, want %d after deduplication", info.State.Msgs, initialMessageCount+1)
	}
	publishedSequence := info.State.LastSeq
	t.Cleanup(func() {
		cleanupCtx, cleanupCancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cleanupCancel()
		_ = stream.DeleteMsg(cleanupCtx, publishedSequence)
	})
	message, err := stream.GetMsg(ctx, publishedSequence)
	if err != nil {
		t.Fatalf("read published message: %v", err)
	}
	if message.Subject != SavedDomainSubjectV1 ||
		message.Header.Get(jetstream.MsgIDHeader) != event.EventID.String() ||
		message.Header.Get(jetstream.ExpectedStreamHeader) != SavedDomainStreamName ||
		message.Header.Get("Content-Type") != SavedDomainContentType {
		t.Fatalf("published message contract = subject:%q headers:%v", message.Subject, message.Header)
	}
	wantPayload, err := encodeSavedDomainEvent(event)
	if err != nil {
		t.Fatalf("encode expected payload: %v", err)
	}
	if string(message.Data) != string(wantPayload) {
		t.Fatalf("published payload = %s, want %s", message.Data, wantPayload)
	}
}
