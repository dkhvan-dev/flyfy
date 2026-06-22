#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${AUTH_DEV_BASE_URL:-http://127.0.0.1:8080/api/v1/auth}"
PHONE="${AUTH_DEV_PHONE:-+77019990001}"
REDIS_CONTAINER="${AUTH_DEV_REDIS_CONTAINER:-inflap-redis}"
AUTH_CONTAINER="${AUTH_DEV_AUTH_CONTAINER:-auth-service}"
AUTH_LOG_TAIL="${AUTH_DEV_AUTH_LOG_TAIL:-200}"
OTP_CODE="${AUTH_DEV_OTP_CODE:-}"
TMP_DIR="${TMP_DIR:-$(mktemp -d "${TMPDIR:-/tmp}/inflap-dev-auth.XXXXXX")}"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

need() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 127
  fi
}

json_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

need curl
need jq

send_body="${TMP_DIR}/send.json"
verify_body="${TMP_DIR}/verify.json"

curl -sS \
  --fail \
  -X POST \
  -H 'Content-Type: application/json' \
  --data "{\"phone\":\"$(json_escape "$PHONE")\"}" \
  "${BASE_URL}/phone/send-code" >"$send_body"

if [[ -z "$OTP_CODE" ]]; then
  need docker
  OTP_CODE="$(
    docker exec "$REDIS_CONTAINER" redis-cli GET "otp:${PHONE}" \
      | tr -d '\r' \
      | tail -n 1
  )"
fi

if [[ -z "$OTP_CODE" || "$OTP_CODE" == "(nil)" ]]; then
  need docker
  auth_logs="$(docker logs "$AUTH_CONTAINER" --tail "$AUTH_LOG_TAIL" 2>&1 || true)"
  OTP_CODE="$(
    printf '%s\n' "$auth_logs" \
      | awk -v phone="$PHONE" '
          {
            line = $0
            gsub(/\033\[[0-9;]*[[:alpha:]]/, "", line)
          }
          index(line, "phone=" phone) {
            if (match(line, /code=[0-9]+/)) {
              print substr(line, RSTART + 5, RLENGTH - 5)
            }
          }
        ' \
      | tail -n 1
  )"
fi

if [[ -z "$OTP_CODE" || "$OTP_CODE" == "(nil)" ]]; then
  echo "OTP code was not found for ${PHONE}. Set AUTH_DEV_OTP_CODE or check ${REDIS_CONTAINER}/${AUTH_CONTAINER}." >&2
  exit 1
fi

curl -sS \
  --fail \
  -X POST \
  -H 'Content-Type: application/json' \
  --data "{\"phone\":\"$(json_escape "$PHONE")\",\"code\":\"$(json_escape "$OTP_CODE")\"}" \
  "${BASE_URL}/phone/verify" >"$verify_body"

token="$(jq -r '.access_token // .accessToken // empty' "$verify_body")"
if [[ -z "$token" || "$token" == "null" ]]; then
  echo "Auth service response did not contain an access token" >&2
  cat "$verify_body" >&2
  exit 1
fi

printf '%s\n' "$token"
