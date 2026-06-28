#!/bin/sh
set -eu

export PGPASSWORD="${POSTGRES_PASSWORD}"

psql_cmd() {
  psql \
    -v ON_ERROR_STOP=1 \
    -h "${PGHOST}" \
    -p "${PGPORT}" \
    -U "${POSTGRES_USER}" \
    -d "${POSTGRES_DB}" \
    "$@"
}

query_scalar() {
  psql_cmd -tAc "$1" | tr -d '[:space:]'
}

mark_applied() {
  filename="$1"
  psql_cmd -c "INSERT INTO schema_migrations (filename) VALUES ('$filename') ON CONFLICT (filename) DO NOTHING;" >/dev/null
}

psql_cmd -c "
  CREATE TABLE IF NOT EXISTS schema_migrations (
    filename TEXT PRIMARY KEY,
    applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
  );
" >/dev/null

if [ "$(query_scalar "SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'user_routes' LIMIT 1;")" = "1" ]; then
  mark_applied "001_user_routes.up.sql"
fi

if [ "$(query_scalar "SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'user_routes' AND column_name = 'moderation_status' LIMIT 1;")" = "1" ] &&
  [ "$(query_scalar "SELECT 1 FROM pg_constraint WHERE conrelid = 'public.user_routes'::regclass AND conname = 'user_routes_moderation_status_check' LIMIT 1;")" = "1" ] &&
  [ "$(query_scalar "SELECT 1 WHERE to_regclass('public.idx_user_routes_moderation_updated') IS NOT NULL LIMIT 1;")" = "1" ] &&
  [ "$(query_scalar "SELECT 1 WHERE to_regclass('public.idx_user_routes_public_city_updated') IS NOT NULL LIMIT 1;")" = "1" ]; then
  mark_applied "002_user_route_moderation.up.sql"
fi

for migration in /migrations/user-route-service/*.up.sql; do
  filename="$(basename "$migration")"
  if [ "$(query_scalar "SELECT 1 FROM schema_migrations WHERE filename = '$filename' LIMIT 1;")" = "1" ]; then
    echo "Skipping $filename"
    continue
  fi

  echo "Applying user-route-service migration: ${migration}"
  psql_cmd -f "${migration}"
  mark_applied "$filename"
done
