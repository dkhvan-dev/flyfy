#!/usr/bin/env bash
set -euo pipefail

APP_DIR="${APP_DIR:-/opt/inflap}"
ENV_FILE="${ENV_FILE:-${APP_DIR}/env/test.env}"
DEPLOY_ENV_FILE="${DEPLOY_ENV_FILE:-${APP_DIR}/env/deploy.env}"
COMPOSE_FILE="${COMPOSE_FILE:-${APP_DIR}/docker-compose.test.yml}"

REQUESTED_IMAGE_REGISTRY="${IMAGE_REGISTRY:-}"
REQUESTED_IMAGE_NAMESPACE="${IMAGE_NAMESPACE:-}"
REQUESTED_IMAGE_PREFIX="${IMAGE_PREFIX:-}"
REQUESTED_IMAGE_TAG="${IMAGE_TAG:-}"

cd "${APP_DIR}"

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Missing runtime env file: ${ENV_FILE}" >&2
  exit 1
fi

set -a
# shellcheck disable=SC1090
. "${ENV_FILE}"
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
  printf '%s' "${GHCR_READ_TOKEN}" | docker login ghcr.io -u "${GHCR_USERNAME}" --password-stdin
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
  echo "Checking public gateway health: https://${TEST_API_HOST}/health"
  curl -fsS --retry 12 --retry-delay 5 "https://${TEST_API_HOST}/health" >/dev/null
fi

echo "Deploy completed for ${IMAGE_NAMESPACE}/${IMAGE_PREFIX:-inflap-}*:${IMAGE_TAG}"
