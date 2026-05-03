package app

import (
	"strings"

	"github.com/dkhvan-dev/flyfy/backend/services/file-manager-service/internal/domain/enum"
)

type UploadPolicy struct {
	MaxSizeBytes        int64
	AllowedExtensions   map[string]struct{}
	AllowedContentTypes map[string]struct{}
}

type UploadPolicies map[enum.FilePurpose]UploadPolicy

func DefaultUploadPolicies(globalMaxSize int64) UploadPolicies {
	return UploadPolicies{
		enum.FilePurposeAvatar: {
			MaxSizeBytes: 5 * 1024 * 1024,
			AllowedExtensions: setOf(
				"jpg", "jpeg", "png", "webp",
			),
			AllowedContentTypes: setOf(
				"image/jpeg", "image/png", "image/webp",
			),
		},
		enum.FilePurposeGuideVerificationDoc: {
			MaxSizeBytes: 15 * 1024 * 1024,
			AllowedExtensions: setOf(
				"jpg", "jpeg", "png", "pdf", "webp",
			),
			AllowedContentTypes: setOf(
				"image/jpeg", "image/png", "image/webp", "application/pdf",
			),
		},
		enum.FilePurposeActivityMedia: {
			MaxSizeBytes: 20 * 1024 * 1024,
			AllowedExtensions: setOf(
				"jpg", "jpeg", "png", "webp",
			),
			AllowedContentTypes: setOf(
				"image/jpeg", "image/png", "image/webp",
			),
		},
		enum.FilePurposeTourMedia: {
			MaxSizeBytes: 20 * 1024 * 1024,
			AllowedExtensions: setOf(
				"jpg", "jpeg", "png", "webp",
			),
			AllowedContentTypes: setOf(
				"image/jpeg", "image/png", "image/webp",
			),
		},
		enum.FilePurposeAttractionReviewMedia: {
			MaxSizeBytes: 50 * 1024 * 1024,
			AllowedExtensions: setOf(
				"jpg", "jpeg", "png", "webp",
				"mp4", "mov", "webm", "m4v",
			),
			AllowedContentTypes: setOf(
				"image/jpeg", "image/png", "image/webp",
				"video/mp4", "video/quicktime", "video/webm", "video/x-m4v",
			),
		},
		enum.FilePurposeChatAttachment: {
			MaxSizeBytes: 25 * 1024 * 1024,
			AllowedExtensions: setOf(
				"jpg", "jpeg", "png", "webp", "heic", "heif",
				"mp4", "mov", "webm", "m4v",
				"m4a", "aac", "mp3", "wav", "ogg", "opus",
				"pdf", "zip", "txt", "csv",
				"xls", "xlsx", "doc", "docx",
			),
			AllowedContentTypes: setOf(
				"image/jpeg", "image/png", "image/webp", "image/heic", "image/heif",
				"video/mp4", "video/quicktime", "video/webm", "video/x-m4v",
				"audio/mp4", "audio/m4a", "audio/aac", "audio/mpeg", "audio/wav",
				"audio/wave", "audio/x-wav", "audio/ogg", "audio/opus",
				"application/pdf", "application/zip", "application/x-zip-compressed",
				"text/plain", "text/csv", "application/csv",
				"application/vnd.ms-excel",
				"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
				"application/msword",
				"application/vnd.openxmlformats-officedocument.wordprocessingml.document",
			),
		},
		enum.FilePurposeGenericDocument: {
			MaxSizeBytes: minNonZero(globalMaxSize, 25*1024*1024),
			AllowedExtensions: setOf(
				"jpg", "jpeg", "png", "webp", "pdf",
			),
			AllowedContentTypes: setOf(
				"image/jpeg", "image/png", "image/webp", "application/pdf",
			),
		},
	}
}

func setOf(values ...string) map[string]struct{} {
	res := make(map[string]struct{}, len(values))
	for _, v := range values {
		res[strings.ToLower(strings.TrimSpace(v))] = struct{}{}
	}
	return res
}

func minNonZero(a, b int64) int64 {
	switch {
	case a <= 0:
		return b
	case b <= 0:
		return a
	case a < b:
		return a
	default:
		return b
	}
}
