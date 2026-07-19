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

mkdir -p "${tmp_dir}/bin"
fake_docker_log="${tmp_dir}/docker.log"
cat >"${tmp_dir}/bin/docker" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"${FAKE_DOCKER_LOG}"
if [[ "$*" == *"ps -q postgres"* ]]; then
  printf '%s\n' 'postgres-container-id'
fi
SH
chmod +x "${tmp_dir}/bin/docker"

PATH="${tmp_dir}/bin:${PATH}" \
FAKE_DOCKER_LOG="${fake_docker_log}" \
APP_DIR="${tmp_dir}" \
COMPOSE_FILE="${tmp_dir}/docker-compose.test.yml" \
MIGRATION_SERVICE_MAP="demo-service:demo_db" \
SEED_TOKEN_SERVICE_ACCOUNTS=false \
bash "${script_dir}/migrate-postgres.sh" >/dev/null

grep -Fq 'TARGET_DATABASE=demo_db' "${fake_docker_log}" || {
  echo "migration runner did not pass the target database to the bootstrap step" >&2
  exit 1
}
grep -Fq 'createdb -U "$POSTGRES_USER" --owner "$POSTGRES_USER" "$TARGET_DATABASE"' "${fake_docker_log}" || {
  echo "migration runner does not create a database missing from an existing PostgreSQL volume" >&2
  exit 1
}

if APP_DIR="${tmp_dir}" \
  COMPOSE_FILE="${tmp_dir}/docker-compose.test.yml" \
  MIGRATION_SERVICE_MAP="demo-service:unsafe-name;drop" \
  MIGRATIONS_DRY_RUN=true \
  bash "${script_dir}/migrate-postgres.sh" >/dev/null 2>&1; then
  echo "migration runner accepted an unsafe database name" >&2
  exit 1
fi

echo "migrate-postgres contract test passed"
