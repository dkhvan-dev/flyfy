#!/bin/sh
set -eu

export PGPASSWORD="${POSTGRES_PASSWORD}"

for migration in /migrations/user-route-service/*.up.sql; do
  echo "Applying user-route-service migration: ${migration}"
  psql \
    -v ON_ERROR_STOP=1 \
    -h "${PGHOST}" \
    -p "${PGPORT}" \
    -U "${POSTGRES_USER}" \
    -d "${POSTGRES_DB}" \
    -f "${migration}"
done
