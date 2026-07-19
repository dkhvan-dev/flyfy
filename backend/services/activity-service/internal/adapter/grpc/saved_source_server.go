package grpc

import (
	"context"
	"errors"
	"strings"

	"github.com/google/uuid"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/metadata"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/types/known/timestamppb"

	"kz/inflap/backend/pkg/serviceauth"
	"kz/inflap/backend/services/activity-service/internal/app"
	contentv1 "kz/inflap/proto/gen/go/content/v1"
)

const savedSourceResolveRole = "saved:resolve"

type ServiceAuthorizer interface {
	ValidateBearer(
		ctx context.Context,
		authHeader string,
		requiredRoles []string,
	) (*serviceauth.Claims, error)
}

type ServerOption func(*Server)

func WithSavedSource(
	useCase *app.SavedSourceUseCase,
	authorizer ServiceAuthorizer,
) ServerOption {
	return func(server *Server) {
		server.savedSourceUC = useCase
		server.serviceAuthorizer = authorizer
	}
}

func (s *Server) ResolveSaveEligibility(
	ctx context.Context,
	req *contentv1.ResolveSaveEligibilityRequest,
) (*contentv1.ResolveSaveEligibilityResponse, error) {
	if err := s.authorizeSavedSource(ctx); err != nil {
		return nil, err
	}
	if s.savedSourceUC == nil {
		return nil, status.Error(codes.Unavailable, "saved source resolver is unavailable")
	}

	target := req.GetTarget()
	if target == nil || target.GetEntityType() != contentv1.SavedEntityType_SAVED_ENTITY_TYPE_ACTIVITY {
		return nil, status.Error(codes.InvalidArgument, "target must be an activity")
	}
	rawActivityID := target.GetEntityId()
	activityID, err := parseCanonicalActivityID(rawActivityID)
	if err != nil {
		return nil, status.Error(codes.InvalidArgument, "target entity id must be a canonical activity UUID")
	}

	resolution, err := s.savedSourceUC.ResolveActivity(ctx, activityID)
	if err != nil {
		return nil, mapSavedSourceError(err)
	}

	validatedAt := timestamppb.New(resolution.ValidatedAt.UTC())
	if err = validatedAt.CheckValid(); err != nil {
		return nil, status.Error(codes.Unavailable, "saved source validation time is unavailable")
	}
	response := &contentv1.ResolveSaveEligibilityResponse{
		Target: &contentv1.SavedTarget{
			EntityType: target.GetEntityType(),
			EntityId:   rawActivityID,
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
	if resolution.Eligible && resolution.PublicProjection != nil {
		response.Eligibility = contentv1.SaveEligibility_SAVE_ELIGIBILITY_ELIGIBLE
		response.PublicProjection = toProtoSavedSourceProjection(resolution.PublicProjection)
	}
	return response, nil
}

func (s *Server) authorizeSavedSource(ctx context.Context) error {
	if s.serviceAuthorizer == nil {
		return status.Error(codes.Unavailable, "service authentication is unavailable")
	}
	md, _ := metadata.FromIncomingContext(ctx)
	values := md.Get("authorization")
	if len(values) != 1 || strings.TrimSpace(values[0]) == "" {
		return status.Error(codes.Unauthenticated, "missing or invalid service token")
	}
	_, err := s.serviceAuthorizer.ValidateBearer(
		ctx,
		values[0],
		[]string{savedSourceResolveRole},
	)
	if err == nil {
		return nil
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

func parseCanonicalActivityID(raw string) (uuid.UUID, error) {
	if raw == "" || raw != strings.TrimSpace(raw) {
		return uuid.Nil, app.ErrInvalidActivityID
	}
	parsed, err := uuid.Parse(raw)
	if err != nil || parsed.String() != raw {
		return uuid.Nil, app.ErrInvalidActivityID
	}
	return parsed, nil
}

func mapSavedSourceError(err error) error {
	switch {
	case errors.Is(err, app.ErrInvalidActivityID):
		return status.Error(codes.InvalidArgument, "invalid activity target")
	case errors.Is(err, app.ErrActivityNotFound):
		return status.Error(codes.NotFound, "saved target unavailable")
	case errors.Is(err, app.ErrSavedSourceUnavailable):
		return status.Error(codes.Unavailable, "activity source unavailable")
	default:
		return status.Error(codes.Internal, "failed to resolve saved target")
	}
}

func toProtoSavedSourceVisibility(
	visibility app.SavedSourceVisibility,
) contentv1.SavedTargetVisibility {
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

func toProtoSavedSourceProjection(
	projection *app.SavedSourcePublicProjection,
) *contentv1.SavedPublicCardProjection {
	if projection == nil {
		return nil
	}
	result := &contentv1.SavedPublicCardProjection{
		SourceDefaultLocale:  toProtoSavedLocale(projection.SourceDefaultLocale),
		CanonicalDetailRoute: projection.CanonicalDetailRoute,
		En:                   toProtoSavedLocalizedProjection(projection.Localized["en"]),
		Ru:                   toProtoSavedLocalizedProjection(projection.Localized["ru"]),
		Kk:                   toProtoSavedLocalizedProjection(projection.Localized["kk"]),
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
	case "kk":
		return contentv1.SavedLocale_SAVED_LOCALE_KK
	default:
		return contentv1.SavedLocale_SAVED_LOCALE_RU
	}
}
