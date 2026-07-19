package savedcollection

import (
	"context"

	"github.com/google/uuid"

	"kz/inflap/backend/services/saved-service/internal/domain"
)

type ReadRepository interface {
	ListCollectionRecords(context.Context, ListQuery) ([]CollectionRecord, error)
	GetCollectionRecord(context.Context, GetQuery) (CollectionRecord, error)
	GetTargetCollections(context.Context, TargetSnapshotQuery) (TargetCollectionsSnapshot, error)
}

// Repository owns collection final transactions. Policy, session, source
// resolution, and operation creation deliberately remain outside this port.
type Repository interface {
	ReadRepository
	AnalyzeDesiredSet(context.Context, AnalyzeDesiredSetQuery) (DesiredSetAnalysis, error)
	PrepareProjectionShell(context.Context, PrepareProjectionShellCommand) (*domain.SavedOperation, error)
	Create(context.Context, CreateCommand) (*domain.SavedOperation, error)
	Rename(context.Context, RenameCommand) (*domain.SavedOperation, error)
	Delete(context.Context, DeleteCommand) (*domain.SavedOperation, error)
	ReplaceDesiredSet(context.Context, ReplaceDesiredSetCommand) (*domain.SavedOperation, error)
	RejectPending(context.Context, RejectPendingCommand) (*domain.SavedOperation, error)
}

type ThumbnailResolver interface {
	ResolveCollectionThumbnails(context.Context, []ThumbnailRequest) (map[uuid.UUID]string, error)
}
