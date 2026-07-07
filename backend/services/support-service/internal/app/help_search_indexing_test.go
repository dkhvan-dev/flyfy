package app

import (
	"context"
	"testing"
	"time"
)

func TestHelpArticleSearchDocumentIncludesLocalizedContent(t *testing.T) {
	article := helpSearchTestArticle(ArticleStatusPublished)

	if !isHelpArticleSearchIndexable(article) {
		t.Fatal("published help-center article should be search indexable")
	}

	doc := helpArticleSearchDocument(article)
	if doc.Domain != "help_article" || doc.EntityID != article.ID {
		t.Fatalf("identity = %s/%s, want help_article/%s", doc.Domain, doc.EntityID, article.ID)
	}
	if doc.Locale != "ru" {
		t.Fatalf("locale = %q, want ru", doc.Locale)
	}
	if doc.Title["ru"] != "Как отменить активность?" || doc.Title["en"] != "How do I cancel an activity?" {
		t.Fatalf("title = %#v", doc.Title)
	}
	if doc.Subtitle["ru"] == "" || doc.Description["en"] == "" {
		t.Fatalf("localized subtitle/description missing: %#v %#v", doc.Subtitle, doc.Description)
	}
	if doc.DeepLink != "/help?article=activity-cancel-paid" {
		t.Fatalf("deep link = %q", doc.DeepLink)
	}
	if !helpArticleContainsString(doc.Tags, "activities") || !helpArticleContainsString(doc.CategoryCodes, "payments") {
		t.Fatalf("tags/categories = %#v/%#v", doc.Tags, doc.CategoryCodes)
	}
	if doc.SearchText == "" || len(doc.SearchVariants) == 0 {
		t.Fatalf("search text/variants = %q/%#v", doc.SearchText, doc.SearchVariants)
	}
}

func TestBackfillHelpArticleSearchIndexReconcilesDocuments(t *testing.T) {
	repo := &helpArticleSearchBackfillRepoStub{
		pages: [][]HelpArticle{
			{helpSearchTestArticle(ArticleStatusPublished)},
			{helpSearchTestArticle(ArticleStatusArchived)},
		},
	}
	indexer := &helpSearchIndexerStub{}

	stats, err := BackfillHelpArticleSearchIndex(context.Background(), repo, indexer, SearchIndexBackfillOptions{
		BatchSize:   1,
		DeleteStale: true,
	})
	if err != nil {
		t.Fatalf("BackfillHelpArticleSearchIndex() error = %v", err)
	}

	if stats.Scanned != 2 || stats.Upserted != 1 || stats.Deleted != 1 || stats.Skipped != 0 || stats.Failed != 0 {
		t.Fatalf("stats = %#v", stats)
	}
	if len(indexer.upserts) != 1 {
		t.Fatalf("upserts = %d, want 1", len(indexer.upserts))
	}
	if len(indexer.deletes) != 1 {
		t.Fatalf("deletes = %d, want 1", len(indexer.deletes))
	}
}

func TestBackfillHelpArticleSearchIndexDryRunDoesNotPublish(t *testing.T) {
	repo := &helpArticleSearchBackfillRepoStub{
		pages: [][]HelpArticle{{helpSearchTestArticle(ArticleStatusPublished)}},
	}
	indexer := &helpSearchIndexerStub{}

	stats, err := BackfillHelpArticleSearchIndex(context.Background(), repo, indexer, SearchIndexBackfillOptions{
		DryRun: true,
	})
	if err != nil {
		t.Fatalf("BackfillHelpArticleSearchIndex() error = %v", err)
	}
	if stats.Scanned != 1 || stats.Upserted != 1 || stats.Deleted != 0 {
		t.Fatalf("stats = %#v", stats)
	}
	if len(indexer.upserts) != 0 || len(indexer.deletes) != 0 {
		t.Fatalf("dry run published upserts=%d deletes=%d, want none", len(indexer.upserts), len(indexer.deletes))
	}
}

func helpSearchTestArticle(status ArticleStatus) HelpArticle {
	now := time.Unix(1000, 0).UTC()
	return HelpArticle{
		ID:         "activity-cancel-paid",
		CategoryID: "payments",
		Slug:       "activity-cancel-paid",
		Status:     status,
		Version:    3,
		Tags:       []string{"Activities", "Payments"},
		Surfaces:   []HelpSurface{HelpSurfaceHelpCenter, HelpSurfaceActivityDetails},
		Translations: map[string]ArticleTranslation{
			"ru": {
				Title:       "Как отменить активность?",
				ShortAnswer: "Откройте бронирование и проверьте условия возврата.",
				Body:        "Возврат зависит от времени до старта активности и способа оплаты.",
			},
			"en": {
				Title:       "How do I cancel an activity?",
				ShortAnswer: "Open the booking and check the refund policy.",
				Body:        "Refund availability depends on activity start time and payment state.",
			},
			"kk": {
				Title:       "Белсенділікті қалай тоқтатамын?",
				ShortAnswer: "Брондауды ашып, қайтару шарттарын тексеріңіз.",
				Body:        "Қайтару белсенділік басталу уақытына және төлем күйіне байланысты.",
			},
		},
		PublishedAt: &now,
		UpdatedAt:   now,
	}
}

type helpSearchIndexerStub struct {
	upserts []SearchIndexDocument
	deletes []SearchIndexDelete
}

func (s *helpSearchIndexerStub) UpsertSearchDocument(_ context.Context, document SearchIndexDocument) error {
	s.upserts = append(s.upserts, document)
	return nil
}

func (s *helpSearchIndexerStub) DeleteSearchDocument(_ context.Context, deletion SearchIndexDelete) error {
	s.deletes = append(s.deletes, deletion)
	return nil
}

type helpArticleSearchBackfillRepoStub struct {
	pages     [][]HelpArticle
	listCalls []HelpArticleFilter
}

func (s *helpArticleSearchBackfillRepoStub) ListAdminArticles(
	_ context.Context,
	filter HelpArticleFilter,
) ([]HelpArticle, error) {
	s.listCalls = append(s.listCalls, filter)
	index := len(s.listCalls) - 1
	if index >= len(s.pages) {
		return nil, nil
	}
	return s.pages[index], nil
}
