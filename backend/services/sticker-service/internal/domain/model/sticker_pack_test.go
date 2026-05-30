package model

import (
	"testing"

	"github.com/google/uuid"

	"kz/inflap/backend/services/sticker-service/internal/domain/enum"
)

func TestNewStickerPackRejectsUserCustomPackWithoutOwner(t *testing.T) {
	pack, err := NewStickerPack(NewStickerPackParams{
		Slug:       "my-custom",
		Type:       enum.PackTypeUserCustom,
		Visibility: enum.PackVisibilityPrivate,
		Status:     enum.PackStatusActive,
		Title:      map[string]string{"en": "My stickers"},
	})

	if err == nil {
		t.Fatalf("expected error, got pack=%+v", pack)
	}
}

func TestNewStickerPackAcceptsActiveSystemPack(t *testing.T) {
	pack, err := NewStickerPack(NewStickerPackParams{
		Slug:       "inflap-default",
		Type:       enum.PackTypeSystem,
		Visibility: enum.PackVisibilityPublic,
		Status:     enum.PackStatusActive,
		Title:      map[string]string{"en": "Inflap"},
	})

	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}
	if pack.ID == uuid.Nil {
		t.Fatal("expected generated id")
	}
	if pack.OwnerUserID != nil {
		t.Fatalf("expected no owner for system pack, got %v", pack.OwnerUserID)
	}
}
