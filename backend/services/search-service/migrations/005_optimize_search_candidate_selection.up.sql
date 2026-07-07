CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_search_documents_active_trgm_gist
    ON search_documents USING GIST (search_text_normalized gist_trgm_ops(siglen=64))
    WHERE deleted_at IS NULL
      AND visibility = 'public'
      AND moderation_status = 'approved';

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_search_documents_active_trending_score
    ON search_documents (
        (
            LEAST(GREATEST(popularity_score, 0), 1) * 0.15
            + LEAST(GREATEST(freshness_score, 0), 1) * 0.10
            + LEAST(GREATEST(trust_score, 0), 1) * 0.05
        ) DESC,
        updated_at DESC
    )
    WHERE deleted_at IS NULL
      AND visibility = 'public'
      AND moderation_status = 'approved';

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_search_documents_active_domain_trending_score
    ON search_documents (
        domain,
        (
            LEAST(GREATEST(popularity_score, 0), 1) * 0.15
            + LEAST(GREATEST(freshness_score, 0), 1) * 0.10
            + LEAST(GREATEST(trust_score, 0), 1) * 0.05
        ) DESC,
        updated_at DESC
    )
    WHERE deleted_at IS NULL
      AND visibility = 'public'
      AND moderation_status = 'approved';
