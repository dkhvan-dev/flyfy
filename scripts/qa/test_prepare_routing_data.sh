#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/inflap-routing-data-test.XXXXXX")"
trap 'rm -rf "${tmp_dir}"' EXIT

pbf_path="${tmp_dir}/sample.osm.pbf"
data_dir="${tmp_dir}/routing-data"
mkdir -p "${data_dir}"
printf 'tiny-osm-pbf-fixture\n' >"${pbf_path}"
printf 'stale\n' >"${data_dir}/stale.txt"

CLEAN_ROUTING_DATA=true \
PBF_PATH="${pbf_path}" \
ROUTING_REGION=qa-region \
ROUTING_DATA_DIR="${data_dir}" \
BUILD_OSRM=false \
BUILD_VALHALLA=false \
  "${repo_root}/scripts/routing/prepare_routing_data.sh"

if [[ -e "${data_dir}/stale.txt" ]]; then
  echo "CLEAN_ROUTING_DATA=true must remove stale generated files" >&2
  exit 1
fi

if [[ ! -f "${data_dir}/DATASET_MANIFEST.json" ]]; then
  echo "DATASET_MANIFEST.json was not written" >&2
  exit 1
fi

if [[ ! -f "${data_dir}/routing-data.env" ]]; then
  echo "routing-data.env was not written" >&2
  exit 1
fi

expected_sha="$(shasum -a 256 "${pbf_path}" | awk '{print $1}')"
expected_size="$(wc -c <"${pbf_path}" | tr -d '[:space:]')"
grep -q "\"region\": \"qa-region\"" "${data_dir}/DATASET_MANIFEST.json"
grep -q "\"pbfSha256\": \"${expected_sha}\"" "${data_dir}/DATASET_MANIFEST.json"
grep -q "\"pbfSizeBytes\": ${expected_size}" "${data_dir}/DATASET_MANIFEST.json"
grep -q '"osrmImage": "osrm/osrm-backend:v5.25.0"' "${data_dir}/DATASET_MANIFEST.json"
grep -q '^ROUTING_DATA_REGION=qa-region$' "${data_dir}/routing-data.env"
grep -q "^ROUTING_OSM_DATA_VERSION=${expected_sha}$" "${data_dir}/routing-data.env"

echo "Routing data preparation test passed"
