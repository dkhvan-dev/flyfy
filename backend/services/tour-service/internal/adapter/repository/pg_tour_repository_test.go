package repository

import (
	"context"
	"encoding/json"
	"fmt"
	"regexp"
	"strconv"
	"strings"
	"testing"

	"github.com/dkhvan-dev/flyfy/backend/services/tour-service/internal/domain/enum"
	"github.com/dkhvan-dev/flyfy/backend/services/tour-service/internal/domain/model"
	"github.com/dkhvan-dev/flyfy/backend/services/tour-service/internal/domain/port"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
)

func TestUpdateTourUsesContiguousPlaceholders(t *testing.T) {
	item, err := model.NewTour(model.NewTourParams{
		GuideProfileID:  uuid.New(),
		GuideUserID:     uuid.New(),
		Title:           "Almaty Mountain Escape",
		Summary:         "Private mountain route",
		Description:     "A guided route through the most scenic mountain stops around Almaty.",
		CategorySlug:    "nature",
		Visibility:      enum.TourVisibilityPublic,
		DurationMinutes: 240,
		MaxGroupSize:    8,
		MeetingPoint:    "Hotel pickup",
		PriceAmount:     120,
		Currency:        "USD",
	})
	if err != nil {
		t.Fatalf("NewTour() error = %v", err)
	}

	err = updateTour(context.Background(), placeholderCheckingExecutor{}, item)
	if err != nil {
		t.Fatalf("updateTour() error = %v", err)
	}
}

func TestTourMarketplaceCanonicalKeyPrefersLandmarkID(t *testing.T) {
	landmarkID := uuid.New()
	item := validRepositoryTour(t)
	item.LandmarkID = &landmarkID
	item.CountryCode = stringPtr("KZ")
	item.CityName = stringPtr("Almaty")
	item.CategorySlug = "nature"
	item.Title = "Almaty Mountain Escape"

	got := tourMarketplaceCanonicalKey(item)
	want := "landmark:" + landmarkID.String()

	if got != want {
		t.Fatalf("canonical key = %q, want %q", got, want)
	}
}

func TestTourMarketplaceCanonicalKeyNormalizesCustomRoute(t *testing.T) {
	item := validRepositoryTour(t)
	item.LandmarkID = nil
	item.CountryCode = stringPtr(" kz ")
	item.CityName = stringPtr(" Almaty ")
	item.CategorySlug = " Nature Tours "
	item.Title = "  Almaty   Mountain -- Escape! "

	got := tourMarketplaceCanonicalKey(item)
	want := "custom:kz:almaty:nature-tours:almaty-mountain-escape"

	if got != want {
		t.Fatalf("canonical key = %q, want %q", got, want)
	}
}

func TestSyncTourMarketplaceUsesContiguousPlaceholders(t *testing.T) {
	item := validRepositoryTour(t)
	coverFileID := uuid.New()

	err := syncTourMarketplace(
		context.Background(),
		&marketplacePlaceholderExecutor{queryRows: []uuid.UUID{uuid.New(), uuid.New()}},
		item,
		port.TourRelations{
			LanguageCodes: []string{"en", "ru"},
			IncludedItems: []model.TourIncludedItem{
				model.NewTourIncludedItem("Transport", nil),
				model.NewTourIncludedItem("Tickets", nil),
			},
			CoverFileID: &coverFileID,
		},
	)
	if err != nil {
		t.Fatalf("syncTourMarketplace() error = %v", err)
	}
}

func TestSyncTourMarketplaceKeepsSharedCardAndOfferAttractionBased(t *testing.T) {
	item := validRepositoryTour(t)
	landmarkName := "Medeu"
	item.LandmarkName = &landmarkName
	item.Title = "Aruzhan's sunrise Medeu walk"
	item.Summary = "My private sunrise route"
	item.Description = "My author description with my exact selling points."

	exec := &marketplaceRecordingExecutor{
		queryRows: []uuid.UUID{uuid.New(), uuid.New()},
	}
	err := syncTourMarketplace(
		context.Background(),
		exec,
		item,
		port.TourRelations{
			LanguageCodes: []string{"en"},
			IncludedItems: []model.TourIncludedItem{
				model.NewTourIncludedItem("Transport", nil),
			},
		},
	)
	if err != nil {
		t.Fatalf("syncTourMarketplace() error = %v", err)
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

func TestSyncTourMarketplaceUsesProductCoverForSharedCardAndOfferCoverForGuide(t *testing.T) {
	item := validRepositoryTour(t)
	landmarkID := uuid.New()
	landmarkName := "Medeu"
	item.LandmarkID = &landmarkID
	item.LandmarkName = &landmarkName
	productCoverFileID := uuid.New()
	offerCoverFileID := uuid.New()

	exec := &marketplaceRecordingExecutor{
		queryRows: []uuid.UUID{uuid.New(), uuid.New()},
	}
	err := syncTourMarketplace(
		context.Background(),
		exec,
		item,
		port.TourRelations{
			LanguageCodes:      []string{"en"},
			ProductCoverFileID: &productCoverFileID,
			CoverFileID:        &offerCoverFileID,
		},
	)
	if err != nil {
		t.Fatalf("syncTourMarketplace() error = %v", err)
	}
	if len(exec.queryRowArgs) != 2 {
		t.Fatalf("QueryRow calls = %d, want 2", len(exec.queryRowArgs))
	}

	productArgs := exec.queryRowArgs[0]
	if got, ok := productArgs[16].(*uuid.UUID); !ok || got == nil || *got != productCoverFileID {
		t.Fatalf("product cover arg = %#v, want product cover %s", productArgs[16], productCoverFileID)
	}

	offerArgs := exec.queryRowArgs[1]
	if got, ok := offerArgs[23].(*uuid.UUID); !ok || got == nil || *got != offerCoverFileID {
		t.Fatalf("offer cover arg = %#v, want offer cover %s", offerArgs[23], offerCoverFileID)
	}
}

func TestSyncTourMarketplacePersistsPreparedTranslations(t *testing.T) {
	item := validRepositoryTour(t)
	item.Translations = model.TourTranslations{
		"kk": {
			Title:       "Шарын бойынша авторлық бағыт",
			Summary:     "Гидпен бағыт",
			Description: "Шарын шатқалы бойынша гидтің толық сипаттамасы.",
		},
	}
	item.ProductTranslations = model.TourTranslations{
		"kk": {
			Title:       "Шарын шатқалы",
			Summary:     "Шарын шатқалы бойынша гид ұсыныстарын салыстырыңыз.",
			Description: "Гидті, тілді, бағаны және кездесу орнын таңдаңыз.",
		},
	}

	exec := &marketplaceRecordingExecutor{
		queryRows: []uuid.UUID{uuid.New(), uuid.New()},
	}
	if err := syncTourMarketplace(context.Background(), exec, item, port.TourRelations{}); err != nil {
		t.Fatalf("syncTourMarketplace() error = %v", err)
	}
	if len(exec.queryRowArgs) != 2 {
		t.Fatalf("QueryRow calls = %d, want 2", len(exec.queryRowArgs))
	}

	productTranslations := decodeTranslationsArg(t, exec.queryRowArgs[0][19])
	if got := productTranslations["kk"].Title; got != "Шарын шатқалы" {
		t.Fatalf("product kk title = %q", got)
	}

	offerTranslations := decodeTranslationsArg(t, exec.queryRowArgs[1][29])
	if len(offerTranslations) != 0 {
		t.Fatalf("offer translations = %#v, want empty because guide copy is no longer part of offers", offerTranslations)
	}
}

func TestTourOfferOrderBySupportsRatingExperienceAndPriceDirections(t *testing.T) {
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
			got := tourOfferOrderBy(tc.sort, tc.direction)
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
			columnSmartSearchTarget("tour_products.title"),
			templatedSmartSearchTarget(`EXISTS (
				SELECT 1
				FROM tour_offers o_search
				WHERE o_search.product_id = tour_products.id
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
	if !strings.Contains(query, "tour_products.title") || !strings.Contains(query, "tour_offers") {
		t.Fatalf("query = %q, want product and related offer search targets", query)
	}
	if !containsArgument(args, "%чар%") || !containsArgument(args, "%каньон%") {
		t.Fatalf("args = %#v, want cyrillic transliteration needles", args)
	}
}

func TestTourOfferSmartSearchTargetsIncludeGuideSnapshot(t *testing.T) {
	parts := []string{"SELECT 1 FROM tour_offers WHERE TRUE"}
	args := make([]any, 0)
	argPos := appendSmartSearchCondition(
		&parts,
		&args,
		1,
		"aruzhan",
		tourOfferSmartSearchTargets(),
	)

	query := strings.Join(parts, "")
	if argPos != len(args)+1 {
		t.Fatalf("next arg position = %d, args = %d", argPos, len(args))
	}
	if err := validateContiguousPlaceholders(query, len(args)); err != nil {
		t.Fatalf("placeholders are not contiguous: %v\nquery:\n%s", err, query)
	}
	if !strings.Contains(query, "tour_offers.guide_display_name") {
		t.Fatalf("query = %q, want guide display name snapshot target", query)
	}
	if !strings.Contains(query, "tour_offers.guide_search_text") {
		t.Fatalf("query = %q, want guide search text snapshot target", query)
	}
}

func TestMarketplaceProductCopyPreservesCustomRouteCopyWithoutLandmark(t *testing.T) {
	item := validRepositoryTour(t)
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
	item := validRepositoryTour(t)
	item.Status = enum.TourStatusPublished
	item.Visibility = enum.TourVisibilityUnlisted

	got := marketplaceProductStatus(item)

	if got != string(enum.TourStatusDraft) {
		t.Fatalf("marketplace product status = %q, want %q", got, enum.TourStatusDraft)
	}
}

func decodeTranslationsArg(t *testing.T, arg any) model.TourTranslations {
	t.Helper()
	raw, ok := arg.(string)
	if !ok {
		t.Fatalf("translations arg type = %T, want string", arg)
	}
	var translations model.TourTranslations
	if err := json.Unmarshal([]byte(raw), &translations); err != nil {
		t.Fatalf("decode translations: %v", err)
	}
	return translations
}

func validRepositoryTour(t *testing.T) *model.Tour {
	t.Helper()
	item, err := model.NewTour(model.NewTourParams{
		GuideProfileID:  uuid.New(),
		GuideUserID:     uuid.New(),
		Title:           "Almaty Mountain Escape",
		Summary:         "Private mountain route",
		Description:     "A guided route through the most scenic mountain stops around Almaty.",
		CategorySlug:    "nature",
		Visibility:      enum.TourVisibilityPublic,
		DurationMinutes: 240,
		MaxGroupSize:    8,
		MeetingPoint:    "Hotel pickup",
		PriceAmount:     120,
		Currency:        "USD",
	})
	if err != nil {
		t.Fatalf("NewTour() error = %v", err)
	}
	return item
}

func stringPtr(value string) *string {
	return &value
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
