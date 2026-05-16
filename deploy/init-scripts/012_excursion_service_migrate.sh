#!/bin/sh
set -eu

echo "Running pending excursion-service migrations..."

: "${PGHOST:=excursion-postgres}"
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
if [ "$(query_scalar "SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'excursions' LIMIT 1;")" = "1" ]; then
  mark_applied "001_init.up.sql"
fi

if [ "$(query_scalar "SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'excursion_products' LIMIT 1;")" = "1" ]; then
  mark_applied "002_marketplace_schema.up.sql"
fi

if [ "$(query_scalar "SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'excursion_bookings' LIMIT 1;")" = "1" ]; then
  mark_applied "004_excursion_bookings.up.sql"
fi

if [ "$(query_scalar "SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'excursion_offers' AND column_name = 'guide_rating_avg' LIMIT 1;")" = "1" ]; then
  mark_applied "005_excursion_offer_guide_sort_snapshot.up.sql"
fi

if [ "$(query_scalar "SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'excursion_offers' AND column_name = 'guide_search_text' LIMIT 1;")" = "1" ]; then
  mark_applied "006_excursion_offer_guide_search_snapshot.up.sql"
fi

if [ "$(query_scalar "SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'excursion_products' AND column_name = 'translations' LIMIT 1;")" = "1" ]; then
  mark_applied "007_excursion_translations.up.sql"
fi

if [ "$(query_scalar "SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'excursion_offer_included_items' AND column_name = 'translations' LIMIT 1;")" = "1" ]; then
  mark_applied "008_offer_content_translations.up.sql"
fi

for file in /migrations/excursion-service/*.up.sql; do
  filename="$(basename "$file")"
  if [ "$(query_scalar "SELECT 1 FROM schema_migrations WHERE filename = '$filename' LIMIT 1;")" = "1" ]; then
    echo "Skipping $filename"
    continue
  fi

  echo "Applying $filename"
  psql_cmd -f "$file"
  mark_applied "$filename"
done

echo "Pending excursion-service migrations applied"
