package app

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
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
	defaultRelatedLimit  = 3
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
	Nickname     *string
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
	Title               string
	Content             string
	Format              enum.StoryFormat
	ContentBlocks       json.RawMessage
	Category            enum.StoryCategory
	Status              enum.StoryStatus
	PublishIntent       bool
	AllowArchivedStatus bool
	Revision            int64
	CoverFileID         *uuid.UUID
	PlaceName           *string
	PlaceCountryCode    *string
	PlaceCityID         *string
	Tags                []string
}

type UpdateStoryInput struct {
	Title               *string
	Content             *string
	Format              *enum.StoryFormat
	ContentBlocks       *json.RawMessage
	Category            *enum.StoryCategory
	Status              *enum.StoryStatus
	PublishIntent       bool
	AllowArchivedStatus bool
	Revision            int64
	CoverFileID         *uuid.UUID
	CoverFileIDSet      bool
	PlaceName           *string
	PlaceNameSet        bool
	PlaceCountryCode    *string
	PlaceCountryCodeSet bool
	PlaceCityID         *string
	PlaceCityIDSet      bool
	Tags                []string
	TagsSet             bool
}

type ListStoriesInput struct {
	Search      string
	Format      []string
	Category    []string
	Status      string
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

	storyID := uuid.New()
	story, err := normalizeStoryInput(storyID, input)
	if err != nil {
		return nil, err
	}

	now := time.Now().UTC()
	story.ID = storyID
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
	return u.updateOwnedStory(ctx, subject, storyID, input.Revision, func(*model.Story) (UpdateStoryInput, error) {
		return input, nil
	}, nil)
}

func (u *StoryUseCase) AutosaveStory(ctx context.Context, subject string, storyID uuid.UUID, input UpdateStoryInput) (*StoryView, error) {
	return u.updateOwnedStory(ctx, subject, storyID, input.Revision, func(existing *model.Story) (UpdateStoryInput, error) {
		return input, nil
	}, func(story *model.Story, now time.Time) {
		story.LastAutosavedAt = &now
	})
}

func (u *StoryUseCase) PublishStory(ctx context.Context, subject string, storyID uuid.UUID, revision int64) (*StoryView, error) {
	return u.updateOwnedStory(ctx, subject, storyID, revision, func(existing *model.Story) (UpdateStoryInput, error) {
		status := enum.StoryStatusPublished
		input := UpdateStoryInput{Status: &status}
		input.PublishIntent = true
		return input, nil
	}, nil)
}

func (u *StoryUseCase) ArchiveStory(ctx context.Context, subject string, storyID uuid.UUID, revision int64) (*StoryView, error) {
	return u.updateOwnedStory(ctx, subject, storyID, revision, func(existing *model.Story) (UpdateStoryInput, error) {
		status := enum.StoryStatusArchived
		return UpdateStoryInput{Status: &status, AllowArchivedStatus: true}, nil
	}, func(story *model.Story, now time.Time) {
		story.ArchivedAt = &now
	})
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
	if !story.IsPubliclyVisible() && (viewerUserID == nil || !story.IsOwnedBy(*viewerUserID)) {
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
	if story == nil || !story.IsPubliclyVisible() {
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

	relatedStories, err := u.repo.ListStories(ctx, relatedStoriesFilterFor(story))
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

func (u *StoryUseCase) CountStories(ctx context.Context, subject string, input ListStoriesInput) (int, error) {
	viewerUserID, err := u.optionalUserID(ctx, subject)
	if err != nil {
		return 0, err
	}

	filter, err := u.normalizeListInput(input, viewerUserID)
	if err != nil {
		return 0, err
	}

	count, err := u.repo.CountStories(ctx, filter)
	if err != nil {
		return 0, fmt.Errorf("count stories: %w", err)
	}
	return count, nil
}

func relatedStoriesFilterFor(story *model.Story) model.StoryListFilter {
	if story == nil {
		return model.StoryListFilter{
			OnlyPublished: true,
			Limit:         defaultRelatedLimit,
			Sort:          "popular_desc",
		}
	}

	filter := model.StoryListFilter{
		ExcludeStoryID: &story.ID,
		OnlyPublished:  true,
		Limit:          defaultRelatedLimit,
		Offset:         0,
		Sort:           "related",
		RelatedToCountry: strings.ToUpper(
			strings.TrimSpace(derefString(story.PlaceCountryCode)),
		),
		RelatedToCityID: strings.TrimSpace(derefString(story.PlaceCityID)),
		RelatedToTags:   sanitizeRelatedTags(story.Tags),
	}
	if story.AuthorUserID != uuid.Nil {
		filter.RelatedToAuthor = &story.AuthorUserID
	}

	format := enum.NormalizeStoryFormat(story.Format)
	if format.IsValid() {
		filter.RelatedToFormat = &format
	}
	if story.Category.IsValid() {
		category := story.Category
		filter.RelatedToCategory = &category
	}

	return filter
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
	if story == nil || !story.IsPubliclyVisible() {
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
	if story == nil || !story.IsPubliclyVisible() {
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
	if story == nil || !story.IsPubliclyVisible() {
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
	if !story.IsPubliclyVisible() && (viewerUserID == nil || !story.IsOwnedBy(*viewerUserID)) {
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
	if story == nil || !story.IsPubliclyVisible() {
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
	if story == nil || !story.IsPubliclyVisible() {
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
	if story == nil || !story.IsPubliclyVisible() {
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
	if story == nil || !story.IsPubliclyVisible() {
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

	filter.Formats = make([]enum.StoryFormat, 0, len(input.Format))
	for _, raw := range input.Format {
		format := enum.NormalizeStoryFormat(enum.StoryFormat(raw))
		if strings.TrimSpace(raw) == "" {
			continue
		}
		if !format.IsValid() {
			return model.StoryListFilter{}, ErrInvalidStoryFormat
		}
		filter.Formats = append(filter.Formats, format)
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
		filter.ExcludeArchived = true
	}

	switch strings.ToUpper(strings.TrimSpace(input.Status)) {
	case "":
	case "ARCHIVED":
		filter.ArchivedOnly = true
		filter.ExcludeArchived = false
		if input.IncludeMine {
			filter.OnlyPublished = false
		}
	case string(enum.StoryStatusDraft):
		status := enum.StoryStatusDraft
		filter.Status = &status
		if input.IncludeMine {
			filter.OnlyPublished = false
		}
	case string(enum.StoryStatusPublished):
		status := enum.StoryStatusPublished
		filter.Status = &status
	default:
		return model.StoryListFilter{}, ErrInvalidStoryStatus
	}

	return filter, nil
}

func (u *StoryUseCase) updateOwnedStory(
	ctx context.Context,
	subject string,
	storyID uuid.UUID,
	revision int64,
	inputForExisting func(*model.Story) (UpdateStoryInput, error),
	mutate func(*model.Story, time.Time),
) (*StoryView, error) {
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
	if revision <= 0 {
		return nil, ErrStoryRevisionConflict
	}

	input, err := inputForExisting(existing)
	if err != nil {
		return nil, err
	}
	input.Revision = revision

	mergedInput := mergeStoryUpdateInput(existing, input)
	next, err := normalizeStoryInput(existing.ID, mergedInput)
	if err != nil {
		return nil, err
	}

	applyStoryUpdate(existing, next, revision, existing.ModerationStatus)
	now := time.Now().UTC()
	existing.UpdatedAt = now
	if mutate != nil {
		mutate(existing, now)
	}
	if existing.Status == enum.StoryStatusPublished && existing.PublishedAt == nil {
		existing.PublishedAt = &now
	}

	if err = u.repo.UpdateStory(ctx, existing); err != nil {
		if errors.Is(err, port.ErrStoryRevisionConflict) {
			return nil, ErrStoryRevisionConflict
		}
		return nil, fmt.Errorf("update story: %w", err)
	}

	return u.GetStoryByID(ctx, subject, storyID)
}

func applyStoryUpdate(existing *model.Story, next *model.Story, revision int64, moderationStatus enum.ModerationStatus) {
	existing.Title = next.Title
	existing.Excerpt = next.Excerpt
	existing.Content = next.Content
	existing.Format = next.Format
	existing.ContentSchemaVersion = next.ContentSchemaVersion
	existing.ContentBlocks = next.ContentBlocks
	existing.ContentPlainText = next.ContentPlainText
	existing.Category = next.Category
	existing.Status = next.Status
	existing.Revision = revision
	existing.ModerationStatus = moderationStatus
	existing.CoverFileID = next.CoverFileID
	existing.PlaceName = next.PlaceName
	existing.PlaceCountryCode = next.PlaceCountryCode
	existing.PlaceCityID = next.PlaceCityID
	existing.Tags = next.Tags
	existing.Slug = buildStorySlug(next.Title, existing.ID)
}

func storyInputFromExisting(story *model.Story) CreateStoryInput {
	if story == nil {
		return CreateStoryInput{}
	}
	return CreateStoryInput{
		Title:            story.Title,
		Content:          story.Content,
		Format:           story.Format,
		ContentBlocks:    append(json.RawMessage(nil), story.ContentBlocks...),
		Category:         story.Category,
		Status:           story.Status,
		CoverFileID:      story.CoverFileID,
		PlaceName:        story.PlaceName,
		PlaceCountryCode: story.PlaceCountryCode,
		PlaceCityID:      story.PlaceCityID,
		Tags:             append([]string(nil), story.Tags...),
	}
}

func mergeStoryUpdateInput(story *model.Story, input UpdateStoryInput) CreateStoryInput {
	merged := storyInputFromExisting(story)
	if input.Title != nil {
		merged.Title = *input.Title
	}
	if input.Content != nil {
		merged.Content = *input.Content
		if input.ContentBlocks == nil {
			merged.ContentBlocks = nil
		}
	}
	if input.Format != nil {
		merged.Format = *input.Format
	}
	if input.ContentBlocks != nil {
		merged.ContentBlocks = append(json.RawMessage(nil), (*input.ContentBlocks)...)
	}
	if input.Category != nil {
		merged.Category = *input.Category
	}
	if input.Status != nil {
		merged.Status = *input.Status
	}
	merged.PublishIntent = input.PublishIntent
	merged.AllowArchivedStatus = input.AllowArchivedStatus
	merged.Revision = input.Revision
	if input.CoverFileIDSet {
		merged.CoverFileID = input.CoverFileID
	}
	if input.PlaceNameSet {
		merged.PlaceName = input.PlaceName
	}
	if input.PlaceCountryCodeSet {
		merged.PlaceCountryCode = input.PlaceCountryCode
	}
	if input.PlaceCityIDSet {
		merged.PlaceCityID = input.PlaceCityID
	}
	if input.TagsSet {
		merged.Tags = append([]string(nil), input.Tags...)
	}
	return merged
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

func normalizeStoryInput(storyID uuid.UUID, input CreateStoryInput) (*model.Story, error) {
	title := strings.TrimSpace(input.Title)
	if utf8.RuneCountInString(title) > maxStoryTitleChars {
		return nil, ErrInvalidStoryTitle
	}

	format := enum.NormalizeStoryFormat(input.Format)
	if !format.IsValid() {
		return nil, ErrInvalidStoryContent
	}

	category := enum.StoryCategory(strings.ToUpper(strings.TrimSpace(string(input.Category))))
	if category != "" && !category.IsValid() {
		return nil, ErrInvalidStoryCategory
	}

	status := enum.StoryStatus(strings.ToUpper(strings.TrimSpace(string(input.Status))))
	if status == "" {
		status = enum.StoryStatusDraft
	}
	if input.PublishIntent {
		status = enum.StoryStatusPublished
	}
	if !status.IsValid() {
		return nil, ErrInvalidStoryStatus
	}
	if status == enum.StoryStatusArchived && !input.AllowArchivedStatus {
		return nil, ErrInvalidStoryStatus
	}

	document, contentBlocks, err := normalizeStoryDocumentInput(storyID, input.ContentBlocks, input.Content)
	if err != nil {
		return nil, ErrInvalidStoryContent
	}

	contentPlainText := strings.TrimSpace(document.PlainText())
	content := strings.TrimSpace(document.LegacyContent())
	hasPublishableContent := !document.IsEmptyForPublish()
	if utf8.RuneCountInString(visibleStoryContent(content)) > maxStoryContentChars {
		return nil, ErrInvalidStoryContent
	}
	if status != enum.StoryStatusPublished && title == "" && !hasPublishableContent {
		return nil, ErrInvalidStoryContent
	}

	placeName := trimOptionalString(input.PlaceName)
	if status == enum.StoryStatusPublished {
		if err := validatePublishableStory(title, category, placeName, input.CoverFileID, hasPublishableContent); err != nil {
			return nil, err
		}
	}

	tags, err := sanitizeTags(input.Tags)
	if err != nil {
		return nil, err
	}

	return &model.Story{
		Title:                title,
		Excerpt:              buildExcerpt(content, title),
		Content:              content,
		Format:               format,
		ContentSchemaVersion: model.StoryDocumentVersion,
		ContentBlocks:        contentBlocks,
		ContentPlainText:     contentPlainText,
		Category:             category,
		Status:               status,
		ModerationStatus:     enum.ModerationStatusNotRequired,
		Revision:             1,
		CoverFileID:          input.CoverFileID,
		PlaceName:            placeName,
		PlaceCountryCode:     trimOptionalString(input.PlaceCountryCode),
		PlaceCityID:          trimOptionalString(input.PlaceCityID),
		Tags:                 tags,
	}, nil
}

func validatePublishableStory(
	title string,
	category enum.StoryCategory,
	placeName *string,
	coverFileID *uuid.UUID,
	hasPublishableContent bool,
) error {
	fields := make(map[string]string, 5)
	causes := make([]error, 0, 5)
	if title == "" {
		fields["title"] = "required_for_publish"
		causes = append(causes, ErrInvalidStoryTitle)
	}
	if !category.IsValid() {
		fields["category"] = "required_for_publish"
		causes = append(causes, ErrInvalidStoryCategory)
	}
	if placeName == nil {
		fields["placeName"] = "required_for_publish"
		causes = append(causes, ErrInvalidStoryPlace)
	}
	if coverFileID == nil {
		fields["coverFileId"] = "required_for_publish"
		causes = append(causes, ErrInvalidStoryCover)
	}
	if !hasPublishableContent {
		fields["contentBlocks"] = "required_for_publish"
		causes = append(causes, ErrInvalidStoryContent)
	}
	if len(fields) == 0 {
		return nil
	}
	return NewStoryValidationError(fields, causes...)
}

func normalizeStoryDocumentInput(
	storyID uuid.UUID,
	contentBlocks json.RawMessage,
	legacyContent string,
) (model.StoryDocument, json.RawMessage, error) {
	var document model.StoryDocument

	if len(contentBlocks) > 0 {
		trimmedContentBlocks := bytes.TrimSpace(contentBlocks)
		if len(trimmedContentBlocks) > 0 && trimmedContentBlocks[0] == '[' {
			var blocks []model.StoryBlock
			if err := json.Unmarshal(trimmedContentBlocks, &blocks); err != nil {
				return model.StoryDocument{}, nil, err
			}
			document = model.StoryDocument{
				Version: model.StoryDocumentVersion,
				Blocks:  blocks,
			}
		} else {
			if err := json.Unmarshal(trimmedContentBlocks, &document); err != nil {
				return model.StoryDocument{}, nil, err
			}
		}
		if err := document.Validate(); err != nil {
			return model.StoryDocument{}, nil, err
		}
		normalizedContentBlocks, err := marshalStoryDocument(document)
		return document, normalizedContentBlocks, err
	}

	document, err := LegacyStoryContentToDocument(storyID, legacyContent)
	if err != nil {
		return model.StoryDocument{}, nil, err
	}
	normalizedContentBlocks, err := marshalStoryDocument(document)
	return document, normalizedContentBlocks, err
}

func marshalStoryDocument(document model.StoryDocument) (json.RawMessage, error) {
	data, err := json.Marshal(document)
	if err != nil {
		return nil, err
	}
	return json.RawMessage(data), nil
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

func sanitizeRelatedTags(tags []string) []string {
	if len(tags) == 0 {
		return nil
	}
	seen := make(map[string]struct{}, len(tags))
	result := make([]string, 0, len(tags))
	for _, tag := range tags {
		normalized := strings.ToLower(strings.TrimSpace(tag))
		if normalized == "" {
			continue
		}
		if _, exists := seen[normalized]; exists {
			continue
		}
		seen[normalized] = struct{}{}
		result = append(result, normalized)
	}
	if len(result) == 0 {
		return nil
	}
	return result
}

func derefString(value *string) string {
	if value == nil {
		return ""
	}
	return *value
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
		Nickname:     profile.Nickname,
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
