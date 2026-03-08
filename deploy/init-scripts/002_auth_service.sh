#!/bin/bash
set -e

echo "Running auth-service migrations..."
export PGPASSWORD=auth_secret_dev

psql -v ON_ERROR_STOP=1 \
  --username "auth_service" \
  --dbname "auth_db" \
  -f /migrations/auth-service/001_init.up.sql

echo "auth-service migrations completed."