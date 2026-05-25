-- Curated cover media for the in-city Kazakhstan attractions from migration 009.
-- `external_url` is a temporary import source for cmd/backfill-media-minio only:
-- runtime clients must use the mirrored MinIO/file-manager `file_id`, and the
-- backfill command clears `external_url` after a successful upload.
-- Wikimedia Commons rows keep canonical file pages for license verification.
-- Exact third-party tourism pages are used only where Commons has no strong,
-- representative image for the specific city attraction.

WITH curated_media (
    id,
    attraction_id,
    external_url,
    source_url,
    credit,
    license
) AS (
    VALUES
        ('11000000-0000-4000-8000-000000000001'::uuid, '2eeacb52-12ef-4499-b229-05e52a199d22'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/View%20of%20Kok-Tobe%20amusement%20part%20and%20Almaty%20T.V%20Tower..JPG?width=1400', 'https://commons.wikimedia.org/wiki/File:View_of_Kok-Tobe_amusement_part_and_Almaty_T.V_Tower..JPG', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('11000000-0000-4000-8000-000000000002'::uuid, '6acdc04c-67b9-4e86-a43f-160738c3dda3'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/Ascension%20Cathedral,%20Almaty%20(LRM%2020240402%20221113-RR).jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:Ascension_Cathedral,_Almaty_(LRM_20240402_221113-RR).jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('11000000-0000-4000-8000-000000000003'::uuid, '3c070f18-a92c-4d5c-868c-dd4bda71ce95'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/Central%20Park%20Almaty.jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:Central_Park_Almaty.jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('11000000-0000-4000-8000-000000000004'::uuid, '396f6629-a240-4845-8a5d-2fa33fc42b1b'::uuid, 'https://wildticketasia.com/uploads/posts/2025-10/1760629421_park-fantasy-world-almaty-01.jpg', 'https://wildticketasia.com/2047-fantasy-world-almaty.html', 'WildTicket Asia', 'See source page terms'),
        ('11000000-0000-4000-8000-000000000005'::uuid, '8a7b975e-9a4e-434e-a7e2-d721c41bda93'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/Giraffe.%20Almaty%20zoo.JPG?width=1400', 'https://commons.wikimedia.org/wiki/File:Giraffe._Almaty_zoo.JPG', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('11000000-0000-4000-8000-000000000006'::uuid, 'ce5ca032-073b-4e4a-93d9-825a4e495574'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/2008%20Green%20bazaar%20Almaty%20nuts%202472773966.jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:2008_Green_bazaar_Almaty_nuts_2472773966.jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('11000000-0000-4000-8000-000000000007'::uuid, 'bc934181-e9d9-4daa-9909-5f87a3169159'::uuid, 'https://static.wixstatic.com/media/43eb5b_29d2048291c94be98c5c40cfb3c39731%7Emv2.jpg/v1/fit/w_2500,h_1330,al_c/43eb5b_29d2048291c94be98c5c40cfb3c39731%7Emv2.jpg', 'https://www.walkingalmaty.com/barakholka-market-tour', 'Walking Almaty', 'See source page terms'),
        ('11000000-0000-4000-8000-000000000008'::uuid, '33192bba-1776-48e6-918b-198e81b17eae'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/Japanese%20Garden%20in%20the%20Park%20of%20the%20First%20President%20in%20Almaty.jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:Japanese_Garden_in_the_Park_of_the_First_President_in_Almaty.jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('11000000-0000-4000-8000-000000000009'::uuid, '39759c2a-e2f1-4f2f-b354-d5c29f40fcc9'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/Khan%20Shatyr%20shopping%20center.jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:Khan_Shatyr_shopping_center.jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('11000000-0000-4000-8000-000000000010'::uuid, 'abede8f2-87db-4f12-bc3e-64e815a1f97e'::uuid, 'https://kz-admin.yers.dev/uploads/astana_expo_nuralem_6abed4be9d.jpg', 'https://qaztravel.kz/en/tourist-spots/nur-alem-museum-of-future-energy', 'QazTravel', 'See source page terms'),
        ('11000000-0000-4000-8000-000000000011'::uuid, 'a752e044-c458-4926-bdd1-76638b74b1c1'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/Botanical%20garden,%20Astana%20(P1190700).jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:Botanical_garden,_Astana_(P1190700).jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('11000000-0000-4000-8000-000000000012'::uuid, '1ede5116-b919-493e-9c58-b0027eb5f93b'::uuid, 'https://kz-admin.yers.dev/uploads/Hazret_sultan_6e4a8a9f37.jpg', 'https://qaztravel.kz/en/tourist-spots/hazrat-sultan-mosque', 'QazTravel', 'See source page terms'),
        ('11000000-0000-4000-8000-000000000013'::uuid, '12e77265-9e9d-4d11-9c6d-acb8aac48f4b'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/National%20Museum%20of%20Kazakhstan%2004.jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:National_Museum_of_Kazakhstan_04.jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('11000000-0000-4000-8000-000000000014'::uuid, 'adece1ed-0d63-48e5-b54e-d49cad52a391'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/Astana%20Opera%2002.jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:Astana_Opera_02.jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('11000000-0000-4000-8000-000000000015'::uuid, '9ed105cc-3f78-437a-ad1b-137422f3c8e6'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/Citadel-Shymkent-Kazakhstan.jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:Citadel-Shymkent-Kazakhstan.jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('11000000-0000-4000-8000-000000000016'::uuid, '92f6c2cc-1b44-4900-a764-c1daab90024d'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/Africa-Section-of-Zoo-Shymkent.jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:Africa-Section-of-Zoo-Shymkent.jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('11000000-0000-4000-8000-000000000017'::uuid, 'd3951503-5e02-41ec-b886-dfc7cce1f925'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/Dendropark%20Shymkent.jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:Dendropark_Shymkent.jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('11000000-0000-4000-8000-000000000018'::uuid, 'f1bfab8a-c217-4fe3-b4ba-c65c3fea9a9e'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/Abay%20park%2001.jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:Abay_park_01.jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('11000000-0000-4000-8000-000000000019'::uuid, '0e06eed4-e871-4f78-919c-a11322eda453'::uuid, 'https://www.shymkent.info/wp-content/uploads/2020/02/IMG_20191029_173040-01-scaled.jpeg', 'https://www.shymkent.info/about-shymkent/sights-in-shymkent/', 'Info Shymkent', 'See source page terms'),
        ('11000000-0000-4000-8000-000000000020'::uuid, 'b8847588-a922-42cf-94a2-ffcbf043922a'::uuid, 'https://kz-admin.yers.dev/uploads/Whats_App_Image_b4879e71b8.jpeg', 'https://qaztravel.kz/en/tourist-spots/karavansaray-tourist-complex', 'QazTravel', 'See source page terms'),
        ('11000000-0000-4000-8000-000000000021'::uuid, '788b2836-0bbb-40bc-8a14-9548f47979ab'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/Mausoleum%20of%20Khoja%20Ahmed%20Yasawi%20in%20Turkistan%203.jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:Mausoleum_of_Khoja_Ahmed_Yasawi_in_Turkistan_3.jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('11000000-0000-4000-8000-000000000022'::uuid, '877a0a46-da12-4f4c-be9c-a12a2032f93a'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/Otrar-aerial-view-May-2016-2.jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:Otrar-aerial-view-May-2016-2.jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('11000000-0000-4000-8000-000000000023'::uuid, '1d3163c5-fa93-484f-b917-f721a8f1ae27'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/Karlag-museum1.jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:Karlag-museum1.jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('11000000-0000-4000-8000-000000000024'::uuid, '09cdcef4-cb4d-4206-8a7a-2200270401ec'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/Караганда,%20рыбак%20в%20ЦПКиО%20(3).jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:Караганда,_рыбак_в_ЦПКиО_(3).jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('11000000-0000-4000-8000-000000000025'::uuid, '1f32c9d1-d41d-4428-a853-fabe168aadef'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/Atyrau%20footbridge%20across%20Ural%20River.jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:Atyrau_footbridge_across_Ural_River.jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('11000000-0000-4000-8000-000000000026'::uuid, '25f2452e-9943-463f-a135-27a72df7015d'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/The%20grotto%20at%20the%20seashore%20in%20Aktau.jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:The_grotto_at_the_seashore_in_Aktau.jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('11000000-0000-4000-8000-000000000027'::uuid, '7344289b-c411-4ad5-ab27-268c06ef3cbb'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/Pedestrian%20walkway%20along%20the%20Caspian%20Sea%20waterfront%20promenade%20in%20Aktau,%20Kazakhstan.jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:Pedestrian_walkway_along_the_Caspian_Sea_waterfront_promenade_in_Aktau,_Kazakhstan.jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('11000000-0000-4000-8000-000000000028'::uuid, 'c7d8a58e-ee75-44cb-93f8-6f93f9a8a929'::uuid, 'https://kz-admin.yers.dev/uploads/mechet_mashhur_Zhusup_ba6485b010.jpg', 'https://qaztravel.kz/en/tourist-spots/mashkhur-jusup-kopeyev-mosque', 'QazTravel', 'See source page terms'),
        ('11000000-0000-4000-8000-000000000029'::uuid, 'b42b4c2b-cd7f-47c1-b2ba-da8c1798cf60'::uuid, 'https://kz-admin.yers.dev/uploads/AAM_1327_b5e89e8cc6.JPG', 'https://qaztravel.kz/kk/tourist-spots/ethnographic-museum-reserve-of-east-kazakhstan-province', 'QazTravel', 'See source page terms'),
        ('11000000-0000-4000-8000-000000000030'::uuid, '90742f2d-6b54-4676-930c-97bc59b60a64'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/Семей%20қаласындағы%20Абай%20музей-үйі.jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:Семей_қаласындағы_Абай_музей-үйі.jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('11000000-0000-4000-8000-000000000031'::uuid, '1ab18d1c-be18-4cfc-a5df-4494a4c12aed'::uuid, 'https://kz-admin.yers.dev/uploads/VS_9796_8fb38e8e31.jpg', 'https://qaztravel.kz/en/tourist-spots/korkyt-ata-memorial', 'QazTravel', 'See source page terms'),
        ('11000000-0000-4000-8000-000000000032'::uuid, 'e895297e-6ecd-454e-89a5-88e341ccad4f'::uuid, 'https://kz-admin.yers.dev/uploads/aktobe_mechet_n_75d07db780.jpg', 'https://qaztravel.kz/en/tourist-spots/nur-gasyr-regional-mosque', 'QazTravel', 'See source page terms'),
        ('11000000-0000-4000-8000-000000000033'::uuid, '0ce9cd13-dfc9-481b-821f-78ccaafb48bc'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/Костанай,%20пр.%20Аль-Фараби%20-%20panoramio%20(3).jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:Костанай,_пр._Аль-Фараби_-_panoramio_(3).jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('11000000-0000-4000-8000-000000000034'::uuid, 'eb123ce9-2da4-4b75-a0cd-d419699c166f'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/Краеведческий%20музей%20-%20panoramio%20(8).jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:Краеведческий_музей_-_panoramio_(8).jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page'),
        ('11000000-0000-4000-8000-000000000035'::uuid, '3050b34f-5ecf-4ed3-8438-d6cc8deee7ff'::uuid, 'https://commons.wikimedia.org/wiki/Special:FilePath/Akmola%20Regional%20Museum%20of%20History%20and%20Local%20Lore%20in%20Kokshetau.jpg?width=1400', 'https://commons.wikimedia.org/wiki/File:Akmola_Regional_Museum_of_History_and_Local_Lore_in_Kokshetau.jpg', 'Wikimedia Commons contributors', 'See Wikimedia Commons source page')
)
INSERT INTO attraction_media (
    id,
    attraction_id,
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
    curated_media.attraction_id,
    '00000000-0000-0000-0000-000000000000'::uuid,
    curated_media.external_url,
    curated_media.source_url,
    curated_media.credit,
    curated_media.license,
    'PHOTO',
    0,
    NOW()
FROM curated_media
WHERE EXISTS (
    SELECT 1
    FROM attractions a
    WHERE a.id = curated_media.attraction_id
)
ON CONFLICT (id) DO UPDATE
SET
    attraction_id = EXCLUDED.attraction_id,
    file_id = EXCLUDED.file_id,
    external_url = EXCLUDED.external_url,
    source_url = EXCLUDED.source_url,
    credit = EXCLUDED.credit,
    license = EXCLUDED.license,
    media_type = EXCLUDED.media_type,
    position = EXCLUDED.position;
