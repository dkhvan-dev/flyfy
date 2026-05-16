#!/bin/sh
set -eu

echo "Running pending guide-service migrations..."

: "${PGHOST:=guide-postgres}"
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

# Bootstrap migration history for local volumes initialized by the postgres
# entrypoint before schema_migrations tracking was added.
if [ "$(query_scalar "SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'guide_profiles' LIMIT 1;")" = "1" ]; then
  mark_applied "000001_init_guide_service.up.sql"
fi

if [ "$(query_scalar "SELECT 1 WHERE to_regclass('public.idx_guide_profiles_public_rating') IS NOT NULL;")" = "1" ]; then
  mark_applied "000002_public_guide_discovery_indexes.up.sql"
fi

if [ "$(query_scalar "SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'guide_profiles' AND column_name = 'is_excursion_guide_available' LIMIT 1;")" = "1" ] &&
   [ "$(query_scalar "SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'guide_profiles' AND column_name = 'is_tour_guide_available' LIMIT 1;")" != "1" ]; then
  mark_applied "000003_rename_tour_guide_availability_to_excursion.up.sql"
fi

for file in /migrations/guide-service/*.up.sql; do
  filename="$(basename "$file")"
  if [ "$(query_scalar "SELECT 1 FROM schema_migrations WHERE filename = '$filename' LIMIT 1;")" = "1" ]; then
    echo "Skipping $filename"
    continue
  fi

  echo "Applying $filename"
  psql_cmd -f "$file"
  mark_applied "$filename"
done

echo "Pending guide-service migrations applied"
