#!/usr/bin/env sh
set -eu

: "${SERVICE_NAME:?SERVICE_NAME is required}"
: "${POSTGRES_DB:?POSTGRES_DB is required}"
: "${POSTGRES_USER:?POSTGRES_USER is required}"
: "${POSTGRES_PASSWORD:?POSTGRES_PASSWORD is required}"

PGHOST="${PGHOST:-127.0.0.1}"
PGPORT="${PGPORT:-5432}"
MIGRATION_DIR="${MIGRATION_DIR:-/migrations/${SERVICE_NAME}}"

export LC_ALL=C
export PGPASSWORD="${POSTGRES_PASSWORD}"

psql_base() {
  psql \
    -v ON_ERROR_STOP=1 \
    -h "${PGHOST}" \
    -p "${PGPORT}" \
    -U "${POSTGRES_USER}" \
    "$@"
}

psql_cmd() {
  psql_base -d "${POSTGRES_DB}" "$@"
}

query_scalar() {
  psql_cmd -tAc "$1" | tr -d '[:space:]'
}

sql_literal() {
  printf "%s" "$1" | sed "s/'/''/g"
}

query_migration_applied() {
  filename="$1"
  escaped_filename="$(sql_literal "${filename}")"
  psql_cmd -tAc "SELECT 1 FROM schema_migrations WHERE filename = '${escaped_filename}' LIMIT 1;" | tr -d '[:space:]'
}

mark_migration_applied() {
  filename="$1"
  escaped_filename="$(sql_literal "${filename}")"
  psql_cmd -c "INSERT INTO schema_migrations (filename) VALUES ('${escaped_filename}') ON CONFLICT (filename) DO NOTHING;" >/dev/null
}

if [ ! -d "${MIGRATION_DIR}" ]; then
  echo "Missing migration directory for ${SERVICE_NAME}: ${MIGRATION_DIR}" >&2
  exit 1
fi

echo "Ensuring PostgreSQL database exists: ${POSTGRES_DB}"
psql_base -d postgres -v db="${POSTGRES_DB}" <<'SQL'
SELECT 'CREATE DATABASE ' || quote_ident(:'db')
WHERE NOT EXISTS (
  SELECT 1 FROM pg_database WHERE datname = :'db'
)
\gexec
SQL

echo "Ensuring PostGIS extension exists in: ${POSTGRES_DB}"
psql_cmd -c "CREATE EXTENSION IF NOT EXISTS postgis;" >/dev/null

psql_cmd -c "
  CREATE TABLE IF NOT EXISTS schema_migrations (
    filename TEXT PRIMARY KEY,
    applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
  );
" >/dev/null

found=0
for file in "${MIGRATION_DIR}"/*.up.sql; do
  if [ ! -e "${file}" ]; then
    break
  fi

  found=1
  filename="$(basename "${file}")"
  if [ "$(query_migration_applied "${filename}")" = "1" ]; then
    echo "Skipping ${SERVICE_NAME}/${filename}"
    continue
  fi

  echo "Applying ${SERVICE_NAME}/${filename}"
  psql_cmd -f "${file}"
  mark_migration_applied "${filename}"
done

if [ "${found}" -eq 0 ]; then
  echo "No *.up.sql migrations found for ${SERVICE_NAME} in ${MIGRATION_DIR}" >&2
  exit 1
fi

echo "Pending ${SERVICE_NAME} migrations applied"
