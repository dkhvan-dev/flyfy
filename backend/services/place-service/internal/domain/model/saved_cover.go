package model

import (
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/place-service/internal/domain/enum"
)

// SavedAttractionCoverSnapshot is the current source-owned authorization
// state needed to exchange an opaque Saved media reference for a file ID.
type SavedAttractionCoverSnapshot struct {
	ID                 uuid.UUID
	Status             enum.PlaceStatus
	DeletedAt          *time.Time
	ProjectionRevision uint64
	FileID             uuid.UUID
	ExternalURL        string
}
