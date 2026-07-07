#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Generate an Inflap internal mTLS certificate bundle for dev/test runtime use.

This script writes private keys only to the selected runtime directory. Do not
run it with an output directory inside the repository.

Usage:
  generate-mtls-certs.sh [options]

Options:
  --out-dir DIR      Bundle directory. Default: $MTLS_SECRETS_DIR or /opt/inflap/secrets/mtls
  --env NAME         Identity environment segment. Default: $INFLAP_ENV or test
  --cert-days N      Leaf certificate lifetime in days. Default: $MTLS_CERT_DAYS or 30
  --ca-days N        CA certificate lifetime in days. Default: $MTLS_CA_DAYS or 365
  --force            Regenerate existing CA and leaf certificates
  -h, --help         Show this help
USAGE
}

fail() {
  echo "generate-mtls-certs: $*" >&2
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
identity_env="${INFLAP_ENV:-test}"
cert_days="${MTLS_CERT_DAYS:-30}"
ca_days="${MTLS_CA_DAYS:-365}"
cert_group_id="${MTLS_CERT_GROUP_ID:-1001}"
force="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --out-dir)
      [[ $# -ge 2 ]] || fail "--out-dir requires a value"
      secrets_dir="$2"
      shift 2
      ;;
    --env)
      [[ $# -ge 2 ]] || fail "--env requires a value"
      identity_env="$2"
      shift 2
      ;;
    --cert-days)
      [[ $# -ge 2 ]] || fail "--cert-days requires a value"
      cert_days="$2"
      shift 2
      ;;
    --ca-days)
      [[ $# -ge 2 ]] || fail "--ca-days requires a value"
      ca_days="$2"
      shift 2
      ;;
    --force)
      force="true"
      shift
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
validate_positive_int "--cert-days" "${cert_days}"
validate_positive_int "--ca-days" "${ca_days}"
validate_positive_int "MTLS_CERT_GROUP_ID" "${cert_group_id}"
[[ "${identity_env}" =~ ^[A-Za-z0-9._-]+$ ]] || fail "--env may contain only letters, numbers, dot, underscore, and hyphen"

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)"
target_root="$(mkdir -p "${secrets_dir}" && cd "${secrets_dir}" && pwd -P)"
case "${target_root}" in
  "${repo_root}"|"${repo_root}/"*)
    fail "refusing to write private keys inside repository: ${target_root}"
    ;;
esac

services=(
  admin-panel
  anti-fraud-service
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

ca_key="${target_root}/ca.key"
ca_crt="${target_root}/ca.crt"
ca_serial="${target_root}/ca.srl"

umask 077
chgrp "${cert_group_id}" "${target_root}" || fail "failed to set mTLS bundle group to GID ${cert_group_id}; run bootstrap-server.sh as root or chgrp the bundle with sudo"
chmod 750 "${target_root}"

if [[ "${force}" == "true" ]]; then
  rm -f "${ca_key}" "${ca_crt}" "${ca_serial}"
fi

if [[ ! -f "${ca_key}" && ! -f "${ca_crt}" ]]; then
  openssl genrsa -out "${ca_key}" 4096 >/dev/null 2>&1
  openssl req \
    -x509 \
    -new \
    -nodes \
    -key "${ca_key}" \
    -sha256 \
    -days "${ca_days}" \
    -out "${ca_crt}" \
    -subj "/CN=Inflap ${identity_env} internal mTLS CA" \
    -addext "basicConstraints=critical,CA:TRUE,pathlen:0" \
    -addext "keyUsage=critical,keyCertSign,cRLSign" >/dev/null 2>&1
  chmod 600 "${ca_key}"
  chmod 644 "${ca_crt}"
elif [[ ! -f "${ca_key}" || ! -f "${ca_crt}" ]]; then
  fail "CA bundle is incomplete: expected both ${ca_key} and ${ca_crt}"
fi

tmp_dir="$(mktemp -d)"
cleanup() {
  rm -rf "${tmp_dir}"
}
trap cleanup EXIT

write_ext_file() {
  local file="$1"
  local service="$2"
  local eku="$3"

  cat >"${file}" <<EOF
[req]
prompt = no
distinguished_name = dn
req_extensions = req_ext

[dn]
CN = ${service}

[req_ext]
subjectAltName = @alt_names

[v3_leaf]
basicConstraints = critical, CA:FALSE
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = ${eku}
subjectAltName = @alt_names

[alt_names]
URI.1 = spiffe://inflap/${identity_env}/${service}
DNS.1 = ${service}
EOF
}

generate_leaf() {
  local service="$1"
  local role="$2"
  local eku="$3"
  local service_dir="${target_root}/${service}"
  local key_path="${service_dir}/${role}.key"
  local cert_path="${service_dir}/${role}.crt"
  local csr_path="${tmp_dir}/${service}-${role}.csr"
  local ext_path="${tmp_dir}/${service}-${role}.cnf"

  mkdir -p "${service_dir}"
  chgrp "${cert_group_id}" "${service_dir}" || fail "failed to set mTLS service bundle group to GID ${cert_group_id}: ${service_dir}"
  chmod 750 "${service_dir}"
  cp "${ca_crt}" "${service_dir}/ca.crt"
  chgrp "${cert_group_id}" "${service_dir}/ca.crt" || fail "failed to set mTLS CA copy group: ${service_dir}/ca.crt"
  chmod 644 "${service_dir}/ca.crt"

  if [[ "${force}" == "true" ]]; then
    rm -f "${key_path}" "${cert_path}"
  fi
  if [[ -f "${key_path}" && -f "${cert_path}" ]]; then
    chgrp "${cert_group_id}" "${key_path}" "${cert_path}" || fail "failed to set mTLS leaf bundle group for ${service}/${role}"
    chmod 640 "${key_path}"
    chmod 644 "${cert_path}"
    return 0
  fi
  if [[ -f "${key_path}" || -f "${cert_path}" ]]; then
    fail "leaf bundle is incomplete for ${service}/${role}: expected both key and certificate"
  fi

  write_ext_file "${ext_path}" "${service}" "${eku}"
  openssl genrsa -out "${key_path}" 2048 >/dev/null 2>&1
  openssl req -new -key "${key_path}" -out "${csr_path}" -config "${ext_path}" >/dev/null 2>&1
  openssl x509 \
    -req \
    -in "${csr_path}" \
    -CA "${ca_crt}" \
    -CAkey "${ca_key}" \
    -CAcreateserial \
    -out "${cert_path}" \
    -days "${cert_days}" \
    -sha256 \
    -extfile "${ext_path}" \
    -extensions v3_leaf >/dev/null 2>&1
  chgrp "${cert_group_id}" "${key_path}" "${cert_path}" || fail "failed to set mTLS leaf bundle group for ${service}/${role}"
  chmod 640 "${key_path}"
  chmod 644 "${cert_path}"
}

for service in "${services[@]}"; do
  generate_leaf "${service}" server serverAuth
  generate_leaf "${service}" client clientAuth
done

echo "Generated Inflap mTLS cert bundle in ${target_root}"
echo "CA certificate: ${ca_crt}"
echo "Keep ${ca_key} private and outside the repository."
