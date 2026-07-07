package model

import (
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/feed-service/internal/domain/enum"
)

type Community struct {
	ID                     uuid.UUID
	Slug                   string
	Title                  string
	TitleI18n              map[string]string
	Description            string
	DescriptionI18n        map[string]string
	Topic                  string
	Rules                  []string
	RulesI18n              map[string][]string
	CityID                 *string
	CountryCode            *string
	LanguageCode           string
	AvatarFileID           *uuid.UUID
	CoverFileID            *uuid.UUID
	Visibility             enum.CommunityVisibility
	PostingPolicy          enum.CommunityPostingPolicy
	Status                 enum.CommunityStatus
	DefaultPostProfileKey  enum.PostProfileKey
	AllowedPostProfileKeys []string
	EnabledTabs            []string
	FollowerCount          int
	PostCount              int
	CreatedByAdminID       *uuid.UUID
	CreatedAt              time.Time
	UpdatedAt              time.Time
	DeletedAt              *time.Time
}

func (c *Community) IsPubliclyVisible() bool {
	return c != nil &&
		c.DeletedAt == nil &&
		c.Status == enum.CommunityStatusActive &&
		c.Visibility == enum.CommunityVisibilityPublic
}

func (c *Community) IsActive() bool {
	return c != nil &&
		c.DeletedAt == nil &&
		c.Status == enum.CommunityStatusActive
}

type CommunityMembership struct {
	CommunityID uuid.UUID
	UserID      uuid.UUID
	Role        enum.CommunityMembershipRole
	Status      enum.CommunityMembershipStatus
	CreatedAt   time.Time
	UpdatedAt   time.Time
}

type CommunityMemberRoleChange struct {
	ID           uuid.UUID
	CommunityID  uuid.UUID
	TargetUserID uuid.UUID
	ActorUserID  uuid.UUID
	PreviousRole enum.CommunityMembershipRole
	NextRole     enum.CommunityMembershipRole
	CreatedAt    time.Time
}

type CommunityMemberRoleChangeListFilter struct {
	CommunityID  uuid.UUID
	TargetUserID uuid.UUID
	Limit        int
	Offset       int
}

type CommunityMemberStatusChange struct {
	ID             uuid.UUID
	CommunityID    uuid.UUID
	TargetUserID   uuid.UUID
	ActorUserID    uuid.UUID
	PreviousStatus enum.CommunityMembershipStatus
	NextStatus     enum.CommunityMembershipStatus
	CreatedAt      time.Time
}

type CommunityListFilter struct {
	Topic                   string
	CountryCode             string
	CityID                  string
	Search                  string
	PublicOnly              bool
	IncludeDeleted          bool
	OnlyFollowedByUserID    *uuid.UUID
	ExcludeFollowedByUserID *uuid.UUID
	Limit                   int
	Offset                  int
}

type CommunityMemberListFilter struct {
	CommunityID uuid.UUID
	Role        *enum.CommunityMembershipRole
	Status      *enum.CommunityMembershipStatus
	Limit       int
	Offset      int
}
