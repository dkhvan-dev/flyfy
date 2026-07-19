package domain

import (
	"time"

	"github.com/google/uuid"
)

const removedRelationshipRetention = 14 * 24 * time.Hour

type RelationshipState string

const (
	RelationshipStateActive  RelationshipState = "ACTIVE"
	RelationshipStateRemoved RelationshipState = "REMOVED"
)

func (s RelationshipState) IsValid() bool {
	return s == RelationshipStateActive || s == RelationshipStateRemoved
}

// ActivationIdentity changes for every new ACTIVE generation.
type ActivationIdentity struct {
	StateGeneration           uuid.UUID
	RelationshipAttributionID uuid.UUID
}

func (i ActivationIdentity) IsValid() bool {
	return i.StateGeneration != uuid.Nil && i.RelationshipAttributionID != uuid.Nil
}

// SavedRelationship is the owner-specific lifecycle record for a SavedTarget.
type SavedRelationship struct {
	id                         uuid.UUID
	ownerUserID                uuid.UUID
	target                     SavedTarget
	state                      RelationshipState
	savedAt                    time.Time
	updatedAt                  time.Time
	removedAt                  *time.Time
	purgeEligibleAt            *time.Time
	stateGeneration            uuid.UUID
	relationshipAttributionID  uuid.UUID
	relationshipVersion        uint64
	dependentMembershipVersion uint64
}

func NewActiveRelationship(
	id uuid.UUID,
	ownerUserID uuid.UUID,
	target SavedTarget,
	activation ActivationIdentity,
	serverNow time.Time,
) (*SavedRelationship, error) {
	if id == uuid.Nil || ownerUserID == uuid.Nil || target.IsZero() || !activation.IsValid() || serverNow.IsZero() {
		return nil, ErrMutationStale
	}

	return &SavedRelationship{
		id:                        id,
		ownerUserID:               ownerUserID,
		target:                    target,
		state:                     RelationshipStateActive,
		savedAt:                   serverNow,
		updatedAt:                 serverNow,
		stateGeneration:           activation.StateGeneration,
		relationshipAttributionID: activation.RelationshipAttributionID,
		relationshipVersion:       1,
	}, nil
}

func (r *SavedRelationship) Remove(serverNow time.Time) error {
	if r == nil || serverNow.IsZero() || serverNow.Before(r.updatedAt) {
		return ErrMutationStale
	}
	if r.state == RelationshipStateRemoved {
		return nil
	}
	if r.state != RelationshipStateActive {
		return ErrMutationStale
	}

	purgeEligibleAt := serverNow.Add(removedRelationshipRetention)
	r.state = RelationshipStateRemoved
	r.updatedAt = serverNow
	r.removedAt = &serverNow
	r.purgeEligibleAt = &purgeEligibleAt
	r.relationshipVersion++
	return nil
}

func (r *SavedRelationship) Reactivate(activation ActivationIdentity, serverNow time.Time) error {
	if r == nil || r.state != RelationshipStateRemoved || !activation.IsValid() || serverNow.IsZero() || serverNow.Before(r.updatedAt) {
		return ErrMutationStale
	}

	r.state = RelationshipStateActive
	r.savedAt = serverNow
	r.updatedAt = serverNow
	r.removedAt = nil
	r.purgeEligibleAt = nil
	r.stateGeneration = activation.StateGeneration
	r.relationshipAttributionID = activation.RelationshipAttributionID
	r.relationshipVersion++
	return nil
}

// BumpDependentMembershipVersion records a membership-only mutation without
// changing the relationship's saved timestamp or lifecycle version.
func (r *SavedRelationship) BumpDependentMembershipVersion(serverNow time.Time) error {
	if r == nil || r.state != RelationshipStateActive || serverNow.IsZero() || serverNow.Before(r.updatedAt) {
		return ErrMutationStale
	}

	r.updatedAt = serverNow
	r.dependentMembershipVersion++
	return nil
}

func (r *SavedRelationship) ID() uuid.UUID                        { return r.id }
func (r *SavedRelationship) OwnerUserID() uuid.UUID               { return r.ownerUserID }
func (r *SavedRelationship) Target() SavedTarget                  { return r.target }
func (r *SavedRelationship) State() RelationshipState             { return r.state }
func (r *SavedRelationship) SavedAt() time.Time                   { return r.savedAt }
func (r *SavedRelationship) UpdatedAt() time.Time                 { return r.updatedAt }
func (r *SavedRelationship) StateGeneration() uuid.UUID           { return r.stateGeneration }
func (r *SavedRelationship) RelationshipAttributionID() uuid.UUID { return r.relationshipAttributionID }
func (r *SavedRelationship) RelationshipVersion() uint64          { return r.relationshipVersion }
func (r *SavedRelationship) DependentMembershipVersion() uint64   { return r.dependentMembershipVersion }

func (r *SavedRelationship) RemovedAt() *time.Time {
	return copyTime(r.removedAt)
}

func (r *SavedRelationship) PurgeEligibleAt() *time.Time {
	return copyTime(r.purgeEligibleAt)
}

func copyTime(value *time.Time) *time.Time {
	if value == nil {
		return nil
	}

	copy := *value
	return &copy
}
