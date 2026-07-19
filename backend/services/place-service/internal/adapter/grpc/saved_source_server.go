package grpc

import (
	"context"
	"errors"
	"strings"
	"unicode/utf8"

	"github.com/google/uuid"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/metadata"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/types/known/timestamppb"

	"kz/inflap/backend/pkg/serviceauth"
	"kz/inflap/backend/services/place-service/internal/app"
	contentv1 "kz/inflap/proto/gen/go/content/v1"
)

const (
	SavedSourceResolveRole = "saved:resolve"
	canonicalUUIDLength    = 36
)

type ServiceAuthorizer interface {
	ValidateBearer(
		ctx context.Context,
		authHeader string,
		requiredRoles []string,
	) (*serviceauth.Claims, error)
}

type SavedSourceServer struct {
	contentv1.UnimplementedSavedSourceServiceServer

	useCase    *app.SavedSourceUseCase
	authorizer ServiceAuthorizer
}

func NewSavedSourceServer(
	useCase *app.SavedSourceUseCase,
	authorizer ServiceAuthorizer,
) *SavedSourceServer {
	return &SavedSourceServer{
		useCase:    useCase,
		authorizer: authorizer,
	}
}

func RegisterSavedSourceServer(
	registrar grpc.ServiceRegistrar,
	server *SavedSourceServer,
) {
	contentv1.RegisterSavedSourceServiceServer(registrar, server)
}

func (s *SavedSourceServer) ResolveSaveEligibility(
	ctx context.Context,
	request *contentv1.ResolveSaveEligibilityRequest,
) (*contentv1.ResolveSaveEligibilityResponse, error) {
	if err := s.authorize(ctx); err != nil {
		return nil, err
	}
	if s == nil || s.useCase == nil {
		return nil, status.Error(codes.Unavailable, "saved source resolver is unavailable")
	}

	target := request.GetTarget()
	if target == nil ||
		target.GetEntityType() != contentv1.SavedEntityType_SAVED_ENTITY_TYPE_ATTRACTION {
		return nil, status.Error(codes.InvalidArgument, "target must be an attraction")
	}
	rawID := target.GetEntityId()
	attractionID, err := parseCanonicalAttractionID(rawID)
	if err != nil {
		return nil, status.Error(codes.InvalidArgument, "target entity id must be a canonical attraction UUID")
	}

	resolution, err := s.useCase.ResolveAttraction(ctx, attractionID)
	if err != nil {
		return nil, mapSavedSourceError(err)
	}
	response, err := toResolveSaveEligibilityResponse(target, resolution)
	if err != nil {
		return nil, err
	}
	return response, nil
}

func (s *SavedSourceServer) authorize(ctx context.Context) error {
	if s == nil || s.authorizer == nil {
		return status.Error(codes.Unavailable, "service authentication is unavailable")
	}
	requestMetadata, _ := metadata.FromIncomingContext(ctx)
	values := requestMetadata.Get("authorization")
	if len(values) != 1 || strings.TrimSpace(values[0]) == "" {
		return status.Error(codes.Unauthenticated, "missing or invalid service token")
	}
	claims, err := s.authorizer.ValidateBearer(
		ctx,
		values[0],
		[]string{SavedSourceResolveRole},
	)
	if err == nil && claims != nil && strings.TrimSpace(claims.Subject) != "" {
		return nil
	}
	if err == nil {
		return status.Error(codes.Unauthenticated, "missing or invalid service token")
	}
	switch {
	case serviceauth.IsForbidden(err):
		return status.Error(codes.PermissionDenied, "service is not allowed")
	case serviceauth.IsUnauthorized(err):
		return status.Error(codes.Unauthenticated, "missing or invalid service token")
	default:
		return status.Error(codes.Unavailable, "service authentication is unavailable")
	}
}

func parseCanonicalAttractionID(raw string) (uuid.UUID, error) {
	if len(raw) != canonicalUUIDLength ||
		raw != strings.TrimSpace(raw) ||
		!utf8.ValidString(raw) {
		return uuid.Nil, app.ErrInvalidPlaceID
	}
	for _, character := range raw {
		if character < 0x20 || character == 0x7f {
			return uuid.Nil, app.ErrInvalidPlaceID
		}
	}
	parsed, err := uuid.Parse(raw)
	if err != nil || parsed == uuid.Nil || parsed.String() != raw {
		return uuid.Nil, app.ErrInvalidPlaceID
	}
	return parsed, nil
}

func mapSavedSourceError(err error) error {
	switch {
	case errors.Is(err, app.ErrInvalidPlaceID):
		return status.Error(codes.InvalidArgument, "invalid attraction target")
	case errors.Is(err, app.ErrAttractionNotFound):
		return status.Error(codes.NotFound, "saved target unavailable")
	case errors.Is(err, app.ErrSavedSourceUnavailable):
		return status.Error(codes.Unavailable, "attraction source unavailable")
	default:
		return status.Error(codes.Internal, "failed to resolve saved target")
	}
}

func toResolveSaveEligibilityResponse(
	target *contentv1.SavedTarget,
	resolution *app.SavedSourceResolution,
) (*contentv1.ResolveSaveEligibilityResponse, error) {
	if resolution == nil ||
		resolution.SourceRevision == 0 ||
		resolution.ProjectionRevision == 0 ||
		resolution.VisibilityRevision == 0 {
		return nil, status.Error(codes.Unavailable, "attraction source revisions are unavailable")
	}
	validatedAt := timestamppb.New(resolution.ValidatedAt.UTC())
	if err := validatedAt.CheckValid(); err != nil {
		return nil, status.Error(codes.Unavailable, "saved source validation time is unavailable")
	}

	response := &contentv1.ResolveSaveEligibilityResponse{
		Target: &contentv1.SavedTarget{
			EntityType: target.GetEntityType(),
			EntityId:   target.GetEntityId(),
		},
		Eligibility: contentv1.SaveEligibility_SAVE_ELIGIBILITY_INELIGIBLE,
		Visibility:  toProtoSavedSourceVisibility(resolution.Visibility),
		Revisions: &contentv1.SavedSourceRevisions{
			SourceRevision:     resolution.SourceRevision,
			ProjectionRevision: resolution.ProjectionRevision,
			VisibilityRevision: resolution.VisibilityRevision,
		},
		ValidatedAt: validatedAt,
	}
	if !resolution.Eligible {
		return response, nil
	}
	if resolution.Visibility != app.SavedSourceVisibilityPublic ||
		resolution.PublicProjection == nil {
		return nil, status.Error(codes.Unavailable, "attraction public projection is unavailable")
	}
	projection, err := toProtoSavedSourceProjection(resolution.PublicProjection)
	if err != nil {
		return nil, err
	}
	response.Eligibility = contentv1.SaveEligibility_SAVE_ELIGIBILITY_ELIGIBLE
	response.PublicProjection = projection
	return response, nil
}

func toProtoSavedSourceVisibility(
	visibility app.SavedSourceVisibility,
) contentv1.SavedTargetVisibility {
	switch visibility {
	case app.SavedSourceVisibilityPublic:
		return contentv1.SavedTargetVisibility_SAVED_TARGET_VISIBILITY_PUBLIC
	case app.SavedSourceVisibilityDeleted:
		return contentv1.SavedTargetVisibility_SAVED_TARGET_VISIBILITY_DELETED
	case app.SavedSourceVisibilityRestricted:
		return contentv1.SavedTargetVisibility_SAVED_TARGET_VISIBILITY_RESTRICTED
	default:
		return contentv1.SavedTargetVisibility_SAVED_TARGET_VISIBILITY_UNAVAILABLE
	}
}

func toProtoSavedSourceProjection(
	projection *app.SavedSourcePublicProjection,
) (*contentv1.SavedPublicCardProjection, error) {
	if projection == nil ||
		len(projection.CanonicalDetailRoute) > 256 ||
		!strings.HasPrefix(projection.CanonicalDetailRoute, "/places/") {
		return nil, status.Error(codes.Unavailable, "attraction detail route is unavailable")
	}
	result := &contentv1.SavedPublicCardProjection{
		SourceDefaultLocale:  toProtoSavedLocale(projection.SourceDefaultLocale),
		CanonicalDetailRoute: projection.CanonicalDetailRoute,
		En:                   toProtoSavedLocalizedProjection(projection.Localized["en"]),
		Ru:                   toProtoSavedLocalizedProjection(projection.Localized["ru"]),
		Kk:                   toProtoSavedLocalizedProjection(projection.Localized["kk"]),
	}
	if result.SourceDefaultLocale == contentv1.SavedLocale_SAVED_LOCALE_UNSPECIFIED {
		return nil, status.Error(codes.Unavailable, "attraction source locale is unavailable")
	}
	if (result.SourceDefaultLocale == contentv1.SavedLocale_SAVED_LOCALE_EN && result.En == nil) ||
		(result.SourceDefaultLocale == contentv1.SavedLocale_SAVED_LOCALE_RU && result.Ru == nil) ||
		(result.SourceDefaultLocale == contentv1.SavedLocale_SAVED_LOCALE_KK && result.Kk == nil) {
		return nil, status.Error(codes.Unavailable, "attraction source locale payload is unavailable")
	}
	if projection.Rating != nil {
		if projection.AsOf == nil ||
			projection.Rating.ScaleMax <= 0 ||
			projection.Rating.Value < 0 ||
			projection.Rating.Value > projection.Rating.ScaleMax {
			return nil, status.Error(codes.Unavailable, "attraction rating is unavailable")
		}
		result.Rating = &contentv1.SavedRatingSummary{
			Value:       projection.Rating.Value,
			ReviewCount: projection.Rating.ReviewCount,
			ScaleMax:    projection.Rating.ScaleMax,
		}
	}
	if projection.AsOf != nil {
		result.AsOf = timestamppb.New(projection.AsOf.UTC())
		if err := result.AsOf.CheckValid(); err != nil {
			return nil, status.Error(codes.Unavailable, "attraction projection timestamp is unavailable")
		}
	}
	if projection.Media != nil {
		if strings.TrimSpace(projection.Media.OpaqueReference) == "" ||
			len(projection.Media.OpaqueReference) > 512 ||
			projection.Media.ReferenceRevision == 0 {
			return nil, status.Error(codes.Unavailable, "attraction media reference is unavailable")
		}
		validUntil := timestamppb.New(projection.Media.ValidUntil.UTC())
		if err := validUntil.CheckValid(); err != nil {
			return nil, status.Error(codes.Unavailable, "attraction media lease is unavailable")
		}
		result.Media = &contentv1.SavedMediaReference{
			OpaqueReference:   projection.Media.OpaqueReference,
			ReferenceRevision: projection.Media.ReferenceRevision,
			ValidUntil:        validUntil,
		}
	}
	return result, nil
}

func toProtoSavedLocalizedProjection(
	projection app.SavedSourceLocalizedProjection,
) *contentv1.SavedLocalizedCardProjection {
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

func toProtoSavedLocale(locale string) contentv1.SavedLocale {
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
