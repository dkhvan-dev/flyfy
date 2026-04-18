package grpc

import (
	"context"
	"strings"

	"github.com/google/uuid"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"github.com/dkhvan-dev/flyfy/backend/services/chat-service/internal/app"
)

type Server struct {
	conversationUC *app.ConversationUseCase
}

func NewServer(conversationUC *app.ConversationUseCase) *Server {
	return &Server{conversationUC: conversationUC}
}

type CreateActivityConversationRequest struct {
	ActivityID string
	Title      string
	HostUserID string
}

type CreateActivityConversationResponse struct {
	ConversationID string
}

func (s *Server) CreateActivityConversation(ctx context.Context, activityID, title, hostUserID string) (string, error) {
	aID, err := uuid.Parse(strings.TrimSpace(activityID))
	if err != nil {
		return "", status.Error(codes.InvalidArgument, "invalid activity id")
	}

	hID, err := uuid.Parse(strings.TrimSpace(hostUserID))
	if err != nil {
		return "", status.Error(codes.InvalidArgument, "invalid host user id")
	}

	conv, err := s.conversationUC.CreateActivityConversation(ctx, app.CreateActivityConversationInput{
		ActivityID: aID,
		Title:      title,
		HostUserID: hID,
	})
	if err != nil {
		return "", status.Error(codes.Internal, err.Error())
	}

	return conv.ID.String(), nil
}

func (s *Server) AddParticipant(ctx context.Context, conversationID, userID, displayName string) error {
	cID, err := uuid.Parse(strings.TrimSpace(conversationID))
	if err != nil {
		return status.Error(codes.InvalidArgument, "invalid conversation id")
	}

	uID, err := uuid.Parse(strings.TrimSpace(userID))
	if err != nil {
		return status.Error(codes.InvalidArgument, "invalid user id")
	}

	return s.conversationUC.AddParticipant(ctx, cID, uID, displayName)
}

func (s *Server) RemoveParticipant(ctx context.Context, conversationID, userID string) error {
	cID, err := uuid.Parse(strings.TrimSpace(conversationID))
	if err != nil {
		return status.Error(codes.InvalidArgument, "invalid conversation id")
	}

	uID, err := uuid.Parse(strings.TrimSpace(userID))
	if err != nil {
		return status.Error(codes.InvalidArgument, "invalid user id")
	}

	return s.conversationUC.RemoveParticipant(ctx, cID, uID)
}
