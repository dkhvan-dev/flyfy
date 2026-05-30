package model

import (
	"errors"
	"fmt"
	"path/filepath"
	"strings"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/file-manager-service/internal/domain/enum"
)

var (
	ErrInvalidFileID         = errors.New("invalid file id")
	ErrInvalidProvider       = errors.New("invalid provider")
	ErrInvalidBucket         = errors.New("invalid bucket")
	ErrInvalidObjectKey      = errors.New("invalid object key")
	ErrInvalidOriginalName   = errors.New("invalid original name")
	ErrInvalidStoredName     = errors.New("invalid stored name")
	ErrInvalidContentType    = errors.New("invalid content type")
	ErrInvalidSizeBytes      = errors.New("invalid size bytes")
	ErrInvalidVisibility     = errors.New("invalid visibility")
	ErrInvalidPurpose        = errors.New("invalid purpose")
	ErrInvalidStatus         = errors.New("invalid status")
	ErrInvalidOwnerType      = errors.New("invalid owner type")
	ErrOwnerIDWithoutType    = errors.New("owner id provided without owner type")
	ErrOwnerTypeWithoutID    = errors.New("owner type provided without owner id")
	ErrDeletedFileMutation   = errors.New("cannot mutate deleted file")
	ErrEmptyUploadedByUserID = errors.New("uploaded_by_user_id cannot be empty uuid")
	ErrInvalidPolicyStatus   = errors.New("invalid policy status")
)

type FilePolicyStatus string

const (
	FilePolicyAllowed     FilePolicyStatus = "ALLOWED"
	FilePolicyQuarantined FilePolicyStatus = "QUARANTINED"
	FilePolicyDenied      FilePolicyStatus = "DENIED"
	FilePolicyPending     FilePolicyStatus = "PENDING"
)

func (s FilePolicyStatus) IsValid() bool {
	switch s {
	case FilePolicyAllowed, FilePolicyQuarantined, FilePolicyDenied, FilePolicyPending:
		return true
	default:
		return false
	}
}

type File struct {
	ID                  uuid.UUID
	Provider            string
	Bucket              string
	ObjectKey           string
	OriginalName        string
	StoredName          string
	Extension           *string
	ContentType         string
	DetectedContentType *string
	SizeBytes           int64
	ChecksumSHA256      *string
	Visibility          enum.FileVisibility
	Purpose             enum.FilePurpose
	Status              enum.FileStatus
	OwnerType           *enum.OwnerType
	OwnerID             *uuid.UUID
	UploadedByUserID    *uuid.UUID
	UploadExpiresAt     *time.Time
	PolicyStatus        FilePolicyStatus
	PolicyReasonCode    string
	PolicyDecisionID    string
	IsDeleted           bool
	DeletedAt           *time.Time
	CreatedAt           time.Time
	UpdatedAt           time.Time
}

type NewFileParams struct {
	Provider         string
	Bucket           string
	ObjectKey        string
	OriginalName     string
	ContentType      string
	SizeBytes        int64
	Visibility       enum.FileVisibility
	Purpose          enum.FilePurpose
	OwnerType        *enum.OwnerType
	OwnerID          *uuid.UUID
	UploadedByUserID *uuid.UUID
	UploadExpiresAt  *time.Time
}

func NewFile(params NewFileParams) (*File, error) {
	now := time.Now().UTC()

	originalName := strings.TrimSpace(params.OriginalName)
	ext := normalizedExtension(originalName)
	storedName := buildStoredName(ext)

	file := &File{
		ID:               uuid.New(),
		Provider:         strings.TrimSpace(params.Provider),
		Bucket:           strings.TrimSpace(params.Bucket),
		ObjectKey:        strings.TrimSpace(params.ObjectKey),
		OriginalName:     originalName,
		StoredName:       storedName,
		Extension:        nilIfEmpty(ext),
		ContentType:      strings.TrimSpace(params.ContentType),
		SizeBytes:        params.SizeBytes,
		Visibility:       params.Visibility,
		Purpose:          params.Purpose,
		Status:           enum.FileStatusPendingUpload,
		OwnerType:        params.OwnerType,
		OwnerID:          params.OwnerID,
		UploadedByUserID: params.UploadedByUserID,
		UploadExpiresAt:  params.UploadExpiresAt,
		PolicyStatus:     FilePolicyAllowed,
		IsDeleted:        false,
		CreatedAt:        now,
		UpdatedAt:        now,
	}

	if err := file.Validate(); err != nil {
		return nil, err
	}

	return file, nil
}

func (f *File) Validate() error {
	if f.ID == uuid.Nil {
		return ErrInvalidFileID
	}
	if strings.TrimSpace(f.Provider) == "" {
		return ErrInvalidProvider
	}
	if strings.TrimSpace(f.Bucket) == "" {
		return ErrInvalidBucket
	}
	if strings.TrimSpace(f.ObjectKey) == "" {
		return ErrInvalidObjectKey
	}
	if strings.TrimSpace(f.OriginalName) == "" {
		return ErrInvalidOriginalName
	}
	if strings.TrimSpace(f.StoredName) == "" {
		return ErrInvalidStoredName
	}
	if strings.TrimSpace(f.ContentType) == "" {
		return ErrInvalidContentType
	}
	if f.SizeBytes < 0 {
		return ErrInvalidSizeBytes
	}
	if !f.Visibility.IsValid() {
		return ErrInvalidVisibility
	}
	if !f.Purpose.IsValid() {
		return ErrInvalidPurpose
	}
	if !f.Status.IsValid() {
		return ErrInvalidStatus
	}

	if f.OwnerType != nil && !f.OwnerType.IsValid() {
		return ErrInvalidOwnerType
	}
	if f.OwnerType == nil && f.OwnerID != nil {
		return ErrOwnerIDWithoutType
	}
	if f.OwnerType != nil && f.OwnerID == nil {
		return ErrOwnerTypeWithoutID
	}
	if f.UploadedByUserID != nil && *f.UploadedByUserID == uuid.Nil {
		return ErrEmptyUploadedByUserID
	}
	if f.PolicyStatus == "" {
		f.PolicyStatus = FilePolicyAllowed
	}
	if !f.PolicyStatus.IsValid() {
		return ErrInvalidPolicyStatus
	}

	return nil
}

func (f *File) ApplyPolicyDecision(status FilePolicyStatus, reasonCode string, decisionID string) error {
	if f.IsDeleted {
		return ErrDeletedFileMutation
	}
	if status == "" {
		status = FilePolicyAllowed
	}
	if !status.IsValid() {
		return ErrInvalidPolicyStatus
	}
	f.PolicyStatus = status
	f.PolicyReasonCode = strings.TrimSpace(reasonCode)
	f.PolicyDecisionID = strings.TrimSpace(decisionID)
	f.UpdatedAt = time.Now().UTC()
	return nil
}

func (f *File) MarkUploaded(detectedContentType string, sizeBytes int64, checksumSHA256 *string) error {
	if f.IsDeleted {
		return ErrDeletedFileMutation
	}
	if sizeBytes < 0 {
		return ErrInvalidSizeBytes
	}

	detectedContentType = strings.TrimSpace(detectedContentType)
	if detectedContentType == "" {
		return ErrInvalidContentType
	}

	f.Status = enum.FileStatusUploaded
	f.DetectedContentType = &detectedContentType
	f.SizeBytes = sizeBytes
	f.ChecksumSHA256 = checksumSHA256
	f.UpdatedAt = time.Now().UTC()

	return nil
}

func (f *File) MarkReady() error {
	if f.IsDeleted {
		return ErrDeletedFileMutation
	}
	if f.Status != enum.FileStatusUploaded {
		return fmt.Errorf("cannot mark file ready from status %s", f.Status)
	}

	f.Status = enum.FileStatusReady
	f.UpdatedAt = time.Now().UTC()
	return nil
}

func (f *File) MarkFailed() error {
	if f.IsDeleted {
		return ErrDeletedFileMutation
	}

	f.Status = enum.FileStatusFailed
	f.UpdatedAt = time.Now().UTC()
	return nil
}

func (f *File) SoftDelete() error {
	if f.IsDeleted {
		return nil
	}

	now := time.Now().UTC()
	f.IsDeleted = true
	f.Status = enum.FileStatusDeleted
	f.DeletedAt = &now
	f.UpdatedAt = now

	return nil
}

func normalizedExtension(originalName string) string {
	ext := strings.ToLower(strings.TrimSpace(filepath.Ext(originalName)))
	ext = strings.TrimPrefix(ext, ".")
	return ext
}

func buildStoredName(ext string) string {
	id := uuid.NewString()
	if ext == "" {
		return id
	}
	return id + "." + ext
}

func nilIfEmpty(s string) *string {
	if strings.TrimSpace(s) == "" {
		return nil
	}
	v := s
	return &v
}
