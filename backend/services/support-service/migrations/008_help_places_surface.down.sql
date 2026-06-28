DELETE FROM help_search_events
WHERE surface = 'places';

DELETE FROM help_article_surfaces
WHERE surface = 'places';

ALTER TABLE help_article_surfaces
    DROP CONSTRAINT IF EXISTS help_article_surfaces_surface_check;

ALTER TABLE help_article_surfaces
    ADD CONSTRAINT help_article_surfaces_surface_check
    CHECK (
        surface IN (
            'help_center',
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
            'activity_details',
            'excursion_details',
            'place_details',
            'currency_converter'
        )
    );
