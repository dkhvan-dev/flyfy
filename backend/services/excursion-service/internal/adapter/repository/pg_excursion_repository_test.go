package repository

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
	"testing"
	"time"

	"github.com/dkhvan-dev/flyfy/backend/services/excursion-service/internal/domain/enum"
	"github.com/dkhvan-dev/flyfy/backend/services/excursion-service/internal/domain/model"
	"github.com/dkhvan-dev/flyfy/backend/services/excursion-service/internal/domain/port"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
)

func TestUpdateExcursionUsesContiguousPlaceholders(t *testing.T) {
	lat := 43.238949
	lng := 76.889709
	country := "KZ"
	city := "Almaty"
	item, err := model.NewExcursion(model.NewExcursionParams{
		GuideProfileID:  uuid.New(),
		GuideUserID:     uuid.New(),
		Title:           "Almaty Mountain Escape",
		Summary:         "Private mountain route",
		Description:     "A guided route through the most scenic mountain stops around Almaty.",
		CategorySlug:    "nature",
		Visibility:      enum.ExcursionVisibilityPublic,
		DurationMinutes: 240,
		MaxGroupSize:    8,
		CountryCode:     &country,
		CityName:        &city,
		MeetingPoint:    "Hotel pickup",
		Latitude:        &lat,
		Longitude:       &lng,
		PriceAmount:     120,
		Currency:        "USD",
	})
	if err != nil {
		t.Fatalf("NewExcursion() error = %v", err)
	}

	err = updateExcursion(context.Background(), placeholderCheckingExecutor{}, item)
	if err != nil {
		t.Fatalf("updateExcursion() error = %v", err)
	}
}

func TestInsertExcursionScheduleSlotUsesContiguousPlaceholders(t *testing.T) {
	slot := validRepositoryScheduleSlot(t)

	err := insertExcursionScheduleSlot(context.Background(), placeholderCheckingExecutor{}, slot)
	if err != nil {
		t.Fatalf("insertExcursionScheduleSlot() error = %v", err)
	}
}

func TestInsertExcursionBookingUsesContiguousPlaceholders(t *testing.T) {
	booking := validRepositoryBooking(t)

	err := insertExcursionBooking(context.Background(), placeholderCheckingExecutor{}, booking)
	if err != nil {
		t.Fatalf("insertExcursionBooking() error = %v", err)
	}
}

func TestInsertExcursionBookingMapsIdempotencyUniqueViolation(t *testing.T) {
	booking := validRepositoryBooking(t)

	err := insertExcursionBooking(
		context.Background(),
		uniqueViolationExecutor{constraintName: "idx_excursion_bookings_tourist_idempotency"},
		booking,
	)

	if !errors.Is(err, port.ErrExcursionBookingIdempotencyConflict) {
		t.Fatalf("error = %v, want %v", err, port.ErrExcursionBookingIdempotencyConflict)
	}
}

func TestExcursionScheduleOverlapConstraintMapsConflict(t *testing.T) {
	slot := validRepositoryScheduleSlot(t)

	err := insertExcursionScheduleSlot(
		context.Background(),
		exclusionViolationExecutor{constraintName: "excursion_schedule_slots_no_guide_overlap"},
		slot,
	)

	if !errors.Is(err, port.ErrExcursionScheduleConflict) {
		t.Fatalf("error = %v, want %v", err, port.ErrExcursionScheduleConflict)
	}
}

func TestReserveExcursionScheduleSlotSeatsUsesGuardedStatusUpdate(t *testing.T) {
	err := reserveExcursionScheduleSlotSeats(
		context.Background(),
		placeholderCheckingExecutor{},
		uuid.New(),
		2,
	)
	if err != nil {
		t.Fatalf("reserveExcursionScheduleSlotSeats() error = %v", err)
	}
}

func TestExpireUnbookedExcursionScheduleSlotsUsesGuardedCancellation(t *testing.T) {
	err := expireUnbookedExcursionScheduleSlots(
		context.Background(),
		placeholderCheckingExecutor{},
		time.Now().UTC().Add(2*time.Hour),
		"NO_BOOKINGS_BEFORE_START_2H",
	)
	if err != nil {
		t.Fatalf("expireUnbookedExcursionScheduleSlots() error = %v", err)
	}
}

func TestCompleteDueExcursionScheduleSlotsUsesGuardedCompletion(t *testing.T) {
	_, err := completeDueExcursionScheduleSlots(
		context.Background(),
		placeholderCheckingExecutor{},
		time.Now().UTC(),
		"SLOT_END_REACHED",
		100,
	)
	if err != nil {
		t.Fatalf("completeDueExcursionScheduleSlots() error = %v", err)
	}
}

func TestReserveExcursionScheduleSlotSeatsReturnsUnavailableWhenNoRows(t *testing.T) {
	err := reserveExcursionScheduleSlotSeats(
		context.Background(),
		affectedRowsExecutor{rowsAffected: 0},
		uuid.New(),
		2,
	)

	if !errors.Is(err, port.ErrExcursionScheduleUnavailable) {
		t.Fatalf("error = %v, want %v", err, port.ErrExcursionScheduleUnavailable)
	}
}

func TestUpdateExcursionBookingGuestsUsesContiguousPlaceholders(t *testing.T) {
	booking := validRepositoryBooking(t)
	booking.Adults = 3
	booking.Children = 1
	booking.TotalSeats = 4

	err := updateExcursionBookingGuests(context.Background(), placeholderCheckingExecutor{}, booking)
	if err != nil {
		t.Fatalf("updateExcursionBookingGuests() error = %v", err)
	}
}

func TestReleaseExcursionScheduleSlotSeatsReturnsUnavailableWhenNoRows(t *testing.T) {
	err := releaseExcursionScheduleSlotSeats(
		context.Background(),
		affectedRowsExecutor{rowsAffected: 0},
		uuid.New(),
		2,
	)

	if !errors.Is(err, port.ErrExcursionScheduleUnavailable) {
		t.Fatalf("error = %v, want %v", err, port.ErrExcursionScheduleUnavailable)
	}
}

func TestAppendReferenceCityConditionMatchesReferenceIDAndLegacyCityName(t *testing.T) {
	parts := []string{"WHERE status = 'PUBLISHED'"}
	args := make([]any, 0, 2)
	cityID := " almaty "
	cityName := " Алматы "

	nextArg := appendReferenceCityCondition(
		&parts,
		&args,
		1,
		"departure_city_id",
		"city_name",
		&cityID,
		&cityName,
	)

	query := strings.Join(parts, "")
	for _, want := range []string{
		"departure_city_id = $1",
		"regexp_replace(lower(trim(COALESCE(city_name, '')))",
		"city_name ILIKE $2",
		" OR ",
	} {
		if !strings.Contains(query, want) {
			t.Fatalf("reference city query missing %q in %s", want, query)
		}
	}
	if nextArg != 3 {
		t.Fatalf("next arg = %d, want 3", nextArg)
	}
	if len(args) != 2 || args[0] != "almaty" || args[1] != "%Алматы%" {
		t.Fatalf("args = %#v, want normalized city id and city name", args)
	}
}

func TestExcursionMarketplaceCanonicalKeyPrefersLandmarkID(t *testing.T) {
	landmarkID := uuid.New()
	routeStopA := uuid.New()
	routeStopB := uuid.New()
	item := validRepositoryExcursion(t)
	item.LandmarkID = &landmarkID
	item.CountryCode = stringPtr("KZ")
	item.CityName = stringPtr("Almaty")
	item.CategorySlug = "nature"
	item.Title = "Almaty Mountain Escape"

	got := excursionMarketplaceCanonicalKey(item, port.ExcursionRelations{
		Itinerary: []*model.ExcursionItineraryItem{
			{AttractionID: &routeStopA},
			{AttractionID: &routeStopB},
		},
	})
	want := "landmark:" + landmarkID.String()

	if got != want {
		t.Fatalf("canonical key = %q, want %q", got, want)
	}
}

func TestExcursionMarketplaceCanonicalKeyGroupsCombinedRouteBySortedAttractions(t *testing.T) {
	first := validRepositoryExcursion(t)
	first.LandmarkID = nil
	first.LandmarkName = nil
	first.CountryCode = stringPtr("KZ")
	first.CityName = stringPtr("Almaty")
	first.CategorySlug = "culture"
	first.DurationMinutes = 180

	a := uuid.MustParse("00000000-0000-0000-0000-000000000001")
	b := uuid.MustParse("00000000-0000-0000-0000-000000000002")
	c := uuid.MustParse("00000000-0000-0000-0000-000000000003")

	firstKey := excursionMarketplaceCanonicalKey(first, port.ExcursionRelations{
		Itinerary: []*model.ExcursionItineraryItem{
			{AttractionID: &a},
			{AttractionID: &b},
			{AttractionID: &c},
		},
	})

	second := *first
	secondKey := excursionMarketplaceCanonicalKey(&second, port.ExcursionRelations{
		Itinerary: []*model.ExcursionItineraryItem{
			{AttractionID: &c},
			{AttractionID: &a},
			{AttractionID: &b},
		},
	})

	if firstKey != secondKey {
		t.Fatalf("canonical keys differ:\nfirst:  %s\nsecond: %s", firstKey, secondKey)
	}
	if !strings.HasPrefix(firstKey, "route:kz:almaty:culture:2-4h:walking:") {
		t.Fatalf("canonical key = %q, want route prefix", firstKey)
	}
}

func TestSyncExcursionMarketplacePassesCombinedRouteMetadataToProduct(t *testing.T) {
	item := validRepositoryExcursion(t)
	item.LandmarkID = nil
	item.LandmarkName = nil
	item.CountryCode = stringPtr("KZ")
	item.CityName = stringPtr("Almaty")
	item.CategorySlug = "culture"
	item.DurationMinutes = 180

	a := uuid.MustParse("00000000-0000-0000-0000-000000000001")
	b := uuid.MustParse("00000000-0000-0000-0000-000000000002")
	exec := &marketplaceRecordingExecutor{queryRows: []uuid.UUID{uuid.New(), uuid.New()}}

	err := syncExcursionMarketplace(context.Background(), exec, item, port.ExcursionRelations{
		Itinerary: []*model.ExcursionItineraryItem{
			{AttractionID: &a, AttractionName: stringPtr("Kok-Tobe")},
			{AttractionID: &b, AttractionName: stringPtr("Cathedral")},
		},
	})
	if err != nil {
		t.Fatalf("syncExcursionMarketplace() error = %v", err)
	}

	productArgs := exec.queryRowArgs[0]
	if got := fmt.Sprint(productArgs[22]); got != "COMBINED_ROUTE" {
		t.Fatalf("route_kind arg = %q, want COMBINED_ROUTE", got)
	}
	if got := fmt.Sprint(productArgs[23]); !strings.HasPrefix(got, "route:kz:almaty:culture:2-4h:walking:") {
		t.Fatalf("route_fingerprint arg = %q, want route fingerprint", got)
	}
	attractionIDs, ok := productArgs[24].([]uuid.UUID)
	if !ok {
		t.Fatalf("attraction_ids arg type = %T, want []uuid.UUID", productArgs[24])
	}
	if len(attractionIDs) != 2 || attractionIDs[0] != a || attractionIDs[1] != b {
		t.Fatalf("attraction_ids arg = %#v, want sorted [%s %s]", attractionIDs, a, b)
	}
	attractionNames, ok := productArgs[25].([]string)
	if !ok {
		t.Fatalf("attraction_names arg type = %T, want []string", productArgs[25])
	}
	if strings.Join(attractionNames, ",") != "Kok-Tobe,Cathedral" {
		t.Fatalf("attraction_names arg = %#v, want sorted attraction names", attractionNames)
	}
	if got := fmt.Sprint(productArgs[26]); got != "2" {
		t.Fatalf("stop_count arg = %q, want 2", got)
	}
}

func TestInsertExcursionMapsGuideLandmarkUniqueViolation(t *testing.T) {
	item := validRepositoryExcursion(t)

	err := insertExcursion(
		context.Background(),
		uniqueViolationExecutor{constraintName: "uq_excursions_active_guide_landmark"},
		item,
	)

	if !errors.Is(err, model.ErrExcursionGuideLandmarkAlreadyExists) {
		t.Fatalf("error = %v, want %v", err, model.ErrExcursionGuideLandmarkAlreadyExists)
	}
}

func TestGuideLandmarkUniquenessMigrationExists(t *testing.T) {
	source, err := os.ReadFile("../../../migrations/009_unique_active_guide_landmark.up.sql")
	if err != nil {
		t.Fatalf("read uniqueness migration: %v", err)
	}

	migration := string(source)
	if !strings.Contains(migration, "uq_excursions_active_guide_landmark") ||
		!strings.Contains(migration, "guide_user_id, landmark_id") ||
		!strings.Contains(migration, "deleted_at IS NULL") {
		t.Fatalf("migration does not enforce active guide landmark uniqueness:\n%s", migration)
	}
}

func TestExcursionScheduleMigrationMatchesDomainNullability(t *testing.T) {
	if _, err := os.Stat("../../../migrations/010_excursion_schedule.up.sql"); !errors.Is(err, os.ErrNotExist) {
		t.Fatalf("old duplicate 010 schedule migration still exists or stat failed: %v", err)
	}
	source, err := os.ReadFile("../../../migrations/011_excursion_schedule.up.sql")
	if err != nil {
		t.Fatalf("read schedule migration: %v", err)
	}

	migration := string(source)
	for _, required := range []string{
		"series_id UUID NULL",
		"legacy_excursion_id UUID NULL",
		"default_capacity INTEGER NULL",
		"ARRAY[1, 2, 3, 4, 5, 6, 7]::SMALLINT[]",
		"excursion_schedule_slots_no_guide_overlap",
	} {
		if !strings.Contains(migration, required) {
			t.Fatalf("schedule migration missing %q:\n%s", required, migration)
		}
	}
	if strings.Contains(migration, "default_end_time") {
		t.Fatalf("schedule migration still requires default_end_time:\n%s", migration)
	}
}

func TestCombinedRouteMigrationAddsRouteMetadata(t *testing.T) {
	migration := readMigration(t, "015_combined_excursion_routes.up.sql")
	required := []string{
		"ALTER TABLE excursion_products",
		"route_kind TEXT NOT NULL DEFAULT 'SINGLE_ATTRACTION'",
		"route_fingerprint TEXT NULL",
		"attraction_ids UUID[] NULL",
		"attraction_names TEXT[] NULL",
		"stop_count INT NOT NULL DEFAULT 0",
		"transport_mode TEXT NOT NULL DEFAULT 'WALKING'",
		"route_theme TEXT NULL",
		"duration_bucket TEXT NULL",
		"chk_excursion_products_attraction_ids_cardinality",
		"chk_excursion_products_attraction_names_cardinality",
		"chk_excursion_products_single_attraction_shape",
		"chk_excursion_products_combined_route_shape",
		"route_kind = CASE",
		"WHEN landmark_id IS NULL THEN 'COMBINED_ROUTE'",
		"route_fingerprint = canonical_key",
		"attraction_ids = CASE",
		"WHEN landmark_id IS NULL THEN NULL",
		"ELSE ARRAY[landmark_id]::UUID[]",
		"attraction_names = CASE",
		"WHEN landmark_id IS NULL OR landmark_name IS NULL OR BTRIM(landmark_name) = '' THEN NULL",
		"stop_count = CASE",
		"WHEN landmark_id IS NULL THEN 0",
		"ELSE 1",
		"WHEN duration_minutes IS NULL THEN NULL",
		"WHERE route_fingerprint IS NULL",
		"WHERE attraction_ids IS NOT NULL",
		"ALTER TABLE excursion_itinerary_items",
		"attraction_id UUID NULL",
		"attraction_name VARCHAR(180) NULL",
		"latitude NUMERIC(10,7) NULL",
		"longitude NUMERIC(10,7) NULL",
		"travel_from_previous_minutes INT NULL",
		"uq_excursion_products_route_fingerprint",
	}
	for _, fragment := range required {
		if !strings.Contains(migration, fragment) {
			t.Fatalf("migration missing %q\n%s", fragment, migration)
		}
	}

	downMigration := readMigration(t, "015_combined_excursion_routes.down.sql")
	for _, fragment := range []string{
		"DROP COLUMN IF EXISTS route_kind",
		"DROP INDEX IF EXISTS uq_excursion_products_route_fingerprint",
		"DROP CONSTRAINT IF EXISTS chk_excursion_products_attraction_ids_cardinality",
		"DROP CONSTRAINT IF EXISTS chk_excursion_products_attraction_names_cardinality",
		"DROP CONSTRAINT IF EXISTS chk_excursion_products_single_attraction_shape",
		"DROP CONSTRAINT IF EXISTS chk_excursion_products_combined_route_shape",
		"DROP COLUMN IF EXISTS travel_from_previous_minutes",
	} {
		if !strings.Contains(downMigration, fragment) {
			t.Fatalf("down migration missing %q\n%s", fragment, downMigration)
		}
	}
}

func TestReviewCommentMigrationAllowsRatingOnlyReviews(t *testing.T) {
	upMigration := readMigration(t, "017_allow_empty_review_comments.up.sql")
	requiredUpFragments := []string{
		"DROP CONSTRAINT IF EXISTS chk_excursion_reviews_comment",
		"ADD CONSTRAINT chk_excursion_reviews_comment",
		"DROP CONSTRAINT IF EXISTS chk_guide_reviews_comment",
		"ADD CONSTRAINT chk_guide_reviews_comment",
		"CHECK (length(comment) <= 2000)",
	}
	for _, fragment := range requiredUpFragments {
		if !strings.Contains(upMigration, fragment) {
			t.Fatalf("up migration missing %q\n%s", fragment, upMigration)
		}
	}
	if strings.Contains(upMigration, "length(trim(comment)) > 0") {
		t.Fatalf("up migration still rejects rating-only reviews:\n%s", upMigration)
	}

	downMigration := readMigration(t, "017_allow_empty_review_comments.down.sql")
	requiredDownFragments := []string{
		"UPDATE excursion_reviews",
		"UPDATE guide_reviews",
		"DROP CONSTRAINT IF EXISTS chk_excursion_reviews_comment",
		"ADD CONSTRAINT chk_excursion_reviews_comment",
		"DROP CONSTRAINT IF EXISTS chk_guide_reviews_comment",
		"ADD CONSTRAINT chk_guide_reviews_comment",
		"CHECK (length(trim(comment)) > 0 AND length(comment) <= 2000)",
	}
	for _, fragment := range requiredDownFragments {
		if !strings.Contains(downMigration, fragment) {
			t.Fatalf("down migration missing %q\n%s", fragment, downMigration)
		}
	}
}

func TestExcursionMarketplaceCanonicalKeyNormalizesCustomRoute(t *testing.T) {
	item := validRepositoryExcursion(t)
	item.LandmarkID = nil
	item.CountryCode = stringPtr(" kz ")
	item.CityName = stringPtr(" Almaty ")
	item.CategorySlug = " Nature Excursions "
	item.Title = "  Almaty   Mountain -- Escape! "

	got := excursionMarketplaceCanonicalKey(item, port.ExcursionRelations{})
	want := "custom:kz:almaty:nature-excursions:almaty-mountain-escape"

	if got != want {
		t.Fatalf("canonical key = %q, want %q", got, want)
	}
}

func TestSyncExcursionMarketplaceUsesContiguousPlaceholders(t *testing.T) {
	item := validRepositoryExcursion(t)
	coverFileID := uuid.New()

	err := syncExcursionMarketplace(
		context.Background(),
		&marketplacePlaceholderExecutor{queryRows: []uuid.UUID{uuid.New(), uuid.New()}},
		item,
		port.ExcursionRelations{
			LanguageCodes: []string{"en", "ru"},
			IncludedItems: []model.ExcursionIncludedItem{
				model.NewExcursionIncludedItem("Transport", nil),
				model.NewExcursionIncludedItem("Tickets", nil),
			},
			CoverFileID: &coverFileID,
		},
	)
	if err != nil {
		t.Fatalf("syncExcursionMarketplace() error = %v", err)
	}
}

func TestSyncExcursionMarketplaceKeepsSharedCardAndOfferAttractionBased(t *testing.T) {
	item := validRepositoryExcursion(t)
	landmarkName := "Medeu"
	item.LandmarkName = &landmarkName
	item.Title = "Aruzhan's sunrise Medeu walk"
	item.Summary = "My private sunrise route"
	item.Description = "My author description with my exact selling points."

	exec := &marketplaceRecordingExecutor{
		queryRows: []uuid.UUID{uuid.New(), uuid.New()},
	}
	err := syncExcursionMarketplace(
		context.Background(),
		exec,
		item,
		port.ExcursionRelations{
			LanguageCodes: []string{"en"},
			IncludedItems: []model.ExcursionIncludedItem{
				model.NewExcursionIncludedItem("Transport", nil),
			},
		},
	)
	if err != nil {
		t.Fatalf("syncExcursionMarketplace() error = %v", err)
	}
	if len(exec.queryRowArgs) != 2 {
		t.Fatalf("QueryRow calls = %d, want 2", len(exec.queryRowArgs))
	}

	productArgs := exec.queryRowArgs[0]
	if got := fmt.Sprint(productArgs[4]); got != "Medeu" {
		t.Fatalf("product title = %q, want neutral landmark title", got)
	}
	if got := fmt.Sprint(productArgs[5]); strings.Contains(got, "Aruzhan") || strings.Contains(got, "private sunrise") {
		t.Fatalf("product summary leaks guide copy: %q", got)
	}
	if got := fmt.Sprint(productArgs[6]); strings.Contains(got, "author description") || strings.Contains(got, "selling points") {
		t.Fatalf("product description leaks guide copy: %q", got)
	}

	offerArgs := exec.queryRowArgs[1]
	if got := fmt.Sprint(offerArgs[10]); got != "Medeu" {
		t.Fatalf("offer title = %q, want neutral landmark title", got)
	}
	if got := fmt.Sprint(offerArgs[11]); strings.Contains(got, "Aruzhan") || strings.Contains(got, "private sunrise") {
		t.Fatalf("offer summary leaks guide copy: %q", got)
	}
	if got := fmt.Sprint(offerArgs[12]); strings.Contains(got, "author description") || strings.Contains(got, "selling points") {
		t.Fatalf("offer description leaks guide copy: %q", got)
	}
}

func TestSyncExcursionMarketplaceUsesProductCoverForSharedCardAndOfferCoverForGuide(t *testing.T) {
	item := validRepositoryExcursion(t)
	landmarkID := uuid.New()
	landmarkName := "Medeu"
	item.LandmarkID = &landmarkID
	item.LandmarkName = &landmarkName
	productCoverFileID := uuid.New()
	offerCoverFileID := uuid.New()

	exec := &marketplaceRecordingExecutor{
		queryRows: []uuid.UUID{uuid.New(), uuid.New()},
	}
	err := syncExcursionMarketplace(
		context.Background(),
		exec,
		item,
		port.ExcursionRelations{
			LanguageCodes:      []string{"en"},
			ProductCoverFileID: &productCoverFileID,
			CoverFileID:        &offerCoverFileID,
		},
	)
	if err != nil {
		t.Fatalf("syncExcursionMarketplace() error = %v", err)
	}
	if len(exec.queryRowArgs) != 2 {
		t.Fatalf("QueryRow calls = %d, want 2", len(exec.queryRowArgs))
	}

	productArgs := exec.queryRowArgs[0]
	if got, ok := productArgs[17].(*uuid.UUID); !ok || got == nil || *got != productCoverFileID {
		t.Fatalf("product cover arg = %#v, want product cover %s", productArgs[17], productCoverFileID)
	}

	offerArgs := exec.queryRowArgs[1]
	if got, ok := offerArgs[23].(*uuid.UUID); !ok || got == nil || *got != offerCoverFileID {
		t.Fatalf("offer cover arg = %#v, want offer cover %s", offerArgs[23], offerCoverFileID)
	}
}

func TestSyncExcursionMarketplaceUsesExternalProductCoverFallback(t *testing.T) {
	item := validRepositoryExcursion(t)
	landmarkID := uuid.New()
	landmarkName := "Dragon Bridge"
	item.LandmarkID = &landmarkID
	item.LandmarkName = &landmarkName
	productCoverImageURL := "https://upload.wikimedia.org/dragon-bridge.jpg"

	exec := &marketplaceRecordingExecutor{
		queryRows: []uuid.UUID{uuid.New(), uuid.New()},
	}
	err := syncExcursionMarketplace(
		context.Background(),
		exec,
		item,
		port.ExcursionRelations{
			LanguageCodes:        []string{"en"},
			ProductCoverImageURL: &productCoverImageURL,
		},
	)
	if err != nil {
		t.Fatalf("syncExcursionMarketplace() error = %v", err)
	}
	if len(exec.queryRowArgs) != 2 {
		t.Fatalf("QueryRow calls = %d, want 2", len(exec.queryRowArgs))
	}

	productArgs := exec.queryRowArgs[0]
	if got, ok := productArgs[17].(*uuid.UUID); !ok || got != nil {
		t.Fatalf("product cover file arg = %#v, want nil", productArgs[17])
	}
	if got, ok := productArgs[18].(*string); !ok || got == nil || *got != productCoverImageURL {
		t.Fatalf("product cover image url arg = %#v, want %s", productArgs[18], productCoverImageURL)
	}
}

func TestGetProductCoverFileIDUsesLegacyOfferProductCover(t *testing.T) {
	excursionID := uuid.New()
	productCoverFileID := uuid.New()
	exec := &singleQueryRowExecutor{row: uuidRow{id: productCoverFileID}}

	got, err := getProductCoverFileID(context.Background(), exec, excursionID)

	if err != nil {
		t.Fatalf("getProductCoverFileID() error = %v", err)
	}
	if got == nil || *got != productCoverFileID {
		t.Fatalf("product cover file id = %v, want %s", got, productCoverFileID)
	}
	if len(exec.args) != 1 || exec.args[0] != excursionID {
		t.Fatalf("query args = %#v, want [%s]", exec.args, excursionID)
	}
	if !strings.Contains(exec.query, "excursion_offers") ||
		!strings.Contains(exec.query, "excursion_products") ||
		!strings.Contains(exec.query, "legacy_excursion_id") {
		t.Fatalf("query does not join offer to product cover:\n%s", exec.query)
	}
}

func TestGetProductCoverImageURLUsesLegacyOfferProductCover(t *testing.T) {
	excursionID := uuid.New()
	productCoverImageURL := "https://upload.wikimedia.org/dragon-bridge.jpg"
	exec := &singleQueryRowExecutor{row: stringRow{value: productCoverImageURL}}

	got, err := getProductCoverImageURL(context.Background(), exec, excursionID)

	if err != nil {
		t.Fatalf("getProductCoverImageURL() error = %v", err)
	}
	if got == nil || *got != productCoverImageURL {
		t.Fatalf("product cover image url = %v, want %s", got, productCoverImageURL)
	}
	if len(exec.args) != 1 || exec.args[0] != excursionID {
		t.Fatalf("query args = %#v, want [%s]", exec.args, excursionID)
	}
	if !strings.Contains(exec.query, "excursion_offers") ||
		!strings.Contains(exec.query, "excursion_products") ||
		!strings.Contains(exec.query, "legacy_excursion_id") {
		t.Fatalf("query does not join offer to product cover:\n%s", exec.query)
	}
}

func TestSyncExcursionMarketplacePersistsPreparedTranslations(t *testing.T) {
	item := validRepositoryExcursion(t)
	item.Translations = model.ExcursionTranslations{
		"kk": {
			Title:       "Шарын бойынша авторлық бағыт",
			Summary:     "Гидпен бағыт",
			Description: "Шарын шатқалы бойынша гидтің толық сипаттамасы.",
		},
	}
	item.ProductTranslations = model.ExcursionTranslations{
		"kk": {
			Title:       "Шарын шатқалы",
			Summary:     "Шарын шатқалы бойынша гид ұсыныстарын салыстырыңыз.",
			Description: "Гидті, тілді, бағаны және кездесу орнын таңдаңыз.",
		},
	}

	exec := &marketplaceRecordingExecutor{
		queryRows: []uuid.UUID{uuid.New(), uuid.New()},
	}
	if err := syncExcursionMarketplace(context.Background(), exec, item, port.ExcursionRelations{}); err != nil {
		t.Fatalf("syncExcursionMarketplace() error = %v", err)
	}
	if len(exec.queryRowArgs) != 2 {
		t.Fatalf("QueryRow calls = %d, want 2", len(exec.queryRowArgs))
	}

	productTranslations := decodeTranslationsArg(t, exec.queryRowArgs[0][21])
	if got := productTranslations["kk"].Title; got != "Шарын шатқалы" {
		t.Fatalf("product kk title = %q", got)
	}

	offerTranslations := decodeTranslationsArg(t, exec.queryRowArgs[1][29])
	if len(offerTranslations) != 0 {
		t.Fatalf("offer translations = %#v, want empty because guide copy is no longer part of offers", offerTranslations)
	}
}

func TestExcursionOfferOrderBySupportsRatingExperienceAndPriceDirections(t *testing.T) {
	cases := []struct {
		name          string
		sort          string
		direction     string
		wantSubstring string
	}{
		{
			name:          "rating descending",
			sort:          "rating",
			direction:     "desc",
			wantSubstring: "guide_rating_avg DESC, guide_reviews_count DESC",
		},
		{
			name:          "rating ascending",
			sort:          "rating",
			direction:     "asc",
			wantSubstring: "guide_rating_avg ASC, guide_reviews_count DESC",
		},
		{
			name:          "experience descending",
			sort:          "experience",
			direction:     "desc",
			wantSubstring: "guide_experience_years DESC, guide_rating_avg DESC",
		},
		{
			name:          "experience ascending",
			sort:          "experience",
			direction:     "asc",
			wantSubstring: "guide_experience_years ASC, guide_rating_avg DESC",
		},
		{
			name:          "price ascending",
			sort:          "price",
			direction:     "asc",
			wantSubstring: "price_amount ASC, guide_rating_avg DESC",
		},
		{
			name:          "price descending",
			sort:          "price",
			direction:     "desc",
			wantSubstring: "price_amount DESC, guide_rating_avg DESC",
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			got := excursionOfferOrderBy(tc.sort, tc.direction)
			if !strings.Contains(got, tc.wantSubstring) {
				t.Fatalf("order by = %q, want to contain %q", got, tc.wantSubstring)
			}
		})
	}
}

func TestSmartSearchNeedleGroupsTransliteratesLatinToCyrillic(t *testing.T) {
	groups := smartSearchNeedleGroups("char canyon")
	if len(groups) != 2 {
		t.Fatalf("groups = %#v, want 2 token groups", groups)
	}
	if !containsString(groups[0], "char") || !containsString(groups[0], "чар") {
		t.Fatalf("first token variants = %#v, want latin and cyrillic char variants", groups[0])
	}
	if !containsString(groups[1], "canyon") || !containsString(groups[1], "каньон") {
		t.Fatalf("second token variants = %#v, want latin and cyrillic canyon variants", groups[1])
	}
}

func TestSmartSearchNeedleGroupsTransliteratesCyrillicToLatin(t *testing.T) {
	groups := smartSearchNeedleGroups("Чарын")
	if len(groups) != 1 {
		t.Fatalf("groups = %#v, want 1 token group", groups)
	}
	if !containsString(groups[0], "чарын") || !containsString(groups[0], "charyn") {
		t.Fatalf("variants = %#v, want cyrillic and latin Charyn variants", groups[0])
	}
}

func TestAppendSmartSearchConditionBuildsTokenizedRelationSearch(t *testing.T) {
	parts := []string{"SELECT 1 WHERE TRUE"}
	args := make([]any, 0)
	argPos := appendSmartSearchCondition(
		&parts,
		&args,
		1,
		"char canyon",
		[]smartSearchTarget{
			columnSmartSearchTarget("excursion_products.title"),
			templatedSmartSearchTarget(`EXISTS (
				SELECT 1
				FROM excursion_offers o_search
				WHERE o_search.product_id = excursion_products.id
				  AND LOWER(COALESCE(o_search.title, '')) LIKE %s
			)`),
		},
	)

	query := strings.Join(parts, "")
	if argPos != len(args)+1 {
		t.Fatalf("next arg position = %d, args = %d", argPos, len(args))
	}
	if err := validateContiguousPlaceholders(query, len(args)); err != nil {
		t.Fatalf("placeholders are not contiguous: %v\nquery:\n%s", err, query)
	}
	if strings.Count(query, " AND (") != 2 {
		t.Fatalf("query = %q, want one AND group per search token", query)
	}
	if !strings.Contains(query, "excursion_products.title") || !strings.Contains(query, "excursion_offers") {
		t.Fatalf("query = %q, want product and related offer search targets", query)
	}
	if !containsArgument(args, "%чар%") || !containsArgument(args, "%каньон%") {
		t.Fatalf("args = %#v, want cyrillic transliteration needles", args)
	}
}

func TestExcursionOfferSmartSearchTargetsIncludeGuideSnapshot(t *testing.T) {
	parts := []string{"SELECT 1 FROM excursion_offers WHERE TRUE"}
	args := make([]any, 0)
	argPos := appendSmartSearchCondition(
		&parts,
		&args,
		1,
		"aruzhan",
		excursionOfferSmartSearchTargets(),
	)

	query := strings.Join(parts, "")
	if argPos != len(args)+1 {
		t.Fatalf("next arg position = %d, args = %d", argPos, len(args))
	}
	if err := validateContiguousPlaceholders(query, len(args)); err != nil {
		t.Fatalf("placeholders are not contiguous: %v\nquery:\n%s", err, query)
	}
	if !strings.Contains(query, "excursion_offers.guide_display_name") {
		t.Fatalf("query = %q, want guide display name snapshot target", query)
	}
	if !strings.Contains(query, "excursion_offers.guide_search_text") {
		t.Fatalf("query = %q, want guide search text snapshot target", query)
	}
}

func TestMarketplaceProductCopyPreservesCustomRouteCopyWithoutLandmark(t *testing.T) {
	item := validRepositoryExcursion(t)
	item.LandmarkID = nil
	item.LandmarkName = nil
	item.CityName = stringPtr("Almaty")
	item.Title = "Author's hidden gorge route"
	item.Summary = "A specific custom route summary"
	item.Description = "A specific custom route description."

	if got := marketplaceProductTitle(item); got != item.Title {
		t.Fatalf("custom product title = %q, want %q", got, item.Title)
	}
	if got := marketplaceProductSummary(item); got != item.Summary {
		t.Fatalf("custom product summary = %q, want %q", got, item.Summary)
	}
	if got := marketplaceProductDescription(item); got != item.Description {
		t.Fatalf("custom product description = %q, want %q", got, item.Description)
	}
}

func TestMarketplaceProductStatusRequiresPublicVisibility(t *testing.T) {
	item := validRepositoryExcursion(t)
	item.Status = enum.ExcursionStatusPublished
	item.Visibility = enum.ExcursionVisibilityUnlisted

	got := marketplaceProductStatus(item)

	if got != string(enum.ExcursionStatusDraft) {
		t.Fatalf("marketplace product status = %q, want %q", got, enum.ExcursionStatusDraft)
	}
}

func decodeTranslationsArg(t *testing.T, arg any) model.ExcursionTranslations {
	t.Helper()
	raw, ok := arg.(string)
	if !ok {
		t.Fatalf("translations arg type = %T, want string", arg)
	}
	var translations model.ExcursionTranslations
	if err := json.Unmarshal([]byte(raw), &translations); err != nil {
		t.Fatalf("decode translations: %v", err)
	}
	return translations
}

func validRepositoryExcursion(t *testing.T) *model.Excursion {
	t.Helper()
	lat := 43.238949
	lng := 76.889709
	country := "KZ"
	city := "Almaty"
	item, err := model.NewExcursion(model.NewExcursionParams{
		GuideProfileID:  uuid.New(),
		GuideUserID:     uuid.New(),
		Title:           "Almaty Mountain Escape",
		Summary:         "Private mountain route",
		Description:     "A guided route through the most scenic mountain stops around Almaty.",
		CategorySlug:    "nature",
		Visibility:      enum.ExcursionVisibilityPublic,
		DurationMinutes: 240,
		MaxGroupSize:    8,
		CountryCode:     &country,
		CityName:        &city,
		MeetingPoint:    "Hotel pickup",
		Latitude:        &lat,
		Longitude:       &lng,
		PriceAmount:     120,
		Currency:        "USD",
	})
	if err != nil {
		t.Fatalf("NewExcursion() error = %v", err)
	}
	return item
}

func validRepositoryBooking(t *testing.T) *model.ExcursionBooking {
	t.Helper()

	idempotencyKey := uuid.NewString()
	item, err := model.NewExcursionBooking(model.NewExcursionBookingParams{
		ProductID:       uuid.New(),
		OfferID:         uuid.New(),
		GuideProfileID:  uuid.New(),
		GuideUserID:     uuid.New(),
		TouristUserID:   uuid.New(),
		ScheduledFor:    time.Date(2026, 6, 2, 9, 0, 0, 0, time.UTC),
		Adults:          2,
		Children:        1,
		UnitPriceAmount: 120,
		Currency:        "KZT",
		IdempotencyKey:  &idempotencyKey,
	})
	if err != nil {
		t.Fatalf("NewExcursionBooking() error = %v", err)
	}
	return item
}

func stringPtr(value string) *string {
	return &value
}

func readMigration(t *testing.T, name string) string {
	t.Helper()
	path := filepath.Join("..", "..", "..", "migrations", name)
	content, err := os.ReadFile(path)
	if err != nil {
		t.Fatalf("read migration %s: %v", name, err)
	}
	return string(content)
}

func containsString(items []string, want string) bool {
	for _, item := range items {
		if item == want {
			return true
		}
	}
	return false
}

func containsArgument(args []any, want string) bool {
	for _, arg := range args {
		if got, ok := arg.(string); ok && got == want {
			return true
		}
	}
	return false
}

type placeholderCheckingExecutor struct{}

func (placeholderCheckingExecutor) Exec(_ context.Context, query string, arguments ...any) (pgconn.CommandTag, error) {
	if err := validateContiguousPlaceholders(query, len(arguments)); err != nil {
		return pgconn.CommandTag{}, err
	}
	return pgconn.NewCommandTag("UPDATE 1"), nil
}

func (placeholderCheckingExecutor) QueryRow(context.Context, string, ...any) pgx.Row {
	return nil
}

type uniqueViolationExecutor struct {
	constraintName string
}

func (e uniqueViolationExecutor) Exec(context.Context, string, ...any) (pgconn.CommandTag, error) {
	return pgconn.CommandTag{}, &pgconn.PgError{
		Code:           pgUniqueViolation,
		ConstraintName: e.constraintName,
	}
}

func (uniqueViolationExecutor) QueryRow(context.Context, string, ...any) pgx.Row {
	return nil
}

type exclusionViolationExecutor struct {
	constraintName string
}

func (e exclusionViolationExecutor) Exec(context.Context, string, ...any) (pgconn.CommandTag, error) {
	return pgconn.CommandTag{}, &pgconn.PgError{
		Code:           pgExclusionViolation,
		ConstraintName: e.constraintName,
	}
}

func (exclusionViolationExecutor) QueryRow(context.Context, string, ...any) pgx.Row {
	return nil
}

type affectedRowsExecutor struct {
	rowsAffected int64
}

func (e affectedRowsExecutor) Exec(_ context.Context, query string, arguments ...any) (pgconn.CommandTag, error) {
	if err := validateContiguousPlaceholders(query, len(arguments)); err != nil {
		return pgconn.CommandTag{}, err
	}
	return pgconn.NewCommandTag(fmt.Sprintf("UPDATE %d", e.rowsAffected)), nil
}

func (affectedRowsExecutor) QueryRow(context.Context, string, ...any) pgx.Row {
	return nil
}

type marketplacePlaceholderExecutor struct {
	queryRows []uuid.UUID
}

func (e *marketplacePlaceholderExecutor) Exec(_ context.Context, query string, arguments ...any) (pgconn.CommandTag, error) {
	if err := validateContiguousPlaceholders(query, len(arguments)); err != nil {
		return pgconn.CommandTag{}, err
	}
	return pgconn.NewCommandTag("UPDATE 1"), nil
}

func (e *marketplacePlaceholderExecutor) QueryRow(_ context.Context, query string, arguments ...any) pgx.Row {
	if err := validateContiguousPlaceholders(query, len(arguments)); err != nil {
		return errorRow{err: err}
	}
	if len(e.queryRows) == 0 {
		return errorRow{err: fmt.Errorf("unexpected QueryRow call")}
	}
	id := e.queryRows[0]
	e.queryRows = e.queryRows[1:]
	return uuidRow{id: id}
}

type marketplaceRecordingExecutor struct {
	queryRows    []uuid.UUID
	queryRowArgs [][]any
}

func (e *marketplaceRecordingExecutor) Exec(_ context.Context, query string, arguments ...any) (pgconn.CommandTag, error) {
	if err := validateContiguousPlaceholders(query, len(arguments)); err != nil {
		return pgconn.CommandTag{}, err
	}
	return pgconn.NewCommandTag("UPDATE 1"), nil
}

func (e *marketplaceRecordingExecutor) QueryRow(_ context.Context, query string, arguments ...any) pgx.Row {
	if err := validateContiguousPlaceholders(query, len(arguments)); err != nil {
		return errorRow{err: err}
	}
	if len(e.queryRows) == 0 {
		return errorRow{err: fmt.Errorf("unexpected QueryRow call")}
	}
	e.queryRowArgs = append(e.queryRowArgs, append([]any(nil), arguments...))
	id := e.queryRows[0]
	e.queryRows = e.queryRows[1:]
	return uuidRow{id: id}
}

type singleQueryRowExecutor struct {
	query string
	args  []any
	row   pgx.Row
}

func (e *singleQueryRowExecutor) QueryRow(_ context.Context, query string, arguments ...any) pgx.Row {
	e.query = query
	e.args = append([]any(nil), arguments...)
	return e.row
}

type uuidRow struct {
	id uuid.UUID
}

func (r uuidRow) Scan(dest ...any) error {
	if len(dest) != 1 {
		return fmt.Errorf("destinations = %d, want 1", len(dest))
	}
	target, ok := dest[0].(*uuid.UUID)
	if !ok {
		return fmt.Errorf("destination type = %T, want *uuid.UUID", dest[0])
	}
	*target = r.id
	return nil
}

type stringRow struct {
	value string
}

func (r stringRow) Scan(dest ...any) error {
	if len(dest) != 1 {
		return fmt.Errorf("destinations = %d, want 1", len(dest))
	}
	target, ok := dest[0].(*string)
	if !ok {
		return fmt.Errorf("destination type = %T, want *string", dest[0])
	}
	*target = r.value
	return nil
}

type errorRow struct {
	err error
}

func (r errorRow) Scan(...any) error {
	return r.err
}

func validateContiguousPlaceholders(query string, argCount int) error {
	matches := regexp.MustCompile(`\$(\d+)`).FindAllStringSubmatch(query, -1)
	seen := make(map[int]struct{}, len(matches))
	maxPlaceholder := 0
	for _, match := range matches {
		value, err := strconv.Atoi(match[1])
		if err != nil {
			return err
		}
		seen[value] = struct{}{}
		if value > maxPlaceholder {
			maxPlaceholder = value
		}
	}
	if maxPlaceholder != argCount {
		return fmt.Errorf("max placeholder = %d, args = %d", maxPlaceholder, argCount)
	}
	for index := 1; index <= maxPlaceholder; index++ {
		if _, ok := seen[index]; !ok {
			return fmt.Errorf("placeholder $%d is not used", index)
		}
	}
	return nil
}

func validRepositoryScheduleSlot(t *testing.T) *model.ExcursionScheduleSlot {
	t.Helper()

	startAt := time.Date(2026, 6, 1, 10, 0, 0, 0, time.UTC)
	seriesID := uuid.New()
	legacyExcursionID := uuid.New()
	slot, err := model.NewExcursionScheduleSlot(model.NewExcursionScheduleSlotParams{
		SeriesID:          &seriesID,
		GuideProfileID:    uuid.New(),
		GuideUserID:       uuid.New(),
		OfferID:           uuid.New(),
		ProductID:         uuid.New(),
		LegacyExcursionID: &legacyExcursionID,
		StartAt:           startAt,
		EndAt:             startAt.Add(2 * time.Hour),
		Timezone:          "Asia/Almaty",
		Capacity:          8,
	})
	if err != nil {
		t.Fatalf("NewExcursionScheduleSlot() error = %v", err)
	}
	return slot
}
