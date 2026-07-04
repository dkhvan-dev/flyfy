#!/usr/bin/env bash
set -euo pipefail

APP_DIR="${APP_DIR:-/opt/inflap}"
ENV_FILE="${ENV_FILE:-${APP_DIR}/env/test.env}"
GHCR_ENV_FILE="${GHCR_ENV_FILE:-${APP_DIR}/env/ghcr.env}"
DEPLOY_ENV_FILE="${DEPLOY_ENV_FILE:-${APP_DIR}/env/deploy.env}"
COMPOSE_FILE="${COMPOSE_FILE:-${APP_DIR}/docker-compose.test.yml}"

REQUESTED_IMAGE_REGISTRY="${IMAGE_REGISTRY:-}"
REQUESTED_IMAGE_NAMESPACE="${IMAGE_NAMESPACE:-}"
REQUESTED_IMAGE_PREFIX="${IMAGE_PREFIX:-}"
REQUESTED_IMAGE_TAG="${IMAGE_TAG:-}"
REQUIRE_GHCR_AUTH="${REQUIRE_GHCR_AUTH:-false}"

cd "${APP_DIR}"

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Missing runtime env file: ${ENV_FILE}" >&2
  exit 1
fi

set -a
# shellcheck disable=SC1090
. "${ENV_FILE}"
if [[ -f "${GHCR_ENV_FILE}" ]]; then
  # shellcheck disable=SC1090
  . "${GHCR_ENV_FILE}"
fi
set +a

IMAGE_REGISTRY="${REQUESTED_IMAGE_REGISTRY:-${IMAGE_REGISTRY:-ghcr.io}}"
IMAGE_NAMESPACE="${REQUESTED_IMAGE_NAMESPACE:-${IMAGE_NAMESPACE:-}}"
IMAGE_PREFIX="${REQUESTED_IMAGE_PREFIX:-${IMAGE_PREFIX:-inflap-}}"
IMAGE_TAG="${REQUESTED_IMAGE_TAG:-${IMAGE_TAG:-}}"

umask 077
{
  echo "IMAGE_REGISTRY=${IMAGE_REGISTRY}"
  echo "IMAGE_NAMESPACE=${IMAGE_NAMESPACE:?IMAGE_NAMESPACE is required}"
  echo "IMAGE_PREFIX=${IMAGE_PREFIX}"
  echo "IMAGE_TAG=${IMAGE_TAG:?IMAGE_TAG is required}"
} >"${DEPLOY_ENV_FILE}"

if [[ -n "${GHCR_READ_TOKEN:-}" && -n "${GHCR_USERNAME:-}" ]]; then
  echo "Logging in to GHCR as ${GHCR_USERNAME}."
  printf '%s' "${GHCR_READ_TOKEN}" | docker login ghcr.io -u "${GHCR_USERNAME}" --password-stdin
elif [[ "${REQUIRE_GHCR_AUTH}" == "true" ]]; then
  echo "Missing GHCR credentials. Set GHCR_USERNAME and GHCR_READ_TOKEN GitHub environment secrets, or create ${GHCR_ENV_FILE} on the server." >&2
  exit 1
elif [[ "${IMAGE_REGISTRY}" == "ghcr.io" ]]; then
  echo "GHCR credentials are not configured; pulling anonymously. Private GHCR images will fail." >&2
fi

if [[ -f "${DEPLOY_ENV_FILE}.previous" ]]; then
  cp "${DEPLOY_ENV_FILE}.previous" "${DEPLOY_ENV_FILE}.rollback"
fi
cp "${DEPLOY_ENV_FILE}" "${DEPLOY_ENV_FILE}.previous"

docker compose \
  --env-file "${ENV_FILE}" \
  --env-file "${DEPLOY_ENV_FILE}" \
  -f "${COMPOSE_FILE}" \
  pull

if [[ "${RUN_POSTGRES_MIGRATIONS:-true}" == "true" ]]; then
  APP_DIR="${APP_DIR}" \
    ENV_FILE="${ENV_FILE}" \
    DEPLOY_ENV_FILE="${DEPLOY_ENV_FILE}" \
    COMPOSE_FILE="${COMPOSE_FILE}" \
    "${APP_DIR}/scripts/migrate-postgres.sh"
else
  echo "Skipping PostgreSQL migrations because RUN_POSTGRES_MIGRATIONS=false."
fi

docker compose \
  --env-file "${ENV_FILE}" \
  --env-file "${DEPLOY_ENV_FILE}" \
  -f "${COMPOSE_FILE}" \
  up -d --remove-orphans

docker compose \
  --env-file "${ENV_FILE}" \
  --env-file "${DEPLOY_ENV_FILE}" \
  -f "${COMPOSE_FILE}" \
  ps

if command -v curl >/dev/null 2>&1 && [[ -n "${TEST_API_HOST:-}" ]]; then
  health_url="https://${TEST_API_HOST}/health"
  health_retries="${HEALTHCHECK_RETRIES:-36}"
  health_delay_seconds="${HEALTHCHECK_RETRY_DELAY_SECONDS:-5}"

  echo "Checking public gateway health: ${health_url}"
  for ((attempt = 1; attempt <= health_retries; attempt++)); do
    if curl -fsS "${health_url}" >/dev/null; then
      echo "Public gateway health check passed."
      break
    fi

    if ((attempt == health_retries)); then
      echo "Public gateway health check failed after ${health_retries} attempts." >&2
      exit 1
    fi

    echo "Public gateway health check failed; retrying in ${health_delay_seconds}s (${attempt}/${health_retries})."
    sleep "${health_delay_seconds}"
  done
fi

echo "Deploy completed for ${IMAGE_NAMESPACE}/${IMAGE_PREFIX:-inflap-}*:${IMAGE_TAG}"
