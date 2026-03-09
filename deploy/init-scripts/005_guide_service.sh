#!/bin/sh
set -e

echo "Running guide-service migrations..."

for file in /migrations/guide-service/*.up.sql; do
  echo "Applying $file"
  psql -v ON_ERROR_STOP=1 \
    -U "$POSTGRES_USER" \
    -d "$POSTGRES_DB" \
    -f "$file"
done

echo "guide-service migrations applied"