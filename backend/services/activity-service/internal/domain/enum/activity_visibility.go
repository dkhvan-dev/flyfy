package enum

type ActivityVisibility string

const (
	ActivityVisibilityPublic   ActivityVisibility = "PUBLIC"
	ActivityVisibilityPrivate  ActivityVisibility = "PRIVATE"
	ActivityVisibilityUnlisted ActivityVisibility = "UNLISTED"
)

func (v ActivityVisibility) IsValid() bool {
	switch v {
	case ActivityVisibilityPublic, ActivityVisibilityPrivate, ActivityVisibilityUnlisted:
		return true
	default:
		return false
	}
}
