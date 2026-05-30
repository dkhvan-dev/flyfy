package app

import (
	"context"

	"kz/inflap/backend/services/excursion-service/internal/domain/model"
	"kz/inflap/backend/services/excursion-service/internal/domain/port"
)

const trustActionTourPublish = "TOUR_PUBLISH"

func (u *ExcursionUseCase) WithTrustPolicyClient(client port.TrustPolicyClient) *ExcursionUseCase {
	u.trustPolicy = client
	return u
}

func checkTrustPolicy(ctx context.Context, client port.TrustPolicyClient, check port.TrustPolicyCheck) (port.TrustPolicyResult, error) {
	if client == nil {
		return port.TrustPolicyResult{Decision: port.TrustPolicyAllow}, nil
	}
	return client.CheckActionPolicy(ctx, check)
}

func applyTrustReviewDecision(evaluation model.ExcursionPublishingEvaluation, result port.TrustPolicyResult, fallback string) model.ExcursionPublishingEvaluation {
	evaluation.Decision = model.ExcursionPublishingDecisionNeedsReview
	reason := result.ReasonCode
	if reason == "" {
		reason = fallback
	}
	evaluation.ReasonCodes = append(evaluation.ReasonCodes, reason)
	return evaluation
}
