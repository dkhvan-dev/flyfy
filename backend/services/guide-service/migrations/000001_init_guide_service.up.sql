CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE IF NOT EXISTS guide_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE,

    type VARCHAR(32) NOT NULL,
    status VARCHAR(32) NOT NULL,

    headline VARCHAR(255),
    about TEXT,
    experience_years INTEGER NOT NULL DEFAULT 0 CHECK (experience_years >= 0),

    base_city_id UUID,

    is_private_guide_available BOOLEAN NOT NULL DEFAULT FALSE,
    is_activity_host_available BOOLEAN NOT NULL DEFAULT FALSE,
    is_excursion_guide_available BOOLEAN NOT NULL DEFAULT FALSE,

    rating_avg NUMERIC(4,2) NOT NULL DEFAULT 0,
    reviews_count INTEGER NOT NULL DEFAULT 0 CHECK (reviews_count >= 0),

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS guide_verification_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    guide_profile_id UUID NOT NULL REFERENCES guide_profiles(id),

    status VARCHAR(32) NOT NULL,
    comment TEXT,
    review_comment TEXT,

    submitted_at TIMESTAMPTZ,
    reviewed_at TIMESTAMPTZ,
    reviewed_by UUID,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS guide_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    verification_request_id UUID NOT NULL REFERENCES guide_verification_requests(id),
    file_id UUID NOT NULL,
    document_type VARCHAR(64) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS guide_languages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    guide_profile_id UUID NOT NULL REFERENCES guide_profiles(id),
    language_code VARCHAR(16) NOT NULL,
    proficiency_level VARCHAR(32) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS guide_specializations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    guide_profile_id UUID NOT NULL REFERENCES guide_profiles(id),
    specialization_code VARCHAR(64) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS guide_regions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    guide_profile_id UUID NOT NULL REFERENCES guide_profiles(id),
    country_code VARCHAR(8) NOT NULL,
    city_id UUID,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS guide_company_affiliations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    guide_profile_id UUID NOT NULL REFERENCES guide_profiles(id),
    organization_id UUID NOT NULL,
    employment_type VARCHAR(32) NOT NULL,
    is_primary BOOLEAN NOT NULL DEFAULT FALSE,
    active_from TIMESTAMPTZ,
    active_to TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_guide_documents_request_file
    ON guide_documents(verification_request_id, file_id);

CREATE UNIQUE INDEX IF NOT EXISTS uq_guide_languages_profile_language
    ON guide_languages(guide_profile_id, language_code);

CREATE UNIQUE INDEX IF NOT EXISTS uq_guide_specializations_profile_code
    ON guide_specializations(guide_profile_id, specialization_code);

CREATE INDEX IF NOT EXISTS idx_guide_profiles_user_id
    ON guide_profiles(user_id);

CREATE INDEX IF NOT EXISTS idx_guide_profiles_status
    ON guide_profiles(status);

CREATE INDEX IF NOT EXISTS idx_guide_profiles_type
    ON guide_profiles(type);

CREATE INDEX IF NOT EXISTS idx_guide_verification_requests_profile_id
    ON guide_verification_requests(guide_profile_id);

CREATE INDEX IF NOT EXISTS idx_guide_verification_requests_status
    ON guide_verification_requests(status);

CREATE INDEX IF NOT EXISTS idx_guide_documents_request_id
    ON guide_documents(verification_request_id);

CREATE INDEX IF NOT EXISTS idx_guide_languages_profile_id
    ON guide_languages(guide_profile_id);

CREATE INDEX IF NOT EXISTS idx_guide_specializations_profile_id
    ON guide_specializations(guide_profile_id);

CREATE INDEX IF NOT EXISTS idx_guide_regions_profile_id
    ON guide_regions(guide_profile_id);

CREATE INDEX IF NOT EXISTS idx_guide_company_affiliations_profile_id
    ON guide_company_affiliations(guide_profile_id);

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_guide_profiles_set_updated_at ON guide_profiles;
CREATE TRIGGER trg_guide_profiles_set_updated_at
BEFORE UPDATE ON guide_profiles
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS trg_guide_verification_requests_set_updated_at ON guide_verification_requests;
CREATE TRIGGER trg_guide_verification_requests_set_updated_at
BEFORE UPDATE ON guide_verification_requests
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();