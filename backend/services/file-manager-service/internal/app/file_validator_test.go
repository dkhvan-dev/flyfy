package app

import (
	"testing"

	"github.com/dkhvan-dev/flyfy/backend/services/file-manager-service/internal/domain/enum"
)

func TestChatStickerAllowsAnimatedGif(t *testing.T) {
	validator := NewFileValidator(DefaultUploadPolicies(0))

	if err := validator.ValidateForCreate(
		"flyfy-sticker.gif",
		"image/gif",
		128*1024,
		enum.FilePurposeChatSticker,
	); err != nil {
		t.Fatalf("expected animated gif sticker to be allowed, got %v", err)
	}
}
