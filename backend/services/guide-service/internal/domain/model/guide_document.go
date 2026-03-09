package model

import (
	"errors"
	"strings"
	"time"

	"github.com/google/uuid"
)

var (
	ErrInvalidGuideDocumentID                    = errors.New("invalid guide document id")
	ErrInvalidGuideDocumentVerificationRequestID = errors.New("invalid guide document verification request id")
	ErrInvalidGuideDocumentFileID                = errors.New("invalid guide document file id")
	ErrInvalidGuideDocumentType                  = errors.New("invalid guide document type")
)

type GuideDocument struct {
	ID                    uuid.UUID
	VerificationRequestID uuid.UUID
	FileID                uuid.UUID
	DocumentType          string
	CreatedAt             time.Time
}

type NewGuideDocumentParams struct {
	VerificationRequestID uuid.UUID
	FileID                uuid.UUID
	DocumentType          string
}

func NewGuideDocument(params NewGuideDocumentParams) (*GuideDocument, error) {
	doc := &GuideDocument{
		ID:                    uuid.New(),
		VerificationRequestID: params.VerificationRequestID,
		FileID:                params.FileID,
		DocumentType:          strings.TrimSpace(params.DocumentType),
		CreatedAt:             time.Now().UTC(),
	}

	if err := doc.Validate(); err != nil {
		return nil, err
	}

	return doc, nil
}

func (d *GuideDocument) Validate() error {
	if d.ID == uuid.Nil {
		return ErrInvalidGuideDocumentID
	}
	if d.VerificationRequestID == uuid.Nil {
		return ErrInvalidGuideDocumentVerificationRequestID
	}
	if d.FileID == uuid.Nil {
		return ErrInvalidGuideDocumentFileID
	}
	if strings.TrimSpace(d.DocumentType) == "" {
		return ErrInvalidGuideDocumentType
	}
	return nil
}
