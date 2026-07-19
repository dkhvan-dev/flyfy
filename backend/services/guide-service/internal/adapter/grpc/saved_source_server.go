package grpc

import (
	"context"
	"errors"
	"math"
	"strings"
	"time"

	"github.com/google/uuid"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/types/known/timestamppb"

	"kz/inflap/backend/services/guide-service/internal/app"
	contentv1 "kz/inflap/proto/gen/go/content/v1"
)

func (s *Server) ResolveSaveEligibility(
	ctx context.Context,
	req *contentv1.ResolveSaveEligibilityRequest,
) (*contentv1.ResolveSaveEligibilityResponse, error) {
	if savedSourceCallerFromContext(ctx) == "" {
		return nil, status.Error(codes.Unauthenticated, "missing or invalid service token")
	}
	if s == nil || s.savedSourceUseCase == nil {
		return nil, status.Error(codes.Unavailable, "saved source resolver is unavailable")
	}

	target := req.GetTarget()
	if target == nil || target.GetEntityType() != contentv1.SavedEntityType_SAVED_ENTITY_TYPE_GUIDE {
		return nil, status.Error(codes.InvalidArgument, "target must be a guide")
	}
	rawUserID := target.GetEntityId()
	userID, err := parseCanonicalGuideUserID(rawUserID)
	if err != nil {
		return nil, status.Error(codes.InvalidArgument, "target entity id must be a canonical guide user UUID")
	}

	resolution, err := s.savedSourceUseCase.ResolveGuide(ctx, userID)
	if err != nil {
		return nil, mapSavedGuideSourceError(err)
	}
	validatedAt, ok := requiredSavedGuideTimestamp(resolution.ValidatedAt)
	if !ok {
		return nil, status.Error(codes.Unavailable, "saved source validation time is unavailable")
	}
	if resolution.SourceRevision == 0 ||
		resolution.ProjectionRevision == 0 ||
		resolution.VisibilityRevision == 0 {
		return nil, status.Error(codes.Unavailable, "saved source revisions are unavailable")
	}

	response := &contentv1.ResolveSaveEligibilityResponse{
		Target: &contentv1.SavedTarget{
			EntityType: contentv1.SavedEntityType_SAVED_ENTITY_TYPE_GUIDE,
			EntityId:   rawUserID,
		},
		Eligibility: contentv1.SaveEligibility_SAVE_ELIGIBILITY_INELIGIBLE,
		Visibility:  contentv1.SavedTargetVisibility_SAVED_TARGET_VISIBILITY_UNAVAILABLE,
		Revisions: &contentv1.SavedSourceRevisions{
			SourceRevision:     resolution.SourceRevision,
			ProjectionRevision: resolution.ProjectionRevision,
			VisibilityRevision: resolution.VisibilityRevision,
		},
		ValidatedAt: validatedAt,
	}
	if resolution.Visibility == app.SavedGuideVisibilityDeleted {
		response.Visibility = contentv1.SavedTargetVisibility_SAVED_TARGET_VISIBILITY_DELETED
	}
	if !resolution.Eligible || resolution.Visibility != app.SavedGuideVisibilityPublic {
		return response, nil
	}
	projection, err := toProtoSavedGuideProjection(resolution.PublicProjection)
	if err != nil {
		return nil, status.Error(codes.Unavailable, "saved guide projection is unavailable")
	}
	response.Eligibility = contentv1.SaveEligibility_SAVE_ELIGIBILITY_ELIGIBLE
	response.Visibility = contentv1.SavedTargetVisibility_SAVED_TARGET_VISIBILITY_PUBLIC
	response.PublicProjection = projection
	return response, nil
}

func parseCanonicalGuideUserID(raw string) (uuid.UUID, error) {
	if raw == "" || raw != strings.TrimSpace(raw) || len(raw) != len(uuid.Nil.String()) {
		return uuid.Nil, app.ErrInvalidGuideUserID
	}
	parsed, err := uuid.Parse(raw)
	if err != nil || parsed == uuid.Nil || parsed.String() != raw {
		return uuid.Nil, app.ErrInvalidGuideUserID
	}
	return parsed, nil
}

func mapSavedGuideSourceError(err error) error {
	switch {
	case errors.Is(err, app.ErrInvalidGuideUserID):
		return status.Error(codes.InvalidArgument, "invalid guide target")
	case errors.Is(err, app.ErrGuideProfileNotFound):
		return status.Error(codes.NotFound, "saved target unavailable")
	case errors.Is(err, app.ErrSavedSourceUnavailable):
		return status.Error(codes.Unavailable, "guide source unavailable")
	default:
		return status.Error(codes.Internal, "failed to resolve saved target")
	}
}

func toProtoSavedGuideProjection(
	projection *app.SavedGuidePublicProjection,
) (*contentv1.SavedPublicCardProjection, error) {
	if projection == nil || strings.TrimSpace(projection.CanonicalDetailRoute) == "" {
		return nil, app.ErrSavedSourceUnavailable
	}
	sourceLocale := toProtoSavedGuideLocale(projection.SourceDefaultLocale)
	if sourceLocale == contentv1.SavedLocale_SAVED_LOCALE_UNSPECIFIED {
		return nil, app.ErrSavedSourceUnavailable
	}
	result := &contentv1.SavedPublicCardProjection{
		SourceDefaultLocale:  sourceLocale,
		CanonicalDetailRoute: projection.CanonicalDetailRoute,
		En:                   toProtoSavedGuideLocalized(projection.Localized["en"]),
		Ru:                   toProtoSavedGuideLocalized(projection.Localized["ru"]),
		Kk:                   toProtoSavedGuideLocalized(projection.Localized["kk"]),
	}
	if localizedForSavedGuideLocale(result, sourceLocale) == nil {
		return nil, app.ErrSavedSourceUnavailable
	}
	if projection.Rating != nil {
		if projection.AsOf == nil || projection.Rating.ScaleMax <= 0 ||
			projection.Rating.Value < 0 || projection.Rating.Value > projection.Rating.ScaleMax ||
			math.IsNaN(projection.Rating.Value) || math.IsInf(projection.Rating.Value, 0) ||
			math.IsNaN(projection.Rating.ScaleMax) || math.IsInf(projection.Rating.ScaleMax, 0) {
			return nil, app.ErrSavedSourceUnavailable
		}
		asOf, ok := requiredSavedGuideTimestamp(*projection.AsOf)
		if !ok {
			return nil, app.ErrSavedSourceUnavailable
		}
		result.AsOf = asOf
		result.Rating = &contentv1.SavedRatingSummary{
			Value:       projection.Rating.Value,
			ReviewCount: projection.Rating.ReviewCount,
			ScaleMax:    projection.Rating.ScaleMax,
		}
	}
	if projection.Media != nil {
		validUntil, ok := requiredSavedGuideTimestamp(projection.Media.ValidUntil)
		if !ok || projection.Media.ReferenceRevision == 0 ||
			strings.TrimSpace(projection.Media.OpaqueReference) == "" {
			return nil, app.ErrSavedSourceUnavailable
		}
		result.Media = &contentv1.SavedMediaReference{
			OpaqueReference:   projection.Media.OpaqueReference,
			ReferenceRevision: projection.Media.ReferenceRevision,
			ValidUntil:        validUntil,
		}
	}
	return result, nil
}

func toProtoSavedGuideLocalized(
	projection app.SavedGuideLocalizedProjection,
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

func toProtoSavedGuideLocale(locale string) contentv1.SavedLocale {
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

func localizedForSavedGuideLocale(
	projection *contentv1.SavedPublicCardProjection,
	locale contentv1.SavedLocale,
) *contentv1.SavedLocalizedCardProjection {
	switch locale {
	case contentv1.SavedLocale_SAVED_LOCALE_EN:
		return projection.GetEn()
	case contentv1.SavedLocale_SAVED_LOCALE_RU:
		return projection.GetRu()
	case contentv1.SavedLocale_SAVED_LOCALE_KK:
		return projection.GetKk()
	default:
		return nil
	}
}

func requiredSavedGuideTimestamp(value time.Time) (*timestamppb.Timestamp, bool) {
	timestamp := timestamppb.New(value.UTC())
	if err := timestamp.CheckValid(); err != nil {
		return nil, false
	}
	return timestamp, true
}
