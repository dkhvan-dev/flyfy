package natsadapter

import (
	"context"
	"encoding/json"
	"errors"
	"sync"
	"testing"
	"time"

	"github.com/nats-io/nats.go/jetstream"

	savedlifecycle "kz/inflap/backend/services/saved-service/internal/app/savedlifecycle"
)

type ingestorStub struct {
	mu      sync.Mutex
	outcome savedlifecycle.Outcome
	err     error
	steps   *[]string
}

func (s *ingestorStub) Ingest(
	_ context.Context,
	_ savedlifecycle.Event,
) (savedlifecycle.Outcome, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.steps != nil {
		*s.steps = append(*s.steps, "ingest")
	}
	return s.outcome, s.err
}

func (s *ingestorStub) DeleteExpiredInbox(context.Context, int) (int64, error) {
	return 0, nil
}

type lifecycleMessageStub struct {
	mu        sync.Mutex
	subject   string
	payload   []byte
	attempt   uint64
	steps     *[]string
	ackCount  int
	nakCount  int
	termCount int
	nakDelay  time.Duration
	ackErr    error
	nakErr    error
	termErr   error
}

func (m *lifecycleMessageStub) Data() []byte    { return m.payload }
func (m *lifecycleMessageStub) Subject() string { return m.subject }
func (m *lifecycleMessageStub) Metadata() (*jetstream.MsgMetadata, error) {
	return &jetstream.MsgMetadata{NumDelivered: m.attempt}, nil
}
func (m *lifecycleMessageStub) DoubleAck(context.Context) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.ackCount++
	if m.steps != nil {
		*m.steps = append(*m.steps, "ack")
	}
	return m.ackErr
}
func (m *lifecycleMessageStub) NakWithDelay(delay time.Duration) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.nakCount++
	m.nakDelay = delay
	return m.nakErr
}
func (m *lifecycleMessageStub) Term() error {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.termCount++
	return m.termErr
}

func TestConsumerAcknowledgesOnlyAfterSuccessfulIngest(t *testing.T) {
	t.Parallel()

	now := time.Now().UTC().Truncate(time.Microsecond)
	binding := DefaultConsumerConfig().Bindings[0]
	contract, _ := savedlifecycle.ContractForSubject(binding.Subject)
	steps := make([]string, 0, 2)
	ingestor := &ingestorStub{
		outcome: savedlifecycle.Outcome{Code: savedlifecycle.OutcomeApplied, ProjectionApplied: true},
		steps:   &steps,
	}
	consumer := testSavedLifecycleConsumer(now, ingestor)
	message := &lifecycleMessageStub{
		subject: binding.Subject,
		payload: validLifecycleProtoPayload(t, contract, now, true),
		attempt: 1,
		steps:   &steps,
	}

	consumer.handleMessage(context.Background(), binding, message)
	if len(steps) != 2 || steps[0] != "ingest" || steps[1] != "ack" {
		t.Fatalf("processing order = %v", steps)
	}
	if message.ackCount != 1 || message.nakCount != 0 || message.termCount != 0 {
		t.Fatalf("ack=%d nak=%d term=%d", message.ackCount, message.nakCount, message.termCount)
	}
}

func TestConsumerRetriesTransientFailureBeforeMaxDeliver(t *testing.T) {
	t.Parallel()

	now := time.Now().UTC().Truncate(time.Microsecond)
	binding := DefaultConsumerConfig().Bindings[0]
	contract, _ := savedlifecycle.ContractForSubject(binding.Subject)
	ingestor := &ingestorStub{err: savedlifecycle.ErrRepositoryUnavailable}
	consumer := testSavedLifecycleConsumer(now, ingestor)
	message := &lifecycleMessageStub{
		subject: binding.Subject,
		payload: validLifecycleProtoPayload(t, contract, now, true),
		attempt: 2,
	}

	consumer.handleMessage(context.Background(), binding, message)
	if message.ackCount != 0 || message.nakCount != 1 || message.termCount != 0 ||
		message.nakDelay < consumer.config.RetryBaseDelay ||
		message.nakDelay > consumer.config.RetryMaxDelay {
		t.Fatalf("ack=%d nak=%d term=%d delay=%s", message.ackCount, message.nakCount, message.termCount, message.nakDelay)
	}
}

func TestConsumerDeadLettersPoisonWithoutRawPayload(t *testing.T) {
	t.Parallel()

	now := time.Now().UTC().Truncate(time.Microsecond)
	binding := DefaultConsumerConfig().Bindings[0]
	consumer := testSavedLifecycleConsumer(now, &ingestorStub{})
	var dlqPayload []byte
	consumer.publishDeadLetter = func(_ context.Context, subject string, payload []byte, messageID string) error {
		if subject != binding.DLQSubject || messageID == "" {
			t.Fatalf("DLQ publish subject=%q messageID=%q", subject, messageID)
		}
		dlqPayload = append([]byte(nil), payload...)
		return nil
	}
	rawPayload := []byte("private raw payload that must not be copied")
	message := &lifecycleMessageStub{subject: binding.Subject, payload: rawPayload, attempt: 1}

	consumer.handleMessage(context.Background(), binding, message)
	if message.termCount != 1 || message.nakCount != 0 || message.ackCount != 0 {
		t.Fatalf("ack=%d nak=%d term=%d", message.ackCount, message.nakCount, message.termCount)
	}
	if len(dlqPayload) == 0 || bytesContains(dlqPayload, rawPayload) {
		t.Fatalf("DLQ payload contains raw input: %s", dlqPayload)
	}
	var record deadLetterRecord
	if err := json.Unmarshal(dlqPayload, &record); err != nil {
		t.Fatalf("decode DLQ record: %v", err)
	}
	if record.ErrorCode != savedlifecycle.ErrorCodeMalformedProtobuf ||
		record.FailedSubject != binding.Subject || len(record.PayloadSHA256) != 64 {
		t.Fatalf("DLQ record = %+v", record)
	}
}

func TestConsumerDoesNotTerminateUntilDLQIsDurable(t *testing.T) {
	t.Parallel()

	now := time.Now().UTC().Truncate(time.Microsecond)
	binding := DefaultConsumerConfig().Bindings[0]
	consumer := testSavedLifecycleConsumer(now, &ingestorStub{})
	consumer.publishDeadLetter = func(context.Context, string, []byte, string) error {
		return errors.New("DLQ unavailable")
	}
	message := &lifecycleMessageStub{subject: binding.Subject, payload: []byte{0xff}, attempt: 1}

	consumer.handleMessage(context.Background(), binding, message)
	if message.termCount != 0 || message.nakCount != 1 || message.ackCount != 0 {
		t.Fatalf("ack=%d nak=%d term=%d", message.ackCount, message.nakCount, message.termCount)
	}
}

func TestConsumerDeadLettersTransientFailureAtMaxDeliver(t *testing.T) {
	t.Parallel()

	now := time.Now().UTC().Truncate(time.Microsecond)
	binding := DefaultConsumerConfig().Bindings[0]
	contract, _ := savedlifecycle.ContractForSubject(binding.Subject)
	consumer := testSavedLifecycleConsumer(now, &ingestorStub{err: savedlifecycle.ErrRepositoryUnavailable})
	consumer.publishDeadLetter = func(context.Context, string, []byte, string) error { return nil }
	message := &lifecycleMessageStub{
		subject: binding.Subject,
		payload: validLifecycleProtoPayload(t, contract, now, true),
		attempt: uint64(consumer.config.MaxDeliver),
	}

	consumer.handleMessage(context.Background(), binding, message)
	if message.termCount != 1 || message.nakCount != 0 || message.ackCount != 0 {
		t.Fatalf("ack=%d nak=%d term=%d", message.ackCount, message.nakCount, message.termCount)
	}
}

func TestDefaultConsumerConfigUsesCanonicalSharedStreamOnly(t *testing.T) {
	t.Parallel()

	config := DefaultConsumerConfig()
	if err := config.validate(); err != nil {
		t.Fatalf("default config invalid: %v", err)
	}
	want := map[string]bool{
		savedlifecycle.ActivitySubjectV1:   true,
		savedlifecycle.AttractionSubjectV1: true,
		savedlifecycle.GuideSubjectV1:      true,
	}
	for _, binding := range config.Bindings {
		if binding.Stream != SavedSourceStreamName || !want[binding.Subject] {
			t.Fatalf("unexpected default binding: %+v", binding)
		}
		delete(want, binding.Subject)
	}
	if len(want) != 0 {
		t.Fatalf("missing canonical bindings: %v", want)
	}

	config.Bindings[1].Subject = "content.saved.lifecycle.v1.attraction"
	if err := config.validate(); err == nil {
		t.Fatal("legacy attraction subject was accepted")
	}

	config = DefaultConsumerConfig()
	config.Bindings[1].Stream = "PLACE_SAVED_SOURCE"
	if err := config.validate(); err == nil {
		t.Fatal("non-canonical attraction stream was accepted")
	}
}

func testSavedLifecycleConsumer(
	now time.Time,
	ingestor LifecycleIngestor,
) *SavedLifecycleConsumer {
	config := DefaultConsumerConfig()
	return &SavedLifecycleConsumer{
		ingestor: ingestor,
		observer: noopObserver{},
		config:   config,
		now:      func() time.Time { return now },
		publishDeadLetter: func(context.Context, string, []byte, string) error {
			return nil
		},
	}
}

func bytesContains(haystack []byte, needle []byte) bool {
	if len(needle) == 0 || len(needle) > len(haystack) {
		return false
	}
	for index := 0; index+len(needle) <= len(haystack); index++ {
		match := true
		for offset := range needle {
			if haystack[index+offset] != needle[offset] {
				match = false
				break
			}
		}
		if match {
			return true
		}
	}
	return false
}
