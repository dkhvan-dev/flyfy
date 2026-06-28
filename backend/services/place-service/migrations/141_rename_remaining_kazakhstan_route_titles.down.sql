-- Roll back the final Kazakhstan RU route-title cleanup.

CREATE TEMP TABLE seed_kazakhstan_remaining_route_titles (
    old_title text NOT NULL,
    new_title text NOT NULL,
    match_tags text[] NOT NULL
);

INSERT INTO seed_kazakhstan_remaining_route_titles (old_title, new_title, match_tags) VALUES
    ('Скальная тропа Актау', 'Актау: скальная тропа', ARRAY['rocky-trail']::text[]),
    ('Трек через перевал Сары-Булак у Кольсая', 'Перевал Сары-Булак у Кольсая', ARRAY['kolsai-sary-bulak-pass-trek']::text[]),
    ('Тропа озер Имантау-Шалкар', 'Озера Имантау-Шалкар', ARRAY['imantau-shalkar-lakes-trail']::text[]),
    ('Тропы Западно-Алтайского заповедника', 'Западно-Алтайский заповедник: тропы', ARRAY['west-altai-nature-reserve-trails']::text[]);

UPDATE place_translations pt
SET
    title = remaining.old_title,
    updated_at = NOW()
FROM places p
JOIN seed_kazakhstan_remaining_route_titles remaining
    ON p.tags && remaining.match_tags
WHERE pt.place_id = p.id
  AND pt.locale = 'ru'
  AND p.country_code = 'KZ'
  AND pt.title = remaining.new_title;

DROP TABLE IF EXISTS seed_kazakhstan_remaining_route_titles;
