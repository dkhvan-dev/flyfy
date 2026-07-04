#!/usr/bin/env bash
set -euo pipefail

APP_DIR="${APP_DIR:-/opt/inflap}"
DEPLOY_USER="${DEPLOY_USER:-deploy}"
LOG_DIR="${LOG_DIR:-/var/log/inflap}"
SYSTEMD_DIR="${SYSTEMD_DIR:-/etc/systemd/system}"

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run this script as root with sudo." >&2
  exit 1
fi

if ! id "${DEPLOY_USER}" >/dev/null 2>&1; then
  echo "Deploy user does not exist: ${DEPLOY_USER}" >&2
  exit 1
fi

install -m 0755 -d "${LOG_DIR}" "${APP_DIR}/backups/postgres"
chown -R "${DEPLOY_USER}:${DEPLOY_USER}" "${LOG_DIR}" "${APP_DIR}/backups"

for unit in \
  inflap-test-postgres-backup.service \
  inflap-test-postgres-backup.timer \
  inflap-test-smoke-check.service
do
  install -m 0644 "${APP_DIR}/systemd/${unit}" "${SYSTEMD_DIR}/${unit}"
done

systemctl daemon-reload
systemctl enable --now inflap-test-postgres-backup.timer

echo "Installed systemd units:"
systemctl list-timers --all --no-pager inflap-test-postgres-backup.timer
echo
echo "Manual commands:"
echo "  systemctl start inflap-test-postgres-backup.service"
echo "  systemctl start inflap-test-smoke-check.service"
echo "  journalctl -u inflap-test-postgres-backup.service -n 80 --no-pager"
echo "  journalctl -u inflap-test-smoke-check.service -n 80 --no-pager"
