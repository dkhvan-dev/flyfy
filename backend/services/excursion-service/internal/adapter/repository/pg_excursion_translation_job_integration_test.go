package repository

import (
	"context"
	"encoding/json"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"

	"kz/inflap/backend/services/excursion-service/internal/domain/model"
	"kz/inflap/backend/services/excursion-service/internal/domain/port"
)

func TestPGExcursionTranslationJobLifecycleAgainstPostgres(t *testing.T) {
	dsn := strings.TrimSpace(os.Getenv("EXCURSION_SERVICE_REPOSITORY_TEST_DSN"))
	if dsn == "" {
		t.Skip("EXCURSION_SERVICE_REPOSITORY_TEST_DSN is not set")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	pool, err := pgxpool.New(ctx, dsn)
	if err != nil {
		t.Fatalf("open PostgreSQL pool: %v", err)
	}
	t.Cleanup(pool.Close)
	if err = pool.Ping(ctx); err != nil {
		t.Fatalf("ping PostgreSQL: %v", err)
	}

	repo := NewPGExcursionRepository(pool)
	excursion := validRepositoryExcursion(t)
	landmarkID := uuid.New()
	landmarkName := "Translation integration landmark"
	excursion.LandmarkID = &landmarkID
	excursion.LandmarkName = &landmarkName
	if err = excursion.SetTranslationState("ru", model.ExcursionTranslationPending); err != nil {
		t.Fatalf("set translation state: %v", err)
	}
	itineraryItem, err := model.NewExcursionItineraryItem(model.NewExcursionItineraryItemParams{
		ExcursionID: excursion.ID,
		SortOrder:   0,
		Title:       "Выезд из отеля",
		Description: "Встречаемся с гидом и начинаем маршрут.",
		Translations: model.ExcursionItineraryTranslations{
			"ru": {
				Title:       "Выезд из отеля",
				Description: "Встречаемся с гидом и начинаем маршрут.",
			},
		},
	})
	if err != nil {
		t.Fatalf("create itinerary item: %v", err)
	}

	fields := map[string]string{
		"title":       itineraryItem.Title,
		"description": itineraryItem.Description,
	}
	now := time.Now().UTC()
	job := model.ExcursionTranslationJob{
		ID:             uuid.New(),
		ExcursionID:    excursion.ID,
		EntityType:     model.ExcursionTranslationEntityItineraryItem,
		EntityID:       itineraryItem.ID,
		SourceLanguage: "ru",
		TargetLanguage: "en",
		SourceFields:   fields,
		SourceHash:     model.HashExcursionTranslationSource("ru", fields),
		Status:         model.ExcursionTranslationJobPending,
		MaxAttempts:    5,
		NextRunAt:      now,
		CreatedAt:      now,
		UpdatedAt:      now,
	}
	relations := port.ExcursionRelations{
		Itinerary:             []*model.ExcursionItineraryItem{itineraryItem},
		PhotoFileIDs:          []uuid.UUID{},
		ProductPhotoFileIDs:   []uuid.UUID{},
		ProductPhotoImageURLs: []string{},
		TranslationJobs:       []model.ExcursionTranslationJob{job},
	}

	canonicalKey := excursionMarketplaceCanonicalKey(excursion, relations)
	t.Cleanup(func() {
		cleanupCtx, cleanupCancel := context.WithTimeout(context.Background(), 10*time.Second)
		defer cleanupCancel()
		_, _ = pool.Exec(cleanupCtx, "DELETE FROM excursion_products WHERE canonical_key = $1", canonicalKey)
		_, _ = pool.Exec(cleanupCtx, "DELETE FROM excursions WHERE id = $1", excursion.ID)
	})

	if err = repo.CreateExcursionAggregate(ctx, excursion, relations); err != nil {
		t.Fatalf("create excursion aggregate: %v", err)
	}

	claimed, err := repo.ClaimExcursionTranslationJobs(ctx, "integration-worker", 10, time.Minute)
	if err != nil {
		t.Fatalf("claim translation jobs: %v", err)
	}
	if len(claimed) != 1 || claimed[0].ID != job.ID {
		t.Fatalf("claimed jobs = %#v, want job %s", claimed, job.ID)
	}
	claimedAgain, err := repo.ClaimExcursionTranslationJobs(ctx, "other-worker", 10, time.Minute)
	if err != nil {
		t.Fatalf("claim translation jobs again: %v", err)
	}
	if len(claimedAgain) != 0 {
		t.Fatalf("second worker claimed %d processing jobs, want 0", len(claimedAgain))
	}

	applyResult, err := repo.ApplyExcursionTranslationJob(ctx, job.ID, map[string]string{
		"title":       "Hotel departure",
		"description": "Meet your guide and start the route.",
	}, "integration-provider")
	if err != nil {
		t.Fatalf("apply translation job: %v", err)
	}
	if applyResult != model.ExcursionTranslationApplied {
		t.Fatalf("apply result = %s, want %s", applyResult, model.ExcursionTranslationApplied)
	}

	assertStoredItineraryTranslation(t, ctx, pool, repo, excursion.ID, itineraryItem.ID)

	duplicate := job
	duplicate.ID = uuid.New()
	if err = repo.EnqueueExcursionTranslationJobs(ctx, []model.ExcursionTranslationJob{duplicate}); err != nil {
		t.Fatalf("enqueue duplicate translation job: %v", err)
	}
	var (
		jobCount          int
		jobStatus         string
		translationStatus string
	)
	err = pool.QueryRow(ctx, `
		SELECT COUNT(*), MIN(status)
		FROM excursion_translation_jobs
		WHERE entity_type = $1 AND entity_id = $2 AND target_language = $3 AND source_hash = $4
	`, string(job.EntityType), job.EntityID, job.TargetLanguage, job.SourceHash).Scan(&jobCount, &jobStatus)
	if err != nil {
		t.Fatalf("read deduplicated jobs: %v", err)
	}
	if jobCount != 1 || jobStatus != string(model.ExcursionTranslationJobCompleted) {
		t.Fatalf("job count/status = %d/%s, want 1/COMPLETED", jobCount, jobStatus)
	}
	if err = pool.QueryRow(ctx, "SELECT translation_status FROM excursions WHERE id = $1", excursion.ID).Scan(&translationStatus); err != nil {
		t.Fatalf("read excursion translation status: %v", err)
	}
	if translationStatus != string(model.ExcursionTranslationCompleted) {
		t.Fatalf("translation status = %s, want COMPLETED", translationStatus)
	}

	staleJob := job
	staleJob.ID = uuid.New()
	staleJob.TargetLanguage = "kk"
	staleJob.Status = model.ExcursionTranslationJobPending
	staleJob.Provider = nil
	staleJob.CompletedAt = nil
	staleJob.CreatedAt = time.Now().UTC()
	staleJob.UpdatedAt = staleJob.CreatedAt
	staleJob.NextRunAt = staleJob.CreatedAt.Add(-time.Second)
	if err = repo.EnqueueExcursionTranslationJobs(ctx, []model.ExcursionTranslationJob{staleJob}); err != nil {
		t.Fatalf("enqueue stale-guard translation job: %v", err)
	}
	var (
		storedStaleStatus string
		storedStaleDue    bool
	)
	if err = pool.QueryRow(ctx, `
		SELECT status, next_run_at <= NOW()
		FROM excursion_translation_jobs
		WHERE id = $1
	`, staleJob.ID).Scan(&storedStaleStatus, &storedStaleDue); err != nil {
		t.Fatalf("read queued stale-guard job: %v", err)
	}
	if storedStaleStatus != string(model.ExcursionTranslationJobPending) || !storedStaleDue {
		t.Fatalf("queued stale-guard status/due = %s/%t, want PENDING/true", storedStaleStatus, storedStaleDue)
	}
	claimedForFailure, err := repo.ClaimExcursionTranslationJobs(ctx, "failure-worker", 10, time.Minute)
	if err != nil {
		t.Fatalf("claim recoverable translation job: %v", err)
	}
	if len(claimedForFailure) != 1 || claimedForFailure[0].ID != staleJob.ID {
		t.Fatalf("claimed recoverable jobs = %#v, want %s", claimedForFailure, staleJob.ID)
	}
	if err = repo.FailExcursionTranslationJob(
		ctx,
		staleJob.ID,
		false,
		time.Now().UTC().Add(time.Minute),
		"invalid_request",
	); err != nil {
		t.Fatalf("fail recoverable translation job: %v", err)
	}
	var failedAttempts int
	if err = pool.QueryRow(ctx, `
		SELECT status, attempts
		FROM excursion_translation_jobs
		WHERE id = $1
	`, staleJob.ID).Scan(&storedStaleStatus, &failedAttempts); err != nil {
		t.Fatalf("read failed recoverable job: %v", err)
	}
	if storedStaleStatus != string(model.ExcursionTranslationJobFailed) || failedAttempts != 1 {
		t.Fatalf("failed recoverable status/attempts = %s/%d, want FAILED/1", storedStaleStatus, failedAttempts)
	}
	if err = repo.EnqueueExcursionTranslationJobs(ctx, []model.ExcursionTranslationJob{staleJob}); err != nil {
		t.Fatalf("requeue failed translation job: %v", err)
	}
	if err = pool.QueryRow(ctx, `
		SELECT status, attempts, next_run_at <= NOW()
		FROM excursion_translation_jobs
		WHERE id = $1
	`, staleJob.ID).Scan(&storedStaleStatus, &failedAttempts, &storedStaleDue); err != nil {
		t.Fatalf("read requeued translation job: %v", err)
	}
	if storedStaleStatus != string(model.ExcursionTranslationJobPending) || failedAttempts != 0 || !storedStaleDue {
		t.Fatalf("requeued status/attempts/due = %s/%d/%t, want PENDING/0/true", storedStaleStatus, failedAttempts, storedStaleDue)
	}
	claimedStale, err := repo.ClaimExcursionTranslationJobs(ctx, "stale-worker", 10, time.Minute)
	if err != nil {
		t.Fatalf("claim requeued stale-guard job: %v", err)
	}
	if len(claimedStale) != 1 || claimedStale[0].ID != staleJob.ID {
		t.Fatalf("claimed requeued stale-guard jobs = %#v, want %s", claimedStale, staleJob.ID)
	}

	updatedSource := model.ExcursionItineraryLocalizedCopy{
		Title:       "Обновлённый выезд из отеля",
		Description: "Обновлённое описание начала маршрута.",
	}
	updatedSourceJSON, err := json.Marshal(updatedSource)
	if err != nil {
		t.Fatalf("encode updated source: %v", err)
	}
	if _, err = pool.Exec(ctx, `
		UPDATE excursion_itinerary_items
		SET title = $2,
		    description = $3,
		    translations = jsonb_set(translations, '{ru}', $4::jsonb, TRUE),
		    updated_at = NOW()
		WHERE id = $1
	`, itineraryItem.ID, updatedSource.Title, updatedSource.Description, updatedSourceJSON); err != nil {
		t.Fatalf("change itinerary source during translation: %v", err)
	}
	staleResult, err := repo.ApplyExcursionTranslationJob(ctx, staleJob.ID, map[string]string{
		"title":       "Қонақүйден шығу",
		"description": "Гидпен кездесіп, маршрутты бастаңыз.",
	}, "integration-provider")
	if err != nil {
		t.Fatalf("apply stale translation job: %v", err)
	}
	if staleResult != model.ExcursionTranslationStale {
		t.Fatalf("stale apply result = %s, want %s", staleResult, model.ExcursionTranslationStale)
	}
	var (
		staleStatus       string
		kazakhTranslation bool
	)
	if err = pool.QueryRow(ctx, `
		SELECT job.status, item.translations ? 'kk'
		FROM excursion_translation_jobs AS job
		JOIN excursion_itinerary_items AS item ON item.id = job.entity_id
		WHERE job.id = $1
	`, staleJob.ID).Scan(&staleStatus, &kazakhTranslation); err != nil {
		t.Fatalf("read stale translation result: %v", err)
	}
	if staleStatus != string(model.ExcursionTranslationJobStale) || kazakhTranslation {
		t.Fatalf("stale status/translation = %s/%t, want STALE/false", staleStatus, kazakhTranslation)
	}
}

func TestUpsertExcursionProductWithNilPhotosAgainstPostgres(t *testing.T) {
	dsn := strings.TrimSpace(os.Getenv("EXCURSION_SERVICE_REPOSITORY_TEST_DSN"))
	if dsn == "" {
		t.Skip("EXCURSION_SERVICE_REPOSITORY_TEST_DSN is not set")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()
	pool, err := pgxpool.New(ctx, dsn)
	if err != nil {
		t.Fatalf("open PostgreSQL pool: %v", err)
	}
	t.Cleanup(pool.Close)
	if err = pool.Ping(ctx); err != nil {
		t.Fatalf("ping PostgreSQL: %v", err)
	}

	tx, err := pool.Begin(ctx)
	if err != nil {
		t.Fatalf("begin product upsert transaction: %v", err)
	}
	defer func() {
		_ = tx.Rollback(context.Background())
	}()

	excursion := validRepositoryExcursion(t)
	landmarkID := uuid.New()
	landmarkName := "Empty gallery integration landmark"
	excursion.LandmarkID = &landmarkID
	excursion.LandmarkName = &landmarkName
	if err = insertExcursion(ctx, tx, excursion); err != nil {
		t.Fatalf("insert excursion for marketplace upsert: %v", err)
	}

	productID, err := upsertExcursionProduct(
		ctx,
		tx,
		excursion,
		port.ExcursionRelations{},
		nil,
		nil,
		nil,
		nil,
	)
	if err != nil {
		t.Fatalf("upsert excursion product with nil photos: %v", err)
	}
	offerID, err := upsertExcursionOffer(ctx, tx, productID, excursion, nil, nil)
	if err != nil {
		t.Fatalf("upsert excursion offer with nil photos: %v", err)
	}

	var photoFileIDs []uuid.UUID
	var photoImageURLs []string
	if err = tx.QueryRow(
		ctx,
		"SELECT photo_file_ids, photo_image_urls FROM excursion_products WHERE id = $1",
		productID,
	).Scan(&photoFileIDs, &photoImageURLs); err != nil {
		t.Fatalf("read upserted product photos: %v", err)
	}
	if photoFileIDs == nil || len(photoFileIDs) != 0 {
		t.Fatalf("photo_file_ids = %#v, want non-nil empty array", photoFileIDs)
	}
	if photoImageURLs == nil || len(photoImageURLs) != 0 {
		t.Fatalf("photo_image_urls = %#v, want non-nil empty array", photoImageURLs)
	}

	var offerPhotoFileIDs []uuid.UUID
	if err = tx.QueryRow(
		ctx,
		"SELECT photo_file_ids FROM excursion_offers WHERE id = $1",
		offerID,
	).Scan(&offerPhotoFileIDs); err != nil {
		t.Fatalf("read upserted offer photos: %v", err)
	}
	if offerPhotoFileIDs == nil || len(offerPhotoFileIDs) != 0 {
		t.Fatalf("offer photo_file_ids = %#v, want non-nil empty array", offerPhotoFileIDs)
	}
}

func assertStoredItineraryTranslation(
	t *testing.T,
	ctx context.Context,
	pool *pgxpool.Pool,
	repo *PGExcursionRepository,
	excursionID uuid.UUID,
	itineraryItemID uuid.UUID,
) {
	t.Helper()
	var legacyRaw []byte
	if err := pool.QueryRow(ctx, `
		SELECT translations
		FROM excursion_itinerary_items
		WHERE id = $1 AND excursion_id = $2
	`, itineraryItemID, excursionID).Scan(&legacyRaw); err != nil {
		t.Fatalf("read legacy itinerary translation: %v", err)
	}
	var legacy model.ExcursionItineraryTranslations
	if err := json.Unmarshal(legacyRaw, &legacy); err != nil {
		t.Fatalf("decode legacy itinerary translation: %v", err)
	}
	if legacy["en"].Title != "Hotel departure" {
		t.Fatalf("legacy English title = %q", legacy["en"].Title)
	}

	var offerID uuid.UUID
	if err := pool.QueryRow(ctx, `
		SELECT id
		FROM excursion_offers
		WHERE legacy_excursion_id = $1
		LIMIT 1
	`, excursionID).Scan(&offerID); err != nil {
		t.Fatalf("read excursion offer: %v", err)
	}
	offerRelations, err := repo.LoadExcursionOfferRelations(ctx, offerID)
	if err != nil {
		t.Fatalf("load offer relations: %v", err)
	}
	if len(offerRelations.Itinerary) != 1 ||
		offerRelations.Itinerary[0].Translations["en"].Description !=
			"Meet your guide and start the route." {
		t.Fatalf("offer itinerary = %#v, want applied English translation", offerRelations.Itinerary)
	}
}
