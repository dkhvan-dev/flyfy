package model

import (
	"errors"
	"time"

	"github.com/google/uuid"
)

var (
	ErrInvalidActivityMediaID   = errors.New("invalid activity media id")
	ErrInvalidActivityMediaType = errors.New("invalid activity media type")
	ErrInvalidActivityMediaFile = errors.New("invalid activity media file")
)

type ActivityMediaType string

const (
	ActivityMediaTypeImage ActivityMediaType = "IMAGE"
	ActivityMediaTypeVideo ActivityMediaType = "VIDEO"
)

func (v ActivityMediaType) IsValid() bool {
	switch v {
	case ActivityMediaTypeImage, ActivityMediaTypeVideo:
		return true
	default:
		return false
	}
}

type ActivityMedia struct {
	ID         uuid.UUID
	ActivityID uuid.UUID
	FileID     uuid.UUID
	MediaType  ActivityMediaType
	SortOrder  int
	IsCover    bool
	CreatedAt  time.Time
}

type NewActivityMediaParams struct {
	ActivityID uuid.UUID
	FileID     uuid.UUID
	MediaType  ActivityMediaType
	SortOrder  int
	IsCover    bool
}

func NewActivityMedia(params NewActivityMediaParams) (*ActivityMedia, error) {
	item := &ActivityMedia{
		ID:         uuid.New(),
		ActivityID: params.ActivityID,
		FileID:     params.FileID,
		MediaType:  params.MediaType,
		SortOrder:  params.SortOrder,
		IsCover:    params.IsCover,
		CreatedAt:  time.Now().UTC(),
	}

	if err := item.Validate(); err != nil {
		return nil, err
	}

	return item, nil
}

func (m *ActivityMedia) Validate() error {
	if m.ID == uuid.Nil || m.ActivityID == uuid.Nil {
		return ErrInvalidActivityMediaID
	}
	if m.FileID == uuid.Nil {
		return ErrInvalidActivityMediaFile
	}
	if !m.MediaType.IsValid() {
		return ErrInvalidActivityMediaType
	}
	if m.SortOrder < 0 {
		return ErrInvalidActivityMediaID
	}
	return nil
}
