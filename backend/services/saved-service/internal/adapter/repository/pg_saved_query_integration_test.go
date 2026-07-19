package repository

import (
	"context"
	"errors"
	"sort"
	"sync"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"

	savedqueryapp "kz/inflap/backend/services/saved-service/internal/app/savedquery"
	"kz/inflap/backend/services/saved-service/internal/domain"
)

func TestPGSavedQueryRepositoryStatusFiltersTenantAndPayload(t *testing.T) {
	pool, operationStore, mutationRepository := openSavedItemKernelIntegration(t)
	queryRepository, err := NewPGSavedQueryRepository(pool)
	if err != nil {
		t.Fatalf("NewPGSavedQueryRepository() error = %v", err)
	}

	base := time.Now().UTC().Add(-time.Minute).Truncate(time.Microsecond)
	readAt := base.Add(20 * time.Second)
	ownerA := uuid.New()
	ownerB := uuid.New()
	subject := uuid.New()
	session := uuid.New()
	attraction := integrationSavedTarget(t, domain.EntityTypeAttraction)
	activity := integrationSavedTarget(t, domain.EntityTypeActivity)
	guide := integrationSavedTarget(t, domain.EntityTypeGuide)
	unknown := integrationSavedTarget(t, domain.EntityTypeGuide)

	seedQuerySavedItem(t, operationStore, mutationRepository, subject, session, ownerA, attraction, base, 1, uuid.Nil)
	seedQuerySavedItem(t, operationStore, mutationRepository, subject, session, ownerA, activity, base.Add(time.Second), 2, uuid.Nil)
	seedQuerySavedItem(t, operationStore, mutationRepository, subject, session, ownerA, guide, base.Add(2*time.Second), 3, uuid.Nil)
	seedQueryGlobalUnsave(t, operationStore, mutationRepository, subject, session, ownerA, guide, base.Add(3*time.Second), 4)
	seedQuerySavedItem(t, operationStore, mutationRepository, subject, session, ownerB, attraction, base.Add(4*time.Second), 5, uuid.Nil)

	_, _ = seedSavedMemberships(t, pool, ownerA, activity, base.Add(5*time.Second))
	activeCollection, deletedCollection := queryCollectionIDs(t, pool, ownerA)
	markQueryCollectionDeleted(t, pool, ownerA, deletedCollection, base.Add(6*time.Second))
	markQueryProjectionPrivate(t, pool, activity, base.Add(7*time.Second))

	status, err := queryRepository.GetStatus(context.Background(), savedqueryapp.StatusQuery{
		OwnerUserID: ownerA,
		Target:      activity,
	})
	if err != nil {
		t.Fatalf("GetStatus(activity) error = %v", err)
	}
	if status.SavedState != savedqueryapp.SavedStateSaved ||
		status.Eligibility != savedqueryapp.EligibilityReductionOnly ||
		status.EffectiveCollectionCount != 1 || status.RelationshipGeneration == nil ||
		status.ResourceVersion != 3 {
		t.Fatalf("private activity status = %+v", status)
	}

	statuses, err := queryRepository.BatchStatus(context.Background(), savedqueryapp.BatchStatusQuery{
		OwnerUserID: ownerA,
		Targets:     []domain.SavedTarget{guide, unknown, attraction, activity},
	})
	if err != nil {
		t.Fatalf("BatchStatus() error = %v", err)
	}
	if len(statuses) != 4 || statuses[0].Target != guide || statuses[1].Target != unknown ||
		statuses[2].Target != attraction || statuses[3].Target != activity {
		t.Fatalf("batch order = %+v", statuses)
	}
	if statuses[0].SavedState != savedqueryapp.SavedStateConfirmedUnsaved ||
		statuses[0].Eligibility != savedqueryapp.EligibilityEligible ||
		statuses[0].ResourceVersion != 2 || statuses[0].EffectiveCollectionCount != 0 {
		t.Fatalf("removed guide status = %+v", statuses[0])
	}
	if statuses[1].SavedState != savedqueryapp.SavedStateUnknown ||
		statuses[1].Eligibility != savedqueryapp.EligibilityUnknown || statuses[1].ResourceVersion != 0 {
		t.Fatalf("unknown status = %+v", statuses[1])
	}

	foreignStatus, err := queryRepository.GetStatus(context.Background(), savedqueryapp.StatusQuery{
		OwnerUserID: ownerB,
		Target:      activity,
	})
	if err != nil || foreignStatus.SavedState != savedqueryapp.SavedStateUnknown {
		t.Fatalf("foreign owner activity status = (%+v, %v)", foreignStatus, err)
	}

	page, err := queryRepository.ListItems(context.Background(), savedqueryapp.ListQuery{
		OwnerUserID: ownerA,
		Locale:      savedqueryapp.LocaleRU,
		Limit:       100,
		ReadAt:      readAt,
	})
	if err != nil {
		t.Fatalf("ListItems(all) error = %v", err)
	}
	if len(page.Items) != 2 || page.Items[0].Target != activity || page.Items[1].Target != attraction {
		t.Fatalf("all items/order = %+v", queryTargets(page.Items))
	}
	if page.Items[0].Projection.ContentState != savedqueryapp.ContentStateUnavailable ||
		page.Items[0].Projection.Public != nil || page.Items[0].EffectiveCollectionCount != 1 {
		t.Fatalf("private activity leaked projection = %+v", page.Items[0])
	}
	if page.Items[1].Projection.ContentState != savedqueryapp.ContentStateAvailable ||
		page.Items[1].Projection.Public == nil || page.Items[1].Projection.Public.Title != "Национальный музей" ||
		page.Items[1].Projection.Public.CanonicalDetailRoute == "" ||
		page.Items[1].Projection.Public.ResolvedImageURL != nil {
		t.Fatalf("public attraction projection = %+v", page.Items[1].Projection)
	}

	expiredPage, err := queryRepository.ListItems(context.Background(), savedqueryapp.ListQuery{
		OwnerUserID: ownerA,
		Locale:      savedqueryapp.LocaleEN,
		Limit:       100,
		ReadAt:      base.Add(20 * time.Minute),
	})
	if err != nil {
		t.Fatalf("ListItems(expired media) error = %v", err)
	}
	if expiredPage.Items[1].Projection.Public == nil ||
		expiredPage.Items[1].Projection.Public.ResolvedImageURL != nil {
		t.Fatalf("opaque/expired media exposed = %+v", expiredPage.Items[1].Projection.Public)
	}

	activityType := domain.EntityTypeActivity
	filtered, err := queryRepository.ListItems(context.Background(), savedqueryapp.ListQuery{
		OwnerUserID: ownerA,
		Locale:      savedqueryapp.LocaleEN,
		EntityType:  &activityType,
		Limit:       100,
		ReadAt:      readAt,
	})
	if err != nil || len(filtered.Items) != 1 || filtered.Items[0].Target != activity {
		t.Fatalf("activity filter = (%+v, %v)", queryTargets(filtered.Items), err)
	}

	collectionPage, err := queryRepository.ListItems(context.Background(), savedqueryapp.ListQuery{
		OwnerUserID: ownerA,
		Locale:      savedqueryapp.LocaleEN,
		Collection:  &activeCollection,
		Limit:       100,
		ReadAt:      readAt,
	})
	if err != nil || len(collectionPage.Items) != 1 || collectionPage.Items[0].Target != activity {
		t.Fatalf("collection filter = (%+v, %v)", queryTargets(collectionPage.Items), err)
	}

	uncollectedPage, err := queryRepository.ListItems(context.Background(), savedqueryapp.ListQuery{
		OwnerUserID: ownerA,
		Locale:      savedqueryapp.LocaleEN,
		Uncollected: true,
		Limit:       100,
		ReadAt:      readAt,
	})
	if err != nil || len(uncollectedPage.Items) != 1 || uncollectedPage.Items[0].Target != attraction {
		t.Fatalf("uncollected filter = (%+v, %v)", queryTargets(uncollectedPage.Items), err)
	}

	for name, ownerAndCollection := range map[string]struct {
		owner      uuid.UUID
		collection uuid.UUID
	}{
		"foreign": {owner: ownerB, collection: activeCollection},
		"deleted": {owner: ownerA, collection: deletedCollection},
	} {
		_, err := queryRepository.ListItems(context.Background(), savedqueryapp.ListQuery{
			OwnerUserID: ownerAndCollection.owner,
			Locale:      savedqueryapp.LocaleEN,
			Collection:  &ownerAndCollection.collection,
			Limit:       100,
			ReadAt:      readAt,
		})
		if !errors.Is(err, savedqueryapp.ErrCollectionNotFound) {
			t.Fatalf("%s collection error = %v, want %v", name, err, savedqueryapp.ErrCollectionNotFound)
		}
	}
}

func TestPGSavedQueryRepositoryKeysetPaginationAndConcurrentReads(t *testing.T) {
	_, operationStore, mutationRepository := openSavedItemKernelIntegration(t)
	queryRepository, err := NewPGSavedQueryRepository(mutationRepository.pool)
	if err != nil {
		t.Fatalf("NewPGSavedQueryRepository() error = %v", err)
	}

	base := time.Now().UTC().Add(-time.Minute).Truncate(time.Microsecond)
	readAt := base.Add(10 * time.Second)
	owner := uuid.New()
	subject := uuid.New()
	session := uuid.New()
	ids := []uuid.UUID{
		uuid.MustParse("f0000000-0000-4000-8000-000000000004"),
		uuid.MustParse("e0000000-0000-4000-8000-000000000003"),
		uuid.MustParse("d0000000-0000-4000-8000-000000000002"),
		uuid.MustParse("c0000000-0000-4000-8000-000000000001"),
	}
	targetByID := make(map[uuid.UUID]domain.SavedTarget, len(ids)+1)
	for index, itemID := range ids {
		target := integrationSavedTarget(t, domain.EntityTypeAttraction)
		targetByID[itemID] = target
		seedQuerySavedItem(
			t,
			operationStore,
			mutationRepository,
			subject,
			session,
			owner,
			target,
			base,
			byte(index+20),
			itemID,
		)
	}

	first, err := queryRepository.ListItems(context.Background(), savedqueryapp.ListQuery{
		OwnerUserID: owner,
		Locale:      savedqueryapp.LocaleEN,
		Limit:       2,
		ReadAt:      readAt,
	})
	if err != nil {
		t.Fatalf("first page error = %v", err)
	}
	if !first.HasMore || first.Next == nil || len(first.Items) != 2 ||
		first.Items[0].ItemID != ids[0] || first.Items[1].ItemID != ids[1] {
		t.Fatalf("first page = %+v", queryItemIDs(first.Items))
	}

	newerID := uuid.MustParse("ff000000-0000-4000-8000-000000000005")
	newerTarget := integrationSavedTarget(t, domain.EntityTypeGuide)
	targetByID[newerID] = newerTarget
	seedQuerySavedItem(t, operationStore, mutationRepository, subject, session, owner, newerTarget, base, 30, newerID)
	seedQueryGlobalUnsave(
		t,
		operationStore,
		mutationRepository,
		subject,
		session,
		owner,
		targetByID[ids[2]],
		base.Add(time.Second),
		31,
	)

	second, err := queryRepository.ListItems(context.Background(), savedqueryapp.ListQuery{
		OwnerUserID: owner,
		Locale:      savedqueryapp.LocaleEN,
		After:       first.Next,
		Limit:       2,
		ReadAt:      readAt,
	})
	if err != nil {
		t.Fatalf("second page error = %v", err)
	}
	if second.HasMore || second.Next != nil || len(second.Items) != 1 || second.Items[0].ItemID != ids[3] {
		t.Fatalf("second page after insert/delete = %+v", queryItemIDs(second.Items))
	}
	for _, item := range second.Items {
		if item.ItemID == newerID || item.ItemID == first.Items[0].ItemID || item.ItemID == first.Items[1].ItemID {
			t.Fatalf("cursor page contains duplicate/newer item %s", item.ItemID)
		}
	}

	refreshed, err := queryRepository.ListItems(context.Background(), savedqueryapp.ListQuery{
		OwnerUserID: owner,
		Locale:      savedqueryapp.LocaleEN,
		Limit:       2,
		ReadAt:      readAt,
	})
	if err != nil || len(refreshed.Items) != 2 || refreshed.Items[0].ItemID != newerID || refreshed.Items[1].ItemID != ids[0] {
		t.Fatalf("refreshed page = (%+v, %v)", queryItemIDs(refreshed.Items), err)
	}

	const readers = 24
	errorsByReader := make(chan error, readers)
	var waitGroup sync.WaitGroup
	waitGroup.Add(readers)
	for range readers {
		go func() {
			defer waitGroup.Done()
			page, err := queryRepository.ListItems(context.Background(), savedqueryapp.ListQuery{
				OwnerUserID: owner,
				Locale:      savedqueryapp.LocaleEN,
				Limit:       100,
				ReadAt:      readAt,
			})
			if err != nil {
				errorsByReader <- err
				return
			}
			if len(page.Items) != 4 || hasDuplicateQueryItem(page.Items) {
				errorsByReader <- savedqueryapp.ErrDataInvariant
			}
		}()
	}
	waitGroup.Wait()
	close(errorsByReader)
	for err := range errorsByReader {
		t.Fatalf("concurrent reader error = %v", err)
	}
}

func seedQuerySavedItem(
	t testing.TB,
	operationStore *PGOperationStore,
	repository *PGSavedItemRepository,
	subject uuid.UUID,
	session uuid.UUID,
	owner uuid.UUID,
	target domain.SavedTarget,
	savedAt time.Time,
	seed byte,
	itemID uuid.UUID,
) {
	t.Helper()
	identity := createKernelOperation(
		t,
		operationStore,
		subject,
		session,
		domain.OperationKindSave,
		seed,
		savedAt,
		savedAt.Add(10*time.Second),
	)
	command := integrationSaveCommand(t, identity, owner, target, savedAt, uint64(seed)+1)
	if itemID != uuid.Nil {
		command.SavedItemID = itemID
	}
	if _, err := repository.Save(context.Background(), command); err != nil {
		t.Fatalf("seed Save() error = %v", err)
	}
}

func seedQueryGlobalUnsave(
	t testing.TB,
	operationStore *PGOperationStore,
	repository *PGSavedItemRepository,
	subject uuid.UUID,
	session uuid.UUID,
	owner uuid.UUID,
	target domain.SavedTarget,
	removedAt time.Time,
	seed byte,
) {
	t.Helper()
	identity := createKernelOperation(
		t,
		operationStore,
		subject,
		session,
		domain.OperationKindUnsave,
		seed,
		removedAt,
		removedAt.Add(10*time.Second),
	)
	if _, err := repository.GlobalUnsave(
		context.Background(),
		integrationUnsaveCommand(identity, owner, target, removedAt),
	); err != nil {
		t.Fatalf("seed GlobalUnsave() error = %v", err)
	}
}

func queryCollectionIDs(t testing.TB, pool *pgxpool.Pool, owner uuid.UUID) (uuid.UUID, uuid.UUID) {
	t.Helper()
	rows, err := pool.Query(context.Background(), `
        SELECT id::text
        FROM saved_collections
        WHERE owner_user_id = $1
        ORDER BY id`, owner.String())
	if err != nil {
		t.Fatalf("query collection IDs: %v", err)
	}
	defer rows.Close()
	ids := make([]uuid.UUID, 0, 2)
	for rows.Next() {
		var raw string
		if err := rows.Scan(&raw); err != nil {
			t.Fatalf("scan collection ID: %v", err)
		}
		parsed, err := uuid.Parse(raw)
		if err != nil {
			t.Fatalf("parse collection ID: %v", err)
		}
		ids = append(ids, parsed)
	}
	if err := rows.Err(); err != nil {
		t.Fatalf("iterate collection IDs: %v", err)
	}
	if len(ids) != 2 {
		t.Fatalf("collection IDs = %d, want 2", len(ids))
	}
	return ids[0], ids[1]
}

func markQueryCollectionDeleted(
	t testing.TB,
	pool *pgxpool.Pool,
	owner uuid.UUID,
	collection uuid.UUID,
	deletedAt time.Time,
) {
	t.Helper()
	result, err := pool.Exec(context.Background(), `
        UPDATE saved_collections
        SET title = NULL,
            normalized_title_key = NULL,
            lifecycle_state = 'DELETED',
            lifecycle_version = lifecycle_version + 1,
            active_item_count = 0,
            updated_at = $3::timestamptz,
            deleted_at = $3::timestamptz,
            purge_eligible_at = $3::timestamptz + INTERVAL '14 days'
        WHERE owner_user_id = $1 AND id = $2`, owner.String(), collection.String(), deletedAt)
	if err != nil {
		t.Fatalf("delete query collection: %v", err)
	}
	if result.RowsAffected() != 1 {
		t.Fatalf("deleted collection rows = %d, want 1", result.RowsAffected())
	}
}

func markQueryProjectionPrivate(
	t testing.TB,
	pool *pgxpool.Pool,
	target domain.SavedTarget,
	validatedAt time.Time,
) {
	t.Helper()
	result, err := pool.Exec(context.Background(), `
        UPDATE saved_content_projections
        SET source_revision = source_revision + 1,
            projection_revision = projection_revision + 1,
            visibility_revision = visibility_revision + 1,
            visibility_status = 'PRIVATE',
            visibility_validated_at = $3,
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
            updated_at = $3
        WHERE entity_type = $1 AND entity_id = $2`,
		string(target.EntityType()), target.EntityID(), validatedAt)
	if err != nil {
		t.Fatalf("make projection PRIVATE: %v", err)
	}
	if result.RowsAffected() != 1 {
		t.Fatalf("private projection rows = %d, want 1", result.RowsAffected())
	}
}

func queryTargets(items []savedqueryapp.Item) []domain.SavedTarget {
	result := make([]domain.SavedTarget, len(items))
	for index, item := range items {
		result[index] = item.Target
	}
	return result
}

func queryItemIDs(items []savedqueryapp.Item) []uuid.UUID {
	result := make([]uuid.UUID, len(items))
	for index, item := range items {
		result[index] = item.ItemID
	}
	return result
}

func hasDuplicateQueryItem(items []savedqueryapp.Item) bool {
	ids := queryItemIDs(items)
	sort.Slice(ids, func(left, right int) bool { return ids[left].String() < ids[right].String() })
	for index := 1; index < len(ids); index++ {
		if ids[index] == ids[index-1] {
			return true
		}
	}
	return false
}
