package model

import (
	"errors"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/guide-service/internal/domain/enum"
)

var (
	ErrInvalidVerificationRequestID      = errors.New("invalid verification request id")
	ErrInvalidVerificationGuideProfileID = errors.New("invalid verification guide profile id")
	ErrInvalidVerificationStatus         = errors.New("invalid verification status")
)

type GuideVerificationRequest struct {
	ID             uuid.UUID
	GuideProfileID uuid.UUID
	Status         enum.VerificationRequestStatus
	Comment        *string
	ReviewComment  *string
	SubmittedAt    *time.Time
	ReviewedAt     *time.Time
	ReviewedBy     *uuid.UUID
	CreatedAt      time.Time
	UpdatedAt      time.Time
}

type NewGuideVerificationRequestParams struct {
	GuideProfileID uuid.UUID
	Comment        *string
}

func NewGuideVerificationRequest(params NewGuideVerificationRequestParams) (*GuideVerificationRequest, error) {
	now := time.Now().UTC()

	req := &GuideVerificationRequest{
		ID:             uuid.New(),
		GuideProfileID: params.GuideProfileID,
		Status:         enum.VerificationRequestStatusDraft,
		Comment:        normalizeOptionalString(params.Comment),
		CreatedAt:      now,
		UpdatedAt:      now,
	}

	if err := req.Validate(); err != nil {
		return nil, err
	}

	return req, nil
}

func (r *GuideVerificationRequest) Validate() error {
	if r.ID == uuid.Nil {
		return ErrInvalidVerificationRequestID
	}
	if r.GuideProfileID == uuid.Nil {
		return ErrInvalidVerificationGuideProfileID
	}
	if !r.Status.IsValid() {
		return ErrInvalidVerificationStatus
	}
	return nil
}

func (r *GuideVerificationRequest) Submit(comment *string) error {
	if r.ID == uuid.Nil {
		return ErrInvalidVerificationRequestID
	}

	now := time.Now().UTC()
	r.Status = enum.VerificationRequestStatusSubmitted
	r.Comment = normalizeOptionalString(comment)
	r.SubmittedAt = &now
	r.UpdatedAt = now

	return r.Validate()
}

func (r *GuideVerificationRequest) MarkUnderReview(reviewerID *uuid.UUID) error {
	if r.ID == uuid.Nil {
		return ErrInvalidVerificationRequestID
	}

	now := time.Now().UTC()
	r.Status = enum.VerificationRequestStatusUnderReview
	r.ReviewedBy = reviewerID
	r.UpdatedAt = now

	return r.Validate()
}

func (r *GuideVerificationRequest) Approve(reviewerID *uuid.UUID, reviewComment *string) error {
	if r.ID == uuid.Nil {
		return ErrInvalidVerificationRequestID
	}

	now := time.Now().UTC()
	r.Status = enum.VerificationRequestStatusApproved
	r.ReviewComment = normalizeOptionalString(reviewComment)
	r.ReviewedAt = &now
	r.ReviewedBy = reviewerID
	r.UpdatedAt = now

	return r.Validate()
}

func (r *GuideVerificationRequest) Reject(reviewerID *uuid.UUID, reviewComment *string) error {
	if r.ID == uuid.Nil {
		return ErrInvalidVerificationRequestID
	}

	now := time.Now().UTC()
	r.Status = enum.VerificationRequestStatusRejected
	r.ReviewComment = normalizeOptionalString(reviewComment)
	r.ReviewedAt = &now
	r.ReviewedBy = reviewerID
	r.UpdatedAt = now

	return r.Validate()
}

func normalizeOptionalString(v *string) *string {
	if v == nil {
		return nil
	}
	s := strings.TrimSpace(*v)
	if s == "" {
		return nil
	}
	return &s
}
