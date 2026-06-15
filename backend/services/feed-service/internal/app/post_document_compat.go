package app

import (
	"fmt"
	"regexp"
	"strings"
	"unicode"

	"github.com/google/uuid"

	"kz/inflap/backend/services/feed-service/internal/domain/model"
)

var legacyPostContentParagraphSplitRegexp = regexp.MustCompile(`(?:\r?\n[ \t]*){2,}`)

const legacyPostImageMarkerPrefix = "[[post-image:"
const legacyPostImageMarkerSuffix = "]]"

// LegacyPostContentToDocument converts marker-based legacy post content into
// the structured document format used by the content engine.
func LegacyPostContentToDocument(postID uuid.UUID, content string) (model.PostDocument, error) {
	document := model.PostDocument{
		Version: model.PostDocumentVersion,
		Blocks:  make([]model.PostBlock, 0),
	}

	normalizedContent := strings.ReplaceAll(content, "\r\n", "\n")
	normalizedContent = strings.ReplaceAll(normalizedContent, "\r", "\n")
	sections := legacyPostContentParagraphSplitRegexp.Split(normalizedContent, -1)

	for _, section := range sections {
		trimmed := strings.TrimSpace(section)
		if trimmed == "" {
			continue
		}

		blockID := legacyPostDocumentBlockID(postID, len(document.Blocks)+1)
		if fileID, ok := parseLegacyPostImageMarker(trimmed); ok {
			document.Blocks = append(document.Blocks, model.PostBlock{
				ID:     blockID,
				Type:   model.PostBlockTypeImage,
				FileID: fileID,
			})
			continue
		}

		document.Blocks = append(document.Blocks, model.PostBlock{
			ID:   blockID,
			Type: model.PostBlockTypeParagraph,
			Text: trimmed,
		})
	}

	if err := document.Validate(); err != nil {
		return document, fmt.Errorf("validate legacy post document: %w", err)
	}
	return document, nil
}

func legacyPostDocumentBlockID(postID uuid.UUID, blockOrder int) string {
	return fmt.Sprintf("legacy-%s-%06d", postID.String(), blockOrder)
}

func parseLegacyPostImageMarker(value string) (string, bool) {
	if !strings.HasPrefix(value, legacyPostImageMarkerPrefix) || !strings.HasSuffix(value, legacyPostImageMarkerSuffix) {
		return "", false
	}

	rawFileID := strings.TrimSuffix(strings.TrimPrefix(value, legacyPostImageMarkerPrefix), legacyPostImageMarkerSuffix)
	fileID, ok := normalizeLegacyPostFileID(rawFileID)
	if !ok {
		return "", false
	}
	return fileID, true
}

func normalizeLegacyPostFileID(fileID string) (string, bool) {
	normalized := strings.TrimSpace(fileID)
	if normalized == "" || len([]rune(normalized)) > model.PostDocumentMaxFileIDLength {
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
