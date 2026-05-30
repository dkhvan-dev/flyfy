package grpc

import (
	"errors"
	"testing"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"kz/inflap/backend/services/chat-service/internal/app"
)

func TestGRPCStatusFromAppErrorMapsBusinessErrors(t *testing.T) {
	tests := []struct {
		name        string
		err         error
		wantCode    codes.Code
		wantMessage string
	}{
		{
			name:        "invalid activity id",
			err:         app.ErrInvalidActivityID,
			wantCode:    codes.InvalidArgument,
			wantMessage: "invalid activity id",
		},
		{
			name:        "conversation not found",
			err:         app.ErrConversationNotFound,
			wantCode:    codes.NotFound,
			wantMessage: "conversation not found",
		},
		{
			name:        "not participant",
			err:         app.ErrNotParticipant,
			wantCode:    codes.PermissionDenied,
			wantMessage: "user is not a participant of this conversation",
		},
		{
			name:        "conversation full",
			err:         app.ErrConversationFull,
			wantCode:    codes.ResourceExhausted,
			wantMessage: "conversation has reached maximum participants",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := grpcStatusFromAppError(tt.err)
			st, ok := status.FromError(got)
			if !ok {
				t.Fatalf("error is not a gRPC status: %v", got)
			}
			if st.Code() != tt.wantCode {
				t.Fatalf("code = %s, want %s", st.Code(), tt.wantCode)
			}
			if st.Message() != tt.wantMessage {
				t.Fatalf("message = %q, want %q", st.Message(), tt.wantMessage)
			}
		})
	}
}

func TestGRPCStatusFromAppErrorHidesInternalDetails(t *testing.T) {
	got := grpcStatusFromAppError(errors.New("postgres password leaked"))
	st, ok := status.FromError(got)
	if !ok {
		t.Fatalf("error is not a gRPC status: %v", got)
	}
	if st.Code() != codes.Internal {
		t.Fatalf("code = %s, want %s", st.Code(), codes.Internal)
	}
	if st.Message() != "technical error" {
		t.Fatalf("message = %q, want safe technical message", st.Message())
	}
}
