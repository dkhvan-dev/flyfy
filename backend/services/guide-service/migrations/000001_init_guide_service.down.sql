DROP TRIGGER IF EXISTS trg_guide_verification_requests_set_updated_at ON guide_verification_requests;
DROP TRIGGER IF EXISTS trg_guide_profiles_set_updated_at ON guide_profiles;

DROP INDEX IF EXISTS idx_guide_company_affiliations_profile_id;
DROP INDEX IF EXISTS idx_guide_regions_profile_id;
DROP INDEX IF EXISTS idx_guide_specializations_profile_id;
DROP INDEX IF EXISTS idx_guide_languages_profile_id;
DROP INDEX IF EXISTS idx_guide_documents_request_id;
DROP INDEX IF EXISTS idx_guide_verification_requests_status;
DROP INDEX IF EXISTS idx_guide_verification_requests_profile_id;
DROP INDEX IF EXISTS idx_guide_profiles_type;
DROP INDEX IF EXISTS idx_guide_profiles_status;
DROP INDEX IF EXISTS idx_guide_profiles_user_id;

DROP INDEX IF EXISTS uq_guide_specializations_profile_code;
DROP INDEX IF EXISTS uq_guide_languages_profile_language;
DROP INDEX IF EXISTS uq_guide_documents_request_file;

DROP TABLE IF EXISTS guide_company_affiliations;
DROP TABLE IF EXISTS guide_regions;
DROP TABLE IF EXISTS guide_specializations;
DROP TABLE IF EXISTS guide_languages;
DROP TABLE IF EXISTS guide_documents;
DROP TABLE IF EXISTS guide_verification_requests;
DROP TABLE IF EXISTS guide_profiles;