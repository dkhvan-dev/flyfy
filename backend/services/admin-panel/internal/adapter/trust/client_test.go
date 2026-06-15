package trust

import (
	"testing"
	"time"

	"github.com/google/uuid"
	"google.golang.org/protobuf/types/known/timestamppb"

	"kz/inflap/backend/services/admin-panel/internal/domain/model"
	trustv1 "kz/inflap/proto/gen/go/trust/v1"
)

func TestTrustAppealFromProtoMapsDecisionFields(t *testing.T) {
	appealID := uuid.New()
	userID := uuid.New()
	restrictionID := uuid.New()
	staffID := uuid.New()
	decidedAt := time.Date(2026, 6, 12, 8, 30, 0, 0, time.UTC)

	got := trustAppealFromProto(&trustv1.RestrictionAppeal{
		AppealId:           appealID.String(),
		UserId:             userID.String(),
		RestrictionId:      restrictionID.String(),
		Status:             trustv1.RestrictionAppealStatus_RESTRICTION_APPEAL_STATUS_APPROVED,
		ReasonCode:         "false_positive",
		UserMessage:        "Please review",
		DecidedByStaffId:   staffID.String(),
		DecisionReasonCode: "mistake",
		StaffComment:       "Approved after review",
		DecidedAt:          timestamppb.New(decidedAt),
	})

	if got.ID != appealID || got.UserID != userID || got.RestrictionID != restrictionID {
		t.Fatalf("mapped ids = appeal:%s user:%s restriction:%s", got.ID, got.UserID, got.RestrictionID)
	}
	if got.Status != model.TrustRestrictionAppealStatusApproved {
		t.Fatalf("status = %q, want approved", got.Status)
	}
	if got.StaffDecision == nil || *got.StaffDecision != model.TrustRestrictionAppealDecisionApprove {
		t.Fatalf("staff decision = %#v, want approve", got.StaffDecision)
	}
	if got.DecidedByStaffID == nil || *got.DecidedByStaffID != staffID {
		t.Fatalf("decided by = %#v, want %s", got.DecidedByStaffID, staffID)
	}
	if got.DecidedAt == nil || !got.DecidedAt.Equal(decidedAt) {
		t.Fatalf("decided at = %#v, want %s", got.DecidedAt, decidedAt)
	}
}

func TestPageOffsetRejectsInvalidTokens(t *testing.T) {
	tests := map[string]int{
		"":    0,
		"abc": 0,
		"-10": 0,
		"25":  25,
	}

	for raw, want := range tests {
		if got := pageOffset(raw); got != want {
			t.Fatalf("pageOffset(%q) = %d, want %d", raw, got, want)
		}
	}
}

func TestDecisionEventIDDerivesStableUUIDFromFormKey(t *testing.T) {
	appealID := uuid.New()
	input := model.TrustRestrictionAppealDecisionInput{
		AppealID:       appealID,
		IdempotencyKey: "manual-form-key",
	}

	first := decisionEventID(input)
	second := decisionEventID(input)

	if _, err := uuid.Parse(first); err != nil {
		t.Fatalf("decisionEventID() returned invalid UUID %q: %v", first, err)
	}
	if first != second {
		t.Fatalf("decisionEventID() = %q then %q, want stable value", first, second)
	}
}
