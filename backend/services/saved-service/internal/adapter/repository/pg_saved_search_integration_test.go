package repository

import (
	"context"
	"errors"
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"

	savedqueryapp "kz/inflap/backend/services/saved-service/internal/app/savedquery"
	savedsearchapp "kz/inflap/backend/services/saved-service/internal/app/savedsearch"
	savedsearchmigration "kz/inflap/backend/services/saved-service/internal/app/savedsearchmigration"
	"kz/inflap/backend/services/saved-service/internal/domain"
)

const savedSearchIntegrationDSNEnv = "SAVED_SERVICE_REPOSITORY_TEST_DSN"
const savedSearchMigrationsDirEnv = "SAVED_SEARCH_MIGRATIONS_DIR"

func TestPGSavedSearchRepositoryRanksLocalesFiltersAndPrivacy(t *testing.T) {
	pool := openSavedSearchIntegration(t)
	repository, err := NewPGSavedSearchRepository(pool)
	if err != nil {
		t.Fatalf("NewPGSavedSearchRepository() error = %v", err)
	}

	base := time.Now().UTC().Add(-time.Hour).Truncate(time.Microsecond)
	readAt := base.Add(30 * time.Minute)
	owner := uuid.New()
	foreignOwner := uuid.New()
	rank1ID := uuid.MustParse("10000000-0000-4000-8000-000000000001")
	rank2ID := uuid.MustParse("20000000-0000-4000-8000-000000000002")
	rank3ID := uuid.MustParse("30000000-0000-4000-8000-000000000003")
	rank4ID := uuid.MustParse("40000000-0000-4000-8000-000000000004")
	rank5ID := uuid.MustParse("50000000-0000-4000-8000-000000000005")

	rank1 := savedSearchSeed{
		ItemID: rank1ID, Owner: owner, EntityType: domain.EntityTypeAttraction,
		SavedAt: base, DefaultLocale: savedqueryapp.LocaleEN,
		Title: localizedSearchText{EN: searchText("Museum")},
	}
	rank2 := savedSearchSeed{
		ItemID: rank2ID, Owner: owner, EntityType: domain.EntityTypeAttraction,
		SavedAt: base.Add(5 * time.Minute), DefaultLocale: savedqueryapp.LocaleEN,
		Title: localizedSearchText{
			EN: searchText("National Museum"),
			RU: searchText("Museum RU"),
			KK: searchText("Museum KK"),
		},
	}
	rank3 := savedSearchSeed{
		ItemID: rank3ID, Owner: owner, EntityType: domain.EntityTypeGuide,
		SavedAt: base.Add(10 * time.Minute), DefaultLocale: savedqueryapp.LocaleEN,
		Title: localizedSearchText{EN: searchText("Museumland Guide")},
	}
	rank4 := savedSearchSeed{
		ItemID: rank4ID, Owner: owner, EntityType: domain.EntityTypeActivity,
		SavedAt: base.Add(15 * time.Minute), DefaultLocale: savedqueryapp.LocaleEN,
		Title:   localizedSearchText{EN: searchText("City Walk")},
		City:    localizedSearchText{EN: searchText("Old Museum Quarter")},
		Country: localizedSearchText{EN: searchText("Museum")},
	}
	rank5 := savedSearchSeed{
		ItemID: rank5ID, Owner: owner, EntityType: domain.EntityTypeGuide,
		SavedAt: base.Add(20 * time.Minute), DefaultLocale: savedqueryapp.LocaleEN,
		Title:   localizedSearchText{EN: searchText("Country Tour")},
		Country: localizedSearchText{EN: searchText("Museumland")},
	}
	for _, seed := range []savedSearchSeed{rank1, rank2, rank3, rank4, rank5} {
		insertSavedSearchSeed(t, pool, seed)
	}

	foreign := rank1
	foreign.ItemID = uuid.New()
	foreign.Owner = foreignOwner
	foreign.TargetID = "foreign-" + uuid.NewString()
	insertSavedSearchSeed(t, pool, foreign)

	removed := rank1
	removed.ItemID = uuid.New()
	removed.TargetID = "removed-" + uuid.NewString()
	insertSavedSearchSeed(t, pool, removed)
	markSavedSearchItemRemoved(t, pool, removed.Owner, removed.ItemID, base.Add(25*time.Minute))

	nonPublicSeeds := make([]savedSearchSeed, 0, 3)
	for index, visibility := range []domain.VisibilityStatus{
		domain.VisibilityPrivate,
		domain.VisibilityUnknown,
		domain.VisibilityDeleted,
	} {
		seed := rank1
		seed.ItemID = uuid.New()
		seed.TargetID = strings.ToLower(string(visibility)) + "-" + uuid.NewString()
		if visibility == domain.VisibilityPrivate {
			seed.EntityType = domain.EntityTypeActivity
		}
		insertSavedSearchSeed(t, pool, seed)
		markSavedSearchProjectionNonPublic(
			t,
			pool,
			seed.EntityType,
			seed.effectiveTargetID(),
			visibility,
			base.Add(time.Duration(26+index)*time.Minute),
		)
		nonPublicSeeds = append(nonPublicSeeds, seed)
	}

	page, err := repository.Search(context.Background(), savedSearchQuery(
		t, owner, savedqueryapp.LocaleKK, "museum", readAt, 100,
	))
	if err != nil {
		t.Fatalf("ranked search failed: %v", err)
	}
	if got, want := savedSearchItemIDs(page.Items), []uuid.UUID{rank1ID, rank2ID, rank3ID, rank4ID, rank5ID}; !equalUUIDs(got, want) {
		t.Fatal("ranked search returned an unexpected item order")
	}
	for index, item := range page.Items {
		wantRank := savedsearchapp.MatchRank(index + 1)
		if item.Match.Rank != wantRank {
			t.Fatalf("ranked search item %d has the wrong rank", index)
		}
	}
	if page.Items[1].Match.Locale != savedqueryapp.LocaleKK ||
		page.Items[1].Match.AlternatePublicDisplay != nil {
		t.Fatal("current-locale winning match is incorrect")
	}
	if page.Items[3].Match.Field != savedsearchapp.MatchedFieldCity ||
		page.Items[3].Match.Kind != savedsearchapp.MatchKindToken ||
		page.Items[3].Match.AlternatePublicDisplay == nil ||
		*page.Items[3].Match.AlternatePublicDisplay != "Old Museum Quarter" {
		t.Fatal("field-priority location match is incorrect")
	}
	if page.Items[4].Match.Field != savedsearchapp.MatchedFieldCountry ||
		page.Items[4].Match.Kind != savedsearchapp.MatchKindPrefix {
		t.Fatal("country-prefix match is incorrect")
	}

	activeCollection := createSavedSearchCollection(t, pool, owner, rank4, base.Add(27*time.Minute))
	collectionQuery := savedSearchQuery(t, owner, savedqueryapp.LocaleEN, "museum", readAt, 100)
	collectionQuery.Collection = &activeCollection
	collectionPage, err := repository.Search(context.Background(), collectionQuery)
	if err != nil || len(collectionPage.Items) != 1 || collectionPage.Items[0].ItemID != rank4ID ||
		collectionPage.Items[0].EffectiveCollectionCount != 1 {
		t.Fatalf("collection-scoped search failed its contract: %v", err)
	}

	uncollectedQuery := savedSearchQuery(t, owner, savedqueryapp.LocaleEN, "museum", readAt, 100)
	uncollectedQuery.Uncollected = true
	uncollectedPage, err := repository.Search(context.Background(), uncollectedQuery)
	if err != nil || len(uncollectedPage.Items) != 4 || containsUUID(savedSearchItemIDs(uncollectedPage.Items), rank4ID) {
		t.Fatalf("uncollected search failed its contract: %v", err)
	}

	activityType := domain.EntityTypeActivity
	typeQuery := savedSearchQuery(t, owner, savedqueryapp.LocaleEN, "museum", readAt, 100)
	typeQuery.EntityType = &activityType
	typePage, err := repository.Search(context.Background(), typeQuery)
	if err != nil || len(typePage.Items) != 1 || typePage.Items[0].ItemID != rank4ID {
		t.Fatalf("type-filtered search failed its contract: %v", err)
	}

	deletedCollection := createDeletedSavedSearchCollection(t, pool, owner, base.Add(28*time.Minute))
	for name, scope := range map[string]struct {
		owner      uuid.UUID
		collection uuid.UUID
	}{
		"foreign": {owner: foreignOwner, collection: activeCollection},
		"deleted": {owner: owner, collection: deletedCollection},
	} {
		query := savedSearchQuery(t, scope.owner, savedqueryapp.LocaleEN, "museum", readAt, 10)
		query.Collection = &scope.collection
		if _, err := repository.Search(context.Background(), query); !errors.Is(err, savedsearchapp.ErrCollectionNotFound) {
			t.Fatalf("%s collection error = %v, want %v", name, err, savedsearchapp.ErrCollectionNotFound)
		}
	}

	for _, seed := range nonPublicSeeds {
		assertDerivedSearchPayloadNull(t, pool, seed.EntityType, seed.effectiveTargetID())
	}
}

func TestPGSavedSearchRepositoryAlternateLocaleIsPublicAndBounded(t *testing.T) {
	pool := openSavedSearchIntegration(t)
	repository, err := NewPGSavedSearchRepository(pool)
	if err != nil {
		t.Fatalf("NewPGSavedSearchRepository() error = %v", err)
	}
	now := time.Now().UTC().Truncate(time.Microsecond)
	owner := uuid.New()
	seed := savedSearchSeed{
		ItemID: uuid.New(), Owner: owner, EntityType: domain.EntityTypeAttraction,
		SavedAt: now.Add(-time.Minute), DefaultLocale: savedqueryapp.LocaleEN,
		Title: localizedSearchText{
			EN: searchText("National Museum"),
			RU: searchText("Национальный музей"),
		},
	}
	insertSavedSearchSeed(t, pool, seed)
	page, err := repository.Search(context.Background(), savedSearchQuery(
		t, owner, savedqueryapp.LocaleKK, "музей", now, 10,
	))
	if err != nil || len(page.Items) != 1 {
		t.Fatalf("alternate-locale search failed its contract: %v", err)
	}
	item := page.Items[0]
	if item.Projection.Public == nil || item.Projection.Public.DisplayLocale != savedqueryapp.LocaleEN ||
		item.Match.Locale != savedqueryapp.LocaleRU || item.Match.AlternatePublicDisplay == nil ||
		*item.Match.AlternatePublicDisplay != "Национальный музей" {
		t.Fatal("alternate-locale presentation metadata is incorrect")
	}
}

func TestPGSavedSearchRepositoryWinningLocaleTuple(t *testing.T) {
	pool := openSavedSearchIntegration(t)
	repository, err := NewPGSavedSearchRepository(pool)
	if err != nil {
		t.Fatalf("NewPGSavedSearchRepository() error = %v", err)
	}
	now := time.Now().UTC().Truncate(time.Microsecond)
	owner := uuid.New()
	sourceDefaultID := uuid.New()
	fallbackENID := uuid.New()
	fallbackRUID := uuid.New()
	for _, seed := range []savedSearchSeed{
		{
			ItemID: sourceDefaultID, Owner: owner, EntityType: domain.EntityTypeAttraction,
			SavedAt: now.Add(-3 * time.Minute), DefaultLocale: savedqueryapp.LocaleRU,
			Title: localizedSearchText{
				EN: searchText("Museum"), RU: searchText("Museum"), KK: searchText("Other"),
			},
		},
		{
			ItemID: fallbackENID, Owner: owner, EntityType: domain.EntityTypeAttraction,
			SavedAt: now.Add(-2 * time.Minute), DefaultLocale: savedqueryapp.LocaleKK,
			Title: localizedSearchText{
				EN: searchText("Museum"), RU: searchText("Museum"), KK: searchText("Other"),
			},
		},
		{
			ItemID: fallbackRUID, Owner: owner, EntityType: domain.EntityTypeAttraction,
			SavedAt: now.Add(-time.Minute), DefaultLocale: savedqueryapp.LocaleEN,
			Title: localizedSearchText{
				EN: searchText("Other"), RU: searchText("Museum"), KK: searchText("Museum"),
			},
		},
	} {
		insertSavedSearchSeed(t, pool, seed)
	}

	kkPage, err := repository.Search(context.Background(), savedSearchQuery(
		t, owner, savedqueryapp.LocaleKK, "museum", now, 10,
	))
	if err != nil {
		t.Fatalf("locale tuple search failed: %v", err)
	}
	sourceDefaultItem, sourceDefaultFound := savedSearchItemByID(kkPage.Items, sourceDefaultID)
	fallbackENItem, fallbackENFound := savedSearchItemByID(kkPage.Items, fallbackENID)
	if !sourceDefaultFound || sourceDefaultItem.Match.Locale != savedqueryapp.LocaleRU ||
		sourceDefaultItem.Match.AlternatePublicDisplay == nil {
		t.Fatal("source-default locale did not win its deterministic tie")
	}
	if !fallbackENFound || fallbackENItem.Match.Locale != savedqueryapp.LocaleEN ||
		fallbackENItem.Match.AlternatePublicDisplay == nil {
		t.Fatal("EN locale did not win the fixed fallback tie")
	}

	enPage, err := repository.Search(context.Background(), savedSearchQuery(
		t, owner, savedqueryapp.LocaleEN, "museum", now, 10,
	))
	if err != nil {
		t.Fatalf("fixed locale fallback search failed: %v", err)
	}
	fallbackRUItem, fallbackRUFound := savedSearchItemByID(enPage.Items, fallbackRUID)
	if !fallbackRUFound || fallbackRUItem.Match.Locale != savedqueryapp.LocaleRU ||
		fallbackRUItem.Match.AlternatePublicDisplay == nil {
		t.Fatal("RU locale did not win ahead of KK in the fixed fallback tie")
	}
}

func TestPGSavedSearchRepositorySameRankTieAndCursor(t *testing.T) {
	pool := openSavedSearchIntegration(t)
	repository, err := NewPGSavedSearchRepository(pool)
	if err != nil {
		t.Fatalf("NewPGSavedSearchRepository() error = %v", err)
	}
	base := time.Now().UTC().Add(-time.Hour).Truncate(time.Microsecond)
	owner := uuid.New()
	olderID := uuid.MustParse("f0000000-0000-4000-8000-000000000001")
	newerLowID := uuid.MustParse("a0000000-0000-4000-8000-000000000002")
	newerHighID := uuid.MustParse("b0000000-0000-4000-8000-000000000003")
	for _, seed := range []savedSearchSeed{
		{
			ItemID: olderID, Owner: owner, EntityType: domain.EntityTypeAttraction,
			SavedAt: base, DefaultLocale: savedqueryapp.LocaleEN,
			Title: localizedSearchText{EN: searchText("National Museum")},
		},
		{
			ItemID: newerLowID, Owner: owner, EntityType: domain.EntityTypeAttraction,
			SavedAt: base.Add(time.Minute), DefaultLocale: savedqueryapp.LocaleEN,
			Title: localizedSearchText{EN: searchText("Modern Museum")},
		},
		{
			ItemID: newerHighID, Owner: owner, EntityType: domain.EntityTypeAttraction,
			SavedAt: base.Add(time.Minute), DefaultLocale: savedqueryapp.LocaleEN,
			Title: localizedSearchText{EN: searchText("City Museum")},
		},
	} {
		insertSavedSearchSeed(t, pool, seed)
	}

	firstQuery := savedSearchQuery(t, owner, savedqueryapp.LocaleEN, "museum", base.Add(10*time.Minute), 2)
	first, err := repository.Search(context.Background(), firstQuery)
	if err != nil || !first.HasMore || first.Next == nil || len(first.Items) != 2 ||
		first.Items[0].ItemID != newerHighID || first.Items[1].ItemID != newerLowID {
		t.Fatalf("same-rank first page failed its tie contract: %v", err)
	}
	secondQuery := firstQuery
	secondQuery.After = first.Next
	second, err := repository.Search(context.Background(), secondQuery)
	if err != nil || second.HasMore || second.Next != nil || len(second.Items) != 1 ||
		second.Items[0].ItemID != olderID {
		t.Fatalf("same-rank cursor page failed its tie contract: %v", err)
	}
}

func TestPGSavedSearchRepositoryKeysetAndConcurrentReaders(t *testing.T) {
	pool := openSavedSearchIntegration(t)
	repository, err := NewPGSavedSearchRepository(pool)
	if err != nil {
		t.Fatalf("NewPGSavedSearchRepository() error = %v", err)
	}
	base := time.Now().UTC().Add(-time.Hour).Truncate(time.Microsecond)
	readAt := base.Add(30 * time.Minute)
	owner := uuid.New()
	seeds := rankedSavedSearchSeeds(owner, base)
	for _, seed := range seeds {
		insertSavedSearchSeed(t, pool, seed)
	}

	firstQuery := savedSearchQuery(t, owner, savedqueryapp.LocaleEN, "museum", readAt, 2)
	first, err := repository.Search(context.Background(), firstQuery)
	if err != nil {
		t.Fatalf("first search page failed: %v", err)
	}
	if !first.HasMore || first.Next == nil || len(first.Items) != 2 ||
		first.Items[0].Match.Rank != savedsearchapp.MatchRankTitleExact ||
		first.Items[1].Match.Rank != savedsearchapp.MatchRankTitleToken {
		t.Fatal("first search page has an invalid rank boundary")
	}

	newRank1 := seeds[0]
	newRank1.ItemID = uuid.MustParse("f0000000-0000-4000-8000-000000000009")
	newRank1.TargetID = "new-rank-1-" + uuid.NewString()
	newRank1.SavedAt = base.Add(25 * time.Minute)
	insertSavedSearchSeed(t, pool, newRank1)
	markSavedSearchItemRemoved(t, pool, owner, seeds[3].ItemID, base.Add(26*time.Minute))

	secondQuery := savedSearchQuery(t, owner, savedqueryapp.LocaleEN, "museum", readAt, 2)
	secondQuery.After = first.Next
	second, err := repository.Search(context.Background(), secondQuery)
	if err != nil {
		t.Fatalf("second search page error = %v", err)
	}
	if second.HasMore || second.Next != nil || len(second.Items) != 2 ||
		second.Items[0].Match.Rank != savedsearchapp.MatchRankTitlePrefix ||
		second.Items[1].Match.Rank != savedsearchapp.MatchRankLocationPrefix ||
		containsUUID(savedSearchItemIDs(second.Items), newRank1.ItemID) {
		t.Fatal("second search page violated rank-aware keyset semantics")
	}

	refreshed, err := repository.Search(context.Background(), firstQuery)
	if err != nil || len(refreshed.Items) != 2 || refreshed.Items[0].ItemID != newRank1.ItemID ||
		refreshed.Items[1].ItemID != seeds[0].ItemID {
		t.Fatalf("refreshed first page failed its contract: %v", err)
	}

	const readers = 24
	errorsByReader := make(chan error, readers)
	var waitGroup sync.WaitGroup
	readerQuery := savedSearchQuery(t, owner, savedqueryapp.LocaleEN, "museum", readAt, 100)
	waitGroup.Add(readers)
	for range readers {
		go func() {
			defer waitGroup.Done()
			page, err := repository.Search(context.Background(), readerQuery)
			if err != nil {
				errorsByReader <- err
				return
			}
			if len(page.Items) != 5 || hasDuplicateSavedSearchItem(page.Items) {
				errorsByReader <- savedsearchapp.ErrDataInvariant
			}
		}()
	}
	waitGroup.Wait()
	close(errorsByReader)
	for err := range errorsByReader {
		t.Fatalf("concurrent search reader error = %v", err)
	}

}

func TestSavedSearchNormalizationMatchesPostgresV1(t *testing.T) {
	pool := openSavedSearchIntegration(t)
	fixtures := []struct {
		name string
		raw  string
	}{
		{name: "english_case_multi_space", raw: "  National   MUSEUM  "},
		{name: "russian_punctuation", raw: "МУЗЕЙ—ИСКУССТВО, МОСКВА"},
		{name: "kazakh_letters", raw: "ҚАЗАҚСТАН / ӨСКЕМЕН / ӘЛЕМ"},
		{name: "nfkc_full_width", raw: "ＦＬＹＦＹ　ＭＵＳＥＵＭ"},
		{name: "combining_marks_composed", raw: "Cafe\u0301  A\u0308lem"},
		{name: "combining_marks_uncomposed", raw: "Музе\u0301й Қала\u0301"},
		{name: "mixed_punctuation_space", raw: "Museum\u00a0/\tМузей\n—\u2003Қала"},
	}
	for _, fixture := range fixtures {
		t.Run(fixture.name, func(t *testing.T) {
			term, err := savedsearchapp.Normalize(fixture.raw)
			if err != nil {
				t.Fatalf("app normalization failed: %v", err)
			}
			var databaseValue string
			if err := pool.QueryRow(
				context.Background(),
				"SELECT saved_search_normalize_v1($1::text)",
				fixture.raw,
			).Scan(&databaseValue); err != nil {
				t.Fatalf("database normalization failed: %v", err)
			}
			if databaseValue != term.Normalized() {
				t.Fatal("database and app normalization parity mismatch")
			}
		})
	}
}

func TestSavedSearchExpandBackfillContractWithExistingRows(t *testing.T) {
	var relationFileBefore uint32
	pool := openSavedSearchIntegrationWithSetup(t, func(pool *pgxpool.Pool) {
		if err := pool.QueryRow(
			context.Background(),
			"SELECT pg_relation_filenode('saved_content_projections'::regclass)",
		).Scan(&relationFileBefore); err != nil {
			t.Fatalf("read pre-expand projection relfilenode: %v", err)
		}
		insertPreExpandSavedSearchProjection(t, pool, "pre-expand-en", savedqueryapp.LocaleEN, "ＦＬＹＦＹ Museum")
		insertPreExpandSavedSearchProjection(t, pool, "pre-expand-ru", savedqueryapp.LocaleRU, "Национальный МУЗЕЙ")
		insertPreExpandSavedSearchProjection(t, pool, "pre-expand-kk", savedqueryapp.LocaleKK, "Қазақстан ӘЛЕМІ")
	}, false)

	var relationFileAfter uint32
	if err := pool.QueryRow(
		context.Background(),
		"SELECT pg_relation_filenode('saved_content_projections'::regclass)",
	).Scan(&relationFileAfter); err != nil {
		t.Fatalf("read post-expand projection relfilenode: %v", err)
	}
	if relationFileAfter != relationFileBefore {
		t.Fatalf("search expand rewrote projection heap: relfilenode %d -> %d", relationFileBefore, relationFileAfter)
	}

	store, err := NewPGSavedSearchMigrationRepository(pool, SavedSearchMigrationOptions{
		LockTimeout:      time.Second,
		StatementTimeout: 10 * time.Second,
		ContractTimeout:  time.Minute,
	})
	if err != nil {
		t.Fatalf("NewPGSavedSearchMigrationRepository() error = %v", err)
	}
	status, err := store.Status(context.Background())
	if err != nil {
		t.Fatalf("initial Status() error = %v", err)
	}
	if !status.ContractPrerequisitesReady() || status.ParityConstraintValidated || !status.Pending {
		t.Fatalf("initial migration status = %+v", status)
	}

	for batch := 0; batch < 3; batch++ {
		rows, err := store.BackfillBatch(context.Background(), 1)
		if err != nil {
			t.Fatalf("BackfillBatch(%d) error = %v", batch+1, err)
		}
		if rows != 1 {
			t.Fatalf("BackfillBatch(%d) rows = %d, want 1", batch+1, rows)
		}
	}
	if rows, err := store.BackfillBatch(context.Background(), 1); err != nil || rows != 0 {
		t.Fatalf("completed BackfillBatch() rows = %d, error = %v", rows, err)
	}

	assertSavedSearchDerivedParity(t, pool, "pre-expand-en", savedqueryapp.LocaleEN)
	assertSavedSearchDerivedParity(t, pool, "pre-expand-ru", savedqueryapp.LocaleRU)
	assertSavedSearchDerivedParity(t, pool, "pre-expand-kk", savedqueryapp.LocaleKK)

	insertPreExpandSavedSearchProjection(t, pool, "post-expand-en", savedqueryapp.LocaleEN, "Trigger Museum")
	assertSavedSearchDerivedParity(t, pool, "post-expand-en", savedqueryapp.LocaleEN)
	if _, err := pool.Exec(context.Background(), `
        UPDATE saved_content_projections
        SET search_title_en_v1 = 'tampered'
        WHERE entity_type = 'ATTRACTION' AND entity_id = 'post-expand-en'`); err == nil {
		t.Fatal("NOT VALID parity constraint accepted a stale update")
	} else {
		var pgError *pgconn.PgError
		if !errors.As(err, &pgError) || pgError.Code != "23514" {
			t.Fatalf("stale update error = %v, want SQLSTATE 23514", err)
		}
	}

	service, err := savedsearchmigration.NewService(store, savedsearchmigration.Config{
		BatchSize:  1,
		MaxBatches: 1,
	})
	if err != nil {
		t.Fatalf("NewService() error = %v", err)
	}
	status, err = service.Contract(context.Background())
	if err != nil {
		t.Fatalf("Contract() error = %v", err)
	}
	if !status.Ready() {
		t.Fatalf("contract status = %+v", status)
	}
}

func TestPGSavedSearchExplainAtBoundedTenThousandOwnerRows(t *testing.T) {
	pool := openSavedSearchIntegration(t)
	repository, err := NewPGSavedSearchRepository(pool)
	if err != nil {
		t.Fatalf("NewPGSavedSearchRepository() error = %v", err)
	}
	base := time.Now().UTC().Add(-time.Hour).Truncate(time.Microsecond)
	owner := uuid.New()
	seedBoundedSavedSearchOwner(t, pool, owner, base, 10_000)
	query := savedSearchQuery(t, owner, savedqueryapp.LocaleEN, "museum", base.Add(time.Hour), 30)
	page, err := repository.Search(context.Background(), query)
	if err != nil || len(page.Items) != 30 || !page.HasMore || page.Next == nil {
		t.Fatalf("bounded owner search failed its page contract: %v", err)
	}
	assertSavedSearchExplainUsesIndexes(t, pool, query)
}

func TestPGSavedSearchBackfillExplainUsesPartialIndex(t *testing.T) {
	base := time.Now().UTC().Add(-time.Hour).Truncate(time.Microsecond)
	pool := openSavedSearchIntegrationWithSetup(t, func(pool *pgxpool.Pool) {
		seedBoundedSavedSearchOwner(t, pool, uuid.New(), base, 10_000)
	}, false)

	rows, err := pool.Query(
		context.Background(),
		"EXPLAIN (COSTS OFF) "+savedSearchBackfillBatchSQL,
		500,
	)
	if err != nil {
		t.Fatalf("EXPLAIN saved search backfill: %v", err)
	}
	defer rows.Close()
	planLines := make([]string, 0, 24)
	for rows.Next() {
		var line string
		if err := rows.Scan(&line); err != nil {
			t.Fatalf("scan saved search backfill EXPLAIN: %v", err)
		}
		planLines = append(planLines, line)
	}
	if err := rows.Err(); err != nil {
		t.Fatalf("iterate saved search backfill EXPLAIN: %v", err)
	}
	plan := strings.Join(planLines, "\n")
	if !strings.Contains(plan, "idx_saved_content_projections_search_backfill_v1") {
		t.Fatalf("backfill plan does not use temporary partial index:\n%s", plan)
	}
}

type localizedSearchText struct {
	EN *string
	RU *string
	KK *string
}

type savedSearchSeed struct {
	ItemID        uuid.UUID
	Owner         uuid.UUID
	EntityType    domain.EntityType
	TargetID      string
	SavedAt       time.Time
	DefaultLocale savedqueryapp.Locale
	Title         localizedSearchText
	City          localizedSearchText
	Country       localizedSearchText
}

func (seed savedSearchSeed) effectiveTargetID() string {
	if seed.TargetID != "" {
		return seed.TargetID
	}
	return "search-target-" + seed.ItemID.String()
}

func insertSavedSearchSeed(t testing.TB, pool *pgxpool.Pool, seed savedSearchSeed) {
	t.Helper()
	if seed.ItemID == uuid.Nil || seed.Owner == uuid.Nil || !seed.EntityType.IsValid() ||
		!seed.DefaultLocale.IsValid() || seed.SavedAt.IsZero() {
		t.Fatal("invalid saved search seed")
	}
	targetID := seed.effectiveTargetID()
	createdAt := seed.SavedAt.UTC()
	searchEN := normalizedSavedSearchText(t, seed.Title.EN, seed.City.EN, seed.Country.EN)
	searchRU := normalizedSavedSearchText(t, seed.Title.RU, seed.City.RU, seed.Country.RU)
	searchKK := normalizedSavedSearchText(t, seed.Title.KK, seed.City.KK, seed.Country.KK)
	route := "/saved-search/" + seed.ItemID.String()
	_, err := pool.Exec(context.Background(), `
        INSERT INTO saved_content_projections (
            entity_type, entity_id, source_service,
            source_revision, projection_revision, visibility_revision,
            visibility_status, visibility_validated_at, source_default_locale,
            title_en, title_ru, title_kk,
            city_en, city_ru, city_kk,
            country_en, country_ru, country_kk,
            search_document_version,
            normalized_search_document_en,
            normalized_search_document_ru,
            normalized_search_document_kk,
            canonical_detail_route,
            ever_referenced, created_at, updated_at
        ) VALUES (
            $1, $2, $3,
            1, 1, 1,
            'PUBLIC', $4, $5,
            $6, $7, $8,
            $9, $10, $11,
            $12, $13, $14,
            1, $15, $16, $17,
            $18,
            TRUE, $4, $4
        )`,
		string(seed.EntityType), targetID, savedSearchSourceService(seed.EntityType), createdAt,
		string(seed.DefaultLocale),
		optionalSearchText(seed.Title.EN), optionalSearchText(seed.Title.RU), optionalSearchText(seed.Title.KK),
		optionalSearchText(seed.City.EN), optionalSearchText(seed.City.RU), optionalSearchText(seed.City.KK),
		optionalSearchText(seed.Country.EN), optionalSearchText(seed.Country.RU), optionalSearchText(seed.Country.KK),
		searchEN, searchRU, searchKK, route,
	)
	if err != nil {
		t.Fatalf("insert saved search projection: %v", err)
	}
	_, err = pool.Exec(context.Background(), `
        INSERT INTO saved_items (
            id, owner_user_id, entity_type, entity_id,
            relationship_state, state_generation, relationship_attribution_id,
            relationship_version, dependent_membership_version,
            saved_at, created_at, updated_at
        ) VALUES (
            $1, $2, $3, $4,
            'ACTIVE', $5, $6,
            1, 0,
            $7, $7, $7
        )`,
		seed.ItemID.String(), seed.Owner.String(), string(seed.EntityType), targetID,
		uuid.NewString(), uuid.NewString(), createdAt,
	)
	if err != nil {
		t.Fatalf("insert saved search item: %v", err)
	}
}

func insertPreExpandSavedSearchProjection(
	t testing.TB,
	pool *pgxpool.Pool,
	targetID string,
	locale savedqueryapp.Locale,
	title string,
) {
	t.Helper()
	if strings.TrimSpace(targetID) == "" || !locale.IsValid() || strings.TrimSpace(title) == "" {
		t.Fatal("invalid pre-expand saved search projection")
	}
	normalized, err := savedsearchapp.Normalize(title)
	if err != nil {
		t.Fatalf("normalize pre-expand projection: %v", err)
	}
	var titleEN, titleRU, titleKK any
	var searchEN, searchRU, searchKK any
	switch locale {
	case savedqueryapp.LocaleEN:
		titleEN, searchEN = title, normalized.Normalized()
	case savedqueryapp.LocaleRU:
		titleRU, searchRU = title, normalized.Normalized()
	case savedqueryapp.LocaleKK:
		titleKK, searchKK = title, normalized.Normalized()
	default:
		t.Fatal("unsupported pre-expand locale")
	}
	now := time.Now().UTC().Truncate(time.Microsecond)
	_, err = pool.Exec(context.Background(), `
        INSERT INTO saved_content_projections (
            entity_type, entity_id, source_service,
            source_revision, projection_revision, visibility_revision,
            visibility_status, visibility_validated_at, source_default_locale,
            title_en, title_ru, title_kk,
            search_document_version,
            normalized_search_document_en,
            normalized_search_document_ru,
            normalized_search_document_kk,
            canonical_detail_route,
            ever_referenced, created_at, updated_at
        ) VALUES (
            'ATTRACTION', $1, 'place-service',
            1, 1, 1,
            'PUBLIC', $2, $3,
            $4, $5, $6,
            1,
            $7, $8, $9,
            $10,
            TRUE, $2, $2
        )`,
		targetID, now, string(locale),
		titleEN, titleRU, titleKK,
		searchEN, searchRU, searchKK,
		"/saved-search-migration/"+targetID,
	)
	if err != nil {
		t.Fatalf("insert pre-expand saved search projection: %v", err)
	}
}

func assertSavedSearchDerivedParity(
	t testing.TB,
	pool *pgxpool.Pool,
	targetID string,
	locale savedqueryapp.Locale,
) {
	t.Helper()
	var source, derived string
	if err := pool.QueryRow(context.Background(), `
        SELECT CASE $2::text
                   WHEN 'EN' THEN title_en
                   WHEN 'RU' THEN title_ru
                   WHEN 'KK' THEN title_kk
               END,
               CASE $2::text
                   WHEN 'EN' THEN search_title_en_v1
                   WHEN 'RU' THEN search_title_ru_v1
                   WHEN 'KK' THEN search_title_kk_v1
               END
        FROM saved_content_projections
        WHERE entity_type = 'ATTRACTION' AND entity_id = $1`,
		targetID, string(locale),
	).Scan(&source, &derived); err != nil {
		t.Fatalf("read saved search derived parity: %v", err)
	}
	normalized, err := savedsearchapp.Normalize(source)
	if err != nil {
		t.Fatalf("normalize saved search parity source: %v", err)
	}
	if derived != normalized.Normalized() {
		t.Fatalf("derived search value %q != normalized source %q", derived, normalized.Normalized())
	}
}

func normalizedSavedSearchText(t testing.TB, values ...*string) any {
	t.Helper()
	parts := make([]string, 0, len(values))
	for _, value := range values {
		if value != nil {
			parts = append(parts, *value)
		}
	}
	if len(parts) == 0 {
		return nil
	}
	term, err := savedsearchapp.Normalize(strings.Join(parts, " "))
	if err != nil {
		t.Fatalf("normalize saved search seed: %v", err)
	}
	return term.Normalized()
}

func optionalSearchText(value *string) any {
	if value == nil {
		return nil
	}
	return *value
}

func searchText(value string) *string {
	return &value
}

func savedSearchSourceService(entityType domain.EntityType) string {
	switch entityType {
	case domain.EntityTypeAttraction:
		return "place-service"
	case domain.EntityTypeActivity:
		return "activity-service"
	case domain.EntityTypeGuide:
		return "guide-service"
	default:
		return "saved-source"
	}
}

func markSavedSearchItemRemoved(
	t testing.TB,
	pool *pgxpool.Pool,
	owner uuid.UUID,
	itemID uuid.UUID,
	removedAt time.Time,
) {
	t.Helper()
	result, err := pool.Exec(context.Background(), `
        UPDATE saved_items
        SET relationship_state = 'REMOVED',
            relationship_version = relationship_version + 1,
            removed_at = $3,
            purge_eligible_at = $3::timestamptz + INTERVAL '14 days',
            updated_at = $3
        WHERE owner_user_id = $1 AND id = $2`, owner.String(), itemID.String(), removedAt.UTC())
	if err != nil {
		t.Fatalf("mark saved search item removed: %v", err)
	}
	if result.RowsAffected() != 1 {
		t.Fatalf("removed saved search rows = %d, want 1", result.RowsAffected())
	}
}

func markSavedSearchProjectionNonPublic(
	t testing.TB,
	pool *pgxpool.Pool,
	entityType domain.EntityType,
	targetID string,
	visibility domain.VisibilityStatus,
	updatedAt time.Time,
) {
	t.Helper()
	result, err := pool.Exec(context.Background(), `
        UPDATE saved_content_projections
        SET source_revision = source_revision + 1,
            projection_revision = projection_revision + 1,
            visibility_revision = visibility_revision + 1,
			search_document_version = projection_revision + 1,
            visibility_status = $3,
            visibility_validated_at = $4,
            source_default_locale = NULL,
            title_en = NULL, title_ru = NULL, title_kk = NULL,
            subtitle_en = NULL, subtitle_ru = NULL, subtitle_kk = NULL,
            city_en = NULL, city_ru = NULL, city_kk = NULL,
            country_en = NULL, country_ru = NULL, country_kk = NULL,
            display_location_en = NULL, display_location_ru = NULL, display_location_kk = NULL,
            normalized_search_document_en = NULL,
            normalized_search_document_ru = NULL,
            normalized_search_document_kk = NULL,
            media_reference = NULL,
            media_reference_revision = NULL,
            media_valid_until = NULL,
            rating_value = NULL,
            rating_count = NULL,
            rating_scale_max = NULL,
            price_summary = NULL,
            availability_summary = NULL,
            summary_as_of = NULL,
            summary_valid_until = NULL,
            canonical_detail_route = NULL,
            updated_at = $4
        WHERE entity_type = $1 AND entity_id = $2`,
		string(entityType), targetID, string(visibility), updatedAt.UTC())
	if err != nil {
		t.Fatalf("mark projection %s: %v", visibility, err)
	}
	if result.RowsAffected() != 1 {
		t.Fatalf("non-public projection rows = %d, want 1", result.RowsAffected())
	}
}

func createSavedSearchCollection(
	t testing.TB,
	pool *pgxpool.Pool,
	owner uuid.UUID,
	seed savedSearchSeed,
	createdAt time.Time,
) uuid.UUID {
	t.Helper()
	collectionID := uuid.New()
	_, err := pool.Exec(context.Background(), `
        INSERT INTO saved_collections (
            id, owner_user_id, client_creation_id, title, normalized_title_key,
            lifecycle_state, lifecycle_version, metadata_version, items_version,
            active_item_count, created_at, organized_at, updated_at
        ) VALUES ($1, $2, $3, 'Museums', 'museums', 'ACTIVE', 1, 1, 1, 1, $4, $4, $4)`,
		collectionID.String(), owner.String(), uuid.NewString(), createdAt.UTC())
	if err != nil {
		t.Fatalf("insert saved search collection: %v", err)
	}
	_, err = pool.Exec(context.Background(), `
        INSERT INTO saved_collection_items (
            id, owner_user_id, collection_id, saved_item_id,
            membership_state, membership_version, saved_at_snapshot,
            added_at, updated_at
        ) VALUES ($1, $2, $3, $4, 'ACTIVE', 1, $5, $6, $6)`,
		uuid.NewString(), owner.String(), collectionID.String(), seed.ItemID.String(),
		seed.SavedAt.UTC(), createdAt.UTC())
	if err != nil {
		t.Fatalf("insert saved search membership: %v", err)
	}
	return collectionID
}

func createDeletedSavedSearchCollection(
	t testing.TB,
	pool *pgxpool.Pool,
	owner uuid.UUID,
	deletedAt time.Time,
) uuid.UUID {
	t.Helper()
	collectionID := uuid.New()
	createdAt := deletedAt.Add(-time.Minute).UTC()
	_, err := pool.Exec(context.Background(), `
        INSERT INTO saved_collections (
            id, owner_user_id, client_creation_id, title, normalized_title_key,
            lifecycle_state, lifecycle_version, metadata_version, items_version,
            active_item_count, created_at, organized_at, updated_at,
            deleted_at, purge_eligible_at
        ) VALUES (
            $1, $2, $3, NULL, NULL,
            'DELETED', 2, 1, 0,
            0, $4, $4, $5,
            $5, $5::timestamptz + INTERVAL '14 days'
        )`, collectionID.String(), owner.String(), uuid.NewString(), createdAt, deletedAt.UTC())
	if err != nil {
		t.Fatalf("insert deleted saved search collection: %v", err)
	}
	return collectionID
}

func assertDerivedSearchPayloadNull(
	t testing.TB,
	pool *pgxpool.Pool,
	entityType domain.EntityType,
	targetID string,
) {
	t.Helper()
	var values [9]pgtype.Text
	err := pool.QueryRow(context.Background(), `
        SELECT search_title_en_v1, search_title_ru_v1, search_title_kk_v1,
               search_city_en_v1, search_city_ru_v1, search_city_kk_v1,
               search_country_en_v1, search_country_ru_v1, search_country_kk_v1
        FROM saved_content_projections
        WHERE entity_type = $1 AND entity_id = $2`, string(entityType), targetID).Scan(
		&values[0], &values[1], &values[2],
		&values[3], &values[4], &values[5],
		&values[6], &values[7], &values[8],
	)
	if err != nil {
		t.Fatalf("read generated privacy payload: %v", err)
	}
	for index, value := range values {
		if value.Valid {
			t.Fatalf("generated search field %d retained non-public payload", index)
		}
	}
}

func savedSearchQuery(
	t testing.TB,
	owner uuid.UUID,
	locale savedqueryapp.Locale,
	raw string,
	readAt time.Time,
	limit int,
) savedsearchapp.Query {
	t.Helper()
	term, err := savedsearchapp.Normalize(raw)
	if err != nil {
		t.Fatalf("search fixture normalization failed: %v", err)
	}
	return savedsearchapp.Query{
		OwnerUserID: owner,
		Locale:      locale,
		Term:        term,
		Limit:       limit,
		ReadAt:      readAt.UTC(),
	}
}

func rankedSavedSearchSeeds(owner uuid.UUID, base time.Time) []savedSearchSeed {
	return []savedSearchSeed{
		{
			ItemID: uuid.MustParse("10000000-0000-4000-8000-000000000001"), Owner: owner,
			EntityType: domain.EntityTypeAttraction, SavedAt: base,
			DefaultLocale: savedqueryapp.LocaleEN,
			Title:         localizedSearchText{EN: searchText("Museum")},
		},
		{
			ItemID: uuid.MustParse("20000000-0000-4000-8000-000000000002"), Owner: owner,
			EntityType: domain.EntityTypeAttraction, SavedAt: base.Add(5 * time.Minute),
			DefaultLocale: savedqueryapp.LocaleEN,
			Title:         localizedSearchText{EN: searchText("National Museum")},
		},
		{
			ItemID: uuid.MustParse("30000000-0000-4000-8000-000000000003"), Owner: owner,
			EntityType: domain.EntityTypeGuide, SavedAt: base.Add(10 * time.Minute),
			DefaultLocale: savedqueryapp.LocaleEN,
			Title:         localizedSearchText{EN: searchText("Museumland")},
		},
		{
			ItemID: uuid.MustParse("40000000-0000-4000-8000-000000000004"), Owner: owner,
			EntityType: domain.EntityTypeActivity, SavedAt: base.Add(15 * time.Minute),
			DefaultLocale: savedqueryapp.LocaleEN,
			Title:         localizedSearchText{EN: searchText("City Walk")},
			City:          localizedSearchText{EN: searchText("Museum")},
		},
		{
			ItemID: uuid.MustParse("50000000-0000-4000-8000-000000000005"), Owner: owner,
			EntityType: domain.EntityTypeGuide, SavedAt: base.Add(20 * time.Minute),
			DefaultLocale: savedqueryapp.LocaleEN,
			Title:         localizedSearchText{EN: searchText("Country Tour")},
			Country:       localizedSearchText{EN: searchText("Museumland")},
		},
	}
}

func seedBoundedSavedSearchOwner(
	t testing.TB,
	pool *pgxpool.Pool,
	owner uuid.UUID,
	base time.Time,
	count int,
) {
	t.Helper()
	if count != 10_000 {
		t.Fatal("bounded EXPLAIN fixture must contain exactly 10,000 owner rows")
	}
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	_, err := pool.Exec(ctx, `
        INSERT INTO saved_content_projections (
            entity_type, entity_id, source_service,
            source_revision, projection_revision, visibility_revision,
            visibility_status, visibility_validated_at, source_default_locale,
            title_en, search_document_version, normalized_search_document_en,
            canonical_detail_route, ever_referenced, created_at, updated_at
        )
        SELECT 'ATTRACTION',
               'bounded-search-target-' || fixture_number::text,
               'place-service',
               1, 1, 1,
               'PUBLIC', $1::timestamptz, 'EN',
               'Museum ' || fixture_number::text,
               1,
               'museum ' || fixture_number::text,
               '/bounded-search/' || fixture_number::text,
               TRUE,
               $1::timestamptz,
               $1::timestamptz
        FROM generate_series(1, $2::integer) AS fixture_number`, base.UTC(), count)
	if err != nil {
		t.Fatalf("seed bounded search projections: %v", err)
	}
	_, err = pool.Exec(ctx, `
        INSERT INTO saved_items (
            id, owner_user_id, entity_type, entity_id,
            relationship_state, state_generation, relationship_attribution_id,
            relationship_version, dependent_membership_version,
            saved_at, created_at, updated_at
        )
        SELECT (
                   '00000000-0000-4000-8000-'
                   || lpad(fixture_number::text, 12, '0')
               )::uuid,
               $1::uuid,
               'ATTRACTION',
               'bounded-search-target-' || fixture_number::text,
               'ACTIVE',
               '00000000-0000-4000-8000-000000000001'::uuid,
               '00000000-0000-4000-8000-000000000002'::uuid,
               1,
               0,
               $2::timestamptz + fixture_number * INTERVAL '1 microsecond',
               $2::timestamptz + fixture_number * INTERVAL '1 microsecond',
               $2::timestamptz + fixture_number * INTERVAL '1 microsecond'
        FROM generate_series(1, $3::integer) AS fixture_number`, owner.String(), base.UTC(), count)
	if err != nil {
		t.Fatalf("seed bounded owner relationships: %v", err)
	}
	var activeCount int
	if err := pool.QueryRow(ctx, `
        SELECT count(*)
        FROM saved_items
        WHERE owner_user_id = $1::uuid
          AND relationship_state = 'ACTIVE'`, owner.String()).Scan(&activeCount); err != nil {
		t.Fatalf("count bounded owner relationships: %v", err)
	}
	if activeCount != count {
		t.Fatal("bounded owner relationship count is incorrect")
	}
	if _, err := pool.Exec(ctx, "ANALYZE saved_items, saved_content_projections"); err != nil {
		t.Fatalf("analyze bounded Saved search fixture: %v", err)
	}
}

func assertSavedSearchExplainUsesIndexes(
	t testing.TB,
	pool *pgxpool.Pool,
	query savedsearchapp.Query,
) {
	t.Helper()
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	tx, err := pool.BeginTx(ctx, pgx.TxOptions{AccessMode: pgx.ReadOnly})
	if err != nil {
		t.Fatalf("begin EXPLAIN transaction: %v", err)
	}
	defer func() { _ = tx.Rollback(context.Background()) }()
	// The fixture intentionally contains only one bounded owner. With fresh
	// statistics a sequential scan is rational for that synthetic table, so
	// disable it only for the plan-contract assertion to prove both production
	// indexes remain usable. The repository call above still runs with the
	// normal planner and guards real execution behavior.
	if _, err := tx.Exec(ctx, `
        SET LOCAL enable_seqscan = off;
        SET LOCAL enable_hashjoin = off;
        SET LOCAL enable_mergejoin = off`); err != nil {
		t.Fatalf("configure Saved search EXPLAIN: %v", err)
	}
	rows, err := tx.Query(
		ctx,
		"EXPLAIN (ANALYZE, BUFFERS, COSTS OFF) "+savedSearchSQL(query),
		savedSearchArguments(query)...,
	)
	if err != nil {
		t.Fatalf("EXPLAIN saved search: %v", err)
	}
	defer rows.Close()
	planLines := make([]string, 0, 32)
	for rows.Next() {
		var line string
		if err := rows.Scan(&line); err != nil {
			t.Fatalf("scan EXPLAIN line: %v", err)
		}
		planLines = append(planLines, line)
	}
	if err := rows.Err(); err != nil {
		t.Fatalf("iterate EXPLAIN: %v", err)
	}
	plan := strings.Join(planLines, "\n")
	if strings.Contains(plan, "Seq Scan on saved_items") ||
		(!strings.Contains(plan, "idx_saved_items_active_owner_search_v1") &&
			!strings.Contains(plan, "idx_saved_items_owner_state_saved") &&
			!strings.Contains(plan, "saved_items_owner_id_key")) {
		t.Fatalf("owner-first search index contract failed:\n%s", plan)
	}
	if strings.Contains(plan, "Seq Scan on saved_content_projections") ||
		(!strings.Contains(plan, "idx_saved_content_projections_public_search_target_v1") &&
			!strings.Contains(plan, "saved_content_projections_pkey")) {
		t.Fatalf("PUBLIC projection search index contract failed:\n%s", plan)
	}
	if !strings.Contains(plan, "actual time=") || !strings.Contains(plan, "Buffers:") {
		t.Fatal("saved search EXPLAIN did not execute with ANALYZE and BUFFERS")
	}
}

func savedSearchItemIDs(items []savedsearchapp.Item) []uuid.UUID {
	result := make([]uuid.UUID, len(items))
	for index, item := range items {
		result[index] = item.ItemID
	}
	return result
}

func savedSearchItemByID(items []savedsearchapp.Item, itemID uuid.UUID) (savedsearchapp.Item, bool) {
	for _, item := range items {
		if item.ItemID == itemID {
			return item, true
		}
	}
	return savedsearchapp.Item{}, false
}

func equalUUIDs(left, right []uuid.UUID) bool {
	if len(left) != len(right) {
		return false
	}
	for index := range left {
		if left[index] != right[index] {
			return false
		}
	}
	return true
}

func containsUUID(values []uuid.UUID, expected uuid.UUID) bool {
	for _, value := range values {
		if value == expected {
			return true
		}
	}
	return false
}

func hasDuplicateSavedSearchItem(items []savedsearchapp.Item) bool {
	seen := make(map[uuid.UUID]struct{}, len(items))
	for _, item := range items {
		if _, exists := seen[item.ItemID]; exists {
			return true
		}
		seen[item.ItemID] = struct{}{}
	}
	return false
}

func openSavedSearchIntegration(t *testing.T) *pgxpool.Pool {
	return openSavedSearchIntegrationWithSetup(t, nil, true)
}

func openSavedSearchIntegrationWithSetup(
	t *testing.T,
	beforeExpand func(pool *pgxpool.Pool),
	validateContract bool,
) *pgxpool.Pool {
	t.Helper()
	dsn := strings.TrimSpace(os.Getenv(savedSearchIntegrationDSNEnv))
	if dsn == "" {
		t.Skipf("%s is not set", savedSearchIntegrationDSNEnv)
	}
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	adminPool, err := pgxpool.New(ctx, dsn)
	if err != nil {
		t.Fatalf("connect search integration database: %v", err)
	}
	if err := adminPool.Ping(ctx); err != nil {
		adminPool.Close()
		t.Fatalf("ping search integration database: %v", err)
	}

	schema := "saved_search_" + strings.ReplaceAll(uuid.NewString(), "-", "")
	quotedSchema := pgx.Identifier{schema}.Sanitize()
	if _, err := adminPool.Exec(ctx, "CREATE SCHEMA "+quotedSchema); err != nil {
		adminPool.Close()
		t.Fatalf("create saved search schema: %v", err)
	}
	poolConfig, err := pgxpool.ParseConfig(dsn)
	if err != nil {
		_, _ = adminPool.Exec(context.Background(), "DROP SCHEMA "+quotedSchema+" CASCADE")
		adminPool.Close()
		t.Fatalf("parse search integration DSN: %v", err)
	}
	poolConfig.ConnConfig.RuntimeParams["search_path"] = quotedSchema
	poolConfig.ConnConfig.DefaultQueryExecMode = pgx.QueryExecModeSimpleProtocol
	pool, err := pgxpool.NewWithConfig(ctx, poolConfig)
	if err != nil {
		_, _ = adminPool.Exec(context.Background(), "DROP SCHEMA "+quotedSchema+" CASCADE")
		adminPool.Close()
		t.Fatalf("connect saved search schema: %v", err)
	}

	baseMigrations := []string{
		readSavedSearchMigration(t, "001_saved_core.up.sql"),
		readSavedSearchMigration(t, "002_saved_collections.up.sql"),
	}
	for index, migration := range baseMigrations {
		if _, err := pool.Exec(ctx, migration); err != nil {
			pool.Close()
			_, _ = adminPool.Exec(context.Background(), "DROP SCHEMA "+quotedSchema+" CASCADE")
			adminPool.Close()
			t.Fatalf("apply saved search base migration %d: %v", index+1, err)
		}
	}
	if beforeExpand != nil {
		beforeExpand(pool)
	}
	searchMigrations := []string{
		readSavedSearchMigration(t, "003_saved_search.up.sql"),
		readSavedSearchMigration(t, "003a_saved_search_owner_index.up.sql"),
		readSavedSearchMigration(t, "003b_saved_search_projection_index.up.sql"),
		readSavedSearchMigration(t, "003c_saved_search_backfill_index.up.sql"),
	}
	if validateContract {
		searchMigrations = append(
			searchMigrations,
			readSavedSearchMigration(t, "003d_saved_search_contract.sql"),
			readSavedSearchMigration(t, "003c_saved_search_backfill_index.down.sql"),
		)
	}
	for index, migration := range searchMigrations {
		if _, err := pool.Exec(ctx, migration); err != nil {
			pool.Close()
			_, _ = adminPool.Exec(context.Background(), "DROP SCHEMA "+quotedSchema+" CASCADE")
			adminPool.Close()
			t.Fatalf("apply saved search phased migration %d: %v", index+1, err)
		}
	}
	if _, err := pool.Exec(
		ctx,
		readSavedSearchMigration(t, "006_saved_reconciliation_scheduler.up.sql"),
	); err != nil {
		pool.Close()
		_, _ = adminPool.Exec(context.Background(), "DROP SCHEMA "+quotedSchema+" CASCADE")
		adminPool.Close()
		t.Fatalf("apply Saved reconciliation migration: %v", err)
	}

	t.Cleanup(func() {
		cleanupCtx, cleanupCancel := context.WithTimeout(context.Background(), 30*time.Second)
		defer cleanupCancel()
		_, _ = pool.Exec(cleanupCtx, `TRUNCATE TABLE
            saved_outbox,
            saved_collection_items,
            saved_collections,
            saved_items,
            saved_content_projections,
            saved_operations,
            saved_collection_usage,
            saved_user_usage
            CASCADE`)
		downMigrations := []string{
			readSavedSearchMigration(t, "006_saved_reconciliation_scheduler.down.sql"),
			readSavedSearchMigration(t, "003c_saved_search_backfill_index.down.sql"),
			readSavedSearchMigration(t, "003b_saved_search_projection_index.down.sql"),
			readSavedSearchMigration(t, "003a_saved_search_owner_index.down.sql"),
			readSavedSearchMigration(t, "003_saved_search.down.sql"),
			readSavedSearchMigration(t, "002_saved_collections.down.sql"),
			readSavedSearchMigration(t, "001_saved_core.down.sql"),
		}
		for index, migration := range downMigrations {
			if _, err := pool.Exec(cleanupCtx, migration); err != nil {
				t.Errorf("apply saved search down migration %d: %v", index+1, err)
			}
		}
		pool.Close()
		if _, err := adminPool.Exec(cleanupCtx, "DROP SCHEMA "+quotedSchema+" CASCADE"); err != nil {
			t.Errorf("drop saved search schema: %v", err)
		}
		adminPool.Close()
	})

	var currentSchema string
	if err := pool.QueryRow(ctx, "SELECT current_schema()").Scan(&currentSchema); err != nil {
		t.Fatalf("read saved search schema: %v", err)
	}
	if currentSchema != schema {
		t.Fatalf("current schema = %q, want %q", currentSchema, schema)
	}
	return pool
}

func readSavedSearchMigration(t testing.TB, name string) string {
	t.Helper()
	migrationsDir := strings.TrimSpace(os.Getenv(savedSearchMigrationsDirEnv))
	if migrationsDir == "" {
		_, currentFile, _, ok := runtime.Caller(0)
		if !ok {
			t.Fatal("resolve saved search integration test path")
		}
		migrationsDir = filepath.Join(filepath.Dir(currentFile), "..", "..", "..", "migrations")
	}
	path := filepath.Join(migrationsDir, name)
	contents, err := os.ReadFile(path)
	if err != nil {
		t.Fatalf("read saved search migration %s: %v", name, err)
	}
	if len(contents) == 0 {
		t.Fatalf("saved search migration %s is empty", name)
	}
	return string(contents)
}
