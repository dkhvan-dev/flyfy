#!/usr/bin/env bash
set -euo pipefail

APP_DIR="${APP_DIR:-/opt/inflap}"
ENV_FILE="${ENV_FILE:-${APP_DIR}/env/test.env}"
DEPLOY_ENV_FILE="${DEPLOY_ENV_FILE:-${APP_DIR}/env/deploy.env}"
RUNTIME_ENV_FILE="${RUNTIME_ENV_FILE:-${APP_DIR}/env/runtime.env}"
COMPOSE_FILE="${COMPOSE_FILE:-${APP_DIR}/docker-compose.test.yml}"
MIGRATIONS_DIR="${MIGRATIONS_DIR:-${APP_DIR}/migrations}"
MIGRATION_SCRIPTS_DIR="${MIGRATION_SCRIPTS_DIR:-${APP_DIR}/migration-scripts}"
MIGRATION_CLIENT_IMAGE="${MIGRATION_CLIENT_IMAGE:-postgis/postgis:16-3.4-alpine}"
MIGRATIONS_DRY_RUN="${MIGRATIONS_DRY_RUN:-false}"

DEFAULT_MIGRATION_SERVICE_MAP=(
  "token-service:token_service_db:001_token_service_migrate.sh"
  "auth-service:auth_db:002_auth_service_migrate.sh"
  "user-service:user_service_db:004_user_service_migrate.sh"
  "guide-service:guide_service_db:005_guide_service_migrate.sh"
  "file-manager-service:file_manager_service_db:-"
  "activity-service:activity_service_db:006_activity_service_migrate.sh"
  "excursion-service:excursion_service_db:012_excursion_service_migrate.sh"
  "feed-service:feed_service_db:007_feed_service_migrate.sh"
  "chat-service:chat_service_db:008_chat_service_migrate.sh"
  "notification-service:notification_service_db:016_notification_service_migrate.sh"
  "payment-service:payment_service_db:010_payment_service_migrate.sh"
  "place-service:place_service_db:009_place_service_migrate.sh"
  "sticker-service:sticker_service_db:011_sticker_service_migrate.sh"
  "checklist-service:checklist_service_db:020_checklist_service_migrate.sh"
  "switches-service:switches_service_db:019_switches_service_migrate.sh"
  "trust-service:trust_service_db:015_trust_service_migrate.sh"
  "anti-fraud-service:anti_fraud_service_db:014_anti_fraud_service_migrate.sh"
  "support-service:support_service_db:022_support_service_migrate.sh"
  "admin-panel:admin_panel_db:013_admin_panel_migrate.sh"
  "user-route-service:user_route_service_db:021_user_route_service_migrate.sh"
  "search-service:search_service_db:-"
  "translation-service:translation_service_db:-"
  "saved-service:saved_service_db:025_saved_service_migrate.sh"
)

cd "${APP_DIR}"

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Missing runtime env file: ${ENV_FILE}" >&2
  exit 1
fi

set -a
# shellcheck disable=SC1090
. "${ENV_FILE}"
if [[ -f "${DEPLOY_ENV_FILE}" ]]; then
  # shellcheck disable=SC1090
  . "${DEPLOY_ENV_FILE}"
fi
set +a

load_compose_env_value() {
  local key="$1"
  local file="$2"
  local line

  if [[ ! -f "${file}" || -n "${!key:-}" ]]; then
    return 0
  fi

  line="$(grep -E "^${key}=" "${file}" | tail -n 1 || true)"
  if [[ -z "${line}" ]]; then
    return 0
  fi

  export "${key}=${line#*=}"
}

if [[ -f "${RUNTIME_ENV_FILE}" ]]; then
  for key in \
    API_GATEWAY_TOKEN_SERVICE_SECRET \
    AUTH_SERVICE_TOKEN_SERVICE_SECRET \
    ACTIVITY_SERVICE_TOKEN_SERVICE_SECRET \
    EXCURSION_SERVICE_TOKEN_SERVICE_SECRET \
    FEED_SERVICE_TOKEN_SERVICE_SECRET \
    GUIDE_SERVICE_TOKEN_SERVICE_SECRET \
    PLACE_SERVICE_TOKEN_SERVICE_SECRET \
    SAVED_SERVICE_TOKEN_SERVICE_SECRET \
    SUPPORT_SERVICE_TOKEN_SERVICE_SECRET \
    USER_SERVICE_TOKEN_SERVICE_SECRET
  do
    load_compose_env_value "${key}" "${RUNTIME_ENV_FILE}"
  done
fi

POSTGRES_USER="${POSTGRES_USER:-postgres}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-change-me-postgres-password}"

if [[ -n "${MIGRATION_SERVICE_MAP:-}" ]]; then
  # shellcheck disable=SC2206
  migration_services=(${MIGRATION_SERVICE_MAP})
else
  migration_services=("${DEFAULT_MIGRATION_SERVICE_MAP[@]}")
fi

if [[ ! -d "${MIGRATIONS_DIR}" ]]; then
  echo "Missing migrations directory: ${MIGRATIONS_DIR}" >&2
  exit 1
fi

for item in "${migration_services[@]}"; do
  IFS=":" read -r service database migration_script <<<"${item}"
  if [[ -z "${service}" || -z "${database}" ]]; then
    echo "Invalid migration service mapping: ${item}" >&2
    exit 1
  fi
  if [[ ! "${database}" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
    echo "Unsafe migration database name: ${database}" >&2
    exit 1
  fi
  migration_script="${migration_script:-}"
  if [[ ! -d "${MIGRATIONS_DIR}/${service}" ]]; then
    echo "Missing migration directory for ${service}: ${MIGRATIONS_DIR}/${service}" >&2
    exit 1
  fi
  if [[ -n "${migration_script}" && "${migration_script}" != "-" && ! -f "${MIGRATION_SCRIPTS_DIR}/${migration_script}" ]]; then
    echo "Missing migration script for ${service}: ${MIGRATION_SCRIPTS_DIR}/${migration_script}" >&2
    exit 1
  fi
done

if [[ "${MIGRATIONS_DRY_RUN}" == "true" ]]; then
  echo "PostgreSQL migration dry run:"
  for item in "${migration_services[@]}"; do
    IFS=":" read -r service database migration_script <<<"${item}"
    migration_script="${migration_script:--}"
    count="$(find "${MIGRATIONS_DIR}/${service}" -maxdepth 1 -type f -name '*.up.sql' | wc -l | tr -d ' ')"
    echo "  ${service} -> ${database}: ${count} migration(s), script=${migration_script}"
  done
  exit 0
fi

compose_args=(docker compose --env-file "${ENV_FILE}")
if [[ -f "${RUNTIME_ENV_FILE}" ]]; then
  compose_args+=(--env-file "${RUNTIME_ENV_FILE}")
fi
if [[ -f "${DEPLOY_ENV_FILE}" ]]; then
  compose_args+=(--env-file "${DEPLOY_ENV_FILE}")
fi
compose_args+=(-f "${COMPOSE_FILE}")

"${compose_args[@]}" up -d postgres

postgres_container_id="$("${compose_args[@]}" ps -q postgres)"
if [[ -z "${postgres_container_id}" ]]; then
  echo "Unable to resolve postgres container id." >&2
  exit 1
fi

echo "Running PostgreSQL migrations through ${MIGRATION_CLIENT_IMAGE}."
for item in "${migration_services[@]}"; do
  IFS=":" read -r service database migration_script <<<"${item}"
  migration_script="${migration_script:-}"
  echo "Migrating ${service} -> ${database}"
  docker run --rm \
    --network "container:${postgres_container_id}" \
    --entrypoint /bin/sh \
    -e "POSTGRES_USER=${POSTGRES_USER}" \
    -e "POSTGRES_PASSWORD=${POSTGRES_PASSWORD}" \
    -e "PGHOST=127.0.0.1" \
    -e "PGPORT=5432" \
    -e "TARGET_DATABASE=${database}" \
    "${MIGRATION_CLIENT_IMAGE}" \
    -ec '
      export PGPASSWORD="$POSTGRES_PASSWORD"
      exists="$(psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname = '\''$TARGET_DATABASE'\''" | tr -d "[:space:]")"
      if [ "$exists" != "1" ]; then
        createdb -U "$POSTGRES_USER" --owner "$POSTGRES_USER" "$TARGET_DATABASE"
      fi
    '
  if [[ -n "${migration_script}" && "${migration_script}" != "-" ]]; then
    container_script="/migration-scripts/${migration_script}"
    script_mount=("${MIGRATION_SCRIPTS_DIR}:/migration-scripts:ro")
  else
    container_script="/scripts/apply-postgres-migrations.sh"
    script_mount=("${APP_DIR}/scripts/apply-postgres-migrations.sh:/scripts/apply-postgres-migrations.sh:ro")
  fi

  docker run --rm \
    --network "container:${postgres_container_id}" \
    --entrypoint /bin/sh \
    -e "SERVICE_NAME=${service}" \
    -e "POSTGRES_DB=${database}" \
    -e "POSTGRES_USER=${POSTGRES_USER}" \
    -e "POSTGRES_PASSWORD=${POSTGRES_PASSWORD}" \
    -e "PGHOST=127.0.0.1" \
    -e "PGPORT=5432" \
    -v "${MIGRATIONS_DIR}:/migrations:ro" \
    -v "${script_mount[@]}" \
    "${MIGRATION_CLIENT_IMAGE}" \
    "${container_script}"

  if [[ "${service}" == "token-service" && "${SEED_TOKEN_SERVICE_ACCOUNTS:-true}" == "true" ]]; then
    seed_script="${MIGRATION_SCRIPTS_DIR}/001_token_service_seed_services.sh"
    if [[ ! -f "${seed_script}" ]]; then
      echo "Missing token-service seed script: ${seed_script}" >&2
      exit 1
    fi
    echo "Seeding token-service service accounts"
    docker run --rm \
      --network "container:${postgres_container_id}" \
      --entrypoint /bin/sh \
      -e "POSTGRES_DB=${database}" \
      -e "POSTGRES_USER=${POSTGRES_USER}" \
      -e "POSTGRES_PASSWORD=${POSTGRES_PASSWORD}" \
      -e "PGHOST=127.0.0.1" \
      -e "PGPORT=5432" \
      -e "AUTH_SERVICE_TOKEN_SERVICE_SECRET=${AUTH_SERVICE_TOKEN_SERVICE_SECRET:?AUTH_SERVICE_TOKEN_SERVICE_SECRET is required}" \
      -e "API_GATEWAY_TOKEN_SERVICE_SECRET=${API_GATEWAY_TOKEN_SERVICE_SECRET:?API_GATEWAY_TOKEN_SERVICE_SECRET is required}" \
      -e "ACTIVITY_SERVICE_TOKEN_SERVICE_SECRET=${ACTIVITY_SERVICE_TOKEN_SERVICE_SECRET:?ACTIVITY_SERVICE_TOKEN_SERVICE_SECRET is required}" \
      -e "EXCURSION_SERVICE_TOKEN_SERVICE_SECRET=${EXCURSION_SERVICE_TOKEN_SERVICE_SECRET:?EXCURSION_SERVICE_TOKEN_SERVICE_SECRET is required}" \
      -e "FEED_SERVICE_TOKEN_SERVICE_SECRET=${FEED_SERVICE_TOKEN_SERVICE_SECRET:?FEED_SERVICE_TOKEN_SERVICE_SECRET is required}" \
      -e "GUIDE_SERVICE_TOKEN_SERVICE_SECRET=${GUIDE_SERVICE_TOKEN_SERVICE_SECRET:?GUIDE_SERVICE_TOKEN_SERVICE_SECRET is required}" \
      -e "PLACE_SERVICE_TOKEN_SERVICE_SECRET=${PLACE_SERVICE_TOKEN_SERVICE_SECRET:?PLACE_SERVICE_TOKEN_SERVICE_SECRET is required}" \
      -e "SAVED_SERVICE_TOKEN_SERVICE_SECRET=${SAVED_SERVICE_TOKEN_SERVICE_SECRET:?SAVED_SERVICE_TOKEN_SERVICE_SECRET is required}" \
      -e "SUPPORT_SERVICE_TOKEN_SERVICE_SECRET=${SUPPORT_SERVICE_TOKEN_SERVICE_SECRET:?SUPPORT_SERVICE_TOKEN_SERVICE_SECRET is required}" \
      -e "USER_SERVICE_TOKEN_SERVICE_SECRET=${USER_SERVICE_TOKEN_SERVICE_SECRET:?USER_SERVICE_TOKEN_SERVICE_SECRET is required}" \
      -v "${seed_script}:/scripts/001_token_service_seed_services.sh:ro" \
      "${MIGRATION_CLIENT_IMAGE}" \
      /scripts/001_token_service_seed_services.sh
  fi
done

echo "PostgreSQL migrations completed."
