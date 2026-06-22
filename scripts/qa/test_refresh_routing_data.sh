#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/inflap-routing-refresh-test.XXXXXX")"
trap 'rm -rf "${tmp_dir}"' EXIT

if ! command -v jq >/dev/null 2>&1; then
  echo "Skipping refresh routing data test: jq is not installed" >&2
  exit 0
fi

fake_prepare="${tmp_dir}/prepare.sh"
fake_bad_prepare="${tmp_dir}/prepare-bad.sh"
fake_smoke="${tmp_dir}/smoke.sh"
data_dir="${tmp_dir}/routing-data"
compose_file="${tmp_dir}/docker-compose.yml"
sha256_value="aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"

cat >"${fake_prepare}" <<EOF
#!/usr/bin/env bash
set -euo pipefail

mkdir -p "\${ROUTING_DATA_DIR}"
printf '%s|%s|%s|%s|%s|%s\n' \
  "\${ROUTING_REGION}" \
  "\${PBF_URL:-}" \
  "\${PBF_PATH:-}" \
  "\${CLEAN_ROUTING_DATA}" \
  "\${BUILD_OSRM}" \
  "\${BUILD_VALHALLA}" \
  >"\${ROUTING_DATA_DIR}/prepare.env"

cat >"\${ROUTING_DATA_DIR}/DATASET_MANIFEST.json" <<JSON
{
  "region": "\${ROUTING_REGION}",
  "generatedAt": "2026-06-21T00:00:00Z",
  "sourceExtract": "\${PBF_URL:-\${PBF_PATH:-}}",
  "sourceData": "OpenStreetMap contributors",
  "license": "ODbL-1.0",
  "pbfFile": "extract.osm.pbf",
  "pbfSha256": "${sha256_value}",
  "pbfSizeBytes": 123,
  "buildOsrm": true,
  "buildValhalla": true,
  "attributionRequired": true
}
JSON

cat >"\${ROUTING_DATA_DIR}/routing-data.env" <<ENV
ROUTING_DATA_REGION=\${ROUTING_REGION}
ROUTING_OSM_SOURCE=\${PBF_URL:-\${PBF_PATH:-}}
ROUTING_OSM_DATA_VERSION=${sha256_value}
ROUTING_DATA_GENERATED_AT=2026-06-21T00:00:00Z
ROUTING_ATTRIBUTION_REQUIRED=true
ENV
EOF

cat >"${fake_bad_prepare}" <<EOF
#!/usr/bin/env bash
set -euo pipefail

mkdir -p "\${ROUTING_DATA_DIR}"
cat >"\${ROUTING_DATA_DIR}/DATASET_MANIFEST.json" <<JSON
{
  "region": "\${ROUTING_REGION}",
  "sourceData": "OpenStreetMap contributors",
  "license": "ODbL-1.0",
  "pbfSha256": "${sha256_value}",
  "attributionRequired": false
}
JSON
cat >"\${ROUTING_DATA_DIR}/routing-data.env" <<ENV
ROUTING_ATTRIBUTION_REQUIRED=false
ENV
EOF

cat >"${fake_smoke}" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

printf '%s|%s\n' \
  "${ROUTING_SMOKE_BASE_URL}" \
  "${ROUTING_SMOKE_REQUIRE_ENGINE_SUCCESS}" \
  >"${FAKE_SMOKE_OUTPUT}"
EOF

mkdir -p "${tmp_dir}/bin"
cat >"${tmp_dir}/bin/docker" <<EOF
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "\$*" >"${tmp_dir}/docker.args"
EOF

chmod +x "${fake_prepare}" "${fake_bad_prepare}" "${fake_smoke}" "${tmp_dir}/bin/docker"
printf 'services: {}\n' >"${compose_file}"

ROUTING_REFRESH_PREPARE_SCRIPT="${fake_prepare}" \
ROUTING_REGION=qa-region \
ROUTING_DATA_DIR="${data_dir}" \
PBF_URL=https://download.example.test/qa-latest.osm.pbf \
BUILD_OSRM=false \
BUILD_VALHALLA=false \
  "${repo_root}/scripts/routing/refresh_routing_data.sh" >/dev/null

grep -q '^qa-region|https://download.example.test/qa-latest.osm.pbf||true|false|false$' "${data_dir}/prepare.env"

rm -rf "${data_dir}"
PATH="${tmp_dir}/bin:${PATH}" \
FAKE_SMOKE_OUTPUT="${tmp_dir}/smoke.args" \
ROUTING_REFRESH_PREPARE_SCRIPT="${fake_prepare}" \
ROUTING_REFRESH_SMOKE_SCRIPT="${fake_smoke}" \
ROUTING_REFRESH_COMPOSE_FILE="${compose_file}" \
ROUTING_REFRESH_RESTART_COMPOSE=true \
ROUTING_REFRESH_RUN_SMOKE=true \
ROUTING_SMOKE_BASE_URL=http://127.0.0.1:8104/v1 \
ROUTING_SMOKE_REQUIRE_ENGINE_SUCCESS=true \
ROUTING_REGION=qa-region \
ROUTING_DATA_DIR="${data_dir}" \
PBF_URL=https://download.example.test/qa-latest.osm.pbf \
  "${repo_root}/scripts/routing/refresh_routing_data.sh" >/dev/null

grep -q -- "compose -f ${compose_file} --profile routing-engines up -d --force-recreate valhalla osrm routing-service api-gateway" "${tmp_dir}/docker.args"
grep -q '^http://127.0.0.1:8104/v1|true$' "${tmp_dir}/smoke.args"

rm -rf "${data_dir}"
if ROUTING_REFRESH_PREPARE_SCRIPT="${fake_bad_prepare}" \
  ROUTING_REGION=qa-region \
  ROUTING_DATA_DIR="${data_dir}" \
  PBF_URL=https://download.example.test/qa-latest.osm.pbf \
  "${repo_root}/scripts/routing/refresh_routing_data.sh" >/dev/null 2>"${tmp_dir}/bad.err"; then
  echo "refresh must fail when attributionRequired is false" >&2
  exit 1
fi

grep -q 'manifest guard failed' "${tmp_dir}/bad.err"

echo "Routing data refresh test passed"
