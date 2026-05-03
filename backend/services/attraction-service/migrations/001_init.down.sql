DROP TABLE IF EXISTS review_media;
DROP TABLE IF EXISTS attraction_reviews;
DROP TABLE IF EXISTS attraction_media;
DROP TRIGGER IF EXISTS trg_attraction_translations_search_vector ON attraction_translations;
DROP FUNCTION IF EXISTS attraction_translations_search_vector_update();
DROP TABLE IF EXISTS attraction_translations;
DROP TABLE IF EXISTS attractions;
