package http

import (
	"testing"
	"time"

	"google.golang.org/protobuf/types/known/timestamppb"
	trustv1 "kz/inflap/proto/gen/go/trust/v1"
)

func TestRestrictionIDFromAppealPath(t *testing.T) {
	tests := map[string]struct {
		path string
		want string
	}{
		"valid": {
			path: "/api/v1/trust/restrictions/2f1a5e7b-5ef8-4b77-9fed-fb5a2a64efdf/appeals",
			want: "2f1a5e7b-5ef8-4b77-9fed-fb5a2a64efdf",
		},
		"valid custom prefix": {
			path: "/v2/trust/restrictions/restriction-1/appeals",
			want: "restriction-1",
		},
		"nested id rejected": {
			path: "/api/v1/trust/restrictions/restriction-1/extra/appeals",
			want: "",
		},
		"missing suffix rejected": {
			path: "/api/v1/trust/restrictions/restriction-1",
			want: "",
		},
	}

	for name, tc := range tests {
		t.Run(name, func(t *testing.T) {
			prefix := "/api/v1"
			if name == "valid custom prefix" {
				prefix = "/v2"
			}
			if got := restrictionIDFromAppealPath(tc.path, prefix); got != tc.want {
				t.Fatalf("restrictionIDFromAppealPath() = %q, want %q", got, tc.want)
			}
		})
	}
}

func TestActiveRestrictionsFromProtoSanitizesPublicPayload(t *testing.T) {
	expiresAt := time.Date(2026, 7, 20, 12, 0, 0, 0, time.UTC)
	createdAt := time.Date(2026, 7, 11, 11, 0, 0, 0, time.UTC)
	items := activeRestrictionsFromProto([]*trustv1.ActiveRestriction{
		nil,
		{RestrictionId: "", RestrictionCode: "ACTIVITY_CREATION"},
		{
			RestrictionId:   "restriction-1",
			RestrictionCode: "ACTIVITY_CREATION",
			ReasonCode:      "staff_restriction",
			ExpiresAt:       timestamppb.New(expiresAt),
			CreatedAt:       timestamppb.New(createdAt),
		},
	})

	if len(items) != 1 {
		t.Fatalf("active restrictions = %d, want 1 valid item", len(items))
	}
	got := items[0]
	if got.RestrictionID != "restriction-1" || got.RestrictionCode != "ACTIVITY_CREATION" || got.ReasonCode != "staff_restriction" {
		t.Fatalf("active restriction payload = %+v", got)
	}
	if got.ExpiresAt != expiresAt.Format(time.RFC3339) || got.CreatedAt != createdAt.Format(time.RFC3339) {
		t.Fatalf("restriction timestamps = %q/%q", got.ExpiresAt, got.CreatedAt)
	}
}

func TestRestrictionAppealStatusFromQuery(t *testing.T) {
	tests := map[string]trustv1.RestrictionAppealStatus{
		"":         trustv1.RestrictionAppealStatus_RESTRICTION_APPEAL_STATUS_UNSPECIFIED,
		"open":     trustv1.RestrictionAppealStatus_RESTRICTION_APPEAL_STATUS_PENDING,
		"PENDING":  trustv1.RestrictionAppealStatus_RESTRICTION_APPEAL_STATUS_PENDING,
		"approved": trustv1.RestrictionAppealStatus_RESTRICTION_APPEAL_STATUS_APPROVED,
		"rejected": trustv1.RestrictionAppealStatus_RESTRICTION_APPEAL_STATUS_REJECTED,
	}

	for raw, want := range tests {
		if got := restrictionAppealStatusFromQuery(raw); got != want {
			t.Fatalf("restrictionAppealStatusFromQuery(%q) = %s, want %s", raw, got, want)
		}
	}
}
