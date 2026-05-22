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

func (r *UserResolver) DisplayNameForUserID(ctx context.Context, userID uuid.UUID) (string, error) {
	resp, err := r.client.GetUserById(ctx, &userv1.GetUserByIdRequest{
		UserId: userID.String(),
	})
	if err != nil {
		return "", err
	}

	aggregate := resp.GetAggregate()
	if aggregate == nil || aggregate.GetProfile() == nil {
		return "", errors.New("empty user profile")
	}

	profile := aggregate.GetProfile()
	if displayName := strings.TrimSpace(profile.GetDisplayName()); displayName != "" {
		return displayName, nil
	}

	fullName := strings.TrimSpace(strings.Join([]string{
		strings.TrimSpace(profile.GetFirstName()),
		strings.TrimSpace(profile.GetLastName()),
	}, " "))
	return fullName, nil
}

func (r *UserResolver) FilterFriendUserIDs(
	ctx context.Context,
	userID uuid.UUID,
	candidateUserIDs []uuid.UUID,
) ([]uuid.UUID, error) {
	req := &userv1.FilterFriendUserIdsRequest{
		UserId:           userID.String(),
		CandidateUserIds: make([]string, 0, len(candidateUserIDs)),
	}
	for _, candidateUserID := range candidateUserIDs {
		if candidateUserID == uuid.Nil || candidateUserID == userID {
			continue
		}
		req.CandidateUserIds = append(req.CandidateUserIds, candidateUserID.String())
	}

	resp, err := r.client.FilterFriendUserIds(ctx, req)
	if err != nil {
		return nil, err
	}

	rawIDs := resp.GetFriendUserIds()
	result := make([]uuid.UUID, 0, len(rawIDs))
	for _, raw := range rawIDs {
		parsed, parseErr := uuid.Parse(strings.TrimSpace(raw))
		if parseErr != nil {
			continue
		}
		result = append(result, parsed)
	}

	return result, nil
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
