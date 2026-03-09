#!/bin/sh
set -e

echo "Running file-manager-service migrations..."

for f in /migrations/file-manager-service/*.up.sql; do
  echo "Applying $f"
  psql -v ON_ERROR_STOP=1 \
    -U "$POSTGRES_USER" \
    -d "$POSTGRES_DB" \
    -f "$f"
done

echo "file-manager-service migrations applied"