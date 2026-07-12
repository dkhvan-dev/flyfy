#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
script="${repo_root}/infra/test/scripts/smoke-check.sh"

output="$(
  APP_DIR="${repo_root}" \
  ENV_FILE=/dev/null \
  DEPLOY_ENV_FILE=/dev/null \
  SMOKE_BASE_URL=https://test-api.inflap.app \
  SMOKE_ENDPOINTS="/health,/api/v1/auth/health" \
  SMOKE_SKIP_DOCKER=true \
  SMOKE_DRY_RUN=true \
  "${script}"
)"

grep -Fq "Would check endpoint: https://test-api.inflap.app/health" <<<"${output}"
grep -Fq "Would check endpoint: https://test-api.inflap.app/api/v1/auth/health" <<<"${output}"
grep -Fq "Smoke check completed." <<<"${output}"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT
mkdir -p "${tmp_dir}/bin"
touch "${tmp_dir}/test.env" "${tmp_dir}/runtime.env" "${tmp_dir}/deploy.env" "${tmp_dir}/compose.yml"

cat >"${tmp_dir}/bin/docker" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"${FAKE_DOCKER_LOG}"
if [[ "$*" == *"ps --all --format json"* ]]; then
  attempt=0
  if [[ -f "${FAKE_DOCKER_STATE}" ]]; then
    attempt="$(cat "${FAKE_DOCKER_STATE}")"
  fi
  attempt=$((attempt + 1))
  printf '%s' "${attempt}" >"${FAKE_DOCKER_STATE}"
  if [[ ${attempt} -eq 1 ]]; then
    printf '%s\n' '{"Service":"translation-service","State":"running","Health":"starting","Status":"Up (health: starting)"}'
  else
    printf '%s\n' '{"Service":"translation-service","State":"running","Health":"healthy","Status":"Up (healthy)"}'
  fi
  printf '%s\n' '{"Service":"sticker-default-stickers-seeder","State":"exited","Health":"","ExitCode":0,"Status":"Exited (0)"}'
elif [[ "$*" == *"config --format json"* ]]; then
  printf '%s\n' '{"services":{"translation-service":{},"sticker-default-stickers-seeder":{"restart":"no","labels":{"com.inflap.smoke.allow-exited":"true"}}}}'
fi
EOF
chmod +x "${tmp_dir}/bin/docker"

cat >"${tmp_dir}/bin/curl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
output_file=/dev/null
previous=""
for argument in "$@"; do
  if [[ "${previous}" == "-o" ]]; then
    output_file="${argument}"
  fi
  previous="${argument}"
done
: >"${output_file}"
printf '200'
EOF
chmod +x "${tmp_dir}/bin/curl"

cat >"${tmp_dir}/bin/sleep" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "${tmp_dir}/bin/sleep"

fake_docker_log="${tmp_dir}/docker.log"
PATH="${tmp_dir}/bin:${PATH}" \
FAKE_DOCKER_LOG="${fake_docker_log}" \
FAKE_DOCKER_STATE="${tmp_dir}/docker.state" \
APP_DIR="${tmp_dir}" \
ENV_FILE="${tmp_dir}/test.env" \
RUNTIME_ENV_FILE="${tmp_dir}/runtime.env" \
DEPLOY_ENV_FILE="${tmp_dir}/deploy.env" \
COMPOSE_FILE="${tmp_dir}/compose.yml" \
SMOKE_BASE_URL=https://test-api.inflap.app \
SMOKE_RETRIES=3 \
SMOKE_RETRY_DELAY_SECONDS=1 \
SMOKE_REQUIRED_CONSECUTIVE_PASSES=2 \
SMOKE_ALLOW_EXITED_SERVICES=legacy-one-shot \
"${script}" >"${tmp_dir}/smoke.out"

grep -Fq -- "--env-file ${tmp_dir}/runtime.env" "${fake_docker_log}"
grep -Fq 'Compose services are not ready' "${tmp_dir}/smoke.out"
grep -Fq 'Compose services passed stability check 1/2' "${tmp_dir}/smoke.out"
grep -Fq 'Smoke endpoint passed' "${tmp_dir}/smoke.out"

cat >"${tmp_dir}/bin/docker" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [[ "$*" == *"config --format json"* ]]; then
  printf '%s\n' '{"services":{"translation-service":{},"token-service":{}}}'
elif [[ "$*" == *"ps --all --format json"* ]]; then
  printf '%s\n' '{"Service":"translation-service","State":"running","Health":"healthy","Status":"Up (healthy)"}'
fi
EOF
chmod +x "${tmp_dir}/bin/docker"

if PATH="${tmp_dir}/bin:${PATH}" \
  APP_DIR="${tmp_dir}" \
  ENV_FILE="${tmp_dir}/test.env" \
  RUNTIME_ENV_FILE="${tmp_dir}/runtime.env" \
  DEPLOY_ENV_FILE="${tmp_dir}/deploy.env" \
  COMPOSE_FILE="${tmp_dir}/compose.yml" \
  SMOKE_BASE_URL=https://test-api.inflap.app \
  SMOKE_RETRIES=1 \
  SMOKE_RETRY_DELAY_SECONDS=1 \
  SMOKE_REQUIRED_CONSECUTIVE_PASSES=1 \
  "${script}" >"${tmp_dir}/missing-service.out" 2>&1; then
  echo "smoke test expected a missing service to fail" >&2
  exit 1
fi
grep -Fq 'token-service: container is missing' "${tmp_dir}/missing-service.out"

cat >"${tmp_dir}/bin/docker" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [[ "$*" == *"config --format json"* ]]; then
  printf '%s\n' '{"services":{"sticker-default-stickers-seeder":{"restart":"no","labels":{"com.inflap.smoke.allow-exited":"true"}}}}'
elif [[ "$*" == *"ps --all --format json"* ]]; then
  printf '%s\n' '{"Service":"sticker-default-stickers-seeder","State":"exited","Health":"","ExitCode":1,"Status":"Exited (1)"}'
fi
EOF
chmod +x "${tmp_dir}/bin/docker"

if PATH="${tmp_dir}/bin:${PATH}" \
  APP_DIR="${tmp_dir}" \
  ENV_FILE="${tmp_dir}/test.env" \
  RUNTIME_ENV_FILE="${tmp_dir}/runtime.env" \
  DEPLOY_ENV_FILE="${tmp_dir}/deploy.env" \
  COMPOSE_FILE="${tmp_dir}/compose.yml" \
  SMOKE_BASE_URL=https://test-api.inflap.app \
  SMOKE_RETRIES=1 \
  SMOKE_RETRY_DELAY_SECONDS=1 \
  SMOKE_REQUIRED_CONSECUTIVE_PASSES=1 \
  "${script}" >"${tmp_dir}/failed-one-shot.out" 2>&1; then
  echo "smoke test expected a failed one-shot service to fail" >&2
  exit 1
fi
grep -Fq 'sticker-default-stickers-seeder: state=exited' "${tmp_dir}/failed-one-shot.out"
grep -Fq 'exit_code=1' "${tmp_dir}/failed-one-shot.out"
