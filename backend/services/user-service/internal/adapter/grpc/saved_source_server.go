package grpc

import (
	"context"
	"errors"
	"strings"
	"time"

	"github.com/google/uuid"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/types/known/timestamppb"

	"kz/inflap/backend/services/user-service/internal/app"
	contentv1 "kz/inflap/proto/gen/go/content/v1"
)

const savedSourceAllowedCaller = "saved-service"

func (server *Server) ResolveSaveEligibility(
	ctx context.Context,
	request *contentv1.ResolveSaveEligibilityRequest,
) (*contentv1.ResolveSaveEligibilityResponse, error) {
	if ServiceFromContext(ctx) != savedSourceAllowedCaller {
		return nil, status.Error(codes.PermissionDenied, "saved source caller is not allowed")
	}
	if server == nil || server.savedUserSourceUseCase == nil {
		return nil, status.Error(codes.Unavailable, "saved user source is unavailable")
	}
	target := request.GetTarget()
	if target == nil || target.GetEntityType() != contentv1.SavedEntityType_SAVED_ENTITY_TYPE_USER {
		return nil, status.Error(codes.InvalidArgument, "target must be a user")
	}
	userID, err := parseCanonicalSavedUserID(target.GetEntityId())
	if err != nil {
		return nil, status.Error(codes.InvalidArgument, "target entity id must be a canonical user UUID")
	}

	resolution, err := server.savedUserSourceUseCase.ResolveUser(ctx, userID)
	if err != nil {
		return nil, mapSavedUserSourceError(err)
	}
	validatedAt, ok := requiredSavedUserTimestamp(resolution.ValidatedAt)
	if !ok || resolution.SourceRevision == 0 || resolution.ProjectionRevision == 0 ||
		resolution.VisibilityRevision == 0 {
		return nil, status.Error(codes.Unavailable, "saved user source revisions are unavailable")
	}

	response := &contentv1.ResolveSaveEligibilityResponse{
		Target: &contentv1.SavedTarget{
			EntityType: contentv1.SavedEntityType_SAVED_ENTITY_TYPE_USER,
			EntityId:   target.GetEntityId(),
		},
		Eligibility: contentv1.SaveEligibility_SAVE_ELIGIBILITY_INELIGIBLE,
		Visibility:  toProtoSavedUserVisibility(resolution.Visibility),
		Revisions: &contentv1.SavedSourceRevisions{
			SourceRevision:     resolution.SourceRevision,
			ProjectionRevision: resolution.ProjectionRevision,
			VisibilityRevision: resolution.VisibilityRevision,
		},
		ValidatedAt: validatedAt,
	}
	if !resolution.Eligible || resolution.Visibility != app.SavedUserVisibilityPublic {
		return response, nil
	}
	projection, err := toProtoSavedUserProjection(resolution.PublicProjection)
	if err != nil {
		return nil, status.Error(codes.Unavailable, "saved user projection is unavailable")
	}
	response.Eligibility = contentv1.SaveEligibility_SAVE_ELIGIBILITY_ELIGIBLE
	response.Visibility = contentv1.SavedTargetVisibility_SAVED_TARGET_VISIBILITY_PUBLIC
	response.PublicProjection = projection
	return response, nil
}

func parseCanonicalSavedUserID(raw string) (uuid.UUID, error) {
	if raw == "" || raw != strings.TrimSpace(raw) || len(raw) != len(uuid.Nil.String()) {
		return uuid.Nil, app.ErrInvalidSavedUserID
	}
	parsed, err := uuid.Parse(raw)
	if err != nil || parsed == uuid.Nil || parsed.String() != raw {
		return uuid.Nil, app.ErrInvalidSavedUserID
	}
	return parsed, nil
}

func mapSavedUserSourceError(err error) error {
	switch {
	case errors.Is(err, app.ErrInvalidSavedUserID):
		return status.Error(codes.InvalidArgument, "invalid user target")
	case errors.Is(err, app.ErrSavedUserNotFound):
		return status.Error(codes.NotFound, "saved target unavailable")
	case errors.Is(err, context.Canceled):
		return status.Error(codes.Canceled, "saved source request canceled")
	case errors.Is(err, context.DeadlineExceeded):
		return status.Error(codes.DeadlineExceeded, "saved source deadline exceeded")
	case errors.Is(err, app.ErrSavedUserSourceUnavailable):
		return status.Error(codes.Unavailable, "user source unavailable")
	default:
		return status.Error(codes.Internal, "failed to resolve saved target")
	}
}

func toProtoSavedUserProjection(
	projection *app.SavedUserPublicProjection,
) (*contentv1.SavedPublicCardProjection, error) {
	if projection == nil || strings.TrimSpace(projection.CanonicalDetailRoute) == "" {
		return nil, app.ErrSavedUserSourceUnavailable
	}
	defaultLocale := toProtoSavedUserLocale(projection.SourceDefaultLocale)
	if defaultLocale == contentv1.SavedLocale_SAVED_LOCALE_UNSPECIFIED {
		return nil, app.ErrSavedUserSourceUnavailable
	}
	result := &contentv1.SavedPublicCardProjection{
		SourceDefaultLocale:  defaultLocale,
		CanonicalDetailRoute: projection.CanonicalDetailRoute,
		En:                   toProtoSavedUserLocalized(projection.Localized["en"]),
		Ru:                   toProtoSavedUserLocalized(projection.Localized["ru"]),
		Kk:                   toProtoSavedUserLocalized(projection.Localized["kk"]),
	}
	if result.GetEn() == nil || result.GetRu() == nil || result.GetKk() == nil {
		return nil, app.ErrSavedUserSourceUnavailable
	}
	if projection.Media != nil {
		validUntil, ok := requiredSavedUserTimestamp(projection.Media.ValidUntil)
		if !ok || projection.Media.ReferenceRevision == 0 ||
			strings.TrimSpace(projection.Media.OpaqueReference) == "" {
			return nil, app.ErrSavedUserSourceUnavailable
		}
		result.Media = &contentv1.SavedMediaReference{
			OpaqueReference:   projection.Media.OpaqueReference,
			ReferenceRevision: projection.Media.ReferenceRevision,
			ValidUntil:        validUntil,
		}
	}
	return result, nil
}

func toProtoSavedUserLocalized(
	projection app.SavedUserLocalizedProjection,
) *contentv1.SavedLocalizedCardProjection {
	if strings.TrimSpace(projection.Title) == "" {
		return nil
	}
	return &contentv1.SavedLocalizedCardProjection{
		Title:           projection.Title,
		Subtitle:        projection.Subtitle,
		Country:         projection.Country,
		DisplayLocation: projection.DisplayLocation,
	}
}

func toProtoSavedUserLocale(locale string) contentv1.SavedLocale {
	switch locale {
	case "en":
		return contentv1.SavedLocale_SAVED_LOCALE_EN
	case "ru":
		return contentv1.SavedLocale_SAVED_LOCALE_RU
	case "kk":
		return contentv1.SavedLocale_SAVED_LOCALE_KK
	default:
		return contentv1.SavedLocale_SAVED_LOCALE_UNSPECIFIED
	}
}

func toProtoSavedUserVisibility(
	visibility app.SavedUserVisibility,
) contentv1.SavedTargetVisibility {
	switch visibility {
	case app.SavedUserVisibilityPublic:
		return contentv1.SavedTargetVisibility_SAVED_TARGET_VISIBILITY_PUBLIC
	case app.SavedUserVisibilityDeleted:
		return contentv1.SavedTargetVisibility_SAVED_TARGET_VISIBILITY_DELETED
	case app.SavedUserVisibilityRestricted:
		return contentv1.SavedTargetVisibility_SAVED_TARGET_VISIBILITY_RESTRICTED
	default:
		return contentv1.SavedTargetVisibility_SAVED_TARGET_VISIBILITY_UNAVAILABLE
	}
}

func requiredSavedUserTimestamp(value time.Time) (*timestamppb.Timestamp, bool) {
	timestamp := timestamppb.New(value.UTC())
	if err := timestamp.CheckValid(); err != nil {
		return nil, false
	}
	return timestamp, true
}
