package grpc

import (
	"context"

	"google.golang.org/grpc/metadata"
)

func WithInternalMetadata(
	ctx context.Context,
	internalToken string,
	serviceName string,
	requestID string,
	subject string,
) context.Context {
	md := metadata.New(map[string]string{
		"x-internal-service-token": internalToken,
		"x-service-name":           serviceName,
	})

	if requestID != "" {
		md.Set("x-request-id", requestID)
	}
	if subject != "" {
		md.Set("x-subject", subject)
	}

	return metadata.NewOutgoingContext(ctx, md)
}
