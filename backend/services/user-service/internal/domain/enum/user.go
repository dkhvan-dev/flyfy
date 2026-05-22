package enum

type UserStatus string

const (
	UserStatusActive  UserStatus = "ACTIVE"
	UserStatusBlocked UserStatus = "BLOCKED"
	UserStatusDeleted UserStatus = "DELETED"
)

func (s UserStatus) IsValid() bool {
	switch s {
	case UserStatusActive, UserStatusBlocked, UserStatusDeleted:
		return true
	default:
		return false
	}
}

type SystemRole string

const (
	SystemRoleUser      SystemRole = "USER"
	SystemRoleAdmin     SystemRole = "ADMIN"
	SystemRoleModerator SystemRole = "MODERATOR"
	SystemRoleSupport   SystemRole = "SUPPORT"
)

func (r SystemRole) IsValid() bool {
	switch r {
	case SystemRoleUser, SystemRoleAdmin, SystemRoleModerator, SystemRoleSupport:
		return true
	default:
		return false
	}
}

type FriendshipStatus string

const (
	FriendshipStatusPending  FriendshipStatus = "PENDING"
	FriendshipStatusAccepted FriendshipStatus = "ACCEPTED"
)

func (s FriendshipStatus) IsValid() bool {
	switch s {
	case FriendshipStatusPending, FriendshipStatusAccepted:
		return true
	default:
		return false
	}
}
