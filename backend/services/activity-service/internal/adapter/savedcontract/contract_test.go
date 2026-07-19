package savedcontract

import (
	"bytes"
	"testing"
	"time"

	"github.com/google/uuid"
	"google.golang.org/protobuf/encoding/protojson"
	"google.golang.org/protobuf/proto"

	"kz/inflap/backend/services/activity-service/internal/domain/enum"
	"kz/inflap/backend/services/activity-service/internal/domain/model"
	contentv1 "kz/inflap/proto/gen/go/content/v1"
)

func TestBuildActivityLifecycleEventKeepsDenyPayloadsEmpty(t *testing.T) {
	t.Parallel()

	before := savedLifecycleContractActivity()
	after := cloneSavedLifecycleContractActivity(before)
	after.Visibility = enum.ActivityVisibilityPrivate
	after.SavedSourceRevision++
	after.SavedProjectionRevision++
	after.SavedVisibilityRevision++
	after.Revision++
	after.UpdatedAt = before.UpdatedAt.Add(time.Second)

	event, err := BuildActivityLifecycleEvent(before, after, nil, nil, after.UpdatedAt)
	if err != nil {
		t.Fatalf("BuildActivityLifecycleEvent() error = %v", err)
	}
	if event == nil || event.Kind != model.ActivitySavedLifecycleVisibilityChanged {
		t.Fatalf("event = %+v, want visibility change", event)
	}
	if event.Visibility != "PRIVATE" || event.HasPublicProjection {
		t.Fatalf("visibility/projection = %s/%v", event.Visibility, event.HasPublicProjection)
	}
	if bytes.Contains(event.Payload, []byte("Public title")) ||
		bytes.Contains(event.Payload, []byte("private-owner")) ||
		bytes.Contains(event.Payload, []byte("public_projection")) {
		t.Fatalf("deny payload leaked projection data: %s", event.Payload)
	}
	decoded := decodeSavedLifecycleContractEvent(t, event.Payload)
	if decoded.GetVisibility() != contentv1.SavedTargetVisibility_SAVED_TARGET_VISIBILITY_PRIVATE ||
		decoded.GetPublicProjection() != nil {
		t.Fatalf("decoded deny event = %+v", decoded)
	}
	if err = ValidateActivityLifecyclePayload(*event); err != nil {
		t.Fatalf("ValidateActivityLifecyclePayload() error = %v", err)
	}
	binaryPayload, err := EncodeActivityLifecycleBinary(*event)
	if err != nil {
		t.Fatalf("EncodeActivityLifecycleBinary() error = %v", err)
	}
	binaryEvent := new(contentv1.SavedSourceLifecycleEvent)
	if err = proto.Unmarshal(binaryPayload, binaryEvent); err != nil {
		t.Fatalf("decode deny lifecycle protobuf: %v", err)
	}
	if binaryEvent.GetPublicProjection() != nil {
		t.Fatalf("binary deny lifecycle event contains projection: %+v", binaryEvent.GetPublicProjection())
	}
}

func TestBuildActivityLifecycleEventEmitsClosedTransitionKinds(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name       string
		mutate     func(*model.Activity)
		wantKind   model.ActivitySavedLifecycleEventKind
		visibility string
	}{
		{
			name: "cancelled",
			mutate: func(item *model.Activity) {
				item.Status = enum.ActivityStatusCancelled
				now := item.UpdatedAt
				item.CancelledAt = &now
			},
			wantKind:   model.ActivitySavedLifecycleUnavailable,
			visibility: "UNAVAILABLE",
		},
		{
			name: "archived",
			mutate: func(item *model.Activity) {
				item.Status = enum.ActivityStatusArchived
			},
			wantKind:   model.ActivitySavedLifecycleDeleted,
			visibility: "DELETED",
		},
		{
			name: "restricted",
			mutate: func(item *model.Activity) {
				item.ModerationStatus = enum.ActivityModerationStatusRejected
			},
			wantKind:   model.ActivitySavedLifecycleVisibilityChanged,
			visibility: "RESTRICTED",
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			t.Parallel()
			before := savedLifecycleContractActivity()
			after := cloneSavedLifecycleContractActivity(before)
			after.UpdatedAt = before.UpdatedAt.Add(time.Second)
			test.mutate(after)
			after.SavedSourceRevision++
			after.SavedProjectionRevision++
			after.SavedVisibilityRevision++
			after.Revision++

			event, err := BuildActivityLifecycleEvent(before, after, nil, nil, after.UpdatedAt)
			if err != nil {
				t.Fatalf("BuildActivityLifecycleEvent() error = %v", err)
			}
			if event == nil || event.Kind != test.wantKind || event.Visibility != test.visibility {
				t.Fatalf("event = %+v, want %s/%s", event, test.wantKind, test.visibility)
			}
			if event.HasPublicProjection || bytes.Contains(event.Payload, []byte("public_projection")) {
				t.Fatalf("deny event contains projection: %s", event.Payload)
			}
		})
	}
}

func TestBuildActivityLifecycleEventRestoresPublicProjection(t *testing.T) {
	t.Parallel()

	before := savedLifecycleContractActivity()
	before.Visibility = enum.ActivityVisibilityPrivate
	after := cloneSavedLifecycleContractActivity(before)
	after.Visibility = enum.ActivityVisibilityPublic
	after.SavedSourceRevision++
	after.SavedProjectionRevision++
	after.SavedVisibilityRevision++
	after.Revision++
	after.UpdatedAt = before.UpdatedAt.Add(time.Second)

	event, err := BuildActivityLifecycleEvent(before, after, nil, nil, after.UpdatedAt)
	if err != nil {
		t.Fatalf("BuildActivityLifecycleEvent() error = %v", err)
	}
	if event == nil || event.Kind != model.ActivitySavedLifecycleVisibilityChanged ||
		event.Visibility != "PUBLIC" || !event.HasPublicProjection {
		t.Fatalf("restored event = %+v", event)
	}
	decoded := decodeSavedLifecycleContractEvent(t, event.Payload)
	if decoded.GetPublicProjection().GetEn().GetTitle() != "Public title" {
		t.Fatalf("restored projection = %+v", decoded.GetPublicProjection())
	}
}

func TestBuildActivityLifecycleEventRejectsPublicBoundaryWithoutMediaRotation(t *testing.T) {
	t.Parallel()

	before := savedLifecycleContractActivity()
	after := cloneSavedLifecycleContractActivity(before)
	after.Visibility = enum.ActivityVisibilityPrivate
	after.SavedSourceRevision++
	after.SavedVisibilityRevision++
	after.Revision++
	after.UpdatedAt = before.UpdatedAt.Add(time.Second)

	if event, err := BuildActivityLifecycleEvent(before, after, nil, nil, after.UpdatedAt); err == nil || event != nil {
		t.Fatalf("BuildActivityLifecycleEvent() = %+v/%v, want projection-rotation error", event, err)
	}
}

func TestBuildActivityLifecycleEventSkipsUnrelatedUpdate(t *testing.T) {
	t.Parallel()

	before := savedLifecycleContractActivity()
	after := cloneSavedLifecycleContractActivity(before)
	after.RequiresProfileCompletion = !before.RequiresProfileCompletion
	after.Revision++
	after.UpdatedAt = before.UpdatedAt.Add(time.Second)

	event, err := BuildActivityLifecycleEvent(before, after, nil, nil, after.UpdatedAt)
	if err != nil {
		t.Fatalf("BuildActivityLifecycleEvent() error = %v", err)
	}
	if event != nil {
		t.Fatalf("unrelated update emitted event = %+v", event)
	}
}

func TestBuildActivityLifecycleEventPublishedAndUpdatedCarryCanonicalTarget(t *testing.T) {
	t.Parallel()

	created := savedLifecycleContractActivity()
	published, err := BuildActivityLifecycleEvent(nil, created, nil, nil, created.UpdatedAt)
	if err != nil {
		t.Fatalf("build published event: %v", err)
	}
	if published.Kind != model.ActivitySavedLifecyclePublished || !published.HasPublicProjection {
		t.Fatalf("published event = %+v", published)
	}

	updated := cloneSavedLifecycleContractActivity(created)
	updated.Title = "Updated public title"
	updated.Translations["en"] = model.ActivityLocalizedCopy{Title: updated.Title, Description: updated.Description}
	updated.SavedSourceRevision++
	updated.SavedProjectionRevision++
	updated.Revision++
	updated.UpdatedAt = created.UpdatedAt.Add(time.Second)
	changed, err := BuildActivityLifecycleEvent(created, updated, nil, nil, updated.UpdatedAt)
	if err != nil {
		t.Fatalf("build updated event: %v", err)
	}
	if changed == nil || changed.Kind != model.ActivitySavedLifecycleUpdated {
		t.Fatalf("updated event = %+v", changed)
	}
	decoded := decodeSavedLifecycleContractEvent(t, changed.Payload)
	if decoded.GetTarget().GetEntityId() != created.ID.String() ||
		decoded.GetTarget().GetEntityType() != contentv1.SavedEntityType_SAVED_ENTITY_TYPE_ACTIVITY {
		t.Fatalf("target = %+v", decoded.GetTarget())
	}
}

func TestEncodeActivityLifecycleBinaryIsDeterministic(t *testing.T) {
	t.Parallel()

	created := savedLifecycleContractActivity()
	event, err := BuildActivityLifecycleEvent(nil, created, nil, nil, created.UpdatedAt)
	if err != nil {
		t.Fatalf("BuildActivityLifecycleEvent() error = %v", err)
	}
	first, err := EncodeActivityLifecycleBinary(*event)
	if err != nil {
		t.Fatalf("first EncodeActivityLifecycleBinary() error = %v", err)
	}
	second, err := EncodeActivityLifecycleBinary(*event)
	if err != nil {
		t.Fatalf("second EncodeActivityLifecycleBinary() error = %v", err)
	}
	if !bytes.Equal(first, second) {
		t.Fatalf("deterministic lifecycle payloads differ: %x / %x", first, second)
	}

	decoded := new(contentv1.SavedSourceLifecycleEvent)
	if err = proto.Unmarshal(first, decoded); err != nil {
		t.Fatalf("decode lifecycle protobuf: %v", err)
	}
	if decoded.GetEventId() != event.ID.String() ||
		decoded.GetTarget().GetEntityId() != event.ActivityID.String() ||
		decoded.GetPublicProjection() == nil {
		t.Fatalf("decoded lifecycle protobuf = %+v", decoded)
	}
}

func decodeSavedLifecycleContractEvent(
	t *testing.T,
	payload []byte,
) *contentv1.SavedSourceLifecycleEvent {
	t.Helper()
	event := new(contentv1.SavedSourceLifecycleEvent)
	if err := (protojson.UnmarshalOptions{DiscardUnknown: false}).Unmarshal(payload, event); err != nil {
		t.Fatalf("decode lifecycle payload: %v", err)
	}
	return event
}

func savedLifecycleContractActivity() *model.Activity {
	now := time.Date(2026, time.July, 16, 8, 0, 0, 0, time.UTC)
	publishedAt := now.Add(-time.Hour)
	return &model.Activity{
		ID:                      uuid.New(),
		HostUserID:              uuid.New(),
		Title:                   "Public title",
		Description:             "Public description for the Activity card",
		SourceLanguage:          "en",
		Translations:            model.ActivityTranslations{"en": {Title: "Public title", Description: "Public description for the Activity card"}},
		Status:                  enum.ActivityStatusEnrollmentOpen,
		Visibility:              enum.ActivityVisibilityPublic,
		ModerationStatus:        enum.ActivityModerationStatusApproved,
		PublishedAt:             &publishedAt,
		Revision:                10,
		SavedSourceRevision:     100,
		SavedProjectionRevision: 101,
		SavedVisibilityRevision: 102,
		UpdatedAt:               now,
	}
}

func cloneSavedLifecycleContractActivity(source *model.Activity) *model.Activity {
	clone := *source
	clone.Translations = make(model.ActivityTranslations, len(source.Translations))
	for locale, value := range source.Translations {
		clone.Translations[locale] = value
	}
	return &clone
}
