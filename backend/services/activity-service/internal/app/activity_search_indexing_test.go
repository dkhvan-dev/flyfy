package app

import (
	"context"
	"testing"

	"github.com/google/uuid"

	"kz/inflap/backend/services/activity-service/internal/domain/enum"
	"kz/inflap/backend/services/activity-service/internal/domain/model"
	"kz/inflap/backend/services/activity-service/internal/domain/port"
)

func TestCreatePublicApprovedActivityIndexesSearchDocument(t *testing.T) {
	t.Parallel()

	var storedTags []string
	indexer := &activitySearchIndexerStub{}
	repo := &activityRepoStub{
		replaceTags: func(ctx context.Context, activityID uuid.UUID, tags []string) error {
			storedTags = append([]string(nil), tags...)
			return nil
		},
		listTagsByActivityID: func(ctx context.Context, activityID uuid.UUID) ([]string, error) {
			return append([]string(nil), storedTags...), nil
		},
	}
	uc := NewActivityUseCase(repo)
	uc.SetSearchIndexer(indexer)

	input := validCreateActivityInput()
	input.Title = "Almaty mountain picnic"
	input.Description = "A relaxed weekend picnic in the mountains near Almaty."
	input.Format = enum.ActivityFormatOffline
	input.MeetingURL = nil
	input.CountryCode = stringPtr("KZ")
	input.CityID = stringPtr("almaty")
	input.CityName = stringPtr("Almaty")
	input.AddressText = stringPtr("Big Almaty Lake")
	input.Latitude = floatPtr(43.05)
	input.Longitude = floatPtr(76.98)
	input.CategorySlug = "nature-outdoor"
	input.SubcategorySlug = stringPtr("park-picnic")
	input.Tags = []string{" Mountain ", "Picnic"}
	input.PriceType = enum.ActivityPriceTypePaid
	input.PriceAmount = floatPtr(12000)
	input.Currency = stringPtr("kzt")

	item, err := uc.CreateActivity(context.Background(), input)
	if err != nil {
		t.Fatalf("CreateActivity() error = %v", err)
	}

	if len(indexer.upserts) != 1 {
		t.Fatalf("search upserts = %d, want 1", len(indexer.upserts))
	}
	if len(indexer.deletes) != 0 {
		t.Fatalf("search deletes = %d, want 0", len(indexer.deletes))
	}

	doc := indexer.upserts[0]
	if doc.Domain != "activity" || doc.EntityID != item.ID.String() {
		t.Fatalf("domain/entity = %q/%q, want activity/%s", doc.Domain, doc.EntityID, item.ID)
	}
	if doc.Locale != "en" || doc.Title["en"] != "Almaty mountain picnic" {
		t.Fatalf("locale/title = %q/%#v", doc.Locale, doc.Title)
	}
	if doc.DeepLink != "/activities/"+item.ID.String() {
		t.Fatalf("deep link = %q", doc.DeepLink)
	}
	if doc.CityID != "almaty" || doc.CountryCode != "KZ" {
		t.Fatalf("location = %q/%q, want almaty/KZ", doc.CityID, doc.CountryCode)
	}
	if doc.Latitude == nil || *doc.Latitude != 43.05 || doc.Longitude == nil || *doc.Longitude != 76.98 {
		t.Fatalf("geo = %#v/%#v", doc.Latitude, doc.Longitude)
	}
	if doc.PriceMin == nil || *doc.PriceMin != 12000 || doc.Currency != "KZT" {
		t.Fatalf("price = %#v %q", doc.PriceMin, doc.Currency)
	}
	if doc.Visibility != "public" || doc.ModerationStatus != "approved" {
		t.Fatalf("visibility/moderation = %q/%q", doc.Visibility, doc.ModerationStatus)
	}
	if !containsString(doc.CategoryCodes, "nature-outdoor") || !containsString(doc.CategoryCodes, "park-picnic") {
		t.Fatalf("category codes = %#v", doc.CategoryCodes)
	}
	if !containsString(doc.Tags, "mountain") || !containsString(doc.Tags, "picnic") {
		t.Fatalf("tags = %#v", doc.Tags)
	}
	if doc.SearchTextNormalized == "" {
		t.Fatal("search text normalized is empty")
	}
}

func TestCreateNonPublicActivityDeletesSearchDocument(t *testing.T) {
	t.Parallel()

	indexer := &activitySearchIndexerStub{}
	uc := NewActivityUseCase(&activityRepoStub{})
	uc.SetSearchIndexer(indexer)

	input := validCreateActivityInput()
	input.Visibility = enum.ActivityVisibilityPrivate
	input.VisibilityPassword = stringPtr("secret-pass")

	item, err := uc.CreateActivity(context.Background(), input)
	if err != nil {
		t.Fatalf("CreateActivity() error = %v", err)
	}

	if len(indexer.upserts) != 0 {
		t.Fatalf("search upserts = %d, want 0", len(indexer.upserts))
	}
	if len(indexer.deletes) != 1 {
		t.Fatalf("search deletes = %d, want 1", len(indexer.deletes))
	}
	if indexer.deletes[0].Domain != "activity" || indexer.deletes[0].EntityID != item.ID.String() {
		t.Fatalf("delete request = %#v", indexer.deletes[0])
	}
}

func TestCancelActivityDeletesSearchDocument(t *testing.T) {
	t.Parallel()

	activityID := uuid.New()
	actorUserID := uuid.New()
	indexer := &activitySearchIndexerStub{}
	repo := &activityRepoStub{
		withTx: func(ctx context.Context, fn func(repo port.ActivityTxRepository) error) error {
			return fn(&activityTxRepoStub{
				getActivityByIDForUpdate: func(ctx context.Context, requestedID uuid.UUID) (*model.Activity, error) {
					if requestedID != activityID {
						t.Fatalf("activity id = %s, want %s", requestedID, activityID)
					}
					return validActivity(t, activityID, actorUserID), nil
				},
				listParticipantsByActivityIDForUpdate: func(ctx context.Context, requestedID uuid.UUID) ([]*model.ActivityParticipant, error) {
					if requestedID != activityID {
						t.Fatalf("participants activity id = %s, want %s", requestedID, activityID)
					}
					return nil, nil
				},
			})
		},
	}
	uc := NewActivityUseCase(repo)
	uc.SetSearchIndexer(indexer)

	item, err := uc.CancelActivity(context.Background(), activityID, actorUserID, "weather changed")
	if err != nil {
		t.Fatalf("CancelActivity() error = %v", err)
	}

	if item.Status != enum.ActivityStatusCancelled {
		t.Fatalf("status = %s, want CANCELLED", item.Status)
	}
	if len(indexer.deletes) != 1 {
		t.Fatalf("search deletes = %d, want 1", len(indexer.deletes))
	}
	if indexer.deletes[0].Domain != "activity" || indexer.deletes[0].EntityID != activityID.String() {
		t.Fatalf("delete request = %#v", indexer.deletes[0])
	}
}

func TestBackfillActivitySearchIndexReconcilesDocuments(t *testing.T) {
	t.Parallel()

	publicActivity := validActivity(t, uuid.New(), uuid.New())
	publicActivity.Title = "Charyn canyon hike"
	publicActivity.Description = "Weekend hiking activity"
	publicActivity.CategorySlug = "nature"
	publicActivity.CityID = stringPtr("almaty")
	publicActivity.CityName = stringPtr("Almaty")
	publicActivity.CountryCode = stringPtr("KZ")

	privateActivity := validActivity(t, uuid.New(), uuid.New())
	privateActivity.Visibility = enum.ActivityVisibilityPrivate

	repo := &activitySearchBackfillRepoStub{
		pages: [][]*model.Activity{
			{publicActivity},
			{privateActivity},
		},
		tagsByActivityID: map[uuid.UUID][]string{
			publicActivity.ID: {" Hiking ", "Nature"},
		},
	}
	indexer := &activitySearchIndexerStub{}

	stats, err := BackfillActivitySearchIndex(context.Background(), repo, indexer, SearchIndexBackfillOptions{
		BatchSize:   1,
		DeleteStale: true,
	})
	if err != nil {
		t.Fatalf("BackfillActivitySearchIndex() error = %v", err)
	}

	if stats.Scanned != 2 || stats.Upserted != 1 || stats.Deleted != 1 || stats.Skipped != 0 {
		t.Fatalf("stats = %#v", stats)
	}
	if len(indexer.upserts) != 1 {
		t.Fatalf("upserts = %d, want 1", len(indexer.upserts))
	}
	if indexer.upserts[0].EntityID != publicActivity.ID.String() {
		t.Fatalf("upsert entity = %s, want %s", indexer.upserts[0].EntityID, publicActivity.ID)
	}
	if !containsString(indexer.upserts[0].Tags, "hiking") || !containsString(indexer.upserts[0].Tags, "nature") {
		t.Fatalf("upsert tags = %#v", indexer.upserts[0].Tags)
	}
	if len(indexer.deletes) != 1 {
		t.Fatalf("deletes = %d, want 1", len(indexer.deletes))
	}
	if indexer.deletes[0].EntityID != privateActivity.ID.String() {
		t.Fatalf("delete entity = %s, want %s", indexer.deletes[0].EntityID, privateActivity.ID)
	}
}

type activitySearchIndexerStub struct {
	upserts []SearchIndexDocument
	deletes []SearchIndexDelete
}

func (s *activitySearchIndexerStub) UpsertSearchDocument(_ context.Context, document SearchIndexDocument) error {
	s.upserts = append(s.upserts, document)
	return nil
}

func (s *activitySearchIndexerStub) DeleteSearchDocument(_ context.Context, deletion SearchIndexDelete) error {
	s.deletes = append(s.deletes, deletion)
	return nil
}

type activitySearchBackfillRepoStub struct {
	pages            [][]*model.Activity
	tagsByActivityID map[uuid.UUID][]string
	listCalls        []port.ActivityFilter
}

func (s *activitySearchBackfillRepoStub) ListActivities(_ context.Context, filter port.ActivityFilter) ([]*model.Activity, error) {
	s.listCalls = append(s.listCalls, filter)
	index := len(s.listCalls) - 1
	if index >= len(s.pages) {
		return []*model.Activity{}, nil
	}
	return s.pages[index], nil
}

func (s *activitySearchBackfillRepoStub) ListTagsByActivityID(_ context.Context, activityID uuid.UUID) ([]string, error) {
	return append([]string(nil), s.tagsByActivityID[activityID]...), nil
}
