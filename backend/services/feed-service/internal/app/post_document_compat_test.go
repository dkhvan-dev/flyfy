package app

import (
	"reflect"
	"testing"

	"github.com/google/uuid"

	"kz/inflap/backend/services/feed-service/internal/domain/model"
)

func TestPostDocumentCompatTextOnlyContent(t *testing.T) {
	postID := uuid.MustParse("11111111-1111-1111-1111-111111111111")

	document, err := LegacyPostContentToDocument(postID, "  First paragraph.\nStill first.\n\n\nSecond paragraph.  ")
	if err != nil {
		t.Fatalf("LegacyPostContentToDocument() error = %v", err)
	}

	want := model.PostDocument{
		Version: model.PostDocumentVersion,
		Blocks: []model.PostBlock{
			{
				ID:   "legacy-11111111-1111-1111-1111-111111111111-000001",
				Type: model.PostBlockTypeParagraph,
				Text: "First paragraph.\nStill first.",
			},
			{
				ID:   "legacy-11111111-1111-1111-1111-111111111111-000002",
				Type: model.PostBlockTypeParagraph,
				Text: "Second paragraph.",
			},
		},
	}
	assertPostDocument(t, document, want)
}

func TestPostDocumentCompatImageOnlyContent(t *testing.T) {
	postID := uuid.MustParse("22222222-2222-2222-2222-222222222222")

	document, err := LegacyPostContentToDocument(postID, "\n[[post-image:file-1]]\n\n[[post-image:file_2.webp]]\n")
	if err != nil {
		t.Fatalf("LegacyPostContentToDocument() error = %v", err)
	}

	want := model.PostDocument{
		Version: model.PostDocumentVersion,
		Blocks: []model.PostBlock{
			{
				ID:     "legacy-22222222-2222-2222-2222-222222222222-000001",
				Type:   model.PostBlockTypeImage,
				FileID: "file-1",
			},
			{
				ID:     "legacy-22222222-2222-2222-2222-222222222222-000002",
				Type:   model.PostBlockTypeImage,
				FileID: "file_2.webp",
			},
		},
	}
	assertPostDocument(t, document, want)
}

func TestPostDocumentCompatMixedTextAndImages(t *testing.T) {
	postID := uuid.MustParse("33333333-3333-3333-3333-333333333333")

	document, err := LegacyPostContentToDocument(postID, "Intro\n\n[[post-image:cover-123]]\n\nAfter image")
	if err != nil {
		t.Fatalf("LegacyPostContentToDocument() error = %v", err)
	}

	want := model.PostDocument{
		Version: model.PostDocumentVersion,
		Blocks: []model.PostBlock{
			{
				ID:   "legacy-33333333-3333-3333-3333-333333333333-000001",
				Type: model.PostBlockTypeParagraph,
				Text: "Intro",
			},
			{
				ID:     "legacy-33333333-3333-3333-3333-333333333333-000002",
				Type:   model.PostBlockTypeImage,
				FileID: "cover-123",
			},
			{
				ID:   "legacy-33333333-3333-3333-3333-333333333333-000003",
				Type: model.PostBlockTypeParagraph,
				Text: "After image",
			},
		},
	}
	assertPostDocument(t, document, want)
}

func TestPostDocumentCompatMalformedMarkersBecomeText(t *testing.T) {
	postID := uuid.MustParse("44444444-4444-4444-4444-444444444444")

	document, err := LegacyPostContentToDocument(postID, "[[post-image:missing-close]\n\n[[post-image:bad:id]]\n\n[[post-image:good]] trailing")
	if err != nil {
		t.Fatalf("LegacyPostContentToDocument() error = %v", err)
	}

	want := model.PostDocument{
		Version: model.PostDocumentVersion,
		Blocks: []model.PostBlock{
			{
				ID:   "legacy-44444444-4444-4444-4444-444444444444-000001",
				Type: model.PostBlockTypeParagraph,
				Text: "[[post-image:missing-close]",
			},
			{
				ID:   "legacy-44444444-4444-4444-4444-444444444444-000002",
				Type: model.PostBlockTypeParagraph,
				Text: "[[post-image:bad:id]]",
			},
			{
				ID:   "legacy-44444444-4444-4444-4444-444444444444-000003",
				Type: model.PostBlockTypeParagraph,
				Text: "[[post-image:good]] trailing",
			},
		},
	}
	assertPostDocument(t, document, want)
}

func TestPostDocumentCompatEmptyContent(t *testing.T) {
	postID := uuid.MustParse("55555555-5555-5555-5555-555555555555")

	document, err := LegacyPostContentToDocument(postID, " \n\t\n ")
	if err != nil {
		t.Fatalf("LegacyPostContentToDocument() error = %v", err)
	}

	want := model.PostDocument{Version: model.PostDocumentVersion}
	assertPostDocument(t, document, want)
}

func TestPostDocumentCompatDeterministicIDs(t *testing.T) {
	postID := uuid.MustParse("66666666-6666-6666-6666-666666666666")
	otherPostID := uuid.MustParse("77777777-7777-7777-7777-777777777777")
	content := "Text\n\n[[post-image:file-1]]"

	first, err := LegacyPostContentToDocument(postID, content)
	if err != nil {
		t.Fatalf("LegacyPostContentToDocument() first error = %v", err)
	}
	second, err := LegacyPostContentToDocument(postID, content)
	if err != nil {
		t.Fatalf("LegacyPostContentToDocument() second error = %v", err)
	}
	other, err := LegacyPostContentToDocument(otherPostID, content)
	if err != nil {
		t.Fatalf("LegacyPostContentToDocument() other error = %v", err)
	}

	assertPostDocument(t, first, second)
	if first.Blocks[0].ID == other.Blocks[0].ID {
		t.Fatalf("block id must include post id: got same id %q", first.Blocks[0].ID)
	}
}

func TestPostDocumentCompatDoesNotCreateUnsafeFileIDs(t *testing.T) {
	postID := uuid.MustParse("88888888-8888-8888-8888-888888888888")

	document, err := LegacyPostContentToDocument(postID, "[[post-image:file-1]]\n\n[[post-image:file-2]][[post-image:file-3]]\n\n[[post-image:file 4]]")
	if err != nil {
		t.Fatalf("LegacyPostContentToDocument() error = %v", err)
	}

	if len(document.Blocks) != 3 {
		t.Fatalf("blocks len = %d, want 3", len(document.Blocks))
	}
	if document.Blocks[0].Type != model.PostBlockTypeImage || document.Blocks[0].FileID != "file-1" {
		t.Fatalf("first block = %+v, want safe image block", document.Blocks[0])
	}
	for _, block := range document.Blocks[1:] {
		if block.Type == model.PostBlockTypeImage {
			t.Fatalf("unsafe marker became image block: %+v", block)
		}
		if block.FileID != "" {
			t.Fatalf("unsafe marker created file id %q", block.FileID)
		}
	}
}

func assertPostDocument(t *testing.T, got model.PostDocument, want model.PostDocument) {
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
