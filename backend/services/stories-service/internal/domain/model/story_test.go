package model

import (
	"encoding/json"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/stories-service/internal/domain/enum"
)

func TestStoryContentEngineFields(t *testing.T) {
	lastAutosavedAt := time.Now().UTC()
	archivedAt := lastAutosavedAt.Add(time.Hour)

	story := Story{
		ID:                   uuid.New(),
		Format:               enum.StoryFormatGuide,
		ContentSchemaVersion: 1,
		ContentBlocks:        json.RawMessage(`[{"id":"block-1","type":"paragraph","text":"Hello"}]`),
		ContentPlainText:     "Hello",
		Revision:             7,
		LastAutosavedAt:      &lastAutosavedAt,
		ArchivedAt:           &archivedAt,
		ModerationStatus:     enum.ModerationStatusPending,
	}

	if story.Format != enum.StoryFormatGuide {
		t.Fatalf("Format = %q, want %q", story.Format, enum.StoryFormatGuide)
	}
	if story.ContentSchemaVersion != 1 {
		t.Fatalf("ContentSchemaVersion = %d, want 1", story.ContentSchemaVersion)
	}
	if !json.Valid(story.ContentBlocks) {
		t.Fatalf("ContentBlocks must hold valid JSON")
	}
	if story.ContentPlainText != "Hello" {
		t.Fatalf("ContentPlainText = %q, want Hello", story.ContentPlainText)
	}
	if story.Revision != 7 {
		t.Fatalf("Revision = %d, want 7", story.Revision)
	}
	if story.LastAutosavedAt == nil || !story.LastAutosavedAt.Equal(lastAutosavedAt) {
		t.Fatalf("LastAutosavedAt = %v, want %v", story.LastAutosavedAt, lastAutosavedAt)
	}
	if story.ArchivedAt == nil || !story.ArchivedAt.Equal(archivedAt) {
		t.Fatalf("ArchivedAt = %v, want %v", story.ArchivedAt, archivedAt)
	}
	if story.ModerationStatus != enum.ModerationStatusPending {
		t.Fatalf("ModerationStatus = %q, want %q", story.ModerationStatus, enum.ModerationStatusPending)
	}
}

func TestStoryIsPubliclyVisible(t *testing.T) {
	now := time.Now().UTC()

	tests := map[string]struct {
		story *Story
		want  bool
	}{
		"nil story": {
			story: nil,
			want:  false,
		},
		"published not required moderation": {
			story: &Story{
				Status:           enum.StoryStatusPublished,
				ModerationStatus: enum.ModerationStatusNotRequired,
			},
			want: true,
		},
		"published approved": {
			story: &Story{
				Status:           enum.StoryStatusPublished,
				ModerationStatus: enum.ModerationStatusApproved,
			},
			want: true,
		},
		"draft": {
			story: &Story{
				Status:           enum.StoryStatusDraft,
				ModerationStatus: enum.ModerationStatusApproved,
			},
			want: false,
		},
		"deleted": {
			story: &Story{
				Status:           enum.StoryStatusPublished,
				ModerationStatus: enum.ModerationStatusApproved,
				DeletedAt:        &now,
			},
			want: false,
		},
		"archived": {
			story: &Story{
				Status:           enum.StoryStatusPublished,
				ModerationStatus: enum.ModerationStatusApproved,
				ArchivedAt:       &now,
			},
			want: false,
		},
		"pending moderation": {
			story: &Story{
				Status:           enum.StoryStatusPublished,
				ModerationStatus: enum.ModerationStatusPending,
			},
			want: false,
		},
		"rejected moderation": {
			story: &Story{
				Status:           enum.StoryStatusPublished,
				ModerationStatus: enum.ModerationStatusRejected,
			},
			want: false,
		},
		"hidden moderation": {
			story: &Story{
				Status:           enum.StoryStatusPublished,
				ModerationStatus: enum.ModerationStatusHidden,
			},
			want: false,
		},
	}

	for name, tt := range tests {
		t.Run(name, func(t *testing.T) {
			if got := tt.story.IsPubliclyVisible(); got != tt.want {
				t.Fatalf("IsPubliclyVisible() = %v, want %v", got, tt.want)
			}
		})
	}
}

func TestStoryIsPublishedRemainsRawPublishedStatus(t *testing.T) {
	now := time.Now().UTC()
	story := &Story{
		Status:           enum.StoryStatusPublished,
		ModerationStatus: enum.ModerationStatusHidden,
		ArchivedAt:       &now,
	}

	if !story.IsPublished() {
		t.Fatal("IsPublished() should remain true for raw published, non-deleted stories")
	}
	if story.IsPubliclyVisible() {
		t.Fatal("IsPubliclyVisible() should reject archived or hidden stories")
	}
}
