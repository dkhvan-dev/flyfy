package app

import (
	"context"
	"errors"
	"fmt"

	"github.com/google/uuid"

	"kz/inflap/backend/services/activity-service/internal/domain/model"
	"kz/inflap/backend/services/activity-service/internal/domain/port"
)

const defaultSearchIndexBackfillBatchSize = 100
const maxSearchIndexBackfillBatchSize = 500

var (
	ErrSearchBackfillRepositoryRequired = errors.New("search backfill repository is required")
	ErrSearchBackfillIndexerRequired    = errors.New("search backfill indexer is required")
)

type ActivitySearchBackfillRepository interface {
	ListActivities(ctx context.Context, filter port.ActivityFilter) ([]*model.Activity, error)
	ListTagsByActivityID(ctx context.Context, activityID uuid.UUID) ([]string, error)
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

func BackfillActivitySearchIndex(
	ctx context.Context,
	repo ActivitySearchBackfillRepository,
	indexer ActivitySearchIndexer,
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

		items, err := repo.ListActivities(ctx, port.ActivityFilter{
			Limit:  limit,
			Offset: offset,
		})
		if err != nil {
			stats.Failed++
			return stats, fmt.Errorf("list activities for search backfill: %w", err)
		}
		if len(items) == 0 {
			return stats, nil
		}

		for _, item := range items {
			if item == nil {
				stats.Skipped++
				continue
			}
			stats.Scanned++
			if err = backfillActivitySearchDocument(ctx, repo, indexer, options, item, &stats); err != nil {
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

func backfillActivitySearchDocument(
	ctx context.Context,
	repo ActivitySearchBackfillRepository,
	indexer ActivitySearchIndexer,
	options SearchIndexBackfillOptions,
	item *model.Activity,
	stats *SearchIndexBackfillStats,
) error {
	if isActivitySearchIndexable(item) {
		tags, err := repo.ListTagsByActivityID(ctx, item.ID)
		if err != nil {
			stats.Failed++
			return fmt.Errorf("list activity tags for search backfill: %w", err)
		}
		if !options.DryRun {
			if err = indexer.UpsertSearchDocument(ctx, activitySearchDocument(item, tags)); err != nil {
				stats.Failed++
				return fmt.Errorf("upsert activity search document: %w", err)
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
			Domain:   "activity",
			EntityID: item.ID.String(),
			Locale:   fallbackActivityLocale,
		}); err != nil {
			stats.Failed++
			return fmt.Errorf("delete stale activity search document: %w", err)
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
