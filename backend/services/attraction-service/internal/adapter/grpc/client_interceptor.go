package grpc

import (
	"context"

	gogrpc "google.golang.org/grpc"
	"google.golang.org/grpc/metadata"
)

func InternalTokenInterceptor(internalToken, serviceName string) gogrpc.UnaryClientInterceptor {
	return func(
		ctx context.Context,
		method string,
		req, reply any,
		cc *gogrpc.ClientConn,
		invoker gogrpc.UnaryInvoker,
		opts ...gogrpc.CallOption,
	) error {
		ctx = metadata.AppendToOutgoingContext(
			ctx,
			"x-internal-service-token", internalToken,
			"x-service-name", serviceName,
		)
		return invoker(ctx, method, req, reply, cc, opts...)
	}
}
