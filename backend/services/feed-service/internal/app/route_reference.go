package app

import (
	"context"
	"errors"
	"fmt"
	"strings"

	"github.com/google/uuid"

	"kz/inflap/backend/services/feed-service/internal/domain/model"
)

type PostRouteReferenceValidator interface {
	ValidatePostRouteReference(ctx context.Context, input PostRouteReferenceValidationInput) error
}

type PostRouteReferenceValidationInput struct {
	AuthorUserID uuid.UUID
	RouteID      string
}

func (u *PostUseCase) WithRouteReferenceValidator(validator PostRouteReferenceValidator) *PostUseCase {
	u.routeReferenceValidator = validator
	return u
}

func (u *PostUseCase) validatePostRouteReferences(
	ctx context.Context,
	authorUserID uuid.UUID,
	document model.PostDocument,
) error {
	routeIDs := routeReferenceIDs(document)
	if len(routeIDs) == 0 {
		return nil
	}
	if authorUserID == uuid.Nil {
		return routeReferenceValidationError("route_reference_not_shareable")
	}
	if u == nil || u.routeReferenceValidator == nil {
		return routeReferenceValidationError("route_reference_validator_unavailable")
	}

	for _, routeID := range routeIDs {
		if err := u.routeReferenceValidator.ValidatePostRouteReference(ctx, PostRouteReferenceValidationInput{
			AuthorUserID: authorUserID,
			RouteID:      routeID,
		}); err != nil {
			if errors.Is(err, ErrInvalidPostRouteReference) {
				return fmt.Errorf("%w: %v", routeReferenceValidationError("route_reference_not_shareable"), err)
			}
			return fmt.Errorf("validate post route reference %q: %w", routeID, err)
		}
	}
	return nil
}

func routeReferenceIDs(document model.PostDocument) []string {
	seen := make(map[string]struct{})
	ids := make([]string, 0, 2)
	for _, block := range document.Blocks {
		if block.Type != model.PostBlockTypeRouteReference {
			continue
		}
		routeID := strings.TrimSpace(block.RouteID)
		if routeID == "" {
			continue
		}
		if _, ok := seen[routeID]; ok {
			continue
		}
		seen[routeID] = struct{}{}
		ids = append(ids, routeID)
	}
	return ids
}

func routeReferenceValidationError(code string) *PostValidationError {
	return NewPostValidationError(
		map[string]string{"contentBlocks": code},
		ErrInvalidPostContent,
		ErrInvalidPostRouteReference,
	)
}
