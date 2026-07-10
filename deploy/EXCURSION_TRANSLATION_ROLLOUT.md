# Excursion Translation Rollout

This runbook covers the asynchronous excursion translation queue owned by
`excursion-service`. Azure credentials remain owned by `translation-service`
and must be injected through the environment or the deployment secret store.

## Configuration

```bash
EXCURSION_ASYNC_TRANSLATION_ENABLED=true
EXCURSION_TRANSLATION_WORKER_ENABLED=true
EXCURSION_TRANSLATION_WORKER_BATCH_SIZE=10
EXCURSION_TRANSLATION_WORKER_INTERVAL=2s
EXCURSION_TRANSLATION_MAX_ATTEMPTS=5
EXCURSION_TRANSLATION_RETRY_BASE_DELAY=30s
EXCURSION_TRANSLATION_REQUEST_TIMEOUT=8s
EXCURSION_TRANSLATION_LOCK_TIMEOUT=2m
```

`TRANSLATION_SERVICE_URL`, token-service credentials, mTLS certificates, and
the existing internal service token must be configured for the environment.
The `excursion-service` service account needs the `translation:translate`
role. Do not place Azure keys in Compose files, images, logs, or this runbook.
Both `TRANSLATION_PROVIDER=azure` and `TRANSLATION_PROVIDER=azure_translator`
are supported; `azure_translator` is the canonical value for new environments.

The provider scope is intentionally limited to guide-authored itinerary item
`title` and `description` fields. Landmark title/description content comes from
the localized place catalog, while included-item labels are persisted in their
localized form. Neither landmark content nor included items may be sent to the
translation provider.

The steady-state default keeps asynchronous scheduling enabled and the worker
disabled. This allows excursion writes to succeed and persist translation jobs
when provider credentials or quota are unavailable. During the first schema
rollout only, explicitly set both flags to `false` as described below.

`excursion-service` has no Compose startup dependency on
`translation-service`. It must remain healthy and accept excursion writes when
the translation container or Azure provider is unavailable.

## Rollout

1. Deploy migration `100_async_excursion_translation_jobs.up.sql` with both
   feature flags disabled. Confirm the migration is present in
   `schema_migrations` and the service remains healthy.
2. On staging, enable `EXCURSION_ASYNC_TRANSLATION_ENABLED=true` while keeping
   the worker disabled. Create and update an excursion, then verify durable
   `PENDING` jobs were written in the same transaction.
3. Enable `EXCURSION_TRANSLATION_WORKER_ENABLED=true` on staging. Verify jobs
   transition through `PROCESSING` to `COMPLETED`, offer itinerary translations
   are updated, and the details API returns `translationInfo` for the request's
   `X-Language`/`Accept-Language`.
4. Enable both flags in production with batch size `10`. Increase the batch
   size only after pending age, failure rate, provider quota, and DB load remain
   stable for a full traffic cycle.

## Backfill

Dry-run does not write jobs or call `translation-service`:

```bash
docker compose --profile translation-backfill run --rm excursion-translation-backfill
```

Apply after reviewing the printed counts:

```bash
docker compose --profile translation-backfill run --rm excursion-translation-backfill -apply
```

The command uses the same scheduler, source hash, uniqueness constraint, and
repository enqueue path as online create/update operations. It leaves active
and completed jobs unchanged, and safely reactivates matching `FAILED` jobs as
`PENDING` with attempts reset to zero.

## Provider Outage

Keep the asynchronous write path enabled so excursion creation remains
independent from the provider, and pause only processing:

```bash
EXCURSION_ASYNC_TRANSLATION_ENABLED=true
EXCURSION_TRANSLATION_WORKER_ENABLED=false
```

After Azure credentials or quota recover, enable the worker and run the
backfill in `-apply` mode once to reactivate jobs that reached `FAILED` before
processing was paused. Review the dry-run count first.

## Metrics And Alerts

`excursion-service` exposes these Prometheus metrics on `/metrics`:

- `excursion_translation_jobs_pending`
- `excursion_translation_jobs_processing`
- `excursion_translation_jobs_completed_total`
- `excursion_translation_jobs_failed_total`
- `excursion_translation_jobs_stale_total`
- `excursion_translation_duration_seconds`
- `excursion_translation_oldest_pending_age_seconds`

Recommended alerts:

- oldest pending age above 15 minutes for 5 minutes;
- failed jobs above 10% of completed plus failed jobs over 10 minutes;
- pending jobs above zero while completed count does not change for 5 minutes;
- repeated `quota_exhausted` outcomes from `translation-service`;
- service-token authorization or provider authentication errors.

Worker logs include job and entity identifiers, languages, source hash,
attempt, status, provider, duration, and error code. They must never include
source text, translated text, itinerary descriptions, or raw request bodies.

## Rollback

Stop processing without losing queued work:

```bash
EXCURSION_TRANSLATION_WORKER_ENABLED=false
```

Return new writes to the synchronous compatibility path if required:

```bash
EXCURSION_ASYNC_TRANSLATION_ENABLED=false
```

Do not delete queue rows during rollback. Pending jobs remain resumable. The
schema migration is backward compatible and should normally stay deployed;
run the down migration only after all code using the columns and table has been
removed.
