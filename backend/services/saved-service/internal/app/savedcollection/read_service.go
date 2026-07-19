package savedcollection

import (
	"context"
	"math"
	"net/url"
	"strings"
	"time"
	"unicode"
	"unicode/utf8"

	"github.com/google/uuid"

	"kz/inflap/backend/services/saved-service/internal/app/savedaccess"
	"kz/inflap/backend/services/saved-service/internal/domain"
)

type ReadService struct {
	repository ReadRepository
	resolver   ThumbnailResolver
	access     savedaccess.Policy
}

func NewReadService(
	repository ReadRepository,
	resolver ThumbnailResolver,
	accessPolicies ...savedaccess.Policy,
) (*ReadService, error) {
	if repository == nil || len(accessPolicies) > 1 ||
		(len(accessPolicies) == 1 && accessPolicies[0] == nil) {
		return nil, ErrInvalidCommand
	}
	service := &ReadService{repository: repository, resolver: resolver}
	if len(accessPolicies) == 1 {
		service.access = accessPolicies[0]
	}
	return service, nil
}

func (service *ReadService) List(ctx context.Context, query ListQuery) ([]Collection, error) {
	if service == nil || service.repository == nil {
		return nil, ErrRepositoryUnavailable
	}
	if err := validateReadContext(ctx); err != nil {
		return nil, err
	}
	if err := query.Validate(); err != nil {
		return nil, err
	}
	records, err := service.repository.ListCollectionRecords(ctx, query)
	if err != nil {
		return nil, err
	}
	if err := validateCollectionRecords(records, query.OwnerUserID, true); err != nil {
		return nil, err
	}
	return service.resolveCovers(ctx, records), nil
}

func (service *ReadService) Get(ctx context.Context, query GetQuery) (Collection, error) {
	if service == nil || service.repository == nil {
		return Collection{}, ErrRepositoryUnavailable
	}
	if err := validateReadContext(ctx); err != nil {
		return Collection{}, err
	}
	if err := query.Validate(); err != nil {
		return Collection{}, err
	}
	record, err := service.repository.GetCollectionRecord(ctx, query)
	if err != nil {
		return Collection{}, err
	}
	if err := validateCollectionRecords([]CollectionRecord{record}, query.OwnerUserID, false); err != nil {
		return Collection{}, err
	}
	collections := service.resolveCovers(ctx, []CollectionRecord{record})
	if len(collections) != 1 {
		return Collection{}, ErrDataInvariant
	}
	return collections[0], nil
}

func (service *ReadService) TargetCollections(
	ctx context.Context,
	query TargetSnapshotQuery,
) (TargetCollectionsSnapshot, error) {
	if service == nil || service.repository == nil {
		return TargetCollectionsSnapshot{}, ErrRepositoryUnavailable
	}
	if err := validateReadContext(ctx); err != nil {
		return TargetCollectionsSnapshot{}, err
	}
	if err := query.Validate(); err != nil {
		return TargetCollectionsSnapshot{}, err
	}
	snapshot, err := service.repository.GetTargetCollections(ctx, query)
	if err != nil {
		return TargetCollectionsSnapshot{}, err
	}
	if err := validateTargetCollectionsSnapshot(snapshot, query); err != nil {
		return TargetCollectionsSnapshot{}, err
	}
	return cloneTargetCollectionsSnapshot(snapshot), nil
}

func (service *ReadService) resolveCovers(ctx context.Context, records []CollectionRecord) []Collection {
	collections := make([]Collection, len(records))
	requests := make([]ThumbnailRequest, 0, len(records))
	targets := make([]domain.SavedTarget, 0, len(records))
	for _, record := range records {
		if record.CoverCandidate != nil {
			targets = append(targets, record.CoverCandidate.Target)
		}
	}
	denied := make(map[domain.SavedTarget]struct{})
	if len(records) > 0 {
		var err error
		denied, err = savedaccess.DeniedTargetsFailClosed(
			ctx,
			service.access,
			records[0].OwnerUserID,
			targets,
		)
		if err != nil {
			denied = savedaccess.FailClosedUserTargets(targets, denied)
		}
	}
	for index, record := range records {
		collections[index] = record.Collection
		collections[index].Cover = GenericCover()
		candidate := record.CoverCandidate
		if candidate == nil {
			continue
		}
		if _, unavailable := denied[candidate.Target]; unavailable {
			continue
		}
		requests = append(requests, ThumbnailRequest{
			CollectionID:      candidate.CollectionID,
			Target:            candidate.Target,
			OpaqueReference:   candidate.OpaqueReference,
			ReferenceRevision: candidate.ReferenceRevision,
			ValidUntil:        candidate.ValidUntil,
		})
	}
	if service.resolver == nil || len(requests) == 0 {
		return collections
	}
	resolved, err := service.resolver.ResolveCollectionThumbnails(ctx, requests)
	if err != nil {
		return collections
	}
	for index, record := range records {
		candidate := record.CoverCandidate
		if candidate == nil {
			continue
		}
		if _, unavailable := denied[candidate.Target]; unavailable {
			continue
		}
		imageURL, ok := resolved[candidate.CollectionID]
		if !ok || !validResolvedImageURL(imageURL) {
			continue
		}
		target := candidate.Target
		title := candidate.Title
		resolvedURL := imageURL
		collections[index].Cover = CoverPreview{
			Kind:             CoverKindItem,
			Target:           &target,
			Title:            &title,
			ResolvedImageURL: &resolvedURL,
		}
	}
	return collections
}

func validResolvedImageURL(value string) bool {
	if value == "" || len(value) > 2048 || value != strings.TrimSpace(value) {
		return false
	}
	parsed, err := url.ParseRequestURI(value)
	if err != nil || parsed.Host == "" || parsed.User != nil || parsed.Fragment != "" {
		return false
	}
	return parsed.Scheme == "https" || parsed.Scheme == "http"
}

func validateReadContext(ctx context.Context) error {
	if ctx == nil {
		return ErrInvalidCommand
	}
	return ctx.Err()
}

func validateCollectionRecords(records []CollectionRecord, ownerUserID uuid.UUID, ordered bool) error {
	if ownerUserID == uuid.Nil || len(records) > int(DefaultMaxActiveCollections) {
		return ErrDataInvariant
	}
	seen := make(map[uuid.UUID]struct{}, len(records))
	for index, record := range records {
		collection := record.Collection
		if record.OwnerUserID != ownerUserID || collection.ID == uuid.Nil ||
			collection.LifecycleState != CollectionLifecycleActive ||
			collection.MetadataVersion == 0 || collection.MetadataVersion > math.MaxInt64 ||
			collection.LifecycleVersion == 0 || collection.LifecycleVersion > math.MaxInt64 ||
			collection.ActiveItemCount > DefaultMaxMembershipsPerCollection ||
			collection.CreatedAt.IsZero() || collection.OrganizedAt.IsZero() || collection.UpdatedAt.IsZero() ||
			collection.OrganizedAt.Before(collection.CreatedAt) ||
			collection.UpdatedAt.Before(collection.OrganizedAt) ||
			collection.Cover.Kind != CoverKindGeneric || collection.Cover.Target != nil ||
			collection.Cover.Title != nil || collection.Cover.ResolvedImageURL != nil {
			return ErrDataInvariant
		}
		normalized, err := NormalizeStoredTitle(collection.Title)
		if err != nil || normalized.Display != collection.Title {
			return ErrDataInvariant
		}
		if _, duplicate := seen[collection.ID]; duplicate {
			return ErrDataInvariant
		}
		seen[collection.ID] = struct{}{}
		if ordered && index > 0 && !collectionPrecedes(records[index-1].Collection, collection) {
			return ErrDataInvariant
		}
		if record.CoverCandidate != nil && !validCoverCandidate(record.CoverCandidate, collection.ID) {
			return ErrDataInvariant
		}
	}
	return nil
}

func collectionPrecedes(previous Collection, current Collection) bool {
	if previous.OrganizedAt.After(current.OrganizedAt) {
		return true
	}
	if !previous.OrganizedAt.Equal(current.OrganizedAt) {
		return false
	}
	return strings.Compare(previous.ID.String(), current.ID.String()) > 0
}

func validCoverCandidate(candidate *CoverCandidate, collectionID uuid.UUID) bool {
	return candidate != nil && candidate.CollectionID == collectionID && !candidate.Target.IsZero() &&
		candidate.ReferenceRevision > 0 && candidate.ReferenceRevision <= math.MaxInt64 &&
		!candidate.VisibilityValidatedAt.IsZero() && !candidate.ValidUntil.IsZero() &&
		candidate.ValidUntil.After(candidate.VisibilityValidatedAt) &&
		!candidate.ValidUntil.After(candidate.VisibilityValidatedAt.Add(15*time.Minute)) &&
		validBoundedReadText(candidate.Title, 300, 1024) &&
		validBoundedReadText(candidate.OpaqueReference, 2048, 2048)
}

func validBoundedReadText(value string, maxRunes int, maxBytes int) bool {
	return value != "" && utf8.ValidString(value) && value == strings.TrimSpace(value) &&
		utf8.RuneCountInString(value) <= maxRunes && len(value) <= maxBytes &&
		strings.IndexFunc(value, unicode.IsControl) < 0
}

func validateTargetCollectionsSnapshot(
	snapshot TargetCollectionsSnapshot,
	query TargetSnapshotQuery,
) error {
	if snapshot.Target != query.Target || snapshot.RecordedAt.IsZero() ||
		!snapshot.RecordedAt.Equal(query.ReadAt.UTC()) ||
		snapshot.DependentMembershipVersion > math.MaxInt64 ||
		len(snapshot.EffectiveCollectionIDs) > DefaultMaxDesiredCollectionIDs ||
		len(snapshot.CollectionOptions) > int(DefaultMaxActiveCollections) {
		return ErrDataInvariant
	}
	switch snapshot.Relationship.State {
	case RelationshipSnapshotAbsent:
		if snapshot.Relationship.Generation != uuid.Nil || snapshot.Relationship.Version != 0 ||
			snapshot.DependentMembershipVersion != 0 || len(snapshot.EffectiveCollectionIDs) != 0 {
			return ErrDataInvariant
		}
	case RelationshipSnapshotActive, RelationshipSnapshotRemoved:
		if snapshot.Relationship.Generation == uuid.Nil || snapshot.Relationship.Version == 0 ||
			snapshot.Relationship.Version > math.MaxInt64 {
			return ErrDataInvariant
		}
		if snapshot.Relationship.State == RelationshipSnapshotRemoved &&
			len(snapshot.EffectiveCollectionIDs) != 0 {
			return ErrDataInvariant
		}
	default:
		return ErrDataInvariant
	}

	options := make(map[uuid.UUID]struct{}, len(snapshot.CollectionOptions))
	for _, option := range snapshot.CollectionOptions {
		if option.ID == uuid.Nil || option.MetadataVersion == 0 || option.MetadataVersion > math.MaxInt64 ||
			option.LifecycleVersion == 0 || option.LifecycleVersion > math.MaxInt64 {
			return ErrDataInvariant
		}
		normalized, err := NormalizeStoredTitle(option.Title)
		if err != nil || normalized.Display != option.Title {
			return ErrDataInvariant
		}
		if _, duplicate := options[option.ID]; duplicate {
			return ErrDataInvariant
		}
		options[option.ID] = struct{}{}
	}
	seenEffective := make(map[uuid.UUID]struct{}, len(snapshot.EffectiveCollectionIDs))
	for _, collectionID := range snapshot.EffectiveCollectionIDs {
		if collectionID == uuid.Nil {
			return ErrDataInvariant
		}
		if _, duplicate := seenEffective[collectionID]; duplicate {
			return ErrDataInvariant
		}
		if _, active := options[collectionID]; !active {
			return ErrDataInvariant
		}
		seenEffective[collectionID] = struct{}{}
	}
	return nil
}

func cloneTargetCollectionsSnapshot(snapshot TargetCollectionsSnapshot) TargetCollectionsSnapshot {
	snapshot.EffectiveCollectionIDs = append([]uuid.UUID(nil), snapshot.EffectiveCollectionIDs...)
	snapshot.CollectionOptions = append([]CollectionOption(nil), snapshot.CollectionOptions...)
	return snapshot
}
