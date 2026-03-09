#!/bin/sh
set -e

echo "Running activity-service migrations..."

for f in /migrations/activity-service/*.up.sql; do
  echo "Applying $f"
  psql -v ON_ERROR_STOP=1 \
    -U "$POSTGRES_USER" \
    -d "$POSTGRES_DB" \
    -f "$f"
done

echo "activity-service migrations applied"