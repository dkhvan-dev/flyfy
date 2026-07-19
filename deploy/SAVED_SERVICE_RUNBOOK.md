# Saved Service: Production Operations Runbook

**Статус:** production baseline

**Проверено по реализации:** 2026-07-16

**Сервис:** `saved-service`
**Владельцы:** `<SAVED_ON_CALL>`, `<DBA_ON_CALL>`, `<NATS_ON_CALL>`, `<SECURITY_ON_CALL>`

## 1. Назначение и жесткие границы

Saved хранит только личные сохранения и личные коллекции владельца. Поддерживаемые пользовательские действия ограничены сохранением или удалением одной карточки и ручным распределением одной карточки по личным коллекциям.

В сервисе отсутствуют:

- sharing, публичные ссылки и совместные коллекции;
- заметки и описания коллекций;
- bulk mutation;
- Undo, recovery window и «Недавно удаленные»;
- manual reorder;
- persistent client operation markers, offline mutation queue и replay после перезапуска приложения.

Canonical state всегда находится в PostgreSQL. Клиент может повторить mutation с тем же idempotency key или прочитать operation status только пока его процесс хранит operation identity. После restart клиент загружает canonical state обычными Saved API.

Закрытый набор product source-типов: `ATTRACTION`, `ACTIVITY`, `USER`. `USER`
охватывает любой активный профиль, включая профиль гида. Экскурсии
остаются в домене гида, календаря и бронирования и не являются SavedTarget.
Retired или неизвестные entity types отклоняются fail-closed.

## 2. Зависимости и data flow

| Зависимость | Назначение | Поведение при отказе |
| --- | --- | --- |
| PostgreSQL 17 | relationships, collections, projections, operation journal, outbox, inbox, purge ledger | startup или `/ready` fail; personal API недоступен |
| NATS JetStream | source lifecycle ingestion и privacy-safe Saved domain events | startup или `/ready` fail; lifecycle runner failure завершает процесс |
| token-service | service JWT, session generation validation, Gateway JWT/JWKS | `/ready` fail; request fail-closed |
| activity-service | live eligibility и lifecycle для Activity | `/ready` fail; Activity expansion fail-closed |
| place-service | eligibility и lifecycle для Attraction | `/ready` fail; new expansion недоступен |
| user-service | PUBLIC projection любого активного USER-профиля | `/ready` fail; USER expansion недоступен |
| chat-service | bounded batch-проверка target-owned blocks без profile payload | USER expansion fail-closed; существующие USER cards scrubbed до removable placeholder |
| switches-service platform policy | общая аварийная policy для personal data | stale/unavailable policy fail-closed |
| API Gateway | auth, trusted headers, route/rate/body policy | внешний Saved API недоступен; прямой listener не должен быть публичным |

JetStream contracts:

- source stream: `SAVED_SOURCE`, subjects `saved.source.activity.lifecycle.v1`, `saved.source.attraction.lifecycle.v1`, `saved.source.guide.lifecycle.v1`;
- durable consumers: `SAVED_SERVICE_ACTIVITY_LIFECYCLE_V1`, `SAVED_SERVICE_ATTRACTION_LIFECYCLE_V1`, `SAVED_SERVICE_GUIDE_LIFECYCLE_V1`;
- lifecycle DLQ subject: `saved.source.saved-service.lifecycle.dlq.v1`;
- Saved domain stream: `SAVED_DOMAIN`, subject `saved.domain.lifecycle.v1`;
- `SAVED_DOMAIN` хранит только bounded privacy-safe event: event ID, kind, entity type, occurred_at и schema version.

Guide lifecycle consumer остается только переходным drain-контрактом для
исторических `GUIDE` events. После migration `008` он не является source для
USER projections и не разрешает новые GUIDE saves; USER freshness идет через
user-service reconciliation.

## 3. Безопасное выполнение команд

Все placeholders вида `<...>` обязательны к замене значениями конкретного окружения. Не вставлять секреты, DSN с паролем, subject, owner ID, target ID, collection title или raw query в тикет, shell history, dashboard label или лог.

Для PostgreSQL использовать read-only роль и secret-mounted `PGPASSFILE`:

```bash
export PGHOST="<SAVED_DB_HOST>"
export PGPORT="5432"
export PGUSER="<SAVED_READ_ONLY_USER>"
export PGDATABASE="saved_service_db"
export PGSSLMODE="verify-full"
export PGSSLROOTCERT="<POSTGRES_CA_FILE>"
export PGPASSFILE="<READ_ONLY_PGPASS_SECRET_FILE>"
```

Для NATS использовать read-only operations account и mounted credentials. Не передавать user/password в `NATS_URL`:

```bash
export NATS_URL="<TLS_NATS_URLS>"
export NATS_CREDS="<READ_ONLY_NATS_CREDS_FILE>"
export NATS_CA="<NATS_CA_FILE>"
export NATS_CERT="<READ_ONLY_NATS_CLIENT_CERT_FILE>"
export NATS_KEY="<READ_ONLY_NATS_CLIENT_KEY_FILE>"
```

Команды `nats stream view`, `nats stream get`, `nats consumer next` и любые аналоги, печатающие payload, в обычной диагностике запрещены.

## 4. Startup, probes и metrics

### 4.1 Порядок startup

1. One-shot migrator применяет еще не отмеченные `*.up.sql` в лексическом порядке и только после успеха записывает filename в `schema_migrations`.
2. Saved подключается к PostgreSQL.
3. Инициализируются crypto keys, service auth, Gateway verifier, platform policy и source adapters.
4. Saved подключается к NATS.
5. Проверяется или создается `SAVED_DOMAIN` с заданным `SAVED_DOMAIN_STREAM_REPLICAS`.
6. Запускаются lifecycle consumer, outbox dispatcher, outbox cleanup,
   maintenance и bounded reconciliation известных ACTIVE projections.
7. Запускаются public HTTP listener и, при `MTLS_MODE=enforce`, отдельный internal mTLS listener.

Startup fail-closed. В production обязательны TLS PostgreSQL/NATS, mTLS, non-development crypto keys и минимум 3 replicas для `SAVED_DOMAIN`.

### 4.2 Probes

```bash
curl --fail --silent --show-error \
  "http://<SAVED_PRIVATE_HOST>:8102/health"

curl --fail --silent --show-error \
  "http://<SAVED_PRIVATE_HOST>:8102/ready"

curl --fail --silent --show-error \
  "http://<SAVED_PRIVATE_HOST>:8102/metrics"
```

Ожидаемый healthy body для первых двух probes:

```json
{"status":"ok"}
```

`/health` проверяет только живой HTTP process. `/ready` последовательно проверяет:

- PostgreSQL;
- свежую и валидную platform personal-data policy;
- получение service token;
- gRPC connectivity `token-session`, `attraction-source`, `activity-source`, `user-source`;
- NATS connection;
- запущенный и не завершившийся background coordinator.

`/ready` не измеряет consumer lag, replica health stream или возраст DB backlog. Для них обязательны отдельные alerts ниже. Ответ `/ready` намеренно не раскрывает имя отказавшей зависимости.

`/metrics` не имеет встроенной auth. Scrape разрешен только из private observability network; маршрут нельзя публиковать в Internet.

### 4.3 Реально экспортируемые metrics

- `saved_http_requests_total`, `saved_http_errors_total`, `saved_http_request_duration_seconds`;
- `saved_runtime_runs_total`, `saved_runtime_run_duration_seconds`;
- `saved_runtime_consecutive_failures`, `saved_runtime_last_run_success`;
- `saved_runtime_last_success_timestamp_seconds`, `saved_runtime_last_error_timestamp_seconds`;
- `saved_lifecycle_outcomes_total`, `saved_lifecycle_actions_total`, `saved_lifecycle_errors_total`;
- `saved_lifecycle_delivery_attempts`, `saved_lifecycle_inbox_cleanup_deleted_total`;
- `saved_outbox_events_total`, `saved_outbox_recovery_total`, `saved_outbox_likely_more`;
- `saved_outbox_dispatch_duration_seconds`, `saved_outbox_cleanup_deleted_total`;
- `saved_maintenance_rows_total`, `saved_maintenance_events_total`, `saved_maintenance_ticks_total`;
- `saved_maintenance_backlog`, `saved_maintenance_run_duration_seconds`.
- `saved_reconciliation_total`, `saved_reconciliation_backlog`,
  `saved_reconciliation_run_duration_seconds`.

Route labels являются allowlisted templates; user, target, collection, query и error text в labels отсутствуют.

## 5. SLO и обязательные alerts

Основные SLO:

| Сигнал | Target |
| --- | --- |
| Personal API availability | 99.9% в месяц |
| Mutation p95/p99 | `<=350/750 ms` |
| List p95/p99 | `<=300/700 ms` |
| Search p95/p99 | `<=350/800 ms` при 10 000 saves |
| Operation status p95/p99 | `<=150/400 ms` |
| Projection event lag p95/p99 | `<=60 s / 5 min` |
| Activity deny/private purge p95/p99 | `<=2/10 s` |
| Ephemeral shell purge | не позже 1 h после expiry |
| Deleted collection child cleanup | не позже 24 h |
| Terminal row purge | не позже 24 h после eligibility |
| Platform policy propagation target/hard | `<=10/30 s` |
| Confirmed data loss/cross-account exposure | 0 |

### 5.1 P1 alerts

- cross-account read/write, auth bypass, policy bypass или personal payload в логах;
- confirmed data loss;
- non-PUBLIC projection содержит card/search/media payload;
- `PRIVATE` projection для типа, отличного от `ACTIVITY`;
- lifecycle `DLQ_TERMINATED` до классификации события;
- Activity visibility/deny lag больше 10 секунд, если incident связан с privacy transition;
- восстановление backup открылось для traffic до replay deletion ledger.

Первая реакция: активировать platform policy `LOCKED`, остановить rollout, назначить Security/Privacy incident commander и перейти к разделу 13.

### 5.2 P2 alerts

| Alert | Рекомендуемый trigger | Первая диагностика |
| --- | --- | --- |
| SavedNotReady | `/ready` fail 2 минуты | probes, startup logs, DB/NATS/policy checks |
| SavedHTTP5xx | 5xx ratio >1% 5 минут | HTTP metrics по route template/status class |
| SavedLatency | p99 выше SLO 10 минут | HTTP histogram, DB locks, CPU, NATS/source latency |
| RuntimeFailures | `saved_runtime_consecutive_failures >= 3` | task label и bounded runtime logs |
| LifecycleRecovery | рост `RETRY`, `ACK_FAILED`, `DLQ_RETRY`, `ITERATOR_RETRY` | consumer metadata и DB inbox aggregates |
| OutboxDead | любой рост `saved_outbox_events_total{result="dead"}` | outbox aggregates, `SAVED_DOMAIN` metadata |
| OutboxBacklog | `saved_outbox_likely_more=1` 5 минут или oldest due >5 минут | outbox SQL, NATS connectivity |
| MaintenanceStalled | last success >35 минут или failures >=3 | maintenance metrics и retention SQL |
| PendingOperationStale | oldest PENDING past deadline >20 минут | operations SQL |
| PurgeStalled | active purge `next_attempt_at` overdue >20 минут | purge aggregate и status endpoint |
| ProjectionGCOverdue | shell >1 h after expiry или standard candidate >24 h after eligibility | GC SQL |
| RetentionOverdue | terminal rows >24 h after eligibility | maintenance SQL |
| NATSReplicaOrLag | stream replicas <3 или consumer pending/redelivery sustained | metadata-only NATS commands |
| DBRisk | disk <20%, WAL archive failure, replica lag/lock threshold | PostgreSQL platform metrics |

PromQL examples, где `<SAVED_SELECTOR>` заменяется стандартными low-cardinality environment/job labels:

```promql
sum(rate(saved_http_errors_total{<SAVED_SELECTOR>,status_class="5xx"}[5m]))
/
clamp_min(sum(rate(saved_http_requests_total{<SAVED_SELECTOR>}[5m])), 1)
```

```promql
histogram_quantile(
  0.99,
  sum by (le, route, method) (
    rate(saved_http_request_duration_seconds_bucket{<SAVED_SELECTOR>}[10m])
  )
)
```

```promql
max by (task) (saved_runtime_consecutive_failures{<SAVED_SELECTOR>}) >= 3
```

```promql
increase(saved_lifecycle_actions_total{<SAVED_SELECTOR>,action="DLQ_TERMINATED"}[5m]) > 0
```

Не использовать `saved_runtime_last_success_timestamp_seconds{task="LIFECYCLE"}` как heartbeat: lifecycle runner блокирующий и сообщает runtime observation только при неожиданном завершении. Его здоровье определяется readiness, JetStream consumer metadata и lifecycle action metrics.

## 6. Универсальная первая реакция

1. Зафиксировать UTC start time, environment, image digest, capability revision и incident ID. Не добавлять personal identifiers.
2. Проверить `/health`, `/ready`, `/metrics`.
3. Проверить последний deploy, migration job и изменение flags/keys/certificates.
4. Запустить aggregate-only SQL из раздела 15.
5. Проверить NATS stream/consumer metadata из раздела 8.
6. Проверить platform policy decision из раздела 10.
7. Если DB/NATS/policy healthy, проверить transport к token/source services и их собственные health dashboards.
8. Не выполнять ручные `UPDATE`, `DELETE`, replay payload или удаление migration markers в ходе первичной диагностики.

Проверка mTLS transport к token/source dependency, без утверждения application-level gRPC health:

```bash
openssl s_client -brief -verify_return_error \
  -connect "<DEPENDENCY_HOST>:<DEPENDENCY_TLS_PORT>" \
  -servername "<DEPENDENCY_TLS_SERVER_NAME>" \
  -CAfile "<SAVED_MTLS_CA_FILE>" \
  -cert "<SAVED_MTLS_CLIENT_CERT_FILE>" \
  -key "<SAVED_MTLS_CLIENT_KEY_FILE>" \
  </dev/null
```

Повторить для token, activity, place, user и internal HTTPS endpoint chat-service. Успешный TLS handshake не заменяет их application health check. Отказ chat-service не делает весь Saved unready: USER reads fail closed до unavailable placeholders, USER expansion запрещается, а Attraction/Activity продолжают работать.

Для Compose-based environment безопасный обзор:

```bash
docker compose -f deploy/docker-compose.yml ps \
  saved-service saved-postgres saved-postgres-migrator nats

docker compose -f deploy/docker-compose.yml logs --since=15m \
  saved-service saved-postgres-migrator
```

В production использовать эквивалентные read-only команды оркестратора и централизованные логи.

## 7. PostgreSQL incidents

### Симптомы

- `/ready` 503 при healthy process;
- рост 5xx/latency;
- runtime task failures;
- migration не завершилась;
- outbox/maintenance backlog;
- replica lag, WAL archive failure, disk pressure или lock waits.

### Диагностика

```bash
psql -X -v ON_ERROR_STOP=1 -c \
  "BEGIN READ ONLY; SET LOCAL statement_timeout='5s'; SELECT now() AS db_now, pg_is_in_recovery() AS replica; COMMIT;"
```

Затем выполнить раздел 15. Для lock investigation использовать штатный PostgreSQL dashboard. Не завершать backend PID без DBA approval; сначала установить владельца и тип транзакции.

### Safe remediation

- восстановить connectivity/certificates/credentials или выполнить managed failover по DB runbook;
- при disk pressure сначала остановить rollout/backfill и восстановить headroom, а не удалять Saved rows;
- не отключать FK/check constraints;
- не повышать pool size как первую реакцию;
- не запускать down migration;
- после failover дождаться `/ready`, проверить migrations, search status, operation/outbox/maintenance aggregates и только затем возвращать traffic.

## 8. NATS, lifecycle, outbox и DLQ

### 8.1 Metadata-only inspection

```bash
nats --server "$NATS_URL" --creds "$NATS_CREDS" \
  --tlsca "$NATS_CA" --tlscert "$NATS_CERT" --tlskey "$NATS_KEY" \
  stream info SAVED_SOURCE --json

nats --server "$NATS_URL" --creds "$NATS_CREDS" \
  --tlsca "$NATS_CA" --tlscert "$NATS_CERT" --tlskey "$NATS_KEY" \
  consumer info SAVED_SOURCE SAVED_SERVICE_ACTIVITY_LIFECYCLE_V1 --json

nats --server "$NATS_URL" --creds "$NATS_CREDS" \
  --tlsca "$NATS_CA" --tlscert "$NATS_CERT" --tlskey "$NATS_KEY" \
  consumer info SAVED_SOURCE SAVED_SERVICE_ATTRACTION_LIFECYCLE_V1 --json

nats --server "$NATS_URL" --creds "$NATS_CREDS" \
  --tlsca "$NATS_CA" --tlscert "$NATS_CERT" --tlskey "$NATS_KEY" \
  consumer info SAVED_SOURCE SAVED_SERVICE_GUIDE_LIFECYCLE_V1 --json

nats --server "$NATS_URL" --creds "$NATS_CREDS" \
  --tlsca "$NATS_CA" --tlscert "$NATS_CERT" --tlskey "$NATS_KEY" \
  stream info SAVED_DOMAIN --json
```

GUIDE consumer проверяется только в объявленное окно compatibility drain. Его
lag не означает stale USER projection; после migration `008` USER freshness
проверяется по reconciliation/user-service.

Проверить replicas, cluster leader, message count, consumer `num_pending`, `num_ack_pending`, redeliveries и last delivery. Не извлекать message payload.

### 8.2 Lifecycle behavior

- 2 workers на source binding;
- explicit ACK, `AckWait=30s`, `MaxDeliver=8`, `MaxAckPending=64`;
- processing timeout 10s;
- retry от 1s до 5m;
- inbox dedup retention 14d;
- malformed/permanent или исчерпавшее 8 deliveries событие переводится в DLQ flow.

Lifecycle runner, завершившийся при живом process context, считается fatal: coordinator останавливает процесс, чтобы privacy events не перестали обрабатываться незаметно.

### 8.3 DLQ handling

DLQ record содержит только `schema_version`, `failed_subject`, `error_code`, `payload_sha256`. Original event payload в DLQ не сохраняется.

1. Считать alert потенциально P1, пока не доказано, что событие не связано с visibility/deny/delete.
2. По metrics определить source и bounded error code.
3. По producer-side outbox metadata и digest локализовать исходное событие внутри защищенного source contour. Не копировать payload в тикет или Saved logs.
4. Исправить source contract/data или consumer compatibility.
5. Попросить source owner выпустить новое корректное versioned lifecycle event с новым event ID и monotonic revisions через producer-owned outbox.
6. Проверить ACK/outcome и projection aggregate. Закрыть incident только после проверки current canonical source state.

Запрещено публиковать DLQ body обратно в source subject: в нем нет исходного event, а hash не является replay payload. В Saved нет operator replay endpoint и нет ручного reconcile endpoint.

### 8.4 Outbox behavior и remediation

Saved dispatcher обрабатывает до 100 rows за batch, concurrency 8, lease 5m, publish timeout 5s, максимум 8 attempts. Terminal outbox retention 14d. `SAVED_DOMAIN` создается сервисом с 14d max age, 10m duplicate window и минимум 3 replicas в production.

При NATS outage оставить `PENDING` rows нетронутыми: dispatcher восстановит stale lease и повторит delivery. Если появились `DEAD` rows:

- не переводить их вручную в `PENDING`;
- не удалять их;
- проверить downstream idempotency и причину bounded `last_error_code`;
- использовать только reviewed one-shot recovery, созданный delivery-командой для конкретного incident. Готового public/internal replay endpoint в реализации нет.

### 8.5 Reconciliation quarantine recovery

Quarantine означает последовательные permanent `INVARIANT` или `UNSUPPORTED` результаты. Предпочтительное восстановление всегда автоматическое: source owner исправляет canonical contract/data и публикует новое authoritative lifecycle event с monotonic source или visibility revision. Применение более новой revision сбрасывает failure streak и quarantine; ручное снятие в этом случае запрещено.

Сначала выполнить payload-free диагностику под read-only ролью. Значения target передаются только через защищенную operator session и не копируются в тикет или общий лог:

```sql
BEGIN READ ONLY;
SET LOCAL lock_timeout = '1s';
SET LOCAL statement_timeout = '5s';

SELECT source_service,
       source_revision,
       projection_revision,
       visibility_revision,
       visibility_status,
       reconciliation_failure_count,
       reconciliation_failure_kind,
       reconciliation_quarantined_at,
       reconciliation_quarantine_reason,
       reconciliation_fail_closed_at IS NOT NULL AS local_fail_closed
FROM saved_content_projections
WHERE entity_type = :'entity_type'
  AND entity_id = :'entity_id';

COMMIT;
```

Сверить bounded reason с source-owner deployment/contract, consumer lag и последней canonical revision. Не читать card/search/media payload. Если ожидаемое новое lifecycle event отсутствует, сначала восстановить producer/outbox delivery.

Ручное снятие quarantine разрешено только после change approval от Saved owner и DBA, с incident/change reference, подтвержденным исправлением причины и точным снимком revisions/quarantine timestamp. Использовать отдельную privileged break-glass роль; PostgreSQL audit logging должен сохранять actor, `application_name`, statement и row count.

```sql
BEGIN;
SET LOCAL lock_timeout = '1s';
SET LOCAL statement_timeout = '5s';
SELECT set_config(
    'application_name',
    left('saved-quarantine-recovery:' || :'incident_ref', 63),
    true
);

SELECT source_service,
       source_revision,
       projection_revision,
       visibility_revision,
       visibility_status,
       reconciliation_quarantined_at,
       reconciliation_quarantine_reason
FROM saved_content_projections
WHERE entity_type = :'entity_type'
  AND entity_id = :'entity_id'
FOR UPDATE;

UPDATE saved_content_projections
SET reconciliation_failure_count = 0,
    reconciliation_failure_kind = NULL,
    reconciliation_quarantined_at = NULL,
    reconciliation_quarantine_reason = NULL,
    reconciliation_next_attempt_at = clock_timestamp()
WHERE entity_type = :'entity_type'
  AND entity_id = :'entity_id'
  AND source_service = :'expected_source_service'
  AND source_revision = :'expected_source_revision'::bigint
  AND projection_revision = :'expected_projection_revision'::bigint
  AND visibility_revision = :'expected_visibility_revision'::bigint
  AND visibility_status = :'expected_visibility_status'
  AND reconciliation_quarantined_at = :'expected_quarantined_at'::timestamptz
  AND reconciliation_quarantine_reason = :'expected_quarantine_reason'
  AND reconciliation_failure_kind = :'expected_quarantine_reason'
  AND reconciliation_lease_token IS NULL
RETURNING source_service,
          source_revision,
          projection_revision,
          visibility_revision,
          reconciliation_failure_count,
          reconciliation_quarantined_at;

COMMIT;
```

Команда обязана вернуть ровно `UPDATE 1`; при `UPDATE 0` или любом расхождении выполнить `ROLLBACK`, повторить диагностику и получить новое approval. В audit/change record сохранить только incident reference, actor, environment, source service, guarded revision tuple, quarantine reason и row count. После commit проверить один bounded reconciliation attempt и новую persisted schedule; повторный permanent failure требует нового расследования, а не повторного unquarantine.

Публичного или internal HTTP endpoint для reconcile/unquarantine нет и добавлять его нельзя.

## 9. Maintenance, operations, purge и projection GC

Default scheduler:

- maintenance каждые 15m;
- при backlog следующий run через 250ms;
- timeout одного run 2m;
- retry backoff 5s..5m;
- batch 100, максимум 8 bounded ticks за run.

Maintenance выполняет subject purge, expiry PENDING operations, terminal retention, deleted-child cleanup и projection GC. Ошибка одного stage завершает текущий tick; coordinator повторяет весь bounded run с backoff.

### Pending operations

- commit deadline не больше 15s;
- operation после deadline не может commit-иться, даже если DB row еще `PENDING`;
- live quota считает только `PENDING` с будущим deadline;
- cleanup физически переводит overdue row в `EXPIRED` bounded maintenance worker;
- отсутствие persistent client marker означает, что после client restart оператор не восстанавливает intent: пользовательский клиент читает canonical state.

Не удалять PENDING row и не создавать новую operation от имени пользователя. Alert только если oldest overdue превышает 20m, то есть больше нормального 15m maintenance interval с запасом.

### Projection GC и retention

- ephemeral shell: hard alert, если row существует более 1h после `shell_expires_at`;
- standard referenced projection без Saved rows: eligibility через 14d после `gc_candidate_at`, hard alert еще через 24h;
- deleted collection children: hard alert после 24h;
- removed items, removed memberships, deleted collections, terminal operations/outbox/inbox и completed purge ledger: 14d eligibility плюс 24h hard purge SLO.

Не выполнять ad hoc delete. Сначала восстановить maintenance runner/DB, убедиться, что backlog уменьшается, и только затем рассматривать reviewed one-shot maintenance command. Отдельного operator maintenance endpoint нет.

## 10. Platform policy и kill switches

### 10.1 Проверка policy

`<POLICY_INTERNAL_AUTH_HEADER_FILE>` должен быть secret-managed файлом, содержащим ровно один internal auth header. Не печатать его содержимое.

```bash
curl --fail --silent --show-error \
  --header "@<POLICY_INTERNAL_AUTH_HEADER_FILE>" \
  "https://<SWITCHES_INTERNAL_HOST>/api/v1/internal/platform-policy/personal-data"
```

Ожидаются positive `revision`, state `AVAILABLE|LOCKED`, `issued_at` и `valid_until`; validity window не больше 30s. Stale, malformed, rollback revision и unavailable response блокируют Saved fail-closed.

### 10.2 Реальное поведение switches

| Механизм | Фактическое поведение | Когда использовать |
| --- | --- | --- |
| `SAVED_ITEMS_PRODUCT_ENABLED` | публикуется через capabilities; требует config rollout | product discovery/cohort rollback |
| `SAVED_SEARCH_PRODUCT_ENABLED` | публикуется через capabilities; startup требует готовый search contract | штатно включается после успешного `saved-search-rollout` |
| `SAVED_COLLECTIONS_PRODUCT_ENABLED` | публикуется через capabilities; требует config rollout | collections discovery/cohort rollback |
| `SAVED_ROLLOUT_*_BASIS_POINTS` | sticky owner/capability cohort, диапазон `0..10000` | постепенный rollout без marker store |
| `SAVED_ROLLOUT_ANDROID_MIN_BUILD`, `SAVED_ROLLOUT_IOS_MIN_BUILD` | минимальный положительный store build для expansion | отсечение несовместимого клиента |
| Platform policy `LOCKED` | Gateway и Saved блокируют personal reads/writes; final commit повторно проверяет policy | security/privacy/data-integrity incident |

Product flags и cohort rules не являются security boundary. Они блокируют на
backend только discovery и новые expansion (`save/create/add/search`), сохраняя
канонические reads и ручные reduction (`unsave/delete/remove`). Saved middleware
вычисляет cohort по trusted owner ID и bounded `X-Client-Platform`/`X-App-Build`;
отсутствующие или malformed client metadata fail-closed для expansion. При
изменении правил обязательно увеличить `SAVED_CAPABILITY_REVISION`. Для полной
немедленной блокировки personal reads/writes использовать только утвержденную
platform policy procedure через существующий admin control plane
`PUT /api/v1/platform-policy/personal-data`.

Release CI обязан передавать фактический mobile build через
`--dart-define=INFLAP_APP_BUILD=<build>`. Закрытый entity scope не расширяется
через rollout-переменные: поддерживаются только `ATTRACTION`, `ACTIVITY`, `USER`.

`SAVED_SEARCH_PRODUCT_ENABLED=true` или `SAVED_COLLECTIONS_PRODUCT_ENABLED=true` при `SAVED_ITEMS_PRODUCT_ENABLED=false` является invalid configuration и не пройдет startup. При core rollback сначала выключить search/collections, затем core, одним согласованным config rollout.

Saved-specific destructive-data breaker или mutation-only admin endpoint в текущей реализации отсутствует. Не придумывать такой endpoint в incident.

Policy `LOCKED` не удаляет данные. Она также блокирует пользовательские reducing actions, поэтому routine product rollback не должен использовать emergency lock без incident основания.

## 11. Zero-downtime migrations

### 11.1 Общие правила

1. Подтвердить successful backup/WAL archive и tested restore path.
2. Проверить disk/WAL/replica headroom и отсутствие long transactions.
3. Сначала deploy backward-compatible expand schema, затем совместимый binary, backfill, contract и только потом cleanup в отдельном release.
4. Migrator применяет только `*.up.sql`; `003d_saved_search_contract.sql` и `006b_saved_reconciliation_scheduler_contract.sql` автоматически не выполняются.
5. Не оборачивать `CREATE INDEX CONCURRENTLY` в transaction.
6. Не вставлять migration marker вручную и не запускать down migration в live incident.
7. При fail миграции оставить Saved not-ready, устранить lock/disk/invalid-index причину и повторить тот же immutable artifact.

Migrator определяет `CREATE INDEX CONCURRENTLY` по содержимому migration, а не по списку имен. Перед записью marker он проверяет `pg_index.indisvalid/indisready` по всей базе и fail-closed при любой незавершенной index build. Это предотвращает ситуацию, когда `IF NOT EXISTS` после interrupted build пропускает INVALID index и ошибочно фиксирует migration как applied.

Read-only migration status:

```bash
psql -X -v ON_ERROR_STOP=1 -c \
  "BEGIN READ ONLY; SET LOCAL statement_timeout='5s'; SELECT filename, applied_at FROM schema_migrations ORDER BY filename; COMMIT;"
```

### 11.2 Saved search expand/backfill/contract

Штатный deploy запускает `saved-search-rollout` после normal migrator и до
`saved-service`. Job использует тот же immutable Saved image digest, выполняет
bounded backfill и contract, а зависимость `service_completed_successfully` не
позволяет приложению стартовать при частично подготовленной БД. Повторный запуск
на готовой схеме является no-op и возвращает `ready=true`.

```bash
/app/saved-search-backfill \
  -mode=rollout \
  -batch-size=500 \
  -max-batches=10000 \
  -pause=25ms
```

Для ручного восстановления во всех фазах до успешного contract держать
`SAVED_SEARCH_PRODUCT_ENABLED=false` и не включать search cohort. Использовать
тот же immutable Saved image digest, который будет обслуживать traffic.

Required job environment передается secret references, без inline password:

```bash
export PGHOST="<SAVED_DB_HOST>"
export PGPORT="5432"
export PGUSER="<SAVED_MIGRATION_USER>"
export PGDATABASE="saved_service_db"
export PGSSLMODE="verify-full"
export PGSSLROOTCERT="<POSTGRES_CA_FILE>"
export PGPASSFILE="<MIGRATION_PGPASS_SECRET_FILE>"
```

**Expand**

Normal migrator применяет:

- `003_saved_search.up.sql`: nullable V1 columns, dual-write trigger, `NOT VALID` parity constraint;
- `003a_saved_search_owner_index.up.sql`: final owner index concurrently;
- `003b_saved_search_projection_index.up.sql`: final projection index concurrently;
- `003c_saved_search_backfill_index.up.sql`: temporary partial backfill index concurrently.

Проверка status из immutable image:

```bash
/app/saved-search-backfill -mode=status
```

До backfill должны быть true `columns_ready`, `trigger_ready`, `parity_constraint_present`, `owner_index_ready`, `projection_index_ready`, `backfill_index_ready`.

**Bounded backfill**

```bash
/app/saved-search-backfill \
  -mode=backfill \
  -batch-size=500 \
  -max-batches=100 \
  -pause=25ms
```

Повторять отдельными jobs, пока JSON не вернет `complete=true` и `status.pending=false`. Каждый batch является отдельной короткой transaction с `FOR UPDATE SKIP LOCKED`; persistent cursor/marker отсутствует.

**Contract**

```bash
/app/saved-search-backfill -mode=contract
```

Contract валидирует parity constraint, удаляет temporary backfill index concurrently и проверяет отсутствие stale rows. Включать search cohort разрешено только при `ready=true`, `parity_constraint_validated=true`, `backfill_index_present=false`, `pending=false`.

После ручного восстановления:

1. установить `SAVED_SEARCH_PRODUCT_ENABLED=true`;
2. увеличить `SAVED_CAPABILITY_REVISION`;
3. выполнить config rollout;
4. включать cohorts постепенно, наблюдая p99, DB CPU/buffer reads,
   `saved_search_first_pages_total{result="zero_results"}` и 5xx.

В штатном Compose-деплое эти шаги заменены обязательным rollout-job и полной
когортой из deployment config; отдельные search env/secrets устанавливать не
нужно.

**Interrupted concurrent index**

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

Если один из строго перечисленных indexes invalid, DBA по approved change удаляет только этот invalid index через `DROP INDEX CONCURRENTLY`, после чего повторяется соответствующая migration. Не удалять valid index. Если marker уже присутствует при invalid index, считать это schema drift и не менять `schema_migrations` без DBA review.

**Search rollback**

- вернуть `SAVED_SEARCH_PRODUCT_ENABLED=false` и увеличить capability revision;
- остановить search cohort/client discovery;
- при необходимости вернуть предыдущий binary, совместимый с expanded schema;
- оставить columns, trigger, constraint и indexes;
- не запускать `003*_saved_search*.down.sql` в production incident.

### 11.3 Reconciliation scheduler expand/contract

До contract все старые и новые Saved instances должны быть совместимы с nullable scheduler columns. Normal migrator применяет:

- `006_saved_reconciliation_scheduler.up.sql`: nullable lease/schedule/quarantine metadata и три `NOT VALID` constraints;
- `006a_saved_reconciliation_scheduler_index.up.sql`: partial due-schedule index через `CREATE INDEX CONCURRENTLY`.

После deploy нового binary проверить отсутствие invalid indexes:

```sql
SELECT c.relname, i.indisready, i.indisvalid
FROM pg_index AS i
JOIN pg_class AS c ON c.oid = i.indexrelid
WHERE c.relname = 'idx_saved_content_projections_reconciliation_due_v1';
```

Затем отдельным retryable contract job выполнить:

```bash
psql -X -v ON_ERROR_STOP=1 \
  -f /migrations/saved-service/006b_saved_reconciliation_scheduler_contract.sql
```

Contract использует bounded `lock_timeout`/`statement_timeout` и валидирует lease, schedule и quarantine constraints без удаления expanded columns. При timeout job повторяется после устранения long transaction; feature rollback выполняется предыдущим совместимым binary, а не `006*.down.sql`.

Если concurrent build оставил reconciliation index invalid, DBA по approved change удаляет только этот invalid index через `DROP INDEX CONCURRENTLY`, после чего повторяет immutable `006a` migration. Marker вручную не добавлять.

## 12. Account purge over internal mTLS

Endpoints существуют только на internal mTLS listener:

- `POST /internal/v1/compliance/saved-subject-purges`;
- `GET /internal/v1/compliance/saved-subject-purges/{operationId}`.

Caller certificate обязан иметь точный SPIFFE ID из `SAVED_COMPLIANCE_ALLOWED_CALLER_SPIFFE_ID`, по умолчанию только user-service identity. Public listener не регистрирует purge route.

### 12.1 Preconditions

1. Account/auth owner durably revoke-нул active session.
2. Writes для subject/owner durably fenced до завершения purge.
3. Fence подтвержден source-of-truth orchestrator, не только UI.
4. UUIDv4 operation ID создан account deletion orchestrator и сохранен в его durable deletion ledger.
5. Secure request file имеет mode `0600`, не попадает в logs/artifacts.

Request file shape:

```json
{
  "operation_id": "<UUID_V4>",
  "subject": "<AUTH_SUBJECT_FROM_SECURE_ORCHESTRATOR>",
  "owner_user_id": "<OWNER_UUID_FROM_SECURE_ORCHESTRATOR>",
  "writes_fenced": true
}
```

Start:

```bash
curl --fail-with-body --silent --show-error \
  --cacert "<SAVED_MTLS_CA_FILE>" \
  --cert "<USER_SERVICE_MTLS_CLIENT_CERT_FILE>" \
  --key "<USER_SERVICE_MTLS_CLIENT_KEY_FILE>" \
  --header "Content-Type: application/json" \
  --data-binary "@<SECURE_PURGE_REQUEST_FILE>" \
  "https://<SAVED_INTERNAL_HOST>:<SAVED_INTERNAL_TLS_PORT>/internal/v1/compliance/saved-subject-purges"
```

Retry start только с теми же operation ID, subject и owner ID. Identity clash возвращает `409 SUBJECT_PURGE_IDENTITY_CONFLICT` и требует incident review, а не нового случайного ID.

Status:

```bash
curl --fail-with-body --silent --show-error \
  --cacert "<SAVED_MTLS_CA_FILE>" \
  --cert "<USER_SERVICE_MTLS_CLIENT_CERT_FILE>" \
  --key "<USER_SERVICE_MTLS_CLIENT_KEY_FILE>" \
  "https://<SAVED_INTERNAL_HOST>:<SAVED_INTERNAL_TLS_PORT>/internal/v1/compliance/saved-subject-purges/<UUID_V4>"
```

Phases: `OUTBOX -> COLLECTION_ITEMS -> COLLECTIONS -> SAVED_ITEMS -> OPERATIONS -> COLLECTION_USAGE -> USER_USAGE -> COMPLETED`.

Response намеренно не содержит subject или owner ID. Fence нельзя снимать до `phase=COMPLETED`. Completed ledger row хранится 14d, затем удаляется maintenance worker. Durable account deletion ledger вне Saved обязан жить по compliance policy и использоваться при PITR replay.

Для alerting использовать phase, `updated_at`, `next_attempt_at` и maintenance runtime metrics; не полагаться только на `attempt_count`.

## 13. Security/privacy incident

1. Активировать общую platform policy `LOCKED` через утвержденный switches admin control plane. Не менять Saved DB напрямую.
2. Проверить, что Gateway и direct Saved personal routes возвращают shared locked response, а ранее принятые PENDING operations не commit-ятся.
3. Остановить rollout и запретить новые deploy/backfill jobs.
4. Сохранить request/trace/operation IDs, UTC intervals, image/config revisions и aggregate metrics. Не сохранять body, query, target/collection IDs, title или subject.
5. Для Activity PUBLIC -> PRIVATE проверить source media revocation/rotation и lifecycle consumer lag.
6. Запустить non-public payload aggregate check из раздела 15. Любое значение больше нуля является P1.
7. При credential exposure начать rotation из раздела 14.
8. Выполнить forensic analysis только в approved restricted environment с audit trail.
9. Открыть traffic только после root cause fix, integrity checks, policy rehearsal и Security/Privacy approval.

Разрешенные log fields: request ID, trace ID, random operation ID, route template, method, status class, bounded task/source/action/outcome/error code, revision и aggregate count.

Запрещенные log fields: owner/user/subject, target/entity ID, collection ID/title, search query, cursor, request/response body, source projection payload, media reference и raw error text от DB/source.

## 14. Key and credential rotation

### 14.1 Operation HMAC

1. Создать независимый random key в KMS/secrets manager; version должна монотонно увеличиться.
2. Новый key установить как `OPERATION_HMAC_CURRENT_*`, прежний current добавить в `OPERATION_HMAC_PREVIOUS_KEYS` в формате `version:base64`.
3. Не больше 3 previous keys. Не переиспользовать cursor key material.
4. Выполнить rolling deploy и проверить readiness, save/unsave idempotent retry и operation status.
5. Старый key удалять только когда aggregate query не показывает ни одной operation с его `request_hmac_key_version`; минимальный overlap обычно не меньше 14d retention плюс rollout margin.

```sql
SELECT request_hmac_key_version, status, count(*) AS rows
FROM saved_operations
GROUP BY request_hmac_key_version, status
ORDER BY request_hmac_key_version, status;
```

### 14.2 Cursor AEAD

1. Новый 32-byte key установить как `CURSOR_ACTIVE_KEY_*`, прежний current добавить в `CURSOR_PREVIOUS_KEYS`.
2. Выполнить rolling deploy.
3. Держать previous key не меньше configured `CURSOR_TTL` плюс полный rollout overlap; hard maximum TTL в сервисе 24h.
4. Проверить list/search pagination до и после rotation. Invalid old cursor должен давать neutral `SAVED_CURSOR_INVALID`, без раскрытия причины.

### 14.3 mTLS, NATS, DB и service credentials

- CA rotation выполнять через dual-trust window, затем roll leaf certificates, затем удалить старый CA;
- NATS сначала разрешает old+new credentials, затем roll Saved, проверка streams/consumers, затем revoke old;
- DB credential rotation выполнять managed dual-user/dual-secret процедурой без DSN в manifests;
- token service secret rotation координировать с token-service owner и проверять service token readiness;
- после любой rotation проверить `/ready`, NATS metadata, source eligibility smoke и account purge mTLS authorization;
- secret values никогда не выводить через `env`, `docker inspect`, debug logs или support bundle.

## 15. Aggregate-only SQL diagnostics

Запросы ниже read-only, ограничены statement timeout и не возвращают personal identifiers.

```sql
BEGIN READ ONLY;
SET LOCAL statement_timeout = '15s';
SET LOCAL lock_timeout = '1s';

-- Schema state: ожидается 0 invalid indexes и 0 unexpected unvalidated
-- constraints после завершенного search contract.
SELECT count(*) AS invalid_saved_indexes
FROM pg_index AS i
JOIN pg_class AS table_class ON table_class.oid = i.indrelid
JOIN pg_namespace AS table_namespace ON table_namespace.oid = table_class.relnamespace
WHERE table_class.relname LIKE 'saved_%'
  AND table_namespace.nspname = current_schema()
  AND (NOT i.indisready OR NOT i.indisvalid);

SELECT table_class.relname AS table_name, constraint_row.conname
FROM pg_constraint AS constraint_row
JOIN pg_class AS table_class ON table_class.oid = constraint_row.conrelid
JOIN pg_namespace AS table_namespace ON table_namespace.oid = table_class.relnamespace
WHERE table_class.relname LIKE 'saved_%'
  AND table_namespace.nspname = current_schema()
  AND NOT constraint_row.convalidated
ORDER BY table_class.relname, constraint_row.conname;

-- Operation journal. Oldest overdue больше 20 минут требует incident.
SELECT
    count(*) FILTER (
        WHERE status = 'PENDING' AND commit_deadline > now()
    ) AS live_pending,
    count(*) FILTER (
        WHERE status = 'PENDING' AND commit_deadline <= now()
    ) AS overdue_pending,
    COALESCE(
        extract(epoch FROM now() - min(commit_deadline) FILTER (
            WHERE status = 'PENDING' AND commit_deadline <= now()
        )),
        0
    )::bigint AS oldest_overdue_seconds
FROM saved_operations;

SELECT COALESCE(max(pending_count), 0) AS max_live_pending_per_subject
FROM (
    SELECT count(*) AS pending_count
    FROM saved_operations
    WHERE status = 'PENDING' AND commit_deadline > now()
    GROUP BY subject
) AS aggregate_only;

-- Outbox: не выводит owner, target или event ID.
SELECT
    status,
    count(*) AS rows,
    min(created_at) AS oldest_created_at,
    max(attempt_count) AS max_attempt_count
FROM saved_outbox
GROUP BY status
ORDER BY status;

SELECT
    count(*) FILTER (
        WHERE status = 'PENDING' AND next_attempt_at <= now()
    ) AS due_rows,
    COALESCE(
        extract(epoch FROM now() - min(next_attempt_at) FILTER (
            WHERE status = 'PENDING' AND next_attempt_at <= now()
        )),
        0
    )::bigint AS oldest_due_seconds,
    count(*) FILTER (
        WHERE status = 'PENDING' AND locked_at < now() - interval '5 minutes'
    ) AS stale_leases,
    count(*) FILTER (WHERE status = 'DEAD') AS dead_rows
FROM saved_outbox;

SELECT COALESCE(last_error_code, 'NONE') AS error_code, count(*) AS rows
FROM saved_outbox
WHERE status = 'DEAD'
GROUP BY COALESCE(last_error_code, 'NONE')
ORDER BY rows DESC, error_code;

-- Lifecycle inbox outcomes by bounded source only.
SELECT source_service, processing_state, count(*) AS rows, max(processed_at) AS last_processed_at
FROM saved_inbox_dedup
GROUP BY source_service, processing_state
ORDER BY source_service, processing_state;

-- Subject purge backlog. Subject/owner/operation IDs не выводятся.
SELECT
    phase,
    count(*) AS jobs,
    min(created_at) AS oldest_created_at,
    max(updated_at) AS last_updated_at,
    count(*) FILTER (
        WHERE phase <> 'COMPLETED'
          AND next_attempt_at < now() - interval '20 minutes'
    ) AS stalled_jobs
FROM saved_subject_purge_operations
GROUP BY phase
ORDER BY phase;

-- Retention and GC hard-SLO breaches.
SELECT
    (SELECT count(*) FROM saved_operations
      WHERE status IN ('SUCCEEDED', 'REJECTED', 'EXPIRED')
        AND retention_expires_at < now() - interval '24 hours') AS overdue_operations,
    (SELECT count(*) FROM saved_outbox
      WHERE status IN ('DELIVERED', 'DEAD')
        AND retention_expires_at < now() - interval '24 hours') AS overdue_outbox,
    (SELECT count(*) FROM saved_inbox_dedup
      WHERE retention_expires_at < now() - interval '24 hours') AS overdue_inbox,
    (SELECT count(*) FROM saved_collection_items
      WHERE membership_state = 'REMOVED'
        AND purge_eligible_at < now() - interval '24 hours') AS overdue_memberships,
    (SELECT count(*) FROM saved_collections
      WHERE lifecycle_state = 'DELETED'
        AND purge_eligible_at < now() - interval '24 hours') AS overdue_collections,
    (SELECT count(*) FROM saved_items
      WHERE relationship_state = 'REMOVED'
        AND purge_eligible_at < now() - interval '24 hours') AS overdue_saved_items,
    (SELECT count(*) FROM saved_content_projections
      WHERE ever_referenced = FALSE
        AND shell_expires_at < now() - interval '1 hour') AS overdue_ephemeral_projections,
    (SELECT count(*) FROM saved_content_projections
      WHERE ever_referenced = TRUE
        AND gc_candidate_at < now() - interval '15 days') AS overdue_standard_projections,
    (SELECT count(*) FROM saved_subject_purge_operations
      WHERE phase = 'COMPLETED'
        AND retention_expires_at < now() - interval '24 hours') AS overdue_purge_ledgers;

SELECT count(*) AS deleted_collection_children_over_24h
FROM saved_collection_items AS item
JOIN saved_collections AS collection
  ON collection.owner_user_id = item.owner_user_id
 AND collection.id = item.collection_id
WHERE collection.lifecycle_state = 'DELETED'
  AND collection.deleted_at < now() - interval '24 hours';

-- Privacy invariants. Оба результата всегда должны быть 0.
SELECT count(*) AS impossible_private_rows
FROM saved_content_projections
WHERE visibility_status = 'PRIVATE' AND entity_type <> 'ACTIVITY';

SELECT count(*) AS non_public_payload_rows
FROM saved_content_projections
WHERE visibility_status <> 'PUBLIC'
  AND num_nonnulls(
      source_default_locale,
      title_en, title_ru, title_kk,
      subtitle_en, subtitle_ru, subtitle_kk,
      city_en, city_ru, city_kk,
      country_en, country_ru, country_kk,
      display_location_en, display_location_ru, display_location_kk,
      normalized_search_document_en,
      normalized_search_document_ru,
      normalized_search_document_kk,
      search_title_en_v1, search_title_ru_v1, search_title_kk_v1,
      search_city_en_v1, search_city_ru_v1, search_city_kk_v1,
      search_country_en_v1, search_country_ru_v1, search_country_kk_v1,
      media_reference, media_reference_revision, media_valid_until,
      rating_value, rating_count, rating_scale_max,
      price_summary, availability_summary,
      summary_as_of, summary_valid_until,
      canonical_detail_route
  ) > 0;

SELECT count(*) AS gc_candidates_with_saved_rows
FROM saved_content_projections AS projection
WHERE projection.gc_candidate_at IS NOT NULL
  AND EXISTS (
      SELECT 1
      FROM saved_items AS item
      WHERE item.entity_type = projection.entity_type
        AND item.entity_id = projection.entity_id
  );

-- Counter drift. Результаты всегда должны быть 0.
WITH actual AS (
    SELECT owner_user_id, count(*)::bigint AS active_count
    FROM saved_items
    WHERE relationship_state = 'ACTIVE'
    GROUP BY owner_user_id
), compared AS (
    SELECT
        COALESCE(usage.owner_user_id, actual.owner_user_id) AS owner_user_id,
        COALESCE(usage.active_saved_items_count, 0) AS recorded_count,
        COALESCE(actual.active_count, 0) AS actual_count
    FROM saved_user_usage AS usage
    FULL JOIN actual USING (owner_user_id)
)
SELECT count(*) AS saved_user_usage_mismatches
FROM compared
WHERE recorded_count <> actual_count;

WITH actual AS (
    SELECT
        collection.owner_user_id,
        collection.id,
        count(item.id) FILTER (
            WHERE item.membership_state = 'ACTIVE'
              AND saved_item.relationship_state = 'ACTIVE'
        )::bigint AS actual_count
    FROM saved_collections AS collection
    LEFT JOIN saved_collection_items AS item
      ON item.owner_user_id = collection.owner_user_id
     AND item.collection_id = collection.id
    LEFT JOIN saved_items AS saved_item
      ON saved_item.owner_user_id = item.owner_user_id
     AND saved_item.id = item.saved_item_id
    WHERE collection.lifecycle_state = 'ACTIVE'
    GROUP BY collection.owner_user_id, collection.id
)
SELECT count(*) AS active_collection_count_mismatches
FROM actual
JOIN saved_collections AS collection
  ON collection.owner_user_id = actual.owner_user_id
 AND collection.id = actual.id
WHERE collection.active_item_count <> actual.actual_count;

WITH actual_collections AS (
    SELECT owner_user_id, count(*)::bigint AS active_collections_count
    FROM saved_collections
    WHERE lifecycle_state = 'ACTIVE'
    GROUP BY owner_user_id
), actual_memberships AS (
    SELECT item.owner_user_id, count(*)::bigint AS active_memberships_count
    FROM saved_collection_items AS item
    JOIN saved_collections AS collection
      ON collection.owner_user_id = item.owner_user_id
     AND collection.id = item.collection_id
     AND collection.lifecycle_state = 'ACTIVE'
    JOIN saved_items AS saved_item
      ON saved_item.owner_user_id = item.owner_user_id
     AND saved_item.id = item.saved_item_id
     AND saved_item.relationship_state = 'ACTIVE'
    WHERE item.membership_state = 'ACTIVE'
    GROUP BY item.owner_user_id
), owners AS (
    SELECT owner_user_id FROM saved_collection_usage
    UNION
    SELECT owner_user_id FROM actual_collections
    UNION
    SELECT owner_user_id FROM actual_memberships
), compared AS (
    SELECT
        owners.owner_user_id,
        COALESCE(usage.active_collections_count, 0) AS recorded_collections,
        COALESCE(collections.active_collections_count, 0) AS actual_collections,
        COALESCE(usage.active_memberships_count, 0) AS recorded_memberships,
        COALESCE(memberships.active_memberships_count, 0) AS actual_memberships
    FROM owners
    LEFT JOIN saved_collection_usage AS usage USING (owner_user_id)
    LEFT JOIN actual_collections AS collections USING (owner_user_id)
    LEFT JOIN actual_memberships AS memberships USING (owner_user_id)
)
SELECT count(*) AS saved_collection_usage_mismatches
FROM compared
WHERE recorded_collections <> actual_collections
   OR recorded_memberships <> actual_memberships;

COMMIT;
```

Если search expand еще не применен, privacy query с `search_*_v1` закономерно не скомпилируется. В production после migration 003 эти columns обязательны; до этого использовать ту же проверку без девяти `search_*_v1` полей.

## 16. Backup, PITR и restore drill

### Objectives

| Failure class | RPO | RTO |
| --- | --- | --- |
| Zonal PostgreSQL failure | 0 | `<=15 min` |
| Regional disaster | `<=5 min` | `<=4 h` |

Требования: encrypted storage/WAL/backups, cross-account или cross-region copy по platform policy, immutable retention, audited restore role и регулярная проверка WAL archive continuity.

### Restore drill

1. Восстановить backup/PITR в изолированное окружение без Gateway/public traffic и без production NATS credentials.
2. Зафиксировать backup timestamp, last replayed WAL и фактические RPO/RTO.
3. Применить только forward migrations из того же release artifact.
4. Запустить `/app/saved-search-backfill -mode=status`; при необходимости завершить bounded backfill/contract до включения search.
5. Выполнить aggregate-only SQL из раздела 15. Privacy/invariant/counter mismatch должны быть 0.
6. Account deletion orchestrator обязан replay-ить все deletion ledger entries после restore point через internal mTLS purge endpoint.
7. Держать writes fenced для каждого replayed account до `COMPLETED`.
8. Проверить, что active purge backlog равен 0 и completed jobs появились для replayed operations.
9. Подключить non-production NATS contour, проверить streams/consumers и отсутствие DLQ.
10. Запустить Saved, проверить `/health`, `/ready`, `/metrics` и synthetic E2E только на выделенном test account.
11. Для реального disaster recovery открыть traffic только после Security/Privacy, DBA и Saved owner sign-off.

Backup restore без replay authoritative account deletion ledger запрещен: PITR может вернуть данные, удаленные после выбранной точки.

## 17. Production deployment checklist

- [ ] Change ticket, owners, rollback owner и incident channel назначены.
- [ ] Immutable image digest и SBOM/security scan подтверждены.
- [ ] Scope не расширен: no sharing/notes/bulk/Undo/reorder/client markers.
- [ ] Saved capabilities и API публикуют только `ATTRACTION`, `ACTIVITY`, `USER`.
- [ ] PostgreSQL backup, WAL archive, free disk, locks и replica lag healthy.
- [ ] Migration files reviewed как expand/contract; down migration не входит в deploy procedure.
- [ ] Search flag false до `-mode=contract` с `ready=true`.
- [ ] Production DB использует `verify-full`; secrets только из secret manager.
- [ ] NATS использует `tls://`, mounted credentials/certs и production cluster.
- [ ] Activity, Guide compatibility producer и Place используют отдельные NATS credentials/client
  certificates; inline credentials и общий producer credential отсутствуют.
- [ ] `SAVED_SOURCE` source producers подключены к тому же cluster.
- [ ] Activity: `ACTIVITY_SAVED_LIFECYCLE_ENABLED=true`.
- [ ] Migration `008` преобразовала все GUIDE projections/items/outbox rows в USER; GUIDE rows в canonical tables отсутствуют.
- [ ] user-service Saved source доступен по mTLS и возвращает USER projection для test account.
- [ ] chat-service internal Saved access endpoint доступен только trusted service identity и блокировка даёт neutral unavailable behavior.
- [ ] Place: runtime `SAVED_LIFECYCLE_EVENTS_ENABLED=true` (Compose control `PLACE_SAVED_LIFECYCLE_ENABLED=true`).
- [ ] `SAVED_DOMAIN_STREAM_REPLICAS >= 3`.
- [ ] mTLS CA/server/client certificates и SPIFFE allowlists прошли preflight.
- [ ] saved-service identity разрешена в user-service gRPC и chat-service internal HTTP allowlists.
- [ ] user-service SPIFFE имеет доступ только к internal purge contour.
- [ ] Operation HMAC и cursor AEAD используют разные non-development keys.
- [ ] Previous key overlap достаточен для retention/TTL.
- [ ] Platform policy `AVAILABLE`, revision monotonic, validity fresh.
- [ ] Product flags и новый `SAVED_CAPABILITY_REVISION` заданы явно.
- [ ] Source/token URLs, TLS server names и service credentials проверены.
- [ ] Migrator завершился успешно; marker не добавлялся вручную.
- [ ] Search status соответствует выбранной rollout phase.
- [ ] `/health`, `/ready`, `/metrics` healthy на canary.
- [ ] `SAVED_SOURCE` consumers и `SAVED_DOMAIN` metadata healthy.
- [ ] Aggregate SQL: PII/privacy/counter/invariant breaches равны 0.
- [ ] Synthetic test account проходит USER save, same-key retry, global unsave, list, collection и operation status.
- [ ] Synthetic block/unblock проверяет neutral unavailable placeholder, отсутствие avatar/route/search metadata и ручной unsave.
- [ ] Logs не содержат personal IDs, titles, queries, cursors или bodies.
- [ ] 1% -> 5% -> 25% -> 50% -> 100% только после soak и SLO review.

## 18. Rollback checklist

- [ ] Остановить расширение cohort и новые deploy/backfill jobs.
- [ ] Зафиксировать UTC interval, image digest, capability revision и aggregate symptoms.
- [ ] Для обычного product regression выключить соответствующий product flag, увеличить capability revision и остановить discovery на client/edge.
- [ ] Для security/privacy/data-integrity incident активировать platform policy `LOCKED`.
- [ ] Не считать product flag security kill switch.
- [ ] Вернуть только предыдущий binary, совместимый с уже примененной expanded schema.
- [ ] Не запускать down migrations и не удалять columns/indexes в incident window.
- [ ] Не удалять NATS streams/consumers и не purge-ить messages.
- [ ] Не редактировать operation/outbox/purge rows вручную.
- [ ] После rollback проверить `/ready`, metrics, DB aggregates и NATS consumer metadata.
- [ ] Убедиться, что reducing user actions и existing data не были скрыты routine product rollback-ом.
- [ ] Для снятия platform `LOCKED` требуется Security/Privacy approval и monotonic policy revision.
- [ ] Задокументировать residual backlog и назначить controlled cleanup/forward fix.

## 19. Известные эксплуатационные границы текущей реализации

- `/ready` aggregate-only и не указывает отказавшую dependency в response.
- Product flags блокируют discovery и новые expansion на backend, но намеренно
  сохраняют reads и reducing actions для уже существующих owner data.
- Отдельного Saved mutation-only breaker нет.
- Нет operator endpoints для outbox replay, DLQ replay, maintenance run или reconciliation.
- Service metrics не экспортируют DB pool, policy age, exact pending-operation backlog или GC age; эти сигналы должны приходить из platform exporters, synthetic probes и aggregate SQL jobs.
- `/metrics` требует network-level restriction.
- `MTLS_MODE` поддерживает только `disabled|enforce`; production использует `enforce`.
- retired и неизвестные Saved entity types отклоняются до создания operation.

Эти границы нельзя обходить ручным SQL, spoofed headers или неописанными endpoints. Изменение любой из них требует code change, tests, security review и отдельного rollout.
