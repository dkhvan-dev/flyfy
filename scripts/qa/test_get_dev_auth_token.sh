#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/inflap-auth-token-test.XXXXXX")"
trap 'rm -rf "${tmp_dir}"' EXIT

mkdir -p "${tmp_dir}/bin"

cat >"${tmp_dir}/bin/curl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

args="$*"
if [[ "${args}" == *"/phone/send-code"* ]]; then
  printf '{"message":"OTP code sent successfully"}\n'
  exit 0
fi
if [[ "${args}" == *"/phone/verify"* ]]; then
  expected_code="${FAKE_EXPECTED_CODE:-654321}"
  if [[ "${args}" != *"\"code\":\"${expected_code}\""* ]]; then
    echo "verify request did not include expected OTP ${expected_code}" >&2
    exit 12
  fi
  printf '{"access_token":"access-token-from-auth","refresh_token":"refresh"}\n'
  exit 0
fi

echo "unexpected curl call: ${args}" >&2
exit 11
EOF

cat >"${tmp_dir}/bin/docker" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

args="$*"
if [[ "${args}" == *"redis-cli"* && "${args}" == *"otp:+77010000001"* ]]; then
  printf '654321\n'
  exit 0
fi
if [[ "${args}" == *"redis-cli"* && "${args}" == *"otp:+77010000002"* ]]; then
  printf '(nil)\n'
  exit 0
fi
if [[ "${args}" == *"logs auth-test"* ]]; then
  printf '\033[90mINF\033[0m OTP code (dev mode) \033[36mcode=\033[0m112233 component=otp_sender phone=+77010000002 service=auth-service\n'
  exit 0
fi

echo "unexpected docker call: ${args}" >&2
exit 21
EOF

chmod +x "${tmp_dir}/bin/curl" "${tmp_dir}/bin/docker"

token="$(
  PATH="${tmp_dir}/bin:${PATH}" \
  AUTH_DEV_BASE_URL="http://auth.local/api/v1/auth" \
  AUTH_DEV_PHONE="+77010000001" \
  AUTH_DEV_REDIS_CONTAINER="redis-test" \
  "${repo_root}/scripts/qa/get_dev_auth_token.sh"
)"

if [[ "${token}" != "access-token-from-auth" ]]; then
  echo "token = ${token}, want access-token-from-auth" >&2
  exit 1
fi

token_from_logs="$(
  PATH="${tmp_dir}/bin:${PATH}" \
  FAKE_EXPECTED_CODE="112233" \
  AUTH_DEV_BASE_URL="http://auth.local/api/v1/auth" \
  AUTH_DEV_PHONE="+77010000002" \
  AUTH_DEV_REDIS_CONTAINER="redis-test" \
  AUTH_DEV_AUTH_CONTAINER="auth-test" \
  "${repo_root}/scripts/qa/get_dev_auth_token.sh"
)"

if [[ "${token_from_logs}" != "access-token-from-auth" ]]; then
  echo "token_from_logs = ${token_from_logs}, want access-token-from-auth" >&2
  exit 1
fi

echo "Dev auth token helper test passed"
