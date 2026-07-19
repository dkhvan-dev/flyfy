#!/usr/bin/env bash
set -euo pipefail

APP_DIR="${APP_DIR:-/opt/inflap}"
ENV_FILE="${ENV_FILE:-${APP_DIR}/env/test.env}"
GHCR_ENV_FILE="${GHCR_ENV_FILE:-${APP_DIR}/env/ghcr.env}"
RUNTIME_ENV_FILE="${RUNTIME_ENV_FILE:-${APP_DIR}/env/runtime.env}"
DEPLOY_ENV_FILE="${DEPLOY_ENV_FILE:-${APP_DIR}/env/deploy.env}"
COMPOSE_FILE="${COMPOSE_FILE:-${APP_DIR}/docker-compose.test.yml}"
PREVIOUS_RUNTIME_ENV_FILE="${PREVIOUS_RUNTIME_ENV_FILE:-${RUNTIME_ENV_FILE}.previous}"
PREVIOUS_DEPLOY_ENV_FILE="${PREVIOUS_DEPLOY_ENV_FILE:-${DEPLOY_ENV_FILE}.previous}"
PREVIOUS_COMPOSE_FILE="${PREVIOUS_COMPOSE_FILE:-${COMPOSE_FILE}.previous}"
ROLLBACK_COMPOSE_OVERRIDE_FILE="${ROLLBACK_COMPOSE_OVERRIDE_FILE:-${APP_DIR}/docker-compose.rollback.yml}"
ROLLBACK_IMAGE_NAMESPACE="${ROLLBACK_IMAGE_NAMESPACE:-inflap-rollback}"

REQUESTED_IMAGE_REGISTRY="${IMAGE_REGISTRY:-}"
REQUESTED_IMAGE_NAMESPACE="${IMAGE_NAMESPACE:-}"
REQUESTED_IMAGE_PREFIX="${IMAGE_PREFIX:-}"
REQUESTED_IMAGE_TAG="${IMAGE_TAG:-}"
REQUESTED_MTLS_MODE="${MTLS_MODE:-}"
REQUESTED_MTLS_CERT_GROUP_ID="${MTLS_CERT_GROUP_ID:-}"
REQUESTED_MTLS_SECRETS_DIR="${MTLS_SECRETS_DIR:-}"
REQUESTED_MTLS_CA_CERT_PATH="${MTLS_CA_CERT_PATH:-}"
REQUESTED_MTLS_AUTO_PROVISION_CERTS="${MTLS_AUTO_PROVISION_CERTS:-}"
REQUIRE_GHCR_AUTH="${REQUIRE_GHCR_AUTH:-false}"

restore_prepared_files_on_early_failure() {
  local exit_code=$?
  local restore_failed="false"
  trap - EXIT

  if [[ ${exit_code} -eq 0 ]]; then
    exit 0
  fi

  set +e
  if [[ -f "${PREVIOUS_COMPOSE_FILE}" ]]; then
    cp -p "${PREVIOUS_COMPOSE_FILE}" "${COMPOSE_FILE}" || restore_failed="true"
  fi
  if [[ -f "${PREVIOUS_RUNTIME_ENV_FILE}" ]]; then
    cp -p "${PREVIOUS_RUNTIME_ENV_FILE}" "${RUNTIME_ENV_FILE}" || restore_failed="true"
  fi

  if [[ "${restore_failed}" == "true" ]]; then
    echo "CRITICAL: deploy validation failed and previous deployment files could not be fully restored." >&2
  else
    echo "Deploy validation failed; previous deployment files were restored and running containers were not changed." >&2
  fi
  exit "${exit_code}"
}
trap restore_prepared_files_on_early_failure EXIT

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

# runtime.env is a Docker Compose env-file, not a shell script.
# Values such as "Inflap <otp@send.inflap.app>" are valid for Compose
# but invalid when executed through `source`, so keep it out of shell loading.

IMAGE_REGISTRY="${REQUESTED_IMAGE_REGISTRY:-${IMAGE_REGISTRY:-ghcr.io}}"
IMAGE_NAMESPACE="${REQUESTED_IMAGE_NAMESPACE:-${IMAGE_NAMESPACE:-}}"
IMAGE_PREFIX="${REQUESTED_IMAGE_PREFIX:-${IMAGE_PREFIX:-inflap-}}"
IMAGE_TAG="${REQUESTED_IMAGE_TAG:-${IMAGE_TAG:-}}"
MTLS_MODE="${REQUESTED_MTLS_MODE:-${MTLS_MODE:-disabled}}"
MTLS_CERT_GROUP_ID="${REQUESTED_MTLS_CERT_GROUP_ID:-${MTLS_CERT_GROUP_ID:-1001}}"
MTLS_SECRETS_DIR="${REQUESTED_MTLS_SECRETS_DIR:-${MTLS_SECRETS_DIR:-${APP_DIR}/secrets/mtls}}"
MTLS_CA_CERT_PATH="${REQUESTED_MTLS_CA_CERT_PATH:-${MTLS_CA_CERT_PATH:-${MTLS_SECRETS_DIR}/ca.crt}}"
MTLS_AUTO_PROVISION_CERTS="${REQUESTED_MTLS_AUTO_PROVISION_CERTS:-${MTLS_AUTO_PROVISION_CERTS:-false}}"
RUN_PRE_DEPLOY_BACKUP="${RUN_PRE_DEPLOY_BACKUP:-true}"
ROLLBACK_ON_FAILURE="${ROLLBACK_ON_FAILURE:-true}"
DEPLOY_SMOKE_RETRIES="${DEPLOY_SMOKE_RETRIES:-36}"
DEPLOY_SMOKE_RETRY_DELAY_SECONDS="${DEPLOY_SMOKE_RETRY_DELAY_SECONDS:-5}"
DEPLOY_DIAGNOSTIC_LOG_LINES="${DEPLOY_DIAGNOSTIC_LOG_LINES:-200}"

for name in DEPLOY_SMOKE_RETRIES DEPLOY_SMOKE_RETRY_DELAY_SECONDS DEPLOY_DIAGNOSTIC_LOG_LINES; do
  if [[ ! "${!name}" =~ ^[1-9][0-9]*$ ]]; then
    echo "${name} must be a positive integer." >&2
    exit 1
  fi
done
if (( DEPLOY_DIAGNOSTIC_LOG_LINES > 2000 )); then
  echo "DEPLOY_DIAGNOSTIC_LOG_LINES must not exceed 2000." >&2
  exit 1
fi
for name in RUN_PRE_DEPLOY_BACKUP ROLLBACK_ON_FAILURE MTLS_AUTO_PROVISION_CERTS; do
  if [[ "${!name}" != "true" && "${!name}" != "false" ]]; then
    echo "${name} must be true or false." >&2
    exit 1
  fi
done

compose_env_args=()
build_compose_env_args() {
  compose_env_args=(--env-file "${ENV_FILE}")
  if [[ -f "${RUNTIME_ENV_FILE}" ]]; then
    compose_env_args+=(--env-file "${RUNTIME_ENV_FILE}")
  fi
  if [[ -f "${DEPLOY_ENV_FILE}" ]]; then
    compose_env_args+=(--env-file "${DEPLOY_ENV_FILE}")
  fi
}

compose() {
  docker compose "${compose_env_args[@]}" -f "${COMPOSE_FILE}" "$@"
}

rollback_compose() {
  docker compose \
    "${compose_env_args[@]}" \
    -f "${COMPOSE_FILE}" \
    -f "${ROLLBACK_COMPOSE_OVERRIDE_FILE}" \
    "$@"
}

capture_failed_deploy_diagnostics() {
  local ps_json
  local failed_services
  local service
  local container_ids
  local container_id

  echo "Capturing failed deployment diagnostics before rollback."
  if ! ps_json="$(compose ps --all --format json)"; then
    echo "Unable to read Compose service state."
    return 0
  fi

  if ! jq -rs -r '
    if length == 1 and (.[0] | type) == "array" then .[0] else . end
    | .[]
    | "service=\(.Service // "unknown") state=\(.State // "unknown") health=\(.Health // "none") exit_code=\(.ExitCode // "unknown") status=\(.Status // "unknown")"
  ' <<<"${ps_json}"; then
    echo "Unable to parse Compose service state. Raw state follows:"
    printf '%s\n' "${ps_json}"
    return 0
  fi

  failed_services="$(
    jq -rs -r '
      if length == 1 and (.[0] | type) == "array" then .[0] else . end
      | .[]
      | ((.State // "") | ascii_downcase) as $state
      | ((.Health // "") | ascii_downcase) as $health
      | ((.ExitCode // 0) | tonumber? // 0) as $exit_code
      | select(
          ($health != "" and $health != "healthy") or
          $state == "restarting" or
          $state == "dead" or
          ($state == "exited" and $exit_code != 0)
        )
      | .Service // empty
    ' <<<"${ps_json}" | sort -u
  )"
  if [[ -z "${failed_services}" ]]; then
    echo "No unhealthy, restarting, dead, or failed Compose service was identified."
    return 0
  fi

  while IFS= read -r service; do
    if [[ -z "${service}" || ! "${service}" =~ ^[a-zA-Z0-9][a-zA-Z0-9_.-]*$ ]]; then
      continue
    fi
    echo "--- ${service}: recent logs (last ${DEPLOY_DIAGNOSTIC_LOG_LINES} lines) ---"
    compose logs --no-color --tail "${DEPLOY_DIAGNOSTIC_LOG_LINES}" "${service}" || true

    container_ids="$(compose ps --all -q "${service}" 2>/dev/null || true)"
    while IFS= read -r container_id; do
      if [[ -z "${container_id}" ]]; then
        continue
      fi
      docker inspect --format \
        'container={{.Name}} status={{.State.Status}} exit_code={{.State.ExitCode}} restarting={{.State.Restarting}} oom_killed={{.State.OOMKilled}} error={{json .State.Error}} health={{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' \
        "${container_id}" || true
      docker inspect --format \
        '{{if .State.Health}}{{range .State.Health.Log}}health end={{.End}} exit_code={{.ExitCode}} output={{json .Output}}{{println}}{{end}}{{end}}' \
        "${container_id}" || true
    done <<<"${container_ids}"
  done <<<"${failed_services}"
}

snapshot_rollback_images() {
  local ps_json
  local snapshot_rows
  local override_next="${ROLLBACK_COMPOSE_OVERRIDE_FILE}.next"
  local image_id
  local rollback_image

  ps_json="$(compose ps --all --format json)"
  snapshot_rows="$(
    jq -rs '
      if length == 1 and (.[0] | type) == "array" then .[0] else . end
      | map(select((.Service // "") != "" and (.ID // .Id // "") != ""))
      | unique_by(.Service)
      | .[]
      | [(.Service // ""), (.ID // .Id // "")]
      | @tsv
    ' <<<"${ps_json}"
  )"
  if [[ -z "${snapshot_rows}" ]]; then
    rm -f "${override_next}" "${ROLLBACK_COMPOSE_OVERRIDE_FILE}"
    echo "No existing Compose containers were found; image rollback is unavailable for this first deployment."
    return 0
  fi

  printf 'services:\n' >"${override_next}"
  while IFS=$'\t' read -r service container_id; do
    if [[ ! "${service}" =~ ^[a-z0-9][a-z0-9_.-]*$ ]]; then
      echo "Unsafe Compose service name in rollback snapshot: ${service}" >&2
      return 1
    fi
    image_id="$(docker inspect --format '{{.Image}}' "${container_id}")"
    rollback_image="${ROLLBACK_IMAGE_NAMESPACE}/${service}:previous"
    docker image tag "${image_id}" "${rollback_image}"
    printf '  %s:\n    image: %s\n' "${service}" "${rollback_image}" >>"${override_next}"
  done <<<"${snapshot_rows}"
  mv "${override_next}" "${ROLLBACK_COMPOSE_OVERRIDE_FILE}"
  echo "Rollback image snapshot created: ${ROLLBACK_COMPOSE_OVERRIDE_FILE}"
}

run_smoke_check() {
  APP_DIR="${APP_DIR}" \
    ENV_FILE="${ENV_FILE}" \
    RUNTIME_ENV_FILE="${RUNTIME_ENV_FILE}" \
    DEPLOY_ENV_FILE="${DEPLOY_ENV_FILE}" \
    COMPOSE_FILE="${COMPOSE_FILE}" \
    SMOKE_RETRIES="${DEPLOY_SMOKE_RETRIES}" \
    SMOKE_RETRY_DELAY_SECONDS="${DEPLOY_SMOKE_RETRY_DELAY_SECONDS}" \
    "${APP_DIR}/scripts/smoke-check.sh"
}

deployment_started="false"
deployment_succeeded="false"

rollback_on_failure() {
  local exit_code=$?
  trap - EXIT

  if [[ ${exit_code} -eq 0 || "${deployment_succeeded}" == "true" ]]; then
    exit "${exit_code}"
  fi

  set +e
  if [[ "${deployment_started}" == "true" ]]; then
    capture_failed_deploy_diagnostics >&2
  fi
  echo "Deploy failed; restoring the previous deployment configuration." >&2

  local restore_ready="true"
  for previous in \
    "${PREVIOUS_COMPOSE_FILE}" \
    "${PREVIOUS_DEPLOY_ENV_FILE}"
  do
    if [[ ! -f "${previous}" ]]; then
      echo "Rollback file is missing: ${previous}" >&2
      restore_ready="false"
    fi
  done
  if [[ -f "${RUNTIME_ENV_FILE}" && ! -f "${PREVIOUS_RUNTIME_ENV_FILE}" ]]; then
    echo "Rollback runtime env is missing: ${PREVIOUS_RUNTIME_ENV_FILE}" >&2
    restore_ready="false"
  fi
  if [[ "${deployment_started}" == "true" && ! -f "${ROLLBACK_COMPOSE_OVERRIDE_FILE}" ]]; then
    echo "Rollback image override is missing: ${ROLLBACK_COMPOSE_OVERRIDE_FILE}" >&2
    restore_ready="false"
  fi

  if [[ "${restore_ready}" == "true" ]]; then
    if ! cp -p "${PREVIOUS_COMPOSE_FILE}" "${COMPOSE_FILE}" || \
      ! cp -p "${PREVIOUS_DEPLOY_ENV_FILE}" "${DEPLOY_ENV_FILE}"; then
      echo "CRITICAL: failed to restore previous Compose or deploy env file." >&2
      exit "${exit_code}"
    fi
    if [[ -f "${PREVIOUS_RUNTIME_ENV_FILE}" ]]; then
      if ! cp -p "${PREVIOUS_RUNTIME_ENV_FILE}" "${RUNTIME_ENV_FILE}"; then
        echo "CRITICAL: failed to restore previous runtime env file." >&2
        exit "${exit_code}"
      fi
    fi
    build_compose_env_args

    if [[ "${deployment_started}" == "true" && "${ROLLBACK_ON_FAILURE}" == "true" ]]; then
      echo "Starting automatic container rollback. Database changes are not reverted automatically."
      if rollback_compose config --quiet && \
        rollback_compose up -d --remove-orphans && \
        run_smoke_check; then
        echo "Automatic container rollback completed successfully." >&2
      else
        echo "CRITICAL: automatic container rollback failed; manual intervention is required." >&2
      fi
    else
      echo "Previous deployment files restored; running containers were not changed." >&2
    fi
  else
    echo "CRITICAL: rollback configuration is incomplete; running containers were left untouched where possible." >&2
  fi

  exit "${exit_code}"
}
trap rollback_on_failure EXIT

umask 077
if [[ -f "${DEPLOY_ENV_FILE}" ]]; then
  cp -p "${DEPLOY_ENV_FILE}" "${PREVIOUS_DEPLOY_ENV_FILE}"
else
  rm -f "${PREVIOUS_DEPLOY_ENV_FILE}"
fi
deploy_env_next="${DEPLOY_ENV_FILE}.next"
{
  echo "IMAGE_REGISTRY=${IMAGE_REGISTRY}"
  echo "IMAGE_NAMESPACE=${IMAGE_NAMESPACE:?IMAGE_NAMESPACE is required}"
  echo "IMAGE_PREFIX=${IMAGE_PREFIX}"
  echo "IMAGE_TAG=${IMAGE_TAG:?IMAGE_TAG is required}"
} >"${deploy_env_next}"
mv "${deploy_env_next}" "${DEPLOY_ENV_FILE}"

if [[ -n "${GHCR_READ_TOKEN:-}" && -n "${GHCR_USERNAME:-}" ]]; then
  echo "Logging in to GHCR as ${GHCR_USERNAME}."
  printf '%s' "${GHCR_READ_TOKEN}" | docker login ghcr.io -u "${GHCR_USERNAME}" --password-stdin
elif [[ "${REQUIRE_GHCR_AUTH}" == "true" ]]; then
  echo "Missing GHCR credentials. Set GHCR_USERNAME and GHCR_READ_TOKEN GitHub environment secrets, or create ${GHCR_ENV_FILE} on the server." >&2
  false
elif [[ "${IMAGE_REGISTRY}" == "ghcr.io" ]]; then
  echo "GHCR credentials are not configured; pulling anonymously. Private GHCR images will fail." >&2
fi

build_compose_env_args
if [[ "${MTLS_MODE}" != "disabled" ]]; then
  mkdir -p "${MTLS_SECRETS_DIR}"
  chgrp "${MTLS_CERT_GROUP_ID}" "${MTLS_SECRETS_DIR}"
  chmod 750 "${MTLS_SECRETS_DIR}"
  if [[ "${MTLS_AUTO_PROVISION_CERTS}" == "true" ]]; then
    bundle_ca_cert="${MTLS_SECRETS_DIR}/ca.crt"
    bundle_ca_key="${MTLS_SECRETS_DIR}/ca.key"
    generator="${APP_DIR}/scripts/generate-mtls-certs.sh"

    if [[ ! -r "${bundle_ca_cert}" || ! -r "${bundle_ca_key}" ]]; then
      echo "Automatic mTLS certificate provisioning requires an existing readable CA certificate and private key in ${MTLS_SECRETS_DIR}; refusing to create or replace the CA during deploy." >&2
      false
    fi
    if [[ ! -x "${generator}" ]]; then
      echo "Missing executable mTLS certificate generator: ${generator}" >&2
      false
    fi
    if [[ "${MTLS_CA_CERT_PATH}" != "${bundle_ca_cert}" ]]; then
      if [[ ! -r "${MTLS_CA_CERT_PATH}" ]] || ! cmp -s "${bundle_ca_cert}" "${MTLS_CA_CERT_PATH}"; then
        echo "Automatic mTLS certificate provisioning requires MTLS_CA_CERT_PATH to match ${bundle_ca_cert}." >&2
        false
      fi
    fi

    echo "Reconciling the test mTLS certificate inventory with the existing CA."
    INFLAP_ENV="${INFLAP_ENV:-test}" \
      MTLS_CERT_GROUP_ID="${MTLS_CERT_GROUP_ID}" \
      "${generator}" \
      --out-dir "${MTLS_SECRETS_DIR}" \
      --env "${INFLAP_ENV:-test}"
  fi
  INFLAP_ENV="${INFLAP_ENV:-test}" \
    MTLS_CERT_GROUP_ID="${MTLS_CERT_GROUP_ID}" \
    MTLS_MIN_VALID_DAYS=1 \
    "${APP_DIR}/scripts/preflight-mtls-certs.sh" \
    --secrets-dir "${MTLS_SECRETS_DIR}" \
    --ca-cert "${MTLS_CA_CERT_PATH}" \
    --env "${INFLAP_ENV:-test}" \
    --min-valid-days 1
fi
compose config --quiet
if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required to snapshot rollback images." >&2
  false
fi
snapshot_rollback_images
compose pull

if [[ "${RUN_POSTGRES_MIGRATIONS:-true}" == "true" ]]; then
  if [[ "${RUN_PRE_DEPLOY_BACKUP}" == "true" ]]; then
    APP_DIR="${APP_DIR}" \
      ENV_FILE="${ENV_FILE}" \
      RUNTIME_ENV_FILE="${RUNTIME_ENV_FILE}" \
      DEPLOY_ENV_FILE="${DEPLOY_ENV_FILE}" \
      COMPOSE_FILE="${COMPOSE_FILE}" \
      "${APP_DIR}/scripts/backup-postgres.sh"
  else
    echo "Skipping pre-deploy PostgreSQL backup because RUN_PRE_DEPLOY_BACKUP=false." >&2
  fi
  APP_DIR="${APP_DIR}" \
    ENV_FILE="${ENV_FILE}" \
    RUNTIME_ENV_FILE="${RUNTIME_ENV_FILE}" \
    DEPLOY_ENV_FILE="${DEPLOY_ENV_FILE}" \
    COMPOSE_FILE="${COMPOSE_FILE}" \
    "${APP_DIR}/scripts/migrate-postgres.sh"
else
  echo "Skipping PostgreSQL migrations because RUN_POSTGRES_MIGRATIONS=false."
fi

deployment_started="true"
compose up -d --remove-orphans
run_smoke_check

deployment_succeeded="true"
echo "Deploy completed for ${IMAGE_NAMESPACE}/${IMAGE_PREFIX:-inflap-}*:${IMAGE_TAG}"
