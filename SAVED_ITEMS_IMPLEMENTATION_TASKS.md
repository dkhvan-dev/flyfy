# Saved Items: implementation task board

**Source of truth:** `SAVED_ITEMS_PRODUCTION_PLAN.md`

**Started:** 2026-07-16

## Delivery rules

- Work follows the production plan stages; this board only decomposes execution.
- Each worker owns an explicit, disjoint write scope and must not revert unrelated changes.
- A task is complete only with code, tests, and the listed verification evidence.
- Source ID, auth session-generation, and platform emergency-policy contracts gate external rollout.
- No sharing, notes, bulk mutations, persistent Saved cache, offline writes, generic aliases, manual reorder, or restart replay may be introduced.

## Current assignments

| Agent | Work package | Mode | Write scope | Status |
|---|---|---|---|---|
| Kant | B0 backend pattern discovery | investigator | read-only | Complete |
| Tesla | S0 source services and Gateway discovery | investigator | read-only | Complete |
| Copernicus | M0 Flutter discovery | investigator | read-only | Complete |
| Hilbert | D0 delivery and verification discovery | investigator | read-only | Complete |
| Hooke/Epicurus | B1 core PostgreSQL migration and hardening | worker/reviewer | `backend/services/saved-service/migrations/001_saved_core.*.sql` | Complete |
| Newton | B2 service skeleton | worker | `backend/services/saved-service/{cmd,internal/config,internal/adapter/http}`, module and build files | Complete |
| Hume/Main | B3 domain model | worker/integrator | `backend/services/saved-service/internal/domain/**` | Complete, including collection operation receipts |
| Locke/Main | B3 semantic HMAC/idempotency kernel | worker/integrator | `backend/services/saved-service/internal/app/operation/**` | Complete |
| Parfit | B3 PostgreSQL OperationStore | worker | `backend/services/saved-service/internal/adapter/repository/pg_operation_store*` | Complete |
| Dirac/Main | G0.3 OpenAPI contract | worker/integrator | `backend/services/saved-service/api/**` | Complete |
| Boyle | G0.1 shared source contract | worker | `proto/content/v1` and generated Go | Complete |
| Zeno/Main | G0.2 Gateway session/Saved boundary | worker/integrator | `backend/services/api-gateway/**` | Complete |
| Arendt/Main | G0.2 shared fail-closed personal-data policy client | worker/integrator | `backend/pkg/platformpolicy/**`, Saved/Gateway wiring | Complete |
| Harvey/Descartes/Main | M1 mobile state foundation | worker/integrator | `mobile/lib/features/saved/{domain,data,presentation/state}` and focused tests | Complete; Saved/full integration coverage verified, real-device QA remains release evidence |
| Schrodinger/Turing | S1 Activity source adapter, ACL and lifecycle outbox | workers | `backend/services/activity-service/**` | Complete |
| Faraday/Hubble | S2 Attraction source adapter and lifecycle outbox | workers | `backend/services/place-service/**` | Complete |
| Aquinas/Kuhn | S2 Guide source adapter and lifecycle outbox | workers | `backend/services/guide-service/**` | Complete |
| Ptolemy | B7 collection schema | worker | Saved migration `002` and tests | Complete |
| Godel/Main | G0.2 fresh session-generation validation | worker/integrator | token proto, `token-service`, Saved client | Complete |
| Ohm | G0.2 shared personal-data policy producer | worker | `switches-service` | Complete |
| Hegel | G0.2 Gateway personal-data policy enforcement | worker | `api-gateway` | Complete |
| Popper/Main | S1/S2 Saved source client router | worker/integrator | Saved `app/source`, `adapter/source`, bootstrap | Complete for the closed Attraction, Activity and Guide scope |
| Lovelace/Main | G0.2 Saved session validation client | worker/integrator | Saved `app/session`, `adapter/session`, bootstrap | Complete |
| Singer/Main | B4 save/global-unsave transaction kernel and orchestration | worker/integrator | Saved item app/repository/HTTP paths | Complete |
| Dewey/Main | B2/B5 production dependency bootstrap | worker/integrator | Saved config/bootstrap/auth/policy/runtime | Complete |
| Euclid/Main | B4/B5 owner read kernel | worker/integrator | Saved query app/repository/HTTP paths | Complete |
| Turing/Kuhn/Hubble | S2 lifecycle outboxes | workers | Activity/Guide/Place services | Complete |
| Fermat/Main | M2/M3 Saved, collection and bookmark UX | worker/integrator | Saved mobile feature, routes/profile/l10n/source cards | Complete; analyzer, policy, adaptive and cross-screen tests verified, real-device QA remains release evidence |
| Curie/Main | D1 compose, migrations 001-006a, NATS and mTLS wiring | worker/integrator | `deploy/**`, certificate scripts | Complete; production rollout drill pending |
| Pasteur/Main | B7 collection transaction/read kernel | worker/integrator | Saved collection app/repository/HTTP/runtime paths | Complete |
| Nash/Main | B6 multilingual search kernel and online rollout migration | worker/integrator | Saved search app/repository/HTTP/migrations 003-003d | Complete |
| Sartre/Main | S2 Saved lifecycle consumer | worker/integrator | Saved lifecycle app/NATS/repository/migration 004 | Complete |
| Chandrasekhar/Main | D2 bounded expiry/retention/GC and subject purge | worker/integrator | Saved maintenance app/repository/migration 005 | Complete |
| Kepler/Main | D2 bounded source reconciliation hardening | worker/integrator | Saved reconciliation app/repository/runtime/migrations 006-006a | Complete after independent concurrency/privacy review and live PostgreSQL race tests |
| Main agent | Integration, review and production verification | integrator | cross-module after worker handoff | Complete for implementation and local production-equivalent verification; staged rollout remains release work |

## Work packages

### Gate 0: contracts and threat model

**G0.1 Source capability matrix**

- Confirm immutable IDs, PUBLIC eligibility RPC, localized projection, monotonic revisions, lifecycle events, routes, and revocable media for each production-enabled type: Attraction, Activity, and Guide.
- A domain that changes IDs requires its own ADR and migration before enablement; the Saved core gets no generic alias subsystem.
- Evidence: contract and integration tests for all enabled adapters; retired and unknown wire types fail closed.

Current gate status:

| Type | Canonical identity | Enablement gate |
|---|---|---|
| ATTRACTION | `place-service.places.id` | Enabled: public-read policy, monotonic revision, eligibility/projection RPC and lifecycle outbox are implemented |
| ACTIVITY | `activity-service.activities.id` | Enabled: strict PUBLIC Saved eligibility, cover ACL, authenticated RPC and lifecycle outbox are implemented |
| GUIDE | Public `guide-service.user_id` | Enabled only for ACTIVE public guide profiles; revisions, localized projection and lifecycle outbox are implemented |

**G0.2 Auth and emergency policy contract**

- Confirm trusted owner header, stable session generation, revoke semantics, final-commit validation, and shared platform emergency access policy.
- Evidence: contract tests covering spoofed headers, revoked generation, stale policy, and direct-service bypass.

Status: complete. Token final-commit RPC, shared switches-service producer, Gateway enforcement, Saved policy/session clients and final business-use-case commit checks are wired and covered by focused tests.

**G0.3 API and privacy review**

Status: complete in code. The owner-only OpenAPI contract, privacy-negative vocabulary tests, cursor protection and logging redaction checks are implemented; formal organizational approval remains a release-governance activity.

- Freeze versioned HTTP/OpenAPI schemas, error codes, logging redaction, cursor contents, and operation result payload.
- Evidence: OpenAPI compatibility test and approved threat model.

### Stage 1: reliable Saved kernel

**B1 Core schema**

Status: complete for Stage 1 core; collection extension is B7.

- Tables: relationships, on-demand projections, bounded operations, outbox, and usage counters.
- Constraints: owner-first uniqueness, closed states, payload-free deny rows, operation deadline/retention, and bounded indexes.
- Evidence: up/down migration contract test and PostgreSQL integration test.

**B2 Service skeleton**

Status: complete, including production dependency wiring, health/readiness, mTLS listener and graceful background shutdown.

- Add Go module, config validation, PostgreSQL pool, graceful shutdown, health/readiness, mTLS listener, Makefile, and Dockerfile.
- Evidence: config/unit tests, `go test ./...`, `go vet ./...`, and container health check.

**B3 Domain and operation kernel**

Status: complete for target and collection receipt kinds, including PostgreSQL identity convergence and all collection semantic request encoders.

- Implement SavedTarget validation, relationship lifecycle, server timestamps/versions, PENDING/SUCCEEDED/REJECTED/EXPIRED operation states, semantic request HMAC, same-key replay, deadline CAS, and typed errors.
- No request payload or device marker is persisted.
- Evidence: concurrent same-key, mismatch, ACK-loss, deadline, stale-response, and revoked-session tests.

**B4 Core repository and use cases**

Status: complete. Save/global-unsave, status/batch, owner list, operation status, capabilities, collections, search, lifecycle consumer, projection-shell fencing, reconciliation and bounded maintenance kernels are implemented. DB-clock lease fencing, local fail-closed recovery and quarantine recovery passed live race/integration coverage.

- Implement save, global unsave, status, batch status, list, operation status, quotas, outbox atomicity, and retention hooks.
- Global DELETE removes all current memberships in one transaction; `removal:commit` does not exist.
- Evidence: repository integration tests with race and rollback coverage.

**B5 HTTP API and cursor**

Status: complete. OpenAPI, auth/policy middleware, body bounds, AEAD cursor, save/global-unsave, list, search, status/batch, operation-status, capabilities and collection handlers are implemented and covered by contract/focused tests.

- Implement owner-only routes, bounded bodies, operation/idempotency headers, neutral target errors, keyset pagination, and AEAD cursor rotation.
- Evidence: handler and contract tests; no aggregate total/category counters.

**S1 First source adapter and Gateway route**

Status: complete in code. Gateway, all enabled source adapters, Saved business handlers and source lifecycle outboxes are wired. A live PostgreSQL vertical-slice test exists; the final compose/Gateway smoke remains an integration verification step.

- Select one source with the strongest existing PUBLIC contract, implement live eligibility/projection hydration, and expose Saved routes through Gateway.
- Evidence: source timeout/deny tests, spoofed-header test, and one end-to-end PUBLIC save flow.

**M1 Mobile state foundation**

Status: complete, including repository, strict wire models, in-process operation resolution, bounded registry, automatic batched status bootstrap, profile route, adaptive Saved/collection screens, reusable source bookmark and localized states. Automated compact/expanded/large-text/network coverage is complete; physical-device matrix remains D2 release evidence.

- Add Saved API/repository, in-memory operation state, global bounded SavedStateRegistry/LRU, batch status, and bookmark bindings.
- No persistent Saved pages or operation identity.
- Evidence: provider/repository/widget tests for UNKNOWN, timeout, same-key retry, logout, and process restart bootstrap.

### Stage 2: complete Saved screen

**S2 Remaining source adapters and lifecycle events**

Status: complete for the final Activity, Attraction and Guide scope, including eligibility, transactional lifecycle outboxes and the Saved-side durable consumer.

- Add remaining types, PUBLIC/PRIVATE Activity handling, projection purge, bounded shell GC, event deduplication, and reconciliation of known rows.
- Evidence: contract suites for the three supported types, retired-type rejection, and PUBLIC to PRIVATE to PUBLIC tests where the source domain supports private visibility.

**M2 Navigation and Saved views**

Status: implementation and automated Flutter verification complete, including bookmarks on supported card/detail surfaces, policy tests, compact/expanded layouts, large text and network states. Physical-device checks remain release evidence.

- Add the profile "Мой путь" entry, `/saved`, "Все", categories, "Без коллекции", adaptive lists, pagination, loading/error/offline/empty states, localization, and accessibility.
- Evidence: EN/RU/KK widget checks across compact/medium/expanded widths and 200% text scale; real-device and visual regression checks remain D2 release evidence.

**B6 Multilingual search**

Status: complete in a bounded, dedicated Saved search module, including online expand/backfill/contract migration tooling and privacy-safe zero-result metrics.

- Implement EN/RU/KK exact, token, and prefix ranks with keyset search pagination and privacy-safe zero-result analytics.
- Evidence: deterministic ordering, query plans at 10,000 saves, and no raw query in logs/events.

### Stage 3: personal collections

**B7 Collection schema and use cases**

Status: complete. Migration 002, transaction/read kernel, derived first-item cover, HTTP/runtime integration and focused PostgreSQL tests are implemented.

- Add collection/membership migrations, V1 title normalization, unique ACTIVE names, atomic inline create, desired-set assignment, parent delete, quotas, and bounded child cleanup.
- Evidence: transaction/race tests and 200/5,000/50,000 limit tests.

**B8 Derived collection cover**

Status: complete. The cover is derived at read time from exactly the first effective item by canonical Saved ordering; unavailable or image-less first items use the generic fallback without selecting a later card.

- Derive cover from the first collection item by `saved_at DESC, id DESC`; use generic fallback for empty/non-PUBLIC/no-thumbnail first item.
- Do not add persisted cover state, reverse indexes, or repair workers.
- Evidence: indexed query plan and immediate deny fallback test.

**M3 Collection UX**

Status: implementation and focused tests complete. The picker supports bounded local search, atomic inline creation, desired-set assignment and explicit per-card/global removal semantics without bulk actions.

- Add bounded local search over at most 200 collections, picker, inline creation, per-card assignment, reduction-only mode, collection screen, and distinct remove/global-delete actions.
- Evidence: draft preservation, keyboard/safe-area, long localization, and no accidental global unsave.

### Stage 4: operations and rollout

**D1 Infrastructure and observability**

Status: compose database/migrator/service/Gateway/mTLS wiring is complete for migrations 001-006a. Fresh-database apply, checksum replay, concurrent-index validation and 003d/006b contracts passed; production rollout drills remain release work.

- Add compose/deployment wiring, secrets/config, migration job, metrics, traces, alerts, dashboards, and runbooks.
- Evidence: readiness, failover, migration rollback, and alert rehearsal.

**D2 Hardening**

Status: code-level and local production-equivalent hardening complete. Race suites, live PostgreSQL/NATS contracts, retention/purge/reconciliation tests, adaptive Flutter tests and deployment contracts pass. Load/soak, PITR, alert rehearsal and the physical-device matrix require stage/prod-like infrastructure and remain release evidence.

- Execute security, load, soak, PITR, account purge, projection GC, operation expiry, and device performance suites.
- Evidence: all Definition of Done gates from the production plan linked to test or runbook output.

**D3 Staged rollout**

Status: implementation-ready, not executed. Flags, cohorts, pause criteria and rollback runbook are wired; progressing through real cohorts is intentionally owned by release operations after environment-specific gates pass.

- Wire product flags independently from the platform emergency policy and progress internal, 1%, 5%, 25%, 50%, and 100% cohorts only after guardrails pass.
- Evidence: cohort report, SLO review, support owner, and rollback drill.

## Dependency order

1. G0 contracts unblock B3, S1, and Gateway integration.
2. B1 and B2 unblock B3-B5.
3. B3-B5 plus S1 unblock M1 and the first internal vertical slice.
4. The verified vertical slice unblocks S2, M2, and B6 in parallel.
5. Stage 2 stability unblocks B7-B8 and M3.
6. D1 runs alongside implementation; D2-D3 close delivery.

## First vertical-slice exit

- One authenticated user can save and unsave one confirmed PUBLIC target through Gateway.
- The Saved service persists one owner-scoped relationship and replays the same idempotency key without duplicate writes or source RPC.
- Operation status resolves ACK loss while the process is alive; no restart marker/replay exists.
- Mobile shows confirmed bookmark state and a truthful UNKNOWN/error state.
- Tests prove tenant isolation, deadline fencing, rollback atomicity, and source deny behavior.
