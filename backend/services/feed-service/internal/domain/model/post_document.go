package model

import (
	"fmt"
	"net/url"
	"strings"
	"unicode"
)

const (
	PostDocumentVersion                    = 1
	PostDocumentMaxBlockCount              = 256
	PostDocumentMaxTextLength              = 20_000
	PostDocumentMaxInlineMarksPerTextBlock = 64
	PostDocumentMaxListItems               = 100
	PostDocumentMaxListItemTextLength      = 2_000
	PostDocumentMaxGalleryImages           = 30
	PostDocumentMaxHeadingLevel            = 6
	PostDocumentMaxPlaceIDLength           = 128
	PostDocumentMaxPlaceNameLength         = 300
	PostDocumentMaxPlaceCountryCodeLength  = 8
	PostDocumentMaxPlaceCityIDLength       = 128
	PostDocumentMaxRouteIDLength           = 128
	PostDocumentMaxRouteTitleLength        = 160
	PostDocumentMaxRouteDescriptionLength  = 500
	PostDocumentMaxRouteProfileLength      = 32
	PostDocumentMaxFileIDLength            = 256
	PostDocumentMaxURLLength               = 2_048
)

type PostBlockType string

const (
	PostBlockTypeParagraph      PostBlockType = "paragraph"
	PostBlockTypeHeading        PostBlockType = "heading"
	PostBlockTypeBulletedList   PostBlockType = "bulleted_list"
	PostBlockTypeNumberedList   PostBlockType = "numbered_list"
	PostBlockTypeQuote          PostBlockType = "quote"
	PostBlockTypeCallout        PostBlockType = "callout"
	PostBlockTypeImage          PostBlockType = "image"
	PostBlockTypeGallery        PostBlockType = "gallery"
	PostBlockTypeDivider        PostBlockType = "divider"
	PostBlockTypePlaceReference PostBlockType = "place_reference"
	PostBlockTypeRouteReference PostBlockType = "route_reference"
)

type PostInlineMarkType string

const (
	PostInlineMarkTypeBold          PostInlineMarkType = "bold"
	PostInlineMarkTypeItalic        PostInlineMarkType = "italic"
	PostInlineMarkTypeUnderline     PostInlineMarkType = "underline"
	PostInlineMarkTypeStrikethrough PostInlineMarkType = "strikethrough"
	PostInlineMarkTypeLink          PostInlineMarkType = "link"
)

type PostDocument struct {
	Version int         `json:"version"`
	Blocks  []PostBlock `json:"blocks"`
}

type PostBlock struct {
	ID                   string             `json:"id"`
	Type                 PostBlockType      `json:"type"`
	Text                 string             `json:"text,omitempty"`
	Level                int                `json:"level,omitempty"`
	Marks                []PostInlineMark   `json:"marks,omitempty"`
	Items                []PostListItem     `json:"items,omitempty"`
	FileID               string             `json:"fileId,omitempty"`
	Images               []PostGalleryImage `json:"images,omitempty"`
	PlaceID              string             `json:"placeId,omitempty"`
	PlaceName            string             `json:"placeName,omitempty"`
	PlaceCountryCode     string             `json:"placeCountryCode,omitempty"`
	PlaceCityID          string             `json:"placeCityId,omitempty"`
	RouteID              string             `json:"routeId,omitempty"`
	RouteTitle           string             `json:"routeTitle,omitempty"`
	RouteDescription     string             `json:"routeDescription,omitempty"`
	RouteProfile         string             `json:"routeProfile,omitempty"`
	RouteDistanceMeters  int                `json:"distanceMeters,omitempty"`
	RouteDurationSeconds int                `json:"durationSeconds,omitempty"`
	RouteStopsCount      int                `json:"stopsCount,omitempty"`
	RouteShareURL        string             `json:"shareUrl,omitempty"`
}

type PostListItem struct {
	Text  string           `json:"text"`
	Marks []PostInlineMark `json:"marks,omitempty"`
}

type PostGalleryImage struct {
	FileID string `json:"fileId"`
}

type PostInlineMark struct {
	Type  PostInlineMarkType `json:"type"`
	Start int                `json:"start,omitempty"`
	End   int                `json:"end,omitempty"`
	URL   string             `json:"url,omitempty"`
}

type postBlockField uint32

const (
	blockFieldText postBlockField = 1 << iota
	blockFieldLevel
	blockFieldMarks
	blockFieldItems
	blockFieldFileID
	blockFieldImages
	blockFieldPlaceID
	blockFieldPlaceName
	blockFieldPlaceCountryCode
	blockFieldPlaceCityID
	blockFieldRouteID
	blockFieldRouteTitle
	blockFieldRouteDescription
	blockFieldRouteProfile
	blockFieldRouteDistanceMeters
	blockFieldRouteDurationSeconds
	blockFieldRouteStopsCount
	blockFieldRouteShareURL
)

func (d PostDocument) Validate() error {
	if d.Version != PostDocumentVersion {
		return fmt.Errorf("post document version must be %d", PostDocumentVersion)
	}
	if len(d.Blocks) > PostDocumentMaxBlockCount {
		return fmt.Errorf("post document must contain at most %d blocks", PostDocumentMaxBlockCount)
	}

	seenBlockIDs := make(map[string]struct{}, len(d.Blocks))
	for index, block := range d.Blocks {
		blockID := strings.TrimSpace(block.ID)
		if blockID == "" {
			return fmt.Errorf("post document block %d id is required", index)
		}
		if _, exists := seenBlockIDs[blockID]; exists {
			return fmt.Errorf("post document block id %q is duplicated", blockID)
		}
		seenBlockIDs[blockID] = struct{}{}

		if err := validatePostBlock(block); err != nil {
			return fmt.Errorf("post document block %q: %w", blockID, err)
		}
	}

	return nil
}

func (d PostDocument) PlainText() string {
	parts := make([]string, 0, len(d.Blocks))
	for _, block := range d.Blocks {
		switch block.Type {
		case PostBlockTypeParagraph, PostBlockTypeHeading, PostBlockTypeQuote, PostBlockTypeCallout:
			appendVisibleText(&parts, block.Text)
		case PostBlockTypeBulletedList, PostBlockTypeNumberedList:
			for _, item := range block.Items {
				appendVisibleText(&parts, item.Text)
			}
		case PostBlockTypePlaceReference:
			appendVisibleText(&parts, block.PlaceName)
		case PostBlockTypeRouteReference:
			appendVisibleText(&parts, block.RouteTitle)
		}
	}

	return strings.Join(parts, "\n")
}

func (d PostDocument) LegacyContent() string {
	sections := make([]string, 0, len(d.Blocks))
	for _, block := range d.Blocks {
		switch block.Type {
		case PostBlockTypeParagraph, PostBlockTypeHeading, PostBlockTypeQuote, PostBlockTypeCallout:
			appendLegacySection(&sections, block.Text)
		case PostBlockTypeBulletedList:
			appendLegacySection(&sections, legacyListContent(block.Items, "- "))
		case PostBlockTypeNumberedList:
			appendLegacySection(&sections, legacyNumberedListContent(block.Items))
		case PostBlockTypeImage:
			if fileID, err := normalizePostFileID(block.FileID); err == nil {
				sections = append(sections, legacyPostImageMarker(fileID))
			}
		case PostBlockTypeGallery:
			for _, image := range block.Images {
				if fileID, err := normalizePostFileID(image.FileID); err == nil {
					sections = append(sections, legacyPostImageMarker(fileID))
				}
			}
		case PostBlockTypePlaceReference:
			appendLegacySection(&sections, block.PlaceName)
		case PostBlockTypeRouteReference:
			appendLegacySection(&sections, block.RouteTitle)
		}
	}

	return strings.Join(sections, "\n\n")
}

func (d PostDocument) IsEmptyForPublish() bool {
	if strings.TrimSpace(d.PlainText()) != "" {
		return false
	}

	for _, block := range d.Blocks {
		switch block.Type {
		case PostBlockTypeImage:
			if _, err := normalizePostFileID(block.FileID); err == nil {
				return false
			}
		case PostBlockTypeGallery:
			for _, image := range block.Images {
				if _, err := normalizePostFileID(image.FileID); err == nil {
					return false
				}
			}
		}
	}

	return true
}

func validatePostBlock(block PostBlock) error {
	switch block.Type {
	case PostBlockTypeParagraph, PostBlockTypeQuote, PostBlockTypeCallout:
		if err := rejectInactivePostBlockFields(block, blockFieldText|blockFieldMarks); err != nil {
			return err
		}
		return validatePostTextBlock(block.Text, block.Marks)
	case PostBlockTypeHeading:
		if err := rejectInactivePostBlockFields(block, blockFieldText|blockFieldLevel|blockFieldMarks); err != nil {
			return err
		}
		if block.Level < 1 || block.Level > PostDocumentMaxHeadingLevel {
			return fmt.Errorf("heading level must be between 1 and %d", PostDocumentMaxHeadingLevel)
		}
		return validatePostTextBlock(block.Text, block.Marks)
	case PostBlockTypeBulletedList, PostBlockTypeNumberedList:
		if err := rejectInactivePostBlockFields(block, blockFieldItems); err != nil {
			return err
		}
		if len(block.Items) == 0 {
			return fmt.Errorf("list requires at least one item")
		}
		if len(block.Items) > PostDocumentMaxListItems {
			return fmt.Errorf("list must contain at most %d items", PostDocumentMaxListItems)
		}
		for index, item := range block.Items {
			if strings.TrimSpace(item.Text) == "" {
				return fmt.Errorf("list item %d text is required", index)
			}
			if err := validatePostText(item.Text, PostDocumentMaxListItemTextLength, item.Marks); err != nil {
				return fmt.Errorf("list item %d: %w", index, err)
			}
		}
		return nil
	case PostBlockTypeImage:
		if err := rejectInactivePostBlockFields(block, blockFieldFileID); err != nil {
			return err
		}
		if _, err := normalizePostFileID(block.FileID); err != nil {
			return fmt.Errorf("image fileId is invalid: %w", err)
		}
		return nil
	case PostBlockTypeGallery:
		if err := rejectInactivePostBlockFields(block, blockFieldImages); err != nil {
			return err
		}
		if len(block.Images) == 0 {
			return fmt.Errorf("gallery requires at least one image")
		}
		if len(block.Images) > PostDocumentMaxGalleryImages {
			return fmt.Errorf("gallery must contain at most %d images", PostDocumentMaxGalleryImages)
		}
		for index, image := range block.Images {
			if _, err := normalizePostFileID(image.FileID); err != nil {
				return fmt.Errorf("gallery image %d fileId is invalid: %w", index, err)
			}
		}
		return nil
	case PostBlockTypeDivider:
		return rejectInactivePostBlockFields(block, 0)
	case PostBlockTypePlaceReference:
		if err := rejectInactivePostBlockFields(block, blockFieldPlaceID|blockFieldPlaceName|blockFieldPlaceCountryCode|blockFieldPlaceCityID); err != nil {
			return err
		}
		return validatePostPlaceReference(block)
	case PostBlockTypeRouteReference:
		if err := rejectInactivePostBlockFields(block, blockFieldRouteID|blockFieldRouteTitle|blockFieldRouteDescription|blockFieldRouteProfile|blockFieldRouteDistanceMeters|blockFieldRouteDurationSeconds|blockFieldRouteStopsCount|blockFieldRouteShareURL); err != nil {
			return err
		}
		return validatePostRouteReference(block)
	default:
		return fmt.Errorf("unsupported block type %q", block.Type)
	}
}

func validatePostTextBlock(text string, marks []PostInlineMark) error {
	return validatePostText(text, PostDocumentMaxTextLength, marks)
}

func validatePostText(text string, maxLength int, marks []PostInlineMark) error {
	if exceedsRuneLimit(text, maxLength) {
		return fmt.Errorf("text length must be at most %d characters", maxLength)
	}
	if len(marks) > PostDocumentMaxInlineMarksPerTextBlock {
		return fmt.Errorf("text must contain at most %d inline marks", PostDocumentMaxInlineMarksPerTextBlock)
	}

	for index, mark := range marks {
		if err := validatePostInlineMark(mark); err != nil {
			return fmt.Errorf("inline mark %d: %w", index, err)
		}
	}

	return nil
}

func rejectInactivePostBlockFields(block PostBlock, allowed postBlockField) error {
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
	if allowed&blockFieldRouteID == 0 && block.RouteID != "" {
		return fmt.Errorf("%s block must not include routeId", block.Type)
	}
	if allowed&blockFieldRouteTitle == 0 && block.RouteTitle != "" {
		return fmt.Errorf("%s block must not include routeTitle", block.Type)
	}
	if allowed&blockFieldRouteDescription == 0 && block.RouteDescription != "" {
		return fmt.Errorf("%s block must not include routeDescription", block.Type)
	}
	if allowed&blockFieldRouteProfile == 0 && block.RouteProfile != "" {
		return fmt.Errorf("%s block must not include routeProfile", block.Type)
	}
	if allowed&blockFieldRouteDistanceMeters == 0 && block.RouteDistanceMeters != 0 {
		return fmt.Errorf("%s block must not include distanceMeters", block.Type)
	}
	if allowed&blockFieldRouteDurationSeconds == 0 && block.RouteDurationSeconds != 0 {
		return fmt.Errorf("%s block must not include durationSeconds", block.Type)
	}
	if allowed&blockFieldRouteStopsCount == 0 && block.RouteStopsCount != 0 {
		return fmt.Errorf("%s block must not include stopsCount", block.Type)
	}
	if allowed&blockFieldRouteShareURL == 0 && block.RouteShareURL != "" {
		return fmt.Errorf("%s block must not include shareUrl", block.Type)
	}
	return nil
}

func validatePostInlineMark(mark PostInlineMark) error {
	switch mark.Type {
	case PostInlineMarkTypeBold, PostInlineMarkTypeItalic, PostInlineMarkTypeUnderline, PostInlineMarkTypeStrikethrough:
		if strings.TrimSpace(mark.URL) != "" {
			return fmt.Errorf("%s mark must not include url", mark.Type)
		}
		return nil
	case PostInlineMarkTypeLink:
		if !isSafePostLinkURL(mark.URL) {
			return fmt.Errorf("link url must use http or https")
		}
		return nil
	default:
		return fmt.Errorf("unsupported inline mark type %q", mark.Type)
	}
}

func isSafePostLinkURL(rawURL string) bool {
	normalizedURL := strings.TrimSpace(rawURL)
	if normalizedURL == "" || len(normalizedURL) > PostDocumentMaxURLLength || hasControlOrSpaceRune(normalizedURL) {
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

func legacyListContent(items []PostListItem, prefix string) string {
	lines := make([]string, 0, len(items))
	for _, item := range items {
		if text := strings.TrimSpace(item.Text); text != "" {
			lines = append(lines, prefix+text)
		}
	}
	return strings.Join(lines, "\n")
}

func legacyNumberedListContent(items []PostListItem) string {
	lines := make([]string, 0, len(items))
	for _, item := range items {
		if text := strings.TrimSpace(item.Text); text != "" {
			lines = append(lines, fmt.Sprintf("%d. %s", len(lines)+1, text))
		}
	}
	return strings.Join(lines, "\n")
}

func legacyPostImageMarker(fileID string) string {
	return fmt.Sprintf("[[post-image:%s]]", fileID)
}

func validatePostPlaceReference(block PostBlock) error {
	placeID := strings.TrimSpace(block.PlaceID)
	placeName := strings.TrimSpace(block.PlaceName)
	if placeID == "" && placeName == "" {
		return fmt.Errorf("place reference requires place id or name")
	}
	if exceedsRuneLimit(placeID, PostDocumentMaxPlaceIDLength) {
		return fmt.Errorf("place id length must be at most %d characters", PostDocumentMaxPlaceIDLength)
	}
	if exceedsRuneLimit(placeName, PostDocumentMaxPlaceNameLength) {
		return fmt.Errorf("place name length must be at most %d characters", PostDocumentMaxPlaceNameLength)
	}
	if exceedsRuneLimit(strings.TrimSpace(block.PlaceCountryCode), PostDocumentMaxPlaceCountryCodeLength) {
		return fmt.Errorf("place country code length must be at most %d characters", PostDocumentMaxPlaceCountryCodeLength)
	}
	if exceedsRuneLimit(strings.TrimSpace(block.PlaceCityID), PostDocumentMaxPlaceCityIDLength) {
		return fmt.Errorf("place city id length must be at most %d characters", PostDocumentMaxPlaceCityIDLength)
	}
	return nil
}

func validatePostRouteReference(block PostBlock) error {
	routeID := strings.TrimSpace(block.RouteID)
	routeTitle := strings.TrimSpace(block.RouteTitle)
	if routeID == "" || routeTitle == "" {
		return fmt.Errorf("route reference requires route id and title")
	}
	if exceedsRuneLimit(routeID, PostDocumentMaxRouteIDLength) {
		return fmt.Errorf("route id length must be at most %d characters", PostDocumentMaxRouteIDLength)
	}
	if exceedsRuneLimit(routeTitle, PostDocumentMaxRouteTitleLength) {
		return fmt.Errorf("route title length must be at most %d characters", PostDocumentMaxRouteTitleLength)
	}
	if exceedsRuneLimit(strings.TrimSpace(block.RouteDescription), PostDocumentMaxRouteDescriptionLength) {
		return fmt.Errorf("route description length must be at most %d characters", PostDocumentMaxRouteDescriptionLength)
	}
	if exceedsRuneLimit(strings.TrimSpace(block.RouteProfile), PostDocumentMaxRouteProfileLength) {
		return fmt.Errorf("route profile length must be at most %d characters", PostDocumentMaxRouteProfileLength)
	}
	if block.RouteDistanceMeters < 0 {
		return fmt.Errorf("route distance must be non-negative")
	}
	if block.RouteDurationSeconds < 0 {
		return fmt.Errorf("route duration must be non-negative")
	}
	if block.RouteStopsCount < 0 {
		return fmt.Errorf("route stops count must be non-negative")
	}
	shareURL := strings.TrimSpace(block.RouteShareURL)
	if shareURL != "" && !isSafePostLinkURL(shareURL) {
		return fmt.Errorf("route share url must use http or https")
	}
	return nil
}

func normalizePostFileID(fileID string) (string, error) {
	normalized := strings.TrimSpace(fileID)
	if normalized == "" {
		return "", fmt.Errorf("fileId is required")
	}
	if exceedsRuneLimit(normalized, PostDocumentMaxFileIDLength) {
		return "", fmt.Errorf("fileId length must be at most %d characters", PostDocumentMaxFileIDLength)
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
