package serviceauth

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"sync"
	"sync/atomic"
	"testing"

	"google.golang.org/grpc"
	"google.golang.org/grpc/metadata"
)

func TestUnaryClientInterceptorInjectsServiceTokenAndPreservesMetadata(t *testing.T) {
	t.Parallel()

	var sourceCalls atomic.Int32
	source := tokenSourceFunc(func(context.Context) (string, error) {
		sourceCalls.Add(1)
		return " service-jwt ", nil
	})
	interceptor := UnaryClientInterceptor(source)
	originalMD := metadata.Pairs(
		grpcAuthorizationMetadataKey, "Bearer user-token",
		grpcAuthorizationMetadataKey, "Bearer stale-service-token",
		strings.ToLower(HeaderInternalServiceToken), "legacy-internal-token",
		"x-request-id", "request-123",
		"x-trace-id", "trace-456",
	)
	ctx := metadata.NewOutgoingContext(context.Background(), originalMD)

	var invokerCalls atomic.Int32
	var gotMD metadata.MD
	err := interceptor(
		ctx,
		"/inflap.example.v1.Example/Get",
		struct{}{},
		&struct{}{},
		nil,
		func(callCtx context.Context, _ string, _, _ any, _ *grpc.ClientConn, _ ...grpc.CallOption) error {
			invokerCalls.Add(1)
			var ok bool
			gotMD, ok = metadata.FromOutgoingContext(callCtx)
			if !ok {
				return errors.New("outgoing metadata is missing")
			}
			return nil
		},
	)
	if err != nil {
		t.Fatalf("interceptor() error = %v", err)
	}

	if got := gotMD.Get(grpcAuthorizationMetadataKey); len(got) != 1 || got[0] != "Bearer service-jwt" {
		t.Fatalf("authorization metadata = %q, want exactly one service bearer token", got)
	}
	if got := gotMD.Get(strings.ToLower(HeaderInternalServiceToken)); len(got) != 0 {
		t.Fatalf("legacy internal-token metadata = %q, want none", got)
	}
	if got := gotMD.Get("x-request-id"); len(got) != 1 || got[0] != "request-123" {
		t.Fatalf("request ID metadata = %q, want preserved value", got)
	}
	if got := gotMD.Get("x-trace-id"); len(got) != 1 || got[0] != "trace-456" {
		t.Fatalf("trace ID metadata = %q, want preserved value", got)
	}
	if got := originalMD.Get(grpcAuthorizationMetadataKey); len(got) != 2 {
		t.Fatalf("original authorization metadata = %q, want unchanged", got)
	}
	if got := originalMD.Get(strings.ToLower(HeaderInternalServiceToken)); len(got) != 1 {
		t.Fatalf("original legacy metadata = %q, want unchanged", got)
	}
	if got := sourceCalls.Load(); got != 1 {
		t.Fatalf("Token() calls = %d, want 1", got)
	}
	if got := invokerCalls.Load(); got != 1 {
		t.Fatalf("invoker calls = %d, want 1", got)
	}
}

func TestUnaryClientInterceptorFailsBeforeInvoker(t *testing.T) {
	t.Parallel()

	tokenSourceErr := errors.New("token source unavailable")
	tests := []struct {
		name               string
		sourceIsNil        bool
		token              string
		sourceErr          error
		cancelBeforeCall   bool
		cancelInSource     bool
		wantSourceCalls    int32
		wantWrappedError   error
		forbiddenErrorText string
	}{
		{
			name:            "nil source",
			sourceIsNil:     true,
			wantSourceCalls: 0,
		},
		{
			name:             "token source error",
			sourceErr:        tokenSourceErr,
			wantSourceCalls:  1,
			wantWrappedError: tokenSourceErr,
		},
		{
			name:            "empty token",
			token:           "",
			wantSourceCalls: 1,
		},
		{
			name:            "blank token",
			token:           "   ",
			wantSourceCalls: 1,
		},
		{
			name:               "control character token",
			token:              "sensitive\x00service-jwt",
			wantSourceCalls:    1,
			forbiddenErrorText: "sensitive",
		},
		{
			name:             "context canceled before call",
			token:            "service-jwt",
			cancelBeforeCall: true,
			wantSourceCalls:  0,
			wantWrappedError: context.Canceled,
		},
		{
			name:             "context canceled by source",
			token:            "service-jwt",
			cancelInSource:   true,
			wantSourceCalls:  1,
			wantWrappedError: context.Canceled,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()

			ctx, cancel := context.WithCancel(context.Background())
			defer cancel()
			if tt.cancelBeforeCall {
				cancel()
			}

			var sourceCalls atomic.Int32
			var source TokenSource
			if !tt.sourceIsNil {
				source = tokenSourceFunc(func(context.Context) (string, error) {
					sourceCalls.Add(1)
					if tt.cancelInSource {
						cancel()
					}
					return tt.token, tt.sourceErr
				})
			}

			var invokerCalls atomic.Int32
			err := UnaryClientInterceptor(source)(
				ctx,
				"/inflap.example.v1.Example/Get",
				struct{}{},
				&struct{}{},
				nil,
				func(context.Context, string, any, any, *grpc.ClientConn, ...grpc.CallOption) error {
					invokerCalls.Add(1)
					return nil
				},
			)
			if err == nil {
				t.Fatal("interceptor() error = nil, want failure")
			}
			if tt.wantWrappedError != nil && !errors.Is(err, tt.wantWrappedError) {
				t.Fatalf("interceptor() error = %v, want wrapped %v", err, tt.wantWrappedError)
			}
			if tt.forbiddenErrorText != "" && strings.Contains(err.Error(), tt.forbiddenErrorText) {
				t.Fatalf("interceptor() error exposed token contents: %v", err)
			}
			if got := sourceCalls.Load(); got != tt.wantSourceCalls {
				t.Fatalf("Token() calls = %d, want %d", got, tt.wantSourceCalls)
			}
			if got := invokerCalls.Load(); got != 0 {
				t.Fatalf("invoker calls = %d, want 0", got)
			}
		})
	}
}

func TestUnaryClientInterceptorConcurrentUse(t *testing.T) {
	t.Parallel()

	const callCount = 128
	var sourceCalls atomic.Int32
	var invokerCalls atomic.Int32
	interceptor := UnaryClientInterceptor(tokenSourceFunc(func(context.Context) (string, error) {
		sourceCalls.Add(1)
		return "service-jwt", nil
	}))

	start := make(chan struct{})
	errs := make(chan error, callCount)
	var wg sync.WaitGroup
	for i := 0; i < callCount; i++ {
		wg.Add(1)
		go func(callID int) {
			defer wg.Done()
			<-start

			requestID := fmt.Sprintf("request-%d", callID)
			ctx := metadata.NewOutgoingContext(context.Background(), metadata.Pairs(
				grpcAuthorizationMetadataKey, "Bearer user-token",
				strings.ToLower(HeaderInternalServiceToken), "legacy-internal-token",
				"x-request-id", requestID,
			))
			err := interceptor(
				ctx,
				"/inflap.example.v1.Example/Get",
				callID,
				&struct{}{},
				nil,
				func(callCtx context.Context, _ string, _, _ any, _ *grpc.ClientConn, _ ...grpc.CallOption) error {
					invokerCalls.Add(1)
					md, ok := metadata.FromOutgoingContext(callCtx)
					if !ok {
						return errors.New("outgoing metadata is missing")
					}
					if got := md.Get(grpcAuthorizationMetadataKey); len(got) != 1 || got[0] != "Bearer service-jwt" {
						return fmt.Errorf("authorization metadata count/value is invalid")
					}
					if got := md.Get(strings.ToLower(HeaderInternalServiceToken)); len(got) != 0 {
						return fmt.Errorf("legacy internal-token metadata was propagated")
					}
					if got := md.Get("x-request-id"); len(got) != 1 || got[0] != requestID {
						return fmt.Errorf("request ID metadata was not preserved")
					}
					return nil
				},
			)
			errs <- err
		}(i)
	}

	close(start)
	wg.Wait()
	close(errs)
	for err := range errs {
		if err != nil {
			t.Fatalf("concurrent interceptor call failed: %v", err)
		}
	}
	if got := sourceCalls.Load(); got != callCount {
		t.Fatalf("Token() calls = %d, want %d", got, callCount)
	}
	if got := invokerCalls.Load(); got != callCount {
		t.Fatalf("invoker calls = %d, want %d", got, callCount)
	}
}

type tokenSourceFunc func(context.Context) (string, error)

func (f tokenSourceFunc) Token(ctx context.Context) (string, error) {
	return f(ctx)
}
