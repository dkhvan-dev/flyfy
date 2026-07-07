package app

import (
	"context"
	"errors"
	"fmt"

	"github.com/google/uuid"

	"kz/inflap/backend/services/user-service/internal/domain/port"
)

const defaultSearchIndexBackfillBatchSize = 100
const maxSearchIndexBackfillBatchSize = 500

var (
	ErrSearchBackfillRepositoryRequired = errors.New("search backfill repository is required")
	ErrSearchBackfillIndexerRequired    = errors.New("search backfill indexer is required")
)

type UserSearchBackfillRepository interface {
	ListUserSearchIndexBackfillAggregates(
		ctx context.Context,
		limit int,
		offset int,
	) ([]port.UserSearchIndexBackfillAggregate, error)
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

func BackfillUserSearchIndex(
	ctx context.Context,
	repo UserSearchBackfillRepository,
	indexer UserSearchIndexer,
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

		items, err := repo.ListUserSearchIndexBackfillAggregates(ctx, limit, offset)
		if err != nil {
			stats.Failed++
			return stats, fmt.Errorf("list users for search backfill: %w", err)
		}
		if len(items) == 0 {
			return stats, nil
		}

		for _, item := range items {
			stats.Scanned++
			if err = backfillUserSearchDocument(ctx, indexer, options, item, &stats); err != nil {
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

func backfillUserSearchDocument(
	ctx context.Context,
	indexer UserSearchIndexer,
	options SearchIndexBackfillOptions,
	item port.UserSearchIndexBackfillAggregate,
	stats *SearchIndexBackfillStats,
) error {
	aggregate := &UserAggregate{
		User:       item.User,
		Profile:    item.Profile,
		Reputation: item.Reputation,
		Followers: UserFollowSummary{
			FollowersCount: item.FollowersCount,
		},
	}
	if isUserSearchIndexable(aggregate) {
		if !options.DryRun {
			if err := indexer.UpsertSearchDocument(ctx, userSearchDocument(aggregate)); err != nil {
				stats.Failed++
				return fmt.Errorf("upsert user search document: %w", err)
			}
		}
		stats.Upserted++
		return nil
	}

	if !options.DeleteStale {
		stats.Skipped++
		return nil
	}

	userID := uuid.Nil
	if item.User != nil {
		userID = item.User.ID
	} else if item.Profile != nil {
		userID = item.Profile.UserID
	}
	if userID == uuid.Nil {
		stats.Skipped++
		return nil
	}

	if !options.DryRun {
		if err := indexer.DeleteSearchDocument(ctx, SearchIndexDelete{
			Domain:   "user",
			EntityID: userID.String(),
			Locale:   fallbackUserSearchLocale,
		}); err != nil {
			stats.Failed++
			return fmt.Errorf("delete stale user search document: %w", err)
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
