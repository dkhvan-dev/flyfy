package app

import (
	"context"
	"log/slog"
	"strings"
	"time"
)

const fallbackHelpArticleLocale = "ru"

type HelpSearchIndexer interface {
	UpsertSearchDocument(ctx context.Context, document SearchIndexDocument) error
	DeleteSearchDocument(ctx context.Context, deletion SearchIndexDelete) error
}

type SearchIndexDocument struct {
	Domain               string
	EntityID             string
	EntityVersion        int64
	Locale               string
	Title                map[string]string
	Subtitle             map[string]string
	Description          map[string]string
	Tags                 []string
	CategoryCodes        []string
	PopularityScore      float64
	FreshnessScore       float64
	TrustScore           float64
	AvailabilityStatus   string
	Visibility           string
	ModerationStatus     string
	DeepLink             string
	SearchText           string
	SearchTextNormalized string
	SearchVariants       []string
}

type SearchIndexDelete struct {
	Domain   string
	EntityID string
	Locale   string
}

func (uc *HelpUseCase) SetHelpSearchIndexer(indexer HelpSearchIndexer) {
	uc.searchIndexer = indexer
}

func (uc *HelpUseCase) syncHelpArticleSearchDocument(ctx context.Context, article HelpArticle) {
	if uc.searchIndexer == nil || strings.TrimSpace(article.ID) == "" {
		return
	}
	if !isHelpArticleSearchIndexable(article) {
		uc.deleteHelpArticleSearchDocument(ctx, article.ID)
		return
	}

	if err := uc.searchIndexer.UpsertSearchDocument(ctx, helpArticleSearchDocument(article)); err != nil {
		slog.Warn("failed to upsert help article search document", "error", err, "article_id", article.ID)
	}
}

func (uc *HelpUseCase) deleteHelpArticleSearchDocument(ctx context.Context, articleID string) {
	if uc.searchIndexer == nil || strings.TrimSpace(articleID) == "" {
		return
	}
	if err := uc.searchIndexer.DeleteSearchDocument(ctx, SearchIndexDelete{
		Domain:   "help_article",
		EntityID: strings.TrimSpace(articleID),
		Locale:   fallbackHelpArticleLocale,
	}); err != nil {
		slog.Warn("failed to delete help article search document", "error", err, "article_id", articleID)
	}
}

func isHelpArticleSearchIndexable(article HelpArticle) bool {
	return article.Status == ArticleStatusPublished &&
		containsSurface(article.Surfaces, HelpSurfaceHelpCenter) &&
		len(article.Translations) > 0
}

func helpArticleSearchDocument(article HelpArticle) SearchIndexDocument {
	title := make(map[string]string, len(article.Translations))
	subtitle := make(map[string]string, len(article.Translations))
	description := make(map[string]string, len(article.Translations))
	searchParts := make([]string, 0, len(article.Translations)*3+len(article.Tags)+len(article.Surfaces)+4)

	for locale, translation := range article.Translations {
		locale = normalizeLocale(locale)
		if locale == "" {
			continue
		}
		if value := strings.TrimSpace(translation.Title); value != "" {
			title[locale] = value
			searchParts = append(searchParts, value)
		}
		if value := strings.TrimSpace(translation.ShortAnswer); value != "" {
			subtitle[locale] = value
			searchParts = append(searchParts, value)
		}
		if value := strings.TrimSpace(translation.Body); value != "" {
			description[locale] = value
			searchParts = append(searchParts, value)
		}
	}

	tags := normalizeHelpArticleSearchList(article.Tags)
	categoryCodes := helpArticleSearchCategoryCodes(article)
	searchParts = append(searchParts, tags...)
	searchParts = append(searchParts, categoryCodes...)
	searchParts = append(searchParts, article.ID, article.Slug)
	for _, surface := range article.Surfaces {
		searchParts = append(searchParts, string(surface))
	}

	entityVersion := int64(article.Version)
	if entityVersion <= 0 {
		entityVersion = article.UpdatedAt.UnixNano()
	}
	if entityVersion <= 0 {
		entityVersion = 1
	}

	return SearchIndexDocument{
		Domain:             "help_article",
		EntityID:           strings.TrimSpace(article.ID),
		EntityVersion:      entityVersion,
		Locale:             fallbackHelpArticleLocale,
		Title:              title,
		Subtitle:           subtitle,
		Description:        description,
		Tags:               tags,
		CategoryCodes:      categoryCodes,
		PopularityScore:    0.45,
		FreshnessScore:     helpArticleFreshnessScore(article),
		TrustScore:         0.95,
		AvailabilityStatus: string(article.Status),
		Visibility:         "public",
		ModerationStatus:   "approved",
		DeepLink:           "/help?article=" + strings.TrimSpace(article.ID),
		SearchText:         strings.Join(searchParts, " "),
		SearchVariants:     helpArticleSearchVariants(article, tags, categoryCodes),
	}
}

func normalizeHelpArticleSearchList(values []string) []string {
	result := make([]string, 0, len(values))
	seen := make(map[string]struct{}, len(values))
	for _, value := range values {
		value = normalizeSearchText(value)
		if value == "" {
			continue
		}
		if _, ok := seen[value]; ok {
			continue
		}
		seen[value] = struct{}{}
		result = append(result, value)
	}
	return result
}

func helpArticleSearchCategoryCodes(article HelpArticle) []string {
	codes := make([]string, 0, 2)
	appendCode := func(value string) {
		value = normalizeSearchText(value)
		if value == "" || helpArticleContainsString(codes, value) {
			return
		}
		codes = append(codes, value)
	}
	appendCode(article.CategoryID)
	appendCode(strings.ReplaceAll(article.Slug, "-", " "))
	return codes
}

func helpArticleSearchVariants(article HelpArticle, tags []string, categoryCodes []string) []string {
	variants := make([]string, 0, len(article.Translations)+len(tags)+len(categoryCodes)+len(article.Surfaces)+1)
	appendVariant := func(value string) {
		value = normalizeSearchText(strings.ReplaceAll(value, "-", " "))
		if value == "" || helpArticleContainsString(variants, value) {
			return
		}
		variants = append(variants, value)
	}
	for _, translation := range article.Translations {
		appendVariant(translation.Title)
		appendVariant(translation.ShortAnswer)
	}
	for _, tag := range tags {
		appendVariant(tag)
	}
	for _, code := range categoryCodes {
		appendVariant(code)
	}
	for _, surface := range article.Surfaces {
		appendVariant(string(surface))
	}
	appendVariant(article.ID)
	return variants
}

func helpArticleFreshnessScore(article HelpArticle) float64 {
	if article.PublishedAt == nil || article.UpdatedAt.IsZero() {
		return 0.6
	}
	if article.UpdatedAt.Sub(*article.PublishedAt) > 90*24*time.Hour {
		return 0.7
	}
	return 0.8
}

func helpArticleContainsString(values []string, candidate string) bool {
	for _, value := range values {
		if value == candidate {
			return true
		}
	}
	return false
}
