package app

import (
	"context"
	"strings"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"kz/inflap/backend/services/chat-service/internal/domain/model"
	"kz/inflap/backend/services/chat-service/internal/domain/port"
)

func enrichParticipants(ctx context.Context, resolver port.UserProfileResolver, participants []*model.Participant) {
	if resolver == nil || len(participants) == 0 {
		return
	}

	userIDs := make([]uuid.UUID, 0, len(participants))
	for _, participant := range participants {
		if participant != nil && participant.UserID != uuid.Nil {
			userIDs = append(userIDs, participant.UserID)
		}
	}

	profiles := loadPublicProfiles(ctx, resolver, userIDs)
	applyProfilesToParticipants(profiles, participants)
}

func enrichParticipantsAndMessages(
	ctx context.Context,
	resolver port.UserProfileResolver,
	participants []*model.Participant,
	messages []*model.Message,
) {
	if resolver == nil {
		defaultParticipants(participants)
		defaultMessages(messages)
		return
	}

	userIDs := make([]uuid.UUID, 0, len(participants)+len(messages))
	for _, participant := range participants {
		if participant != nil && participant.UserID != uuid.Nil {
			userIDs = append(userIDs, participant.UserID)
		}
	}
	for _, message := range messages {
		if message == nil {
			continue
		}
		if message.SenderUserID == uuid.Nil {
			continue
		}
		userIDs = append(userIDs, message.SenderUserID)
	}

	profiles := loadPublicProfiles(ctx, resolver, userIDs)
	applyProfilesToParticipants(profiles, participants)
	applyProfilesToMessages(profiles, messages)
}

func applyProfilesToParticipants(
	profiles map[uuid.UUID]port.PublicUserProfile,
	participants []*model.Participant,
) {
	for _, participant := range participants {
		if participant == nil {
			continue
		}
		profile, ok := profiles[participant.UserID]
		if !ok {
			if strings.TrimSpace(participant.DisplayName) == "" {
				participant.DisplayName = "User"
			}
			continue
		}
		if strings.TrimSpace(profile.DisplayName) != "" {
			participant.DisplayName = profile.DisplayName
		}
		participant.AvatarFileID = profile.AvatarFileID
		participant.IsOnline = profile.IsOnline
		participant.LastSeenAt = profile.LastSeenAt
	}
}

func enrichMessages(ctx context.Context, resolver port.UserProfileResolver, messages []*model.Message) {
	if len(messages) == 0 {
		return
	}

	userIDs := make([]uuid.UUID, 0, len(messages))
	for _, message := range messages {
		if message == nil {
			continue
		}
		if message.SenderUserID == uuid.Nil {
			if strings.TrimSpace(message.SenderDisplayName) == "" {
				message.SenderDisplayName = "System"
			}
			message.SenderAvatarFileID = nil
			continue
		}
		userIDs = append(userIDs, message.SenderUserID)
	}

	if resolver == nil {
		return
	}

	profiles := loadPublicProfiles(ctx, resolver, userIDs)
	applyProfilesToMessages(profiles, messages)
}

func applyProfilesToMessages(
	profiles map[uuid.UUID]port.PublicUserProfile,
	messages []*model.Message,
) {
	for _, message := range messages {
		if message == nil {
			continue
		}
		if message.SenderUserID == uuid.Nil {
			continue
		}
		profile, ok := profiles[message.SenderUserID]
		if !ok {
			if strings.TrimSpace(message.SenderDisplayName) == "" {
				if message.Type == "system" {
					message.SenderDisplayName = "System"
				} else {
					message.SenderDisplayName = "User"
				}
			}
			continue
		}
		if strings.TrimSpace(profile.DisplayName) != "" {
			message.SenderDisplayName = profile.DisplayName
		}
		if message.Type == "system" {
			message.SenderAvatarFileID = nil
		} else {
			message.SenderAvatarFileID = profile.AvatarFileID
		}
	}
}

func defaultParticipants(participants []*model.Participant) {
	applyProfilesToParticipants(nil, participants)
}

func defaultMessages(messages []*model.Message) {
	applyProfilesToMessages(nil, messages)
}

func displayNameForUser(ctx context.Context, resolver port.UserProfileResolver, userID uuid.UUID, fallback string) string {
	fallback = strings.TrimSpace(fallback)
	if fallback == "" {
		fallback = "User"
	}
	if resolver == nil || userID == uuid.Nil {
		return fallback
	}

	profiles := loadPublicProfiles(ctx, resolver, []uuid.UUID{userID})
	if profile, ok := profiles[userID]; ok && strings.TrimSpace(profile.DisplayName) != "" {
		return profile.DisplayName
	}
	return fallback
}

func loadPublicProfiles(
	ctx context.Context,
	resolver port.UserProfileResolver,
	userIDs []uuid.UUID,
) map[uuid.UUID]port.PublicUserProfile {
	if resolver == nil || len(userIDs) == 0 {
		return nil
	}

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
	if len(uniqueIDs) == 0 {
		return nil
	}

	profiles, err := resolver.GetPublicProfilesByUserIDs(ctx, uniqueIDs)
	if err != nil {
		log.Warn().Err(err).Msg("failed to load chat public profiles")
		return nil
	}
	return profiles
}
