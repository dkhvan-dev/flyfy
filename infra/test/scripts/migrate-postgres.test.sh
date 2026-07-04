#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT

mkdir -p "${tmp_dir}/env" "${tmp_dir}/migrations/demo-service"
cat >"${tmp_dir}/env/test.env" <<'ENV'
POSTGRES_PASSWORD=test-password
ENV
cat >"${tmp_dir}/migrations/demo-service/001_init.up.sql" <<'SQL'
CREATE TABLE demo(id TEXT PRIMARY KEY);
SQL
touch "${tmp_dir}/docker-compose.test.yml"

output="$(
  APP_DIR="${tmp_dir}" \
  COMPOSE_FILE="${tmp_dir}/docker-compose.test.yml" \
  MIGRATION_SERVICE_MAP="demo-service:demo_db" \
  MIGRATIONS_DRY_RUN=true \
  bash "${script_dir}/migrate-postgres.sh"
)"

case "${output}" in
  *"demo-service -> demo_db: 1 migration(s), script=-"*) ;;
  *)
    echo "unexpected dry-run output:" >&2
    echo "${output}" >&2
    exit 1
    ;;
esac

echo "migrate-postgres dry-run test passed"
