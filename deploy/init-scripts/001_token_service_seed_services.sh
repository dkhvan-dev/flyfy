#!/bin/bash
set -e

echo "Seeding token-service service accounts..."

# bcrypt hashes:
# auth-service-secret
AUTH_SERVICE_SECRET_HASH='$2a$10$A7ef3KDBYRHMONku1D3rmuvAc6Qb5nG95u8AybaBWvVzmknXA461i'

# api-gateway-secret
API_GATEWAY_SECRET_HASH='$2a$10$q5bLHfked72rceQ/ozfxU.p0iXLEOeXgWZQ34MnNox/EeDmIwk6sm'

psql -v ON_ERROR_STOP=1 \
  --username "token_service" \
  --dbname "token_service" <<'SQL'
INSERT INTO service_accounts (id, service_id, service_secret, display_name, is_active)
VALUES
  (gen_random_uuid(), 'auth-service', '$2a$10$A7ef3KDBYRHMONku1D3rmuvAc6Qb5nG95u8AybaBWvVzmknXA461i', 'Auth Service', TRUE),
  (gen_random_uuid(), 'api-gateway', '$2a$10$q5bLHfked72rceQ/ozfxU.p0iXLEOeXgWZQ34MnNox/EeDmIwk6sm', 'API Gateway', TRUE)
ON CONFLICT (service_id) DO UPDATE
SET
  service_secret = EXCLUDED.service_secret,
  display_name = EXCLUDED.display_name,
  is_active = EXCLUDED.is_active,
  updated_at = NOW();

INSERT INTO service_roles (account_id, role)
SELECT sa.id, 'token:generate'
FROM service_accounts sa
WHERE sa.service_id = 'auth-service'
ON CONFLICT DO NOTHING;

INSERT INTO service_roles (account_id, role)
SELECT sa.id, 'token:validate'
FROM service_accounts sa
WHERE sa.service_id = 'api-gateway'
ON CONFLICT DO NOTHING;
SQL

echo "token-service service accounts seeded."