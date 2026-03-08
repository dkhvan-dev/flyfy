package interceptor

import (
	"context"
	"runtime/debug"
	"time"

	"github.com/rs/zerolog"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

// RecoveryInterceptor catches panics in gRPC handlers and returns Internal error.
func RecoveryInterceptor(logger zerolog.Logger) grpc.UnaryServerInterceptor {
	return func(
		ctx context.Context,
		req any,
		info *grpc.UnaryServerInfo,
		handler grpc.UnaryHandler,
	) (resp any, err error) {
		defer func() {
			if r := recover(); r != nil {
				logger.Error().
					Interface("panic", r).
					Str("method", info.FullMethod).
					Str("stack", string(debug.Stack())).
					Msg("gRPC handler panic recovered")

				err = status.Errorf(codes.Internal, "internal server error")
			}
		}()

		return handler(ctx, req)
	}
}

// LoggingInterceptor logs gRPC request method, duration and status.
func LoggingInterceptor(logger zerolog.Logger) grpc.UnaryServerInterceptor {
	log := logger.With().Str("component", "grpc").Logger()

	return func(
		ctx context.Context,
		req any,
		info *grpc.UnaryServerInfo,
		handler grpc.UnaryHandler,
	) (any, error) {
		start := time.Now()

		resp, err := handler(ctx, req)

		duration := time.Since(start)
		code := status.Code(err)

		event := log.Info()
		if err != nil {
			event = log.Error().Err(err)
		}

		event.
			Str("method", info.FullMethod).
			Dur("duration", duration).
			Str("code", code.String()).
			Msg("gRPC request")

		return resp, err
	}
}
