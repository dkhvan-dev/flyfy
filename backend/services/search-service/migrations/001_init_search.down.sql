DROP INDEX IF EXISTS idx_search_document_events_due;
DROP INDEX IF EXISTS idx_search_document_events_source_unique;
DROP TABLE IF EXISTS search_document_events;

DROP INDEX IF EXISTS idx_search_documents_updated_at;
DROP INDEX IF EXISTS idx_search_documents_country_city;
DROP INDEX IF EXISTS idx_search_documents_domain_visibility_moderation;
DROP INDEX IF EXISTS idx_search_documents_geo;
DROP INDEX IF EXISTS idx_search_documents_trgm;
DROP INDEX IF EXISTS idx_search_documents_vector;
DROP INDEX IF EXISTS idx_search_documents_entity_unique;
DROP TRIGGER IF EXISTS trg_search_documents_refresh_derived_fields ON search_documents;
DROP TABLE IF EXISTS search_documents;
DROP FUNCTION IF EXISTS refresh_search_document_derived_fields();
