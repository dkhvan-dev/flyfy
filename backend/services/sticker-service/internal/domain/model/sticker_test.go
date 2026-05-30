package model

import (
	"testing"

	"github.com/google/uuid"

	"kz/inflap/backend/services/sticker-service/internal/domain/enum"
)

func TestNewStickerUsesEmptyKeywordsWhenOmitted(t *testing.T) {
	sticker, err := NewSticker(NewStickerParams{
		PackID: uuid.New(),
		FileID: uuid.New(),
		Status: enum.StickerStatusActive,
	})
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}
	if sticker.Keywords == nil {
		t.Fatal("expected empty keywords slice, got nil")
	}
	if len(sticker.Keywords) != 0 {
		t.Fatalf("expected no keywords, got %v", sticker.Keywords)
	}
}

func TestCanSendStickerAllowsActiveStickerFromActivePublicSystemPack(t *testing.T) {
	packID := uuid.New()
	pack := StickerPack{
		ID:         packID,
		Type:       enum.PackTypeSystem,
		Visibility: enum.PackVisibilityPublic,
		Status:     enum.PackStatusActive,
	}
	sticker := Sticker{
		ID:     uuid.New(),
		PackID: packID,
		FileID: uuid.New(),
		Status: enum.StickerStatusActive,
	}

	if !CanSendSticker(pack, sticker) {
		t.Fatal("expected active sticker from active public system pack to be sendable")
	}
}

func TestCanSendStickerRejectsDeletedSticker(t *testing.T) {
	packID := uuid.New()
	pack := StickerPack{
		ID:         packID,
		Type:       enum.PackTypeSystem,
		Visibility: enum.PackVisibilityPublic,
		Status:     enum.PackStatusActive,
	}
	sticker := Sticker{
		ID:     uuid.New(),
		PackID: packID,
		FileID: uuid.New(),
		Status: enum.StickerStatusDeleted,
	}

	if CanSendSticker(pack, sticker) {
		t.Fatal("expected deleted sticker to be rejected")
	}
}

func TestStickerAssetMetadataRequiresFallback(t *testing.T) {
	asset := StickerAssetMetadata{
		AnimationFileID: uuid.New(),
		ContentType:     "application/json",
		Width:           512,
		Height:          512,
		DurationMS:      3000,
		SizeBytes:       64000,
	}

	if err := asset.Validate(); err == nil {
		t.Fatal("expected missing fallback file id to fail validation")
	}
}
