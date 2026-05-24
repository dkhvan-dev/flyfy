package app

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/dkhvan-dev/flyfy/backend/services/excursion-service/internal/domain/enum"
	"github.com/dkhvan-dev/flyfy/backend/services/excursion-service/internal/domain/model"
	"github.com/dkhvan-dev/flyfy/backend/services/excursion-service/internal/domain/port"
)

type excursionRepoStub struct {
	createdExcursion                *model.Excursion
	createdRelations                port.ExcursionRelations
	gotExcursion                    *model.Excursion
	gotOffer                        *model.ExcursionOffer
	gotOfferByLegacy                *model.ExcursionOffer
	gotOfferByLegacyID              uuid.UUID
	savedExcursion                  *model.Excursion
	savedRelations                  port.ExcursionRelations
	createdBooking                  *model.ExcursionBooking
	createBookingErr                error
	existingBookingByKey            *model.ExcursionBooking
	existingBookingAfterKeyConflict *model.ExcursionBooking
	gotIdempotencyTouristID         uuid.UUID
	gotIdempotencyKey               string
	idempotencyLookupCount          int
	createdScheduleSlot             *model.ExcursionScheduleSlot
	createdScheduleSeries           *model.ExcursionScheduleSeries
	createdSeriesSlots              []*model.ExcursionScheduleSlot
	createScheduleSeriesErr         error
	createScheduleSlotErr           error
	gotScheduleSlot                 *model.ExcursionScheduleSlot
	reservedScheduleSlotID          uuid.UUID
	reservedScheduleSeats           int
	reserveScheduleErr              error
	expiredScheduleCutoff           time.Time
	expiredScheduleReason           string
	expireScheduleErr               error
	closedScheduleCutoff            time.Time
	closedScheduleLimit             int
	closedScheduleSlots             []*model.ExcursionScheduleSlot
	closeScheduleErr                error
	completedScheduleBefore         time.Time
	completedScheduleReason         string
	completedScheduleLimit          int
	completedScheduleCount          int
	createdAttendanceIssue          *model.ExcursionAttendanceQRIssue
	gotAttendanceIssue              *model.ExcursionAttendanceQRIssue
	gotAttendanceAttempt            *model.ExcursionAttendanceSyncAttempt
	createdAttendanceAttempt        *model.ExcursionAttendanceSyncAttempt
	gotAttendanceBooking            *model.ExcursionBooking
	checkedInAttendanceBooking      *model.ExcursionBooking
	txRepo                          port.ExcursionTxRepository
	txErr                           error
	txUsed                          bool
	listBookingFilter               port.ExcursionBookingFilter
	listBookingItems                []*model.ExcursionBookingListItem
	gotBooking                      *model.ExcursionBooking
	updatedBooking                  *model.ExcursionBooking
	updatedBookingSeatDelta         int
	updateBookingGuestsErr          error
	cancelledBooking                *model.ExcursionBooking
	cancelledBookingReleaseSeats    int
	cancelBookingErr                error
	createdReview                   *model.ExcursionReview
	createReviewFn                  func(item *model.ExcursionReview)
	updatedReview                   *model.ExcursionReview
	deletedReview                   *model.ExcursionReview
	createdGuideReview              *model.GuideReview
	updatedGuideReview              *model.GuideReview
	deletedGuideReview              *model.GuideReview
	existingGuideReview             *model.GuideReview
	landmarkReviewStatsID           uuid.UUID
	landmarkRatingAvg               float64
	landmarkReviewsCount            int
	existingReview                  *model.ExcursionReview
	listReviewFilter                port.ExcursionReviewFilter
	listReviewItems                 []*model.ExcursionReview
	listScheduleFilter              port.ExcursionScheduleFilter
	listScheduleSlots               []*model.ExcursionScheduleSlot
	listExcursionsFilter            port.ExcursionFilter
	listExcursions                  []*model.Excursion
	loadedRelations                 port.ExcursionRelations
	hasGuideLandmark                bool
	createAggregateFn               func(ctx context.Context, item *model.Excursion, relations port.ExcursionRelations) error
}

func (s *excursionRepoStub) CreateExcursionAggregate(ctx context.Context, item *model.Excursion, relations port.ExcursionRelations) error {
	s.createdExcursion = item
	s.createdRelations = relations
	if s.createAggregateFn != nil {
		return s.createAggregateFn(ctx, item, relations)
	}
	return nil
}

func (s *excursionRepoStub) UpdateExcursionAggregate(ctx context.Context, item *model.Excursion, relations port.ExcursionRelations) error {
	s.savedExcursion = item
	s.savedRelations = relations
	return nil
}

func (s *excursionRepoStub) UpdateExcursion(ctx context.Context, item *model.Excursion) error {
	s.savedExcursion = item
	return nil
}

func (s *excursionRepoStub) GetExcursionByID(ctx context.Context, excursionID uuid.UUID) (*model.Excursion, error) {
	return s.gotExcursion, nil
}

func (s *excursionRepoStub) ListExcursions(ctx context.Context, filter port.ExcursionFilter) ([]*model.Excursion, error) {
	s.listExcursionsFilter = filter
	return s.listExcursions, nil
}

func (s *excursionRepoStub) LoadExcursionRelations(ctx context.Context, excursionID uuid.UUID) (port.ExcursionRelations, error) {
	return s.loadedRelations, nil
}

func (s *excursionRepoStub) CreateExcursionEvent(ctx context.Context, item *model.ExcursionEvent) error {
	return nil
}

func (s *excursionRepoStub) ListExcursionProductCards(ctx context.Context, filter port.ExcursionProductFilter) ([]*model.ExcursionProductCard, error) {
	return nil, nil
}

func (s *excursionRepoStub) GetExcursionProductCardByID(ctx context.Context, productID uuid.UUID) (*model.ExcursionProductCard, error) {
	return nil, nil
}

func (s *excursionRepoStub) ListExcursionOffers(ctx context.Context, filter port.ExcursionOfferFilter) ([]*model.ExcursionOffer, error) {
	return nil, nil
}

func (s *excursionRepoStub) ListExcursionLanguageCodesByGuideUserIDs(ctx context.Context, guideUserIDs []uuid.UUID) (map[uuid.UUID][]string, error) {
	return nil, nil
}

func (s *excursionRepoStub) ListGuideUserIDsByExcursionCity(ctx context.Context, filter port.GuideExcursionCityFilter) ([]uuid.UUID, error) {
	return nil, nil
}

func (s *excursionRepoStub) HasActiveExcursionForGuideLandmark(ctx context.Context, guideUserID uuid.UUID, landmarkID uuid.UUID) (bool, error) {
	return s.hasGuideLandmark, nil
}

func (s *excursionRepoStub) ArchiveGuideExcursionOffers(context.Context, uuid.UUID) error {
	return nil
}

func (s *excursionRepoStub) GetExcursionOfferByID(ctx context.Context, offerID uuid.UUID) (*model.ExcursionOffer, error) {
	return s.gotOffer, nil
}

func (s *excursionRepoStub) GetExcursionOfferByLegacyExcursionID(ctx context.Context, legacyExcursionID uuid.UUID) (*model.ExcursionOffer, error) {
	s.gotOfferByLegacyID = legacyExcursionID
	return s.gotOfferByLegacy, nil
}

func (s *excursionRepoStub) LoadExcursionOfferRelations(ctx context.Context, offerID uuid.UUID) (port.ExcursionOfferRelations, error) {
	return port.ExcursionOfferRelations{}, nil
}

func (s *excursionRepoStub) CreateExcursionBooking(ctx context.Context, item *model.ExcursionBooking) error {
	s.createdBooking = item
	return s.createBookingErr
}

func (s *excursionRepoStub) GetExcursionBookingByTouristIDAndIdempotencyKey(ctx context.Context, touristUserID uuid.UUID, idempotencyKey string) (*model.ExcursionBooking, error) {
	s.gotIdempotencyTouristID = touristUserID
	s.gotIdempotencyKey = idempotencyKey
	s.idempotencyLookupCount++
	if s.idempotencyLookupCount > 1 && s.existingBookingAfterKeyConflict != nil {
		return s.existingBookingAfterKeyConflict, nil
	}
	return s.existingBookingByKey, nil
}

func (s *excursionRepoStub) CreateExcursionScheduleSlot(ctx context.Context, slot *model.ExcursionScheduleSlot) error {
	s.createdScheduleSlot = slot
	return s.createScheduleSlotErr
}

func (s *excursionRepoStub) CreateExcursionScheduleSeriesWithSlots(ctx context.Context, series *model.ExcursionScheduleSeries, slots []*model.ExcursionScheduleSlot) error {
	s.createdScheduleSeries = series
	s.createdSeriesSlots = slots
	return s.createScheduleSeriesErr
}

func (s *excursionRepoStub) UpdateExcursionScheduleSlot(ctx context.Context, slot *model.ExcursionScheduleSlot) error {
	s.createdScheduleSlot = slot
	return nil
}

func (s *excursionRepoStub) DeleteExcursionScheduleSlot(ctx context.Context, slotID uuid.UUID, guideUserID uuid.UUID) error {
	return nil
}

func (s *excursionRepoStub) GetExcursionScheduleSlotByID(ctx context.Context, slotID uuid.UUID) (*model.ExcursionScheduleSlot, error) {
	return s.gotScheduleSlot, nil
}

func (s *excursionRepoStub) ListExcursionScheduleSlots(ctx context.Context, filter port.ExcursionScheduleFilter) ([]*model.ExcursionScheduleSlot, error) {
	s.listScheduleFilter = filter
	return s.listScheduleSlots, nil
}

func (s *excursionRepoStub) ReserveExcursionScheduleSlotSeats(ctx context.Context, slotID uuid.UUID, seats int) error {
	s.reservedScheduleSlotID = slotID
	s.reservedScheduleSeats = seats
	return s.reserveScheduleErr
}

func (s *excursionRepoStub) ExpireUnbookedExcursionScheduleSlots(ctx context.Context, cutoff time.Time, reason string) error {
	s.expiredScheduleCutoff = cutoff
	s.expiredScheduleReason = reason
	return s.expireScheduleErr
}

func (s *excursionRepoStub) CloseBookedExcursionScheduleSlots(ctx context.Context, cutoff time.Time, limit int) ([]*model.ExcursionScheduleSlot, error) {
	s.closedScheduleCutoff = cutoff
	s.closedScheduleLimit = limit
	return s.closedScheduleSlots, s.closeScheduleErr
}

func (s *excursionRepoStub) CompleteDueExcursionScheduleSlots(ctx context.Context, before time.Time, reason string, limit int) (int, error) {
	s.completedScheduleBefore = before
	s.completedScheduleReason = reason
	s.completedScheduleLimit = limit
	return s.completedScheduleCount, nil
}

func (s *excursionRepoStub) CreateExcursionAttendanceQRIssue(ctx context.Context, item *model.ExcursionAttendanceQRIssue) error {
	s.createdAttendanceIssue = item
	return nil
}

func (s *excursionRepoStub) WithTx(ctx context.Context, fn func(repo port.ExcursionTxRepository) error) error {
	s.txUsed = true
	if s.txErr != nil {
		return s.txErr
	}
	txRepo := s.txRepo
	if txRepo == nil {
		txRepo = &excursionTxRepoStub{repo: s}
	}
	return fn(txRepo)
}

func (s *excursionRepoStub) ListExcursionBookings(ctx context.Context, filter port.ExcursionBookingFilter) ([]*model.ExcursionBookingListItem, error) {
	s.listBookingFilter = filter
	return s.listBookingItems, nil
}

func (s *excursionRepoStub) GetExcursionBookingByID(ctx context.Context, bookingID uuid.UUID) (*model.ExcursionBooking, error) {
	return s.gotBooking, nil
}

func (s *excursionRepoStub) UpdateExcursionBookingGuests(ctx context.Context, item *model.ExcursionBooking, seatDelta int) error {
	s.updatedBooking = item
	s.updatedBookingSeatDelta = seatDelta
	return s.updateBookingGuestsErr
}

func (s *excursionRepoStub) CancelExcursionBooking(ctx context.Context, item *model.ExcursionBooking) error {
	s.cancelledBooking = item
	if item != nil && item.ScheduleSlotID != nil {
		s.cancelledBookingReleaseSeats = item.TotalSeats
	}
	return s.cancelBookingErr
}

func (s *excursionRepoStub) CreateExcursionReview(ctx context.Context, item *model.ExcursionReview) error {
	s.createdReview = item
	if s.createReviewFn != nil {
		s.createReviewFn(item)
	}
	return nil
}

func (s *excursionRepoStub) UpdateExcursionReview(ctx context.Context, item *model.ExcursionReview) error {
	s.updatedReview = item
	return nil
}

func (s *excursionRepoStub) DeleteExcursionReview(ctx context.Context, item *model.ExcursionReview) error {
	s.deletedReview = item
	return nil
}

func (s *excursionRepoStub) GetExcursionReviewByBookingID(ctx context.Context, bookingID uuid.UUID) (*model.ExcursionReview, error) {
	return s.existingReview, nil
}

func (s *excursionRepoStub) CreateGuideReview(ctx context.Context, item *model.GuideReview) error {
	s.createdGuideReview = item
	return nil
}

func (s *excursionRepoStub) UpdateGuideReview(ctx context.Context, item *model.GuideReview) error {
	s.updatedGuideReview = item
	return nil
}

func (s *excursionRepoStub) DeleteGuideReview(ctx context.Context, item *model.GuideReview) error {
	s.deletedGuideReview = item
	return nil
}

func (s *excursionRepoStub) GetGuideReviewByBookingID(ctx context.Context, bookingID uuid.UUID) (*model.GuideReview, error) {
	return s.existingGuideReview, nil
}

func (s *excursionRepoStub) ListExcursionReviews(ctx context.Context, filter port.ExcursionReviewFilter) ([]*model.ExcursionReview, error) {
	s.listReviewFilter = filter
	return s.listReviewItems, nil
}

func (s *excursionRepoStub) ListGuideReviews(ctx context.Context, filter port.GuideReviewFilter) ([]*model.GuideReview, error) {
	return nil, nil
}

type excursionTxRepoStub struct {
	repo *excursionRepoStub
}

func (s *excursionTxRepoStub) CreateExcursionReview(ctx context.Context, item *model.ExcursionReview) error {
	return s.repo.CreateExcursionReview(ctx, item)
}

func (s *excursionTxRepoStub) UpdateExcursionReview(ctx context.Context, item *model.ExcursionReview) error {
	return s.repo.UpdateExcursionReview(ctx, item)
}

func (s *excursionTxRepoStub) DeleteExcursionReview(ctx context.Context, item *model.ExcursionReview) error {
	return s.repo.DeleteExcursionReview(ctx, item)
}

func (s *excursionTxRepoStub) GetExcursionReviewByBookingID(ctx context.Context, bookingID uuid.UUID) (*model.ExcursionReview, error) {
	return s.repo.GetExcursionReviewByBookingID(ctx, bookingID)
}

func (s *excursionTxRepoStub) CreateGuideReview(ctx context.Context, item *model.GuideReview) error {
	return s.repo.CreateGuideReview(ctx, item)
}

func (s *excursionTxRepoStub) UpdateGuideReview(ctx context.Context, item *model.GuideReview) error {
	return s.repo.UpdateGuideReview(ctx, item)
}

func (s *excursionTxRepoStub) DeleteGuideReview(ctx context.Context, item *model.GuideReview) error {
	return s.repo.DeleteGuideReview(ctx, item)
}

func (s *excursionTxRepoStub) GetGuideReviewByBookingID(ctx context.Context, bookingID uuid.UUID) (*model.GuideReview, error) {
	return s.repo.GetGuideReviewByBookingID(ctx, bookingID)
}

func (s *excursionTxRepoStub) GetExcursionAttendanceQRIssueByJTIForUpdate(ctx context.Context, jti uuid.UUID) (*model.ExcursionAttendanceQRIssue, error) {
	return s.repo.gotAttendanceIssue, nil
}

func (s *excursionTxRepoStub) GetExcursionAttendanceSyncAttemptByScanIDForUpdate(ctx context.Context, scanID uuid.UUID) (*model.ExcursionAttendanceSyncAttempt, error) {
	return s.repo.gotAttendanceAttempt, nil
}

func (s *excursionTxRepoStub) GetExcursionScheduleSlotByIDForUpdate(ctx context.Context, slotID uuid.UUID) (*model.ExcursionScheduleSlot, error) {
	return s.repo.gotScheduleSlot, nil
}

func (s *excursionTxRepoStub) GetExcursionBookingByScheduleSlotAndTouristForUpdate(ctx context.Context, slotID uuid.UUID, touristUserID uuid.UUID) (*model.ExcursionBooking, error) {
	return s.repo.gotAttendanceBooking, nil
}

func (s *excursionTxRepoStub) CreateExcursionAttendanceSyncAttempt(ctx context.Context, item *model.ExcursionAttendanceSyncAttempt) error {
	s.repo.createdAttendanceAttempt = item
	return nil
}

func (s *excursionTxRepoStub) UpdateExcursionBookingAttendance(ctx context.Context, item *model.ExcursionBooking) error {
	s.repo.checkedInAttendanceBooking = item
	return nil
}

func (s *excursionRepoStub) CalculateLandmarkReviewStats(ctx context.Context, landmarkID uuid.UUID) (float64, int, error) {
	s.landmarkReviewStatsID = landmarkID
	return s.landmarkRatingAvg, s.landmarkReviewsCount, nil
}

type guideVerifierStub struct {
	result port.GuideExcursionPermission
	err    error
}

func (s guideVerifierStub) VerifyExcursionGuide(ctx context.Context, userID uuid.UUID) (port.GuideExcursionPermission, error) {
	return s.result, s.err
}

type fileManagerStub struct {
	validated *uuid.UUID
	bound     *uuid.UUID
}

func (s *fileManagerStub) ValidateExcursionCoverFile(ctx context.Context, fileID uuid.UUID) error {
	s.validated = &fileID
	return nil
}

func (s *fileManagerStub) BindExcursionCoverFile(ctx context.Context, fileID uuid.UUID, excursionID uuid.UUID, createdByUserID uuid.UUID) error {
	s.bound = &fileID
	return nil
}

func (s *fileManagerStub) CreateDownloadURL(ctx context.Context, fileID uuid.UUID) (string, error) {
	return "https://cdn.example.test/excursion-cover.jpg", nil
}

type translatorStub struct {
	result port.TranslationResult
	err    error
	calls  []port.TranslationRequest
}

func (s *translatorStub) TranslateTexts(ctx context.Context, input port.TranslationRequest) (port.TranslationResult, error) {
	s.calls = append(s.calls, input)
	return s.result, s.err
}

type attractionRatingUpdaterStub struct {
	snapshots []port.AttractionRatingSnapshot
}

func (s *attractionRatingUpdaterStub) ApplyAttractionRatingSnapshot(ctx context.Context, snapshot port.AttractionRatingSnapshot) error {
	s.snapshots = append(s.snapshots, snapshot)
	return nil
}

type userProfileResolverStub struct {
	profiles map[uuid.UUID]port.UserProfileProjection
	requests [][]uuid.UUID
}

func (s *userProfileResolverStub) GetUserProfileProjections(ctx context.Context, userIDs []uuid.UUID) (map[uuid.UUID]port.UserProfileProjection, error) {
	copied := append([]uuid.UUID(nil), userIDs...)
	s.requests = append(s.requests, copied)
	return s.profiles, nil
}

type excursionChatGatewayStub struct {
	synced *port.SyncExcursionScheduleSlotConversationInput
}

var (
	testExcursionCountryCode = "KZ"
	testExcursionCityName    = "Almaty"
	testExcursionLatitude    = 43.238949
	testExcursionLongitude   = 76.889709
)

func (s *excursionChatGatewayStub) SyncExcursionScheduleSlotConversation(
	_ context.Context,
	input port.SyncExcursionScheduleSlotConversationInput,
) error {
	copyInput := input
	copyInput.ParticipantUserIDs = append([]uuid.UUID(nil), input.ParticipantUserIDs...)
	s.synced = &copyInput
	return nil
}

func TestCreateExcursionRequiresActiveExcursionGuide(t *testing.T) {
	repo := &excursionRepoStub{}
	uc := NewExcursionUseCase(repo, guideVerifierStub{err: ErrGuideNotAllowed}, nil)

	_, err := uc.CreateExcursion(context.Background(), CreateExcursionInput{
		ActorUserID:     uuid.New(),
		CategorySlug:    "nature",
		DurationMinutes: 240,
		MaxGroupSize:    8,
		LanguageCodes:   []string{"en"},
		CountryCode:     &testExcursionCountryCode,
		CityName:        &testExcursionCityName,
		MeetingPoint:    "Hotel pickup",
		Latitude:        &testExcursionLatitude,
		Longitude:       &testExcursionLongitude,
		PriceAmount:     120,
		Currency:        "USD",
		Itinerary: []ExcursionItineraryItemInput{
			{StartOffsetMinutes: 0, Title: "Hotel departure", Description: "Meet your guide and start the route."},
		},
	})

	if !errors.Is(err, ErrGuideNotAllowed) {
		t.Fatalf("error = %v, want %v", err, ErrGuideNotAllowed)
	}
	if repo.createdExcursion != nil {
		t.Fatal("excursion was persisted for a non-authorized guide")
	}
}

func TestCreateExcursionRejectsRouteWithoutLandmarkOrAttractionStops(t *testing.T) {
	repo := &excursionRepoStub{}
	actorUserID := uuid.New()
	uc := NewExcursionUseCase(repo, guideVerifierStub{
		result: port.GuideExcursionPermission{
			GuideProfileID: uuid.New(),
			GuideUserID:    actorUserID,
			Allowed:        true,
		},
	}, nil)

	_, err := uc.CreateExcursion(context.Background(), CreateExcursionInput{
		ActorUserID:     actorUserID,
		LandmarkName:    stringPtr("Custom place"),
		DurationMinutes: 240,
		MaxGroupSize:    8,
		LanguageCodes:   []string{"en"},
		CountryCode:     &testExcursionCountryCode,
		CityName:        &testExcursionCityName,
		MeetingPoint:    "Hotel pickup",
		Latitude:        &testExcursionLatitude,
		Longitude:       &testExcursionLongitude,
		PriceAmount:     120,
		Currency:        "USD",
		Itinerary: []ExcursionItineraryItemInput{
			{StartOffsetMinutes: 0, Title: "Hotel departure", Description: "Meet your guide and start the route."},
		},
	})

	if !errors.Is(err, ErrCombinedExcursionRouteRequiresTwoStops) {
		t.Fatalf("error = %v, want %v", err, ErrCombinedExcursionRouteRequiresTwoStops)
	}
	if repo.createdExcursion != nil {
		t.Fatal("excursion was persisted without a landmark or combined route")
	}
}

func TestCreateExcursionAcceptsCombinedRouteWithoutLandmark(t *testing.T) {
	repo := &excursionRepoStub{}
	actorUserID := uuid.New()
	a := uuid.New()
	b := uuid.New()
	uc := NewExcursionUseCase(repo, guideVerifierStub{
		result: port.GuideExcursionPermission{
			GuideProfileID: uuid.New(),
			GuideUserID:    actorUserID,
			Allowed:        true,
		},
	}, nil)

	aggregate, err := uc.CreateExcursion(context.Background(), CreateExcursionInput{
		ActorUserID:     actorUserID,
		CategorySlug:    "culture",
		Visibility:      "PUBLIC",
		DurationMinutes: 180,
		MaxGroupSize:    8,
		LanguageCodes:   []string{"en"},
		CountryCode:     stringPtr("KZ"),
		CityName:        stringPtr("Almaty"),
		MeetingPoint:    "Hotel pickup",
		Latitude:        &testExcursionLatitude,
		Longitude:       &testExcursionLongitude,
		PriceAmount:     45000,
		Currency:        "KZT",
		Itinerary: []ExcursionItineraryItemInput{
			{StartOffsetMinutes: 0, AttractionID: &a, AttractionName: stringPtr("Kok-Tobe"), Title: "Kok-Tobe", Description: "Start with the city view."},
			{StartOffsetMinutes: 60, AttractionID: &b, AttractionName: stringPtr("Cathedral"), Title: "Cathedral", Description: "Visit the cathedral story."},
		},
	})

	if err != nil {
		t.Fatalf("CreateExcursion() error = %v", err)
	}
	if aggregate.Excursion.LandmarkID != nil {
		t.Fatalf("LandmarkID = %v, want nil for combined route", aggregate.Excursion.LandmarkID)
	}
	if aggregate.Excursion.Summary != "Compare guide offers for Kok-Tobe + Cathedral." {
		t.Fatalf("Summary = %q, want route-aware copy", aggregate.Excursion.Summary)
	}
	if aggregate.Excursion.Description != "Choose a guide, language, price, meeting point, schedule, and included options before booking a route through Kok-Tobe, Cathedral." {
		t.Fatalf("Description = %q, want route-aware copy", aggregate.Excursion.Description)
	}
	if len(repo.createdRelations.Itinerary) != 2 {
		t.Fatalf("itinerary length = %d, want 2", len(repo.createdRelations.Itinerary))
	}
}

func TestCreateExcursionRejectsCombinedRouteWithOneAttractionStop(t *testing.T) {
	repo := &excursionRepoStub{}
	actorUserID := uuid.New()
	a := uuid.New()
	uc := NewExcursionUseCase(repo, guideVerifierStub{
		result: port.GuideExcursionPermission{
			GuideProfileID: uuid.New(),
			GuideUserID:    actorUserID,
			Allowed:        true,
		},
	}, nil)

	_, err := uc.CreateExcursion(context.Background(), CreateExcursionInput{
		ActorUserID:     actorUserID,
		CategorySlug:    "culture",
		Visibility:      "PUBLIC",
		DurationMinutes: 90,
		MaxGroupSize:    8,
		LanguageCodes:   []string{"en"},
		CountryCode:     &testExcursionCountryCode,
		CityName:        &testExcursionCityName,
		MeetingPoint:    "Hotel pickup",
		Latitude:        &testExcursionLatitude,
		Longitude:       &testExcursionLongitude,
		PriceAmount:     30000,
		Currency:        "KZT",
		Itinerary: []ExcursionItineraryItemInput{
			{StartOffsetMinutes: 0, AttractionID: &a, AttractionName: stringPtr("Kok-Tobe"), Title: "Kok-Tobe", Description: "Only one stop."},
		},
	})

	if !errors.Is(err, ErrCombinedExcursionRouteRequiresTwoStops) {
		t.Fatalf("error = %v, want %v", err, ErrCombinedExcursionRouteRequiresTwoStops)
	}
}

func TestCreateExcursionRejectsCombinedRouteDuplicateAttractionStop(t *testing.T) {
	repo := &excursionRepoStub{}
	actorUserID := uuid.New()
	a := uuid.New()
	uc := NewExcursionUseCase(repo, guideVerifierStub{
		result: port.GuideExcursionPermission{
			GuideProfileID: uuid.New(),
			GuideUserID:    actorUserID,
			Allowed:        true,
		},
	}, nil)

	_, err := uc.CreateExcursion(context.Background(), CreateExcursionInput{
		ActorUserID:     actorUserID,
		CategorySlug:    "culture",
		Visibility:      "PUBLIC",
		DurationMinutes: 90,
		MaxGroupSize:    8,
		LanguageCodes:   []string{"en"},
		CountryCode:     &testExcursionCountryCode,
		CityName:        &testExcursionCityName,
		MeetingPoint:    "Hotel pickup",
		Latitude:        &testExcursionLatitude,
		Longitude:       &testExcursionLongitude,
		PriceAmount:     30000,
		Currency:        "KZT",
		Itinerary: []ExcursionItineraryItemInput{
			{StartOffsetMinutes: 0, AttractionID: &a, AttractionName: stringPtr("Kok-Tobe"), Title: "Kok-Tobe", Description: "First stop."},
			{StartOffsetMinutes: 60, AttractionID: &a, AttractionName: stringPtr("Kok-Tobe"), Title: "Kok-Tobe again", Description: "Duplicate stop."},
		},
	})

	if !errors.Is(err, ErrCombinedExcursionRouteDuplicateStop) {
		t.Fatalf("error = %v, want %v", err, ErrCombinedExcursionRouteDuplicateStop)
	}
	if repo.createdExcursion != nil {
		t.Fatal("excursion was persisted despite duplicate attraction stop")
	}
}

func TestCreateExcursionRejectsCombinedRouteTooManyAttractionStops(t *testing.T) {
	repo := &excursionRepoStub{}
	actorUserID := uuid.New()
	uc := NewExcursionUseCase(repo, guideVerifierStub{
		result: port.GuideExcursionPermission{
			GuideProfileID: uuid.New(),
			GuideUserID:    actorUserID,
			Allowed:        true,
		},
	}, nil)
	itinerary := make([]ExcursionItineraryItemInput, 0, 6)
	for i := 0; i < 6; i++ {
		attractionID := uuid.New()
		itinerary = append(itinerary, ExcursionItineraryItemInput{
			StartOffsetMinutes: i * 30,
			AttractionID:       &attractionID,
			AttractionName:     stringPtr("Stop"),
			Title:              "Stop",
			Description:        "A valid route stop.",
		})
	}

	_, err := uc.CreateExcursion(context.Background(), CreateExcursionInput{
		ActorUserID:     actorUserID,
		CategorySlug:    "culture",
		Visibility:      "PUBLIC",
		DurationMinutes: 240,
		MaxGroupSize:    8,
		LanguageCodes:   []string{"en"},
		CountryCode:     &testExcursionCountryCode,
		CityName:        &testExcursionCityName,
		MeetingPoint:    "Hotel pickup",
		Latitude:        &testExcursionLatitude,
		Longitude:       &testExcursionLongitude,
		PriceAmount:     30000,
		Currency:        "KZT",
		Itinerary:       itinerary,
	})

	if !errors.Is(err, ErrCombinedExcursionRouteTooManyStops) {
		t.Fatalf("error = %v, want %v", err, ErrCombinedExcursionRouteTooManyStops)
	}
	if repo.createdExcursion != nil {
		t.Fatal("excursion was persisted despite too many attraction stops")
	}
}

func TestCreateExcursionNormalizesNilLandmarkIDForCombinedRoute(t *testing.T) {
	repo := &excursionRepoStub{}
	actorUserID := uuid.New()
	nilLandmarkID := uuid.Nil
	a := uuid.New()
	b := uuid.New()
	uc := NewExcursionUseCase(repo, guideVerifierStub{
		result: port.GuideExcursionPermission{
			GuideProfileID: uuid.New(),
			GuideUserID:    actorUserID,
			Allowed:        true,
		},
	}, nil)

	aggregate, err := uc.CreateExcursion(context.Background(), CreateExcursionInput{
		ActorUserID:     actorUserID,
		LandmarkID:      &nilLandmarkID,
		LandmarkName:    stringPtr("Should be ignored"),
		CategorySlug:    "culture",
		Visibility:      "PUBLIC",
		DurationMinutes: 180,
		MaxGroupSize:    8,
		LanguageCodes:   []string{"en"},
		CountryCode:     &testExcursionCountryCode,
		CityName:        &testExcursionCityName,
		MeetingPoint:    "Hotel pickup",
		Latitude:        &testExcursionLatitude,
		Longitude:       &testExcursionLongitude,
		PriceAmount:     45000,
		Currency:        "KZT",
		Itinerary: []ExcursionItineraryItemInput{
			{StartOffsetMinutes: 0, AttractionID: &a, AttractionName: stringPtr("Kok-Tobe"), Title: "Kok-Tobe", Description: "Start with the city view."},
			{StartOffsetMinutes: 60, AttractionID: &b, AttractionName: stringPtr("Cathedral"), Title: "Cathedral", Description: "Visit the cathedral story."},
		},
	})

	if err != nil {
		t.Fatalf("CreateExcursion() error = %v", err)
	}
	if aggregate.Excursion.LandmarkID != nil {
		t.Fatalf("LandmarkID = %v, want nil", aggregate.Excursion.LandmarkID)
	}
	if aggregate.Excursion.LandmarkName != nil {
		t.Fatalf("LandmarkName = %v, want nil", aggregate.Excursion.LandmarkName)
	}
}

func TestCreateExcursionPersistsDraftAggregate(t *testing.T) {
	coverFileID := uuid.New()
	repo := &excursionRepoStub{}
	files := &fileManagerStub{}
	guideProfileID := uuid.New()
	actorUserID := uuid.New()
	uc := NewExcursionUseCase(repo, guideVerifierStub{
		result: port.GuideExcursionPermission{
			GuideProfileID: guideProfileID,
			GuideUserID:    actorUserID,
			Allowed:        true,
		},
	}, files)

	aggregate, err := uc.CreateExcursion(context.Background(), CreateExcursionInput{
		ActorUserID:     actorUserID,
		LandmarkID:      uuidPtr(uuid.New()),
		LandmarkName:    stringPtr("Medeu"),
		CategorySlug:    "nature",
		Visibility:      "PUBLIC",
		DurationMinutes: 240,
		MaxGroupSize:    8,
		LanguageCodes:   []string{"EN", "ru"},
		CountryCode:     &testExcursionCountryCode,
		CityName:        &testExcursionCityName,
		MeetingPoint:    "Hotel pickup",
		Latitude:        &testExcursionLatitude,
		Longitude:       &testExcursionLongitude,
		PriceAmount:     120,
		Currency:        "usd",
		CoverFileID:     &coverFileID,
		IncludedItems: []ExcursionIncludedItemInput{
			{Text: "transport"},
			{Text: "food"},
		},
		Itinerary: []ExcursionItineraryItemInput{
			{StartOffsetMinutes: 0, Title: "Hotel departure", Description: "Meet your guide and start the route."},
		},
	})

	if err != nil {
		t.Fatalf("CreateExcursion() error = %v", err)
	}
	if aggregate.Excursion.GuideProfileID != guideProfileID {
		t.Fatalf("guide profile id = %s, want %s", aggregate.Excursion.GuideProfileID, guideProfileID)
	}
	if repo.createdExcursion == nil {
		t.Fatal("excursion was not persisted")
	}
	if len(repo.createdRelations.LanguageCodes) != 2 || repo.createdRelations.LanguageCodes[0] != "en" {
		t.Fatalf("language codes = %#v, want normalized codes", repo.createdRelations.LanguageCodes)
	}
	if files.validated == nil || *files.validated != coverFileID {
		t.Fatal("cover file was not validated")
	}
	if files.bound == nil || *files.bound != coverFileID {
		t.Fatal("cover file was not bound to the excursion")
	}
	if len(repo.createdRelations.IncludedItems) != 2 ||
		repo.createdRelations.IncludedItems[0].Text != "food" ||
		repo.createdRelations.IncludedItems[1].Text != "transport" {
		t.Fatalf("included items = %#v, want stable dictionary keys", repo.createdRelations.IncludedItems)
	}
}

func TestListMyExcursionsKeepsProductCoverFallback(t *testing.T) {
	guideUserID := uuid.New()
	productCoverFileID := uuid.New()
	excursion, err := model.NewExcursion(model.NewExcursionParams{
		GuideProfileID:  uuid.New(),
		GuideUserID:     guideUserID,
		LandmarkID:      uuidPtr(uuid.New()),
		LandmarkName:    stringPtr("Medeu"),
		Title:           "Medeu tour",
		Summary:         "Private mountain route",
		Description:     "A detailed mountain excursion through Medeu.",
		CategorySlug:    "nature",
		Visibility:      enum.ExcursionVisibilityPublic,
		DurationMinutes: 180,
		MaxGroupSize:    6,
		CountryCode:     &testExcursionCountryCode,
		CityName:        &testExcursionCityName,
		MeetingPoint:    "Medeu entrance",
		Latitude:        &testExcursionLatitude,
		Longitude:       &testExcursionLongitude,
		PriceAmount:     120,
		Currency:        "KZT",
	})
	if err != nil {
		t.Fatalf("NewExcursion() error = %v", err)
	}
	repo := &excursionRepoStub{
		listExcursions: []*model.Excursion{excursion},
		loadedRelations: port.ExcursionRelations{
			ProductCoverFileID: &productCoverFileID,
		},
	}
	uc := NewExcursionUseCase(repo, nil, nil)

	items, err := uc.ListMyExcursions(context.Background(), guideUserID, 20, 0, nil)

	if err != nil {
		t.Fatalf("ListMyExcursions() error = %v", err)
	}
	if len(items) != 1 {
		t.Fatalf("items = %d, want 1", len(items))
	}
	if items[0].CoverFileID != nil {
		t.Fatalf("cover file id = %v, want nil offer cover", items[0].CoverFileID)
	}
	if items[0].ProductCoverFileID == nil || *items[0].ProductCoverFileID != productCoverFileID {
		t.Fatalf("product cover file id = %v, want %s", items[0].ProductCoverFileID, productCoverFileID)
	}
}

func TestPublishExcursionSendsNewGuideToPendingReview(t *testing.T) {
	guideProfileID := uuid.New()
	guideUserID := uuid.New()
	excursion := mustNewAppTestExcursion(t, guideProfileID, guideUserID)
	departureCityID := "almaty"
	excursion.DepartureCityID = &departureCityID
	repo := &excursionRepoStub{
		gotExcursion:    excursion,
		loadedRelations: validAppTestExcursionRelations(excursion.ID),
	}
	uc := NewExcursionUseCase(repo, guideVerifierStub{
		result: port.GuideExcursionPermission{
			GuideProfileID:  guideProfileID,
			GuideUserID:     guideUserID,
			Allowed:         true,
			RatingAvg:       0,
			ReviewsCount:    0,
			ExperienceYears: 0,
		},
	}, nil)

	aggregate, err := uc.PublishExcursion(context.Background(), excursion.ID, guideUserID)

	if err != nil {
		t.Fatalf("PublishExcursion() error = %v", err)
	}
	if aggregate.Excursion.Status != enum.ExcursionStatusPendingReview {
		t.Fatalf("status = %q, want %q", aggregate.Excursion.Status, enum.ExcursionStatusPendingReview)
	}
	if repo.savedExcursion == nil {
		t.Fatal("excursion was not persisted")
	}
	if repo.savedExcursion.PublishedAt != nil {
		t.Fatalf("PublishedAt = %v, want nil while pending review", repo.savedExcursion.PublishedAt)
	}
	if repo.savedExcursion.SubmittedForReviewAt == nil {
		t.Fatal("SubmittedForReviewAt is nil")
	}
	if repo.savedExcursion.PublishingDecision != model.ExcursionPublishingDecisionNeedsReview {
		t.Fatalf("decision = %q, want %q", repo.savedExcursion.PublishingDecision, model.ExcursionPublishingDecisionNeedsReview)
	}
	if repo.savedExcursion.GuideTrustScore >= 70 {
		t.Fatalf("guide trust score = %d, want below auto-publish threshold", repo.savedExcursion.GuideTrustScore)
	}
	if !containsString(repo.savedExcursion.ModerationReasonCodes, "guide_new") {
		t.Fatalf("reason codes = %#v, want guide_new", repo.savedExcursion.ModerationReasonCodes)
	}
}

func TestPublishExcursionAutoPublishesTrustedLowRiskGuide(t *testing.T) {
	guideProfileID := uuid.New()
	guideUserID := uuid.New()
	excursion := mustNewAppTestExcursion(t, guideProfileID, guideUserID)
	departureCityID := "almaty"
	excursion.DepartureCityID = &departureCityID
	repo := &excursionRepoStub{
		gotExcursion:    excursion,
		loadedRelations: validAppTestExcursionRelations(excursion.ID),
	}
	uc := NewExcursionUseCase(repo, guideVerifierStub{
		result: port.GuideExcursionPermission{
			GuideProfileID:  guideProfileID,
			GuideUserID:     guideUserID,
			Allowed:         true,
			RatingAvg:       4.8,
			ReviewsCount:    12,
			ExperienceYears: 2,
		},
	}, nil)

	aggregate, err := uc.PublishExcursion(context.Background(), excursion.ID, guideUserID)

	if err != nil {
		t.Fatalf("PublishExcursion() error = %v", err)
	}
	if aggregate.Excursion.Status != enum.ExcursionStatusPublished {
		t.Fatalf("status = %q, want %q", aggregate.Excursion.Status, enum.ExcursionStatusPublished)
	}
	if repo.savedExcursion.PublishedAt == nil {
		t.Fatal("PublishedAt is nil")
	}
	if repo.savedExcursion.SubmittedForReviewAt != nil {
		t.Fatalf("SubmittedForReviewAt = %v, want nil for auto-publish", repo.savedExcursion.SubmittedForReviewAt)
	}
	if repo.savedExcursion.PublishingDecision != model.ExcursionPublishingDecisionAutoPublish {
		t.Fatalf("decision = %q, want %q", repo.savedExcursion.PublishingDecision, model.ExcursionPublishingDecisionAutoPublish)
	}
	if repo.savedExcursion.GuideTrustScore < 70 {
		t.Fatalf("guide trust score = %d, want auto-publish threshold", repo.savedExcursion.GuideTrustScore)
	}
	if repo.savedExcursion.PublishRiskScore > 30 {
		t.Fatalf("publish risk score = %d, want low risk", repo.savedExcursion.PublishRiskScore)
	}
}

func TestApproveExcursionModerationPublishesPendingReview(t *testing.T) {
	excursion := mustNewAppTestExcursion(t, uuid.New(), uuid.New())
	relations := validAppTestExcursionRelations(excursion.ID)
	if err := excursion.SubmitForReview(model.SubmitExcursionForReviewParams{
		Publish: model.PublishExcursionParams{
			LanguageCodes: relations.LanguageCodes,
			Itinerary:     relations.Itinerary,
		},
		Evaluation: model.ExcursionPublishingEvaluation{
			Decision:         model.ExcursionPublishingDecisionNeedsReview,
			GuideTrustScore:  35,
			PublishRiskScore: 45,
			ReasonCodes:      []string{"guide_new"},
		},
	}); err != nil {
		t.Fatalf("SubmitForReview() error = %v", err)
	}
	repo := &excursionRepoStub{
		gotExcursion:    excursion,
		loadedRelations: relations,
	}
	uc := NewExcursionUseCase(repo, nil, nil)

	aggregate, err := uc.ApproveExcursionModeration(context.Background(), excursion.ID, uuid.New())

	if err != nil {
		t.Fatalf("ApproveExcursionModeration() error = %v", err)
	}
	if aggregate.Excursion.Status != enum.ExcursionStatusPublished {
		t.Fatalf("status = %q, want %q", aggregate.Excursion.Status, enum.ExcursionStatusPublished)
	}
	if repo.savedExcursion == nil || repo.savedExcursion.PublishedAt == nil {
		t.Fatal("approved excursion was not persisted with PublishedAt")
	}
}

func TestRejectExcursionModerationMarksPendingReviewRejected(t *testing.T) {
	excursion := mustNewAppTestExcursion(t, uuid.New(), uuid.New())
	relations := validAppTestExcursionRelations(excursion.ID)
	if err := excursion.SubmitForReview(model.SubmitExcursionForReviewParams{
		Publish: model.PublishExcursionParams{
			LanguageCodes: relations.LanguageCodes,
			Itinerary:     relations.Itinerary,
		},
		Evaluation: model.ExcursionPublishingEvaluation{
			Decision:         model.ExcursionPublishingDecisionNeedsReview,
			GuideTrustScore:  35,
			PublishRiskScore: 45,
			ReasonCodes:      []string{"guide_new"},
		},
	}); err != nil {
		t.Fatalf("SubmitForReview() error = %v", err)
	}
	repo := &excursionRepoStub{
		gotExcursion:    excursion,
		loadedRelations: relations,
	}
	uc := NewExcursionUseCase(repo, nil, nil)

	aggregate, err := uc.RejectExcursionModeration(context.Background(), excursion.ID, uuid.New(), []string{"missing_license"})

	if err != nil {
		t.Fatalf("RejectExcursionModeration() error = %v", err)
	}
	if aggregate.Excursion.Status != enum.ExcursionStatusRejected {
		t.Fatalf("status = %q, want %q", aggregate.Excursion.Status, enum.ExcursionStatusRejected)
	}
	if repo.savedExcursion == nil {
		t.Fatal("rejected excursion was not persisted")
	}
	if repo.savedExcursion.PublishedAt != nil {
		t.Fatalf("PublishedAt = %v, want nil", repo.savedExcursion.PublishedAt)
	}
	if !containsString(repo.savedExcursion.ModerationReasonCodes, "missing_license") {
		t.Fatalf("reason codes = %#v, want missing_license", repo.savedExcursion.ModerationReasonCodes)
	}
}

func TestCreateExcursionRejectsDuplicateGuideLandmark(t *testing.T) {
	repo := &excursionRepoStub{hasGuideLandmark: true}
	guideUserID := uuid.New()
	uc := NewExcursionUseCase(repo, guideVerifierStub{
		result: port.GuideExcursionPermission{
			GuideProfileID: uuid.New(),
			GuideUserID:    guideUserID,
			Allowed:        true,
		},
	}, nil)

	_, err := uc.CreateExcursion(context.Background(), CreateExcursionInput{
		ActorUserID:     guideUserID,
		LandmarkID:      uuidPtr(uuid.New()),
		LandmarkName:    stringPtr("Katon-Karagay National Park"),
		CategorySlug:    "nature",
		Visibility:      "PUBLIC",
		DurationMinutes: 240,
		MaxGroupSize:    8,
		LanguageCodes:   []string{"ru"},
		CountryCode:     &testExcursionCountryCode,
		CityName:        &testExcursionCityName,
		MeetingPoint:    "Visitor center",
		Latitude:        &testExcursionLatitude,
		Longitude:       &testExcursionLongitude,
		PriceAmount:     120,
		Currency:        "USD",
		Itinerary: []ExcursionItineraryItemInput{
			{StartOffsetMinutes: 0, Title: "Start", Description: "Meet your guide."},
		},
	})

	if !errors.Is(err, model.ErrExcursionGuideLandmarkAlreadyExists) {
		t.Fatalf("error = %v, want %v", err, model.ErrExcursionGuideLandmarkAlreadyExists)
	}
	if repo.createdExcursion != nil {
		t.Fatal("duplicate guide landmark excursion was persisted")
	}
}

func TestCreateExcursionTranslatesItineraryBeforePersisting(t *testing.T) {
	repo := &excursionRepoStub{}
	translator := &translatorStub{
		result: port.TranslationResult{
			Translations: map[string][]string{
				"en": {"Hotel departure", "Meet your guide and start the route."},
				"kk": {"Қонақүйден шығу", "Гидпен кездесіп, маршрутты бастаңыз."},
			},
		},
	}
	actorUserID := uuid.New()
	uc := NewExcursionUseCase(repo, guideVerifierStub{
		result: port.GuideExcursionPermission{
			GuideProfileID: uuid.New(),
			GuideUserID:    actorUserID,
			Allowed:        true,
		},
	}, nil, translator)

	_, err := uc.CreateExcursion(context.Background(), CreateExcursionInput{
		ActorUserID:     actorUserID,
		LandmarkID:      uuidPtr(uuid.New()),
		LandmarkName:    stringPtr("Medeu"),
		CategorySlug:    "nature",
		Visibility:      "PUBLIC",
		DurationMinutes: 240,
		MaxGroupSize:    8,
		LanguageCodes:   []string{"ru"},
		CountryCode:     &testExcursionCountryCode,
		CityName:        &testExcursionCityName,
		MeetingPoint:    "Hotel pickup",
		Latitude:        &testExcursionLatitude,
		Longitude:       &testExcursionLongitude,
		PriceAmount:     120,
		Currency:        "USD",
		Itinerary: []ExcursionItineraryItemInput{
			{
				StartOffsetMinutes: 0,
				Title:              "Выезд из отеля",
				Description:        "Встречаемся с гидом и начинаем маршрут.",
				Translations: model.ExcursionItineraryTranslations{
					"ru": {Title: "Выезд из отеля", Description: "Встречаемся с гидом и начинаем маршрут."},
				},
			},
		},
	})

	if err != nil {
		t.Fatalf("CreateExcursion() error = %v", err)
	}
	if len(translator.calls) != 1 {
		t.Fatalf("translator calls = %d, want 1", len(translator.calls))
	}
	if translator.calls[0].SourceLocale != "ru" {
		t.Fatalf("source locale = %q, want ru", translator.calls[0].SourceLocale)
	}
	got := repo.createdRelations.Itinerary[0].Translations
	if got["ru"].Title != "Выезд из отеля" || got["ru"].Description == "" {
		t.Fatalf("source translation = %#v, want persisted ru copy", got["ru"])
	}
	if got["en"].Title != "Hotel departure" || got["kk"].Title != "Қонақүйден шығу" {
		t.Fatalf("translations = %#v, want generated en and kk copies", got)
	}
}

func TestCreateExcursionBatchesItineraryTranslationBySourceLocale(t *testing.T) {
	repo := &excursionRepoStub{}
	translator := &translatorStub{
		result: port.TranslationResult{
			Translations: map[string][]string{
				"en": {
					"Hotel departure", "Meet your guide and start the route.",
					"Viewpoint walk", "We stop for photos.",
				},
				"kk": {
					"Қонақүйден шығу", "Гидпен кездесіп, маршрутты бастаңыз.",
					"Шолу алаңына серуен", "Суретке түсу үшін тоқтаймыз.",
				},
			},
		},
	}
	actorUserID := uuid.New()
	uc := NewExcursionUseCase(repo, guideVerifierStub{
		result: port.GuideExcursionPermission{
			GuideProfileID: uuid.New(),
			GuideUserID:    actorUserID,
			Allowed:        true,
		},
	}, nil, translator)

	_, err := uc.CreateExcursion(context.Background(), CreateExcursionInput{
		ActorUserID:     actorUserID,
		LandmarkID:      uuidPtr(uuid.New()),
		LandmarkName:    stringPtr("Medeu"),
		CategorySlug:    "nature",
		Visibility:      "PUBLIC",
		DurationMinutes: 240,
		MaxGroupSize:    8,
		LanguageCodes:   []string{"ru"},
		CountryCode:     &testExcursionCountryCode,
		CityName:        &testExcursionCityName,
		MeetingPoint:    "Hotel pickup",
		Latitude:        &testExcursionLatitude,
		Longitude:       &testExcursionLongitude,
		PriceAmount:     120,
		Currency:        "USD",
		Itinerary: []ExcursionItineraryItemInput{
			{
				StartOffsetMinutes: 0,
				Title:              "Выезд из отеля",
				Description:        "Встречаемся с гидом и начинаем маршрут.",
				Translations: model.ExcursionItineraryTranslations{
					"ru": {Title: "Выезд из отеля", Description: "Встречаемся с гидом и начинаем маршрут."},
				},
			},
			{
				StartOffsetMinutes: 60,
				Title:              "Прогулка к смотровой",
				Description:        "Останавливаемся для фото.",
				Translations: model.ExcursionItineraryTranslations{
					"ru": {Title: "Прогулка к смотровой", Description: "Останавливаемся для фото."},
				},
			},
		},
	})

	if err != nil {
		t.Fatalf("CreateExcursion() error = %v", err)
	}
	if len(translator.calls) != 1 {
		t.Fatalf("translator calls = %d, want 1 batched call", len(translator.calls))
	}
	if len(translator.calls[0].Texts) != 4 {
		t.Fatalf("translated text count = %d, want 4", len(translator.calls[0].Texts))
	}
	got := repo.createdRelations.Itinerary[1].Translations
	if got["en"].Title != "Viewpoint walk" || got["kk"].Description != "Суретке түсу үшін тоқтаймыз." {
		t.Fatalf("second item translations = %#v, want batched generated copies", got)
	}
}

func TestCreateExcursionRejectsIncompleteItineraryTranslation(t *testing.T) {
	repo := &excursionRepoStub{}
	translator := &translatorStub{
		result: port.TranslationResult{
			Translations: map[string][]string{
				"en": {"Hotel departure", "Meet your guide and start the route."},
			},
		},
	}
	actorUserID := uuid.New()
	uc := NewExcursionUseCase(repo, guideVerifierStub{
		result: port.GuideExcursionPermission{
			GuideProfileID: uuid.New(),
			GuideUserID:    actorUserID,
			Allowed:        true,
		},
	}, nil, translator)

	_, err := uc.CreateExcursion(context.Background(), CreateExcursionInput{
		ActorUserID:     actorUserID,
		LandmarkID:      uuidPtr(uuid.New()),
		LandmarkName:    stringPtr("Medeu"),
		CategorySlug:    "nature",
		Visibility:      "PUBLIC",
		DurationMinutes: 240,
		MaxGroupSize:    8,
		LanguageCodes:   []string{"ru"},
		CountryCode:     &testExcursionCountryCode,
		CityName:        &testExcursionCityName,
		MeetingPoint:    "Hotel pickup",
		Latitude:        &testExcursionLatitude,
		Longitude:       &testExcursionLongitude,
		PriceAmount:     120,
		Currency:        "USD",
		Itinerary: []ExcursionItineraryItemInput{
			{
				StartOffsetMinutes: 0,
				Title:              "Выезд из отеля",
				Description:        "Встречаемся с гидом и начинаем маршрут.",
				Translations: model.ExcursionItineraryTranslations{
					"ru": {Title: "Выезд из отеля", Description: "Встречаемся с гидом и начинаем маршрут."},
				},
			},
		},
	})

	if !errors.Is(err, ErrExcursionTranslationFailed) {
		t.Fatalf("error = %v, want %v", err, ErrExcursionTranslationFailed)
	}
	if repo.createdExcursion != nil {
		t.Fatal("excursion was persisted with incomplete itinerary translations")
	}
}

func TestCreateExcursionRejectsFreeTextIncludedItem(t *testing.T) {
	repo := &excursionRepoStub{}
	actorUserID := uuid.New()
	uc := NewExcursionUseCase(repo, guideVerifierStub{
		result: port.GuideExcursionPermission{
			GuideProfileID: uuid.New(),
			GuideUserID:    actorUserID,
			Allowed:        true,
		},
	}, nil)

	_, err := uc.CreateExcursion(context.Background(), CreateExcursionInput{
		ActorUserID:     actorUserID,
		LandmarkID:      uuidPtr(uuid.New()),
		LandmarkName:    stringPtr("Medeu"),
		CategorySlug:    "nature",
		Visibility:      "PUBLIC",
		DurationMinutes: 240,
		MaxGroupSize:    8,
		LanguageCodes:   []string{"en"},
		CountryCode:     &testExcursionCountryCode,
		CityName:        &testExcursionCityName,
		MeetingPoint:    "Hotel pickup",
		Latitude:        &testExcursionLatitude,
		Longitude:       &testExcursionLongitude,
		PriceAmount:     120,
		Currency:        "USD",
		IncludedItems: []ExcursionIncludedItemInput{
			{Text: "Private SUV"},
		},
		Itinerary: []ExcursionItineraryItemInput{
			{StartOffsetMinutes: 0, Title: "Hotel departure", Description: "Meet your guide and start the route."},
		},
	})

	if !errors.Is(err, ErrInvalidExcursionIncludedItem) {
		t.Fatalf("error = %v, want %v", err, ErrInvalidExcursionIncludedItem)
	}
	if repo.createdExcursion != nil {
		t.Fatal("excursion was persisted with a free-text included item")
	}
}

func TestCreateExcursionPersistsGuideSearchSnapshot(t *testing.T) {
	repo := &excursionRepoStub{}
	guideProfileID := uuid.New()
	actorUserID := uuid.New()
	uc := NewExcursionUseCase(repo, guideVerifierStub{
		result: port.GuideExcursionPermission{
			GuideProfileID:  guideProfileID,
			GuideUserID:     actorUserID,
			Allowed:         true,
			DisplayName:     "Aruzhan T.",
			Nickname:        "@aru_t",
			FirstName:       "Aruzhan",
			LastName:        "Khan",
			GuideSearchText: "Aruzhan T. @aru_t local canyon expert",
		},
	}, nil)

	aggregate, err := uc.CreateExcursion(context.Background(), CreateExcursionInput{
		ActorUserID:     actorUserID,
		LandmarkID:      uuidPtr(uuid.New()),
		LandmarkName:    stringPtr("Charyn Canyon"),
		CategorySlug:    "nature",
		Visibility:      "PUBLIC",
		DurationMinutes: 240,
		MaxGroupSize:    8,
		LanguageCodes:   []string{"en"},
		CountryCode:     &testExcursionCountryCode,
		CityName:        &testExcursionCityName,
		MeetingPoint:    "Hotel pickup",
		Latitude:        &testExcursionLatitude,
		Longitude:       &testExcursionLongitude,
		PriceAmount:     120,
		Currency:        "USD",
		Itinerary: []ExcursionItineraryItemInput{
			{StartOffsetMinutes: 0, Title: "Hotel departure", Description: "Meet your guide and start the route."},
		},
	})

	if err != nil {
		t.Fatalf("CreateExcursion() error = %v", err)
	}
	if aggregate.Excursion.GuideDisplayName != "Aruzhan T." {
		t.Fatalf("guide display name = %q, want snapshot display name", aggregate.Excursion.GuideDisplayName)
	}
	if aggregate.Excursion.GuideSearchText != "Aruzhan T. @aru_t local canyon expert" {
		t.Fatalf("guide search text = %q, want snapshot search text", aggregate.Excursion.GuideSearchText)
	}
	if aggregate.Excursion.GuideNickname != "@aru_t" {
		t.Fatalf("guide nickname = %q, want snapshot nickname", aggregate.Excursion.GuideNickname)
	}
	if aggregate.Excursion.GuideLastName != "Khan" || aggregate.Excursion.GuideFirstName != "Aruzhan" {
		t.Fatalf("guide full name = %q %q, want Khan Aruzhan", aggregate.Excursion.GuideLastName, aggregate.Excursion.GuideFirstName)
	}
	if repo.createdExcursion.GuideDisplayName != aggregate.Excursion.GuideDisplayName ||
		repo.createdExcursion.GuideNickname != aggregate.Excursion.GuideNickname ||
		repo.createdExcursion.GuideFirstName != aggregate.Excursion.GuideFirstName ||
		repo.createdExcursion.GuideLastName != aggregate.Excursion.GuideLastName ||
		repo.createdExcursion.GuideSearchText != aggregate.Excursion.GuideSearchText {
		t.Fatal("guide search snapshot was not persisted with the excursion aggregate")
	}
}

func TestListPendingReviewExcursionsUsesPendingStatus(t *testing.T) {
	excursion := &model.Excursion{
		ID:              uuid.New(),
		GuideProfileID:  uuid.New(),
		GuideUserID:     uuid.New(),
		Title:           "Medeu tour",
		Summary:         "Private mountain route",
		Description:     "A detailed mountain excursion through Medeu.",
		CategorySlug:    "nature",
		Status:          enum.ExcursionStatusPendingReview,
		Visibility:      enum.ExcursionVisibilityPublic,
		DurationMinutes: 180,
		MaxGroupSize:    6,
		MeetingPoint:    "Medeu entrance",
		PriceAmount:     120,
		Currency:        "KZT",
		Revision:        1,
		CreatedAt:       time.Now().UTC(),
		UpdatedAt:       time.Now().UTC(),
	}
	repo := &excursionRepoStub{listExcursions: []*model.Excursion{excursion}}
	uc := NewExcursionUseCase(repo, guideVerifierStub{}, nil)

	aggregates, err := uc.ListPendingReviewExcursions(context.Background(), 25, 3)
	if err != nil {
		t.Fatalf("ListPendingReviewExcursions() error = %v", err)
	}
	if len(aggregates) != 1 || aggregates[0].Excursion.ID != excursion.ID {
		t.Fatalf("aggregates = %#v, want pending excursion", aggregates)
	}
	filter := repo.listExcursionsFilter
	if len(filter.Statuses) != 1 || filter.Statuses[0] != string(enum.ExcursionStatusPendingReview) {
		t.Fatalf("statuses = %#v, want PENDING_REVIEW", filter.Statuses)
	}
	if filter.Limit != 25 || filter.Offset != 3 {
		t.Fatalf("pagination = limit %d offset %d, want 25/3", filter.Limit, filter.Offset)
	}
	if filter.Visibility != nil {
		t.Fatalf("visibility = %v, want nil for moderation queue", *filter.Visibility)
	}
}

func TestGetModerationExcursionAllowsPendingReview(t *testing.T) {
	excursion := &model.Excursion{
		ID:              uuid.New(),
		GuideProfileID:  uuid.New(),
		GuideUserID:     uuid.New(),
		Title:           "Medeu tour",
		Summary:         "Private mountain route",
		Description:     "A detailed mountain excursion through Medeu.",
		CategorySlug:    "nature",
		Status:          enum.ExcursionStatusPendingReview,
		Visibility:      enum.ExcursionVisibilityPublic,
		DurationMinutes: 180,
		MaxGroupSize:    6,
		MeetingPoint:    "Medeu entrance",
		PriceAmount:     120,
		Currency:        "KZT",
		Revision:        1,
		CreatedAt:       time.Now().UTC(),
		UpdatedAt:       time.Now().UTC(),
	}
	repo := &excursionRepoStub{gotExcursion: excursion}
	uc := NewExcursionUseCase(repo, guideVerifierStub{}, nil)

	aggregate, err := uc.GetModerationExcursion(context.Background(), excursion.ID)
	if err != nil {
		t.Fatalf("GetModerationExcursion() error = %v", err)
	}
	if aggregate.Excursion.ID != excursion.ID {
		t.Fatalf("excursion id = %s, want %s", aggregate.Excursion.ID, excursion.ID)
	}
}

func TestUpdateExcursionRejectsNonOwner(t *testing.T) {
	ownerID := uuid.New()
	excursion, err := model.NewExcursion(model.NewExcursionParams{
		GuideProfileID:  uuid.New(),
		GuideUserID:     ownerID,
		LandmarkID:      uuidPtr(uuid.New()),
		LandmarkName:    stringPtr("Medeu"),
		Title:           "Almaty Mountain Escape",
		Summary:         "Private mountain route",
		Description:     "A guided route through the most scenic mountain stops around Almaty.",
		CategorySlug:    "nature",
		Visibility:      "PUBLIC",
		DurationMinutes: 240,
		MaxGroupSize:    8,
		CountryCode:     &testExcursionCountryCode,
		CityName:        &testExcursionCityName,
		MeetingPoint:    "Hotel pickup",
		Latitude:        &testExcursionLatitude,
		Longitude:       &testExcursionLongitude,
		PriceAmount:     120,
		Currency:        "USD",
	})
	if err != nil {
		t.Fatalf("NewExcursion() error = %v", err)
	}

	repo := &excursionRepoStub{gotExcursion: excursion}
	uc := NewExcursionUseCase(repo, guideVerifierStub{}, nil)

	_, err = uc.UpdateExcursion(context.Background(), UpdateExcursionInput{
		ActorUserID:     uuid.New(),
		ExcursionID:     excursion.ID,
		CategorySlug:    "nature",
		DurationMinutes: 240,
		MaxGroupSize:    8,
		LanguageCodes:   []string{"en"},
		CountryCode:     &testExcursionCountryCode,
		CityName:        &testExcursionCityName,
		MeetingPoint:    "Hotel pickup",
		Latitude:        &testExcursionLatitude,
		Longitude:       &testExcursionLongitude,
		PriceAmount:     120,
		Currency:        "USD",
		Itinerary: []ExcursionItineraryItemInput{
			{StartOffsetMinutes: 0, Title: "Hotel departure", Description: "Meet your guide and start the route."},
		},
	})

	if !errors.Is(err, ErrExcursionAccessDenied) {
		t.Fatalf("error = %v, want %v", err, ErrExcursionAccessDenied)
	}
	if repo.savedExcursion != nil {
		t.Fatal("excursion was updated by a non-owner")
	}
}

func TestArchiveExcursionKeepsOfferVisibleForGuideArchive(t *testing.T) {
	ownerID := uuid.New()
	excursion, err := model.NewExcursion(model.NewExcursionParams{
		GuideProfileID:  uuid.New(),
		GuideUserID:     ownerID,
		LandmarkID:      uuidPtr(uuid.New()),
		LandmarkName:    stringPtr("Medeu"),
		Title:           "Almaty Mountain Escape",
		Summary:         "Private mountain route",
		Description:     "A guided route through the most scenic mountain stops around Almaty.",
		CategorySlug:    "nature",
		Visibility:      enum.ExcursionVisibilityPublic,
		DurationMinutes: 240,
		MaxGroupSize:    8,
		CountryCode:     &testExcursionCountryCode,
		CityName:        &testExcursionCityName,
		MeetingPoint:    "Hotel pickup",
		Latitude:        &testExcursionLatitude,
		Longitude:       &testExcursionLongitude,
		PriceAmount:     120,
		Currency:        "USD",
	})
	if err != nil {
		t.Fatalf("NewExcursion() error = %v", err)
	}

	repo := &excursionRepoStub{gotExcursion: excursion}
	uc := NewExcursionUseCase(repo, guideVerifierStub{}, nil)

	aggregate, err := uc.ArchiveExcursion(context.Background(), excursion.ID, ownerID)
	if err != nil {
		t.Fatalf("ArchiveExcursion() error = %v", err)
	}
	if aggregate.Excursion.Status != enum.ExcursionStatusArchived {
		t.Fatalf("status = %s, want %s", aggregate.Excursion.Status, enum.ExcursionStatusArchived)
	}
	if aggregate.Excursion.DeletedAt != nil {
		t.Fatalf("DeletedAt = %v, want nil", aggregate.Excursion.DeletedAt)
	}
	if repo.savedExcursion == nil {
		t.Fatal("archived excursion was not persisted")
	}
}

func TestUpdatePublishedExcursionKeepsOriginalPublicationTime(t *testing.T) {
	ownerID := uuid.New()
	publishedAt := time.Date(2026, 1, 2, 3, 4, 5, 0, time.UTC)
	excursion, err := model.NewExcursion(model.NewExcursionParams{
		GuideProfileID:  uuid.New(),
		GuideUserID:     ownerID,
		LandmarkID:      uuidPtr(uuid.New()),
		LandmarkName:    stringPtr("Medeu"),
		Title:           "Almaty Mountain Escape",
		Summary:         "Private mountain route",
		Description:     "A guided route through the most scenic mountain stops around Almaty.",
		CategorySlug:    "nature",
		Visibility:      enum.ExcursionVisibilityPublic,
		DurationMinutes: 240,
		MaxGroupSize:    8,
		CountryCode:     &testExcursionCountryCode,
		CityName:        &testExcursionCityName,
		MeetingPoint:    "Hotel pickup",
		Latitude:        &testExcursionLatitude,
		Longitude:       &testExcursionLongitude,
		PriceAmount:     120,
		Currency:        "USD",
	})
	if err != nil {
		t.Fatalf("NewExcursion() error = %v", err)
	}
	excursion.Status = enum.ExcursionStatusPublished
	excursion.PublishedAt = &publishedAt

	repo := &excursionRepoStub{gotExcursion: excursion}
	uc := NewExcursionUseCase(repo, guideVerifierStub{
		result: port.GuideExcursionPermission{
			GuideProfileID: excursion.GuideProfileID,
			GuideUserID:    ownerID,
			Allowed:        true,
		},
	}, nil)

	_, err = uc.UpdateExcursion(context.Background(), UpdateExcursionInput{
		ActorUserID:     ownerID,
		ExcursionID:     excursion.ID,
		CategorySlug:    "nature",
		Visibility:      string(enum.ExcursionVisibilityPublic),
		DurationMinutes: 260,
		MaxGroupSize:    8,
		LanguageCodes:   []string{"en", "ru"},
		CountryCode:     &testExcursionCountryCode,
		CityName:        &testExcursionCityName,
		MeetingPoint:    "Hotel pickup",
		Latitude:        &testExcursionLatitude,
		Longitude:       &testExcursionLongitude,
		PriceAmount:     140,
		Currency:        "USD",
		Itinerary: []ExcursionItineraryItemInput{
			{StartOffsetMinutes: 0, Title: "Hotel departure", Description: "Meet your guide and start the route."},
		},
	})
	if err != nil {
		t.Fatalf("UpdateExcursion() error = %v", err)
	}
	if repo.savedExcursion == nil {
		t.Fatal("excursion was not saved")
	}
	if repo.savedExcursion.Status != enum.ExcursionStatusPublished {
		t.Fatalf("status = %s, want %s", repo.savedExcursion.Status, enum.ExcursionStatusPublished)
	}
	if repo.savedExcursion.PublishedAt == nil || !repo.savedExcursion.PublishedAt.Equal(publishedAt) {
		t.Fatalf("publishedAt = %v, want %v", repo.savedExcursion.PublishedAt, publishedAt)
	}
}

func TestUpdateExcursionTranslatesItineraryBeforePersisting(t *testing.T) {
	ownerID := uuid.New()
	excursion, err := model.NewExcursion(model.NewExcursionParams{
		GuideProfileID:  uuid.New(),
		GuideUserID:     ownerID,
		LandmarkID:      uuidPtr(uuid.New()),
		LandmarkName:    stringPtr("Medeu"),
		Title:           "Medeu",
		Summary:         "Compare guide offers for Medeu.",
		Description:     "Choose a guide, language, price, meeting point, schedule, and included options before booking.",
		CategorySlug:    "nature",
		Visibility:      "PUBLIC",
		DurationMinutes: 240,
		MaxGroupSize:    8,
		CountryCode:     &testExcursionCountryCode,
		CityName:        &testExcursionCityName,
		MeetingPoint:    "Hotel pickup",
		Latitude:        &testExcursionLatitude,
		Longitude:       &testExcursionLongitude,
		PriceAmount:     120,
		Currency:        "USD",
	})
	if err != nil {
		t.Fatalf("NewExcursion() error = %v", err)
	}

	repo := &excursionRepoStub{gotExcursion: excursion}
	translator := &translatorStub{
		result: port.TranslationResult{
			Translations: map[string][]string{
				"en": {"Walk to the viewpoint", "We stop for photos and a short story."},
				"kk": {"Шолу алаңына серуен", "Суретке түсіп, қысқа әңгіме тыңдаймыз."},
			},
		},
	}
	uc := NewExcursionUseCase(repo, guideVerifierStub{
		result: port.GuideExcursionPermission{
			GuideProfileID: excursion.GuideProfileID,
			GuideUserID:    ownerID,
			Allowed:        true,
		},
	}, nil, translator)

	_, err = uc.UpdateExcursion(context.Background(), UpdateExcursionInput{
		ActorUserID:     ownerID,
		ExcursionID:     excursion.ID,
		CategorySlug:    "nature",
		Visibility:      string(enum.ExcursionVisibilityPublic),
		DurationMinutes: 260,
		MaxGroupSize:    8,
		LanguageCodes:   []string{"ru"},
		CountryCode:     &testExcursionCountryCode,
		CityName:        &testExcursionCityName,
		MeetingPoint:    "Hotel pickup",
		Latitude:        &testExcursionLatitude,
		Longitude:       &testExcursionLongitude,
		PriceAmount:     140,
		Currency:        "USD",
		Itinerary: []ExcursionItineraryItemInput{
			{
				StartOffsetMinutes: 60,
				Title:              "Прогулка к смотровой",
				Description:        "Останавливаемся для фото и короткого рассказа.",
				Translations: model.ExcursionItineraryTranslations{
					"ru": {Title: "Прогулка к смотровой", Description: "Останавливаемся для фото и короткого рассказа."},
				},
			},
		},
	})

	if err != nil {
		t.Fatalf("UpdateExcursion() error = %v", err)
	}
	got := repo.savedRelations.Itinerary[0].Translations
	if got["en"].Title != "Walk to the viewpoint" || got["kk"].Description == "" {
		t.Fatalf("translations = %#v, want generated copies before save", got)
	}
}

func TestUpdateExcursionAppliesCombinedRouteInput(t *testing.T) {
	ownerID := uuid.New()
	landmarkID := uuid.New()
	excursion, err := model.NewExcursion(model.NewExcursionParams{
		GuideProfileID:  uuid.New(),
		GuideUserID:     ownerID,
		LandmarkID:      &landmarkID,
		LandmarkName:    stringPtr("Medeu"),
		Title:           "Medeu",
		Summary:         "Compare guide offers for Medeu.",
		Description:     "Choose a guide, language, price, meeting point, schedule, and included options before booking.",
		CategorySlug:    "nature",
		Visibility:      enum.ExcursionVisibilityPublic,
		DurationMinutes: 120,
		MaxGroupSize:    8,
		CountryCode:     &testExcursionCountryCode,
		CityName:        &testExcursionCityName,
		MeetingPoint:    "Hotel pickup",
		Latitude:        &testExcursionLatitude,
		Longitude:       &testExcursionLongitude,
		PriceAmount:     120,
		Currency:        "USD",
	})
	if err != nil {
		t.Fatalf("NewExcursion() error = %v", err)
	}

	a := uuid.New()
	b := uuid.New()
	repo := &excursionRepoStub{gotExcursion: excursion}
	uc := NewExcursionUseCase(repo, guideVerifierStub{
		result: port.GuideExcursionPermission{
			GuideProfileID: excursion.GuideProfileID,
			GuideUserID:    ownerID,
			Allowed:        true,
		},
	}, nil)

	_, err = uc.UpdateExcursion(context.Background(), UpdateExcursionInput{
		ActorUserID:     ownerID,
		ExcursionID:     excursion.ID,
		LandmarkID:      nil,
		LandmarkName:    nil,
		CategorySlug:    "culture",
		Visibility:      string(enum.ExcursionVisibilityPublic),
		DurationMinutes: 180,
		MaxGroupSize:    8,
		LanguageCodes:   []string{"en"},
		CountryCode:     &testExcursionCountryCode,
		CityName:        stringPtr("Almaty"),
		MeetingPoint:    "Hotel pickup",
		Latitude:        &testExcursionLatitude,
		Longitude:       &testExcursionLongitude,
		PriceAmount:     45000,
		Currency:        "KZT",
		Itinerary: []ExcursionItineraryItemInput{
			{StartOffsetMinutes: 0, AttractionID: &a, AttractionName: stringPtr("Kok-Tobe"), Title: "Kok-Tobe", Description: "Start with the city view."},
			{StartOffsetMinutes: 60, AttractionID: &b, AttractionName: stringPtr("Cathedral"), Title: "Cathedral", Description: "Visit the cathedral story."},
		},
	})

	if err != nil {
		t.Fatalf("UpdateExcursion() error = %v", err)
	}
	if repo.savedExcursion == nil {
		t.Fatal("excursion was not saved")
	}
	if repo.savedExcursion.LandmarkID != nil {
		t.Fatalf("LandmarkID = %v, want nil for combined route", repo.savedExcursion.LandmarkID)
	}
	if repo.savedExcursion.CategorySlug != "culture" {
		t.Fatalf("CategorySlug = %q, want culture", repo.savedExcursion.CategorySlug)
	}
	if repo.savedExcursion.Title != "Kok-Tobe + Cathedral" {
		t.Fatalf("Title = %q, want combined route copy", repo.savedExcursion.Title)
	}
	if repo.savedExcursion.Summary != "Compare guide offers for Kok-Tobe + Cathedral." {
		t.Fatalf("Summary = %q, want route-aware copy", repo.savedExcursion.Summary)
	}
	if repo.savedExcursion.Description != "Choose a guide, language, price, meeting point, schedule, and included options before booking a route through Kok-Tobe, Cathedral." {
		t.Fatalf("Description = %q, want route-aware copy", repo.savedExcursion.Description)
	}
	if len(repo.savedRelations.Itinerary) != 2 {
		t.Fatalf("itinerary length = %d, want 2", len(repo.savedRelations.Itinerary))
	}
}

func TestCreateExcursionBookingPersistsRequestForSelectedOffer(t *testing.T) {
	productID := uuid.New()
	offerID := uuid.New()
	legacyExcursionID := uuid.New()
	guideUserID := uuid.New()
	touristUserID := uuid.New()
	scheduledFor := time.Now().UTC().Add(48 * time.Hour)

	repo := &excursionRepoStub{
		gotOffer: &model.ExcursionOffer{
			ID:                offerID,
			ProductID:         productID,
			LegacyExcursionID: &legacyExcursionID,
			GuideProfileID:    uuid.New(),
			GuideUserID:       guideUserID,
			Status:            enum.ExcursionStatusPublished,
			Visibility:        enum.ExcursionVisibilityPublic,
			DurationMinutes:   240,
			MaxGroupSize:      8,
			MeetingPoint:      "Hotel pickup",
			PriceAmount:       120,
			Currency:          "USD",
			Revision:          1,
			CreatedAt:         time.Now().UTC(),
			UpdatedAt:         time.Now().UTC(),
		},
	}
	uc := NewExcursionUseCase(repo, guideVerifierStub{}, nil)

	booking, err := uc.CreateExcursionBooking(context.Background(), CreateExcursionBookingInput{
		ActorUserID:  touristUserID,
		ProductID:    productID,
		OfferID:      offerID,
		ScheduledFor: scheduledFor,
		Adults:       2,
		Children:     1,
	})
	if err != nil {
		t.Fatalf("CreateExcursionBooking() error = %v", err)
	}
	if repo.createdBooking == nil {
		t.Fatal("booking was not persisted")
	}
	if booking.OfferID != offerID {
		t.Fatalf("booking offer id = %s, want %s", booking.OfferID, offerID)
	}
	if booking.LegacyExcursionID == nil || *booking.LegacyExcursionID != legacyExcursionID {
		t.Fatalf("legacy excursion id = %v, want %s", booking.LegacyExcursionID, legacyExcursionID)
	}
	if booking.GuideUserID != guideUserID {
		t.Fatalf("guide user id = %s, want %s", booking.GuideUserID, guideUserID)
	}
	if booking.TouristUserID != touristUserID {
		t.Fatalf("tourist user id = %s, want %s", booking.TouristUserID, touristUserID)
	}
	if booking.TotalSeats != 3 {
		t.Fatalf("total seats = %d, want 3", booking.TotalSeats)
	}
	if booking.TotalPriceAmount <= booking.UnitPriceAmount {
		t.Fatalf("total price = %v, want subtotal plus service fee", booking.TotalPriceAmount)
	}
}

func TestCreateExcursionReviewRequestsAttractionRatingRecalculation(t *testing.T) {
	productID := uuid.New()
	offerID := uuid.New()
	landmarkID := uuid.New()
	touristUserID := uuid.New()
	booking, err := model.NewExcursionBooking(model.NewExcursionBookingParams{
		ProductID:       productID,
		OfferID:         offerID,
		GuideProfileID:  uuid.New(),
		GuideUserID:     uuid.New(),
		TouristUserID:   touristUserID,
		ScheduledFor:    time.Now().UTC().Add(-24 * time.Hour),
		Adults:          1,
		Children:        0,
		UnitPriceAmount: 120,
		Currency:        "KZT",
	})
	if err != nil {
		t.Fatalf("NewExcursionBooking() error = %v", err)
	}
	repo := &excursionRepoStub{
		gotBooking:           booking,
		landmarkRatingAvg:    4.7,
		landmarkReviewsCount: 9,
		createReviewFn: func(item *model.ExcursionReview) {
			item.LandmarkID = &landmarkID
		},
	}
	ratings := &attractionRatingUpdaterStub{}
	uc := NewExcursionUseCase(repo, guideVerifierStub{}, nil).
		WithAttractionRatingUpdater(ratings)

	_, err = uc.CreateExcursionReview(context.Background(), CreateExcursionReviewInput{
		ActorUserID: touristUserID,
		BookingID:   booking.ID,
		Rating:      5,
		Comment:     "Excellent route and guide",
	})
	if err != nil {
		t.Fatalf("CreateExcursionReview() error = %v", err)
	}
	if repo.landmarkReviewStatsID != landmarkID {
		t.Fatalf("landmark stats id = %s, want %s", repo.landmarkReviewStatsID, landmarkID)
	}
	if len(ratings.snapshots) != 1 {
		t.Fatalf("snapshots count = %d, want 1", len(ratings.snapshots))
	}
	got := ratings.snapshots[0]
	if got.AttractionID != landmarkID ||
		got.Source != attractionRatingSourceExcursionReviews ||
		got.RatingAvg != 4.7 ||
		got.ReviewCount != 9 {
		t.Fatalf("snapshot = %+v, want attraction %s source %s rating 4.7 count 9",
			got, landmarkID, attractionRatingSourceExcursionReviews)
	}
}

func TestSaveBookingReviewsUpdatesExcursionAndCreatesGuideReviewFromBookingAuthor(t *testing.T) {
	landmarkID := uuid.New()
	touristUserID := uuid.New()
	booking, err := model.NewExcursionBooking(model.NewExcursionBookingParams{
		ProductID:       uuid.New(),
		OfferID:         uuid.New(),
		GuideProfileID:  uuid.New(),
		GuideUserID:     uuid.New(),
		TouristUserID:   touristUserID,
		ScheduledFor:    time.Now().UTC().Add(-24 * time.Hour),
		Adults:          1,
		Children:        0,
		UnitPriceAmount: 120,
		Currency:        "KZT",
	})
	if err != nil {
		t.Fatalf("NewExcursionBooking() error = %v", err)
	}
	existingReview := &model.ExcursionReview{
		ID:             uuid.New(),
		BookingID:      booking.ID,
		ProductID:      booking.ProductID,
		OfferID:        booking.OfferID,
		LandmarkID:     &landmarkID,
		GuideProfileID: booking.GuideProfileID,
		GuideUserID:    booking.GuideUserID,
		TouristUserID:  touristUserID,
		Rating:         3,
		Comment:        "Good",
		CreatedAt:      time.Now().UTC().Add(-time.Hour),
		UpdatedAt:      time.Now().UTC().Add(-time.Hour),
	}
	repo := &excursionRepoStub{
		gotBooking:           booking,
		existingReview:       existingReview,
		landmarkRatingAvg:    4.4,
		landmarkReviewsCount: 12,
	}
	ratings := &attractionRatingUpdaterStub{}
	uc := NewExcursionUseCase(repo, guideVerifierStub{}, nil).
		WithAttractionRatingUpdater(ratings)

	result, err := uc.SaveBookingReviews(context.Background(), SaveBookingReviewsInput{
		ActorUserID: touristUserID,
		BookingID:   booking.ID,
		ExcursionReview: &ReviewMutationInput{
			Rating:  4.5,
			Comment: "Updated excursion review",
		},
		GuideReview: &ReviewMutationInput{
			Rating:  5,
			Comment: "Guide was thoughtful and punctual",
		},
	})
	if err != nil {
		t.Fatalf("SaveBookingReviews() error = %v", err)
	}
	if !repo.txUsed {
		t.Fatal("SaveBookingReviews() must persist review mutations in one transaction")
	}
	if repo.updatedReview == nil {
		t.Fatal("excursion review was not updated")
	}
	if repo.updatedReview.ID != existingReview.ID || repo.updatedReview.TouristUserID != touristUserID {
		t.Fatalf("updated review = %+v, want existing id and booking tourist author", repo.updatedReview)
	}
	if repo.updatedReview.Rating != 4.5 || repo.updatedReview.Comment != "Updated excursion review" {
		t.Fatalf("updated review rating/comment = %.1f/%q", repo.updatedReview.Rating, repo.updatedReview.Comment)
	}
	if repo.createdGuideReview == nil {
		t.Fatal("guide review was not created")
	}
	if repo.createdGuideReview.BookingID != booking.ID ||
		repo.createdGuideReview.GuideUserID != booking.GuideUserID ||
		repo.createdGuideReview.TouristUserID != touristUserID {
		t.Fatalf("created guide review = %+v, want booking-derived author and guide", repo.createdGuideReview)
	}
	if result.ExcursionReview == nil || result.ExcursionReview.ID != existingReview.ID {
		t.Fatalf("result excursion review = %+v", result.ExcursionReview)
	}
	if result.GuideReview == nil || result.GuideReview.TouristUserID != touristUserID {
		t.Fatalf("result guide review = %+v", result.GuideReview)
	}
	if len(ratings.snapshots) != 1 || repo.landmarkReviewStatsID != landmarkID {
		t.Fatalf("attraction snapshots = %+v, landmark stats id = %s, want one refresh for %s",
			ratings.snapshots, repo.landmarkReviewStatsID, landmarkID)
	}
}

func TestSaveBookingReviewsDeletesReviewsAndRefreshesLandmarkStats(t *testing.T) {
	landmarkID := uuid.New()
	touristUserID := uuid.New()
	booking, err := model.NewExcursionBooking(model.NewExcursionBookingParams{
		ProductID:       uuid.New(),
		OfferID:         uuid.New(),
		GuideProfileID:  uuid.New(),
		GuideUserID:     uuid.New(),
		TouristUserID:   touristUserID,
		ScheduledFor:    time.Now().UTC().Add(-24 * time.Hour),
		Adults:          1,
		Children:        0,
		UnitPriceAmount: 120,
		Currency:        "KZT",
	})
	if err != nil {
		t.Fatalf("NewExcursionBooking() error = %v", err)
	}
	repo := &excursionRepoStub{
		gotBooking: booking,
		existingReview: &model.ExcursionReview{
			ID:             uuid.New(),
			BookingID:      booking.ID,
			ProductID:      booking.ProductID,
			OfferID:        booking.OfferID,
			LandmarkID:     &landmarkID,
			GuideProfileID: booking.GuideProfileID,
			GuideUserID:    booking.GuideUserID,
			TouristUserID:  touristUserID,
			Rating:         4,
			Comment:        "Nice",
			CreatedAt:      time.Now().UTC().Add(-time.Hour),
			UpdatedAt:      time.Now().UTC().Add(-time.Hour),
		},
		existingGuideReview: &model.GuideReview{
			ID:             uuid.New(),
			BookingID:      booking.ID,
			GuideProfileID: booking.GuideProfileID,
			GuideUserID:    booking.GuideUserID,
			TouristUserID:  touristUserID,
			Rating:         5,
			Comment:        "Great guide",
			CreatedAt:      time.Now().UTC().Add(-time.Hour),
			UpdatedAt:      time.Now().UTC().Add(-time.Hour),
		},
		landmarkRatingAvg:    0,
		landmarkReviewsCount: 0,
	}
	ratings := &attractionRatingUpdaterStub{}
	uc := NewExcursionUseCase(repo, guideVerifierStub{}, nil).
		WithAttractionRatingUpdater(ratings)

	result, err := uc.SaveBookingReviews(context.Background(), SaveBookingReviewsInput{
		ActorUserID:     touristUserID,
		BookingID:       booking.ID,
		ExcursionReview: &ReviewMutationInput{Delete: true},
		GuideReview:     &ReviewMutationInput{Delete: true},
	})
	if err != nil {
		t.Fatalf("SaveBookingReviews() error = %v", err)
	}
	if repo.deletedReview == nil || repo.deletedReview.ID != repo.existingReview.ID {
		t.Fatalf("deleted excursion review = %+v", repo.deletedReview)
	}
	if repo.deletedGuideReview == nil || repo.deletedGuideReview.ID != repo.existingGuideReview.ID {
		t.Fatalf("deleted guide review = %+v", repo.deletedGuideReview)
	}
	if result.ExcursionReview != nil || result.GuideReview != nil {
		t.Fatalf("result = %+v, want nil reviews after delete", result)
	}
	if len(ratings.snapshots) != 1 || ratings.snapshots[0].ReviewCount != 0 {
		t.Fatalf("snapshots = %+v, want attraction reset after delete", ratings.snapshots)
	}
}

func TestSaveBookingReviewsRejectsNonAuthor(t *testing.T) {
	booking, err := model.NewExcursionBooking(model.NewExcursionBookingParams{
		ProductID:       uuid.New(),
		OfferID:         uuid.New(),
		GuideProfileID:  uuid.New(),
		GuideUserID:     uuid.New(),
		TouristUserID:   uuid.New(),
		ScheduledFor:    time.Now().UTC().Add(-24 * time.Hour),
		Adults:          1,
		Children:        0,
		UnitPriceAmount: 120,
		Currency:        "KZT",
	})
	if err != nil {
		t.Fatalf("NewExcursionBooking() error = %v", err)
	}
	repo := &excursionRepoStub{gotBooking: booking}
	uc := NewExcursionUseCase(repo, guideVerifierStub{}, nil)

	_, err = uc.SaveBookingReviews(context.Background(), SaveBookingReviewsInput{
		ActorUserID: uuid.New(),
		BookingID:   booking.ID,
		GuideReview: &ReviewMutationInput{Rating: 5, Comment: "Not mine"},
	})
	if !errors.Is(err, ErrExcursionBookingNotFound) {
		t.Fatalf("SaveBookingReviews() error = %v, want ErrExcursionBookingNotFound", err)
	}
	if repo.createdGuideReview != nil || repo.updatedGuideReview != nil || repo.deletedGuideReview != nil {
		t.Fatalf("guide review was mutated by non-author: created=%+v updated=%+v deleted=%+v",
			repo.createdGuideReview, repo.updatedGuideReview, repo.deletedGuideReview)
	}
}

func TestListExcursionReviewsProjectsAuthorFromUnifiedProfile(t *testing.T) {
	touristUserID := uuid.New()
	avatarFileID := uuid.New()
	displayName := "@nomad_aru"
	review := &model.ExcursionReview{
		ID:             uuid.New(),
		BookingID:      uuid.New(),
		ProductID:      uuid.New(),
		OfferID:        uuid.New(),
		GuideProfileID: uuid.New(),
		GuideUserID:    uuid.New(),
		TouristUserID:  touristUserID,
		Rating:         4.5,
		Comment:        "Calm pace and beautiful viewpoints",
		CreatedAt:      time.Now().UTC(),
		UpdatedAt:      time.Now().UTC(),
	}
	repo := &excursionRepoStub{listReviewItems: []*model.ExcursionReview{review}}
	profiles := &userProfileResolverStub{
		profiles: map[uuid.UUID]port.UserProfileProjection{
			touristUserID: {
				UserID:       touristUserID,
				DisplayName:  &displayName,
				AvatarFileID: &avatarFileID,
			},
		},
	}
	uc := NewExcursionUseCase(repo, guideVerifierStub{}, nil).
		WithUserProfileResolver(profiles)

	items, err := uc.ListExcursionReviews(context.Background(), port.ExcursionReviewFilter{
		ProductID: uuidPtr(review.ProductID),
		Limit:     20,
	})
	if err != nil {
		t.Fatalf("ListExcursionReviews() error = %v", err)
	}
	if len(items) != 1 {
		t.Fatalf("items len = %d, want 1", len(items))
	}
	got := items[0].Author
	if got.UserID != touristUserID {
		t.Fatalf("author user id = %s, want %s", got.UserID, touristUserID)
	}
	if got.DisplayName == nil || *got.DisplayName != displayName {
		t.Fatalf("author display name = %v, want %s", got.DisplayName, displayName)
	}
	if got.AvatarFileID == nil || *got.AvatarFileID != avatarFileID {
		t.Fatalf("author avatar file id = %v, want %s", got.AvatarFileID, avatarFileID)
	}
	if len(profiles.requests) != 1 || len(profiles.requests[0]) != 1 || profiles.requests[0][0] != touristUserID {
		t.Fatalf("profile requests = %v, want one batched tourist id", profiles.requests)
	}
}

func TestListMyGuideExcursionBookingsProjectsAuthorFromUnifiedProfile(t *testing.T) {
	guideUserID := uuid.New()
	touristUserID := uuid.New()
	avatarFileID := uuid.New()
	displayName := "@booking_author"
	booking := &model.ExcursionBooking{
		ID:               uuid.New(),
		ProductID:        uuid.New(),
		OfferID:          uuid.New(),
		GuideProfileID:   uuid.New(),
		GuideUserID:      guideUserID,
		TouristUserID:    touristUserID,
		ScheduledFor:     time.Now().UTC().Add(24 * time.Hour),
		Adults:           2,
		Children:         1,
		TotalSeats:       3,
		UnitPriceAmount:  100,
		TotalPriceAmount: 315,
		Currency:         "KZT",
		Status:           enum.ExcursionBookingStatusRequested,
		CreatedAt:        time.Now().UTC(),
		UpdatedAt:        time.Now().UTC(),
	}
	repo := &excursionRepoStub{
		listBookingItems: []*model.ExcursionBookingListItem{
			{Booking: booking},
		},
	}
	profiles := &userProfileResolverStub{
		profiles: map[uuid.UUID]port.UserProfileProjection{
			touristUserID: {
				UserID:       touristUserID,
				DisplayName:  &displayName,
				AvatarFileID: &avatarFileID,
			},
		},
	}
	uc := NewExcursionUseCase(repo, guideVerifierStub{}, nil).
		WithUserProfileResolver(profiles)

	items, err := uc.ListMyGuideExcursionBookings(
		context.Background(),
		guideUserID,
		20,
		0,
	)
	if err != nil {
		t.Fatalf("ListMyGuideExcursionBookings() error = %v", err)
	}
	if len(items) != 1 {
		t.Fatalf("items len = %d, want 1", len(items))
	}
	got := items[0].Author
	if got.UserID != touristUserID {
		t.Fatalf("author user id = %s, want %s", got.UserID, touristUserID)
	}
	if got.DisplayName == nil || *got.DisplayName != displayName {
		t.Fatalf("author display name = %v, want %s", got.DisplayName, displayName)
	}
	if got.AvatarFileID == nil || *got.AvatarFileID != avatarFileID {
		t.Fatalf("author avatar file id = %v, want %s", got.AvatarFileID, avatarFileID)
	}
	if len(profiles.requests) != 1 || len(profiles.requests[0]) != 1 || profiles.requests[0][0] != touristUserID {
		t.Fatalf("profile requests = %v, want one batched tourist id", profiles.requests)
	}
}

func TestCreateExcursionBookingReturnsExistingForIdempotencyRetry(t *testing.T) {
	productID := uuid.New()
	offerID := uuid.New()
	guideUserID := uuid.New()
	touristUserID := uuid.New()
	scheduledFor := time.Date(2026, 5, 18, 8, 0, 0, 0, time.UTC)
	idempotencyKey := productID.String() + ":" + offerID.String() + ":1:0"
	existing, err := model.NewExcursionBooking(model.NewExcursionBookingParams{
		ProductID:       productID,
		OfferID:         offerID,
		GuideProfileID:  uuid.New(),
		GuideUserID:     guideUserID,
		TouristUserID:   touristUserID,
		ScheduledFor:    scheduledFor,
		Adults:          1,
		Children:        0,
		UnitPriceAmount: 120,
		Currency:        "KZT",
		IdempotencyKey:  &idempotencyKey,
	})
	if err != nil {
		t.Fatalf("NewExcursionBooking() error = %v", err)
	}
	repo := &excursionRepoStub{
		existingBookingByKey: existing,
	}
	uc := NewExcursionUseCase(repo, guideVerifierStub{}, nil)

	booking, err := uc.CreateExcursionBooking(context.Background(), CreateExcursionBookingInput{
		ActorUserID:    touristUserID,
		ProductID:      productID,
		OfferID:        offerID,
		ScheduledFor:   scheduledFor,
		Adults:         1,
		Children:       0,
		IdempotencyKey: &idempotencyKey,
	})

	if err != nil {
		t.Fatalf("CreateExcursionBooking() error = %v", err)
	}
	if booking.ID != existing.ID {
		t.Fatalf("booking id = %s, want existing %s", booking.ID, existing.ID)
	}
	if repo.createdBooking != nil {
		t.Fatal("idempotency retry inserted a new booking")
	}
	if repo.gotIdempotencyTouristID != touristUserID {
		t.Fatalf("idempotency tourist id = %s, want %s", repo.gotIdempotencyTouristID, touristUserID)
	}
	if repo.gotIdempotencyKey != idempotencyKey {
		t.Fatalf("idempotency key = %q, want %q", repo.gotIdempotencyKey, idempotencyKey)
	}
}

func TestCreateExcursionBookingReturnsExistingWhenInsertHitsIdempotencyConflict(t *testing.T) {
	productID := uuid.New()
	offerID := uuid.New()
	guideUserID := uuid.New()
	touristUserID := uuid.New()
	scheduledFor := time.Now().UTC().Add(48 * time.Hour)
	idempotencyKey := productID.String() + ":" + offerID.String() + ":1:0"
	existing, err := model.NewExcursionBooking(model.NewExcursionBookingParams{
		ProductID:       productID,
		OfferID:         offerID,
		GuideProfileID:  uuid.New(),
		GuideUserID:     guideUserID,
		TouristUserID:   touristUserID,
		ScheduledFor:    scheduledFor,
		Adults:          1,
		Children:        0,
		UnitPriceAmount: 120,
		Currency:        "KZT",
		IdempotencyKey:  &idempotencyKey,
	})
	if err != nil {
		t.Fatalf("NewExcursionBooking() error = %v", err)
	}
	repo := &excursionRepoStub{
		gotOffer: &model.ExcursionOffer{
			ID:             offerID,
			ProductID:      productID,
			GuideProfileID: uuid.New(),
			GuideUserID:    guideUserID,
			Status:         enum.ExcursionStatusPublished,
			Visibility:     enum.ExcursionVisibilityPublic,
			MaxGroupSize:   6,
			PriceAmount:    120,
			Currency:       "KZT",
		},
		createBookingErr:                port.ErrExcursionBookingIdempotencyConflict,
		existingBookingAfterKeyConflict: existing,
	}
	uc := NewExcursionUseCase(repo, guideVerifierStub{}, nil)

	booking, err := uc.CreateExcursionBooking(context.Background(), CreateExcursionBookingInput{
		ActorUserID:    touristUserID,
		ProductID:      productID,
		OfferID:        offerID,
		ScheduledFor:   scheduledFor,
		Adults:         1,
		Children:       0,
		IdempotencyKey: &idempotencyKey,
	})

	if err != nil {
		t.Fatalf("CreateExcursionBooking() error = %v", err)
	}
	if booking.ID != existing.ID {
		t.Fatalf("booking id = %s, want existing %s", booking.ID, existing.ID)
	}
	if repo.createdBooking == nil {
		t.Fatal("booking insert was not attempted before conflict resolution")
	}
	if repo.idempotencyLookupCount != 2 {
		t.Fatalf("idempotency lookups = %d, want 2", repo.idempotencyLookupCount)
	}
}

func TestCreateGuideScheduleSlotRejectsOverlap(t *testing.T) {
	guideUserID := uuid.New()
	start := time.Now().UTC().Add(24 * time.Hour).Truncate(time.Second)
	repo := &excursionRepoStub{
		gotOffer: &model.ExcursionOffer{
			ID:                uuid.New(),
			ProductID:         uuid.New(),
			LegacyExcursionID: uuidPtr(uuid.New()),
			GuideProfileID:    uuid.New(),
			GuideUserID:       guideUserID,
			Status:            enum.ExcursionStatusPublished,
			Visibility:        enum.ExcursionVisibilityPublic,
			DurationMinutes:   240,
			MaxGroupSize:      6,
			MeetingPoint:      "Medeu entrance",
			PriceAmount:       120,
			Currency:          "KZT",
		},
		createScheduleSlotErr: port.ErrExcursionScheduleConflict,
	}
	uc := NewExcursionUseCase(repo, guideVerifierStub{}, nil)

	_, err := uc.CreateGuideScheduleSlot(context.Background(), CreateGuideScheduleSlotInput{
		ActorUserID: guideUserID,
		OfferID:     repo.gotOffer.ID,
		StartAt:     start,
		Timezone:    "Asia/Almaty",
		Capacity:    6,
	})

	if !errors.Is(err, ErrExcursionScheduleConflict) {
		t.Fatalf("error = %v, want ErrExcursionScheduleConflict", err)
	}
}

func TestCreateGuideScheduleSlotAcceptsLegacyExcursionID(t *testing.T) {
	guideUserID := uuid.New()
	legacyExcursionID := uuid.New()
	offerID := uuid.New()
	productID := uuid.New()
	start := time.Now().UTC().Add(24 * time.Hour).Truncate(time.Second)
	repo := &excursionRepoStub{
		gotOfferByLegacy: &model.ExcursionOffer{
			ID:                offerID,
			ProductID:         productID,
			LegacyExcursionID: &legacyExcursionID,
			GuideProfileID:    uuid.New(),
			GuideUserID:       guideUserID,
			Status:            enum.ExcursionStatusPublished,
			Visibility:        enum.ExcursionVisibilityPublic,
			DurationMinutes:   180,
			MaxGroupSize:      6,
			MeetingPoint:      "Medeu entrance",
			PriceAmount:       120,
			Currency:          "KZT",
		},
	}
	uc := NewExcursionUseCase(repo, guideVerifierStub{}, nil)

	slot, err := uc.CreateGuideScheduleSlot(context.Background(), CreateGuideScheduleSlotInput{
		ActorUserID: guideUserID,
		OfferID:     legacyExcursionID,
		StartAt:     start,
		Timezone:    "Asia/Almaty",
		Capacity:    6,
	})

	if err != nil {
		t.Fatalf("CreateGuideScheduleSlot() error = %v", err)
	}
	if repo.gotOfferByLegacyID != legacyExcursionID {
		t.Fatalf("legacy lookup id = %s, want %s", repo.gotOfferByLegacyID, legacyExcursionID)
	}
	if slot.OfferID != offerID || slot.ProductID != productID {
		t.Fatalf("slot offer/product = %s/%s, want %s/%s", slot.OfferID, slot.ProductID, offerID, productID)
	}
}

func TestCreateGuideScheduleSlotRejectsCapacityAboveOfferMax(t *testing.T) {
	guideUserID := uuid.New()
	offerID := uuid.New()
	repo := &excursionRepoStub{
		gotOffer: &model.ExcursionOffer{
			ID:              offerID,
			ProductID:       uuid.New(),
			GuideProfileID:  uuid.New(),
			GuideUserID:     guideUserID,
			Status:          enum.ExcursionStatusPublished,
			Visibility:      enum.ExcursionVisibilityPublic,
			DurationMinutes: 180,
			MaxGroupSize:    8,
			MeetingPoint:    "Medeu entrance",
			PriceAmount:     120,
			Currency:        "KZT",
		},
	}
	uc := NewExcursionUseCase(repo, guideVerifierStub{}, nil)

	_, err := uc.CreateGuideScheduleSlot(context.Background(), CreateGuideScheduleSlotInput{
		ActorUserID: guideUserID,
		OfferID:     offerID,
		StartAt:     time.Date(2026, 5, 22, 9, 0, 0, 0, time.UTC),
		Timezone:    "Asia/Almaty",
		Capacity:    100,
	})

	if !errors.Is(err, model.ErrInvalidExcursionScheduleCapacity) {
		t.Fatalf("error = %v, want ErrInvalidExcursionScheduleCapacity", err)
	}
	if repo.createdScheduleSlot != nil {
		t.Fatalf("slot was persisted despite invalid capacity: %#v", repo.createdScheduleSlot)
	}
}

func TestCreateGuideScheduleSlotRejectsStartInsideSetupLeadTime(t *testing.T) {
	guideUserID := uuid.New()
	offerID := uuid.New()
	repo := &excursionRepoStub{
		gotOffer: &model.ExcursionOffer{
			ID:              offerID,
			ProductID:       uuid.New(),
			GuideProfileID:  uuid.New(),
			GuideUserID:     guideUserID,
			Status:          enum.ExcursionStatusPublished,
			Visibility:      enum.ExcursionVisibilityPublic,
			DurationMinutes: 180,
			MaxGroupSize:    8,
			MeetingPoint:    "Medeu entrance",
			PriceAmount:     120,
			Currency:        "KZT",
		},
	}
	uc := NewExcursionUseCase(repo, guideVerifierStub{}, nil)

	_, err := uc.CreateGuideScheduleSlot(context.Background(), CreateGuideScheduleSlotInput{
		ActorUserID: guideUserID,
		OfferID:     offerID,
		StartAt:     time.Now().UTC().Add(2 * time.Hour),
		Timezone:    "Asia/Almaty",
		Capacity:    6,
	})

	if !errors.Is(err, ErrExcursionScheduleStartTooSoon) {
		t.Fatalf("error = %v, want ErrExcursionScheduleStartTooSoon", err)
	}
	if repo.createdScheduleSlot != nil {
		t.Fatalf("slot was persisted despite setup lead time: %#v", repo.createdScheduleSlot)
	}
}

func TestUpdateGuideScheduleSlotReschedulesWithSelectedOffer(t *testing.T) {
	guideUserID := uuid.New()
	slotID := uuid.New()
	oldOfferID := uuid.New()
	newOfferID := uuid.New()
	newProductID := uuid.New()
	newLegacyExcursionID := uuid.New()
	startAt := time.Date(2026, 5, 29, 9, 30, 0, 0, time.UTC)
	repo := &excursionRepoStub{
		gotScheduleSlot: &model.ExcursionScheduleSlot{
			ID:             slotID,
			GuideProfileID: uuid.New(),
			GuideUserID:    guideUserID,
			OfferID:        oldOfferID,
			ProductID:      uuid.New(),
			StartAt:        time.Date(2026, 5, 22, 9, 0, 0, 0, time.UTC),
			EndAt:          time.Date(2026, 5, 22, 11, 0, 0, 0, time.UTC),
			Timezone:       "Asia/Almaty",
			Capacity:       6,
			BookedSeats:    0,
			Status:         enum.ExcursionScheduleSlotStatusAvailable,
		},
		gotOffer: &model.ExcursionOffer{
			ID:                newOfferID,
			ProductID:         newProductID,
			LegacyExcursionID: &newLegacyExcursionID,
			GuideProfileID:    uuid.New(),
			GuideUserID:       guideUserID,
			Status:            enum.ExcursionStatusPublished,
			Visibility:        enum.ExcursionVisibilityPublic,
			DurationMinutes:   180,
			MaxGroupSize:      8,
			MeetingPoint:      "Medeu entrance",
			PriceAmount:       120,
			Currency:          "KZT",
		},
	}
	uc := NewExcursionUseCase(repo, guideVerifierStub{}, nil)

	slot, err := uc.UpdateGuideScheduleSlot(context.Background(), UpdateGuideScheduleSlotInput{
		ActorUserID: guideUserID,
		SlotID:      slotID,
		OfferID:     newOfferID,
		StartAt:     startAt,
		Timezone:    "Asia/Almaty",
		Capacity:    5,
	})

	if err != nil {
		t.Fatalf("UpdateGuideScheduleSlot() error = %v", err)
	}
	if repo.createdScheduleSlot == nil {
		t.Fatal("updated slot was not persisted")
	}
	if slot.OfferID != newOfferID || slot.ProductID != newProductID {
		t.Fatalf("slot offer/product = %s/%s, want %s/%s", slot.OfferID, slot.ProductID, newOfferID, newProductID)
	}
	if slot.StartAt != startAt || slot.EndAt != startAt.Add(180*time.Minute) {
		t.Fatalf("slot interval = %s-%s, want %s + 180m", slot.StartAt, slot.EndAt, startAt)
	}
	if slot.Capacity != 5 {
		t.Fatalf("capacity = %d, want 5", slot.Capacity)
	}
}

func TestUpdateGuideScheduleSlotRejectsBookedSlot(t *testing.T) {
	guideUserID := uuid.New()
	slotID := uuid.New()
	offerID := uuid.New()
	repo := &excursionRepoStub{
		gotScheduleSlot: &model.ExcursionScheduleSlot{
			ID:             slotID,
			GuideProfileID: uuid.New(),
			GuideUserID:    guideUserID,
			OfferID:        offerID,
			ProductID:      uuid.New(),
			StartAt:        time.Date(2026, 5, 22, 9, 0, 0, 0, time.UTC),
			EndAt:          time.Date(2026, 5, 22, 11, 0, 0, 0, time.UTC),
			Timezone:       "Asia/Almaty",
			Capacity:       6,
			BookedSeats:    2,
			Status:         enum.ExcursionScheduleSlotStatusBooked,
		},
	}
	uc := NewExcursionUseCase(repo, guideVerifierStub{}, nil)

	_, err := uc.UpdateGuideScheduleSlot(context.Background(), UpdateGuideScheduleSlotInput{
		ActorUserID: guideUserID,
		SlotID:      slotID,
		OfferID:     offerID,
		StartAt:     time.Date(2026, 5, 29, 9, 30, 0, 0, time.UTC),
		Timezone:    "Asia/Almaty",
		Capacity:    5,
	})

	if !errors.Is(err, ErrExcursionScheduleUnavailable) {
		t.Fatalf("error = %v, want ErrExcursionScheduleUnavailable", err)
	}
	if repo.createdScheduleSlot != nil {
		t.Fatalf("slot was persisted despite booked seats: %#v", repo.createdScheduleSlot)
	}
}

func TestUpdateGuideScheduleSlotRejectsStartInsideSetupLeadTime(t *testing.T) {
	guideUserID := uuid.New()
	slotID := uuid.New()
	offerID := uuid.New()
	repo := &excursionRepoStub{
		gotScheduleSlot: &model.ExcursionScheduleSlot{
			ID:             slotID,
			GuideProfileID: uuid.New(),
			GuideUserID:    guideUserID,
			OfferID:        offerID,
			ProductID:      uuid.New(),
			StartAt:        time.Now().UTC().Add(24 * time.Hour),
			EndAt:          time.Now().UTC().Add(26 * time.Hour),
			Timezone:       "Asia/Almaty",
			Capacity:       6,
			BookedSeats:    0,
			Status:         enum.ExcursionScheduleSlotStatusAvailable,
		},
		gotOffer: &model.ExcursionOffer{
			ID:              offerID,
			ProductID:       uuid.New(),
			GuideProfileID:  uuid.New(),
			GuideUserID:     guideUserID,
			Status:          enum.ExcursionStatusPublished,
			Visibility:      enum.ExcursionVisibilityPublic,
			DurationMinutes: 180,
			MaxGroupSize:    8,
			MeetingPoint:    "Medeu entrance",
			PriceAmount:     120,
			Currency:        "KZT",
		},
	}
	uc := NewExcursionUseCase(repo, guideVerifierStub{}, nil)

	_, err := uc.UpdateGuideScheduleSlot(context.Background(), UpdateGuideScheduleSlotInput{
		ActorUserID: guideUserID,
		SlotID:      slotID,
		OfferID:     offerID,
		StartAt:     time.Now().UTC().Add(2 * time.Hour),
		Timezone:    "Asia/Almaty",
		Capacity:    5,
	})

	if !errors.Is(err, ErrExcursionScheduleStartTooSoon) {
		t.Fatalf("error = %v, want ErrExcursionScheduleStartTooSoon", err)
	}
	if repo.createdScheduleSlot != nil {
		t.Fatalf("slot was persisted despite setup lead time: %#v", repo.createdScheduleSlot)
	}
}

func TestCloseGuideScheduleSlotSyncsChatForGuideAndBookingAuthors(t *testing.T) {
	guideUserID := uuid.New()
	slotID := uuid.New()
	offerID := uuid.New()
	productID := uuid.New()
	activeTouristID := uuid.New()
	cancelledTouristID := uuid.New()
	startAt := time.Now().UTC().Add(3 * time.Hour)
	endAt := startAt.Add(2 * time.Hour)
	repo := &excursionRepoStub{
		gotScheduleSlot: &model.ExcursionScheduleSlot{
			ID:             slotID,
			GuideProfileID: uuid.New(),
			GuideUserID:    guideUserID,
			OfferID:        offerID,
			ProductID:      productID,
			StartAt:        startAt,
			EndAt:          endAt,
			Timezone:       "Asia/Almaty",
			Capacity:       6,
			BookedSeats:    2,
			Status:         enum.ExcursionScheduleSlotStatusBooked,
			Title:          "Big Almaty Lake",
		},
		listBookingItems: []*model.ExcursionBookingListItem{
			{
				Booking: &model.ExcursionBooking{
					ID:             uuid.New(),
					ProductID:      productID,
					OfferID:        offerID,
					ScheduleSlotID: &slotID,
					GuideProfileID: uuid.New(),
					GuideUserID:    guideUserID,
					TouristUserID:  activeTouristID,
					ScheduledFor:   startAt,
					Adults:         2,
					TotalSeats:     2,
					Currency:       "KZT",
					Status:         enum.ExcursionBookingStatusRequested,
				},
			},
			{
				Booking: &model.ExcursionBooking{
					ID:             uuid.New(),
					ProductID:      productID,
					OfferID:        offerID,
					ScheduleSlotID: &slotID,
					GuideProfileID: uuid.New(),
					GuideUserID:    guideUserID,
					TouristUserID:  cancelledTouristID,
					ScheduledFor:   startAt,
					Adults:         1,
					TotalSeats:     1,
					Currency:       "KZT",
					Status:         enum.ExcursionBookingStatusCancelled,
				},
			},
		},
	}
	chat := &excursionChatGatewayStub{}
	uc := NewExcursionUseCase(repo, guideVerifierStub{}, nil).WithExcursionChatGateway(chat)

	_, err := uc.CloseGuideScheduleSlot(context.Background(), guideUserID, slotID)
	if err != nil {
		t.Fatalf("CloseGuideScheduleSlot() error = %v", err)
	}
	if chat.synced == nil {
		t.Fatal("chat was not synced")
	}
	if chat.synced.ScheduleSlotID != slotID {
		t.Fatalf("chat slot id = %s, want %s", chat.synced.ScheduleSlotID, slotID)
	}
	if chat.synced.GuideUserID != guideUserID {
		t.Fatalf("chat guide id = %s, want %s", chat.synced.GuideUserID, guideUserID)
	}
	if len(chat.synced.ParticipantUserIDs) != 1 || chat.synced.ParticipantUserIDs[0] != activeTouristID {
		t.Fatalf("chat participants = %v, want only active booking author %s", chat.synced.ParticipantUserIDs, activeTouristID)
	}
	if chat.synced.MessagingAvailableUntil == nil || !chat.synced.MessagingAvailableUntil.Equal(endAt.Add(time.Hour)) {
		t.Fatalf("messaging deadline = %v, want %v", chat.synced.MessagingAvailableUntil, endAt.Add(time.Hour))
	}
	if repo.listBookingFilter.ScheduleSlotID == nil || *repo.listBookingFilter.ScheduleSlotID != slotID {
		t.Fatalf("booking filter slot id = %v, want %s", repo.listBookingFilter.ScheduleSlotID, slotID)
	}
}

func TestWeeklyOccurrencesKeepsLocalWeekdayAndClock(t *testing.T) {
	startDate := time.Date(2026, 5, 18, 12, 0, 0, 0, time.UTC)
	until := time.Date(2026, 6, 5, 23, 59, 0, 0, time.UTC)

	items, err := weeklyOccurrences(startDate, []int{5}, "09:00", 180, "Asia/Almaty", until, 3)

	if err != nil {
		t.Fatalf("weeklyOccurrences() error = %v", err)
	}
	if len(items) != 3 {
		t.Fatalf("items len = %d, want 3", len(items))
	}
	loc, err := time.LoadLocation("Asia/Almaty")
	if err != nil {
		t.Fatalf("load location: %v", err)
	}
	for _, item := range items {
		local := item.In(loc)
		if local.Weekday() != time.Friday || local.Hour() != 9 || local.Minute() != 0 {
			t.Fatalf("occurrence = %s, want Friday 09:00 Asia/Almaty", local)
		}
	}
}

func TestCreateGuideScheduleSeriesCreatesWeeklySlots(t *testing.T) {
	guideUserID := uuid.New()
	offerID := uuid.New()
	productID := uuid.New()
	repo := &excursionRepoStub{
		gotOffer: &model.ExcursionOffer{
			ID:              offerID,
			ProductID:       productID,
			GuideProfileID:  uuid.New(),
			GuideUserID:     guideUserID,
			Status:          enum.ExcursionStatusPublished,
			Visibility:      enum.ExcursionVisibilityPublic,
			DurationMinutes: 180,
			MaxGroupSize:    6,
			MeetingPoint:    "Medeu entrance",
			PriceAmount:     120,
			Currency:        "KZT",
		},
	}
	uc := NewExcursionUseCase(repo, guideVerifierStub{}, nil)
	limit := 3

	slots, err := uc.CreateGuideScheduleSeries(context.Background(), CreateGuideScheduleSeriesInput{
		ActorUserID:     guideUserID,
		OfferID:         offerID,
		StartsOn:        time.Now().UTC().AddDate(0, 0, 7),
		OccurrenceLimit: &limit,
		StartTime:       "09:00",
		Timezone:        "Asia/Almaty",
		Weekdays:        []int{5},
		Capacity:        5,
	})

	if err != nil {
		t.Fatalf("CreateGuideScheduleSeries() error = %v", err)
	}
	if repo.createdScheduleSeries == nil {
		t.Fatal("series was not persisted")
	}
	if len(slots) != 3 || len(repo.createdSeriesSlots) != 3 {
		t.Fatalf("slots = %d persisted = %d, want 3", len(slots), len(repo.createdSeriesSlots))
	}
	loc, err := time.LoadLocation("Asia/Almaty")
	if err != nil {
		t.Fatalf("load location: %v", err)
	}
	for _, slot := range slots {
		local := slot.StartAt.In(loc)
		if local.Weekday() != time.Friday || local.Hour() != 9 || slot.Capacity != 5 {
			t.Fatalf("slot = %+v local = %v, want Friday 09:00 capacity 5", slot, local)
		}
		if slot.SeriesID == nil || *slot.SeriesID != repo.createdScheduleSeries.ID {
			t.Fatalf("slot series id = %v, want %s", slot.SeriesID, repo.createdScheduleSeries.ID)
		}
	}
}

func TestCreateExcursionBookingUsesScheduleSlotAndLocksCapacity(t *testing.T) {
	touristUserID := uuid.New()
	guideUserID := uuid.New()
	slotID := uuid.New()
	offerID := uuid.New()
	productID := uuid.New()
	startAt := time.Now().UTC().Add(24 * time.Hour).Truncate(time.Second)
	repo := &excursionRepoStub{
		gotOffer: &model.ExcursionOffer{
			ID:             offerID,
			ProductID:      productID,
			GuideProfileID: uuid.New(),
			GuideUserID:    guideUserID,
			Status:         enum.ExcursionStatusPublished,
			Visibility:     enum.ExcursionVisibilityPublic,
			MaxGroupSize:   6,
			PriceAmount:    100,
			Currency:       "KZT",
		},
		gotScheduleSlot: &model.ExcursionScheduleSlot{
			ID:             slotID,
			GuideProfileID: uuid.New(),
			GuideUserID:    guideUserID,
			OfferID:        offerID,
			ProductID:      productID,
			StartAt:        startAt,
			EndAt:          startAt.Add(4 * time.Hour),
			Timezone:       "Asia/Almaty",
			Capacity:       6,
			BookedSeats:    0,
			Status:         enum.ExcursionScheduleSlotStatusAvailable,
		},
	}
	uc := NewExcursionUseCase(repo, guideVerifierStub{}, nil)

	booking, err := uc.CreateExcursionBooking(context.Background(), CreateExcursionBookingInput{
		ActorUserID:    touristUserID,
		ProductID:      productID,
		OfferID:        offerID,
		ScheduleSlotID: &slotID,
		Adults:         2,
		Children:       0,
	})

	if err != nil {
		t.Fatalf("CreateExcursionBooking() error = %v", err)
	}
	if booking.ScheduleSlotID == nil || *booking.ScheduleSlotID != slotID {
		t.Fatalf("schedule slot id = %v, want %s", booking.ScheduleSlotID, slotID)
	}
	if booking.ScheduledFor != startAt {
		t.Fatalf("scheduled for = %v, want %v", booking.ScheduledFor, startAt)
	}
}

func TestCreateExcursionBookingRejectsSlotInsideBookingLeadTime(t *testing.T) {
	touristUserID := uuid.New()
	guideUserID := uuid.New()
	slotID := uuid.New()
	offerID := uuid.New()
	productID := uuid.New()
	startAt := time.Now().UTC().Add(90 * time.Minute)
	repo := &excursionRepoStub{
		gotOffer: &model.ExcursionOffer{
			ID:             offerID,
			ProductID:      productID,
			GuideProfileID: uuid.New(),
			GuideUserID:    guideUserID,
			Status:         enum.ExcursionStatusPublished,
			Visibility:     enum.ExcursionVisibilityPublic,
			MaxGroupSize:   6,
			PriceAmount:    100,
			Currency:       "KZT",
		},
		gotScheduleSlot: &model.ExcursionScheduleSlot{
			ID:             slotID,
			GuideProfileID: uuid.New(),
			GuideUserID:    guideUserID,
			OfferID:        offerID,
			ProductID:      productID,
			StartAt:        startAt,
			EndAt:          startAt.Add(4 * time.Hour),
			Timezone:       "Asia/Almaty",
			Capacity:       6,
			BookedSeats:    0,
			Status:         enum.ExcursionScheduleSlotStatusAvailable,
		},
	}
	uc := NewExcursionUseCase(repo, guideVerifierStub{}, nil)

	_, err := uc.CreateExcursionBooking(context.Background(), CreateExcursionBookingInput{
		ActorUserID:    touristUserID,
		ProductID:      productID,
		OfferID:        offerID,
		ScheduleSlotID: &slotID,
		Adults:         1,
		Children:       0,
	})

	if !errors.Is(err, ErrExcursionScheduleUnavailable) {
		t.Fatalf("error = %v, want ErrExcursionScheduleUnavailable", err)
	}
	if repo.createdBooking != nil {
		t.Fatal("booking was persisted despite slot being inside booking lead time")
	}
}

func TestUpdateExcursionBookingGuestsAdjustsScheduleSeatDelta(t *testing.T) {
	touristUserID := uuid.New()
	guideUserID := uuid.New()
	slotID := uuid.New()
	offerID := uuid.New()
	productID := uuid.New()
	scheduledFor := time.Now().UTC().Add(48 * time.Hour)
	booking, err := model.NewExcursionBooking(model.NewExcursionBookingParams{
		ProductID:       productID,
		OfferID:         offerID,
		ScheduleSlotID:  &slotID,
		GuideProfileID:  uuid.New(),
		GuideUserID:     guideUserID,
		TouristUserID:   touristUserID,
		ScheduledFor:    scheduledFor,
		Adults:          2,
		Children:        0,
		UnitPriceAmount: 120,
		Currency:        "KZT",
	})
	if err != nil {
		t.Fatalf("NewExcursionBooking() error = %v", err)
	}
	repo := &excursionRepoStub{
		gotBooking: booking,
		gotOffer: &model.ExcursionOffer{
			ID:             offerID,
			ProductID:      productID,
			GuideProfileID: uuid.New(),
			GuideUserID:    guideUserID,
			Status:         enum.ExcursionStatusPublished,
			Visibility:     enum.ExcursionVisibilityPublic,
			MaxGroupSize:   6,
			PriceAmount:    120,
			Currency:       "KZT",
		},
		gotScheduleSlot: &model.ExcursionScheduleSlot{
			ID:          slotID,
			OfferID:     offerID,
			ProductID:   productID,
			GuideUserID: guideUserID,
			StartAt:     scheduledFor,
			EndAt:       scheduledFor.Add(2 * time.Hour),
			Timezone:    "Asia/Almaty",
			Capacity:    6,
			BookedSeats: 2,
			Status:      enum.ExcursionScheduleSlotStatusBooked,
		},
	}
	uc := NewExcursionUseCase(repo, guideVerifierStub{}, nil)

	updated, err := uc.UpdateExcursionBookingGuests(context.Background(), UpdateExcursionBookingGuestsInput{
		ActorUserID: touristUserID,
		BookingID:   booking.ID,
		Adults:      3,
		Children:    1,
	})

	if err != nil {
		t.Fatalf("UpdateExcursionBookingGuests() error = %v", err)
	}
	if updated.TotalSeats != 4 || updated.Adults != 3 || updated.Children != 1 {
		t.Fatalf("updated guests = %d/%d total %d, want 3/1 total 4", updated.Adults, updated.Children, updated.TotalSeats)
	}
	if repo.updatedBookingSeatDelta != 2 {
		t.Fatalf("seat delta = %d, want 2", repo.updatedBookingSeatDelta)
	}
	if repo.updatedBooking == nil || repo.updatedBooking.ID != booking.ID {
		t.Fatal("updated booking was not persisted")
	}
}

func TestUpdateExcursionBookingGuestsRejectsSlotCapacityOverflow(t *testing.T) {
	touristUserID := uuid.New()
	guideUserID := uuid.New()
	slotID := uuid.New()
	offerID := uuid.New()
	productID := uuid.New()
	scheduledFor := time.Now().UTC().Add(48 * time.Hour)
	booking, err := model.NewExcursionBooking(model.NewExcursionBookingParams{
		ProductID:       productID,
		OfferID:         offerID,
		ScheduleSlotID:  &slotID,
		GuideProfileID:  uuid.New(),
		GuideUserID:     guideUserID,
		TouristUserID:   touristUserID,
		ScheduledFor:    scheduledFor,
		Adults:          2,
		Children:        0,
		UnitPriceAmount: 120,
		Currency:        "KZT",
	})
	if err != nil {
		t.Fatalf("NewExcursionBooking() error = %v", err)
	}
	repo := &excursionRepoStub{
		gotBooking: booking,
		gotOffer: &model.ExcursionOffer{
			ID:             offerID,
			ProductID:      productID,
			GuideProfileID: uuid.New(),
			GuideUserID:    guideUserID,
			Status:         enum.ExcursionStatusPublished,
			Visibility:     enum.ExcursionVisibilityPublic,
			MaxGroupSize:   6,
			PriceAmount:    120,
			Currency:       "KZT",
		},
		gotScheduleSlot: &model.ExcursionScheduleSlot{
			ID:          slotID,
			OfferID:     offerID,
			ProductID:   productID,
			GuideUserID: guideUserID,
			StartAt:     scheduledFor,
			EndAt:       scheduledFor.Add(2 * time.Hour),
			Timezone:    "Asia/Almaty",
			Capacity:    4,
			BookedSeats: 2,
			Status:      enum.ExcursionScheduleSlotStatusBooked,
		},
	}
	uc := NewExcursionUseCase(repo, guideVerifierStub{}, nil)

	_, err = uc.UpdateExcursionBookingGuests(context.Background(), UpdateExcursionBookingGuestsInput{
		ActorUserID: touristUserID,
		BookingID:   booking.ID,
		Adults:      4,
		Children:    1,
	})

	if !errors.Is(err, ErrExcursionScheduleUnavailable) {
		t.Fatalf("error = %v, want ErrExcursionScheduleUnavailable", err)
	}
	if repo.updatedBooking != nil {
		t.Fatal("booking was persisted despite capacity overflow")
	}
}

func TestExcursionBookingCancellationRefundPolicyTiers(t *testing.T) {
	now := time.Date(2026, time.May, 18, 12, 0, 0, 0, time.UTC)

	tests := []struct {
		name          string
		untilStart    time.Duration
		wantPercent   int
		wantAmount    float64
		wantPolicy    string
		wantRefunding bool
	}{
		{
			name:          "full refund at least twenty four hours before start",
			untilStart:    24 * time.Hour,
			wantPercent:   100,
			wantAmount:    10500,
			wantPolicy:    "FULL_REFUND_BEFORE_24H",
			wantRefunding: true,
		},
		{
			name:          "seventy five percent from twelve to twenty four hours",
			untilStart:    12 * time.Hour,
			wantPercent:   75,
			wantAmount:    7875,
			wantPolicy:    "PARTIAL_REFUND_BEFORE_12H",
			wantRefunding: true,
		},
		{
			name:          "half refund from six to twelve hours",
			untilStart:    6 * time.Hour,
			wantPercent:   50,
			wantAmount:    5250,
			wantPolicy:    "PARTIAL_REFUND_BEFORE_6H",
			wantRefunding: true,
		},
		{
			name:          "quarter refund from two to six hours",
			untilStart:    2 * time.Hour,
			wantPercent:   25,
			wantAmount:    2625,
			wantPolicy:    "PARTIAL_REFUND_BEFORE_2H",
			wantRefunding: true,
		},
		{
			name:          "no refund inside two hours",
			untilStart:    time.Hour + 59*time.Minute,
			wantPercent:   0,
			wantAmount:    0,
			wantPolicy:    "NO_REFUND_INSIDE_2H",
			wantRefunding: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			quote := excursionBookingCancellationRefundQuote(10500, "KZT", now.Add(tt.untilStart), now)

			if quote.Percent != tt.wantPercent {
				t.Fatalf("percent = %d, want %d", quote.Percent, tt.wantPercent)
			}
			if quote.Amount != tt.wantAmount {
				t.Fatalf("amount = %v, want %v", quote.Amount, tt.wantAmount)
			}
			if quote.PolicyCode != tt.wantPolicy {
				t.Fatalf("policy = %q, want %q", quote.PolicyCode, tt.wantPolicy)
			}
			if (quote.Status == "PENDING_PAYMENT_INTEGRATION") != tt.wantRefunding {
				t.Fatalf("status = %q, want refunding %v", quote.Status, tt.wantRefunding)
			}
		})
	}
}

func TestCancelExcursionBookingMarksTouristCancellationAndReleasesSlotSeats(t *testing.T) {
	touristUserID := uuid.New()
	guideUserID := uuid.New()
	slotID := uuid.New()
	offerID := uuid.New()
	productID := uuid.New()
	scheduledFor := time.Now().UTC().Add(48 * time.Hour)
	booking, err := model.NewExcursionBooking(model.NewExcursionBookingParams{
		ProductID:       productID,
		OfferID:         offerID,
		ScheduleSlotID:  &slotID,
		GuideProfileID:  uuid.New(),
		GuideUserID:     guideUserID,
		TouristUserID:   touristUserID,
		ScheduledFor:    scheduledFor,
		Adults:          2,
		Children:        1,
		UnitPriceAmount: 10000,
		Currency:        "KZT",
	})
	if err != nil {
		t.Fatalf("NewExcursionBooking() error = %v", err)
	}
	repo := &excursionRepoStub{gotBooking: booking}
	uc := NewExcursionUseCase(repo, guideVerifierStub{}, nil)

	cancelled, err := uc.CancelExcursionBooking(context.Background(), CancelExcursionBookingInput{
		ActorUserID: touristUserID,
		BookingID:   booking.ID,
		Reason:      "Планы изменились",
	})
	if err != nil {
		t.Fatalf("CancelExcursionBooking() error = %v", err)
	}

	if cancelled.Status != enum.ExcursionBookingStatusCancelled {
		t.Fatalf("status = %q, want %q", cancelled.Status, enum.ExcursionBookingStatusCancelled)
	}
	if cancelled.CancelledAt == nil {
		t.Fatal("cancelled_at was not set")
	}
	if cancelled.CancelledBy == nil || *cancelled.CancelledBy != enum.ExcursionBookingCancelledByTourist {
		t.Fatalf("cancelled_by = %v, want tourist", cancelled.CancelledBy)
	}
	if cancelled.CancelReason == nil || *cancelled.CancelReason != "Планы изменились" {
		t.Fatalf("cancel reason = %v", cancelled.CancelReason)
	}
	if cancelled.RefundPercent != 100 || cancelled.RefundAmount != cancelled.TotalPriceAmount {
		t.Fatalf("refund = %d/%v, want 100/%v", cancelled.RefundPercent, cancelled.RefundAmount, cancelled.TotalPriceAmount)
	}
	if repo.cancelledBooking == nil || repo.cancelledBooking.ID != booking.ID {
		t.Fatal("cancelled booking was not persisted")
	}
	if repo.cancelledBookingReleaseSeats != 3 {
		t.Fatalf("release seats = %d, want 3", repo.cancelledBookingReleaseSeats)
	}
}

func TestListPublicExcursionScheduleFiltersBookableSlotsBySeats(t *testing.T) {
	offerID := uuid.New()
	productID := uuid.New()
	guideUserID := uuid.New()
	from := time.Date(2026, 6, 1, 0, 0, 0, 0, time.UTC)
	to := from.Add(7 * 24 * time.Hour)
	availableStart := time.Date(2026, 6, 2, 9, 0, 0, 0, time.UTC)
	fullStart := time.Date(2026, 6, 3, 9, 0, 0, 0, time.UTC)
	closedStart := time.Date(2026, 6, 4, 9, 0, 0, 0, time.UTC)
	repo := &excursionRepoStub{
		gotOffer: &model.ExcursionOffer{
			ID:             offerID,
			ProductID:      productID,
			GuideProfileID: uuid.New(),
			GuideUserID:    guideUserID,
			Status:         enum.ExcursionStatusPublished,
			Visibility:     enum.ExcursionVisibilityPublic,
			MaxGroupSize:   8,
			PriceAmount:    100,
			Currency:       "KZT",
		},
		listScheduleSlots: []*model.ExcursionScheduleSlot{
			{
				ID:             uuid.New(),
				GuideProfileID: uuid.New(),
				GuideUserID:    guideUserID,
				OfferID:        offerID,
				ProductID:      productID,
				StartAt:        availableStart,
				EndAt:          availableStart.Add(3 * time.Hour),
				Timezone:       "Asia/Almaty",
				Capacity:       8,
				BookedSeats:    4,
				Status:         enum.ExcursionScheduleSlotStatusBooked,
			},
			{
				ID:             uuid.New(),
				GuideProfileID: uuid.New(),
				GuideUserID:    guideUserID,
				OfferID:        offerID,
				ProductID:      productID,
				StartAt:        fullStart,
				EndAt:          fullStart.Add(3 * time.Hour),
				Timezone:       "Asia/Almaty",
				Capacity:       8,
				BookedSeats:    6,
				Status:         enum.ExcursionScheduleSlotStatusBooked,
			},
			{
				ID:             uuid.New(),
				GuideProfileID: uuid.New(),
				GuideUserID:    guideUserID,
				OfferID:        offerID,
				ProductID:      productID,
				StartAt:        closedStart,
				EndAt:          closedStart.Add(3 * time.Hour),
				Timezone:       "Asia/Almaty",
				Capacity:       8,
				Status:         enum.ExcursionScheduleSlotStatusClosed,
			},
		},
	}
	uc := NewExcursionUseCase(repo, guideVerifierStub{}, nil)

	slots, err := uc.ListPublicExcursionSchedule(context.Background(), ListPublicExcursionScheduleInput{
		ProductID: productID,
		OfferID:   offerID,
		From:      from,
		To:        to,
		Seats:     3,
	})

	if err != nil {
		t.Fatalf("ListPublicExcursionSchedule() error = %v", err)
	}
	if len(slots) != 1 {
		t.Fatalf("slots len = %d, want 1", len(slots))
	}
	if slots[0].StartAt != availableStart {
		t.Fatalf("slot start = %v, want %v", slots[0].StartAt, availableStart)
	}
	if repo.listScheduleFilter.OfferID == nil || *repo.listScheduleFilter.OfferID != offerID {
		t.Fatalf("offer filter = %v, want %s", repo.listScheduleFilter.OfferID, offerID)
	}
	if len(repo.listScheduleFilter.Statuses) != 2 {
		t.Fatalf("status filters = %v, want available/booked", repo.listScheduleFilter.Statuses)
	}
}

func TestListPublicExcursionScheduleRequiresTwoHourLeadTime(t *testing.T) {
	offerID := uuid.New()
	productID := uuid.New()
	guideUserID := uuid.New()
	now := time.Now().UTC()
	soonStart := now.Add(90 * time.Minute)
	futureStart := now.Add(3 * time.Hour)
	repo := &excursionRepoStub{
		gotOffer: &model.ExcursionOffer{
			ID:             offerID,
			ProductID:      productID,
			GuideProfileID: uuid.New(),
			GuideUserID:    guideUserID,
			Status:         enum.ExcursionStatusPublished,
			Visibility:     enum.ExcursionVisibilityPublic,
			MaxGroupSize:   8,
			PriceAmount:    100,
			Currency:       "KZT",
		},
		listScheduleSlots: []*model.ExcursionScheduleSlot{
			{
				ID:             uuid.New(),
				GuideProfileID: uuid.New(),
				GuideUserID:    guideUserID,
				OfferID:        offerID,
				ProductID:      productID,
				StartAt:        soonStart,
				EndAt:          soonStart.Add(3 * time.Hour),
				Timezone:       "Asia/Almaty",
				Capacity:       8,
				BookedSeats:    0,
				Status:         enum.ExcursionScheduleSlotStatusAvailable,
			},
			{
				ID:             uuid.New(),
				GuideProfileID: uuid.New(),
				GuideUserID:    guideUserID,
				OfferID:        offerID,
				ProductID:      productID,
				StartAt:        futureStart,
				EndAt:          futureStart.Add(3 * time.Hour),
				Timezone:       "Asia/Almaty",
				Capacity:       8,
				BookedSeats:    0,
				Status:         enum.ExcursionScheduleSlotStatusAvailable,
			},
		},
	}
	uc := NewExcursionUseCase(repo, guideVerifierStub{}, nil)

	slots, err := uc.ListPublicExcursionSchedule(context.Background(), ListPublicExcursionScheduleInput{
		ProductID: productID,
		OfferID:   offerID,
		From:      now.Add(-time.Hour),
		To:        now.Add(24 * time.Hour),
		Seats:     1,
	})

	if err != nil {
		t.Fatalf("ListPublicExcursionSchedule() error = %v", err)
	}
	if len(slots) != 1 || slots[0].StartAt != futureStart {
		t.Fatalf("slots = %v, want only future slot %v", slots, futureStart)
	}
	if repo.listScheduleFilter.From.Before(now.Add(2*time.Hour - time.Second)) {
		t.Fatalf("list from = %v, want at least two-hour booking lead time", repo.listScheduleFilter.From)
	}
	if repo.expiredScheduleReason == "" || repo.expiredScheduleCutoff.IsZero() {
		t.Fatal("unbooked near-start slots were not expired before public schedule list")
	}
}

func TestListGuideScheduleExpiresUnbookedSlotsBeforeBookingCutoff(t *testing.T) {
	actorUserID := uuid.New()
	now := time.Now().UTC()
	repo := &excursionRepoStub{}
	uc := NewExcursionUseCase(repo, guideVerifierStub{}, nil)

	_, err := uc.ListGuideSchedule(context.Background(), ListGuideScheduleInput{
		ActorUserID: actorUserID,
		From:        now.Add(-24 * time.Hour),
		To:          now.Add(24 * time.Hour),
	})

	if err != nil {
		t.Fatalf("ListGuideSchedule() error = %v", err)
	}
	if repo.expiredScheduleReason == "" {
		t.Fatal("unbooked near-start slots were not expired before guide schedule list")
	}
	if repo.expiredScheduleCutoff.Before(now.Add(2*time.Hour - time.Second)) {
		t.Fatalf("expire cutoff = %v, want at least now + 2h", repo.expiredScheduleCutoff)
	}
}

func TestListGuideScheduleIncludesCompletedSlotsForReadonlyHistory(t *testing.T) {
	actorUserID := uuid.New()
	now := time.Now().UTC()
	repo := &excursionRepoStub{}
	uc := NewExcursionUseCase(repo, guideVerifierStub{}, nil)

	_, err := uc.ListGuideSchedule(context.Background(), ListGuideScheduleInput{
		ActorUserID: actorUserID,
		From:        now.Add(-24 * time.Hour),
		To:          now.Add(24 * time.Hour),
	})

	if err != nil {
		t.Fatalf("ListGuideSchedule() error = %v", err)
	}
	for _, status := range repo.listScheduleFilter.Statuses {
		if status == enum.ExcursionScheduleSlotStatusCompleted {
			return
		}
	}
	t.Fatalf("status filters = %v, want completed included for guide calendar history", repo.listScheduleFilter.Statuses)
}

func TestListPublicGuideScheduleUsesRequestedGuideUser(t *testing.T) {
	guideUserID := uuid.New()
	now := time.Now().UTC()
	repo := &excursionRepoStub{}
	uc := NewExcursionUseCase(repo, guideVerifierStub{}, nil)

	_, err := uc.ListPublicGuideSchedule(context.Background(), ListPublicGuideScheduleInput{
		GuideUserID: guideUserID,
		From:        now.Add(-24 * time.Hour),
		To:          now.Add(24 * time.Hour),
	})

	if err != nil {
		t.Fatalf("ListPublicGuideSchedule() error = %v", err)
	}
	if repo.listScheduleFilter.GuideUserID == nil || *repo.listScheduleFilter.GuideUserID != guideUserID {
		t.Fatalf("guide filter = %v, want %s", repo.listScheduleFilter.GuideUserID, guideUserID)
	}
	for _, status := range repo.listScheduleFilter.Statuses {
		if status == enum.ExcursionScheduleSlotStatusCompleted {
			return
		}
	}
	t.Fatalf("status filters = %v, want completed included for readonly public guide calendar", repo.listScheduleFilter.Statuses)
}

func TestAutoCompleteDueExcursionScheduleSlotsCompletesEndedSlots(t *testing.T) {
	repo := &excursionRepoStub{completedScheduleCount: 2}
	uc := NewExcursionUseCase(repo, guideVerifierStub{}, nil)

	count, err := uc.AutoCompleteDueExcursionScheduleSlots(context.Background(), 50)
	if err != nil {
		t.Fatalf("AutoCompleteDueExcursionScheduleSlots() error = %v", err)
	}

	if count != 2 {
		t.Fatalf("count = %d, want 2", count)
	}
	if repo.completedScheduleReason != excursionScheduleAutoCompleteReasonEnded {
		t.Fatalf("completion reason = %q, want %q", repo.completedScheduleReason, excursionScheduleAutoCompleteReasonEnded)
	}
	if repo.completedScheduleLimit != 50 {
		t.Fatalf("completion limit = %d, want 50", repo.completedScheduleLimit)
	}
	if repo.completedScheduleBefore.IsZero() {
		t.Fatal("completion cutoff was not passed to repository")
	}
}

func TestGenerateExcursionAttendanceQRRequiresOwnedBookedSlot(t *testing.T) {
	guideUserID := uuid.New()
	slotID := uuid.New()
	repo := &excursionRepoStub{
		gotScheduleSlot: &model.ExcursionScheduleSlot{
			ID:             slotID,
			GuideProfileID: uuid.New(),
			GuideUserID:    guideUserID,
			OfferID:        uuid.New(),
			ProductID:      uuid.New(),
			StartAt:        time.Now().UTC().Add(30 * time.Minute),
			EndAt:          time.Now().UTC().Add(3 * time.Hour),
			Timezone:       "Asia/Almaty",
			Capacity:       8,
			BookedSeats:    2,
			Status:         enum.ExcursionScheduleSlotStatusBooked,
		},
	}
	uc := NewExcursionUseCase(repo, guideVerifierStub{}, nil).
		WithAttendanceQRConfig("test-excursion-secret", time.Minute, 4*time.Hour)

	qr, err := uc.GenerateExcursionAttendanceQR(context.Background(), slotID, guideUserID)
	if err != nil {
		t.Fatalf("GenerateExcursionAttendanceQR() error = %v", err)
	}

	if qr == nil || qr.Token == "" {
		t.Fatal("qr token was not generated")
	}
	if repo.createdAttendanceIssue == nil {
		t.Fatal("attendance qr issue was not persisted")
	}
	if repo.createdAttendanceIssue.ScheduleSlotID != slotID {
		t.Fatalf("issue slot id = %s, want %s", repo.createdAttendanceIssue.ScheduleSlotID, slotID)
	}
}

func TestGenerateExcursionAttendanceQRRejectsSlotsEarlierThanOneHourBeforeStart(t *testing.T) {
	guideUserID := uuid.New()
	slotID := uuid.New()
	repo := &excursionRepoStub{
		gotScheduleSlot: &model.ExcursionScheduleSlot{
			ID:             slotID,
			GuideProfileID: uuid.New(),
			GuideUserID:    guideUserID,
			OfferID:        uuid.New(),
			ProductID:      uuid.New(),
			StartAt:        time.Now().UTC().Add(90 * time.Minute),
			EndAt:          time.Now().UTC().Add(3 * time.Hour),
			Timezone:       "Asia/Almaty",
			Capacity:       8,
			BookedSeats:    2,
			Status:         enum.ExcursionScheduleSlotStatusBooked,
		},
	}
	uc := NewExcursionUseCase(repo, guideVerifierStub{}, nil).
		WithAttendanceQRConfig("test-excursion-secret", time.Minute, 4*time.Hour)

	_, err := uc.GenerateExcursionAttendanceQR(context.Background(), slotID, guideUserID)
	if !errors.Is(err, ErrExcursionAttendanceQRUnavailable) {
		t.Fatalf("GenerateExcursionAttendanceQR() error = %v, want %v", err, ErrExcursionAttendanceQRUnavailable)
	}
	if repo.createdAttendanceIssue != nil {
		t.Fatal("attendance qr issue was persisted for a slot earlier than one hour before start")
	}
}

func TestSyncExcursionAttendanceProofMarksTouristBookingCheckedIn(t *testing.T) {
	guideUserID := uuid.New()
	touristUserID := uuid.New()
	slotID := uuid.New()
	qr, err := signExcursionAttendanceQRToken(
		[]byte("test-excursion-secret"),
		slotID,
		guideUserID,
		uuid.MustParse("44444444-4444-4444-8444-444444444444"),
		time.Now().UTC().Add(-time.Minute),
		time.Now().UTC().Add(time.Minute),
	)
	if err != nil {
		t.Fatalf("signExcursionAttendanceQRToken() error = %v", err)
	}
	repo := &excursionRepoStub{
		gotAttendanceIssue: &model.ExcursionAttendanceQRIssue{
			JTI:            uuid.MustParse("44444444-4444-4444-8444-444444444444"),
			ScheduleSlotID: slotID,
			GuideUserID:    guideUserID,
			IssuedAt:       time.Now().UTC().Add(-time.Minute),
			ExpiresAt:      time.Now().UTC().Add(time.Minute),
			UsableUntil:    time.Now().UTC().Add(3 * time.Hour),
			CreatedAt:      time.Now().UTC().Add(-time.Minute),
		},
		gotScheduleSlot: &model.ExcursionScheduleSlot{
			ID:             slotID,
			GuideProfileID: uuid.New(),
			GuideUserID:    guideUserID,
			OfferID:        uuid.New(),
			ProductID:      uuid.New(),
			StartAt:        time.Now().UTC().Add(-30 * time.Minute),
			EndAt:          time.Now().UTC().Add(90 * time.Minute),
			Timezone:       "Asia/Almaty",
			Capacity:       8,
			BookedSeats:    2,
			Status:         enum.ExcursionScheduleSlotStatusBooked,
		},
		gotAttendanceBooking: &model.ExcursionBooking{
			ID:             uuid.New(),
			ProductID:      uuid.New(),
			OfferID:        uuid.New(),
			ScheduleSlotID: &slotID,
			GuideProfileID: uuid.New(),
			GuideUserID:    guideUserID,
			TouristUserID:  touristUserID,
			ScheduledFor:   time.Now().UTC().Add(-30 * time.Minute),
			Adults:         1,
			Children:       0,
			TotalSeats:     1,
			Currency:       "KZT",
			Status:         enum.ExcursionBookingStatusRequested,
			CreatedAt:      time.Now().UTC().Add(-24 * time.Hour),
			UpdatedAt:      time.Now().UTC().Add(-24 * time.Hour),
		},
	}
	uc := NewExcursionUseCase(repo, guideVerifierStub{}, nil).
		WithAttendanceQRConfig("test-excursion-secret", time.Minute, 4*time.Hour)

	results, err := uc.SyncExcursionAttendanceProofs(context.Background(), touristUserID, []ExcursionAttendanceProofInput{
		{
			ScanID:         uuid.New(),
			QRToken:        qr,
			InstallationID: "installation-1",
		},
	})
	if err != nil {
		t.Fatalf("SyncExcursionAttendanceProofs() error = %v", err)
	}

	if len(results) != 1 || results[0].Status != AttendanceSyncStatusSynced {
		t.Fatalf("results = %+v, want one synced result", results)
	}
	if repo.checkedInAttendanceBooking == nil || repo.checkedInAttendanceBooking.CheckedInAt == nil {
		t.Fatalf("booking was not checked in: %#v", repo.checkedInAttendanceBooking)
	}
	if repo.createdAttendanceAttempt == nil || repo.createdAttendanceAttempt.ResultStatus != model.AttendanceSyncAttemptStatusAccepted {
		t.Fatalf("attendance attempt = %#v, want accepted", repo.createdAttendanceAttempt)
	}
}

func TestSyncExcursionAttendanceProofRejectsBookingForDifferentTourist(t *testing.T) {
	guideUserID := uuid.New()
	touristUserID := uuid.New()
	otherTouristUserID := uuid.New()
	slotID := uuid.New()
	qrJTI := uuid.MustParse("55555555-5555-4555-8555-555555555555")
	qr, err := signExcursionAttendanceQRToken(
		[]byte("test-excursion-secret"),
		slotID,
		guideUserID,
		qrJTI,
		time.Now().UTC().Add(-time.Minute),
		time.Now().UTC().Add(time.Minute),
	)
	if err != nil {
		t.Fatalf("signExcursionAttendanceQRToken() error = %v", err)
	}
	repo := &excursionRepoStub{
		gotAttendanceIssue: &model.ExcursionAttendanceQRIssue{
			JTI:            qrJTI,
			ScheduleSlotID: slotID,
			GuideUserID:    guideUserID,
			IssuedAt:       time.Now().UTC().Add(-time.Minute),
			ExpiresAt:      time.Now().UTC().Add(time.Minute),
			UsableUntil:    time.Now().UTC().Add(3 * time.Hour),
			CreatedAt:      time.Now().UTC().Add(-time.Minute),
		},
		gotScheduleSlot: &model.ExcursionScheduleSlot{
			ID:             slotID,
			GuideProfileID: uuid.New(),
			GuideUserID:    guideUserID,
			OfferID:        uuid.New(),
			ProductID:      uuid.New(),
			StartAt:        time.Now().UTC().Add(-30 * time.Minute),
			EndAt:          time.Now().UTC().Add(90 * time.Minute),
			Timezone:       "Asia/Almaty",
			Capacity:       8,
			BookedSeats:    2,
			Status:         enum.ExcursionScheduleSlotStatusBooked,
		},
		gotAttendanceBooking: &model.ExcursionBooking{
			ID:             uuid.New(),
			ProductID:      uuid.New(),
			OfferID:        uuid.New(),
			ScheduleSlotID: &slotID,
			GuideProfileID: uuid.New(),
			GuideUserID:    guideUserID,
			TouristUserID:  otherTouristUserID,
			ScheduledFor:   time.Now().UTC().Add(-30 * time.Minute),
			Adults:         1,
			Children:       0,
			TotalSeats:     1,
			Currency:       "KZT",
			Status:         enum.ExcursionBookingStatusRequested,
			CreatedAt:      time.Now().UTC().Add(-24 * time.Hour),
			UpdatedAt:      time.Now().UTC().Add(-24 * time.Hour),
		},
	}
	uc := NewExcursionUseCase(repo, guideVerifierStub{}, nil).
		WithAttendanceQRConfig("test-excursion-secret", time.Minute, 4*time.Hour)

	results, err := uc.SyncExcursionAttendanceProofs(context.Background(), touristUserID, []ExcursionAttendanceProofInput{
		{
			ScanID:         uuid.New(),
			QRToken:        qr,
			InstallationID: "installation-1",
		},
	})
	if err != nil {
		t.Fatalf("SyncExcursionAttendanceProofs() error = %v", err)
	}

	if len(results) != 1 || results[0].Status != AttendanceSyncStatusRejected || results[0].Code != "not_registered" {
		t.Fatalf("results = %+v, want one not_registered rejection", results)
	}
	if repo.checkedInAttendanceBooking != nil {
		t.Fatalf("booking for another tourist was checked in: %#v", repo.checkedInAttendanceBooking)
	}
	if repo.createdAttendanceAttempt == nil || repo.createdAttendanceAttempt.ResultStatus != model.AttendanceSyncAttemptStatusRejected {
		t.Fatalf("attendance attempt = %#v, want rejected", repo.createdAttendanceAttempt)
	}
}

func TestListMyGuideExcursionBookingsFiltersByGuideUser(t *testing.T) {
	actorUserID := uuid.New()
	repo := &excursionRepoStub{
		listBookingItems: []*model.ExcursionBookingListItem{
			{Booking: &model.ExcursionBooking{ID: uuid.New(), GuideUserID: actorUserID}},
		},
	}
	uc := NewExcursionUseCase(repo, guideVerifierStub{}, nil)

	items, err := uc.ListMyGuideExcursionBookings(context.Background(), actorUserID, 25, 10)
	if err != nil {
		t.Fatalf("ListMyGuideExcursionBookings() error = %v", err)
	}
	if len(items) != 1 {
		t.Fatalf("items len = %d, want 1", len(items))
	}
	if repo.listBookingFilter.GuideUserID == nil || *repo.listBookingFilter.GuideUserID != actorUserID {
		t.Fatalf("GuideUserID filter = %v, want %s", repo.listBookingFilter.GuideUserID, actorUserID)
	}
	if repo.listBookingFilter.TouristUserID != nil {
		t.Fatalf("TouristUserID filter = %v, want nil", repo.listBookingFilter.TouristUserID)
	}
	if repo.listBookingFilter.Limit != 25 || repo.listBookingFilter.Offset != 10 {
		t.Fatalf("pagination = (%d,%d), want (25,10)", repo.listBookingFilter.Limit, repo.listBookingFilter.Offset)
	}
}

func TestCreateExcursionBookingRejectsOwnOffer(t *testing.T) {
	actorUserID := uuid.New()
	productID := uuid.New()
	offerID := uuid.New()
	repo := &excursionRepoStub{
		gotOffer: &model.ExcursionOffer{
			ID:             offerID,
			ProductID:      productID,
			GuideProfileID: uuid.New(),
			GuideUserID:    actorUserID,
			Status:         enum.ExcursionStatusPublished,
			Visibility:     enum.ExcursionVisibilityPublic,
			MaxGroupSize:   4,
			PriceAmount:    80,
			Currency:       "USD",
		},
	}
	uc := NewExcursionUseCase(repo, guideVerifierStub{}, nil)

	_, err := uc.CreateExcursionBooking(context.Background(), CreateExcursionBookingInput{
		ActorUserID:  actorUserID,
		ProductID:    productID,
		OfferID:      offerID,
		ScheduledFor: time.Now().UTC().Add(24 * time.Hour),
		Adults:       1,
	})

	if !errors.Is(err, ErrExcursionAccessDenied) {
		t.Fatalf("error = %v, want %v", err, ErrExcursionAccessDenied)
	}
	if repo.createdBooking != nil {
		t.Fatal("guide booked their own offer")
	}
}

func mustNewAppTestExcursion(t *testing.T, guideProfileID uuid.UUID, guideUserID uuid.UUID) *model.Excursion {
	t.Helper()
	excursion, err := model.NewExcursion(model.NewExcursionParams{
		GuideProfileID:  guideProfileID,
		GuideUserID:     guideUserID,
		LandmarkID:      uuidPtr(uuid.New()),
		LandmarkName:    stringPtr("Medeu"),
		Title:           "Medeu tour",
		Summary:         "Private mountain route",
		Description:     "A detailed mountain excursion through Medeu.",
		CategorySlug:    "nature",
		Visibility:      enum.ExcursionVisibilityPublic,
		DurationMinutes: 180,
		MaxGroupSize:    6,
		CountryCode:     &testExcursionCountryCode,
		CityName:        &testExcursionCityName,
		MeetingPoint:    "Medeu entrance",
		Latitude:        &testExcursionLatitude,
		Longitude:       &testExcursionLongitude,
		PriceAmount:     120,
		Currency:        "KZT",
	})
	if err != nil {
		t.Fatalf("NewExcursion() error = %v", err)
	}
	return excursion
}

func validAppTestExcursionRelations(excursionID uuid.UUID) port.ExcursionRelations {
	return port.ExcursionRelations{
		LanguageCodes: []string{"en"},
		Itinerary: []*model.ExcursionItineraryItem{
			{
				ID:                 uuid.New(),
				ExcursionID:        excursionID,
				SortOrder:          0,
				StartOffsetMinutes: 0,
				Title:              "Hotel departure",
				Description:        "Meet your guide and start the route.",
			},
		},
	}
}

func containsString(items []string, want string) bool {
	for _, item := range items {
		if item == want {
			return true
		}
	}
	return false
}

func stringPtr(v string) *string {
	return &v
}

func uuidPtr(v uuid.UUID) *uuid.UUID {
	return &v
}
