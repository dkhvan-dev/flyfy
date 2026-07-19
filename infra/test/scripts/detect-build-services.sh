#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "detect-build-services: $*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "missing required command: $1"
}

event_name="${EVENT_NAME:-push}"
requested_services="${REQUESTED_SERVICES:-auto}"
deploy_requested="${DEPLOY_REQUESTED:-false}"
image_registry="${IMAGE_REGISTRY:-ghcr.io}"
image_namespace="${IMAGE_NAMESPACE:-}"
image_prefix="${IMAGE_PREFIX:-}"

[[ "${deploy_requested}" == "true" || "${deploy_requested}" == "false" ]] || \
  fail "DEPLOY_REQUESTED must be true or false"
[[ "${event_name}" =~ ^[A-Za-z0-9._-]+$ ]] || fail "EVENT_NAME contains unsupported characters"

all_services=(
  activity-service
  admin-panel
  anti-fraud-service
  api-gateway
  auth-service
  chat-service
  checklist-service
  currency-service
  excursion-service
  feed-service
  file-manager-service
  guide-service
  notification-service
  payment-service
  place-service
  reference-service
  routing-service
  saved-service
  search-service
  sticker-service
  support-service
  switches-service
  token-service
  translation-service
  trust-service
  user-route-service
  user-service
)

# Keep a sentinel so Bash 3.2 with `set -u` can safely expand an empty array.
selected=("")

select_service() {
  local service="$1"
  local known="false"
  local candidate
  for candidate in "${all_services[@]}"; do
    if [[ "${candidate}" == "${service}" ]]; then
      known="true"
      break
    fi
  done
  if [[ "${known}" != "true" ]]; then
    fail "unknown service requested for build: ${service}"
  fi
  for candidate in "${selected[@]}"; do
    [[ "${candidate}" == "${service}" ]] && return 0
  done
  selected+=("${service}")
}

select_all_services() {
  local service
  for service in "${all_services[@]}"; do
    select_service "${service}"
  done
}

changed_files_for_build() {
  if [[ -n "${CHANGED_FILES_FILE:-}" ]]; then
    [[ -r "${CHANGED_FILES_FILE}" ]] || fail "CHANGED_FILES_FILE is not readable: ${CHANGED_FILES_FILE}"
    cat "${CHANGED_FILES_FILE}"
    return
  fi

  require_command git
  local head_sha="${HEAD_SHA:-HEAD}"
  local base_sha="${BASE_SHA:-}"
  if [[ -n "${base_sha}" && "${base_sha}" =~ ^0+$ ]]; then
    # No successful deployment baseline exists. A full rebuild is the only
    # safe choice because mutable test-latest tags may represent old code.
    printf 'proto/\n'
    return
  fi
  if [[ -n "${base_sha}" ]] && \
    ! git cat-file -e "${base_sha}^{commit}" >/dev/null 2>&1; then
    printf 'proto/\n'
    return
  fi
  if [[ -z "${base_sha}" ]]; then
    if base_sha="$(git rev-parse "${head_sha}^" 2>/dev/null)"; then
      :
    else
      printf 'proto/\n'
      return
    fi
  fi
  git diff --name-only "${base_sha}" "${head_sha}"
}

if [[ "${event_name}" == "workflow_dispatch" && "${requested_services}" != "auto" ]]; then
  if [[ "${requested_services}" == "all" ]]; then
    select_all_services
  else
    IFS=',' read -ra requested <<<"${requested_services}"
    for service in "${requested[@]}"; do
      service="$(echo "${service}" | xargs)"
      [[ -n "${service}" ]] || fail "requested services must not contain empty entries"
      select_service "${service}"
    done
  fi
else
  changed_files="$(changed_files_for_build)"
  if grep -Eq '^(proto/|backend/pkg/)' <<<"${changed_files}"; then
    select_all_services
  else
    for service in "${all_services[@]}"; do
      if grep -q "^backend/services/${service}/" <<<"${changed_files}"; then
        select_service "${service}"
      fi
    done
  fi
fi

if [[ "${deploy_requested}" == "true" ]]; then
  require_command docker
  [[ -n "${image_namespace}" ]] || fail "IMAGE_NAMESPACE is required for deployment inventory validation"
  [[ -n "${image_prefix}" ]] || fail "IMAGE_PREFIX is required for deployment inventory validation"
  for service in "${all_services[@]}"; do
    image="${image_registry}/${image_namespace}/${image_prefix}${service}:test-latest"
    if ! docker manifest inspect "${image}" >/dev/null 2>&1; then
      echo "Selecting ${service}: required deployment image is missing from the registry." >&2
      select_service "${service}"
    fi
  done
fi

require_command jq
if [[ ${#selected[@]} -eq 1 ]]; then
  printf '[]\n'
  exit 0
fi

printf 'Selected services:\n' >&2
printf ' - %s\n' "${selected[@]:1}" >&2
printf '%s\n' "${selected[@]:1}" | jq -R . | jq -cs .
