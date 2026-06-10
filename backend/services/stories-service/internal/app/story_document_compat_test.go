package app

import (
	"reflect"
	"testing"

	"github.com/google/uuid"

	"kz/inflap/backend/services/stories-service/internal/domain/model"
)

func TestStoryDocumentCompatTextOnlyContent(t *testing.T) {
	storyID := uuid.MustParse("11111111-1111-1111-1111-111111111111")

	document, err := LegacyStoryContentToDocument(storyID, "  First paragraph.\nStill first.\n\n\nSecond paragraph.  ")
	if err != nil {
		t.Fatalf("LegacyStoryContentToDocument() error = %v", err)
	}

	want := model.StoryDocument{
		Version: model.StoryDocumentVersion,
		Blocks: []model.StoryBlock{
			{
				ID:   "legacy-11111111-1111-1111-1111-111111111111-000001",
				Type: model.StoryBlockTypeParagraph,
				Text: "First paragraph.\nStill first.",
			},
			{
				ID:   "legacy-11111111-1111-1111-1111-111111111111-000002",
				Type: model.StoryBlockTypeParagraph,
				Text: "Second paragraph.",
			},
		},
	}
	assertStoryDocument(t, document, want)
}

func TestStoryDocumentCompatImageOnlyContent(t *testing.T) {
	storyID := uuid.MustParse("22222222-2222-2222-2222-222222222222")

	document, err := LegacyStoryContentToDocument(storyID, "\n[[story-image:file-1]]\n\n[[story-image:file_2.webp]]\n")
	if err != nil {
		t.Fatalf("LegacyStoryContentToDocument() error = %v", err)
	}

	want := model.StoryDocument{
		Version: model.StoryDocumentVersion,
		Blocks: []model.StoryBlock{
			{
				ID:     "legacy-22222222-2222-2222-2222-222222222222-000001",
				Type:   model.StoryBlockTypeImage,
				FileID: "file-1",
			},
			{
				ID:     "legacy-22222222-2222-2222-2222-222222222222-000002",
				Type:   model.StoryBlockTypeImage,
				FileID: "file_2.webp",
			},
		},
	}
	assertStoryDocument(t, document, want)
}

func TestStoryDocumentCompatMixedTextAndImages(t *testing.T) {
	storyID := uuid.MustParse("33333333-3333-3333-3333-333333333333")

	document, err := LegacyStoryContentToDocument(storyID, "Intro\n\n[[story-image:cover-123]]\n\nAfter image")
	if err != nil {
		t.Fatalf("LegacyStoryContentToDocument() error = %v", err)
	}

	want := model.StoryDocument{
		Version: model.StoryDocumentVersion,
		Blocks: []model.StoryBlock{
			{
				ID:   "legacy-33333333-3333-3333-3333-333333333333-000001",
				Type: model.StoryBlockTypeParagraph,
				Text: "Intro",
			},
			{
				ID:     "legacy-33333333-3333-3333-3333-333333333333-000002",
				Type:   model.StoryBlockTypeImage,
				FileID: "cover-123",
			},
			{
				ID:   "legacy-33333333-3333-3333-3333-333333333333-000003",
				Type: model.StoryBlockTypeParagraph,
				Text: "After image",
			},
		},
	}
	assertStoryDocument(t, document, want)
}

func TestStoryDocumentCompatMalformedMarkersBecomeText(t *testing.T) {
	storyID := uuid.MustParse("44444444-4444-4444-4444-444444444444")

	document, err := LegacyStoryContentToDocument(storyID, "[[story-image:missing-close]\n\n[[story-image:bad:id]]\n\n[[story-image:good]] trailing")
	if err != nil {
		t.Fatalf("LegacyStoryContentToDocument() error = %v", err)
	}

	want := model.StoryDocument{
		Version: model.StoryDocumentVersion,
		Blocks: []model.StoryBlock{
			{
				ID:   "legacy-44444444-4444-4444-4444-444444444444-000001",
				Type: model.StoryBlockTypeParagraph,
				Text: "[[story-image:missing-close]",
			},
			{
				ID:   "legacy-44444444-4444-4444-4444-444444444444-000002",
				Type: model.StoryBlockTypeParagraph,
				Text: "[[story-image:bad:id]]",
			},
			{
				ID:   "legacy-44444444-4444-4444-4444-444444444444-000003",
				Type: model.StoryBlockTypeParagraph,
				Text: "[[story-image:good]] trailing",
			},
		},
	}
	assertStoryDocument(t, document, want)
}

func TestStoryDocumentCompatEmptyContent(t *testing.T) {
	storyID := uuid.MustParse("55555555-5555-5555-5555-555555555555")

	document, err := LegacyStoryContentToDocument(storyID, " \n\t\n ")
	if err != nil {
		t.Fatalf("LegacyStoryContentToDocument() error = %v", err)
	}

	want := model.StoryDocument{Version: model.StoryDocumentVersion}
	assertStoryDocument(t, document, want)
}

func TestStoryDocumentCompatDeterministicIDs(t *testing.T) {
	storyID := uuid.MustParse("66666666-6666-6666-6666-666666666666")
	otherStoryID := uuid.MustParse("77777777-7777-7777-7777-777777777777")
	content := "Text\n\n[[story-image:file-1]]"

	first, err := LegacyStoryContentToDocument(storyID, content)
	if err != nil {
		t.Fatalf("LegacyStoryContentToDocument() first error = %v", err)
	}
	second, err := LegacyStoryContentToDocument(storyID, content)
	if err != nil {
		t.Fatalf("LegacyStoryContentToDocument() second error = %v", err)
	}
	other, err := LegacyStoryContentToDocument(otherStoryID, content)
	if err != nil {
		t.Fatalf("LegacyStoryContentToDocument() other error = %v", err)
	}

	assertStoryDocument(t, first, second)
	if first.Blocks[0].ID == other.Blocks[0].ID {
		t.Fatalf("block id must include story id: got same id %q", first.Blocks[0].ID)
	}
}

func TestStoryDocumentCompatDoesNotCreateUnsafeFileIDs(t *testing.T) {
	storyID := uuid.MustParse("88888888-8888-8888-8888-888888888888")

	document, err := LegacyStoryContentToDocument(storyID, "[[story-image:file-1]]\n\n[[story-image:file-2]][[story-image:file-3]]\n\n[[story-image:file 4]]")
	if err != nil {
		t.Fatalf("LegacyStoryContentToDocument() error = %v", err)
	}

	if len(document.Blocks) != 3 {
		t.Fatalf("blocks len = %d, want 3", len(document.Blocks))
	}
	if document.Blocks[0].Type != model.StoryBlockTypeImage || document.Blocks[0].FileID != "file-1" {
		t.Fatalf("first block = %+v, want safe image block", document.Blocks[0])
	}
	for _, block := range document.Blocks[1:] {
		if block.Type == model.StoryBlockTypeImage {
			t.Fatalf("unsafe marker became image block: %+v", block)
		}
		if block.FileID != "" {
			t.Fatalf("unsafe marker created file id %q", block.FileID)
		}
	}
}

func assertStoryDocument(t *testing.T, got model.StoryDocument, want model.StoryDocument) {
	t.Helper()

	if err := got.Validate(); err != nil {
		t.Fatalf("document does not validate: %v", err)
	}
	if got.Version != want.Version {
		t.Fatalf("version = %d, want %d", got.Version, want.Version)
	}
	if len(got.Blocks) != len(want.Blocks) {
		t.Fatalf("blocks len = %d, want %d; got %#v", len(got.Blocks), len(want.Blocks), got.Blocks)
	}
	for index := range got.Blocks {
		if !reflect.DeepEqual(got.Blocks[index], want.Blocks[index]) {
			t.Fatalf("block %d = %#v, want %#v", index, got.Blocks[index], want.Blocks[index])
		}
	}
}
