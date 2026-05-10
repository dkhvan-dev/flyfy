#!/bin/sh
set -e

echo "Running tour-service migrations..."

for f in /migrations/tour-service/*.up.sql; do
  echo "Applying $f"
  psql -v ON_ERROR_STOP=1 \
    -U "$POSTGRES_USER" \
    -d "$POSTGRES_DB" \
    -f "$f"
done

echo "tour-service migrations applied"