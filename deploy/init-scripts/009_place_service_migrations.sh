#!/bin/sh
set -eu

echo "Running pending place-service migrations..."

: "${PGHOST:=place-postgres}"
: "${PGPORT:=5432}"
: "${POSTGRES_DB:?POSTGRES_DB is required}"
: "${POSTGRES_USER:?POSTGRES_USER is required}"
: "${POSTGRES_PASSWORD:?POSTGRES_PASSWORD is required}"

export PGPASSWORD="$POSTGRES_PASSWORD"
export LC_ALL=C

psql_cmd() {
  psql -v ON_ERROR_STOP=1 \
    -h "$PGHOST" \
    -p "$PGPORT" \
    -U "$POSTGRES_USER" \
    -d "$POSTGRES_DB" \
    "$@"
}

psql_concurrent_cmd() {
  PGOPTIONS="${PGOPTIONS:-} -c lock_timeout=5s -c statement_timeout=30min" \
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

mark_concurrent_applied() {
  filename="$1"
  checksum="$2"
  psql_cmd -c "
    INSERT INTO schema_migrations (filename, checksum)
    VALUES ('$filename', '$checksum')
    ON CONFLICT (filename) DO NOTHING;
  " >/dev/null
}

assert_no_invalid_indexes() {
  invalid_count="$(query_scalar "
    SELECT count(*)
    FROM pg_index
    WHERE NOT indisvalid OR NOT indisready;
  ")"
  if [ "$invalid_count" != "0" ]; then
    echo "Refusing to mark a concurrent migration applied: PostgreSQL reports ${invalid_count} invalid or unfinished index(es). Repair or drop them before retrying." >&2
    exit 1
  fi
}

psql_cmd -c "
  CREATE TABLE IF NOT EXISTS schema_migrations (
    filename TEXT PRIMARY KEY,
    checksum TEXT,
    applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
  );
  ALTER TABLE schema_migrations ADD COLUMN IF NOT EXISTS checksum TEXT;
" >/dev/null

if [ "$(query_scalar "SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'places' LIMIT 1;")" = "1" ]; then
  psql_cmd -c "
    INSERT INTO schema_migrations (filename)
    VALUES ('001_init.up.sql')
    ON CONFLICT (filename) DO NOTHING;
  " >/dev/null
fi

# The migrator is the sole schema owner; PostgreSQL init does not replay files.
for file in /migrations/place-service/*.up.sql; do
  if [ ! -f "$file" ]; then
    echo "No place-service migrations found" >&2
    exit 1
  fi

  filename="$(basename "$file")"
  checksum="$(sha256sum "$file" | awk '{print $1}')"
  applied_checksum="$(query_scalar "SELECT COALESCE(checksum, '') FROM schema_migrations WHERE filename = '$filename' LIMIT 1;")"
  if [ -n "$applied_checksum" ]; then
    if [ "$applied_checksum" != "$checksum" ]; then
      echo "Checksum drift detected for applied migration $filename" >&2
      exit 1
    fi
    echo "Skipping $filename (checksum verified)"
    continue
  fi
  if [ "$(query_scalar "SELECT 1 FROM schema_migrations WHERE filename = '$filename' LIMIT 1;")" = "1" ]; then
    echo "Adopting checksum for legacy marker $filename"
    psql_cmd -c "UPDATE schema_migrations SET checksum = '$checksum' WHERE filename = '$filename' AND checksum IS NULL;" >/dev/null
    continue
  fi

  echo "Applying $filename"
  if grep -Eiq 'CREATE[[:space:]]+(UNIQUE[[:space:]]+)?INDEX[[:space:]]+CONCURRENTLY' "$file"; then
    psql_concurrent_cmd -f "$file"
    assert_no_invalid_indexes
    mark_concurrent_applied "$filename" "$checksum"
  else
    psql_cmd --single-transaction \
      -f "$file" \
      -c "INSERT INTO schema_migrations (filename, checksum) VALUES ('$filename', '$checksum');"
  fi
done

echo "Pending place-service migrations applied"
