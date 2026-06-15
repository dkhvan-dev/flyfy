package app

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"strings"

	"github.com/google/uuid"

	"kz/inflap/backend/services/feed-service/internal/domain/enum"
	"kz/inflap/backend/services/feed-service/internal/domain/model"
)

type PostMediaBinder interface {
	BindPostMedia(ctx context.Context, input PostMediaBindingInput) (PostMediaBindingResult, error)
}

type PostMediaBindingInput struct {
	PostID        uuid.UUID
	ActorUserID   uuid.UUID
	FileIDs       []uuid.UUID
	PrimaryFileID *uuid.UUID
}

type PostMediaBindingResult struct {
	Files map[uuid.UUID]PostMediaFileMetadata
}

type PostMediaFileMetadata struct {
	Width           *int
	Height          *int
	DurationMS      *int
	ThumbnailFileID *uuid.UUID
}

func (u *PostUseCase) bindPostMedia(ctx context.Context, actorUserID uuid.UUID, post *model.Post) error {
	plan, err := buildPostMediaPlan(post, actorUserID)
	if err != nil {
		return err
	}
	_, err = u.bindPostMediaPlan(ctx, plan)
	return err
}

func (u *PostUseCase) bindPostMediaPlan(ctx context.Context, plan postMediaPlan) (postMediaPlan, error) {
	if u.mediaBinder == nil || len(plan.BindingInput.FileIDs) == 0 {
		return plan, nil
	}

	result, err := u.mediaBinder.BindPostMedia(ctx, plan.BindingInput)
	if err != nil {
		return plan, fmt.Errorf("bind post media: %w", err)
	}
	plan, err = applyPostMediaBindingResult(plan, result)
	if err != nil {
		return plan, err
	}
	return plan, nil
}

func postMediaBindingInput(post *model.Post, actorUserID uuid.UUID) (PostMediaBindingInput, error) {
	plan, err := buildPostMediaPlan(post, actorUserID)
	if err != nil {
		return PostMediaBindingInput{}, err
	}
	return plan.BindingInput, nil
}

type postMediaPlan struct {
	BindingInput PostMediaBindingInput
	Media        []model.PostMedia
}

func buildPostMediaPlan(post *model.Post, actorUserID uuid.UUID) (postMediaPlan, error) {
	if post == nil || post.ID == uuid.Nil || actorUserID == uuid.Nil {
		return postMediaPlan{}, ErrInvalidPostMedia
	}

	plan := postMediaPlan{
		BindingInput: PostMediaBindingInput{
			PostID:      post.ID,
			ActorUserID: actorUserID,
			FileIDs:     make([]uuid.UUID, 0, 4),
		},
		Media: make([]model.PostMedia, 0, 4),
	}
	seen := make(map[uuid.UUID]struct{}, 4)
	position := 0
	addMedia := func(fileID uuid.UUID, mediaType enum.PostMediaType, isPrimary bool, caption string, altText string) {
		if _, exists := seen[fileID]; exists {
			return
		}
		seen[fileID] = struct{}{}
		plan.BindingInput.FileIDs = append(plan.BindingInput.FileIDs, fileID)
		plan.Media = append(plan.Media, model.PostMedia{
			PostID:           post.ID,
			FileID:           fileID,
			MediaType:        mediaType,
			Position:         position,
			IsPrimary:        isPrimary,
			Caption:          strings.TrimSpace(caption),
			AltText:          strings.TrimSpace(altText),
			ProcessingStatus: enum.PostMediaProcessingStatusPendingBind,
		})
		position++
	}

	if post.CoverFileID != nil {
		if *post.CoverFileID == uuid.Nil {
			return postMediaPlan{}, fmt.Errorf("%w: cover file id is empty", ErrInvalidPostMedia)
		}
		primary := *post.CoverFileID
		plan.BindingInput.PrimaryFileID = &primary
		addMedia(primary, enum.PostMediaTypeImage, true, "", post.Title)
	}

	document, err := postDocumentFromNormalizedBlocks(post.ContentBlocks)
	if err != nil {
		return postMediaPlan{}, err
	}
	for _, block := range document.Blocks {
		switch block.Type {
		case model.PostBlockTypeImage:
			fileID, err := parsePostMediaFileID(block.FileID)
			if err != nil {
				return postMediaPlan{}, err
			}
			addMedia(fileID, enum.PostMediaTypeImage, false, "", "")
		case model.PostBlockTypeGallery:
			for _, image := range block.Images {
				fileID, err := parsePostMediaFileID(image.FileID)
				if err != nil {
					return postMediaPlan{}, err
				}
				addMedia(fileID, enum.PostMediaTypeImage, false, "", "")
			}
		}
	}

	return plan, nil
}

func applyPostMediaPlan(post *model.Post, plan postMediaPlan, status enum.PostMediaStatus, processingStatus enum.PostMediaProcessingStatus) {
	if post == nil {
		return
	}
	post.MediaStatus = status
	post.Media = make([]model.PostMedia, 0, len(plan.Media))
	for _, item := range plan.Media {
		item.ProcessingStatus = processingStatus
		post.Media = append(post.Media, item)
	}
}

func applyPostMediaBindingResult(plan postMediaPlan, result PostMediaBindingResult) (postMediaPlan, error) {
	if len(result.Files) == 0 {
		return plan, nil
	}

	for i := range plan.Media {
		metadata, ok := result.Files[plan.Media[i].FileID]
		if !ok {
			continue
		}
		if !validPostMediaMetadata(metadata) {
			return plan, fmt.Errorf("%w: invalid file metadata", ErrInvalidPostMedia)
		}
		plan.Media[i].Width = cloneOptionalInt(metadata.Width)
		plan.Media[i].Height = cloneOptionalInt(metadata.Height)
		plan.Media[i].DurationMS = cloneOptionalInt(metadata.DurationMS)
		plan.Media[i].ThumbnailFileID = cloneOptionalUUID(metadata.ThumbnailFileID)
	}

	return plan, nil
}

func validPostMediaMetadata(metadata PostMediaFileMetadata) bool {
	if !validPositiveOptionalInt(metadata.Width) ||
		!validPositiveOptionalInt(metadata.Height) ||
		!validPositiveOptionalInt(metadata.DurationMS) {
		return false
	}
	return metadata.ThumbnailFileID == nil || *metadata.ThumbnailFileID != uuid.Nil
}

func validPositiveOptionalInt(value *int) bool {
	return value == nil || *value > 0
}

func cloneOptionalInt(value *int) *int {
	if value == nil {
		return nil
	}
	copied := *value
	return &copied
}

func cloneOptionalUUID(value *uuid.UUID) *uuid.UUID {
	if value == nil {
		return nil
	}
	copied := *value
	return &copied
}

func postHasMedia(plan postMediaPlan) bool {
	return len(plan.Media) > 0
}

func postDocumentFromNormalizedBlocks(contentBlocks json.RawMessage) (model.PostDocument, error) {
	if len(bytes.TrimSpace(contentBlocks)) == 0 {
		return model.PostDocument{Version: model.PostDocumentVersion}, nil
	}

	var document model.PostDocument
	if err := json.Unmarshal(contentBlocks, &document); err != nil {
		return model.PostDocument{}, fmt.Errorf("%w: content blocks are malformed", ErrInvalidPostMedia)
	}
	return document, nil
}

func parsePostMediaFileID(raw string) (uuid.UUID, error) {
	fileID, err := uuid.Parse(strings.TrimSpace(raw))
	if err != nil || fileID == uuid.Nil {
		return uuid.Nil, fmt.Errorf("%w: content file id must be uuid", ErrInvalidPostMedia)
	}
	return fileID, nil
}
