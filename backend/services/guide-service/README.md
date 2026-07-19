# guide-service

`guide-service` отвечает за профессиональный профиль гида, верификацию и связанные с этим доменные данные.

## Что хранит сервис

- `guide_profiles`
- `guide_verification_requests`
- `guide_documents`
- `guide_languages`
- `guide_specializations`
- `guide_regions`
- `guide_company_affiliations`

## Что сервис не хранит

- user account / identity
- auth / login
- сами файлы
- туры
- активности

## Интеграции

### user-service
Используется для проверки, что `user_id` существует.

### file-manager-service
Используется для:
- проверки документов верификации
- bind документа на `GUIDE_VERIFICATION_REQUEST`

## HTTP API

### Health
- `GET /health`

### My guide profile
- `POST /v1/guides/me/init`
- `GET /v1/guides/me`
- `PUT /v1/guides/me/profile`

### Verification
- `POST /v1/guides/me/verification-requests`
- `POST /v1/guides/me/verification-requests/{id}/documents`

### Public
- `GET /v1/guides/public`
- `GET /v1/guides/public/by-user/{user_id}`

Полные aggregate-маршруты `GET /v1/guides/{id}` и
`GET /v1/guides/by-user/{user_id}` доступны только владельцу профиля или
модерации. Публичные ответы не содержат документы, review comments и внутренние
поля смены статуса.

## gRPC API

См. `proto/guide/v1/guide.proto`.

Основные методы:
- `GetOrCreateGuideProfile`
- `GetGuideProfileById`
- `GetGuideProfileByUserId`
- `UpdateGuideProfile`
- `CreateVerificationRequest`
- `AttachVerificationDocument`
- `ListPublicGuides`

### Saved source (internal only)

`content.v1.SavedSourceService/ResolveSaveEligibility` зарегистрирован только
на gRPC-сервере сервиса и не имеет HTTP/Gateway-маршрута. Resolver принимает
канонический `GUIDE user_id`, требует service JWT caller `saved-service` с ролью
`saved:resolve` и возвращает карточную projection только для профиля
`ACTIVE + latest verification APPROVED` с активным user account.

Для service JWT verifier используются:

- `SERVICE_AUTH_ISSUER`
- `SERVICE_AUTH_JWKS_URL`
- `SERVICE_AUTH_JWKS_CACHE_TTL`
- `SAVED_SOURCE_ALLOWED_CALLER` (по умолчанию `saved-service`)

### Saved lifecycle events

Guide-owned изменения профиля и последней верификации пишут immutable
`content.v1.SavedSourceLifecycleEvent` в PostgreSQL transactional outbox в той
же транзакции. Dispatcher публикует protobuf в JetStream subject
`saved.source.guide.lifecycle.v1` с `event_id` как `Nats-Msg-Id`. Доставка
at-least-once: одинаковый `event_id` всегда имеет одинаковые semantic fields,
а consumer обязан дедуплицировать его и сравнивать три revision component
независимо.

`user-service` владеет account/profile и не участвует в транзакции Guide.
Поэтому bounded reconciler запрашивает только уже существующие guide rows через
authenticated internal gRPC. Локально сохраняются source timestamps,
SHA-256 fingerprint публичной projection и avatar file ID; имя и другие PII не
копируются. Переход в deny-state, деактивация/rotation avatar reference и
outbox insert выполняются одной локальной транзакцией. Default reconcile bound
равен одной минуте, а guide/verification visibility transition немедленно
делает row due. Старый opaque media ref
не должен резолвиться без проверки current `media_reference_revision` и
`media_reference_active`.

Guide avatar передаётся только как opaque token
`guide-avatar:<lowercase-user_id>:<avatar_file_id>:<media_reference_revision>`.
Это не URL, и Saved/mobile не должны пытаться загружать его напрямую. Публичный
delivery endpoint имеет контракт:

```http
GET /v1/guides/public/by-user/{userID}/saved-avatar?saved_revision=<media_reference_revision>
```

`saved_revision` обязан точно совпадать с current
`SavedMediaReference.reference_revision`, то есть с media revision внутри
`guide-avatar` token. Он намеренно не сравнивается с `projection_revision`:
изменение имени, title или rating не должно инвалидировать URL неизменившегося
avatar. Endpoint публичный, но на каждом запросе внутри вызывает
Guide-owned `ResolveCurrentGuideAvatarReference`, повторно проверяет exact token,
lifecycle `PUBLIC`, eligibility, профиль `ACTIVE`, latest verification
`APPROVED`, current ACTIVE user account и совпадение current avatar. Только после
этого authenticated file-service client выпускает короткоживущий download URL,
на который Guide отвечает `307` с `Cache-Control: no-store` и строгими security
headers. Прямая подстановка file ID, immutable CDN URL или opaque token в
public route запрещена. Любая ошибка зависимостей закрывает доступ.

При локальном переходе `PUBLIC -> deny` Guide в одной транзакции сначала
выключает `media_reference_active` и увеличивает media revision, после чего
создаёт payload-free lifecycle event. User-service deny/avatar transition
дополнительно проверяется live при media resolve, а reconciler закрепляет revoke
в Guide state в bounded interval. Поэтому stale token получает нейтральный
not-found; ранее выданный signed URL должен жить не дольше короткого CDN TTL и
никогда не кэшироваться дольше `valid_until`. Для `UNAVAILABLE`/`DELETED`
outbox, domain validator и protobuf encoder запрещают `public_projection`;
следовательно, такие события не содержат ни projection, ни media reference.

Outbox использует `PENDING -> PROCESSING -> DELIVERED | DEAD`, `FOR UPDATE SKIP
LOCKED`, bounded exponential retry и lease recovery. `DEAD` rows являются
durable DLQ и хранятся 90 дней; semantic columns менять запрещено. После
устранения причины оператор может вернуть row в `PENDING`, изменив только
delivery fields и сохранив исходный `event_id`/payload/revisions.

Основные настройки:

- `SAVED_LIFECYCLE_ENABLED` (включать только после миграции и готовности Saved consumer);
- `NATS_URL`, `SAVED_LIFECYCLE_SUBJECT`;
- `SAVED_LIFECYCLE_BATCH_SIZE`, `SAVED_LIFECYCLE_CONCURRENCY`;
- `SAVED_LIFECYCLE_LEASE_DURATION`, `SAVED_LIFECYCLE_PUBLISH_TIMEOUT`;
- `SAVED_USER_RECONCILE_BATCH_SIZE`, `SAVED_USER_RECONCILE_CONCURRENCY`;
- `SAVED_USER_RECONCILE_INTERVAL`, `SAVED_USER_RECONCILE_SOURCE_TIMEOUT`.

Перед включением `saved_entity_guide` обязательны: нулевой/контролируемый
outbox backlog, отсутствие `DEAD`, успешный reconcile активных гидов и
проверенная подписка Saved consumer. Отключение dispatcher не теряет события:
producer продолжает писать outbox, но backlog должен алертиться.

## ENV

Скопируй `.env.example` и задай реальные значения.

## Локальный запуск

```bash
go mod tidy
go run ./cmd
