package grpc

import (
	"context"
	"errors"
	"strings"

	"github.com/google/uuid"
	"kz/inflap/backend/services/activity-service/internal/domain/port"
	userv1 "kz/inflap/proto/gen/go/user/v1"
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
	displayName, _, err := r.ProfileNamesForUserID(ctx, userID)
	return displayName, err
}

func (r *UserResolver) FullNameForUserID(ctx context.Context, userID uuid.UUID) (string, error) {
	_, fullName, err := r.ProfileNamesForUserID(ctx, userID)
	return fullName, err
}

func (r *UserResolver) ProfileNamesForUserID(ctx context.Context, userID uuid.UUID) (string, string, error) {
	resp, err := r.client.GetUserById(ctx, &userv1.GetUserByIdRequest{
		UserId: userID.String(),
	})
	if err != nil {
		return "", "", err
	}

	aggregate := resp.GetAggregate()
	if aggregate == nil || aggregate.GetProfile() == nil {
		return "", "", errors.New("empty user profile")
	}

	profile := aggregate.GetProfile()
	fullName := strings.TrimSpace(strings.Join([]string{
		strings.TrimSpace(profile.GetFirstName()),
		strings.TrimSpace(profile.GetLastName()),
	}, " "))
	if nickname := strings.TrimSpace(profile.GetNickname()); nickname != "" {
		return nickname, fullName, nil
	}
	return fullName, fullName, nil
}

func (r *UserResolver) EmailForUserID(ctx context.Context, userID uuid.UUID) (string, error) {
	resp, err := r.client.GetUserById(ctx, &userv1.GetUserByIdRequest{
		UserId: userID.String(),
	})
	if err != nil {
		return "", err
	}

	aggregate := resp.GetAggregate()
	if aggregate == nil || aggregate.GetUser() == nil {
		return "", errors.New("empty user aggregate")
	}
	return strings.TrimSpace(aggregate.GetUser().GetPrimaryEmail()), nil
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

func (r *UserResolver) GetUserProfileProjections(ctx context.Context, userIDs []uuid.UUID) (map[uuid.UUID]port.UserProfileProjection, error) {
	rawIDs := make([]string, 0, len(userIDs))
	for _, id := range userIDs {
		if id == uuid.Nil {
			continue
		}
		rawIDs = append(rawIDs, id.String())
	}
	if len(rawIDs) == 0 {
		return map[uuid.UUID]port.UserProfileProjection{}, nil
	}

	resp, err := r.client.GetPublicProfilesByUserIds(ctx, &userv1.GetPublicProfilesByUserIdsRequest{
		UserIds: rawIDs,
	})
	if err != nil {
		return nil, err
	}

	result := make(map[uuid.UUID]port.UserProfileProjection, len(resp.GetItems()))
	for _, item := range resp.GetItems() {
		userID, parseErr := uuid.Parse(strings.TrimSpace(item.GetUserId()))
		if parseErr != nil {
			continue
		}
		var nickname *string
		if value := strings.TrimSpace(item.GetNickname()); value != "" {
			nickname = &value
		}
		var avatarFileID *uuid.UUID
		if value := strings.TrimSpace(item.GetAvatarFileId()); value != "" {
			if parsed, err := uuid.Parse(value); err == nil {
				avatarFileID = &parsed
			}
		}
		result[userID] = port.UserProfileProjection{
			UserID:       userID,
			Nickname:     nickname,
			AvatarFileID: avatarFileID,
		}
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
