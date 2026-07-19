package natsadapter

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"sync"
	"testing"
	"time"

	"github.com/google/uuid"
	gonats "github.com/nats-io/nats.go"
	"github.com/nats-io/nats.go/jetstream"

	"kz/inflap/backend/services/saved-service/internal/app/savedoutbox"
	"kz/inflap/backend/services/saved-service/internal/domain"
)

func TestSavedOutboxPublisherPublishesExactPrivacyContract(t *testing.T) {
	broker := &fakeSavedDomainBroker{}
	publisher, err := newSavedOutboxPublisher(broker, 1)
	if err != nil {
		t.Fatalf("newSavedOutboxPublisher() error = %v", err)
	}
	event := testSavedDomainEvent()

	if err = publisher.Publish(context.Background(), event); err != nil {
		t.Fatalf("Publish() error = %v", err)
	}

	ensureCalls, publishCalls, ensured, messages := broker.snapshot()
	if ensureCalls != 1 || publishCalls != 1 || len(messages) != 1 {
		t.Fatalf("broker calls = ensure:%d publish:%d messages:%d", ensureCalls, publishCalls, len(messages))
	}
	if !savedDomainStreamConfigMatches(ensured[0], savedDomainStreamConfig(1)) {
		t.Fatalf("ensured stream config = %+v", ensured[0])
	}
	message := messages[0]
	if message.Subject != SavedDomainSubjectV1 {
		t.Fatalf("subject = %q", message.Subject)
	}
	if got := message.Header.Get(jetstream.MsgIDHeader); got != event.EventID.String() {
		t.Fatalf("Nats-Msg-Id = %q", got)
	}
	if got := message.Header.Get(jetstream.ExpectedStreamHeader); got != SavedDomainStreamName {
		t.Fatalf("Nats-Expected-Stream = %q", got)
	}
	if got := message.Header.Get("Content-Type"); got != SavedDomainContentType {
		t.Fatalf("Content-Type = %q", got)
	}
	wantPayload := `{"event_id":"018f13e8-7d2a-7ca6-a080-1b7e561f46e2","kind":"SAVED_ITEM_ACTIVATED","entity_type":"ACTIVITY","occurred_at":"2026-07-16T04:11:12.123456Z","schema_version":1}`
	if string(message.Data) != wantPayload {
		t.Fatalf("payload = %s\nwant    = %s", message.Data, wantPayload)
	}
	var fields map[string]json.RawMessage
	if err = json.Unmarshal(message.Data, &fields); err != nil {
		t.Fatalf("decode payload: %v", err)
	}
	allowed := map[string]struct{}{
		"event_id": {}, "kind": {}, "entity_type": {}, "occurred_at": {}, "schema_version": {},
	}
	if len(fields) != len(allowed) {
		t.Fatalf("payload fields = %v", fields)
	}
	for field := range fields {
		if _, ok := allowed[field]; !ok {
			t.Fatalf("payload contains forbidden field %q: %s", field, message.Data)
		}
	}
}

func TestSavedOutboxPublisherRejectsInvalidEventBeforeBrokerUse(t *testing.T) {
	broker := &fakeSavedDomainBroker{}
	publisher, err := newSavedOutboxPublisher(broker, 1)
	if err != nil {
		t.Fatalf("newSavedOutboxPublisher() error = %v", err)
	}

	err = publisher.Publish(context.Background(), savedoutbox.Event{})
	if err == nil || err.Error() != "invalid Saved domain event" {
		t.Fatalf("Publish() error = %v", err)
	}
	ensureCalls, publishCalls, _, _ := broker.snapshot()
	if ensureCalls != 0 || publishCalls != 0 {
		t.Fatalf("broker used for invalid event: ensure=%d publish=%d", ensureCalls, publishCalls)
	}
}

func TestSavedOutboxPublisherRejectsStreamContractDrift(t *testing.T) {
	actual := savedDomainStreamConfig(1)
	actual.Subjects = []string{"saved.domain.>"}
	broker := &fakeSavedDomainBroker{actualConfig: &actual}
	publisher, err := newSavedOutboxPublisher(broker, 1)
	if err != nil {
		t.Fatalf("newSavedOutboxPublisher() error = %v", err)
	}

	err = publisher.Publish(context.Background(), testSavedDomainEvent())
	if !errors.Is(err, errSavedDomainStreamContract) {
		t.Fatalf("Publish() error = %v, want stream contract mismatch", err)
	}
	_, publishCalls, _, _ := broker.snapshot()
	if publishCalls != 0 {
		t.Fatalf("published against drifted stream %d times", publishCalls)
	}
}

func TestSavedDomainStreamContractAllowsOnlyServerManagedMetadata(t *testing.T) {
	expected := savedDomainStreamConfig(1)
	serverNormalized := cloneStreamConfig(expected)
	serverNormalized.Metadata = map[string]string{"_nats.ver": "2.14.2"}
	if !savedDomainStreamConfigMatches(serverNormalized, expected) {
		t.Fatal("server-managed metadata must not break the stream contract")
	}

	serverNormalized.Metadata["owner"] = "another-service"
	if savedDomainStreamConfigMatches(serverNormalized, expected) {
		t.Fatal("application metadata drift must break the stream contract")
	}
}

func TestSavedOutboxPublisherInvalidatesProvisioningAfterPublishFailure(t *testing.T) {
	broker := &fakeSavedDomainBroker{
		publishErrors: []error{errors.New("broker unavailable"), nil},
	}
	publisher, err := newSavedOutboxPublisher(broker, 1)
	if err != nil {
		t.Fatalf("newSavedOutboxPublisher() error = %v", err)
	}
	event := testSavedDomainEvent()

	if err = publisher.Publish(context.Background(), event); err == nil {
		t.Fatal("first Publish() error = nil")
	}
	if err = publisher.Publish(context.Background(), event); err != nil {
		t.Fatalf("second Publish() error = %v", err)
	}
	ensureCalls, publishCalls, _, _ := broker.snapshot()
	if ensureCalls != 2 || publishCalls != 2 {
		t.Fatalf("broker calls = ensure:%d publish:%d, want 2/2", ensureCalls, publishCalls)
	}
}

func TestSavedOutboxPublisherRequiresJetStreamAckFromExpectedStream(t *testing.T) {
	tests := []struct {
		name string
		ack  *jetstream.PubAck
	}{
		{name: "nil", ack: nil},
		{name: "wrong stream", ack: &jetstream.PubAck{Stream: "OTHER", Sequence: 1}},
		{name: "zero sequence", ack: &jetstream.PubAck{Stream: SavedDomainStreamName}},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			broker := &fakeSavedDomainBroker{ack: test.ack, ackSet: true}
			publisher, err := newSavedOutboxPublisher(broker, 1)
			if err != nil {
				t.Fatalf("newSavedOutboxPublisher() error = %v", err)
			}

			err = publisher.Publish(context.Background(), testSavedDomainEvent())
			if err == nil || err.Error() != "publish Saved domain event: invalid JetStream acknowledgement" {
				t.Fatalf("Publish() error = %v", err)
			}
		})
	}
}

func TestSavedOutboxPublisherSerializesConcurrentProvisioning(t *testing.T) {
	broker := &fakeSavedDomainBroker{ensureDelay: 5 * time.Millisecond}
	publisher, err := newSavedOutboxPublisher(broker, 1)
	if err != nil {
		t.Fatalf("newSavedOutboxPublisher() error = %v", err)
	}

	const workers = 32
	var wait sync.WaitGroup
	errorsByWorker := make(chan error, workers)
	for index := range workers {
		wait.Add(1)
		go func(index int) {
			defer wait.Done()
			event := testSavedDomainEvent()
			event.EventID = uuid.MustParse(fmt.Sprintf("018f13e8-7d2a-7ca6-a080-%012x", index+1))
			errorsByWorker <- publisher.Publish(context.Background(), event)
		}(index)
	}
	wait.Wait()
	close(errorsByWorker)
	for publishErr := range errorsByWorker {
		if publishErr != nil {
			t.Fatalf("concurrent Publish() error = %v", publishErr)
		}
	}
	ensureCalls, publishCalls, _, _ := broker.snapshot()
	if ensureCalls != 1 || publishCalls != workers {
		t.Fatalf("broker calls = ensure:%d publish:%d", ensureCalls, publishCalls)
	}
}

func TestNewSavedOutboxPublisherRejectsInvalidDependencies(t *testing.T) {
	if _, err := newSavedOutboxPublisher(nil, 1); !errors.Is(err, errSavedOutboxPublisherUnavailable) {
		t.Fatalf("nil broker error = %v", err)
	}
	if _, err := newSavedOutboxPublisher(&fakeSavedDomainBroker{}, 2); !errors.Is(err, errSavedOutboxPublisherUnavailable) {
		t.Fatalf("invalid replicas error = %v", err)
	}
	if _, err := NewSavedOutboxPublisher(nil, 1); !errors.Is(err, errSavedOutboxPublisherUnavailable) {
		t.Fatalf("nil connection error = %v", err)
	}
}

type fakeSavedDomainBroker struct {
	mu            sync.Mutex
	ensureCalls   int
	publishCalls  int
	ensured       []jetstream.StreamConfig
	messages      []*gonats.Msg
	actualConfig  *jetstream.StreamConfig
	ensureErr     error
	publishErrors []error
	ack           *jetstream.PubAck
	ackSet        bool
	ensureDelay   time.Duration
}

func (broker *fakeSavedDomainBroker) EnsureStream(
	ctx context.Context,
	config jetstream.StreamConfig,
) (jetstream.StreamConfig, error) {
	if broker.ensureDelay > 0 {
		timer := time.NewTimer(broker.ensureDelay)
		defer timer.Stop()
		select {
		case <-ctx.Done():
			return jetstream.StreamConfig{}, ctx.Err()
		case <-timer.C:
		}
	}
	broker.mu.Lock()
	defer broker.mu.Unlock()
	broker.ensureCalls++
	broker.ensured = append(broker.ensured, cloneStreamConfig(config))
	if broker.ensureErr != nil {
		return jetstream.StreamConfig{}, broker.ensureErr
	}
	if broker.actualConfig != nil {
		return cloneStreamConfig(*broker.actualConfig), nil
	}
	return cloneStreamConfig(config), nil
}

func (broker *fakeSavedDomainBroker) Publish(
	_ context.Context,
	message *gonats.Msg,
) (*jetstream.PubAck, error) {
	broker.mu.Lock()
	defer broker.mu.Unlock()
	broker.publishCalls++
	broker.messages = append(broker.messages, cloneNATSMessage(message))
	index := broker.publishCalls - 1
	if index < len(broker.publishErrors) && broker.publishErrors[index] != nil {
		return nil, broker.publishErrors[index]
	}
	if broker.ackSet {
		return broker.ack, nil
	}
	return &jetstream.PubAck{Stream: SavedDomainStreamName, Sequence: uint64(broker.publishCalls)}, nil
}

func (broker *fakeSavedDomainBroker) snapshot() (
	int,
	int,
	[]jetstream.StreamConfig,
	[]*gonats.Msg,
) {
	broker.mu.Lock()
	defer broker.mu.Unlock()
	ensured := make([]jetstream.StreamConfig, len(broker.ensured))
	for index := range broker.ensured {
		ensured[index] = cloneStreamConfig(broker.ensured[index])
	}
	messages := make([]*gonats.Msg, len(broker.messages))
	for index := range broker.messages {
		messages[index] = cloneNATSMessage(broker.messages[index])
	}
	return broker.ensureCalls, broker.publishCalls, ensured, messages
}

func cloneNATSMessage(message *gonats.Msg) *gonats.Msg {
	if message == nil {
		return nil
	}
	cloned := &gonats.Msg{
		Subject: message.Subject,
		Reply:   message.Reply,
		Data:    append([]byte(nil), message.Data...),
		Header:  make(gonats.Header, len(message.Header)),
	}
	for name, values := range message.Header {
		cloned.Header[name] = append([]string(nil), values...)
	}
	return cloned
}

func testSavedDomainEvent() savedoutbox.Event {
	return savedoutbox.Event{
		EventID:       uuid.MustParse("018f13e8-7d2a-7ca6-a080-1b7e561f46e2"),
		Kind:          savedoutbox.EventSavedItemActivated,
		EntityType:    domain.EntityTypeActivity,
		OccurredAt:    time.Date(2026, 7, 16, 10, 11, 12, 123_456_000, time.FixedZone("ALMT", 6*60*60)),
		SchemaVersion: savedoutbox.SchemaVersionV1,
	}
}
