package model

import (
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/guide-service/internal/domain/enum"
)

// SavedGuideSnapshot is the source-owned subset required to decide whether a
// guide can be represented in Saved. It deliberately excludes verification
// documents, review comments, moderation actors, and any Saved relationship.
type SavedGuideSnapshot struct {
	Profile                     *GuideProfile
	LatestVerificationStatus    *enum.VerificationRequestStatus
	LatestVerificationUpdatedAt *time.Time
	SourceRevision              uint64
	ProjectionRevision          uint64
	VisibilityRevision          uint64
	LifecycleVisibility         SavedLifecycleVisibility
	MediaReferenceRevision      uint64
	MediaReferenceActive        bool
	ExternalAvatarFileID        *uuid.UUID
}
