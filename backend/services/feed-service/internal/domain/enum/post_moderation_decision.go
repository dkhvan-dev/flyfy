package enum

import "strings"

type PostModerationDecision string

const (
	PostModerationDecisionApprove PostModerationDecision = "APPROVE"
	PostModerationDecisionReject  PostModerationDecision = "REJECT"
)

func (d PostModerationDecision) IsValid() bool {
	switch d {
	case PostModerationDecisionApprove, PostModerationDecisionReject:
		return true
	default:
		return false
	}
}

func NormalizePostModerationDecision(decision PostModerationDecision) PostModerationDecision {
	return PostModerationDecision(strings.ToUpper(strings.TrimSpace(string(decision))))
}
