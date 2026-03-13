package grpc

import (
	"context"
	"errors"
	"strings"

	userv1 "github.com/dkhvan-dev/flyfy/proto/gen/go/user/v1"
	"github.com/google/uuid"
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
		return uuid.Nil, err
	}

	aggregate := resp.GetAggregate()
	if aggregate == nil || aggregate.GetUser() == nil {
		return uuid.Nil, errors.New("empty user aggregate")
	}

	userID := strings.TrimSpace(aggregate.GetUser().GetId())
	if userID == "" {
		return uuid.Nil, errors.New("empty user id")
	}

	return uuid.Parse(userID)
}

func (r *UserResolver) ResolveRolesBySubject(ctx context.Context, subject string) ([]string, error) {
	resp, err := r.client.GetUserBySubject(ctx, &userv1.GetUserBySubjectRequest{
		SubjectId: strings.TrimSpace(subject),
	})
	if err != nil {
		return nil, err
	}

	return aggregateRoles(resp.GetAggregate()), nil
}

func aggregateRoles(aggregate *userv1.UserAggregate) []string {
	if aggregate == nil {
		return nil
	}
	src := aggregate.GetRoles()
	out := make([]string, 0, len(src))
	seen := make(map[string]struct{}, len(src))

	for _, role := range src {
		role = strings.ToUpper(strings.TrimSpace(role))
		if role == "" {
			continue
		}
		if _, ok := seen[role]; ok {
			continue
		}
		seen[role] = struct{}{}
		out = append(out, role)
	}

	return out
}
