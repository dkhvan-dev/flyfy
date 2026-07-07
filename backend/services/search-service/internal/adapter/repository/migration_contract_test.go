package repository

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestInitialSearchMigrationDefinesSearchIndexContract(t *testing.T) {
	up := readMigration(t, "001_init_search.up.sql")

	required := []string{
		"CREATE EXTENSION IF NOT EXISTS pgcrypto",
		"CREATE EXTENSION IF NOT EXISTS pg_trgm",
		"CREATE EXTENSION IF NOT EXISTS postgis",
		"CREATE TABLE IF NOT EXISTS search_documents",
		"domain TEXT NOT NULL",
		"entity_id TEXT NOT NULL",
		"entity_version BIGINT NOT NULL",
		"search_text_normalized TEXT NOT NULL",
		"search_vector TSVECTOR",
		"visibility TEXT NOT NULL",
		"moderation_status TEXT NOT NULL",
		"CONSTRAINT search_documents_domain_check",
		"CONSTRAINT search_documents_excludes_private_domains",
		"CREATE INDEX IF NOT EXISTS idx_search_documents_vector",
		"USING GIN (search_vector)",
		"CREATE INDEX IF NOT EXISTS idx_search_documents_trgm",
		"gin_trgm_ops",
		"CREATE INDEX IF NOT EXISTS idx_search_documents_geo",
		"USING GIST",
		"CREATE UNIQUE INDEX IF NOT EXISTS idx_search_documents_entity_unique",
	}
	for _, fragment := range required {
		if !strings.Contains(up, fragment) {
			t.Fatalf("migration missing %q", fragment)
		}
	}
}

func TestInitialSearchMigrationDefinesIndexEventContract(t *testing.T) {
	up := readMigration(t, "001_init_search.up.sql")

	required := []string{
		"CREATE TABLE IF NOT EXISTS search_document_events",
		"source_service TEXT NOT NULL",
		"source_event_id TEXT NOT NULL",
		"aggregate_type TEXT NOT NULL",
		"aggregate_id TEXT NOT NULL",
		"event_type TEXT NOT NULL",
		"payload JSONB NOT NULL",
		"status TEXT NOT NULL",
		"attempt_count INT NOT NULL",
		"next_attempt_at TIMESTAMPTZ NOT NULL",
		"CREATE UNIQUE INDEX IF NOT EXISTS idx_search_document_events_source_unique",
		"CREATE INDEX IF NOT EXISTS idx_search_document_events_due",
		"WHERE status IN ('pending', 'retry')",
	}
	for _, fragment := range required {
		if !strings.Contains(up, fragment) {
			t.Fatalf("migration missing %q", fragment)
		}
	}
}

func TestSearchQueryEventMigrationDefinesTelemetryContract(t *testing.T) {
	up := readMigration(t, "002_create_search_query_events.up.sql")

	required := []string{
		"CREATE TABLE IF NOT EXISTS search_query_events",
		"event_type TEXT NOT NULL",
		"search_session_id TEXT",
		"query_hash TEXT",
		"query_length INT NOT NULL",
		"user_id_hash TEXT",
		"scope TEXT",
		"domain TEXT",
		"entity_id TEXT",
		"result_position INT",
		"request_id TEXT",
		"metadata JSONB NOT NULL",
		"CREATE INDEX IF NOT EXISTS idx_search_query_events_type_created",
		"CREATE INDEX IF NOT EXISTS idx_search_query_events_session",
	}
	for _, fragment := range required {
		if !strings.Contains(up, fragment) {
			t.Fatalf("migration missing %q", fragment)
		}
	}
}

func TestSearchFailedEventMigrationDefinesDLQContract(t *testing.T) {
	up := readMigration(t, "003_create_search_failed_events.up.sql")

	required := []string{
		"CREATE TABLE IF NOT EXISTS search_failed_events",
		"document_event_id UUID NOT NULL",
		"source_service TEXT NOT NULL",
		"source_event_id TEXT NOT NULL",
		"aggregate_type TEXT NOT NULL",
		"aggregate_id TEXT NOT NULL",
		"event_type TEXT NOT NULL",
		"payload JSONB NOT NULL",
		"attempt_count INT NOT NULL",
		"last_error TEXT",
		"failed_at TIMESTAMPTZ NOT NULL",
		"CREATE UNIQUE INDEX IF NOT EXISTS idx_search_failed_events_document_event",
		"CREATE INDEX IF NOT EXISTS idx_search_failed_events_failed_at",
		"CREATE INDEX IF NOT EXISTS idx_search_failed_events_source",
	}
	for _, fragment := range required {
		if !strings.Contains(up, fragment) {
			t.Fatalf("migration missing %q", fragment)
		}
	}
}

func TestSearchOptimizationMigrationDefinesProductionIndexes(t *testing.T) {
	up := readMigration(t, "004_optimize_search_documents.up.sql")
	down := readMigration(t, "004_optimize_search_documents.down.sql")

	requiredUp := []string{
		"CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_search_documents_active_vector",
		"USING GIN (search_vector)",
		"WHERE deleted_at IS NULL",
		"visibility = 'public'",
		"moderation_status = 'approved'",
		"CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_search_documents_active_trgm",
		"gin_trgm_ops",
		"CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_search_documents_active_prefix",
		"text_pattern_ops",
		"CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_search_documents_active_domain_locale_scores",
		"popularity_score DESC",
		"freshness_score DESC",
		"trust_score DESC",
	}
	for _, fragment := range requiredUp {
		if !strings.Contains(up, fragment) {
			t.Fatalf("optimization migration missing %q", fragment)
		}
	}

	for _, fragment := range []string{
		"DROP INDEX CONCURRENTLY IF EXISTS idx_search_documents_active_vector",
		"DROP INDEX CONCURRENTLY IF EXISTS idx_search_documents_active_trgm",
		"DROP INDEX CONCURRENTLY IF EXISTS idx_search_documents_active_prefix",
		"DROP INDEX CONCURRENTLY IF EXISTS idx_search_documents_active_domain_locale_scores",
	} {
		if !strings.Contains(down, fragment) {
			t.Fatalf("optimization down migration missing %q", fragment)
		}
	}
}

func TestSearchCandidateSelectionMigrationDefinesKNNAndTrendingIndexes(t *testing.T) {
	up := readMigration(t, "005_optimize_search_candidate_selection.up.sql")
	down := readMigration(t, "005_optimize_search_candidate_selection.down.sql")

	requiredUp := []string{
		"CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_search_documents_active_trgm_gist",
		"USING GIST",
		"gist_trgm_ops(siglen=64)",
		"CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_search_documents_active_trending_score",
		"LEAST(GREATEST(popularity_score, 0), 1) * 0.15",
		"LEAST(GREATEST(freshness_score, 0), 1) * 0.10",
		"LEAST(GREATEST(trust_score, 0), 1) * 0.05",
		"CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_search_documents_active_domain_trending_score",
		"domain,",
		"updated_at DESC",
		"WHERE deleted_at IS NULL",
		"visibility = 'public'",
		"moderation_status = 'approved'",
	}
	for _, fragment := range requiredUp {
		if !strings.Contains(up, fragment) {
			t.Fatalf("candidate selection migration missing %q", fragment)
		}
	}

	for _, fragment := range []string{
		"DROP INDEX CONCURRENTLY IF EXISTS idx_search_documents_active_domain_trending_score",
		"DROP INDEX CONCURRENTLY IF EXISTS idx_search_documents_active_trending_score",
		"DROP INDEX CONCURRENTLY IF EXISTS idx_search_documents_active_trgm_gist",
	} {
		if !strings.Contains(down, fragment) {
			t.Fatalf("candidate selection down migration missing %q", fragment)
		}
	}
}

func TestHelpArticleSearchDomainMigrationExtendsDomainConstraint(t *testing.T) {
	up := readMigration(t, "006_add_help_article_search_domain.up.sql")
	down := readMigration(t, "006_add_help_article_search_domain.down.sql")

	for _, fragment := range []string{
		"DROP CONSTRAINT IF EXISTS search_documents_domain_check",
		"'help_article'",
		"VALIDATE CONSTRAINT search_documents_domain_check",
	} {
		if !strings.Contains(up, fragment) {
			t.Fatalf("help article domain migration missing %q", fragment)
		}
	}
	if strings.Contains(down, "'help_article'") && !strings.Contains(down, "DELETE FROM search_documents") {
		t.Fatalf("help article down migration must clean derived help documents before restoring constraint")
	}
}

func TestSearchRepositorySQLIncludesGeoBoostContract(t *testing.T) {
	source := readRepositorySource(t, "pg_search_repository.go")

	required := []string{
		"ST_Distance",
		"ST_SetSRID(ST_MakePoint",
		"d.geo_point IS NULL",
		"* 0.20",
	}
	for _, fragment := range required {
		if !strings.Contains(source, fragment) {
			t.Fatalf("repository search SQL missing %q", fragment)
		}
	}
}

func TestSearchRepositorySQLUsesBoundedCandidatePoolBeforeFinalRanking(t *testing.T) {
	source := readRepositorySource(t, "pg_search_repository.go")

	required := []string{
		"func (r *PGSearchRepository) searchTextStrong",
		"func (r *PGSearchRepository) searchTextWithFuzzy",
		"candidate_pool AS",
		"candidate_score",
		"LIMIT LEAST(GREATEST($8::int",
		"ranked AS",
		"FROM candidate_pool d",
		"ORDER BY score DESC, title ASC",
	}
	for _, fragment := range required {
		if !strings.Contains(source, fragment) {
			t.Fatalf("repository optimized search SQL missing %q", fragment)
		}
	}
	if strings.Contains(source, "ILIKE '%' || normalized.q || '%'") {
		t.Fatalf("repository optimized search SQL must avoid unbounded contains ILIKE")
	}
	if strings.Contains(source, "OR d.search_text_normalized % normalized.q") {
		t.Fatalf("repository optimized search SQL must not mix fuzzy trigram into the first candidate pool")
	}
}

func TestSearchRepositoryUsesFastTrendingAndKNNFuzzyFallback(t *testing.T) {
	source := readRepositorySource(t, "pg_search_repository.go")

	required := []string{
		"func (r *PGSearchRepository) searchTrending",
		"if strings.TrimSpace(query.Query) == \"\"",
		"return r.searchTrending(ctx, query, domains, locale, limit, offset, fetchLimit)",
		"ORDER BY trending_score DESC, updated_at DESC",
		"ORDER BY d.search_text_normalized <-> lower(trim($2::text))",
		"word_similarity(token.value, fuzzy.search_text_normalized) >= 0.45",
		"strict_word_similarity(token.value, fuzzy.search_text_normalized) >= 0.38",
		"word_similarity(normalized.q, d.search_text_normalized)",
		"func finalizeSearchPage",
	}
	for _, fragment := range required {
		if !strings.Contains(source, fragment) {
			t.Fatalf("repository optimized search SQL missing %q", fragment)
		}
	}
}

func TestSearchRepositorySkipsFuzzyForEmptyDomains(t *testing.T) {
	source := readRepositorySource(t, "pg_search_repository.go")

	required := []string{
		"if len(strongPage.Items) == 0",
		"hasActiveDocuments(ctx, domains)",
		"func (r *PGSearchRepository) hasActiveDocuments",
		"SELECT EXISTS",
		"LIMIT 1",
	}
	for _, fragment := range required {
		if !strings.Contains(source, fragment) {
			t.Fatalf("repository empty-domain fuzzy guard missing %q", fragment)
		}
	}
}

func TestSearchRepositorySQLMatchesAnyNormalizedQueryToken(t *testing.T) {
	source := readRepositorySource(t, "pg_search_repository.go")

	required := []string{
		"tokenQuery := searchTokenQuery(query.Query)",
		"websearch_to_tsquery('simple', $9)",
		"d.search_vector @@ websearch_to_tsquery('simple', $9)",
		"regexp_split_to_array(lower(trim($2::text)), '\\s+') AS tokens",
		"char_length(token.value) >= 2",
		"d.search_text_normalized LIKE token.value || '%'",
		"d.search_text_normalized LIKE '% ' || token.value || '%'",
	}
	for _, fragment := range required {
		if !strings.Contains(source, fragment) {
			t.Fatalf("repository search SQL missing %q", fragment)
		}
	}
	if strings.Contains(source, "websearch_to_tsquery('simple', normalized.token_query)") {
		t.Fatalf("repository search SQL should pass token query as a parameter so the FTS index remains usable")
	}
}

func TestSearchTokenQueryUsesORBetweenTokens(t *testing.T) {
	tests := []struct {
		name  string
		query string
		want  string
	}{
		{name: "single token", query: "чарын", want: "чарын"},
		{name: "transliterated tokens", query: "чарын charyn", want: "чарын OR charyn"},
		{name: "folds whitespace and case", query: "  Charyn   Canyon ", want: "charyn OR canyon"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := searchTokenQuery(tt.query); got != tt.want {
				t.Fatalf("searchTokenQuery(%q) = %q, want %q", tt.query, got, tt.want)
			}
		})
	}
}

func TestSearchRepositorySQLKeepsLegacyTokenExpansionRemoved(t *testing.T) {
	source := readRepositorySource(t, "pg_search_repository.go")

	removed := []string{
		"regexp_split_to_array(lower(trim($2::text)), '\\s+') AS tokens",
		"array_to_string(tokens, ' OR ')",
		"websearch_to_tsquery('simple', normalized.token_query)",
	}
	for _, fragment := range removed[1:] {
		if !strings.Contains(source, fragment) {
			continue
		}
		t.Fatalf("repository search SQL should not keep legacy token query fragment %q", fragment)
	}
}

func readMigration(t *testing.T, name string) string {
	t.Helper()

	path := filepath.Join("..", "..", "..", "migrations", name)
	data, err := os.ReadFile(path)
	if err != nil {
		t.Fatalf("read migration %s: %v", name, err)
	}
	return string(data)
}

func readRepositorySource(t *testing.T, name string) string {
	t.Helper()

	data, err := os.ReadFile(name)
	if err != nil {
		t.Fatalf("read repository source %s: %v", name, err)
	}
	return string(data)
}
