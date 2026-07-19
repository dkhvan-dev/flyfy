package app

import (
	"context"
	"errors"
	"net/url"
	"strings"
	"unicode"

	"github.com/google/uuid"
)

var (
	ErrFileManagerFileNotFound       = errors.New("file manager file not found")
	ErrFileManagerRequestRejected    = errors.New("file manager request rejected")
	ErrFileManagerDownloadURLInvalid = errors.New("file manager download URL is invalid")
)

type FileManagerClient interface {
	ValidateGuideDocumentFile(ctx context.Context, fileID uuid.UUID) error
	CreateGuideDocumentDownloadURL(ctx context.Context, fileID uuid.UUID) (string, error)
	BindGuideDocumentToVerificationRequest(
		ctx context.Context,
		fileID uuid.UUID,
		verificationRequestID uuid.UUID,
		createdByUserID *uuid.UUID,
	) error
}

// DownloadURLFileManager is the purpose-neutral contract used only after an
// owning use case has authorized access to the referenced file.
type DownloadURLFileManager interface {
	CreateDownloadURL(ctx context.Context, fileID uuid.UUID) (string, error)
}

func ValidateFileManagerDownloadURL(value string) (string, error) {
	if value == "" || value != strings.TrimSpace(value) ||
		strings.ContainsFunc(value, unicode.IsControl) {
		return "", ErrFileManagerDownloadURLInvalid
	}

	parsed, err := url.ParseRequestURI(value)
	if err != nil || parsed == nil || parsed.Opaque != "" || parsed.User != nil ||
		parsed.Host == "" || parsed.Hostname() == "" ||
		(parsed.Scheme != "http" && parsed.Scheme != "https") {
		return "", ErrFileManagerDownloadURLInvalid
	}
	decoded, err := url.PathUnescape(value)
	if err != nil || strings.ContainsFunc(decoded, unicode.IsControl) {
		return "", ErrFileManagerDownloadURLInvalid
	}

	return value, nil
}
