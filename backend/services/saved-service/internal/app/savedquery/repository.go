package savedquery

import (
	"context"

	"github.com/google/uuid"
)

type Repository interface {
	GetStatus(context.Context, StatusQuery) (TargetStatus, error)
	BatchStatus(context.Context, BatchStatusQuery) ([]TargetStatus, error)
	ListItems(context.Context, ListQuery) (Page, error)
}

// ImageResolver converts opaque source references into public Saved media
// routes. Missing map entries are a valid fail-closed result (generic/no image).
type ImageResolver interface {
	ResolveItemImages(context.Context, []ImageRequest) (map[uuid.UUID]string, error)
}
