package grpcserver

import (
	"context"
	"errors"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"kz/inflap/backend/services/token-service/internal/adapter/grpc/handler"
	"kz/inflap/backend/services/token-service/internal/domain/model"
	pb "kz/inflap/proto/gen/go/token"
)

type sessionManagerStub struct {
	validate func(context.Context, uuid.UUID, uuid.UUID) (bool, error)
}

func (s *sessionManagerStub) LogoutSession(context.Context, uuid.UUID, string) error {
	return nil
}

func (s *sessionManagerStub) ListUserSessions(context.Context, uuid.UUID) ([]*model.UserSession, error) {
	return nil, nil
}

func (s *sessionManagerStub) RevokeAllUserSessions(context.Context, uuid.UUID, string) (int, error) {
	return 0, nil
}

func (s *sessionManagerStub) ValidateUserSessionGeneration(
	ctx context.Context,
	userID, generation uuid.UUID,
) (bool, error) {
	return s.validate(ctx, userID, generation)
}

func newSessionGenerationServer(stub *sessionManagerStub) *TokenServiceServer {
	grpcHandler := handler.NewTokenGRPCHandler(nil, nil, nil, nil, stub, nil, zerolog.Nop())
	return NewTokenServiceServer(grpcHandler)
}

func TestValidateUserSessionGenerationRPC(t *testing.T) {
	t.Parallel()

	subject := uuid.New()
	generation := uuid.New()
	var capturedDeadline time.Time
	server := newSessionGenerationServer(&sessionManagerStub{
		validate: func(ctx context.Context, gotSubject, gotGeneration uuid.UUID) (bool, error) {
			if gotSubject != subject || gotGeneration != generation {
				t.Fatalf("validator identity = (%s, %s), want (%s, %s)", gotSubject, gotGeneration, subject, generation)
			}
			deadline, ok := ctx.Deadline()
			if !ok {
				t.Fatal("validator context has no deadline")
			}
			capturedDeadline = deadline
			return true, nil
		},
	})
	startedAt := time.Now()

	response, err := server.ValidateUserSessionGeneration(t.Context(), &pb.ValidateUserSessionGenerationRequest{
		Subject:           subject.String(),
		SessionGeneration: generation.String(),
	})
	if err != nil {
		t.Fatalf("ValidateUserSessionGeneration() error = %v", err)
	}
	if !response.GetValid() {
		t.Fatal("ValidateUserSessionGeneration() valid = false, want true")
	}
	if capturedDeadline.After(startedAt.Add(3 * time.Second)) {
		t.Fatalf("validator deadline = %v, want bounded internal deadline", capturedDeadline)
	}
}

func TestValidateUserSessionGenerationRPCReturnsNeutralFalse(t *testing.T) {
	t.Parallel()

	server := newSessionGenerationServer(&sessionManagerStub{
		validate: func(context.Context, uuid.UUID, uuid.UUID) (bool, error) {
			return false, nil
		},
	})

	response, err := server.ValidateUserSessionGeneration(t.Context(), &pb.ValidateUserSessionGenerationRequest{
		Subject:           uuid.NewString(),
		SessionGeneration: uuid.NewString(),
	})
	if err != nil {
		t.Fatalf("ValidateUserSessionGeneration() error = %v", err)
	}
	if response.GetValid() {
		t.Fatal("ValidateUserSessionGeneration() valid = true, want false")
	}
}

func TestValidateUserSessionGenerationRPCRejectsNonCanonicalUUIDs(t *testing.T) {
	t.Parallel()

	canonicalSubject := uuid.NewString()
	canonicalGeneration := uuid.NewString()
	server := newSessionGenerationServer(&sessionManagerStub{
		validate: func(context.Context, uuid.UUID, uuid.UUID) (bool, error) {
			t.Fatal("validator called for malformed request")
			return false, nil
		},
	})

	tests := []struct {
		name       string
		subject    string
		generation string
	}{
		{name: "missing subject", subject: "", generation: canonicalGeneration},
		{name: "uppercase subject", subject: strings.ToUpper(canonicalSubject), generation: canonicalGeneration},
		{name: "compact subject", subject: strings.ReplaceAll(canonicalSubject, "-", ""), generation: canonicalGeneration},
		{name: "spaced generation", subject: canonicalSubject, generation: " " + canonicalGeneration},
		{name: "nil generation", subject: canonicalSubject, generation: uuid.Nil.String()},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			response, err := server.ValidateUserSessionGeneration(t.Context(), &pb.ValidateUserSessionGenerationRequest{
				Subject:           test.subject,
				SessionGeneration: test.generation,
			})
			if response != nil {
				t.Fatalf("response = %#v, want nil", response)
			}
			if status.Code(err) != codes.InvalidArgument {
				t.Fatalf("status code = %s, want %s (error %v)", status.Code(err), codes.InvalidArgument, err)
			}
		})
	}
}

func TestValidateUserSessionGenerationRPCStorageFailureIsUnavailable(t *testing.T) {
	t.Parallel()

	subject := uuid.NewString()
	generation := uuid.NewString()
	server := newSessionGenerationServer(&sessionManagerStub{
		validate: func(context.Context, uuid.UUID, uuid.UUID) (bool, error) {
			return true, errors.New("database unavailable")
		},
	})

	response, err := server.ValidateUserSessionGeneration(t.Context(), &pb.ValidateUserSessionGenerationRequest{
		Subject:           subject,
		SessionGeneration: generation,
	})
	if response != nil {
		t.Fatalf("response = %#v, want nil on dependency failure", response)
	}
	if status.Code(err) != codes.Unavailable {
		t.Fatalf("status code = %s, want %s", status.Code(err), codes.Unavailable)
	}
	if strings.Contains(err.Error(), subject) || strings.Contains(err.Error(), generation) {
		t.Fatalf("public error contains session identity: %v", err)
	}
}
