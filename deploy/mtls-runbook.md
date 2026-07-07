# Inflap Internal mTLS Runbook

This runbook covers internal service-to-service mTLS for Inflap. It does not
cover external mobile/web traffic through Caddy/API Gateway.

The canonical caller/callee matrix is documented in
[`docs/mtls-service-communication-matrix.md`](../docs/mtls-service-communication-matrix.md).

## Identity Model

- Service URI SAN: `spiffe://inflap/<env>/<service-name>`.
- DNS SAN: Docker/Kubernetes service name, for example `search-service`.
- CN is not an identity source.
- mTLS proves caller identity at transport level.
- Service JWT/RBAC remains the application authorization layer.

## Certificate Layout

Runtime certificates live outside the repository:

```text
/opt/inflap/secrets/mtls/
  ca.crt
  <service-name>/
    ca.crt
    server.crt
    server.key
    client.crt
    client.key
```

Private keys must never be committed or printed in CI logs.
Docker Compose mounts only the target service directory into each container, so
`<service-name>/ca.crt` is the CA path used by that service at runtime. The root
`ca.crt` remains the operator/preflight source of truth.

For the test server, generate a non-production bundle on the server:

```bash
/opt/inflap/scripts/generate-mtls-certs.sh \
  --out-dir /opt/inflap/secrets/mtls \
  --env test \
  --cert-days 30 \
  --ca-days 365
```

Then validate it before switching `MTLS_MODE` away from `disabled`:

```bash
/opt/inflap/scripts/preflight-mtls-certs.sh \
  --secrets-dir /opt/inflap/secrets/mtls \
  --ca-cert /opt/inflap/secrets/mtls/ca.crt \
  --env test \
  --min-valid-days 1
```

## Required Environment

Each internal service uses the shared mTLS env contract:

```text
MTLS_MODE=disabled|permissive|enforce
<SERVICE>_MTLS_MODE=disabled|permissive|enforce
MTLS_CA_CERT_PATH=/opt/inflap/secrets/mtls/<service>/ca.crt
MTLS_SERVER_CERT_PATH=/opt/inflap/secrets/mtls/<service>/server.crt
MTLS_SERVER_KEY_PATH=/opt/inflap/secrets/mtls/<service>/server.key
MTLS_CLIENT_CERT_PATH=/opt/inflap/secrets/mtls/<service>/client.crt
MTLS_CLIENT_KEY_PATH=/opt/inflap/secrets/mtls/<service>/client.key
MTLS_ALLOWED_SPIFFE_IDS=spiffe://inflap/<env>/<caller>,...
MTLS_ALLOWED_DNS_NAMES=<caller-service>,...
MTLS_MIN_VERSION=1.3
```

## Rollout Gates

1. Keep `MTLS_MODE=disabled`; deploy and verify existing traffic.
2. Set `MTLS_MODE=permissive`; verify plain and mTLS listeners, logs, and health checks.
3. Enable `enforce` for search/token/gateway-adjacent contours first.
4. Enable `enforce` for domain service-to-service HTTP/gRPC calls.
5. Enable `enforce` for backfill/job containers.
6. Remove legacy shared internal-token dependency only after enforcement is stable.

Before each gate:

```bash
infra/test/scripts/preflight-mtls-certs.sh \
  --secrets-dir "${MTLS_SECRETS_DIR:-/opt/inflap/secrets/mtls}" \
  --ca-cert "${MTLS_CA_CERT_PATH:-/opt/inflap/secrets/mtls/ca.crt}" \
  --env "${INFLAP_ENV:-test}"
docker compose -f deploy/docker-compose.yml config --quiet
docker compose -f infra/test/docker-compose.test.yml config --quiet
```

Also run the targeted Go/Python tests for changed services.

For a single-service Docker Compose enforcement gate, keep the stack in
`permissive` and recreate only the target service with `--no-deps`. Otherwise
Compose may also recreate dependency services with the stricter environment:

```bash
MTLS_MODE=permissive \
SEARCH_SERVICE_MTLS_MODE=enforce \
docker compose -f deploy/docker-compose.yml up -d --no-deps search-service
```

After the smoke check, either continue the planned rollout group or roll the
target service back to `permissive` using the same `--no-deps` pattern.

## Rotation Policy

- Prefer short-lived leaf certificates: 7-30 days for test/stage, 24h-7 days for production when automated issuance is available.
- Leaf `server.crt/server.key` and `client.crt/client.key` files are reloaded by services during new TLS handshakes, so normal leaf renewal does not require a process restart after files are replaced atomically.
- Rotate CA only through a planned dual-trust window.
- Generate new service certs with both old and new certs deployable during the transition.
- Verify new cert SANs against `MTLS_ALLOWED_SPIFFE_IDS` and `MTLS_ALLOWED_DNS_NAMES`.
- Deploy certs first, then config, then switch `MTLS_MODE`.
- Check health/readiness and service logs before moving the next service group.

## Rollback

Fast rollback:

```text
MTLS_MODE=permissive
```

Emergency rollback:

```text
MTLS_MODE=disabled
```

Keep plaintext health endpoints available for Docker health checks unless a service has an explicit mTLS-aware health probe.

## Future Production Path

For Kubernetes or multi-node production, move issuance and rotation to one of:

- SPIFFE/SPIRE workload API;
- cert-manager with short-lived internal CA certificates;
- service mesh mTLS, if it does not conflict with application-level JWT/RBAC.

The app-level service JWT/RBAC model must stay in place even when transport mTLS is delegated to infrastructure.
