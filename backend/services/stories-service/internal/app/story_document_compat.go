package app

import (
	"fmt"
	"regexp"
	"strings"
	"unicode"

	"github.com/google/uuid"

	"kz/inflap/backend/services/stories-service/internal/domain/model"
)

var legacyStoryContentParagraphSplitRegexp = regexp.MustCompile(`(?:\r?\n[ \t]*){2,}`)

const legacyStoryImageMarkerPrefix = "[[story-image:"
const legacyStoryImageMarkerSuffix = "]]"

// LegacyStoryContentToDocument converts marker-based legacy story content into
// the structured document format used by the content engine.
func LegacyStoryContentToDocument(storyID uuid.UUID, content string) (model.StoryDocument, error) {
	document := model.StoryDocument{
		Version: model.StoryDocumentVersion,
		Blocks:  make([]model.StoryBlock, 0),
	}

	normalizedContent := strings.ReplaceAll(content, "\r\n", "\n")
	normalizedContent = strings.ReplaceAll(normalizedContent, "\r", "\n")
	sections := legacyStoryContentParagraphSplitRegexp.Split(normalizedContent, -1)

	for _, section := range sections {
		trimmed := strings.TrimSpace(section)
		if trimmed == "" {
			continue
		}

		blockID := legacyStoryDocumentBlockID(storyID, len(document.Blocks)+1)
		if fileID, ok := parseLegacyStoryImageMarker(trimmed); ok {
			document.Blocks = append(document.Blocks, model.StoryBlock{
				ID:     blockID,
				Type:   model.StoryBlockTypeImage,
				FileID: fileID,
			})
			continue
		}

		document.Blocks = append(document.Blocks, model.StoryBlock{
			ID:   blockID,
			Type: model.StoryBlockTypeParagraph,
			Text: trimmed,
		})
	}

	if err := document.Validate(); err != nil {
		return document, fmt.Errorf("validate legacy story document: %w", err)
	}
	return document, nil
}

func legacyStoryDocumentBlockID(storyID uuid.UUID, blockOrder int) string {
	return fmt.Sprintf("legacy-%s-%06d", storyID.String(), blockOrder)
}

func parseLegacyStoryImageMarker(value string) (string, bool) {
	if !strings.HasPrefix(value, legacyStoryImageMarkerPrefix) || !strings.HasSuffix(value, legacyStoryImageMarkerSuffix) {
		return "", false
	}

	rawFileID := strings.TrimSuffix(strings.TrimPrefix(value, legacyStoryImageMarkerPrefix), legacyStoryImageMarkerSuffix)
	fileID, ok := normalizeLegacyStoryFileID(rawFileID)
	if !ok {
		return "", false
	}
	return fileID, true
}

func normalizeLegacyStoryFileID(fileID string) (string, bool) {
	normalized := strings.TrimSpace(fileID)
	if normalized == "" || len([]rune(normalized)) > model.StoryDocumentMaxFileIDLength {
		return "", false
	}
	if strings.ContainsAny(normalized, "[]:") {
		return "", false
	}
	for _, r := range normalized {
		if unicode.IsControl(r) || unicode.IsSpace(r) {
			return "", false
		}
	}
	return normalized, true
}
