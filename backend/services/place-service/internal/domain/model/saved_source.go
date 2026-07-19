package model

import (
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/place-service/internal/domain/enum"
)

// SavedAttractionSnapshot is the bounded source-owned state required to
// resolve an attraction for Saved. It intentionally excludes ownership and
// every user-specific Saved concern.
type SavedAttractionSnapshot struct {
	ID                 uuid.UUID
	DefaultLocale      string
	CountryCode        string
	CityID             string
	Rating             float64
	ReviewCount        int
	Status             enum.PlaceStatus
	DeletedAt          *time.Time
	Translations       map[string]PlaceTranslation
	Media              []PlaceMedia
	SourceRevision     uint64
	ProjectionRevision uint64
	VisibilityRevision uint64
}
