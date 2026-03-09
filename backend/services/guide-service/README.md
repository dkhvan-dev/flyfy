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
- `GET /v1/guides/{id}`

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

## ENV

Скопируй `.env.example` и задай реальные значения.

## Локальный запуск

```bash
go mod tidy
go run ./cmd