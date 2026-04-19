#!/bin/sh
set -e

echo "Running chat-service migrations..."

for f in /migrations/chat-service/*.up.sql; do
  echo "Applying $f"
  psql -v ON_ERROR_STOP=1 \
    -U "$POSTGRES_USER" \
    -d "$POSTGRES_DB" \
    -f "$f"
done

echo "chat-service migrations applied"
