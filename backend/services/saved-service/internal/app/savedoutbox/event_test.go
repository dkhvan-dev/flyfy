package savedoutbox

import (
	"encoding/json"
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/saved-service/internal/domain"
)

func TestMapClaimedRecordProducesPrivacySafePayload(t *testing.T) {
	now := time.Date(2026, time.July, 16, 12, 0, 0, 0, time.UTC)
	record := ClaimedRecord{
		Lease: Lease{
			EventID:    uuid.New(),
			AcquiredAt: now,
			Attempt:    1,
		},
		Kind:          EventSavedItemActivated,
		EntityType:    domain.EntityTypeActivity,
		SchemaVersion: int32(SchemaVersionV1),
		OccurredAt:    now.Add(-time.Second),
	}

	event, err := MapClaimedRecord(record)
	if err != nil {
		t.Fatalf("MapClaimedRecord() error = %v", err)
	}
	payload, err := json.Marshal(event)
	if err != nil {
		t.Fatalf("json.Marshal() error = %v", err)
	}
	var fields map[string]json.RawMessage
	if err = json.Unmarshal(payload, &fields); err != nil {
		t.Fatalf("json.Unmarshal() error = %v", err)
	}
	wantFields := map[string]bool{
		"event_id":       true,
		"kind":           true,
		"entity_type":    true,
		"occurred_at":    true,
		"schema_version": true,
	}
	if len(fields) != len(wantFields) {
		t.Fatalf("payload fields = %v", fields)
	}
	for field := range fields {
		if !wantFields[field] {
			t.Fatalf("unexpected payload field %q", field)
		}
	}
	for _, forbidden := range []string{
		"owner_user_id",
		"account_id",
		"target_id",
		"entity_id",
		"saved_item_id",
		"state_generation",
		"relationship_attribution_id",
		"relationship_version",
	} {
		if _, found := fields[forbidden]; found {
			t.Fatalf("privacy-sensitive field %q is present", forbidden)
		}
	}
}

func TestMapClaimedRecordRejectsUnsupportedSchemaAndNilEventID(t *testing.T) {
	now := time.Date(2026, time.July, 16, 12, 0, 0, 0, time.UTC)
	record := ClaimedRecord{
		Lease:         Lease{EventID: uuid.New(), AcquiredAt: now, Attempt: 1},
		Kind:          EventSavedItemRemoved,
		EntityType:    domain.EntityTypeGuide,
		SchemaVersion: 2,
		OccurredAt:    now,
	}
	if _, err := MapClaimedRecord(record); !errors.Is(err, ErrInvalidRecord) {
		t.Fatalf("unsupported schema error = %v", err)
	}

	record.SchemaVersion = int32(SchemaVersionV1)
	record.Lease.EventID = uuid.Nil
	if _, err := MapClaimedRecord(record); !errors.Is(err, ErrInvalidRecord) {
		t.Fatalf("nil event id error = %v", err)
	}
}

func TestRetryDelayIsDeterministicAndBounded(t *testing.T) {
	eventID := uuid.MustParse("fd8d8bb5-cd6a-49aa-af68-cc10d9f18ae7")
	base := time.Second
	maximum := 8 * time.Second
	for attempt := 1; attempt <= 20; attempt++ {
		first := retryDelay(eventID, attempt, base, maximum)
		second := retryDelay(eventID, attempt, base, maximum)
		if first != second {
			t.Fatalf("attempt %d is not deterministic: %s != %s", attempt, first, second)
		}
		ceiling := base
		for current := 1; current < attempt && ceiling < maximum; current++ {
			ceiling = min(ceiling*2, maximum)
		}
		if first < ceiling/2 || first > ceiling {
			t.Fatalf("attempt %d delay = %s, want [%s,%s]", attempt, first, ceiling/2, ceiling)
		}
	}
}

func TestConfigRequiresLeaseToCoverAllPublishWaves(t *testing.T) {
	config := DefaultConfig()
	config.BatchSize = 10
	config.Concurrency = 2
	config.PublishTimeout = time.Second
	config.LeaseDuration = 9 * time.Second
	if err := config.Validate(); !errors.Is(err, ErrInvalidConfig) {
		t.Fatalf("short lease error = %v", err)
	}
	config.LeaseDuration = 10 * time.Second
	if err := config.Validate(); err != nil {
		t.Fatalf("valid config error = %v", err)
	}
}
