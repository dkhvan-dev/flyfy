UPDATE places
SET
    category = CASE id
        WHEN 'ce5ca032-073b-4e4a-93d9-825a4e495574'::uuid THEN 'FOOD'
        WHEN 'bc934181-e9d9-4daa-9909-5f87a3169159'::uuid THEN 'SHOPPING'
        WHEN '8b507042-be77-4e72-a530-78a6ccbf8979'::uuid THEN 'FOOD'
        WHEN 'b0f6561c-68a2-4dad-ae5a-80ae3edfc53c'::uuid THEN 'FOOD'
        WHEN '072f60d2-ef0d-4eae-aa77-51ff1eee274f'::uuid THEN 'SHOPPING'
        WHEN '58b1ccbc-6671-4112-a6b4-551767360a11'::uuid THEN 'SHOPPING'
        WHEN 'aa81bb79-cabb-477a-ac05-45b863d6df8e'::uuid THEN 'FOOD'
        WHEN '262204b6-09c5-4914-85cf-06a878cd8668'::uuid THEN 'FOOD'
        WHEN 'b789d8ae-3f3f-41e3-88b2-e553cd978947'::uuid THEN 'SHOPPING'
        WHEN '0425d348-b915-4c47-9dfe-a3edb8186be5'::uuid THEN 'SHOPPING'
        WHEN '587038b0-d882-4220-b65e-005b54d99344'::uuid THEN 'SHOPPING'
        WHEN '8302674f-7fbc-4f13-8ce1-9c46a08e311e'::uuid THEN 'SHOPPING'
        WHEN '9becd171-75b3-4488-b2bb-a8256d3ef7dc'::uuid THEN 'SHOPPING'
        WHEN '627c04c6-16f7-4a8d-abc9-189a32d7b656'::uuid THEN 'SHOPPING'
        ELSE category
    END,
    updated_at = NOW()
WHERE source = 'IMPORT'
    AND id IN (
        'ce5ca032-073b-4e4a-93d9-825a4e495574',
        'bc934181-e9d9-4daa-9909-5f87a3169159',
        '8b507042-be77-4e72-a530-78a6ccbf8979',
        'b0f6561c-68a2-4dad-ae5a-80ae3edfc53c',
        '072f60d2-ef0d-4eae-aa77-51ff1eee274f',
        '58b1ccbc-6671-4112-a6b4-551767360a11',
        'aa81bb79-cabb-477a-ac05-45b863d6df8e',
        '262204b6-09c5-4914-85cf-06a878cd8668',
        'b789d8ae-3f3f-41e3-88b2-e553cd978947',
        '0425d348-b915-4c47-9dfe-a3edb8186be5',
        '587038b0-d882-4220-b65e-005b54d99344',
        '8302674f-7fbc-4f13-8ce1-9c46a08e311e',
        '9becd171-75b3-4488-b2bb-a8256d3ef7dc',
        '627c04c6-16f7-4a8d-abc9-189a32d7b656'
    );

UPDATE places
SET
    category = 'SHOPPING',
    updated_at = NOW()
WHERE category = 'MARKET';

ALTER TABLE places
    DROP CONSTRAINT IF EXISTS chk_places_category;

ALTER TABLE places
    ADD CONSTRAINT chk_places_category CHECK (category IN (
        'NATURE', 'ARCHITECTURE', 'MUSEUM', 'BEACH', 'PARK',
        'TEMPLE', 'ENTERTAINMENT', 'FOOD', 'SHOPPING', 'OTHER'
    ));
