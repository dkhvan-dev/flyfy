#!/bin/sh
set -e

echo "Running anti-fraud-service migrations..."

for f in /migrations/anti-fraud-service/*.up.sql; do
  echo "Applying $f"
  psql -v ON_ERROR_STOP=1 \
    -U "$POSTGRES_USER" \
    -d "$POSTGRES_DB" \
    -f "$f"
done

echo "anti-fraud-service migrations applied"
