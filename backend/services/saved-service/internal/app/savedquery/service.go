package savedquery

import (
	"context"
	"net/url"
	"strings"
	"time"
	"unicode"
	"unicode/utf8"

	"github.com/google/uuid"

	"kz/inflap/backend/services/saved-service/internal/app/savedaccess"
	"kz/inflap/backend/services/saved-service/internal/domain"
)

type Service struct {
	repository    Repository
	imageResolver ImageResolver
	accessPolicy  savedaccess.Policy
	now           func() time.Time
}

func NewService(
	repository Repository,
	imageResolver ImageResolver,
	accessPolicies ...savedaccess.Policy,
) (*Service, error) {
	if imageResolver == nil || len(accessPolicies) > 1 ||
		(len(accessPolicies) == 1 && accessPolicies[0] == nil) {
		return nil, ErrInvalidQuery
	}
	service, err := newService(repository, time.Now, imageResolver)
	if err != nil {
		return nil, err
	}
	if len(accessPolicies) == 1 {
		service.accessPolicy = accessPolicies[0]
	}
	return service, nil
}

func newService(repository Repository, now func() time.Time, imageResolvers ...ImageResolver) (*Service, error) {
	if repository == nil || now == nil || len(imageResolvers) > 1 ||
		(len(imageResolvers) == 1 && imageResolvers[0] == nil) {
		return nil, ErrInvalidQuery
	}
	var imageResolver ImageResolver
	if len(imageResolvers) == 1 {
		imageResolver = imageResolvers[0]
	}
	return &Service{repository: repository, imageResolver: imageResolver, now: now}, nil
}

func (s *Service) GetStatus(
	ctx context.Context,
	ownerUserID uuid.UUID,
	target domain.SavedTarget,
) (TargetStatus, error) {
	if err := contextError(ctx); err != nil {
		return TargetStatus{}, err
	}
	query := StatusQuery{OwnerUserID: ownerUserID, Target: target}
	if err := query.Validate(); err != nil {
		return TargetStatus{}, err
	}
	status, err := s.repository.GetStatus(ctx, query)
	if err != nil {
		return TargetStatus{}, err
	}
	if err := validateTargetStatus(status, target); err != nil {
		return TargetStatus{}, err
	}
	statuses, err := s.applyUserAccessToStatuses(ctx, ownerUserID, []TargetStatus{status})
	if err != nil || len(statuses) != 1 {
		if err != nil {
			return TargetStatus{}, err
		}
		return TargetStatus{}, ErrDataInvariant
	}
	return statuses[0], nil
}

func (s *Service) BatchStatus(
	ctx context.Context,
	ownerUserID uuid.UUID,
	targets []domain.SavedTarget,
) ([]TargetStatus, error) {
	if err := contextError(ctx); err != nil {
		return nil, err
	}
	query := BatchStatusQuery{
		OwnerUserID: ownerUserID,
		Targets:     append([]domain.SavedTarget(nil), targets...),
	}
	if err := query.Validate(); err != nil {
		return nil, err
	}
	statuses, err := s.repository.BatchStatus(ctx, query)
	if err != nil {
		return nil, err
	}
	if len(statuses) != len(query.Targets) {
		return nil, ErrDataInvariant
	}
	for index, status := range statuses {
		if err := validateTargetStatus(status, query.Targets[index]); err != nil {
			return nil, err
		}
	}
	return s.applyUserAccessToStatuses(ctx, ownerUserID, statuses)
}

func (s *Service) ListItems(ctx context.Context, input ListInput) (Page, error) {
	if err := contextError(ctx); err != nil {
		return Page{}, err
	}
	query := normalizedListQuery(input, s.now().UTC())
	if err := query.Validate(); err != nil {
		return Page{}, err
	}
	page, err := s.repository.ListItems(ctx, query)
	if err != nil {
		return Page{}, err
	}
	if err := validatePage(page, query); err != nil {
		return Page{}, err
	}
	page.Items = cloneItems(page.Items)
	targets := make([]domain.SavedTarget, len(page.Items))
	for index := range page.Items {
		targets[index] = page.Items[index].Target
	}
	denied, err := savedaccess.DeniedTargetsFailClosed(
		ctx,
		s.accessPolicy,
		query.OwnerUserID,
		targets,
	)
	if err != nil {
		return Page{}, err
	}
	for index := range page.Items {
		if _, unavailable := denied[page.Items[index].Target]; unavailable {
			page.Items[index].Projection.ContentState = ContentStateUnavailable
			page.Items[index].Projection.Public = nil
		}
	}
	itemPointers := make([]*Item, len(page.Items))
	for index := range page.Items {
		itemPointers[index] = &page.Items[index]
	}
	if err := ResolveItemImages(ctx, s.imageResolver, itemPointers); err != nil {
		return Page{}, err
	}
	if err := validatePage(page, query); err != nil {
		return Page{}, err
	}
	page.Next = copyKeyset(page.Next)
	return page, nil
}

func (s *Service) applyUserAccessToStatuses(
	ctx context.Context,
	ownerUserID uuid.UUID,
	statuses []TargetStatus,
) ([]TargetStatus, error) {
	result := append([]TargetStatus(nil), statuses...)
	targets := make([]domain.SavedTarget, len(result))
	for index := range result {
		targets[index] = result[index].Target
	}
	denied, err := savedaccess.DeniedTargetsFailClosed(ctx, s.accessPolicy, ownerUserID, targets)
	if err != nil {
		return nil, err
	}
	for index := range result {
		if _, unavailable := denied[result[index].Target]; !unavailable {
			continue
		}
		if result[index].SavedState == SavedStateSaved {
			result[index].Eligibility = EligibilityReductionOnly
		} else {
			result[index].Eligibility = EligibilityIneligible
		}
		if err := validateTargetStatus(result[index], targets[index]); err != nil {
			return nil, err
		}
	}
	return result, nil
}

// ResolveItemImages resolves and then scrubs every opaque media reference. It
// is exported so search can apply the same fail-closed contract to embedded
// Saved items without duplicating media handling.
func ResolveItemImages(ctx context.Context, resolver ImageResolver, items []*Item) error {
	if ctx == nil {
		return ErrInvalidQuery
	}
	if err := ctx.Err(); err != nil {
		return err
	}
	requests := make([]ImageRequest, 0, len(items))
	known := make(map[uuid.UUID]*Item, len(items))
	for _, item := range items {
		if item == nil || item.ItemID == uuid.Nil {
			return ErrDataInvariant
		}
		if _, exists := known[item.ItemID]; exists {
			return ErrDataInvariant
		}
		known[item.ItemID] = item
		if item.Projection.Public == nil || item.Projection.Public.MediaReference == nil {
			continue
		}
		reference := item.Projection.Public.MediaReference
		requests = append(requests, ImageRequest{
			ItemID:            item.ItemID,
			Target:            item.Target,
			OpaqueReference:   reference.OpaqueReference,
			ReferenceRevision: reference.ReferenceRevision,
			ValidUntil:        reference.ValidUntil,
		})
	}

	resolved := map[uuid.UUID]string{}
	if len(requests) > 0 && resolver != nil {
		var err error
		resolved, err = resolver.ResolveItemImages(ctx, requests)
		if err != nil {
			return err
		}
		if resolved == nil {
			return ErrDataInvariant
		}
	}
	for itemID, imageURL := range resolved {
		item, exists := known[itemID]
		if !exists || item.Projection.Public == nil ||
			item.Projection.Public.MediaReference == nil || !validResolvedImageURL(imageURL) {
			return ErrDataInvariant
		}
		value := imageURL
		item.Projection.Public.ResolvedImageURL = &value
	}
	for _, item := range items {
		if item.Projection.Public != nil {
			item.Projection.Public.MediaReference = nil
		}
	}
	return nil
}

func normalizedListQuery(input ListInput, readAt time.Time) ListQuery {
	limit := input.Limit
	if limit == 0 {
		limit = DefaultPageLimit
	}
	return ListQuery{
		OwnerUserID: input.OwnerUserID,
		Locale:      input.Locale,
		EntityType:  copyEntityType(input.EntityType),
		Collection:  copyUUID(input.Collection),
		Uncollected: input.Uncollected,
		After:       copyKeyset(input.After),
		Limit:       limit,
		ReadAt:      readAt,
	}
}

func validateTargetStatus(status TargetStatus, expected domain.SavedTarget) error {
	if status.Target != expected || !status.SavedState.IsValid() || !status.Eligibility.IsValid() ||
		status.EffectiveCollectionCount > MaxEffectiveCollectionCount {
		return ErrDataInvariant
	}
	switch status.SavedState {
	case SavedStateUnknown:
		if status.RelationshipGeneration != nil || status.ResourceVersion != 0 ||
			status.EffectiveCollectionCount != 0 ||
			(status.Eligibility != EligibilityUnknown && status.Eligibility != EligibilityIneligible) {
			return ErrDataInvariant
		}
	case SavedStateConfirmedUnsaved:
		if status.RelationshipGeneration != nil || status.ResourceVersion == 0 ||
			status.EffectiveCollectionCount != 0 || status.Eligibility == EligibilityReductionOnly {
			return ErrDataInvariant
		}
	case SavedStateSaved:
		if status.RelationshipGeneration == nil || *status.RelationshipGeneration == uuid.Nil ||
			status.ResourceVersion == 0 ||
			(status.Eligibility != EligibilityEligible && status.Eligibility != EligibilityReductionOnly) {
			return ErrDataInvariant
		}
	default:
		return ErrDataInvariant
	}
	return nil
}

func cloneItems(items []Item) []Item {
	cloned := append([]Item(nil), items...)
	for index := range cloned {
		if cloned[index].Projection.Public == nil {
			continue
		}
		public := *cloned[index].Projection.Public
		public.Subtitle = cloneString(public.Subtitle)
		public.ResolvedImageURL = cloneString(public.ResolvedImageURL)
		if public.MediaReference != nil {
			mediaReference := *public.MediaReference
			public.MediaReference = &mediaReference
		}
		cloned[index].Projection.Public = &public
	}
	return cloned
}

func cloneString(value *string) *string {
	if value == nil {
		return nil
	}
	copyValue := *value
	return &copyValue
}

func validatePage(page Page, query ListQuery) error {
	if len(page.Items) > query.Limit || page.HasMore != (page.Next != nil) {
		return ErrDataInvariant
	}
	if len(page.Items) == 0 && page.Next != nil {
		return ErrDataInvariant
	}
	seen := make(map[uuid.UUID]struct{}, len(page.Items))
	for index, item := range page.Items {
		if item.ItemID == uuid.Nil || item.Target.IsZero() || item.Relationship.Generation == uuid.Nil ||
			item.Relationship.Version == 0 || item.Relationship.SavedAt.IsZero() ||
			item.Relationship.AttributionID == uuid.Nil ||
			item.EffectiveCollectionCount > MaxEffectiveCollectionCount {
			return ErrDataInvariant
		}
		if query.EntityType != nil && item.Target.EntityType() != *query.EntityType {
			return ErrDataInvariant
		}
		if _, exists := seen[item.ItemID]; exists {
			return ErrDataInvariant
		}
		seen[item.ItemID] = struct{}{}
		if query.After != nil && !keysetBefore(item.Relationship.SavedAt, item.ItemID, *query.After) {
			return ErrDataInvariant
		}
		if index > 0 {
			previous := page.Items[index-1]
			if !keysetBefore(item.Relationship.SavedAt, item.ItemID, Keyset{
				SavedAt: previous.Relationship.SavedAt,
				ItemID:  previous.ItemID,
			}) {
				return ErrDataInvariant
			}
		}
		if err := validateProjection(item.Projection); err != nil {
			return err
		}
	}
	if page.Next != nil {
		last := page.Items[len(page.Items)-1]
		if !page.Next.SavedAt.Equal(last.Relationship.SavedAt) || page.Next.ItemID != last.ItemID {
			return ErrDataInvariant
		}
	}
	return nil
}

func validateProjection(projection CardProjection) error {
	if projection.Revisions.Source > uint64(^uint64(0)>>1) ||
		projection.Revisions.Projection > uint64(^uint64(0)>>1) ||
		projection.Revisions.Visibility > uint64(^uint64(0)>>1) {
		return ErrDataInvariant
	}
	switch projection.ContentState {
	case ContentStateUnavailable:
		if projection.Public != nil {
			return ErrDataInvariant
		}
	case ContentStateAvailable:
		if projection.Public == nil || !projection.Public.DisplayLocale.IsValid() ||
			projection.Revisions.Source == 0 || projection.Revisions.Projection == 0 ||
			projection.Revisions.Visibility == 0 ||
			!validPublicDisplayText(projection.Public.Title, 300) ||
			(projection.Public.Subtitle != nil &&
				!validPublicDisplayText(*projection.Public.Subtitle, 500)) ||
			!validCanonicalDetailRoute(projection.Public.CanonicalDetailRoute) ||
			projection.Public.SourceUpdatedAt.IsZero() || projection.Public.SourceUpdatedAt.UnixMicro() <= 0 {
			return ErrDataInvariant
		}
		if projection.Public.ResolvedImageURL != nil && !validResolvedImageURL(*projection.Public.ResolvedImageURL) {
			return ErrDataInvariant
		}
		if projection.Public.MediaReference != nil && !validMediaReference(*projection.Public.MediaReference) {
			return ErrDataInvariant
		}
	default:
		return ErrDataInvariant
	}
	return nil
}

func validMediaReference(reference MediaReference) bool {
	return reference.OpaqueReference != "" && len(reference.OpaqueReference) <= 2048 &&
		reference.OpaqueReference == strings.TrimSpace(reference.OpaqueReference) &&
		strings.IndexFunc(reference.OpaqueReference, unicode.IsControl) < 0 &&
		reference.ReferenceRevision > 0 && reference.ReferenceRevision <= uint64(^uint64(0)>>1) &&
		!reference.ValidUntil.IsZero() && reference.ValidUntil.UnixMicro() > 0
}

func validResolvedImageURL(value string) bool {
	if value == "" || len(value) > 2048 || value != strings.TrimSpace(value) {
		return false
	}
	parsed, err := url.Parse(value)
	return err == nil && parsed.Host != "" && parsed.User == nil &&
		(parsed.Scheme == "https" || parsed.Scheme == "http")
}

func validPublicDisplayText(value string, maxRunes int) bool {
	return value != "" && maxRunes > 0 && utf8.ValidString(value) && utf8.RuneCountInString(value) <= maxRunes &&
		value == strings.TrimSpace(value) && strings.IndexFunc(value, unicode.IsControl) < 0
}

func validCanonicalDetailRoute(value string) bool {
	return strings.HasPrefix(value, "/") && len(value) <= 2048 &&
		!strings.ContainsAny(value, "?#%\\") && validPublicDisplayText(value, 2048)
}

func keysetBefore(savedAt time.Time, itemID uuid.UUID, cursor Keyset) bool {
	if savedAt.Before(cursor.SavedAt) {
		return true
	}
	if !savedAt.Equal(cursor.SavedAt) {
		return false
	}
	return string(itemID[:]) < string(cursor.ItemID[:])
}

func contextError(ctx context.Context) error {
	if ctx == nil {
		return ErrInvalidQuery
	}
	return ctx.Err()
}

func copyEntityType(value *domain.EntityType) *domain.EntityType {
	if value == nil {
		return nil
	}
	copy := *value
	return &copy
}

func copyUUID(value *uuid.UUID) *uuid.UUID {
	if value == nil {
		return nil
	}
	copy := *value
	return &copy
}

func copyKeyset(value *Keyset) *Keyset {
	if value == nil {
		return nil
	}
	copy := *value
	copy.SavedAt = copy.SavedAt.UTC()
	return &copy
}
