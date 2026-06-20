DELETE FROM place_media
WHERE id IN (
    '48000000-0000-4000-8000-000000000001',
    '48000000-0000-4000-8000-000000000002',
    '48000000-0000-4000-8000-000000000003',
    '48000000-0000-4000-8000-000000000004',
    '48000000-0000-4000-8000-000000000005',
    '48000000-0000-4000-8000-000000000006',
    '48000000-0000-4000-8000-000000000007',
    '48000000-0000-4000-8000-000000000008',
    '48000000-0000-4000-8000-000000000009',
    '48000000-0000-4000-8000-000000000010',
    '48000000-0000-4000-8000-000000000011',
    '48000000-0000-4000-8000-000000000012',
    '48000000-0000-4000-8000-000000000013'
);

DELETE FROM places
WHERE id IN (
    'b789d8ae-3f3f-41e3-88b2-e553cd978947',
    '4257b4a9-5a58-4c6b-b0a6-70e5d5307618',
    '24dced8d-8032-477f-abf6-9816d08701bc',
    '0425d348-b915-4c47-9dfe-a3edb8186be5',
    '07040179-73c0-400c-867a-9c97d70bc818',
    'cc3df3f7-e3c4-43c9-855e-9c98957d6f8d',
    '2065e87e-6cd2-4146-9d5b-64b67d8d39fb',
    'a708528c-04c0-452f-ba7f-0729f576aa52',
    'aca1444b-ef1c-4795-8c6f-a454b285567c',
    'b1d53f6d-bfa4-4a3e-8c32-7e46a0c76c08',
    'd2a9f71a-f62c-4b94-b862-8f61955100e3',
    'c78fd68a-17e6-486a-9ac4-c2923a76127b',
    '0b67cda1-5fe1-45e0-94a3-89a2ad43efbf'
)
AND source = 'IMPORT';

WITH rollback_po_nagar_translations (
    place_id,
    locale,
    title,
    description
) AS (
    VALUES
        ('fdedb547-0ae0-4fe8-a413-dec8f9d9f154'::uuid, 'ru', 'Башни По Нагар', 'Чамский храмовый комплекс рядом с Нячангом, посвященный богине Ян По Нагар. Компактная культурная остановка с краснокирпичными башнями, видом на реку и контекстом древней Чампы.'),
        ('fdedb547-0ae0-4fe8-a413-dec8f9d9f154'::uuid, 'en', 'Po Nagar Cham Towers', 'A Cham temple complex near Nha Trang dedicated to the goddess Yan Po Nagar. It is a compact cultural stop with red-brick towers, river views and context around ancient Champa.'),
        ('fdedb547-0ae0-4fe8-a413-dec8f9d9f154'::uuid, 'kk', 'По Нагар Чам мұнаралары', 'Нячанг маңындағы Ян По Нагар құдайына арналған Чам храм кешені. Қызыл кірпіш мұнаралары, өзен көрінісі және ежелгі Чампа туралы контексті бар ықшам мәдени аялдама.')
)
INSERT INTO place_translations (
    place_id,
    locale,
    title,
    description,
    created_at,
    updated_at
)
SELECT
    rollback_po_nagar_translations.place_id,
    rollback_po_nagar_translations.locale,
    rollback_po_nagar_translations.title,
    rollback_po_nagar_translations.description,
    NOW(),
    NOW()
FROM rollback_po_nagar_translations
WHERE EXISTS (
    SELECT 1
    FROM places a
    WHERE a.id = rollback_po_nagar_translations.place_id
        AND a.source = 'IMPORT'
)
ON CONFLICT (place_id, locale) DO UPDATE
SET
    title = EXCLUDED.title,
    description = EXCLUDED.description,
    updated_at = NOW();
