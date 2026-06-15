package app

import (
	"context"
	"encoding/binary"
	"fmt"
	"image"
	_ "image/jpeg"
	_ "image/png"
	"io"

	"github.com/google/uuid"

	"kz/inflap/backend/services/file-manager-service/internal/domain/model"
)

type uploadMediaMetadata struct {
	Width           *int
	Height          *int
	DurationMS      *int
	ThumbnailFileID *uuid.UUID
}

func (u *FileUseCase) readUploadMediaMetadata(
	ctx context.Context,
	file *model.File,
	contentType string,
) (uploadMediaMetadata, error) {
	contentType = normalizeContentType(contentType)
	if !isImageMetadataContentType(contentType) {
		return uploadMediaMetadata{}, nil
	}

	body, _, err := u.storage.GetObject(ctx, file.Bucket, file.ObjectKey)
	if err != nil {
		return uploadMediaMetadata{}, fmt.Errorf("get object for media metadata: %w", err)
	}
	defer body.Close()

	width, height, err := decodeImageDimensions(body, contentType)
	if err != nil {
		return uploadMediaMetadata{}, err
	}

	return uploadMediaMetadata{
		Width:  intPtr(width),
		Height: intPtr(height),
	}, nil
}

func decodeImageDimensions(reader io.Reader, contentType string) (int, int, error) {
	switch normalizeContentType(contentType) {
	case "image/webp":
		return decodeWebPDimensions(reader)
	default:
		cfg, _, err := image.DecodeConfig(reader)
		if err != nil {
			return 0, 0, fmt.Errorf("decode image metadata: %w", err)
		}
		if cfg.Width <= 0 || cfg.Height <= 0 {
			return 0, 0, model.ErrInvalidMediaMetadata
		}
		return cfg.Width, cfg.Height, nil
	}
}

func decodeWebPDimensions(reader io.Reader) (int, int, error) {
	header, err := io.ReadAll(io.LimitReader(reader, 64))
	if err != nil {
		return 0, 0, fmt.Errorf("read webp metadata: %w", err)
	}
	if len(header) < 30 || string(header[0:4]) != "RIFF" || string(header[8:12]) != "WEBP" {
		return 0, 0, fmt.Errorf("decode webp metadata: %w", model.ErrInvalidMediaMetadata)
	}

	var width int
	var height int
	switch string(header[12:16]) {
	case "VP8X":
		width = 1 + int(uint32(header[24])|uint32(header[25])<<8|uint32(header[26])<<16)
		height = 1 + int(uint32(header[27])|uint32(header[28])<<8|uint32(header[29])<<16)
	case "VP8L":
		if header[20] != 0x2f {
			return 0, 0, fmt.Errorf("decode webp metadata: %w", model.ErrInvalidMediaMetadata)
		}
		b0 := header[21]
		b1 := header[22]
		b2 := header[23]
		b3 := header[24]
		width = 1 + int(uint16(b0)|uint16(b1&0x3f)<<8)
		height = 1 + int(uint32(b1&0xc0)>>6|uint32(b2)<<2|uint32(b3&0x0f)<<10)
	case "VP8 ":
		if string(header[23:26]) != string([]byte{0x9d, 0x01, 0x2a}) {
			return 0, 0, fmt.Errorf("decode webp metadata: %w", model.ErrInvalidMediaMetadata)
		}
		width = int(binary.LittleEndian.Uint16(header[26:28]) & 0x3fff)
		height = int(binary.LittleEndian.Uint16(header[28:30]) & 0x3fff)
	default:
		return 0, 0, fmt.Errorf("decode webp metadata: %w", model.ErrInvalidMediaMetadata)
	}

	if width <= 0 || height <= 0 {
		return 0, 0, model.ErrInvalidMediaMetadata
	}
	return width, height, nil
}

func isImageMetadataContentType(contentType string) bool {
	switch normalizeContentType(contentType) {
	case "image/jpeg", "image/png", "image/webp":
		return true
	default:
		return false
	}
}

func intPtr(v int) *int {
	return &v
}
