#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
compose_file="${repo_root}/infra/test/docker-compose.test.yml"
preflight_file="${repo_root}/infra/test/scripts/preflight-mtls-certs.sh"
workflow_file="${repo_root}/.github/workflows/deploy-test.yml"
deploy_script_file="${repo_root}/infra/test/scripts/deploy.sh"
saved_migrator_file="${repo_root}/deploy/init-scripts/025_saved_service_migrate.sh"
saved_entity_scope_dir="${repo_root}/backend/services/saved-service/migrations"
place_migrator_file="${repo_root}/deploy/init-scripts/009_place_service_migrations.sh"
deploy_compose_file="${repo_root}/deploy/docker-compose.yml"
migration_runner_file="${repo_root}/infra/test/scripts/migrate-postgres.sh"
saved_dockerfile="${repo_root}/backend/services/saved-service/Dockerfile"

for service in minio-mc saved-search-rollout sticker-default-stickers-seeder; do
  service_section="$(sed -n "/^  ${service}:/,/^  [a-zA-Z0-9_-]*:/p" "${compose_file}")"
  grep -Fq 'com.inflap.smoke.allow-exited: "true"' <<<"${service_section}" || {
    echo "one-shot service ${service} must be marked as allowed to exit successfully" >&2
    exit 1
  }
done

for migration in \
  007_saved_entity_scope_expand.up.sql \
  007a_saved_entity_scope_validate.up.sql \
  007b_saved_entity_scope_contract.up.sql \
  008_saved_user_entity.up.sql \
  008a_saved_user_reconciliation_index.up.sql \
  009_saved_post_entity_expand.up.sql \
  009a_saved_post_entity_validate.up.sql \
  009b_saved_post_entity_contract.up.sql \
  009c_saved_post_reconciliation_index.up.sql
do
  test -f "${saved_entity_scope_dir}/${migration}" || {
    echo "saved-service entity scope migration is missing: ${migration}" >&2
    exit 1
  }
done
grep -Fq "CHECK (entity_type IN ('ATTRACTION', 'ACTIVITY', 'USER', 'POST')) NOT VALID" \
  "${saved_entity_scope_dir}/009_saved_post_entity_expand.up.sql" || {
  echo "saved-service final entity scope must contain Attraction, Activity, User and Post" >&2
  exit 1
}

grep -Fq 'command: ["-js", "-sd", "/data", "-m", "8222"]' "${compose_file}" || {
  echo "test NATS JetStream must persist its store in the mounted /data volume" >&2
  exit 1
}

translation_service="$(sed -n '/^  translation-service:/,/^networks:/p' "${compose_file}")"
for expected in \
  'MTLS_CLIENT_CERT_PATH: /opt/inflap/secrets/mtls/translation-service/client.crt' \
  'MTLS_CLIENT_KEY_PATH: /opt/inflap/secrets/mtls/translation-service/client.key' \
  '      - egress'
do
  grep -Fq -- "${expected}" <<<"${translation_service}" || {
    echo "translation-service deployment config is missing: ${expected}" >&2
    exit 1
  }
done

token_service="$(sed -n '/^  token-service:/,/^  auth-service:/p' "${compose_file}")"
for expected in \
  'spiffe://inflap/test/translation-service' \
  'support-service,translation-service,user-service'
do
  grep -Fq -- "${expected}" <<<"${token_service}" || {
    echo "token-service mTLS allowlist is missing: ${expected}" >&2
    exit 1
  }
done

saved_service="$(sed -n '/^  saved-service:/,/^  token-service:/p' "${compose_file}")"
if grep -Fq 'EXCURSION_SOURCE_ENABLED' <<<"${saved_service}"; then
  echo "saved-service deployment must not expose a retired Excursion source flag" >&2
  exit 1
fi
for expected in \
  '}saved-service:${IMAGE_TAG:-test-latest}' \
  'POSTGRES_DB: saved_service_db' \
  'SAVED_SERVICE_TOKEN_SERVICE_SECRET is required' \
  'SAVED_OPERATION_HMAC_CURRENT_KEY_BASE64 is required' \
  'SAVED_CURSOR_ACTIVE_KEY_BASE64 is required' \
  'SAVED_COLLECTIONS_PRODUCT_ENABLED: "true"' \
  'SAVED_SEARCH_PRODUCT_ENABLED: "true"' \
  'SAVED_ROLLOUT_SEARCH_BASIS_POINTS: "10000"' \
  'SAVED_ROLLOUT_USER_BASIS_POINTS: ${SAVED_ROLLOUT_USER_BASIS_POINTS:-10000}' \
  'SAVED_ROLLOUT_POST_BASIS_POINTS: ${SAVED_ROLLOUT_POST_BASIS_POINTS:-10000}' \
  '<<: [*common-env, *postgres-env]' \
  'USER_SOURCE_GRPC_TARGET:' \
  'POST_SOURCE_GRPC_TARGET:' \
  'CHAT_SERVICE_INTERNAL_HTTP_URL:' \
  'saved-search-rollout:' \
  'condition: service_completed_successfully' \
  'spiffe://inflap/test/api-gateway,spiffe://inflap/test/user-service' \
  'user-service:' \
  'chat-service:'
do
  grep -Fq -- "${expected}" <<<"${saved_service}" || {
    echo "saved-service deployment config is missing: ${expected}" >&2
    exit 1
  }
done

feed_service="$(sed -n '/^  feed-service:/,/^  feed-search-backfill:/p' "${compose_file}")"
for expected in \
  'GRPC_PORT: 9098' \
  'INTERNAL_GRPC_TLS_PORT: ${FEED_SERVICE_INTERNAL_GRPC_TLS_PORT:-9448}' \
  'SERVICE_AUTH_ISSUER: inflap/test-token-service' \
  'SERVICE_AUTH_JWKS_URL:' \
  'spiffe://inflap/test/saved-service' \
  'admin-panel,api-gateway,saved-service,user-service' \
  'token-service:'
do
  grep -Fq -- "${expected}" <<<"${feed_service}" || {
    echo "feed-service Saved source deployment config is missing: ${expected}" >&2
    exit 1
  }
done
grep -Fq 'INTERNAL_SERVICE_TOKEN: ${INTERNAL_SERVICE_TOKEN:?INTERNAL_SERVICE_TOKEN is required}' \
  "${compose_file}" || {
  echo "test Saved deployment must receive the shared internal service token" >&2
  exit 1
}

saved_search_rollout="$(sed -n '/^  saved-search-rollout:/,/^  saved-service:/p' "${compose_file}")"
for expected in \
  '}saved-service:${IMAGE_TAG:-test-latest}' \
  'entrypoint: ["/app/saved-search-backfill"]' \
  '"-mode=rollout"' \
  '"-max-batches=${SAVED_SEARCH_BACKFILL_MAX_BATCHES:-10000}"' \
  'PGDATABASE: saved_service_db' \
  'POSTGRES_PASSWORD is required' \
  'condition: service_healthy' \
  'disable: true' \
  'restart: "no"'
do
  grep -Fq -- "${expected}" <<<"${saved_search_rollout}" || {
    echo "saved-search-rollout deployment config is missing: ${expected}" >&2
    exit 1
  }
done

grep -Fq 'saved_service_db}' "${compose_file}" || {
  echo "test PostgreSQL bootstrap does not create saved_service_db" >&2
  exit 1
}
grep -Fq '"saved-service:saved_service_db:025_saved_service_migrate.sh"' "${migration_runner_file}" || {
  echo "test migration runner does not include saved-service" >&2
  exit 1
}
grep -Fq 'SAVED_SERVICE_TOKEN_SERVICE_SECRET' "${migration_runner_file}" || {
  echo "test migration runner does not forward the saved-service seed secret" >&2
  exit 1
}
for expected in \
  'COPY proto ./proto' \
  'COPY backend/pkg/platformpolicy ./backend/pkg/platformpolicy' \
  'COPY backend/pkg/serviceauth ./backend/pkg/serviceauth' \
  'COPY backend/pkg/transportauth ./backend/pkg/transportauth' \
  'go build -trimpath -ldflags="-s -w" -o /out/saved-service ./cmd' \
  'go build -trimpath -ldflags="-s -w" -o /out/saved-search-backfill ./cmd/saved-search-backfill'
do
  grep -Fq -- "${expected}" "${saved_dockerfile}" || {
    echo "saved-service CI Dockerfile is missing: ${expected}" >&2
    exit 1
  }
done

for service in activity-service guide-service place-service; do
  service_section="$(sed -n "/^  ${service}:/,/^  [a-zA-Z0-9_-]*:/p" "${compose_file}")"
  for expected in 'spiffe://inflap/test/saved-service' 'NATS_URL: nats://nats:4222'; do
    grep -Fq -- "${expected}" <<<"${service_section}" || {
      echo "${service} Saved source wiring is missing: ${expected}" >&2
      exit 1
    }
  done
done

for service in user-service chat-service; do
  service_section="$(sed -n "/^  ${service}:/,/^  [a-zA-Z0-9_-]*:/p" "${compose_file}")"
  grep -Fq 'spiffe://inflap/test/saved-service' <<<"${service_section}" || {
    echo "${service} mTLS allowlist does not grant saved-service access" >&2
    exit 1
  }
done

client_services="$(sed -n '/^client_services=(/,/^)/p' "${preflight_file}")"
grep -Fq '  translation-service' <<<"${client_services}" || {
  echo "mTLS preflight does not validate the translation-service client certificate" >&2
  exit 1
}
grep -Fq '  saved-service' <<<"${client_services}" || {
  echo "mTLS preflight does not validate the saved-service client certificate" >&2
  exit 1
}

server_services="$(sed -n '/^server_services=(/,/^)/p' "${preflight_file}")"
grep -Fq '  saved-service' <<<"${server_services}" || {
  echo "mTLS preflight does not validate the saved-service server certificate" >&2
  exit 1
}

generator_services="$(sed -n '/^services=(/,/^)/p' "${repo_root}/infra/test/scripts/generate-mtls-certs.sh")"
grep -Fq '  saved-service' <<<"${generator_services}" || {
  echo "mTLS generator does not issue saved-service certificates" >&2
  exit 1
}

for expected in \
  'MTLS_AUTO_PROVISION_CERTS' \
  'generate-mtls-certs.sh' \
  'refusing to create or replace the CA during deploy' \
  'Reconciling the test mTLS certificate inventory with the existing CA.'
do
  grep -Fq -- "${expected}" "${deploy_script_file}" || {
    echo "deploy script is missing safe mTLS certificate reconciliation: ${expected}" >&2
    exit 1
  }
done

for expected in \
  '/opt/inflap/docker-compose.test.yml.previous' \
  '/opt/inflap/env/runtime.env.previous' \
  "MTLS_MODE='\${MTLS_MODE}'" \
  "MTLS_AUTO_PROVISION_CERTS='\${MTLS_AUTO_PROVISION_CERTS}'" \
  '/opt/inflap/scripts/deploy.sh'
do
  grep -Fq -- "${expected}" "${workflow_file}" || {
    echo "deploy workflow transaction wiring is missing: ${expected}" >&2
    exit 1
  }
done

grep -Fq 'go-version-file: proto/go.mod' "${workflow_file}" || {
  echo "deploy workflow must resolve Go from the tracked proto/go.mod file" >&2
  exit 1
}
if grep -Fq 'go-version-file: go.work' "${workflow_file}"; then
  echo "deploy workflow must not depend on the gitignored local go.work file" >&2
  exit 1
fi
grep -Fq 'compose_validation_env=(' "${workflow_file}" || {
  echo "deploy workflow must define an inline Compose validation environment" >&2
  exit 1
}
for expected in \
  '            saved-service' \
  'SAVED_SERVICE_TOKEN_SERVICE_SECRET: ${{ secrets.SAVED_SERVICE_TOKEN_SERVICE_SECRET }}' \
  'SAVED_OPERATION_HMAC_CURRENT_KEY_BASE64: ${{ secrets.SAVED_OPERATION_HMAC_CURRENT_KEY_BASE64 }}' \
  'SAVED_CURSOR_ACTIVE_KEY_BASE64: ${{ secrets.SAVED_CURSOR_ACTIVE_KEY_BASE64 }}' \
  "MTLS_AUTO_PROVISION_CERTS: \${{ vars.MTLS_AUTO_PROVISION_CERTS || 'true' }}" \
  'SAVED_SERVICE_INTERNAL_HTTP_URL: ${{ vars.SAVED_SERVICE_INTERNAL_HTTP_URL'
do
  grep -Fq -- "${expected}" "${workflow_file}" || {
    echo "deploy workflow Saved wiring is missing: ${expected}" >&2
    exit 1
  }
done
while IFS= read -r required_name; do
  grep -Fq "${required_name}=compose-validation" "${workflow_file}" || {
    echo "deploy workflow Compose validation is missing ${required_name}" >&2
    exit 1
  }
done < <(
  grep -oE '\$\{[A-Z0-9_]+:\?[^}]+\}' "${compose_file}" \
    | sed -E 's/^\$\{([A-Z0-9_]+):.*/\1/' \
    | sort -u
)
if grep -Fq 'infra/test/env/.env.test.example' "${workflow_file}"; then
  echo "deploy workflow must not depend on the gitignored local test env file" >&2
  exit 1
fi
if grep -Fq -- '--no-interpolate' "${workflow_file}"; then
  echo "deploy workflow must not validate short volume syntax with unresolved interpolation" >&2
  exit 1
fi

grep -Fq "INDEX[[:space:]]+CONCURRENTLY" "${saved_migrator_file}" || {
  echo "saved-service migrator must detect concurrent indexes from migration content" >&2
  exit 1
}
for expected in 'NOT indisvalid' 'NOT indisready' 'assert_no_invalid_indexes'; do
  grep -Fq "${expected}" "${saved_migrator_file}" || {
    echo "saved-service migrator must reject invalid concurrent index state: ${expected}" >&2
    exit 1
  }
done
for expected in 'psql_concurrent_cmd -f "$file"' 'lock_timeout=5s' 'statement_timeout=30min'; do
  grep -Fq "${expected}" "${saved_migrator_file}" || {
    echo "saved-service concurrent index migration must have bounded execution: ${expected}" >&2
    exit 1
  }
done
if grep -Eq '003a_\*|003b_\*|003c_\*|006a_\*' "${saved_migrator_file}"; then
  echo "saved-service migrator must not use a filename allowlist for concurrent indexes" >&2
  exit 1
fi

for expected in '--single-transaction' 'checksum' 'assert_no_invalid_indexes' 'lock_timeout=5s'; do
  grep -Fq -- "${expected}" "${place_migrator_file}" || {
    echo "place-service migrator is missing production migration safety: ${expected}" >&2
    exit 1
  }
done
if grep -Fq '009_place_service.sh:/docker-entrypoint-initdb.d/' "${deploy_compose_file}"; then
  echo "place-service schema must have one owner; PostgreSQL init must not replay migrator-owned files" >&2
  exit 1
fi

deploy_saved_service="$(sed -n '/^  saved-service:/,/^  place-postgres:/p' "${deploy_compose_file}")"
if grep -Fq 'EXCURSION_SOURCE_ENABLED' <<<"${deploy_saved_service}"; then
  echo "local Saved Compose must not expose a retired Excursion source flag" >&2
  exit 1
fi
for expected in \
  'POSTGRES_HOST: ${SAVED_POSTGRES_HOST:-saved-postgres}' \
  'POSTGRES_PORT: ${SAVED_POSTGRES_PORT:-5432}' \
  'POSTGRES_USER: ${SAVED_POSTGRES_USER:-saved_service}' \
  'POSTGRES_DB: ${SAVED_POSTGRES_DB:-saved_service_db}' \
  'PGSSLROOTCERT: ${SAVED_POSTGRES_SSL_ROOT_CERT:-}' \
  'SAVED_COLLECTIONS_PRODUCT_ENABLED: ${SAVED_COLLECTIONS_PRODUCT_ENABLED:-true}' \
  'SAVED_SEARCH_PRODUCT_ENABLED: ${SAVED_SEARCH_PRODUCT_ENABLED:-true}' \
  'SAVED_ROLLOUT_USER_BASIS_POINTS: ${SAVED_ROLLOUT_USER_BASIS_POINTS:-10000}' \
  'SAVED_ROLLOUT_POST_BASIS_POINTS: ${SAVED_ROLLOUT_POST_BASIS_POINTS:-10000}' \
  'USER_SOURCE_GRPC_TARGET: ${USER_SERVICE_INTERNAL_GRPC_TARGET:-dns:///user-service:9094}' \
  'POST_SOURCE_GRPC_TARGET: ${FEED_SERVICE_INTERNAL_GRPC_TARGET:-dns:///feed-service:9098}' \
  'INTERNAL_SERVICE_TOKEN: ${SAVED_SERVICE_INTERNAL_SERVICE_TOKEN:-super-secret-internal-token}' \
  'CHAT_SERVICE_INTERNAL_HTTP_URL: ${CHAT_SERVICE_INTERNAL_HTTP_URL:-http://chat-service:8088}' \
  'saved-search-rollout:' \
  'condition: service_completed_successfully'
do
  grep -Fq -- "${expected}" <<<"${deploy_saved_service}" || {
    echo "local Saved Compose override contract is missing: ${expected}" >&2
    exit 1
  }
done
if grep -Fq 'INTERNAL_SERVICE_TOKEN: ${INTERNAL_SERVICE_TOKEN:-super-secret-internal-token}' \
  <<<"${deploy_saved_service}"; then
  echo "local Saved Compose must not inherit another service's generic internal token" >&2
  exit 1
fi


deploy_saved_search_rollout="$(sed -n '/^  saved-search-rollout:/,/^  checklist-postgres:/p' "${deploy_compose_file}")"
for expected in \
  'image: ${SAVED_SERVICE_IMAGE:-inflap-saved-service:local}' \
  'entrypoint: ["/app/saved-search-backfill"]' \
  '"-mode=rollout"' \
  'saved-postgres-migrator:' \
  'condition: service_completed_successfully' \
  'PGDATABASE: ${SAVED_POSTGRES_DB:-saved_service_db}'
do
  grep -Fq -- "${expected}" <<<"${deploy_saved_search_rollout}" || {
    echo "local Saved search rollout contract is missing: ${expected}" >&2
    exit 1
  }
done

echo "deployment config contract test passed"
