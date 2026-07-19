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
	"kz/inflap/backend/services/feed-service/internal/app"
	contentv1 "kz/inflap/proto/gen/go/content/v1"
)

const savedPostSourceResolveRole = "saved:resolve"

type SavedPostServiceAuthorizer interface {
	ValidateBearer(context.Context, string, []string) (*serviceauth.Claims, error)
}

type SavedPostSourceServer struct {
	contentv1.UnimplementedSavedSourceServiceServer

	useCase    *app.SavedPostSourceUseCase
	authorizer SavedPostServiceAuthorizer
}

func NewSavedPostSourceServer(
	useCase *app.SavedPostSourceUseCase,
	authorizer SavedPostServiceAuthorizer,
) *SavedPostSourceServer {
	return &SavedPostSourceServer{useCase: useCase, authorizer: authorizer}
}

func (server *SavedPostSourceServer) ResolveSaveEligibility(
	ctx context.Context,
	request *contentv1.ResolveSaveEligibilityRequest,
) (*contentv1.ResolveSaveEligibilityResponse, error) {
	if err := server.authorize(ctx); err != nil {
		return nil, err
	}
	if server == nil || server.useCase == nil {
		return nil, status.Error(codes.Unavailable, "saved post source is unavailable")
	}
	target := request.GetTarget()
	if target == nil || target.GetEntityType() != contentv1.SavedEntityType_SAVED_ENTITY_TYPE_POST {
		return nil, status.Error(codes.InvalidArgument, "target must be a post")
	}
	postID, err := parseCanonicalSavedPostID(target.GetEntityId())
	if err != nil {
		return nil, status.Error(codes.InvalidArgument, "target entity id must be a canonical post UUID")
	}

	resolution, err := server.useCase.ResolvePost(ctx, postID)
	if err != nil {
		return nil, mapSavedPostSourceError(err)
	}
	validatedAt := timestamppb.New(resolution.ValidatedAt.UTC())
	if validatedAt.CheckValid() != nil || resolution.SourceRevision == 0 ||
		resolution.ProjectionRevision == 0 || resolution.VisibilityRevision == 0 {
		return nil, status.Error(codes.Unavailable, "saved post source revisions are unavailable")
	}
	response := &contentv1.ResolveSaveEligibilityResponse{
		Target: &contentv1.SavedTarget{
			EntityType: contentv1.SavedEntityType_SAVED_ENTITY_TYPE_POST,
			EntityId:   target.GetEntityId(),
		},
		Eligibility: contentv1.SaveEligibility_SAVE_ELIGIBILITY_INELIGIBLE,
		Visibility:  toProtoSavedPostVisibility(resolution.Visibility),
		Revisions: &contentv1.SavedSourceRevisions{
			SourceRevision:     resolution.SourceRevision,
			ProjectionRevision: resolution.ProjectionRevision,
			VisibilityRevision: resolution.VisibilityRevision,
		},
		ValidatedAt: validatedAt,
	}
	if !resolution.Eligible || resolution.Visibility != app.SavedPostSourceVisibilityPublic {
		return response, nil
	}
	projection := toProtoSavedPostProjection(resolution.PublicProjection)
	if projection == nil {
		return nil, status.Error(codes.Unavailable, "saved post projection is unavailable")
	}
	response.Eligibility = contentv1.SaveEligibility_SAVE_ELIGIBILITY_ELIGIBLE
	response.PublicProjection = projection
	return response, nil
}

func (server *SavedPostSourceServer) authorize(ctx context.Context) error {
	if server == nil || server.authorizer == nil {
		return status.Error(codes.Unavailable, "service authentication is unavailable")
	}
	values := []string(nil)
	if incoming, ok := metadata.FromIncomingContext(ctx); ok {
		values = incoming.Get("authorization")
	}
	if len(values) != 1 || strings.TrimSpace(values[0]) == "" {
		return status.Error(codes.Unauthenticated, "missing or invalid service token")
	}
	_, err := server.authorizer.ValidateBearer(
		ctx,
		values[0],
		[]string{savedPostSourceResolveRole},
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

func parseCanonicalSavedPostID(raw string) (uuid.UUID, error) {
	if raw == "" || raw != strings.TrimSpace(raw) || len(raw) != len(uuid.Nil.String()) {
		return uuid.Nil, app.ErrInvalidPostID
	}
	parsed, err := uuid.Parse(raw)
	if err != nil || parsed == uuid.Nil || parsed.String() != raw {
		return uuid.Nil, app.ErrInvalidPostID
	}
	return parsed, nil
}

func mapSavedPostSourceError(err error) error {
	switch {
	case errors.Is(err, app.ErrInvalidPostID):
		return status.Error(codes.InvalidArgument, "invalid post target")
	case errors.Is(err, app.ErrPostNotFound):
		return status.Error(codes.NotFound, "saved target unavailable")
	case errors.Is(err, context.Canceled):
		return status.Error(codes.Canceled, "saved source request canceled")
	case errors.Is(err, context.DeadlineExceeded):
		return status.Error(codes.DeadlineExceeded, "saved source deadline exceeded")
	case errors.Is(err, app.ErrSavedPostSourceUnavailable):
		return status.Error(codes.Unavailable, "post source unavailable")
	default:
		return status.Error(codes.Internal, "failed to resolve saved target")
	}
}

func toProtoSavedPostProjection(
	projection *app.SavedPostPublicProjection,
) *contentv1.SavedPublicCardProjection {
	if projection == nil || strings.TrimSpace(projection.CanonicalDetailRoute) == "" {
		return nil
	}
	result := &contentv1.SavedPublicCardProjection{
		SourceDefaultLocale:  contentv1.SavedLocale_SAVED_LOCALE_EN,
		CanonicalDetailRoute: projection.CanonicalDetailRoute,
		En:                   toProtoSavedPostLocalized(projection.Localized["en"]),
		Ru:                   toProtoSavedPostLocalized(projection.Localized["ru"]),
		Kk:                   toProtoSavedPostLocalized(projection.Localized["kk"]),
	}
	if result.GetEn() == nil || result.GetRu() == nil || result.GetKk() == nil {
		return nil
	}
	if projection.Media != nil {
		validUntil := timestamppb.New(projection.Media.ValidUntil.UTC())
		if validUntil.CheckValid() != nil || projection.Media.ReferenceRevision == 0 ||
			strings.TrimSpace(projection.Media.OpaqueReference) == "" {
			return nil
		}
		result.Media = &contentv1.SavedMediaReference{
			OpaqueReference:   projection.Media.OpaqueReference,
			ReferenceRevision: projection.Media.ReferenceRevision,
			ValidUntil:        validUntil,
		}
	}
	return result
}

func toProtoSavedPostLocalized(
	projection app.SavedPostLocalizedProjection,
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

func toProtoSavedPostVisibility(
	visibility app.SavedPostSourceVisibility,
) contentv1.SavedTargetVisibility {
	switch visibility {
	case app.SavedPostSourceVisibilityPublic:
		return contentv1.SavedTargetVisibility_SAVED_TARGET_VISIBILITY_PUBLIC
	case app.SavedPostSourceVisibilityDeleted:
		return contentv1.SavedTargetVisibility_SAVED_TARGET_VISIBILITY_DELETED
	case app.SavedPostSourceVisibilityRestricted:
		return contentv1.SavedTargetVisibility_SAVED_TARGET_VISIBILITY_RESTRICTED
	default:
		return contentv1.SavedTargetVisibility_SAVED_TARGET_VISIBILITY_UNAVAILABLE
	}
}
