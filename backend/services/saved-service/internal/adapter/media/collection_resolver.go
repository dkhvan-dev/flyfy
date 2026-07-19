package media

import (
	"context"

	"github.com/google/uuid"

	"kz/inflap/backend/services/saved-service/internal/app/savedcollection"
	"kz/inflap/backend/services/saved-service/internal/app/savedquery"
)

var _ savedcollection.ThumbnailResolver = (*RouteResolver)(nil)
var _ savedquery.ImageResolver = (*RouteResolver)(nil)

func (resolver *RouteResolver) ResolveCollectionThumbnails(
	ctx context.Context,
	requests []savedcollection.ThumbnailRequest,
) (map[uuid.UUID]string, error) {
	if ctx == nil {
		return nil, ErrInvalidReference
	}
	if err := ctx.Err(); err != nil {
		return nil, err
	}
	resolved := make(map[uuid.UUID]string, len(requests))
	for _, request := range requests {
		if err := ctx.Err(); err != nil {
			return nil, err
		}
		if request.CollectionID == uuid.Nil {
			continue
		}
		value, err := resolver.Resolve(Reference{
			Target:            request.Target,
			OpaqueReference:   request.OpaqueReference,
			ReferenceRevision: request.ReferenceRevision,
		})
		if err != nil {
			continue
		}
		resolved[request.CollectionID] = value
	}
	return resolved, nil
}

func (resolver *RouteResolver) ResolveItemImages(
	ctx context.Context,
	requests []savedquery.ImageRequest,
) (map[uuid.UUID]string, error) {
	if ctx == nil {
		return nil, ErrInvalidReference
	}
	if err := ctx.Err(); err != nil {
		return nil, err
	}
	resolved := make(map[uuid.UUID]string, len(requests))
	for _, request := range requests {
		if err := ctx.Err(); err != nil {
			return nil, err
		}
		if request.ItemID == uuid.Nil {
			continue
		}
		value, err := resolver.Resolve(Reference{
			Target:            request.Target,
			OpaqueReference:   request.OpaqueReference,
			ReferenceRevision: request.ReferenceRevision,
		})
		if err != nil {
			continue
		}
		resolved[request.ItemID] = value
	}
	return resolved, nil
}
