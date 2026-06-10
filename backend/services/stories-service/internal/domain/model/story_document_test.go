package model

import (
	"encoding/json"
	"strings"
	"testing"
)

func TestStoryDocumentValidateAcceptsSupportedBlocks(t *testing.T) {
	document := StoryDocument{
		Version: StoryDocumentVersion,
		Blocks: []StoryBlock{
			{ID: "paragraph-1", Type: StoryBlockTypeParagraph, Text: "A calm walk through Almaty.", Marks: []StoryInlineMark{{Type: StoryInlineMarkTypeBold}, {Type: StoryInlineMarkTypeUnderline}, {Type: StoryInlineMarkTypeStrikethrough}}},
			{ID: "heading-1", Type: StoryBlockTypeHeading, Level: 2, Text: "Route"},
			{ID: "bullets-1", Type: StoryBlockTypeBulletedList, Items: []StoryListItem{{Text: "Coffee"}, {Text: "Museum"}}},
			{ID: "numbers-1", Type: StoryBlockTypeNumberedList, Items: []StoryListItem{{Text: "Arrive"}, {Text: "Explore"}}},
			{ID: "quote-1", Type: StoryBlockTypeQuote, Text: "Travel slowly."},
			{ID: "callout-1", Type: StoryBlockTypeCallout, Text: "Bring cash for small cafes."},
			{ID: "image-1", Type: StoryBlockTypeImage, FileID: "file-cover"},
			{ID: "gallery-1", Type: StoryBlockTypeGallery, Images: []StoryGalleryImage{{FileID: "file-1"}, {FileID: "file-2"}}},
			{ID: "divider-1", Type: StoryBlockTypeDivider},
			{ID: "place-1", Type: StoryBlockTypePlaceReference, PlaceID: "place-123", PlaceName: "Kok-Tobe"},
			{ID: "link-1", Type: StoryBlockTypeParagraph, Text: "Official route", Marks: []StoryInlineMark{{Type: StoryInlineMarkTypeLink, URL: "https://example.com/route"}}},
		},
	}

	if err := document.Validate(); err != nil {
		t.Fatalf("Validate() error = %v, want nil", err)
	}
}

func TestStoryDocumentValidateRejectsInvalidBlocks(t *testing.T) {
	longText := strings.Repeat("x", StoryDocumentMaxTextLength+1)

	tests := map[string]StoryDocument{
		"invalid version": {
			Version: 2,
			Blocks:  []StoryBlock{{ID: "paragraph-1", Type: StoryBlockTypeParagraph, Text: "hello"}},
		},
		"missing block id": {
			Version: StoryDocumentVersion,
			Blocks:  []StoryBlock{{Type: StoryBlockTypeParagraph, Text: "hello"}},
		},
		"duplicate block id": {
			Version: StoryDocumentVersion,
			Blocks: []StoryBlock{
				{ID: "paragraph-1", Type: StoryBlockTypeParagraph, Text: "hello"},
				{ID: "paragraph-1", Type: StoryBlockTypeQuote, Text: "again"},
			},
		},
		"text too long": {
			Version: StoryDocumentVersion,
			Blocks:  []StoryBlock{{ID: "paragraph-1", Type: StoryBlockTypeParagraph, Text: longText}},
		},
		"heading level too low": {
			Version: StoryDocumentVersion,
			Blocks:  []StoryBlock{{ID: "heading-1", Type: StoryBlockTypeHeading, Level: 0, Text: "Route"}},
		},
		"heading level too high": {
			Version: StoryDocumentVersion,
			Blocks:  []StoryBlock{{ID: "heading-1", Type: StoryBlockTypeHeading, Level: StoryDocumentMaxHeadingLevel + 1, Text: "Route"}},
		},
		"image without file id": {
			Version: StoryDocumentVersion,
			Blocks:  []StoryBlock{{ID: "image-1", Type: StoryBlockTypeImage}},
		},
		"empty gallery": {
			Version: StoryDocumentVersion,
			Blocks:  []StoryBlock{{ID: "gallery-1", Type: StoryBlockTypeGallery}},
		},
		"gallery image without file id": {
			Version: StoryDocumentVersion,
			Blocks:  []StoryBlock{{ID: "gallery-1", Type: StoryBlockTypeGallery, Images: []StoryGalleryImage{{FileID: "file-1"}, {}}}},
		},
		"unknown block type": {
			Version: StoryDocumentVersion,
			Blocks:  []StoryBlock{{ID: "custom-1", Type: StoryBlockType("custom"), Text: "hello"}},
		},
		"unknown inline mark": {
			Version: StoryDocumentVersion,
			Blocks:  []StoryBlock{{ID: "paragraph-1", Type: StoryBlockTypeParagraph, Text: "hello", Marks: []StoryInlineMark{{Type: StoryInlineMarkType("highlight")}}}},
		},
		"too many blocks": {
			Version: StoryDocumentVersion,
			Blocks:  repeatStoryBlocks(StoryDocumentMaxBlockCount+1, func(index int) StoryBlock { return StoryBlock{ID: blockID(index), Type: StoryBlockTypeDivider} }),
		},
		"too many inline marks": {
			Version: StoryDocumentVersion,
			Blocks: []StoryBlock{{
				ID:    "paragraph-1",
				Type:  StoryBlockTypeParagraph,
				Text:  "hello",
				Marks: repeatStoryInlineMarks(StoryDocumentMaxInlineMarksPerTextBlock + 1),
			}},
		},
		"too many list items": {
			Version: StoryDocumentVersion,
			Blocks: []StoryBlock{{
				ID:    "list-1",
				Type:  StoryBlockTypeBulletedList,
				Items: repeatStoryListItems(StoryDocumentMaxListItems+1, "item"),
			}},
		},
		"blank list item": {
			Version: StoryDocumentVersion,
			Blocks:  []StoryBlock{{ID: "list-1", Type: StoryBlockTypeBulletedList, Items: []StoryListItem{{Text: "First"}, {Text: "  \n\t"}}}},
		},
		"list item too long": {
			Version: StoryDocumentVersion,
			Blocks:  []StoryBlock{{ID: "list-1", Type: StoryBlockTypeNumberedList, Items: []StoryListItem{{Text: strings.Repeat("x", StoryDocumentMaxListItemTextLength+1)}}}},
		},
		"too many gallery images": {
			Version: StoryDocumentVersion,
			Blocks: []StoryBlock{{
				ID:     "gallery-1",
				Type:   StoryBlockTypeGallery,
				Images: repeatStoryGalleryImages(StoryDocumentMaxGalleryImages + 1),
			}},
		},
		"place reference without id or name": {
			Version: StoryDocumentVersion,
			Blocks:  []StoryBlock{{ID: "place-1", Type: StoryBlockTypePlaceReference}},
		},
		"place id too long": {
			Version: StoryDocumentVersion,
			Blocks:  []StoryBlock{{ID: "place-1", Type: StoryBlockTypePlaceReference, PlaceID: strings.Repeat("p", StoryDocumentMaxPlaceIDLength+1)}},
		},
		"place name too long": {
			Version: StoryDocumentVersion,
			Blocks:  []StoryBlock{{ID: "place-1", Type: StoryBlockTypePlaceReference, PlaceName: strings.Repeat("p", StoryDocumentMaxPlaceNameLength+1)}},
		},
		"place country too long": {
			Version: StoryDocumentVersion,
			Blocks:  []StoryBlock{{ID: "place-1", Type: StoryBlockTypePlaceReference, PlaceID: "place-1", PlaceCountryCode: strings.Repeat("K", StoryDocumentMaxPlaceCountryCodeLength+1)}},
		},
		"place city too long": {
			Version: StoryDocumentVersion,
			Blocks:  []StoryBlock{{ID: "place-1", Type: StoryBlockTypePlaceReference, PlaceID: "place-1", PlaceCityID: strings.Repeat("c", StoryDocumentMaxPlaceCityIDLength+1)}},
		},
		"bold mark with url": {
			Version: StoryDocumentVersion,
			Blocks:  []StoryBlock{{ID: "paragraph-1", Type: StoryBlockTypeParagraph, Text: "hello", Marks: []StoryInlineMark{{Type: StoryInlineMarkTypeBold, URL: "https://example.com"}}}},
		},
		"italic mark with url": {
			Version: StoryDocumentVersion,
			Blocks:  []StoryBlock{{ID: "paragraph-1", Type: StoryBlockTypeParagraph, Text: "hello", Marks: []StoryInlineMark{{Type: StoryInlineMarkTypeItalic, URL: "https://example.com"}}}},
		},
		"underline mark with url": {
			Version: StoryDocumentVersion,
			Blocks:  []StoryBlock{{ID: "paragraph-1", Type: StoryBlockTypeParagraph, Text: "hello", Marks: []StoryInlineMark{{Type: StoryInlineMarkTypeUnderline, URL: "https://example.com"}}}},
		},
		"strikethrough mark with url": {
			Version: StoryDocumentVersion,
			Blocks:  []StoryBlock{{ID: "paragraph-1", Type: StoryBlockTypeParagraph, Text: "hello", Marks: []StoryInlineMark{{Type: StoryInlineMarkTypeStrikethrough, URL: "https://example.com"}}}},
		},
		"image file id with control character": {
			Version: StoryDocumentVersion,
			Blocks:  []StoryBlock{{ID: "image-1", Type: StoryBlockTypeImage, FileID: "file\n1"}},
		},
		"image file id with legacy marker injection": {
			Version: StoryDocumentVersion,
			Blocks:  []StoryBlock{{ID: "image-1", Type: StoryBlockTypeImage, FileID: "file-1]]\n[[story-image:file-2"}},
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

func TestStoryDocumentValidateRejectsUnsafeLinks(t *testing.T) {
	tests := map[string]string{
		"javascript":     "javascript:alert(1)",
		"mailto":         "mailto:hello@example.com",
		"relative":       "/stories/1",
		"empty":          "",
		"control chars":  "https://example.com/\npath",
		"user info":      "https://user:pass@example.com/path",
		"blank host":     "https:///path",
		"excessive size": "https://example.com/" + strings.Repeat("x", StoryDocumentMaxURLLength+1),
	}

	for name, rawURL := range tests {
		t.Run(name, func(t *testing.T) {
			document := StoryDocument{
				Version: StoryDocumentVersion,
				Blocks: []StoryBlock{
					{
						ID:    "paragraph-1",
						Type:  StoryBlockTypeParagraph,
						Text:  "unsafe",
						Marks: []StoryInlineMark{{Type: StoryInlineMarkTypeLink, URL: rawURL}},
					},
				},
			}

			if err := document.Validate(); err == nil {
				t.Fatal("Validate() error = nil, want error")
			}
		})
	}
}

func TestStoryDocumentValidateRejectsInactiveFields(t *testing.T) {
	tests := map[string]StoryBlock{
		"divider with text": {
			ID:   "divider-1",
			Type: StoryBlockTypeDivider,
			Text: "hidden text",
		},
		"divider with items": {
			ID:    "divider-1",
			Type:  StoryBlockTypeDivider,
			Items: []StoryListItem{{Text: "hidden item"}},
		},
		"divider with images": {
			ID:     "divider-1",
			Type:   StoryBlockTypeDivider,
			Images: []StoryGalleryImage{{FileID: "file-1"}},
		},
		"divider with file id": {
			ID:     "divider-1",
			Type:   StoryBlockTypeDivider,
			FileID: "file-1",
		},
		"divider with place fields": {
			ID:        "divider-1",
			Type:      StoryBlockTypeDivider,
			PlaceName: "Hidden place",
		},
		"text block with inactive items": {
			ID:    "paragraph-1",
			Type:  StoryBlockTypeParagraph,
			Text:  "visible",
			Items: []StoryListItem{{Text: "hidden item"}},
		},
		"text block with inactive images": {
			ID:     "paragraph-1",
			Type:   StoryBlockTypeParagraph,
			Text:   "visible",
			Images: []StoryGalleryImage{{FileID: "file-1"}},
		},
		"text block with inactive file id": {
			ID:     "paragraph-1",
			Type:   StoryBlockTypeParagraph,
			Text:   "visible",
			FileID: "file-1",
		},
		"text block with inactive place fields": {
			ID:        "paragraph-1",
			Type:      StoryBlockTypeParagraph,
			Text:      "visible",
			PlaceName: "Hidden place",
		},
		"list block with inactive place field": {
			ID:        "list-1",
			Type:      StoryBlockTypeNumberedList,
			Items:     []StoryListItem{{Text: "visible"}},
			PlaceName: "Hidden place",
		},
		"place block with inactive text": {
			ID:        "place-1",
			Type:      StoryBlockTypePlaceReference,
			Text:      "hidden text",
			PlaceName: "Kok-Tobe",
		},
		"place block with inactive media": {
			ID:        "place-1",
			Type:      StoryBlockTypePlaceReference,
			PlaceName: "Kok-Tobe",
			FileID:    "file-1",
		},
		"place block with inactive list": {
			ID:        "place-1",
			Type:      StoryBlockTypePlaceReference,
			PlaceName: "Kok-Tobe",
			Items:     []StoryListItem{{Text: "hidden item"}},
		},
	}

	for name, block := range tests {
		t.Run(name, func(t *testing.T) {
			document := StoryDocument{
				Version: StoryDocumentVersion,
				Blocks:  []StoryBlock{block},
			}

			if err := document.Validate(); err == nil {
				t.Fatal("Validate() error = nil, want error")
			}
		})
	}
}

func TestStoryDocumentValidateAcceptsPlaceReferenceFields(t *testing.T) {
	document := StoryDocument{
		Version: StoryDocumentVersion,
		Blocks: []StoryBlock{{
			ID:               "place-1",
			Type:             StoryBlockTypePlaceReference,
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

func TestStoryDocumentValidateAcceptsTrimmedIDsAndURLs(t *testing.T) {
	document := StoryDocument{
		Version: StoryDocumentVersion,
		Blocks: []StoryBlock{
			{ID: " paragraph-1 ", Type: StoryBlockTypeParagraph, Text: "Official route", Marks: []StoryInlineMark{{Type: StoryInlineMarkTypeLink, URL: " https://example.com/route "}}},
			{ID: " image-1 ", Type: StoryBlockTypeImage, FileID: " file-cover "},
			{ID: " place-1 ", Type: StoryBlockTypePlaceReference, PlaceID: " place-123 ", PlaceName: " Kok-Tobe "},
		},
	}

	if err := document.Validate(); err != nil {
		t.Fatalf("Validate() error = %v, want nil", err)
	}
}

func TestStoryDocumentPlainText(t *testing.T) {
	document := StoryDocument{
		Version: StoryDocumentVersion,
		Blocks: []StoryBlock{
			{ID: "heading-1", Type: StoryBlockTypeHeading, Level: 1, Text: "Weekend in Almaty"},
			{ID: "paragraph-1", Type: StoryBlockTypeParagraph, Text: "Start near Panfilov Park."},
			{ID: "list-1", Type: StoryBlockTypeBulletedList, Items: []StoryListItem{{Text: "Coffee"}, {Text: "Museum"}}},
			{ID: "image-1", Type: StoryBlockTypeImage, FileID: "file-1"},
			{ID: "gallery-1", Type: StoryBlockTypeGallery, Images: []StoryGalleryImage{{FileID: "file-2"}, {FileID: "file-3"}}},
			{ID: "divider-1", Type: StoryBlockTypeDivider},
			{ID: "place-1", Type: StoryBlockTypePlaceReference, PlaceName: "Kok-Tobe"},
		},
	}

	const expected = "Weekend in Almaty\nStart near Panfilov Park.\nCoffee\nMuseum\nKok-Tobe"

	if got := document.PlainText(); got != expected {
		t.Fatalf("PlainText() = %q, want %q", got, expected)
	}
}

func TestStoryDocumentLegacyContent(t *testing.T) {
	document := StoryDocument{
		Version: StoryDocumentVersion,
		Blocks: []StoryBlock{
			{ID: "heading-1", Type: StoryBlockTypeHeading, Level: 1, Text: "Weekend in Almaty"},
			{ID: "paragraph-1", Type: StoryBlockTypeParagraph, Text: "Start near Panfilov Park."},
			{ID: "list-1", Type: StoryBlockTypeNumberedList, Items: []StoryListItem{{Text: "Arrive"}, {Text: "Explore"}}},
			{ID: "image-1", Type: StoryBlockTypeImage, FileID: "file-cover"},
			{ID: "gallery-1", Type: StoryBlockTypeGallery, Images: []StoryGalleryImage{{FileID: "file-1"}, {FileID: "file-2"}}},
			{ID: "quote-1", Type: StoryBlockTypeQuote, Text: "Travel slowly."},
		},
	}

	const expected = "Weekend in Almaty\n\nStart near Panfilov Park.\n\n1. Arrive\n2. Explore\n\n[[story-image:file-cover]]\n\n[[story-image:file-1]]\n\n[[story-image:file-2]]\n\nTravel slowly."

	if got := document.LegacyContent(); got != expected {
		t.Fatalf("LegacyContent() = %q, want %q", got, expected)
	}
}

func TestStoryDocumentLegacyContentUsesNormalizedSafeFileIDs(t *testing.T) {
	document := StoryDocument{
		Version: StoryDocumentVersion,
		Blocks: []StoryBlock{
			{ID: "image-1", Type: StoryBlockTypeImage, FileID: " file-cover "},
			{ID: "gallery-1", Type: StoryBlockTypeGallery, Images: []StoryGalleryImage{{FileID: " file-1 "}}},
		},
	}

	const expected = "[[story-image:file-cover]]\n\n[[story-image:file-1]]"

	if got := document.LegacyContent(); got != expected {
		t.Fatalf("LegacyContent() = %q, want %q", got, expected)
	}
}

func TestStoryDocumentIsEmptyForPublish(t *testing.T) {
	tests := map[string]struct {
		document StoryDocument
		want     bool
	}{
		"no blocks": {
			document: StoryDocument{Version: StoryDocumentVersion},
			want:     true,
		},
		"only whitespace text": {
			document: StoryDocument{
				Version: StoryDocumentVersion,
				Blocks:  []StoryBlock{{ID: "paragraph-1", Type: StoryBlockTypeParagraph, Text: " \n\t "}},
			},
			want: true,
		},
		"only divider": {
			document: StoryDocument{
				Version: StoryDocumentVersion,
				Blocks:  []StoryBlock{{ID: "divider-1", Type: StoryBlockTypeDivider}},
			},
			want: true,
		},
		"visible text": {
			document: StoryDocument{
				Version: StoryDocumentVersion,
				Blocks:  []StoryBlock{{ID: "paragraph-1", Type: StoryBlockTypeParagraph, Text: "hello"}},
			},
			want: false,
		},
		"image media": {
			document: StoryDocument{
				Version: StoryDocumentVersion,
				Blocks:  []StoryBlock{{ID: "image-1", Type: StoryBlockTypeImage, FileID: "file-1"}},
			},
			want: false,
		},
		"gallery media": {
			document: StoryDocument{
				Version: StoryDocumentVersion,
				Blocks:  []StoryBlock{{ID: "gallery-1", Type: StoryBlockTypeGallery, Images: []StoryGalleryImage{{FileID: "file-1"}}}},
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

func TestStoryDocumentJSONMarshalUnmarshal(t *testing.T) {
	document := StoryDocument{
		Version: StoryDocumentVersion,
		Blocks: []StoryBlock{
			{
				ID:               "place-1",
				Type:             StoryBlockTypePlaceReference,
				PlaceID:          "place-123",
				PlaceName:        "Kok-Tobe",
				PlaceCountryCode: "KZ",
				PlaceCityID:      "almaty",
			},
			{
				ID:    "paragraph-1",
				Type:  StoryBlockTypeParagraph,
				Text:  "Official route",
				Marks: []StoryInlineMark{{Type: StoryInlineMarkTypeLink, URL: "https://example.com/route"}},
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

	var decoded StoryDocument
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

func repeatStoryBlocks(count int, build func(index int) StoryBlock) []StoryBlock {
	blocks := make([]StoryBlock, 0, count)
	for index := 0; index < count; index++ {
		blocks = append(blocks, build(index))
	}
	return blocks
}

func repeatStoryInlineMarks(count int) []StoryInlineMark {
	marks := make([]StoryInlineMark, 0, count)
	for index := 0; index < count; index++ {
		marks = append(marks, StoryInlineMark{Type: StoryInlineMarkTypeBold})
	}
	return marks
}

func repeatStoryListItems(count int, text string) []StoryListItem {
	items := make([]StoryListItem, 0, count)
	for index := 0; index < count; index++ {
		items = append(items, StoryListItem{Text: text})
	}
	return items
}

func repeatStoryGalleryImages(count int) []StoryGalleryImage {
	images := make([]StoryGalleryImage, 0, count)
	for index := 0; index < count; index++ {
		images = append(images, StoryGalleryImage{FileID: blockID(index)})
	}
	return images
}
