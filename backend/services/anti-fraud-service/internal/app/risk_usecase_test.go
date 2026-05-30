package app

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/anti-fraud-service/internal/domain/model"
	"kz/inflap/backend/services/anti-fraud-service/internal/domain/port"
)

func TestRiskUseCaseBlocksOtpRequestWhenPhoneVelocityIsHigh(t *testing.T) {
	ctx := context.Background()
	repo := newMemoryRiskRepository()
	useCase := NewRiskUseCase(repo, Policy{
		Version:                "test-policy",
		ShadowMode:             false,
		OTPSendPhoneLimit:      3,
		OTPSendIPLimit:         20,
		UploadUserLimit:        50,
		HighPaymentAmountMinor: 1_000_000,
		Window:                 time.Hour,
	})

	actorID := uuid.New()
	for i := 0; i < 3; i++ {
		if err := repo.CreateEvent(ctx, &model.RiskEvent{
			ID:          uuid.New(),
			Action:      ActionAuthOTPRequest,
			ActorUserID: &actorID,
			SignalHashes: map[string]string{
				"phone": "phone-hash",
				"ip":    "ip-hash",
			},
			Metadata:  map[string]any{},
			CreatedAt: time.Now().UTC().Add(-time.Duration(i) * time.Minute),
		}); err != nil {
			t.Fatalf("seed risk event: %v", err)
		}
	}

	decision, err := useCase.AssessAction(ctx, AssessActionInput{
		Action:      ActionAuthOTPRequest,
		ActorUserID: &actorID,
		SignalHashes: map[string]string{
			"phone": "phone-hash",
			"ip":    "ip-hash",
		},
		Metadata: map[string]any{},
	})
	if err != nil {
		t.Fatalf("assess otp request: %v", err)
	}

	if decision.Decision != model.RiskDecisionBlock {
		t.Fatalf("expected BLOCK, got %s", decision.Decision)
	}
	if !hasReason(decision.Reasons, ReasonOTPPhoneVelocity) {
		t.Fatalf("expected reason %s, got %#v", ReasonOTPPhoneVelocity, decision.Reasons)
	}
	if decision.ShadowMode {
		t.Fatal("expected enforced decision, got shadow decision")
	}
}

func TestRiskUseCaseReviewsHighValuePayment(t *testing.T) {
	ctx := context.Background()
	repo := newMemoryRiskRepository()
	useCase := NewRiskUseCase(repo, Policy{
		Version:                "test-policy",
		ShadowMode:             true,
		OTPSendPhoneLimit:      5,
		OTPSendIPLimit:         20,
		UploadUserLimit:        50,
		HighPaymentAmountMinor: 1_000_000,
		Window:                 time.Hour,
	})

	decision, err := useCase.AssessAction(ctx, AssessActionInput{
		Action:      ActionPaymentCharge,
		ActorUserID: uuidPtr(uuid.New()),
		AmountMinor: int64Ptr(1_500_000),
		Currency:    "KZT",
		Metadata:    map[string]any{},
	})
	if err != nil {
		t.Fatalf("assess high value payment: %v", err)
	}

	if decision.Decision != model.RiskDecisionReview {
		t.Fatalf("expected REVIEW, got %s", decision.Decision)
	}
	if !decision.ShadowMode {
		t.Fatal("expected shadow decision for configured shadow mode")
	}
	if !hasReason(decision.Reasons, ReasonHighPaymentAmount) {
		t.Fatalf("expected reason %s, got %#v", ReasonHighPaymentAmount, decision.Reasons)
	}
}

func TestRiskUseCaseAllowsNormalUploadAndPersistsEventAndAssessment(t *testing.T) {
	ctx := context.Background()
	repo := newMemoryRiskRepository()
	useCase := NewRiskUseCase(repo, Policy{
		Version:                "test-policy",
		ShadowMode:             false,
		OTPSendPhoneLimit:      5,
		OTPSendIPLimit:         20,
		UploadUserLimit:        50,
		HighPaymentAmountMinor: 1_000_000,
		Window:                 time.Hour,
	})

	actorID := uuid.New()
	decision, err := useCase.AssessAction(ctx, AssessActionInput{
		Action:      ActionFileUploadRequest,
		ActorUserID: &actorID,
		SignalHashes: map[string]string{
			"ip": "ip-hash",
		},
		Metadata: map[string]any{
			"purpose":     "AVATAR",
			"contentType": "image/jpeg",
			"sizeBytes":   float64(100_000),
		},
	})
	if err != nil {
		t.Fatalf("assess upload: %v", err)
	}

	if decision.Decision != model.RiskDecisionAllow {
		t.Fatalf("expected ALLOW, got %s", decision.Decision)
	}
	if len(repo.events) != 1 {
		t.Fatalf("expected one persisted risk event, got %d", len(repo.events))
	}
	if len(repo.assessments) != 1 {
		t.Fatalf("expected one persisted assessment, got %d", len(repo.assessments))
	}
}

func TestRiskUseCaseReviewsActivityCreateWhenActorVelocityIsHigh(t *testing.T) {
	ctx := context.Background()
	repo := newMemoryRiskRepository()
	useCase := NewRiskUseCase(repo, Policy{
		Version:                 "test-policy",
		ShadowMode:              false,
		ActivityCreateUserLimit: 2,
		Window:                  time.Hour,
	})

	actorID := uuid.New()
	for i := 0; i < 2; i++ {
		if err := repo.CreateEvent(ctx, &model.RiskEvent{
			ID:          uuid.New(),
			Action:      ActionActivityCreate,
			ActorUserID: &actorID,
			Metadata:    map[string]any{},
			CreatedAt:   time.Now().UTC().Add(-time.Duration(i) * time.Minute),
		}); err != nil {
			t.Fatalf("seed activity event: %v", err)
		}
	}

	decision, err := useCase.AssessAction(ctx, AssessActionInput{
		Action:      ActionActivityCreate,
		ActorUserID: &actorID,
		Metadata: map[string]any{
			"priceMinor": float64(10_000),
			"capacity":   float64(6),
		},
	})
	if err != nil {
		t.Fatalf("assess activity create: %v", err)
	}

	if decision.Decision != model.RiskDecisionReview {
		t.Fatalf("expected REVIEW, got %s", decision.Decision)
	}
	if !hasReason(decision.Reasons, ReasonActivityCreateVelocity) {
		t.Fatalf("expected reason %s, got %#v", ReasonActivityCreateVelocity, decision.Reasons)
	}
}

func TestRiskUseCaseReviewsExcursionPublishWhenActorVelocityIsHigh(t *testing.T) {
	ctx := context.Background()
	repo := newMemoryRiskRepository()
	useCase := NewRiskUseCase(repo, Policy{
		Version:                   "test-policy",
		ShadowMode:                false,
		ExcursionPublishUserLimit: 1,
		Window:                    time.Hour,
	})

	actorID := uuid.New()
	if err := repo.CreateEvent(ctx, &model.RiskEvent{
		ID:          uuid.New(),
		Action:      ActionExcursionPublish,
		ActorUserID: &actorID,
		Metadata:    map[string]any{},
		CreatedAt:   time.Now().UTC().Add(-time.Minute),
	}); err != nil {
		t.Fatalf("seed excursion publish event: %v", err)
	}

	decision, err := useCase.AssessAction(ctx, AssessActionInput{
		Action:      ActionExcursionPublish,
		ActorUserID: &actorID,
		Metadata: map[string]any{
			"guideVerificationStatus": "VERIFIED",
		},
	})
	if err != nil {
		t.Fatalf("assess excursion publish: %v", err)
	}

	if decision.Decision != model.RiskDecisionReview {
		t.Fatalf("expected REVIEW, got %s", decision.Decision)
	}
	if !hasReason(decision.Reasons, ReasonExcursionPublishVelocity) {
		t.Fatalf("expected reason %s, got %#v", ReasonExcursionPublishVelocity, decision.Reasons)
	}
}

func TestRiskUseCaseReviewsHighExcursionPriceChange(t *testing.T) {
	ctx := context.Background()
	repo := newMemoryRiskRepository()
	useCase := NewRiskUseCase(repo, Policy{
		Version:                       "test-policy",
		ShadowMode:                    false,
		HighPriceChangePercent:        50,
		HighPriceChangeAmountMinor:    50_000,
		HighPaymentAmountMinor:        1_000_000,
		ActivityCreateUserLimit:       10,
		ExcursionPublishUserLimit:     10,
		ActivityJoinUserLimit:         10,
		ExcursionBookingUserLimit:     10,
		ActivityCancellationUserLimit: 10,
		ExcursionCancelUserLimit:      10,
		Window:                        time.Hour,
	})

	decision, err := useCase.AssessAction(ctx, AssessActionInput{
		Action:      ActionExcursionPriceChange,
		ActorUserID: uuidPtr(uuid.New()),
		Metadata: map[string]any{
			"oldPriceMinor": float64(100_000),
			"newPriceMinor": float64(180_000),
		},
	})
	if err != nil {
		t.Fatalf("assess excursion price change: %v", err)
	}

	if decision.Decision != model.RiskDecisionReview {
		t.Fatalf("expected REVIEW, got %s", decision.Decision)
	}
	if !hasReason(decision.Reasons, ReasonHighPriceChange) {
		t.Fatalf("expected reason %s, got %#v", ReasonHighPriceChange, decision.Reasons)
	}
}

func TestRiskUseCaseDoesNotReviewTinyPriceChangeByPercentOnly(t *testing.T) {
	ctx := context.Background()
	repo := newMemoryRiskRepository()
	useCase := NewRiskUseCase(repo, Policy{
		Version:                    "test-policy",
		ShadowMode:                 false,
		HighPriceChangePercent:     50,
		HighPriceChangeAmountMinor: 50_000,
		Window:                     time.Hour,
	})

	decision, err := useCase.AssessAction(ctx, AssessActionInput{
		Action:      ActionExcursionPriceChange,
		ActorUserID: uuidPtr(uuid.New()),
		Metadata: map[string]any{
			"oldPriceMinor": float64(100),
			"newPriceMinor": float64(200),
		},
	})
	if err != nil {
		t.Fatalf("assess tiny excursion price change: %v", err)
	}

	if decision.Decision != model.RiskDecisionAllow {
		t.Fatalf("expected ALLOW, got %s with reasons %#v", decision.Decision, decision.Reasons)
	}
}

func TestRiskUseCaseListsOpenFraudBlocksByTargetType(t *testing.T) {
	ctx := context.Background()
	repo := newMemoryRiskRepository()
	useCase := NewRiskUseCase(repo, Policy{Version: "test-policy", Window: time.Hour})

	activityID := uuid.New()
	excursionID := uuid.New()
	guideApplicationID := uuid.New()
	repo.assessments = append(repo.assessments,
		&model.RiskAssessment{
			ID:           uuid.New(),
			Action:       ActionActivityCreate,
			SubjectType:  "ACTIVITY",
			SubjectID:    &activityID,
			Decision:     model.RiskDecisionReview,
			RiskScore:    72,
			ReviewStatus: model.RiskReviewStatusOpen,
			CreatedAt:    time.Now().UTC(),
		},
		&model.RiskAssessment{
			ID:           uuid.New(),
			Action:       ActionExcursionPublish,
			SubjectType:  "EXCURSION",
			SubjectID:    &excursionID,
			Decision:     model.RiskDecisionBlock,
			RiskScore:    95,
			ReviewStatus: model.RiskReviewStatusOpen,
			CreatedAt:    time.Now().UTC().Add(-time.Minute),
		},
		&model.RiskAssessment{
			ID:           uuid.New(),
			Action:       ActionGuideApplication,
			SubjectType:  "GUIDE_APPLICATION",
			SubjectID:    &guideApplicationID,
			Decision:     model.RiskDecisionReview,
			RiskScore:    55,
			ReviewStatus: model.RiskReviewStatusOpen,
			CreatedAt:    time.Now().UTC().Add(-2 * time.Minute),
		},
	)

	items, err := useCase.ListFraudBlocks(ctx, ListFraudBlocksInput{
		TargetType: FraudBlockTargetActivity,
		Limit:      100,
	})
	if err != nil {
		t.Fatalf("ListFraudBlocks(activity) error = %v", err)
	}
	if len(items) != 1 || items[0].SubjectID == nil || *items[0].SubjectID != activityID {
		t.Fatalf("activity fraud blocks = %#v, want activity %s", items, activityID)
	}

	items, err = useCase.ListFraudBlocks(ctx, ListFraudBlocksInput{
		TargetType: FraudBlockTargetGuideApplication,
		Limit:      100,
	})
	if err != nil {
		t.Fatalf("ListFraudBlocks(guide_application) error = %v", err)
	}
	if len(items) != 0 {
		t.Fatalf("guide fraud blocks = %#v, want no REVIEW-only guide blocks", items)
	}
}

func TestRiskUseCaseReviewsFraudBlockWithAuditMetadata(t *testing.T) {
	ctx := context.Background()
	repo := newMemoryRiskRepository()
	useCase := NewRiskUseCase(repo, Policy{Version: "test-policy", Window: time.Hour})

	assessmentID := uuid.New()
	staffID := uuid.New()
	repo.assessments = append(repo.assessments, &model.RiskAssessment{
		ID:           assessmentID,
		Action:       ActionActivityCreate,
		SubjectType:  "ACTIVITY",
		Decision:     model.RiskDecisionReview,
		RiskScore:    72,
		ReviewStatus: model.RiskReviewStatusOpen,
		CreatedAt:    time.Now().UTC(),
	})

	updated, err := useCase.ReviewFraudBlock(ctx, ReviewFraudBlockInput{
		AssessmentID:      assessmentID,
		Status:            model.RiskReviewStatusFalsePositive,
		ReviewedByStaffID: staffID,
		ReasonCodes:       []string{"false_positive"},
		Comment:           "Manual review confirmed legitimate activity.",
	})
	if err != nil {
		t.Fatalf("ReviewFraudBlock() error = %v", err)
	}
	if updated.ReviewStatus != model.RiskReviewStatusFalsePositive {
		t.Fatalf("ReviewStatus = %s, want %s", updated.ReviewStatus, model.RiskReviewStatusFalsePositive)
	}
	if updated.ReviewedByStaffID == nil || *updated.ReviewedByStaffID != staffID {
		t.Fatalf("ReviewedByStaffID = %#v, want %s", updated.ReviewedByStaffID, staffID)
	}
	if updated.ReviewComment != "Manual review confirmed legitimate activity." {
		t.Fatalf("ReviewComment = %q", updated.ReviewComment)
	}
}

type memoryRiskRepository struct {
	events      []*model.RiskEvent
	assessments []*model.RiskAssessment
}

func newMemoryRiskRepository() *memoryRiskRepository {
	return &memoryRiskRepository{
		events:      make([]*model.RiskEvent, 0),
		assessments: make([]*model.RiskAssessment, 0),
	}
}

func (r *memoryRiskRepository) CreateEvent(ctx context.Context, event *model.RiskEvent) error {
	clone := *event
	clone.SignalHashes = cloneStringMap(event.SignalHashes)
	clone.Metadata = cloneAnyMap(event.Metadata)
	r.events = append(r.events, &clone)
	return nil
}

func (r *memoryRiskRepository) CountEvents(ctx context.Context, filter port.RiskEventFilter) (int, error) {
	count := 0
	for _, event := range r.events {
		if event.CreatedAt.Before(filter.Since) {
			continue
		}
		if filter.Action != "" && event.Action != filter.Action {
			continue
		}
		if filter.ActorUserID != nil && (event.ActorUserID == nil || *event.ActorUserID != *filter.ActorUserID) {
			continue
		}
		if filter.SignalKey != "" {
			if event.SignalHashes == nil || event.SignalHashes[filter.SignalKey] != filter.SignalHash {
				continue
			}
		}
		count++
	}
	return count, nil
}

func (r *memoryRiskRepository) CreateAssessment(ctx context.Context, assessment *model.RiskAssessment) error {
	clone := *assessment
	clone.Reasons = append([]string(nil), assessment.Reasons...)
	clone.ReviewReasonCodes = append([]string(nil), assessment.ReviewReasonCodes...)
	clone.Metadata = cloneAnyMap(assessment.Metadata)
	r.assessments = append(r.assessments, &clone)
	return nil
}

func (r *memoryRiskRepository) ListAssessments(ctx context.Context, filter port.RiskAssessmentFilter) ([]*model.RiskAssessment, error) {
	items := make([]*model.RiskAssessment, 0, len(r.assessments))
	subjectTypes := make(map[string]struct{}, len(filter.SubjectTypes))
	for _, value := range filter.SubjectTypes {
		subjectTypes[model.NormalizeCode(value)] = struct{}{}
	}
	decisions := make(map[model.RiskDecision]struct{}, len(filter.Decisions))
	for _, value := range filter.Decisions {
		decisions[value] = struct{}{}
	}
	statuses := make(map[model.RiskReviewStatus]struct{}, len(filter.ReviewStatuses))
	for _, value := range filter.ReviewStatuses {
		statuses[model.NormalizeReviewStatus(value)] = struct{}{}
	}
	for _, item := range r.assessments {
		if len(subjectTypes) > 0 {
			if _, ok := subjectTypes[model.NormalizeCode(item.SubjectType)]; !ok {
				continue
			}
		}
		if len(decisions) > 0 {
			if _, ok := decisions[item.Decision]; !ok {
				continue
			}
		}
		if len(statuses) > 0 {
			if _, ok := statuses[model.NormalizeReviewStatus(item.ReviewStatus)]; !ok {
				continue
			}
		}
		if filter.EnforcedOnly && item.ShadowMode {
			continue
		}
		clone := *item
		clone.Reasons = append([]string(nil), item.Reasons...)
		clone.ReviewReasonCodes = append([]string(nil), item.ReviewReasonCodes...)
		clone.Metadata = cloneAnyMap(item.Metadata)
		items = append(items, &clone)
	}
	return items, nil
}

func (r *memoryRiskRepository) UpdateAssessmentReview(ctx context.Context, input port.RiskAssessmentReviewInput) (*model.RiskAssessment, error) {
	for _, item := range r.assessments {
		if item.ID != input.AssessmentID {
			continue
		}
		item.ReviewStatus = model.NormalizeReviewStatus(input.Status)
		item.ReviewedByStaffID = &input.ReviewedByStaffID
		item.ReviewReasonCodes = append([]string(nil), input.ReasonCodes...)
		item.ReviewComment = input.Comment
		item.ReviewedAt = &input.ReviewedAt
		item.UpdatedAt = input.ReviewedAt
		clone := *item
		clone.Reasons = append([]string(nil), item.Reasons...)
		clone.ReviewReasonCodes = append([]string(nil), item.ReviewReasonCodes...)
		clone.Metadata = cloneAnyMap(item.Metadata)
		return &clone, nil
	}
	return nil, errors.New("assessment not found")
}

func hasReason(reasons []string, want string) bool {
	for _, reason := range reasons {
		if reason == want {
			return true
		}
	}
	return false
}

func uuidPtr(v uuid.UUID) *uuid.UUID {
	return &v
}

func int64Ptr(v int64) *int64 {
	return &v
}

func cloneStringMap(in map[string]string) map[string]string {
	if in == nil {
		return nil
	}
	out := make(map[string]string, len(in))
	for key, value := range in {
		out[key] = value
	}
	return out
}

func cloneAnyMap(in map[string]any) map[string]any {
	if in == nil {
		return nil
	}
	out := make(map[string]any, len(in))
	for key, value := range in {
		out[key] = value
	}
	return out
}
