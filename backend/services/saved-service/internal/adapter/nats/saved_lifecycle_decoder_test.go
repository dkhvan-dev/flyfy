package natsadapter

import (
	"bytes"
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"
	"google.golang.org/protobuf/encoding/protowire"
	"google.golang.org/protobuf/proto"
	"google.golang.org/protobuf/types/known/timestamppb"

	savedlifecycle "kz/inflap/backend/services/saved-service/internal/app/savedlifecycle"
	"kz/inflap/backend/services/saved-service/internal/domain"
	contentv1 "kz/inflap/proto/gen/go/content/v1"
)

func TestDecodeSavedLifecycleEventAcceptsCanonicalV1Subjects(t *testing.T) {
	t.Parallel()

	now := time.Now().UTC().Truncate(time.Microsecond)
	for _, contract := range savedlifecycle.SubjectContracts() {
		contract := contract
		t.Run(string(contract.EntityType), func(t *testing.T) {
			t.Parallel()
			payload := validLifecycleProtoPayload(t, contract, now, true)
			event, err := DecodeSavedLifecycleEvent(contract.Subject, payload, now)
			if err != nil {
				t.Fatalf("DecodeSavedLifecycleEvent() error = %v", err)
			}
			if event.Subject != contract.Subject || event.SourceService != contract.SourceService ||
				event.Target.EntityType() != contract.EntityType || event.SchemaVersion != 1 ||
				event.EnvelopeFingerprint == ([32]byte{}) {
				t.Fatalf("decoded event = %+v", event)
			}
		})
	}
}

func TestDecodeSavedLifecycleEventAllowsPublicEventWithoutProjection(t *testing.T) {
	t.Parallel()

	now := time.Now().UTC().Truncate(time.Microsecond)
	contract, _ := savedlifecycle.ContractForSubject(savedlifecycle.AttractionSubjectV1)
	payload := validLifecycleProtoPayload(t, contract, now, false)
	event, err := DecodeSavedLifecycleEvent(contract.Subject, payload, now)
	if err != nil || event.PublicProjection != nil || event.Visibility != domain.VisibilityPublic {
		t.Fatalf("DecodeSavedLifecycleEvent() = (%+v, %v)", event, err)
	}
}

func TestDecodeSavedLifecycleEventRejectsLegacySubjectAndTypeMismatch(t *testing.T) {
	t.Parallel()

	now := time.Now().UTC().Truncate(time.Microsecond)
	contract, _ := savedlifecycle.ContractForSubject(savedlifecycle.AttractionSubjectV1)
	payload := validLifecycleProtoPayload(t, contract, now, false)
	_, err := DecodeSavedLifecycleEvent("content.saved.lifecycle.v1.attraction", payload, now)
	assertDecoderErrorCode(t, err, savedlifecycle.ErrorCodeInvalidSubject)

	envelope := decodeLifecycleProtoForTest(t, payload)
	// Wire value 3 belonged to the retired EXCURSION type and remains reserved.
	envelope.Target.EntityType = contentv1.SavedEntityType(3)
	payload = marshalLifecycleProtoForTest(t, envelope)
	_, err = DecodeSavedLifecycleEvent(contract.Subject, payload, now)
	assertDecoderErrorCode(t, err, savedlifecycle.ErrorCodeInvalidTarget)
}

func TestDecodeSavedLifecycleEventRejectsUnknownFieldsAndNonCanonicalUUID(t *testing.T) {
	t.Parallel()

	now := time.Now().UTC().Truncate(time.Microsecond)
	contract, _ := savedlifecycle.ContractForSubject(savedlifecycle.ActivitySubjectV1)
	payload := validLifecycleProtoPayload(t, contract, now, true)
	payload = protowire.AppendTag(payload, 100, protowire.VarintType)
	payload = protowire.AppendVarint(payload, 1)
	_, err := DecodeSavedLifecycleEvent(contract.Subject, payload, now)
	assertDecoderErrorCode(t, err, savedlifecycle.ErrorCodeUnknownContractField)

	envelope := decodeLifecycleProtoForTest(t, validLifecycleProtoPayload(t, contract, now, true))
	envelope.EventId = stringsToUpper(envelope.EventId)
	payload = marshalLifecycleProtoForTest(t, envelope)
	_, err = DecodeSavedLifecycleEvent(contract.Subject, payload, now)
	assertDecoderErrorCode(t, err, savedlifecycle.ErrorCodeInvalidEventID)
}

func TestDecodeSavedLifecycleEventRejectsPrivacyAndProjectionViolations(t *testing.T) {
	t.Parallel()

	now := time.Now().UTC().Truncate(time.Microsecond)
	activity, _ := savedlifecycle.ContractForSubject(savedlifecycle.ActivitySubjectV1)
	envelope := decodeLifecycleProtoForTest(t, validLifecycleProtoPayload(t, activity, now, true))
	envelope.Kind = contentv1.SavedLifecycleEventKind_SAVED_LIFECYCLE_EVENT_KIND_VISIBILITY_CHANGED
	envelope.Visibility = contentv1.SavedTargetVisibility_SAVED_TARGET_VISIBILITY_PRIVATE
	payload := marshalLifecycleProtoForTest(t, envelope)
	_, err := DecodeSavedLifecycleEvent(activity.Subject, payload, now)
	assertDecoderErrorCode(t, err, savedlifecycle.ErrorCodePayloadForbidden)

	envelope = decodeLifecycleProtoForTest(t, validLifecycleProtoPayload(t, activity, now, true))
	envelope.PublicProjection.En.Title = ""
	payload = marshalLifecycleProtoForTest(t, envelope)
	_, err = DecodeSavedLifecycleEvent(activity.Subject, payload, now)
	assertDecoderErrorCode(t, err, savedlifecycle.ErrorCodeInvalidPublicProjection)
}

func TestLifecycleEnvelopeFingerprintUsesCanonicalSubjectAndSemantics(t *testing.T) {
	t.Parallel()

	now := time.Now().UTC().Truncate(time.Microsecond)
	contract, _ := savedlifecycle.ContractForSubject(savedlifecycle.GuideSubjectV1)
	payload := validLifecycleProtoPayload(t, contract, now, true)
	first, err := DecodeSavedLifecycleEvent(contract.Subject, payload, now)
	if err != nil {
		t.Fatalf("first decode error = %v", err)
	}
	second, err := DecodeSavedLifecycleEvent(contract.Subject, append([]byte(nil), payload...), now)
	if err != nil {
		t.Fatalf("second decode error = %v", err)
	}
	if !bytes.Equal(first.EnvelopeFingerprint[:], second.EnvelopeFingerprint[:]) {
		t.Fatal("identical semantics produced different fingerprints")
	}

	envelope := decodeLifecycleProtoForTest(t, payload)
	envelope.Revisions.SourceRevision++
	changed, err := DecodeSavedLifecycleEvent(contract.Subject, marshalLifecycleProtoForTest(t, envelope), now)
	if err != nil {
		t.Fatalf("changed decode error = %v", err)
	}
	if bytes.Equal(first.EnvelopeFingerprint[:], changed.EnvelopeFingerprint[:]) {
		t.Fatal("changed semantics produced the same fingerprint")
	}
}

func validLifecycleProtoPayload(
	t testing.TB,
	contract savedlifecycle.SubjectContract,
	occurredAt time.Time,
	withProjection bool,
) []byte {
	t.Helper()
	targetID := uuid.NewString()
	envelope := &contentv1.SavedSourceLifecycleEvent{
		EventId: uuid.NewString(),
		Kind:    contentv1.SavedLifecycleEventKind_SAVED_LIFECYCLE_EVENT_KIND_UPDATED,
		Target: &contentv1.SavedTarget{
			EntityType: protoEntityType(contract.EntityType),
			EntityId:   targetID,
		},
		Revisions: &contentv1.SavedSourceRevisions{
			SourceRevision:     1,
			ProjectionRevision: 1,
			VisibilityRevision: 1,
		},
		OccurredAt: timestamppb.New(occurredAt.UTC()),
		Visibility: contentv1.SavedTargetVisibility_SAVED_TARGET_VISIBILITY_PUBLIC,
	}
	if withProjection {
		route := "/activities/" + targetID
		switch contract.EntityType {
		case domain.EntityTypeAttraction:
			route = "/places/" + targetID
		case domain.EntityTypeGuide:
			route = "/users/" + targetID + "/profile"
		}
		envelope.PublicProjection = &contentv1.SavedPublicCardProjection{
			SourceDefaultLocale: contentv1.SavedLocale_SAVED_LOCALE_EN,
			En: &contentv1.SavedLocalizedCardProjection{
				Title:           "Public title",
				City:            "Almaty",
				DisplayLocation: "Almaty, Kazakhstan",
			},
			CanonicalDetailRoute: route,
		}
	}
	return marshalLifecycleProtoForTest(t, envelope)
}

func decodeLifecycleProtoForTest(
	t testing.TB,
	payload []byte,
) *contentv1.SavedSourceLifecycleEvent {
	t.Helper()
	envelope := new(contentv1.SavedSourceLifecycleEvent)
	if err := proto.Unmarshal(payload, envelope); err != nil {
		t.Fatalf("proto.Unmarshal() error = %v", err)
	}
	return envelope
}

func marshalLifecycleProtoForTest(
	t testing.TB,
	envelope *contentv1.SavedSourceLifecycleEvent,
) []byte {
	t.Helper()
	payload, err := (proto.MarshalOptions{Deterministic: true}).Marshal(envelope)
	if err != nil {
		t.Fatalf("proto.Marshal() error = %v", err)
	}
	return payload
}

func assertDecoderErrorCode(t testing.TB, err error, code savedlifecycle.ErrorCode) {
	t.Helper()
	if err == nil || !savedlifecycle.IsPermanent(err) {
		t.Fatalf("error = %v, want permanent %s", err, code)
	}
	var permanent *savedlifecycle.PermanentError
	if !errors.As(err, &permanent) || permanent.Code != code {
		t.Fatalf("error = %v, want %s", err, code)
	}
}

func stringsToUpper(value string) string {
	result := []byte(value)
	for index, char := range result {
		if char >= 'a' && char <= 'f' {
			result[index] = char - ('a' - 'A')
		}
	}
	return string(result)
}
