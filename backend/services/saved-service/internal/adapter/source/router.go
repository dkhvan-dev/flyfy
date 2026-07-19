package source

import (
	"context"
	"errors"

	appsource "kz/inflap/backend/services/saved-service/internal/app/source"
	"kz/inflap/backend/services/saved-service/internal/domain"
)

var ErrInvalidResolverConfiguration = errors.New("saved source resolver configuration is invalid")

var routedEntityTypes = [...]domain.EntityType{
	domain.EntityTypeAttraction,
	domain.EntityTypeActivity,
	domain.EntityTypeUser,
	domain.EntityTypePost,
}

// Router selects the authoritative source by the closed Saved entity type.
type Router struct {
	resolvers map[domain.EntityType]appsource.Resolver
}

func NewRouter(
	resolvers map[domain.EntityType]appsource.Resolver,
) (*Router, error) {
	if len(resolvers) != len(routedEntityTypes) {
		return nil, ErrInvalidResolverConfiguration
	}
	copyByType := make(map[domain.EntityType]appsource.Resolver, len(routedEntityTypes))
	for _, entityType := range routedEntityTypes {
		resolver, exists := resolvers[entityType]
		if !exists || resolver == nil {
			return nil, ErrInvalidResolverConfiguration
		}
		copyByType[entityType] = resolver
	}
	return &Router{resolvers: copyByType}, nil
}

func (r *Router) Resolve(
	ctx context.Context,
	target domain.SavedTarget,
) (appsource.Resolution, error) {
	if !target.EntityType().IsValid() {
		return appsource.Resolution{}, domain.ErrTargetTypeUnsupported
	}
	if target.IsZero() {
		return appsource.Resolution{}, domain.ErrTargetUnavailable
	}
	if r == nil {
		return appsource.Resolution{}, domain.ErrDependencyUnavailable
	}
	resolver, exists := r.resolvers[target.EntityType()]
	if !exists || resolver == nil {
		return appsource.Resolution{}, domain.ErrDependencyUnavailable
	}

	result, err := resolver.Resolve(ctx, target)
	if err != nil {
		return appsource.Resolution{}, err
	}
	if result.Target.EntityType() != target.EntityType() ||
		result.Target.EntityID() != target.EntityID() ||
		result.Revisions.Source == 0 ||
		result.Revisions.Projection == 0 ||
		result.Revisions.Visibility == 0 ||
		result.ValidatedAt.IsZero() ||
		!isResolvedVisibility(result.Visibility) ||
		(result.Visibility == domain.VisibilityPrivate && target.EntityType() != domain.EntityTypeActivity) ||
		(result.Eligible != (result.Visibility == domain.VisibilityPublic)) ||
		(result.Eligible != (result.PublicProjection != nil)) {
		return appsource.Resolution{}, domain.ErrDependencyUnavailable
	}
	return result, nil
}

func isResolvedVisibility(visibility domain.VisibilityStatus) bool {
	switch visibility {
	case domain.VisibilityPublic,
		domain.VisibilityPrivate,
		domain.VisibilityUnavailable,
		domain.VisibilityDeleted,
		domain.VisibilityRestricted:
		return true
	default:
		return false
	}
}
