#!/usr/bin/env bash
set -euo pipefail

APP_DIR="${APP_DIR:-/opt/inflap}"
ENV_FILE="${ENV_FILE:-${APP_DIR}/env/test.env}"
DEPLOY_ENV_FILE="${DEPLOY_ENV_FILE:-${APP_DIR}/env/deploy.env}"
COMPOSE_FILE="${COMPOSE_FILE:-${APP_DIR}/docker-compose.test.yml}"

backup_path="${1:-}"

if [[ -z "${backup_path}" ]]; then
  echo "Usage: $0 /opt/inflap/backups/postgres/inflap-test-YYYYmmdd-HHMMSS.sql.gz" >&2
  exit 1
fi

if [[ ! -f "${backup_path}" ]]; then
  echo "Backup file does not exist: ${backup_path}" >&2
  exit 1
fi

echo "This restore imports into the current test PostgreSQL container."
echo "It is intended for test/stage only. Press Ctrl+C within 10 seconds to abort."
sleep 10

gzip -dc "${backup_path}" | docker compose \
  --env-file "${ENV_FILE}" \
  --env-file "${DEPLOY_ENV_FILE}" \
  -f "${COMPOSE_FILE}" \
  exec -T postgres psql -U postgres -d postgres

echo "PostgreSQL restore completed from: ${backup_path}"
