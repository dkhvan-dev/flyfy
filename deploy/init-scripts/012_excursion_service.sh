#!/bin/sh
set -e

echo "Running excursion-service migrations..."

psql_cmd() {
  psql -v ON_ERROR_STOP=1 \
    -U "$POSTGRES_USER" \
    -d "$POSTGRES_DB" \
    "$@"
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

for f in /migrations/excursion-service/*.up.sql; do
  filename="$(basename "$f")"
  echo "Applying $filename"
  psql_cmd -f "$f"
  mark_applied "$filename"
done

echo "excursion-service migrations applied"
