#!/bin/sh
set -eu

echo "Running pending token-service migrations..."

: "${PGHOST:=token-postgres}"
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

if [ "$(query_scalar "SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'service_accounts' LIMIT 1;")" = "1" ]; then
  mark_applied "001_init.up.sql"
fi

if [ "$(query_scalar "SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'user_sessions' LIMIT 1;")" = "1" ]; then
  mark_applied "002_user_sessions.up.sql"
fi

for file in /migrations/token-service/*.up.sql; do
  filename="$(basename "$file")"
  if [ "$(query_scalar "SELECT 1 FROM schema_migrations WHERE filename = '$filename' LIMIT 1;")" = "1" ]; then
    echo "Skipping $filename"
    continue
  fi

  echo "Applying $filename"
  psql_cmd -f "$file"
  mark_applied "$filename"
done

if [ "${SEED_TOKEN_SERVICE_ACCOUNTS:-true}" = "true" ] && [ -f /usr/local/bin/001_token_service_seed_services.sh ]; then
  echo "Seeding token-service service accounts..."
  /bin/sh /usr/local/bin/001_token_service_seed_services.sh
fi

echo "Pending token-service migrations applied"
