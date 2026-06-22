#!/usr/bin/env bash
set -euo pipefail

compose_file="${1:-deploy/docker-compose.yml}"

if [[ ! -f "${compose_file}" ]]; then
  echo "Compose file not found: ${compose_file}" >&2
  exit 1
fi

service_block() {
  local service="$1"
  awk -v service="  ${service}:" '
    $0 == service { inside = 1; print; next }
    inside && $0 ~ /^  [A-Za-z0-9_-]+:/ { exit }
    inside { print }
  ' "${compose_file}"
}

require_top_level_service() {
  local service="$1"
  if ! grep -qE "^  ${service}:" "${compose_file}"; then
    echo "Missing top-level compose service: ${service}" >&2
    exit 1
  fi
}

require_in_block() {
  local service="$1"
  local pattern="$2"
  local message="$3"
  if ! service_block "${service}" | grep -qE "${pattern}"; then
    echo "${message}" >&2
    exit 1
  fi
}

require_top_level_service routing-service
require_top_level_service valhalla
require_top_level_service osrm

require_in_block routing-service '^    healthcheck:' \
  "routing-service must expose a compose healthcheck"
require_in_block routing-service 'ROUTING_TRANSIT_ENABLED:' \
  "routing-service must declare ROUTING_TRANSIT_ENABLED"
require_in_block routing-service 'ROUTING_TRANSIT_CITY_CODE:' \
  "routing-service must declare ROUTING_TRANSIT_CITY_CODE"
require_in_block routing-service 'ROUTING_TRANSIT_GTFS_VERSION:' \
  "routing-service must declare ROUTING_TRANSIT_GTFS_VERSION"
require_in_block routing-service 'ROUTING_OSM_DATA_VERSION: "\$\{ROUTING_OSM_DATA_VERSION:-dev\}"' \
  "routing-service must allow ROUTING_OSM_DATA_VERSION to come from routing-data.env"
require_in_block routing-service 'ROUTING_DATA_GENERATED_AT: "\$\{ROUTING_DATA_GENERATED_AT:-\}"' \
  "routing-service must allow ROUTING_DATA_GENERATED_AT to come from routing-data.env"
if service_block routing-service | grep -q 'ROUTING_GTFS_VERSION:'; then
  echo "routing-service compose env must use ROUTING_TRANSIT_GTFS_VERSION, not legacy ROUTING_GTFS_VERSION" >&2
  exit 1
fi
require_in_block api-gateway 'routing-service:' \
  "api-gateway must depend on routing-service"
require_in_block api-gateway 'condition: service_healthy' \
  "api-gateway must wait for routing-service health"
require_in_block valhalla 'profiles:' \
  "valhalla must be opt-in through a compose profile"
require_in_block valhalla 'entrypoint:' \
  "valhalla must override the image wrapper entrypoint so valhalla_service can start"
require_in_block osrm 'profiles:' \
  "osrm must be opt-in through a compose profile"
require_in_block osrm '\$\{OSRM_HOST_PORT:-5001\}:5000' \
  "osrm host port must be configurable and default to 5001 to avoid common macOS port 5000 conflicts"
if service_block valhalla | grep -q 'wget'; then
  echo "valhalla healthcheck must not depend on wget because the selected image does not provide it" >&2
  exit 1
fi
if service_block osrm | grep -q 'wget'; then
  echo "osrm healthcheck must not depend on wget because the selected image does not provide it" >&2
  exit 1
fi

echo "Routing compose checks passed"
