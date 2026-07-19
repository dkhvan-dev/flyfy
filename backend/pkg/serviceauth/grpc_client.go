package serviceauth

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"unicode"

	"google.golang.org/grpc"
	"google.golang.org/grpc/metadata"
)

const grpcAuthorizationMetadataKey = "authorization"

// UnaryClientInterceptor authenticates each unary RPC with a current service JWT.
// Streaming RPCs are intentionally out of scope because their outgoing metadata is
// fixed at stream creation and cannot safely refresh a token during a long-lived stream.
func UnaryClientInterceptor(source TokenSource) grpc.UnaryClientInterceptor {
	return func(
		ctx context.Context,
		method string,
		req any,
		reply any,
		cc *grpc.ClientConn,
		invoker grpc.UnaryInvoker,
		opts ...grpc.CallOption,
	) error {
		if ctx == nil {
			return fmt.Errorf("serviceauth grpc client context is required")
		}
		if err := ctx.Err(); err != nil {
			return fmt.Errorf("serviceauth grpc client context: %w", err)
		}
		if source == nil {
			return fmt.Errorf("serviceauth grpc client token source is required")
		}

		token, err := source.Token(ctx)
		if err != nil {
			return fmt.Errorf("serviceauth grpc client get service token: %w", err)
		}
		if err := ctx.Err(); err != nil {
			return fmt.Errorf("serviceauth grpc client context: %w", err)
		}
		token, err = normalizeServiceToken(token)
		if err != nil {
			return fmt.Errorf("serviceauth grpc client get service token: %w", err)
		}

		outgoingMD := metadata.MD{}
		if currentMD, ok := metadata.FromOutgoingContext(ctx); ok {
			outgoingMD = currentMD.Copy()
		}
		deleteGRPCMetadataKey(outgoingMD, grpcAuthorizationMetadataKey)
		deleteGRPCMetadataKey(outgoingMD, HeaderInternalServiceToken)
		outgoingMD.Set(grpcAuthorizationMetadataKey, "Bearer "+token)

		callCtx := metadata.NewOutgoingContext(ctx, outgoingMD)
		if err := callCtx.Err(); err != nil {
			return fmt.Errorf("serviceauth grpc client context: %w", err)
		}
		return invoker(callCtx, method, req, reply, cc, opts...)
	}
}

func normalizeServiceToken(token string) (string, error) {
	if strings.IndexFunc(token, unicode.IsControl) >= 0 {
		return "", errors.New("token contains a control character")
	}
	token = strings.TrimSpace(token)
	if token == "" {
		return "", errors.New("empty token")
	}
	return token, nil
}

func deleteGRPCMetadataKey(md metadata.MD, key string) {
	for existingKey := range md {
		if strings.EqualFold(existingKey, key) {
			delete(md, existingKey)
		}
	}
}
