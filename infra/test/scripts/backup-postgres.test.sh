#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
script="${repo_root}/infra/test/scripts/backup-postgres.sh"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT

mkdir -p "${tmp_dir}/bin" "${tmp_dir}/backups"
touch "${tmp_dir}/test.env" "${tmp_dir}/runtime.env" "${tmp_dir}/deploy.env" "${tmp_dir}/compose.yml"

cat >"${tmp_dir}/bin/docker" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"${FAKE_DOCKER_LOG}"
printf '%s\n' '-- Inflap PostgreSQL backup fixture'
if [[ "${FAKE_DOCKER_FAIL:-false}" == "true" ]]; then
  exit 1
fi
EOF
chmod +x "${tmp_dir}/bin/docker"

fake_docker_log="${tmp_dir}/docker.log"
PATH="${tmp_dir}/bin:${PATH}" \
FAKE_DOCKER_LOG="${fake_docker_log}" \
APP_DIR="${tmp_dir}" \
BACKUP_DIR="${tmp_dir}/backups" \
ENV_FILE="${tmp_dir}/test.env" \
RUNTIME_ENV_FILE="${tmp_dir}/runtime.env" \
DEPLOY_ENV_FILE="${tmp_dir}/deploy.env" \
COMPOSE_FILE="${tmp_dir}/compose.yml" \
"${script}" >"${tmp_dir}/backup.out"

backup_file="$(find "${tmp_dir}/backups" -type f -name 'inflap-test-*.sql.gz' -print -quit)"
if [[ -z "${backup_file}" ]]; then
  echo "backup test did not create a final archive" >&2
  exit 1
fi
gzip -t "${backup_file}"
grep -Fq -- "--env-file ${tmp_dir}/runtime.env" "${fake_docker_log}"

rm -f "${tmp_dir}/backups"/*
if PATH="${tmp_dir}/bin:${PATH}" \
  FAKE_DOCKER_LOG="${fake_docker_log}" \
  FAKE_DOCKER_FAIL=true \
  APP_DIR="${tmp_dir}" \
  BACKUP_DIR="${tmp_dir}/backups" \
  ENV_FILE="${tmp_dir}/test.env" \
  RUNTIME_ENV_FILE="${tmp_dir}/runtime.env" \
  DEPLOY_ENV_FILE="${tmp_dir}/deploy.env" \
  COMPOSE_FILE="${tmp_dir}/compose.yml" \
  "${script}" >/dev/null 2>&1; then
  echo "backup test expected pg_dumpall failure" >&2
  exit 1
fi
if find "${tmp_dir}/backups" -type f | grep -q .; then
  echo "failed backup left an archive or temporary file" >&2
  find "${tmp_dir}/backups" -type f >&2
  exit 1
fi

echo "backup-postgres test passed"
