package grpc

import (
	"errors"
	"testing"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"kz/inflap/backend/services/file-manager-service/internal/app"
)

func TestMapErrorReturnsSafeBusinessMessages(t *testing.T) {
	tests := []struct {
		name    string
		err     error
		code    codes.Code
		message string
	}{
		{
			name:    "idempotency conflict",
			err:     app.ErrIdempotencyConflict,
			code:    codes.Aborted,
			message: "idempotency_conflict",
		},
		{
			name:    "file not ready",
			err:     app.ErrFileNotReady,
			code:    codes.FailedPrecondition,
			message: "file_not_ready",
		},
		{
			name:    "file not public",
			err:     app.ErrFileNotPublic,
			code:    codes.PermissionDenied,
			message: "file_not_public",
		},
		{
			name:    "file purpose mismatch",
			err:     app.ErrFilePurposeMismatch,
			code:    codes.InvalidArgument,
			message: "file_purpose_mismatch",
		},
		{
			name:    "file ownership mismatch",
			err:     app.ErrFileOwnershipMismatch,
			code:    codes.PermissionDenied,
			message: "file_ownership_mismatch",
		},
		{
			name:    "file already bound",
			err:     app.ErrFileAlreadyBound,
			code:    codes.Aborted,
			message: "file_already_bound",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			st, ok := status.FromError(mapError(tt.err))
			if !ok {
				t.Fatal("mapped error is not a gRPC status")
			}
			if st.Code() != tt.code {
				t.Fatalf("code = %s, want %s", st.Code(), tt.code)
			}
			if st.Message() != tt.message {
				t.Fatalf("message = %q, want %q", st.Message(), tt.message)
			}
		})
	}
}

func TestMapErrorHidesTechnicalDetails(t *testing.T) {
	st, ok := status.FromError(mapError(errors.New("postgres password leaked")))
	if !ok {
		t.Fatal("mapped error is not a gRPC status")
	}
	if st.Code() != codes.Internal {
		t.Fatalf("code = %s, want %s", st.Code(), codes.Internal)
	}
	if st.Message() != "technical_error" {
		t.Fatalf("message = %q, want technical_error", st.Message())
	}
}
