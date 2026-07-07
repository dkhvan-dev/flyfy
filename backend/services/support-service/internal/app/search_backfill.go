package app

import (
	"context"
	"errors"
	"fmt"
)

const defaultSearchIndexBackfillBatchSize = 100
const maxSearchIndexBackfillBatchSize = 500

var (
	ErrSearchBackfillRepositoryRequired = errors.New("search backfill repository is required")
	ErrSearchBackfillIndexerRequired    = errors.New("search backfill indexer is required")
)

type HelpArticleSearchBackfillRepository interface {
	ListAdminArticles(ctx context.Context, filter HelpArticleFilter) ([]HelpArticle, error)
}

type SearchIndexBackfillOptions struct {
	BatchSize   int
	Limit       int
	DryRun      bool
	DeleteStale bool
}

type SearchIndexBackfillStats struct {
	Scanned  int
	Upserted int
	Deleted  int
	Skipped  int
	Failed   int
}

func BackfillHelpArticleSearchIndex(
	ctx context.Context,
	repo HelpArticleSearchBackfillRepository,
	indexer HelpSearchIndexer,
	options SearchIndexBackfillOptions,
) (SearchIndexBackfillStats, error) {
	if repo == nil {
		return SearchIndexBackfillStats{}, ErrSearchBackfillRepositoryRequired
	}
	if indexer == nil && !options.DryRun {
		return SearchIndexBackfillStats{}, ErrSearchBackfillIndexerRequired
	}

	options = normalizeSearchIndexBackfillOptions(options)
	var stats SearchIndexBackfillStats
	offset := 0

	for {
		limit := nextSearchIndexBackfillLimit(options, stats.Scanned)
		if limit <= 0 {
			return stats, nil
		}

		items, err := repo.ListAdminArticles(ctx, HelpArticleFilter{
			Limit:  limit,
			Offset: offset,
		})
		if err != nil {
			stats.Failed++
			return stats, fmt.Errorf("list help articles for search backfill: %w", err)
		}
		if len(items) == 0 {
			return stats, nil
		}

		for _, item := range items {
			stats.Scanned++
			if err = backfillHelpArticleSearchDocument(ctx, indexer, options, item, &stats); err != nil {
				return stats, err
			}
			if options.Limit > 0 && stats.Scanned >= options.Limit {
				return stats, nil
			}
		}

		offset += len(items)
		if len(items) < limit {
			return stats, nil
		}
	}
}

func backfillHelpArticleSearchDocument(
	ctx context.Context,
	indexer HelpSearchIndexer,
	options SearchIndexBackfillOptions,
	article HelpArticle,
	stats *SearchIndexBackfillStats,
) error {
	if isHelpArticleSearchIndexable(article) {
		if !options.DryRun {
			if err := indexer.UpsertSearchDocument(ctx, helpArticleSearchDocument(article)); err != nil {
				stats.Failed++
				return fmt.Errorf("upsert help article search document: %w", err)
			}
		}
		stats.Upserted++
		return nil
	}

	if !options.DeleteStale {
		stats.Skipped++
		return nil
	}

	if !options.DryRun {
		if err := indexer.DeleteSearchDocument(ctx, SearchIndexDelete{
			Domain:   "help_article",
			EntityID: article.ID,
			Locale:   fallbackHelpArticleLocale,
		}); err != nil {
			stats.Failed++
			return fmt.Errorf("delete stale help article search document: %w", err)
		}
	}
	stats.Deleted++
	return nil
}

func normalizeSearchIndexBackfillOptions(options SearchIndexBackfillOptions) SearchIndexBackfillOptions {
	if options.BatchSize <= 0 {
		options.BatchSize = defaultSearchIndexBackfillBatchSize
	}
	if options.BatchSize > maxSearchIndexBackfillBatchSize {
		options.BatchSize = maxSearchIndexBackfillBatchSize
	}
	if options.Limit < 0 {
		options.Limit = 0
	}
	return options
}

func nextSearchIndexBackfillLimit(options SearchIndexBackfillOptions, scanned int) int {
	limit := options.BatchSize
	if options.Limit > 0 {
		remaining := options.Limit - scanned
		if remaining <= 0 {
			return 0
		}
		if remaining < limit {
			limit = remaining
		}
	}
	return limit
}
