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
