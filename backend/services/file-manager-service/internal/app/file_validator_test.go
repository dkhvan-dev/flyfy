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
