ALTER TABLE place_media
    ADD COLUMN IF NOT EXISTS external_url TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS source_url TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS credit TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS license TEXT NOT NULL DEFAULT '';

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'chk_place_media_external_url'
    ) THEN
        ALTER TABLE place_media
            ADD CONSTRAINT chk_place_media_external_url
            CHECK (external_url = '' OR external_url ~ '^https://');
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'chk_place_media_source_url'
    ) THEN
        ALTER TABLE place_media
            ADD CONSTRAINT chk_place_media_source_url
            CHECK (source_url = '' OR source_url ~ '^https://');
    END IF;
END $$;

-- Curated seed media from Wikimedia Commons. `source_url` is the canonical
-- file page for attribution and license verification; `external_url` resolves
-- through Special:FilePath to the current file rendition.
WITH curated_media (
    id,
    place_id,
    file_name
) AS (
    VALUES
        ('10000000-0000-4000-8000-000000000001'::uuid, 'a9b79956-5545-4218-8646-2e619c5214d5'::uuid, 'Charyn Canyon, Kazakhstan 01.jpg'),
        ('10000000-0000-4000-8000-000000000002'::uuid, '62d4f3a1-6821-4ad9-a7f8-e947a8475dca'::uuid, 'Kolsai lake.jpg'),
        ('10000000-0000-4000-8000-000000000003'::uuid, '9dca7991-e73e-4f92-92b7-41d30a6b8b49'::uuid, 'Kaindy lake.jpg'),
        ('10000000-0000-4000-8000-000000000004'::uuid, '40e5320e-32fa-4160-8211-da015eb5195b'::uuid, 'Big Almaty Lake 2014.jpg'),
        ('10000000-0000-4000-8000-000000000005'::uuid, '39f691c1-91e4-4544-8e80-045ccc32f45e'::uuid, 'AlmaAtaMedeu.jpg'),
        ('10000000-0000-4000-8000-000000000006'::uuid, 'a382cda5-4781-4840-8e56-a5237e35acd2'::uuid, 'Shymbulak, Almaty (P1180189).jpg'),
        ('10000000-0000-4000-8000-000000000007'::uuid, '7763f114-9bed-4b3d-9d65-31fb78dfea29'::uuid, 'Altyn Emel 1.jpg'),
        ('10000000-0000-4000-8000-000000000008'::uuid, 'ffed49ce-ac1f-431b-8d9c-60d581956120'::uuid, 'Petroglyphs in Tamgaly, Kazakhstan 01.jpg'),
        ('10000000-0000-4000-8000-000000000009'::uuid, 'f5d59a14-b4f4-45a5-931b-48e88baeb313'::uuid, 'Mausoleum of Khoja Ahmed Yasawi in Turkistan 3.jpg'),
        ('10000000-0000-4000-8000-000000000010'::uuid, '114d51df-f9ad-42c0-85a3-c22a7837d68e'::uuid, 'Borovoe1.jpg'),
        ('10000000-0000-4000-8000-000000000011'::uuid, 'c128bdff-bdd1-4eba-a9c4-47fcd17ce16f'::uuid, 'Bayanaul National Park.jpg'),
        ('10000000-0000-4000-8000-000000000012'::uuid, '2b8cf2b3-78e3-41af-92c6-5ac00b1536d4'::uuid, 'Beautiful view of the mountains (Katon-Karagay).jpg'),
        ('10000000-0000-4000-8000-000000000013'::uuid, '73ebd6ff-2960-4bee-b01b-7fd0704aaf45'::uuid, 'Aksu-Zhabagly Nature Reserve.jpg'),
        ('10000000-0000-4000-8000-000000000014'::uuid, 'd58d55d5-f0f8-410f-9b62-f0accc1b8320'::uuid, 'Sunset in Korgalzhyn Nature Reserve.jpg'),
        ('10000000-0000-4000-8000-000000000015'::uuid, 'f8bf4a72-9c35-4720-95bc-4b880f25f65c'::uuid, 'Alakol District, Kazakhstan - panoramio (3).jpg'),
        ('10000000-0000-4000-8000-000000000016'::uuid, '83423d6a-b4c8-49f6-a43a-11915345dd32'::uuid, 'Balkhash lake, september 2020.jpg'),
        ('10000000-0000-4000-8000-000000000017'::uuid, '9f15a751-3cee-4a54-8fef-5f2926db9917'::uuid, 'Bozzhyra valley, Mangistau region, Kazakhstan.jpg'),
        ('10000000-0000-4000-8000-000000000018'::uuid, 'dbdd707a-bc65-478e-86b1-1eb229000495'::uuid, 'Baiterek.jpg'),
        ('10000000-0000-4000-8000-000000000019'::uuid, 'e7016a75-1384-4bd7-a9bc-bd0e045fc7cf'::uuid, 'Model of Ancient Taraz (5611934896).jpg'),
        ('10000000-0000-4000-8000-000000000020'::uuid, '9b28f1b9-8fe0-4b14-b8b8-f6e4cf441442'::uuid, 'Dzhuchi khan mausoleum.jpg')
)
INSERT INTO place_media (
    id,
    place_id,
    file_id,
    external_url,
    source_url,
    credit,
    license,
    media_type,
    position,
    created_at
)
SELECT
    curated_media.id,
    curated_media.place_id,
    '00000000-0000-0000-0000-000000000000'::uuid,
    'https://commons.wikimedia.org/wiki/Special:FilePath/' || replace(curated_media.file_name, ' ', '%20') || '?width=1400',
    'https://commons.wikimedia.org/wiki/File:' || replace(curated_media.file_name, ' ', '_'),
    'Wikimedia Commons contributors',
    'See Wikimedia Commons source page',
    'PHOTO',
    0,
    NOW()
FROM curated_media
WHERE EXISTS (
    SELECT 1
    FROM places a
    WHERE a.id = curated_media.place_id
)
ON CONFLICT (id) DO UPDATE
SET
    place_id = EXCLUDED.place_id,
    file_id = EXCLUDED.file_id,
    external_url = EXCLUDED.external_url,
    source_url = EXCLUDED.source_url,
    credit = EXCLUDED.credit,
    license = EXCLUDED.license,
    media_type = EXCLUDED.media_type,
    position = EXCLUDED.position;
