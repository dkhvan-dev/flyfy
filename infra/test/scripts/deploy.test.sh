#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
script="${repo_root}/infra/test/scripts/deploy.sh"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT

mkdir -p "${tmp_dir}/env" "${tmp_dir}/scripts" "${tmp_dir}/bin"
printf 'TEST_API_HOST=test-api.inflap.app\n' >"${tmp_dir}/env/test.env"
printf 'RELEASE=new\n' >"${tmp_dir}/env/runtime.env"
printf 'RELEASE=old\n' >"${tmp_dir}/env/runtime.env.previous"
printf 'IMAGE_REGISTRY=registry.example\nIMAGE_NAMESPACE=inflap\nIMAGE_PREFIX=inflap-\nIMAGE_TAG=old\n' >"${tmp_dir}/env/deploy.env"
printf 'release: new\n' >"${tmp_dir}/docker-compose.test.yml"
printf 'release: old\n' >"${tmp_dir}/docker-compose.test.yml.previous"

cat >"${tmp_dir}/bin/docker" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"${FAKE_DOCKER_LOG}"
if [[ "$*" == *"ps --all --format json"* ]]; then
  printf '%s\n' '{"Service":"api-gateway","ID":"old-api-gateway"}'
elif [[ "${1:-}" == "inspect" ]]; then
  printf '%s\n' 'sha256:old-api-gateway-image'
fi
exit 0
EOF
chmod +x "${tmp_dir}/bin/docker"

cat >"${tmp_dir}/scripts/smoke-check.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if grep -Fq 'release: new' "${COMPOSE_FILE}"; then
  echo "new deployment is unhealthy" >&2
  exit 1
fi
grep -Fq 'release: old' "${COMPOSE_FILE}"
grep -Fq 'RELEASE=old' "${RUNTIME_ENV_FILE}"
grep -Fq 'IMAGE_TAG=old' "${DEPLOY_ENV_FILE}"
echo "previous deployment is healthy"
EOF
chmod +x "${tmp_dir}/scripts/smoke-check.sh"

fake_docker_log="${tmp_dir}/docker.log"
output_file="${tmp_dir}/deploy.out"
if PATH="${tmp_dir}/bin:${PATH}" \
  FAKE_DOCKER_LOG="${fake_docker_log}" \
  APP_DIR="${tmp_dir}" \
  ENV_FILE="${tmp_dir}/env/test.env" \
  RUNTIME_ENV_FILE="${tmp_dir}/env/runtime.env" \
  DEPLOY_ENV_FILE="${tmp_dir}/env/deploy.env" \
  COMPOSE_FILE="${tmp_dir}/docker-compose.test.yml" \
  PREVIOUS_RUNTIME_ENV_FILE="${tmp_dir}/env/runtime.env.previous" \
  PREVIOUS_DEPLOY_ENV_FILE="${tmp_dir}/env/deploy.env.previous" \
  PREVIOUS_COMPOSE_FILE="${tmp_dir}/docker-compose.test.yml.previous" \
  IMAGE_REGISTRY=registry.example \
  IMAGE_NAMESPACE=inflap \
  IMAGE_PREFIX=inflap- \
  IMAGE_TAG=new \
  RUN_POSTGRES_MIGRATIONS=false \
  DEPLOY_SMOKE_RETRIES=1 \
  DEPLOY_SMOKE_RETRY_DELAY_SECONDS=1 \
  "${script}" >"${output_file}" 2>&1; then
  echo "deploy test expected the new deployment to fail" >&2
  exit 1
fi

grep -Fq 'release: old' "${tmp_dir}/docker-compose.test.yml"
grep -Fq 'RELEASE=old' "${tmp_dir}/env/runtime.env"
grep -Fq 'IMAGE_TAG=old' "${tmp_dir}/env/deploy.env"
grep -Fq 'Automatic container rollback completed successfully.' "${output_file}"
grep -Fq 'image: inflap-rollback/api-gateway:previous' "${tmp_dir}/docker-compose.rollback.yml"
grep -Fq 'image tag sha256:old-api-gateway-image inflap-rollback/api-gateway:previous' "${fake_docker_log}"

up_count="$(grep -c ' up -d --remove-orphans' "${fake_docker_log}")"
if [[ "${up_count}" != "2" ]]; then
  echo "deploy test expected two compose up calls, got ${up_count}" >&2
  cat "${fake_docker_log}" >&2
  exit 1
fi

printf 'RELEASE=new\n' >"${tmp_dir}/env/runtime.env"
printf 'RELEASE=old\n' >"${tmp_dir}/env/runtime.env.previous"
printf 'release: new\n' >"${tmp_dir}/docker-compose.test.yml"
printf 'release: old\n' >"${tmp_dir}/docker-compose.test.yml.previous"
: >"${fake_docker_log}"

mkdir -p "${tmp_dir}/secrets/mtls"
printf 'test-ca-certificate\n' >"${tmp_dir}/secrets/mtls/ca.crt"
printf 'test-ca-private-key\n' >"${tmp_dir}/secrets/mtls/ca.key"
provision_marker="${tmp_dir}/mtls-provisioned"

cat >"${tmp_dir}/scripts/generate-mtls-certs.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
: "${MTLS_PROVISION_MARKER:?}"
touch "${MTLS_PROVISION_MARKER}"
EOF
chmod +x "${tmp_dir}/scripts/generate-mtls-certs.sh"

cat >"${tmp_dir}/scripts/preflight-mtls-certs.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
test -f "${MTLS_PROVISION_MARKER:?}"
echo "simulated mTLS preflight failure" >&2
exit 1
EOF
chmod +x "${tmp_dir}/scripts/preflight-mtls-certs.sh"

preflight_output_file="${tmp_dir}/deploy-preflight.out"
if PATH="${tmp_dir}/bin:${PATH}" \
  FAKE_DOCKER_LOG="${fake_docker_log}" \
  APP_DIR="${tmp_dir}" \
  ENV_FILE="${tmp_dir}/env/test.env" \
  RUNTIME_ENV_FILE="${tmp_dir}/env/runtime.env" \
  DEPLOY_ENV_FILE="${tmp_dir}/env/deploy.env" \
  COMPOSE_FILE="${tmp_dir}/docker-compose.test.yml" \
  PREVIOUS_RUNTIME_ENV_FILE="${tmp_dir}/env/runtime.env.previous" \
  PREVIOUS_DEPLOY_ENV_FILE="${tmp_dir}/env/deploy.env.previous" \
  PREVIOUS_COMPOSE_FILE="${tmp_dir}/docker-compose.test.yml.previous" \
  IMAGE_REGISTRY=registry.example \
  IMAGE_NAMESPACE=inflap \
  IMAGE_PREFIX=inflap- \
  IMAGE_TAG=new \
  MTLS_MODE=enforce \
  MTLS_AUTO_PROVISION_CERTS=true \
  MTLS_CERT_GROUP_ID="$(id -g)" \
  MTLS_SECRETS_DIR="${tmp_dir}/secrets/mtls" \
  MTLS_CA_CERT_PATH="${tmp_dir}/secrets/mtls/ca.crt" \
  MTLS_PROVISION_MARKER="${provision_marker}" \
  RUN_POSTGRES_MIGRATIONS=false \
  "${script}" >"${preflight_output_file}" 2>&1; then
  echo "deploy test expected mTLS preflight to fail" >&2
  exit 1
fi

grep -Fq 'release: old' "${tmp_dir}/docker-compose.test.yml"
grep -Fq 'RELEASE=old' "${tmp_dir}/env/runtime.env"
grep -Fq 'IMAGE_TAG=old' "${tmp_dir}/env/deploy.env"
test -f "${provision_marker}"
grep -Fq 'Previous deployment files restored; running containers were not changed.' "${preflight_output_file}"
if grep -Fq ' up -d --remove-orphans' "${fake_docker_log}"; then
  echo "compose up must not run after a failed preflight" >&2
  cat "${fake_docker_log}" >&2
  exit 1
fi

printf 'RELEASE=new\n' >"${tmp_dir}/env/runtime.env"
printf 'RELEASE=old\n' >"${tmp_dir}/env/runtime.env.previous"
printf 'release: new\n' >"${tmp_dir}/docker-compose.test.yml"
printf 'release: old\n' >"${tmp_dir}/docker-compose.test.yml.previous"
: >"${fake_docker_log}"
rm -f "${tmp_dir}/secrets/mtls/ca.key" "${provision_marker}"

missing_ca_key_output_file="${tmp_dir}/deploy-missing-ca-key.out"
if PATH="${tmp_dir}/bin:${PATH}" \
  FAKE_DOCKER_LOG="${fake_docker_log}" \
  APP_DIR="${tmp_dir}" \
  ENV_FILE="${tmp_dir}/env/test.env" \
  RUNTIME_ENV_FILE="${tmp_dir}/env/runtime.env" \
  DEPLOY_ENV_FILE="${tmp_dir}/env/deploy.env" \
  COMPOSE_FILE="${tmp_dir}/docker-compose.test.yml" \
  PREVIOUS_RUNTIME_ENV_FILE="${tmp_dir}/env/runtime.env.previous" \
  PREVIOUS_DEPLOY_ENV_FILE="${tmp_dir}/env/deploy.env.previous" \
  PREVIOUS_COMPOSE_FILE="${tmp_dir}/docker-compose.test.yml.previous" \
  IMAGE_REGISTRY=registry.example \
  IMAGE_NAMESPACE=inflap \
  IMAGE_PREFIX=inflap- \
  IMAGE_TAG=new \
  MTLS_MODE=enforce \
  MTLS_AUTO_PROVISION_CERTS=true \
  MTLS_CERT_GROUP_ID="$(id -g)" \
  MTLS_SECRETS_DIR="${tmp_dir}/secrets/mtls" \
  MTLS_CA_CERT_PATH="${tmp_dir}/secrets/mtls/ca.crt" \
  MTLS_PROVISION_MARKER="${provision_marker}" \
  RUN_POSTGRES_MIGRATIONS=false \
  "${script}" >"${missing_ca_key_output_file}" 2>&1; then
  echo "deploy test expected automatic provisioning without a CA key to fail" >&2
  exit 1
fi

grep -Fq 'release: old' "${tmp_dir}/docker-compose.test.yml"
grep -Fq 'RELEASE=old' "${tmp_dir}/env/runtime.env"
grep -Fq 'refusing to create or replace the CA during deploy' "${missing_ca_key_output_file}"
test ! -e "${provision_marker}"
if grep -Fq ' up -d --remove-orphans' "${fake_docker_log}"; then
  echo "compose up must not run when automatic mTLS provisioning lacks the existing CA key" >&2
  cat "${fake_docker_log}" >&2
  exit 1
fi

printf 'RELEASE=new\n' >"${tmp_dir}/env/runtime.env"
printf 'RELEASE=old\n' >"${tmp_dir}/env/runtime.env.previous"
printf 'release: new\n' >"${tmp_dir}/docker-compose.test.yml"
printf 'release: old\n' >"${tmp_dir}/docker-compose.test.yml.previous"
: >"${fake_docker_log}"

validation_output_file="${tmp_dir}/deploy-validation.out"
if PATH="${tmp_dir}/bin:${PATH}" \
  FAKE_DOCKER_LOG="${fake_docker_log}" \
  APP_DIR="${tmp_dir}" \
  ENV_FILE="${tmp_dir}/env/test.env" \
  RUNTIME_ENV_FILE="${tmp_dir}/env/runtime.env" \
  DEPLOY_ENV_FILE="${tmp_dir}/env/deploy.env" \
  COMPOSE_FILE="${tmp_dir}/docker-compose.test.yml" \
  PREVIOUS_RUNTIME_ENV_FILE="${tmp_dir}/env/runtime.env.previous" \
  PREVIOUS_DEPLOY_ENV_FILE="${tmp_dir}/env/deploy.env.previous" \
  PREVIOUS_COMPOSE_FILE="${tmp_dir}/docker-compose.test.yml.previous" \
  IMAGE_REGISTRY=registry.example \
  IMAGE_NAMESPACE=inflap \
  IMAGE_PREFIX=inflap- \
  IMAGE_TAG=new \
  DEPLOY_SMOKE_RETRIES=invalid \
  RUN_POSTGRES_MIGRATIONS=false \
  "${script}" >"${validation_output_file}" 2>&1; then
  echo "deploy test expected early validation to fail" >&2
  exit 1
fi

grep -Fq 'release: old' "${tmp_dir}/docker-compose.test.yml"
grep -Fq 'RELEASE=old' "${tmp_dir}/env/runtime.env"
grep -Fq 'Deploy validation failed; previous deployment files were restored' "${validation_output_file}"
if [[ -s "${fake_docker_log}" ]]; then
  echo "docker must not run after an early deploy validation failure" >&2
  cat "${fake_docker_log}" >&2
  exit 1
fi

echo "deploy rollback test passed"
