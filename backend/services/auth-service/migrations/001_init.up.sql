-- 001_init.up.sql
-- Auth Service Schema
-- PostgreSQL 17+

BEGIN;

-- Auth users: user identities for authentication
CREATE TABLE IF NOT EXISTS auth_users (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone           VARCHAR(20) UNIQUE,
    role            VARCHAR(32) NOT NULL DEFAULT 'tourist',
    is_active       BOOLEAN DEFAULT true,
    created_at      TIMESTAMPTZ DEFAULT now(),
    updated_at      TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_auth_users_phone ON auth_users(phone) WHERE phone IS NOT NULL;

-- Auth providers: OAuth provider links (Google, Apple)
CREATE TABLE IF NOT EXISTS auth_providers (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES auth_users(id) ON DELETE CASCADE,
    provider        VARCHAR(16) NOT NULL,   -- 'google', 'apple'
    provider_id     VARCHAR(256) NOT NULL,  -- 'sub' from ID token
    email           VARCHAR(256),
    created_at      TIMESTAMPTZ DEFAULT now(),
    UNIQUE(provider, provider_id)
);

CREATE INDEX idx_auth_providers_user    ON auth_providers(user_id);
CREATE INDEX idx_auth_providers_lookup  ON auth_providers(provider, provider_id);

-- Updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_auth_users_updated
    BEFORE UPDATE ON auth_users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

COMMIT;
