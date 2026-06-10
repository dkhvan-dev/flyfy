package model

import (
	"fmt"
	"net/url"
	"strings"
	"unicode"
)

const (
	StoryDocumentVersion                    = 1
	StoryDocumentMaxBlockCount              = 256
	StoryDocumentMaxTextLength              = 20_000
	StoryDocumentMaxInlineMarksPerTextBlock = 64
	StoryDocumentMaxListItems               = 100
	StoryDocumentMaxListItemTextLength      = 2_000
	StoryDocumentMaxGalleryImages           = 30
	StoryDocumentMaxHeadingLevel            = 6
	StoryDocumentMaxPlaceIDLength           = 128
	StoryDocumentMaxPlaceNameLength         = 300
	StoryDocumentMaxPlaceCountryCodeLength  = 8
	StoryDocumentMaxPlaceCityIDLength       = 128
	StoryDocumentMaxFileIDLength            = 256
	StoryDocumentMaxURLLength               = 2_048
)

type StoryBlockType string

const (
	StoryBlockTypeParagraph      StoryBlockType = "paragraph"
	StoryBlockTypeHeading        StoryBlockType = "heading"
	StoryBlockTypeBulletedList   StoryBlockType = "bulleted_list"
	StoryBlockTypeNumberedList   StoryBlockType = "numbered_list"
	StoryBlockTypeQuote          StoryBlockType = "quote"
	StoryBlockTypeCallout        StoryBlockType = "callout"
	StoryBlockTypeImage          StoryBlockType = "image"
	StoryBlockTypeGallery        StoryBlockType = "gallery"
	StoryBlockTypeDivider        StoryBlockType = "divider"
	StoryBlockTypePlaceReference StoryBlockType = "place_reference"
)

type StoryInlineMarkType string

const (
	StoryInlineMarkTypeBold          StoryInlineMarkType = "bold"
	StoryInlineMarkTypeItalic        StoryInlineMarkType = "italic"
	StoryInlineMarkTypeUnderline     StoryInlineMarkType = "underline"
	StoryInlineMarkTypeStrikethrough StoryInlineMarkType = "strikethrough"
	StoryInlineMarkTypeLink          StoryInlineMarkType = "link"
)

type StoryDocument struct {
	Version int          `json:"version"`
	Blocks  []StoryBlock `json:"blocks"`
}

type StoryBlock struct {
	ID               string              `json:"id"`
	Type             StoryBlockType      `json:"type"`
	Text             string              `json:"text,omitempty"`
	Level            int                 `json:"level,omitempty"`
	Marks            []StoryInlineMark   `json:"marks,omitempty"`
	Items            []StoryListItem     `json:"items,omitempty"`
	FileID           string              `json:"fileId,omitempty"`
	Images           []StoryGalleryImage `json:"images,omitempty"`
	PlaceID          string              `json:"placeId,omitempty"`
	PlaceName        string              `json:"placeName,omitempty"`
	PlaceCountryCode string              `json:"placeCountryCode,omitempty"`
	PlaceCityID      string              `json:"placeCityId,omitempty"`
}

type StoryListItem struct {
	Text  string            `json:"text"`
	Marks []StoryInlineMark `json:"marks,omitempty"`
}

type StoryGalleryImage struct {
	FileID string `json:"fileId"`
}

type StoryInlineMark struct {
	Type  StoryInlineMarkType `json:"type"`
	Start int                 `json:"start,omitempty"`
	End   int                 `json:"end,omitempty"`
	URL   string              `json:"url,omitempty"`
}

type storyBlockField uint16

const (
	blockFieldText storyBlockField = 1 << iota
	blockFieldLevel
	blockFieldMarks
	blockFieldItems
	blockFieldFileID
	blockFieldImages
	blockFieldPlaceID
	blockFieldPlaceName
	blockFieldPlaceCountryCode
	blockFieldPlaceCityID
)

func (d StoryDocument) Validate() error {
	if d.Version != StoryDocumentVersion {
		return fmt.Errorf("story document version must be %d", StoryDocumentVersion)
	}
	if len(d.Blocks) > StoryDocumentMaxBlockCount {
		return fmt.Errorf("story document must contain at most %d blocks", StoryDocumentMaxBlockCount)
	}

	seenBlockIDs := make(map[string]struct{}, len(d.Blocks))
	for index, block := range d.Blocks {
		blockID := strings.TrimSpace(block.ID)
		if blockID == "" {
			return fmt.Errorf("story document block %d id is required", index)
		}
		if _, exists := seenBlockIDs[blockID]; exists {
			return fmt.Errorf("story document block id %q is duplicated", blockID)
		}
		seenBlockIDs[blockID] = struct{}{}

		if err := validateStoryBlock(block); err != nil {
			return fmt.Errorf("story document block %q: %w", blockID, err)
		}
	}

	return nil
}

func (d StoryDocument) PlainText() string {
	parts := make([]string, 0, len(d.Blocks))
	for _, block := range d.Blocks {
		switch block.Type {
		case StoryBlockTypeParagraph, StoryBlockTypeHeading, StoryBlockTypeQuote, StoryBlockTypeCallout:
			appendVisibleText(&parts, block.Text)
		case StoryBlockTypeBulletedList, StoryBlockTypeNumberedList:
			for _, item := range block.Items {
				appendVisibleText(&parts, item.Text)
			}
		case StoryBlockTypePlaceReference:
			appendVisibleText(&parts, block.PlaceName)
		}
	}

	return strings.Join(parts, "\n")
}

func (d StoryDocument) LegacyContent() string {
	sections := make([]string, 0, len(d.Blocks))
	for _, block := range d.Blocks {
		switch block.Type {
		case StoryBlockTypeParagraph, StoryBlockTypeHeading, StoryBlockTypeQuote, StoryBlockTypeCallout:
			appendLegacySection(&sections, block.Text)
		case StoryBlockTypeBulletedList:
			appendLegacySection(&sections, legacyListContent(block.Items, "- "))
		case StoryBlockTypeNumberedList:
			appendLegacySection(&sections, legacyNumberedListContent(block.Items))
		case StoryBlockTypeImage:
			if fileID, err := normalizeStoryFileID(block.FileID); err == nil {
				sections = append(sections, legacyStoryImageMarker(fileID))
			}
		case StoryBlockTypeGallery:
			for _, image := range block.Images {
				if fileID, err := normalizeStoryFileID(image.FileID); err == nil {
					sections = append(sections, legacyStoryImageMarker(fileID))
				}
			}
		case StoryBlockTypePlaceReference:
			appendLegacySection(&sections, block.PlaceName)
		}
	}

	return strings.Join(sections, "\n\n")
}

func (d StoryDocument) IsEmptyForPublish() bool {
	if strings.TrimSpace(d.PlainText()) != "" {
		return false
	}

	for _, block := range d.Blocks {
		switch block.Type {
		case StoryBlockTypeImage:
			if _, err := normalizeStoryFileID(block.FileID); err == nil {
				return false
			}
		case StoryBlockTypeGallery:
			for _, image := range block.Images {
				if _, err := normalizeStoryFileID(image.FileID); err == nil {
					return false
				}
			}
		}
	}

	return true
}

func validateStoryBlock(block StoryBlock) error {
	switch block.Type {
	case StoryBlockTypeParagraph, StoryBlockTypeQuote, StoryBlockTypeCallout:
		if err := rejectInactiveStoryBlockFields(block, blockFieldText|blockFieldMarks); err != nil {
			return err
		}
		return validateStoryTextBlock(block.Text, block.Marks)
	case StoryBlockTypeHeading:
		if err := rejectInactiveStoryBlockFields(block, blockFieldText|blockFieldLevel|blockFieldMarks); err != nil {
			return err
		}
		if block.Level < 1 || block.Level > StoryDocumentMaxHeadingLevel {
			return fmt.Errorf("heading level must be between 1 and %d", StoryDocumentMaxHeadingLevel)
		}
		return validateStoryTextBlock(block.Text, block.Marks)
	case StoryBlockTypeBulletedList, StoryBlockTypeNumberedList:
		if err := rejectInactiveStoryBlockFields(block, blockFieldItems); err != nil {
			return err
		}
		if len(block.Items) == 0 {
			return fmt.Errorf("list requires at least one item")
		}
		if len(block.Items) > StoryDocumentMaxListItems {
			return fmt.Errorf("list must contain at most %d items", StoryDocumentMaxListItems)
		}
		for index, item := range block.Items {
			if strings.TrimSpace(item.Text) == "" {
				return fmt.Errorf("list item %d text is required", index)
			}
			if err := validateStoryText(item.Text, StoryDocumentMaxListItemTextLength, item.Marks); err != nil {
				return fmt.Errorf("list item %d: %w", index, err)
			}
		}
		return nil
	case StoryBlockTypeImage:
		if err := rejectInactiveStoryBlockFields(block, blockFieldFileID); err != nil {
			return err
		}
		if _, err := normalizeStoryFileID(block.FileID); err != nil {
			return fmt.Errorf("image fileId is invalid: %w", err)
		}
		return nil
	case StoryBlockTypeGallery:
		if err := rejectInactiveStoryBlockFields(block, blockFieldImages); err != nil {
			return err
		}
		if len(block.Images) == 0 {
			return fmt.Errorf("gallery requires at least one image")
		}
		if len(block.Images) > StoryDocumentMaxGalleryImages {
			return fmt.Errorf("gallery must contain at most %d images", StoryDocumentMaxGalleryImages)
		}
		for index, image := range block.Images {
			if _, err := normalizeStoryFileID(image.FileID); err != nil {
				return fmt.Errorf("gallery image %d fileId is invalid: %w", index, err)
			}
		}
		return nil
	case StoryBlockTypeDivider:
		return rejectInactiveStoryBlockFields(block, 0)
	case StoryBlockTypePlaceReference:
		if err := rejectInactiveStoryBlockFields(block, blockFieldPlaceID|blockFieldPlaceName|blockFieldPlaceCountryCode|blockFieldPlaceCityID); err != nil {
			return err
		}
		return validateStoryPlaceReference(block)
	default:
		return fmt.Errorf("unsupported block type %q", block.Type)
	}
}

func validateStoryTextBlock(text string, marks []StoryInlineMark) error {
	return validateStoryText(text, StoryDocumentMaxTextLength, marks)
}

func validateStoryText(text string, maxLength int, marks []StoryInlineMark) error {
	if exceedsRuneLimit(text, maxLength) {
		return fmt.Errorf("text length must be at most %d characters", maxLength)
	}
	if len(marks) > StoryDocumentMaxInlineMarksPerTextBlock {
		return fmt.Errorf("text must contain at most %d inline marks", StoryDocumentMaxInlineMarksPerTextBlock)
	}

	for index, mark := range marks {
		if err := validateStoryInlineMark(mark); err != nil {
			return fmt.Errorf("inline mark %d: %w", index, err)
		}
	}

	return nil
}

func rejectInactiveStoryBlockFields(block StoryBlock, allowed storyBlockField) error {
	if allowed&blockFieldText == 0 && block.Text != "" {
		return fmt.Errorf("%s block must not include text", block.Type)
	}
	if allowed&blockFieldLevel == 0 && block.Level != 0 {
		return fmt.Errorf("%s block must not include heading level", block.Type)
	}
	if allowed&blockFieldMarks == 0 && len(block.Marks) > 0 {
		return fmt.Errorf("%s block must not include inline marks", block.Type)
	}
	if allowed&blockFieldItems == 0 && len(block.Items) > 0 {
		return fmt.Errorf("%s block must not include list items", block.Type)
	}
	if allowed&blockFieldFileID == 0 && block.FileID != "" {
		return fmt.Errorf("%s block must not include fileId", block.Type)
	}
	if allowed&blockFieldImages == 0 && len(block.Images) > 0 {
		return fmt.Errorf("%s block must not include images", block.Type)
	}
	if allowed&blockFieldPlaceID == 0 && block.PlaceID != "" {
		return fmt.Errorf("%s block must not include placeId", block.Type)
	}
	if allowed&blockFieldPlaceName == 0 && block.PlaceName != "" {
		return fmt.Errorf("%s block must not include placeName", block.Type)
	}
	if allowed&blockFieldPlaceCountryCode == 0 && block.PlaceCountryCode != "" {
		return fmt.Errorf("%s block must not include placeCountryCode", block.Type)
	}
	if allowed&blockFieldPlaceCityID == 0 && block.PlaceCityID != "" {
		return fmt.Errorf("%s block must not include placeCityId", block.Type)
	}
	return nil
}

func validateStoryInlineMark(mark StoryInlineMark) error {
	switch mark.Type {
	case StoryInlineMarkTypeBold, StoryInlineMarkTypeItalic, StoryInlineMarkTypeUnderline, StoryInlineMarkTypeStrikethrough:
		if strings.TrimSpace(mark.URL) != "" {
			return fmt.Errorf("%s mark must not include url", mark.Type)
		}
		return nil
	case StoryInlineMarkTypeLink:
		if !isSafeStoryLinkURL(mark.URL) {
			return fmt.Errorf("link url must use http or https")
		}
		return nil
	default:
		return fmt.Errorf("unsupported inline mark type %q", mark.Type)
	}
}

func isSafeStoryLinkURL(rawURL string) bool {
	normalizedURL := strings.TrimSpace(rawURL)
	if normalizedURL == "" || len(normalizedURL) > StoryDocumentMaxURLLength || hasControlOrSpaceRune(normalizedURL) {
		return false
	}

	parsedURL, err := url.Parse(normalizedURL)
	if err != nil {
		return false
	}

	scheme := strings.ToLower(parsedURL.Scheme)
	return (scheme == "http" || scheme == "https") && parsedURL.Host != "" && parsedURL.User == nil
}

func appendVisibleText(parts *[]string, text string) {
	if trimmed := strings.TrimSpace(text); trimmed != "" {
		*parts = append(*parts, trimmed)
	}
}

func appendLegacySection(sections *[]string, text string) {
	if trimmed := strings.TrimSpace(text); trimmed != "" {
		*sections = append(*sections, trimmed)
	}
}

func legacyListContent(items []StoryListItem, prefix string) string {
	lines := make([]string, 0, len(items))
	for _, item := range items {
		if text := strings.TrimSpace(item.Text); text != "" {
			lines = append(lines, prefix+text)
		}
	}
	return strings.Join(lines, "\n")
}

func legacyNumberedListContent(items []StoryListItem) string {
	lines := make([]string, 0, len(items))
	for _, item := range items {
		if text := strings.TrimSpace(item.Text); text != "" {
			lines = append(lines, fmt.Sprintf("%d. %s", len(lines)+1, text))
		}
	}
	return strings.Join(lines, "\n")
}

func legacyStoryImageMarker(fileID string) string {
	return fmt.Sprintf("[[story-image:%s]]", fileID)
}

func validateStoryPlaceReference(block StoryBlock) error {
	placeID := strings.TrimSpace(block.PlaceID)
	placeName := strings.TrimSpace(block.PlaceName)
	if placeID == "" && placeName == "" {
		return fmt.Errorf("place reference requires place id or name")
	}
	if exceedsRuneLimit(placeID, StoryDocumentMaxPlaceIDLength) {
		return fmt.Errorf("place id length must be at most %d characters", StoryDocumentMaxPlaceIDLength)
	}
	if exceedsRuneLimit(placeName, StoryDocumentMaxPlaceNameLength) {
		return fmt.Errorf("place name length must be at most %d characters", StoryDocumentMaxPlaceNameLength)
	}
	if exceedsRuneLimit(strings.TrimSpace(block.PlaceCountryCode), StoryDocumentMaxPlaceCountryCodeLength) {
		return fmt.Errorf("place country code length must be at most %d characters", StoryDocumentMaxPlaceCountryCodeLength)
	}
	if exceedsRuneLimit(strings.TrimSpace(block.PlaceCityID), StoryDocumentMaxPlaceCityIDLength) {
		return fmt.Errorf("place city id length must be at most %d characters", StoryDocumentMaxPlaceCityIDLength)
	}
	return nil
}

func normalizeStoryFileID(fileID string) (string, error) {
	normalized := strings.TrimSpace(fileID)
	if normalized == "" {
		return "", fmt.Errorf("fileId is required")
	}
	if exceedsRuneLimit(normalized, StoryDocumentMaxFileIDLength) {
		return "", fmt.Errorf("fileId length must be at most %d characters", StoryDocumentMaxFileIDLength)
	}
	if strings.ContainsAny(normalized, "[]:") {
		return "", fmt.Errorf("fileId contains legacy marker delimiters")
	}
	for _, r := range normalized {
		if unicode.IsControl(r) || unicode.IsSpace(r) {
			return "", fmt.Errorf("fileId must not contain whitespace or control characters")
		}
	}
	return normalized, nil
}

func exceedsRuneLimit(value string, max int) bool {
	if max < 0 {
		return true
	}
	count := 0
	for range value {
		count++
		if count > max {
			return true
		}
	}
	return false
}

func hasControlOrSpaceRune(value string) bool {
	for _, r := range value {
		if unicode.IsControl(r) || unicode.IsSpace(r) {
			return true
		}
	}
	return false
}
