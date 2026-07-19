package savedcontract

import (
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"google.golang.org/protobuf/encoding/protojson"
	"google.golang.org/protobuf/proto"
	"google.golang.org/protobuf/types/known/timestamppb"

	"kz/inflap/backend/services/activity-service/internal/app"
	"kz/inflap/backend/services/activity-service/internal/domain/model"
	contentv1 "kz/inflap/proto/gen/go/content/v1"
)

var lifecycleJSON = protojson.MarshalOptions{
	UseProtoNames:   true,
	EmitUnpopulated: false,
}

func BuildActivityLifecycleEvent(
	before *model.Activity,
	after *model.Activity,
	beforeMedia []*model.ActivityMedia,
	afterMedia []*model.ActivityMedia,
	occurredAt time.Time,
) (*model.ActivitySavedLifecycleOutboxEvent, error) {
	if after == nil || after.ID == uuid.Nil {
		return nil, fmt.Errorf("activity lifecycle event requires the current activity")
	}
	if before != nil && before.ID != after.ID {
		return nil, fmt.Errorf("activity lifecycle transition target changed")
	}
	occurredAt = occurredAt.UTC()
	if occurredAt.IsZero() {
		return nil, fmt.Errorf("activity lifecycle occurrence time is required")
	}

	visibility, projection := app.ResolveSavedSourceSnapshot(after, afterMedia, occurredAt)
	kind, emit, err := lifecycleKind(before, after, beforeMedia, visibility)
	if err != nil || !emit {
		return nil, err
	}

	sourceRevision, projectionRevision, visibilityRevision, ok := app.SavedSourceRevisionVector(after)
	if !ok {
		return nil, fmt.Errorf("activity Saved revision vector is invalid")
	}
	eventID := uuid.New()
	protoEvent := &contentv1.SavedSourceLifecycleEvent{
		EventId: eventID.String(),
		Kind:    toProtoLifecycleKind(kind),
		Target: &contentv1.SavedTarget{
			EntityType: contentv1.SavedEntityType_SAVED_ENTITY_TYPE_ACTIVITY,
			EntityId:   after.ID.String(),
		},
		Revisions: &contentv1.SavedSourceRevisions{
			SourceRevision:     sourceRevision,
			ProjectionRevision: projectionRevision,
			VisibilityRevision: visibilityRevision,
		},
		OccurredAt: timestamppb.New(occurredAt),
		Visibility: ToProtoVisibility(visibility),
	}
	if err = protoEvent.OccurredAt.CheckValid(); err != nil {
		return nil, fmt.Errorf("invalid activity lifecycle occurrence time: %w", err)
	}
	if visibility == app.SavedSourceVisibilityPublic {
		if projection == nil {
			return nil, fmt.Errorf("public activity lifecycle event has no projection")
		}
		protoEvent.PublicProjection = ToProtoProjection(projection)
	}
	payload, err := lifecycleJSON.Marshal(protoEvent)
	if err != nil {
		return nil, fmt.Errorf("marshal activity Saved lifecycle event: %w", err)
	}

	event := &model.ActivitySavedLifecycleOutboxEvent{
		ID:                  eventID,
		ActivityID:          after.ID,
		Subject:             model.ActivitySavedLifecycleSubjectV1,
		SchemaVersion:       1,
		Kind:                kind,
		Visibility:          string(visibility),
		SourceRevision:      sourceRevision,
		ProjectionRevision:  projectionRevision,
		VisibilityRevision:  visibilityRevision,
		HasPublicProjection: protoEvent.PublicProjection != nil,
		Payload:             payload,
		OccurredAt:          occurredAt,
	}
	if err = event.ValidateSemanticEnvelope(); err != nil {
		return nil, err
	}
	return event, nil
}

func lifecycleKind(
	before *model.Activity,
	after *model.Activity,
	beforeMedia []*model.ActivityMedia,
	afterVisibility app.SavedSourceVisibility,
) (model.ActivitySavedLifecycleEventKind, bool, error) {
	if before == nil {
		return kindForNewVisibility(afterVisibility, true), true, nil
	}
	beforeVisibility, _ := app.ResolveSavedSourceSnapshot(before, beforeMedia, before.UpdatedAt.UTC())
	beforeSourceRevision, beforeProjectionRevision, beforeVisibilityRevision, beforeOK :=
		app.SavedSourceRevisionVector(before)
	afterSourceRevision, afterProjectionRevision, afterVisibilityRevision, afterOK :=
		app.SavedSourceRevisionVector(after)
	if !beforeOK || !afterOK {
		return "", false, fmt.Errorf("activity Saved revision vector is invalid")
	}
	if afterSourceRevision < beforeSourceRevision ||
		afterProjectionRevision < beforeProjectionRevision ||
		afterVisibilityRevision < beforeVisibilityRevision {
		return "", false, fmt.Errorf("activity Saved revision vector regressed")
	}
	if beforeVisibility != afterVisibility {
		if afterSourceRevision <= beforeSourceRevision ||
			afterVisibilityRevision <= beforeVisibilityRevision {
			return "", false, fmt.Errorf("activity Saved visibility transition did not advance revisions")
		}
		crossesPublicBoundary :=
			(beforeVisibility == app.SavedSourceVisibilityPublic) !=
				(afterVisibility == app.SavedSourceVisibilityPublic)
		if crossesPublicBoundary && afterProjectionRevision <= beforeProjectionRevision {
			return "", false, fmt.Errorf("activity Saved PUBLIC boundary did not rotate projection revision")
		}
		return kindForNewVisibility(afterVisibility, false), true, nil
	}

	if afterVisibility == app.SavedSourceVisibilityPublic && afterProjectionRevision > beforeProjectionRevision {
		if afterSourceRevision <= beforeSourceRevision {
			return "", false, fmt.Errorf("activity Saved projection transition did not advance source revision")
		}
		return model.ActivitySavedLifecycleUpdated, true, nil
	}
	return "", false, nil
}

func kindForNewVisibility(
	visibility app.SavedSourceVisibility,
	created bool,
) model.ActivitySavedLifecycleEventKind {
	switch visibility {
	case app.SavedSourceVisibilityPublic:
		if created {
			return model.ActivitySavedLifecyclePublished
		}
		return model.ActivitySavedLifecycleVisibilityChanged
	case app.SavedSourceVisibilityUnavailable:
		return model.ActivitySavedLifecycleUnavailable
	case app.SavedSourceVisibilityDeleted:
		return model.ActivitySavedLifecycleDeleted
	default:
		return model.ActivitySavedLifecycleVisibilityChanged
	}
}

func ToProtoVisibility(visibility app.SavedSourceVisibility) contentv1.SavedTargetVisibility {
	switch visibility {
	case app.SavedSourceVisibilityPublic:
		return contentv1.SavedTargetVisibility_SAVED_TARGET_VISIBILITY_PUBLIC
	case app.SavedSourceVisibilityPrivate:
		return contentv1.SavedTargetVisibility_SAVED_TARGET_VISIBILITY_PRIVATE
	case app.SavedSourceVisibilityDeleted:
		return contentv1.SavedTargetVisibility_SAVED_TARGET_VISIBILITY_DELETED
	case app.SavedSourceVisibilityRestricted:
		return contentv1.SavedTargetVisibility_SAVED_TARGET_VISIBILITY_RESTRICTED
	default:
		return contentv1.SavedTargetVisibility_SAVED_TARGET_VISIBILITY_UNAVAILABLE
	}
}

func ToProtoProjection(projection *app.SavedSourcePublicProjection) *contentv1.SavedPublicCardProjection {
	if projection == nil {
		return nil
	}
	result := &contentv1.SavedPublicCardProjection{
		SourceDefaultLocale:  toProtoLocale(projection.SourceDefaultLocale),
		CanonicalDetailRoute: projection.CanonicalDetailRoute,
		En:                   toProtoLocalizedProjection(projection.Localized["en"]),
		Ru:                   toProtoLocalizedProjection(projection.Localized["ru"]),
		Kk:                   toProtoLocalizedProjection(projection.Localized["kk"]),
	}
	if projection.Media != nil {
		result.Media = &contentv1.SavedMediaReference{
			OpaqueReference:   projection.Media.OpaqueReference,
			ReferenceRevision: projection.Media.ReferenceRevision,
			ValidUntil:        timestamppb.New(projection.Media.ValidUntil.UTC()),
		}
	}
	return result
}

func ValidateActivityLifecyclePayload(event model.ActivitySavedLifecycleOutboxEvent) error {
	_, err := decodeActivityLifecyclePayload(event)
	return err
}

func EncodeActivityLifecycleBinary(event model.ActivitySavedLifecycleOutboxEvent) ([]byte, error) {
	decoded, err := decodeActivityLifecyclePayload(event)
	if err != nil {
		return nil, err
	}
	payload, err := (proto.MarshalOptions{Deterministic: true}).Marshal(decoded)
	if err != nil {
		return nil, fmt.Errorf("encode Activity Saved lifecycle protobuf: %w", err)
	}
	return payload, nil
}

func decodeActivityLifecyclePayload(
	event model.ActivitySavedLifecycleOutboxEvent,
) (*contentv1.SavedSourceLifecycleEvent, error) {
	if err := event.ValidateSemanticEnvelope(); err != nil {
		return nil, err
	}
	decoded := new(contentv1.SavedSourceLifecycleEvent)
	if err := (protojson.UnmarshalOptions{DiscardUnknown: false}).Unmarshal(event.Payload, decoded); err != nil {
		return nil, fmt.Errorf("decode activity Saved lifecycle payload: %w", err)
	}
	if decoded.GetEventId() != event.ID.String() ||
		decoded.GetKind() != toProtoLifecycleKind(event.Kind) ||
		decoded.GetTarget().GetEntityType() != contentv1.SavedEntityType_SAVED_ENTITY_TYPE_ACTIVITY ||
		decoded.GetTarget().GetEntityId() != event.ActivityID.String() ||
		decoded.GetRevisions().GetSourceRevision() != event.SourceRevision ||
		decoded.GetRevisions().GetProjectionRevision() != event.ProjectionRevision ||
		decoded.GetRevisions().GetVisibilityRevision() != event.VisibilityRevision ||
		decoded.GetVisibility() != ToProtoVisibility(app.SavedSourceVisibility(event.Visibility)) ||
		(decoded.GetPublicProjection() != nil) != event.HasPublicProjection {
		return nil, fmt.Errorf("activity Saved lifecycle payload does not match immutable envelope")
	}
	if decoded.GetOccurredAt() == nil || !decoded.GetOccurredAt().AsTime().Equal(event.OccurredAt.UTC()) {
		return nil, fmt.Errorf("activity Saved lifecycle occurrence time does not match immutable envelope")
	}
	if event.Visibility != string(app.SavedSourceVisibilityPublic) && decoded.GetPublicProjection() != nil {
		return nil, fmt.Errorf("non-public activity Saved lifecycle payload contains a projection")
	}
	return decoded, nil
}

func toProtoLifecycleKind(kind model.ActivitySavedLifecycleEventKind) contentv1.SavedLifecycleEventKind {
	switch kind {
	case model.ActivitySavedLifecyclePublished:
		return contentv1.SavedLifecycleEventKind_SAVED_LIFECYCLE_EVENT_KIND_PUBLISHED
	case model.ActivitySavedLifecycleUpdated:
		return contentv1.SavedLifecycleEventKind_SAVED_LIFECYCLE_EVENT_KIND_UPDATED
	case model.ActivitySavedLifecycleUnavailable:
		return contentv1.SavedLifecycleEventKind_SAVED_LIFECYCLE_EVENT_KIND_UNAVAILABLE
	case model.ActivitySavedLifecycleDeleted:
		return contentv1.SavedLifecycleEventKind_SAVED_LIFECYCLE_EVENT_KIND_DELETED
	default:
		return contentv1.SavedLifecycleEventKind_SAVED_LIFECYCLE_EVENT_KIND_VISIBILITY_CHANGED
	}
}

func toProtoLocalizedProjection(projection app.SavedSourceLocalizedProjection) *contentv1.SavedLocalizedCardProjection {
	if strings.TrimSpace(projection.Title) == "" {
		return nil
	}
	return &contentv1.SavedLocalizedCardProjection{
		Title:           projection.Title,
		Subtitle:        projection.Subtitle,
		City:            projection.City,
		Country:         projection.Country,
		DisplayLocation: projection.DisplayLocation,
	}
}

func toProtoLocale(locale string) contentv1.SavedLocale {
	switch locale {
	case "en":
		return contentv1.SavedLocale_SAVED_LOCALE_EN
	case "kk":
		return contentv1.SavedLocale_SAVED_LOCALE_KK
	default:
		return contentv1.SavedLocale_SAVED_LOCALE_RU
	}
}
