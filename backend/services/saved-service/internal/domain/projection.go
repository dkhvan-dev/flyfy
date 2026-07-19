package domain

import "time"

type VisibilityStatus string

const (
	VisibilityUnknown     VisibilityStatus = "UNKNOWN"
	VisibilityPublic      VisibilityStatus = "PUBLIC"
	VisibilityPrivate     VisibilityStatus = "PRIVATE"
	VisibilityUnavailable VisibilityStatus = "UNAVAILABLE"
	VisibilityDeleted     VisibilityStatus = "DELETED"
	VisibilityRestricted  VisibilityStatus = "RESTRICTED"
)

func (s VisibilityStatus) IsValid() bool {
	switch s {
	case VisibilityUnknown, VisibilityPublic, VisibilityPrivate, VisibilityUnavailable, VisibilityDeleted, VisibilityRestricted:
		return true
	default:
		return false
	}
}

func (s VisibilityStatus) AllowsExpansion() bool {
	return s == VisibilityPublic
}

// PublicProjectionPayload deliberately holds only fields that may be exposed
// from a PUBLIC source projection. Non-public visibility must clear it.
type PublicProjectionPayload struct {
	Title                string
	Subtitle             string
	SearchDocument       string
	MediaReference       string
	CanonicalDetailRoute string
}

func (p *PublicProjectionPayload) clone() *PublicProjectionPayload {
	if p == nil {
		return nil
	}

	copy := *p
	return &copy
}

// SavedContentProjection is a materialized public projection or a payload-free
// deny shell. It is not a source-content mirror.
type SavedContentProjection struct {
	target                SavedTarget
	visibility            VisibilityStatus
	visibilityRevision    uint64
	visibilityValidatedAt time.Time
	payload               *PublicProjectionPayload
}

func NewSavedContentProjection(
	target SavedTarget,
	visibility VisibilityStatus,
	visibilityRevision uint64,
	visibilityValidatedAt time.Time,
	payload *PublicProjectionPayload,
) (*SavedContentProjection, error) {
	projection := &SavedContentProjection{target: target}
	if err := projection.SetVisibility(visibility, visibilityRevision, visibilityValidatedAt, payload); err != nil {
		return nil, err
	}

	return projection, nil
}

func (p *SavedContentProjection) SetVisibility(
	visibility VisibilityStatus,
	visibilityRevision uint64,
	validatedAt time.Time,
	payload *PublicProjectionPayload,
) error {
	if p == nil || p.target.IsZero() || !visibility.IsValid() || validatedAt.IsZero() {
		return ErrMutationStale
	}
	if p.visibilityRevision > 0 && visibilityRevision < p.visibilityRevision {
		return ErrMutationStale
	}
	if visibility == VisibilityPrivate && p.target.EntityType() != EntityTypeActivity {
		return ErrTargetUnavailable
	}
	if visibility == VisibilityPublic && payload == nil {
		return ErrMutationStale
	}
	if visibility != VisibilityPublic && payload != nil {
		return ErrTargetUnavailable
	}

	p.visibility = visibility
	p.visibilityRevision = visibilityRevision
	p.visibilityValidatedAt = validatedAt
	p.payload = payload.clone()
	return nil
}

func (p *SavedContentProjection) Target() SavedTarget                     { return p.target }
func (p *SavedContentProjection) Visibility() VisibilityStatus            { return p.visibility }
func (p *SavedContentProjection) VisibilityRevision() uint64              { return p.visibilityRevision }
func (p *SavedContentProjection) VisibilityValidatedAt() time.Time        { return p.visibilityValidatedAt }
func (p *SavedContentProjection) PublicPayload() *PublicProjectionPayload { return p.payload.clone() }
