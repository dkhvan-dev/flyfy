package repository

import (
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"

	savedqueryapp "kz/inflap/backend/services/saved-service/internal/app/savedquery"
	savedsearchapp "kz/inflap/backend/services/saved-service/internal/app/savedsearch"
	"kz/inflap/backend/services/saved-service/internal/domain"
)

func TestSavedSearchSQLUsesClosedOwnerPublicVariants(t *testing.T) {
	t.Parallel()

	term, err := savedsearchapp.Normalize("Museum")
	if err != nil {
		t.Fatalf("Normalize() error = %v", err)
	}
	collectionID := uuid.New()
	base := savedsearchapp.Query{Term: term}
	allSQL := savedSearchSQL(base)
	collectionSQL := savedSearchSQL(savedsearchapp.Query{Term: term, Collection: &collectionID})
	uncollectedSQL := savedSearchSQL(savedsearchapp.Query{Term: term, Uncollected: true})

	for name, querySQL := range map[string]string{
		"all":         allSQL,
		"collection":  collectionSQL,
		"uncollected": uncollectedSQL,
	} {
		for _, required := range []string{
			"WITH owner_items AS MATERIALIZED",
			"owner_user_id = $1::uuid",
			"relationship_state = 'ACTIVE'",
			"projections.visibility_status = 'PUBLIC'",
			"projections.search_document_version = projections.projection_revision",
			"winning_match.match_rank > $5::smallint",
			"(saved_items.saved_at, saved_items.id) < ($6::timestamptz, $7::uuid)",
			"ORDER BY winning_match.match_rank ASC, saved_items.saved_at DESC, saved_items.id DESC",
			"LIMIT $8",
		} {
			if !strings.Contains(querySQL, required) {
				t.Errorf("%s SQL misses invariant %q", name, required)
			}
		}
	}
	if strings.Contains(allSQL, "filter_membership") {
		t.Fatal("all-search SQL unexpectedly contains a collection filter")
	}
	if !strings.Contains(collectionSQL, "filter_membership.collection_id = $11::uuid") ||
		strings.Contains(collectionSQL, "filter_collection") {
		t.Fatal("collection SQL does not use the exact positive membership scope")
	}
	if !strings.Contains(uncollectedSQL, "AND NOT EXISTS") ||
		!strings.Contains(uncollectedSQL, "filter_collection.lifecycle_state = 'ACTIVE'") {
		t.Fatal("uncollected SQL does not ignore ineffective memberships")
	}

	lowerSQL := strings.ToLower(allSQL)
	for _, banned := range []string{
		" ilike ",
		"similarity(",
		"levenshtein",
		"pg_trgm",
		"unaccent(",
		"to_tsvector",
		"tsquery",
		"transliter",
		"position(",
	} {
		if strings.Contains(lowerSQL, banned) {
			t.Errorf("search SQL contains out-of-scope construct %q", banned)
		}
	}
}

func TestSavedSearchSQLPinsWinningTuple(t *testing.T) {
	t.Parallel()

	for _, required := range []string{
		"WHEN fields.matched_field = 'TITLE' AND characteristics.full_field_exact THEN 1",
		"WHEN fields.matched_field = 'TITLE' AND characteristics.all_tokens_exact THEN 2",
		"WHEN fields.matched_field = 'TITLE' AND characteristics.field_or_tokens_prefix THEN 3",
		"AND (characteristics.full_field_exact OR characteristics.all_tokens_exact) THEN 4",
		"WHEN fields.matched_field <> 'TITLE' AND characteristics.field_or_tokens_prefix THEN 5",
		"ORDER BY evaluated.match_rank",
		"fields.field_priority",
		"WHEN fields.matched_locale = $10::text THEN 0",
		"WHEN fields.matched_locale = projections.source_default_locale THEN 1",
		"WHEN fields.matched_locale = 'EN' THEN 2",
		"WHEN fields.matched_locale = 'RU' THEN 3",
		"WHEN fields.matched_locale = 'KK' THEN 4",
	} {
		if !strings.Contains(savedSearchSelectSQL, required) {
			t.Errorf("search SQL misses deterministic winner fragment %q", required)
		}
	}
	if got := strings.Count(savedSearchSelectSQL, "projections.search_title_"); got != 3 {
		t.Errorf("title locale field count = %d, want 3", got)
	}
	if got := strings.Count(savedSearchSelectSQL, "projections.search_city_"); got != 3 {
		t.Errorf("city locale field count = %d, want 3", got)
	}
	if got := strings.Count(savedSearchSelectSQL, "projections.search_country_"); got != 3 {
		t.Errorf("country locale field count = %d, want 3", got)
	}
}

func TestSavedSearchArgumentsContainOnlyNormalizedTermAndDecodedKeyset(t *testing.T) {
	t.Parallel()

	raw := "  ＭＵＳＥＵＭ!!! "
	term, err := savedsearchapp.Normalize(raw)
	if err != nil {
		t.Fatalf("Normalize() error = %v", err)
	}
	now := time.Now().UTC()
	query := savedsearchapp.Query{
		OwnerUserID: uuid.New(),
		Locale:      savedqueryapp.LocaleKK,
		Term:        term,
		After: &savedsearchapp.Keyset{
			MatchRank: savedsearchapp.MatchRankTitlePrefix,
			SavedAt:   now.Add(-time.Minute),
			ItemID:    uuid.New(),
		},
		Limit:  30,
		ReadAt: now,
	}
	arguments := savedSearchArguments(query)
	if len(arguments) != 10 || arguments[2] != "museum" || arguments[4] != int16(3) ||
		arguments[7] != 31 || arguments[9] != "KK" {
		t.Fatal("saved search arguments violated the normalized boundary contract")
	}
	tokens, ok := arguments[3].([]string)
	if !ok || len(tokens) != 1 || tokens[0] != "museum" {
		t.Fatal("saved search token arguments violated the normalized boundary contract")
	}
	for _, argument := range arguments {
		if value, ok := argument.(string); ok && value == raw {
			t.Fatal("raw query crossed the PostgreSQL boundary")
		}
	}
}

func TestSavedSearchMatchReturnsAlternateOnlyWhenRequired(t *testing.T) {
	t.Parallel()

	public := &savedqueryapp.PublicCardProjection{
		DisplayLocale: savedqueryapp.LocaleEN,
		Title:         "Museum",
	}
	match, err := savedSearchMatch(
		savedsearchapp.MatchRankTitleExact,
		savedsearchapp.MatchKindExact,
		savedsearchapp.MatchedFieldTitle,
		savedqueryapp.LocaleEN,
		"Museum",
		public,
	)
	if err != nil || match.AlternatePublicDisplay != nil {
		t.Fatalf("current title match failed its contract: %v", err)
	}

	match, err = savedSearchMatch(
		savedsearchapp.MatchRankTitleToken,
		savedsearchapp.MatchKindToken,
		savedsearchapp.MatchedFieldTitle,
		savedqueryapp.LocaleRU,
		"Национальный музей",
		public,
	)
	if err != nil || match.AlternatePublicDisplay == nil ||
		*match.AlternatePublicDisplay != "Национальный музей" {
		t.Fatalf("alternate title match failed its contract: %v", err)
	}

	match, err = savedSearchMatch(
		savedsearchapp.MatchRankLocationExactOrToken,
		savedsearchapp.MatchKindExact,
		savedsearchapp.MatchedFieldCity,
		savedqueryapp.LocaleEN,
		"Museum City",
		public,
	)
	if err != nil || match.AlternatePublicDisplay == nil || *match.AlternatePublicDisplay != "Museum City" {
		t.Fatalf("location match failed its contract: %v", err)
	}

	if _, err := savedSearchMatch(
		savedsearchapp.MatchRankTitleExact,
		savedsearchapp.MatchKindPrefix,
		savedsearchapp.MatchedFieldTitle,
		savedqueryapp.LocaleEN,
		"Museum",
		public,
	); err == nil {
		t.Fatal("invalid rank/kind shape was accepted")
	}
}

func TestSavedSearchTypeFilterArgumentIsClosed(t *testing.T) {
	t.Parallel()

	term, err := savedsearchapp.Normalize("museum")
	if err != nil {
		t.Fatalf("Normalize() error = %v", err)
	}
	entityType := domain.EntityTypeAttraction
	query := savedsearchapp.Query{EntityType: &entityType, Term: term}
	arguments := savedSearchArguments(query)
	if arguments[1] != "ATTRACTION" {
		t.Fatal("saved search entity type argument is not closed")
	}
}
