#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Refresh self-hosted Inflap routing data with manifest and attribution guards.

Defaults target the Kazakhstan Geofabrik extract and generate both Valhalla and
OSRM data under deploy/data/routing/kazakhstan.

Optional environment:
  ROUTING_REGION=kazakhstan
  ROUTING_DATA_DIR=deploy/data/routing/${ROUTING_REGION}
  PBF_URL=https://download.geofabrik.de/asia/kazakhstan-latest.osm.pbf
  PBF_PATH=/path/to/extract.osm.pbf
  PBF_SHA256=<expected source extract sha256>
  BUILD_OSRM=true
  BUILD_VALHALLA=true
  CLEAN_ROUTING_DATA=true
  ROUTING_REFRESH_RESTART_COMPOSE=false
  ROUTING_REFRESH_RUN_SMOKE=false
  ROUTING_REFRESH_COMPOSE_FILE=deploy/docker-compose.yml
  ROUTING_SMOKE_BASE_URL=http://127.0.0.1:8104/v1
  ROUTING_SMOKE_REQUIRE_ENGINE_SUCCESS=true

Example:
  PBF_SHA256=<expected sha256> \
  ROUTING_REFRESH_RESTART_COMPOSE=true \
  ROUTING_REFRESH_RUN_SMOKE=true \
  scripts/routing/refresh_routing_data.sh
USAGE
}

require_command() {
  local name="$1"
  if ! command -v "$name" >/dev/null 2>&1; then
    echo "Missing required command: $name" >&2
    exit 1
  fi
}

require_file() {
  local path="$1"
  local label="$2"
  if [[ ! -f "$path" ]]; then
    echo "Missing ${label}: ${path}" >&2
    exit 1
  fi
}

bool_enabled() {
  case "${1:-}" in
    1 | true | TRUE | yes | YES | y | Y) return 0 ;;
    *) return 1 ;;
  esac
}

repo_root() {
  cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd
}

run_prepare() {
  local prepare_script="$1"
  local region="$2"
  local data_dir="$3"
  local default_pbf_url="$4"

  local prepare_env=(
    env
    "ROUTING_REGION=${region}"
    "ROUTING_DATA_DIR=${data_dir}"
    "CLEAN_ROUTING_DATA=${CLEAN_ROUTING_DATA:-true}"
    "BUILD_OSRM=${BUILD_OSRM:-true}"
    "BUILD_VALHALLA=${BUILD_VALHALLA:-true}"
    "DOWNLOAD_RETRIES=${DOWNLOAD_RETRIES:-3}"
  )

  if [[ -n "${PBF_PATH:-}" ]]; then
    prepare_env+=("PBF_PATH=${PBF_PATH}")
  else
    prepare_env+=("PBF_URL=${PBF_URL:-${default_pbf_url}}")
  fi
  if [[ -n "${PBF_SHA256:-}" ]]; then
    prepare_env+=("PBF_SHA256=${PBF_SHA256}")
  fi
  if [[ -n "${OSRM_PROFILE:-}" ]]; then
    prepare_env+=("OSRM_PROFILE=${OSRM_PROFILE}")
  fi
  if [[ -n "${OSRM_IMAGE:-}" ]]; then
    prepare_env+=("OSRM_IMAGE=${OSRM_IMAGE}")
  fi
  if [[ -n "${VALHALLA_IMAGE:-}" ]]; then
    prepare_env+=("VALHALLA_IMAGE=${VALHALLA_IMAGE}")
  fi

  "${prepare_env[@]}" "$prepare_script"
}

validate_routing_dataset() {
  local data_dir="$1"
  local manifest="${data_dir}/DATASET_MANIFEST.json"
  local runtime_env="${data_dir}/routing-data.env"

  require_file "$manifest" "routing dataset manifest"
  require_file "$runtime_env" "routing runtime env file"
  require_command jq

  if ! jq -e '
    .sourceData == "OpenStreetMap contributors"
    and .license == "ODbL-1.0"
    and .attributionRequired == true
    and (.region | type == "string" and length > 0)
    and (.sourceExtract | type == "string" and length > 0)
    and (.generatedAt | type == "string" and length > 0)
    and (.pbfSha256 | type == "string" and length >= 64)
    and (.pbfSizeBytes | type == "number" and . > 0)
  ' "$manifest" >/dev/null; then
    echo "routing dataset manifest guard failed: ${manifest}" >&2
    exit 1
  fi

  if ! grep -q '^ROUTING_ATTRIBUTION_REQUIRED=true$' "$runtime_env"; then
    echo "routing runtime env guard failed: ROUTING_ATTRIBUTION_REQUIRED=true is required" >&2
    exit 1
  fi
  if ! grep -q '^ROUTING_OSM_DATA_VERSION=.\+' "$runtime_env"; then
    echo "routing runtime env guard failed: ROUTING_OSM_DATA_VERSION is required" >&2
    exit 1
  fi
}

restart_compose_services() {
  local compose_file="$1"

  require_command docker
  require_file "$compose_file" "Docker Compose file"
  docker compose \
    -f "$compose_file" \
    --profile routing-engines \
    up \
    -d \
    --force-recreate \
    valhalla \
    osrm \
    routing-service \
    api-gateway
}

run_smoke() {
  local smoke_script="$1"
  require_file "$smoke_script" "routing smoke script"

  env \
    "ROUTING_SMOKE_BASE_URL=${ROUTING_SMOKE_BASE_URL:-http://127.0.0.1:8104/v1}" \
    "ROUTING_SMOKE_REQUIRE_ENGINE_SUCCESS=${ROUTING_SMOKE_REQUIRE_ENGINE_SUCCESS:-true}" \
    "ROUTING_SMOKE_AUTH_TOKEN=${ROUTING_SMOKE_AUTH_TOKEN:-}" \
    "$smoke_script"
}

main() {
  if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    usage
    exit 0
  fi

  local root
  root="$(repo_root)"
  local region="${ROUTING_REGION:-kazakhstan}"
  local data_dir="${ROUTING_DATA_DIR:-${root}/deploy/data/routing/${region}}"
  local default_pbf_url="https://download.geofabrik.de/asia/kazakhstan-latest.osm.pbf"
  local prepare_script="${ROUTING_REFRESH_PREPARE_SCRIPT:-${root}/scripts/routing/prepare_routing_data.sh}"
  local compose_file="${ROUTING_REFRESH_COMPOSE_FILE:-${root}/deploy/docker-compose.yml}"
  local smoke_script="${ROUTING_REFRESH_SMOKE_SCRIPT:-${root}/scripts/qa/run_routing_smoke.sh}"

  require_file "$prepare_script" "routing data preparation script"

  run_prepare "$prepare_script" "$region" "$data_dir" "$default_pbf_url"
  validate_routing_dataset "$data_dir"

  if bool_enabled "${ROUTING_REFRESH_RESTART_COMPOSE:-false}"; then
    restart_compose_services "$compose_file"
  fi

  if bool_enabled "${ROUTING_REFRESH_RUN_SMOKE:-false}"; then
    run_smoke "$smoke_script"
  fi

  echo "Routing data refresh completed"
  jq -r '
    "region=\(.region)",
    "source=\(.sourceExtract)",
    "sha256=\(.pbfSha256)",
    "generatedAt=\(.generatedAt)"
  ' "${data_dir}/DATASET_MANIFEST.json"
}

main "$@"
