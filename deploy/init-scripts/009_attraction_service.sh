#!/bin/sh
set -e

echo "Running attraction-service migrations..."

for f in /migrations/attraction-service/*.up.sql; do
  echo "Applying $f"
  psql -v ON_ERROR_STOP=1 \
    -U "$POSTGRES_USER" \
    -d "$POSTGRES_DB" \
    -f "$f"
done

echo "attraction-service migrations applied"
