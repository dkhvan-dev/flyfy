CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_search_documents_active_vector
    ON search_documents USING GIN (search_vector)
    WHERE deleted_at IS NULL
      AND visibility = 'public'
      AND moderation_status = 'approved';

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_search_documents_active_trgm
    ON search_documents USING GIN (search_text_normalized gin_trgm_ops)
    WHERE deleted_at IS NULL
      AND visibility = 'public'
      AND moderation_status = 'approved';

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_search_documents_active_prefix
    ON search_documents (search_text_normalized text_pattern_ops)
    WHERE deleted_at IS NULL
      AND visibility = 'public'
      AND moderation_status = 'approved';

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_search_documents_active_domain_locale_scores
    ON search_documents (
        domain,
        locale,
        popularity_score DESC,
        freshness_score DESC,
        trust_score DESC,
        updated_at DESC
    )
    WHERE deleted_at IS NULL
      AND visibility = 'public'
      AND moderation_status = 'approved';

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_search_documents_active_geo
    ON search_documents USING GIST (geo_point)
    WHERE deleted_at IS NULL
      AND visibility = 'public'
      AND moderation_status = 'approved'
      AND geo_point IS NOT NULL;
