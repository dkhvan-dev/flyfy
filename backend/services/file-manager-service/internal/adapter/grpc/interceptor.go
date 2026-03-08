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

	"github.com/dkhvan-dev/flyfy/backend/services/file-manager-service/internal/config"
)

func UnaryServerInterceptor(cfg *config.Config) grpc.UnaryServerInterceptor {
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

func firstMetadataValue(md metadata.MD, key string) string {
	values := md.Get(strings.ToLower(strings.TrimSpace(key)))
	if len(values) == 0 {
		return ""
	}
	return strings.TrimSpace(values[0])
}
