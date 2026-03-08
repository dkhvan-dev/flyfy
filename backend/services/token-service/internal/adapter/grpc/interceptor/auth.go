package interceptor

import (
	"context"
	"strings"

	"github.com/rs/zerolog"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/metadata"
	"google.golang.org/grpc/status"

	"github.com/dkhvan-dev/flyfy/backend/services/token-service/internal/domain/model"
	"github.com/dkhvan-dev/flyfy/backend/services/token-service/internal/domain/port"
)

type contextKey string

const (
	CallerServiceKey contextKey = "caller_service"
	CallerRolesKey   contextKey = "caller_roles"
)

// MethodPermissions maps gRPC full method names to required roles.
// A nil slice means the method is public (no auth required).
// An empty slice means only authentication is required (any role).
type MethodPermissions map[string][]string

// ServiceAuthInterceptor validates service tokens and checks RBAC on every gRPC call.
func ServiceAuthInterceptor(
	validator port.TokenValidator,
	audit port.AuditLogger,
	permissions MethodPermissions,
	logger zerolog.Logger,
) grpc.UnaryServerInterceptor {
	log := logger.With().Str("component", "s2s_interceptor").Logger()

	return func(
		ctx context.Context,
		req any,
		info *grpc.UnaryServerInfo,
		handler grpc.UnaryHandler,
	) (any, error) {
		// Check if this method requires auth
		requiredRoles, requiresAuth := permissions[info.FullMethod]
		if !requiresAuth {
			// Method is public (e.g., JWKS endpoint or health check)
			return handler(ctx, req)
		}

		// 1. Extract token from gRPC metadata
		md, ok := metadata.FromIncomingContext(ctx)
		if !ok {
			return nil, status.Error(codes.Unauthenticated, "missing metadata")
		}

		authHeaders := md.Get("authorization")
		if len(authHeaders) == 0 {
			return nil, status.Error(codes.Unauthenticated, "missing authorization header")
		}

		tokenStr := strings.TrimPrefix(authHeaders[0], "Bearer ")
		if tokenStr == authHeaders[0] {
			return nil, status.Error(codes.Unauthenticated, "invalid authorization format, expected: Bearer <token>")
		}

		// 2. Validate the service token
		claims, err := validator.ValidateServiceToken(ctx, tokenStr)
		if err != nil {
			log.Warn().
				Err(err).
				Str("method", info.FullMethod).
				Msg("service token validation failed")

			return nil, status.Errorf(codes.Unauthenticated, "invalid service token: %v", err)
		}

		// 3. Verify this is indeed a service token
		if claims.Type != model.TokenTypeService {
			return nil, status.Error(codes.PermissionDenied, "expected service token, got user token")
		}

		// 4. Check required roles (if any specified)
		if len(requiredRoles) > 0 && !hasAllRoles(claims.Roles, requiredRoles) {
			missing := findMissingRoles(claims.Roles, requiredRoles)

			audit.LogServiceAuth(ctx, claims.Subject, info.FullMethod, "denied", map[string]string{
				"missing_roles": strings.Join(missing, ","),
			})

			log.Warn().
				Str("caller", claims.Subject).
				Str("method", info.FullMethod).
				Strs("missing_roles", missing).
				Msg("service auth denied: insufficient roles")

			return nil, status.Errorf(
				codes.PermissionDenied,
				"service %q lacks required roles: %v",
				claims.Subject, missing,
			)
		}

		// 5. Audit: granted
		audit.LogServiceAuth(ctx, claims.Subject, info.FullMethod, "granted", nil)

		// 6. Inject caller info into context for downstream use
		ctx = context.WithValue(ctx, CallerServiceKey, claims.Subject)
		ctx = context.WithValue(ctx, CallerRolesKey, claims.Roles)

		return handler(ctx, req)
	}
}

// CallerFromContext extracts the calling service ID from the context.
func CallerFromContext(ctx context.Context) string {
	if v, ok := ctx.Value(CallerServiceKey).(string); ok {
		return v
	}
	return "unknown"
}

// CallerRolesFromContext extracts the calling service's roles from the context.
func CallerRolesFromContext(ctx context.Context) []string {
	if v, ok := ctx.Value(CallerRolesKey).([]string); ok {
		return v
	}
	return nil
}

// hasAllRoles checks that the service has every required role.
func hasAllRoles(serviceRoles, requiredRoles []string) bool {
	roleSet := make(map[string]struct{}, len(serviceRoles))
	for _, r := range serviceRoles {
		roleSet[r] = struct{}{}
	}
	for _, req := range requiredRoles {
		if _, ok := roleSet[req]; !ok {
			return false
		}
	}
	return true
}

// findMissingRoles returns roles that are required but not present.
func findMissingRoles(serviceRoles, requiredRoles []string) []string {
	roleSet := make(map[string]struct{}, len(serviceRoles))
	for _, r := range serviceRoles {
		roleSet[r] = struct{}{}
	}

	var missing []string
	for _, req := range requiredRoles {
		if _, ok := roleSet[req]; !ok {
			missing = append(missing, req)
		}
	}
	return missing
}
