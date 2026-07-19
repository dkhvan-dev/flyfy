package repository

import (
	"strings"
	"testing"

	"kz/inflap/backend/services/guide-service/internal/domain/enum"
	"kz/inflap/backend/services/guide-service/internal/domain/port"
)

func TestPublicGuideWhereRequiresActiveProfileAndLatestApproval(t *testing.T) {
	where, args := buildPublicGuideWhere(port.PublicGuideListFilter{})
	query := strings.Join(where, " ")
	if !strings.Contains(query, "gp.status = $1") ||
		!strings.Contains(query, "gp.deleted_at IS NULL") ||
		!strings.Contains(query, "guide_verification_requests") ||
		!strings.Contains(query, "ORDER BY vr.created_at DESC, vr.id DESC") ||
		!strings.Contains(query, "= $2") {
		t.Fatalf("public guide predicate is missing lifecycle proof: %s", query)
	}
	if len(args) != 2 ||
		args[0] != string(enum.GuideStatusActive) ||
		args[1] != string(enum.VerificationRequestStatusApproved) {
		t.Fatalf("args = %#v, want ACTIVE/APPROVED", args)
	}
}
