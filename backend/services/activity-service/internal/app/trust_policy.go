package app

import (
	"context"
	"fmt"
	"time"

	"kz/inflap/backend/services/activity-service/internal/domain/port"
)

const (
	trustActionActivityCreate = "ACTIVITY_CREATE"
)

func (u *ActivityUseCase) SetTrustPolicyClient(client port.TrustPolicyClient) {
	u.trustPolicy = client
}

func checkTrustPolicy(ctx context.Context, client port.TrustPolicyClient, check port.TrustPolicyCheck) (port.TrustPolicyResult, error) {
	if client == nil {
		return port.TrustPolicyResult{Decision: port.TrustPolicyAllow}, nil
	}
	return client.CheckActionPolicy(ctx, check)
}

func activityTrustModerationReasons(result port.TrustPolicyResult, fallback string) []string {
	reason := result.ReasonCode
	if reason == "" {
		reason = fallback
	}
	return []string{reason}
}

func activityTrustPolicyError(result port.TrustPolicyResult) error {
	if result.PublicMessageKey != "" {
		return fmt.Errorf("%w: %s", ErrTrustPolicyRejected, result.PublicMessageKey)
	}
	return ErrTrustPolicyRejected
}

func trustPolicyNow() time.Time {
	return time.Now().UTC()
}

func trustPolicyOptionalString(value *string) string {
	if value == nil {
		return ""
	}
	return *value
}
