#!/usr/bin/env bash
set -euo pipefail

APP_DIR="${APP_DIR:-/opt/inflap}"
ENV_FILE="${ENV_FILE:-${APP_DIR}/env/test.env}"
DEPLOY_ENV_FILE="${DEPLOY_ENV_FILE:-${APP_DIR}/env/deploy.env}"
COMPOSE_FILE="${COMPOSE_FILE:-${APP_DIR}/docker-compose.test.yml}"

SMOKE_DRY_RUN="${SMOKE_DRY_RUN:-false}"
SMOKE_SKIP_DOCKER="${SMOKE_SKIP_DOCKER:-false}"
SMOKE_TIMEOUT_SECONDS="${SMOKE_TIMEOUT_SECONDS:-10}"
SMOKE_ENDPOINTS="${SMOKE_ENDPOINTS:-/health}"
SMOKE_ALLOW_EXITED_SERVICES="${SMOKE_ALLOW_EXITED_SERVICES:-minio-mc}"

if [[ -f "${ENV_FILE}" ]]; then
  set -a
  # shellcheck disable=SC1090
  . "${ENV_FILE}"
  set +a
fi

base_url="${SMOKE_BASE_URL:-}"
if [[ -z "${base_url}" && -n "${TEST_API_HOST:-}" ]]; then
  base_url="https://${TEST_API_HOST}"
fi
if [[ -z "${base_url}" ]]; then
  echo "Set SMOKE_BASE_URL or TEST_API_HOST in ${ENV_FILE}." >&2
  exit 1
fi
base_url="${base_url%/}"

cd "${APP_DIR}"

if [[ "${SMOKE_SKIP_DOCKER}" != "true" ]]; then
  docker compose \
    --env-file "${ENV_FILE}" \
    --env-file "${DEPLOY_ENV_FILE}" \
    -f "${COMPOSE_FILE}" \
    config --quiet

  docker compose \
    --env-file "${ENV_FILE}" \
    --env-file "${DEPLOY_ENV_FILE}" \
    -f "${COMPOSE_FILE}" \
    ps

  if command -v jq >/dev/null 2>&1; then
    ps_json="$(
      docker compose \
        --env-file "${ENV_FILE}" \
        --env-file "${DEPLOY_ENV_FILE}" \
        -f "${COMPOSE_FILE}" \
        ps --all --format json
    )"
    unhealthy="$(
      jq -rs --arg allowed ",${SMOKE_ALLOW_EXITED_SERVICES}," '
        if length == 1 and (.[0] | type) == "array" then .[0] else . end
        | .[]
        | .Service as $service
        | (.State // "") as $state
        | (.Health // "") as $health
        | select(
            (
              $state != "running"
              and (
                $state != "exited"
                or (($allowed | contains("," + $service + ",")) | not)
              )
            )
            or (
              $state == "running"
              and $health != ""
              and $health != "healthy"
            )
          )
        | "\($service): state=\($state) health=\($health) status=\(.Status // "")"
      ' <<<"${ps_json}"
    )"
    if [[ -n "${unhealthy}" ]]; then
      echo "Unexpected compose service state:" >&2
      echo "${unhealthy}" >&2
      exit 1
    fi
  else
    echo "jq is not installed; skipped strict compose state validation."
  fi
fi

tmp_response="$(mktemp)"
trap 'rm -f "${tmp_response}"' EXIT

while IFS= read -r endpoint; do
  endpoint="${endpoint#"${endpoint%%[![:space:]]*}"}"
  endpoint="${endpoint%"${endpoint##*[![:space:]]}"}"
  [[ -z "${endpoint}" ]] && continue
  [[ "${endpoint}" == /* ]] || endpoint="/${endpoint}"

  url="${base_url}${endpoint}"
  if [[ "${SMOKE_DRY_RUN}" == "true" ]]; then
    echo "Would check endpoint: ${url}"
    continue
  fi

  status="$(
    curl -sS \
      --max-time "${SMOKE_TIMEOUT_SECONDS}" \
      -o "${tmp_response}" \
      -w '%{http_code}' \
      "${url}"
  )"
  if [[ ! "${status}" =~ ^2[0-9][0-9]$ ]]; then
    echo "Smoke endpoint failed: ${url} returned HTTP ${status}" >&2
    sed -n '1,40p' "${tmp_response}" >&2
    exit 1
  fi
  echo "Smoke endpoint passed: ${url} -> HTTP ${status}"
done < <(printf '%s\n' "${SMOKE_ENDPOINTS}" | tr ',' '\n')

echo "Smoke check completed."
