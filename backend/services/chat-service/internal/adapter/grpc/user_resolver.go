package grpc

import (
	"context"
	"fmt"
	"strings"

	"github.com/google/uuid"
	userv1 "github.com/dkhvan-dev/flyfy/proto/gen/go/user/v1"
)

type UserResolver struct {
	client userv1.UserServiceClient
}

func NewUserResolver(client userv1.UserServiceClient) *UserResolver {
	return &UserResolver{client: client}
}

func (r *UserResolver) ResolveUserIDBySubject(ctx context.Context, subject string) (uuid.UUID, error) {
	resp, err := r.client.GetUserBySubject(ctx, &userv1.GetUserBySubjectRequest{
		SubjectId: strings.TrimSpace(subject),
	})
	if err != nil {
		return uuid.Nil, fmt.Errorf("resolve user by subject: %w", err)
	}
	return uuid.Parse(resp.GetAggregate().GetUser().GetId())
}
