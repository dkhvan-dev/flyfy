package natsadapter

import (
	"crypto/sha256"
	"encoding/binary"
	"time"

	"github.com/google/uuid"
	"google.golang.org/protobuf/proto"
	"google.golang.org/protobuf/reflect/protoreflect"
	"google.golang.org/protobuf/types/known/timestamppb"

	savedlifecycle "kz/inflap/backend/services/saved-service/internal/app/savedlifecycle"
	"kz/inflap/backend/services/saved-service/internal/domain"
	contentv1 "kz/inflap/proto/gen/go/content/v1"
)

const (
	maxLifecyclePayloadBytes = 64 * 1024
	maxPublicProjectionBytes = 16 * 1024
)

func DecodeSavedLifecycleEvent(
	subject string,
	payload []byte,
	now time.Time,
) (savedlifecycle.Event, error) {
	contract, ok := savedlifecycle.ContractForSubject(subject)
	if !ok {
		return savedlifecycle.Event{}, savedlifecycle.NewPermanentError(
			savedlifecycle.ErrorCodeInvalidSubject,
		)
	}
	if len(payload) == 0 || len(payload) > maxLifecyclePayloadBytes {
		return savedlifecycle.Event{}, savedlifecycle.NewPermanentError(
			savedlifecycle.ErrorCodeMalformedProtobuf,
		)
	}

	envelope := new(contentv1.SavedSourceLifecycleEvent)
	if err := (proto.UnmarshalOptions{DiscardUnknown: false}).Unmarshal(payload, envelope); err != nil {
		return savedlifecycle.Event{}, savedlifecycle.NewPermanentError(
			savedlifecycle.ErrorCodeMalformedProtobuf,
		)
	}
	if containsUnknownContractField(envelope.ProtoReflect()) {
		return savedlifecycle.Event{}, savedlifecycle.NewPermanentError(
			savedlifecycle.ErrorCodeUnknownContractField,
		)
	}

	eventID, err := parseCanonicalEventID(envelope.GetEventId())
	if err != nil {
		return savedlifecycle.Event{}, err
	}
	targetMessage := envelope.GetTarget()
	if targetMessage == nil || targetMessage.GetEntityType() != protoEntityType(contract.EntityType) {
		return savedlifecycle.Event{}, savedlifecycle.NewPermanentError(
			savedlifecycle.ErrorCodeInvalidTarget,
		)
	}
	target, targetErr := domain.NewSavedTarget(contract.EntityType, targetMessage.GetEntityId())
	if targetErr != nil {
		return savedlifecycle.Event{}, savedlifecycle.NewPermanentError(
			savedlifecycle.ErrorCodeInvalidTarget,
		)
	}

	revisionsMessage := envelope.GetRevisions()
	if revisionsMessage == nil {
		return savedlifecycle.Event{}, savedlifecycle.NewPermanentError(
			savedlifecycle.ErrorCodeInvalidRevision,
		)
	}
	revisions := savedlifecycle.Revisions{
		Source:     revisionsMessage.GetSourceRevision(),
		Projection: revisionsMessage.GetProjectionRevision(),
		Visibility: revisionsMessage.GetVisibilityRevision(),
	}
	if !revisions.IsValid() {
		return savedlifecycle.Event{}, savedlifecycle.NewPermanentError(
			savedlifecycle.ErrorCodeInvalidRevision,
		)
	}

	occurredAt, ok := strictTimestamp(envelope.GetOccurredAt())
	if !ok {
		return savedlifecycle.Event{}, savedlifecycle.NewPermanentError(
			savedlifecycle.ErrorCodeInvalidTimestamp,
		)
	}
	kind, ok := lifecycleEventKind(envelope.GetKind())
	if !ok {
		return savedlifecycle.Event{}, savedlifecycle.NewPermanentError(
			savedlifecycle.ErrorCodeInvalidKindVisibility,
		)
	}
	visibility, ok := lifecycleVisibility(envelope.GetVisibility())
	if !ok {
		return savedlifecycle.Event{}, savedlifecycle.NewPermanentError(
			savedlifecycle.ErrorCodeInvalidKindVisibility,
		)
	}

	var publicProjection *savedlifecycle.PublicProjection
	if envelope.GetPublicProjection() != nil {
		if visibility != domain.VisibilityPublic {
			return savedlifecycle.Event{}, savedlifecycle.NewPermanentError(
				savedlifecycle.ErrorCodePayloadForbidden,
			)
		}
		publicProjection, err = decodePublicProjection(envelope.GetPublicProjection())
		if err != nil {
			return savedlifecycle.Event{}, err
		}
	}

	fingerprint, err := lifecycleEnvelopeFingerprint(subject, envelope)
	if err != nil {
		return savedlifecycle.Event{}, err
	}
	event := savedlifecycle.Event{
		EventID:             eventID,
		Subject:             contract.Subject,
		SourceService:       contract.SourceService,
		SchemaVersion:       contract.SchemaVersion,
		Kind:                kind,
		Target:              target,
		Revisions:           revisions,
		OccurredAt:          occurredAt,
		Visibility:          visibility,
		PublicProjection:    publicProjection,
		EnvelopeFingerprint: fingerprint,
	}
	if err = event.Validate(now.UTC()); err != nil {
		return savedlifecycle.Event{}, err
	}
	return event, nil
}

func decodePublicProjection(
	message *contentv1.SavedPublicCardProjection,
) (*savedlifecycle.PublicProjection, error) {
	if message == nil || proto.Size(message) > maxPublicProjectionBytes {
		return nil, savedlifecycle.NewPermanentError(
			savedlifecycle.ErrorCodeInvalidPublicProjection,
		)
	}
	locale, ok := lifecycleLocale(message.GetSourceDefaultLocale())
	if !ok {
		return nil, savedlifecycle.NewPermanentError(
			savedlifecycle.ErrorCodeInvalidPublicProjection,
		)
	}
	projection := &savedlifecycle.PublicProjection{
		SourceDefaultLocale: locale,
		Localized: savedlifecycle.LocalizedProjections{
			EN: decodeLocalizedProjection(message.GetEn()),
			RU: decodeLocalizedProjection(message.GetRu()),
			KK: decodeLocalizedProjection(message.GetKk()),
		},
		CanonicalDetailRoute: message.GetCanonicalDetailRoute(),
	}
	if message.GetRating() != nil {
		projection.Rating = &savedlifecycle.RatingSummary{
			Value:       message.GetRating().GetValue(),
			ReviewCount: message.GetRating().GetReviewCount(),
			ScaleMax:    message.GetRating().GetScaleMax(),
		}
	}
	if message.GetAsOf() != nil {
		value, valid := strictTimestamp(message.GetAsOf())
		if !valid {
			return nil, savedlifecycle.NewPermanentError(
				savedlifecycle.ErrorCodeInvalidPublicProjection,
			)
		}
		projection.AsOf = &value
	}
	if message.GetValidUntil() != nil {
		value, valid := strictTimestamp(message.GetValidUntil())
		if !valid {
			return nil, savedlifecycle.NewPermanentError(
				savedlifecycle.ErrorCodeInvalidPublicProjection,
			)
		}
		projection.ValidUntil = &value
	}
	if message.GetMedia() != nil {
		validUntil, valid := strictTimestamp(message.GetMedia().GetValidUntil())
		if !valid {
			return nil, savedlifecycle.NewPermanentError(
				savedlifecycle.ErrorCodeInvalidPublicProjection,
			)
		}
		projection.Media = &savedlifecycle.MediaReference{
			OpaqueReference:   message.GetMedia().GetOpaqueReference(),
			ReferenceRevision: message.GetMedia().GetReferenceRevision(),
			ValidUntil:        validUntil,
		}
	}
	return projection, nil
}

func decodeLocalizedProjection(
	message *contentv1.SavedLocalizedCardProjection,
) *savedlifecycle.LocalizedProjection {
	if message == nil {
		return nil
	}
	return &savedlifecycle.LocalizedProjection{
		Title:               message.GetTitle(),
		Subtitle:            message.GetSubtitle(),
		City:                message.GetCity(),
		Country:             message.GetCountry(),
		DisplayLocation:     message.GetDisplayLocation(),
		PriceSummary:        message.GetPriceSummary(),
		AvailabilitySummary: message.GetAvailabilitySummary(),
	}
}

func parseCanonicalEventID(raw string) (uuid.UUID, error) {
	parsed, err := uuid.Parse(raw)
	if err != nil || parsed == uuid.Nil || parsed.Version() != 4 ||
		parsed.Variant() != uuid.RFC4122 || parsed.String() != raw {
		return uuid.Nil, savedlifecycle.NewPermanentError(savedlifecycle.ErrorCodeInvalidEventID)
	}
	return parsed, nil
}

func strictTimestamp(value *timestamppb.Timestamp) (time.Time, bool) {
	if value == nil || value.CheckValid() != nil {
		return time.Time{}, false
	}
	result := value.AsTime().UTC()
	return result, !result.IsZero() && !result.Before(time.Unix(0, 0).UTC())
}

func lifecycleEnvelopeFingerprint(
	subject string,
	envelope *contentv1.SavedSourceLifecycleEvent,
) ([32]byte, error) {
	canonical, err := (proto.MarshalOptions{Deterministic: true}).Marshal(envelope)
	if err != nil {
		return [32]byte{}, savedlifecycle.NewPermanentError(
			savedlifecycle.ErrorCodeMalformedProtobuf,
		)
	}
	hash := sha256.New()
	var length [4]byte
	binary.BigEndian.PutUint32(length[:], uint32(len(subject)))
	_, _ = hash.Write(length[:])
	_, _ = hash.Write([]byte(subject))
	_, _ = hash.Write(canonical)
	var fingerprint [32]byte
	copy(fingerprint[:], hash.Sum(nil))
	return fingerprint, nil
}

func containsUnknownContractField(message protoreflect.Message) bool {
	if !message.IsValid() || len(message.GetUnknown()) != 0 {
		return true
	}
	unknown := false
	message.Range(func(field protoreflect.FieldDescriptor, value protoreflect.Value) bool {
		switch {
		case field.IsList() && field.Message() != nil:
			list := value.List()
			for index := 0; index < list.Len(); index++ {
				if containsUnknownContractField(list.Get(index).Message()) {
					unknown = true
					return false
				}
			}
		case field.IsMap() && field.MapValue().Message() != nil:
			value.Map().Range(func(_ protoreflect.MapKey, mapValue protoreflect.Value) bool {
				if containsUnknownContractField(mapValue.Message()) {
					unknown = true
					return false
				}
				return true
			})
		case field.Message() != nil:
			unknown = containsUnknownContractField(value.Message())
		}
		return !unknown
	})
	return unknown
}

func protoEntityType(entityType domain.EntityType) contentv1.SavedEntityType {
	switch entityType {
	case domain.EntityTypeAttraction:
		return contentv1.SavedEntityType_SAVED_ENTITY_TYPE_ATTRACTION
	case domain.EntityTypeActivity:
		return contentv1.SavedEntityType_SAVED_ENTITY_TYPE_ACTIVITY
	case domain.EntityTypeGuide:
		return contentv1.SavedEntityType_SAVED_ENTITY_TYPE_GUIDE
	case domain.EntityTypeUser:
		return contentv1.SavedEntityType_SAVED_ENTITY_TYPE_USER
	default:
		return contentv1.SavedEntityType_SAVED_ENTITY_TYPE_UNSPECIFIED
	}
}

func lifecycleEventKind(value contentv1.SavedLifecycleEventKind) (savedlifecycle.EventKind, bool) {
	switch value {
	case contentv1.SavedLifecycleEventKind_SAVED_LIFECYCLE_EVENT_KIND_PUBLISHED:
		return savedlifecycle.EventPublished, true
	case contentv1.SavedLifecycleEventKind_SAVED_LIFECYCLE_EVENT_KIND_UPDATED:
		return savedlifecycle.EventUpdated, true
	case contentv1.SavedLifecycleEventKind_SAVED_LIFECYCLE_EVENT_KIND_UNAVAILABLE:
		return savedlifecycle.EventUnavailable, true
	case contentv1.SavedLifecycleEventKind_SAVED_LIFECYCLE_EVENT_KIND_DELETED:
		return savedlifecycle.EventDeleted, true
	case contentv1.SavedLifecycleEventKind_SAVED_LIFECYCLE_EVENT_KIND_VISIBILITY_CHANGED:
		return savedlifecycle.EventVisibilityChanged, true
	default:
		return "", false
	}
}

func lifecycleVisibility(value contentv1.SavedTargetVisibility) (domain.VisibilityStatus, bool) {
	switch value {
	case contentv1.SavedTargetVisibility_SAVED_TARGET_VISIBILITY_PUBLIC:
		return domain.VisibilityPublic, true
	case contentv1.SavedTargetVisibility_SAVED_TARGET_VISIBILITY_PRIVATE:
		return domain.VisibilityPrivate, true
	case contentv1.SavedTargetVisibility_SAVED_TARGET_VISIBILITY_UNAVAILABLE:
		return domain.VisibilityUnavailable, true
	case contentv1.SavedTargetVisibility_SAVED_TARGET_VISIBILITY_DELETED:
		return domain.VisibilityDeleted, true
	case contentv1.SavedTargetVisibility_SAVED_TARGET_VISIBILITY_RESTRICTED:
		return domain.VisibilityRestricted, true
	default:
		return domain.VisibilityUnknown, false
	}
}

func lifecycleLocale(value contentv1.SavedLocale) (savedlifecycle.Locale, bool) {
	switch value {
	case contentv1.SavedLocale_SAVED_LOCALE_EN:
		return savedlifecycle.LocaleEN, true
	case contentv1.SavedLocale_SAVED_LOCALE_RU:
		return savedlifecycle.LocaleRU, true
	case contentv1.SavedLocale_SAVED_LOCALE_KK:
		return savedlifecycle.LocaleKK, true
	default:
		return "", false
	}
}
