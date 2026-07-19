package natsadapter

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"regexp"
	"strings"
	"sync"
	"time"

	gonats "github.com/nats-io/nats.go"
	"github.com/nats-io/nats.go/jetstream"

	savedlifecycle "kz/inflap/backend/services/saved-service/internal/app/savedlifecycle"
)

const (
	SavedSourceStreamName      = "SAVED_SOURCE"
	SavedLifecycleDLQSubjectV1 = "saved.source.saved-service.lifecycle.dlq.v1"
)

var consumerNamePattern = regexp.MustCompile(`^[A-Za-z0-9_-]+$`)

type LifecycleIngestor interface {
	Ingest(ctx context.Context, event savedlifecycle.Event) (savedlifecycle.Outcome, error)
	DeleteExpiredInbox(ctx context.Context, limit int) (int64, error)
}

type ConsumerBinding struct {
	Stream     string
	Durable    string
	Subject    string
	DLQSubject string
}

type ConsumerConfig struct {
	Bindings           []ConsumerBinding
	WorkersPerBinding  int
	AckWait            time.Duration
	MaxDeliver         int
	MaxAckPending      int
	ProcessTimeout     time.Duration
	AckTimeout         time.Duration
	ProvisionTimeout   time.Duration
	DLQPublishTimeout  time.Duration
	RetryBaseDelay     time.Duration
	RetryMaxDelay      time.Duration
	IteratorRetryDelay time.Duration
	CleanupInterval    time.Duration
	CleanupTimeout     time.Duration
	CleanupBatchSize   int
}

func DefaultConsumerConfig() ConsumerConfig {
	return ConsumerConfig{
		Bindings: []ConsumerBinding{
			{
				Stream:     SavedSourceStreamName,
				Durable:    "SAVED_SERVICE_ACTIVITY_LIFECYCLE_V1",
				Subject:    savedlifecycle.ActivitySubjectV1,
				DLQSubject: SavedLifecycleDLQSubjectV1,
			},
			{
				Stream:     SavedSourceStreamName,
				Durable:    "SAVED_SERVICE_ATTRACTION_LIFECYCLE_V1",
				Subject:    savedlifecycle.AttractionSubjectV1,
				DLQSubject: SavedLifecycleDLQSubjectV1,
			},
			{
				Stream:     SavedSourceStreamName,
				Durable:    "SAVED_SERVICE_GUIDE_LIFECYCLE_V1",
				Subject:    savedlifecycle.GuideSubjectV1,
				DLQSubject: SavedLifecycleDLQSubjectV1,
			},
		},
		WorkersPerBinding:  2,
		AckWait:            30 * time.Second,
		MaxDeliver:         8,
		MaxAckPending:      64,
		ProcessTimeout:     10 * time.Second,
		AckTimeout:         3 * time.Second,
		ProvisionTimeout:   5 * time.Second,
		DLQPublishTimeout:  3 * time.Second,
		RetryBaseDelay:     time.Second,
		RetryMaxDelay:      5 * time.Minute,
		IteratorRetryDelay: time.Second,
		CleanupInterval:    time.Hour,
		CleanupTimeout:     10 * time.Second,
		CleanupBatchSize:   200,
	}
}

func (c ConsumerConfig) validate() error {
	if len(c.Bindings) == 0 || len(c.Bindings) > 3 ||
		c.WorkersPerBinding < 1 || c.WorkersPerBinding > 16 ||
		c.AckWait < 5*time.Second || c.AckWait > 5*time.Minute ||
		c.MaxDeliver < 2 || c.MaxDeliver > 20 ||
		c.MaxAckPending < c.WorkersPerBinding || c.MaxAckPending > 10_000 ||
		c.ProcessTimeout <= 0 || c.ProcessTimeout+c.AckTimeout >= c.AckWait ||
		c.AckTimeout <= 0 || c.ProvisionTimeout <= 0 || c.DLQPublishTimeout <= 0 ||
		c.RetryBaseDelay <= 0 || c.RetryMaxDelay < c.RetryBaseDelay ||
		c.IteratorRetryDelay <= 0 || c.CleanupInterval <= 0 || c.CleanupTimeout <= 0 ||
		c.CleanupBatchSize < 1 || c.CleanupBatchSize > savedlifecycle.MaxInboxCleanupBatch {
		return errors.New("invalid Saved lifecycle consumer limits")
	}

	seenSubjects := make(map[string]struct{}, len(c.Bindings))
	seenDurables := make(map[string]struct{}, len(c.Bindings))
	for _, binding := range c.Bindings {
		contract, supported := savedlifecycle.ContractForSubject(binding.Subject)
		_, dlqIsSource := savedlifecycle.ContractForSubject(binding.DLQSubject)
		if !supported || contract.Subject != binding.Subject ||
			binding.Stream != SavedSourceStreamName || dlqIsSource ||
			!consumerNamePattern.MatchString(binding.Stream) ||
			!consumerNamePattern.MatchString(binding.Durable) ||
			!validExactSubject(binding.DLQSubject) {
			return errors.New("invalid Saved lifecycle consumer binding")
		}
		if _, exists := seenSubjects[binding.Subject]; exists {
			return errors.New("duplicate Saved lifecycle subject binding")
		}
		if _, exists := seenDurables[binding.Stream+"\x00"+binding.Durable]; exists {
			return errors.New("duplicate Saved lifecycle durable binding")
		}
		seenSubjects[binding.Subject] = struct{}{}
		seenDurables[binding.Stream+"\x00"+binding.Durable] = struct{}{}
	}
	return nil
}

func validExactSubject(subject string) bool {
	return subject != "" && subject == strings.TrimSpace(subject) &&
		!strings.HasPrefix(subject, ".") && !strings.HasSuffix(subject, ".") &&
		!strings.Contains(subject, "..") &&
		!strings.ContainsAny(subject, " \t\r\n*>")
}

type ObservationAction string

const (
	ObservationAck           ObservationAction = "ACK"
	ObservationAckFailed     ObservationAction = "ACK_FAILED"
	ObservationRetry         ObservationAction = "RETRY"
	ObservationRetryFailed   ObservationAction = "RETRY_FAILED"
	ObservationDLQTerminated ObservationAction = "DLQ_TERMINATED"
	ObservationDLQRetry      ObservationAction = "DLQ_RETRY"
	ObservationIteratorRetry ObservationAction = "ITERATOR_RETRY"
	ObservationCleanup       ObservationAction = "CLEANUP"
	ObservationCleanupFailed ObservationAction = "CLEANUP_FAILED"
)

type Observation struct {
	Subject         string
	Outcome         savedlifecycle.OutcomeCode
	ErrorCode       savedlifecycle.ErrorCode
	Action          ObservationAction
	DeliveryAttempt uint64
	DeletedRows     int64
}

type Observer interface {
	ObserveSavedLifecycle(Observation)
}

type ObserverFunc func(Observation)

func (f ObserverFunc) ObserveSavedLifecycle(observation Observation) {
	if f != nil {
		f(observation)
	}
}

type noopObserver struct{}

func (noopObserver) ObserveSavedLifecycle(Observation) {}

type publishDeadLetterFunc func(
	ctx context.Context,
	subject string,
	payload []byte,
	messageID string,
) error

type SavedLifecycleConsumer struct {
	jetStream         jetstream.JetStream
	ingestor          LifecycleIngestor
	observer          Observer
	config            ConsumerConfig
	now               func() time.Time
	publishDeadLetter publishDeadLetterFunc
}

func NewSavedLifecycleConsumer(
	connection *gonats.Conn,
	ingestor LifecycleIngestor,
	config ConsumerConfig,
	observer Observer,
) (*SavedLifecycleConsumer, error) {
	if connection == nil || connection.IsClosed() || ingestor == nil {
		return nil, errors.New("Saved lifecycle consumer dependencies are unavailable")
	}
	if err := config.validate(); err != nil {
		return nil, err
	}
	js, err := jetstream.New(connection)
	if err != nil {
		return nil, fmt.Errorf("create Saved lifecycle JetStream context: %w", err)
	}
	if observer == nil {
		observer = noopObserver{}
	}
	config.Bindings = append([]ConsumerBinding(nil), config.Bindings...)
	consumer := &SavedLifecycleConsumer{
		jetStream: js,
		ingestor:  ingestor,
		observer:  observer,
		config:    config,
		now:       time.Now,
	}
	consumer.publishDeadLetter = func(
		ctx context.Context,
		subject string,
		payload []byte,
		messageID string,
	) error {
		_, publishErr := js.Publish(ctx, subject, payload, jetstream.WithMsgID(messageID))
		return publishErr
	}
	return consumer, nil
}

func (c *SavedLifecycleConsumer) Run(ctx context.Context) error {
	if ctx == nil || c == nil || c.jetStream == nil || c.ingestor == nil ||
		c.observer == nil || c.now == nil || c.publishDeadLetter == nil {
		return errors.New("Saved lifecycle consumer is unavailable")
	}
	if err := ctx.Err(); err != nil {
		return nil
	}

	type provisionedBinding struct {
		binding  ConsumerBinding
		consumer jetstream.Consumer
	}
	provisioned := make([]provisionedBinding, 0, len(c.config.Bindings))
	for _, binding := range c.config.Bindings {
		provisionCtx, cancel := context.WithTimeout(ctx, c.config.ProvisionTimeout)
		consumer, err := c.jetStream.CreateOrUpdateConsumer(
			provisionCtx,
			binding.Stream,
			jetstream.ConsumerConfig{
				Name:               binding.Durable,
				Durable:            binding.Durable,
				Description:        "saved-service source lifecycle v1",
				DeliverPolicy:      jetstream.DeliverAllPolicy,
				AckPolicy:          jetstream.AckExplicitPolicy,
				AckWait:            c.config.AckWait,
				MaxDeliver:         c.config.MaxDeliver,
				FilterSubject:      binding.Subject,
				ReplayPolicy:       jetstream.ReplayInstantPolicy,
				MaxWaiting:         c.config.WorkersPerBinding * 2,
				MaxAckPending:      c.config.MaxAckPending,
				MaxRequestBatch:    1,
				MaxRequestExpires:  min(5*time.Second, c.config.AckWait/2),
				MaxRequestMaxBytes: maxLifecyclePayloadBytes,
			},
		)
		cancel()
		if err != nil {
			return fmt.Errorf("provision Saved lifecycle consumer for %s: %w", binding.Subject, err)
		}
		provisioned = append(provisioned, provisionedBinding{binding: binding, consumer: consumer})
	}

	var workers sync.WaitGroup
	for _, item := range provisioned {
		for range c.config.WorkersPerBinding {
			workers.Add(1)
			go func(binding ConsumerBinding, consumer jetstream.Consumer) {
				defer workers.Done()
				c.runWorker(ctx, binding, consumer)
			}(item.binding, item.consumer)
		}
	}
	workers.Add(1)
	go func() {
		defer workers.Done()
		c.runCleanup(ctx)
	}()
	workers.Wait()
	return nil
}

func (c *SavedLifecycleConsumer) runWorker(
	ctx context.Context,
	binding ConsumerBinding,
	consumer jetstream.Consumer,
) {
	for ctx.Err() == nil {
		messages, err := consumer.Messages(
			jetstream.PullMaxMessages(1),
			jetstream.PullExpiry(min(5*time.Second, c.config.AckWait/2)),
		)
		if err != nil {
			c.observe(Observation{
				Subject:   binding.Subject,
				ErrorCode: savedlifecycle.ErrorCodeUnknown,
				Action:    ObservationIteratorRetry,
			})
			if !waitForContext(ctx, c.config.IteratorRetryDelay) {
				return
			}
			continue
		}

		for ctx.Err() == nil {
			message, nextErr := messages.Next(jetstream.NextContext(ctx))
			if nextErr == nil {
				c.handleMessage(ctx, binding, message)
				continue
			}
			messages.Stop()
			if ctx.Err() != nil || errors.Is(nextErr, jetstream.ErrMsgIteratorClosed) {
				break
			}
			c.observe(Observation{
				Subject:   binding.Subject,
				ErrorCode: savedlifecycle.ErrorCodeUnknown,
				Action:    ObservationIteratorRetry,
			})
			break
		}
		messages.Stop()
		if !waitForContext(ctx, c.config.IteratorRetryDelay) {
			return
		}
	}
}

type lifecycleMessage interface {
	Data() []byte
	Subject() string
	Metadata() (*jetstream.MsgMetadata, error)
	DoubleAck(context.Context) error
	NakWithDelay(time.Duration) error
	Term() error
}

func (c *SavedLifecycleConsumer) handleMessage(
	ctx context.Context,
	binding ConsumerBinding,
	message lifecycleMessage,
) {
	if message == nil || ctx.Err() != nil {
		return
	}
	attempt := uint64(1)
	if metadata, err := message.Metadata(); err == nil && metadata != nil && metadata.NumDelivered > 0 {
		attempt = metadata.NumDelivered
	}
	if message.Subject() != binding.Subject {
		c.deadLetterOrRetry(
			ctx,
			binding,
			message,
			attempt,
			savedlifecycle.ErrorCodeInvalidSubject,
		)
		return
	}

	event, err := DecodeSavedLifecycleEvent(message.Subject(), message.Data(), c.now().UTC())
	if err != nil {
		c.deadLetterOrRetry(ctx, binding, message, attempt, savedlifecycle.CodeOf(err))
		return
	}

	processCtx, cancel := context.WithTimeout(ctx, c.config.ProcessTimeout)
	outcome, err := c.ingestor.Ingest(processCtx, event)
	cancel()
	if err == nil {
		ackCtx, ackCancel := context.WithTimeout(ctx, c.config.AckTimeout)
		ackErr := message.DoubleAck(ackCtx)
		ackCancel()
		action := ObservationAck
		errorCode := savedlifecycle.ErrorCode("")
		if ackErr != nil {
			action = ObservationAckFailed
			errorCode = savedlifecycle.ErrorCodeUnknown
		}
		c.observe(Observation{
			Subject:         binding.Subject,
			Outcome:         outcome.Code,
			ErrorCode:       errorCode,
			Action:          action,
			DeliveryAttempt: attempt,
		})
		return
	}
	if ctx.Err() != nil {
		return
	}
	if savedlifecycle.IsPermanent(err) || attempt >= uint64(c.config.MaxDeliver) {
		c.deadLetterOrRetry(ctx, binding, message, attempt, savedlifecycle.CodeOf(err))
		return
	}

	action := ObservationRetry
	if nakErr := message.NakWithDelay(c.retryDelay(attempt, message.Data())); nakErr != nil {
		action = ObservationRetryFailed
	}
	c.observe(Observation{
		Subject:         binding.Subject,
		ErrorCode:       savedlifecycle.CodeOf(err),
		Action:          action,
		DeliveryAttempt: attempt,
	})
}

func (c *SavedLifecycleConsumer) deadLetterOrRetry(
	ctx context.Context,
	binding ConsumerBinding,
	message lifecycleMessage,
	attempt uint64,
	errorCode savedlifecycle.ErrorCode,
) {
	if errorCode == "" {
		errorCode = savedlifecycle.ErrorCodeUnknown
	}
	record, messageID, err := encodeDeadLetterRecord(message.Subject(), message.Data(), errorCode)
	if err == nil {
		publishCtx, cancel := context.WithTimeout(ctx, c.config.DLQPublishTimeout)
		err = c.publishDeadLetter(publishCtx, binding.DLQSubject, record, messageID)
		cancel()
	}
	if err == nil {
		err = message.Term()
		if err == nil {
			c.observe(Observation{
				Subject:         binding.Subject,
				ErrorCode:       errorCode,
				Action:          ObservationDLQTerminated,
				DeliveryAttempt: attempt,
			})
			return
		}
	}
	if ctx.Err() != nil {
		return
	}
	_ = message.NakWithDelay(c.retryDelay(attempt, message.Data()))
	c.observe(Observation{
		Subject:         binding.Subject,
		ErrorCode:       errorCode,
		Action:          ObservationDLQRetry,
		DeliveryAttempt: attempt,
	})
}

type deadLetterRecord struct {
	SchemaVersion int                      `json:"schema_version"`
	FailedSubject string                   `json:"failed_subject"`
	ErrorCode     savedlifecycle.ErrorCode `json:"error_code"`
	PayloadSHA256 string                   `json:"payload_sha256"`
}

func encodeDeadLetterRecord(
	subject string,
	payload []byte,
	errorCode savedlifecycle.ErrorCode,
) ([]byte, string, error) {
	payloadDigest := sha256.Sum256(payload)
	record := deadLetterRecord{
		SchemaVersion: 1,
		FailedSubject: subject,
		ErrorCode:     errorCode,
		PayloadSHA256: hex.EncodeToString(payloadDigest[:]),
	}
	encoded, err := json.Marshal(record)
	if err != nil {
		return nil, "", err
	}
	recordDigest := sha256.Sum256(encoded)
	return encoded, "saved-lifecycle-dlq-" + hex.EncodeToString(recordDigest[:]), nil
}

func (c *SavedLifecycleConsumer) retryDelay(attempt uint64, payload []byte) time.Duration {
	if attempt == 0 {
		attempt = 1
	}
	attempt = min(attempt, uint64(c.config.MaxDeliver))
	delay := c.config.RetryBaseDelay
	for retry := uint64(1); retry < attempt; retry++ {
		if delay >= c.config.RetryMaxDelay/2 {
			delay = c.config.RetryMaxDelay
			break
		}
		delay *= 2
	}
	delay = min(delay, c.config.RetryMaxDelay)
	digest := sha256.Sum256(payload)
	jitterWindow := delay / 5
	if jitterWindow > 0 {
		jitter := time.Duration(uint64(digest[0])<<8|uint64(digest[1])) % jitterWindow
		delay += jitter
	}
	return min(delay, c.config.RetryMaxDelay)
}

func (c *SavedLifecycleConsumer) runCleanup(ctx context.Context) {
	timer := time.NewTimer(0)
	defer timer.Stop()
	for {
		select {
		case <-ctx.Done():
			return
		case <-timer.C:
			cleanupCtx, cancel := context.WithTimeout(ctx, c.config.CleanupTimeout)
			deleted, err := c.ingestor.DeleteExpiredInbox(cleanupCtx, c.config.CleanupBatchSize)
			cancel()
			observation := Observation{Action: ObservationCleanup, DeletedRows: deleted}
			if err != nil && ctx.Err() == nil {
				observation.Action = ObservationCleanupFailed
				observation.ErrorCode = savedlifecycle.CodeOf(err)
			}
			c.observe(observation)
			timer.Reset(c.config.CleanupInterval)
		}
	}
}

func (c *SavedLifecycleConsumer) observe(observation Observation) {
	c.observer.ObserveSavedLifecycle(observation)
}

func waitForContext(ctx context.Context, delay time.Duration) bool {
	timer := time.NewTimer(delay)
	defer timer.Stop()
	select {
	case <-ctx.Done():
		return false
	case <-timer.C:
		return true
	}
}
