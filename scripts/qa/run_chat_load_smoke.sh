#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

cd "$ROOT_DIR"
GOWORK=off GOCACHE="${GOCACHE:-/private/tmp/inflap-go-build}" go run ./scripts/qa/chat_load_smoke.go "$@"
