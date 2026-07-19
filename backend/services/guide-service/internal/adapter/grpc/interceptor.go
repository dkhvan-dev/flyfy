package grpc

import (
	"context"
	"crypto/subtle"
	"strings"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/metadata"
	"google.golang.org/grpc/status"

	"kz/inflap/backend/pkg/serviceauth"
	"kz/inflap/backend/services/guide-service/internal/config"
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

func UnaryServerInterceptor(
	cfg *config.Config,
	savedSourceAuthorizer ServiceAuthorizer,
) grpc.UnaryServerInterceptor {
	return func(
		ctx context.Context,
		req any,
		info *grpc.UnaryServerInfo,
		handler grpc.UnaryHandler,
	) (any, error) {
		md, _ := metadata.FromIncomingContext(ctx)

		requestID := firstMetadataValue(md, "x-request-id")
		if requestID == "" {
			requestID = uuid.NewString()
		}
		ctx = withRequestID(ctx, requestID)

		if info.FullMethod == contentv1.SavedSourceService_ResolveSaveEligibility_FullMethodName {
			var authErr error
			ctx, authErr = authorizeSavedSourceRequest(ctx, md, cfg, savedSourceAuthorizer)
			if authErr != nil {
				return nil, authErr
			}
		} else {
			if cfg == nil {
				return nil, status.Error(codes.Unavailable, "service authentication is unavailable")
			}
			internalToken := firstMetadataValue(md, "x-internal-service-token")
			if internalToken == "" {
				return nil, status.Error(codes.Unauthenticated, "missing internal service token")
			}

			if subtle.ConstantTimeCompare([]byte(internalToken), []byte(cfg.Security.InternalServiceToken)) != 1 {
				return nil, status.Error(codes.Unauthenticated, "invalid internal service token")
			}

			if serviceName := firstMetadataValue(md, "x-service-name"); serviceName != "" {
				ctx = withService(ctx, serviceName)
			}
			if subject := firstMetadataValue(md, "x-subject"); subject != "" {
				ctx = withSubject(ctx, subject)
			}
		}

		resp, err := handler(ctx, req)

		logger := log.Info().
			Str("transport", "grpc").
			Str("method", info.FullMethod).
			Str("request_id", RequestIDFromContext(ctx))

		if service := ServiceFromContext(ctx); service != "" {
			logger = logger.Str("caller_service", service)
		}
		if subject := SubjectFromContext(ctx); subject != "" {
			logger = logger.Str("subject", subject)
		}
		if err != nil {
			st, _ := status.FromError(err)
			logger = logger.Str("grpc_code", st.Code().String()).Err(err)
		}

		logger.Msg("grpc request completed")
		return resp, err
	}
}

func authorizeSavedSourceRequest(
	ctx context.Context,
	md metadata.MD,
	cfg *config.Config,
	authorizer ServiceAuthorizer,
) (context.Context, error) {
	if cfg == nil || authorizer == nil {
		return ctx, status.Error(codes.Unavailable, "service authentication is unavailable")
	}
	authValues := md.Get("authorization")
	if len(authValues) != 1 || strings.TrimSpace(authValues[0]) == "" {
		return ctx, status.Error(codes.Unauthenticated, "missing or invalid service token")
	}
	claims, err := authorizer.ValidateBearer(
		ctx,
		authValues[0],
		[]string{savedSourceResolveRole},
	)
	if err != nil {
		switch {
		case serviceauth.IsForbidden(err):
			return ctx, status.Error(codes.PermissionDenied, "service is not allowed")
		case serviceauth.IsUnauthorized(err):
			return ctx, status.Error(codes.Unauthenticated, "missing or invalid service token")
		default:
			return ctx, status.Error(codes.Unavailable, "service authentication is unavailable")
		}
	}
	allowedCaller := strings.TrimSpace(cfg.Security.SavedSourceAllowedCaller)
	if claims == nil || allowedCaller == "" || claims.Subject != allowedCaller {
		return ctx, status.Error(codes.PermissionDenied, "service is not allowed")
	}
	ctx = withSavedSourceCaller(ctx, claims.Subject)
	ctx = withService(ctx, claims.Subject)
	return ctx, nil
}

func firstMetadataValue(md metadata.MD, key string) string {
	values := md.Get(strings.ToLower(strings.TrimSpace(key)))
	if len(values) == 0 {
		return ""
	}
	return strings.TrimSpace(values[0])
}
