package model

import (
	"testing"

	"github.com/google/uuid"
	"kz/inflap/backend/services/guide-service/internal/domain/enum"
)

func TestGuideProfileRevokeDisablesGuideCapabilitiesAndStoresReason(t *testing.T) {
	profile, err := NewGuideProfile(NewGuideProfileParams{
		UserID: uuid.New(),
		Type:   enum.GuideTypeIndependent,
	})
	if err != nil {
		t.Fatalf("NewGuideProfile() error = %v", err)
	}
	if err = profile.Activate(); err != nil {
		t.Fatalf("Activate() error = %v", err)
	}
	profile.IsPrivateGuideAvailable = true
	profile.IsActivityHostAvailable = true
	profile.IsExcursionGuideAvailable = true

	reason := "Документ не подтверждает право проводить экскурсии."
	revokedBy := uuid.New()
	if err = profile.Revoke(reason, &revokedBy); err != nil {
		t.Fatalf("Revoke() error = %v", err)
	}

	if profile.Status != enum.GuideStatusRevoked {
		t.Fatalf("status = %s, want %s", profile.Status, enum.GuideStatusRevoked)
	}
	if profile.StatusReason == nil || *profile.StatusReason != reason {
		t.Fatalf("status reason = %#v, want %q", profile.StatusReason, reason)
	}
	if profile.StatusChangedBy == nil || *profile.StatusChangedBy != revokedBy {
		t.Fatalf("status changed by = %#v, want %s", profile.StatusChangedBy, revokedBy)
	}
	if profile.StatusChangedAt == nil {
		t.Fatal("status changed at must be set")
	}
	if profile.IsPrivateGuideAvailable || profile.IsActivityHostAvailable || profile.IsExcursionGuideAvailable {
		t.Fatal("revoked guide profile must not keep guide capabilities enabled")
	}
}

func TestGuideProfileRevokeRequiresReason(t *testing.T) {
	profile, err := NewGuideProfile(NewGuideProfileParams{
		UserID: uuid.New(),
		Type:   enum.GuideTypeIndependent,
	})
	if err != nil {
		t.Fatalf("NewGuideProfile() error = %v", err)
	}
	if err = profile.Activate(); err != nil {
		t.Fatalf("Activate() error = %v", err)
	}

	if err = profile.Revoke("   ", nil); err != ErrGuideRevocationReasonRequired {
		t.Fatalf("Revoke() error = %v, want %v", err, ErrGuideRevocationReasonRequired)
	}
}
