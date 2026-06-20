#!/bin/sh
set -e

echo "Running place-service migrations..."

for f in /migrations/place-service/*.up.sql; do
  echo "Applying $f"
  psql -v ON_ERROR_STOP=1 \
    -U "$POSTGRES_USER" \
    -d "$POSTGRES_DB" \
    -f "$f"
done

echo "place-service migrations applied"
