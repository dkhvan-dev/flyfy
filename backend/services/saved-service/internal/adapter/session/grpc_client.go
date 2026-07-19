package session

import (
	"context"
	"errors"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	tokenpb "kz/inflap/proto/gen/go/token"

	sessionapp "kz/inflap/backend/services/saved-service/internal/app/session"
)

const maxValidationDuration = 2 * time.Second

// ValidationRPC is the smallest generated-client surface required by Saved.
// tokenpb.TokenServiceClient satisfies it without exposing unrelated RPCs to
// the adapter.
type ValidationRPC interface {
	ValidateUserSessionGeneration(
		ctx context.Context,
		in *tokenpb.ValidateUserSessionGenerationRequest,
		opts ...grpc.CallOption,
	) (*tokenpb.ValidateUserSessionGenerationResponse, error)
}

// GRPCClient validates a session generation against token-service. The
// supplied client/connection is expected to carry service authentication via
// its externally configured interceptors.
type GRPCClient struct {
	rpc         ValidationRPC
	callTimeout time.Duration
}

var _ sessionapp.Validator = (*GRPCClient)(nil)

func NewGRPCClient(rpc ValidationRPC) *GRPCClient {
	return newGRPCClient(rpc, maxValidationDuration)
}

func NewGRPCClientFromConn(conn grpc.ClientConnInterface) *GRPCClient {
	if conn == nil {
		return NewGRPCClient(nil)
	}
	return NewGRPCClient(tokenpb.NewTokenServiceClient(conn))
}

func newGRPCClient(rpc ValidationRPC, timeout time.Duration) *GRPCClient {
	if timeout <= 0 || timeout > maxValidationDuration {
		timeout = maxValidationDuration
	}
	return &GRPCClient{rpc: rpc, callTimeout: timeout}
}

func (c *GRPCClient) Validate(
	ctx context.Context,
	subject string,
	sessionGeneration string,
) (bool, error) {
	if err := sessionapp.ValidateInput(subject, sessionGeneration); err != nil {
		return false, err
	}
	if ctx == nil || c == nil || c.rpc == nil {
		return false, sessionapp.ErrDependencyUnavailable
	}

	validationCtx, cancel := context.WithTimeout(ctx, c.callTimeout)
	defer cancel()

	response, err := c.rpc.ValidateUserSessionGeneration(
		validationCtx,
		&tokenpb.ValidateUserSessionGenerationRequest{
			Subject:           subject,
			SessionGeneration: sessionGeneration,
		},
	)
	if err != nil {
		return false, classifyRPCError(ctx, validationCtx, err)
	}
	if response == nil {
		if callerErr := ctx.Err(); callerErr != nil {
			return false, callerErr
		}
		return false, sessionapp.ErrContractViolation
	}

	return response.GetValid(), nil
}

func classifyRPCError(parent, callCtx context.Context, rpcErr error) error {
	// Caller cancellation and caller-owned deadlines retain their standard
	// context errors so upper layers can stop work without treating them as a
	// dependency incident.
	if parentErr := parent.Err(); parentErr != nil {
		return parentErr
	}

	// A timeout introduced by this adapter is a bounded dependency failure.
	if callErr := callCtx.Err(); callErr != nil {
		return sessionapp.ErrDependencyUnavailable
	}

	if errors.Is(rpcErr, context.Canceled) || errors.Is(rpcErr, context.DeadlineExceeded) {
		return sessionapp.ErrDependencyUnavailable
	}

	switch status.Code(rpcErr) {
	case codes.Canceled,
		codes.DeadlineExceeded,
		codes.ResourceExhausted,
		codes.Aborted,
		codes.Unavailable:
		return sessionapp.ErrDependencyUnavailable
	case codes.OK:
		return sessionapp.ErrContractViolation
	default:
		// Unexpected application/auth/protocol statuses indicate a broken
		// internal contract. The wrapped classification still maps safely to
		// Saved dependency unavailable at the transport boundary.
		if _, ok := status.FromError(rpcErr); ok {
			return sessionapp.ErrContractViolation
		}
		return sessionapp.ErrDependencyUnavailable
	}
}
