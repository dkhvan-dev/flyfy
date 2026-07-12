#!/usr/bin/env bash
set -euo pipefail

APP_DIR="${APP_DIR:-/opt/inflap}"
ENV_FILE="${ENV_FILE:-${APP_DIR}/env/test.env}"
RUNTIME_ENV_FILE="${RUNTIME_ENV_FILE:-${APP_DIR}/env/runtime.env}"
DEPLOY_ENV_FILE="${DEPLOY_ENV_FILE:-${APP_DIR}/env/deploy.env}"
COMPOSE_FILE="${COMPOSE_FILE:-${APP_DIR}/docker-compose.test.yml}"

SMOKE_DRY_RUN="${SMOKE_DRY_RUN:-false}"
SMOKE_SKIP_DOCKER="${SMOKE_SKIP_DOCKER:-false}"
SMOKE_TIMEOUT_SECONDS="${SMOKE_TIMEOUT_SECONDS:-10}"
SMOKE_RETRIES="${SMOKE_RETRIES:-12}"
SMOKE_RETRY_DELAY_SECONDS="${SMOKE_RETRY_DELAY_SECONDS:-5}"
SMOKE_REQUIRED_CONSECUTIVE_PASSES="${SMOKE_REQUIRED_CONSECUTIVE_PASSES:-3}"
SMOKE_ENDPOINTS="${SMOKE_ENDPOINTS:-/health}"
SMOKE_ALLOW_EXITED_SERVICES="${SMOKE_ALLOW_EXITED_SERVICES:-minio-mc,sticker-default-stickers-seeder}"

for name in \
  SMOKE_TIMEOUT_SECONDS \
  SMOKE_RETRIES \
  SMOKE_RETRY_DELAY_SECONDS \
  SMOKE_REQUIRED_CONSECUTIVE_PASSES
do
  if [[ ! "${!name}" =~ ^[1-9][0-9]*$ ]]; then
    echo "${name} must be a positive integer." >&2
    exit 1
  fi
done
if ((SMOKE_REQUIRED_CONSECUTIVE_PASSES > SMOKE_RETRIES)); then
  echo "SMOKE_REQUIRED_CONSECUTIVE_PASSES cannot exceed SMOKE_RETRIES." >&2
  exit 1
fi

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

compose_env_args=(--env-file "${ENV_FILE}")
if [[ -f "${RUNTIME_ENV_FILE}" ]]; then
  compose_env_args+=(--env-file "${RUNTIME_ENV_FILE}")
fi
if [[ -f "${DEPLOY_ENV_FILE}" ]]; then
  compose_env_args+=(--env-file "${DEPLOY_ENV_FILE}")
fi

if [[ "${SMOKE_SKIP_DOCKER}" != "true" ]]; then
  docker compose \
    "${compose_env_args[@]}" \
    -f "${COMPOSE_FILE}" \
    config --quiet

  if ! command -v jq >/dev/null 2>&1; then
    echo "jq is required for strict compose state validation." >&2
    exit 1
  fi

  compose_config_json="$(
    docker compose \
      "${compose_env_args[@]}" \
      -f "${COMPOSE_FILE}" \
      config --format json
  )"
  expected_services_json="$(
    jq -c '
      [
        .services
        | to_entries[]
        | select(((.value.profiles // []) | length) == 0)
        | .key
      ]
    ' <<<"${compose_config_json}"
  )"
  if [[ "${expected_services_json}" == "[]" ]]; then
    echo "Compose config contains no active services." >&2
    exit 1
  fi
  allowed_exited_services_json="$(
    jq -c --arg configured "${SMOKE_ALLOW_EXITED_SERVICES}" '
      (
        [
          .services
          | to_entries[]
          | select(((.value.profiles // []) | length) == 0)
          | select((.value.labels["com.inflap.smoke.allow-exited"] // "false") == "true")
          | .key
        ]
        + (
          $configured
          | split(",")
          | map(gsub("^ +| +$"; ""))
          | map(select(length > 0))
        )
      )
      | unique
    ' <<<"${compose_config_json}"
  )"

  compose_ready="false"
  unhealthy="compose state was not checked"
  consecutive_passes=0
  for ((attempt = 1; attempt <= SMOKE_RETRIES; attempt++)); do
    ps_json="$(
      docker compose \
        "${compose_env_args[@]}" \
        -f "${COMPOSE_FILE}" \
        ps --all --format json
    )"
    unhealthy="$(
      jq -rs \
        --argjson allowed_exited "${allowed_exited_services_json}" \
        --argjson expected "${expected_services_json}" '
        (
          if length == 1 and (.[0] | type) == "array" then .[0] else . end
        ) as $reported
        | (
            $reported
            | map(
                select(
                  (.Service // "") as $service
                  | $expected
                  | index($service)
                )
              )
          ) as $rows
        | (
            ($expected - ($rows | map(.Service // "") | unique))[]
            | "\(.): container is missing"
          ),
          (
            $rows[]
            | .Service as $service
            | (.State // "") as $state
            | (.Health // "") as $health
            | ((.ExitCode // 1) | tostring) as $exit_code
            | select(
                (
                  $state != "running"
                  and (
                    $state != "exited"
                    or (($allowed_exited | index($service)) == null)
                    or $exit_code != "0"
                  )
                )
                or (
                  $state == "running"
                  and $health != ""
                  and $health != "healthy"
                )
              )
            | "\($service): state=\($state) health=\($health) exit_code=\($exit_code) status=\(.Status // "")"
          )
      ' <<<"${ps_json}"
    )"
    if [[ -z "${unhealthy}" ]]; then
      consecutive_passes=$((consecutive_passes + 1))
      if ((consecutive_passes >= SMOKE_REQUIRED_CONSECUTIVE_PASSES)); then
        compose_ready="true"
        break
      fi
      echo "Compose services passed stability check ${consecutive_passes}/${SMOKE_REQUIRED_CONSECUTIVE_PASSES}."
    else
      consecutive_passes=0
    fi
    if ((attempt < SMOKE_RETRIES)); then
      if [[ -n "${unhealthy}" ]]; then
        echo "Compose services are not ready; retrying in ${SMOKE_RETRY_DELAY_SECONDS}s (${attempt}/${SMOKE_RETRIES}):"
        echo "${unhealthy}"
      fi
      sleep "${SMOKE_RETRY_DELAY_SECONDS}"
    fi
  done
  if [[ "${compose_ready}" != "true" ]]; then
    echo "Unexpected compose service state after ${SMOKE_RETRIES} attempt(s):" >&2
    echo "${unhealthy}" >&2
    exit 1
  fi

  docker compose \
    "${compose_env_args[@]}" \
    -f "${COMPOSE_FILE}" \
    ps
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

  passed="false"
  status="curl_error"
  for ((attempt = 1; attempt <= SMOKE_RETRIES; attempt++)); do
    if status="$(
      curl -sS \
        --max-time "${SMOKE_TIMEOUT_SECONDS}" \
        -o "${tmp_response}" \
        -w '%{http_code}' \
        "${url}"
    )" && [[ "${status}" =~ ^2[0-9][0-9]$ ]]; then
      passed="true"
      break
    fi
    if ((attempt < SMOKE_RETRIES)); then
      echo "Smoke endpoint not ready: ${url} status=${status}; retrying in ${SMOKE_RETRY_DELAY_SECONDS}s (${attempt}/${SMOKE_RETRIES})."
      sleep "${SMOKE_RETRY_DELAY_SECONDS}"
    fi
  done
  if [[ "${passed}" != "true" ]]; then
    echo "Smoke endpoint failed: ${url} returned ${status} after ${SMOKE_RETRIES} attempt(s)." >&2
    sed -n '1,40p' "${tmp_response}" >&2
    exit 1
  fi
  echo "Smoke endpoint passed: ${url} -> HTTP ${status}"
done < <(printf '%s\n' "${SMOKE_ENDPOINTS}" | tr ',' '\n')

echo "Smoke check completed."
