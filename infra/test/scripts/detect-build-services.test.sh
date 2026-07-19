#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
script="${repo_root}/infra/test/scripts/detect-build-services.sh"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT

mkdir -p "${tmp_dir}/bin"
cat >"${tmp_dir}/bin/docker" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"${FAKE_DOCKER_LOG:?}"
if [[ -n "${MISSING_IMAGE_FRAGMENT:-}" && "${3:-}" == *"${MISSING_IMAGE_FRAGMENT}"* ]]; then
  exit 1
fi
exit 0
EOF
chmod +x "${tmp_dir}/bin/docker"

changed_files="${tmp_dir}/changed-files"
docker_log="${tmp_dir}/docker.log"

run_detector() {
  PATH="${tmp_dir}/bin:${PATH}" \
    EVENT_NAME="${EVENT_NAME:-push}" \
    REQUESTED_SERVICES="${REQUESTED_SERVICES:-auto}" \
    DEPLOY_REQUESTED="${DEPLOY_REQUESTED:-true}" \
    CHANGED_FILES_FILE="${changed_files}" \
    IMAGE_REGISTRY=ghcr.io \
    IMAGE_NAMESPACE=inflap-owner \
    IMAGE_PREFIX=inflap- \
    FAKE_DOCKER_LOG="${docker_log}" \
    MISSING_IMAGE_FRAGMENT="${MISSING_IMAGE_FRAGMENT:-}" \
    bash "${script}"
}

printf 'backend/services/activity-service/internal/app/activity.go\n' >"${changed_files}"
: >"${docker_log}"
result="$(run_detector)"
[[ "$(jq -r 'length' <<<"${result}")" == "1" ]]
[[ "$(jq -r '.[0]' <<<"${result}")" == "activity-service" ]]

: >"${changed_files}"
: >"${docker_log}"
MISSING_IMAGE_FRAGMENT='/inflap-saved-service:test-latest'
result="$(run_detector)"
unset MISSING_IMAGE_FRAGMENT
[[ "$(jq -r 'length' <<<"${result}")" == "1" ]]
[[ "$(jq -r '.[0]' <<<"${result}")" == "saved-service" ]]

printf 'backend/services/saved-service/cmd/main.go\n' >"${changed_files}"
: >"${docker_log}"
MISSING_IMAGE_FRAGMENT='/inflap-saved-service:test-latest'
result="$(run_detector)"
unset MISSING_IMAGE_FRAGMENT
[[ "$(jq -r 'length' <<<"${result}")" == "1" ]]
[[ "$(jq -r '.[0]' <<<"${result}")" == "saved-service" ]]

printf 'proto/content/v1/saved_source.proto\n' >"${changed_files}"
DEPLOY_REQUESTED=false
result="$(run_detector)"
unset DEPLOY_REQUESTED
[[ "$(jq -r 'length' <<<"${result}")" == "27" ]]
[[ "$(jq -r 'index("saved-service") != null' <<<"${result}")" == "true" ]]

: >"${changed_files}"
DEPLOY_REQUESTED=false
result="$(run_detector)"
unset DEPLOY_REQUESTED
[[ "${result}" == "[]" ]]

result="$(
  cd "${repo_root}"
  EVENT_NAME=push \
    REQUESTED_SERVICES=auto \
    DEPLOY_REQUESTED=false \
    BASE_SHA=0000000000000000000000000000000000000000 \
    HEAD_SHA=HEAD \
    bash "${script}"
)"
[[ "$(jq -r 'length' <<<"${result}")" == "27" ]]
[[ "$(jq -r 'index("switches-service") != null' <<<"${result}")" == "true" ]]

EVENT_NAME=workflow_dispatch
REQUESTED_SERVICES='saved-service,unknown-service'
DEPLOY_REQUESTED=false
if run_detector >"${tmp_dir}/invalid.out" 2>"${tmp_dir}/invalid.err"; then
  echo "detector accepted an unknown manually requested service" >&2
  exit 1
fi
unset EVENT_NAME REQUESTED_SERVICES DEPLOY_REQUESTED
grep -Fq 'unknown service requested for build: unknown-service' "${tmp_dir}/invalid.err"

echo "build service detector test passed"
