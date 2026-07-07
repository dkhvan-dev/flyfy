package app

import (
	"context"
	"errors"
	"fmt"

	"kz/inflap/backend/services/feed-service/internal/domain/model"
)

const defaultSearchIndexBackfillBatchSize = 50
const maxSearchIndexBackfillBatchSize = 50

var (
	ErrSearchBackfillRepositoryRequired = errors.New("search backfill repository is required")
	ErrSearchBackfillIndexerRequired    = errors.New("search backfill indexer is required")
)

type CommunitySearchBackfillRepository interface {
	ListCommunities(ctx context.Context, filter model.CommunityListFilter) ([]*model.Community, error)
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

func BackfillCommunitySearchIndex(
	ctx context.Context,
	repo CommunitySearchBackfillRepository,
	indexer CommunitySearchIndexer,
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

		items, err := repo.ListCommunities(ctx, model.CommunityListFilter{
			IncludeDeleted: options.DeleteStale,
			Limit:          limit,
			Offset:         offset,
		})
		if err != nil {
			stats.Failed++
			return stats, fmt.Errorf("list communities for search backfill: %w", err)
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
			if err = backfillCommunitySearchDocument(ctx, indexer, options, item, &stats); err != nil {
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

func backfillCommunitySearchDocument(
	ctx context.Context,
	indexer CommunitySearchIndexer,
	options SearchIndexBackfillOptions,
	community *model.Community,
	stats *SearchIndexBackfillStats,
) error {
	if community.IsPubliclyVisible() {
		if !options.DryRun {
			if err := indexer.UpsertSearchDocument(ctx, communitySearchDocument(community)); err != nil {
				stats.Failed++
				return fmt.Errorf("upsert community search document: %w", err)
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
			Domain:   "community",
			EntityID: community.ID.String(),
			Locale:   fallbackCommunityLocale,
		}); err != nil {
			stats.Failed++
			return fmt.Errorf("delete stale community search document: %w", err)
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
