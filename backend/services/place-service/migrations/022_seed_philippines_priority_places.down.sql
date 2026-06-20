DROP TABLE IF EXISTS seed_philippines_down_ids;
DROP TABLE IF EXISTS seed_philippines_down_slugs;

CREATE TEMP TABLE seed_philippines_down_slugs (
    slug varchar(96) PRIMARY KEY
);

INSERT INTO seed_philippines_down_slugs (slug) VALUES
    ('intramuros'),
    ('fort-santiago'),
    ('rizal-park'),
    ('national-museum-fine-arts'),
    ('national-museum-natural-history'),
    ('binondo-chinatown'),
    ('divisoria-market'),
    ('manila-ocean-park'),
    ('sm-mall-of-asia'),
    ('ayala-museum'),
    ('greenbelt-makati'),
    ('bonifacio-high-street'),
    ('venice-grand-canal-mall'),
    ('taal-volcano-viewpoint'),
    ('sky-ranch-tagaytay'),
    ('magellans-cross'),
    ('basilica-santo-nino'),
    ('fort-san-pedro-cebu'),
    ('sirao-garden'),
    ('temple-of-leah'),
    ('cebu-taoist-temple'),
    ('carbon-market'),
    ('ayala-center-cebu'),
    ('sm-seaside-city-cebu'),
    ('mactan-shrine'),
    ('ten-thousand-roses'),
    ('chocolate-hills'),
    ('philippine-tarsier-sanctuary'),
    ('loboc-river'),
    ('alona-beach'),
    ('balicasag-island'),
    ('puerto-princesa-underground-river'),
    ('honda-bay'),
    ('nagtabon-beach'),
    ('palawan-wildlife-rescue-center'),
    ('big-lagoon-el-nido'),
    ('nacpan-beach'),
    ('seven-commandos-beach'),
    ('hidden-beach-el-nido'),
    ('kayangan-lake'),
    ('twin-lagoon'),
    ('barracuda-lake'),
    ('mount-tapyas'),
    ('maquinit-hot-spring'),
    ('malcapuya-island'),
    ('white-beach-boracay'),
    ('puka-shell-beach'),
    ('bulabog-beach'),
    ('willys-rock'),
    ('dmall-boracay'),
    ('dtalipapa-market'),
    ('iloilo-river-esplanade'),
    ('molo-church'),
    ('calle-real-iloilo'),
    ('la-paz-public-market'),
    ('the-ruins-bacolod'),
    ('negros-museum'),
    ('manokan-country'),
    ('peoples-park-davao'),
    ('philippine-eagle-center'),
    ('eden-nature-park'),
    ('roxas-night-market'),
    ('abreeza-mall'),
    ('cloud-9-siargao'),
    ('sugba-lagoon'),
    ('magpupungko-rock-pools'),
    ('maasin-river'),
    ('dahilayan-adventure-park'),
    ('camiguin-white-island'),
    ('sunken-cemetery-camiguin'),
    ('burnham-park'),
    ('mines-view-park'),
    ('bencab-museum'),
    ('baguio-night-market'),
    ('calle-crisologo'),
    ('vigan-cathedral'),
    ('banaue-rice-terraces'),
    ('sagada-hanging-coffins'),
    ('sumaguing-cave'),
    ('san-juan-surf-beach-la-union'),
    ('saud-beach'),
    ('bangui-windmills');

CREATE TEMP TABLE seed_philippines_down_ids AS
WITH hashed AS (
    SELECT
        slug,
        md5('ph-place:' || slug) AS place_hash,
        md5('ph-media:' || slug) AS media_hash
    FROM seed_philippines_down_slugs
)
SELECT
    (
        substr(place_hash, 1, 8) || '-' ||
        substr(place_hash, 9, 4) || '-4' ||
        substr(place_hash, 14, 3) || '-8' ||
        substr(place_hash, 18, 3) || '-' ||
        substr(place_hash, 21, 12)
    )::uuid AS place_id,
    (
        substr(media_hash, 1, 8) || '-' ||
        substr(media_hash, 9, 4) || '-4' ||
        substr(media_hash, 14, 3) || '-8' ||
        substr(media_hash, 18, 3) || '-' ||
        substr(media_hash, 21, 12)
    )::uuid AS media_id
FROM hashed;

DELETE FROM place_media
WHERE id IN (
    SELECT media_id
    FROM seed_philippines_down_ids
);

DELETE FROM places
WHERE id IN (
    SELECT place_id
    FROM seed_philippines_down_ids
)
AND source = 'IMPORT';

DROP TABLE IF EXISTS seed_philippines_down_ids;
DROP TABLE IF EXISTS seed_philippines_down_slugs;
