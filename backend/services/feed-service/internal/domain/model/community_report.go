package model

import (
	"strings"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/feed-service/internal/domain/enum"
)

type CommunityReport struct {
	ID             uuid.UUID
	CommunityID    uuid.UUID
	ReporterUserID uuid.UUID
	Reason         enum.PostReportReason
	Details        string
	Status         enum.PostReportStatus
	CreatedAt      time.Time
	UpdatedAt      time.Time
}

type NewCommunityReportParams struct {
	CommunityID    uuid.UUID
	ReporterUserID uuid.UUID
	Reason         enum.PostReportReason
	Details        string
}

func NewCommunityReport(params NewCommunityReportParams) *CommunityReport {
	now := time.Now().UTC()
	return &CommunityReport{
		ID:             uuid.New(),
		CommunityID:    params.CommunityID,
		ReporterUserID: params.ReporterUserID,
		Reason:         enum.NormalizePostReportReason(params.Reason),
		Details:        strings.TrimSpace(params.Details),
		Status:         enum.PostReportStatusOpen,
		CreatedAt:      now,
		UpdatedAt:      now,
	}
}

type CommunityReportSubmissionResult struct {
	Report           *CommunityReport
	OpenReportsCount int
}
