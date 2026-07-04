package app

import (
	"context"
	"encoding/json"
	"errors"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"

	"kz/inflap/backend/services/feed-service/internal/domain/enum"
	"kz/inflap/backend/services/feed-service/internal/domain/model"
	"kz/inflap/backend/services/feed-service/internal/domain/port"
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
	filter, err := (&PostUseCase{}).normalizeListInput(
		ListPostsInput{Place: "KZ"},
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
	filter, err := (&PostUseCase{}).normalizeListInput(
		ListPostsInput{CountryCode: " kz ", CityID: " almaty "},
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

func TestNormalizeListInputDefaultsToPostFormatsAndExcludesStories(t *testing.T) {
	filter, err := (&PostUseCase{}).normalizeListInput(ListPostsInput{}, nil)
	if err != nil {
		t.Fatalf("normalizeListInput returned error: %v", err)
	}

	if !filter.ExcludeExpiring {
		t.Fatal("filter.ExcludeExpiring = false, want true for post listings")
	}
	if len(filter.Formats) != 4 {
		t.Fatalf("filter.Formats = %v, want post formats only", filter.Formats)
	}
	for _, format := range filter.Formats {
		if format == enum.PostFormatPost {
			t.Fatalf("filter.Formats = %v, must not include story format", filter.Formats)
		}
	}
}

func TestNormalizeListInputIncludesQuickPostsForCommunityLists(t *testing.T) {
	communityID := uuid.New()
	filter, err := (&PostUseCase{}).normalizeListInput(
		ListPostsInput{CommunityID: &communityID},
		nil,
	)
	if err != nil {
		t.Fatalf("normalizeListInput returned error: %v", err)
	}

	foundQuickPost := false
	for _, format := range filter.Formats {
		if format == enum.PostFormatPost {
			foundQuickPost = true
			break
		}
	}
	if !foundQuickPost {
		t.Fatalf("filter.Formats = %v, want quick posts included for community lists", filter.Formats)
	}
}

func TestNormalizeListInputMapsSelectedPostFormatsToFormatFilter(t *testing.T) {
	filter, err := (&PostUseCase{}).normalizeListInput(
		ListPostsInput{Format: []string{" article ", "GUIDE"}},
		nil,
	)
	if err != nil {
		t.Fatalf("normalizeListInput returned error: %v", err)
	}

	if len(filter.Formats) != 2 {
		t.Fatalf("filter.Formats = %v, want two formats", filter.Formats)
	}
	if filter.Formats[0] != enum.PostFormatArticle ||
		filter.Formats[1] != enum.PostFormatGuide {
		t.Fatalf("filter.Formats = %v, want ARTICLE and GUIDE", filter.Formats)
	}
}

func TestNormalizeListInputRejectsStoryFormat(t *testing.T) {
	_, err := (&PostUseCase{}).normalizeListInput(
		ListPostsInput{Format: []string{"post"}},
		nil,
	)
	if !errors.Is(err, ErrInvalidPostFormat) {
		t.Fatalf("normalizeListInput error = %v, want %v", err, ErrInvalidPostFormat)
	}
}

func TestNormalizeListInputPreservesPostSortDirection(t *testing.T) {
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
			filter, err := (&PostUseCase{}).normalizeListInput(
				ListPostsInput{Sort: input},
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

func TestCountPublishedPostsByAuthorIDUsesRepository(t *testing.T) {
	authorID := uuid.New()
	repo := &countingPostRepository{count: 7}
	useCase := NewPostUseCase(repo, nil, "")

	count, err := useCase.CountPublishedPostsByAuthorID(context.Background(), authorID)
	if err != nil {
		t.Fatalf("CountPublishedPostsByAuthorID returned error: %v", err)
	}

	if count != 7 {
		t.Fatalf("count = %d, want 7", count)
	}
	if repo.authorID != authorID {
		t.Fatalf("authorID = %s, want %s", repo.authorID, authorID)
	}
}

func normalizePostInput(postID uuid.UUID, input CreatePostInput) (*model.Post, error) {
	return normalizePostInputWithProfile(postID, input, testPostProfileDefaults(enum.PostProfileArticleV1))
}

func TestNormalizePostInputAllowsDraftWithoutCoverPlaceOrFullContent(t *testing.T) {
	post, err := normalizePostInput(uuid.New(), CreatePostInput{
		Title: "  Quick draft  ",
	})
	if err != nil {
		t.Fatalf("normalizePostInput returned error: %v", err)
	}

	if post.Title != "Quick draft" {
		t.Fatalf("Title = %q, want trimmed draft title", post.Title)
	}
	if post.Status != enum.PostStatusDraft {
		t.Fatalf("Status = %q, want %q", post.Status, enum.PostStatusDraft)
	}
	if post.Format != enum.PostFormatArticle {
		t.Fatalf("Format = %q, want %q", post.Format, enum.PostFormatArticle)
	}
	if post.CoverFileID != nil {
		t.Fatalf("CoverFileID = %v, want nil for draft", post.CoverFileID)
	}
	if post.PlaceName != nil {
		t.Fatalf("PlaceName = %v, want nil for draft", *post.PlaceName)
	}
	if post.Content != "" || post.ContentPlainText != "" || len(post.ContentBlocks) == 0 {
		t.Fatalf("draft content fields not normalized: content=%q plain=%q blocks=%s", post.Content, post.ContentPlainText, post.ContentBlocks)
	}
}

func TestNormalizePostInputDraftRequiresTitleOrContent(t *testing.T) {
	_, err := normalizePostInput(uuid.New(), CreatePostInput{})
	if !errors.Is(err, ErrInvalidPostContent) {
		t.Fatalf("normalizePostInput error = %v, want %v", err, ErrInvalidPostContent)
	}
}

func TestCreatePostReturnsCreatedDraftWhenAuthorProfileLookupFails(t *testing.T) {
	authorID := uuid.New()
	repo := &postUseCaseRepositoryStub{}
	useCase := NewPostUseCase(
		repo,
		postUseCaseUserClientStub{
			userID:      authorID,
			profilesErr: errors.New("user-service unavailable"),
		},
		"https://posts.test",
	)

	view, err := useCase.CreatePost(context.Background(), "subject-1", CreatePostInput{
		Title: "Local draft",
		ContentBlocks: mustPostDocumentJSON(t, model.PostDocument{
			Version: model.PostDocumentVersion,
			Blocks: []model.PostBlock{{
				ID:   "p1",
				Type: model.PostBlockTypeParagraph,
				Text: "Draft content",
			}},
		}),
	})

	if err != nil {
		t.Fatalf("CreatePost returned error: %v", err)
	}
	if repo.created == nil {
		t.Fatal("CreatePost did not persist post")
	}
	if view == nil || view.Post == nil || view.Post.ID != repo.created.ID {
		t.Fatalf("CreatePost view = %+v, want created post id %s", view, repo.created.ID)
	}
	if view.Author.UserID != authorID {
		t.Fatalf("view author = %s, want %s", view.Author.UserID, authorID)
	}
	if view.Post.Revision != 1 {
		t.Fatalf("view revision = %d, want 1", view.Post.Revision)
	}
}

func TestCreatePostValidatesRouteReferenceBeforePersisting(t *testing.T) {
	authorID := uuid.New()
	routeID := "route-1"
	repo := &postUseCaseRepositoryStub{}
	validator := &postRouteReferenceValidatorStub{}
	useCase := NewPostUseCase(
		repo,
		postUseCaseUserClientStub{userID: authorID},
		"https://posts.test",
	).WithRouteReferenceValidator(validator)

	_, err := useCase.CreatePost(context.Background(), "subject-1", CreatePostInput{
		Title:         "Route draft",
		ContentBlocks: routeReferencePostDocumentJSON(t, routeID),
	})

	if err != nil {
		t.Fatalf("CreatePost returned error: %v", err)
	}
	if repo.created == nil {
		t.Fatal("CreatePost did not persist post")
	}
	if len(validator.calls) != 1 {
		t.Fatalf("route validator calls = %d, want 1", len(validator.calls))
	}
	if validator.calls[0].AuthorUserID != authorID || validator.calls[0].RouteID != routeID {
		t.Fatalf("route validator call = %+v, want author %s route %s", validator.calls[0], authorID, routeID)
	}
}

func TestCreatePostRejectsUnsafeRouteReference(t *testing.T) {
	authorID := uuid.New()
	repo := &postUseCaseRepositoryStub{}
	validator := &postRouteReferenceValidatorStub{err: ErrInvalidPostRouteReference}
	useCase := NewPostUseCase(
		repo,
		postUseCaseUserClientStub{userID: authorID},
		"https://posts.test",
	).WithRouteReferenceValidator(validator)

	_, err := useCase.CreatePost(context.Background(), "subject-1", CreatePostInput{
		Title:         "Route draft",
		ContentBlocks: routeReferencePostDocumentJSON(t, "private-route"),
	})

	if !errors.Is(err, ErrPostValidationFailed) || !errors.Is(err, ErrInvalidPostRouteReference) {
		t.Fatalf("CreatePost error = %v, want route validation failure", err)
	}
	var validationErr *PostValidationError
	if !errors.As(err, &validationErr) || validationErr.Fields["contentBlocks"] != "route_reference_not_shareable" {
		t.Fatalf("validation fields = %#v, want route_reference_not_shareable", validationErr)
	}
	if repo.created != nil {
		t.Fatal("CreatePost must not persist unsafe route reference")
	}
}

func TestCreatePostRejectsRouteReferenceWithoutValidator(t *testing.T) {
	authorID := uuid.New()
	repo := &postUseCaseRepositoryStub{}
	useCase := NewPostUseCase(
		repo,
		postUseCaseUserClientStub{userID: authorID},
		"https://posts.test",
	)

	_, err := useCase.CreatePost(context.Background(), "subject-1", CreatePostInput{
		Title:         "Route draft",
		ContentBlocks: routeReferencePostDocumentJSON(t, "route-1"),
	})

	if !errors.Is(err, ErrPostValidationFailed) || !errors.Is(err, ErrInvalidPostRouteReference) {
		t.Fatalf("CreatePost error = %v, want route validation failure", err)
	}
	if repo.created != nil {
		t.Fatal("CreatePost must not persist route references without backend validator")
	}
}

func TestCreatePostKeepsRouteReferenceValidatorFailuresTechnical(t *testing.T) {
	authorID := uuid.New()
	repo := &postUseCaseRepositoryStub{}
	validator := &postRouteReferenceValidatorStub{err: errors.New("user-route-service unavailable")}
	useCase := NewPostUseCase(
		repo,
		postUseCaseUserClientStub{userID: authorID},
		"https://posts.test",
	).WithRouteReferenceValidator(validator)

	_, err := useCase.CreatePost(context.Background(), "subject-1", CreatePostInput{
		Title:         "Route draft",
		ContentBlocks: routeReferencePostDocumentJSON(t, "route-1"),
	})

	if err == nil {
		t.Fatal("CreatePost returned nil, want technical validator error")
	}
	if errors.Is(err, ErrPostValidationFailed) || errors.Is(err, ErrInvalidPostRouteReference) {
		t.Fatalf("CreatePost error = %v, must not be business validation", err)
	}
	if repo.created != nil {
		t.Fatal("CreatePost must not persist when route validator is unavailable")
	}
}

func TestNormalizePostInputRejectsClientArchivedStatus(t *testing.T) {
	_, err := normalizePostInput(uuid.New(), CreatePostInput{
		Title:  "Client archived",
		Status: enum.PostStatusArchived,
	})
	if !errors.Is(err, ErrInvalidPostStatus) {
		t.Fatalf("normalizePostInput error = %v, want %v", err, ErrInvalidPostStatus)
	}
}

func TestNormalizePostInputPublishValidationRequiresRequiredFields(t *testing.T) {
	postID := uuid.New()
	coverID := uuid.New()
	place := "Almaty"
	contentBlocks := mustPostDocumentJSON(t, model.PostDocument{
		Version: model.PostDocumentVersion,
		Blocks: []model.PostBlock{{
			ID:   "p1",
			Type: model.PostBlockTypeParagraph,
			Text: "Publishable content",
		}},
	})

	valid := CreatePostInput{
		Title:         "Publishable",
		Format:        enum.PostFormatGuide,
		Category:      enum.PostCategoryGuide,
		Status:        enum.PostStatusPublished,
		CoverFileID:   &coverID,
		PlaceName:     &place,
		ContentBlocks: contentBlocks,
	}

	tests := map[string]struct {
		mutate func(*CreatePostInput)
		want   error
	}{
		"missing title": {
			mutate: func(input *CreatePostInput) { input.Title = "" },
			want:   ErrInvalidPostTitle,
		},
		"missing category": {
			mutate: func(input *CreatePostInput) { input.Category = "" },
			want:   ErrInvalidPostCategory,
		},
		"missing place": {
			mutate: func(input *CreatePostInput) { input.PlaceName = nil },
			want:   ErrInvalidPostPlace,
		},
		"missing cover": {
			mutate: func(input *CreatePostInput) { input.CoverFileID = nil },
			want:   ErrInvalidPostCover,
		},
		"missing content": {
			mutate: func(input *CreatePostInput) { input.ContentBlocks = nil },
			want:   ErrInvalidPostContent,
		},
	}

	for name, tt := range tests {
		t.Run(name, func(t *testing.T) {
			input := valid
			tt.mutate(&input)
			_, err := normalizePostInput(postID, input)
			if !errors.Is(err, tt.want) {
				t.Fatalf("normalizePostInput error = %v, want %v", err, tt.want)
			}
		})
	}
}

func TestNormalizePostInputLegacyContentNormalizesStructuredFields(t *testing.T) {
	postID := uuid.New()
	post, err := normalizePostInput(postID, CreatePostInput{
		Title:   "Legacy",
		Content: "Intro\n\n[[post-image:file-1]]",
	})
	if err != nil {
		t.Fatalf("normalizePostInput returned error: %v", err)
	}

	if post.ContentPlainText != "Intro" {
		t.Fatalf("ContentPlainText = %q, want Intro", post.ContentPlainText)
	}
	if post.Content != "Intro\n\n[[post-image:file-1]]" {
		t.Fatalf("Content = %q, want legacy content preserved", post.Content)
	}

	var document model.PostDocument
	if err := json.Unmarshal(post.ContentBlocks, &document); err != nil {
		t.Fatalf("unmarshal ContentBlocks: %v", err)
	}
	if len(document.Blocks) != 2 {
		t.Fatalf("document block count = %d, want 2", len(document.Blocks))
	}
	if document.Blocks[1].Type != model.PostBlockTypeImage || document.Blocks[1].FileID != "file-1" {
		t.Fatalf("second block = %+v, want legacy image block", document.Blocks[1])
	}
}

func TestNormalizePostInputAcceptsLegacyContentBlockList(t *testing.T) {
	post, err := normalizePostInput(uuid.New(), CreatePostInput{
		Title: "Mobile draft",
		ContentBlocks: json.RawMessage(`[
			{"id":"heading-1","type":"heading","text":"Arrival","level":2},
			{"id":"paragraph-1","type":"paragraph","text":"Read more"}
		]`),
	})
	if err != nil {
		t.Fatalf("normalizePostInput returned error: %v", err)
	}

	var document model.PostDocument
	if err := json.Unmarshal(post.ContentBlocks, &document); err != nil {
		t.Fatalf("unmarshal normalized content blocks: %v", err)
	}
	if document.Version != model.PostDocumentVersion {
		t.Fatalf("document version = %d, want %d", document.Version, model.PostDocumentVersion)
	}
	if len(document.Blocks) != 2 {
		t.Fatalf("document block count = %d, want 2", len(document.Blocks))
	}
	if document.Blocks[0].Type != model.PostBlockTypeHeading || document.Blocks[0].Level != 2 {
		t.Fatalf("first block = %+v, want heading level 2", document.Blocks[0])
	}
	if post.ContentPlainText != "Arrival\nRead more" {
		t.Fatalf("ContentPlainText = %q, want normalized text", post.ContentPlainText)
	}
}

func TestNormalizePostInputPrefersStructuredContentOverLegacyContent(t *testing.T) {
	post, err := normalizePostInput(uuid.New(), CreatePostInput{
		Title:   "Structured",
		Content: "legacy text that must be ignored",
		ContentBlocks: mustPostDocumentJSON(t, model.PostDocument{
			Version: model.PostDocumentVersion,
			Blocks: []model.PostBlock{{
				ID:   "structured-1",
				Type: model.PostBlockTypeParagraph,
				Text: "Structured text",
			}},
		}),
	})
	if err != nil {
		t.Fatalf("normalizePostInput returned error: %v", err)
	}

	if post.ContentPlainText != "Structured text" {
		t.Fatalf("ContentPlainText = %q, want structured plain text", post.ContentPlainText)
	}
	if post.Content != "Structured text" {
		t.Fatalf("Content = %q, want legacy content derived from structured document", post.Content)
	}
}

func TestNormalizePostInputRejectsOverLimitLegacyContent(t *testing.T) {
	_, err := normalizePostInput(uuid.New(), CreatePostInput{
		Title:   "Too long",
		Content: strings.Repeat("x", maxPostContentChars+1),
	})
	if !errors.Is(err, ErrInvalidPostContent) {
		t.Fatalf("normalizePostInput error = %v, want %v", err, ErrInvalidPostContent)
	}
}

func TestNormalizePostInputRejectsOverLimitStructuredContent(t *testing.T) {
	_, err := normalizePostInput(uuid.New(), CreatePostInput{
		Title: "Too long",
		ContentBlocks: mustPostDocumentJSON(t, model.PostDocument{
			Version: model.PostDocumentVersion,
			Blocks: []model.PostBlock{{
				ID:   "too-long-1",
				Type: model.PostBlockTypeParagraph,
				Text: strings.Repeat("x", maxPostContentChars+1),
			}},
		}),
	})
	if !errors.Is(err, ErrInvalidPostContent) {
		t.Fatalf("normalizePostInput error = %v, want %v", err, ErrInvalidPostContent)
	}
}

func TestUpdatePostMapsRevisionConflict(t *testing.T) {
	authorID := uuid.New()
	postID := uuid.New()
	repo := &postUseCaseRepositoryStub{
		existing: &model.Post{
			ID:           postID,
			AuthorUserID: authorID,
			Title:        "Existing",
			Status:       enum.PostStatusDraft,
			Revision:     7,
		},
		updateErr: port.ErrPostRevisionConflict,
	}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: authorID}, "https://posts.test")

	_, err := useCase.UpdatePost(context.Background(), "subject-1", postID, UpdatePostInput{
		Title:    postStringPtr("Updated"),
		Revision: 7,
	})
	if !errors.Is(err, ErrPostRevisionConflict) {
		t.Fatalf("UpdatePost error = %v, want %v", err, ErrPostRevisionConflict)
	}
	if repo.updated == nil {
		t.Fatal("UpdatePost did not call repository")
	}
	if repo.updated.Revision != 7 {
		t.Fatalf("repository revision = %d, want original client revision 7", repo.updated.Revision)
	}
}

func TestUpdatePostPreservesOmittedFieldsAndModeration(t *testing.T) {
	authorID := uuid.New()
	postID := uuid.New()
	coverID := uuid.New()
	placeName := "Almaty"
	existingBlocks := mustPostDocumentJSON(t, model.PostDocument{
		Version: model.PostDocumentVersion,
		Blocks: []model.PostBlock{{
			ID:   "p1",
			Type: model.PostBlockTypeParagraph,
			Text: "Original content",
		}},
	})
	repo := &postUseCaseRepositoryStub{
		existing: &model.Post{
			ID:                   postID,
			Slug:                 "original-slug",
			AuthorUserID:         authorID,
			Title:                "Original",
			Content:              "Original content",
			Format:               enum.PostFormatGuide,
			ContentSchemaVersion: model.PostDocumentVersion,
			ContentBlocks:        existingBlocks,
			ContentPlainText:     "Original content",
			Category:             enum.PostCategoryGuide,
			Status:               enum.PostStatusPublished,
			ModerationStatus:     enum.ModerationStatusRejected,
			Revision:             4,
			CoverFileID:          &coverID,
			PlaceName:            &placeName,
			Tags:                 []string{"one", "two"},
		},
	}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: authorID}, "https://posts.test")

	_, err := useCase.UpdatePost(context.Background(), "subject-1", postID, UpdatePostInput{
		Title:    postStringPtr("Retitled"),
		Revision: 4,
	})
	if err != nil {
		t.Fatalf("UpdatePost returned error: %v", err)
	}
	if repo.updated == nil {
		t.Fatal("UpdatePost did not call repository")
	}
	if repo.updated.Title != "Retitled" {
		t.Fatalf("Title = %q, want Retitled", repo.updated.Title)
	}
	if repo.updated.ModerationStatus != enum.ModerationStatusRejected {
		t.Fatalf("ModerationStatus = %q, want REJECTED", repo.updated.ModerationStatus)
	}
	if repo.updated.Category != enum.PostCategoryGuide ||
		repo.updated.Status != enum.PostStatusPublished ||
		repo.updated.Format != enum.PostFormatGuide ||
		repo.updated.CoverFileID == nil ||
		*repo.updated.CoverFileID != coverID ||
		repo.updated.PlaceName == nil ||
		*repo.updated.PlaceName != placeName ||
		string(repo.updated.ContentBlocks) != string(existingBlocks) ||
		strings.Join(repo.updated.Tags, ",") != "one,two" {
		t.Fatalf("updated post did not preserve omitted fields: %+v", repo.updated)
	}
	if repo.updated.IsPubliclyVisible() {
		t.Fatal("rejected post became publicly visible after owner update")
	}
}

func TestUpdatePostValidatesRouteReferenceBeforePersisting(t *testing.T) {
	authorID := uuid.New()
	postID := uuid.New()
	routeID := "route-1"
	repo := &postUseCaseRepositoryStub{
		existing: &model.Post{
			ID:               postID,
			AuthorUserID:     authorID,
			Title:            "Existing",
			Status:           enum.PostStatusDraft,
			ModerationStatus: enum.ModerationStatusNotRequired,
			Revision:         3,
		},
	}
	validator := &postRouteReferenceValidatorStub{}
	useCase := NewPostUseCase(
		repo,
		postUseCaseUserClientStub{userID: authorID},
		"https://posts.test",
	).WithRouteReferenceValidator(validator)

	_, err := useCase.UpdatePost(context.Background(), "subject-1", postID, UpdatePostInput{
		ContentBlocks: postRawMessagePtr(routeReferencePostDocumentJSON(t, routeID)),
		Revision:      3,
	})

	if err != nil {
		t.Fatalf("UpdatePost returned error: %v", err)
	}
	if repo.updated == nil {
		t.Fatal("UpdatePost did not persist post")
	}
	if len(validator.calls) != 1 {
		t.Fatalf("route validator calls = %d, want 1", len(validator.calls))
	}
	if validator.calls[0].AuthorUserID != authorID || validator.calls[0].RouteID != routeID {
		t.Fatalf("route validator call = %+v, want author %s route %s", validator.calls[0], authorID, routeID)
	}
}

func TestUpdatePostRejectsUnsafeRouteReference(t *testing.T) {
	authorID := uuid.New()
	postID := uuid.New()
	repo := &postUseCaseRepositoryStub{
		existing: &model.Post{
			ID:               postID,
			AuthorUserID:     authorID,
			Title:            "Existing",
			Status:           enum.PostStatusDraft,
			ModerationStatus: enum.ModerationStatusNotRequired,
			Revision:         3,
		},
	}
	validator := &postRouteReferenceValidatorStub{err: ErrInvalidPostRouteReference}
	useCase := NewPostUseCase(
		repo,
		postUseCaseUserClientStub{userID: authorID},
		"https://posts.test",
	).WithRouteReferenceValidator(validator)

	_, err := useCase.UpdatePost(context.Background(), "subject-1", postID, UpdatePostInput{
		ContentBlocks: postRawMessagePtr(routeReferencePostDocumentJSON(t, "private-route")),
		Revision:      3,
	})

	if !errors.Is(err, ErrPostValidationFailed) || !errors.Is(err, ErrInvalidPostRouteReference) {
		t.Fatalf("UpdatePost error = %v, want route validation failure", err)
	}
	if repo.updated != nil {
		t.Fatal("UpdatePost must not persist unsafe route reference")
	}
}

func TestUpdateAndAutosaveRejectClientArchivedStatus(t *testing.T) {
	authorID := uuid.New()
	postID := uuid.New()
	archivedStatus := enum.PostStatusArchived

	tests := map[string]func(*PostUseCase) (*PostView, error){
		"update": func(useCase *PostUseCase) (*PostView, error) {
			return useCase.UpdatePost(context.Background(), "subject-1", postID, UpdatePostInput{
				Status:   &archivedStatus,
				Revision: 3,
			})
		},
		"autosave": func(useCase *PostUseCase) (*PostView, error) {
			return useCase.AutosavePost(context.Background(), "subject-1", postID, UpdatePostInput{
				Status:   &archivedStatus,
				Revision: 3,
			})
		},
	}

	for name, action := range tests {
		t.Run(name, func(t *testing.T) {
			repo := &postUseCaseRepositoryStub{
				existing: &model.Post{
					ID:               postID,
					AuthorUserID:     authorID,
					Title:            "Existing",
					Status:           enum.PostStatusDraft,
					ModerationStatus: enum.ModerationStatusNotRequired,
					Revision:         3,
				},
			}
			useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: authorID}, "https://posts.test")

			_, err := action(useCase)
			if !errors.Is(err, ErrInvalidPostStatus) {
				t.Fatalf("%s error = %v, want %v", name, err, ErrInvalidPostStatus)
			}
			if repo.updated != nil {
				t.Fatalf("%s should not call repository when client requests ARCHIVED status", name)
			}
		})
	}
}

func TestUpdatePostRevisionConflictDoesNotBindMedia(t *testing.T) {
	authorID := uuid.New()
	postID := uuid.New()
	coverID := uuid.New()
	placeName := "Almaty"
	repo := &postUseCaseRepositoryStub{
		existing: &model.Post{
			ID:               postID,
			AuthorUserID:     authorID,
			Title:            "Existing",
			Status:           enum.PostStatusDraft,
			ModerationStatus: enum.ModerationStatusNotRequired,
			Revision:         5,
		},
	}
	binder := &postUseCaseMediaBinderStub{}
	useCase := NewPostUseCase(
		repo,
		postUseCaseUserClientStub{userID: authorID},
		"https://posts.test",
	).WithPostMediaBinder(binder)

	publishedStatus := enum.PostStatusPublished
	category := enum.PostCategoryGuide
	_, err := useCase.UpdatePost(context.Background(), "subject-1", postID, UpdatePostInput{
		Title:          postStringPtr("Updated"),
		Status:         &publishedStatus,
		Category:       &category,
		CoverFileID:    &coverID,
		CoverFileIDSet: true,
		PlaceName:      &placeName,
		PlaceNameSet:   true,
		ContentBlocks: postRawMessagePtr(mustPostDocumentJSON(t, model.PostDocument{
			Version: model.PostDocumentVersion,
			Blocks: []model.PostBlock{{
				ID:   "p1",
				Type: model.PostBlockTypeParagraph,
				Text: "Useful content",
			}},
		})),
		Revision: 4,
	})

	if !errors.Is(err, ErrPostRevisionConflict) {
		t.Fatalf("UpdatePost error = %v, want %v", err, ErrPostRevisionConflict)
	}
	if repo.updated != nil {
		t.Fatal("UpdatePost should not persist stale revision")
	}
	if len(binder.calls) != 0 {
		t.Fatalf("media binder calls = %d, want 0", len(binder.calls))
	}
}

func TestCreatePostBindsCoverAndContentMedia(t *testing.T) {
	authorID := uuid.New()
	coverID := uuid.New()
	imageID := uuid.New()
	galleryID := uuid.New()
	placeName := "Almaty"
	repo := &postUseCaseRepositoryStub{}
	binder := &postUseCaseMediaBinderStub{
		metadata: map[uuid.UUID]postUseCaseMediaMetadata{
			coverID: {width: 1200, height: 800},
			imageID: {width: 640, height: 480},
		},
	}
	useCase := NewPostUseCase(
		repo,
		postUseCaseUserClientStub{userID: authorID},
		"https://posts.test",
	).WithPostMediaBinder(binder)

	_, err := useCase.CreatePost(context.Background(), "subject-1", CreatePostInput{
		Title:       "Media post",
		Format:      enum.PostFormatGuide,
		Category:    enum.PostCategoryGuide,
		Status:      enum.PostStatusPublished,
		CoverFileID: &coverID,
		PlaceName:   &placeName,
		ContentBlocks: mustPostDocumentJSON(t, model.PostDocument{
			Version: model.PostDocumentVersion,
			Blocks: []model.PostBlock{
				{ID: "p1", Type: model.PostBlockTypeParagraph, Text: "Useful content"},
				{ID: "image-1", Type: model.PostBlockTypeImage, FileID: imageID.String()},
				{
					ID:   "gallery-1",
					Type: model.PostBlockTypeGallery,
					Images: []model.PostGalleryImage{
						{FileID: galleryID.String()},
						{FileID: coverID.String()},
					},
				},
			},
		}),
	})

	if err != nil {
		t.Fatalf("CreatePost returned error: %v", err)
	}
	if repo.created == nil {
		t.Fatal("CreatePost did not persist post")
	}
	if repo.created.Status != enum.PostStatusDraft {
		t.Fatalf("initial persisted status = %q, want DRAFT while media binds", repo.created.Status)
	}
	if repo.created.MediaStatus != enum.PostMediaStatusPendingBind {
		t.Fatalf("initial media status = %q, want PENDING_BIND", repo.created.MediaStatus)
	}
	assertPostMediaStatuses(t, repo.created.Media, enum.PostMediaProcessingStatusPendingBind)
	if repo.updated == nil {
		t.Fatal("CreatePost did not finalize post after media binding")
	}
	if repo.updated.Status != enum.PostStatusPublished {
		t.Fatalf("final status = %q, want PUBLISHED", repo.updated.Status)
	}
	if repo.updated.MediaStatus != enum.PostMediaStatusReady {
		t.Fatalf("final media status = %q, want READY", repo.updated.MediaStatus)
	}
	assertPostMediaStatuses(t, repo.updated.Media, enum.PostMediaProcessingStatusBound)
	assertPostMediaDimensions(t, repo.updated.Media, coverID, 1200, 800)
	assertPostMediaDimensions(t, repo.updated.Media, imageID, 640, 480)
	if len(binder.calls) != 1 {
		t.Fatalf("media binder calls = %d, want 1", len(binder.calls))
	}

	call := binder.calls[0]
	if call.PostID != repo.updated.ID {
		t.Fatalf("binding post id = %s, want %s", call.PostID, repo.updated.ID)
	}
	if call.ActorUserID != authorID {
		t.Fatalf("binding actor user id = %s, want %s", call.ActorUserID, authorID)
	}
	if call.PrimaryFileID == nil || *call.PrimaryFileID != coverID {
		t.Fatalf("primary file id = %v, want %s", call.PrimaryFileID, coverID)
	}
	assertUUIDSlicesEqual(t, call.FileIDs, []uuid.UUID{coverID, imageID, galleryID})
}

func TestCreatePostRejectsStoryPayload(t *testing.T) {
	authorID := uuid.New()
	coverID := uuid.New()
	placeName := "Almaty"
	expiresAt := time.Now().UTC().Add(24 * time.Hour)
	repo := &postUseCaseRepositoryStub{}
	useCase := NewPostUseCase(
		repo,
		postUseCaseUserClientStub{userID: authorID},
		"https://posts.test",
	)

	_, err := useCase.CreatePost(context.Background(), "subject-1", CreatePostInput{
		Title:       "Ephemeral camera post",
		Format:      enum.PostFormatPost,
		Category:    enum.PostCategoryJournal,
		Status:      enum.PostStatusPublished,
		CoverFileID: &coverID,
		PlaceName:   &placeName,
		ExpiresAt:   &expiresAt,
		ContentBlocks: mustPostDocumentJSON(t, model.PostDocument{
			Version: model.PostDocumentVersion,
			Blocks: []model.PostBlock{{
				ID:     "image-1",
				Type:   model.PostBlockTypeImage,
				FileID: coverID.String(),
			}},
		}),
	})

	if !errors.Is(err, ErrInvalidPostFormat) {
		t.Fatalf("CreatePost error = %v, want %v", err, ErrInvalidPostFormat)
	}
	if repo.created != nil {
		t.Fatal("CreatePost must not persist story payloads")
	}
}

func TestCreateStoryPersistsSeparateStoryAggregate(t *testing.T) {
	authorID := uuid.New()
	coverID := uuid.New()
	repo := &postUseCaseRepositoryStub{}
	useCase := NewPostUseCase(
		repo,
		postUseCaseUserClientStub{userID: authorID},
		"https://posts.test",
	)

	view, err := useCase.CreateStory(context.Background(), "subject-1", CreateStoryInput{
		Caption:     "Camera moment",
		CoverFileID: coverID,
		MediaFileID: coverID,
		MediaType:   enum.PostMediaTypeImage,
	})

	if err != nil {
		t.Fatalf("CreateStory returned error: %v", err)
	}
	if view == nil || view.Story == nil {
		t.Fatal("CreateStory returned nil view")
	}
	if repo.created != nil {
		t.Fatal("CreateStory must not persist a post row")
	}
	if repo.createdStory == nil {
		t.Fatal("CreateStory did not persist a story")
	}
	if repo.createdStory.Caption != "Camera moment" {
		t.Fatalf("Caption = %q, want Camera moment", repo.createdStory.Caption)
	}
	if repo.createdStory.MediaType != enum.PostMediaTypeImage {
		t.Fatalf("MediaType = %q, want IMAGE", repo.createdStory.MediaType)
	}
	if !repo.createdStory.ExpiresAt.After(repo.createdStory.CreatedAt) {
		t.Fatal("ExpiresAt must be after CreatedAt")
	}
	if got := repo.createdStory.ExpiresAt.Sub(repo.createdStory.CreatedAt); got != defaultStoryTTL {
		t.Fatalf("story ttl = %s, want %s", got, defaultStoryTTL)
	}
}

func TestListMyArchivedStoriesRequestsExpiredOwnedStories(t *testing.T) {
	authorID := uuid.New()
	fileID := uuid.New()
	now := postUseCaseNow()
	archived := &model.Story{
		ID:           uuid.New(),
		AuthorUserID: authorID,
		Caption:      "Archived camera moment",
		MediaFileID:  fileID,
		CoverFileID:  fileID,
		MediaType:    enum.StoryMediaTypeImage,
		ExpiresAt:    now.Add(-time.Hour),
		CreatedAt:    now.Add(-25 * time.Hour),
		UpdatedAt:    now.Add(-25 * time.Hour),
	}
	repo := &postUseCaseRepositoryStub{listedStories: []*model.Story{archived}}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: authorID}, "https://posts.test")

	page, err := useCase.ListMyArchivedStories(context.Background(), "subject-1", ListStoriesInput{
		Limit:  10,
		Offset: 0,
	})
	if err != nil {
		t.Fatalf("ListMyArchivedStories returned error: %v", err)
	}

	if len(page.Items) != 1 || page.Items[0].Story.ID != archived.ID {
		t.Fatalf("archived stories = %+v, want %s", page.Items, archived.ID)
	}
	if repo.storyListFilter.AuthorUserID == nil || *repo.storyListFilter.AuthorUserID != authorID {
		t.Fatalf("AuthorUserID filter = %v, want %s", repo.storyListFilter.AuthorUserID, authorID)
	}
	if !repo.storyListFilter.OnlyExpired || !repo.storyListFilter.IncludeExpired {
		t.Fatalf("story archive filter = %+v, want expired-only archive", repo.storyListFilter)
	}
}

func TestLikeStoryPersistsSeparateStoryLike(t *testing.T) {
	storyID := uuid.New()
	authorID := uuid.New()
	viewerID := uuid.New()
	fileID := uuid.New()
	now := postUseCaseNow()
	repo := &postUseCaseRepositoryStub{
		listedStories: []*model.Story{{
			ID:           storyID,
			AuthorUserID: authorID,
			Caption:      "Morning route",
			MediaFileID:  fileID,
			CoverFileID:  fileID,
			MediaType:    enum.StoryMediaTypeImage,
			ExpiresAt:    now.Add(time.Hour),
			CreatedAt:    now,
			UpdatedAt:    now,
		}},
	}
	useCase := NewPostUseCase(
		repo,
		postUseCaseUserClientStub{userID: viewerID},
		"https://posts.test",
	)

	count, err := useCase.LikeStory(context.Background(), "subject-1", storyID)
	if err != nil {
		t.Fatalf("LikeStory returned error: %v", err)
	}
	if count != 1 {
		t.Fatalf("LikeStory count = %d, want 1", count)
	}
	if !repo.likeStoryCalled {
		t.Fatal("LikeStory did not persist story like")
	}
}

func TestLikeStoryRejectsOwnStory(t *testing.T) {
	storyID := uuid.New()
	authorID := uuid.New()
	fileID := uuid.New()
	now := postUseCaseNow()
	repo := &postUseCaseRepositoryStub{
		listedStories: []*model.Story{{
			ID:           storyID,
			AuthorUserID: authorID,
			Caption:      "My route",
			MediaFileID:  fileID,
			CoverFileID:  fileID,
			MediaType:    enum.StoryMediaTypeImage,
			ExpiresAt:    now.Add(time.Hour),
			CreatedAt:    now,
			UpdatedAt:    now,
		}},
	}
	useCase := NewPostUseCase(
		repo,
		postUseCaseUserClientStub{userID: authorID},
		"https://posts.test",
	)

	_, err := useCase.LikeStory(context.Background(), "subject-1", storyID)
	if !errors.Is(err, ErrCannotLikeOwnStory) {
		t.Fatalf("LikeStory error = %v, want ErrCannotLikeOwnStory", err)
	}
	if repo.likeStoryCalled {
		t.Fatal("LikeStory must not persist own-story like")
	}
}

func TestCreateQuickPostUsesStructuredProfileWithoutArticleRequirements(t *testing.T) {
	authorID := uuid.New()
	repo := &postUseCaseRepositoryStub{}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: authorID}, "https://posts.test")

	_, err := useCase.CreatePost(context.Background(), "subject-1", CreatePostInput{
		Format:         enum.PostFormatPost,
		Status:         enum.PostStatusPublished,
		PublishIntent:  true,
		PostProfileKey: enum.PostProfileQuickPostV1,
		StructuredData: json.RawMessage(`{"body":"Кто едет в Дананг сегодня?"}`),
	})
	if err != nil {
		t.Fatalf("CreatePost returned error: %v", err)
	}
	if repo.created == nil {
		t.Fatal("CreatePost did not persist quick post")
	}
	if repo.created.PostKind != enum.PostKindQuickPost {
		t.Fatalf("PostKind = %q, want QUICK_POST", repo.created.PostKind)
	}
	if repo.created.PostProfileKey != enum.PostProfileQuickPostV1 {
		t.Fatalf("PostProfileKey = %q, want quick_post_v1", repo.created.PostProfileKey)
	}
	if repo.created.Title == "" || repo.created.ContentPlainText == "" {
		t.Fatalf("quick post should derive title/content from structured data: %+v", repo.created)
	}
}

func TestCreateQuickPostPublishesFirstInModeratedCommunity(t *testing.T) {
	authorID := uuid.New()
	communityID := uuid.New()
	repo := &postUseCaseRepositoryStub{
		community: postUseCaseCommunity(
			communityID,
			enum.CommunityPostingPolicyMembersAfterModeration,
		),
		communityMembership: postUseCaseMembership(
			communityID,
			authorID,
			enum.CommunityMembershipRoleMember,
		),
	}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: authorID}, "https://posts.test")

	_, err := useCase.CreatePost(context.Background(), "subject-1", CreatePostInput{
		Format:         enum.PostFormatPost,
		Status:         enum.PostStatusPublished,
		PublishIntent:  true,
		CommunityID:    &communityID,
		PostProfileKey: enum.PostProfileQuickPostV1,
		StructuredData: json.RawMessage(`{"body":"Кто идет на мастер-класс сегодня?"}`),
	})
	if err != nil {
		t.Fatalf("CreatePost returned error: %v", err)
	}
	if repo.created == nil {
		t.Fatal("CreatePost did not persist quick post")
	}
	if repo.created.ModerationStatus != enum.ModerationStatusNotRequired {
		t.Fatalf("ModerationStatus = %q, want NOT_REQUIRED for publish-first quick post", repo.created.ModerationStatus)
	}
	if !repo.created.IsPubliclyVisible() {
		t.Fatal("publish-first quick post should be publicly visible")
	}
}

func TestCreatePostInvalidatesFeedCachesForPublishedCommunityPost(t *testing.T) {
	authorID := uuid.New()
	communityID := uuid.New()
	repo := &postUseCaseRepositoryStub{
		community: postUseCaseCommunity(
			communityID,
			enum.CommunityPostingPolicyOpenMembers,
		),
		communityMembership: postUseCaseMembership(
			communityID,
			authorID,
			enum.CommunityMembershipRoleMember,
		),
	}
	cache := &postFeedCacheFake{}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: authorID}, "https://posts.test").
		WithPostFeedCache(cache, time.Minute, 30*time.Second)

	if _, err := useCase.CreatePost(
		context.Background(),
		"subject-1",
		validPublishedCommunityPostInput(t, communityID),
	); err != nil {
		t.Fatalf("CreatePost returned error: %v", err)
	}

	for _, scope := range []string{
		postFeedCacheGlobalScope,
		postFeedCacheAuthorScope(authorID),
		postFeedCacheCommunityScope(communityID),
	} {
		if !containsString(cache.bumpedScopes, scope) {
			t.Fatalf("bumped scopes = %#v, want %s", cache.bumpedScopes, scope)
		}
	}
}

func TestUpdatePostInvalidatesFeedCachesForPublishedCommunityPost(t *testing.T) {
	authorID := uuid.New()
	communityID := uuid.New()
	coverID := uuid.New()
	placeName := "Almaty"
	now := postUseCaseNow()
	repo := &postUseCaseRepositoryStub{
		existing: &model.Post{
			ID:               uuid.New(),
			Slug:             "community-post",
			AuthorUserID:     authorID,
			Title:            "Community post",
			Format:           enum.PostFormatGuide,
			ContentBlocks:    mustPostDocumentJSON(t, model.PostDocument{Version: model.PostDocumentVersion, Blocks: []model.PostBlock{{ID: "p1", Type: model.PostBlockTypeParagraph, Text: "Useful content"}}}),
			ContentPlainText: "Useful content",
			Category:         enum.PostCategoryGuide,
			Status:           enum.PostStatusPublished,
			MediaStatus:      enum.PostMediaStatusReady,
			ModerationStatus: enum.ModerationStatusNotRequired,
			Revision:         1,
			CommunityID:      &communityID,
			CoverFileID:      &coverID,
			PlaceName:        &placeName,
			PublishedAt:      &now,
			CreatedAt:        now,
			UpdatedAt:        now,
		},
		community: postUseCaseCommunity(
			communityID,
			enum.CommunityPostingPolicyOpenMembers,
		),
		communityMembership: postUseCaseMembership(
			communityID,
			authorID,
			enum.CommunityMembershipRoleMember,
		),
	}
	cache := &postFeedCacheFake{}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: authorID}, "https://posts.test").
		WithPostFeedCache(cache, time.Minute, 30*time.Second)
	updatedTitle := "Updated community post"

	if _, err := useCase.UpdatePost(
		context.Background(),
		"subject-1",
		repo.existing.ID,
		UpdatePostInput{Title: &updatedTitle, Revision: repo.existing.Revision},
	); err != nil {
		t.Fatalf("UpdatePost returned error: %v", err)
	}

	for _, scope := range []string{
		postFeedCacheGlobalScope,
		postFeedCacheAuthorScope(authorID),
		postFeedCacheCommunityScope(communityID),
	} {
		if !containsString(cache.bumpedScopes, scope) {
			t.Fatalf("bumped scopes = %#v, want %s", cache.bumpedScopes, scope)
		}
	}
}

func TestDeletePostInvalidatesGlobalAndAuthorFeedCaches(t *testing.T) {
	authorID := uuid.New()
	postID := uuid.New()
	repo := &postUseCaseRepositoryStub{}
	cache := &postFeedCacheFake{}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: authorID}, "https://posts.test").
		WithPostFeedCache(cache, time.Minute, 30*time.Second)

	if err := useCase.DeletePost(context.Background(), "subject-1", postID); err != nil {
		t.Fatalf("DeletePost returned error: %v", err)
	}

	for _, scope := range []string{
		postFeedCacheGlobalScope,
		postFeedCacheAuthorScope(authorID),
	} {
		if !containsString(cache.bumpedScopes, scope) {
			t.Fatalf("bumped scopes = %#v, want %s", cache.bumpedScopes, scope)
		}
	}
}

func TestCreatePostRateLimitedByRecentPosts(t *testing.T) {
	authorID := uuid.New()
	repo := &postUseCaseRepositoryStub{
		postCreateCountSince: postCreateRateLimitMax,
	}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: authorID}, "https://posts.test")

	_, err := useCase.CreatePost(context.Background(), "subject-1", CreatePostInput{
		Format:         enum.PostFormatPost,
		Status:         enum.PostStatusPublished,
		PublishIntent:  true,
		PostProfileKey: enum.PostProfileQuickPostV1,
		StructuredData: json.RawMessage(`{"body":"Кто едет в Дананг сегодня?"}`),
	})
	if !errors.Is(err, ErrPostRateLimited) {
		t.Fatalf("CreatePost error = %v, want %v", err, ErrPostRateLimited)
	}
	if repo.created != nil {
		t.Fatal("CreatePost should not persist when post creation is rate limited")
	}
	if repo.postCreateCountAuthorID != authorID {
		t.Fatalf("rate limit author id = %s, want %s", repo.postCreateCountAuthorID, authorID)
	}
	if repo.postCreateCountWindowStart.IsZero() {
		t.Fatal("CreatePost should pass a non-zero rate-limit window start")
	}
}

func TestCheckPostCreateEligibilityReturnsRetryAfterWhenLimited(t *testing.T) {
	authorID := uuid.New()
	now := time.Date(2026, 6, 14, 12, 0, 0, 0, time.UTC)
	oldest := now.Add(-42 * time.Minute)
	repo := &postUseCaseRepositoryStub{
		postCreateCountSince:          postCreateRateLimitMax,
		oldestPostCreatedAtAfterSince: &oldest,
	}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: authorID}, "https://posts.test")

	eligibility, err := useCase.postCreateEligibility(context.Background(), authorID, now)
	if err != nil {
		t.Fatalf("postCreateEligibility returned error: %v", err)
	}

	if eligibility.CanCreate {
		t.Fatal("CanCreate = true, want false for exhausted limit")
	}
	if eligibility.Limit != postCreateRateLimitMax {
		t.Fatalf("Limit = %d, want %d", eligibility.Limit, postCreateRateLimitMax)
	}
	if eligibility.Remaining != 0 {
		t.Fatalf("Remaining = %d, want 0", eligibility.Remaining)
	}
	if eligibility.RetryAfter != 18*time.Minute {
		t.Fatalf("RetryAfter = %s, want 18m", eligibility.RetryAfter)
	}
	if eligibility.NextAvailableAt == nil || !eligibility.NextAvailableAt.Equal(oldest.Add(postCreateRateLimitWindow)) {
		t.Fatalf("NextAvailableAt = %v, want %v", eligibility.NextAvailableAt, oldest.Add(postCreateRateLimitWindow))
	}
}

func TestCreateEventAnnouncementRequestsActivityIntent(t *testing.T) {
	authorID := uuid.New()
	repo := &postUseCaseRepositoryStub{}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: authorID}, "https://posts.test")

	_, err := useCase.CreatePost(context.Background(), "subject-1", CreatePostInput{
		Status:         enum.PostStatusPublished,
		PublishIntent:  true,
		PostProfileKey: enum.PostProfileEventAnnouncementV1,
		StructuredData: json.RawMessage(`{
			"title":"Футбол вечером",
			"description":"Собираемся на пляже",
			"starts_at":"2026-07-01T18:00:00Z",
			"location":{"name":"My Khe Beach","city_id":"da-nang","country_code":"VN"}
		}`),
	})
	if err != nil {
		t.Fatalf("CreatePost returned error: %v", err)
	}
	if repo.created == nil {
		t.Fatal("CreatePost did not persist event announcement")
	}
	if repo.created.PostKind != enum.PostKindEventAnnouncement {
		t.Fatalf("PostKind = %q, want EVENT_ANNOUNCEMENT", repo.created.PostKind)
	}
	if repo.created.ActivityCreationStatus == nil || *repo.created.ActivityCreationStatus != enum.ActivityCreationStatusPending {
		t.Fatalf("ActivityCreationStatus = %v, want PENDING", repo.created.ActivityCreationStatus)
	}
}

func TestCreatePostUsesRepositoryPostProfileContract(t *testing.T) {
	authorID := uuid.New()
	repo := &postUseCaseRepositoryStub{
		listedPostProfiles: []*model.CommunityPostProfile{{
			Key:                  enum.PostProfileTripPlanV1,
			Version:              3,
			PostKind:             enum.PostKindTripPlan,
			ModerationMode:       enum.ModerationModeTrustedPublishElseReview,
			ActivityCreationMode: enum.ActivityCreationModeRequired,
			ValidationJSON:       json.RawMessage(`{"required":["title","route","starts_at","meeting_point"]}`),
		}},
	}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: authorID}, "https://posts.test")

	_, err := useCase.CreatePost(context.Background(), "subject-1", CreatePostInput{
		Status:         enum.PostStatusPublished,
		PublishIntent:  true,
		PostProfileKey: enum.PostProfileTripPlanV1,
		StructuredData: json.RawMessage(`{
			"title":"Хайкинг к водопадам",
			"route":["da-nang","ba-na-hills"],
			"starts_at":"2026-07-02T07:00:00Z",
			"meeting_point":{"name":"Dragon Bridge","city_id":"da-nang","country_code":"VN"}
		}`),
	})
	if err != nil {
		t.Fatalf("CreatePost returned error: %v", err)
	}
	if repo.created == nil {
		t.Fatal("CreatePost did not persist trip post")
	}
	if repo.created.PostProfileVersion != 3 {
		t.Fatalf("PostProfileVersion = %d, want repository profile version 3", repo.created.PostProfileVersion)
	}
	if repo.created.ModerationMode != enum.ModerationModeTrustedPublishElseReview {
		t.Fatalf("ModerationMode = %q, want repository moderation mode", repo.created.ModerationMode)
	}
	if repo.created.ActivityCreationStatus == nil || *repo.created.ActivityCreationStatus != enum.ActivityCreationStatusPending {
		t.Fatalf("ActivityCreationStatus = %v, want PENDING from repository activity mode", repo.created.ActivityCreationStatus)
	}
}

func TestCreatePostRejectsMissingRepositoryPostProfileWhenCatalogLoaded(t *testing.T) {
	authorID := uuid.New()
	repo := &postUseCaseRepositoryStub{
		listedPostProfiles: []*model.CommunityPostProfile{{
			Key:                  enum.PostProfileQuickPostV1,
			Version:              1,
			PostKind:             enum.PostKindQuickPost,
			ModerationMode:       enum.ModerationModePublishFirst,
			ActivityCreationMode: enum.ActivityCreationModeDisabled,
			ValidationJSON:       json.RawMessage(`{"required":["body"]}`),
		}},
	}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: authorID}, "https://posts.test")

	_, err := useCase.CreatePost(context.Background(), "subject-1", CreatePostInput{
		Status:         enum.PostStatusPublished,
		PublishIntent:  true,
		PostProfileKey: enum.PostProfileTripPlanV1,
		StructuredData: json.RawMessage(`{
			"title":"Хайкинг к водопадам",
			"route":["da-nang","ba-na-hills"],
			"starts_at":"2026-07-02T07:00:00Z",
			"meeting_point":{"name":"Dragon Bridge","city_id":"da-nang","country_code":"VN"}
		}`),
	})
	if !errors.Is(err, ErrInvalidPostContent) {
		t.Fatalf("CreatePost error = %v, want %v", err, ErrInvalidPostContent)
	}
	if repo.created != nil {
		t.Fatal("CreatePost should not persist when loaded profile catalog is missing the requested key")
	}
}

func TestCreatePostRejectsEmptyRepositoryPostProfileCatalog(t *testing.T) {
	authorID := uuid.New()
	repo := &postUseCaseRepositoryStub{
		listedPostProfiles: []*model.CommunityPostProfile{},
	}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: authorID}, "https://posts.test")

	_, err := useCase.CreatePost(context.Background(), "subject-1", CreatePostInput{
		Status:         enum.PostStatusPublished,
		PublishIntent:  true,
		PostProfileKey: enum.PostProfileQuickPostV1,
		StructuredData: json.RawMessage(`{"body":"Кто едет в Дананг сегодня?"}`),
	})
	if !errors.Is(err, ErrInvalidPostContent) {
		t.Fatalf("CreatePost error = %v, want %v", err, ErrInvalidPostContent)
	}
	if repo.created != nil {
		t.Fatal("CreatePost should not persist when profile catalog is empty")
	}
}

func TestCreatePostRejectsMalformedRepositoryPostProfileValidation(t *testing.T) {
	authorID := uuid.New()
	repo := &postUseCaseRepositoryStub{
		listedPostProfiles: []*model.CommunityPostProfile{{
			Key:                  enum.PostProfileTripPlanV1,
			Version:              1,
			PostKind:             enum.PostKindTripPlan,
			ModerationMode:       enum.ModerationModePublishFirstWithRiskHold,
			ActivityCreationMode: enum.ActivityCreationModeOptional,
			ValidationJSON:       json.RawMessage(`{`),
		}},
	}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: authorID}, "https://posts.test")

	_, err := useCase.CreatePost(context.Background(), "subject-1", CreatePostInput{
		Status:         enum.PostStatusPublished,
		PublishIntent:  true,
		PostProfileKey: enum.PostProfileTripPlanV1,
		StructuredData: json.RawMessage(`{
			"title":"Хайкинг к водопадам",
			"route":["da-nang","ba-na-hills"],
			"starts_at":"2026-07-02T07:00:00Z",
			"meeting_point":{"name":"Dragon Bridge","city_id":"da-nang","country_code":"VN"}
		}`),
	})
	if !errors.Is(err, ErrInvalidPostContent) {
		t.Fatalf("CreatePost error = %v, want %v", err, ErrInvalidPostContent)
	}
	if repo.created != nil {
		t.Fatal("CreatePost should not persist when profile validation contract is malformed")
	}
}

func TestUpdatePostUsesRepositoryPostProfileContract(t *testing.T) {
	authorID := uuid.New()
	postID := uuid.New()
	repo := &postUseCaseRepositoryStub{
		existing: &model.Post{
			ID:                   postID,
			AuthorUserID:         authorID,
			Title:                "Draft",
			Content:              "Draft content",
			Format:               enum.PostFormatGuide,
			ContentSchemaVersion: model.PostDocumentVersion,
			ContentBlocks: mustPostDocumentJSON(t, model.PostDocument{
				Version: model.PostDocumentVersion,
				Blocks: []model.PostBlock{{
					ID:   "p1",
					Type: model.PostBlockTypeParagraph,
					Text: "Draft content",
				}},
			}),
			ContentPlainText: "Draft content",
			Category:         enum.PostCategoryGuide,
			Status:           enum.PostStatusDraft,
			ModerationStatus: enum.ModerationStatusNotRequired,
			Revision:         2,
		},
		listedPostProfiles: []*model.CommunityPostProfile{{
			Key:                  enum.PostProfileTripPlanV1,
			Version:              4,
			PostKind:             enum.PostKindTripPlan,
			ModerationMode:       enum.ModerationModeTrustedPublishElseReview,
			ActivityCreationMode: enum.ActivityCreationModeRequired,
			ValidationJSON:       json.RawMessage(`{"required":["title","route","starts_at","meeting_point"]}`),
		}},
	}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: authorID}, "https://posts.test")

	publishedStatus := enum.PostStatusPublished
	profileKey := enum.PostProfileTripPlanV1
	structuredData := json.RawMessage(`{
		"title":"Хайкинг к водопадам",
		"route":["da-nang","ba-na-hills"],
		"starts_at":"2026-07-02T07:00:00Z",
		"meeting_point":{"name":"Dragon Bridge","city_id":"da-nang","country_code":"VN"}
	}`)
	_, err := useCase.UpdatePost(context.Background(), "subject-1", postID, UpdatePostInput{
		Status:         &publishedStatus,
		PostProfileKey: &profileKey,
		StructuredData: &structuredData,
		Revision:       2,
	})
	if err != nil {
		t.Fatalf("UpdatePost returned error: %v", err)
	}
	if repo.updated == nil {
		t.Fatal("UpdatePost did not call repository")
	}
	if repo.updated.PostProfileVersion != 4 {
		t.Fatalf("PostProfileVersion = %d, want repository profile version 4", repo.updated.PostProfileVersion)
	}
	if repo.updated.ModerationMode != enum.ModerationModeTrustedPublishElseReview {
		t.Fatalf("ModerationMode = %q, want repository moderation mode", repo.updated.ModerationMode)
	}
	if repo.updated.ActivityCreationStatus == nil || *repo.updated.ActivityCreationStatus != enum.ActivityCreationStatusPending {
		t.Fatalf("ActivityCreationStatus = %v, want PENDING from repository activity mode", repo.updated.ActivityCreationStatus)
	}
}

func TestApplyPostActivityCreationStateIgnoresNilPost(t *testing.T) {
	defer func() {
		if recovered := recover(); recovered != nil {
			t.Fatalf("applyPostActivityCreationState panicked for nil post: %v", recovered)
		}
	}()

	applyPostActivityCreationState(nil, postProfileDefaults{
		Key:                  enum.PostProfileEventAnnouncementV1,
		Version:              1,
		Kind:                 enum.PostKindEventAnnouncement,
		ModerationMode:       enum.ModerationModeTrustedPublishElseReview,
		ActivityCreationMode: enum.ActivityCreationModeRequired,
	})
}

func TestCreatePostRejectsInvalidMediaUUIDBeforePersist(t *testing.T) {
	authorID := uuid.New()
	repo := &postUseCaseRepositoryStub{}
	binder := &postUseCaseMediaBinderStub{}
	useCase := NewPostUseCase(
		repo,
		postUseCaseUserClientStub{userID: authorID},
		"https://posts.test",
	).WithPostMediaBinder(binder)

	_, err := useCase.CreatePost(context.Background(), "subject-1", CreatePostInput{
		Title: "Draft with bad media",
		ContentBlocks: mustPostDocumentJSON(t, model.PostDocument{
			Version: model.PostDocumentVersion,
			Blocks: []model.PostBlock{{
				ID:     "image-1",
				Type:   model.PostBlockTypeImage,
				FileID: "not-a-uuid",
			}},
		}),
	})

	if !errors.Is(err, ErrInvalidPostMedia) {
		t.Fatalf("CreatePost error = %v, want %v", err, ErrInvalidPostMedia)
	}
	if repo.created != nil {
		t.Fatal("CreatePost should not persist post with invalid media file id")
	}
	if len(binder.calls) != 0 {
		t.Fatalf("media binder calls = %d, want 0", len(binder.calls))
	}
}

func TestCreatePostDoesNotPersistWhenMediaBindingFails(t *testing.T) {
	authorID := uuid.New()
	coverID := uuid.New()
	placeName := "Almaty"
	repo := &postUseCaseRepositoryStub{}
	binder := &postUseCaseMediaBinderStub{err: errors.New("file-manager unavailable")}
	useCase := NewPostUseCase(
		repo,
		postUseCaseUserClientStub{userID: authorID},
		"https://posts.test",
	).WithPostMediaBinder(binder)

	_, err := useCase.CreatePost(context.Background(), "subject-1", CreatePostInput{
		Title:       "Media post",
		Format:      enum.PostFormatGuide,
		Category:    enum.PostCategoryGuide,
		Status:      enum.PostStatusPublished,
		CoverFileID: &coverID,
		PlaceName:   &placeName,
		ContentBlocks: mustPostDocumentJSON(t, model.PostDocument{
			Version: model.PostDocumentVersion,
			Blocks: []model.PostBlock{{
				ID:   "p1",
				Type: model.PostBlockTypeParagraph,
				Text: "Useful content",
			}},
		}),
	})

	if err == nil {
		t.Fatal("CreatePost returned nil error, want media binding failure")
	}
	if repo.created == nil {
		t.Fatal("CreatePost should persist a safe draft so media binding can be retried")
	}
	if repo.created.Status != enum.PostStatusDraft {
		t.Fatalf("initial persisted status = %q, want DRAFT while media binds", repo.created.Status)
	}
	if repo.created.MediaStatus != enum.PostMediaStatusPendingBind {
		t.Fatalf("initial media status = %q, want PENDING_BIND", repo.created.MediaStatus)
	}
	if repo.updated == nil {
		t.Fatal("CreatePost should mark persisted post media as failed")
	}
	if repo.updated.Status != enum.PostStatusDraft {
		t.Fatalf("failed media post status = %q, want DRAFT", repo.updated.Status)
	}
	if repo.updated.PublishedAt != nil {
		t.Fatalf("failed media post PublishedAt = %v, want nil", repo.updated.PublishedAt)
	}
	if repo.updated.MediaStatus != enum.PostMediaStatusFailed {
		t.Fatalf("failed media status = %q, want FAILED", repo.updated.MediaStatus)
	}
	assertPostMediaStatuses(t, repo.updated.Media, enum.PostMediaProcessingStatusBindFailed)
}

func TestAutosavePublishArchivePreserveModerationStatus(t *testing.T) {
	authorID := uuid.New()
	postID := uuid.New()
	coverID := uuid.New()
	placeName := "Almaty"
	existingBlocks := mustPostDocumentJSON(t, model.PostDocument{
		Version: model.PostDocumentVersion,
		Blocks: []model.PostBlock{{
			ID:   "p1",
			Type: model.PostBlockTypeParagraph,
			Text: "Ready content",
		}},
	})

	tests := map[string]func(*PostUseCase) (*PostView, error){
		"autosave": func(useCase *PostUseCase) (*PostView, error) {
			return useCase.AutosavePost(context.Background(), "subject-1", postID, UpdatePostInput{
				Title:    postStringPtr("Autosaved"),
				Revision: 8,
			})
		},
		"publish": func(useCase *PostUseCase) (*PostView, error) {
			return useCase.PublishPost(context.Background(), "subject-1", postID, 8)
		},
		"archive": func(useCase *PostUseCase) (*PostView, error) {
			return useCase.ArchivePost(context.Background(), "subject-1", postID, 8)
		},
	}

	for name, action := range tests {
		t.Run(name, func(t *testing.T) {
			repo := &postUseCaseRepositoryStub{
				existing: &model.Post{
					ID:                   postID,
					Slug:                 "moderated-post",
					AuthorUserID:         authorID,
					Title:                "Moderated",
					Content:              "Ready content",
					Format:               enum.PostFormatGuide,
					ContentSchemaVersion: model.PostDocumentVersion,
					ContentBlocks:        existingBlocks,
					ContentPlainText:     "Ready content",
					Category:             enum.PostCategoryGuide,
					Status:               enum.PostStatusPublished,
					ModerationStatus:     enum.ModerationStatusPending,
					Revision:             8,
					CoverFileID:          &coverID,
					PlaceName:            &placeName,
					Tags:                 []string{"one"},
				},
			}
			useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: authorID}, "https://posts.test")

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
				t.Fatalf("%s made a pending post publicly visible", name)
			}
		})
	}
}

func TestCreatePublishedCommunityPostAppliesPostingPolicyModeration(t *testing.T) {
	authorID := uuid.New()
	communityID := uuid.New()
	input := validPublishedCommunityPostInput(t, communityID)

	tests := map[string]struct {
		policy enum.CommunityPostingPolicy
		want   enum.ModerationStatus
	}{
		"members_after_moderation": {
			policy: enum.CommunityPostingPolicyMembersAfterModeration,
			want:   enum.ModerationStatusPending,
		},
		"open_members": {
			policy: enum.CommunityPostingPolicyOpenMembers,
			want:   enum.ModerationStatusNotRequired,
		},
	}

	for name, tc := range tests {
		t.Run(name, func(t *testing.T) {
			repo := &postUseCaseRepositoryStub{
				community:           postUseCaseCommunity(communityID, tc.policy),
				communityMembership: postUseCaseMembership(communityID, authorID, enum.CommunityMembershipRoleMember),
			}
			useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: authorID}, "https://posts.test")

			_, err := useCase.CreatePost(context.Background(), "subject-1", input)
			if err != nil {
				t.Fatalf("CreatePost returned error: %v", err)
			}
			if repo.created == nil {
				t.Fatal("CreatePost did not call repository")
			}
			if repo.created.ModerationStatus != tc.want {
				t.Fatalf("ModerationStatus = %q, want %q", repo.created.ModerationStatus, tc.want)
			}
		})
	}
}

func TestCreatePublishedCommunityPostDeniesRestrictedPostingPolicyForMember(t *testing.T) {
	authorID := uuid.New()
	communityID := uuid.New()
	input := validPublishedCommunityPostInput(t, communityID)

	tests := map[string]enum.CommunityPostingPolicy{
		"admins_only":     enum.CommunityPostingPolicyAdminsOnly,
		"trusted_members": enum.CommunityPostingPolicyTrustedMembers,
	}

	for name, policy := range tests {
		t.Run(name, func(t *testing.T) {
			repo := &postUseCaseRepositoryStub{
				community:           postUseCaseCommunity(communityID, policy),
				communityMembership: postUseCaseMembership(communityID, authorID, enum.CommunityMembershipRoleMember),
			}
			useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: authorID}, "https://posts.test")

			_, err := useCase.CreatePost(context.Background(), "subject-1", input)
			if !errors.Is(err, ErrCommunityPostingDenied) {
				t.Fatalf("CreatePost error = %v, want %v", err, ErrCommunityPostingDenied)
			}
			if repo.created != nil {
				t.Fatal("CreatePost should not persist denied community post")
			}
		})
	}
}

func TestFollowCommunityRejectsMutedMember(t *testing.T) {
	communityID := uuid.New()
	userID := uuid.New()
	membership := postUseCaseMembership(communityID, userID, enum.CommunityMembershipRoleMember)
	membership.Status = enum.CommunityMembershipStatusMuted
	repo := &postUseCaseRepositoryStub{
		community:           postUseCaseCommunity(communityID, enum.CommunityPostingPolicyOpenMembers),
		communityMembership: membership,
	}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: userID}, "https://posts.test")

	_, err := useCase.FollowCommunity(context.Background(), "subject", communityID)

	if !errors.Is(err, ErrCommunityFollowDenied) {
		t.Fatalf("FollowCommunity error = %v, want %v", err, ErrCommunityFollowDenied)
	}
	if repo.followCommunityCalled {
		t.Fatal("FollowCommunity should not call repository follow for muted members")
	}
}

func TestListCommunitiesExcludesFollowedAndPassesSearchFilter(t *testing.T) {
	viewerID := uuid.New()
	followedID := uuid.New()
	openID := uuid.New()
	repo := &postUseCaseRepositoryStub{
		listedCommunities: []*model.Community{
			postUseCaseCommunity(followedID, enum.CommunityPostingPolicyOpenMembers),
			postUseCaseCommunity(openID, enum.CommunityPostingPolicyOpenMembers),
		},
		followedCommunityIDs: map[uuid.UUID]bool{
			followedID: true,
		},
	}
	repo.listedCommunities[0].Title = "Crypto investors"
	repo.listedCommunities[1].Title = "Blockchain&Crypto"

	useCase := NewPostUseCase(
		repo,
		postUseCaseUserClientStub{userID: viewerID},
		"https://posts.test",
	)

	items, err := useCase.ListCommunities(context.Background(), "subject", ListCommunitiesInput{
		Search:          "crypto",
		ExcludeFollowed: true,
		Limit:           20,
	})
	if err != nil {
		t.Fatalf("ListCommunities returned error: %v", err)
	}

	if repo.communityListFilter.Search != "crypto" {
		t.Fatalf("Search filter = %q, want crypto", repo.communityListFilter.Search)
	}
	if len(repo.followedCommunityLookupIDs) != 2 {
		t.Fatalf("followed lookup ids = %v, want both communities", repo.followedCommunityLookupIDs)
	}
	if len(items) != 1 || items[0].Community.ID != openID {
		t.Fatalf("items = %#v, want only open community", items)
	}
	if items[0].FollowedByViewer {
		t.Fatal("returned community should not be marked followed")
	}
}

func TestListCommunitiesCanReturnOnlyFollowed(t *testing.T) {
	viewerID := uuid.New()
	followedID := uuid.New()
	openID := uuid.New()
	repo := &postUseCaseRepositoryStub{
		listedCommunities: []*model.Community{
			postUseCaseCommunity(followedID, enum.CommunityPostingPolicyOpenMembers),
			postUseCaseCommunity(openID, enum.CommunityPostingPolicyOpenMembers),
		},
		followedCommunityIDs: map[uuid.UUID]bool{
			followedID: true,
		},
	}

	useCase := NewPostUseCase(
		repo,
		postUseCaseUserClientStub{userID: viewerID},
		"https://posts.test",
	)

	items, err := useCase.ListCommunities(context.Background(), "subject", ListCommunitiesInput{
		OnlyFollowed: true,
		Limit:        20,
	})
	if err != nil {
		t.Fatalf("ListCommunities returned error: %v", err)
	}

	if repo.communityListFilter.OnlyFollowedByUserID == nil ||
		*repo.communityListFilter.OnlyFollowedByUserID != viewerID {
		t.Fatalf("OnlyFollowedByUserID = %v, want %s", repo.communityListFilter.OnlyFollowedByUserID, viewerID)
	}
	if len(items) != 1 || items[0].Community.ID != followedID {
		t.Fatalf("items = %#v, want only followed community", items)
	}
	if !items[0].FollowedByViewer {
		t.Fatal("returned community should be marked followed")
	}
}

func TestCreateCommunityStoresLocalizedContent(t *testing.T) {
	actorID := uuid.New()
	repo := &postUseCaseRepositoryStub{}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{}, "https://posts.test")

	created, err := useCase.CreateCommunity(context.Background(), CreateCommunityInput{
		Slug:             "investments",
		TitleI18n:        map[string]string{"ru": "Инвестиции", "en": "Investments", "kk": "Инвестициялар"},
		DescriptionI18n:  map[string]string{"ru": "Советы по инвестициям", "en": "Investment discussions", "kk": "Инвестиция талқылауы"},
		RulesI18n:        map[string][]string{"ru": {"Без спама"}, "en": {"No spam"}, "kk": {"Спам жоқ"}},
		Topic:            "FINANCE",
		PostingPolicy:    "MEMBERS_AFTER_MODERATION",
		Status:           "ACTIVE",
		CreatedByAdminID: actorID,
	})
	if err != nil {
		t.Fatalf("CreateCommunity returned error: %v", err)
	}

	if repo.createdCommunity == nil {
		t.Fatal("CreateCommunity did not persist community")
	}
	if repo.createdCommunity.Title != "Инвестиции" ||
		repo.createdCommunity.Description != "Советы по инвестициям" ||
		repo.createdCommunity.Rules[0] != "Без спама" {
		t.Fatalf("fallback content = %#v", repo.createdCommunity)
	}
	if repo.createdCommunity.TitleI18n["en"] != "Investments" ||
		repo.createdCommunity.DescriptionI18n["kk"] != "Инвестиция талқылауы" ||
		repo.createdCommunity.RulesI18n["en"][0] != "No spam" {
		t.Fatalf("i18n content = %#v", repo.createdCommunity)
	}
	if created.Community.ID == uuid.Nil || created.Community.CreatedByAdminID == nil || *created.Community.CreatedByAdminID != actorID {
		t.Fatalf("created community identity/admin = %#v", created.Community)
	}
}

func TestRestrictedCommunityMemberCannotInteractWithCommunityPost(t *testing.T) {
	communityID := uuid.New()
	postID := uuid.New()
	commentID := uuid.New()
	viewerID := uuid.New()
	authorID := uuid.New()
	publishedAt := postUseCaseNow()

	for _, status := range []enum.CommunityMembershipStatus{
		enum.CommunityMembershipStatusMuted,
		enum.CommunityMembershipStatusBanned,
	} {
		t.Run(string(status), func(t *testing.T) {
			tests := map[string]func(*PostUseCase) error{
				"like_post": func(useCase *PostUseCase) error {
					_, err := useCase.LikePost(context.Background(), "subject", postID)
					return err
				},
				"create_comment": func(useCase *PostUseCase) error {
					_, err := useCase.CreateComment(context.Background(), "subject", postID, "Thanks for sharing")
					return err
				},
				"like_comment": func(useCase *PostUseCase) error {
					_, _, err := useCase.LikeComment(context.Background(), "subject", postID, commentID)
					return err
				},
			}

			for name, act := range tests {
				t.Run(name, func(t *testing.T) {
					membership := postUseCaseMembership(communityID, viewerID, enum.CommunityMembershipRoleMember)
					membership.Status = status
					repo := &postUseCaseRepositoryStub{
						existing: &model.Post{
							ID:               postID,
							AuthorUserID:     authorID,
							Title:            "Community post",
							Status:           enum.PostStatusPublished,
							ModerationStatus: enum.ModerationStatusApproved,
							CommunityID:      &communityID,
							PublishedAt:      &publishedAt,
						},
						communityMembership: membership,
						comment: &model.PostComment{
							ID:           commentID,
							PostID:       postID,
							AuthorUserID: authorID,
							Body:         "Existing comment",
							CreatedAt:    publishedAt,
							UpdatedAt:    publishedAt,
						},
					}
					useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: viewerID}, "https://posts.test")

					err := act(useCase)

					if !errors.Is(err, ErrCommunityInteractionDenied) {
						t.Fatalf("%s error = %v, want %v", name, err, ErrCommunityInteractionDenied)
					}
					if repo.likePostCalled || repo.createdComment != nil || repo.likeCommentCalled {
						t.Fatalf("%s should not mutate repository for %s member", name, status)
					}
				})
			}
		})
	}
}

func TestLikePostSendsPostLikeNotificationOnFirstLike(t *testing.T) {
	postID := uuid.New()
	authorID := uuid.New()
	viewerID := uuid.New()
	coverID := uuid.New()
	publishedAt := postUseCaseNow()
	nickname := "@devdone"
	repo := &postUseCaseRepositoryStub{
		existing: &model.Post{
			ID:               postID,
			Slug:             "almaty-morning",
			AuthorUserID:     authorID,
			Title:            "Almaty morning",
			Status:           enum.PostStatusPublished,
			ModerationStatus: enum.ModerationStatusApproved,
			CoverFileID:      &coverID,
			PublishedAt:      &publishedAt,
		},
		likePostChangedSet: true,
		likePostChanged:    true,
	}
	notifications := newPostNotificationGatewayStub()
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{
		userID: viewerID,
		profiles: map[uuid.UUID]PublicUserProfile{
			viewerID: {UserID: viewerID, Nickname: &nickname},
		},
	}, "https://posts.test").WithPostNotificationGateway(notifications)

	count, err := useCase.LikePost(context.Background(), "subject", postID)
	if err != nil {
		t.Fatalf("LikePost returned error: %v", err)
	}
	if count != 1 {
		t.Fatalf("LikePost count = %d, want 1", count)
	}

	notification := notifications.take(t)
	if notification.PostID != postID || notification.PostAuthorUserID != authorID {
		t.Fatalf("post notification target = %+v", notification)
	}
	if notification.ActorUserID != viewerID || notification.ActorDisplayName != "devdone" {
		t.Fatalf("post notification actor = %s %q, want %s devdone", notification.ActorUserID, notification.ActorDisplayName, viewerID)
	}
	if notification.PostSlug != "almaty-morning" || notification.PostTitle != "Almaty morning" {
		t.Fatalf("post notification post data = %+v", notification)
	}
	if notification.PostCoverFileID == nil || *notification.PostCoverFileID != coverID {
		t.Fatalf("post notification cover = %v, want %s", notification.PostCoverFileID, coverID)
	}
}

func TestLikePostAllowsAuthorToLikeOwnPost(t *testing.T) {
	postID := uuid.New()
	authorID := uuid.New()
	publishedAt := postUseCaseNow()
	repo := &postUseCaseRepositoryStub{
		existing: &model.Post{
			ID:               postID,
			AuthorUserID:     authorID,
			Title:            "Author update",
			Status:           enum.PostStatusPublished,
			ModerationStatus: enum.ModerationStatusApproved,
			PublishedAt:      &publishedAt,
			LikeCount:        2,
		},
	}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: authorID}, "https://posts.test")

	count, err := useCase.LikePost(context.Background(), "subject", postID)
	if err != nil {
		t.Fatalf("LikePost returned error: %v", err)
	}
	if count != 3 {
		t.Fatalf("LikePost count = %d, want 3", count)
	}
	if !repo.likePostCalled {
		t.Fatal("LikePost should call repository for author-owned posts")
	}
}

func TestLikePostSkipsNotificationWhenLikeAlreadyExists(t *testing.T) {
	postID := uuid.New()
	authorID := uuid.New()
	viewerID := uuid.New()
	publishedAt := postUseCaseNow()
	repo := &postUseCaseRepositoryStub{
		existing: &model.Post{
			ID:               postID,
			Slug:             "almaty-morning",
			AuthorUserID:     authorID,
			Title:            "Almaty morning",
			Status:           enum.PostStatusPublished,
			ModerationStatus: enum.ModerationStatusApproved,
			PublishedAt:      &publishedAt,
		},
		likePostChangedSet: true,
		likePostChanged:    false,
	}
	notifications := newPostNotificationGatewayStub()
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: viewerID}, "https://posts.test").
		WithPostNotificationGateway(notifications)

	if _, err := useCase.LikePost(context.Background(), "subject", postID); err != nil {
		t.Fatalf("LikePost returned error: %v", err)
	}

	notifications.expectNone(t)
}

func TestLikePostTracksPositiveFeedSignalOnFirstLike(t *testing.T) {
	postID := uuid.New()
	authorID := uuid.New()
	viewerID := uuid.New()
	communityID := uuid.New()
	publishedAt := postUseCaseNow()
	repo := &postUseCaseRepositoryStub{
		existing: &model.Post{
			ID:               postID,
			AuthorUserID:     authorID,
			Title:            "Useful local note",
			Status:           enum.PostStatusPublished,
			ModerationStatus: enum.ModerationStatusApproved,
			CommunityID:      &communityID,
			PostProfileKey:   enum.PostProfileQuickPostV1,
			Category:         enum.PostCategoryJournal,
			Tags:             []string{"local", "tips"},
			PublishedAt:      &publishedAt,
		},
		likePostChangedSet: true,
		likePostChanged:    true,
	}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: viewerID}, "https://posts.test")

	if _, err := useCase.LikePost(context.Background(), "subject", postID); err != nil {
		t.Fatalf("LikePost returned error: %v", err)
	}

	if len(repo.trackedFeedEvents) != 1 {
		t.Fatalf("tracked feed events = %d, want like signal", len(repo.trackedFeedEvents))
	}
	event := repo.trackedFeedEvents[0]
	if event.EventType != model.FeedEventTypeLike ||
		event.ViewerUserID == nil ||
		*event.ViewerUserID != viewerID ||
		event.PostID == nil ||
		*event.PostID != postID ||
		event.CommunityID == nil ||
		*event.CommunityID != communityID ||
		event.BlockType != model.FeedBlockTypePostCard ||
		event.Metadata["source"] != "post_interaction" ||
		event.Metadata["engagementType"] != model.FeedEventTypeLike ||
		event.Metadata["postProfileKey"] != string(enum.PostProfileQuickPostV1) {
		t.Fatalf("like feed event = %+v, want post interaction metadata", event)
	}
}

func TestLikePostDoesNotFailWhenPositiveFeedSignalTrackingFails(t *testing.T) {
	postID := uuid.New()
	authorID := uuid.New()
	viewerID := uuid.New()
	publishedAt := postUseCaseNow()
	repo := &postUseCaseRepositoryStub{
		existing: &model.Post{
			ID:               postID,
			AuthorUserID:     authorID,
			Title:            "Useful local note",
			Status:           enum.PostStatusPublished,
			ModerationStatus: enum.ModerationStatusApproved,
			PostProfileKey:   enum.PostProfileQuickPostV1,
			PublishedAt:      &publishedAt,
		},
		likePostChangedSet:  true,
		likePostChanged:     true,
		createFeedEventsErr: errors.New("feed event store unavailable"),
	}
	notifications := newPostNotificationGatewayStub()
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: viewerID}, "https://posts.test").
		WithPostNotificationGateway(notifications)

	count, err := useCase.LikePost(context.Background(), "subject", postID)
	if err != nil {
		t.Fatalf("LikePost returned error: %v", err)
	}
	if count != 1 {
		t.Fatalf("LikePost count = %d, want 1", count)
	}
	if len(repo.trackedFeedEvents) != 0 {
		t.Fatalf("tracked feed events = %d, want failed tracking to remain secondary", len(repo.trackedFeedEvents))
	}

	notification := notifications.take(t)
	if notification.PostID != postID || notification.ActorUserID != viewerID {
		t.Fatalf("notification = %+v, want like notification after secondary tracking failure", notification)
	}
}

func TestCreateCommentDelegatesRateLimitToRepository(t *testing.T) {
	authorID := uuid.New()
	postID := uuid.New()
	publishedAt := postUseCaseNow()
	repo := &postUseCaseRepositoryStub{
		existing: &model.Post{
			ID:               postID,
			AuthorUserID:     uuid.New(),
			Title:            "Public post",
			Status:           enum.PostStatusPublished,
			ModerationStatus: enum.ModerationStatusNotRequired,
			PublishedAt:      &publishedAt,
		},
		createCommentErr: port.ErrPostCommentRateLimited,
	}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: authorID}, "https://posts.test")

	_, err := useCase.CreateComment(context.Background(), "subject", postID, "Too soon")

	if !errors.Is(err, ErrPostCommentRateLimited) {
		t.Fatalf("CreateComment error = %v, want %v", err, ErrPostCommentRateLimited)
	}
	if repo.latestCommentLookupCalled {
		t.Fatal("CreateComment should delegate rate-limit enforcement to repository transaction")
	}
	if repo.createdComment != nil {
		t.Fatal("CreateComment should not expose created comment when repository rate-limits")
	}
}

func TestCreateCommentTracksPositiveFeedSignal(t *testing.T) {
	authorID := uuid.New()
	postID := uuid.New()
	communityID := uuid.New()
	publishedAt := postUseCaseNow()
	repo := &postUseCaseRepositoryStub{
		existing: &model.Post{
			ID:               postID,
			AuthorUserID:     uuid.New(),
			Title:            "Question for locals",
			Status:           enum.PostStatusPublished,
			ModerationStatus: enum.ModerationStatusNotRequired,
			CommunityID:      &communityID,
			PostProfileKey:   enum.PostProfileQuickPostV1,
			Category:         enum.PostCategoryJournal,
			Tags:             []string{"question"},
			PublishedAt:      &publishedAt,
		},
	}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: authorID}, "https://posts.test")

	if _, err := useCase.CreateComment(context.Background(), "subject", postID, "I can help"); err != nil {
		t.Fatalf("CreateComment returned error: %v", err)
	}

	if len(repo.trackedFeedEvents) != 1 {
		t.Fatalf("tracked feed events = %d, want comment signal", len(repo.trackedFeedEvents))
	}
	event := repo.trackedFeedEvents[0]
	if event.EventType != model.FeedEventTypeComment ||
		event.ViewerUserID == nil ||
		*event.ViewerUserID != authorID ||
		event.PostID == nil ||
		*event.PostID != postID ||
		event.CommunityID == nil ||
		*event.CommunityID != communityID ||
		event.BlockType != model.FeedBlockTypePostCard ||
		event.Metadata["source"] != "post_interaction" ||
		event.Metadata["engagementType"] != model.FeedEventTypeComment ||
		event.Metadata["postProfileKey"] != string(enum.PostProfileQuickPostV1) {
		t.Fatalf("comment feed event = %+v, want post interaction metadata", event)
	}
}

func TestCreateDraftCommunityPostValidatesCommunityWithoutModeration(t *testing.T) {
	authorID := uuid.New()
	communityID := uuid.New()
	input := validPublishedCommunityPostInput(t, communityID)
	input.Status = enum.PostStatusDraft
	input.PublishIntent = false

	repo := &postUseCaseRepositoryStub{
		community: postUseCaseCommunity(communityID, enum.CommunityPostingPolicyMembersAfterModeration),
	}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: authorID}, "https://posts.test")

	_, err := useCase.CreatePost(context.Background(), "subject-1", input)
	if err != nil {
		t.Fatalf("CreatePost returned error: %v", err)
	}
	if repo.created == nil {
		t.Fatal("CreatePost did not call repository")
	}
	if repo.created.ModerationStatus != enum.ModerationStatusNotRequired {
		t.Fatalf("ModerationStatus = %q, want NOT_REQUIRED", repo.created.ModerationStatus)
	}
}

func TestListCommunityModerationPostsRequiresModeratorRole(t *testing.T) {
	actorID := uuid.New()
	communityID := uuid.New()
	repo := &postUseCaseRepositoryStub{
		community:           postUseCaseCommunity(communityID, enum.CommunityPostingPolicyMembersAfterModeration),
		communityMembership: postUseCaseMembership(communityID, actorID, enum.CommunityMembershipRoleMember),
	}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: actorID}, "https://posts.test")

	_, err := useCase.ListCommunityModerationPosts(context.Background(), "subject-1", ListCommunityModerationPostsInput{
		CommunityID: communityID,
	})
	if !errors.Is(err, ErrCommunityModerationDenied) {
		t.Fatalf("ListCommunityModerationPosts error = %v, want %v", err, ErrCommunityModerationDenied)
	}
}

func TestListCommunityModerationPostsFiltersPendingPublishedPosts(t *testing.T) {
	actorID := uuid.New()
	authorID := uuid.New()
	communityID := uuid.New()
	publishedAt := postUseCaseNow()
	repo := &postUseCaseRepositoryStub{
		community:           postUseCaseCommunity(communityID, enum.CommunityPostingPolicyMembersAfterModeration),
		communityMembership: postUseCaseMembership(communityID, actorID, enum.CommunityMembershipRoleModerator),
		listedPosts: []*model.Post{{
			ID:               uuid.New(),
			Slug:             "pending-community-post",
			AuthorUserID:     authorID,
			Title:            "Pending community post",
			Category:         enum.PostCategoryGuide,
			Status:           enum.PostStatusPublished,
			ModerationStatus: enum.ModerationStatusPending,
			CommunityID:      &communityID,
			PublishedAt:      &publishedAt,
		}},
	}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: actorID}, "https://posts.test")

	items, err := useCase.ListCommunityModerationPosts(context.Background(), "subject-1", ListCommunityModerationPostsInput{
		CommunityID: communityID,
		Limit:       11,
		Offset:      4,
	})
	if err != nil {
		t.Fatalf("ListCommunityModerationPosts returned error: %v", err)
	}
	if len(items) != 1 {
		t.Fatalf("items length = %d, want 1", len(items))
	}
	if len(repo.listFilter.CommunityIDs) != 1 || repo.listFilter.CommunityIDs[0] != communityID {
		t.Fatalf("CommunityIDs filter = %v, want [%s]", repo.listFilter.CommunityIDs, communityID)
	}
	if repo.listFilter.Status == nil || *repo.listFilter.Status != enum.PostStatusPublished {
		t.Fatalf("Status filter = %v, want PUBLISHED", repo.listFilter.Status)
	}
	if len(repo.listFilter.ModerationStatuses) != 1 || repo.listFilter.ModerationStatuses[0] != enum.ModerationStatusPending {
		t.Fatalf("ModerationStatuses filter = %v, want [PENDING]", repo.listFilter.ModerationStatuses)
	}
	if repo.listFilter.OnlyPublished {
		t.Fatal("moderation queue must not use public visibility filter")
	}
	if repo.listFilter.Limit != 11 || repo.listFilter.Offset != 4 {
		t.Fatalf("pagination filter = limit %d offset %d, want 11/4", repo.listFilter.Limit, repo.listFilter.Offset)
	}
}

func TestReviewCommunityPostAppliesModeratorDecision(t *testing.T) {
	actorID := uuid.New()
	authorID := uuid.New()
	communityID := uuid.New()
	postID := uuid.New()
	publishedAt := postUseCaseNow()

	tests := map[string]struct {
		decision string
		want     enum.ModerationStatus
	}{
		"approve": {
			decision: "approve",
			want:     enum.ModerationStatusApproved,
		},
		"reject": {
			decision: "reject",
			want:     enum.ModerationStatusRejected,
		},
	}

	for name, tc := range tests {
		t.Run(name, func(t *testing.T) {
			repo := &postUseCaseRepositoryStub{
				existing: &model.Post{
					ID:               postID,
					Slug:             "pending-community-post",
					AuthorUserID:     authorID,
					Title:            "Pending community post",
					Category:         enum.PostCategoryGuide,
					Status:           enum.PostStatusPublished,
					ModerationStatus: enum.ModerationStatusPending,
					Revision:         3,
					CommunityID:      &communityID,
					PublishedAt:      &publishedAt,
				},
				community:           postUseCaseCommunity(communityID, enum.CommunityPostingPolicyMembersAfterModeration),
				communityMembership: postUseCaseMembership(communityID, actorID, enum.CommunityMembershipRoleModerator),
			}
			useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: actorID}, "https://posts.test")

			_, err := useCase.ReviewCommunityPost(context.Background(), "subject-1", postID, ReviewCommunityPostInput{
				CommunityID: communityID,
				Decision:    tc.decision,
			})
			if err != nil {
				t.Fatalf("ReviewCommunityPost returned error: %v", err)
			}
			if repo.updated == nil {
				t.Fatal("ReviewCommunityPost did not update repository")
			}
			if repo.updated.ModerationStatus != tc.want {
				t.Fatalf("ModerationStatus = %q, want %q", repo.updated.ModerationStatus, tc.want)
			}
			if repo.updated.Revision != 3 {
				t.Fatalf("Revision = %d, want optimistic lock revision 3", repo.updated.Revision)
			}
		})
	}
}

func TestReviewCommunityPostRecordsAuditDecision(t *testing.T) {
	actorID := uuid.New()
	authorID := uuid.New()
	communityID := uuid.New()
	postID := uuid.New()
	publishedAt := postUseCaseNow()
	repo := &postUseCaseRepositoryStub{
		existing: &model.Post{
			ID:               postID,
			Slug:             "pending-community-post",
			AuthorUserID:     authorID,
			Title:            "Pending community post",
			Category:         enum.PostCategoryGuide,
			Status:           enum.PostStatusPublished,
			ModerationStatus: enum.ModerationStatusPending,
			Revision:         7,
			CommunityID:      &communityID,
			PublishedAt:      &publishedAt,
		},
		community:           postUseCaseCommunity(communityID, enum.CommunityPostingPolicyMembersAfterModeration),
		communityMembership: postUseCaseMembership(communityID, actorID, enum.CommunityMembershipRoleAdmin),
	}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: actorID}, "https://posts.test")

	_, err := useCase.ReviewCommunityPost(context.Background(), "subject-1", postID, ReviewCommunityPostInput{
		CommunityID: communityID,
		Decision:    "reject",
		Reason:      "Off-topic commercial post",
	})
	if err != nil {
		t.Fatalf("ReviewCommunityPost returned error: %v", err)
	}
	if repo.moderationDecision == nil {
		t.Fatal("ReviewCommunityPost did not record moderation decision")
	}
	if repo.moderationDecision.ID == uuid.Nil {
		t.Fatal("decision ID is nil")
	}
	if repo.moderationDecision.PostID != postID {
		t.Fatalf("PostID = %s, want %s", repo.moderationDecision.PostID, postID)
	}
	if repo.moderationDecision.CommunityID != communityID {
		t.Fatalf("CommunityID = %s, want %s", repo.moderationDecision.CommunityID, communityID)
	}
	if repo.moderationDecision.ModeratorUserID != actorID {
		t.Fatalf("ModeratorUserID = %s, want %s", repo.moderationDecision.ModeratorUserID, actorID)
	}
	if repo.moderationDecision.Decision != enum.PostModerationDecisionReject {
		t.Fatalf("Decision = %q, want REJECT", repo.moderationDecision.Decision)
	}
	if repo.moderationDecision.PreviousStatus != enum.ModerationStatusPending {
		t.Fatalf("PreviousStatus = %q, want PENDING", repo.moderationDecision.PreviousStatus)
	}
	if repo.moderationDecision.NextStatus != enum.ModerationStatusRejected {
		t.Fatalf("NextStatus = %q, want REJECTED", repo.moderationDecision.NextStatus)
	}
	if repo.moderationDecision.PostRevision != 7 {
		t.Fatalf("PostRevision = %d, want 7", repo.moderationDecision.PostRevision)
	}
	if repo.moderationDecision.Reason != "Off-topic commercial post" {
		t.Fatalf("Reason = %q, want trimmed reason", repo.moderationDecision.Reason)
	}
	if repo.moderationDecision.CreatedAt.IsZero() {
		t.Fatal("CreatedAt is zero")
	}
}

func TestListCommunityPostModerationDecisionsRequiresModeratorRole(t *testing.T) {
	actorID := uuid.New()
	authorID := uuid.New()
	communityID := uuid.New()
	postID := uuid.New()
	repo := &postUseCaseRepositoryStub{
		existing: &model.Post{
			ID:               postID,
			AuthorUserID:     authorID,
			Status:           enum.PostStatusPublished,
			ModerationStatus: enum.ModerationStatusRejected,
			CommunityID:      &communityID,
		},
		community:           postUseCaseCommunity(communityID, enum.CommunityPostingPolicyMembersAfterModeration),
		communityMembership: postUseCaseMembership(communityID, actorID, enum.CommunityMembershipRoleMember),
	}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: actorID}, "https://posts.test")

	_, err := useCase.ListCommunityPostModerationDecisions(context.Background(), "subject-1", ListCommunityPostModerationDecisionsInput{
		CommunityID: communityID,
		PostID:      postID,
	})
	if !errors.Is(err, ErrCommunityModerationDenied) {
		t.Fatalf("ListCommunityPostModerationDecisions error = %v, want %v", err, ErrCommunityModerationDenied)
	}
}

func TestListCommunityPostModerationDecisionsFiltersPostCommunityAndPagination(t *testing.T) {
	actorID := uuid.New()
	authorID := uuid.New()
	communityID := uuid.New()
	postID := uuid.New()
	now := postUseCaseNow()
	repo := &postUseCaseRepositoryStub{
		existing: &model.Post{
			ID:               postID,
			AuthorUserID:     authorID,
			Status:           enum.PostStatusPublished,
			ModerationStatus: enum.ModerationStatusRejected,
			CommunityID:      &communityID,
		},
		community:           postUseCaseCommunity(communityID, enum.CommunityPostingPolicyMembersAfterModeration),
		communityMembership: postUseCaseMembership(communityID, actorID, enum.CommunityMembershipRoleModerator),
		listedModerationDecisions: []*model.PostModerationDecision{{
			ID:              uuid.New(),
			PostID:          postID,
			CommunityID:     communityID,
			ModeratorUserID: actorID,
			Decision:        enum.PostModerationDecisionReject,
			PreviousStatus:  enum.ModerationStatusPending,
			NextStatus:      enum.ModerationStatusRejected,
			PostRevision:    5,
			Reason:          "Off-topic",
			CreatedAt:       now,
		}},
	}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: actorID}, "https://posts.test")

	items, err := useCase.ListCommunityPostModerationDecisions(context.Background(), "subject-1", ListCommunityPostModerationDecisionsInput{
		CommunityID: communityID,
		PostID:      postID,
		Limit:       9,
		Offset:      3,
	})
	if err != nil {
		t.Fatalf("ListCommunityPostModerationDecisions returned error: %v", err)
	}
	if len(items) != 1 {
		t.Fatalf("items length = %d, want 1", len(items))
	}
	if repo.moderationDecisionFilter.CommunityID != communityID {
		t.Fatalf("CommunityID filter = %s, want %s", repo.moderationDecisionFilter.CommunityID, communityID)
	}
	if repo.moderationDecisionFilter.PostID != postID {
		t.Fatalf("PostID filter = %s, want %s", repo.moderationDecisionFilter.PostID, postID)
	}
	if repo.moderationDecisionFilter.Limit != 9 || repo.moderationDecisionFilter.Offset != 3 {
		t.Fatalf("pagination filter = limit %d offset %d, want 9/3", repo.moderationDecisionFilter.Limit, repo.moderationDecisionFilter.Offset)
	}
}

func TestSubmitPostReportCreatesReportAndAutoHidesAtThreshold(t *testing.T) {
	reporterID := uuid.New()
	authorID := uuid.New()
	postID := uuid.New()
	communityID := uuid.New()
	post := &model.Post{
		ID:               postID,
		AuthorUserID:     authorID,
		Title:            "Unsafe post",
		Status:           enum.PostStatusPublished,
		ModerationStatus: enum.ModerationStatusApproved,
		CommunityID:      &communityID,
		MediaStatus:      enum.PostMediaStatusReady,
		Revision:         4,
	}
	hidden := *post
	hidden.ModerationStatus = enum.ModerationStatusHidden
	hidden.Revision = 5
	repo := &postUseCaseRepositoryStub{
		existing: post,
		reportResult: &model.PostReportSubmissionResult{
			Report: &model.PostReport{
				ID:             uuid.New(),
				PostID:         postID,
				CommunityID:    &communityID,
				ReporterUserID: reporterID,
				AuthorUserID:   authorID,
				Reason:         enum.PostReportReasonSpam,
				Status:         enum.PostReportStatusOpen,
			},
			Post:             &hidden,
			OpenReportsCount: 3,
			AutoHidden:       true,
		},
	}
	cache := &postFeedCacheFake{}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: reporterID}, "https://posts.test").
		WithPostFeedCache(cache, time.Minute, 30*time.Second)

	result, err := useCase.SubmitPostReport(context.Background(), "subject-1", postID, SubmitPostReportInput{
		Reason:  string(enum.PostReportReasonSpam),
		Details: "Repeated scam links",
	})

	if err != nil {
		t.Fatalf("SubmitPostReport returned error: %v", err)
	}
	if repo.createdReport == nil {
		t.Fatal("CreatePostReport was not called")
	}
	if repo.createdReport.PostID != postID ||
		repo.createdReport.CommunityID == nil ||
		*repo.createdReport.CommunityID != communityID ||
		repo.createdReport.ReporterUserID != reporterID ||
		repo.createdReport.AuthorUserID != authorID ||
		repo.createdReport.Reason != enum.PostReportReasonSpam ||
		repo.createdReport.Details != "Repeated scam links" {
		t.Fatalf("created report = %+v, want post/community/reporter/author/reason/details", repo.createdReport)
	}
	if repo.reportAutoHideThreshold != 3 {
		t.Fatalf("auto hide threshold = %d, want 3", repo.reportAutoHideThreshold)
	}
	if result.OpenReportsCount != 3 || !result.AutoHidden {
		t.Fatalf("report result = %+v, want count 3 and auto hidden", result)
	}
	if result.Post == nil || result.Post.ModerationStatus != enum.ModerationStatusHidden || result.Post.Revision != 5 {
		t.Fatalf("result post = %+v, want hidden revision 5", result.Post)
	}
	if len(repo.trackedFeedEvents) != 1 {
		t.Fatalf("tracked feed events = %d, want post report negative signal", len(repo.trackedFeedEvents))
	}
	event := repo.trackedFeedEvents[0]
	if event.EventType != "report" ||
		event.ViewerUserID == nil ||
		*event.ViewerUserID != reporterID ||
		event.PostID == nil ||
		*event.PostID != postID ||
		event.CommunityID == nil ||
		*event.CommunityID != communityID ||
		event.BlockType != model.FeedBlockTypePostCard ||
		event.Metadata["source"] != "post_report" ||
		event.Metadata["reason"] != string(enum.PostReportReasonSpam) {
		t.Fatalf("post report feed event = %+v, want report signal with report metadata", event)
	}
	if !containsString(cache.bumpedScopes, postFeedCacheViewerScope(reporterID)) {
		t.Fatalf("bumped scopes = %#v, want viewer scope", cache.bumpedScopes)
	}
	if !containsString(cache.bumpedScopes, postFeedCacheFollowingScope(reporterID)) {
		t.Fatalf("bumped scopes = %#v, want following scope", cache.bumpedScopes)
	}
	if !containsString(cache.bumpedScopes, postFeedCacheDiscoveryScope(reporterID)) {
		t.Fatalf("bumped scopes = %#v, want discovery scope", cache.bumpedScopes)
	}
}

func TestSubmitCommunityReportCreatesNegativeFeedSignal(t *testing.T) {
	reporterID := uuid.New()
	communityID := uuid.New()
	now := time.Now().UTC()
	repo := &postUseCaseRepositoryStub{
		community: &model.Community{
			ID:           communityID,
			Slug:         "almaty-housing",
			Title:        "Housing",
			Topic:        "housing",
			LanguageCode: "ru",
			Visibility:   enum.CommunityVisibilityPublic,
			Status:       enum.CommunityStatusActive,
			CreatedAt:    now,
			UpdatedAt:    now,
		},
		communityReportResult: &model.CommunityReportSubmissionResult{
			Report: &model.CommunityReport{
				ID:             uuid.New(),
				CommunityID:    communityID,
				ReporterUserID: reporterID,
				Reason:         enum.PostReportReasonSpam,
				Status:         enum.PostReportStatusOpen,
			},
			OpenReportsCount: 1,
		},
	}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: reporterID}, "https://posts.test")

	result, err := useCase.SubmitCommunityReport(context.Background(), "subject-1", SubmitCommunityReportInput{
		CommunityID: communityID,
		Reason:      string(enum.PostReportReasonSpam),
		Details:     "Spam group",
	})

	if err != nil {
		t.Fatalf("SubmitCommunityReport returned error: %v", err)
	}
	if result == nil || result.OpenReportsCount != 1 {
		t.Fatalf("community report result = %+v, want one open report", result)
	}
	if repo.createdCommunityReport == nil ||
		repo.createdCommunityReport.CommunityID != communityID ||
		repo.createdCommunityReport.ReporterUserID != reporterID ||
		repo.createdCommunityReport.Reason != enum.PostReportReasonSpam {
		t.Fatalf("created community report = %+v, want reporter/community/reason", repo.createdCommunityReport)
	}
	if len(repo.trackedFeedEvents) != 1 {
		t.Fatalf("tracked feed events = %d, want community report negative signal", len(repo.trackedFeedEvents))
	}
	event := repo.trackedFeedEvents[0]
	if event.EventType != model.FeedEventTypeHide ||
		event.ViewerUserID == nil ||
		*event.ViewerUserID != reporterID ||
		event.PostID != nil ||
		event.CommunityID == nil ||
		*event.CommunityID != communityID ||
		event.BlockType != model.FeedBlockTypeSuggestedCommunities ||
		event.Metadata["entityType"] != model.FeedInterestEntityTypeCommunity ||
		event.Metadata["entityId"] != communityID.String() ||
		event.Metadata["source"] != "community_report" {
		t.Fatalf("community report feed event = %+v, want community hide signal", event)
	}
}

func TestMuteCommunityCreatesNegativeFeedSignal(t *testing.T) {
	userID := uuid.New()
	communityID := uuid.New()
	now := time.Now().UTC()
	repo := &postUseCaseRepositoryStub{
		community: &model.Community{
			ID:           communityID,
			Slug:         "almaty-housing",
			Title:        "Housing",
			Topic:        "housing",
			LanguageCode: "ru",
			Visibility:   enum.CommunityVisibilityPublic,
			Status:       enum.CommunityStatusActive,
			CreatedAt:    now,
			UpdatedAt:    now,
		},
		communityMembership: &model.CommunityMembership{
			CommunityID: communityID,
			UserID:      userID,
			Status:      enum.CommunityMembershipStatusMuted,
		},
	}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: userID}, "https://posts.test")

	if _, err := useCase.MuteCommunity(context.Background(), "subject-1", communityID); err != nil {
		t.Fatalf("MuteCommunity returned error: %v", err)
	}
	if repo.mutedCommunityID != communityID || repo.mutedUserID != userID || !repo.muted {
		t.Fatalf("mute call = community %s user %s muted %v, want requested mute", repo.mutedCommunityID, repo.mutedUserID, repo.muted)
	}
	if len(repo.trackedFeedEvents) != 1 {
		t.Fatalf("tracked feed events = %d, want community mute negative signal", len(repo.trackedFeedEvents))
	}
	event := repo.trackedFeedEvents[0]
	if event.EventType != model.FeedEventTypeHide ||
		event.ViewerUserID == nil ||
		*event.ViewerUserID != userID ||
		event.PostID != nil ||
		event.CommunityID == nil ||
		*event.CommunityID != communityID ||
		event.BlockType != model.FeedBlockTypeSuggestedCommunities ||
		event.Metadata["entityType"] != model.FeedInterestEntityTypeCommunity ||
		event.Metadata["entityId"] != communityID.String() ||
		event.Metadata["source"] != "community_mute" {
		t.Fatalf("community mute feed event = %+v, want community hide signal", event)
	}
}

func TestSubmitPostReportRejectsOwnPost(t *testing.T) {
	authorID := uuid.New()
	postID := uuid.New()
	repo := &postUseCaseRepositoryStub{
		existing: &model.Post{
			ID:               postID,
			AuthorUserID:     authorID,
			Status:           enum.PostStatusPublished,
			ModerationStatus: enum.ModerationStatusApproved,
			MediaStatus:      enum.PostMediaStatusReady,
		},
	}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: authorID}, "https://posts.test")

	_, err := useCase.SubmitPostReport(context.Background(), "subject-1", postID, SubmitPostReportInput{
		Reason: string(enum.PostReportReasonSpam),
	})

	if !errors.Is(err, ErrPostReportOwnContent) {
		t.Fatalf("SubmitPostReport error = %v, want ErrPostReportOwnContent", err)
	}
	if repo.createdReport != nil {
		t.Fatal("CreatePostReport should not be called for own post")
	}
}

func TestListCommunityPostReportsRequiresModeratorRole(t *testing.T) {
	actorID := uuid.New()
	authorID := uuid.New()
	postID := uuid.New()
	communityID := uuid.New()
	now := postUseCaseNow()
	repo := &postUseCaseRepositoryStub{
		community:           postUseCaseCommunity(communityID, enum.CommunityPostingPolicyMembersAfterModeration),
		communityMembership: postUseCaseMembership(communityID, actorID, enum.CommunityMembershipRoleModerator),
		listedReports: []*model.PostReport{{
			ID:             uuid.New(),
			PostID:         postID,
			CommunityID:    &communityID,
			ReporterUserID: uuid.New(),
			AuthorUserID:   authorID,
			Reason:         enum.PostReportReasonHarassment,
			Status:         enum.PostReportStatusOpen,
			CreatedAt:      now,
		}},
	}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: actorID}, "https://posts.test")

	items, err := useCase.ListCommunityPostReports(context.Background(), "subject-1", ListCommunityPostReportsInput{
		CommunityID: communityID,
		Status:      string(enum.PostReportStatusOpen),
		Limit:       7,
		Offset:      2,
	})

	if err != nil {
		t.Fatalf("ListCommunityPostReports returned error: %v", err)
	}
	if len(items) != 1 {
		t.Fatalf("items length = %d, want 1", len(items))
	}
	if repo.reportListFilter.CommunityID != communityID ||
		repo.reportListFilter.Status == nil ||
		*repo.reportListFilter.Status != enum.PostReportStatusOpen ||
		repo.reportListFilter.Limit != 7 ||
		repo.reportListFilter.Offset != 2 {
		t.Fatalf("report list filter = %+v, want community/status/limit/offset", repo.reportListFilter)
	}
}

func TestListCommunityPostReportsRejectsInvalidStatus(t *testing.T) {
	actorID := uuid.New()
	communityID := uuid.New()
	repo := &postUseCaseRepositoryStub{
		community:           postUseCaseCommunity(communityID, enum.CommunityPostingPolicyMembersAfterModeration),
		communityMembership: postUseCaseMembership(communityID, actorID, enum.CommunityMembershipRoleModerator),
	}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: actorID}, "https://posts.test")

	_, err := useCase.ListCommunityPostReports(context.Background(), "subject-1", ListCommunityPostReportsInput{
		CommunityID: communityID,
		Status:      "invalid",
	})

	if !errors.Is(err, ErrInvalidPostReportStatus) {
		t.Fatalf("ListCommunityPostReports error = %v, want ErrInvalidPostReportStatus", err)
	}
}

func TestResolveCommunityPostReportDismissesOpenReport(t *testing.T) {
	actorID := uuid.New()
	reporterID := uuid.New()
	authorID := uuid.New()
	postID := uuid.New()
	reportID := uuid.New()
	communityID := uuid.New()
	resolvedAt := postUseCaseNow()
	repo := &postUseCaseRepositoryStub{
		community:           postUseCaseCommunity(communityID, enum.CommunityPostingPolicyMembersAfterModeration),
		communityMembership: postUseCaseMembership(communityID, actorID, enum.CommunityMembershipRoleModerator),
		resolvedReportResult: &model.PostReport{
			ID:               reportID,
			PostID:           postID,
			CommunityID:      &communityID,
			ReporterUserID:   reporterID,
			AuthorUserID:     authorID,
			Reason:           enum.PostReportReasonHarassment,
			Status:           enum.PostReportStatusDismissed,
			ResolvedByUserID: &actorID,
			ResolutionNote:   "No policy violation",
			ResolvedAt:       &resolvedAt,
		},
	}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: actorID}, "https://posts.test")

	result, err := useCase.ResolveCommunityPostReport(context.Background(), "subject-1", ResolveCommunityPostReportInput{
		CommunityID:    communityID,
		ReportID:       reportID,
		Decision:       "dismiss",
		ResolutionNote: " No policy violation ",
	})

	if err != nil {
		t.Fatalf("ResolveCommunityPostReport returned error: %v", err)
	}
	if repo.resolvedReportInput == nil {
		t.Fatal("ResolvePostReport was not called")
	}
	if repo.resolvedReportInput.ReportID != reportID ||
		repo.resolvedReportInput.CommunityID != communityID ||
		repo.resolvedReportInput.Status != enum.PostReportStatusDismissed ||
		repo.resolvedReportInput.ResolvedByUserID != actorID ||
		repo.resolvedReportInput.ResolutionNote != "No policy violation" {
		t.Fatalf("resolution input = %+v, want dismissed report by moderator", repo.resolvedReportInput)
	}
	if result == nil || result.Status != enum.PostReportStatusDismissed || result.ResolutionNote != "No policy violation" {
		t.Fatalf("resolved report = %+v, want dismissed report", result)
	}
}

func TestResolveCommunityPostReportRequiresModeratorRole(t *testing.T) {
	actorID := uuid.New()
	communityID := uuid.New()
	repo := &postUseCaseRepositoryStub{
		community:           postUseCaseCommunity(communityID, enum.CommunityPostingPolicyMembersAfterModeration),
		communityMembership: postUseCaseMembership(communityID, actorID, enum.CommunityMembershipRoleMember),
	}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: actorID}, "https://posts.test")

	_, err := useCase.ResolveCommunityPostReport(context.Background(), "subject-1", ResolveCommunityPostReportInput{
		CommunityID:    communityID,
		ReportID:       uuid.New(),
		Decision:       "review",
		ResolutionNote: "Escalated",
	})

	if !errors.Is(err, ErrCommunityModerationDenied) {
		t.Fatalf("ResolveCommunityPostReport error = %v, want ErrCommunityModerationDenied", err)
	}
	if repo.resolvedReportInput != nil {
		t.Fatal("ResolvePostReport should not be called without moderator role")
	}
}

func TestResolveCommunityPostReportRejectsAlreadyResolvedReport(t *testing.T) {
	actorID := uuid.New()
	communityID := uuid.New()
	repo := &postUseCaseRepositoryStub{
		community:           postUseCaseCommunity(communityID, enum.CommunityPostingPolicyMembersAfterModeration),
		communityMembership: postUseCaseMembership(communityID, actorID, enum.CommunityMembershipRoleAdmin),
		resolveReportErr:    port.ErrPostReportAlreadyResolved,
	}
	useCase := NewPostUseCase(repo, postUseCaseUserClientStub{userID: actorID}, "https://posts.test")

	_, err := useCase.ResolveCommunityPostReport(context.Background(), "subject-1", ResolveCommunityPostReportInput{
		CommunityID:    communityID,
		ReportID:       uuid.New(),
		Decision:       "review",
		ResolutionNote: "Reviewed",
	})

	if !errors.Is(err, ErrPostReportAlreadyResolved) {
		t.Fatalf("ResolveCommunityPostReport error = %v, want ErrPostReportAlreadyResolved", err)
	}
}

type countingPostRepository struct {
	port.PostRepository
	count    int
	authorID uuid.UUID
}

func (r *countingPostRepository) CountPublishedPostsByAuthorID(
	_ context.Context,
	authorID uuid.UUID,
) (int, error) {
	r.authorID = authorID
	return r.count, nil
}

type postUseCaseRepositoryStub struct {
	port.PostRepository
	existing                      *model.Post
	created                       *model.Post
	createdStory                  *model.Story
	updated                       *model.Post
	listedPosts                   []*model.Post
	listedStories                 []*model.Story
	listFilter                    model.PostListFilter
	storyListFilter               model.StoryListFilter
	moderationDecision            *model.PostModerationDecision
	listedModerationDecisions     []*model.PostModerationDecision
	moderationDecisionFilter      model.PostModerationDecisionListFilter
	createdReport                 *model.PostReport
	reportResult                  *model.PostReportSubmissionResult
	reportAutoHideThreshold       int
	createdCommunityReport        *model.CommunityReport
	communityReportResult         *model.CommunityReportSubmissionResult
	listedReports                 []*model.PostReport
	reportListFilter              model.PostReportListFilter
	resolvedReportInput           *model.PostReportResolution
	resolvedReportResult          *model.PostReport
	resolveReportErr              error
	community                     *model.Community
	createdCommunity              *model.Community
	updatedCommunity              *model.Community
	listedCommunities             []*model.Community
	communityListFilter           model.CommunityListFilter
	listedPostProfiles            []*model.CommunityPostProfile
	postProfileListFilter         model.CommunityPostProfileListFilter
	followedCommunityIDs          map[uuid.UUID]bool
	followedCommunityLookupIDs    []uuid.UUID
	communityMembership           *model.CommunityMembership
	comment                       *model.PostComment
	createdComment                *model.PostComment
	createCommentErr              error
	updateErr                     error
	latestCommentLookupCalled     bool
	followCommunityCalled         bool
	likePostCalled                bool
	likeStoryCalled               bool
	likePostChangedSet            bool
	likePostChanged               bool
	likeCommentCalled             bool
	markedPostSeenAt              time.Time
	markedStorySeenAt             time.Time
	seenPosts                     map[uuid.UUID]time.Time
	seenStories                   map[uuid.UUID]time.Time
	postCreateCountSince          int
	postCreateCountAuthorID       uuid.UUID
	postCreateCountWindowStart    time.Time
	oldestPostCreatedAtAfterSince *time.Time
	softDeletedPostID             uuid.UUID
	softDeletedAuthorID           uuid.UUID
	trackedFeedEvents             []model.FeedEvent
	createFeedEventsErr           error
	mutedCommunityID              uuid.UUID
	mutedUserID                   uuid.UUID
	muted                         bool
}

func (r *postUseCaseRepositoryStub) GetPostByID(_ context.Context, postID uuid.UUID) (*model.Post, error) {
	if r.updated != nil && r.updated.ID == postID {
		copy := *r.updated
		return &copy, nil
	}
	if r.created != nil && r.created.ID == postID {
		copy := *r.created
		return &copy, nil
	}
	if r.existing == nil || r.existing.ID != postID {
		return nil, nil
	}
	copy := *r.existing
	return &copy, nil
}

func (r *postUseCaseRepositoryStub) CreatePost(_ context.Context, post *model.Post) error {
	copy := *post
	copy.Media = append([]model.PostMedia(nil), post.Media...)
	r.created = &copy
	return nil
}

func (r *postUseCaseRepositoryStub) CreateStory(_ context.Context, story *model.Story) error {
	copy := *story
	r.createdStory = &copy
	r.listedStories = append(r.listedStories, &copy)
	return nil
}

func (r *postUseCaseRepositoryStub) UpdatePost(_ context.Context, post *model.Post) error {
	copy := *post
	copy.Media = append([]model.PostMedia(nil), post.Media...)
	r.updated = &copy
	return r.updateErr
}

func (r *postUseCaseRepositoryStub) SoftDeletePost(_ context.Context, postID uuid.UUID, authorUserID uuid.UUID) error {
	r.softDeletedPostID = postID
	r.softDeletedAuthorID = authorUserID
	return nil
}

func (r *postUseCaseRepositoryStub) ReviewCommunityPost(_ context.Context, post *model.Post, decision *model.PostModerationDecision) error {
	copy := *post
	r.updated = &copy
	decisionCopy := *decision
	r.moderationDecision = &decisionCopy
	return r.updateErr
}

func (r *postUseCaseRepositoryStub) ListCommunityPostModerationDecisions(_ context.Context, filter model.PostModerationDecisionListFilter) ([]*model.PostModerationDecision, error) {
	r.moderationDecisionFilter = filter
	items := make([]*model.PostModerationDecision, 0, len(r.listedModerationDecisions))
	for _, decision := range r.listedModerationDecisions {
		copy := *decision
		items = append(items, &copy)
	}
	return items, nil
}

func (r *postUseCaseRepositoryStub) CreatePostReport(_ context.Context, report *model.PostReport, autoHideThreshold int) (*model.PostReportSubmissionResult, error) {
	copy := *report
	r.createdReport = &copy
	r.reportAutoHideThreshold = autoHideThreshold
	if r.reportResult != nil {
		resultCopy := *r.reportResult
		if r.reportResult.Report != nil {
			reportCopy := *r.reportResult.Report
			resultCopy.Report = &reportCopy
		}
		if r.reportResult.Post != nil {
			postCopy := *r.reportResult.Post
			resultCopy.Post = &postCopy
		}
		return &resultCopy, nil
	}
	postCopy := *r.existing
	return &model.PostReportSubmissionResult{
		Report:           &copy,
		Post:             &postCopy,
		OpenReportsCount: 1,
		AutoHidden:       false,
	}, nil
}

func (r *postUseCaseRepositoryStub) CreateCommunityReport(_ context.Context, report *model.CommunityReport) (*model.CommunityReportSubmissionResult, error) {
	copy := *report
	r.createdCommunityReport = &copy
	if r.communityReportResult != nil {
		resultCopy := *r.communityReportResult
		if r.communityReportResult.Report != nil {
			reportCopy := *r.communityReportResult.Report
			resultCopy.Report = &reportCopy
		}
		return &resultCopy, nil
	}
	return &model.CommunityReportSubmissionResult{
		Report:           &copy,
		OpenReportsCount: 1,
	}, nil
}

func (r *postUseCaseRepositoryStub) CreateFeedEvents(_ context.Context, events []model.FeedEvent) error {
	if r.createFeedEventsErr != nil {
		return r.createFeedEventsErr
	}
	r.trackedFeedEvents = append(r.trackedFeedEvents, events...)
	return nil
}

func (r *postUseCaseRepositoryStub) ListCommunityPostReports(_ context.Context, filter model.PostReportListFilter) ([]*model.PostReport, error) {
	r.reportListFilter = filter
	items := make([]*model.PostReport, 0, len(r.listedReports))
	for _, report := range r.listedReports {
		copy := *report
		items = append(items, &copy)
	}
	return items, nil
}

func (r *postUseCaseRepositoryStub) GetPostReport(_ context.Context, reportID uuid.UUID) (*model.PostReport, error) {
	for _, report := range r.listedReports {
		if report != nil && report.ID == reportID {
			copy := *report
			return &copy, nil
		}
	}
	return nil, port.ErrPostReportNotFound
}

func (r *postUseCaseRepositoryStub) ResolvePostReport(_ context.Context, resolution *model.PostReportResolution) (*model.PostReport, error) {
	r.resolvedReportInput = resolution
	if r.resolveReportErr != nil {
		return nil, r.resolveReportErr
	}
	if r.resolvedReportResult != nil {
		copy := *r.resolvedReportResult
		return &copy, nil
	}
	resolvedAt := postUseCaseNow()
	return &model.PostReport{
		ID:               resolution.ReportID,
		CommunityID:      &resolution.CommunityID,
		Status:           resolution.Status,
		ResolvedByUserID: &resolution.ResolvedByUserID,
		ResolutionNote:   resolution.ResolutionNote,
		ResolvedAt:       &resolvedAt,
	}, nil
}

func (r *postUseCaseRepositoryStub) ListPosts(_ context.Context, filter model.PostListFilter) ([]*model.Post, error) {
	r.listFilter = filter
	items := make([]*model.Post, 0, len(r.listedPosts))
	for _, post := range r.listedPosts {
		copy := *post
		items = append(items, &copy)
	}
	return items, nil
}

func (r *postUseCaseRepositoryStub) ListStories(_ context.Context, filter model.StoryListFilter) ([]*model.Story, error) {
	r.storyListFilter = filter
	items := make([]*model.Story, 0, len(r.listedStories))
	now := postUseCaseNow()
	for _, story := range r.listedStories {
		if story == nil {
			continue
		}
		isExpired := !story.ExpiresAt.After(now)
		if filter.OnlyExpired && !isExpired {
			continue
		}
		if !filter.IncludeExpired && isExpired {
			continue
		}
		if filter.StoryID != nil && *filter.StoryID != uuid.Nil && story.ID != *filter.StoryID {
			continue
		}
		if filter.AuthorUserID != nil && *filter.AuthorUserID != uuid.Nil && story.AuthorUserID != *filter.AuthorUserID {
			continue
		}
		copy := *story
		items = append(items, &copy)
	}
	if filter.Offset >= len(items) {
		return []*model.Story{}, nil
	}
	end := filter.Offset + filter.Limit
	if filter.Limit <= 0 || end > len(items) {
		end = len(items)
	}
	return items[filter.Offset:end], nil
}

func (r *postUseCaseRepositoryStub) GetCommunityByID(_ context.Context, communityID uuid.UUID) (*model.Community, error) {
	if r.community == nil || r.community.ID != communityID {
		return nil, nil
	}
	copy := *r.community
	return &copy, nil
}

func (r *postUseCaseRepositoryStub) CreateCommunity(_ context.Context, community *model.Community) error {
	copy := *community
	copy.TitleI18n = cloneTestStringMap(community.TitleI18n)
	copy.DescriptionI18n = cloneTestStringMap(community.DescriptionI18n)
	copy.Rules = append([]string(nil), community.Rules...)
	copy.RulesI18n = cloneTestStringSliceMap(community.RulesI18n)
	r.createdCommunity = &copy
	return nil
}

func (r *postUseCaseRepositoryStub) UpdateCommunity(_ context.Context, community *model.Community) error {
	copy := *community
	copy.TitleI18n = cloneTestStringMap(community.TitleI18n)
	copy.DescriptionI18n = cloneTestStringMap(community.DescriptionI18n)
	copy.Rules = append([]string(nil), community.Rules...)
	copy.RulesI18n = cloneTestStringSliceMap(community.RulesI18n)
	r.updatedCommunity = &copy
	r.community = &copy
	return nil
}

func (r *postUseCaseRepositoryStub) ListCommunities(_ context.Context, filter model.CommunityListFilter) ([]*model.Community, error) {
	r.communityListFilter = filter
	items := make([]*model.Community, 0, len(r.listedCommunities))
	for _, community := range r.listedCommunities {
		if community == nil {
			continue
		}
		if filter.PublicOnly && !community.IsPubliclyVisible() {
			continue
		}
		if filter.OnlyFollowedByUserID != nil &&
			*filter.OnlyFollowedByUserID != uuid.Nil &&
			!r.followedCommunityIDs[community.ID] {
			continue
		}
		if search := strings.ToLower(strings.TrimSpace(filter.Search)); search != "" {
			haystack := strings.ToLower(strings.Join([]string{
				community.Title,
				community.Description,
				community.Slug,
				community.Topic,
			}, " "))
			if !strings.Contains(haystack, search) {
				continue
			}
		}
		copy := *community
		items = append(items, &copy)
	}
	return items, nil
}

func (r *postUseCaseRepositoryStub) ListCommunityPostProfiles(_ context.Context, filter model.CommunityPostProfileListFilter) ([]*model.CommunityPostProfile, error) {
	r.postProfileListFilter = filter
	profiles := r.listedPostProfiles
	if profiles == nil {
		profiles = testCommunityPostProfiles()
	}
	items := make([]*model.CommunityPostProfile, 0, len(profiles))
	for _, profile := range profiles {
		if profile == nil {
			continue
		}
		if filter.PostKind != "" && string(profile.PostKind) != filter.PostKind {
			continue
		}
		copy := *profile
		copy.SchemaJSON = append(json.RawMessage(nil), profile.SchemaJSON...)
		copy.ValidationJSON = append(json.RawMessage(nil), profile.ValidationJSON...)
		items = append(items, &copy)
	}
	return items, nil
}

func testCommunityPostProfiles() []*model.CommunityPostProfile {
	return []*model.CommunityPostProfile{
		testCommunityPostProfile(enum.PostProfileArticleV1),
		testCommunityPostProfile(enum.PostProfileQuickPostV1),
		testCommunityPostProfile(enum.PostProfileListingV1),
		testCommunityPostProfile(enum.PostProfileEventAnnouncementV1),
		testCommunityPostProfile(enum.PostProfileQuestionAnswerV1),
		testCommunityPostProfile(enum.PostProfileTripPlanV1),
	}
}

func testCommunityPostProfile(key enum.PostProfileKey) *model.CommunityPostProfile {
	profile := testPostProfileDefaults(key)
	return &model.CommunityPostProfile{
		Key:                  profile.Key,
		Version:              profile.Version,
		PostKind:             profile.Kind,
		ModerationMode:       profile.ModerationMode,
		ActivityCreationMode: profile.ActivityCreationMode,
		ValidationJSON:       testPostProfileValidationJSON(profile.RequiredFields),
	}
}

func testPostProfileDefaults(key enum.PostProfileKey) postProfileDefaults {
	normalized := enum.NormalizePostProfileKey(key)
	switch normalized {
	case enum.PostProfileQuickPostV1:
		return postProfileDefaults{
			Key:                  normalized,
			Version:              1,
			Kind:                 enum.PostKindQuickPost,
			ModerationMode:       enum.ModerationModePublishFirst,
			ActivityCreationMode: enum.ActivityCreationModeDisabled,
			RequiredFields:       []string{"body"},
		}
	case enum.PostProfileListingV1:
		return postProfileDefaults{
			Key:                  normalized,
			Version:              1,
			Kind:                 enum.PostKindListing,
			ModerationMode:       enum.ModerationModePublishFirstWithRiskHold,
			ActivityCreationMode: enum.ActivityCreationModeDisabled,
			RequiredFields:       []string{"title", "body", "location"},
		}
	case enum.PostProfileEventAnnouncementV1:
		return postProfileDefaults{
			Key:                  normalized,
			Version:              1,
			Kind:                 enum.PostKindEventAnnouncement,
			ModerationMode:       enum.ModerationModeTrustedPublishElseReview,
			ActivityCreationMode: enum.ActivityCreationModeRequired,
			RequiredFields:       []string{"title", "starts_at", "location"},
		}
	case enum.PostProfileQuestionAnswerV1:
		return postProfileDefaults{
			Key:                  normalized,
			Version:              1,
			Kind:                 enum.PostKindQuestionAnswer,
			ModerationMode:       enum.ModerationModePublishFirst,
			ActivityCreationMode: enum.ActivityCreationModeDisabled,
			RequiredFields:       []string{"question"},
		}
	case enum.PostProfileTripPlanV1:
		return postProfileDefaults{
			Key:                  normalized,
			Version:              1,
			Kind:                 enum.PostKindTripPlan,
			ModerationMode:       enum.ModerationModePublishFirstWithRiskHold,
			ActivityCreationMode: enum.ActivityCreationModeOptional,
			RequiredFields:       []string{"title", "route", "starts_at", "meeting_point"},
		}
	default:
		return postProfileDefaults{
			Key:                  enum.PostProfileArticleV1,
			Version:              1,
			Kind:                 enum.PostKindArticle,
			ModerationMode:       enum.ModerationModePremoderation,
			ActivityCreationMode: enum.ActivityCreationModeDisabled,
		}
	}
}

func testPostProfileValidationJSON(required []string) json.RawMessage {
	payload, err := json.Marshal(struct {
		Required []string `json:"required"`
	}{Required: required})
	if err != nil {
		panic(err)
	}
	return payload
}

func (r *postUseCaseRepositoryStub) ListFollowedCommunityIDs(_ context.Context, _ uuid.UUID, communityIDs []uuid.UUID) (map[uuid.UUID]bool, error) {
	r.followedCommunityLookupIDs = append([]uuid.UUID(nil), communityIDs...)
	result := make(map[uuid.UUID]bool, len(communityIDs))
	for _, communityID := range communityIDs {
		if r.followedCommunityIDs[communityID] {
			result[communityID] = true
		}
	}
	return result, nil
}

func (r *postUseCaseRepositoryStub) GetCommunityMembership(_ context.Context, communityID uuid.UUID, userID uuid.UUID) (*model.CommunityMembership, error) {
	if r.communityMembership == nil ||
		r.communityMembership.CommunityID != communityID ||
		r.communityMembership.UserID != userID {
		return nil, nil
	}
	copy := *r.communityMembership
	return &copy, nil
}

func (r *postUseCaseRepositoryStub) SetCommunityMuted(_ context.Context, communityID uuid.UUID, userID uuid.UUID, muted bool) (*model.CommunityMembership, error) {
	r.mutedCommunityID = communityID
	r.mutedUserID = userID
	r.muted = muted
	status := enum.CommunityMembershipStatusActive
	if muted {
		status = enum.CommunityMembershipStatusMuted
	}
	membership := &model.CommunityMembership{
		CommunityID: communityID,
		UserID:      userID,
		Status:      status,
	}
	r.communityMembership = membership
	copy := *membership
	return &copy, nil
}

func (r *postUseCaseRepositoryStub) FollowCommunity(_ context.Context, _ uuid.UUID, _ uuid.UUID) (bool, int, error) {
	r.followCommunityCalled = true
	return true, 1, nil
}

func (r *postUseCaseRepositoryStub) LikePost(_ context.Context, _ uuid.UUID, _ uuid.UUID) (bool, int, error) {
	r.likePostCalled = true
	changed := true
	if r.likePostChangedSet {
		changed = r.likePostChanged
	}
	if r.existing == nil {
		return changed, 1, nil
	}
	return changed, r.existing.LikeCount + 1, nil
}

func (r *postUseCaseRepositoryStub) LikeStory(_ context.Context, storyID uuid.UUID, _ uuid.UUID) (bool, int, error) {
	r.likeStoryCalled = true
	for _, story := range r.listedStories {
		if story != nil && story.ID == storyID {
			return true, story.LikeCount + 1, nil
		}
	}
	return true, 1, nil
}

func (r *postUseCaseRepositoryStub) GetLatestActiveCommentByAuthor(_ context.Context, _ uuid.UUID, _ uuid.UUID) (*model.PostComment, error) {
	r.latestCommentLookupCalled = true
	return nil, nil
}

func (r *postUseCaseRepositoryStub) CreateComment(_ context.Context, comment *model.PostComment, _ time.Time) error {
	if r.createCommentErr != nil {
		return r.createCommentErr
	}
	copy := *comment
	r.createdComment = &copy
	return nil
}

func (r *postUseCaseRepositoryStub) GetCommentByID(_ context.Context, postID uuid.UUID, commentID uuid.UUID) (*model.PostComment, error) {
	if r.comment == nil || r.comment.PostID != postID || r.comment.ID != commentID {
		return nil, nil
	}
	copy := *r.comment
	return &copy, nil
}

func (r *postUseCaseRepositoryStub) LikeComment(_ context.Context, _ uuid.UUID, _ uuid.UUID, _ uuid.UUID) (bool, int, error) {
	r.likeCommentCalled = true
	if r.comment == nil {
		return true, 1, nil
	}
	return true, r.comment.LikeCount + 1, nil
}

func (r *postUseCaseRepositoryStub) HasPostLike(_ context.Context, _ uuid.UUID, _ uuid.UUID) (bool, error) {
	return false, nil
}

func (r *postUseCaseRepositoryStub) HasCommentLike(_ context.Context, _ uuid.UUID, _ uuid.UUID) (bool, error) {
	return false, nil
}

func (r *postUseCaseRepositoryStub) ListPostLikesByUser(_ context.Context, postIDs []uuid.UUID, _ uuid.UUID) (map[uuid.UUID]bool, error) {
	likes := make(map[uuid.UUID]bool, len(postIDs))
	return likes, nil
}

func (r *postUseCaseRepositoryStub) ListFeedSocialEdges(
	context.Context,
	uuid.UUID,
	[]uuid.UUID,
) (map[uuid.UUID]model.FeedSocialEdgeSet, error) {
	return map[uuid.UUID]model.FeedSocialEdgeSet{}, nil
}

func (r *postUseCaseRepositoryStub) MarkPostSeen(_ context.Context, _ uuid.UUID, _ uuid.UUID, seenAt time.Time) (time.Time, error) {
	r.markedPostSeenAt = seenAt
	return seenAt, nil
}

func (r *postUseCaseRepositoryStub) MarkStorySeen(_ context.Context, _ uuid.UUID, _ uuid.UUID, seenAt time.Time) (time.Time, error) {
	r.markedStorySeenAt = seenAt
	return seenAt, nil
}

func (r *postUseCaseRepositoryStub) ListPostSeenByUser(_ context.Context, postIDs []uuid.UUID, _ uuid.UUID) (map[uuid.UUID]time.Time, error) {
	seen := make(map[uuid.UUID]time.Time, len(postIDs))
	for _, postID := range postIDs {
		if seenAt := r.seenPosts[postID]; !seenAt.IsZero() {
			seen[postID] = seenAt
		}
	}
	return seen, nil
}

func (r *postUseCaseRepositoryStub) CountPostsCreatedByAuthorSince(_ context.Context, authorID uuid.UUID, since time.Time) (int, error) {
	r.postCreateCountAuthorID = authorID
	r.postCreateCountWindowStart = since
	return r.postCreateCountSince, nil
}

func (r *postUseCaseRepositoryStub) OldestPostCreatedAtByAuthorSince(_ context.Context, _ uuid.UUID, _ time.Time) (*time.Time, error) {
	if r.oldestPostCreatedAtAfterSince == nil {
		return nil, nil
	}
	oldest := *r.oldestPostCreatedAtAfterSince
	return &oldest, nil
}

func (r *postUseCaseRepositoryStub) ListStorySeenByUser(_ context.Context, storyIDs []uuid.UUID, _ uuid.UUID) (map[uuid.UUID]time.Time, error) {
	seen := make(map[uuid.UUID]time.Time, len(storyIDs))
	for _, storyID := range storyIDs {
		if seenAt := r.seenStories[storyID]; !seenAt.IsZero() {
			seen[storyID] = seenAt
		}
	}
	return seen, nil
}

type postUseCaseUserClientStub struct {
	userID           uuid.UUID
	profiles         map[uuid.UUID]PublicUserProfile
	profilesErr      error
	friendUserIDs    map[uuid.UUID]bool
	friendsErr       error
	followingUserIDs map[uuid.UUID]bool
	followingErr     error
}

func (c postUseCaseUserClientStub) ResolveUserIDBySubject(_ context.Context, _ string) (uuid.UUID, error) {
	return c.userID, nil
}

func (c postUseCaseUserClientStub) GetPublicUserProfiles(
	_ context.Context,
	userIDs []uuid.UUID,
) (map[uuid.UUID]PublicUserProfile, error) {
	if c.profilesErr != nil {
		return nil, c.profilesErr
	}
	profiles := make(map[uuid.UUID]PublicUserProfile, len(userIDs))
	for _, userID := range userIDs {
		if c.profiles != nil {
			if profile, ok := c.profiles[userID]; ok {
				profiles[userID] = profile
				continue
			}
		}
		profiles[userID] = PublicUserProfile{UserID: userID}
	}
	return profiles, nil
}

func (c postUseCaseUserClientStub) FilterFriendUserIDs(
	_ context.Context,
	_ uuid.UUID,
	candidateUserIDs []uuid.UUID,
) (map[uuid.UUID]bool, error) {
	if c.friendsErr != nil {
		return nil, c.friendsErr
	}
	result := make(map[uuid.UUID]bool, len(candidateUserIDs))
	for _, userID := range candidateUserIDs {
		if c.friendUserIDs != nil && c.friendUserIDs[userID] {
			result[userID] = true
		}
	}
	return result, nil
}

func (c postUseCaseUserClientStub) FilterFollowingUserIDs(
	_ context.Context,
	_ uuid.UUID,
	candidateUserIDs []uuid.UUID,
) (map[uuid.UUID]bool, error) {
	if c.followingErr != nil {
		return nil, c.followingErr
	}
	result := make(map[uuid.UUID]bool, len(candidateUserIDs))
	for _, userID := range candidateUserIDs {
		if c.followingUserIDs != nil && c.followingUserIDs[userID] {
			result[userID] = true
		}
	}
	return result, nil
}

type postNotificationGatewayStub struct {
	sent      chan port.PostLikeNotificationInput
	storySent chan port.StoryLikeNotificationInput
}

func newPostNotificationGatewayStub() *postNotificationGatewayStub {
	return &postNotificationGatewayStub{
		sent:      make(chan port.PostLikeNotificationInput, 1),
		storySent: make(chan port.StoryLikeNotificationInput, 1),
	}
}

func (s *postNotificationGatewayStub) SendPostLikeNotification(
	_ context.Context,
	input port.PostLikeNotificationInput,
) error {
	s.sent <- input
	return nil
}

func (s *postNotificationGatewayStub) SendStoryLikeNotification(
	_ context.Context,
	input port.StoryLikeNotificationInput,
) error {
	s.storySent <- input
	return nil
}

func (s *postNotificationGatewayStub) take(t *testing.T) port.PostLikeNotificationInput {
	t.Helper()
	select {
	case notification := <-s.sent:
		return notification
	case <-time.After(time.Second):
		t.Fatal("timed out waiting for post notification")
		return port.PostLikeNotificationInput{}
	}
}

func (s *postNotificationGatewayStub) expectNone(t *testing.T) {
	t.Helper()
	select {
	case notification := <-s.sent:
		t.Fatalf("expected no post notification, got %+v", notification)
	case <-time.After(50 * time.Millisecond):
	}
}

func validPublishedCommunityPostInput(t *testing.T, communityID uuid.UUID) CreatePostInput {
	t.Helper()
	coverID := uuid.New()
	placeName := "Almaty"
	return CreatePostInput{
		Title:         "Community post",
		Format:        enum.PostFormatGuide,
		Category:      enum.PostCategoryGuide,
		Status:        enum.PostStatusPublished,
		PublishIntent: true,
		CommunityID:   &communityID,
		CoverFileID:   &coverID,
		PlaceName:     &placeName,
		ContentBlocks: mustPostDocumentJSON(t, model.PostDocument{
			Version: model.PostDocumentVersion,
			Blocks: []model.PostBlock{{
				ID:   "p1",
				Type: model.PostBlockTypeParagraph,
				Text: "Useful community content",
			}},
		}),
	}
}

func postUseCaseCommunity(communityID uuid.UUID, policy enum.CommunityPostingPolicy) *model.Community {
	return &model.Community{
		ID:            communityID,
		Slug:          "community",
		Title:         "Community",
		Topic:         "TRAVEL",
		LanguageCode:  "ru",
		Visibility:    enum.CommunityVisibilityPublic,
		PostingPolicy: policy,
		Status:        enum.CommunityStatusActive,
	}
}

func postUseCaseMembership(communityID uuid.UUID, userID uuid.UUID, role enum.CommunityMembershipRole) *model.CommunityMembership {
	return &model.CommunityMembership{
		CommunityID: communityID,
		UserID:      userID,
		Role:        role,
		Status:      enum.CommunityMembershipStatusActive,
	}
}

func postUseCaseNow() time.Time {
	return time.Now().UTC().Truncate(time.Second)
}

type postUseCaseMediaBinderStub struct {
	calls    []PostMediaBindingInput
	metadata map[uuid.UUID]postUseCaseMediaMetadata
	err      error
}

type postUseCaseMediaMetadata struct {
	width  int
	height int
}

func (s *postUseCaseMediaBinderStub) BindPostMedia(_ context.Context, input PostMediaBindingInput) (PostMediaBindingResult, error) {
	copied := input
	copied.FileIDs = append([]uuid.UUID(nil), input.FileIDs...)
	if input.PrimaryFileID != nil {
		primary := *input.PrimaryFileID
		copied.PrimaryFileID = &primary
	}
	s.calls = append(s.calls, copied)
	if s.err != nil {
		return PostMediaBindingResult{}, s.err
	}

	result := PostMediaBindingResult{
		Files: make(map[uuid.UUID]PostMediaFileMetadata, len(s.metadata)),
	}
	for fileID, metadata := range s.metadata {
		result.Files[fileID] = PostMediaFileMetadata{
			Width:  postIntPtr(metadata.width),
			Height: postIntPtr(metadata.height),
		}
	}
	return result, nil
}

type postRouteReferenceValidatorStub struct {
	calls []PostRouteReferenceValidationInput
	err   error
}

func (s *postRouteReferenceValidatorStub) ValidatePostRouteReference(
	_ context.Context,
	input PostRouteReferenceValidationInput,
) error {
	s.calls = append(s.calls, input)
	return s.err
}

func postIntPtr(v int) *int {
	if v <= 0 {
		return nil
	}
	return &v
}

func assertUUIDSlicesEqual(t testing.TB, got []uuid.UUID, want []uuid.UUID) {
	t.Helper()
	if len(got) != len(want) {
		t.Fatalf("uuid slice length = %d, want %d; got %v", len(got), len(want), got)
	}
	for i := range want {
		if got[i] != want[i] {
			t.Fatalf("uuid slice[%d] = %s, want %s; full slice %v", i, got[i], want[i], got)
		}
	}
}

func assertPostMediaStatuses(t testing.TB, items []model.PostMedia, want enum.PostMediaProcessingStatus) {
	t.Helper()
	if len(items) == 0 {
		t.Fatal("post media is empty")
	}
	for _, item := range items {
		if item.ProcessingStatus != want {
			t.Fatalf("media %s processing status = %q, want %q", item.FileID, item.ProcessingStatus, want)
		}
	}
}

func assertPostMediaDimensions(t testing.TB, items []model.PostMedia, fileID uuid.UUID, wantWidth int, wantHeight int) {
	t.Helper()
	for _, item := range items {
		if item.FileID != fileID {
			continue
		}
		if item.Width == nil || *item.Width != wantWidth {
			t.Fatalf("media %s width = %v, want %d", fileID, item.Width, wantWidth)
		}
		if item.Height == nil || *item.Height != wantHeight {
			t.Fatalf("media %s height = %v, want %d", fileID, item.Height, wantHeight)
		}
		return
	}
	t.Fatalf("media %s was not found", fileID)
}

func mustPostDocumentJSON(t *testing.T, document model.PostDocument) json.RawMessage {
	t.Helper()
	data, err := json.Marshal(document)
	if err != nil {
		t.Fatalf("marshal post document: %v", err)
	}
	return data
}

func routeReferencePostDocumentJSON(t *testing.T, routeID string) json.RawMessage {
	t.Helper()
	return mustPostDocumentJSON(t, model.PostDocument{
		Version: model.PostDocumentVersion,
		Blocks: []model.PostBlock{{
			ID:                   "route-1",
			Type:                 model.PostBlockTypeRouteReference,
			RouteID:              routeID,
			RouteTitle:           "Almaty walking route",
			RouteDescription:     "A calm route through city highlights",
			RouteProfile:         "tourist_walk",
			RouteDistanceMeters:  4200,
			RouteDurationSeconds: 3600,
			RouteStopsCount:      4,
			RouteShareURL:        "https://inflap.app/user-routes/" + routeID,
		}},
	})
}

func postStringPtr(v string) *string {
	return &v
}

func cloneTestStringMap(input map[string]string) map[string]string {
	if input == nil {
		return nil
	}
	out := make(map[string]string, len(input))
	for key, value := range input {
		out[key] = value
	}
	return out
}

func cloneTestStringSliceMap(input map[string][]string) map[string][]string {
	if input == nil {
		return nil
	}
	out := make(map[string][]string, len(input))
	for key, values := range input {
		out[key] = append([]string(nil), values...)
	}
	return out
}

func postRawMessagePtr(v json.RawMessage) *json.RawMessage {
	copied := append(json.RawMessage(nil), v...)
	return &copied
}
