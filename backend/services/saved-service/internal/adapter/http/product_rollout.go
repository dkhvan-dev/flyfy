package http

import (
	"context"
	"net/http"
	"strconv"

	"kz/inflap/backend/services/saved-service/internal/app/productrollout"
	"kz/inflap/backend/services/saved-service/internal/domain"
)

const (
	HeaderClientPlatform = "X-Client-Platform"
	HeaderAppBuild       = "X-App-Build"
)

type productRolloutContextKey struct{}

type ProductRolloutMiddleware struct {
	gate productrollout.Gate
}

func NewProductRolloutMiddleware(gate productrollout.Gate) (*ProductRolloutMiddleware, error) {
	if gate == nil {
		return nil, ErrInvalidPersonalRouterDependencies
	}
	return &ProductRolloutMiddleware{gate: gate}, nil
}

// Wrap fails closed only for product expansion. Canonical reads and reduction
// actions continue even when client metadata is absent or malformed.
func (middleware *ProductRolloutMiddleware) Wrap(next http.Handler) http.Handler {
	if middleware == nil || middleware.gate == nil || next == nil {
		return http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
			if next != nil {
				next.ServeHTTP(writer, request)
				return
			}
			http.Error(writer, "service unavailable", http.StatusServiceUnavailable)
		})
	}
	return http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		decision := productrollout.Decision{}
		principal, ok := PersonalPrincipalFromContext(request.Context())
		if ok {
			build, err := strconv.ParseUint(request.Header.Get(HeaderAppBuild), 10, 64)
			platform := productrollout.Platform(request.Header.Get(HeaderClientPlatform))
			if err == nil {
				evaluated, evaluationErr := middleware.gate.Evaluate(request.Context(), productrollout.Request{
					OwnerID:  principal.UserID,
					Platform: platform,
					Build:    build,
				})
				if evaluationErr == nil {
					decision = evaluated
				}
			}
		}
		ctx := context.WithValue(request.Context(), productRolloutContextKey{}, decision)
		next.ServeHTTP(writer, request.WithContext(ctx))
	})
}

func ProductRolloutDecisionFromContext(ctx context.Context) (productrollout.Decision, bool) {
	if ctx == nil {
		return productrollout.Decision{}, false
	}
	decision, ok := ctx.Value(productRolloutContextKey{}).(productrollout.Decision)
	return decision, ok
}

func productExpansionAllowed(ctx context.Context, capability productrollout.Capability) bool {
	decision, evaluated := ProductRolloutDecisionFromContext(ctx)
	return !evaluated || decision.Allows(capability)
}

func entityRolloutCapability(entityType domain.EntityType) productrollout.Capability {
	switch entityType {
	case domain.EntityTypeAttraction:
		return productrollout.CapabilityEntityAttraction
	case domain.EntityTypeActivity:
		return productrollout.CapabilityEntityActivity
	case domain.EntityTypeUser:
		return productrollout.CapabilityEntityUser
	case domain.EntityTypePost:
		return productrollout.CapabilityEntityPost
	default:
		return ""
	}
}

func savedTargetExpansionAllowed(ctx context.Context, target domain.SavedTarget) bool {
	capability := entityRolloutCapability(target.EntityType())
	return productExpansionAllowed(ctx, productrollout.CapabilitySavedCore) &&
		capability.IsValid() && productExpansionAllowed(ctx, capability)
}
