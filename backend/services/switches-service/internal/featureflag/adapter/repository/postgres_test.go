package repository

import (
	"context"
	"testing"
	"time"

	"kz/inflap/backend/services/switches-service/internal/featureflag/app"
)

func TestFeatureFlagHistoryCursorRoundTrip(t *testing.T) {
	expected := featureFlagHistoryCursor{
		UpdatedAt: time.Date(2026, 6, 20, 12, 30, 45, 123456000, time.UTC),
		ID:        42,
	}

	encoded := encodeFeatureFlagHistoryCursor(expected.UpdatedAt, expected.ID)
	actual, err := decodeFeatureFlagHistoryCursor(encoded)

	if err != nil {
		t.Fatalf("decode cursor: %v", err)
	}
	if !actual.UpdatedAt.Equal(expected.UpdatedAt) {
		t.Fatalf("updated_at = %s, want %s", actual.UpdatedAt, expected.UpdatedAt)
	}
	if actual.ID != expected.ID {
		t.Fatalf("id = %d, want %d", actual.ID, expected.ID)
	}
}

func TestFeatureFlagHistoryCursorRejectsInvalidValue(t *testing.T) {
	if _, err := decodeFeatureFlagHistoryCursor("not-a-valid-cursor"); err == nil {
		t.Fatal("expected invalid cursor error")
	}
}

func TestFindHistoryRejectsCursorWithUnsupportedOrder(t *testing.T) {
	repo := &PGRepository{}
	cursor := encodeFeatureFlagHistoryCursor(time.Now().UTC(), 1)

	_, err := repo.FindHistory(context.Background(), app.FeatureFlagHistorySearchRequest{
		DomainCode: "CORE",
		Code:       "SOME_FLAG",
		Size:       20,
		Cursor:     cursor,
		OrderBy:    "action_start_date",
	})

	if err == nil {
		t.Fatal("expected unsupported cursor order error")
	}
}
