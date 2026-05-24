WITH seed_attraction_departure_city(attraction_id, country_code, city_id) AS (
    VALUES
        ('a9b79956-5545-4218-8646-2e619c5214d5'::uuid, 'KZ', 'almaty'),
        ('62d4f3a1-6821-4ad9-a7f8-e947a8475dca'::uuid, 'KZ', 'almaty'),
        ('9dca7991-e73e-4f92-92b7-41d30a6b8b49'::uuid, 'KZ', 'almaty'),
        ('40e5320e-32fa-4160-8211-da015eb5195b'::uuid, 'KZ', 'almaty'),
        ('39f691c1-91e4-4544-8e80-045ccc32f45e'::uuid, 'KZ', 'almaty'),
        ('a382cda5-4781-4840-8e56-a5237e35acd2'::uuid, 'KZ', 'almaty'),
        ('7763f114-9bed-4b3d-9d65-31fb78dfea29'::uuid, 'KZ', 'taldykorgan'),
        ('ffed49ce-ac1f-431b-8d9c-60d581956120'::uuid, 'KZ', 'almaty'),
        ('f5d59a14-b4f4-45a5-931b-48e88baeb313'::uuid, 'KZ', 'turkestan'),
        ('114d51df-f9ad-42c0-85a3-c22a7837d68e'::uuid, 'KZ', 'kokshetau'),
        ('c128bdff-bdd1-4eba-a9c4-47fcd17ce16f'::uuid, 'KZ', 'pavlodar'),
        ('2b8cf2b3-78e3-41af-92c6-5ac00b1536d4'::uuid, 'KZ', 'ust-kamenogorsk'),
        ('73ebd6ff-2960-4bee-b01b-7fd0704aaf45'::uuid, 'KZ', 'shymkent'),
        ('d58d55d5-f0f8-410f-9b62-f0accc1b8320'::uuid, 'KZ', 'astana'),
        ('f8bf4a72-9c35-4720-95bc-4b880f25f65c'::uuid, 'KZ', 'taldykorgan'),
        ('83423d6a-b4c8-49f6-a43a-11915345dd32'::uuid, 'KZ', 'balkhash'),
        ('9f15a751-3cee-4a54-8fef-5f2926db9917'::uuid, 'KZ', 'aktau'),
        ('dbdd707a-bc65-478e-86b1-1eb229000495'::uuid, 'KZ', 'astana'),
        ('e7016a75-1384-4bd7-a9bc-bd0e045fc7cf'::uuid, 'KZ', 'taraz'),
        ('9b28f1b9-8fe0-4b14-b8b8-f6e4cf441442'::uuid, 'KZ', 'zhezkazgan')
),
direct_landmarks AS (
    SELECT e.id, m.country_code, m.city_id
    FROM excursions e
    JOIN seed_attraction_departure_city m ON m.attraction_id = e.landmark_id
    WHERE e.deleted_at IS NULL
      AND e.departure_city_id IS NULL
),
first_itinerary_attractions AS (
    SELECT DISTINCT ON (i.excursion_id)
        i.excursion_id AS id,
        m.country_code,
        m.city_id
    FROM excursion_itinerary_items i
    JOIN seed_attraction_departure_city m ON m.attraction_id = i.attraction_id
    JOIN excursions e ON e.id = i.excursion_id
    WHERE e.deleted_at IS NULL
      AND e.departure_city_id IS NULL
    ORDER BY i.excursion_id, i.sort_order ASC, i.created_at ASC
),
candidates AS (
    SELECT * FROM direct_landmarks
    UNION
    SELECT * FROM first_itinerary_attractions
)
UPDATE excursions e
SET country_code = COALESCE(NULLIF(e.country_code, ''), c.country_code),
    departure_city_id = c.city_id,
    updated_at = NOW()
FROM candidates c
WHERE e.id = c.id
  AND e.departure_city_id IS NULL;
