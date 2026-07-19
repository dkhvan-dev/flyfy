# Saved Search Zero-Downtime Rollout

This rollout preserves the existing EN/RU/KK exact, token, and prefix search
contract while avoiding a heap rewrite and long `ACCESS EXCLUSIVE` lock on
`saved_content_projections`. The repository target is PostgreSQL 17.

## Standard Deployment Path

The checked-in Compose deployments run an idempotent `saved-search-rollout`
one-shot service from the exact Saved image being promoted. It starts after the
normal migrator, executes bounded backfill plus contract validation, and must
exit successfully before `saved-service` can start:

```bash
/app/saved-search-backfill \
  -mode=rollout \
  -batch-size=500 \
  -max-batches=10000 \
  -pause=25ms
```

An already contracted database returns `ready=true` without another backfill.
If the bounded cap is reached, the job exits non-zero and the application does
not start. Increase the bounded job capacity only after checking database load,
or continue with the manual recovery phases below. No search-specific secret is
required; the job reuses the Saved database secret reference.

## Invariants

- Never allow an instance with `SAVED_SEARCH_PRODUCT_ENABLED=true` to serve
  before the contract command reports ready. Startup verifies this invariant
  independently of Compose.
- For a manual rollout, keep `SAVED_SEARCH_PRODUCT_ENABLED=false` until the
  contract command reports ready.
- Never backfill all rows in one transaction.
- Do not run `003d_saved_search_contract.sql` before the bounded backfill is
  complete.
- Do not wrap `003a`, `003b`, or `003c` in a transaction. PostgreSQL requires
  `CREATE INDEX CONCURRENTLY` to run at top level.
- A failed expand due to the five-second `lock_timeout` is safe to retry after
  the blocking transaction has ended.

## Phase 1: Expand

1. Apply the normal migrations before starting the Saved runtime.
2. Apply the normal `*.up.sql` migrations. The ordered files perform:
   - `003_saved_search.up.sql`: nullable columns, dual-write trigger, and a
     `NOT VALID` parity constraint;
   - `003a_saved_search_owner_index.up.sql`: owner index concurrently;
   - `003b_saved_search_projection_index.up.sql`: projection index
     concurrently;
   - `003c_saved_search_backfill_index.up.sql`: temporary partial index over
     only stale rows, built concurrently.
3. Confirm the database has enough temporary disk headroom for all three
   concurrent index builds before applying them.
4. Confirm there is no invalid leftover concurrent index:

```sql
SELECT c.relname, i.indisready, i.indisvalid
FROM pg_index AS i
JOIN pg_class AS c ON c.oid = i.indexrelid
WHERE c.relname IN (
    'idx_saved_items_active_owner_search_v1',
    'idx_saved_content_projections_public_search_target_v1',
    'idx_saved_content_projections_search_backfill_v1'
);
```

All three rows must have `indisready=true` and `indisvalid=true`. If a concurrent
build was interrupted, drop only the invalid index with `DROP INDEX
CONCURRENTLY`, remove that file's `schema_migrations` marker if it was recorded,
and re-run the migration.

## Phase 2: Bounded Backfill

Run bounded invocations from the same immutable Saved service image that will
serve traffic. The job uses the standard libpq `PGHOST`, `PGPORT`, `PGUSER`,
`PGPASSWORD`, `PGDATABASE`, and `PGSSLMODE` environment variables:

```bash
/app/saved-search-backfill \
  -mode=backfill \
  -batch-size=500 \
  -max-batches=100 \
  -pause=25ms
```

Each batch is a separate short transaction, uses `FOR UPDATE SKIP LOCKED`, and
does not change projection revisions or `updated_at`. The temporary partial
index contains only stale rows, so completed prefixes are not repeatedly
scanned. Re-run the command until it reports `complete=true`; no persistent
cursor or marker is needed.

## Phase 3: Contract

Run:

```bash
/app/saved-search-backfill -mode=contract
```

The command fails closed unless the trigger, both final indexes, and the
temporary backfill index are healthy. It then validates
`saved_content_projections_search_parity_v1_check` with
PostgreSQL's online constraint validation, drops the now-empty temporary index
concurrently, and verifies zero stale rows. The validation SQL equivalent is
kept in `003d_saved_search_contract.sql` for controlled DBA use; a DBA running
it manually must also drop `idx_saved_content_projections_search_backfill_v1`
with `DROP INDEX CONCURRENTLY` afterward.

Only after the command reports `ready=true` may
`SAVED_SEARCH_PRODUCT_ENABLED` be enabled. Roll out the flag gradually and
monitor query latency, PostgreSQL CPU, buffer reads, and
`saved_search_first_pages_total{result="zero_results"}`. The standard Compose
path enforces this order through `service_completed_successfully` and starts at
the configured full cohort after the contract succeeds.

## Failure And Rollback

- Backfill timeout or cancellation: rerun it; completed rows stay complete.
- Contract validation failure: keep search disabled, rerun backfill, then retry
  contract validation.
- Search runtime regression: disable the feature flag. Keep the additive
  columns, trigger, constraint, and indexes in place while investigating.
- Do not run the destructive down migrations on a live system as an incident
  response. They require a maintenance window and are only for controlled
  environment rollback.
