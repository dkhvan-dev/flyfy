ALTER TABLE activities
    DROP CONSTRAINT IF EXISTS chk_activities_subcategory_slug_reference;

DROP INDEX IF EXISTS idx_activities_category_subcategory;

ALTER TABLE activities
    DROP COLUMN IF EXISTS subcategory_slug;
