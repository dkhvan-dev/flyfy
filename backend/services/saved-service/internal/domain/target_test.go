package domain

import (
	"errors"
	"strings"
	"testing"
)

func TestNewSavedTarget(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name       string
		entityType EntityType
		entityID   string
		wantID     string
		wantErr    error
	}{
		{name: "preserves opaque identifier", entityType: EntityTypeActivity, entityID: "source:activity:42", wantID: "source:activity:42"},
		{name: "accepts post target", entityType: EntityTypePost, entityID: "81ec585b-8eeb-4ff9-b5bd-80fdfbfaa9de", wantID: "81ec585b-8eeb-4ff9-b5bd-80fdfbfaa9de"},
		{name: "rejects surrounding whitespace instead of changing identity", entityType: EntityTypeActivity, entityID: " source:activity:42 ", wantErr: ErrTargetUnavailable},
		{name: "rejects control characters", entityType: EntityTypeActivity, entityID: "source:\n42", wantErr: ErrTargetUnavailable},
		{name: "rejects unsupported type", entityType: "CHECKLIST", entityID: "42", wantErr: ErrTargetTypeUnsupported},
		{name: "rejects retired excursion type", entityType: "EXCURSION", entityID: "42", wantErr: ErrTargetTypeUnsupported},
		{name: "rejects blank identifier", entityType: EntityTypeGuide, entityID: " \t ", wantErr: ErrTargetUnavailable},
		{name: "rejects oversized identifier", entityType: EntityTypeGuide, entityID: strings.Repeat("a", maxEntityIDBytes+1), wantErr: ErrTargetUnavailable},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			target, err := NewSavedTarget(test.entityType, test.entityID)
			if !errors.Is(err, test.wantErr) {
				t.Fatalf("NewSavedTarget() error = %v, want %v", err, test.wantErr)
			}
			if test.wantErr != nil {
				return
			}
			if target.EntityType() != test.entityType || target.EntityID() != test.wantID {
				t.Fatalf("NewSavedTarget() = (%q, %q), want (%q, %q)", target.EntityType(), target.EntityID(), test.entityType, test.wantID)
			}
		})
	}
}
