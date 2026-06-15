package enum

import "strings"

type PostReportReason string

const (
	PostReportReasonSpam           PostReportReason = "SPAM"
	PostReportReasonHarassment     PostReportReason = "HARASSMENT"
	PostReportReasonHate           PostReportReason = "HATE"
	PostReportReasonSexualContent  PostReportReason = "SEXUAL_CONTENT"
	PostReportReasonViolence       PostReportReason = "VIOLENCE"
	PostReportReasonMisinformation PostReportReason = "MISINFORMATION"
	PostReportReasonIllegal        PostReportReason = "ILLEGAL"
	PostReportReasonOther          PostReportReason = "OTHER"
)

func (r PostReportReason) IsValid() bool {
	switch r {
	case PostReportReasonSpam,
		PostReportReasonHarassment,
		PostReportReasonHate,
		PostReportReasonSexualContent,
		PostReportReasonViolence,
		PostReportReasonMisinformation,
		PostReportReasonIllegal,
		PostReportReasonOther:
		return true
	default:
		return false
	}
}

func NormalizePostReportReason(reason PostReportReason) PostReportReason {
	return PostReportReason(strings.ToUpper(strings.TrimSpace(string(reason))))
}

type PostReportStatus string

const (
	PostReportStatusOpen      PostReportStatus = "OPEN"
	PostReportStatusReviewed  PostReportStatus = "REVIEWED"
	PostReportStatusDismissed PostReportStatus = "DISMISSED"
)

func (s PostReportStatus) IsValid() bool {
	switch s {
	case PostReportStatusOpen, PostReportStatusReviewed, PostReportStatusDismissed:
		return true
	default:
		return false
	}
}

func NormalizePostReportStatus(status PostReportStatus) PostReportStatus {
	normalized := PostReportStatus(strings.ToUpper(strings.TrimSpace(string(status))))
	if normalized == "" {
		return PostReportStatusOpen
	}
	return normalized
}
