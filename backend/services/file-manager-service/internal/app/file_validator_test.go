package app

import (
	"testing"

	"kz/inflap/backend/services/file-manager-service/internal/domain/enum"
)

func TestChatStickerAllowsAnimatedGif(t *testing.T) {
	validator := NewFileValidator(DefaultUploadPolicies(0))

	if err := validator.ValidateForCreate(
		"inflap-sticker.gif",
		"image/gif",
		128*1024,
		enum.FilePurposeChatSticker,
	); err != nil {
		t.Fatalf("expected animated gif sticker to be allowed, got %v", err)
	}
}

func TestChatStickerAllowsTelegramTGS(t *testing.T) {
	validator := NewFileValidator(DefaultUploadPolicies(0))

	if err := validator.ValidateForCreate(
		"inflap-sticker.tgs",
		"application/x-tgsticker",
		48*1024,
		enum.FilePurposeChatSticker,
	); err != nil {
		t.Fatalf("expected telegram tgs sticker to be allowed, got %v", err)
	}

	if err := validator.ValidateUploadedObject(
		"inflap-sticker.tgs",
		"application/x-tgsticker; charset=binary",
		48*1024,
		enum.FilePurposeChatSticker,
	); err != nil {
		t.Fatalf("expected uploaded telegram tgs sticker to be allowed, got %v", err)
	}
}

func TestChatStickerRejectsOversizedTelegramTGS(t *testing.T) {
	validator := NewFileValidator(DefaultUploadPolicies(0))

	if err := validator.ValidateForCreate(
		"inflap-sticker.tgs",
		"application/x-tgsticker",
		maxTelegramTGSBytes+1,
		enum.FilePurposeChatSticker,
	); err != ErrUploadTooLarge {
		t.Fatalf("expected oversized telegram tgs to be rejected, got %v", err)
	}
}

func TestStoryMediaAllowsPublicImages(t *testing.T) {
	validator := NewFileValidator(DefaultUploadPolicies(0))

	if err := validator.ValidateForCreate(
		"weekend-cover.webp",
		"image/webp",
		2*1024*1024,
		enum.FilePurposeStoryMedia,
	); err != nil {
		t.Fatalf("expected story image media to be allowed, got %v", err)
	}

	if err := validator.ValidateUploadedObject(
		"weekend-cover.webp",
		"image/webp; charset=binary",
		2*1024*1024,
		enum.FilePurposeStoryMedia,
	); err != nil {
		t.Fatalf("expected uploaded story image media to be allowed, got %v", err)
	}
}

func TestStoryMediaRejectsVideoUploads(t *testing.T) {
	validator := NewFileValidator(DefaultUploadPolicies(0))

	if err := validator.ValidateForCreate(
		"weekend-reel.mp4",
		"video/mp4",
		2*1024*1024,
		enum.FilePurposeStoryMedia,
	); err != ErrExtensionNotAllowed {
		t.Fatalf("expected story video media to be rejected by extension, got %v", err)
	}
}
