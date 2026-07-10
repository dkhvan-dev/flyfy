#!/bin/sh
set -e

required_env() {
  name="$1"
  value="$(printenv "$name" || true)"
  if [ -z "$value" ]; then
    echo "Missing required env: $name" >&2
    exit 1
  fi
}

for name in \
  AUTH_SERVICE_TOKEN_SERVICE_SECRET \
  API_GATEWAY_TOKEN_SERVICE_SECRET \
  ACTIVITY_SERVICE_TOKEN_SERVICE_SECRET \
  EXCURSION_SERVICE_TOKEN_SERVICE_SECRET \
  FEED_SERVICE_TOKEN_SERVICE_SECRET \
  GUIDE_SERVICE_TOKEN_SERVICE_SECRET \
  PLACE_SERVICE_TOKEN_SERVICE_SECRET \
  SUPPORT_SERVICE_TOKEN_SERVICE_SECRET \
  USER_SERVICE_TOKEN_SERVICE_SECRET
do
  required_env "$name"
done

echo "Seeding token-service service accounts..."

POSTGRES_DB="${POSTGRES_DB:-token_service}"
POSTGRES_USER="${POSTGRES_USER:-token_service}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-}"
PGHOST="${PGHOST:-}"
PGPORT="${PGPORT:-5432}"
if [ -n "$POSTGRES_PASSWORD" ]; then
  export PGPASSWORD="$POSTGRES_PASSWORD"
fi

set -- -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB"
if [ -n "$PGHOST" ]; then
  set -- -v ON_ERROR_STOP=1 -h "$PGHOST" -p "$PGPORT" --username "$POSTGRES_USER" --dbname "$POSTGRES_DB"
fi

psql \
  "$@" \
  -v auth_service_secret="$AUTH_SERVICE_TOKEN_SERVICE_SECRET" \
  -v api_gateway_secret="$API_GATEWAY_TOKEN_SERVICE_SECRET" \
  -v activity_service_secret="$ACTIVITY_SERVICE_TOKEN_SERVICE_SECRET" \
  -v excursion_service_secret="$EXCURSION_SERVICE_TOKEN_SERVICE_SECRET" \
  -v feed_service_secret="$FEED_SERVICE_TOKEN_SERVICE_SECRET" \
  -v guide_service_secret="$GUIDE_SERVICE_TOKEN_SERVICE_SECRET" \
  -v place_service_secret="$PLACE_SERVICE_TOKEN_SERVICE_SECRET" \
  -v support_service_secret="$SUPPORT_SERVICE_TOKEN_SERVICE_SECRET" \
  -v user_service_secret="$USER_SERVICE_TOKEN_SERVICE_SECRET" <<'SQL'
CREATE EXTENSION IF NOT EXISTS pgcrypto;

WITH desired(service_id, plain_secret, display_name) AS (
  VALUES
    ('auth-service', :'auth_service_secret', 'Auth Service'),
    ('api-gateway', :'api_gateway_secret', 'API Gateway'),
    ('activity-service', :'activity_service_secret', 'Activity Service'),
    ('excursion-service', :'excursion_service_secret', 'Excursion Service'),
    ('feed-service', :'feed_service_secret', 'Feed Service'),
    ('guide-service', :'guide_service_secret', 'Guide Service'),
    ('place-service', :'place_service_secret', 'Place Service'),
    ('support-service', :'support_service_secret', 'Support Service'),
    ('user-service', :'user_service_secret', 'User Service')
)
INSERT INTO service_accounts (id, service_id, service_secret, display_name, is_active)
SELECT gen_random_uuid(), service_id, crypt(plain_secret, gen_salt('bf', 10)), display_name, TRUE
FROM desired
ON CONFLICT (service_id) DO UPDATE
SET
  service_secret = EXCLUDED.service_secret,
  display_name = EXCLUDED.display_name,
  is_active = EXCLUDED.is_active,
  updated_at = NOW();

WITH desired(service_id, role) AS (
  VALUES
    ('auth-service', 'token:generate'),
    ('auth-service', 'token:validate'),
    ('auth-service', 'token:revoke'),
    ('api-gateway', 'token:validate'),
    ('activity-service', 'search:index'),
    ('excursion-service', 'search:index'),
    ('excursion-service', 'translation:translate'),
    ('feed-service', 'search:index'),
    ('guide-service', 'search:index'),
    ('place-service', 'search:index'),
    ('support-service', 'search:index'),
    ('user-service', 'search:index')
)
DELETE FROM service_roles sr
USING service_accounts sa
WHERE sr.account_id = sa.id
  AND sr.role = 'search:index'
  AND sa.service_id IN (
    'auth-service',
    'api-gateway',
    'activity-service',
    'excursion-service',
    'feed-service',
    'guide-service',
    'place-service',
    'support-service',
    'user-service'
  )
  AND NOT EXISTS (
    SELECT 1
    FROM desired
    WHERE desired.service_id = sa.service_id
      AND desired.role = sr.role
  );

WITH desired(service_id, role) AS (
  VALUES
    ('auth-service', 'token:generate'),
    ('auth-service', 'token:validate'),
    ('auth-service', 'token:revoke'),
    ('api-gateway', 'token:validate'),
    ('activity-service', 'search:index'),
    ('excursion-service', 'search:index'),
    ('excursion-service', 'translation:translate'),
    ('feed-service', 'search:index'),
    ('guide-service', 'search:index'),
    ('place-service', 'search:index'),
    ('support-service', 'search:index'),
    ('user-service', 'search:index')
)
INSERT INTO service_roles (account_id, role)
SELECT sa.id, desired.role
FROM desired
JOIN service_accounts sa ON sa.service_id = desired.service_id
ON CONFLICT DO NOTHING;
SQL

echo "token-service service accounts seeded."
