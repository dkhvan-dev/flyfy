package app

import (
	"context"
	"errors"
	"fmt"

	"github.com/google/uuid"

	"kz/inflap/backend/services/guide-service/internal/domain/model"
)

const defaultSearchIndexBackfillBatchSize = 100
const maxSearchIndexBackfillBatchSize = 500

var (
	ErrSearchBackfillRepositoryRequired = errors.New("search backfill repository is required")
	ErrSearchBackfillUserClientRequired = errors.New("search backfill user client is required")
	ErrSearchBackfillIndexerRequired    = errors.New("search backfill indexer is required")
)

type GuideSearchBackfillRepository interface {
	ListGuideProfilesForSearchIndexBackfill(ctx context.Context, limit int, offset int) ([]*model.GuideProfile, error)
	ListGuideLanguagesByProfileIDs(ctx context.Context, guideProfileIDs []uuid.UUID) (map[uuid.UUID][]*model.GuideLanguage, error)
	ListGuideSpecializationsByProfileIDs(ctx context.Context, guideProfileIDs []uuid.UUID) (map[uuid.UUID][]*model.GuideSpecialization, error)
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

func BackfillGuideSearchIndex(
	ctx context.Context,
	repo GuideSearchBackfillRepository,
	userClient UserServiceClient,
	indexer GuideSearchIndexer,
	options SearchIndexBackfillOptions,
) (SearchIndexBackfillStats, error) {
	if repo == nil {
		return SearchIndexBackfillStats{}, ErrSearchBackfillRepositoryRequired
	}
	if userClient == nil {
		return SearchIndexBackfillStats{}, ErrSearchBackfillUserClientRequired
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

		profiles, err := repo.ListGuideProfilesForSearchIndexBackfill(ctx, limit, offset)
		if err != nil {
			stats.Failed++
			return stats, fmt.Errorf("list guide profiles for search backfill: %w", err)
		}
		if len(profiles) == 0 {
			return stats, nil
		}

		if err = backfillGuideSearchBatch(ctx, repo, userClient, indexer, options, profiles, &stats); err != nil {
			return stats, err
		}
		if options.Limit > 0 && stats.Scanned >= options.Limit {
			return stats, nil
		}

		offset += len(profiles)
		if len(profiles) < limit {
			return stats, nil
		}
	}
}

func backfillGuideSearchBatch(
	ctx context.Context,
	repo GuideSearchBackfillRepository,
	userClient UserServiceClient,
	indexer GuideSearchIndexer,
	options SearchIndexBackfillOptions,
	profiles []*model.GuideProfile,
	stats *SearchIndexBackfillStats,
) error {
	profileIDs := make([]uuid.UUID, 0, len(profiles))
	userIDs := make([]uuid.UUID, 0, len(profiles))
	for _, profile := range profiles {
		if profile == nil {
			continue
		}
		profileIDs = append(profileIDs, profile.ID)
		if isGuideSearchIndexable(profile) {
			userIDs = append(userIDs, profile.UserID)
		}
	}

	languagesByProfileID, err := repo.ListGuideLanguagesByProfileIDs(ctx, profileIDs)
	if err != nil {
		stats.Failed++
		return fmt.Errorf("list guide languages for search backfill: %w", err)
	}
	specializationsByProfileID, err := repo.ListGuideSpecializationsByProfileIDs(ctx, profileIDs)
	if err != nil {
		stats.Failed++
		return fmt.Errorf("list guide specializations for search backfill: %w", err)
	}
	userProfiles, err := userClient.GetPublicUserProfiles(ctx, userIDs)
	if err != nil {
		stats.Failed++
		return fmt.Errorf("get public user profiles for guide search backfill: %w", err)
	}

	for _, profile := range profiles {
		if profile == nil {
			stats.Skipped++
			continue
		}
		stats.Scanned++
		userProfile, hasUserProfile := userProfiles[profile.UserID]
		if err = backfillGuideSearchDocument(
			ctx,
			indexer,
			options,
			&GuideAggregate{
				Profile:         profile,
				UserProfile:     publicUserProfilePtr(userProfile, hasUserProfile),
				Languages:       languagesByProfileID[profile.ID],
				Specializations: specializationsByProfileID[profile.ID],
			},
			hasUserProfile,
			stats,
		); err != nil {
			return err
		}
	}
	return nil
}

func backfillGuideSearchDocument(
	ctx context.Context,
	indexer GuideSearchIndexer,
	options SearchIndexBackfillOptions,
	aggregate *GuideAggregate,
	hasUserProfile bool,
	stats *SearchIndexBackfillStats,
) error {
	if aggregate != nil && isGuideSearchIndexable(aggregate.Profile) && hasUserProfile {
		if !options.DryRun {
			if err := indexer.UpsertSearchDocument(ctx, guideSearchDocument(aggregate)); err != nil {
				stats.Failed++
				return fmt.Errorf("upsert guide search document: %w", err)
			}
		}
		stats.Upserted++
		return nil
	}

	if !options.DeleteStale {
		stats.Skipped++
		return nil
	}
	if aggregate == nil || aggregate.Profile == nil || aggregate.Profile.ID == uuid.Nil {
		stats.Skipped++
		return nil
	}

	if !options.DryRun {
		if err := indexer.DeleteSearchDocument(ctx, SearchIndexDelete{
			Domain:   "guide",
			EntityID: aggregate.Profile.ID.String(),
			Locale:   fallbackGuideLocale,
		}); err != nil {
			stats.Failed++
			return fmt.Errorf("delete stale guide search document: %w", err)
		}
	}
	stats.Deleted++
	return nil
}

func publicUserProfilePtr(profile PublicUserProfile, ok bool) *PublicUserProfile {
	if !ok {
		return nil
	}
	return &profile
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
