package app

import (
	"context"
	"fmt"
	"regexp"
	"sort"
	"strings"
	"time"
	"unicode"
	"unicode/utf8"

	"github.com/google/uuid"

	"kz/inflap/backend/services/stories-service/internal/domain/enum"
	"kz/inflap/backend/services/stories-service/internal/domain/model"
	"kz/inflap/backend/services/stories-service/internal/domain/port"
)

const (
	maxStoryTitleChars   = 160
	maxStoryContentChars = 2500
	maxCommentBodyChars  = 800
	maxStoryTags         = 8
	maxTagChars          = 32
	defaultListLimit     = 20
	maxListLimit         = 100
	defaultCommentLimit  = 20
	commentCreateWindow  = 3 * time.Hour
)

var (
	nonSlugPattern         = regexp.MustCompile(`[^a-z0-9]+`)
	storyImageMarkerRegexp = regexp.MustCompile(`\[\[story-image:[^\]]+\]\]`)
	storySpacingRegexp     = regexp.MustCompile(`\n{3,}`)
)

type StoryAuthor struct {
	UserID       uuid.UUID
	DisplayName  *string
	AvatarFileID *uuid.UUID
	CountryCode  *string
	Locale       string
	Timezone     string
}

type StoryView struct {
	Story         *model.Story
	Author        StoryAuthor
	LikedByViewer bool
	ShareURL      string
}

type StoryCommentView struct {
	Comment       *model.StoryComment
	Author        StoryAuthor
	Editable      bool
	Deletable     bool
	LikedByViewer bool
	ShareURL      string
}

type StoryDetail struct {
	Story    *StoryView
	Related  []*StoryView
	Comments []*StoryCommentView
}

type CreateStoryInput struct {
	Title            string
	Content          string
	Category         enum.StoryCategory
	Status           enum.StoryStatus
	CoverFileID      *uuid.UUID
	PlaceName        *string
	PlaceCountryCode *string
	PlaceCityID      *string
	Tags             []string
}

type UpdateStoryInput = CreateStoryInput

type ListStoriesInput struct {
	Search      string
	Category    []string
	Place       string
	CountryCode string
	CityID      string
	AuthorID    *uuid.UUID
	Sort        string
	Limit       int
	Offset      int
	IncludeMine bool
}

type StoryUseCase struct {
	repo           port.StoryRepository
	users          UserServiceClient
	storiesBaseURL string
}

func NewStoryUseCase(repo port.StoryRepository, users UserServiceClient, storiesBaseURL string) *StoryUseCase {
	return &StoryUseCase{
		repo:           repo,
		users:          users,
		storiesBaseURL: strings.TrimRight(strings.TrimSpace(storiesBaseURL), "/"),
	}
}

func (u *StoryUseCase) CreateStory(ctx context.Context, subject string, input CreateStoryInput) (*StoryView, error) {
	authorUserID, err := u.requireUserID(ctx, subject)
	if err != nil {
		return nil, err
	}

	story, err := normalizeStoryInput(input)
	if err != nil {
		return nil, err
	}

	now := time.Now().UTC()
	story.ID = uuid.New()
	story.AuthorUserID = authorUserID
	story.Slug = buildStorySlug(story.Title, story.ID)
	story.CreatedAt = now
	story.UpdatedAt = now
	story.ViewHLL = model.NewHyperLogLog().Bytes()
	if story.Status == enum.StoryStatusPublished {
		story.PublishedAt = &now
	}

	if err = u.repo.CreateStory(ctx, story); err != nil {
		return nil, fmt.Errorf("create story: %w", err)
	}

	return u.GetStoryByID(ctx, subject, story.ID)
}

func (u *StoryUseCase) UpdateStory(ctx context.Context, subject string, storyID uuid.UUID, input UpdateStoryInput) (*StoryView, error) {
	actorUserID, err := u.requireUserID(ctx, subject)
	if err != nil {
		return nil, err
	}
	if storyID == uuid.Nil {
		return nil, ErrInvalidStoryID
	}

	existing, err := u.repo.GetStoryByID(ctx, storyID)
	if err != nil {
		return nil, fmt.Errorf("get story: %w", err)
	}
	if existing == nil || existing.DeletedAt != nil {
		return nil, ErrStoryNotFound
	}
	if !existing.IsOwnedBy(actorUserID) {
		return nil, ErrStoryAccessDenied
	}

	next, err := normalizeStoryInput(input)
	if err != nil {
		return nil, err
	}

	existing.Title = next.Title
	existing.Excerpt = next.Excerpt
	existing.Content = next.Content
	existing.Category = next.Category
	existing.Status = next.Status
	existing.CoverFileID = next.CoverFileID
	existing.PlaceName = next.PlaceName
	existing.PlaceCountryCode = next.PlaceCountryCode
	existing.PlaceCityID = next.PlaceCityID
	existing.Tags = next.Tags
	existing.Slug = buildStorySlug(next.Title, existing.ID)
	existing.UpdatedAt = time.Now().UTC()
	if existing.Status == enum.StoryStatusPublished && existing.PublishedAt == nil {
		now := time.Now().UTC()
		existing.PublishedAt = &now
	}

	if err = u.repo.UpdateStory(ctx, existing); err != nil {
		return nil, fmt.Errorf("update story: %w", err)
	}

	return u.GetStoryByID(ctx, subject, storyID)
}

func (u *StoryUseCase) DeleteStory(ctx context.Context, subject string, storyID uuid.UUID) error {
	actorUserID, err := u.requireUserID(ctx, subject)
	if err != nil {
		return err
	}
	if storyID == uuid.Nil {
		return ErrInvalidStoryID
	}

	if err = u.repo.SoftDeleteStory(ctx, storyID, actorUserID); err != nil {
		return fmt.Errorf("delete story: %w", err)
	}

	return nil
}

func (u *StoryUseCase) GetStoryByID(ctx context.Context, subject string, storyID uuid.UUID) (*StoryView, error) {
	if storyID == uuid.Nil {
		return nil, ErrInvalidStoryID
	}

	viewerUserID, err := u.optionalUserID(ctx, subject)
	if err != nil {
		return nil, err
	}

	story, err := u.repo.GetStoryByID(ctx, storyID)
	if err != nil {
		return nil, fmt.Errorf("get story by id: %w", err)
	}
	if story == nil || story.DeletedAt != nil {
		return nil, ErrStoryNotFound
	}
	if !story.IsPublished() && (viewerUserID == nil || !story.IsOwnedBy(*viewerUserID)) {
		return nil, ErrStoryNotFound
	}

	view, err := u.buildStoryViews(ctx, []*model.Story{story}, viewerUserID)
	if err != nil {
		return nil, err
	}
	if len(view) == 0 {
		return nil, ErrStoryNotFound
	}

	return view[0], nil
}

func (u *StoryUseCase) GetStoryBySlug(ctx context.Context, slug string, subject string) (*StoryDetail, error) {
	story, err := u.repo.GetStoryBySlug(ctx, strings.TrimSpace(slug))
	if err != nil {
		return nil, fmt.Errorf("get story by slug: %w", err)
	}
	if story == nil || !story.IsPublished() {
		return nil, ErrStoryNotFound
	}

	viewerUserID, err := u.optionalUserID(ctx, subject)
	if err != nil {
		return nil, err
	}

	storyViews, err := u.buildStoryViews(ctx, []*model.Story{story}, viewerUserID)
	if err != nil {
		return nil, err
	}
	if len(storyViews) == 0 {
		return nil, ErrStoryNotFound
	}

	relatedStories, err := u.repo.ListStories(ctx, model.StoryListFilter{
		Categories:     []enum.StoryCategory{story.Category},
		ExcludeStoryID: &story.ID,
		OnlyPublished:  true,
		Limit:          3,
		Offset:         0,
		Sort:           "popular",
	})
	if err != nil {
		return nil, fmt.Errorf("list related stories: %w", err)
	}

	relatedViews, err := u.buildStoryViews(ctx, relatedStories, viewerUserID)
	if err != nil {
		return nil, err
	}

	comments, err := u.repo.ListComments(ctx, story.ID, defaultCommentLimit, 0)
	if err != nil {
		return nil, fmt.Errorf("list story comments: %w", err)
	}

	commentViews, err := u.buildCommentViews(ctx, story, comments, viewerUserID)
	if err != nil {
		return nil, err
	}

	return &StoryDetail{
		Story:    storyViews[0],
		Related:  relatedViews,
		Comments: commentViews,
	}, nil
}

func (u *StoryUseCase) ListStories(ctx context.Context, subject string, input ListStoriesInput) ([]*StoryView, error) {
	viewerUserID, err := u.optionalUserID(ctx, subject)
	if err != nil {
		return nil, err
	}

	filter, err := u.normalizeListInput(input, viewerUserID)
	if err != nil {
		return nil, err
	}

	items, err := u.repo.ListStories(ctx, filter)
	if err != nil {
		return nil, fmt.Errorf("list stories: %w", err)
	}

	return u.buildStoryViews(ctx, items, viewerUserID)
}

func (u *StoryUseCase) CountPublishedStoriesByAuthorID(ctx context.Context, authorUserID uuid.UUID) (int, error) {
	if authorUserID == uuid.Nil {
		return 0, ErrInvalidStoryAuthorID
	}

	count, err := u.repo.CountPublishedStoriesByAuthorID(ctx, authorUserID)
	if err != nil {
		return 0, fmt.Errorf("count published stories: %w", err)
	}

	return count, nil
}

func (u *StoryUseCase) TrackStoryView(ctx context.Context, subject string, storyID uuid.UUID) (int, error) {
	viewerUserID, err := u.requireUserID(ctx, subject)
	if err != nil {
		return 0, err
	}
	if storyID == uuid.Nil {
		return 0, ErrInvalidStoryID
	}

	story, err := u.repo.GetStoryByID(ctx, storyID)
	if err != nil {
		return 0, fmt.Errorf("get story for view: %w", err)
	}
	if story == nil || !story.IsPublished() {
		return 0, ErrStoryNotFound
	}
	if story.IsOwnedBy(viewerUserID) {
		return story.ViewCount, nil
	}

	_, count, err := u.repo.TrackStoryView(ctx, storyID, viewerUserID)
	if err != nil {
		return 0, fmt.Errorf("track story view: %w", err)
	}

	return count, nil
}

func (u *StoryUseCase) LikeStory(ctx context.Context, subject string, storyID uuid.UUID) (int, error) {
	viewerUserID, err := u.requireUserID(ctx, subject)
	if err != nil {
		return 0, err
	}
	if storyID == uuid.Nil {
		return 0, ErrInvalidStoryID
	}

	story, err := u.repo.GetStoryByID(ctx, storyID)
	if err != nil {
		return 0, fmt.Errorf("get story for like: %w", err)
	}
	if story == nil || !story.IsPublished() {
		return 0, ErrStoryNotFound
	}

	_, count, err := u.repo.LikeStory(ctx, storyID, viewerUserID)
	if err != nil {
		return 0, fmt.Errorf("like story: %w", err)
	}

	return count, nil
}

func (u *StoryUseCase) UnlikeStory(ctx context.Context, subject string, storyID uuid.UUID) (int, error) {
	viewerUserID, err := u.requireUserID(ctx, subject)
	if err != nil {
		return 0, err
	}
	if storyID == uuid.Nil {
		return 0, ErrInvalidStoryID
	}

	story, err := u.repo.GetStoryByID(ctx, storyID)
	if err != nil {
		return 0, fmt.Errorf("get story for unlike: %w", err)
	}
	if story == nil || !story.IsPublished() {
		return 0, ErrStoryNotFound
	}

	_, count, err := u.repo.UnlikeStory(ctx, storyID, viewerUserID)
	if err != nil {
		return 0, fmt.Errorf("unlike story: %w", err)
	}

	return count, nil
}

func (u *StoryUseCase) ListComments(ctx context.Context, subject string, storyID uuid.UUID, limit int, offset int) ([]*StoryCommentView, error) {
	if storyID == uuid.Nil {
		return nil, ErrInvalidStoryID
	}

	viewerUserID, err := u.optionalUserID(ctx, subject)
	if err != nil {
		return nil, err
	}

	story, err := u.repo.GetStoryByID(ctx, storyID)
	if err != nil {
		return nil, fmt.Errorf("get story for comments: %w", err)
	}
	if story == nil || story.DeletedAt != nil {
		return nil, ErrStoryNotFound
	}
	if !story.IsPublished() && (viewerUserID == nil || !story.IsOwnedBy(*viewerUserID)) {
		return nil, ErrStoryNotFound
	}

	if limit <= 0 || limit > maxListLimit {
		limit = defaultCommentLimit
	}
	if offset < 0 {
		offset = 0
	}

	items, err := u.repo.ListComments(ctx, storyID, limit, offset)
	if err != nil {
		return nil, fmt.Errorf("list comments: %w", err)
	}

	return u.buildCommentViews(ctx, story, items, viewerUserID)
}

func (u *StoryUseCase) CreateComment(ctx context.Context, subject string, storyID uuid.UUID, body string) (*StoryCommentView, error) {
	authorUserID, err := u.requireUserID(ctx, subject)
	if err != nil {
		return nil, err
	}
	if storyID == uuid.Nil {
		return nil, ErrInvalidStoryID
	}

	story, err := u.repo.GetStoryByID(ctx, storyID)
	if err != nil {
		return nil, fmt.Errorf("get story for comment: %w", err)
	}
	if story == nil || !story.IsPublished() {
		return nil, ErrStoryNotFound
	}

	body = strings.TrimSpace(body)
	if body == "" || utf8.RuneCountInString(body) > maxCommentBodyChars {
		return nil, ErrInvalidCommentBody
	}

	now := time.Now().UTC()
	latestComment, err := u.repo.GetLatestActiveCommentByAuthor(ctx, storyID, authorUserID)
	if err != nil {
		return nil, fmt.Errorf("get latest author comment: %w", err)
	}
	if latestComment != nil && latestComment.CreatedAt.Add(commentCreateWindow).After(now) {
		return nil, ErrStoryCommentRateLimited
	}

	comment := &model.StoryComment{
		ID:           uuid.New(),
		StoryID:      storyID,
		AuthorUserID: authorUserID,
		Body:         body,
		CreatedAt:    now,
		UpdatedAt:    now,
	}

	if err = u.repo.CreateComment(ctx, comment); err != nil {
		return nil, fmt.Errorf("create comment: %w", err)
	}

	views, err := u.buildCommentViews(ctx, story, []*model.StoryComment{comment}, &authorUserID)
	if err != nil {
		return nil, err
	}
	return views[0], nil
}

func (u *StoryUseCase) UpdateComment(ctx context.Context, subject string, storyID uuid.UUID, commentID uuid.UUID, body string) (*StoryCommentView, error) {
	actorUserID, err := u.requireUserID(ctx, subject)
	if err != nil {
		return nil, err
	}
	if storyID == uuid.Nil {
		return nil, ErrInvalidStoryID
	}
	if commentID == uuid.Nil {
		return nil, ErrInvalidCommentID
	}

	comment, err := u.repo.GetCommentByID(ctx, storyID, commentID)
	if err != nil {
		return nil, fmt.Errorf("get comment: %w", err)
	}
	if comment == nil || comment.DeletedAt != nil {
		return nil, ErrStoryCommentNotFound
	}
	if !comment.IsOwnedBy(actorUserID) {
		return nil, ErrStoryCommentAccessDenied
	}

	body = strings.TrimSpace(body)
	if body == "" || utf8.RuneCountInString(body) > maxCommentBodyChars {
		return nil, ErrInvalidCommentBody
	}

	comment.Body = body
	comment.UpdatedAt = time.Now().UTC()

	if err = u.repo.UpdateComment(ctx, comment); err != nil {
		return nil, fmt.Errorf("update comment: %w", err)
	}

	story, err := u.repo.GetStoryByID(ctx, storyID)
	if err != nil {
		return nil, fmt.Errorf("get story for comment update: %w", err)
	}

	views, err := u.buildCommentViews(ctx, story, []*model.StoryComment{comment}, &actorUserID)
	if err != nil {
		return nil, err
	}
	return views[0], nil
}

func (u *StoryUseCase) DeleteComment(ctx context.Context, subject string, storyID uuid.UUID, commentID uuid.UUID) error {
	actorUserID, err := u.requireUserID(ctx, subject)
	if err != nil {
		return err
	}
	if storyID == uuid.Nil {
		return ErrInvalidStoryID
	}
	if commentID == uuid.Nil {
		return ErrInvalidCommentID
	}

	story, err := u.repo.GetStoryByID(ctx, storyID)
	if err != nil {
		return fmt.Errorf("get story for comment delete: %w", err)
	}
	if story == nil || story.DeletedAt != nil {
		return ErrStoryNotFound
	}

	comment, err := u.repo.GetCommentByID(ctx, storyID, commentID)
	if err != nil {
		return fmt.Errorf("get comment for delete: %w", err)
	}
	if comment == nil || comment.DeletedAt != nil {
		return ErrStoryCommentNotFound
	}
	if !comment.IsOwnedBy(actorUserID) {
		return ErrStoryCommentAccessDenied
	}

	if _, err = u.repo.DeleteComment(ctx, storyID, commentID); err != nil {
		return fmt.Errorf("delete comment: %w", err)
	}

	return nil
}

func (u *StoryUseCase) LikeComment(ctx context.Context, subject string, storyID uuid.UUID, commentID uuid.UUID) (int, bool, error) {
	viewerUserID, err := u.requireUserID(ctx, subject)
	if err != nil {
		return 0, false, err
	}
	if storyID == uuid.Nil {
		return 0, false, ErrInvalidStoryID
	}
	if commentID == uuid.Nil {
		return 0, false, ErrInvalidCommentID
	}

	story, err := u.repo.GetStoryByID(ctx, storyID)
	if err != nil {
		return 0, false, fmt.Errorf("get story for comment like: %w", err)
	}
	if story == nil || !story.IsPublished() {
		return 0, false, ErrStoryNotFound
	}

	comment, err := u.repo.GetCommentByID(ctx, storyID, commentID)
	if err != nil {
		return 0, false, fmt.Errorf("get comment for like: %w", err)
	}
	if comment == nil || comment.DeletedAt != nil {
		return 0, false, ErrStoryCommentNotFound
	}

	_, count, err := u.repo.LikeComment(ctx, storyID, commentID, viewerUserID)
	if err != nil {
		return 0, false, fmt.Errorf("like comment: %w", err)
	}

	return count, true, nil
}

func (u *StoryUseCase) UnlikeComment(ctx context.Context, subject string, storyID uuid.UUID, commentID uuid.UUID) (int, bool, error) {
	viewerUserID, err := u.requireUserID(ctx, subject)
	if err != nil {
		return 0, false, err
	}
	if storyID == uuid.Nil {
		return 0, false, ErrInvalidStoryID
	}
	if commentID == uuid.Nil {
		return 0, false, ErrInvalidCommentID
	}

	story, err := u.repo.GetStoryByID(ctx, storyID)
	if err != nil {
		return 0, false, fmt.Errorf("get story for comment unlike: %w", err)
	}
	if story == nil || !story.IsPublished() {
		return 0, false, ErrStoryNotFound
	}

	comment, err := u.repo.GetCommentByID(ctx, storyID, commentID)
	if err != nil {
		return 0, false, fmt.Errorf("get comment for unlike: %w", err)
	}
	if comment == nil || comment.DeletedAt != nil {
		return 0, false, ErrStoryCommentNotFound
	}

	_, count, err := u.repo.UnlikeComment(ctx, storyID, commentID, viewerUserID)
	if err != nil {
		return 0, false, fmt.Errorf("unlike comment: %w", err)
	}

	return count, false, nil
}

func (u *StoryUseCase) ShareStory(ctx context.Context, storyID uuid.UUID) (string, int, error) {
	if storyID == uuid.Nil {
		return "", 0, ErrInvalidStoryID
	}

	story, err := u.repo.GetStoryByID(ctx, storyID)
	if err != nil {
		return "", 0, fmt.Errorf("get story for share: %w", err)
	}
	if story == nil || !story.IsPublished() {
		return "", 0, ErrStoryNotFound
	}

	count, err := u.repo.IncrementShareCount(ctx, storyID)
	if err != nil {
		return "", 0, fmt.Errorf("increment share count: %w", err)
	}

	return u.shareURL(story.Slug), count, nil
}

func (u *StoryUseCase) normalizeListInput(input ListStoriesInput, viewerUserID *uuid.UUID) (model.StoryListFilter, error) {
	placeQuery, placeCountryCode := normalizePlaceFilters(input.Place)
	if explicitCountryCode := normalizeCountryCode(input.CountryCode); explicitCountryCode != "" {
		placeCountryCode = explicitCountryCode
	}

	filter := model.StoryListFilter{
		Search:           strings.TrimSpace(input.Search),
		PlaceQuery:       placeQuery,
		PlaceCountryCode: placeCountryCode,
		PlaceCityID:      strings.TrimSpace(input.CityID),
		AuthorUserID:     input.AuthorID,
		ViewerUserID:     viewerUserID,
		IncludeDrafts:    false,
		OnlyPublished:    true,
		Limit:            input.Limit,
		Offset:           input.Offset,
	}

	if filter.Limit <= 0 {
		filter.Limit = defaultListLimit
	}
	if filter.Limit > maxListLimit {
		filter.Limit = maxListLimit
	}
	if filter.Offset < 0 {
		filter.Offset = 0
	}

	switch strings.ToLower(strings.TrimSpace(input.Sort)) {
	case "", "latest", "latest_desc":
		filter.Sort = "latest_desc"
	case "latest_asc":
		filter.Sort = "latest_asc"
	case "popular", "popular_desc":
		filter.Sort = "popular_desc"
	case "popular_asc":
		filter.Sort = "popular_asc"
	case "discussed", "discussed_desc":
		filter.Sort = "discussed_desc"
	case "discussed_asc":
		filter.Sort = "discussed_asc"
	default:
		filter.Sort = "latest_desc"
	}

	filter.Categories = make([]enum.StoryCategory, 0, len(input.Category))
	for _, raw := range input.Category {
		category := enum.StoryCategory(strings.ToUpper(strings.TrimSpace(raw)))
		if category == "" {
			continue
		}
		if !category.IsValid() {
			return model.StoryListFilter{}, ErrInvalidStoryCategory
		}
		filter.Categories = append(filter.Categories, category)
	}

	if input.IncludeMine {
		if viewerUserID == nil || *viewerUserID == uuid.Nil {
			return model.StoryListFilter{}, ErrUnauthenticatedWriter
		}
		filter.AuthorUserID = viewerUserID
		filter.IncludeDrafts = true
		filter.OnlyPublished = false
	}

	return filter, nil
}

func normalizePlaceFilters(raw string) (placeQuery string, placeCountryCode string) {
	trimmed := strings.TrimSpace(raw)
	if trimmed == "" {
		return "", ""
	}

	if looksLikeCountryCode(trimmed) {
		return "", strings.ToUpper(trimmed)
	}

	return trimmed, ""
}

func looksLikeCountryCode(value string) bool {
	if utf8.RuneCountInString(value) != 2 {
		return false
	}

	for _, r := range value {
		if r > unicode.MaxASCII || !unicode.IsLetter(r) {
			return false
		}
	}

	return true
}

func normalizeStoryInput(input CreateStoryInput) (*model.Story, error) {
	title := strings.TrimSpace(input.Title)
	if title == "" || utf8.RuneCountInString(title) > maxStoryTitleChars {
		return nil, ErrInvalidStoryTitle
	}

	category := enum.StoryCategory(strings.ToUpper(strings.TrimSpace(string(input.Category))))
	if !category.IsValid() {
		return nil, ErrInvalidStoryCategory
	}

	status := enum.StoryStatus(strings.ToUpper(strings.TrimSpace(string(input.Status))))
	if status == "" {
		status = enum.StoryStatusDraft
	}
	if !status.IsValid() {
		return nil, ErrInvalidStoryStatus
	}

	content := strings.TrimSpace(input.Content)
	visibleContent := visibleStoryContent(content)
	if utf8.RuneCountInString(visibleContent) > maxStoryContentChars {
		return nil, ErrInvalidStoryContent
	}
	if status == enum.StoryStatusPublished && visibleContent == "" {
		return nil, ErrInvalidStoryContent
	}

	placeName := trimOptionalString(input.PlaceName)
	if status == enum.StoryStatusPublished && placeName == nil {
		return nil, ErrInvalidStoryPlace
	}

	if status == enum.StoryStatusPublished && input.CoverFileID == nil {
		return nil, ErrInvalidStoryCover
	}

	tags, err := sanitizeTags(input.Tags)
	if err != nil {
		return nil, err
	}

	return &model.Story{
		Title:            title,
		Excerpt:          buildExcerpt(content, title),
		Content:          content,
		Category:         category,
		Status:           status,
		CoverFileID:      input.CoverFileID,
		PlaceName:        placeName,
		PlaceCountryCode: trimOptionalString(input.PlaceCountryCode),
		PlaceCityID:      trimOptionalString(input.PlaceCityID),
		Tags:             tags,
	}, nil
}

func normalizeCountryCode(raw string) string {
	trimmed := strings.TrimSpace(raw)
	if trimmed == "" || !looksLikeCountryCode(trimmed) {
		return ""
	}
	return strings.ToUpper(trimmed)
}

func sanitizeTags(tags []string) ([]string, error) {
	if len(tags) == 0 {
		return []string{}, nil
	}

	seen := make(map[string]struct{}, len(tags))
	result := make([]string, 0, len(tags))

	for _, tag := range tags {
		tag = strings.TrimSpace(tag)
		if tag == "" {
			continue
		}
		if utf8.RuneCountInString(tag) > maxTagChars {
			return nil, ErrInvalidStoryTags
		}

		key := strings.ToLower(tag)
		if _, exists := seen[key]; exists {
			continue
		}
		seen[key] = struct{}{}
		result = append(result, tag)
	}

	if len(result) > maxStoryTags {
		return nil, ErrInvalidStoryTags
	}

	if result == nil {
		return []string{}, nil
	}

	return result, nil
}

func buildExcerpt(content string, title string) string {
	source := visibleStoryContent(content)
	if source == "" {
		source = strings.TrimSpace(title)
	}
	if utf8.RuneCountInString(source) <= 180 {
		return source
	}

	runes := []rune(source)
	return strings.TrimSpace(string(runes[:180])) + "..."
}

func visibleStoryContent(content string) string {
	cleaned := storyImageMarkerRegexp.ReplaceAllString(content, "\n\n")
	cleaned = strings.ReplaceAll(cleaned, "\r\n", "\n")
	cleaned = storySpacingRegexp.ReplaceAllString(cleaned, "\n\n")
	return strings.TrimSpace(cleaned)
}

func buildStorySlug(title string, storyID uuid.UUID) string {
	title = strings.ToLower(strings.TrimSpace(title))
	title = strings.Map(func(r rune) rune {
		switch {
		case unicode.IsLetter(r), unicode.IsDigit(r):
			if r > unicode.MaxASCII {
				return '-'
			}
			return r
		case unicode.IsSpace(r), r == '-', r == '_':
			return '-'
		default:
			return '-'
		}
	}, title)
	title = nonSlugPattern.ReplaceAllString(title, "-")
	title = strings.Trim(title, "-")
	if title == "" {
		title = "story"
	}

	suffix := strings.ReplaceAll(storyID.String()[:8], "-", "")
	return fmt.Sprintf("%s-%s", title, suffix)
}

func trimOptionalString(v *string) *string {
	if v == nil {
		return nil
	}
	trimmed := strings.TrimSpace(*v)
	if trimmed == "" {
		return nil
	}
	return &trimmed
}

func (u *StoryUseCase) requireUserID(ctx context.Context, subject string) (uuid.UUID, error) {
	subject = strings.TrimSpace(subject)
	if subject == "" {
		return uuid.Nil, ErrUnauthenticatedWriter
	}

	userID, err := u.users.ResolveUserIDBySubject(ctx, subject)
	if err != nil {
		if err == ErrUserNotFound {
			return uuid.Nil, err
		}
		return uuid.Nil, fmt.Errorf("resolve user by subject: %w", err)
	}
	return userID, nil
}

func (u *StoryUseCase) optionalUserID(ctx context.Context, subject string) (*uuid.UUID, error) {
	subject = strings.TrimSpace(subject)
	if subject == "" {
		return nil, nil
	}

	userID, err := u.users.ResolveUserIDBySubject(ctx, subject)
	if err != nil {
		if err == ErrUserNotFound {
			return nil, nil
		}
		return nil, fmt.Errorf("resolve optional user by subject: %w", err)
	}

	return &userID, nil
}

func (u *StoryUseCase) buildStoryViews(ctx context.Context, stories []*model.Story, viewerUserID *uuid.UUID) ([]*StoryView, error) {
	if len(stories) == 0 {
		return []*StoryView{}, nil
	}

	authorIDs := make([]uuid.UUID, 0, len(stories))
	seen := make(map[uuid.UUID]struct{}, len(stories))
	for _, story := range stories {
		if story == nil {
			continue
		}
		if _, exists := seen[story.AuthorUserID]; exists {
			continue
		}
		seen[story.AuthorUserID] = struct{}{}
		authorIDs = append(authorIDs, story.AuthorUserID)
	}
	sort.Slice(authorIDs, func(i, j int) bool { return authorIDs[i].String() < authorIDs[j].String() })

	profiles, err := u.users.GetPublicUserProfiles(ctx, authorIDs)
	if err != nil {
		return nil, fmt.Errorf("get public story author profiles: %w", err)
	}

	items := make([]*StoryView, 0, len(stories))
	for _, story := range stories {
		if story == nil {
			continue
		}
		author := toStoryAuthor(story.AuthorUserID, profiles[story.AuthorUserID])
		likedByViewer := false
		if viewerUserID != nil && *viewerUserID != uuid.Nil {
			likedByViewer, err = u.repo.HasStoryLike(ctx, story.ID, *viewerUserID)
			if err != nil {
				return nil, fmt.Errorf("check viewer like: %w", err)
			}
		}

		items = append(items, &StoryView{
			Story:         story,
			Author:        author,
			LikedByViewer: likedByViewer,
			ShareURL:      u.shareURL(story.Slug),
		})
	}

	return items, nil
}

func (u *StoryUseCase) buildCommentViews(
	ctx context.Context,
	story *model.Story,
	comments []*model.StoryComment,
	viewerUserID *uuid.UUID,
) ([]*StoryCommentView, error) {
	if len(comments) == 0 {
		return []*StoryCommentView{}, nil
	}

	authorIDs := make([]uuid.UUID, 0, len(comments))
	seen := make(map[uuid.UUID]struct{}, len(comments))
	for _, comment := range comments {
		if comment == nil {
			continue
		}
		if _, exists := seen[comment.AuthorUserID]; exists {
			continue
		}
		seen[comment.AuthorUserID] = struct{}{}
		authorIDs = append(authorIDs, comment.AuthorUserID)
	}

	profiles, err := u.users.GetPublicUserProfiles(ctx, authorIDs)
	if err != nil {
		return nil, fmt.Errorf("get public comment author profiles: %w", err)
	}

	items := make([]*StoryCommentView, 0, len(comments))
	for _, comment := range comments {
		if comment == nil {
			continue
		}
		editable := false
		deletable := false
		likedByViewer := false
		if viewerUserID != nil && *viewerUserID != uuid.Nil {
			editable = comment.IsOwnedBy(*viewerUserID)
			deletable = editable
			likedByViewer, err = u.repo.HasCommentLike(ctx, comment.ID, *viewerUserID)
			if err != nil {
				return nil, fmt.Errorf("check viewer comment like: %w", err)
			}
		}

		items = append(items, &StoryCommentView{
			Comment:       comment,
			Author:        toStoryAuthor(comment.AuthorUserID, profiles[comment.AuthorUserID]),
			Editable:      editable,
			Deletable:     deletable,
			LikedByViewer: likedByViewer,
			ShareURL:      u.shareCommentURL(story, comment.ID),
		})
	}

	return items, nil
}

func toStoryAuthor(userID uuid.UUID, profile PublicUserProfile) StoryAuthor {
	return StoryAuthor{
		UserID:       userID,
		DisplayName:  profile.DisplayName,
		AvatarFileID: profile.AvatarFileID,
		CountryCode:  profile.CountryCode,
		Locale:       profile.Locale,
		Timezone:     profile.Timezone,
	}
}

func (u *StoryUseCase) shareURL(slug string) string {
	if u.storiesBaseURL == "" {
		return ""
	}
	return u.storiesBaseURL + "/" + strings.TrimLeft(strings.TrimSpace(slug), "/")
}

func (u *StoryUseCase) shareCommentURL(story *model.Story, commentID uuid.UUID) string {
	if story == nil || commentID == uuid.Nil {
		return ""
	}
	base := u.shareURL(story.Slug)
	if base == "" {
		return ""
	}
	return base + "?comment=" + commentID.String()
}
