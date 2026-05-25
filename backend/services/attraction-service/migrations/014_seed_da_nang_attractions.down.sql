DELETE FROM attraction_media
WHERE id IN (
    '46000000-0000-4000-8000-000000000001',
    '46000000-0000-4000-8000-000000000002',
    '46000000-0000-4000-8000-000000000003',
    '46000000-0000-4000-8000-000000000004',
    '46000000-0000-4000-8000-000000000005',
    '46000000-0000-4000-8000-000000000006',
    '46000000-0000-4000-8000-000000000007',
    '46000000-0000-4000-8000-000000000008',
    '46000000-0000-4000-8000-000000000009',
    '46000000-0000-4000-8000-000000000010',
    '46000000-0000-4000-8000-000000000011',
    '46000000-0000-4000-8000-000000000012',
    '46000000-0000-4000-8000-000000000013'
);

DELETE FROM attractions
WHERE id IN (
    'c6e51c2f-97dc-4990-8795-a083ee0b265c',
    '3cb82c60-2819-422b-997e-93fb23bfe6ce',
    '03db0318-9e27-4262-bdb3-1f7204998d3a',
    '9346a24c-4be7-4e7c-95bc-b232b19c8b8c',
    'c4d8a4a5-6a97-4aa6-8855-fc538c75c870',
    '5841aaeb-c597-4b89-992d-26a844dd2054',
    'df554637-6f18-49c8-b4b2-8fcedd82962b',
    'c64903fe-b7ab-4812-9124-8ca7d67a2bfb',
    'c9860c73-dfb2-41b2-87f4-01f92f8f3fb0',
    '072f60d2-ef0d-4eae-aa77-51ff1eee274f',
    '58b1ccbc-6671-4112-a6b4-551767360a11',
    'aa81bb79-cabb-477a-ac05-45b863d6df8e',
    '262204b6-09c5-4914-85cf-06a878cd8668'
)
AND source = 'IMPORT';

WITH rollback_translations (
    attraction_id,
    locale,
    title,
    description
) AS (
    VALUES
        ('0d3d4f26-f5e0-4f82-a7a8-850046edae00'::uuid, 'ru', 'Золотой мост', 'Пешеходный мост в Ba Na Hills рядом с Данангом, известный гигантскими каменными руками и видами на горы. Это фотогеничная точка для поездки в парк на высоте, особенно при ясной погоде.'),
        ('0d3d4f26-f5e0-4f82-a7a8-850046edae00'::uuid, 'en', 'Golden Bridge', 'A pedestrian bridge in Ba Na Hills near Da Nang, known for giant stone hands and mountain views. It is a photogenic stop inside the highland park, especially in clear weather.'),
        ('0d3d4f26-f5e0-4f82-a7a8-850046edae00'::uuid, 'kk', 'Алтын көпір', 'Дананг маңындағы Ba Na Hills аймағындағы алып тас қолдарымен және тау көріністерімен белгілі жаяу жүргінші көпірі. Ашық ауа райында биіктегі парк ішіндегі өте фотогенді аялдама.')
)
INSERT INTO attraction_translations (
    attraction_id,
    locale,
    title,
    description,
    created_at,
    updated_at
)
SELECT
    rollback_translations.attraction_id,
    rollback_translations.locale,
    rollback_translations.title,
    rollback_translations.description,
    NOW(),
    NOW()
FROM rollback_translations
WHERE EXISTS (
    SELECT 1
    FROM attractions a
    WHERE a.id = rollback_translations.attraction_id
        AND a.source = 'IMPORT'
)
ON CONFLICT (attraction_id, locale) DO UPDATE
SET
    title = EXCLUDED.title,
    description = EXCLUDED.description,
    updated_at = NOW();
