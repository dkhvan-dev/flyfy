package repository

import (
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"

	savedqueryapp "kz/inflap/backend/services/saved-service/internal/app/savedquery"
	"kz/inflap/backend/services/saved-service/internal/domain"
)

func TestSavedItemsListSQLUsesClosedOwnerScopedVariants(t *testing.T) {
	base := savedqueryapp.ListQuery{}
	collectionID := uuid.New()

	allSQL := savedItemsListSQL(base)
	collectionSQL := savedItemsListSQL(savedqueryapp.ListQuery{Collection: &collectionID})
	uncollectedSQL := savedItemsListSQL(savedqueryapp.ListQuery{Uncollected: true})

	for name, query := range map[string]string{
		"all":         allSQL,
		"collection":  collectionSQL,
		"uncollected": uncollectedSQL,
	} {
		if !strings.Contains(query, "saved_items.owner_user_id = $1::uuid") ||
			!strings.Contains(query, "saved_items.relationship_state = 'ACTIVE'") ||
			!strings.Contains(query, "ORDER BY saved_items.saved_at DESC, saved_items.id DESC") {
			t.Fatalf("%s SQL misses owner/ACTIVE/order invariant", name)
		}
	}
	if strings.Contains(allSQL, "filter_membership") {
		t.Fatal("all-items SQL unexpectedly contains a collection filter")
	}
	if !strings.Contains(collectionSQL, "filter_membership.collection_id = $7::uuid") ||
		strings.Contains(collectionSQL, "NOT EXISTS") {
		t.Fatal("collection SQL does not use the exact positive membership scope")
	}
	if !strings.Contains(uncollectedSQL, "AND NOT EXISTS") ||
		!strings.Contains(uncollectedSQL, "filter_collection.lifecycle_state = 'ACTIVE'") {
		t.Fatal("uncollected SQL does not ignore ineffective memberships")
	}
}

func TestSavedListRowPrivateActivityIsPayloadFree(t *testing.T) {
	now := time.Now().UTC()
	row := validSavedListRow(t, domain.EntityTypeActivity, now)
	row.visibilityStatus = string(domain.VisibilityPrivate)
	row.sourceDefaultLocale = pgtype.Text{String: "EN", Valid: true}
	row.titleEN = pgtype.Text{String: "must not leak", Valid: true}
	row.mediaReference = pgtype.Text{String: "must-not-leak", Valid: true}
	row.mediaReferenceRevision = pgtype.Int8{Int64: 9, Valid: true}
	row.mediaValidUntil = pgtype.Timestamptz{Time: now.Add(time.Minute), Valid: true}
	row.mediaLeaseCurrent = pgtype.Bool{Bool: true, Valid: true}

	item, err := row.toItem(savedqueryapp.LocaleEN, now)
	if err != nil {
		t.Fatalf("toItem() error = %v", err)
	}
	if item.Projection.ContentState != savedqueryapp.ContentStateUnavailable || item.Projection.Public != nil {
		t.Fatalf("private projection leaked payload: %+v", item.Projection)
	}
}

func TestSavedListRowPublicFallbackAndMediaLease(t *testing.T) {
	now := time.Now().UTC()
	row := validSavedListRow(t, domain.EntityTypeAttraction, now)
	row.sourceDefaultLocale = pgtype.Text{String: "RU", Valid: true}
	row.titleEN = pgtype.Text{String: "Museum", Valid: true}
	row.titleRU = pgtype.Text{String: "Музей", Valid: true}
	row.subtitleRU = pgtype.Text{String: strings.Repeat("а", 500), Valid: true}
	row.mediaReference = pgtype.Text{String: "media:cover", Valid: true}
	row.mediaReferenceRevision = pgtype.Int8{Int64: 3, Valid: true}
	row.mediaValidUntil = pgtype.Timestamptz{Time: now.Add(time.Minute), Valid: true}
	row.mediaLeaseCurrent = pgtype.Bool{Bool: true, Valid: true}

	item, err := row.toItem(savedqueryapp.LocaleKK, now)
	if err != nil {
		t.Fatalf("toItem() error = %v", err)
	}
	public := item.Projection.Public
	if public == nil || public.DisplayLocale != savedqueryapp.LocaleRU || public.Title != "Музей" ||
		public.Subtitle == nil || len([]rune(*public.Subtitle)) != 500 ||
		public.CanonicalDetailRoute == "" || public.ResolvedImageURL != nil {
		t.Fatalf("public fallback projection = %+v", public)
	}

	row.mediaLeaseCurrent = pgtype.Bool{Bool: false, Valid: true}
	item, err = row.toItem(savedqueryapp.LocaleKK, row.mediaValidUntil.Time)
	if err != nil {
		t.Fatalf("toItem(expired) error = %v", err)
	}
	if item.Projection.Public == nil || item.Projection.Public.ResolvedImageURL != nil {
		t.Fatalf("opaque/expired media was exposed: %+v", item.Projection.Public)
	}
}

func TestSavedListRowIncoherentMediaFailsClosed(t *testing.T) {
	now := time.Now().UTC()
	row := validSavedListRow(t, domain.EntityTypeAttraction, now)
	row.sourceDefaultLocale = pgtype.Text{String: "EN", Valid: true}
	row.titleEN = pgtype.Text{String: "Museum", Valid: true}
	row.mediaReference = pgtype.Text{String: "attraction-cover:opaque", Valid: true}
	row.mediaValidUntil = pgtype.Timestamptz{Time: now.Add(time.Minute), Valid: true}
	row.mediaLeaseCurrent = pgtype.Bool{Bool: true, Valid: true}

	item, err := row.toItem(savedqueryapp.LocaleEN, now)
	if err != nil {
		t.Fatalf("toItem() error = %v", err)
	}
	if item.Projection.ContentState != savedqueryapp.ContentStateUnavailable || item.Projection.Public != nil {
		t.Fatalf("incoherent media did not fail closed: %+v", item.Projection)
	}
}

func TestSavedListRowMissingCanonicalRouteFailsClosed(t *testing.T) {
	now := time.Now().UTC()
	row := validSavedListRow(t, domain.EntityTypeGuide, now)
	row.sourceDefaultLocale = pgtype.Text{String: "EN", Valid: true}
	row.titleEN = pgtype.Text{String: "Guide", Valid: true}
	row.canonicalDetailRoute = pgtype.Text{}

	item, err := row.toItem(savedqueryapp.LocaleEN, now)
	if err != nil {
		t.Fatalf("toItem() error = %v", err)
	}
	if item.Projection.ContentState != savedqueryapp.ContentStateUnavailable || item.Projection.Public != nil {
		t.Fatalf("missing canonical route did not fail closed: %+v", item.Projection)
	}
}

func TestSavedListRowMalformedPublicPayloadDegradesSafely(t *testing.T) {
	now := time.Now().UTC()
	row := validSavedListRow(t, domain.EntityTypeGuide, now)
	row.sourceDefaultLocale = pgtype.Text{String: "EN", Valid: true}
	row.titleEN = pgtype.Text{String: "unsafe\nvalue", Valid: true}

	item, err := row.toItem(savedqueryapp.LocaleEN, now)
	if err != nil {
		t.Fatalf("toItem() error = %v", err)
	}
	if item.Projection.ContentState != savedqueryapp.ContentStateUnavailable || item.Projection.Public != nil {
		t.Fatalf("malformed projection did not fail closed: %+v", item.Projection)
	}
}

func validSavedListRow(t testing.TB, entityType domain.EntityType, now time.Time) savedListRow {
	t.Helper()
	target, err := domain.NewSavedTarget(entityType, uuid.NewString())
	if err != nil {
		t.Fatalf("NewSavedTarget() error = %v", err)
	}
	return savedListRow{
		itemIDText:                 uuid.NewString(),
		entityType:                 string(target.EntityType()),
		entityID:                   target.EntityID(),
		generationText:             uuid.NewString(),
		attributionText:            uuid.NewString(),
		relationshipVersion:        1,
		dependentMembershipVersion: 0,
		savedAt:                    now.Add(-time.Minute),
		effectiveCollectionCount:   0,
		sourceRevision:             1,
		projectionRevision:         1,
		visibilityRevision:         1,
		visibilityStatus:           string(domain.VisibilityPublic),
		visibilityValidatedAt:      pgtype.Timestamptz{Time: now.Add(-time.Second), Valid: true},
		projectionUpdatedAt:        now.Add(-time.Second),
		canonicalDetailRoute:       pgtype.Text{String: "/details/" + target.EntityID(), Valid: true},
	}
}
