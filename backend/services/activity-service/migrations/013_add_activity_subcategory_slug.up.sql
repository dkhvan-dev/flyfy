ALTER TABLE activities
    ADD COLUMN subcategory_slug VARCHAR(100) NULL;

UPDATE activities
SET category_slug = 'nature-outdoor'
WHERE category_slug = 'adventure-sports';

UPDATE activities
SET category_slug = 'sports-wellness'
WHERE category_slug = 'health-wellness';

CREATE INDEX idx_activities_category_subcategory
    ON activities(category_slug, subcategory_slug);

ALTER TABLE activities
    ADD CONSTRAINT chk_activities_subcategory_slug_reference
        CHECK (subcategory_slug IS NULL OR subcategory_slug ~ '^[a-z0-9][a-z0-9-]{0,99}$');
