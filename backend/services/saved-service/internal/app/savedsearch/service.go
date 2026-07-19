package savedsearch

import (
	"context"
	"net/url"
	"strings"
	"time"
	"unicode"
	"unicode/utf8"

	"github.com/google/uuid"

	"kz/inflap/backend/services/saved-service/internal/app/savedaccess"
	savedqueryapp "kz/inflap/backend/services/saved-service/internal/app/savedquery"
	"kz/inflap/backend/services/saved-service/internal/domain"
)

type Service struct {
	repository    Repository
	imageResolver savedqueryapp.ImageResolver
	accessPolicy  savedaccess.Policy
	now           func() time.Time
}

func NewService(
	repository Repository,
	imageResolver savedqueryapp.ImageResolver,
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

func newService(
	repository Repository,
	now func() time.Time,
	imageResolvers ...savedqueryapp.ImageResolver,
) (*Service, error) {
	if repository == nil || now == nil || len(imageResolvers) > 1 ||
		(len(imageResolvers) == 1 && imageResolvers[0] == nil) {
		return nil, ErrInvalidQuery
	}
	var imageResolver savedqueryapp.ImageResolver
	if len(imageResolvers) == 1 {
		imageResolver = imageResolvers[0]
	}
	return &Service{repository: repository, imageResolver: imageResolver, now: now}, nil
}

func (s *Service) Search(ctx context.Context, input Input) (Page, error) {
	if err := searchContextError(ctx); err != nil {
		return Page{}, err
	}
	term, err := Normalize(input.Search)
	if err != nil {
		return Page{}, err
	}
	query := normalizedQuery(input, term, s.now().UTC())
	if err := query.Validate(); err != nil {
		return Page{}, err
	}
	page, err := s.repository.Search(ctx, query)
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
			page.Items[index].Projection.ContentState = savedqueryapp.ContentStateUnavailable
			page.Items[index].Projection.Public = nil
			page.Items[index].Match.AlternatePublicDisplay = nil
		}
	}
	itemPointers := make([]*savedqueryapp.Item, len(page.Items))
	for index := range page.Items {
		itemPointers[index] = &page.Items[index].Item
	}
	if err := savedqueryapp.ResolveItemImages(ctx, s.imageResolver, itemPointers); err != nil {
		return Page{}, err
	}
	if err := validateResolvedPage(page, query); err != nil {
		return Page{}, err
	}
	page.Next = copyKeyset(page.Next)
	return page, nil
}

func normalizedQuery(input Input, term SearchTerm, readAt time.Time) Query {
	limit := input.Limit
	if limit == 0 {
		limit = DefaultPageLimit
	}
	return Query{
		OwnerUserID: input.OwnerUserID,
		Locale:      input.Locale,
		EntityType:  copyEntityType(input.EntityType),
		Collection:  copyUUID(input.Collection),
		Uncollected: input.Uncollected,
		Term:        term,
		After:       copyKeyset(input.After),
		Limit:       limit,
		ReadAt:      readAt,
	}
}

func validatePage(page Page, query Query) error {
	if len(page.Items) > query.Limit || page.HasMore != (page.Next != nil) ||
		(len(page.Items) == 0 && page.Next != nil) {
		return ErrDataInvariant
	}
	seen := make(map[uuid.UUID]struct{}, len(page.Items))
	for index, item := range page.Items {
		if err := validateItem(item, query); err != nil {
			return err
		}
		if _, exists := seen[item.ItemID]; exists {
			return ErrDataInvariant
		}
		seen[item.ItemID] = struct{}{}
		if query.After != nil && !itemAfterKeyset(item, *query.After) {
			return ErrDataInvariant
		}
		if index > 0 && !itemAfterKeyset(item, keysetForItem(page.Items[index-1])) {
			return ErrDataInvariant
		}
	}
	if page.Next != nil {
		last := page.Items[len(page.Items)-1]
		if *page.Next != keysetForItem(last) {
			return ErrDataInvariant
		}
	}
	return nil
}

func validateItem(item Item, query Query) error {
	if item.ItemID == uuid.Nil || item.Target.IsZero() || item.Relationship.Generation == uuid.Nil ||
		item.Relationship.Version == 0 || item.Relationship.SavedAt.IsZero() ||
		item.Relationship.AttributionID == uuid.Nil ||
		item.EffectiveCollectionCount > MaxEffectiveCollectionCount ||
		(query.EntityType != nil && item.Target.EntityType() != *query.EntityType) {
		return ErrDataInvariant
	}
	if err := validateMatch(item.Match); err != nil {
		return err
	}
	projection := item.Projection
	if projection.ContentState == savedqueryapp.ContentStateUnavailable {
		if projection.Public != nil || item.Match.AlternatePublicDisplay != nil ||
			projection.Revisions.Source > uint64(^uint64(0)>>1) ||
			projection.Revisions.Projection > uint64(^uint64(0)>>1) ||
			projection.Revisions.Visibility > uint64(^uint64(0)>>1) {
			return ErrDataInvariant
		}
		return nil
	}
	if projection.ContentState != savedqueryapp.ContentStateAvailable || projection.Public == nil ||
		projection.Revisions.Source == 0 || projection.Revisions.Projection == 0 ||
		projection.Revisions.Visibility == 0 || !projection.Public.DisplayLocale.IsValid() ||
		!validDisplayText(projection.Public.Title, 300) ||
		!validCanonicalRoute(projection.Public.CanonicalDetailRoute) ||
		projection.Public.SourceUpdatedAt.IsZero() || projection.Public.SourceUpdatedAt.UnixMicro() <= 0 {
		return ErrDataInvariant
	}
	if projection.Public.Subtitle != nil && !validDisplayText(*projection.Public.Subtitle, 500) {
		return ErrDataInvariant
	}
	if projection.Public.ResolvedImageURL != nil && !validImageURL(*projection.Public.ResolvedImageURL) {
		return ErrDataInvariant
	}
	if projection.Public.MediaReference != nil && !validMediaReference(*projection.Public.MediaReference) {
		return ErrDataInvariant
	}
	requiresAlternate := item.Match.Field != MatchedFieldTitle ||
		item.Match.Locale != projection.Public.DisplayLocale
	if requiresAlternate != (item.Match.AlternatePublicDisplay != nil) {
		return ErrDataInvariant
	}
	return nil
}

func validateMatch(match Match) error {
	if !match.Rank.IsValid() || !match.Kind.IsValid() || !match.Field.IsValid() || !match.Locale.IsValid() {
		return ErrDataInvariant
	}
	validShape := false
	switch match.Rank {
	case MatchRankTitleExact:
		validShape = match.Field == MatchedFieldTitle && match.Kind == MatchKindExact
	case MatchRankTitleToken:
		validShape = match.Field == MatchedFieldTitle && match.Kind == MatchKindToken
	case MatchRankTitlePrefix:
		validShape = match.Field == MatchedFieldTitle && match.Kind == MatchKindPrefix
	case MatchRankLocationExactOrToken:
		validShape = match.Field != MatchedFieldTitle &&
			(match.Kind == MatchKindExact || match.Kind == MatchKindToken)
	case MatchRankLocationPrefix:
		validShape = match.Field != MatchedFieldTitle && match.Kind == MatchKindPrefix
	}
	if !validShape || (match.AlternatePublicDisplay != nil &&
		!validDisplayText(*match.AlternatePublicDisplay, maxAlternateDisplayRunes)) {
		return ErrDataInvariant
	}
	return nil
}

func itemAfterKeyset(item Item, keyset Keyset) bool {
	if item.Match.Rank != keyset.MatchRank {
		return item.Match.Rank > keyset.MatchRank
	}
	if !item.Relationship.SavedAt.Equal(keyset.SavedAt) {
		return item.Relationship.SavedAt.Before(keyset.SavedAt)
	}
	return string(item.ItemID[:]) < string(keyset.ItemID[:])
}

func keysetForItem(item Item) Keyset {
	return Keyset{
		MatchRank: item.Match.Rank,
		SavedAt:   item.Relationship.SavedAt,
		ItemID:    item.ItemID,
	}
}

func validDisplayText(value string, maxRunes int) bool {
	return value != "" && maxRunes > 0 && utf8.ValidString(value) &&
		utf8.RuneCountInString(value) <= maxRunes && value == strings.TrimSpace(value) &&
		strings.IndexFunc(value, unicode.IsControl) < 0
}

func validCanonicalRoute(value string) bool {
	return strings.HasPrefix(value, "/") && len(value) <= 2048 &&
		!strings.ContainsAny(value, "?#%\\") && validDisplayText(value, 2048)
}

func validImageURL(value string) bool {
	if value == "" || len(value) > 2048 || value != strings.TrimSpace(value) {
		return false
	}
	parsed, err := url.Parse(value)
	return err == nil && parsed.Host != "" && parsed.User == nil &&
		(parsed.Scheme == "https" || parsed.Scheme == "http")
}

func validMediaReference(reference savedqueryapp.MediaReference) bool {
	return validDisplayText(reference.OpaqueReference, 2048) && reference.ReferenceRevision > 0 &&
		reference.ReferenceRevision <= uint64(^uint64(0)>>1) &&
		!reference.ValidUntil.IsZero() && reference.ValidUntil.UnixMicro() > 0
}

func validateResolvedPage(page Page, query Query) error {
	for _, item := range page.Items {
		if item.Projection.Public != nil && item.Projection.Public.MediaReference != nil {
			return ErrDataInvariant
		}
	}
	return validatePage(page, query)
}

func cloneItems(items []Item) []Item {
	cloned := append([]Item(nil), items...)
	for index := range cloned {
		if cloned[index].Projection.Public != nil {
			public := *cloned[index].Projection.Public
			public.Subtitle = cloneString(public.Subtitle)
			public.ResolvedImageURL = cloneString(public.ResolvedImageURL)
			if public.MediaReference != nil {
				mediaReference := *public.MediaReference
				public.MediaReference = &mediaReference
			}
			cloned[index].Projection.Public = &public
		}
		if cloned[index].Match.AlternatePublicDisplay != nil {
			cloned[index].Match.AlternatePublicDisplay = cloneString(
				cloned[index].Match.AlternatePublicDisplay,
			)
		}
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

func copyEntityType(value *domain.EntityType) *domain.EntityType {
	if value == nil {
		return nil
	}
	copyValue := *value
	return &copyValue
}

func copyUUID(value *uuid.UUID) *uuid.UUID {
	if value == nil {
		return nil
	}
	copyValue := *value
	return &copyValue
}

func copyKeyset(value *Keyset) *Keyset {
	if value == nil {
		return nil
	}
	copyValue := *value
	copyValue.SavedAt = copyValue.SavedAt.UTC()
	return &copyValue
}

func searchContextError(ctx context.Context) error {
	if ctx == nil {
		return ErrInvalidQuery
	}
	return ctx.Err()
}
