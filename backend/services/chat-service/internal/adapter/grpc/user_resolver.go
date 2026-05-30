package grpc

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"kz/inflap/backend/services/chat-service/internal/domain/port"
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
		return uuid.Nil, fmt.Errorf("resolve user by subject: %w", err)
	}
	return uuid.Parse(resp.GetAggregate().GetUser().GetId())
}

func (r *UserResolver) GetPublicProfilesByUserIDs(
	ctx context.Context,
	userIDs []uuid.UUID,
) (map[uuid.UUID]port.PublicUserProfile, error) {
	ids := make([]string, 0, len(userIDs))
	seen := make(map[uuid.UUID]struct{}, len(userIDs))
	for _, userID := range userIDs {
		if userID == uuid.Nil {
			continue
		}
		if _, ok := seen[userID]; ok {
			continue
		}
		seen[userID] = struct{}{}
		ids = append(ids, userID.String())
	}
	if len(ids) == 0 {
		return nil, nil
	}

	resp, err := r.client.GetPublicProfilesByUserIds(ctx, &userv1.GetPublicProfilesByUserIdsRequest{
		UserIds: ids,
	})
	if err != nil {
		return nil, fmt.Errorf("get public profiles by user ids: %w", err)
	}

	profiles := make(map[uuid.UUID]port.PublicUserProfile, len(resp.GetItems()))
	for _, item := range resp.GetItems() {
		userID, err := uuid.Parse(strings.TrimSpace(item.GetUserId()))
		if err != nil {
			return nil, fmt.Errorf("parse public profile user id: %w", err)
		}

		profiles[userID] = publicProfileFromProto(userID, item)
	}

	for _, userID := range uniqueIDsFromUUIDs(userIDs) {
		if _, ok := profiles[userID]; ok {
			continue
		}
		resp, err := r.client.GetUserById(ctx, &userv1.GetUserByIdRequest{
			UserId: userID.String(),
		})
		if err != nil {
			continue
		}
		profile := resp.GetAggregate().GetProfile()
		if profile == nil {
			continue
		}

		profiles[userID] = userProfileFromProto(userID, profile)
	}

	return profiles, nil
}

func uniqueIDsFromUUIDs(userIDs []uuid.UUID) []uuid.UUID {
	seen := make(map[uuid.UUID]struct{}, len(userIDs))
	uniqueIDs := make([]uuid.UUID, 0, len(userIDs))
	for _, userID := range userIDs {
		if userID == uuid.Nil {
			continue
		}
		if _, ok := seen[userID]; ok {
			continue
		}
		seen[userID] = struct{}{}
		uniqueIDs = append(uniqueIDs, userID)
	}
	return uniqueIDs
}

func publicProfileFromProto(userID uuid.UUID, item *userv1.PublicProfile) port.PublicUserProfile {
	var avatarFileID *string
	if v := strings.TrimSpace(item.GetAvatarFileId()); v != "" {
		avatarFileID = &v
	}

	return port.PublicUserProfile{
		UserID:       userID,
		DisplayName:  strings.TrimSpace(item.GetDisplayName()),
		AvatarFileID: avatarFileID,
		IsOnline:     item.GetIsOnline(),
		LastSeenAt:   parseOptionalRFC3339(item.GetLastSeenAt()),
	}
}

func userProfileFromProto(userID uuid.UUID, profile *userv1.UserProfile) port.PublicUserProfile {
	var avatarFileID *string
	if v := strings.TrimSpace(profile.GetAvatarFileId()); v != "" {
		avatarFileID = &v
	}

	displayName := strings.TrimSpace(profile.GetDisplayName())
	if displayName == "" {
		displayName = strings.TrimSpace(strings.Join([]string{
			strings.TrimSpace(profile.GetFirstName()),
			strings.TrimSpace(profile.GetLastName()),
		}, " "))
	}

	return port.PublicUserProfile{
		UserID:       userID,
		DisplayName:  displayName,
		AvatarFileID: avatarFileID,
		IsOnline:     profile.GetIsOnline(),
		LastSeenAt:   parseOptionalRFC3339(profile.GetLastSeenAt()),
	}
}

func parseOptionalRFC3339(value string) *time.Time {
	value = strings.TrimSpace(value)
	if value == "" {
		return nil
	}
	parsed, err := time.Parse(time.RFC3339, value)
	if err != nil {
		return nil
	}
	utc := parsed.UTC()
	return &utc
}
