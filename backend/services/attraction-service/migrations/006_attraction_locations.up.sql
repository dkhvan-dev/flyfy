-- First-class attraction coordinates used by mobile map deep links.
-- Sources audited in May 2026:
-- - OpenStreetMap/Nominatim for mapped objects and practical map points.
-- - Wikidata coordinate statements for places where OSM search is ambiguous.
-- For very large protected areas, coordinates point to the mapped area centroid
-- or a representative public visitor point, not an exact entrance checkpoint.

ALTER TABLE attractions
    ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION NULL,
    ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION NULL,
    ADD COLUMN IF NOT EXISTS location_source_url TEXT NOT NULL DEFAULT '';

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_attractions_location_pair'
    ) THEN
        ALTER TABLE attractions
            ADD CONSTRAINT chk_attractions_location_pair CHECK (
                (latitude IS NULL AND longitude IS NULL)
                OR (latitude IS NOT NULL AND longitude IS NOT NULL)
            );
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_attractions_latitude'
    ) THEN
        ALTER TABLE attractions
            ADD CONSTRAINT chk_attractions_latitude CHECK (
                latitude IS NULL OR (latitude >= -90 AND latitude <= 90)
            );
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_attractions_longitude'
    ) THEN
        ALTER TABLE attractions
            ADD CONSTRAINT chk_attractions_longitude CHECK (
                longitude IS NULL OR (longitude >= -180 AND longitude <= 180)
            );
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_attractions_location_source_url'
    ) THEN
        ALTER TABLE attractions
            ADD CONSTRAINT chk_attractions_location_source_url CHECK (
                location_source_url = '' OR location_source_url ~ '^https://'
            );
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_attractions_location
    ON attractions (latitude, longitude)
    WHERE deleted_at IS NULL AND latitude IS NOT NULL AND longitude IS NOT NULL;

WITH seed_locations (
    id,
    latitude,
    longitude,
    location_source_url
) AS (
    VALUES
        ('a9b79956-5545-4218-8646-2e619c5214d5'::uuid, 43.3249952, 79.0585755, 'https://www.openstreetmap.org/way/22722438'),
        ('62d4f3a1-6821-4ad9-a7f8-e947a8475dca'::uuid, 42.9525000, 78.3100000, 'https://www.wikidata.org/wiki/Q4228941'),
        ('9dca7991-e73e-4f92-92b7-41d30a6b8b49'::uuid, 42.9845567, 78.4659855, 'https://www.openstreetmap.org/way/60961015'),
        ('40e5320e-32fa-4160-8211-da015eb5195b'::uuid, 43.0510347, 76.9853932, 'https://www.openstreetmap.org/relation/3427772'),
        ('39f691c1-91e4-4544-8e80-045ccc32f45e'::uuid, 43.1571772, 77.0594144, 'https://www.openstreetmap.org/way/171504564'),
        ('a382cda5-4781-4840-8e56-a5237e35acd2'::uuid, 43.1284757, 77.0813878, 'https://www.openstreetmap.org/way/171508693'),
        ('7763f114-9bed-4b3d-9d65-31fb78dfea29'::uuid, 44.1298726, 78.8505676, 'https://www.openstreetmap.org/relation/5935486'),
        ('ffed49ce-ac1f-431b-8d9c-60d581956120'::uuid, 43.8044035, 75.5356085, 'https://www.openstreetmap.org/node/5725790616'),
        ('f5d59a14-b4f4-45a5-931b-48e88baeb313'::uuid, 43.2977090, 68.2709559, 'https://www.openstreetmap.org/way/117854803'),
        ('114d51df-f9ad-42c0-85a3-c22a7837d68e'::uuid, 53.0062905, 70.4262174, 'https://www.openstreetmap.org/way/978784431'),
        ('c128bdff-bdd1-4eba-a9c4-47fcd17ce16f'::uuid, 50.7833952, 75.4654673, 'https://www.openstreetmap.org/relation/6311971'),
        ('2b8cf2b3-78e3-41af-92c6-5ac00b1536d4'::uuid, 49.3590172, 86.6746937, 'https://www.openstreetmap.org/relation/13158691'),
        ('73ebd6ff-2960-4bee-b01b-7fd0704aaf45'::uuid, 42.3075315, 70.6345960, 'https://www.openstreetmap.org/relation/3388788'),
        ('d58d55d5-f0f8-410f-9b62-f0accc1b8320'::uuid, 50.4252609, 68.8978389, 'https://www.openstreetmap.org/relation/6056653'),
        ('f8bf4a72-9c35-4720-95bc-4b880f25f65c'::uuid, 46.1202778, 81.7277778, 'https://www.wikidata.org/wiki/Q310547'),
        ('83423d6a-b4c8-49f6-a43a-11915345dd32'::uuid, 45.9266064, 73.9370132, 'https://www.openstreetmap.org/relation/19025268'),
        ('9f15a751-3cee-4a54-8fef-5f2926db9917'::uuid, 43.4045686, 54.0770414, 'https://www.openstreetmap.org/node/4282143923'),
        ('dbdd707a-bc65-478e-86b1-1eb229000495'::uuid, 51.1282779, 71.4305150, 'https://www.openstreetmap.org/way/230401645'),
        ('e7016a75-1384-4bd7-a9bc-bd0e045fc7cf'::uuid, 42.8994920, 71.3861686, 'https://www.openstreetmap.org/node/5174108322'),
        ('9b28f1b9-8fe0-4b14-b8b8-f6e4cf441442'::uuid, 48.1553430, 67.8173395, 'https://www.openstreetmap.org/way/569293898')
)
UPDATE attractions
SET
    latitude = seed_locations.latitude,
    longitude = seed_locations.longitude,
    location_source_url = seed_locations.location_source_url,
    updated_at = NOW()
FROM seed_locations
WHERE attractions.id = seed_locations.id
    AND attractions.source = 'IMPORT';
