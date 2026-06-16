package model

import (
	"time"

	"github.com/google/uuid"
)

const (
	UserSocialEventFollowCreated     = "user.follow.created"
	UserSocialEventFollowDeleted     = "user.follow.deleted"
	UserSocialEventFriendshipCreated = "user.friendship.created"
	UserSocialEventFriendshipDeleted = "user.friendship.deleted"

	UserSocialEdgeFollowing = "following"
	UserSocialEdgeFriend    = "friend"
)

type UserSocialOutboxEvent struct {
	ID              uuid.UUID
	EventType       string
	ViewerUserID    uuid.UUID
	TargetUserID    uuid.UUID
	EdgeType        string
	Active          bool
	SourceUpdatedAt time.Time
	Status          string
	AttemptCount    int
	NextAttemptAt   time.Time
	LastError       string
	CreatedAt       time.Time
	DeliveredAt     *time.Time
}
