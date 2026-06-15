package enum

import "strings"

type ModerationStatus string

const (
	ModerationStatusNotRequired ModerationStatus = "NOT_REQUIRED"
	ModerationStatusPending     ModerationStatus = "PENDING"
	ModerationStatusApproved    ModerationStatus = "APPROVED"
	ModerationStatusRejected    ModerationStatus = "REJECTED"
	ModerationStatusHidden      ModerationStatus = "HIDDEN"
)

func (s ModerationStatus) IsValid() bool {
	switch s {
	case ModerationStatusNotRequired, ModerationStatusPending, ModerationStatusApproved, ModerationStatusRejected, ModerationStatusHidden:
		return true
	default:
		return false
	}
}

func NormalizeModerationStatus(status ModerationStatus) ModerationStatus {
	normalized := ModerationStatus(strings.ToUpper(strings.TrimSpace(string(status))))
	if normalized == "" {
		return ModerationStatusNotRequired
	}
	return normalized
}
