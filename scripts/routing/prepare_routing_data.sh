#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Prepare self-hosted Inflap routing data from an OSM PBF extract.

Required:
  PBF_PATH=/path/to/extract.osm.pbf
    or
  PBF_URL=https://download.geofabrik.de/asia/kazakhstan-latest.osm.pbf

Optional:
  ROUTING_REGION=kazakhstan
  ROUTING_DATA_DIR=deploy/data/routing/${ROUTING_REGION}
  BUILD_OSRM=true
  BUILD_VALHALLA=true
  OSRM_PROFILE=car
  OSRM_IMAGE=osrm/osrm-backend:v5.25.0
  VALHALLA_IMAGE=ghcr.io/gis-ops/docker-valhalla/valhalla:latest
  CLEAN_ROUTING_DATA=false
  PBF_SHA256=<expected sha256, optional>
  DOWNLOAD_RETRIES=3

Examples:
  PBF_URL=https://download.geofabrik.de/asia/kazakhstan-latest.osm.pbf \
    ROUTING_REGION=kazakhstan BUILD_OSRM=true BUILD_VALHALLA=true \
    scripts/routing/prepare_routing_data.sh

  PBF_PATH=/tmp/almaty.osm.pbf ROUTING_REGION=almaty BUILD_VALHALLA=true \
    scripts/routing/prepare_routing_data.sh
USAGE
}

require_command() {
  local name="$1"
  if ! command -v "$name" >/dev/null 2>&1; then
    echo "Missing required command: $name" >&2
    exit 1
  fi
}

json_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

shell_escape() {
  printf '%q' "$1"
}

bool_enabled() {
  case "${1:-}" in
    1 | true | TRUE | yes | YES | y | Y) return 0 ;;
    *) return 1 ;;
  esac
}

write_attribution() {
  local output_dir="$1"
  local pbf_source="$2"
  local generated_at="$3"
  local pbf_sha256="$4"
  local attribution_file="${output_dir}/ATTRIBUTION.md"

  cat >"${attribution_file}" <<EOF
# Inflap Routing Data Attribution

- Prepared at: ${generated_at}
- Source extract: ${pbf_source}
- Source extract SHA-256: ${pbf_sha256}
- Source data: OpenStreetMap contributors
- License: Open Database License (ODbL) 1.0

Inflap must display OpenStreetMap attribution anywhere this derived routing
data is used. Keep this file with every generated routing dataset and review
ODbL share-alike obligations before publishing modified databases or derived
datasets outside Inflap infrastructure.
EOF
}

sha256_file() {
  local path="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "${path}" | awk '{print $1}'
    return
  fi
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "${path}" | awk '{print $1}'
    return
  fi
  echo "Missing required command: sha256sum or shasum" >&2
  exit 1
}

file_size_bytes() {
  wc -c <"$1" | tr -d '[:space:]'
}

verify_sha256() {
  local path="$1"
  local expected="$2"
  if [[ -z "${expected}" ]]; then
    return
  fi

  local actual
  actual="$(sha256_file "${path}")"
  if [[ "${actual}" != "${expected}" ]]; then
    echo "PBF SHA-256 mismatch for ${path}" >&2
    echo "expected: ${expected}" >&2
    echo "actual:   ${actual}" >&2
    exit 1
  fi
}

download_pbf() {
  local url="$1"
  local destination="$2"
  local retries="$3"

  require_command curl
  echo "Downloading OSM extract: ${url}"
  curl \
    --fail \
    --location \
    --show-error \
    --retry "${retries}" \
    --retry-delay 2 \
    --retry-connrefused \
    --output "${destination}.tmp" \
    "${url}"
  mv "${destination}.tmp" "${destination}"
}

write_manifest() {
  local output_dir="$1"
  local region="$2"
  local pbf_source="$3"
  local pbf_name="$4"
  local pbf_sha256="$5"
  local pbf_size_bytes="$6"
  local generated_at="$7"
  local build_osrm="$8"
  local build_valhalla="$9"
  local osrm_profile="${10}"
  local osrm_image="${11}"
  local valhalla_image="${12}"

  cat >"${output_dir}/DATASET_MANIFEST.json" <<EOF
{
  "region": "$(json_escape "${region}")",
  "generatedAt": "$(json_escape "${generated_at}")",
  "sourceExtract": "$(json_escape "${pbf_source}")",
  "sourceData": "OpenStreetMap contributors",
  "license": "ODbL-1.0",
  "pbfFile": "$(json_escape "${pbf_name}")",
  "pbfSha256": "$(json_escape "${pbf_sha256}")",
  "pbfSizeBytes": ${pbf_size_bytes},
  "buildOsrm": ${build_osrm},
  "buildValhalla": ${build_valhalla},
  "osrmProfile": "$(json_escape "${osrm_profile}")",
  "osrmImage": "$(json_escape "${osrm_image}")",
  "valhallaImage": "$(json_escape "${valhalla_image}")",
  "attributionRequired": true
}
EOF
}

write_runtime_env() {
  local output_dir="$1"
  local region="$2"
  local pbf_source="$3"
  local pbf_sha256="$4"
  local generated_at="$5"

  cat >"${output_dir}/routing-data.env" <<EOF
ROUTING_DATA_REGION=$(shell_escape "${region}")
ROUTING_OSM_SOURCE=$(shell_escape "${pbf_source}")
ROUTING_OSM_DATA_VERSION=$(shell_escape "${pbf_sha256}")
ROUTING_DATA_GENERATED_AT=$(shell_escape "${generated_at}")
ROUTING_ATTRIBUTION_REQUIRED=true
EOF
}

prepare_osrm() {
  local data_dir="$1"
  local pbf_name="$2"
  local profile="$3"
  local image="$4"

  require_command docker
  mkdir -p "${data_dir}/osrm"
  cp "${data_dir}/${pbf_name}" "${data_dir}/osrm/extract.osm.pbf"

  echo "Preparing OSRM graph with profile: ${profile}"
  docker run --rm -t -v "${data_dir}/osrm:/data" "${image}" \
    osrm-extract -p "/opt/${profile}.lua" /data/extract.osm.pbf
  docker run --rm -t -v "${data_dir}/osrm:/data" "${image}" \
    osrm-partition /data/extract.osrm
  docker run --rm -t -v "${data_dir}/osrm:/data" "${image}" \
    osrm-customize /data/extract.osrm
}

prepare_valhalla() {
  local data_dir="$1"
  local pbf_name="$2"
  local image="$3"

  require_command docker
  mkdir -p "${data_dir}/valhalla/tiles"

  echo "Preparing Valhalla tiles"
  docker run --rm -t --entrypoint /bin/sh -v "${data_dir}:/data" "${image}" -lc \
    'valhalla_build_config \
      --mjolnir-tile-dir /data/valhalla/tiles \
      --mjolnir-tile-extract /data/valhalla/tiles.tar \
      --mjolnir-timezone /data/valhalla/timezones.sqlite \
      --mjolnir-admin /data/valhalla/admins.sqlite \
      > /data/valhalla/valhalla.json'

  docker run --rm -t --entrypoint /bin/sh -v "${data_dir}:/data" "${image}" -lc \
    "valhalla_build_tiles -c /data/valhalla/valhalla.json /data/${pbf_name}"
  docker run --rm -t --entrypoint /bin/sh -v "${data_dir}:/data" "${image}" -lc \
    'valhalla_build_extract -c /data/valhalla/valhalla.json -v'
}

main() {
  if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    usage
    exit 0
  fi

  local region="${ROUTING_REGION:-kazakhstan}"
  local data_dir="${ROUTING_DATA_DIR:-deploy/data/routing/${region}}"
  local pbf_name="extract.osm.pbf"
  local pbf_path="${PBF_PATH:-}"
  local pbf_url="${PBF_URL:-}"
  local osrm_profile="${OSRM_PROFILE:-car}"
  local osrm_image="${OSRM_IMAGE:-osrm/osrm-backend:v5.25.0}"
  local valhalla_image="${VALHALLA_IMAGE:-ghcr.io/gis-ops/docker-valhalla/valhalla:latest}"
  local expected_sha256="${PBF_SHA256:-}"
  local download_retries="${DOWNLOAD_RETRIES:-3}"
  local generated_at
  generated_at="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

  if bool_enabled "${CLEAN_ROUTING_DATA:-false}" && [[ -d "${data_dir}" ]]; then
    echo "Cleaning existing routing data under: ${data_dir}"
    rm -rf "${data_dir:?}/"*
  fi
  mkdir -p "${data_dir}"
  data_dir="$(cd "${data_dir}" && pwd -P)"

  local pbf_source
  if [[ -n "${pbf_path}" ]]; then
    if [[ ! -f "${pbf_path}" ]]; then
      echo "PBF_PATH does not exist: ${pbf_path}" >&2
      exit 1
    fi
    verify_sha256 "${pbf_path}" "${expected_sha256}"
    cp "${pbf_path}" "${data_dir}/${pbf_name}"
    pbf_source="${pbf_path}"
  elif [[ -n "${pbf_url}" ]]; then
    download_pbf "${pbf_url}" "${data_dir}/${pbf_name}" "${download_retries}"
    verify_sha256 "${data_dir}/${pbf_name}" "${expected_sha256}"
    pbf_source="${pbf_url}"
  else
    usage
    echo "Set PBF_PATH or PBF_URL." >&2
    exit 1
  fi

  local pbf_sha256
  local pbf_size_bytes
  pbf_sha256="$(sha256_file "${data_dir}/${pbf_name}")"
  pbf_size_bytes="$(file_size_bytes "${data_dir}/${pbf_name}")"
  write_attribution "${data_dir}" "${pbf_source}" "${generated_at}" "${pbf_sha256}"
  write_manifest \
    "${data_dir}" \
    "${region}" \
    "${pbf_source}" \
    "${pbf_name}" \
    "${pbf_sha256}" \
    "${pbf_size_bytes}" \
    "${generated_at}" \
    "$(bool_enabled "${BUILD_OSRM:-false}" && echo true || echo false)" \
    "$(bool_enabled "${BUILD_VALHALLA:-false}" && echo true || echo false)" \
    "${osrm_profile}" \
    "${osrm_image}" \
    "${valhalla_image}"
  write_runtime_env "${data_dir}" "${region}" "${pbf_source}" "${pbf_sha256}" "${generated_at}"

  if bool_enabled "${BUILD_OSRM:-false}"; then
    prepare_osrm "${data_dir}" "${pbf_name}" "${osrm_profile}" "${osrm_image}"
  fi

  if bool_enabled "${BUILD_VALHALLA:-false}"; then
    prepare_valhalla "${data_dir}" "${pbf_name}" "${valhalla_image}"
  fi

  echo "Routing data prepared under: ${data_dir}"
  echo "Keep ${data_dir}/ATTRIBUTION.md with the generated dataset."
  echo "Runtime metadata written to: ${data_dir}/routing-data.env"
}

main "$@"
