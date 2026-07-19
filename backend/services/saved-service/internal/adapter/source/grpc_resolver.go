package source

import (
	"context"
	"errors"
	"math"
	"strings"
	"time"
	"unicode"
	"unicode/utf8"

	"github.com/google/uuid"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/proto"
	"google.golang.org/protobuf/types/known/timestamppb"

	appsource "kz/inflap/backend/services/saved-service/internal/app/source"
	"kz/inflap/backend/services/saved-service/internal/domain"
	contentv1 "kz/inflap/proto/gen/go/content/v1"
)

const (
	maxResolveTimeout       = 2 * time.Second
	maxFutureClockSkew      = 5 * time.Second
	maxValidationAge        = 5 * time.Minute
	maxSummaryAge           = 30 * 24 * time.Hour
	maxSummaryLease         = 24 * time.Hour
	maxMediaLease           = 15 * time.Minute
	maxPublicProjectionSize = 16 * 1024
	maxCanonicalRouteBytes  = 256
	maxTitleBytes           = 256
	maxSubtitleBytes        = 512
	maxPlaceNameBytes       = 128
	maxDisplayLocationBytes = 512
	maxDynamicSummaryBytes  = 256
	maxMediaReferenceBytes  = 512
	maxRatingScale          = 100
	maxReviewCount          = uint64(9_223_372_036_854_775_807)
)

type savedSourceRPC interface {
	ResolveSaveEligibility(
		ctx context.Context,
		in *contentv1.ResolveSaveEligibilityRequest,
		opts ...grpc.CallOption,
	) (*contentv1.ResolveSaveEligibilityResponse, error)
}

// GRPCResolver adapts one authenticated source connection to the app port.
// The connection must already carry the serviceauth client interceptor.
type GRPCResolver struct {
	entityType domain.EntityType
	protoType  contentv1.SavedEntityType
	client     savedSourceRPC
	timeout    time.Duration
	now        func() time.Time
}

func NewAttractionResolver(conn grpc.ClientConnInterface) (*GRPCResolver, error) {
	return newGRPCResolverFromConn(domain.EntityTypeAttraction, conn)
}

func NewActivityResolver(conn grpc.ClientConnInterface) (*GRPCResolver, error) {
	return newGRPCResolverFromConn(domain.EntityTypeActivity, conn)
}

func NewGuideResolver(conn grpc.ClientConnInterface) (*GRPCResolver, error) {
	return newGRPCResolverFromConn(domain.EntityTypeGuide, conn)
}

func NewUserResolver(conn grpc.ClientConnInterface) (*GRPCResolver, error) {
	return newGRPCResolverFromConn(domain.EntityTypeUser, conn)
}

func NewPostResolver(conn grpc.ClientConnInterface) (*GRPCResolver, error) {
	return newGRPCResolverFromConn(domain.EntityTypePost, conn)
}

func newGRPCResolverFromConn(
	entityType domain.EntityType,
	conn grpc.ClientConnInterface,
) (*GRPCResolver, error) {
	if conn == nil {
		return nil, ErrInvalidResolverConfiguration
	}
	return newGRPCResolver(
		entityType,
		contentv1.NewSavedSourceServiceClient(conn),
		maxResolveTimeout,
		time.Now,
	)
}

func newGRPCResolver(
	entityType domain.EntityType,
	client savedSourceRPC,
	timeout time.Duration,
	now func() time.Time,
) (*GRPCResolver, error) {
	protoType, ok := toProtoEntityType(entityType)
	if !ok || client == nil || timeout <= 0 || timeout > maxResolveTimeout || now == nil {
		return nil, ErrInvalidResolverConfiguration
	}
	return &GRPCResolver{
		entityType: entityType,
		protoType:  protoType,
		client:     client,
		timeout:    timeout,
		now:        now,
	}, nil
}

func (r *GRPCResolver) Resolve(
	ctx context.Context,
	target domain.SavedTarget,
) (appsource.Resolution, error) {
	if r == nil || r.client == nil || r.now == nil || r.timeout <= 0 || r.timeout > maxResolveTimeout {
		return appsource.Resolution{}, domain.ErrDependencyUnavailable
	}
	if target.EntityType() != r.entityType {
		return appsource.Resolution{}, domain.ErrTargetTypeUnsupported
	}
	if target.IsZero() {
		return appsource.Resolution{}, domain.ErrTargetUnavailable
	}
	if err := ctx.Err(); err != nil {
		return appsource.Resolution{}, classifyContextError(err)
	}

	callCtx, cancel := context.WithTimeout(ctx, r.timeout)
	defer cancel()

	response, err := r.client.ResolveSaveEligibility(
		callCtx,
		&contentv1.ResolveSaveEligibilityRequest{Target: &contentv1.SavedTarget{
			EntityType: r.protoType,
			EntityId:   target.EntityID(),
		}},
	)
	if err != nil {
		return appsource.Resolution{}, classifyRPCError(ctx, err)
	}

	return r.validateResponse(target, response, r.now().UTC())
}

func classifyContextError(err error) error {
	if errors.Is(err, context.Canceled) {
		return context.Canceled
	}
	return domain.ErrDependencyUnavailable
}

func classifyRPCError(parent context.Context, err error) error {
	if errors.Is(parent.Err(), context.Canceled) {
		return context.Canceled
	}

	switch status.Code(err) {
	case codes.NotFound, codes.InvalidArgument:
		return domain.ErrTargetUnavailable
	default:
		return domain.ErrDependencyUnavailable
	}
}

func (r *GRPCResolver) validateResponse(
	target domain.SavedTarget,
	response *contentv1.ResolveSaveEligibilityResponse,
	now time.Time,
) (appsource.Resolution, error) {
	if response == nil || hasUnknownFields(response) {
		return appsource.Resolution{}, domain.ErrDependencyUnavailable
	}
	responseTarget := response.GetTarget()
	if responseTarget == nil || hasUnknownFields(responseTarget) ||
		responseTarget.GetEntityType() != r.protoType ||
		responseTarget.GetEntityId() != target.EntityID() {
		return appsource.Resolution{}, domain.ErrDependencyUnavailable
	}

	visibility, visibilityOK := toDomainVisibility(response.GetVisibility())
	if !visibilityOK || (visibility == domain.VisibilityPrivate && r.entityType != domain.EntityTypeActivity) {
		return appsource.Resolution{}, domain.ErrDependencyUnavailable
	}
	eligible := response.GetEligibility() == contentv1.SaveEligibility_SAVE_ELIGIBILITY_ELIGIBLE
	if (visibility == domain.VisibilityPublic) != eligible ||
		(!eligible && response.GetEligibility() != contentv1.SaveEligibility_SAVE_ELIGIBILITY_INELIGIBLE) ||
		(visibility == domain.VisibilityPublic && response.GetPublicProjection() == nil) ||
		(visibility != domain.VisibilityPublic && response.GetPublicProjection() != nil) {
		return appsource.Resolution{}, domain.ErrDependencyUnavailable
	}

	revisions := response.GetRevisions()
	if revisions == nil || hasUnknownFields(revisions) ||
		revisions.GetSourceRevision() == 0 ||
		revisions.GetProjectionRevision() == 0 ||
		revisions.GetVisibilityRevision() == 0 {
		return appsource.Resolution{}, domain.ErrDependencyUnavailable
	}
	validatedAt, ok := validatedTimestamp(response.GetValidatedAt())
	if !ok || validatedAt.After(now.Add(maxFutureClockSkew)) ||
		validatedAt.Before(now.Add(-maxValidationAge)) {
		return appsource.Resolution{}, domain.ErrDependencyUnavailable
	}

	result := appsource.Resolution{
		Target:     target,
		Eligible:   eligible,
		Visibility: visibility,
		Revisions: appsource.Revisions{
			Source:     revisions.GetSourceRevision(),
			Projection: revisions.GetProjectionRevision(),
			Visibility: revisions.GetVisibilityRevision(),
		},
		ValidatedAt: validatedAt,
	}
	if !eligible {
		return result, nil
	}

	projection, err := r.validatePublicProjection(
		target,
		response.GetPublicProjection(),
		validatedAt,
		now,
	)
	if err != nil {
		return appsource.Resolution{}, err
	}
	result.PublicProjection = projection
	return result, nil
}

func (r *GRPCResolver) validatePublicProjection(
	target domain.SavedTarget,
	projection *contentv1.SavedPublicCardProjection,
	validatedAt time.Time,
	now time.Time,
) (*appsource.PublicCardProjection, error) {
	if projection == nil || hasUnknownFields(projection) ||
		proto.Size(projection) > maxPublicProjectionSize ||
		!validCanonicalRoute(r.entityType, target.EntityID(), projection.GetCanonicalDetailRoute()) {
		return nil, domain.ErrDependencyUnavailable
	}

	defaultLocale, ok := toAppLocale(projection.GetSourceDefaultLocale())
	if !ok {
		return nil, domain.ErrDependencyUnavailable
	}
	localized := make(map[appsource.Locale]appsource.LocalizedCardProjection, 3)
	localizedInputs := []struct {
		locale appsource.Locale
		value  *contentv1.SavedLocalizedCardProjection
	}{
		{locale: appsource.LocaleEN, value: projection.GetEn()},
		{locale: appsource.LocaleRU, value: projection.GetRu()},
		{locale: appsource.LocaleKK, value: projection.GetKk()},
	}
	hasDynamicSummary := false
	for _, input := range localizedInputs {
		if input.value == nil {
			continue
		}
		value, valid := validateLocalizedProjection(input.value)
		if !valid {
			return nil, domain.ErrDependencyUnavailable
		}
		localized[input.locale] = value
		hasDynamicSummary = hasDynamicSummary ||
			value.PriceSummary != "" || value.AvailabilitySummary != ""
	}
	if _, exists := localized[defaultLocale]; !exists {
		return nil, domain.ErrDependencyUnavailable
	}

	result := &appsource.PublicCardProjection{
		SourceDefaultLocale:  defaultLocale,
		Localized:            localized,
		CanonicalDetailRoute: projection.GetCanonicalDetailRoute(),
	}

	hasRating := projection.GetRating() != nil
	if hasRating {
		rating := projection.GetRating()
		if hasUnknownFields(rating) || !validRating(rating) {
			return nil, domain.ErrDependencyUnavailable
		}
		result.Rating = &appsource.RatingSummary{
			Value:       rating.GetValue(),
			ReviewCount: rating.GetReviewCount(),
			ScaleMax:    rating.GetScaleMax(),
		}
	}

	asOf, validUntil, ok := validateSummaryWindow(
		projection.GetAsOf(),
		projection.GetValidUntil(),
		hasRating,
		hasDynamicSummary,
		validatedAt,
		now,
	)
	if !ok {
		return nil, domain.ErrDependencyUnavailable
	}
	result.AsOf = asOf
	result.ValidUntil = validUntil

	if projection.GetMedia() != nil {
		media, valid := validateMedia(projection.GetMedia(), validatedAt, now)
		if !valid {
			return nil, domain.ErrDependencyUnavailable
		}
		result.Media = media
	}
	return result, nil
}

func validateLocalizedProjection(
	projection *contentv1.SavedLocalizedCardProjection,
) (appsource.LocalizedCardProjection, bool) {
	if projection == nil || hasUnknownFields(projection) ||
		!validRequiredText(projection.GetTitle(), maxTitleBytes) ||
		!validOptionalText(projection.GetSubtitle(), maxSubtitleBytes) ||
		!validOptionalText(projection.GetCity(), maxPlaceNameBytes) ||
		!validOptionalText(projection.GetCountry(), maxPlaceNameBytes) ||
		!validOptionalText(projection.GetDisplayLocation(), maxDisplayLocationBytes) ||
		!validOptionalText(projection.GetPriceSummary(), maxDynamicSummaryBytes) ||
		!validOptionalText(projection.GetAvailabilitySummary(), maxDynamicSummaryBytes) {
		return appsource.LocalizedCardProjection{}, false
	}
	return appsource.LocalizedCardProjection{
		Title:               projection.GetTitle(),
		Subtitle:            projection.GetSubtitle(),
		City:                projection.GetCity(),
		Country:             projection.GetCountry(),
		DisplayLocation:     projection.GetDisplayLocation(),
		PriceSummary:        projection.GetPriceSummary(),
		AvailabilitySummary: projection.GetAvailabilitySummary(),
	}, true
}

func validateSummaryWindow(
	asOfTimestamp *timestamppb.Timestamp,
	validUntilTimestamp *timestamppb.Timestamp,
	hasRating bool,
	hasDynamicSummary bool,
	validatedAt time.Time,
	now time.Time,
) (*time.Time, *time.Time, bool) {
	requiresAsOf := hasRating || hasDynamicSummary
	if requiresAsOf && asOfTimestamp == nil {
		return nil, nil, false
	}
	if asOfTimestamp == nil {
		return nil, nil, validUntilTimestamp == nil
	}
	asOf, ok := validatedTimestamp(asOfTimestamp)
	if !ok || asOf.After(now.Add(maxFutureClockSkew)) ||
		asOf.After(validatedAt.Add(maxFutureClockSkew)) ||
		asOf.Before(validatedAt.Add(-maxSummaryAge)) {
		return nil, nil, false
	}
	asOfCopy := asOf

	if hasDynamicSummary && validUntilTimestamp == nil {
		return nil, nil, false
	}
	if validUntilTimestamp == nil {
		return &asOfCopy, nil, true
	}
	validUntil, ok := validatedTimestamp(validUntilTimestamp)
	if !ok || !validUntil.After(now) || !validUntil.After(asOf) ||
		validUntil.After(asOf.Add(maxSummaryLease)) {
		return nil, nil, false
	}
	validUntilCopy := validUntil
	return &asOfCopy, &validUntilCopy, true
}

func validateMedia(
	media *contentv1.SavedMediaReference,
	validatedAt time.Time,
	now time.Time,
) (*appsource.MediaReference, bool) {
	if media == nil || hasUnknownFields(media) ||
		!validRequiredText(media.GetOpaqueReference(), maxMediaReferenceBytes) ||
		media.GetReferenceRevision() == 0 {
		return nil, false
	}
	validUntil, ok := validatedTimestamp(media.GetValidUntil())
	if !ok || !validUntil.After(now) || !validUntil.After(validatedAt) ||
		validUntil.After(validatedAt.Add(maxMediaLease)) {
		return nil, false
	}
	return &appsource.MediaReference{
		OpaqueReference:   media.GetOpaqueReference(),
		ReferenceRevision: media.GetReferenceRevision(),
		ValidUntil:        validUntil,
	}, true
}

func validRating(rating *contentv1.SavedRatingSummary) bool {
	return rating != nil &&
		!math.IsNaN(rating.GetValue()) && !math.IsInf(rating.GetValue(), 0) &&
		!math.IsNaN(rating.GetScaleMax()) && !math.IsInf(rating.GetScaleMax(), 0) &&
		rating.GetScaleMax() > 0 && rating.GetScaleMax() <= maxRatingScale &&
		rating.GetValue() >= 0 && rating.GetValue() <= rating.GetScaleMax() &&
		rating.GetReviewCount() <= maxReviewCount
}

func validatedTimestamp(value *timestamppb.Timestamp) (time.Time, bool) {
	if value == nil || value.CheckValid() != nil {
		return time.Time{}, false
	}
	result := value.AsTime().UTC()
	if result.IsZero() || result.Before(time.Unix(0, 0).UTC()) {
		return time.Time{}, false
	}
	return result, true
}

func validCanonicalRoute(
	entityType domain.EntityType,
	targetID string,
	route string,
) bool {
	if route == "" || len(route) > maxCanonicalRouteBytes || !utf8.ValidString(route) ||
		route != strings.TrimSpace(route) || strings.ContainsAny(route, "?#%\\") ||
		strings.IndexFunc(route, unicode.IsControl) >= 0 {
		return false
	}

	var routeID string
	switch entityType {
	case domain.EntityTypeAttraction:
		routeID, _ = strings.CutPrefix(route, "/places/")
		if routeID == route || strings.Contains(routeID, "/") {
			return false
		}
	case domain.EntityTypeActivity:
		routeID, _ = strings.CutPrefix(route, "/activities/")
		if routeID == route || strings.Contains(routeID, "/") {
			return false
		}
	case domain.EntityTypeGuide, domain.EntityTypeUser:
		trimmed, found := strings.CutPrefix(route, "/users/")
		if !found || !strings.HasSuffix(trimmed, "/profile") {
			return false
		}
		routeID = strings.TrimSuffix(trimmed, "/profile")
		if routeID == "" || strings.Contains(routeID, "/") {
			return false
		}
	case domain.EntityTypePost:
		routeID, _ = strings.CutPrefix(route, "/posts/")
		if routeID == route || strings.Contains(routeID, "/") {
			return false
		}
	default:
		return false
	}
	parsed, err := uuid.Parse(routeID)
	return err == nil && parsed != uuid.Nil && parsed.String() == routeID && routeID == targetID
}

func validRequiredText(value string, maxBytes int) bool {
	return value != "" && validOptionalText(value, maxBytes)
}

func validOptionalText(value string, maxBytes int) bool {
	return len(value) <= maxBytes && utf8.ValidString(value) &&
		value == strings.TrimSpace(value) &&
		strings.IndexFunc(value, unicode.IsControl) < 0
}

func hasUnknownFields(message proto.Message) bool {
	return message != nil && len(message.ProtoReflect().GetUnknown()) != 0
}

func toProtoEntityType(entityType domain.EntityType) (contentv1.SavedEntityType, bool) {
	switch entityType {
	case domain.EntityTypeAttraction:
		return contentv1.SavedEntityType_SAVED_ENTITY_TYPE_ATTRACTION, true
	case domain.EntityTypeActivity:
		return contentv1.SavedEntityType_SAVED_ENTITY_TYPE_ACTIVITY, true
	case domain.EntityTypeGuide:
		return contentv1.SavedEntityType_SAVED_ENTITY_TYPE_GUIDE, true
	case domain.EntityTypeUser:
		return contentv1.SavedEntityType_SAVED_ENTITY_TYPE_USER, true
	case domain.EntityTypePost:
		return contentv1.SavedEntityType_SAVED_ENTITY_TYPE_POST, true
	default:
		return contentv1.SavedEntityType_SAVED_ENTITY_TYPE_UNSPECIFIED, false
	}
}

func toDomainVisibility(
	visibility contentv1.SavedTargetVisibility,
) (domain.VisibilityStatus, bool) {
	switch visibility {
	case contentv1.SavedTargetVisibility_SAVED_TARGET_VISIBILITY_PUBLIC:
		return domain.VisibilityPublic, true
	case contentv1.SavedTargetVisibility_SAVED_TARGET_VISIBILITY_PRIVATE:
		return domain.VisibilityPrivate, true
	case contentv1.SavedTargetVisibility_SAVED_TARGET_VISIBILITY_UNAVAILABLE:
		return domain.VisibilityUnavailable, true
	case contentv1.SavedTargetVisibility_SAVED_TARGET_VISIBILITY_DELETED:
		return domain.VisibilityDeleted, true
	case contentv1.SavedTargetVisibility_SAVED_TARGET_VISIBILITY_RESTRICTED:
		return domain.VisibilityRestricted, true
	default:
		return domain.VisibilityUnknown, false
	}
}

func toAppLocale(locale contentv1.SavedLocale) (appsource.Locale, bool) {
	switch locale {
	case contentv1.SavedLocale_SAVED_LOCALE_EN:
		return appsource.LocaleEN, true
	case contentv1.SavedLocale_SAVED_LOCALE_RU:
		return appsource.LocaleRU, true
	case contentv1.SavedLocale_SAVED_LOCALE_KK:
		return appsource.LocaleKK, true
	default:
		return "", false
	}
}
