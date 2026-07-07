#!/usr/bin/env bash
set -euo pipefail

APP_DIR="${APP_DIR:-/opt/inflap}"
LOG_DIR="${LOG_DIR:-/var/log/inflap}"
DEPLOY_USER="${DEPLOY_USER:-deploy}"
MTLS_CERT_GROUP_ID="${MTLS_CERT_GROUP_ID:-1001}"
MTLS_CERT_GROUP_NAME="${MTLS_CERT_GROUP_NAME:-inflap-mtls}"

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run this script as root with sudo." >&2
  exit 1
fi

apt-get update
apt-get install -y ca-certificates curl gnupg ufw fail2ban openssl tar gzip jq unattended-upgrades

install -m 0755 -d /etc/apt/keyrings
if [[ ! -f /etc/apt/keyrings/docker.asc ]]; then
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  chmod a+r /etc/apt/keyrings/docker.asc
fi

. /etc/os-release
cat >/etc/apt/sources.list.d/docker.list <<EOF
deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu ${VERSION_CODENAME} stable
EOF

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

mkdir -p /etc/docker
cat >/etc/docker/daemon.json <<'EOF'
{
  "live-restore": true,
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "50m",
    "max-file": "5"
  }
}
EOF

systemctl enable --now docker
systemctl restart docker
systemctl enable --now fail2ban
systemctl enable --now unattended-upgrades

if ! id "${DEPLOY_USER}" >/dev/null 2>&1; then
  useradd --create-home --shell /bin/bash "${DEPLOY_USER}"
fi
usermod -aG docker "${DEPLOY_USER}"

if getent group "${MTLS_CERT_GROUP_ID}" >/dev/null 2>&1; then
  mtls_group_name="$(getent group "${MTLS_CERT_GROUP_ID}" | cut -d: -f1)"
else
  groupadd -g "${MTLS_CERT_GROUP_ID}" "${MTLS_CERT_GROUP_NAME}"
  mtls_group_name="${MTLS_CERT_GROUP_NAME}"
fi
usermod -aG "${mtls_group_name}" "${DEPLOY_USER}"

install -m 0700 -o "${DEPLOY_USER}" -g "${DEPLOY_USER}" -d "/home/${DEPLOY_USER}/.ssh"
if [[ -f /root/.ssh/authorized_keys && ! -s "/home/${DEPLOY_USER}/.ssh/authorized_keys" ]]; then
  install -m 0600 -o "${DEPLOY_USER}" -g "${DEPLOY_USER}" \
    /root/.ssh/authorized_keys "/home/${DEPLOY_USER}/.ssh/authorized_keys"
fi

mkdir -p "${APP_DIR}/env" "${APP_DIR}/scripts" "${APP_DIR}/backups/postgres" "${LOG_DIR}"
chown -R "${DEPLOY_USER}:${DEPLOY_USER}" "${APP_DIR}" "${LOG_DIR}"
install -d -m 0750 -o "${DEPLOY_USER}" -g "${mtls_group_name}" "${APP_DIR}/secrets/mtls"

ufw default deny incoming
ufw default allow outgoing
ufw allow 80/tcp
ufw allow 443/tcp

echo "Docker and base directories are ready."
echo "Add the SSH allow rule manually before enabling UFW, for example:"
echo "  sudo ufw allow from <your-public-ip> to any port 22 proto tcp"
echo "Then run:"
echo "  sudo ufw enable"
