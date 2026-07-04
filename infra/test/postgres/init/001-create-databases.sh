#!/usr/bin/env sh
set -eu

databases="${INFLAP_POSTGRES_DATABASES:-}"

if [ -z "$databases" ]; then
  echo "No INFLAP_POSTGRES_DATABASES configured; skipping extra database creation."
  exit 0
fi

for db in $databases; do
  echo "Ensuring PostgreSQL database exists: $db"
  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -v db="$db" <<'SQL'
SELECT 'CREATE DATABASE ' || quote_ident(:'db')
WHERE NOT EXISTS (
  SELECT 1 FROM pg_database WHERE datname = :'db'
)
\gexec
SQL

  echo "Ensuring PostGIS extension exists in: $db"
  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$db" <<'SQL'
CREATE EXTENSION IF NOT EXISTS postgis;
SQL
done
