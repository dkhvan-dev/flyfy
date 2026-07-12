#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
compose_file="${repo_root}/infra/test/docker-compose.test.yml"
preflight_file="${repo_root}/infra/test/scripts/preflight-mtls-certs.sh"
workflow_file="${repo_root}/.github/workflows/deploy-test.yml"

translation_service="$(sed -n '/^  translation-service:/,/^networks:/p' "${compose_file}")"
for expected in \
  'MTLS_CLIENT_CERT_PATH: /opt/inflap/secrets/mtls/translation-service/client.crt' \
  'MTLS_CLIENT_KEY_PATH: /opt/inflap/secrets/mtls/translation-service/client.key' \
  '      - egress'
do
  grep -Fq -- "${expected}" <<<"${translation_service}" || {
    echo "translation-service deployment config is missing: ${expected}" >&2
    exit 1
  }
done

token_service="$(sed -n '/^  token-service:/,/^  auth-service:/p' "${compose_file}")"
for expected in \
  'spiffe://inflap/test/translation-service' \
  'support-service,translation-service,user-service'
do
  grep -Fq -- "${expected}" <<<"${token_service}" || {
    echo "token-service mTLS allowlist is missing: ${expected}" >&2
    exit 1
  }
done

client_services="$(sed -n '/^client_services=(/,/^)/p' "${preflight_file}")"
grep -Fq '  translation-service' <<<"${client_services}" || {
  echo "mTLS preflight does not validate the translation-service client certificate" >&2
  exit 1
}

for expected in \
  '/opt/inflap/docker-compose.test.yml.previous' \
  '/opt/inflap/env/runtime.env.previous' \
  "MTLS_MODE='\${MTLS_MODE}'" \
  '/opt/inflap/scripts/deploy.sh'
do
  grep -Fq -- "${expected}" "${workflow_file}" || {
    echo "deploy workflow transaction wiring is missing: ${expected}" >&2
    exit 1
  }
done

grep -Fq 'go-version-file: proto/go.mod' "${workflow_file}" || {
  echo "deploy workflow must resolve Go from the tracked proto/go.mod file" >&2
  exit 1
}
if grep -Fq 'go-version-file: go.work' "${workflow_file}"; then
  echo "deploy workflow must not depend on the gitignored local go.work file" >&2
  exit 1
fi
grep -Fq -- '--env-file infra/test/env/.env.test.example' "${workflow_file}" || {
  echo "deploy workflow must render Compose with the tracked test env template" >&2
  exit 1
}
if grep -Fq -- '--no-interpolate' "${workflow_file}"; then
  echo "deploy workflow must not validate short volume syntax with unresolved interpolation" >&2
  exit 1
fi

echo "deployment config contract test passed"
