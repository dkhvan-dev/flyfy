package app

import (
	"path/filepath"
	"strings"

	"kz/inflap/backend/services/file-manager-service/internal/domain/enum"
)

type FileValidator struct {
	policies UploadPolicies
}

func NewFileValidator(policies UploadPolicies) *FileValidator {
	return &FileValidator{
		policies: policies,
	}
}

func (v *FileValidator) ValidateForCreate(
	originalName string,
	contentType string,
	sizeBytes int64,
	purpose enum.FilePurpose,
) error {
	originalName = strings.TrimSpace(originalName)
	if originalName == "" {
		return ErrFilenameRequired
	}

	contentType = normalizeContentType(contentType)
	if contentType == "" {
		return ErrContentTypeRequired
	}

	if sizeBytes <= 0 {
		return ErrInvalidFileSize
	}

	policy, ok := v.policies[purpose]
	if !ok {
		return ErrForbiddenPurpose
	}

	if policy.MaxSizeBytes > 0 && sizeBytes > policy.MaxSizeBytes {
		return ErrUploadTooLarge
	}

	ext := normalizeExtension(originalName)
	if ext == "" {
		return ErrExtensionNotAllowed
	}

	if _, ok = policy.AllowedExtensions[ext]; !ok {
		return ErrExtensionNotAllowed
	}

	if _, ok = policy.AllowedContentTypes[contentType]; !ok {
		return ErrContentTypeNotAllowed
	}

	return nil
}

func (v *FileValidator) ValidateUploadedObject(
	originalName string,
	detectedContentType string,
	sizeBytes int64,
	purpose enum.FilePurpose,
) error {
	detectedContentType = normalizeContentType(detectedContentType)
	if detectedContentType == "" {
		return ErrContentTypeNotAllowed
	}
	if sizeBytes <= 0 {
		return ErrInvalidFileSize
	}

	policy, ok := v.policies[purpose]
	if !ok {
		return ErrForbiddenPurpose
	}

	if policy.MaxSizeBytes > 0 && sizeBytes > policy.MaxSizeBytes {
		return ErrUploadTooLarge
	}

	ext := normalizeExtension(originalName)
	if ext == "" {
		return ErrExtensionNotAllowed
	}

	if _, ok = policy.AllowedExtensions[ext]; !ok {
		return ErrExtensionNotAllowed
	}

	if _, ok = policy.AllowedContentTypes[detectedContentType]; !ok {
		return ErrContentTypeNotAllowed
	}

	return nil
}

func normalizeExtension(filename string) string {
	ext := strings.ToLower(strings.TrimSpace(filepath.Ext(filename)))
	return strings.TrimPrefix(ext, ".")
}

func normalizeContentType(v string) string {
	v = strings.ToLower(strings.TrimSpace(v))
	if idx := strings.Index(v, ";"); idx >= 0 {
		v = strings.TrimSpace(v[:idx])
	}
	return v
}
