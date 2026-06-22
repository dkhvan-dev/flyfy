#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${ROUTING_SMOKE_BASE_URL:-http://localhost:8080/api/v1/routing}"
TIMEOUT_SECONDS="${ROUTING_SMOKE_TIMEOUT_SECONDS:-8}"
REQUIRE_ENGINE_SUCCESS="${ROUTING_SMOKE_REQUIRE_ENGINE_SUCCESS:-false}"
EXPECT_TRANSIT_UNAVAILABLE="${ROUTING_SMOKE_EXPECT_TRANSIT_UNAVAILABLE:-true}"
AUTH_TOKEN="${ROUTING_SMOKE_AUTH_TOKEN:-}"
TMP_DIR="${TMP_DIR:-$(mktemp -d "${TMPDIR:-/tmp}/inflap-routing-smoke.XXXXXX")}"

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

need curl
need jq

request_json() {
  local method="$1"
  local path="$2"
  local payload="${3:-}"
  local output="$4"
  local status_file="$5"
  if [[ -n "$payload" ]]; then
    if [[ -n "$AUTH_TOKEN" ]]; then
      curl -sS \
        --max-time "$TIMEOUT_SECONDS" \
        -o "$output" \
        -w '%{http_code}' \
        -X "$method" \
        -H "Authorization: Bearer ${AUTH_TOKEN}" \
        -H 'Content-Type: application/json' \
        --data "$payload" \
        "${BASE_URL}${path}" >"$status_file"
    else
      curl -sS \
        --max-time "$TIMEOUT_SECONDS" \
        -o "$output" \
        -w '%{http_code}' \
        -X "$method" \
        -H 'Content-Type: application/json' \
        --data "$payload" \
        "${BASE_URL}${path}" >"$status_file"
    fi
  else
    if [[ -n "$AUTH_TOKEN" ]]; then
      curl -sS \
        --max-time "$TIMEOUT_SECONDS" \
        -o "$output" \
        -w '%{http_code}' \
        -X "$method" \
        -H "Authorization: Bearer ${AUTH_TOKEN}" \
        "${BASE_URL}${path}" >"$status_file"
    else
      curl -sS \
        --max-time "$TIMEOUT_SECONDS" \
        -o "$output" \
        -w '%{http_code}' \
        -X "$method" \
        "${BASE_URL}${path}" >"$status_file"
    fi
  fi
}

assert_http() {
  local actual="$1"
  local expected="$2"
  local label="$3"
  local body_file="$4"

  if [[ "$actual" != "$expected" ]]; then
    echo "FAIL $label: HTTP $actual, want $expected" >&2
    sed -n '1,40p' "$body_file" >&2 || true
    exit 1
  fi
  echo "PASS $label: HTTP $actual"
}

assert_json() {
  local body_file="$1"
  local jq_filter="$2"
  local label="$3"

  if ! jq -e "$jq_filter" "$body_file" >/dev/null; then
    echo "FAIL $label: JSON assertion failed: $jq_filter" >&2
    sed -n '1,80p' "$body_file" >&2 || true
    exit 1
  fi
  echo "PASS $label"
}

status_body="$TMP_DIR/status.json"
status_code="$TMP_DIR/status.code"
request_json GET /status "" "$status_body" "$status_code"
assert_http "$(cat "$status_code")" 200 "routing status" "$status_body"
assert_json "$status_body" '.status == "ok" or .status == "degraded"' "routing status value"
assert_json "$status_body" '.data.attributionRequired == true' "routing attribution flag"
assert_json "$status_body" '(.engines | type) == "array"' "routing engines list"

profiles_body="$TMP_DIR/profiles.json"
profiles_code="$TMP_DIR/profiles.code"
request_json GET /route-profiles "" "$profiles_body" "$profiles_code"
assert_http "$(cat "$profiles_code")" 200 "route profiles" "$profiles_body"
assert_json "$profiles_body" 'map(.id) | index("tourist_walk") != null' "tourist_walk profile"
assert_json "$profiles_body" 'map(.id) | index("guide_route") != null' "guide_route profile"

route_payload='{"profile":"tourist_walk","points":[{"latitude":43.238949,"longitude":76.889709},{"latitude":43.255058,"longitude":76.912628}]}'
route_body="$TMP_DIR/route.json"
route_code="$TMP_DIR/route.code"
request_json POST /routes "$route_payload" "$route_body" "$route_code"
route_http="$(cat "$route_code")"
if [[ "$REQUIRE_ENGINE_SUCCESS" == "true" ]]; then
  assert_http "$route_http" 200 "tourist route" "$route_body"
  assert_json "$route_body" '.provider != "" and .distanceMeters > 0 and .durationSeconds > 0' "tourist route payload"
elif [[ "$route_http" == "200" ]]; then
  echo "PASS tourist route: HTTP 200"
  assert_json "$route_body" '.provider != "" and .distanceMeters > 0 and .durationSeconds > 0' "tourist route payload"
else
  assert_http "$route_http" 503 "tourist route degraded fallback" "$route_body"
  assert_json "$route_body" '.code == "routing.engine_unavailable"' "tourist route degraded code"
fi

matrix_payload='{"profile":"car_standard","origins":[{"latitude":43.238949,"longitude":76.889709}],"destinations":[{"latitude":43.255058,"longitude":76.912628},{"latitude":43.219,"longitude":76.851}]}'
matrix_body="$TMP_DIR/matrix.json"
matrix_code="$TMP_DIR/matrix.code"
request_json POST /matrix "$matrix_payload" "$matrix_body" "$matrix_code"
matrix_http="$(cat "$matrix_code")"
if [[ "$REQUIRE_ENGINE_SUCCESS" == "true" ]]; then
  assert_http "$matrix_http" 200 "driving matrix" "$matrix_body"
  assert_json "$matrix_body" '.provider != "" and (.rows | length) > 0' "driving matrix payload"
elif [[ "$matrix_http" == "200" ]]; then
  echo "PASS driving matrix: HTTP 200"
  assert_json "$matrix_body" '.provider != "" and (.rows | length) > 0' "driving matrix payload"
else
  assert_http "$matrix_http" 503 "driving matrix degraded fallback" "$matrix_body"
  assert_json "$matrix_body" '.code == "routing.engine_unavailable"' "driving matrix degraded code"
fi

if [[ "$EXPECT_TRANSIT_UNAVAILABLE" == "true" ]]; then
  transit_payload='{"profile":"transit","points":[{"latitude":43.238949,"longitude":76.889709},{"latitude":43.255058,"longitude":76.912628}]}'
  transit_body="$TMP_DIR/transit.json"
  transit_code="$TMP_DIR/transit.code"
  request_json POST /routes "$transit_payload" "$transit_body" "$transit_code"
  assert_http "$(cat "$transit_code")" 503 "transit unavailable" "$transit_body"
  assert_json "$transit_body" '.code == "routing.transit_unavailable" and .kind == "business"' "transit unavailable code"
fi

echo "Routing smoke checks passed for ${BASE_URL}"
