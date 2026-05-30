package app

import (
	"context"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/file-manager-service/internal/domain/model"
	"kz/inflap/backend/services/file-manager-service/internal/domain/port"
)

const (
	trustActionFileUpload = "FILE_UPLOAD"
	trustActionFileBind   = "FILE_BIND"
)

func (u *FileUseCase) SetTrustPolicyClient(client port.TrustPolicyClient) {
	u.trustPolicy = client
}

func (u *FileBindingUseCase) SetTrustPolicyClient(client port.TrustPolicyClient) {
	u.trustPolicy = client
}

func checkTrustPolicy(ctx context.Context, client port.TrustPolicyClient, check port.TrustPolicyCheck) (port.TrustPolicyResult, error) {
	if client == nil || check.UserID == uuid.Nil {
		return port.TrustPolicyResult{Decision: port.TrustPolicyAllow}, nil
	}
	return client.CheckActionPolicy(ctx, check)
}

func filePolicyStatusFromDecision(result port.TrustPolicyResult) model.FilePolicyStatus {
	switch result.Decision {
	case port.TrustPolicyDeny:
		return model.FilePolicyDenied
	case port.TrustPolicyReview, port.TrustPolicyQuarantine, port.TrustPolicyPending:
		return model.FilePolicyQuarantined
	default:
		return model.FilePolicyAllowed
	}
}

func quarantinedPolicyResult(reason string) port.TrustPolicyResult {
	return port.TrustPolicyResult{
		Decision:   port.TrustPolicyQuarantine,
		ReasonCode: reason,
	}
}

func trustPolicyTimeString(value time.Time) string {
	if value.IsZero() {
		return ""
	}
	return value.UTC().Format(time.RFC3339)
}

func valueOrNilUUID(value *uuid.UUID) uuid.UUID {
	if value == nil {
		return uuid.Nil
	}
	return *value
}

func valueOrZeroTime(value *time.Time) time.Time {
	if value == nil {
		return time.Time{}
	}
	return *value
}
