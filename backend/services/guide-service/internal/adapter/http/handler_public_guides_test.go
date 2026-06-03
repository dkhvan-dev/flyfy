package http

import (
	"context"
	"encoding/json"
	nethttp "net/http"
	"net/http/httptest"
	"reflect"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/guide-service/internal/app"
	"kz/inflap/backend/services/guide-service/internal/domain/enum"
	"kz/inflap/backend/services/guide-service/internal/domain/model"
	"kz/inflap/backend/services/guide-service/internal/domain/port"
)

func TestListPublicGuidesAppliesSearchFilterSortAndReturnsTotal(t *testing.T) {
	t.Parallel()

	profileID := uuid.MustParse("11111111-1111-1111-1111-111111111111")
	userID := uuid.MustParse("22222222-2222-2222-2222-222222222222")
	now := time.Date(2026, 5, 11, 9, 30, 0, 0, time.UTC)
	headline := "Almaty mountain guide"
	about := "Trail, city, and cultural routes"
	displayName := "Aruzhan Guide"
	firstName := "Aruzhan"
	lastName := "Tulegenova"

	repo := &publicGuideRepositoryStub{
		result: port.PublicGuideListResult{
			Items: []*model.GuideProfile{
				{
					ID:                        profileID,
					UserID:                    userID,
					Type:                      enum.GuideTypeIndependent,
					Status:                    enum.GuideStatusActive,
					Headline:                  &headline,
					About:                     &about,
					ExperienceYears:           8,
					IsPrivateGuideAvailable:   true,
					IsActivityHostAvailable:   true,
					IsExcursionGuideAvailable: true,
					RatingAvg:                 4.85,
					ReviewsCount:              42,
					CreatedAt:                 now,
					UpdatedAt:                 now,
				},
			},
			Total: 31,
		},
		languages: map[uuid.UUID][]*model.GuideLanguage{
			profileID: {
				{
					ID:               uuid.MustParse("33333333-3333-3333-3333-333333333333"),
					GuideProfileID:   profileID,
					LanguageCode:     "en",
					ProficiencyLevel: "ADVANCED",
					CreatedAt:        now,
				},
			},
		},
		specializations: map[uuid.UUID][]*model.GuideSpecialization{
			profileID: {
				{
					ID:                 uuid.MustParse("44444444-4444-4444-4444-444444444444"),
					GuideProfileID:     profileID,
					SpecializationCode: "mountain_guide",
					CreatedAt:          now,
				},
			},
		},
	}
	excursionCoverage := &publicGuideExcursionCoverageClientStub{
		guideUserIDs: []uuid.UUID{userID},
	}
	handler := NewHandler(app.NewGuideUseCase(
		repo,
		&publicUserClientStub{
			profiles: map[uuid.UUID]app.PublicUserProfile{
				userID: {
					UserID:      userID,
					FirstName:   &firstName,
					LastName:    &lastName,
					DisplayName: &displayName,
					Locale:      "en",
					Timezone:    "Asia/Almaty",
				},
			},
		},
		nil,
		excursionCoverage,
	))

	req := httptest.NewRequest(
		nethttp.MethodGet,
		"/v1/guides/public?limit=8&offset=16&q=almaty&sort=experience_desc&minRating=4.5&minExperienceYears=3&cityId=almaty&cityName=Алматы&cityCountryCode=KZ&countries=KZ,GE&languages=en,ru&specializations=mountain_guide,city_historian",
		nil,
	)
	rec := httptest.NewRecorder()

	handler.ListPublicGuides(rec, req)

	if rec.Code != nethttp.StatusOK {
		t.Fatalf("expected status %d, got %d: %s", nethttp.StatusOK, rec.Code, rec.Body.String())
	}

	if repo.lastFilter.Query != "almaty" {
		t.Fatalf("expected query almaty, got %q", repo.lastFilter.Query)
	}
	if repo.lastFilter.Sort != port.PublicGuideSortExperienceDesc {
		t.Fatalf("expected sort %q, got %q", port.PublicGuideSortExperienceDesc, repo.lastFilter.Sort)
	}
	if repo.lastFilter.Limit != 8 || repo.lastFilter.Offset != 16 {
		t.Fatalf("expected limit/offset 8/16, got %d/%d", repo.lastFilter.Limit, repo.lastFilter.Offset)
	}
	if repo.lastFilter.MinRating == nil || *repo.lastFilter.MinRating != 4.5 {
		t.Fatalf("expected min rating 4.5, got %#v", repo.lastFilter.MinRating)
	}
	if repo.lastFilter.MinExperienceYears == nil || *repo.lastFilter.MinExperienceYears != 3 {
		t.Fatalf("expected min experience 3, got %#v", repo.lastFilter.MinExperienceYears)
	}
	if !reflect.DeepEqual(repo.lastFilter.CountryCodes, []string{"kz", "ge"}) {
		t.Fatalf("unexpected countries: %#v", repo.lastFilter.CountryCodes)
	}
	if !reflect.DeepEqual(repo.lastFilter.UserIDs, []uuid.UUID{userID}) {
		t.Fatalf("unexpected city guide user ids: %#v", repo.lastFilter.UserIDs)
	}
	if excursionCoverage.lastInput.CityID != "almaty" {
		t.Fatalf("expected excursion city id almaty, got %q", excursionCoverage.lastInput.CityID)
	}
	if excursionCoverage.lastInput.CityName != "Алматы" || excursionCoverage.lastInput.CountryCode != "KZ" {
		t.Fatalf("unexpected excursion city input: %#v", excursionCoverage.lastInput)
	}
	if !reflect.DeepEqual(repo.lastFilter.LanguageCodes, []string{"en", "ru"}) {
		t.Fatalf("unexpected languages: %#v", repo.lastFilter.LanguageCodes)
	}
	if !reflect.DeepEqual(repo.lastFilter.SpecializationCodes, []string{"mountain_guide", "city_historian"}) {
		t.Fatalf("unexpected specializations: %#v", repo.lastFilter.SpecializationCodes)
	}

	var payload struct {
		Items []struct {
			GuideProfile struct {
				ID              string  `json:"id"`
				Headline        *string `json:"headline"`
				ExperienceYears int     `json:"experienceYears"`
			} `json:"guideProfile"`
			UserProfile *struct {
				UserID      string  `json:"userId"`
				FirstName   *string `json:"firstName"`
				LastName    *string `json:"lastName"`
				DisplayName *string `json:"displayName"`
			} `json:"userProfile"`
			Languages []struct {
				LanguageCode string `json:"languageCode"`
			} `json:"languages"`
			Specializations []struct {
				SpecializationCode string `json:"specializationCode"`
			} `json:"specializations"`
		} `json:"items"`
		Total  int `json:"total"`
		Limit  int `json:"limit"`
		Offset int `json:"offset"`
	}
	if err := json.NewDecoder(rec.Body).Decode(&payload); err != nil {
		t.Fatalf("decode response: %v", err)
	}

	if payload.Total != 31 || payload.Limit != 8 || payload.Offset != 16 {
		t.Fatalf("unexpected pagination metadata: total=%d limit=%d offset=%d", payload.Total, payload.Limit, payload.Offset)
	}
	if len(payload.Items) != 1 {
		t.Fatalf("expected 1 item, got %d", len(payload.Items))
	}
	if payload.Items[0].GuideProfile.ID != profileID.String() {
		t.Fatalf("unexpected guide id: %s", payload.Items[0].GuideProfile.ID)
	}
	if payload.Items[0].UserProfile == nil || payload.Items[0].UserProfile.DisplayName == nil ||
		*payload.Items[0].UserProfile.DisplayName != displayName {
		t.Fatalf("expected public user profile, got %#v", payload.Items[0].UserProfile)
	}
	if payload.Items[0].UserProfile.FirstName == nil ||
		*payload.Items[0].UserProfile.FirstName != firstName ||
		payload.Items[0].UserProfile.LastName == nil ||
		*payload.Items[0].UserProfile.LastName != lastName {
		t.Fatalf("expected public first and last name, got %#v", payload.Items[0].UserProfile)
	}
	if len(payload.Items[0].Languages) != 1 || payload.Items[0].Languages[0].LanguageCode != "en" {
		t.Fatalf("expected language metadata, got %#v", payload.Items[0].Languages)
	}
	if len(payload.Items[0].Specializations) != 1 ||
		payload.Items[0].Specializations[0].SpecializationCode != "mountain_guide" {
		t.Fatalf("expected specialization metadata, got %#v", payload.Items[0].Specializations)
	}
}

func TestListPublicGuidesReturnsEmptyWhenCityHasNoExcursionGuides(t *testing.T) {
	t.Parallel()

	repo := &publicGuideRepositoryStub{}
	handler := NewHandler(app.NewGuideUseCase(
		repo,
		&publicUserClientStub{},
		nil,
		&publicGuideExcursionCoverageClientStub{
			guideUserIDs: []uuid.UUID{},
		},
	))

	req := httptest.NewRequest(
		nethttp.MethodGet,
		"/v1/guides/public?cityId=bangkok&cityName=Бангкок&cityCountryCode=TH",
		nil,
	)
	rec := httptest.NewRecorder()

	handler.ListPublicGuides(rec, req)

	if rec.Code != nethttp.StatusOK {
		t.Fatalf("expected status %d, got %d: %s", nethttp.StatusOK, rec.Code, rec.Body.String())
	}
	if repo.listPublicCalls != 0 {
		t.Fatalf("repository should not be queried when excursion city coverage is empty")
	}

	var payload struct {
		Items []any `json:"items"`
		Total int   `json:"total"`
	}
	if err := json.NewDecoder(rec.Body).Decode(&payload); err != nil {
		t.Fatalf("decode response: %v", err)
	}
	if len(payload.Items) != 0 || payload.Total != 0 {
		t.Fatalf("unexpected payload: %+v", payload)
	}
}

func TestListActiveGuidesForAdminReturnsReadableGuideItems(t *testing.T) {
	t.Parallel()

	profileID := uuid.MustParse("11111111-1111-1111-1111-111111111111")
	userID := uuid.MustParse("22222222-2222-2222-2222-222222222222")
	now := time.Date(2026, 5, 25, 9, 30, 0, 0, time.UTC)
	headline := "Almaty mountain guide"
	displayName := "Aruzhan Guide"
	firstName := "Aruzhan"
	lastName := "Tulegenova"
	repo := &publicGuideRepositoryStub{
		result: port.PublicGuideListResult{
			Items: []*model.GuideProfile{
				{
					ID:                        profileID,
					UserID:                    userID,
					Type:                      enum.GuideTypeIndependent,
					Status:                    enum.GuideStatusActive,
					Headline:                  &headline,
					ExperienceYears:           8,
					IsExcursionGuideAvailable: true,
					RatingAvg:                 4.85,
					ReviewsCount:              42,
					CreatedAt:                 now,
					UpdatedAt:                 now,
				},
			},
			Total: 1,
		},
	}
	handler := NewHandler(app.NewGuideUseCase(
		repo,
		&publicUserClientStub{
			profiles: map[uuid.UUID]app.PublicUserProfile{
				userID: {
					UserID:      userID,
					FirstName:   &firstName,
					LastName:    &lastName,
					DisplayName: &displayName,
					Locale:      "ru",
					Timezone:    "Asia/Almaty",
				},
			},
		},
		nil,
	))

	req := httptest.NewRequest(nethttp.MethodGet, "/v1/admin/guides/profiles?limit=50&offset=0", nil)
	req = req.WithContext(withUserRoles(req.Context(), []string{"GUIDE_MODERATOR"}))
	rec := httptest.NewRecorder()

	handler.ListActiveGuidesForAdmin(rec, req)

	if rec.Code != nethttp.StatusOK {
		t.Fatalf("expected status %d, got %d: %s", nethttp.StatusOK, rec.Code, rec.Body.String())
	}
	var payload struct {
		Items []struct {
			GuideProfileID   string `json:"guideProfileId"`
			GuideUserID      string `json:"guideUserId"`
			GuideDisplayName string `json:"guideDisplayName"`
			FirstName        string `json:"firstName"`
			LastName         string `json:"lastName"`
			GuideStatus      string `json:"guideStatus"`
			Headline         string `json:"headline"`
		} `json:"items"`
	}
	if err := json.NewDecoder(rec.Body).Decode(&payload); err != nil {
		t.Fatalf("decode response: %v", err)
	}
	if len(payload.Items) != 1 {
		t.Fatalf("items = %d, want 1", len(payload.Items))
	}
	item := payload.Items[0]
	if item.GuideProfileID != profileID.String() || item.GuideUserID != userID.String() {
		t.Fatalf("unexpected ids: %#v", item)
	}
	if item.GuideDisplayName != displayName || item.FirstName != firstName || item.LastName != lastName {
		t.Fatalf("expected readable guide identity, got %#v", item)
	}
	if item.GuideStatus != string(enum.GuideStatusActive) || item.Headline != headline {
		t.Fatalf("unexpected guide status/headline: %#v", item)
	}
}

type publicGuideRepositoryStub struct {
	result          port.PublicGuideListResult
	lastFilter      port.PublicGuideListFilter
	listPublicCalls int
	languages       map[uuid.UUID][]*model.GuideLanguage
	specializations map[uuid.UUID][]*model.GuideSpecialization
}

func (s *publicGuideRepositoryStub) CreateGuideProfile(context.Context, *model.GuideProfile) error {
	return nil
}

func (s *publicGuideRepositoryStub) GetGuideProfileByID(context.Context, uuid.UUID) (*model.GuideProfile, error) {
	return nil, nil
}

func (s *publicGuideRepositoryStub) GetGuideProfileByUserID(context.Context, uuid.UUID) (*model.GuideProfile, error) {
	return nil, nil
}

func (s *publicGuideRepositoryStub) UpdateGuideProfile(context.Context, *model.GuideProfile) error {
	return nil
}

func (s *publicGuideRepositoryStub) UpdateGuideRatingSnapshot(context.Context, uuid.UUID, float64, int) error {
	return nil
}

func (s *publicGuideRepositoryStub) CreateVerificationRequest(context.Context, *model.GuideVerificationRequest) error {
	return nil
}

func (s *publicGuideRepositoryStub) GetVerificationRequestByID(context.Context, uuid.UUID) (*model.GuideVerificationRequest, error) {
	return nil, nil
}

func (s *publicGuideRepositoryStub) GetLatestVerificationRequestByGuideProfileID(context.Context, uuid.UUID) (*model.GuideVerificationRequest, error) {
	return nil, nil
}

func (s *publicGuideRepositoryStub) UpdateVerificationRequest(context.Context, *model.GuideVerificationRequest) error {
	return nil
}

func (s *publicGuideRepositoryStub) AddGuideDocument(context.Context, *model.GuideDocument) error {
	return nil
}

func (s *publicGuideRepositoryStub) ListGuideDocumentsByVerificationRequestID(context.Context, uuid.UUID) ([]*model.GuideDocument, error) {
	return nil, nil
}

func (s *publicGuideRepositoryStub) AddGuideLanguage(context.Context, *model.GuideLanguage) error {
	return nil
}

func (s *publicGuideRepositoryStub) ReplaceGuideLanguages(context.Context, uuid.UUID, []*model.GuideLanguage) error {
	return nil
}

func (s *publicGuideRepositoryStub) ListGuideLanguages(_ context.Context, guideProfileID uuid.UUID) ([]*model.GuideLanguage, error) {
	return s.languages[guideProfileID], nil
}

func (s *publicGuideRepositoryStub) ListGuideLanguagesByProfileIDs(_ context.Context, guideProfileIDs []uuid.UUID) (map[uuid.UUID][]*model.GuideLanguage, error) {
	result := make(map[uuid.UUID][]*model.GuideLanguage, len(guideProfileIDs))
	for _, id := range guideProfileIDs {
		result[id] = s.languages[id]
	}
	return result, nil
}

func (s *publicGuideRepositoryStub) AddGuideSpecialization(context.Context, *model.GuideSpecialization) error {
	return nil
}

func (s *publicGuideRepositoryStub) ReplaceGuideSpecializations(context.Context, uuid.UUID, []*model.GuideSpecialization) error {
	return nil
}

func (s *publicGuideRepositoryStub) ListGuideSpecializations(_ context.Context, guideProfileID uuid.UUID) ([]*model.GuideSpecialization, error) {
	return s.specializations[guideProfileID], nil
}

func (s *publicGuideRepositoryStub) ListGuideSpecializationsByProfileIDs(_ context.Context, guideProfileIDs []uuid.UUID) (map[uuid.UUID][]*model.GuideSpecialization, error) {
	result := make(map[uuid.UUID][]*model.GuideSpecialization, len(guideProfileIDs))
	for _, id := range guideProfileIDs {
		result[id] = s.specializations[id]
	}
	return result, nil
}

func (s *publicGuideRepositoryStub) ListPublicGuideProfiles(_ context.Context, filter port.PublicGuideListFilter) (port.PublicGuideListResult, error) {
	s.listPublicCalls++
	s.lastFilter = filter
	return s.result, nil
}

type publicGuideExcursionCoverageClientStub struct {
	lastInput    app.GuideExcursionCityFilter
	guideUserIDs []uuid.UUID
}

func (s *publicGuideExcursionCoverageClientStub) ListGuideUserIDsByCity(
	_ context.Context,
	input app.GuideExcursionCityFilter,
) ([]uuid.UUID, error) {
	s.lastInput = input
	return s.guideUserIDs, nil
}

func (s *publicGuideExcursionCoverageClientStub) ArchiveGuideExcursionOffers(context.Context, uuid.UUID) error {
	return nil
}

func (s *publicGuideRepositoryStub) ListVerificationRequestsByStatuses(
	context.Context,
	[]enum.VerificationRequestStatus,
	int,
	int,
) ([]*model.GuideVerificationRequest, error) {
	return nil, nil
}

type publicUserClientStub struct {
	profiles map[uuid.UUID]app.PublicUserProfile
}

func (s *publicUserClientStub) ValidateUserExists(context.Context, uuid.UUID) error {
	return nil
}

func (s *publicUserClientStub) ResolveUserIDBySubject(context.Context, string) (uuid.UUID, error) {
	return uuid.Nil, nil
}

func (s *publicUserClientStub) GetUserProfile(_ context.Context, userID uuid.UUID) (*app.PublicUserProfile, error) {
	if profile, ok := s.profiles[userID]; ok {
		return &profile, nil
	}
	return nil, nil
}

func (s *publicUserClientStub) GetPublicUserProfiles(context.Context, []uuid.UUID) (map[uuid.UUID]app.PublicUserProfile, error) {
	return s.profiles, nil
}

func (s *publicUserClientStub) ListPublicUserIDsByCountryCodes(context.Context, []string) ([]uuid.UUID, error) {
	return []uuid.UUID{uuid.MustParse("22222222-2222-2222-2222-222222222222")}, nil
}

func (s *publicUserClientStub) GrantGuideRole(context.Context, uuid.UUID, *uuid.UUID) error {
	return nil
}

func (s *publicUserClientStub) RevokeGuideRole(context.Context, uuid.UUID) error {
	return nil
}
