package app

import (
	"context"
	"errors"
	"fmt"
	"math"
	"sort"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"

	"github.com/dkhvan-dev/flyfy/backend/services/excursion-service/internal/domain/enum"
	"github.com/dkhvan-dev/flyfy/backend/services/excursion-service/internal/domain/model"
	"github.com/dkhvan-dev/flyfy/backend/services/excursion-service/internal/domain/port"
)

type ExcursionAggregate struct {
	Excursion          *model.Excursion
	Tags               []string
	LanguageCodes      []string
	IncludedItems      []model.ExcursionIncludedItem
	Itinerary          []*model.ExcursionItineraryItem
	CoverFileID        *uuid.UUID
	ProductCoverFileID *uuid.UUID
}

type ExcursionProductCardAggregate struct {
	Product *model.ExcursionProductCard
}

type ExcursionOfferAggregate struct {
	Offer         *model.ExcursionOffer
	LanguageCodes []string
	IncludedItems []model.ExcursionIncludedItem
	Itinerary     []*model.ExcursionItineraryItem
}

type ExcursionUseCase struct {
	repo                    port.ExcursionRepository
	guideVerifier           port.GuideVerifier
	fileManager             port.ExcursionCoverFileManager
	translator              port.ExcursionTranslator
	userProfiles            port.UserProfileResolver
	attractionRatingUpdater port.AttractionRatingUpdater
	chatGateway             port.ExcursionChatGateway
	attendanceQRSigningKey  []byte
	attendanceQRTTL         time.Duration
	attendanceOfflineWindow time.Duration
}

const (
	excursionScheduleBookingLeadTime            = 2 * time.Hour
	excursionScheduleSetupLeadTime              = 3 * time.Hour
	excursionAttendanceQRLeadTime               = time.Hour
	excursionScheduleAutoCancelReasonNoBookings = "NO_BOOKINGS_BEFORE_START_2H"
	excursionScheduleAutoCompleteReasonEnded    = "SLOT_END_REACHED"
	attractionRatingSourceExcursionReviews      = "excursion_reviews"

	excursionBookingRefundPolicyFull24H    = "FULL_REFUND_BEFORE_24H"
	excursionBookingRefundPolicyPartial12H = "PARTIAL_REFUND_BEFORE_12H"
	excursionBookingRefundPolicyPartial6H  = "PARTIAL_REFUND_BEFORE_6H"
	excursionBookingRefundPolicyPartial2H  = "PARTIAL_REFUND_BEFORE_2H"
	excursionBookingRefundPolicyNoRefund2H = "NO_REFUND_INSIDE_2H"

	excursionBookingRefundStatusPendingPaymentIntegration = "PENDING_PAYMENT_INTEGRATION"
	excursionBookingRefundStatusNotRefundable             = "NOT_REFUNDABLE"

	defaultExcursionAttendanceQRSigningSecret = "dev-excursion-attendance-qr-secret"

	excursionAutoPublishTrustThreshold = 70
	excursionAutoPublishRiskThreshold  = 30

	AttendanceSyncStatusSynced        = "SYNCED"
	AttendanceSyncStatusAlreadySynced = "ALREADY_SYNCED"
	AttendanceSyncStatusRejected      = "REJECTED"
	AttendanceSyncStatusRetryable     = "RETRYABLE"
)

func NewExcursionUseCase(
	repo port.ExcursionRepository,
	guideVerifier port.GuideVerifier,
	fileManager port.ExcursionCoverFileManager,
	translators ...port.ExcursionTranslator,
) *ExcursionUseCase {
	var translator port.ExcursionTranslator
	if len(translators) > 0 {
		translator = translators[0]
	}
	return &ExcursionUseCase{
		repo:                    repo,
		guideVerifier:           guideVerifier,
		fileManager:             fileManager,
		translator:              translator,
		attendanceQRSigningKey:  []byte(defaultExcursionAttendanceQRSigningSecret),
		attendanceQRTTL:         45 * time.Second,
		attendanceOfflineWindow: 6 * time.Hour,
	}
}

func (u *ExcursionUseCase) WithUserProfileResolver(resolver port.UserProfileResolver) *ExcursionUseCase {
	u.userProfiles = resolver
	return u
}

func (u *ExcursionUseCase) WithAttractionRatingUpdater(updater port.AttractionRatingUpdater) *ExcursionUseCase {
	u.attractionRatingUpdater = updater
	return u
}

func (u *ExcursionUseCase) WithExcursionChatGateway(chatGateway port.ExcursionChatGateway) *ExcursionUseCase {
	u.chatGateway = chatGateway
	return u
}

func (u *ExcursionUseCase) WithAttendanceQRConfig(secret string, ttl time.Duration, offlineWindow time.Duration) *ExcursionUseCase {
	secret = strings.TrimSpace(secret)
	if secret == "" {
		secret = defaultExcursionAttendanceQRSigningSecret
	}
	if ttl <= 0 {
		ttl = 45 * time.Second
	}
	if offlineWindow <= ttl {
		offlineWindow = 6 * time.Hour
	}
	u.attendanceQRSigningKey = []byte(secret)
	u.attendanceQRTTL = ttl
	u.attendanceOfflineWindow = offlineWindow
	return u
}

type ExcursionItineraryItemInput struct {
	StartOffsetMinutes        int
	DurationMinutes           *int
	AttractionID              *uuid.UUID
	AttractionName            *string
	Latitude                  *float64
	Longitude                 *float64
	TravelFromPreviousMinutes *int
	Title                     string
	Description               string
	Translations              model.ExcursionItineraryTranslations
}

type ExcursionIncludedItemInput struct {
	Text         string
	Translations model.ExcursionLocalizedText
}

type itineraryTranslationJob struct {
	itemIndex      int
	missingLocales []string
	sourceCopy     model.ExcursionItineraryLocalizedCopy
}

type CreateExcursionInput struct {
	ActorUserID         uuid.UUID
	LandmarkID          *uuid.UUID
	LandmarkName        *string
	CategorySlug        string
	ProductTranslations model.ExcursionTranslations
	Visibility          string
	DurationMinutes     int
	MaxGroupSize        int
	LanguageCodes       []string
	CountryCode         *string
	CityName            *string
	DepartureCityID     *string
	MeetingPoint        string
	Latitude            *float64
	Longitude           *float64
	MapURL              *string
	PriceAmount         float64
	Currency            string
	CoverFileID         *uuid.UUID
	ProductCoverFileID  *uuid.UUID
	IncludedItems       []ExcursionIncludedItemInput
	Itinerary           []ExcursionItineraryItemInput
}

type UpdateExcursionInput struct {
	ActorUserID         uuid.UUID
	ExcursionID         uuid.UUID
	LandmarkID          *uuid.UUID
	LandmarkName        *string
	CategorySlug        string
	ProductTranslations model.ExcursionTranslations
	Visibility          string
	DurationMinutes     int
	MaxGroupSize        int
	LanguageCodes       []string
	CountryCode         *string
	CityName            *string
	DepartureCityID     *string
	MeetingPoint        string
	Latitude            *float64
	Longitude           *float64
	MapURL              *string
	PriceAmount         float64
	Currency            string
	CoverFileID         *uuid.UUID
	ProductCoverFileID  *uuid.UUID
	IncludedItems       []ExcursionIncludedItemInput
	Itinerary           []ExcursionItineraryItemInput
}

type CreateExcursionBookingInput struct {
	ActorUserID    uuid.UUID
	ProductID      uuid.UUID
	OfferID        uuid.UUID
	ScheduleSlotID *uuid.UUID
	ScheduledFor   time.Time
	Adults         int
	Children       int
	IdempotencyKey *string
}

type UpdateExcursionBookingGuestsInput struct {
	ActorUserID uuid.UUID
	BookingID   uuid.UUID
	Adults      int
	Children    int
}

type CancelExcursionBookingInput struct {
	ActorUserID uuid.UUID
	BookingID   uuid.UUID
	Reason      string
}

type ExcursionBookingCancellationRefundQuote struct {
	Percent    int
	Amount     float64
	Currency   string
	PolicyCode string
	Status     string
}

type CreateGuideScheduleSlotInput struct {
	ActorUserID uuid.UUID
	OfferID     uuid.UUID
	StartAt     time.Time
	Timezone    string
	Capacity    int
}

type UpdateGuideScheduleSlotInput struct {
	ActorUserID uuid.UUID
	SlotID      uuid.UUID
	OfferID     uuid.UUID
	StartAt     time.Time
	Timezone    string
	Capacity    int
}

type CreateGuideScheduleSeriesInput struct {
	ActorUserID     uuid.UUID
	OfferID         uuid.UUID
	StartsOn        time.Time
	EndsOn          *time.Time
	OccurrenceLimit *int
	StartTime       string
	Timezone        string
	Weekdays        []int
	Capacity        int
}

type ListGuideScheduleInput struct {
	ActorUserID uuid.UUID
	From        time.Time
	To          time.Time
}

type ListPublicGuideScheduleInput struct {
	GuideUserID uuid.UUID
	From        time.Time
	To          time.Time
}

type ListPublicExcursionScheduleInput struct {
	ProductID uuid.UUID
	OfferID   uuid.UUID
	From      time.Time
	To        time.Time
	Seats     int
}

type CreateExcursionReviewInput struct {
	ActorUserID uuid.UUID
	BookingID   uuid.UUID
	Rating      float64
	Comment     string
}

type ReviewMutationInput struct {
	Rating  float64
	Comment string
	Delete  bool
}

type SaveBookingReviewsInput struct {
	ActorUserID     uuid.UUID
	BookingID       uuid.UUID
	ExcursionReview *ReviewMutationInput
	GuideReview     *ReviewMutationInput
}

type BookingReviewsResult struct {
	ExcursionReview *model.ExcursionReview
	GuideReview     *model.GuideReview
}

type reviewMutationRepository interface {
	CreateExcursionReview(ctx context.Context, item *model.ExcursionReview) error
	UpdateExcursionReview(ctx context.Context, item *model.ExcursionReview) error
	DeleteExcursionReview(ctx context.Context, item *model.ExcursionReview) error
	GetExcursionReviewByBookingID(ctx context.Context, bookingID uuid.UUID) (*model.ExcursionReview, error)
	CreateGuideReview(ctx context.Context, item *model.GuideReview) error
	UpdateGuideReview(ctx context.Context, item *model.GuideReview) error
	DeleteGuideReview(ctx context.Context, item *model.GuideReview) error
	GetGuideReviewByBookingID(ctx context.Context, bookingID uuid.UUID) (*model.GuideReview, error)
}

type ExcursionAttendanceQRData struct {
	ScheduleSlotID string
	Token          string
	ExpiresAt      time.Time
	RefreshAt      time.Time
}

type ExcursionAttendanceProofInput struct {
	ScanID          uuid.UUID
	QRToken         string
	InstallationID  string
	ScannedAtDevice *time.Time
}

type ExcursionAttendanceSyncItemResult struct {
	ScanID         uuid.UUID
	ScheduleSlotID *uuid.UUID
	Status         string
	Code           string
	Message        string
	CheckedInAt    *time.Time
	SyncedAt       time.Time
}

func (u *ExcursionUseCase) CreateExcursion(ctx context.Context, input CreateExcursionInput) (*ExcursionAggregate, error) {
	if input.ActorUserID == uuid.Nil {
		return nil, ErrInvalidActorUserID
	}

	permission, err := u.verifyGuide(ctx, input.ActorUserID)
	if err != nil {
		return nil, err
	}
	if !permission.Allowed {
		return nil, ErrGuideNotAllowed
	}
	landmarkID := normalizeUUIDPtr(input.LandmarkID)
	landmarkName := input.LandmarkName
	if landmarkID == nil {
		landmarkName = nil
	}
	if err = validateCombinedRouteInput(landmarkID, input.Itinerary); err != nil {
		return nil, err
	}
	if landmarkID != nil {
		exists, err := u.repo.HasActiveExcursionForGuideLandmark(ctx, permission.GuideUserID, *landmarkID)
		if err != nil {
			return nil, err
		}
		if exists {
			return nil, model.ErrExcursionGuideLandmarkAlreadyExists
		}
	}

	if err = u.validateCoverFiles(ctx, input.CoverFileID, input.ProductCoverFileID); err != nil {
		return nil, err
	}
	marketingCopy := attractionBasedExcursionCopy(landmarkName)
	if landmarkID == nil {
		marketingCopy = combinedRouteMarketingCopy(input)
	}
	categorySlug := model.NormalizeSlug(input.CategorySlug)
	if categorySlug == "" {
		categorySlug = "sightseeing"
	}

	item, err := model.NewExcursion(model.NewExcursionParams{
		GuideProfileID:       permission.GuideProfileID,
		GuideUserID:          permission.GuideUserID,
		GuideRatingAvg:       permission.RatingAvg,
		GuideReviewsCount:    permission.ReviewsCount,
		GuideExperienceYears: permission.ExperienceYears,
		GuideDisplayName:     permission.DisplayName,
		GuideNickname:        permission.Nickname,
		GuideFirstName:       permission.FirstName,
		GuideLastName:        permission.LastName,
		GuideSearchText:      permission.GuideSearchText,
		LandmarkID:           landmarkID,
		LandmarkName:         landmarkName,
		Title:                marketingCopy.Title,
		Summary:              marketingCopy.Summary,
		Description:          marketingCopy.Description,
		Translations:         nil,
		CategorySlug:         categorySlug,
		ProductTranslations:  input.ProductTranslations,
		Visibility:           enum.ExcursionVisibility(strings.TrimSpace(input.Visibility)),
		DurationMinutes:      input.DurationMinutes,
		MaxGroupSize:         input.MaxGroupSize,
		CountryCode:          input.CountryCode,
		CityName:             input.CityName,
		DepartureCityID:      input.DepartureCityID,
		MeetingPoint:         input.MeetingPoint,
		Latitude:             input.Latitude,
		Longitude:            input.Longitude,
		MapURL:               input.MapURL,
		PriceAmount:          input.PriceAmount,
		Currency:             input.Currency,
	})
	if err != nil {
		return nil, err
	}

	itinerary, err := u.translateItinerary(ctx, input.Itinerary)
	if err != nil {
		return nil, err
	}
	relations, err := buildRelations(item.ID, nil, input.LanguageCodes, input.IncludedItems, input.CoverFileID, input.ProductCoverFileID, itinerary)
	if err != nil {
		return nil, err
	}

	if err = u.repo.CreateExcursionAggregate(ctx, item, relations); err != nil {
		return nil, fmt.Errorf("create excursion aggregate: %w", err)
	}
	u.bindCoverFile(ctx, item.ID, input.ActorUserID, input.CoverFileID)
	u.recordEvent(ctx, item.ID, enum.ExcursionEventTypeCreated, input.ActorUserID, map[string]any{"status": string(item.Status)})

	return &ExcursionAggregate{
		Excursion:          item,
		Tags:               relations.Tags,
		LanguageCodes:      relations.LanguageCodes,
		IncludedItems:      relations.IncludedItems,
		Itinerary:          relations.Itinerary,
		CoverFileID:        relations.CoverFileID,
		ProductCoverFileID: relations.ProductCoverFileID,
	}, nil
}

func (u *ExcursionUseCase) UpdateExcursion(ctx context.Context, input UpdateExcursionInput) (*ExcursionAggregate, error) {
	if input.ActorUserID == uuid.Nil {
		return nil, ErrInvalidActorUserID
	}
	if input.ExcursionID == uuid.Nil {
		return nil, ErrInvalidExcursionID
	}

	item, err := u.repo.GetExcursionByID(ctx, input.ExcursionID)
	if err != nil {
		return nil, fmt.Errorf("get excursion by id: %w", err)
	}
	if item == nil {
		return nil, ErrExcursionNotFound
	}
	if !item.IsOwnedBy(input.ActorUserID) {
		return nil, ErrExcursionAccessDenied
	}
	permission, err := u.verifyGuide(ctx, input.ActorUserID)
	if err != nil {
		return nil, err
	}
	item.ApplyGuideSnapshot(
		permission.RatingAvg,
		permission.ReviewsCount,
		permission.ExperienceYears,
		permission.DisplayName,
		permission.Nickname,
		permission.FirstName,
		permission.LastName,
		permission.GuideSearchText,
	)
	if err = u.validateCoverFiles(ctx, input.CoverFileID, input.ProductCoverFileID); err != nil {
		return nil, err
	}
	inputLandmarkID := normalizeUUIDPtr(input.LandmarkID)
	effectiveLandmarkID := inputLandmarkID
	effectiveLandmarkName := input.LandmarkName
	if input.LandmarkID == nil && !hasItineraryAttractionStops(input.Itinerary) {
		effectiveLandmarkID = normalizeUUIDPtr(item.LandmarkID)
		effectiveLandmarkName = item.LandmarkName
	}
	if effectiveLandmarkID == nil {
		effectiveLandmarkName = nil
	} else if effectiveLandmarkName == nil {
		effectiveLandmarkName = item.LandmarkName
	}
	if err = validateCombinedRouteInput(effectiveLandmarkID, input.Itinerary); err != nil {
		return nil, err
	}
	marketingCopy := attractionBasedExcursionCopy(effectiveLandmarkName)
	if effectiveLandmarkID == nil || *effectiveLandmarkID == uuid.Nil {
		marketingCopy = combinedRouteMarketingCopy(CreateExcursionInput{Itinerary: input.Itinerary})
	}

	if err = item.ApplyUpdate(model.UpdateExcursionParams{
		LandmarkID:          effectiveLandmarkID,
		LandmarkName:        effectiveLandmarkName,
		Title:               marketingCopy.Title,
		Summary:             marketingCopy.Summary,
		Description:         marketingCopy.Description,
		Translations:        nil,
		CategorySlug:        input.CategorySlug,
		ProductTranslations: input.ProductTranslations,
		Visibility:          enum.ExcursionVisibility(strings.TrimSpace(input.Visibility)),
		DurationMinutes:     input.DurationMinutes,
		MaxGroupSize:        input.MaxGroupSize,
		CountryCode:         input.CountryCode,
		CityName:            input.CityName,
		DepartureCityID:     input.DepartureCityID,
		MeetingPoint:        input.MeetingPoint,
		Latitude:            input.Latitude,
		Longitude:           input.Longitude,
		MapURL:              input.MapURL,
		PriceAmount:         input.PriceAmount,
		Currency:            input.Currency,
	}); err != nil {
		return nil, err
	}

	itinerary, err := u.translateItinerary(ctx, input.Itinerary)
	if err != nil {
		return nil, err
	}
	relations, err := buildRelations(item.ID, nil, input.LanguageCodes, input.IncludedItems, input.CoverFileID, input.ProductCoverFileID, itinerary)
	if err != nil {
		return nil, err
	}
	if item.Status == enum.ExcursionStatusPublished {
		if err = item.ValidatePublishable(model.PublishExcursionParams{LanguageCodes: relations.LanguageCodes, Itinerary: relations.Itinerary}); err != nil {
			return nil, err
		}
	}

	if err = u.repo.UpdateExcursionAggregate(ctx, item, relations); err != nil {
		return nil, fmt.Errorf("update excursion aggregate: %w", err)
	}
	u.bindCoverFile(ctx, item.ID, input.ActorUserID, input.CoverFileID)
	u.recordEvent(ctx, item.ID, enum.ExcursionEventTypeUpdated, input.ActorUserID, map[string]any{"revision": item.Revision})

	return &ExcursionAggregate{
		Excursion:          item,
		Tags:               relations.Tags,
		LanguageCodes:      relations.LanguageCodes,
		IncludedItems:      relations.IncludedItems,
		Itinerary:          relations.Itinerary,
		CoverFileID:        relations.CoverFileID,
		ProductCoverFileID: relations.ProductCoverFileID,
	}, nil
}

func (u *ExcursionUseCase) PublishExcursion(ctx context.Context, excursionID uuid.UUID, actorUserID uuid.UUID) (*ExcursionAggregate, error) {
	item, relations, err := u.getOwnedExcursionWithRelations(ctx, excursionID, actorUserID)
	if err != nil {
		return nil, err
	}
	permission, err := u.verifyGuide(ctx, actorUserID)
	if err != nil {
		return nil, err
	}
	item.ApplyGuideSnapshot(
		permission.RatingAvg,
		permission.ReviewsCount,
		permission.ExperienceYears,
		permission.DisplayName,
		permission.Nickname,
		permission.FirstName,
		permission.LastName,
		permission.GuideSearchText,
	)
	publishParams := model.PublishExcursionParams{
		LanguageCodes: relations.LanguageCodes,
		Itinerary:     relations.Itinerary,
	}
	evaluation := evaluateExcursionPublishing(item, permission)
	if evaluation.Decision == model.ExcursionPublishingDecisionNeedsReview {
		if err = item.SubmitForReview(model.SubmitExcursionForReviewParams{
			Publish:    publishParams,
			Evaluation: evaluation,
		}); err != nil {
			return nil, err
		}
		if err = u.repo.UpdateExcursionAggregate(ctx, item, relations); err != nil {
			return nil, fmt.Errorf("submit excursion for review: %w", err)
		}
		u.recordEvent(ctx, item.ID, enum.ExcursionEventTypeSubmittedForReview, actorUserID, map[string]any{
			"submittedForReviewAt": item.SubmittedForReviewAt,
			"guideTrustScore":      item.GuideTrustScore,
			"publishRiskScore":     item.PublishRiskScore,
			"reasonCodes":          item.ModerationReasonCodes,
		})
		return &ExcursionAggregate{Excursion: item, Tags: relations.Tags, LanguageCodes: relations.LanguageCodes, IncludedItems: relations.IncludedItems, Itinerary: relations.Itinerary, CoverFileID: relations.CoverFileID, ProductCoverFileID: relations.ProductCoverFileID}, nil
	}
	if err = item.ApplyPublishingEvaluation(evaluation); err != nil {
		return nil, err
	}
	if err = item.Publish(publishParams); err != nil {
		return nil, err
	}
	if err = u.repo.UpdateExcursionAggregate(ctx, item, relations); err != nil {
		return nil, fmt.Errorf("publish excursion: %w", err)
	}
	u.recordEvent(ctx, item.ID, enum.ExcursionEventTypePublished, actorUserID, map[string]any{"publishedAt": item.PublishedAt})

	return &ExcursionAggregate{Excursion: item, Tags: relations.Tags, LanguageCodes: relations.LanguageCodes, IncludedItems: relations.IncludedItems, Itinerary: relations.Itinerary, CoverFileID: relations.CoverFileID, ProductCoverFileID: relations.ProductCoverFileID}, nil
}

func (u *ExcursionUseCase) ApproveExcursionModeration(ctx context.Context, excursionID uuid.UUID, moderatorUserID uuid.UUID) (*ExcursionAggregate, error) {
	if excursionID == uuid.Nil {
		return nil, ErrInvalidExcursionID
	}
	if moderatorUserID == uuid.Nil {
		return nil, ErrInvalidActorUserID
	}
	item, err := u.repo.GetExcursionByID(ctx, excursionID)
	if err != nil {
		return nil, fmt.Errorf("get excursion by id: %w", err)
	}
	if item == nil {
		return nil, ErrExcursionNotFound
	}
	relations, err := u.repo.LoadExcursionRelations(ctx, excursionID)
	if err != nil {
		return nil, fmt.Errorf("load excursion relations: %w", err)
	}
	publishParams := model.PublishExcursionParams{
		LanguageCodes: relations.LanguageCodes,
		Itinerary:     relations.Itinerary,
	}
	if err = item.ApproveReview(publishParams); err != nil {
		return nil, err
	}
	if err = u.repo.UpdateExcursionAggregate(ctx, item, relations); err != nil {
		return nil, fmt.Errorf("approve excursion moderation: %w", err)
	}
	u.recordEvent(ctx, item.ID, enum.ExcursionEventTypeModerationApproved, moderatorUserID, map[string]any{"publishedAt": item.PublishedAt})

	return &ExcursionAggregate{Excursion: item, Tags: relations.Tags, LanguageCodes: relations.LanguageCodes, IncludedItems: relations.IncludedItems, Itinerary: relations.Itinerary, CoverFileID: relations.CoverFileID, ProductCoverFileID: relations.ProductCoverFileID}, nil
}

func (u *ExcursionUseCase) RejectExcursionModeration(ctx context.Context, excursionID uuid.UUID, moderatorUserID uuid.UUID, reasonCodes []string) (*ExcursionAggregate, error) {
	if excursionID == uuid.Nil {
		return nil, ErrInvalidExcursionID
	}
	if moderatorUserID == uuid.Nil {
		return nil, ErrInvalidActorUserID
	}
	item, err := u.repo.GetExcursionByID(ctx, excursionID)
	if err != nil {
		return nil, fmt.Errorf("get excursion by id: %w", err)
	}
	if item == nil {
		return nil, ErrExcursionNotFound
	}
	relations, err := u.repo.LoadExcursionRelations(ctx, excursionID)
	if err != nil {
		return nil, fmt.Errorf("load excursion relations: %w", err)
	}
	if err = item.RejectReview(reasonCodes); err != nil {
		return nil, err
	}
	if err = u.repo.UpdateExcursionAggregate(ctx, item, relations); err != nil {
		return nil, fmt.Errorf("reject excursion moderation: %w", err)
	}
	u.recordEvent(ctx, item.ID, enum.ExcursionEventTypeModerationRejected, moderatorUserID, map[string]any{"reasonCodes": item.ModerationReasonCodes})

	return &ExcursionAggregate{Excursion: item, Tags: relations.Tags, LanguageCodes: relations.LanguageCodes, IncludedItems: relations.IncludedItems, Itinerary: relations.Itinerary, CoverFileID: relations.CoverFileID, ProductCoverFileID: relations.ProductCoverFileID}, nil
}

func (u *ExcursionUseCase) ArchiveExcursion(ctx context.Context, excursionID uuid.UUID, actorUserID uuid.UUID) (*ExcursionAggregate, error) {
	item, relations, err := u.getOwnedExcursionWithRelations(ctx, excursionID, actorUserID)
	if err != nil {
		return nil, err
	}
	if err = item.MoveToArchive(); err != nil {
		return nil, err
	}
	if err = u.repo.UpdateExcursionAggregate(ctx, item, relations); err != nil {
		return nil, fmt.Errorf("archive excursion: %w", err)
	}
	u.recordEvent(ctx, item.ID, enum.ExcursionEventTypeArchived, actorUserID, map[string]any{"archivedAt": item.UpdatedAt})

	return &ExcursionAggregate{Excursion: item, Tags: relations.Tags, LanguageCodes: relations.LanguageCodes, IncludedItems: relations.IncludedItems, Itinerary: relations.Itinerary, CoverFileID: relations.CoverFileID, ProductCoverFileID: relations.ProductCoverFileID}, nil
}

func (u *ExcursionUseCase) ArchiveGuideExcursionOffers(ctx context.Context, guideUserID uuid.UUID) error {
	if guideUserID == uuid.Nil {
		return ErrGuideNotAllowed
	}
	if err := u.repo.ArchiveGuideExcursionOffers(ctx, guideUserID); err != nil {
		return fmt.Errorf("archive guide excursion offers: %w", err)
	}
	return nil
}

func (u *ExcursionUseCase) DeleteExcursion(ctx context.Context, excursionID uuid.UUID, actorUserID uuid.UUID) error {
	item, relations, err := u.getOwnedExcursionWithRelations(ctx, excursionID, actorUserID)
	if err != nil {
		return err
	}
	if err = item.Archive(); err != nil {
		return err
	}
	if err = u.repo.UpdateExcursionAggregate(ctx, item, relations); err != nil {
		return fmt.Errorf("delete excursion: %w", err)
	}
	u.recordEvent(ctx, item.ID, enum.ExcursionEventTypeDeleted, actorUserID, map[string]any{"deletedAt": item.DeletedAt})
	return nil
}

func (u *ExcursionUseCase) GetPublicExcursion(ctx context.Context, excursionID uuid.UUID) (*ExcursionAggregate, error) {
	if excursionID == uuid.Nil {
		return nil, ErrInvalidExcursionID
	}
	item, err := u.repo.GetExcursionByID(ctx, excursionID)
	if err != nil {
		return nil, fmt.Errorf("get excursion by id: %w", err)
	}
	if item == nil || !item.IsPubliclyReadable() {
		return nil, ErrExcursionNotFound
	}
	return u.loadAggregate(ctx, item)
}

func (u *ExcursionUseCase) GetModerationExcursion(ctx context.Context, excursionID uuid.UUID) (*ExcursionAggregate, error) {
	if excursionID == uuid.Nil {
		return nil, ErrInvalidExcursionID
	}
	item, err := u.repo.GetExcursionByID(ctx, excursionID)
	if err != nil {
		return nil, fmt.Errorf("get moderation excursion by id: %w", err)
	}
	if item == nil || item.DeletedAt != nil {
		return nil, ErrExcursionNotFound
	}
	return u.loadAggregate(ctx, item)
}

func (u *ExcursionUseCase) GetMyExcursion(ctx context.Context, excursionID uuid.UUID, actorUserID uuid.UUID) (*ExcursionAggregate, error) {
	item, relations, err := u.getOwnedExcursionWithRelations(ctx, excursionID, actorUserID)
	if err != nil {
		return nil, err
	}
	return &ExcursionAggregate{Excursion: item, Tags: relations.Tags, LanguageCodes: relations.LanguageCodes, IncludedItems: relations.IncludedItems, Itinerary: relations.Itinerary, CoverFileID: relations.CoverFileID, ProductCoverFileID: relations.ProductCoverFileID}, nil
}

func (u *ExcursionUseCase) ListExcursions(ctx context.Context, filter port.ExcursionFilter) ([]*ExcursionAggregate, error) {
	if filter.Limit <= 0 {
		filter.Limit = 20
	}
	if filter.Limit > 100 {
		filter.Limit = 100
	}
	filter.Statuses = []string{string(enum.ExcursionStatusPublished)}
	items, err := u.repo.ListExcursions(ctx, filter)
	if err != nil {
		return nil, fmt.Errorf("list excursions: %w", err)
	}
	return u.loadAggregates(ctx, items)
}

func (u *ExcursionUseCase) ListPendingReviewExcursions(ctx context.Context, limit int, offset int) ([]*ExcursionAggregate, error) {
	if limit <= 0 {
		limit = 20
	}
	if limit > 100 {
		limit = 100
	}
	if offset < 0 {
		offset = 0
	}
	items, err := u.repo.ListExcursions(ctx, port.ExcursionFilter{
		Statuses: []string{string(enum.ExcursionStatusPendingReview)},
		Limit:    limit,
		Offset:   offset,
	})
	if err != nil {
		return nil, fmt.Errorf("list pending review excursions: %w", err)
	}
	return u.loadAggregates(ctx, items)
}

func (u *ExcursionUseCase) ListExcursionProducts(ctx context.Context, filter port.ExcursionProductFilter) ([]*ExcursionProductCardAggregate, error) {
	if filter.Limit <= 0 {
		filter.Limit = 20
	}
	if filter.Limit > 100 {
		filter.Limit = 100
	}
	items, err := u.repo.ListExcursionProductCards(ctx, filter)
	if err != nil {
		return nil, fmt.Errorf("list excursion products: %w", err)
	}
	return toProductCardAggregates(items), nil
}

func (u *ExcursionUseCase) GetExcursionProduct(ctx context.Context, productID uuid.UUID) (*ExcursionProductCardAggregate, error) {
	if productID == uuid.Nil {
		return nil, ErrInvalidExcursionID
	}
	item, err := u.repo.GetExcursionProductCardByID(ctx, productID)
	if err != nil {
		return nil, fmt.Errorf("get excursion product: %w", err)
	}
	if item == nil {
		return nil, ErrExcursionNotFound
	}
	return &ExcursionProductCardAggregate{Product: item}, nil
}

func (u *ExcursionUseCase) ListExcursionProductOffers(ctx context.Context, filter port.ExcursionOfferFilter) ([]*ExcursionOfferAggregate, error) {
	if filter.ProductID == uuid.Nil {
		return nil, ErrInvalidExcursionID
	}
	if filter.Limit <= 0 {
		filter.Limit = 20
	}
	if filter.Limit > 100 {
		filter.Limit = 100
	}
	offers, err := u.repo.ListExcursionOffers(ctx, filter)
	if err != nil {
		return nil, fmt.Errorf("list excursion offers: %w", err)
	}
	result := make([]*ExcursionOfferAggregate, 0, len(offers))
	for _, offer := range offers {
		if offer == nil {
			continue
		}
		relations, relErr := u.repo.LoadExcursionOfferRelations(ctx, offer.ID)
		if relErr != nil {
			return nil, fmt.Errorf("load excursion offer relations: %w", relErr)
		}
		result = append(result, &ExcursionOfferAggregate{
			Offer:         offer,
			LanguageCodes: relations.LanguageCodes,
			IncludedItems: relations.IncludedItems,
			Itinerary:     relations.Itinerary,
		})
	}
	return result, nil
}

func (u *ExcursionUseCase) ListGuideExcursionLanguageCodes(ctx context.Context, guideUserIDs []uuid.UUID) (map[uuid.UUID][]string, error) {
	normalizedIDs := uniqueUUIDs(guideUserIDs)
	if len(normalizedIDs) == 0 {
		return map[uuid.UUID][]string{}, nil
	}
	languages, err := u.repo.ListExcursionLanguageCodesByGuideUserIDs(ctx, normalizedIDs)
	if err != nil {
		return nil, fmt.Errorf("list guide excursion languages: %w", err)
	}
	return languages, nil
}

func (u *ExcursionUseCase) ListGuideUserIDsByExcursionCity(ctx context.Context, filter port.GuideExcursionCityFilter) ([]uuid.UUID, error) {
	filter = normalizeGuideExcursionCityFilter(filter)
	if filter.CityName == nil {
		return []uuid.UUID{}, nil
	}

	guideUserIDs, err := u.repo.ListGuideUserIDsByExcursionCity(ctx, filter)
	if err != nil {
		return nil, fmt.Errorf("list guide user ids by excursion city: %w", err)
	}
	return uniqueUUIDs(guideUserIDs), nil
}

func normalizeGuideExcursionCityFilter(filter port.GuideExcursionCityFilter) port.GuideExcursionCityFilter {
	if filter.CityName != nil {
		cityName := strings.TrimSpace(*filter.CityName)
		if cityName == "" {
			filter.CityName = nil
		} else {
			filter.CityName = &cityName
		}
	}
	if filter.CountryCode != nil {
		countryCode := strings.ToUpper(strings.TrimSpace(*filter.CountryCode))
		if countryCode == "" {
			filter.CountryCode = nil
		} else {
			filter.CountryCode = &countryCode
		}
	}
	return filter
}

func (u *ExcursionUseCase) CreateGuideScheduleSlot(ctx context.Context, input CreateGuideScheduleSlotInput) (*model.ExcursionScheduleSlot, error) {
	if input.ActorUserID == uuid.Nil {
		return nil, ErrInvalidActorUserID
	}
	if input.OfferID == uuid.Nil {
		return nil, ErrInvalidExcursionID
	}
	offer, err := u.getExcursionOfferForSchedule(ctx, input.OfferID)
	if err != nil {
		return nil, err
	}
	if offer == nil {
		return nil, ErrExcursionOfferNotFound
	}
	if offer.GuideUserID != input.ActorUserID {
		return nil, ErrExcursionAccessDenied
	}
	if offer.DeletedAt != nil || offer.Status != enum.ExcursionStatusPublished {
		return nil, ErrExcursionNotPublished
	}
	capacity := input.Capacity
	if capacity <= 0 {
		capacity = offer.MaxGroupSize
	}
	if capacity > offer.MaxGroupSize {
		return nil, model.ErrInvalidExcursionScheduleCapacity
	}
	startAt := input.StartAt.UTC()
	if !scheduleStartAllowsGuideSetup(startAt, time.Now().UTC()) {
		return nil, ErrExcursionScheduleStartTooSoon
	}
	slot, err := model.NewExcursionScheduleSlot(model.NewExcursionScheduleSlotParams{
		GuideProfileID:    offer.GuideProfileID,
		GuideUserID:       offer.GuideUserID,
		OfferID:           offer.ID,
		ProductID:         offer.ProductID,
		LegacyExcursionID: offer.LegacyExcursionID,
		StartAt:           startAt,
		EndAt:             startAt.Add(time.Duration(offer.DurationMinutes) * time.Minute),
		Timezone:          input.Timezone,
		Capacity:          capacity,
	})
	if err != nil {
		return nil, err
	}
	slot.Title = strings.TrimSpace(offer.Title)
	if err = u.repo.CreateExcursionScheduleSlot(ctx, slot); err != nil {
		if errors.Is(err, port.ErrExcursionScheduleConflict) {
			return nil, ErrExcursionScheduleConflict
		}
		return nil, fmt.Errorf("create excursion schedule slot: %w", err)
	}
	return slot, nil
}

func (u *ExcursionUseCase) CreateGuideScheduleSeries(ctx context.Context, input CreateGuideScheduleSeriesInput) ([]*model.ExcursionScheduleSlot, error) {
	if input.ActorUserID == uuid.Nil {
		return nil, ErrInvalidActorUserID
	}
	if input.OfferID == uuid.Nil {
		return nil, ErrInvalidExcursionID
	}
	offer, err := u.getExcursionOfferForSchedule(ctx, input.OfferID)
	if err != nil {
		return nil, err
	}
	if offer == nil {
		return nil, ErrExcursionOfferNotFound
	}
	if offer.GuideUserID != input.ActorUserID {
		return nil, ErrExcursionAccessDenied
	}
	if offer.DeletedAt != nil || offer.Status != enum.ExcursionStatusPublished {
		return nil, ErrExcursionNotPublished
	}

	capacity := input.Capacity
	if capacity <= 0 {
		capacity = offer.MaxGroupSize
	}
	if capacity > offer.MaxGroupSize {
		return nil, model.ErrInvalidExcursionScheduleCapacity
	}
	defaultCapacity := capacity
	limit := 12
	if input.OccurrenceLimit != nil && *input.OccurrenceLimit > 0 {
		limit = *input.OccurrenceLimit
	}
	if limit > 52 {
		limit = 52
	}
	until := input.StartsOn.AddDate(0, 0, limit*7)
	if input.EndsOn != nil {
		until = *input.EndsOn
	}
	starts, err := weeklyOccurrences(input.StartsOn, input.Weekdays, input.StartTime, offer.DurationMinutes, input.Timezone, until, limit)
	if err != nil {
		return nil, err
	}
	if len(starts) == 0 {
		return nil, model.ErrInvalidExcursionScheduleInterval
	}

	now := time.Now().UTC()
	for _, startAt := range starts {
		if !scheduleStartAllowsGuideSetup(startAt, now) {
			return nil, ErrExcursionScheduleStartTooSoon
		}
	}
	series := &model.ExcursionScheduleSeries{
		ID:                uuid.New(),
		GuideProfileID:    offer.GuideProfileID,
		GuideUserID:       offer.GuideUserID,
		OfferID:           offer.ID,
		ProductID:         offer.ProductID,
		LegacyExcursionID: offer.LegacyExcursionID,
		Timezone:          strings.TrimSpace(input.Timezone),
		RecurrenceType:    enum.ExcursionScheduleRecurrenceTypeWeekly,
		Weekdays:          append([]int(nil), input.Weekdays...),
		StartsOn:          input.StartsOn,
		EndsOn:            input.EndsOn,
		OccurrenceLimit:   input.OccurrenceLimit,
		DefaultStartTime:  strings.TrimSpace(input.StartTime),
		DefaultCapacity:   &defaultCapacity,
		Status:            enum.ExcursionScheduleSeriesStatusActive,
		CreatedAt:         now,
		UpdatedAt:         now,
	}
	if err = series.Validate(); err != nil {
		return nil, err
	}
	slots := make([]*model.ExcursionScheduleSlot, 0, len(starts))
	for _, startAt := range starts {
		slot, slotErr := model.NewExcursionScheduleSlot(model.NewExcursionScheduleSlotParams{
			SeriesID:          &series.ID,
			GuideProfileID:    offer.GuideProfileID,
			GuideUserID:       offer.GuideUserID,
			OfferID:           offer.ID,
			ProductID:         offer.ProductID,
			LegacyExcursionID: offer.LegacyExcursionID,
			StartAt:           startAt,
			EndAt:             startAt.Add(time.Duration(offer.DurationMinutes) * time.Minute),
			Timezone:          input.Timezone,
			Capacity:          capacity,
		})
		if slotErr != nil {
			return nil, slotErr
		}
		slot.Title = strings.TrimSpace(offer.Title)
		slots = append(slots, slot)
	}
	if err = u.repo.CreateExcursionScheduleSeriesWithSlots(ctx, series, slots); err != nil {
		if errors.Is(err, port.ErrExcursionScheduleConflict) {
			return nil, ErrExcursionScheduleConflict
		}
		return nil, fmt.Errorf("create excursion schedule series: %w", err)
	}
	return slots, nil
}

func (u *ExcursionUseCase) getExcursionOfferForSchedule(ctx context.Context, offerOrLegacyExcursionID uuid.UUID) (*model.ExcursionOffer, error) {
	offer, err := u.repo.GetExcursionOfferByID(ctx, offerOrLegacyExcursionID)
	if err != nil {
		return nil, fmt.Errorf("get excursion offer: %w", err)
	}
	if offer != nil {
		return offer, nil
	}
	offer, err = u.repo.GetExcursionOfferByLegacyExcursionID(ctx, offerOrLegacyExcursionID)
	if err != nil {
		return nil, fmt.Errorf("get excursion offer by legacy excursion id: %w", err)
	}
	return offer, nil
}

func (u *ExcursionUseCase) ListGuideSchedule(ctx context.Context, input ListGuideScheduleInput) ([]*model.ExcursionScheduleSlot, error) {
	if input.ActorUserID == uuid.Nil {
		return nil, ErrInvalidActorUserID
	}
	return u.listGuideScheduleForGuide(ctx, input.ActorUserID, input.From, input.To)
}

func (u *ExcursionUseCase) ListPublicGuideSchedule(ctx context.Context, input ListPublicGuideScheduleInput) ([]*model.ExcursionScheduleSlot, error) {
	if input.GuideUserID == uuid.Nil {
		return nil, model.ErrInvalidGuideUserID
	}
	return u.listGuideScheduleForGuide(ctx, input.GuideUserID, input.From, input.To)
}

func (u *ExcursionUseCase) listGuideScheduleForGuide(ctx context.Context, guideUserID uuid.UUID, from time.Time, to time.Time) ([]*model.ExcursionScheduleSlot, error) {
	if from.IsZero() || to.IsZero() || !from.Before(to) {
		return nil, model.ErrInvalidExcursionScheduleInterval
	}
	now := time.Now().UTC()
	if _, err := u.AutoCloseBookedExcursionScheduleSlots(ctx, 100); err != nil {
		return nil, err
	}
	if err := u.expireUnbookedExcursionScheduleSlots(ctx, now); err != nil {
		return nil, err
	}
	if _, err := u.AutoCompleteDueExcursionScheduleSlots(ctx, 100); err != nil {
		return nil, err
	}
	items, err := u.repo.ListExcursionScheduleSlots(ctx, port.ExcursionScheduleFilter{
		GuideUserID: &guideUserID,
		From:        from,
		To:          to,
		Statuses: []enum.ExcursionScheduleSlotStatus{
			enum.ExcursionScheduleSlotStatusAvailable,
			enum.ExcursionScheduleSlotStatusBooked,
			enum.ExcursionScheduleSlotStatusFull,
			enum.ExcursionScheduleSlotStatusClosed,
			enum.ExcursionScheduleSlotStatusCancelled,
			enum.ExcursionScheduleSlotStatusCompleted,
		},
		Limit: 500,
	})
	if err != nil {
		return nil, fmt.Errorf("list excursion schedule slots: %w", err)
	}
	return items, nil
}

func (u *ExcursionUseCase) AutoCompleteDueExcursionScheduleSlots(ctx context.Context, limit int) (int, error) {
	if limit <= 0 {
		limit = 100
	}
	count, err := u.repo.CompleteDueExcursionScheduleSlots(
		ctx,
		time.Now().UTC(),
		excursionScheduleAutoCompleteReasonEnded,
		limit,
	)
	if err != nil {
		return 0, fmt.Errorf("complete due excursion schedule slots: %w", err)
	}
	return count, nil
}

func (u *ExcursionUseCase) AutoCloseBookedExcursionScheduleSlots(ctx context.Context, limit int) (int, error) {
	if limit <= 0 {
		limit = 100
	}
	slots, err := u.repo.CloseBookedExcursionScheduleSlots(
		ctx,
		excursionScheduleBookingCutoff(time.Now().UTC()),
		limit,
	)
	if err != nil {
		return 0, fmt.Errorf("close booked excursion schedule slots: %w", err)
	}
	for _, slot := range slots {
		if err := u.syncExcursionScheduleSlotChat(ctx, slot); err != nil {
			log.Warn().
				Err(err).
				Str("schedule_slot_id", slot.ID.String()).
				Msg("failed to sync excursion schedule slot chat after auto-close")
		}
	}
	return len(slots), nil
}

func (u *ExcursionUseCase) GenerateExcursionAttendanceQR(
	ctx context.Context,
	slotID uuid.UUID,
	actorUserID uuid.UUID,
) (*ExcursionAttendanceQRData, error) {
	slot, err := u.getOwnedScheduleSlot(ctx, actorUserID, slotID)
	if err != nil {
		return nil, err
	}
	now := time.Now().UTC()
	if !isExcursionAttendanceQRAvailable(slot, now) {
		return nil, ErrExcursionAttendanceQRUnavailable
	}

	issue, err := model.NewExcursionAttendanceQRIssue(model.NewExcursionAttendanceQRIssueParams{
		ScheduleSlotID: slot.ID,
		GuideUserID:    actorUserID,
		IssuedAt:       now,
		TTL:            u.attendanceQRTTL,
		OfflineWindow:  u.resolveExcursionAttendanceOfflineWindow(slot, now),
	})
	if err != nil {
		return nil, err
	}
	if err = u.repo.CreateExcursionAttendanceQRIssue(ctx, issue); err != nil {
		return nil, fmt.Errorf("create excursion attendance qr issue: %w", err)
	}

	token, err := signExcursionAttendanceQRToken(
		u.attendanceQRSigningKey,
		issue.ScheduleSlotID,
		issue.GuideUserID,
		issue.JTI,
		issue.IssuedAt,
		issue.ExpiresAt,
	)
	if err != nil {
		return nil, fmt.Errorf("sign excursion attendance qr: %w", err)
	}

	refreshAt := issue.ExpiresAt.Add(-10 * time.Second)
	if !refreshAt.After(now) {
		refreshAt = now.Add(u.attendanceQRTTL / 2)
	}

	return &ExcursionAttendanceQRData{
		ScheduleSlotID: issue.ScheduleSlotID.String(),
		Token:          token,
		ExpiresAt:      issue.ExpiresAt,
		RefreshAt:      refreshAt,
	}, nil
}

func (u *ExcursionUseCase) SyncExcursionAttendanceProofs(
	ctx context.Context,
	actorUserID uuid.UUID,
	inputs []ExcursionAttendanceProofInput,
) ([]ExcursionAttendanceSyncItemResult, error) {
	if actorUserID == uuid.Nil {
		return nil, model.ErrInvalidAttendanceSyncParticipantID
	}

	results := make([]ExcursionAttendanceSyncItemResult, 0, len(inputs))
	for _, input := range inputs {
		results = append(results, u.syncExcursionAttendanceProof(ctx, actorUserID, input))
	}
	return results, nil
}

func (u *ExcursionUseCase) syncExcursionAttendanceProof(
	ctx context.Context,
	actorUserID uuid.UUID,
	input ExcursionAttendanceProofInput,
) ExcursionAttendanceSyncItemResult {
	now := time.Now().UTC()
	if input.ScanID == uuid.Nil {
		return excursionAttendanceRejectedResult(input.ScanID, nil, "invalid_scan_id", "invalid attendance scan id")
	}
	if strings.TrimSpace(input.QRToken) == "" {
		return excursionAttendanceRejectedResult(input.ScanID, nil, "invalid_qr", ErrExcursionAttendanceQRInvalid.Error())
	}
	if strings.TrimSpace(input.InstallationID) == "" {
		return excursionAttendanceRejectedResult(input.ScanID, nil, "invalid_installation", "invalid installation id")
	}

	decoded, err := decodeAndVerifyExcursionAttendanceQR(u.attendanceQRSigningKey, input.QRToken)
	if err != nil {
		code := excursionAttendanceCodeForError(err)
		return excursionAttendanceRejectedResult(input.ScanID, nil, code, err.Error())
	}

	result := ExcursionAttendanceSyncItemResult{
		ScanID:         input.ScanID,
		ScheduleSlotID: &decoded.ScheduleSlotID,
		SyncedAt:       now,
	}

	err = u.repo.WithTx(ctx, func(txRepo port.ExcursionTxRepository) error {
		existingAttempt, err := txRepo.GetExcursionAttendanceSyncAttemptByScanIDForUpdate(ctx, input.ScanID)
		if err != nil {
			return fmt.Errorf("get excursion attendance sync attempt: %w", err)
		}
		if existingAttempt != nil {
			result = excursionAttendanceResultFromAttempt(existingAttempt)
			return nil
		}

		issue, err := txRepo.GetExcursionAttendanceQRIssueByJTIForUpdate(ctx, decoded.JTI)
		if err != nil {
			return fmt.Errorf("get excursion attendance qr issue: %w", err)
		}
		if issue == nil ||
			issue.ScheduleSlotID != decoded.ScheduleSlotID ||
			issue.GuideUserID != decoded.GuideUserID {
			return u.persistRejectedExcursionAttendanceAttempt(ctx, txRepo, input, actorUserID, decoded, "invalid_qr", ErrExcursionAttendanceQRInvalid.Error(), &result)
		}
		if now.After(issue.UsableUntil) {
			return u.persistRejectedExcursionAttendanceAttempt(ctx, txRepo, input, actorUserID, decoded, "qr_expired", ErrExcursionAttendanceQRExpired.Error(), &result)
		}

		slot, err := txRepo.GetExcursionScheduleSlotByIDForUpdate(ctx, decoded.ScheduleSlotID)
		if err != nil {
			return fmt.Errorf("get excursion slot for attendance sync: %w", err)
		}
		if slot == nil || slot.GuideUserID != decoded.GuideUserID || !isExcursionAttendanceScanAllowed(slot) {
			return u.persistRejectedExcursionAttendanceAttempt(ctx, txRepo, input, actorUserID, decoded, "slot_unavailable", ErrExcursionAttendanceQRUnavailable.Error(), &result)
		}
		if slot.GuideUserID == actorUserID {
			return u.persistRejectedExcursionAttendanceAttempt(ctx, txRepo, input, actorUserID, decoded, "host_scan_not_allowed", ErrExcursionAttendanceAccessDenied.Error(), &result)
		}

		booking, err := txRepo.GetExcursionBookingByScheduleSlotAndTouristForUpdate(ctx, decoded.ScheduleSlotID, actorUserID)
		if err != nil {
			return fmt.Errorf("get excursion booking for attendance sync: %w", err)
		}
		if booking == nil || booking.TouristUserID != actorUserID {
			return u.persistRejectedExcursionAttendanceAttempt(ctx, txRepo, input, actorUserID, decoded, "not_registered", ErrExcursionBookingNotFound.Error(), &result)
		}
		if booking.Status != enum.ExcursionBookingStatusRequested || booking.CancelledAt != nil {
			return u.persistRejectedExcursionAttendanceAttempt(ctx, txRepo, input, actorUserID, decoded, "participant_not_eligible", ErrExcursionAttendanceBookingInvalid.Error(), &result)
		}
		if booking.CheckedInAt != nil {
			attempt, attemptErr := model.NewExcursionAttendanceSyncAttempt(model.NewExcursionAttendanceSyncAttemptParams{
				ScanID:          input.ScanID,
				ScheduleSlotID:  decoded.ScheduleSlotID,
				TouristUserID:   actorUserID,
				QRJTI:           decoded.JTI,
				InstallationID:  input.InstallationID,
				ScannedAtDevice: input.ScannedAtDevice,
				ResultStatus:    model.AttendanceSyncAttemptStatusAlreadyCheckedIn,
				CheckedInAt:     booking.CheckedInAt,
			})
			if attemptErr != nil {
				return attemptErr
			}
			if err = txRepo.CreateExcursionAttendanceSyncAttempt(ctx, attempt); err != nil {
				return fmt.Errorf("create already checked-in excursion attendance attempt: %w", err)
			}
			result = ExcursionAttendanceSyncItemResult{
				ScanID:         input.ScanID,
				ScheduleSlotID: &decoded.ScheduleSlotID,
				Status:         AttendanceSyncStatusAlreadySynced,
				Code:           "already_checked_in",
				Message:        ErrExcursionAttendanceAlreadyCheckedIn.Error(),
				CheckedInAt:    booking.CheckedInAt,
				SyncedAt:       time.Now().UTC(),
			}
			return nil
		}

		checkInTime := time.Now().UTC()
		if err = booking.MarkCheckedIn(checkInTime); err != nil {
			return err
		}
		if err = txRepo.UpdateExcursionBookingAttendance(ctx, booking); err != nil {
			return fmt.Errorf("update excursion booking attendance: %w", err)
		}
		attempt, attemptErr := model.NewExcursionAttendanceSyncAttempt(model.NewExcursionAttendanceSyncAttemptParams{
			ScanID:          input.ScanID,
			ScheduleSlotID:  decoded.ScheduleSlotID,
			TouristUserID:   actorUserID,
			QRJTI:           decoded.JTI,
			InstallationID:  input.InstallationID,
			ScannedAtDevice: input.ScannedAtDevice,
			ResultStatus:    model.AttendanceSyncAttemptStatusAccepted,
			CheckedInAt:     &checkInTime,
		})
		if attemptErr != nil {
			return attemptErr
		}
		if err = txRepo.CreateExcursionAttendanceSyncAttempt(ctx, attempt); err != nil {
			return fmt.Errorf("create accepted excursion attendance attempt: %w", err)
		}
		result = ExcursionAttendanceSyncItemResult{
			ScanID:         input.ScanID,
			ScheduleSlotID: &decoded.ScheduleSlotID,
			Status:         AttendanceSyncStatusSynced,
			Code:           "checked_in",
			Message:        "attendance synced",
			CheckedInAt:    &checkInTime,
			SyncedAt:       time.Now().UTC(),
		}
		return nil
	})
	if err != nil {
		return ExcursionAttendanceSyncItemResult{
			ScanID:         input.ScanID,
			ScheduleSlotID: result.ScheduleSlotID,
			Status:         AttendanceSyncStatusRetryable,
			Code:           "server_error",
			Message:        "attendance sync failed",
			SyncedAt:       time.Now().UTC(),
		}
	}
	return result
}

func (u *ExcursionUseCase) ListPublicExcursionSchedule(ctx context.Context, input ListPublicExcursionScheduleInput) ([]*model.ExcursionScheduleSlot, error) {
	if input.ProductID == uuid.Nil || input.OfferID == uuid.Nil {
		return nil, ErrInvalidExcursionID
	}
	if input.From.IsZero() || input.To.IsZero() || !input.From.Before(input.To) {
		return nil, model.ErrInvalidExcursionScheduleInterval
	}
	seats := input.Seats
	if seats <= 0 {
		seats = 1
	}
	offer, err := u.repo.GetExcursionOfferByID(ctx, input.OfferID)
	if err != nil {
		return nil, fmt.Errorf("get excursion offer: %w", err)
	}
	if offer == nil || offer.ProductID != input.ProductID {
		return nil, ErrExcursionOfferNotFound
	}
	if offer.DeletedAt != nil ||
		offer.Status != enum.ExcursionStatusPublished ||
		offer.Visibility != enum.ExcursionVisibilityPublic {
		return nil, ErrExcursionOfferNotBookable
	}
	if seats > offer.MaxGroupSize {
		return nil, model.ErrInvalidExcursionBookingGuests
	}
	now := time.Now().UTC()
	if _, err := u.AutoCloseBookedExcursionScheduleSlots(ctx, 100); err != nil {
		return nil, err
	}
	if err := u.expireUnbookedExcursionScheduleSlots(ctx, now); err != nil {
		return nil, err
	}
	from := input.From.UTC()
	cutoff := excursionScheduleBookingCutoff(now)
	if from.Before(cutoff) {
		from = cutoff
	}
	if !from.Before(input.To.UTC()) {
		return []*model.ExcursionScheduleSlot{}, nil
	}

	productID := input.ProductID
	offerID := input.OfferID
	items, err := u.repo.ListExcursionScheduleSlots(ctx, port.ExcursionScheduleFilter{
		ProductID: &productID,
		OfferID:   &offerID,
		From:      from,
		To:        input.To,
		Statuses: []enum.ExcursionScheduleSlotStatus{
			enum.ExcursionScheduleSlotStatusAvailable,
			enum.ExcursionScheduleSlotStatusBooked,
		},
		Limit: 500,
	})
	if err != nil {
		return nil, fmt.Errorf("list public excursion schedule slots: %w", err)
	}

	result := make([]*model.ExcursionScheduleSlot, 0, len(items))
	for _, slot := range items {
		if !slotCanAcceptExcursionBooking(slot, seats, now) {
			continue
		}
		result = append(result, slot)
	}
	return result, nil
}

func (u *ExcursionUseCase) UpdateGuideScheduleSlot(ctx context.Context, input UpdateGuideScheduleSlotInput) (*model.ExcursionScheduleSlot, error) {
	slot, err := u.getOwnedScheduleSlot(ctx, input.ActorUserID, input.SlotID)
	if err != nil {
		return nil, err
	}
	if slot.BookedSeats > 0 {
		return nil, ErrExcursionScheduleUnavailable
	}

	offerID := input.OfferID
	if offerID == uuid.Nil {
		offerID = slot.OfferID
	}
	offer, err := u.getExcursionOfferForSchedule(ctx, offerID)
	if err != nil {
		return nil, err
	}
	if offer == nil {
		return nil, ErrExcursionOfferNotFound
	}
	if offer.GuideUserID != input.ActorUserID {
		return nil, ErrExcursionAccessDenied
	}
	if offer.DeletedAt != nil || offer.Status != enum.ExcursionStatusPublished {
		return nil, ErrExcursionNotPublished
	}

	startAt := input.StartAt
	if startAt.IsZero() {
		startAt = slot.StartAt
	}
	startAt = startAt.UTC()
	if !scheduleStartAllowsGuideSetup(startAt, time.Now().UTC()) {
		return nil, ErrExcursionScheduleStartTooSoon
	}
	timezone := strings.TrimSpace(input.Timezone)
	if timezone == "" {
		timezone = slot.Timezone
	}
	capacity := input.Capacity
	if capacity <= 0 {
		capacity = offer.MaxGroupSize
	}
	if capacity > offer.MaxGroupSize {
		return nil, model.ErrInvalidExcursionScheduleCapacity
	}

	slot.OfferID = offer.ID
	slot.ProductID = offer.ProductID
	slot.LegacyExcursionID = model.NormalizeUUIDPointer(offer.LegacyExcursionID)
	slot.StartAt = startAt
	slot.EndAt = startAt.Add(time.Duration(offer.DurationMinutes) * time.Minute).UTC()
	slot.Timezone = timezone
	slot.Capacity = capacity
	slot.Title = strings.TrimSpace(offer.Title)
	slot.UpdatedAt = time.Now().UTC()

	if err = slot.Validate(); err != nil {
		return nil, err
	}
	if err = u.repo.UpdateExcursionScheduleSlot(ctx, slot); err != nil {
		if errors.Is(err, port.ErrExcursionScheduleConflict) {
			return nil, ErrExcursionScheduleConflict
		}
		if errors.Is(err, port.ErrExcursionScheduleUnavailable) {
			return nil, ErrExcursionScheduleUnavailable
		}
		return nil, fmt.Errorf("update excursion schedule slot: %w", err)
	}
	return slot, nil
}

func (u *ExcursionUseCase) CloseGuideScheduleSlot(ctx context.Context, actorUserID uuid.UUID, slotID uuid.UUID) (*model.ExcursionScheduleSlot, error) {
	slot, err := u.getOwnedScheduleSlot(ctx, actorUserID, slotID)
	if err != nil {
		return nil, err
	}
	slot.Close()
	if err = u.repo.UpdateExcursionScheduleSlot(ctx, slot); err != nil {
		if errors.Is(err, port.ErrExcursionScheduleConflict) {
			return nil, ErrExcursionScheduleConflict
		}
		return nil, fmt.Errorf("close excursion schedule slot: %w", err)
	}
	if err = u.syncExcursionScheduleSlotChat(ctx, slot); err != nil {
		return nil, fmt.Errorf("sync excursion schedule slot chat: %w", err)
	}
	return slot, nil
}

func (u *ExcursionUseCase) CancelGuideScheduleSlot(ctx context.Context, actorUserID uuid.UUID, slotID uuid.UUID, reason string) (*model.ExcursionScheduleSlot, error) {
	slot, err := u.getOwnedScheduleSlot(ctx, actorUserID, slotID)
	if err != nil {
		return nil, err
	}
	if err = slot.Cancel(reason); err != nil {
		return nil, err
	}
	if err = u.repo.UpdateExcursionScheduleSlot(ctx, slot); err != nil {
		return nil, fmt.Errorf("cancel excursion schedule slot: %w", err)
	}
	if err = u.syncExcursionScheduleSlotChat(ctx, slot); err != nil {
		return nil, fmt.Errorf("sync cancelled excursion schedule slot chat: %w", err)
	}
	return slot, nil
}

func (u *ExcursionUseCase) DeleteGuideScheduleSlot(ctx context.Context, actorUserID uuid.UUID, slotID uuid.UUID) error {
	slot, err := u.getOwnedScheduleSlot(ctx, actorUserID, slotID)
	if err != nil {
		return err
	}
	if !slot.CanHardDelete() {
		return model.ErrExcursionScheduleBookedDeleteDenied
	}
	if err = u.repo.DeleteExcursionScheduleSlot(ctx, slotID, actorUserID); err != nil {
		return fmt.Errorf("delete excursion schedule slot: %w", err)
	}
	return nil
}

func (u *ExcursionUseCase) expireUnbookedExcursionScheduleSlots(ctx context.Context, now time.Time) error {
	if err := u.repo.ExpireUnbookedExcursionScheduleSlots(
		ctx,
		excursionScheduleBookingCutoff(now),
		excursionScheduleAutoCancelReasonNoBookings,
	); err != nil {
		return fmt.Errorf("expire unbooked excursion schedule slots: %w", err)
	}
	return nil
}

func (u *ExcursionUseCase) syncExcursionScheduleSlotChat(
	ctx context.Context,
	slot *model.ExcursionScheduleSlot,
) error {
	if u.chatGateway == nil || slot == nil || slot.ID == uuid.Nil {
		return nil
	}
	if slot.BookedSeats <= 0 {
		return nil
	}

	slotID := slot.ID
	items, err := u.repo.ListExcursionBookings(ctx, port.ExcursionBookingFilter{
		ScheduleSlotID: &slotID,
		Statuses:       []enum.ExcursionBookingStatus{enum.ExcursionBookingStatusRequested},
		Limit:          500,
	})
	if err != nil {
		return fmt.Errorf("list excursion slot bookings: %w", err)
	}

	messagingAvailableUntil := excursionScheduleSlotChatMessagingAvailableUntil(slot)
	return u.chatGateway.SyncExcursionScheduleSlotConversation(ctx, port.SyncExcursionScheduleSlotConversationInput{
		ScheduleSlotID:          slot.ID,
		ExcursionTitle:          strings.TrimSpace(slot.Title),
		MessagingAvailableUntil: &messagingAvailableUntil,
		GuideUserID:             slot.GuideUserID,
		ParticipantUserIDs:      activeExcursionBookingAuthorUserIDs(items, slot.GuideUserID),
	})
}

func excursionScheduleSlotChatMessagingAvailableUntil(slot *model.ExcursionScheduleSlot) time.Time {
	if slot == nil {
		return time.Now().UTC()
	}
	closedAt := slot.EndAt
	if slot.CancelledAt != nil {
		closedAt = slot.CancelledAt.UTC()
	} else if slot.CompletedAt != nil {
		closedAt = slot.CompletedAt.UTC()
	}
	return closedAt.UTC().Add(time.Hour)
}

func activeExcursionBookingAuthorUserIDs(
	items []*model.ExcursionBookingListItem,
	guideUserID uuid.UUID,
) []uuid.UUID {
	seen := make(map[uuid.UUID]struct{}, len(items))
	result := make([]uuid.UUID, 0, len(items))
	for _, item := range items {
		if item == nil || item.Booking == nil {
			continue
		}
		booking := item.Booking
		if booking.Status != enum.ExcursionBookingStatusRequested ||
			booking.CancelledAt != nil ||
			booking.TouristUserID == uuid.Nil ||
			booking.TouristUserID == guideUserID {
			continue
		}
		if _, ok := seen[booking.TouristUserID]; ok {
			continue
		}
		seen[booking.TouristUserID] = struct{}{}
		result = append(result, booking.TouristUserID)
	}
	return result
}

func (u *ExcursionUseCase) resolveExcursionAttendanceOfflineWindow(slot *model.ExcursionScheduleSlot, now time.Time) time.Duration {
	offlineDeadline := now.Add(u.attendanceOfflineWindow)
	if slot != nil && !slot.EndAt.IsZero() {
		slotDeadline := slot.EndAt.UTC().Add(6 * time.Hour)
		if slotDeadline.Before(offlineDeadline) {
			offlineDeadline = slotDeadline
		}
	}
	if !offlineDeadline.After(now.Add(u.attendanceQRTTL)) {
		offlineDeadline = now.Add(u.attendanceQRTTL).Add(30 * time.Minute)
	}
	return time.Until(offlineDeadline)
}

func isExcursionAttendanceQRAvailable(slot *model.ExcursionScheduleSlot, now time.Time) bool {
	if slot == nil || slot.BookedSeats <= 0 {
		return false
	}
	now = now.UTC()
	if slot.StartAt.IsZero() ||
		slot.EndAt.IsZero() ||
		now.Before(slot.StartAt.UTC().Add(-excursionAttendanceQRLeadTime)) ||
		!now.Before(slot.EndAt.UTC()) {
		return false
	}
	switch slot.Status {
	case enum.ExcursionScheduleSlotStatusBooked,
		enum.ExcursionScheduleSlotStatusFull,
		enum.ExcursionScheduleSlotStatusClosed:
		return true
	default:
		return false
	}
}

func isExcursionAttendanceScanAllowed(slot *model.ExcursionScheduleSlot) bool {
	if slot == nil {
		return false
	}
	switch slot.Status {
	case enum.ExcursionScheduleSlotStatusBooked,
		enum.ExcursionScheduleSlotStatusFull,
		enum.ExcursionScheduleSlotStatusClosed:
		return true
	default:
		return false
	}
}

func excursionAttendanceCodeForError(err error) string {
	switch err {
	case nil:
		return ""
	case ErrExcursionAttendanceQRVersionInvalid:
		return "unsupported_qr"
	case ErrExcursionAttendanceQRInvalid:
		return "invalid_qr"
	default:
		if err.Error() == ErrExcursionAttendanceQRVersionInvalid.Error() {
			return "unsupported_qr"
		}
		return "invalid_qr"
	}
}

func excursionAttendanceResultFromAttempt(attempt *model.ExcursionAttendanceSyncAttempt) ExcursionAttendanceSyncItemResult {
	status := AttendanceSyncStatusRejected
	code := valueOr(attempt.FailureCode, "rejected")
	message := valueOr(attempt.FailureMessage, "attendance rejected")
	switch attempt.ResultStatus {
	case model.AttendanceSyncAttemptStatusAccepted:
		status = AttendanceSyncStatusSynced
		code = "checked_in"
		message = "attendance synced"
	case model.AttendanceSyncAttemptStatusAlreadyCheckedIn:
		status = AttendanceSyncStatusAlreadySynced
		code = "already_checked_in"
		message = ErrExcursionAttendanceAlreadyCheckedIn.Error()
	}
	return ExcursionAttendanceSyncItemResult{
		ScanID:         attempt.ScanID,
		ScheduleSlotID: &attempt.ScheduleSlotID,
		Status:         status,
		Code:           code,
		Message:        message,
		CheckedInAt:    attempt.CheckedInAt,
		SyncedAt:       attempt.UpdatedAt,
	}
}

func (u *ExcursionUseCase) persistRejectedExcursionAttendanceAttempt(
	ctx context.Context,
	txRepo port.ExcursionTxRepository,
	input ExcursionAttendanceProofInput,
	actorUserID uuid.UUID,
	decoded *decodedExcursionAttendanceQR,
	code string,
	message string,
	result *ExcursionAttendanceSyncItemResult,
) error {
	attempt, attemptErr := model.NewExcursionAttendanceSyncAttempt(model.NewExcursionAttendanceSyncAttemptParams{
		ScanID:          input.ScanID,
		ScheduleSlotID:  decoded.ScheduleSlotID,
		TouristUserID:   actorUserID,
		QRJTI:           decoded.JTI,
		InstallationID:  input.InstallationID,
		ScannedAtDevice: input.ScannedAtDevice,
		ResultStatus:    model.AttendanceSyncAttemptStatusRejected,
		FailureCode:     &code,
		FailureMessage:  &message,
	})
	if attemptErr == nil {
		if err := txRepo.CreateExcursionAttendanceSyncAttempt(ctx, attempt); err != nil {
			return fmt.Errorf("create rejected excursion attendance attempt: %w", err)
		}
	}
	*result = excursionAttendanceRejectedResult(input.ScanID, &decoded.ScheduleSlotID, code, message)
	return nil
}

func excursionAttendanceRejectedResult(
	scanID uuid.UUID,
	scheduleSlotID *uuid.UUID,
	code string,
	message string,
) ExcursionAttendanceSyncItemResult {
	return ExcursionAttendanceSyncItemResult{
		ScanID:         scanID,
		ScheduleSlotID: scheduleSlotID,
		Status:         AttendanceSyncStatusRejected,
		Code:           code,
		Message:        message,
		SyncedAt:       time.Now().UTC(),
	}
}

func valueOr(ptr *string, fallback string) string {
	if ptr == nil || strings.TrimSpace(*ptr) == "" {
		return fallback
	}
	return strings.TrimSpace(*ptr)
}

func slotCanAcceptExcursionBooking(slot *model.ExcursionScheduleSlot, seats int, now time.Time) bool {
	if slot == nil || !slot.IsBookable() {
		return false
	}
	requestedSeats := seats
	if requestedSeats <= 0 {
		requestedSeats = 1
	}
	return scheduleStartAllowsExcursionBooking(slot.StartAt, now) &&
		slot.BookedSeats+requestedSeats <= slot.Capacity
}

func scheduleStartAllowsExcursionBooking(startAt time.Time, now time.Time) bool {
	return !startAt.UTC().Before(excursionScheduleBookingCutoff(now))
}

func excursionScheduleBookingCutoff(now time.Time) time.Time {
	return now.UTC().Add(excursionScheduleBookingLeadTime)
}

func scheduleStartAllowsGuideSetup(startAt time.Time, now time.Time) bool {
	if startAt.IsZero() {
		return false
	}
	return !startAt.UTC().Before(now.UTC().Add(excursionScheduleSetupLeadTime))
}

func (u *ExcursionUseCase) getOwnedScheduleSlot(ctx context.Context, actorUserID uuid.UUID, slotID uuid.UUID) (*model.ExcursionScheduleSlot, error) {
	if actorUserID == uuid.Nil {
		return nil, ErrInvalidActorUserID
	}
	if slotID == uuid.Nil {
		return nil, model.ErrInvalidExcursionScheduleID
	}
	slot, err := u.repo.GetExcursionScheduleSlotByID(ctx, slotID)
	if err != nil {
		return nil, fmt.Errorf("get excursion schedule slot: %w", err)
	}
	if slot == nil {
		return nil, ErrExcursionNotFound
	}
	if slot.GuideUserID != actorUserID {
		return nil, ErrExcursionAccessDenied
	}
	return slot, nil
}

func (u *ExcursionUseCase) CreateExcursionBooking(ctx context.Context, input CreateExcursionBookingInput) (*model.ExcursionBooking, error) {
	if input.ActorUserID == uuid.Nil {
		return nil, ErrInvalidActorUserID
	}
	if input.ProductID == uuid.Nil || input.OfferID == uuid.Nil {
		return nil, ErrInvalidExcursionID
	}
	input.IdempotencyKey = model.NormalizeOptionalString(input.IdempotencyKey)
	existing, err := u.findExistingExcursionBookingForIdempotentRequest(ctx, input)
	if err != nil {
		return nil, err
	}
	if existing != nil {
		return existing, nil
	}
	offer, err := u.repo.GetExcursionOfferByID(ctx, input.OfferID)
	if err != nil {
		return nil, fmt.Errorf("get excursion offer: %w", err)
	}
	if offer == nil || offer.ProductID != input.ProductID {
		return nil, ErrExcursionOfferNotFound
	}
	if offer.DeletedAt != nil ||
		offer.Status != enum.ExcursionStatusPublished ||
		offer.Visibility != enum.ExcursionVisibilityPublic {
		return nil, ErrExcursionOfferNotBookable
	}
	if offer.GuideUserID == input.ActorUserID {
		return nil, ErrExcursionAccessDenied
	}
	totalSeats := input.Adults + input.Children
	if totalSeats > offer.MaxGroupSize {
		return nil, model.ErrInvalidExcursionBookingGuests
	}
	now := time.Now().UTC()
	if input.ScheduleSlotID != nil && *input.ScheduleSlotID != uuid.Nil {
		slot, err := u.repo.GetExcursionScheduleSlotByID(ctx, *input.ScheduleSlotID)
		if err != nil {
			return nil, fmt.Errorf("get excursion schedule slot: %w", err)
		}
		if slot == nil || slot.ProductID != input.ProductID || slot.OfferID != input.OfferID {
			return nil, ErrExcursionNotFound
		}
		if !slotCanAcceptExcursionBooking(slot, totalSeats, now) {
			return nil, ErrExcursionScheduleUnavailable
		}
		input.ScheduledFor = slot.StartAt
	}
	if !input.ScheduledFor.IsZero() && !scheduleStartAllowsExcursionBooking(input.ScheduledFor, now) {
		return nil, ErrExcursionScheduleUnavailable
	}

	booking, err := model.NewExcursionBooking(model.NewExcursionBookingParams{
		ProductID:         offer.ProductID,
		OfferID:           offer.ID,
		ScheduleSlotID:    input.ScheduleSlotID,
		LegacyExcursionID: offer.LegacyExcursionID,
		GuideProfileID:    offer.GuideProfileID,
		GuideUserID:       offer.GuideUserID,
		TouristUserID:     input.ActorUserID,
		ScheduledFor:      input.ScheduledFor,
		Adults:            input.Adults,
		Children:          input.Children,
		UnitPriceAmount:   offer.PriceAmount,
		Currency:          offer.Currency,
		IdempotencyKey:    input.IdempotencyKey,
	})
	if err != nil {
		return nil, err
	}
	if err = u.repo.CreateExcursionBooking(ctx, booking); err != nil {
		if errors.Is(err, port.ErrExcursionScheduleUnavailable) {
			return nil, ErrExcursionScheduleUnavailable
		}
		if errors.Is(err, port.ErrExcursionBookingIdempotencyConflict) {
			existing, findErr := u.findExistingExcursionBookingForIdempotentRequest(ctx, input)
			if findErr != nil {
				return nil, findErr
			}
			if existing != nil {
				return existing, nil
			}
		}
		return nil, fmt.Errorf("create excursion booking: %w", err)
	}
	return booking, nil
}

func (u *ExcursionUseCase) findExistingExcursionBookingForIdempotentRequest(ctx context.Context, input CreateExcursionBookingInput) (*model.ExcursionBooking, error) {
	idempotencyKey := model.NormalizeOptionalString(input.IdempotencyKey)
	if idempotencyKey == nil {
		return nil, nil
	}
	booking, err := u.repo.GetExcursionBookingByTouristIDAndIdempotencyKey(ctx, input.ActorUserID, *idempotencyKey)
	if err != nil {
		return nil, fmt.Errorf("get excursion booking by idempotency key: %w", err)
	}
	if booking == nil {
		return nil, nil
	}
	if !excursionBookingMatchesCreateInput(booking, input) {
		return nil, ErrExcursionBookingIdempotencyConflict
	}
	return booking, nil
}

func excursionBookingMatchesCreateInput(booking *model.ExcursionBooking, input CreateExcursionBookingInput) bool {
	if booking == nil {
		return false
	}
	if booking.TouristUserID != input.ActorUserID ||
		booking.ProductID != input.ProductID ||
		booking.OfferID != input.OfferID ||
		booking.Adults != input.Adults ||
		booking.Children != input.Children {
		return false
	}
	if input.ScheduleSlotID != nil && *input.ScheduleSlotID != uuid.Nil {
		return booking.ScheduleSlotID != nil && *booking.ScheduleSlotID == *input.ScheduleSlotID
	}
	if booking.ScheduleSlotID != nil {
		return false
	}
	return !input.ScheduledFor.IsZero() && booking.ScheduledFor.Equal(input.ScheduledFor.UTC())
}

func (u *ExcursionUseCase) ListMyExcursionBookings(ctx context.Context, actorUserID uuid.UUID, limit int, offset int) ([]*model.ExcursionBookingListItem, error) {
	if actorUserID == uuid.Nil {
		return nil, ErrInvalidActorUserID
	}
	if limit <= 0 {
		limit = 20
	}
	if limit > 100 {
		limit = 100
	}
	touristUserID := actorUserID
	items, err := u.repo.ListExcursionBookings(ctx, port.ExcursionBookingFilter{
		TouristUserID: &touristUserID,
		Limit:         limit,
		Offset:        offset,
	})
	if err != nil {
		return nil, fmt.Errorf("list excursion bookings: %w", err)
	}
	u.enrichExcursionBookingAuthors(ctx, items)
	return items, nil
}

func (u *ExcursionUseCase) ListMyGuideExcursionBookings(ctx context.Context, actorUserID uuid.UUID, limit int, offset int) ([]*model.ExcursionBookingListItem, error) {
	if actorUserID == uuid.Nil {
		return nil, ErrInvalidActorUserID
	}
	if limit <= 0 {
		limit = 20
	}
	if limit > 100 {
		limit = 100
	}
	guideUserID := actorUserID
	items, err := u.repo.ListExcursionBookings(ctx, port.ExcursionBookingFilter{
		GuideUserID: &guideUserID,
		Limit:       limit,
		Offset:      offset,
	})
	if err != nil {
		return nil, fmt.Errorf("list guide excursion bookings: %w", err)
	}
	u.enrichExcursionBookingAuthors(ctx, items)
	return items, nil
}

func (u *ExcursionUseCase) UpdateExcursionBookingGuests(ctx context.Context, input UpdateExcursionBookingGuestsInput) (*model.ExcursionBooking, error) {
	if input.ActorUserID == uuid.Nil {
		return nil, ErrInvalidActorUserID
	}
	if input.BookingID == uuid.Nil {
		return nil, model.ErrInvalidExcursionBookingID
	}
	booking, err := u.repo.GetExcursionBookingByID(ctx, input.BookingID)
	if err != nil {
		return nil, fmt.Errorf("get excursion booking: %w", err)
	}
	if booking == nil || booking.TouristUserID != input.ActorUserID {
		return nil, ErrExcursionBookingNotFound
	}
	if booking.Status != enum.ExcursionBookingStatusRequested ||
		booking.CancelledAt != nil ||
		!booking.ScheduledFor.After(time.Now().UTC()) {
		return nil, ErrExcursionBookingNotEditable
	}

	offer, err := u.repo.GetExcursionOfferByID(ctx, booking.OfferID)
	if err != nil {
		return nil, fmt.Errorf("get excursion offer: %w", err)
	}
	if offer == nil || offer.ProductID != booking.ProductID {
		return nil, ErrExcursionOfferNotFound
	}
	if input.Adults+input.Children > offer.MaxGroupSize {
		return nil, model.ErrInvalidExcursionBookingGuests
	}

	oldSeats := booking.TotalSeats
	seatDelta := input.Adults + input.Children - oldSeats
	if seatDelta > 0 && booking.ScheduleSlotID != nil {
		now := time.Now().UTC()
		slot, err := u.repo.GetExcursionScheduleSlotByID(ctx, *booking.ScheduleSlotID)
		if err != nil {
			return nil, fmt.Errorf("get excursion schedule slot: %w", err)
		}
		if slot == nil || slot.ProductID != booking.ProductID || slot.OfferID != booking.OfferID {
			return nil, ErrExcursionNotFound
		}
		if !slotCanAcceptExcursionBooking(slot, seatDelta, now) {
			return nil, ErrExcursionScheduleUnavailable
		}
	}

	if err := booking.UpdateGuests(input.Adults, input.Children); err != nil {
		return nil, err
	}
	if err := u.repo.UpdateExcursionBookingGuests(ctx, booking, seatDelta); err != nil {
		if errors.Is(err, port.ErrExcursionScheduleUnavailable) {
			return nil, ErrExcursionScheduleUnavailable
		}
		return nil, fmt.Errorf("update excursion booking guests: %w", err)
	}
	return booking, nil
}

func (u *ExcursionUseCase) CancelExcursionBooking(ctx context.Context, input CancelExcursionBookingInput) (*model.ExcursionBooking, error) {
	if input.ActorUserID == uuid.Nil {
		return nil, ErrInvalidActorUserID
	}
	if input.BookingID == uuid.Nil {
		return nil, model.ErrInvalidExcursionBookingID
	}

	booking, err := u.repo.GetExcursionBookingByID(ctx, input.BookingID)
	if err != nil {
		return nil, fmt.Errorf("get excursion booking: %w", err)
	}
	if booking == nil || booking.TouristUserID != input.ActorUserID {
		return nil, ErrExcursionBookingNotFound
	}

	now := time.Now().UTC()
	if booking.Status != enum.ExcursionBookingStatusRequested ||
		booking.CancelledAt != nil ||
		!booking.ScheduledFor.After(now) {
		return nil, ErrExcursionBookingNotEditable
	}

	quote := excursionBookingCancellationRefundQuote(
		booking.TotalPriceAmount,
		booking.Currency,
		booking.ScheduledFor,
		now,
	)
	if err = booking.Cancel(
		enum.ExcursionBookingCancelledByTourist,
		input.Reason,
		quote.Percent,
		quote.Amount,
		quote.Currency,
		quote.PolicyCode,
		quote.Status,
	); err != nil {
		return nil, err
	}

	if err = u.repo.CancelExcursionBooking(ctx, booking); err != nil {
		if errors.Is(err, port.ErrExcursionBookingNotEditable) {
			return nil, ErrExcursionBookingNotEditable
		}
		if errors.Is(err, port.ErrExcursionScheduleUnavailable) {
			return nil, ErrExcursionScheduleUnavailable
		}
		return nil, fmt.Errorf("cancel excursion booking: %w", err)
	}
	return booking, nil
}

func excursionBookingCancellationRefundQuote(
	totalAmount float64,
	currency string,
	scheduledFor time.Time,
	now time.Time,
) ExcursionBookingCancellationRefundQuote {
	untilStart := scheduledFor.UTC().Sub(now.UTC())
	percent := 0
	policyCode := excursionBookingRefundPolicyNoRefund2H

	switch {
	case untilStart >= 24*time.Hour:
		percent = 100
		policyCode = excursionBookingRefundPolicyFull24H
	case untilStart >= 12*time.Hour:
		percent = 75
		policyCode = excursionBookingRefundPolicyPartial12H
	case untilStart >= 6*time.Hour:
		percent = 50
		policyCode = excursionBookingRefundPolicyPartial6H
	case untilStart >= 2*time.Hour:
		percent = 25
		policyCode = excursionBookingRefundPolicyPartial2H
	}

	amount := math.Round((totalAmount*float64(percent)/100)*100) / 100
	status := excursionBookingRefundStatusNotRefundable
	if amount > 0 {
		status = excursionBookingRefundStatusPendingPaymentIntegration
	}

	return ExcursionBookingCancellationRefundQuote{
		Percent:    percent,
		Amount:     amount,
		Currency:   strings.ToUpper(strings.TrimSpace(currency)),
		PolicyCode: policyCode,
		Status:     status,
	}
}

func (u *ExcursionUseCase) CreateExcursionReview(ctx context.Context, input CreateExcursionReviewInput) (*model.ExcursionReview, error) {
	if input.ActorUserID == uuid.Nil {
		return nil, ErrInvalidActorUserID
	}
	if input.BookingID == uuid.Nil {
		return nil, model.ErrInvalidExcursionBookingID
	}
	booking, err := u.repo.GetExcursionBookingByID(ctx, input.BookingID)
	if err != nil {
		return nil, fmt.Errorf("get excursion booking: %w", err)
	}
	if booking == nil || booking.TouristUserID != input.ActorUserID {
		return nil, ErrExcursionBookingNotFound
	}
	if !isExcursionBookingReviewable(booking) {
		return nil, ErrExcursionBookingNotReviewable
	}
	existing, err := u.repo.GetExcursionReviewByBookingID(ctx, booking.ID)
	if err != nil {
		return nil, fmt.Errorf("get excursion review: %w", err)
	}
	if existing != nil {
		return nil, model.ErrExcursionReviewAlreadyExists
	}

	review, err := model.NewExcursionReview(model.NewExcursionReviewParams{
		Booking: booking,
		Rating:  input.Rating,
		Comment: input.Comment,
	})
	if err != nil {
		return nil, err
	}
	if err = u.repo.CreateExcursionReview(ctx, review); err != nil {
		return nil, fmt.Errorf("create excursion review: %w", err)
	}
	u.enrichExcursionReviewAuthors(ctx, []*model.ExcursionReview{review})
	u.applyAttractionRatingSnapshot(ctx, review)
	return review, nil
}

func (u *ExcursionUseCase) SaveBookingReviews(ctx context.Context, input SaveBookingReviewsInput) (*BookingReviewsResult, error) {
	if input.ActorUserID == uuid.Nil {
		return nil, ErrInvalidActorUserID
	}
	if input.BookingID == uuid.Nil {
		return nil, model.ErrInvalidExcursionBookingID
	}
	booking, err := u.repo.GetExcursionBookingByID(ctx, input.BookingID)
	if err != nil {
		return nil, fmt.Errorf("get excursion booking: %w", err)
	}
	if booking == nil || booking.TouristUserID != input.ActorUserID {
		return nil, ErrExcursionBookingNotFound
	}
	if !isExcursionBookingReviewable(booking) {
		return nil, ErrExcursionBookingNotReviewable
	}

	result := &BookingReviewsResult{}
	var refreshLandmarkReview *model.ExcursionReview
	err = u.repo.WithTx(ctx, func(repo port.ExcursionTxRepository) error {
		if input.ExcursionReview != nil {
			existing, err := repo.GetExcursionReviewByBookingID(ctx, booking.ID)
			if err != nil {
				return fmt.Errorf("get excursion review: %w", err)
			}
			result.ExcursionReview, refreshLandmarkReview, err = u.applyExcursionReviewMutation(ctx, repo, booking, existing, *input.ExcursionReview)
			if err != nil {
				return err
			}
		} else {
			result.ExcursionReview, err = repo.GetExcursionReviewByBookingID(ctx, booking.ID)
			if err != nil {
				return fmt.Errorf("get excursion review: %w", err)
			}
		}

		if input.GuideReview != nil {
			existing, err := repo.GetGuideReviewByBookingID(ctx, booking.ID)
			if err != nil {
				return fmt.Errorf("get guide review: %w", err)
			}
			result.GuideReview, err = u.applyGuideReviewMutation(ctx, repo, booking, existing, *input.GuideReview)
			if err != nil {
				return err
			}
		} else {
			result.GuideReview, err = repo.GetGuideReviewByBookingID(ctx, booking.ID)
			if err != nil {
				return fmt.Errorf("get guide review: %w", err)
			}
		}
		return nil
	})
	if err != nil {
		return nil, err
	}

	if result.ExcursionReview != nil {
		u.enrichExcursionReviewAuthors(ctx, []*model.ExcursionReview{result.ExcursionReview})
	}
	if result.GuideReview != nil {
		result.GuideReview.Author.UserID = result.GuideReview.TouristUserID
	}
	u.applyAttractionRatingSnapshot(ctx, refreshLandmarkReview)
	return result, nil
}

func (u *ExcursionUseCase) applyExcursionReviewMutation(
	ctx context.Context,
	repo reviewMutationRepository,
	booking *model.ExcursionBooking,
	existing *model.ExcursionReview,
	input ReviewMutationInput,
) (*model.ExcursionReview, *model.ExcursionReview, error) {
	if input.Delete {
		if existing == nil {
			return nil, nil, nil
		}
		existing.SoftDelete()
		if err := repo.DeleteExcursionReview(ctx, existing); err != nil {
			return nil, nil, fmt.Errorf("delete excursion review: %w", err)
		}
		return nil, existing, nil
	}
	if existing != nil {
		oldRating := existing.Rating
		if err := existing.Update(input.Rating, input.Comment); err != nil {
			return nil, nil, err
		}
		if err := repo.UpdateExcursionReview(ctx, existing); err != nil {
			return nil, nil, fmt.Errorf("update excursion review: %w", err)
		}
		if oldRating != existing.Rating {
			return existing, existing, nil
		}
		return existing, nil, nil
	}
	review, err := model.NewExcursionReview(model.NewExcursionReviewParams{
		Booking: booking,
		Rating:  input.Rating,
		Comment: input.Comment,
	})
	if err != nil {
		return nil, nil, err
	}
	if err := repo.CreateExcursionReview(ctx, review); err != nil {
		return nil, nil, fmt.Errorf("create excursion review: %w", err)
	}
	return review, review, nil
}

func (u *ExcursionUseCase) applyGuideReviewMutation(
	ctx context.Context,
	repo reviewMutationRepository,
	booking *model.ExcursionBooking,
	existing *model.GuideReview,
	input ReviewMutationInput,
) (*model.GuideReview, error) {
	if input.Delete {
		if existing == nil {
			return nil, nil
		}
		existing.SoftDelete()
		if err := repo.DeleteGuideReview(ctx, existing); err != nil {
			return nil, fmt.Errorf("delete guide review: %w", err)
		}
		return nil, nil
	}
	if existing != nil {
		if err := existing.Update(input.Rating, input.Comment); err != nil {
			return nil, err
		}
		if err := repo.UpdateGuideReview(ctx, existing); err != nil {
			return nil, fmt.Errorf("update guide review: %w", err)
		}
		return existing, nil
	}
	review, err := model.NewGuideReview(model.NewGuideReviewParams{
		Booking: booking,
		Rating:  input.Rating,
		Comment: input.Comment,
	})
	if err != nil {
		return nil, err
	}
	if err := repo.CreateGuideReview(ctx, review); err != nil {
		return nil, fmt.Errorf("create guide review: %w", err)
	}
	return review, nil
}

func isExcursionBookingReviewable(booking *model.ExcursionBooking) bool {
	return booking != nil &&
		booking.Status == enum.ExcursionBookingStatusRequested &&
		booking.CancelledAt == nil &&
		!booking.ScheduledFor.After(time.Now().UTC())
}

func (u *ExcursionUseCase) applyAttractionRatingSnapshot(ctx context.Context, review *model.ExcursionReview) {
	if review == nil || review.LandmarkID == nil || *review.LandmarkID == uuid.Nil || u.attractionRatingUpdater == nil {
		return
	}
	ratingAvg, reviewsCount, err := u.repo.CalculateLandmarkReviewStats(ctx, *review.LandmarkID)
	if err != nil {
		return
	}
	_ = u.attractionRatingUpdater.ApplyAttractionRatingSnapshot(ctx, port.AttractionRatingSnapshot{
		AttractionID: *review.LandmarkID,
		Source:       attractionRatingSourceExcursionReviews,
		RatingAvg:    ratingAvg,
		ReviewCount:  reviewsCount,
	})
}

func (u *ExcursionUseCase) ListExcursionReviews(ctx context.Context, filter port.ExcursionReviewFilter) ([]*model.ExcursionReview, error) {
	if filter.ProductID == nil && filter.LandmarkID == nil && filter.GuideUserID == nil {
		return nil, ErrInvalidExcursionID
	}
	if filter.Limit <= 0 {
		filter.Limit = 20
	}
	if filter.Limit > 100 {
		filter.Limit = 100
	}
	if filter.Offset < 0 {
		filter.Offset = 0
	}
	if filter.Sort == "" {
		filter.Sort = port.ExcursionReviewSortLatest
	}
	items, err := u.repo.ListExcursionReviews(ctx, filter)
	if err != nil {
		return nil, fmt.Errorf("list excursion reviews: %w", err)
	}
	u.enrichExcursionReviewAuthors(ctx, items)
	return items, nil
}

func (u *ExcursionUseCase) ListGuideReviews(ctx context.Context, filter port.GuideReviewFilter) ([]*model.GuideReview, error) {
	if filter.GuideUserID == nil || *filter.GuideUserID == uuid.Nil {
		return nil, ErrInvalidActorUserID
	}
	if filter.Limit <= 0 {
		filter.Limit = 20
	}
	if filter.Limit > 100 {
		filter.Limit = 100
	}
	if filter.Offset < 0 {
		filter.Offset = 0
	}
	if filter.Sort == "" {
		filter.Sort = port.GuideReviewSortLatest
	}
	items, err := u.repo.ListGuideReviews(ctx, filter)
	if err != nil {
		return nil, fmt.Errorf("list guide reviews: %w", err)
	}
	u.enrichGuideReviewAuthors(ctx, items)
	return items, nil
}

func (u *ExcursionUseCase) enrichExcursionReviewAuthors(ctx context.Context, items []*model.ExcursionReview) {
	if len(items) == 0 {
		return
	}

	ids := make([]uuid.UUID, 0, len(items))
	seen := make(map[uuid.UUID]struct{}, len(items))
	for _, item := range items {
		if item == nil || item.TouristUserID == uuid.Nil {
			continue
		}
		item.Author.UserID = item.TouristUserID
		if _, ok := seen[item.TouristUserID]; ok {
			continue
		}
		seen[item.TouristUserID] = struct{}{}
		ids = append(ids, item.TouristUserID)
	}
	if len(ids) == 0 || u.userProfiles == nil {
		return
	}

	profiles, err := u.userProfiles.GetUserProfileProjections(ctx, ids)
	if err != nil {
		return
	}
	for _, item := range items {
		if item == nil || item.TouristUserID == uuid.Nil {
			continue
		}
		profile, ok := profiles[item.TouristUserID]
		if !ok {
			continue
		}
		item.Author.UserID = item.TouristUserID
		item.Author.DisplayName = profile.DisplayName
		item.Author.AvatarFileID = profile.AvatarFileID
	}
}

func (u *ExcursionUseCase) enrichGuideReviewAuthors(ctx context.Context, items []*model.GuideReview) {
	if len(items) == 0 {
		return
	}

	ids := make([]uuid.UUID, 0, len(items))
	seen := make(map[uuid.UUID]struct{}, len(items))
	for _, item := range items {
		if item == nil || item.TouristUserID == uuid.Nil {
			continue
		}
		if _, ok := seen[item.TouristUserID]; ok {
			continue
		}
		seen[item.TouristUserID] = struct{}{}
		ids = append(ids, item.TouristUserID)
	}
	if len(ids) == 0 || u.userProfiles == nil {
		for _, item := range items {
			if item != nil && item.Author.UserID == uuid.Nil {
				item.Author.UserID = item.TouristUserID
			}
		}
		return
	}

	profiles, err := u.userProfiles.GetUserProfileProjections(ctx, ids)
	if err != nil {
		for _, item := range items {
			if item != nil && item.Author.UserID == uuid.Nil {
				item.Author.UserID = item.TouristUserID
			}
		}
		return
	}
	for _, item := range items {
		if item == nil {
			continue
		}
		item.Author.UserID = item.TouristUserID
		if profile, ok := profiles[item.TouristUserID]; ok {
			item.Author.DisplayName = profile.DisplayName
			item.Author.AvatarFileID = profile.AvatarFileID
		}
	}
}

func (u *ExcursionUseCase) enrichExcursionBookingAuthors(ctx context.Context, items []*model.ExcursionBookingListItem) {
	if len(items) == 0 {
		return
	}

	ids := make([]uuid.UUID, 0, len(items))
	seen := make(map[uuid.UUID]struct{}, len(items))
	for _, item := range items {
		if item == nil || item.Booking == nil || item.Booking.TouristUserID == uuid.Nil {
			continue
		}
		item.Author.UserID = item.Booking.TouristUserID
		if _, ok := seen[item.Booking.TouristUserID]; ok {
			continue
		}
		seen[item.Booking.TouristUserID] = struct{}{}
		ids = append(ids, item.Booking.TouristUserID)
	}
	if len(ids) == 0 || u.userProfiles == nil {
		return
	}

	profiles, err := u.userProfiles.GetUserProfileProjections(ctx, ids)
	if err != nil {
		return
	}
	for _, item := range items {
		if item == nil || item.Booking == nil || item.Booking.TouristUserID == uuid.Nil {
			continue
		}
		profile, ok := profiles[item.Booking.TouristUserID]
		if !ok {
			continue
		}
		item.Author.UserID = item.Booking.TouristUserID
		item.Author.DisplayName = profile.DisplayName
		item.Author.AvatarFileID = profile.AvatarFileID
	}
}

func (u *ExcursionUseCase) ListMyExcursions(ctx context.Context, actorUserID uuid.UUID, limit int, offset int, statuses []string) ([]*ExcursionAggregate, error) {
	if actorUserID == uuid.Nil {
		return nil, ErrInvalidActorUserID
	}
	if limit <= 0 {
		limit = 20
	}
	if limit > 100 {
		limit = 100
	}
	filter := port.ExcursionFilter{
		GuideUserID: &actorUserID,
		Statuses:    statuses,
		Limit:       limit,
		Offset:      offset,
	}
	items, err := u.repo.ListExcursions(ctx, filter)
	if err != nil {
		return nil, fmt.Errorf("list my excursions: %w", err)
	}
	return u.loadAggregates(ctx, items)
}

func (u *ExcursionUseCase) getOwnedExcursionWithRelations(ctx context.Context, excursionID uuid.UUID, actorUserID uuid.UUID) (*model.Excursion, port.ExcursionRelations, error) {
	if actorUserID == uuid.Nil {
		return nil, port.ExcursionRelations{}, ErrInvalidActorUserID
	}
	if excursionID == uuid.Nil {
		return nil, port.ExcursionRelations{}, ErrInvalidExcursionID
	}
	item, err := u.repo.GetExcursionByID(ctx, excursionID)
	if err != nil {
		return nil, port.ExcursionRelations{}, fmt.Errorf("get excursion by id: %w", err)
	}
	if item == nil {
		return nil, port.ExcursionRelations{}, ErrExcursionNotFound
	}
	if !item.IsOwnedBy(actorUserID) {
		return nil, port.ExcursionRelations{}, ErrExcursionAccessDenied
	}
	relations, err := u.repo.LoadExcursionRelations(ctx, excursionID)
	if err != nil {
		return nil, port.ExcursionRelations{}, fmt.Errorf("load excursion relations: %w", err)
	}
	return item, relations, nil
}

func (u *ExcursionUseCase) loadAggregate(ctx context.Context, item *model.Excursion) (*ExcursionAggregate, error) {
	relations, err := u.repo.LoadExcursionRelations(ctx, item.ID)
	if err != nil {
		return nil, fmt.Errorf("load excursion relations: %w", err)
	}
	return &ExcursionAggregate{Excursion: item, Tags: relations.Tags, LanguageCodes: relations.LanguageCodes, IncludedItems: relations.IncludedItems, Itinerary: relations.Itinerary, CoverFileID: relations.CoverFileID, ProductCoverFileID: relations.ProductCoverFileID}, nil
}

func (u *ExcursionUseCase) loadAggregates(ctx context.Context, items []*model.Excursion) ([]*ExcursionAggregate, error) {
	result := make([]*ExcursionAggregate, 0, len(items))
	for _, item := range items {
		if item == nil {
			continue
		}
		aggregate, err := u.loadAggregate(ctx, item)
		if err != nil {
			return nil, err
		}
		result = append(result, aggregate)
	}
	return result, nil
}

func toProductCardAggregates(items []*model.ExcursionProductCard) []*ExcursionProductCardAggregate {
	result := make([]*ExcursionProductCardAggregate, 0, len(items))
	for _, item := range items {
		if item == nil {
			continue
		}
		result = append(result, &ExcursionProductCardAggregate{Product: item})
	}
	return result
}

func (u *ExcursionUseCase) verifyGuide(ctx context.Context, actorUserID uuid.UUID) (port.GuideExcursionPermission, error) {
	if u.guideVerifier == nil {
		return port.GuideExcursionPermission{
			GuideProfileID: actorUserID,
			GuideUserID:    actorUserID,
			Allowed:        true,
		}, nil
	}
	permission, err := u.guideVerifier.VerifyExcursionGuide(ctx, actorUserID)
	if err != nil {
		return port.GuideExcursionPermission{}, err
	}
	if !permission.Allowed || permission.GuideProfileID == uuid.Nil || permission.GuideUserID == uuid.Nil {
		return port.GuideExcursionPermission{}, ErrGuideNotAllowed
	}
	return permission, nil
}

func evaluateExcursionPublishing(item *model.Excursion, permission port.GuideExcursionPermission) model.ExcursionPublishingEvaluation {
	trustScore, trustReasons := calculateGuideTrustScore(permission)
	riskScore, riskReasons := calculateExcursionPublishRiskScore(item)
	reasons := append(trustReasons, riskReasons...)
	decision := model.ExcursionPublishingDecisionNeedsReview
	if trustScore >= excursionAutoPublishTrustThreshold && riskScore <= excursionAutoPublishRiskThreshold && len(reasons) == 0 {
		decision = model.ExcursionPublishingDecisionAutoPublish
	}
	return model.ExcursionPublishingEvaluation{
		Decision:         decision,
		GuideTrustScore:  trustScore,
		PublishRiskScore: riskScore,
		ReasonCodes:      reasons,
	}
}

func calculateGuideTrustScore(permission port.GuideExcursionPermission) (int, []string) {
	score := 0
	reasons := make([]string, 0, 2)
	if permission.Allowed {
		score += 25
	}
	switch {
	case permission.ReviewsCount >= 10:
		score += 25
	case permission.ReviewsCount >= 3:
		score += 15
	case permission.ReviewsCount > 0:
		score += 5
	default:
		reasons = append(reasons, "guide_new")
	}
	switch {
	case permission.RatingAvg >= 4.7:
		score += 20
	case permission.RatingAvg >= 4.3:
		score += 12
	case permission.RatingAvg > 0:
		score += 5
	}
	switch {
	case permission.ExperienceYears >= 2:
		score += 15
	case permission.ExperienceYears >= 1:
		score += 8
	}
	if score > 100 {
		score = 100
	}
	return score, reasons
}

func calculateExcursionPublishRiskScore(item *model.Excursion) (int, []string) {
	if item == nil {
		return 100, []string{"excursion_missing"}
	}
	score := 0
	reasons := make([]string, 0, 3)
	if item.LandmarkID == nil {
		score += 35
		reasons = append(reasons, "custom_route")
	}
	if item.DepartureCityID == nil {
		score += 20
		reasons = append(reasons, "departure_city_missing")
	}
	if item.DurationMinutes > 24*60 {
		score += 15
		reasons = append(reasons, "multi_day_duration")
	}
	if score > 100 {
		score = 100
	}
	return score, reasons
}

func (u *ExcursionUseCase) validateCoverFile(ctx context.Context, fileID *uuid.UUID) error {
	if fileID == nil || *fileID == uuid.Nil || u.fileManager == nil {
		return nil
	}
	return u.fileManager.ValidateExcursionCoverFile(ctx, *fileID)
}

func (u *ExcursionUseCase) validateCoverFiles(ctx context.Context, fileIDs ...*uuid.UUID) error {
	seen := make(map[uuid.UUID]struct{}, len(fileIDs))
	for _, fileID := range fileIDs {
		if fileID == nil || *fileID == uuid.Nil {
			continue
		}
		if _, ok := seen[*fileID]; ok {
			continue
		}
		seen[*fileID] = struct{}{}
		if err := u.validateCoverFile(ctx, fileID); err != nil {
			return err
		}
	}
	return nil
}

func (u *ExcursionUseCase) bindCoverFile(ctx context.Context, excursionID uuid.UUID, actorUserID uuid.UUID, fileID *uuid.UUID) {
	if fileID == nil || *fileID == uuid.Nil || u.fileManager == nil {
		return
	}
	_ = u.fileManager.BindExcursionCoverFile(ctx, *fileID, excursionID, actorUserID)
}

func (u *ExcursionUseCase) recordEvent(ctx context.Context, excursionID uuid.UUID, eventType enum.ExcursionEventType, actorUserID uuid.UUID, payload any) {
	actor := actorUserID
	event, err := model.NewExcursionEvent(model.NewExcursionEventParams{
		ExcursionID: excursionID,
		EventType:   eventType,
		ActorUserID: &actor,
		Payload:     payload,
	})
	if err != nil {
		return
	}
	_ = u.repo.CreateExcursionEvent(ctx, event)
}

var excursionTranslationLocales = []string{"en", "ru", "kk"}

func (u *ExcursionUseCase) translateItinerary(ctx context.Context, itinerary []ExcursionItineraryItemInput) ([]ExcursionItineraryItemInput, error) {
	if len(itinerary) == 0 {
		return itinerary, nil
	}

	result := make([]ExcursionItineraryItemInput, len(itinerary))
	copy(result, itinerary)
	jobsBySource := make(map[string][]itineraryTranslationJob)

	for index := range result {
		translations := model.NormalizeExcursionItineraryTranslations(result[index].Translations)
		sourceLocale, sourceCopy := chooseItinerarySourceCopy(result[index], translations)
		if sourceLocale == "" {
			result[index].Translations = translations
			continue
		}

		if translations == nil {
			translations = make(model.ExcursionItineraryTranslations, len(excursionTranslationLocales))
		}
		translations[sourceLocale] = sourceCopy

		missingLocales := missingItineraryTranslationLocales(sourceLocale, translations)
		if len(missingLocales) > 0 {
			jobsBySource[sourceLocale] = append(jobsBySource[sourceLocale], itineraryTranslationJob{
				itemIndex:      index,
				missingLocales: missingLocales,
				sourceCopy:     sourceCopy,
			})
		}

		result[index].Translations = model.NormalizeExcursionItineraryTranslations(translations)
	}

	if u.translator == nil || len(jobsBySource) == 0 {
		return result, nil
	}

	for sourceLocale, jobs := range jobsBySource {
		translated, err := u.translator.TranslateTexts(ctx, port.TranslationRequest{
			SourceLocale:  sourceLocale,
			TargetLocales: uniqueMissingLocales(jobs),
			Texts:         itineraryTranslationTexts(jobs),
		})
		if err != nil {
			return nil, fmt.Errorf("%w: %v", ErrExcursionTranslationFailed, err)
		}
		applyItineraryTranslationJobs(result, jobs, translated)
	}

	for index := range result {
		translations := model.NormalizeExcursionItineraryTranslations(result[index].Translations)
		sourceLocale, _ := chooseItinerarySourceCopy(result[index], translations)
		if sourceLocale != "" && len(missingItineraryTranslationLocales(sourceLocale, translations)) > 0 {
			return nil, ErrExcursionTranslationFailed
		}
		result[index].Translations = translations
	}

	return result, nil
}

func chooseItinerarySourceCopy(
	input ExcursionItineraryItemInput,
	translations model.ExcursionItineraryTranslations,
) (string, model.ExcursionItineraryLocalizedCopy) {
	for _, locale := range excursionTranslationLocales {
		copy, ok := translations[locale]
		if !ok || (strings.TrimSpace(copy.Title) == "" && strings.TrimSpace(copy.Description) == "") {
			continue
		}
		return locale, fillItineraryCopyFromBase(input, copy)
	}

	if len(translations) == 0 {
		return "", model.ExcursionItineraryLocalizedCopy{}
	}
	locales := make([]string, 0, len(translations))
	for locale := range translations {
		locales = append(locales, locale)
	}
	sort.Strings(locales)
	for _, locale := range locales {
		normalizedLocale := normalizeExcursionTranslationLocale(locale)
		if normalizedLocale == "" {
			continue
		}
		copy := fillItineraryCopyFromBase(input, translations[locale])
		if strings.TrimSpace(copy.Title) != "" || strings.TrimSpace(copy.Description) != "" {
			return normalizedLocale, copy
		}
	}
	return "", model.ExcursionItineraryLocalizedCopy{}
}

func fillItineraryCopyFromBase(
	input ExcursionItineraryItemInput,
	copy model.ExcursionItineraryLocalizedCopy,
) model.ExcursionItineraryLocalizedCopy {
	title := strings.Join(strings.Fields(strings.TrimSpace(copy.Title)), " ")
	if title == "" {
		title = strings.Join(strings.Fields(strings.TrimSpace(input.Title)), " ")
	}
	description := strings.TrimSpace(copy.Description)
	if description == "" {
		description = strings.TrimSpace(input.Description)
	}
	return model.ExcursionItineraryLocalizedCopy{Title: title, Description: description}
}

func missingItineraryTranslationLocales(
	sourceLocale string,
	translations model.ExcursionItineraryTranslations,
) []string {
	missing := make([]string, 0, len(excursionTranslationLocales)-1)
	for _, locale := range excursionTranslationLocales {
		if locale == sourceLocale {
			continue
		}
		copy := translations[locale]
		if strings.TrimSpace(copy.Title) == "" || strings.TrimSpace(copy.Description) == "" {
			missing = append(missing, locale)
		}
	}
	return missing
}

func uniqueMissingLocales(jobs []itineraryTranslationJob) []string {
	seen := make(map[string]struct{}, len(excursionTranslationLocales))
	result := make([]string, 0, len(excursionTranslationLocales))
	for _, job := range jobs {
		for _, locale := range job.missingLocales {
			if _, ok := seen[locale]; ok {
				continue
			}
			seen[locale] = struct{}{}
			result = append(result, locale)
		}
	}
	sort.Strings(result)
	return result
}

func itineraryTranslationTexts(jobs []itineraryTranslationJob) []string {
	texts := make([]string, 0, len(jobs)*2)
	for _, job := range jobs {
		texts = append(texts, job.sourceCopy.Title, job.sourceCopy.Description)
	}
	return texts
}

func applyItineraryTranslationJobs(
	items []ExcursionItineraryItemInput,
	jobs []itineraryTranslationJob,
	result port.TranslationResult,
) {
	for jobIndex, job := range jobs {
		if job.itemIndex < 0 || job.itemIndex >= len(items) {
			continue
		}
		translations := model.NormalizeExcursionItineraryTranslations(items[job.itemIndex].Translations)
		if translations == nil {
			translations = make(model.ExcursionItineraryTranslations, len(excursionTranslationLocales))
		}
		for _, locale := range job.missingLocales {
			texts := result.Translations[locale]
			titleIndex := jobIndex * 2
			descriptionIndex := titleIndex + 1
			if len(texts) <= descriptionIndex {
				continue
			}
			copy := translations[locale]
			title := strings.Join(strings.Fields(strings.TrimSpace(texts[titleIndex])), " ")
			description := strings.TrimSpace(texts[descriptionIndex])
			if title != "" {
				copy.Title = title
			}
			if description != "" {
				copy.Description = description
			}
			translations[locale] = copy
		}
		items[job.itemIndex].Translations = model.NormalizeExcursionItineraryTranslations(translations)
	}
}

func normalizeExcursionTranslationLocale(value string) string {
	normalized := strings.ToLower(strings.TrimSpace(value))
	if index := strings.IndexAny(normalized, "-_"); index >= 0 {
		normalized = normalized[:index]
	}
	for _, locale := range excursionTranslationLocales {
		if normalized == locale {
			return normalized
		}
	}
	return ""
}

func buildRelations(
	excursionID uuid.UUID,
	tags []string,
	languageCodes []string,
	includedItems []ExcursionIncludedItemInput,
	coverFileID *uuid.UUID,
	productCoverFileID *uuid.UUID,
	itinerary []ExcursionItineraryItemInput,
) (port.ExcursionRelations, error) {
	items := make([]*model.ExcursionItineraryItem, 0, len(itinerary))
	for index, input := range itinerary {
		sortOrder := index
		item, err := model.NewExcursionItineraryItem(model.NewExcursionItineraryItemParams{
			ExcursionID:               excursionID,
			SortOrder:                 sortOrder,
			StartOffsetMinutes:        input.StartOffsetMinutes,
			DurationMinutes:           input.DurationMinutes,
			AttractionID:              input.AttractionID,
			AttractionName:            input.AttractionName,
			Latitude:                  input.Latitude,
			Longitude:                 input.Longitude,
			TravelFromPreviousMinutes: input.TravelFromPreviousMinutes,
			Title:                     input.Title,
			Description:               input.Description,
			Translations:              input.Translations,
		})
		if err != nil {
			return port.ExcursionRelations{}, err
		}
		items = append(items, item)
	}

	relations := port.ExcursionRelations{
		Tags:               normalizeUniqueLower(tags),
		LanguageCodes:      normalizeUniqueLower(languageCodes),
		Itinerary:          items,
		CoverFileID:        normalizeUUIDPtr(coverFileID),
		ProductCoverFileID: normalizeUUIDPtr(productCoverFileID),
	}
	normalizedIncludedItems, err := normalizeIncludedItems(includedItems)
	if err != nil {
		return port.ExcursionRelations{}, err
	}
	relations.IncludedItems = normalizedIncludedItems
	return relations, nil
}

func normalizeUniqueLower(values []string) []string {
	seen := make(map[string]struct{}, len(values))
	result := make([]string, 0, len(values))
	for _, value := range values {
		normalized := strings.ToLower(strings.TrimSpace(value))
		if normalized == "" {
			continue
		}
		if _, ok := seen[normalized]; ok {
			continue
		}
		seen[normalized] = struct{}{}
		result = append(result, normalized)
	}
	sort.Strings(result)
	return result
}

func uniqueUUIDs(values []uuid.UUID) []uuid.UUID {
	result := make([]uuid.UUID, 0, len(values))
	seen := make(map[uuid.UUID]struct{}, len(values))
	for _, value := range values {
		if value == uuid.Nil {
			continue
		}
		if _, ok := seen[value]; ok {
			continue
		}
		seen[value] = struct{}{}
		result = append(result, value)
	}
	return result
}

func validateCombinedRouteInput(landmarkID *uuid.UUID, itinerary []ExcursionItineraryItemInput) error {
	if landmarkID != nil && *landmarkID != uuid.Nil {
		return nil
	}
	seen := make(map[uuid.UUID]struct{}, len(itinerary))
	for _, item := range itinerary {
		if item.AttractionID == nil || *item.AttractionID == uuid.Nil {
			continue
		}
		if _, ok := seen[*item.AttractionID]; ok {
			return ErrCombinedExcursionRouteDuplicateStop
		}
		seen[*item.AttractionID] = struct{}{}
	}
	if len(seen) < 2 {
		return ErrCombinedExcursionRouteRequiresTwoStops
	}
	if len(seen) > 5 {
		return ErrCombinedExcursionRouteTooManyStops
	}
	return nil
}

func hasItineraryAttractionStops(itinerary []ExcursionItineraryItemInput) bool {
	for _, item := range itinerary {
		if item.AttractionID != nil && *item.AttractionID != uuid.Nil {
			return true
		}
	}
	return false
}

func weeklyOccurrences(startDate time.Time, weekdays []int, startClock string, durationMinutes int, timezone string, until time.Time, maxOccurrences int) ([]time.Time, error) {
	if durationMinutes <= 0 || maxOccurrences <= 0 {
		return nil, model.ErrInvalidExcursionScheduleInterval
	}
	loc, err := time.LoadLocation(strings.TrimSpace(timezone))
	if err != nil {
		return nil, model.ErrInvalidExcursionScheduleTimezone
	}
	clock, err := time.Parse("15:04", strings.TrimSpace(startClock))
	if err != nil {
		return nil, model.ErrInvalidExcursionScheduleInterval
	}
	weekdaySet := make(map[int]struct{}, len(weekdays))
	for _, weekday := range weekdays {
		if weekday < 1 || weekday > 7 {
			return nil, model.ErrInvalidExcursionScheduleInterval
		}
		weekdaySet[weekday] = struct{}{}
	}
	if len(weekdaySet) == 0 {
		return nil, model.ErrInvalidExcursionScheduleInterval
	}

	localStart := startDate.In(loc)
	cursor := time.Date(localStart.Year(), localStart.Month(), localStart.Day(), clock.Hour(), clock.Minute(), 0, 0, loc)
	result := make([]time.Time, 0, maxOccurrences)
	for !cursor.After(until.In(loc)) && len(result) < maxOccurrences {
		isoWeekday := int(cursor.Weekday())
		if isoWeekday == 0 {
			isoWeekday = 7
		}
		if _, ok := weekdaySet[isoWeekday]; ok {
			result = append(result, cursor.UTC())
		}
		cursor = cursor.AddDate(0, 0, 1)
	}
	return result, nil
}

var allowedExcursionIncludedItemKeys = map[string]struct{}{
	"transport": {},
	"food":      {},
	"tickets":   {},
	"equipment": {},
	"guide":     {},
	"photo":     {},
}

func normalizeIncludedItems(values []ExcursionIncludedItemInput) ([]model.ExcursionIncludedItem, error) {
	seen := make(map[string]struct{}, len(values))
	result := make([]model.ExcursionIncludedItem, 0, len(values))
	for _, value := range values {
		key := strings.ToLower(strings.TrimSpace(value.Text))
		if key == "" {
			continue
		}
		if _, ok := allowedExcursionIncludedItemKeys[key]; !ok {
			return nil, ErrInvalidExcursionIncludedItem
		}
		if _, ok := seen[key]; ok {
			continue
		}
		seen[key] = struct{}{}
		result = append(result, model.NewExcursionIncludedItem(key, nil))
	}
	sort.Slice(result, func(i, j int) bool {
		return result[i].Text < result[j].Text
	})
	return result, nil
}

type excursionMarketingCopy = model.ExcursionLocalizedCopy

func attractionBasedExcursionCopy(landmarkName *string) model.ExcursionLocalizedCopy {
	name := strings.TrimSpace(optionalStringValue(landmarkName))
	if name == "" {
		name = "FlyFy excursion"
	}
	return model.ExcursionLocalizedCopy{
		Title:       name,
		Summary:     "Compare guide offers for " + name + ".",
		Description: "Choose a guide, language, price, meeting point, schedule, and included options before booking.",
	}
}

func combinedRouteMarketingCopy(input CreateExcursionInput) excursionMarketingCopy {
	names := make([]string, 0, len(input.Itinerary))
	seen := make(map[string]struct{}, len(input.Itinerary))
	for _, item := range input.Itinerary {
		if item.AttractionName == nil {
			continue
		}
		name := strings.TrimSpace(*item.AttractionName)
		key := strings.ToLower(name)
		if key == "" {
			continue
		}
		if _, ok := seen[key]; ok {
			continue
		}
		seen[key] = struct{}{}
		names = append(names, name)
	}
	if len(names) >= 2 {
		routeName := strings.Join(names, " + ")
		routeStops := strings.Join(names, ", ")
		return excursionMarketingCopy{
			Title:       routeName,
			Summary:     "Compare guide offers for " + routeName + ".",
			Description: "Choose a guide, language, price, meeting point, schedule, and included options before booking a route through " + routeStops + ".",
		}
	}
	return excursionMarketingCopy{
		Title:       "Guide route",
		Summary:     "Compare guide offers for this route.",
		Description: "Choose a guide, language, price, meeting point, and schedule before booking this route.",
	}
}

func optionalStringValue(value *string) string {
	if value == nil {
		return ""
	}
	return *value
}

func normalizeUUIDPtr(v *uuid.UUID) *uuid.UUID {
	if v == nil || *v == uuid.Nil {
		return nil
	}
	out := *v
	return &out
}
