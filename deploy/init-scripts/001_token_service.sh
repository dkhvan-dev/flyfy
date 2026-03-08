#!/bin/bash
set -e

echo "Running token-service migrations..."
psql -v ON_ERROR_STOP=1 \
  --username "token_service" \
  --dbname "token_service" \
  -f /migrations/token-service/001_init.up.sql

echo "token-service migrations completed."
