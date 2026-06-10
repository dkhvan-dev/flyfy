package app

import (
	"context"
	"encoding/json"
	"errors"
	"strings"
	"testing"

	"github.com/google/uuid"

	"kz/inflap/backend/services/stories-service/internal/domain/enum"
	"kz/inflap/backend/services/stories-service/internal/domain/model"
	"kz/inflap/backend/services/stories-service/internal/domain/port"
)

func TestSanitizeTagsReturnsEmptySliceForEmptyInput(t *testing.T) {
	tags, err := sanitizeTags(nil)
	if err != nil {
		t.Fatalf("sanitizeTags returned error: %v", err)
	}
	if tags == nil {
		t.Fatal("sanitizeTags returned nil slice for empty input")
	}
	if len(tags) != 0 {
		t.Fatalf("sanitizeTags returned %d tags, want 0", len(tags))
	}
}

func TestNormalizePlaceFiltersUsesCountryCodeWhenPlaceLooksLikeISOCode(t *testing.T) {
	query, countryCode := normalizePlaceFilters(" kz ")

	if query != "" {
		t.Fatalf("normalizePlaceFilters query = %q, want empty", query)
	}
	if countryCode != "KZ" {
		t.Fatalf("normalizePlaceFilters countryCode = %q, want KZ", countryCode)
	}
}

func TestNormalizePlaceFiltersKeepsLocalizedCountryNameAsTextQuery(t *testing.T) {
	query, countryCode := normalizePlaceFilters("Казахстан")

	if query != "Казахстан" {
		t.Fatalf("normalizePlaceFilters query = %q, want localized country name", query)
	}
	if countryCode != "" {
		t.Fatalf("normalizePlaceFilters countryCode = %q, want empty", countryCode)
	}
}

func TestNormalizeListInputMapsSelectedCountryToCountryCodeFilter(t *testing.T) {
	viewerID := uuid.New()
	filter, err := (&StoryUseCase{}).normalizeListInput(
		ListStoriesInput{Place: "KZ"},
		&viewerID,
	)
	if err != nil {
		t.Fatalf("normalizeListInput returned error: %v", err)
	}

	if filter.PlaceCountryCode != "KZ" {
		t.Fatalf("filter.PlaceCountryCode = %q, want KZ", filter.PlaceCountryCode)
	}
	if filter.PlaceQuery != "" {
		t.Fatalf("filter.PlaceQuery = %q, want empty", filter.PlaceQuery)
	}
}

func TestNormalizeListInputMapsSelectedCityToCityIDFilter(t *testing.T) {
	filter, err := (&StoryUseCase{}).normalizeListInput(
		ListStoriesInput{CountryCode: " kz ", CityID: " almaty "},
		nil,
	)
	if err != nil {
		t.Fatalf("normalizeListInput returned error: %v", err)
	}

	if filter.PlaceCountryCode != "KZ" {
		t.Fatalf("filter.PlaceCountryCode = %q, want KZ", filter.PlaceCountryCode)
	}
	if filter.PlaceCityID != "almaty" {
		t.Fatalf("filter.PlaceCityID = %q, want almaty", filter.PlaceCityID)
	}
}

func TestNormalizeListInputMapsSelectedFormatsToFormatFilter(t *testing.T) {
	filter, err := (&StoryUseCase{}).normalizeListInput(
		ListStoriesInput{Format: []string{" story ", "GUIDE"}},
		nil,
	)
	if err != nil {
		t.Fatalf("normalizeListInput returned error: %v", err)
	}

	if len(filter.Formats) != 2 {
		t.Fatalf("filter.Formats = %v, want two formats", filter.Formats)
	}
	if filter.Formats[0] != enum.StoryFormatStory ||
		filter.Formats[1] != enum.StoryFormatGuide {
		t.Fatalf("filter.Formats = %v, want STORY and GUIDE", filter.Formats)
	}
}

func TestNormalizeListInputPreservesStorySortDirection(t *testing.T) {
	tests := map[string]string{
		"latest_asc":    "latest_asc",
		"latest_desc":   "latest_desc",
		"popular_asc":   "popular_asc",
		"popular_desc":  "popular_desc",
		"discussed_asc": "discussed_asc",
		"discussed":     "discussed_desc",
		"":              "latest_desc",
	}

	for input, expected := range tests {
		t.Run(input, func(t *testing.T) {
			filter, err := (&StoryUseCase{}).normalizeListInput(
				ListStoriesInput{Sort: input},
				nil,
			)
			if err != nil {
				t.Fatalf("normalizeListInput returned error: %v", err)
			}
			if filter.Sort != expected {
				t.Fatalf("filter.Sort = %q, want %q", filter.Sort, expected)
			}
		})
	}
}

func TestCountPublishedStoriesByAuthorIDUsesRepository(t *testing.T) {
	authorID := uuid.New()
	repo := &countingStoryRepository{count: 7}
	useCase := NewStoryUseCase(repo, nil, "")

	count, err := useCase.CountPublishedStoriesByAuthorID(context.Background(), authorID)
	if err != nil {
		t.Fatalf("CountPublishedStoriesByAuthorID returned error: %v", err)
	}

	if count != 7 {
		t.Fatalf("count = %d, want 7", count)
	}
	if repo.authorID != authorID {
		t.Fatalf("authorID = %s, want %s", repo.authorID, authorID)
	}
}

func TestNormalizeStoryInputAllowsDraftWithoutCoverPlaceOrFullContent(t *testing.T) {
	story, err := normalizeStoryInput(uuid.New(), CreateStoryInput{
		Title: "  Quick draft  ",
	})
	if err != nil {
		t.Fatalf("normalizeStoryInput returned error: %v", err)
	}

	if story.Title != "Quick draft" {
		t.Fatalf("Title = %q, want trimmed draft title", story.Title)
	}
	if story.Status != enum.StoryStatusDraft {
		t.Fatalf("Status = %q, want %q", story.Status, enum.StoryStatusDraft)
	}
	if story.Format != enum.StoryFormatStory {
		t.Fatalf("Format = %q, want %q", story.Format, enum.StoryFormatStory)
	}
	if story.CoverFileID != nil {
		t.Fatalf("CoverFileID = %v, want nil for draft", story.CoverFileID)
	}
	if story.PlaceName != nil {
		t.Fatalf("PlaceName = %v, want nil for draft", *story.PlaceName)
	}
	if story.Content != "" || story.ContentPlainText != "" || len(story.ContentBlocks) == 0 {
		t.Fatalf("draft content fields not normalized: content=%q plain=%q blocks=%s", story.Content, story.ContentPlainText, story.ContentBlocks)
	}
}

func TestNormalizeStoryInputDraftRequiresTitleOrContent(t *testing.T) {
	_, err := normalizeStoryInput(uuid.New(), CreateStoryInput{})
	if !errors.Is(err, ErrInvalidStoryContent) {
		t.Fatalf("normalizeStoryInput error = %v, want %v", err, ErrInvalidStoryContent)
	}
}

func TestNormalizeStoryInputRejectsClientArchivedStatus(t *testing.T) {
	_, err := normalizeStoryInput(uuid.New(), CreateStoryInput{
		Title:  "Client archived",
		Status: enum.StoryStatusArchived,
	})
	if !errors.Is(err, ErrInvalidStoryStatus) {
		t.Fatalf("normalizeStoryInput error = %v, want %v", err, ErrInvalidStoryStatus)
	}
}

func TestNormalizeStoryInputPublishValidationRequiresRequiredFields(t *testing.T) {
	storyID := uuid.New()
	coverID := uuid.New()
	place := "Almaty"
	contentBlocks := mustStoryDocumentJSON(t, model.StoryDocument{
		Version: model.StoryDocumentVersion,
		Blocks: []model.StoryBlock{{
			ID:   "p1",
			Type: model.StoryBlockTypeParagraph,
			Text: "Publishable content",
		}},
	})

	valid := CreateStoryInput{
		Title:         "Publishable",
		Format:        enum.StoryFormatGuide,
		Category:      enum.StoryCategoryGuide,
		Status:        enum.StoryStatusPublished,
		CoverFileID:   &coverID,
		PlaceName:     &place,
		ContentBlocks: contentBlocks,
	}

	tests := map[string]struct {
		mutate func(*CreateStoryInput)
		want   error
	}{
		"missing title": {
			mutate: func(input *CreateStoryInput) { input.Title = "" },
			want:   ErrInvalidStoryTitle,
		},
		"missing category": {
			mutate: func(input *CreateStoryInput) { input.Category = "" },
			want:   ErrInvalidStoryCategory,
		},
		"missing place": {
			mutate: func(input *CreateStoryInput) { input.PlaceName = nil },
			want:   ErrInvalidStoryPlace,
		},
		"missing cover": {
			mutate: func(input *CreateStoryInput) { input.CoverFileID = nil },
			want:   ErrInvalidStoryCover,
		},
		"missing content": {
			mutate: func(input *CreateStoryInput) { input.ContentBlocks = nil },
			want:   ErrInvalidStoryContent,
		},
	}

	for name, tt := range tests {
		t.Run(name, func(t *testing.T) {
			input := valid
			tt.mutate(&input)
			_, err := normalizeStoryInput(storyID, input)
			if !errors.Is(err, tt.want) {
				t.Fatalf("normalizeStoryInput error = %v, want %v", err, tt.want)
			}
		})
	}
}

func TestNormalizeStoryInputLegacyContentNormalizesStructuredFields(t *testing.T) {
	storyID := uuid.New()
	story, err := normalizeStoryInput(storyID, CreateStoryInput{
		Title:   "Legacy",
		Content: "Intro\n\n[[story-image:file-1]]",
	})
	if err != nil {
		t.Fatalf("normalizeStoryInput returned error: %v", err)
	}

	if story.ContentPlainText != "Intro" {
		t.Fatalf("ContentPlainText = %q, want Intro", story.ContentPlainText)
	}
	if story.Content != "Intro\n\n[[story-image:file-1]]" {
		t.Fatalf("Content = %q, want legacy content preserved", story.Content)
	}

	var document model.StoryDocument
	if err := json.Unmarshal(story.ContentBlocks, &document); err != nil {
		t.Fatalf("unmarshal ContentBlocks: %v", err)
	}
	if len(document.Blocks) != 2 {
		t.Fatalf("document block count = %d, want 2", len(document.Blocks))
	}
	if document.Blocks[1].Type != model.StoryBlockTypeImage || document.Blocks[1].FileID != "file-1" {
		t.Fatalf("second block = %+v, want legacy image block", document.Blocks[1])
	}
}

func TestNormalizeStoryInputAcceptsLegacyContentBlockList(t *testing.T) {
	story, err := normalizeStoryInput(uuid.New(), CreateStoryInput{
		Title: "Mobile draft",
		ContentBlocks: json.RawMessage(`[
			{"id":"heading-1","type":"heading","text":"Arrival","level":2},
			{"id":"paragraph-1","type":"paragraph","text":"Read more"}
		]`),
	})
	if err != nil {
		t.Fatalf("normalizeStoryInput returned error: %v", err)
	}

	var document model.StoryDocument
	if err := json.Unmarshal(story.ContentBlocks, &document); err != nil {
		t.Fatalf("unmarshal normalized content blocks: %v", err)
	}
	if document.Version != model.StoryDocumentVersion {
		t.Fatalf("document version = %d, want %d", document.Version, model.StoryDocumentVersion)
	}
	if len(document.Blocks) != 2 {
		t.Fatalf("document block count = %d, want 2", len(document.Blocks))
	}
	if document.Blocks[0].Type != model.StoryBlockTypeHeading || document.Blocks[0].Level != 2 {
		t.Fatalf("first block = %+v, want heading level 2", document.Blocks[0])
	}
	if story.ContentPlainText != "Arrival\nRead more" {
		t.Fatalf("ContentPlainText = %q, want normalized text", story.ContentPlainText)
	}
}

func TestNormalizeStoryInputPrefersStructuredContentOverLegacyContent(t *testing.T) {
	story, err := normalizeStoryInput(uuid.New(), CreateStoryInput{
		Title:   "Structured",
		Content: "legacy text that must be ignored",
		ContentBlocks: mustStoryDocumentJSON(t, model.StoryDocument{
			Version: model.StoryDocumentVersion,
			Blocks: []model.StoryBlock{{
				ID:   "structured-1",
				Type: model.StoryBlockTypeParagraph,
				Text: "Structured text",
			}},
		}),
	})
	if err != nil {
		t.Fatalf("normalizeStoryInput returned error: %v", err)
	}

	if story.ContentPlainText != "Structured text" {
		t.Fatalf("ContentPlainText = %q, want structured plain text", story.ContentPlainText)
	}
	if story.Content != "Structured text" {
		t.Fatalf("Content = %q, want legacy content derived from structured document", story.Content)
	}
}

func TestNormalizeStoryInputRejectsOverLimitLegacyContent(t *testing.T) {
	_, err := normalizeStoryInput(uuid.New(), CreateStoryInput{
		Title:   "Too long",
		Content: strings.Repeat("x", maxStoryContentChars+1),
	})
	if !errors.Is(err, ErrInvalidStoryContent) {
		t.Fatalf("normalizeStoryInput error = %v, want %v", err, ErrInvalidStoryContent)
	}
}

func TestNormalizeStoryInputRejectsOverLimitStructuredContent(t *testing.T) {
	_, err := normalizeStoryInput(uuid.New(), CreateStoryInput{
		Title: "Too long",
		ContentBlocks: mustStoryDocumentJSON(t, model.StoryDocument{
			Version: model.StoryDocumentVersion,
			Blocks: []model.StoryBlock{{
				ID:   "too-long-1",
				Type: model.StoryBlockTypeParagraph,
				Text: strings.Repeat("x", maxStoryContentChars+1),
			}},
		}),
	})
	if !errors.Is(err, ErrInvalidStoryContent) {
		t.Fatalf("normalizeStoryInput error = %v, want %v", err, ErrInvalidStoryContent)
	}
}

func TestUpdateStoryMapsRevisionConflict(t *testing.T) {
	authorID := uuid.New()
	storyID := uuid.New()
	repo := &storyUseCaseRepositoryStub{
		existing: &model.Story{
			ID:           storyID,
			AuthorUserID: authorID,
			Title:        "Existing",
			Status:       enum.StoryStatusDraft,
			Revision:     7,
		},
		updateErr: port.ErrStoryRevisionConflict,
	}
	useCase := NewStoryUseCase(repo, storyUseCaseUserClientStub{userID: authorID}, "https://stories.test")

	_, err := useCase.UpdateStory(context.Background(), "subject-1", storyID, UpdateStoryInput{
		Title:    storyStringPtr("Updated"),
		Revision: 7,
	})
	if !errors.Is(err, ErrStoryRevisionConflict) {
		t.Fatalf("UpdateStory error = %v, want %v", err, ErrStoryRevisionConflict)
	}
	if repo.updated == nil {
		t.Fatal("UpdateStory did not call repository")
	}
	if repo.updated.Revision != 7 {
		t.Fatalf("repository revision = %d, want original client revision 7", repo.updated.Revision)
	}
}

func TestUpdateStoryPreservesOmittedFieldsAndModeration(t *testing.T) {
	authorID := uuid.New()
	storyID := uuid.New()
	coverID := uuid.New()
	placeName := "Almaty"
	existingBlocks := mustStoryDocumentJSON(t, model.StoryDocument{
		Version: model.StoryDocumentVersion,
		Blocks: []model.StoryBlock{{
			ID:   "p1",
			Type: model.StoryBlockTypeParagraph,
			Text: "Original content",
		}},
	})
	repo := &storyUseCaseRepositoryStub{
		existing: &model.Story{
			ID:                   storyID,
			Slug:                 "original-slug",
			AuthorUserID:         authorID,
			Title:                "Original",
			Content:              "Original content",
			Format:               enum.StoryFormatGuide,
			ContentSchemaVersion: model.StoryDocumentVersion,
			ContentBlocks:        existingBlocks,
			ContentPlainText:     "Original content",
			Category:             enum.StoryCategoryGuide,
			Status:               enum.StoryStatusPublished,
			ModerationStatus:     enum.ModerationStatusRejected,
			Revision:             4,
			CoverFileID:          &coverID,
			PlaceName:            &placeName,
			Tags:                 []string{"one", "two"},
		},
	}
	useCase := NewStoryUseCase(repo, storyUseCaseUserClientStub{userID: authorID}, "https://stories.test")

	_, err := useCase.UpdateStory(context.Background(), "subject-1", storyID, UpdateStoryInput{
		Title:    storyStringPtr("Retitled"),
		Revision: 4,
	})
	if err != nil {
		t.Fatalf("UpdateStory returned error: %v", err)
	}
	if repo.updated == nil {
		t.Fatal("UpdateStory did not call repository")
	}
	if repo.updated.Title != "Retitled" {
		t.Fatalf("Title = %q, want Retitled", repo.updated.Title)
	}
	if repo.updated.ModerationStatus != enum.ModerationStatusRejected {
		t.Fatalf("ModerationStatus = %q, want REJECTED", repo.updated.ModerationStatus)
	}
	if repo.updated.Category != enum.StoryCategoryGuide ||
		repo.updated.Status != enum.StoryStatusPublished ||
		repo.updated.Format != enum.StoryFormatGuide ||
		repo.updated.CoverFileID == nil ||
		*repo.updated.CoverFileID != coverID ||
		repo.updated.PlaceName == nil ||
		*repo.updated.PlaceName != placeName ||
		string(repo.updated.ContentBlocks) != string(existingBlocks) ||
		strings.Join(repo.updated.Tags, ",") != "one,two" {
		t.Fatalf("updated story did not preserve omitted fields: %+v", repo.updated)
	}
	if repo.updated.IsPubliclyVisible() {
		t.Fatal("rejected story became publicly visible after owner update")
	}
}

func TestUpdateAndAutosaveRejectClientArchivedStatus(t *testing.T) {
	authorID := uuid.New()
	storyID := uuid.New()
	archivedStatus := enum.StoryStatusArchived

	tests := map[string]func(*StoryUseCase) (*StoryView, error){
		"update": func(useCase *StoryUseCase) (*StoryView, error) {
			return useCase.UpdateStory(context.Background(), "subject-1", storyID, UpdateStoryInput{
				Status:   &archivedStatus,
				Revision: 3,
			})
		},
		"autosave": func(useCase *StoryUseCase) (*StoryView, error) {
			return useCase.AutosaveStory(context.Background(), "subject-1", storyID, UpdateStoryInput{
				Status:   &archivedStatus,
				Revision: 3,
			})
		},
	}

	for name, action := range tests {
		t.Run(name, func(t *testing.T) {
			repo := &storyUseCaseRepositoryStub{
				existing: &model.Story{
					ID:               storyID,
					AuthorUserID:     authorID,
					Title:            "Existing",
					Status:           enum.StoryStatusDraft,
					ModerationStatus: enum.ModerationStatusNotRequired,
					Revision:         3,
				},
			}
			useCase := NewStoryUseCase(repo, storyUseCaseUserClientStub{userID: authorID}, "https://stories.test")

			_, err := action(useCase)
			if !errors.Is(err, ErrInvalidStoryStatus) {
				t.Fatalf("%s error = %v, want %v", name, err, ErrInvalidStoryStatus)
			}
			if repo.updated != nil {
				t.Fatalf("%s should not call repository when client requests ARCHIVED status", name)
			}
		})
	}
}

func TestAutosavePublishArchivePreserveModerationStatus(t *testing.T) {
	authorID := uuid.New()
	storyID := uuid.New()
	coverID := uuid.New()
	placeName := "Almaty"
	existingBlocks := mustStoryDocumentJSON(t, model.StoryDocument{
		Version: model.StoryDocumentVersion,
		Blocks: []model.StoryBlock{{
			ID:   "p1",
			Type: model.StoryBlockTypeParagraph,
			Text: "Ready content",
		}},
	})

	tests := map[string]func(*StoryUseCase) (*StoryView, error){
		"autosave": func(useCase *StoryUseCase) (*StoryView, error) {
			return useCase.AutosaveStory(context.Background(), "subject-1", storyID, UpdateStoryInput{
				Title:    storyStringPtr("Autosaved"),
				Revision: 8,
			})
		},
		"publish": func(useCase *StoryUseCase) (*StoryView, error) {
			return useCase.PublishStory(context.Background(), "subject-1", storyID, 8)
		},
		"archive": func(useCase *StoryUseCase) (*StoryView, error) {
			return useCase.ArchiveStory(context.Background(), "subject-1", storyID, 8)
		},
	}

	for name, action := range tests {
		t.Run(name, func(t *testing.T) {
			repo := &storyUseCaseRepositoryStub{
				existing: &model.Story{
					ID:                   storyID,
					Slug:                 "moderated-story",
					AuthorUserID:         authorID,
					Title:                "Moderated",
					Content:              "Ready content",
					Format:               enum.StoryFormatGuide,
					ContentSchemaVersion: model.StoryDocumentVersion,
					ContentBlocks:        existingBlocks,
					ContentPlainText:     "Ready content",
					Category:             enum.StoryCategoryGuide,
					Status:               enum.StoryStatusPublished,
					ModerationStatus:     enum.ModerationStatusPending,
					Revision:             8,
					CoverFileID:          &coverID,
					PlaceName:            &placeName,
					Tags:                 []string{"one"},
				},
			}
			useCase := NewStoryUseCase(repo, storyUseCaseUserClientStub{userID: authorID}, "https://stories.test")

			_, err := action(useCase)
			if err != nil {
				t.Fatalf("%s returned error: %v", name, err)
			}
			if repo.updated == nil {
				t.Fatalf("%s did not call repository", name)
			}
			if repo.updated.ModerationStatus != enum.ModerationStatusPending {
				t.Fatalf("ModerationStatus = %q, want PENDING", repo.updated.ModerationStatus)
			}
			if repo.updated.IsPubliclyVisible() {
				t.Fatalf("%s made a pending story publicly visible", name)
			}
		})
	}
}

type countingStoryRepository struct {
	port.StoryRepository
	count    int
	authorID uuid.UUID
}

func (r *countingStoryRepository) CountPublishedStoriesByAuthorID(
	_ context.Context,
	authorID uuid.UUID,
) (int, error) {
	r.authorID = authorID
	return r.count, nil
}

type storyUseCaseRepositoryStub struct {
	port.StoryRepository
	existing  *model.Story
	updated   *model.Story
	updateErr error
}

func (r *storyUseCaseRepositoryStub) GetStoryByID(_ context.Context, storyID uuid.UUID) (*model.Story, error) {
	if r.existing == nil || r.existing.ID != storyID {
		return nil, nil
	}
	copy := *r.existing
	return &copy, nil
}

func (r *storyUseCaseRepositoryStub) UpdateStory(_ context.Context, story *model.Story) error {
	copy := *story
	r.updated = &copy
	return r.updateErr
}

func (r *storyUseCaseRepositoryStub) HasStoryLike(_ context.Context, _ uuid.UUID, _ uuid.UUID) (bool, error) {
	return false, nil
}

type storyUseCaseUserClientStub struct {
	userID uuid.UUID
}

func (c storyUseCaseUserClientStub) ResolveUserIDBySubject(_ context.Context, _ string) (uuid.UUID, error) {
	return c.userID, nil
}

func (c storyUseCaseUserClientStub) GetPublicUserProfiles(
	_ context.Context,
	userIDs []uuid.UUID,
) (map[uuid.UUID]PublicUserProfile, error) {
	profiles := make(map[uuid.UUID]PublicUserProfile, len(userIDs))
	for _, userID := range userIDs {
		profiles[userID] = PublicUserProfile{UserID: userID}
	}
	return profiles, nil
}

func mustStoryDocumentJSON(t *testing.T, document model.StoryDocument) json.RawMessage {
	t.Helper()
	data, err := json.Marshal(document)
	if err != nil {
		t.Fatalf("marshal story document: %v", err)
	}
	return data
}

func storyStringPtr(v string) *string {
	return &v
}
