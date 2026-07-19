package natsadapter

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/nats-io/nats.go/jetstream"
)

type savedSourceStreamManagerStub struct {
	errors []error
	calls  int
}

func (manager *savedSourceStreamManagerStub) CreateOrUpdateStream(
	context.Context,
	jetstream.StreamConfig,
) (jetstream.Stream, error) {
	index := manager.calls
	manager.calls++
	if index < len(manager.errors) {
		return nil, manager.errors[index]
	}
	return nil, nil
}

func TestSavedSourceStreamConfigMatchesCanonicalContract(t *testing.T) {
	t.Parallel()

	config := savedSourceStreamConfig(3)
	if config.Name != SavedSourceStreamName ||
		len(config.Subjects) != 1 || config.Subjects[0] != SavedSourceSubjectPattern ||
		config.Storage != jetstream.FileStorage ||
		config.Retention != jetstream.LimitsPolicy ||
		config.MaxAge != 14*24*time.Hour ||
		config.MaxBytes != int64(4*1024*1024*1024) ||
		config.Discard != jetstream.DiscardOld ||
		config.Duplicates != 10*time.Minute ||
		config.Replicas != 3 {
		t.Fatalf("unexpected Saved source stream config: %+v", config)
	}
}

func TestEnsureSavedSourceStreamRecoversFromConcurrentCreate(t *testing.T) {
	t.Parallel()

	manager := &savedSourceStreamManagerStub{
		errors: []error{jetstream.ErrStreamNameAlreadyInUse, nil},
	}
	if err := ensureSavedSourceStream(
		context.Background(),
		manager,
		savedSourceStreamConfig(1),
	); err != nil {
		t.Fatalf("ensureSavedSourceStream() error = %v", err)
	}
	if manager.calls != 2 {
		t.Fatalf("CreateOrUpdateStream() calls = %d, want 2", manager.calls)
	}

	permanent := errors.New("NATS unavailable")
	manager = &savedSourceStreamManagerStub{errors: []error{permanent}}
	if err := ensureSavedSourceStream(
		context.Background(),
		manager,
		savedSourceStreamConfig(1),
	); !errors.Is(err, permanent) {
		t.Fatalf("ensureSavedSourceStream() error = %v, want permanent error", err)
	}
	if manager.calls != 1 {
		t.Fatalf("permanent CreateOrUpdateStream() calls = %d, want 1", manager.calls)
	}
}
