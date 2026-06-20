CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE INDEX IF NOT EXISTS idx_moderation_cases_excursion_city
    ON moderation_cases (
        LOWER(COALESCE(snapshot->>'DepartureCityID', '')),
        LOWER(COALESCE(snapshot->>'CityName', ''))
    )
    WHERE target_type = 'EXCURSION';

CREATE INDEX IF NOT EXISTS idx_moderation_cases_excursion_reasons
    ON moderation_cases
    USING GIN ((COALESCE(snapshot->'ModerationReasonCodes', '[]'::jsonb)))
    WHERE target_type = 'EXCURSION';

CREATE INDEX IF NOT EXISTS idx_moderation_cases_excursion_risk
    ON moderation_cases (
        (CASE WHEN jsonb_typeof(snapshot->'PublishRiskScore') = 'number'
              THEN (snapshot->>'PublishRiskScore')::int
              ELSE 0
         END) DESC,
        priority DESC,
        opened_at ASC
    )
    WHERE target_type = 'EXCURSION';

CREATE INDEX IF NOT EXISTS idx_moderation_cases_excursion_search_trgm
    ON moderation_cases
    USING GIN (
        (LOWER(
            COALESCE(snapshot->>'Title', '') || ' ' ||
            COALESCE(snapshot->>'Summary', '') || ' ' ||
            COALESCE(snapshot->>'Description', '') || ' ' ||
            COALESCE(snapshot->>'LandmarkName', '') || ' ' ||
            COALESCE(snapshot->>'ProductTranslations', '') || ' ' ||
            COALESCE(snapshot->>'Translations', '') || ' ' ||
            COALESCE(snapshot->>'PlaceNames', '') || ' ' ||
            COALESCE(snapshot->>'PlaceNamesByLocale', '') || ' ' ||
            COALESCE(snapshot->>'GuideDisplayName', '') || ' ' ||
            COALESCE(snapshot->>'GuideNickname', '') || ' ' ||
            COALESCE(snapshot->>'GuideFirstName', '') || ' ' ||
            COALESCE(snapshot->>'GuideLastName', '')
        )) gin_trgm_ops
    )
    WHERE target_type = 'EXCURSION';
