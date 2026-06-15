package http

import (
	"testing"

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
