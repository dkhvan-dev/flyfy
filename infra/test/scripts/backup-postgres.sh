#!/usr/bin/env bash
set -euo pipefail

APP_DIR="${APP_DIR:-/opt/inflap}"
BACKUP_DIR="${BACKUP_DIR:-${APP_DIR}/backups/postgres}"
ENV_FILE="${ENV_FILE:-${APP_DIR}/env/test.env}"
DEPLOY_ENV_FILE="${DEPLOY_ENV_FILE:-${APP_DIR}/env/deploy.env}"
COMPOSE_FILE="${COMPOSE_FILE:-${APP_DIR}/docker-compose.test.yml}"
RETENTION_DAYS="${RETENTION_DAYS:-7}"

mkdir -p "${BACKUP_DIR}"

timestamp="$(date -u +%Y%m%d-%H%M%S)"
backup_path="${BACKUP_DIR}/inflap-test-${timestamp}.sql.gz"

docker compose \
  --env-file "${ENV_FILE}" \
  --env-file "${DEPLOY_ENV_FILE}" \
  -f "${COMPOSE_FILE}" \
  exec -T postgres pg_dumpall -U postgres \
  | gzip -9 >"${backup_path}"

find "${BACKUP_DIR}" -type f -name 'inflap-test-*.sql.gz' -mtime +"${RETENTION_DAYS}" -delete

echo "PostgreSQL backup created: ${backup_path}"
