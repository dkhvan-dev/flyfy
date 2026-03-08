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