#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Validate an Inflap internal mTLS certificate bundle before enabling permissive
or enforce mode.

Usage:
  preflight-mtls-certs.sh [options]

Options:
  --secrets-dir DIR       Bundle directory. Default: $MTLS_SECRETS_DIR or /opt/inflap/secrets/mtls
  --ca-cert FILE          CA certificate. Default: $MTLS_CA_CERT_PATH or <secrets-dir>/ca.crt
  --env NAME              Identity environment segment. Default: $INFLAP_ENV or test
  --min-valid-days N      Minimum remaining validity in days. Default: $MTLS_MIN_VALID_DAYS or 1
  -h, --help              Show this help
USAGE
}

fail() {
  echo "preflight-mtls-certs: $*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "missing required command: $1"
}

validate_positive_int() {
  local name="$1"
  local value="$2"
  [[ "${value}" =~ ^[1-9][0-9]*$ ]] || fail "${name} must be a positive integer"
}

secrets_dir="${MTLS_SECRETS_DIR:-/opt/inflap/secrets/mtls}"
ca_cert="${MTLS_CA_CERT_PATH:-}"
identity_env="${INFLAP_ENV:-test}"
min_valid_days="${MTLS_MIN_VALID_DAYS:-1}"
cert_group_id="${MTLS_CERT_GROUP_ID:-1001}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --secrets-dir)
      [[ $# -ge 2 ]] || fail "--secrets-dir requires a value"
      secrets_dir="$2"
      shift 2
      ;;
    --ca-cert)
      [[ $# -ge 2 ]] || fail "--ca-cert requires a value"
      ca_cert="$2"
      shift 2
      ;;
    --env)
      [[ $# -ge 2 ]] || fail "--env requires a value"
      identity_env="$2"
      shift 2
      ;;
    --min-valid-days)
      [[ $# -ge 2 ]] || fail "--min-valid-days requires a value"
      min_valid_days="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail "unknown option: $1"
      ;;
  esac
done

require_command openssl
validate_positive_int "--min-valid-days" "${min_valid_days}"
validate_positive_int "MTLS_CERT_GROUP_ID" "${cert_group_id}"
[[ "${identity_env}" =~ ^[A-Za-z0-9._-]+$ ]] || fail "--env may contain only letters, numbers, dot, underscore, and hyphen"

secrets_dir="$(cd "${secrets_dir}" 2>/dev/null && pwd -P)" || fail "missing mTLS secrets directory: ${secrets_dir}"
if [[ -z "${ca_cert}" ]]; then
  ca_cert="${secrets_dir}/ca.crt"
fi
[[ -r "${ca_cert}" ]] || fail "missing readable CA certificate: ${ca_cert}"

server_services=(
  admin-panel
  anti-fraud-service
  activity-service
  auth-service
  chat-service
  checklist-service
  currency-service
  excursion-service
  feed-service
  file-manager-service
  guide-service
  notification-service
  payment-service
  place-service
  reference-service
  routing-service
  search-service
  sticker-service
  support-service
  switches-service
  token-service
  translation-service
  trust-service
  user-route-service
  user-service
)

client_services=(
  admin-panel
  api-gateway
  activity-service
  auth-service
  chat-service
  checklist-service
  currency-service
  excursion-service
  feed-service
  file-manager-service
  guide-service
  payment-service
  place-service
  search-service
  sticker-service
  support-service
  token-service
  translation-service
  user-service
)

seconds=$((min_valid_days * 86400))

group_perm_digit() {
  local path="$1"
  local mode
  mode="$(stat -c '%a' "${path}" 2>/dev/null)" || fail "stat failed: ${path}"
  mode="${mode: -3}"
  printf '%s' "${mode:1:1}"
}

check_group_access() {
  local path="$1"
  local required_bits="$2"
  local gid
  local group_digit

  gid="$(stat -c '%g' "${path}" 2>/dev/null)" || fail "stat failed: ${path}"
  [[ "${gid}" == "${cert_group_id}" ]] || \
    fail "mTLS bundle path must be owned by group GID ${cert_group_id} for container read access: ${path} has GID ${gid}"

  group_digit="$(group_perm_digit "${path}")"
  if (( (group_digit & required_bits) != required_bits )); then
    fail "mTLS bundle path lacks required group permission ${required_bits}: ${path}"
  fi
}

check_not_expiring() {
  local file="$1"
  openssl x509 -in "${file}" -checkend "${seconds}" -noout >/dev/null 2>&1 || \
    fail "certificate expires within ${min_valid_days} day(s): ${file}"
}

check_key_matches_cert() {
  local cert="$1"
  local key="$2"
  local cert_mod
  local key_mod

  cert_mod="$(openssl x509 -noout -modulus -in "${cert}" 2>/dev/null | openssl sha256)"
  key_mod="$(openssl rsa -noout -modulus -in "${key}" 2>/dev/null | openssl sha256)"
  [[ -n "${cert_mod}" && "${cert_mod}" == "${key_mod}" ]] || fail "private key does not match certificate: ${cert}"
}

check_service_ca_copy() {
  local service="$1"
  local service_ca="${secrets_dir}/${service}/ca.crt"

  [[ -r "${service_ca}" ]] || fail "missing readable service CA certificate copy: ${service_ca}"
  cmp -s "${ca_cert}" "${service_ca}" || fail "service CA certificate copy does not match root CA: ${service_ca}"
}

check_leaf() {
  local service="$1"
  local role="$2"
  local expected_eku="$3"
  local cert="${secrets_dir}/${service}/${role}.crt"
  local key="${secrets_dir}/${service}/${role}.key"
  local san
  local eku

  [[ -r "${cert}" ]] || fail "missing readable certificate: ${cert}"
  [[ -r "${key}" ]] || fail "missing readable private key: ${key}"
  check_group_access "${secrets_dir}/${service}" 5
  check_group_access "${cert}" 4
  check_group_access "${key}" 4
  check_not_expiring "${cert}"
  openssl verify -CAfile "${ca_cert}" "${cert}" >/dev/null 2>&1 || fail "certificate is not signed by CA: ${cert}"
  check_key_matches_cert "${cert}" "${key}"

  san="$(openssl x509 -in "${cert}" -noout -ext subjectAltName 2>/dev/null || true)"
  grep -F "URI:spiffe://inflap/${identity_env}/${service}" <<<"${san}" >/dev/null || \
    fail "certificate missing SPIFFE URI SAN spiffe://inflap/${identity_env}/${service}: ${cert}"
  grep -F "DNS:${service}" <<<"${san}" >/dev/null || \
    fail "certificate missing DNS SAN ${service}: ${cert}"

  eku="$(openssl x509 -in "${cert}" -noout -ext extendedKeyUsage 2>/dev/null || true)"
  grep -F "${expected_eku}" <<<"${eku}" >/dev/null || \
    fail "certificate missing EKU ${expected_eku}: ${cert}"
}

check_group_access "${secrets_dir}" 5
check_not_expiring "${ca_cert}"

for service in "${server_services[@]}"; do
  check_service_ca_copy "${service}"
  check_group_access "${secrets_dir}/${service}/ca.crt" 4
  check_leaf "${service}" server "TLS Web Server Authentication"
done

for service in "${client_services[@]}"; do
  check_service_ca_copy "${service}"
  check_group_access "${secrets_dir}/${service}/ca.crt" 4
  check_leaf "${service}" client "TLS Web Client Authentication"
done

echo "mTLS certificate preflight passed for ${secrets_dir}"
