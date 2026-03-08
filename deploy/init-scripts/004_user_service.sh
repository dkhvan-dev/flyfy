#!/bin/sh
set -e

echo "Running user-service migrations..."

for file in /migrations/user-service/*.up.sql; do
  echo "Applying $file"
  psql -v ON_ERROR_STOP=1 \
    -U "$POSTGRES_USER" \
    -d "$POSTGRES_DB" \
    -f "$file"
done

echo "user-service migrations applied"