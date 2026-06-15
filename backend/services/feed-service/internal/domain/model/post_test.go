package model

import (
	"encoding/json"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/feed-service/internal/domain/enum"
)

func TestPostContentEngineFields(t *testing.T) {
	lastAutosavedAt := time.Now().UTC()
	archivedAt := lastAutosavedAt.Add(time.Hour)

	post := Post{
		ID:                   uuid.New(),
		Format:               enum.PostFormatGuide,
		ContentSchemaVersion: 1,
		ContentBlocks:        json.RawMessage(`[{"id":"block-1","type":"paragraph","text":"Hello"}]`),
		ContentPlainText:     "Hello",
		Revision:             7,
		LastAutosavedAt:      &lastAutosavedAt,
		ArchivedAt:           &archivedAt,
		ModerationStatus:     enum.ModerationStatusPending,
	}

	if post.Format != enum.PostFormatGuide {
		t.Fatalf("Format = %q, want %q", post.Format, enum.PostFormatGuide)
	}
	if post.ContentSchemaVersion != 1 {
		t.Fatalf("ContentSchemaVersion = %d, want 1", post.ContentSchemaVersion)
	}
	if !json.Valid(post.ContentBlocks) {
		t.Fatalf("ContentBlocks must hold valid JSON")
	}
	if post.ContentPlainText != "Hello" {
		t.Fatalf("ContentPlainText = %q, want Hello", post.ContentPlainText)
	}
	if post.Revision != 7 {
		t.Fatalf("Revision = %d, want 7", post.Revision)
	}
	if post.LastAutosavedAt == nil || !post.LastAutosavedAt.Equal(lastAutosavedAt) {
		t.Fatalf("LastAutosavedAt = %v, want %v", post.LastAutosavedAt, lastAutosavedAt)
	}
	if post.ArchivedAt == nil || !post.ArchivedAt.Equal(archivedAt) {
		t.Fatalf("ArchivedAt = %v, want %v", post.ArchivedAt, archivedAt)
	}
	if post.ModerationStatus != enum.ModerationStatusPending {
		t.Fatalf("ModerationStatus = %q, want %q", post.ModerationStatus, enum.ModerationStatusPending)
	}
}

func TestPostIsPubliclyVisible(t *testing.T) {
	now := time.Now().UTC()

	tests := map[string]struct {
		post *Post
		want bool
	}{
		"nil post": {
			post: nil,
			want: false,
		},
		"published not required moderation": {
			post: &Post{
				Status:           enum.PostStatusPublished,
				ModerationStatus: enum.ModerationStatusNotRequired,
			},
			want: true,
		},
		"published approved": {
			post: &Post{
				Status:           enum.PostStatusPublished,
				ModerationStatus: enum.ModerationStatusApproved,
			},
			want: true,
		},
		"draft": {
			post: &Post{
				Status:           enum.PostStatusDraft,
				ModerationStatus: enum.ModerationStatusApproved,
			},
			want: false,
		},
		"deleted": {
			post: &Post{
				Status:           enum.PostStatusPublished,
				ModerationStatus: enum.ModerationStatusApproved,
				DeletedAt:        &now,
			},
			want: false,
		},
		"archived": {
			post: &Post{
				Status:           enum.PostStatusPublished,
				ModerationStatus: enum.ModerationStatusApproved,
				ArchivedAt:       &now,
			},
			want: false,
		},
		"pending moderation": {
			post: &Post{
				Status:           enum.PostStatusPublished,
				ModerationStatus: enum.ModerationStatusPending,
			},
			want: false,
		},
		"rejected moderation": {
			post: &Post{
				Status:           enum.PostStatusPublished,
				ModerationStatus: enum.ModerationStatusRejected,
			},
			want: false,
		},
		"hidden moderation": {
			post: &Post{
				Status:           enum.PostStatusPublished,
				ModerationStatus: enum.ModerationStatusHidden,
			},
			want: false,
		},
	}

	for name, tt := range tests {
		t.Run(name, func(t *testing.T) {
			if got := tt.post.IsPubliclyVisible(); got != tt.want {
				t.Fatalf("IsPubliclyVisible() = %v, want %v", got, tt.want)
			}
		})
	}
}

func TestPostIsPublishedRemainsRawPublishedStatus(t *testing.T) {
	now := time.Now().UTC()
	post := &Post{
		Status:           enum.PostStatusPublished,
		ModerationStatus: enum.ModerationStatusHidden,
		ArchivedAt:       &now,
	}

	if !post.IsPublished() {
		t.Fatal("IsPublished() should remain true for raw published, non-deleted posts")
	}
	if post.IsPubliclyVisible() {
		t.Fatal("IsPubliclyVisible() should reject archived or hidden posts")
	}
}
