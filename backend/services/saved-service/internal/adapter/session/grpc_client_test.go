package session

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"sync/atomic"
	"testing"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	tokenpb "kz/inflap/proto/gen/go/token"

	sessionapp "kz/inflap/backend/services/saved-service/internal/app/session"
)

const (
	testSubject    = "f4b3b8f7-c75d-4f8a-b89b-ad2b50113b98"
	testGeneration = "a387fd94-d8f4-4434-9d3e-edf8db0a614e"
)

type validationRPCStub struct {
	calls atomic.Int32
	call  func(context.Context, *tokenpb.ValidateUserSessionGenerationRequest) (*tokenpb.ValidateUserSessionGenerationResponse, error)
}

func (s *validationRPCStub) ValidateUserSessionGeneration(
	ctx context.Context,
	request *tokenpb.ValidateUserSessionGenerationRequest,
	_ ...grpc.CallOption,
) (*tokenpb.ValidateUserSessionGenerationResponse, error) {
	s.calls.Add(1)
	return s.call(ctx, request)
}

func TestGRPCClientValidateValid(t *testing.T) {
	t.Parallel()

	rpc := &validationRPCStub{call: func(
		ctx context.Context,
		request *tokenpb.ValidateUserSessionGenerationRequest,
	) (*tokenpb.ValidateUserSessionGenerationResponse, error) {
		if request.GetSubject() != testSubject || request.GetSessionGeneration() != testGeneration {
			t.Fatalf("unexpected request: subject=%q generation=%q", request.GetSubject(), request.GetSessionGeneration())
		}
		deadline, ok := ctx.Deadline()
		if !ok {
			t.Fatal("validation RPC context has no deadline")
		}
		remaining := time.Until(deadline)
		if remaining <= 0 || remaining > maxValidationDuration {
			t.Fatalf("validation deadline remaining = %s, want (0, %s]", remaining, maxValidationDuration)
		}
		return &tokenpb.ValidateUserSessionGenerationResponse{Valid: true}, nil
	}}

	valid, err := NewGRPCClient(rpc).Validate(t.Context(), testSubject, testGeneration)
	if err != nil {
		t.Fatalf("Validate() error = %v", err)
	}
	if !valid {
		t.Fatal("Validate() valid = false, want true")
	}
}

func TestGRPCClientValidateNeutralFalse(t *testing.T) {
	t.Parallel()

	// The token service deliberately reveals no reason for a false result;
	// this covers foreign, revoked, expired, and replaced generations.
	rpc := &validationRPCStub{call: func(
		context.Context,
		*tokenpb.ValidateUserSessionGenerationRequest,
	) (*tokenpb.ValidateUserSessionGenerationResponse, error) {
		return &tokenpb.ValidateUserSessionGenerationResponse{Valid: false}, nil
	}}

	valid, err := NewGRPCClient(rpc).Validate(t.Context(), testSubject, testGeneration)
	if err != nil {
		t.Fatalf("Validate() error = %v", err)
	}
	if valid {
		t.Fatal("Validate() valid = true, want neutral false")
	}
}

func TestGRPCClientRejectsMalformedUUIDBeforeRPC(t *testing.T) {
	t.Parallel()

	rpc := &validationRPCStub{call: func(
		context.Context,
		*tokenpb.ValidateUserSessionGenerationRequest,
	) (*tokenpb.ValidateUserSessionGenerationResponse, error) {
		t.Fatal("RPC must not be called for malformed input")
		return nil, nil
	}}
	client := NewGRPCClient(rpc)

	tests := []struct {
		name       string
		subject    string
		generation string
		wantErr    error
	}{
		{name: "foreign subject format", subject: "urn:uuid:" + testSubject, generation: testGeneration, wantErr: sessionapp.ErrInvalidSubject},
		{name: "malformed subject", subject: "not-a-uuid", generation: testGeneration, wantErr: sessionapp.ErrInvalidSubject},
		{name: "malformed generation", subject: testSubject, generation: "not-a-uuid", wantErr: sessionapp.ErrInvalidSessionGeneration},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()

			valid, err := client.Validate(t.Context(), tt.subject, tt.generation)
			if valid {
				t.Fatal("Validate() valid = true for malformed input")
			}
			if !errors.Is(err, tt.wantErr) {
				t.Fatalf("Validate() error = %v, want %v", err, tt.wantErr)
			}
		})
	}
}

func TestGRPCClientOwnTimeoutIsDependencyUnavailable(t *testing.T) {
	t.Parallel()

	rpc := &validationRPCStub{call: func(
		ctx context.Context,
		_ *tokenpb.ValidateUserSessionGenerationRequest,
	) (*tokenpb.ValidateUserSessionGenerationResponse, error) {
		<-ctx.Done()
		return nil, status.FromContextError(ctx.Err()).Err()
	}}
	client := newGRPCClient(rpc, 20*time.Millisecond)

	valid, err := client.Validate(t.Context(), testSubject, testGeneration)
	if valid {
		t.Fatal("Validate() valid = true after timeout")
	}
	if !errors.Is(err, sessionapp.ErrDependencyUnavailable) {
		t.Fatalf("Validate() error = %v, want ErrDependencyUnavailable", err)
	}
}

func TestGRPCClientPreservesCallerCancellation(t *testing.T) {
	t.Parallel()

	started := make(chan struct{})
	rpc := &validationRPCStub{call: func(
		ctx context.Context,
		_ *tokenpb.ValidateUserSessionGenerationRequest,
	) (*tokenpb.ValidateUserSessionGenerationResponse, error) {
		close(started)
		<-ctx.Done()
		return nil, status.FromContextError(ctx.Err()).Err()
	}}
	ctx, cancel := context.WithCancel(t.Context())
	done := make(chan error, 1)
	go func() {
		_, err := NewGRPCClient(rpc).Validate(ctx, testSubject, testGeneration)
		done <- err
	}()

	<-started
	cancel()
	if err := <-done; !errors.Is(err, context.Canceled) {
		t.Fatalf("Validate() error = %v, want context.Canceled", err)
	}
}

func TestGRPCClientRespectsEarlierParentDeadline(t *testing.T) {
	t.Parallel()

	const parentTimeout = 40 * time.Millisecond
	ctx, cancel := context.WithTimeout(t.Context(), parentTimeout)
	defer cancel()
	parentDeadline, ok := ctx.Deadline()
	if !ok {
		t.Fatal("parent context has no deadline")
	}

	rpc := &validationRPCStub{call: func(
		callCtx context.Context,
		_ *tokenpb.ValidateUserSessionGenerationRequest,
	) (*tokenpb.ValidateUserSessionGenerationResponse, error) {
		callDeadline, hasDeadline := callCtx.Deadline()
		if !hasDeadline {
			t.Fatal("RPC context has no deadline")
		}
		if !callDeadline.Equal(parentDeadline) {
			t.Fatalf("RPC deadline = %s, want parent deadline %s", callDeadline, parentDeadline)
		}
		<-callCtx.Done()
		return nil, status.FromContextError(callCtx.Err()).Err()
	}}

	valid, err := NewGRPCClient(rpc).Validate(ctx, testSubject, testGeneration)
	if valid {
		t.Fatal("Validate() valid = true after caller deadline")
	}
	if !errors.Is(err, context.DeadlineExceeded) {
		t.Fatalf("Validate() error = %v, want context.DeadlineExceeded", err)
	}
}

func TestGRPCClientMapsUnavailableAndResourceFailures(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name string
		err  error
	}{
		{name: "unavailable", err: status.Error(codes.Unavailable, "database unavailable")},
		{name: "deadline", err: status.Error(codes.DeadlineExceeded, "remote timeout")},
		{name: "resource exhausted", err: status.Error(codes.ResourceExhausted, "transport pool exhausted")},
		{name: "raw transport failure", err: errors.New("connection reset")},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()

			rpc := &validationRPCStub{call: func(
				context.Context,
				*tokenpb.ValidateUserSessionGenerationRequest,
			) (*tokenpb.ValidateUserSessionGenerationResponse, error) {
				return nil, tt.err
			}}

			valid, err := NewGRPCClient(rpc).Validate(t.Context(), testSubject, testGeneration)
			if valid {
				t.Fatal("Validate() valid = true after dependency failure")
			}
			if !errors.Is(err, sessionapp.ErrDependencyUnavailable) {
				t.Fatalf("Validate() error = %v, want ErrDependencyUnavailable", err)
			}
		})
	}
}

func TestGRPCClientRejectsNilResponseAsContractViolation(t *testing.T) {
	t.Parallel()

	rpc := &validationRPCStub{call: func(
		context.Context,
		*tokenpb.ValidateUserSessionGenerationRequest,
	) (*tokenpb.ValidateUserSessionGenerationResponse, error) {
		return nil, nil
	}}

	valid, err := NewGRPCClient(rpc).Validate(t.Context(), testSubject, testGeneration)
	if valid {
		t.Fatal("Validate() valid = true for nil response")
	}
	if !errors.Is(err, sessionapp.ErrContractViolation) {
		t.Fatalf("Validate() error = %v, want ErrContractViolation", err)
	}
	if !errors.Is(err, sessionapp.ErrDependencyUnavailable) {
		t.Fatalf("Validate() error = %v, want dependency classification", err)
	}
}

func TestGRPCClientDoesNotLeakIdentifiersOrRemoteMessages(t *testing.T) {
	t.Parallel()

	const secret = "service-token-super-secret"
	remoteMessage := fmt.Sprintf("subject=%s generation=%s token=%s", testSubject, testGeneration, secret)
	rpc := &validationRPCStub{call: func(
		context.Context,
		*tokenpb.ValidateUserSessionGenerationRequest,
	) (*tokenpb.ValidateUserSessionGenerationResponse, error) {
		return nil, status.Error(codes.Unavailable, remoteMessage)
	}}

	_, err := NewGRPCClient(rpc).Validate(t.Context(), testSubject, testGeneration)
	if err == nil {
		t.Fatal("Validate() error = nil, want dependency failure")
	}
	for _, forbidden := range []string{testSubject, testGeneration, secret, remoteMessage} {
		if strings.Contains(err.Error(), forbidden) {
			t.Fatalf("Validate() error leaked sensitive value %q: %q", forbidden, err.Error())
		}
	}
}

func TestGRPCClientFailsClosedWithoutRPC(t *testing.T) {
	t.Parallel()

	valid, err := NewGRPCClient(nil).Validate(t.Context(), testSubject, testGeneration)
	if valid {
		t.Fatal("Validate() valid = true without RPC client")
	}
	if !errors.Is(err, sessionapp.ErrDependencyUnavailable) {
		t.Fatalf("Validate() error = %v, want ErrDependencyUnavailable", err)
	}
}
