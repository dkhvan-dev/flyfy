#!/usr/bin/env bash
set -euo pipefail

APP_DIR="${APP_DIR:-/opt/inflap}"
BACKUP_DIR="${BACKUP_DIR:-${APP_DIR}/backups/postgres}"
ENV_FILE="${ENV_FILE:-${APP_DIR}/env/test.env}"
RUNTIME_ENV_FILE="${RUNTIME_ENV_FILE:-${APP_DIR}/env/runtime.env}"
DEPLOY_ENV_FILE="${DEPLOY_ENV_FILE:-${APP_DIR}/env/deploy.env}"
COMPOSE_FILE="${COMPOSE_FILE:-${APP_DIR}/docker-compose.test.yml}"
RETENTION_DAYS="${RETENTION_DAYS:-7}"

if [[ ! "${RETENTION_DAYS}" =~ ^[1-9][0-9]*$ ]]; then
  echo "RETENTION_DAYS must be a positive integer." >&2
  exit 1
fi

umask 077
mkdir -p "${BACKUP_DIR}"
chmod 700 "${BACKUP_DIR}"

timestamp="$(date -u +%Y%m%d-%H%M%S)"
backup_path="${BACKUP_DIR}/inflap-test-${timestamp}-$$.sql.gz"
backup_tmp="${backup_path}.tmp"
trap 'rm -f "${backup_tmp}"' EXIT

compose_env_args=(--env-file "${ENV_FILE}")
if [[ -f "${RUNTIME_ENV_FILE}" ]]; then
  compose_env_args+=(--env-file "${RUNTIME_ENV_FILE}")
fi
if [[ -f "${DEPLOY_ENV_FILE}" ]]; then
  compose_env_args+=(--env-file "${DEPLOY_ENV_FILE}")
fi

docker compose \
  "${compose_env_args[@]}" \
  -f "${COMPOSE_FILE}" \
  exec -T postgres pg_dumpall -U postgres \
  | gzip -9 >"${backup_tmp}"

if [[ ! -s "${backup_tmp}" ]]; then
  echo "PostgreSQL backup is empty: ${backup_tmp}" >&2
  exit 1
fi
gzip -t "${backup_tmp}"
mv "${backup_tmp}" "${backup_path}"
trap - EXIT

find "${BACKUP_DIR}" -type f -name 'inflap-test-*.sql.gz' -mtime +"${RETENTION_DAYS}" -delete

echo "PostgreSQL backup created: ${backup_path}"
