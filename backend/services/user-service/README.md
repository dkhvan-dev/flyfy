# user-service

`user-service` отвечает за:
- user account
- user profile
- user settings
- system roles
- user reputation
- интеграцию с `file-manager-service` для аватара

## HTTP API

### Health
- `GET /health`

### Current user
- `POST /v1/users/me/init`
- `GET /v1/users/me`
- `PUT /v1/users/me/profile`
- `PUT /v1/users/me/settings`

### Public / admin
- `GET /v1/public/users`
- `GET /v1/users/{id}`
- `POST /v1/admin/users/{id}/roles`

## gRPC API

См. `proto/user/v1/user.proto`.

Основные методы:
- `GetOrCreateUserBySubject`
- `GetUserById`
- `GetUserProfile`
- `UpdateUserProfile`
- `UpdateUserSettings`
- `GrantUserRole`
- `ListPublicProfiles`

## Архитектурные правила

- `auth-service` владеет аутентификацией
- `user-service` владеет user aggregate
- `file-manager-service` владеет файлами
- аватар в `user-service` хранится как `avatar_file_id`
- перед сохранением аватара `user-service` валидирует файл через `file-manager-service`
- после валидации `user-service` вызывает bind в `file-manager-service`

## ENV

Скопируй `.env.example` и задай реальные значения.

## Локальный запуск

```bash
go mod tidy
go run ./cmd
```

## Feed social read-model backfill

`user-service` пишет follow/friendship события в `user_social_outbox`, а worker
доставляет их в `feed-service`, где они становятся локальным read-model для
ранжирования ленты. Для локального docker-compose включен startup backfill:
при старте `user-service` идемпотентно enqueue-ит недостающие события для уже
существующих подписок и дружб, а worker доставляет их в `feed-service`.

В stage/prod startup scan стоит включать осознанно через
`USER_SOCIAL_OUTBOX_STARTUP_BACKFILL_ENABLED=true`, либо запускать one-shot job
после выката миграции `013_user_social_outbox`, чтобы перелить уже существующие
подписки и дружбы:

```bash
make backfill-feed-social-outbox
```

Команда идемпотентна: для старых связей используется детерминированный
`source_key`, поэтому повторный запуск не создаст дубли. В Docker-образ также
пакуется бинарь `/opt/app/user-service-backfill-feed-social-outbox` для
one-shot job в stage/prod.

Если нужно выполнить полный one-shot sync без ожидания фонового worker'а
`user-service`, запусти backfill с drain-режимом. Он положит недостающие события
в outbox и сразу доставит due batches в `feed-service`:

```bash
go run ./cmd/backfill-feed-social-outbox -drain -max-drain-batches=100
```

В контейнере аналогично:

```bash
/opt/app/user-service-backfill-feed-social-outbox -drain -max-drain-batches=100
```
