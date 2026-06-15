package model

import (
	"encoding/json"
	"strings"
	"testing"
)

func TestPostDocumentValidateAcceptsSupportedBlocks(t *testing.T) {
	document := PostDocument{
		Version: PostDocumentVersion,
		Blocks: []PostBlock{
			{ID: "paragraph-1", Type: PostBlockTypeParagraph, Text: "A calm walk through Almaty.", Marks: []PostInlineMark{{Type: PostInlineMarkTypeBold}, {Type: PostInlineMarkTypeUnderline}, {Type: PostInlineMarkTypeStrikethrough}}},
			{ID: "heading-1", Type: PostBlockTypeHeading, Level: 2, Text: "Route"},
			{ID: "bullets-1", Type: PostBlockTypeBulletedList, Items: []PostListItem{{Text: "Coffee"}, {Text: "Museum"}}},
			{ID: "numbers-1", Type: PostBlockTypeNumberedList, Items: []PostListItem{{Text: "Arrive"}, {Text: "Explore"}}},
			{ID: "quote-1", Type: PostBlockTypeQuote, Text: "Travel slowly."},
			{ID: "callout-1", Type: PostBlockTypeCallout, Text: "Bring cash for small cafes."},
			{ID: "image-1", Type: PostBlockTypeImage, FileID: "file-cover"},
			{ID: "gallery-1", Type: PostBlockTypeGallery, Images: []PostGalleryImage{{FileID: "file-1"}, {FileID: "file-2"}}},
			{ID: "divider-1", Type: PostBlockTypeDivider},
			{ID: "place-1", Type: PostBlockTypePlaceReference, PlaceID: "place-123", PlaceName: "Kok-Tobe"},
			{ID: "link-1", Type: PostBlockTypeParagraph, Text: "Official route", Marks: []PostInlineMark{{Type: PostInlineMarkTypeLink, URL: "https://example.com/route"}}},
		},
	}

	if err := document.Validate(); err != nil {
		t.Fatalf("Validate() error = %v, want nil", err)
	}
}

func TestPostDocumentValidateRejectsInvalidBlocks(t *testing.T) {
	longText := strings.Repeat("x", PostDocumentMaxTextLength+1)

	tests := map[string]PostDocument{
		"invalid version": {
			Version: 2,
			Blocks:  []PostBlock{{ID: "paragraph-1", Type: PostBlockTypeParagraph, Text: "hello"}},
		},
		"missing block id": {
			Version: PostDocumentVersion,
			Blocks:  []PostBlock{{Type: PostBlockTypeParagraph, Text: "hello"}},
		},
		"duplicate block id": {
			Version: PostDocumentVersion,
			Blocks: []PostBlock{
				{ID: "paragraph-1", Type: PostBlockTypeParagraph, Text: "hello"},
				{ID: "paragraph-1", Type: PostBlockTypeQuote, Text: "again"},
			},
		},
		"text too long": {
			Version: PostDocumentVersion,
			Blocks:  []PostBlock{{ID: "paragraph-1", Type: PostBlockTypeParagraph, Text: longText}},
		},
		"heading level too low": {
			Version: PostDocumentVersion,
			Blocks:  []PostBlock{{ID: "heading-1", Type: PostBlockTypeHeading, Level: 0, Text: "Route"}},
		},
		"heading level too high": {
			Version: PostDocumentVersion,
			Blocks:  []PostBlock{{ID: "heading-1", Type: PostBlockTypeHeading, Level: PostDocumentMaxHeadingLevel + 1, Text: "Route"}},
		},
		"image without file id": {
			Version: PostDocumentVersion,
			Blocks:  []PostBlock{{ID: "image-1", Type: PostBlockTypeImage}},
		},
		"empty gallery": {
			Version: PostDocumentVersion,
			Blocks:  []PostBlock{{ID: "gallery-1", Type: PostBlockTypeGallery}},
		},
		"gallery image without file id": {
			Version: PostDocumentVersion,
			Blocks:  []PostBlock{{ID: "gallery-1", Type: PostBlockTypeGallery, Images: []PostGalleryImage{{FileID: "file-1"}, {}}}},
		},
		"audio block is unsupported": {
			Version: PostDocumentVersion,
			Blocks:  []PostBlock{{ID: "audio-1", Type: PostBlockType("audio"), FileID: "file-audio", Text: "Morning city walk"}},
		},
		"unknown block type": {
			Version: PostDocumentVersion,
			Blocks:  []PostBlock{{ID: "custom-1", Type: PostBlockType("custom"), Text: "hello"}},
		},
		"unknown inline mark": {
			Version: PostDocumentVersion,
			Blocks:  []PostBlock{{ID: "paragraph-1", Type: PostBlockTypeParagraph, Text: "hello", Marks: []PostInlineMark{{Type: PostInlineMarkType("highlight")}}}},
		},
		"too many blocks": {
			Version: PostDocumentVersion,
			Blocks:  repeatPostBlocks(PostDocumentMaxBlockCount+1, func(index int) PostBlock { return PostBlock{ID: blockID(index), Type: PostBlockTypeDivider} }),
		},
		"too many inline marks": {
			Version: PostDocumentVersion,
			Blocks: []PostBlock{{
				ID:    "paragraph-1",
				Type:  PostBlockTypeParagraph,
				Text:  "hello",
				Marks: repeatPostInlineMarks(PostDocumentMaxInlineMarksPerTextBlock + 1),
			}},
		},
		"too many list items": {
			Version: PostDocumentVersion,
			Blocks: []PostBlock{{
				ID:    "list-1",
				Type:  PostBlockTypeBulletedList,
				Items: repeatPostListItems(PostDocumentMaxListItems+1, "item"),
			}},
		},
		"blank list item": {
			Version: PostDocumentVersion,
			Blocks:  []PostBlock{{ID: "list-1", Type: PostBlockTypeBulletedList, Items: []PostListItem{{Text: "First"}, {Text: "  \n\t"}}}},
		},
		"list item too long": {
			Version: PostDocumentVersion,
			Blocks:  []PostBlock{{ID: "list-1", Type: PostBlockTypeNumberedList, Items: []PostListItem{{Text: strings.Repeat("x", PostDocumentMaxListItemTextLength+1)}}}},
		},
		"too many gallery images": {
			Version: PostDocumentVersion,
			Blocks: []PostBlock{{
				ID:     "gallery-1",
				Type:   PostBlockTypeGallery,
				Images: repeatPostGalleryImages(PostDocumentMaxGalleryImages + 1),
			}},
		},
		"place reference without id or name": {
			Version: PostDocumentVersion,
			Blocks:  []PostBlock{{ID: "place-1", Type: PostBlockTypePlaceReference}},
		},
		"place id too long": {
			Version: PostDocumentVersion,
			Blocks:  []PostBlock{{ID: "place-1", Type: PostBlockTypePlaceReference, PlaceID: strings.Repeat("p", PostDocumentMaxPlaceIDLength+1)}},
		},
		"place name too long": {
			Version: PostDocumentVersion,
			Blocks:  []PostBlock{{ID: "place-1", Type: PostBlockTypePlaceReference, PlaceName: strings.Repeat("p", PostDocumentMaxPlaceNameLength+1)}},
		},
		"place country too long": {
			Version: PostDocumentVersion,
			Blocks:  []PostBlock{{ID: "place-1", Type: PostBlockTypePlaceReference, PlaceID: "place-1", PlaceCountryCode: strings.Repeat("K", PostDocumentMaxPlaceCountryCodeLength+1)}},
		},
		"place city too long": {
			Version: PostDocumentVersion,
			Blocks:  []PostBlock{{ID: "place-1", Type: PostBlockTypePlaceReference, PlaceID: "place-1", PlaceCityID: strings.Repeat("c", PostDocumentMaxPlaceCityIDLength+1)}},
		},
		"bold mark with url": {
			Version: PostDocumentVersion,
			Blocks:  []PostBlock{{ID: "paragraph-1", Type: PostBlockTypeParagraph, Text: "hello", Marks: []PostInlineMark{{Type: PostInlineMarkTypeBold, URL: "https://example.com"}}}},
		},
		"italic mark with url": {
			Version: PostDocumentVersion,
			Blocks:  []PostBlock{{ID: "paragraph-1", Type: PostBlockTypeParagraph, Text: "hello", Marks: []PostInlineMark{{Type: PostInlineMarkTypeItalic, URL: "https://example.com"}}}},
		},
		"underline mark with url": {
			Version: PostDocumentVersion,
			Blocks:  []PostBlock{{ID: "paragraph-1", Type: PostBlockTypeParagraph, Text: "hello", Marks: []PostInlineMark{{Type: PostInlineMarkTypeUnderline, URL: "https://example.com"}}}},
		},
		"strikethrough mark with url": {
			Version: PostDocumentVersion,
			Blocks:  []PostBlock{{ID: "paragraph-1", Type: PostBlockTypeParagraph, Text: "hello", Marks: []PostInlineMark{{Type: PostInlineMarkTypeStrikethrough, URL: "https://example.com"}}}},
		},
		"image file id with control character": {
			Version: PostDocumentVersion,
			Blocks:  []PostBlock{{ID: "image-1", Type: PostBlockTypeImage, FileID: "file\n1"}},
		},
		"image file id with legacy marker injection": {
			Version: PostDocumentVersion,
			Blocks:  []PostBlock{{ID: "image-1", Type: PostBlockTypeImage, FileID: "file-1]]\n[[post-image:file-2"}},
		},
	}

	for name, document := range tests {
		t.Run(name, func(t *testing.T) {
			if err := document.Validate(); err == nil {
				t.Fatal("Validate() error = nil, want error")
			}
		})
	}
}

func TestPostDocumentValidateRejectsUnsafeLinks(t *testing.T) {
	tests := map[string]string{
		"javascript":     "javascript:alert(1)",
		"mailto":         "mailto:hello@example.com",
		"relative":       "/posts/1",
		"empty":          "",
		"control chars":  "https://example.com/\npath",
		"user info":      "https://user:pass@example.com/path",
		"blank host":     "https:///path",
		"excessive size": "https://example.com/" + strings.Repeat("x", PostDocumentMaxURLLength+1),
	}

	for name, rawURL := range tests {
		t.Run(name, func(t *testing.T) {
			document := PostDocument{
				Version: PostDocumentVersion,
				Blocks: []PostBlock{
					{
						ID:    "paragraph-1",
						Type:  PostBlockTypeParagraph,
						Text:  "unsafe",
						Marks: []PostInlineMark{{Type: PostInlineMarkTypeLink, URL: rawURL}},
					},
				},
			}

			if err := document.Validate(); err == nil {
				t.Fatal("Validate() error = nil, want error")
			}
		})
	}
}

func TestPostDocumentValidateRejectsInactiveFields(t *testing.T) {
	tests := map[string]PostBlock{
		"divider with text": {
			ID:   "divider-1",
			Type: PostBlockTypeDivider,
			Text: "hidden text",
		},
		"divider with items": {
			ID:    "divider-1",
			Type:  PostBlockTypeDivider,
			Items: []PostListItem{{Text: "hidden item"}},
		},
		"divider with images": {
			ID:     "divider-1",
			Type:   PostBlockTypeDivider,
			Images: []PostGalleryImage{{FileID: "file-1"}},
		},
		"divider with file id": {
			ID:     "divider-1",
			Type:   PostBlockTypeDivider,
			FileID: "file-1",
		},
		"divider with place fields": {
			ID:        "divider-1",
			Type:      PostBlockTypeDivider,
			PlaceName: "Hidden place",
		},
		"text block with inactive items": {
			ID:    "paragraph-1",
			Type:  PostBlockTypeParagraph,
			Text:  "visible",
			Items: []PostListItem{{Text: "hidden item"}},
		},
		"text block with inactive images": {
			ID:     "paragraph-1",
			Type:   PostBlockTypeParagraph,
			Text:   "visible",
			Images: []PostGalleryImage{{FileID: "file-1"}},
		},
		"text block with inactive file id": {
			ID:     "paragraph-1",
			Type:   PostBlockTypeParagraph,
			Text:   "visible",
			FileID: "file-1",
		},
		"text block with inactive place fields": {
			ID:        "paragraph-1",
			Type:      PostBlockTypeParagraph,
			Text:      "visible",
			PlaceName: "Hidden place",
		},
		"list block with inactive place field": {
			ID:        "list-1",
			Type:      PostBlockTypeNumberedList,
			Items:     []PostListItem{{Text: "visible"}},
			PlaceName: "Hidden place",
		},
		"place block with inactive text": {
			ID:        "place-1",
			Type:      PostBlockTypePlaceReference,
			Text:      "hidden text",
			PlaceName: "Kok-Tobe",
		},
		"place block with inactive media": {
			ID:        "place-1",
			Type:      PostBlockTypePlaceReference,
			PlaceName: "Kok-Tobe",
			FileID:    "file-1",
		},
		"place block with inactive list": {
			ID:        "place-1",
			Type:      PostBlockTypePlaceReference,
			PlaceName: "Kok-Tobe",
			Items:     []PostListItem{{Text: "hidden item"}},
		},
	}

	for name, block := range tests {
		t.Run(name, func(t *testing.T) {
			document := PostDocument{
				Version: PostDocumentVersion,
				Blocks:  []PostBlock{block},
			}

			if err := document.Validate(); err == nil {
				t.Fatal("Validate() error = nil, want error")
			}
		})
	}
}

func TestPostDocumentValidateAcceptsPlaceReferenceFields(t *testing.T) {
	document := PostDocument{
		Version: PostDocumentVersion,
		Blocks: []PostBlock{{
			ID:               "place-1",
			Type:             PostBlockTypePlaceReference,
			PlaceID:          "place-123",
			PlaceName:        "Kok-Tobe",
			PlaceCountryCode: "KZ",
			PlaceCityID:      "almaty",
		}},
	}

	if err := document.Validate(); err != nil {
		t.Fatalf("Validate() error = %v, want nil", err)
	}
}

func TestPostDocumentValidateAcceptsTrimmedIDsAndURLs(t *testing.T) {
	document := PostDocument{
		Version: PostDocumentVersion,
		Blocks: []PostBlock{
			{ID: " paragraph-1 ", Type: PostBlockTypeParagraph, Text: "Official route", Marks: []PostInlineMark{{Type: PostInlineMarkTypeLink, URL: " https://example.com/route "}}},
			{ID: " image-1 ", Type: PostBlockTypeImage, FileID: " file-cover "},
			{ID: " place-1 ", Type: PostBlockTypePlaceReference, PlaceID: " place-123 ", PlaceName: " Kok-Tobe "},
		},
	}

	if err := document.Validate(); err != nil {
		t.Fatalf("Validate() error = %v, want nil", err)
	}
}

func TestPostDocumentPlainText(t *testing.T) {
	document := PostDocument{
		Version: PostDocumentVersion,
		Blocks: []PostBlock{
			{ID: "heading-1", Type: PostBlockTypeHeading, Level: 1, Text: "Weekend in Almaty"},
			{ID: "paragraph-1", Type: PostBlockTypeParagraph, Text: "Start near Panfilov Park."},
			{ID: "list-1", Type: PostBlockTypeBulletedList, Items: []PostListItem{{Text: "Coffee"}, {Text: "Museum"}}},
			{ID: "image-1", Type: PostBlockTypeImage, FileID: "file-1"},
			{ID: "gallery-1", Type: PostBlockTypeGallery, Images: []PostGalleryImage{{FileID: "file-2"}, {FileID: "file-3"}}},
			{ID: "divider-1", Type: PostBlockTypeDivider},
			{ID: "place-1", Type: PostBlockTypePlaceReference, PlaceName: "Kok-Tobe"},
		},
	}

	const expected = "Weekend in Almaty\nStart near Panfilov Park.\nCoffee\nMuseum\nKok-Tobe"

	if got := document.PlainText(); got != expected {
		t.Fatalf("PlainText() = %q, want %q", got, expected)
	}
}

func TestPostDocumentLegacyContent(t *testing.T) {
	document := PostDocument{
		Version: PostDocumentVersion,
		Blocks: []PostBlock{
			{ID: "heading-1", Type: PostBlockTypeHeading, Level: 1, Text: "Weekend in Almaty"},
			{ID: "paragraph-1", Type: PostBlockTypeParagraph, Text: "Start near Panfilov Park."},
			{ID: "list-1", Type: PostBlockTypeNumberedList, Items: []PostListItem{{Text: "Arrive"}, {Text: "Explore"}}},
			{ID: "image-1", Type: PostBlockTypeImage, FileID: "file-cover"},
			{ID: "gallery-1", Type: PostBlockTypeGallery, Images: []PostGalleryImage{{FileID: "file-1"}, {FileID: "file-2"}}},
			{ID: "quote-1", Type: PostBlockTypeQuote, Text: "Travel slowly."},
		},
	}

	const expected = "Weekend in Almaty\n\nStart near Panfilov Park.\n\n1. Arrive\n2. Explore\n\n[[post-image:file-cover]]\n\n[[post-image:file-1]]\n\n[[post-image:file-2]]\n\nTravel slowly."

	if got := document.LegacyContent(); got != expected {
		t.Fatalf("LegacyContent() = %q, want %q", got, expected)
	}
}

func TestPostDocumentLegacyContentUsesNormalizedSafeFileIDs(t *testing.T) {
	document := PostDocument{
		Version: PostDocumentVersion,
		Blocks: []PostBlock{
			{ID: "image-1", Type: PostBlockTypeImage, FileID: " file-cover "},
			{ID: "gallery-1", Type: PostBlockTypeGallery, Images: []PostGalleryImage{{FileID: " file-1 "}}},
		},
	}

	const expected = "[[post-image:file-cover]]\n\n[[post-image:file-1]]"

	if got := document.LegacyContent(); got != expected {
		t.Fatalf("LegacyContent() = %q, want %q", got, expected)
	}
}

func TestPostDocumentIsEmptyForPublish(t *testing.T) {
	tests := map[string]struct {
		document PostDocument
		want     bool
	}{
		"no blocks": {
			document: PostDocument{Version: PostDocumentVersion},
			want:     true,
		},
		"only whitespace text": {
			document: PostDocument{
				Version: PostDocumentVersion,
				Blocks:  []PostBlock{{ID: "paragraph-1", Type: PostBlockTypeParagraph, Text: " \n\t "}},
			},
			want: true,
		},
		"only divider": {
			document: PostDocument{
				Version: PostDocumentVersion,
				Blocks:  []PostBlock{{ID: "divider-1", Type: PostBlockTypeDivider}},
			},
			want: true,
		},
		"visible text": {
			document: PostDocument{
				Version: PostDocumentVersion,
				Blocks:  []PostBlock{{ID: "paragraph-1", Type: PostBlockTypeParagraph, Text: "hello"}},
			},
			want: false,
		},
		"image media": {
			document: PostDocument{
				Version: PostDocumentVersion,
				Blocks:  []PostBlock{{ID: "image-1", Type: PostBlockTypeImage, FileID: "file-1"}},
			},
			want: false,
		},
		"gallery media": {
			document: PostDocument{
				Version: PostDocumentVersion,
				Blocks:  []PostBlock{{ID: "gallery-1", Type: PostBlockTypeGallery, Images: []PostGalleryImage{{FileID: "file-1"}}}},
			},
			want: false,
		},
	}

	for name, tt := range tests {
		t.Run(name, func(t *testing.T) {
			if got := tt.document.IsEmptyForPublish(); got != tt.want {
				t.Fatalf("IsEmptyForPublish() = %v, want %v", got, tt.want)
			}
		})
	}
}

func TestPostDocumentJSONMarshalUnmarshal(t *testing.T) {
	document := PostDocument{
		Version: PostDocumentVersion,
		Blocks: []PostBlock{
			{
				ID:               "place-1",
				Type:             PostBlockTypePlaceReference,
				PlaceID:          "place-123",
				PlaceName:        "Kok-Tobe",
				PlaceCountryCode: "KZ",
				PlaceCityID:      "almaty",
			},
			{
				ID:    "paragraph-1",
				Type:  PostBlockTypeParagraph,
				Text:  "Official route",
				Marks: []PostInlineMark{{Type: PostInlineMarkTypeLink, URL: "https://example.com/route"}},
			},
		},
	}

	encoded, err := json.Marshal(document)
	if err != nil {
		t.Fatalf("json.Marshal() error = %v, want nil", err)
	}

	const expected = `{"version":1,"blocks":[{"id":"place-1","type":"place_reference","placeId":"place-123","placeName":"Kok-Tobe","placeCountryCode":"KZ","placeCityId":"almaty"},{"id":"paragraph-1","type":"paragraph","text":"Official route","marks":[{"type":"link","url":"https://example.com/route"}]}]}`
	if string(encoded) != expected {
		t.Fatalf("json.Marshal() = %s, want %s", encoded, expected)
	}

	var decoded PostDocument
	if err := json.Unmarshal(encoded, &decoded); err != nil {
		t.Fatalf("json.Unmarshal() error = %v, want nil", err)
	}
	if err := decoded.Validate(); err != nil {
		t.Fatalf("decoded Validate() error = %v, want nil", err)
	}
	if decoded.Blocks[0].PlaceCountryCode != "KZ" {
		t.Fatalf("PlaceCountryCode = %q, want KZ", decoded.Blocks[0].PlaceCountryCode)
	}
	if decoded.Blocks[0].PlaceCityID != "almaty" {
		t.Fatalf("PlaceCityID = %q, want almaty", decoded.Blocks[0].PlaceCityID)
	}
}

func blockID(index int) string {
	return "block-" + strings.Repeat("x", index+1)
}

func repeatPostBlocks(count int, build func(index int) PostBlock) []PostBlock {
	blocks := make([]PostBlock, 0, count)
	for index := 0; index < count; index++ {
		blocks = append(blocks, build(index))
	}
	return blocks
}

func repeatPostInlineMarks(count int) []PostInlineMark {
	marks := make([]PostInlineMark, 0, count)
	for index := 0; index < count; index++ {
		marks = append(marks, PostInlineMark{Type: PostInlineMarkTypeBold})
	}
	return marks
}

func repeatPostListItems(count int, text string) []PostListItem {
	items := make([]PostListItem, 0, count)
	for index := 0; index < count; index++ {
		items = append(items, PostListItem{Text: text})
	}
	return items
}

func repeatPostGalleryImages(count int) []PostGalleryImage {
	images := make([]PostGalleryImage, 0, count)
	for index := 0; index < count; index++ {
		images = append(images, PostGalleryImage{FileID: blockID(index)})
	}
	return images
}
