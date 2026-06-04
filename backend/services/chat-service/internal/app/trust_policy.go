package app

import (
	"context"

	"kz/inflap/backend/services/chat-service/internal/domain/port"
)

const (
	trustActionChatSend          = "CHAT_SEND"
	trustReasonPolicyUnavailable = "TRUST_POLICY_UNAVAILABLE"
)

func (u *MessageUseCase) SetTrustPolicyClient(client port.TrustPolicyClient) {
	u.trustPolicy = client
}

func checkTrustPolicy(ctx context.Context, client port.TrustPolicyClient, check port.TrustPolicyCheck) (port.TrustPolicyResult, error) {
	if client == nil {
		return port.TrustPolicyResult{Decision: port.TrustPolicyAllow}, nil
	}
	return client.CheckActionPolicy(ctx, check)
}

func unavailableTrustPolicyResult() port.TrustPolicyResult {
	return port.TrustPolicyResult{
		Decision:   port.TrustPolicyReview,
		ReasonCode: trustReasonPolicyUnavailable,
	}
}

func chatTrustReason(result port.TrustPolicyResult, fallback string) string {
	if result.ReasonCode != "" {
		return result.ReasonCode
	}
	return fallback
}
