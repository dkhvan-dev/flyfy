#!/bin/sh
set -eu

echo "Running pending user-service migrations..."

: "${PGHOST:=user-postgres}"
: "${PGPORT:=5432}"
: "${POSTGRES_DB:?POSTGRES_DB is required}"
: "${POSTGRES_USER:?POSTGRES_USER is required}"
: "${POSTGRES_PASSWORD:?POSTGRES_PASSWORD is required}"

export PGPASSWORD="$POSTGRES_PASSWORD"

psql_cmd() {
  psql -v ON_ERROR_STOP=1 \
    -h "$PGHOST" \
    -p "$PGPORT" \
    -U "$POSTGRES_USER" \
    -d "$POSTGRES_DB" \
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

if [ "$(query_scalar "SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'users' LIMIT 1;")" = "1" ]; then
  mark_applied "000001_init_user_service.up.sql"
fi

if [ "$(query_scalar "SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'user_profiles' AND column_name = 'is_profile_completed' LIMIT 1;")" = "1" ]; then
  mark_applied "002_add_profile_completion.up.sql"
fi

if [ "$(query_scalar "SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND indexname = 'uq_user_profiles_display_name_ci' LIMIT 1;")" = "1" ]; then
  mark_applied "003_add_unique_display_name.up.sql"
fi

for file in /migrations/user-service/*.up.sql; do
  filename="$(basename "$file")"
  if [ "$(query_scalar "SELECT 1 FROM schema_migrations WHERE filename = '$filename' LIMIT 1;")" = "1" ]; then
    echo "Skipping $filename"
    continue
  fi

  echo "Applying $filename"
  psql_cmd -f "$file"
  mark_applied "$filename"
done

echo "Pending user-service migrations applied"
