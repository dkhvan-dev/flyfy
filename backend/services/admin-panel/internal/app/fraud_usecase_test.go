package app

import (
	"context"
	"encoding/json"
	"errors"
	"testing"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/admin-panel/internal/domain/enum"
	"github.com/dkhvan-dev/flyfy/backend/services/admin-panel/internal/domain/model"
)

func TestFraudReviewRequiresFraudReviewPermission(t *testing.T) {
	t.Parallel()

	uc := NewFraudUseCase(&fraudClientStub{}, &fraudAuditRepoStub{})
	actor := fraudTestStaff(enum.PermissionModerationRead)

	_, err := uc.ReviewBlock(context.Background(), ReviewFraudBlockInput{
		Actor:           actor,
		AssessmentID:    uuid.New(),
		Status:          model.FraudBlockReviewStatusFalsePositive,
		InternalComment: "manual verification passed",
	})
	if !errors.Is(err, ErrPermissionDenied) {
		t.Fatalf("ReviewBlock() error = %v, want ErrPermissionDenied", err)
	}
}

func TestFraudReviewWritesAuditEvent(t *testing.T) {
	t.Parallel()

	assessmentID := uuid.New()
	subjectID := uuid.New()
	client := &fraudClientStub{
		block: &model.FraudBlock{
			ID:           assessmentID,
			Action:       "ACTIVITY_CREATE",
			SubjectType:  "ACTIVITY",
			SubjectID:    &subjectID,
			Decision:     "REVIEW",
			RiskScore:    87,
			Reasons:      []string{"ACTIVITY_CREATE_VELOCITY"},
			ReviewStatus: model.FraudBlockReviewStatusFalsePositive,
		},
	}
	auditRepo := &fraudAuditRepoStub{}
	uc := NewFraudUseCase(client, auditRepo)

	_, err := uc.ReviewBlock(context.Background(), ReviewFraudBlockInput{
		Actor:           fraudTestStaff(enum.PermissionFraudReview),
		AssessmentID:    assessmentID,
		Status:          model.FraudBlockReviewStatusFalsePositive,
		ReasonCodes:     []string{"false_positive"},
		InternalComment: "manual verification passed",
		RequestMetadata: RequestMetadata{RequestID: "request-123", IPAddress: "127.0.0.1", UserAgent: "test"},
	})
	if err != nil {
		t.Fatalf("ReviewBlock() error = %v", err)
	}
	if auditRepo.event == nil {
		t.Fatal("expected audit event")
	}
	if auditRepo.event.Action != "fraud.block.false_positive" {
		t.Fatalf("audit action = %q, want fraud.block.false_positive", auditRepo.event.Action)
	}
	if auditRepo.event.EntityID == nil || *auditRepo.event.EntityID != assessmentID {
		t.Fatalf("audit entity id = %v, want %s", auditRepo.event.EntityID, assessmentID)
	}
	var metadata map[string]any
	if err = json.Unmarshal(auditRepo.event.Metadata, &metadata); err != nil {
		t.Fatalf("audit metadata is not valid json: %v", err)
	}
	if metadata["targetType"] != "ACTIVITY" || metadata["decision"] != "REVIEW" {
		t.Fatalf("unexpected audit metadata: %#v", metadata)
	}
}

func fraudTestStaff(permissions ...enum.Permission) *model.StaffUser {
	return &model.StaffUser{
		ID:          uuid.New(),
		Email:       "risk-lead@flyfy.local",
		DisplayName: "Risk Lead",
		Status:      enum.StaffStatusActive,
		Permissions: permissions,
	}
}

type fraudClientStub struct {
	block *model.FraudBlock
}

func (c *fraudClientStub) ListFraudBlocks(context.Context, model.FraudBlockTarget, int, int) ([]model.FraudBlock, error) {
	if c.block == nil {
		return nil, nil
	}
	return []model.FraudBlock{*c.block}, nil
}

func (c *fraudClientStub) ReviewFraudBlock(_ context.Context, input model.FraudBlockReviewInput) (*model.FraudBlock, error) {
	if c.block == nil {
		return nil, ErrInvalidInput
	}
	c.block.ReviewStatus = input.Status
	c.block.ReviewedByStaffID = &input.ReviewedByStaffID
	c.block.ReviewReasonCodes = append([]string(nil), input.ReasonCodes...)
	c.block.ReviewComment = input.Comment
	return c.block, nil
}

type fraudAuditRepoStub struct {
	event *model.AuditEvent
}

func (r *fraudAuditRepoStub) Append(_ context.Context, event *model.AuditEvent) error {
	r.event = event
	return nil
}

func (r *fraudAuditRepoStub) List(context.Context, model.AuditFilter) ([]*model.AuditEvent, error) {
	return nil, nil
}
