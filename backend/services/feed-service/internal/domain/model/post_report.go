package model

import (
	"strings"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/feed-service/internal/domain/enum"
)

type PostReport struct {
	ID               uuid.UUID
	PostID           uuid.UUID
	CommunityID      *uuid.UUID
	ReporterUserID   uuid.UUID
	AuthorUserID     uuid.UUID
	Reason           enum.PostReportReason
	Details          string
	Status           enum.PostReportStatus
	ResolvedByUserID *uuid.UUID
	ResolutionNote   string
	CreatedAt        time.Time
	UpdatedAt        time.Time
	ResolvedAt       *time.Time
}

type NewPostReportParams struct {
	PostID         uuid.UUID
	CommunityID    *uuid.UUID
	ReporterUserID uuid.UUID
	AuthorUserID   uuid.UUID
	Reason         enum.PostReportReason
	Details        string
}

func NewPostReport(params NewPostReportParams) *PostReport {
	now := time.Now().UTC()
	reason := enum.NormalizePostReportReason(params.Reason)
	return &PostReport{
		ID:             uuid.New(),
		PostID:         params.PostID,
		CommunityID:    cloneUUIDPtr(params.CommunityID),
		ReporterUserID: params.ReporterUserID,
		AuthorUserID:   params.AuthorUserID,
		Reason:         reason,
		Details:        strings.TrimSpace(params.Details),
		Status:         enum.PostReportStatusOpen,
		CreatedAt:      now,
		UpdatedAt:      now,
	}
}

type PostReportSubmissionResult struct {
	Report           *PostReport
	Post             *Post
	OpenReportsCount int
	AutoHidden       bool
}

type PostReportResolution struct {
	ReportID         uuid.UUID
	CommunityID      uuid.UUID
	Status           enum.PostReportStatus
	ResolvedByUserID uuid.UUID
	ResolutionNote   string
	ResolvedAt       time.Time
}

type PostReportListFilter struct {
	CommunityID uuid.UUID
	Status      *enum.PostReportStatus
	Limit       int
	Offset      int
}

func cloneUUIDPtr(value *uuid.UUID) *uuid.UUID {
	if value == nil {
		return nil
	}
	copied := *value
	return &copied
}
