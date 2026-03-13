package grpc

import (
	"context"

	"google.golang.org/grpc"
	"google.golang.org/grpc/metadata"
)

// InternalTokenInterceptor returns a gRPC unary client interceptor that
// attaches the internal service token and service name to every outgoing call.
func InternalTokenInterceptor(internalToken, serviceName string) grpc.UnaryClientInterceptor {
	return func(
		ctx context.Context,
		method string,
		req, reply any,
		cc *grpc.ClientConn,
		invoker grpc.UnaryInvoker,
		opts ...grpc.CallOption,
	) error {
		md := metadata.New(map[string]string{
			"x-internal-service-token": internalToken,
			"x-service-name":           serviceName,
		})

		ctx = metadata.NewOutgoingContext(ctx, md)
		return invoker(ctx, method, req, reply, cc, opts...)
	}
}
