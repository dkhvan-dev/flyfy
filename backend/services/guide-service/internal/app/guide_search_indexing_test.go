package app

import (
	"context"
	"testing"

	"github.com/google/uuid"

	"kz/inflap/backend/services/guide-service/internal/domain/enum"
	"kz/inflap/backend/services/guide-service/internal/domain/model"
	"kz/inflap/backend/services/guide-service/internal/domain/port"
)

func TestUpdateActiveGuideProfileIndexesSearchDocument(t *testing.T) {
	t.Parallel()

	profile := activeGuideProfile(t)
	indexer := &guideSearchIndexerStub{}
	repo := &guideSearchRepoStub{profile: profile}
	userClient := &guideSearchUserClientStub{
		profile: &PublicUserProfile{
			UserID:      profile.UserID,
			FirstName:   stringPtr("Aruzhan"),
			LastName:    stringPtr("Sapar"),
			Nickname:    stringPtr("aru-guide"),
			CountryCode: stringPtr("KZ"),
			Locale:      "en",
		},
	}
	uc := NewGuideUseCase(repo, userClient, nil)
	uc.SetSearchIndexer(indexer)

	headline := "Mountain and city guide"
	about := "Local guide for Almaty mountains and culture walks."
	experienceYears := 6
	available := true
	aggregate, err := uc.UpdateGuideProfile(context.Background(), UpdateGuideProfileInput{
		ProfileID:                 profile.ID,
		Headline:                  &headline,
		About:                     &about,
		ExperienceYears:           &experienceYears,
		IsPrivateGuideAvailable:   &available,
		IsExcursionGuideAvailable: &available,
		Languages: []GuideLanguageInput{
			{LanguageCode: "en", ProficiencyLevel: "advanced"},
			{LanguageCode: "ru", ProficiencyLevel: "native"},
		},
		Specializations: []GuideSpecializationInput{
			{SpecializationCode: "mountains"},
			{SpecializationCode: "culture"},
		},
	})
	if err != nil {
		t.Fatalf("UpdateGuideProfile() error = %v", err)
	}

	if len(indexer.upserts) != 1 {
		t.Fatalf("search upserts = %d, want 1", len(indexer.upserts))
	}
	if len(indexer.deletes) != 0 {
		t.Fatalf("search deletes = %d, want 0", len(indexer.deletes))
	}

	doc := indexer.upserts[0]
	if doc.Domain != "guide" || doc.EntityID != aggregate.Profile.ID.String() {
		t.Fatalf("domain/entity = %q/%q, want guide/%s", doc.Domain, doc.EntityID, aggregate.Profile.ID)
	}
	if doc.Title["en"] != "Aruzhan Sapar" {
		t.Fatalf("title = %#v", doc.Title)
	}
	if doc.DeepLink != "/guides/"+aggregate.Profile.UserID.String() {
		t.Fatalf("deep link = %q", doc.DeepLink)
	}
	if doc.CountryCode != "KZ" {
		t.Fatalf("country = %q, want KZ", doc.CountryCode)
	}
	if doc.Rating == nil || *doc.Rating != 4.9 || doc.ReviewCount != 42 {
		t.Fatalf("rating/reviews = %#v/%d", doc.Rating, doc.ReviewCount)
	}
	if !containsString(doc.Tags, "en") || !containsString(doc.Tags, "ru") ||
		!containsString(doc.CategoryCodes, "mountains") ||
		!containsString(doc.CategoryCodes, "culture") {
		t.Fatalf("tags/categories = %#v/%#v", doc.Tags, doc.CategoryCodes)
	}
	if doc.Visibility != "public" || doc.ModerationStatus != "approved" {
		t.Fatalf("visibility/moderation = %q/%q", doc.Visibility, doc.ModerationStatus)
	}
	if doc.SearchTextNormalized == "" {
		t.Fatal("search text normalized is empty")
	}
}

func TestUpdateDraftGuideProfileDeletesSearchDocument(t *testing.T) {
	t.Parallel()

	profile := activeGuideProfile(t)
	profile.Status = enum.GuideStatusDraft
	indexer := &guideSearchIndexerStub{}
	uc := NewGuideUseCase(&guideSearchRepoStub{profile: profile}, &guideSearchUserClientStub{}, nil)
	uc.SetSearchIndexer(indexer)

	headline := "Hidden draft guide"
	_, err := uc.UpdateGuideProfile(context.Background(), UpdateGuideProfileInput{
		ProfileID: profile.ID,
		Headline:  &headline,
	})
	if err != nil {
		t.Fatalf("UpdateGuideProfile() error = %v", err)
	}

	if len(indexer.upserts) != 0 {
		t.Fatalf("search upserts = %d, want 0", len(indexer.upserts))
	}
	if len(indexer.deletes) != 1 {
		t.Fatalf("search deletes = %d, want 1", len(indexer.deletes))
	}
	if indexer.deletes[0].Domain != "guide" || indexer.deletes[0].EntityID != profile.ID.String() {
		t.Fatalf("delete request = %#v", indexer.deletes[0])
	}
}

func TestBackfillGuideSearchIndexReconcilesDocuments(t *testing.T) {
	t.Parallel()

	activeProfile := activeGuideProfile(t)
	draftProfile := activeGuideProfile(t)
	draftProfile.Status = enum.GuideStatusDraft

	repo := &guideSearchRepoStub{
		profiles: [][]*model.GuideProfile{
			{activeProfile},
			{draftProfile},
		},
		languagesByProfileID: map[uuid.UUID][]*model.GuideLanguage{
			activeProfile.ID: {
				{ID: uuid.New(), GuideProfileID: activeProfile.ID, LanguageCode: "en"},
				{ID: uuid.New(), GuideProfileID: activeProfile.ID, LanguageCode: "ru"},
			},
		},
		specializationsByProfileID: map[uuid.UUID][]*model.GuideSpecialization{
			activeProfile.ID: {
				{ID: uuid.New(), GuideProfileID: activeProfile.ID, SpecializationCode: "mountains"},
			},
		},
	}
	userClient := &guideSearchUserClientStub{
		profiles: map[uuid.UUID]PublicUserProfile{
			activeProfile.UserID: {
				UserID:      activeProfile.UserID,
				FirstName:   stringPtr("Aruzhan"),
				LastName:    stringPtr("Sapar"),
				Nickname:    stringPtr("aru-guide"),
				CountryCode: stringPtr("KZ"),
				Locale:      "en",
			},
		},
	}
	indexer := &guideSearchIndexerStub{}

	stats, err := BackfillGuideSearchIndex(context.Background(), repo, userClient, indexer, SearchIndexBackfillOptions{
		BatchSize:   1,
		DeleteStale: true,
	})
	if err != nil {
		t.Fatalf("BackfillGuideSearchIndex() error = %v", err)
	}

	if stats.Scanned != 2 || stats.Upserted != 1 || stats.Deleted != 1 || stats.Skipped != 0 {
		t.Fatalf("stats = %#v", stats)
	}
	if len(indexer.upserts) != 1 {
		t.Fatalf("upserts = %d, want 1", len(indexer.upserts))
	}
	if indexer.upserts[0].EntityID != activeProfile.ID.String() {
		t.Fatalf("upsert entity = %s, want %s", indexer.upserts[0].EntityID, activeProfile.ID)
	}
	if indexer.upserts[0].Title["en"] != "Aruzhan Sapar" {
		t.Fatalf("upsert title = %#v", indexer.upserts[0].Title)
	}
	if !containsString(indexer.upserts[0].Tags, "en") || !containsString(indexer.upserts[0].CategoryCodes, "mountains") {
		t.Fatalf("upsert tags/categories = %#v/%#v", indexer.upserts[0].Tags, indexer.upserts[0].CategoryCodes)
	}
	if len(indexer.deletes) != 1 {
		t.Fatalf("deletes = %d, want 1", len(indexer.deletes))
	}
	if indexer.deletes[0].EntityID != draftProfile.ID.String() {
		t.Fatalf("delete entity = %s, want %s", indexer.deletes[0].EntityID, draftProfile.ID)
	}
}

type guideSearchIndexerStub struct {
	upserts []SearchIndexDocument
	deletes []SearchIndexDelete
}

func (s *guideSearchIndexerStub) UpsertSearchDocument(_ context.Context, document SearchIndexDocument) error {
	s.upserts = append(s.upserts, document)
	return nil
}

func (s *guideSearchIndexerStub) DeleteSearchDocument(_ context.Context, deletion SearchIndexDelete) error {
	s.deletes = append(s.deletes, deletion)
	return nil
}

type guideSearchRepoStub struct {
	profile                    *model.GuideProfile
	profiles                   [][]*model.GuideProfile
	languages                  []*model.GuideLanguage
	languagesByProfileID       map[uuid.UUID][]*model.GuideLanguage
	specializations            []*model.GuideSpecialization
	specializationsByProfileID map[uuid.UUID][]*model.GuideSpecialization
	listBackfillCalls          int
}

func (s *guideSearchRepoStub) CreateGuideProfile(context.Context, *model.GuideProfile) error {
	return nil
}

func (s *guideSearchRepoStub) GetGuideProfileByID(context.Context, uuid.UUID) (*model.GuideProfile, error) {
	return s.profile, nil
}

func (s *guideSearchRepoStub) GetGuideProfileByUserID(context.Context, uuid.UUID) (*model.GuideProfile, error) {
	return s.profile, nil
}

func (s *guideSearchRepoStub) UpdateGuideProfile(_ context.Context, profile *model.GuideProfile) error {
	s.profile = profile
	return nil
}

func (s *guideSearchRepoStub) UpdateGuideRatingSnapshot(context.Context, uuid.UUID, float64, int) error {
	return nil
}

func (s *guideSearchRepoStub) CreateVerificationRequest(context.Context, *model.GuideVerificationRequest) error {
	return nil
}

func (s *guideSearchRepoStub) GetVerificationRequestByID(context.Context, uuid.UUID) (*model.GuideVerificationRequest, error) {
	return nil, nil
}

func (s *guideSearchRepoStub) GetLatestVerificationRequestByGuideProfileID(context.Context, uuid.UUID) (*model.GuideVerificationRequest, error) {
	return nil, nil
}

func (s *guideSearchRepoStub) UpdateVerificationRequest(context.Context, *model.GuideVerificationRequest) error {
	return nil
}

func (s *guideSearchRepoStub) AddGuideDocument(context.Context, *model.GuideDocument) error {
	return nil
}

func (s *guideSearchRepoStub) ListGuideDocumentsByVerificationRequestID(context.Context, uuid.UUID) ([]*model.GuideDocument, error) {
	return nil, nil
}

func (s *guideSearchRepoStub) AddGuideLanguage(context.Context, *model.GuideLanguage) error {
	return nil
}

func (s *guideSearchRepoStub) ReplaceGuideLanguages(_ context.Context, _ uuid.UUID, items []*model.GuideLanguage) error {
	s.languages = items
	return nil
}

func (s *guideSearchRepoStub) ListGuideLanguages(context.Context, uuid.UUID) ([]*model.GuideLanguage, error) {
	return s.languages, nil
}

func (s *guideSearchRepoStub) ListGuideLanguagesByProfileIDs(context.Context, []uuid.UUID) (map[uuid.UUID][]*model.GuideLanguage, error) {
	if s.languagesByProfileID != nil {
		return s.languagesByProfileID, nil
	}
	return map[uuid.UUID][]*model.GuideLanguage{s.profile.ID: s.languages}, nil
}

func (s *guideSearchRepoStub) AddGuideSpecialization(context.Context, *model.GuideSpecialization) error {
	return nil
}

func (s *guideSearchRepoStub) ReplaceGuideSpecializations(_ context.Context, _ uuid.UUID, items []*model.GuideSpecialization) error {
	s.specializations = items
	return nil
}

func (s *guideSearchRepoStub) ListGuideSpecializations(context.Context, uuid.UUID) ([]*model.GuideSpecialization, error) {
	return s.specializations, nil
}

func (s *guideSearchRepoStub) ListGuideSpecializationsByProfileIDs(context.Context, []uuid.UUID) (map[uuid.UUID][]*model.GuideSpecialization, error) {
	if s.specializationsByProfileID != nil {
		return s.specializationsByProfileID, nil
	}
	return map[uuid.UUID][]*model.GuideSpecialization{s.profile.ID: s.specializations}, nil
}

func (s *guideSearchRepoStub) ListGuideProfilesForSearchIndexBackfill(context.Context, int, int) ([]*model.GuideProfile, error) {
	index := s.listBackfillCalls
	s.listBackfillCalls++
	if index >= len(s.profiles) {
		return []*model.GuideProfile{}, nil
	}
	return s.profiles[index], nil
}

func (s *guideSearchRepoStub) ListPublicGuideProfiles(context.Context, port.PublicGuideListFilter) (port.PublicGuideListResult, error) {
	return port.PublicGuideListResult{}, nil
}

func (s *guideSearchRepoStub) ListPublicGuideFilterOptions(context.Context) (port.PublicGuideFilterOptions, error) {
	return port.PublicGuideFilterOptions{}, nil
}

func (s *guideSearchRepoStub) ListVerificationRequestsByStatuses(context.Context, []enum.VerificationRequestStatus, int, int) ([]*model.GuideVerificationRequest, error) {
	return nil, nil
}

type guideSearchUserClientStub struct {
	profile  *PublicUserProfile
	profiles map[uuid.UUID]PublicUserProfile
}

func (s *guideSearchUserClientStub) ValidateUserExists(context.Context, uuid.UUID) error {
	return nil
}

func (s *guideSearchUserClientStub) ResolveUserIDBySubject(context.Context, string) (uuid.UUID, error) {
	return uuid.Nil, nil
}

func (s *guideSearchUserClientStub) GetUserProfile(context.Context, uuid.UUID) (*PublicUserProfile, error) {
	return s.profile, nil
}

func (s *guideSearchUserClientStub) GetPublicUserProfiles(context.Context, []uuid.UUID) (map[uuid.UUID]PublicUserProfile, error) {
	if s.profiles != nil {
		return s.profiles, nil
	}
	if s.profile == nil {
		return map[uuid.UUID]PublicUserProfile{}, nil
	}
	return map[uuid.UUID]PublicUserProfile{s.profile.UserID: *s.profile}, nil
}

func (s *guideSearchUserClientStub) ListPublicUserIDsByCountryCodes(context.Context, []string) ([]uuid.UUID, error) {
	return nil, nil
}

func (s *guideSearchUserClientStub) GrantGuideRole(context.Context, uuid.UUID, *uuid.UUID) error {
	return nil
}

func (s *guideSearchUserClientStub) RevokeGuideRole(context.Context, uuid.UUID) error {
	return nil
}

func activeGuideProfile(t *testing.T) *model.GuideProfile {
	t.Helper()
	profile, err := model.NewGuideProfile(model.NewGuideProfileParams{
		UserID: uuid.New(),
		Type:   enum.GuideTypeIndependent,
	})
	if err != nil {
		t.Fatalf("NewGuideProfile() error = %v", err)
	}
	profile.Status = enum.GuideStatusActive
	profile.RatingAvg = 4.9
	profile.ReviewsCount = 42
	return profile
}

func stringPtr(value string) *string {
	return &value
}

func containsString(items []string, needle string) bool {
	for _, item := range items {
		if item == needle {
			return true
		}
	}
	return false
}
