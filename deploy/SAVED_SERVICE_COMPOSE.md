# Saved Service: Local Compose Wiring

`deploy/docker-compose.yml` runs Saved as a personal-data service with its own
PostgreSQL database, one-shot ordered migrations, service JWT authorization,
on-demand platform-policy checks, and three authoritative content sources:

- Attraction: `place-service` Saved source gRPC;
- Activity: `activity-service` Saved source gRPC;
- User: `user-service` Saved source gRPC for every active profile, including guides;
- USER relationship access: `chat-service` bounded internal HTTP batch check.

Excursions are outside the Saved product scope and remain part of the guide
calendar and booking domain. The deployment contains no sharing, offline replay, reconcile markers, or
persistent client-operation state.

## Local Development

The default Compose values are development-only and preserve the repository's
existing local convention:

```bash
docker compose -f deploy/docker-compose.yml up -d \
  saved-postgres saved-postgres-migrator saved-service api-gateway
```

Useful probes:

```bash
curl --fail http://localhost:8102/health
curl --fail http://localhost:8102/ready
curl --fail http://localhost:8102/metrics
```

The migrator records each `*.up.sql` filename and SHA-256 checksum in
`schema_migrations`. The zero-padded files are applied in lexical order, so
`001_saved_core.up.sql` always precedes `002_saved_collections.up.sql`. Ordinary
migrations and their markers commit in one transaction; concurrent-index files
run at PostgreSQL top level and are marked only after success. Checksum drift
fails closed. `saved-service` starts only after the migrator exits cleanly.

## Test VPS Deployment

`infra/test/docker-compose.test.yml` and `.github/workflows/deploy-test.yml`
ship Saved as part of the normal test deployment. The migration runner creates
`saved_service_db` idempotently, including on an existing PostgreSQL volume,
and then applies `025_saved_service_migrate.sh`. No manual `CREATE DATABASE` is
required.

Before the first deployment, configure these GitHub `test` environment secrets:

- `SAVED_SERVICE_TOKEN_SERVICE_SECRET`: an independent random secret of at
  least 32 bytes;
- `SAVED_OPERATION_HMAC_CURRENT_KEY_BASE64`: padded Base64 for 32 random bytes;
- `SAVED_CURSOR_ACTIVE_KEY_BASE64`: padded Base64 for a different 32 random
  bytes.

Generate each value independently with `openssl rand -base64 32`. CI rejects
malformed, short, or reused Saved crypto keys before connecting to the VPS. Key
versions default to `1`; use the optional GitHub variables
`SAVED_OPERATION_HMAC_CURRENT_VERSION` and `SAVED_CURSOR_ACTIVE_KEY_ID`, plus
the matching `*_PREVIOUS_KEYS` secrets, for a bounded rotation.

The test mTLS bundle must contain the `saved-service` client and server leaves.
The existing CA can issue only the missing leaves without rotating other
services:

```bash
sudo INFLAP_ENV=test MTLS_CERT_GROUP_ID=1001 \
  /opt/inflap/scripts/generate-mtls-certs.sh \
  --out-dir /opt/inflap/secrets/mtls --env test
```

PKI provisioning stays separate from application deploys by design. The deploy
preflight fails before containers change when a required certificate is absent
or expired. Test deployment enables core Saved and personal collections, while
search remains disabled until its explicit backfill and contract step passes.

## Required Production Overrides

Do not promote the development defaults. Supply all values through the target
platform's secret/config management:

- `SAVED_POSTGRES_HOST`, `SAVED_POSTGRES_PORT`, `SAVED_POSTGRES_USER`,
  `SAVED_POSTGRES_DB`, `SAVED_POSTGRES_PASSWORD`, and a PostgreSQL endpoint
  using `SAVED_POSTGRES_SSLMODE=verify-full`; set
  `SAVED_POSTGRES_SSL_ROOT_CERT` when the server CA is not in the image's
  system trust store;
- `SAVED_SERVICE_TOKEN_SERVICE_SECRET`, matching the token-service service
  account seed;
- `PLATFORM_POLICY_INTERNAL_SERVICE_TOKEN`, identical for `switches-service`,
  `saved-service`, and `api-gateway`;
- existing `INTERNAL_SERVICE_TOKEN`, reused by `saved-service` for the trusted
  `chat-service` access check; no Saved-specific relationship secret is added;
- `SAVED_OPERATION_HMAC_CURRENT_VERSION` and
  `SAVED_OPERATION_HMAC_CURRENT_KEY_BASE64`;
- `SAVED_CURSOR_ACTIVE_KEY_ID` and `SAVED_CURSOR_ACTIVE_KEY_BASE64`;
- HTTPS/mTLS dependency URLs and gRPC targets described below;
- Saved, Token, Activity, User, Chat, Place, and Switches SPIFFE/DNS allowlists for
  the actual environment (the Compose defaults use `spiffe://inflap/dev/...`);
- `SAVED_SERVICE_GATEWAY_AUTH_ALLOW_INSECURE_HTTP=false`,
  `SAVED_SERVICE_PLATFORM_POLICY_ALLOW_INSECURE_HTTP=false`, and
  `API_GATEWAY_PLATFORM_POLICY_ALLOW_INSECURE_HTTP=false`.
- a deployment-owned `SAVED_CAPABILITY_REVISION`, bumped for every effective
  product-capability change, plus explicit `SAVED_ITEMS_PRODUCT_ENABLED`,
  `SAVED_SEARCH_PRODUCT_ENABLED`, and `SAVED_COLLECTIONS_PRODUCT_ENABLED`
  rollout values;
- `SAVED_ROLLOUT_ANDROID_MIN_BUILD`, `SAVED_ROLLOUT_IOS_MIN_BUILD`, and
  capability-specific `SAVED_ROLLOUT_*_BASIS_POINTS` values in `[0,10000]`.
  Cohorts are deterministic by owner and capability; no marker store or
  client-persisted operation identity is involved;
- an HTTPS origin-only `SAVED_PUBLIC_API_ORIGIN` for revocable Activity,
  Attraction, and User thumbnail resolver routes;
- `ACTIVITY_SAVED_LIFECYCLE_ENABLED=true` and
  `PLACE_SAVED_LIFECYCLE_ENABLED=true`, with every producer and Saved consumer
  connected to the same durable NATS JetStream cluster. Keep
  `GUIDE_SAVED_LIFECYCLE_ENABLED=true` only during the bounded legacy event
  drain window; GUIDE events do not hydrate USER projections after migration `008`;
- service-specific `*_SAVED_NATS_URL`, `*_SAVED_NATS_CREDS_PATH`,
  `*_SAVED_NATS_CA_CERT_PATH`, `*_SAVED_NATS_CLIENT_CERT_PATH`,
  `*_SAVED_NATS_CLIENT_KEY_PATH`, and `*_SAVED_NATS_TLS_SERVER_NAME` for
  Activity and Place, plus Guide only while its compatibility producer is enabled.
  Staging/production accepts only `tls://`, TLS 1.3,
  mounted NATS credentials, and client mTLS material.

Product flags never override the shared personal-data emergency policy. The
policy is evaluated first and fails closed. Product flags block discovery and
new expansion in backend use cases without hiding existing owner data or
disabling reducing actions. Collections may be enabled after the ordered Saved
migrations are deployed. Search must remain disabled until its matching runtime
routes, backfill, and contract check are complete.

Mobile Saved requests must send `X-Client-Platform: android|ios` and a positive
decimal `X-App-Build`. Release CI passes the actual store build as
`--dart-define=INFLAP_APP_BUILD=<build>`; missing or malformed metadata disables
new expansion for that request but never hides canonical data or blocks
removal. Saved accepts only `ATTRACTION`, `ACTIVITY`, and `USER`; retired or
unknown entity types fail closed and have no rollout variable.

## Search Expand, Backfill, Contract

The standard Compose deployment prepares search automatically. The normal
migrator first applies the additive expand migration and concurrent indexes;
then `saved-search-rollout` runs bounded backfill and contract validation from
the exact Saved image being promoted. `saved-service` has a
`service_completed_successfully` dependency on that job, so a partial backfill
fails the deployment instead of exposing a broken search screen.

```bash
docker compose -f deploy/docker-compose.yml up -d --build
```

The rollout is idempotent and needs no new search-specific env or secret. It
reuses the Saved PostgreSQL connection secret. In staging/production, that
secret must still come from the existing secret manager and PostgreSQL must use
`verify-full`. Manual bounded recovery and the complete invalid-index/rollback
procedure are in
`backend/services/saved-service/migrations/SAVED_SEARCH_ROLLOUT.md`.

Operation HMAC and cursor AEAD keys must be independent random material. Keep
at most three previous `version:base64` entries in
`SAVED_OPERATION_HMAC_PREVIOUS_KEYS` and `SAVED_CURSOR_PREVIOUS_KEYS` during a
bounded rotation window. The checked-in defaults are deterministic development
keys and are rejected by `saved-service` in staging/production.

Local `saved-postgres` does not terminate TLS. Production/staging therefore
needs a TLS-enabled managed or self-operated PostgreSQL endpoint; changing only
`SAVED_SERVICE_APP_ENV` is expected to fail closed.

## mTLS Targets

When enforcing mTLS, provide the internal listener ports and override the
logical targets consistently:

| Caller | Callee | Transport / override |
| --- | --- | --- |
| `api-gateway` | `saved-service` | `SAVED_SERVICE_INTERNAL_HTTP_URL=https://saved-service:<saved-tls-port>` |
| `saved-service` | `token-service` | `TOKEN_SERVICE_INTERNAL_GRPC_TARGET=dns:///token-service:<token-grpc-tls-port>` |
| `saved-service` | token JWKS | `TOKEN_SERVICE_INTERNAL_JWKS_URL=https://token-service:<token-http-tls-port>/.well-known/jwks.json` |
| `saved-service` | `activity-service` | `ACTIVITY_SERVICE_INTERNAL_GRPC_TARGET=dns:///activity-service:<activity-grpc-tls-port>` |
| `saved-service` | `user-service` | `USER_SERVICE_INTERNAL_GRPC_TARGET=dns:///user-service:<user-grpc-tls-port>` |
| `saved-service` | `chat-service` | `CHAT_SERVICE_INTERNAL_HTTP_URL=https://chat-service:<chat-http-tls-port>` |
| `saved-service` | `place-service` | `PLACE_SERVICE_INTERNAL_GRPC_TARGET=dns:///place-service:9099` |
| Saved and Gateway | `switches-service` | `SWITCHES_SERVICE_INTERNAL_HTTP_URL=https://switches-service:<switches-tls-port>` |

`place-service` secures its existing `GRPC_PORT=9099` when mTLS is enabled;
Activity and User use their dedicated internal gRPC TLS listeners; Chat uses
its internal HTTP TLS listener.

The Saved certificate directory must exist before enforcement:

```text
${MTLS_SECRETS_DIR}/saved-service/
  ca.crt
  server.crt
  server.key
  client.crt
  client.key
```

The certificate inventory must also contain client/server identities for
`api-gateway`, `token-service`, `activity-service`, `user-service`,
`chat-service`, `place-service`, and `switches-service`. Compose allowlists permit only the
required Saved contour callers. No Excursion identity is added to Saved.

The repository certificate generator now issues both Saved server and client
leaf certificates, and the preflight checks validate both identities. Run the
generator and preflight after every environment or CA rotation; do not create
the Saved directory manually with copied credentials from another service.

`saved-service` currently accepts `MTLS_MODE=disabled|enforce`; it does not
accept the shared `permissive` rollout value. During that global rollout phase,
set `SAVED_SERVICE_MTLS_MODE=disabled` explicitly. Switch it to `enforce` only
after certificates, TLS listeners, URLs, and gRPC targets have passed
preflight.
