DROP TABLE IF EXISTS review_media;
DROP TABLE IF EXISTS place_reviews;
DROP TABLE IF EXISTS place_media;
DROP TRIGGER IF EXISTS trg_place_translations_search_vector ON place_translations;
DROP FUNCTION IF EXISTS place_translations_search_vector_update();
DROP TABLE IF EXISTS place_translations;
DROP TABLE IF EXISTS places;
