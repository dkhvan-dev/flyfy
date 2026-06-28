ALTER TABLE help_article_surfaces
    DROP CONSTRAINT IF EXISTS help_article_surfaces_surface_check;

ALTER TABLE help_article_surfaces
    ADD CONSTRAINT help_article_surfaces_surface_check
    CHECK (
        surface IN (
            'help_center',
            'places',
            'activity_details',
            'excursion_details',
            'place_details',
            'currency_converter'
        )
    );

ALTER TABLE help_search_events
    DROP CONSTRAINT IF EXISTS help_search_events_surface_check;

ALTER TABLE help_search_events
    ADD CONSTRAINT help_search_events_surface_check
    CHECK (
        surface IN (
            'help_center',
            'places',
            'activity_details',
            'excursion_details',
            'place_details',
            'currency_converter'
        )
    );

INSERT INTO help_article_surfaces (article_id, surface)
SELECT 'place-ticket-info', 'places'
WHERE EXISTS (SELECT 1 FROM help_articles WHERE id = 'place-ticket-info')
ON CONFLICT DO NOTHING;
